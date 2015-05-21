/*
 * 
 * Homing Reflects
 *
 * Author: InsaneMosquito
 * Date:   June 2012
 * 
 * Make homing projectiles from reflections
 * 
 */

/*************************************************************************************************************************************
 Version - 0.0.3:
	Renamed from Rejectiles to Reflectiles
	 
 Version - 0.0.2:
    CVar Change hooks

 Version - 0.0.1:
    Initial Version


 To Do:
    Translations file

*************************************************************************************************************************************/
 

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_NAME "Reflectiles"
#define PLUGIN_VERSION "0.0.3"
#define PLUGIN_DESC "Reflected Projectiles become homing"
#define PLUGIN_URL "http://www.team-vipers.com"
#define PLUGIN_AUTHOR "InsaneMosquito"

	// -- Our stuff -- //
new Handle:c_Enabled   		= INVALID_HANDLE;	// Plugin Enabled?
new Handle:c_Chance   		= INVALID_HANDLE;	// Chance of a Rejectile
new Handle:c_ReflectsNeeded = INVALID_HANDLE;	// Number of reflections before homing starts
new Handle:c_HomingSpeed	= INVALID_HANDLE;	// Speed multiplier
new Handle:c_HomingReflect	= INVALID_HANDLE;	// Speed multiplier increase for each reflect
new Handle:g_hArrayHoming	= INVALID_HANDLE;	// Array of homing projectiles


#define ARRAY_ENTITY 	0
#define ARRAY_TYPE 		1

new g_NumReflects;
new g_Enabled;
new Float:g_Chance;
new Float:g_HomingSpeed;
new Float:g_HomingReflect;

enum g_eProjectiles
{
	PROJECTILE_ROCKET=0,
	PROJECTILE_ARROW,
	PROJECTILE_FLARE,
	PROJECTILE_SENTRY,
	PROJECTILE_BALL
};



public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
//	CreateConVar("sm_reflectile_version", PLUGIN_VERSION, "Reflectile Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	c_Enabled = CreateConVar("sm_reflectile_enable", "1", "<0/1> Enable Rejectiles");
	c_Chance = CreateConVar("sm_reflectile_chance", "1.00", "<0.0 to 1.0> Chance that a projectile will reflect");
	c_ReflectsNeeded = CreateConVar("sm_reflectile_numreflects", "1", "<1 to 20> Number of reflections needed before homing starts", _, true, 1.0, true, 20.0);
	c_HomingSpeed = CreateConVar("sm_reflectile_homing_speed", "0.5", "Speed multiplier for homing rockets.");	
	c_HomingReflect = CreateConVar("sm_reflectile_homing_reflect", "0.1", "Speed multiplier increase for each reflection.");	
	
	g_NumReflects = GetConVarInt(c_ReflectsNeeded);
	g_Enabled = GetConVarInt(c_Enabled);
	g_Chance = GetConVarFloat(c_Chance);
	g_HomingSpeed = GetConVarFloat(c_HomingSpeed);
	g_HomingReflect = GetConVarFloat(c_HomingReflect);
	
	g_hArrayHoming = CreateArray(2);
}

public OnConfigsExecuted()
{
	PrintToServer("[Reflectiles] Plugin Loaded");

	HookConVarChange(c_Enabled, ConVarChange_Enabled);
	HookConVarChange(c_Chance, ConVarChange_Chance);
	HookConVarChange(c_ReflectsNeeded, ConVarChange_ReflectsNeeded);
	HookConVarChange(c_HomingSpeed, ConVarChange_HomingSpeed);
	HookConVarChange(c_HomingReflect, ConVarChange_HomingReflect);
}




	// -- Very much taken from linux_lover's RTD plugin -- //

public OnEntityCreated(entity, const String:classname[])
{
	if (g_Enabled)
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(strcmp(classname, "tf_projectile_rocket") == 0 || strcmp(classname, "tf_projectile_arrow") == 0 || strcmp(classname, "tf_projectile_flare") == 0 || strcmp(classname, "tf_projectile_energy_ball") == 0 || strcmp(classname, "tf_projectile_healing_bolt") == 0 || strcmp(classname, "tf_projectile_sentryrocket") == 0 || strcmp(classname, "tf_projectile_ball_ornament") == 0 || strcmp(classname, "tf_projectile_stun_ball") == 0)
				{
					CreateTimer(0.2, Timer_CheckOwnership, EntIndexToEntRef(entity));
				}

				return;
			}
		}
	}
	return;
}

