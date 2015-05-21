/*
 * 
 * Instant Knife Kills
 * 
 * All knife stabs are instant kill (facestabs)
 * 
 */


#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_NAME "Facestabs"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESC "All knife stabs are facestabs"
#define PLUGIN_URL "http://www.team-vipers.com"
#define PLUGIN_AUTHOR "InsaneMosquito"

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
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PlayerDamage_Hook(i);
		}
	}
}

public OnClientPutInServer(client)
{
    PlayerDamage_Hook(client);
}

PlayerDamage_Hook(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_Hook);
}

public Action:OnTakeDamage_Hook(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (attacker > 0)			// No World check
	{
		decl String:WeaponName[40];
		GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));
			
		if (StrEqual(WeaponName, "tf_weapon_knife", true))
		{
			new TFClassType:class = TF2_GetPlayerClass(victim);
			if (class == TFClass_Spy)
			{
					// Handle Deadringer
				new IsDeadRingerOut = GetEntProp(victim, Prop_Send, "m_bFeignDeathReady");
				if (IsDeadRingerOut)
				{
					new iHealth = GetClientHealth(victim);
					DealDamage(victim, 1, victim);
					if(iHealth>GetClientHealth(victim))
					{
						SetEntityHealth(victim, iHealth);
						damage = 0.0;
						damagetype = DMG_BULLET;
					}
				}
				else		// Non-deadringer
				{
					damage = 10000.0;
					damagetype = DMG_SLASH
				}
			}
			else
			{
				damage = 10000.0;
				damagetype = DMG_SLASH;
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}


// pimpinjuice   -  http://forums.alliedmods.net/showthread.php?t=111684
DealDamage(victim, damage, attacker = 0, dmg_type = 0)
{
	if(victim > 0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage > 0)
	{
		new String:dmg_str[16];
		IntToString(damage, dmg_str, 16);
		
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);

		new pointHurt = CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim, "targetname", "wall_hurtme");
			DispatchKeyValue(pointHurt, "DamageTarget", "wall_hurtme");
			DispatchKeyValue(pointHurt, "Damage", dmg_str);
			DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt, "Hurt", (attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "wall_donthurtme");
			AcceptEntityInput(pointHurt, "Kill");
		}
	}
}