public Action:Timer_CheckOwnership(Handle:hTimer, any:iRef)
{
	new iProjectile = EntRefToEntIndex(iRef);
	if(iProjectile > MaxClients && IsValidEntity(iProjectile))
	{
		new iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
		if(iLauncher >= 1 && iLauncher <= MaxClients && IsClientInGame(iLauncher))
		{
			decl String:strClassname[40];
			GetEdictClassname(iProjectile, strClassname, sizeof(strClassname));
			
			new g_eProjectiles:type = PROJECTILE_ROCKET;
			switch(strClassname[18])
			{
				case 'w': type = PROJECTILE_ARROW;			// tf_projectile_arrow
				case 'i': type = PROJECTILE_ARROW;			// tf_projectile_healing_bolt
				case 'e': type = PROJECTILE_FLARE;			// tf_projectile_flare
				case 'r': type = PROJECTILE_SENTRY;			// tf_projectile_sentryrocket
				case '_': type = PROJECTILE_BALL;			// tf_projectile_ball_ornament
															// tf_projectile_stun_ball
			}
			
			new iData[2];
			iData[ARRAY_ENTITY] = EntIndexToEntRef(iProjectile);
			iData[ARRAY_TYPE] = _:type;
			PushArrayArray(g_hArrayHoming, iData);
		}
	}
	
	return Plugin_Handled;
}

public OnGameFrame()
{
	// Using this method instead of SDKHooks because the Think functions are not called consistently for all projectiles
	for(new i=0; i<GetArraySize(g_hArrayHoming); i++)
	{
		new iData[2];
		GetArrayArray(g_hArrayHoming, i, iData);
		
		if(iData[ARRAY_ENTITY] == 0)
		{
			RemoveFromArray(g_hArrayHoming, i);
			continue;
		}
		
		new iProjectile = EntRefToEntIndex(iData[ARRAY_ENTITY]);
		if (iProjectile > MaxClients)
		{
			new iDeflectionCount = GetEntProp(iProjectile, Prop_Send, "m_iDeflected");
			
			if ((iDeflectionCount >= g_NumReflects) && (g_Chance >= GetURandomFloat()))		// If we've exceeded minimium reflection count and it has exceeded our chance of tracking
			{
				if(iProjectile > MaxClients)
				{
					HomingProjectile_Think(iProjectile, g_eProjectile:iData[ARRAY_TYPE]);
				}
				else
				{
					RemoveFromArray(g_hArrayHoming, i);
				}
			}
		}
	}

}

public HomingProjectile_Think(iProjectile, g_eProjectile:pType)
{	
	new iCurrentTarget = GetEntProp(iProjectile, Prop_Send, "m_nForceBone");
	
	new iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	
	if(!HomingProjectile_IsValidTarget(iCurrentTarget, iProjectile, iTeam))
	{
		HomingProjectile_FindTarget(iProjectile, pType);
	}
	else
	{
		HomingProjectile_TurnToTarget(iCurrentTarget, iProjectile, pType);
	}
}

bool:HomingProjectile_IsValidTarget(client, iProjectile, iTeam)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != iTeam)
	{
		
			// -- When to ignore player; Cloaked, Disguised as friendly to projectile owner, in Uber -- //	
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked)) 
		{
			return false;
		}
		
		if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
		{
			return false;
		}
		
		if (TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
		{
			return false;
		}
		
		new Float:flStart[3];
		GetClientEyePosition(client, flStart);
		new Float:flEnd[3];
		GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flEnd);
		
		new Handle:hTrace = TR_TraceRayFilterEx(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceFilterHoming, iProjectile);
		if(hTrace != INVALID_HANDLE)
		{
			if(TR_DidHit(hTrace))
			{
				CloseHandle(hTrace);
				return false;
			}
			
			CloseHandle(hTrace);
			return true;
		}
	}
	
	return false;
}

public bool:TraceFilterHoming(entity, contentsMask, any:iProjectile)
{
	if(entity == iProjectile || (entity >= 1 && entity <= MaxClients))
	{
		return false;
	}
	
	return true;
}

HomingProjectile_FindTarget(iProjectile, g_eProjectile:pType)
{
	new iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	new Float:flPos1[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flPos1);
	
	new iBestTarget;
	new Float:flBestLength = 99999.9;
	for(new i=1; i<=MaxClients; i++)
	{
		if(HomingProjectile_IsValidTarget(i, iProjectile, iTeam))
		{
			new Float:flPos2[3];
			GetClientEyePosition(i, flPos2);
			
			new Float:flDistance = GetVectorDistance(flPos1, flPos2);
			
			if(flDistance < flBestLength)
			{
				iBestTarget = i;
				flBestLength = flDistance;
			}
		}
	}
	
	if(iBestTarget >= 1 && iBestTarget <= MaxClients)
	{
		SetEntProp(iProjectile, Prop_Send, "m_nForceBone", iBestTarget);
		HomingProjectile_TurnToTarget(iBestTarget, iProjectile, pType);
	}else{
		SetEntProp(iProjectile, Prop_Send, "m_nForceBone", 0);
	}
}

HomingProjectile_TurnToTarget(client, iProjectile, pType)
{
	new Float:flTargetPos[3];
	GetClientAbsOrigin(client, flTargetPos);
	new Float:flRocketPos[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flRocketPos);
	
	new Float:flRocketVel[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_vecAbsVelocity", flRocketVel);
	
	//flTargetPos[2] += 50.0;
	flTargetPos[2] += 30 + Pow(GetVectorDistance(flTargetPos, flRocketPos), 2.0) / 10000;
	
	new Float:flNewVec[3];
	SubtractVectors(flTargetPos, flRocketPos, flNewVec);
	NormalizeVector(flNewVec, flNewVec);
	
	new Float:flAng[3];
	GetVectorAngles(flNewVec, flAng);
	
	new Float:flSpeed = 1100.0;
	switch(pType)
	{
		case PROJECTILE_ARROW: flSpeed = 1800.0; 
		case PROJECTILE_FLARE: flSpeed = 1450.0; 
		case PROJECTILE_SENTRY: flSpeed = 1075.0;
		case PROJECTILE_BALL: flSpeed = 1940.0;
	}
	
	flSpeed *= g_HomingSpeed;	
	flSpeed += GetEntProp(iProjectile, Prop_Send, "m_iDeflected") * (flSpeed * g_HomingReflect);
	
	ScaleVector(flNewVec, flSpeed);
	
	TeleportEntity(iProjectile, NULL_VECTOR, flAng, flNewVec);
}







	// -- ConVar Change Hooks -- //
public ConVarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToInt(newValue) == 0)
	{
		g_Enabled = 0;
	}
	else
	{
		g_Enabled = 1;
	}
}

public ConVarChange_Chance(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToFloat(newValue) < 0.0)
	{
		g_Chance = 0.0;
	}
	else if (StringToFloat(newValue) > 1.0)
	{
		g_Chance = 1.0;
	}
	else
	{
		g_Chance = StringToFloat(newValue);	
	}
}

public ConVarChange_ReflectsNeeded(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToInt(newValue) < 0)
	{
		g_NumReflects = 0;
	}
	else if (StringToInt(newValue) > 20)
	{
		g_NumReflects = 20;
	}
	else
	{
		g_NumReflects = StringToInt(newValue);	
	}
}

public ConVarChange_HomingSpeed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToFloat(newValue) < 0.0)
	{
		g_HomingSpeed = 0.0;
	}
	else
	{
		g_HomingSpeed = StringToFloat(newValue);	
	}
}

public ConVarChange_HomingReflect(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToFloat(newValue) < 0.0)
	{
		g_HomingReflect = 0.0;
	}
	else
	{
		g_HomingReflect = StringToFloat(newValue);	
	}
}