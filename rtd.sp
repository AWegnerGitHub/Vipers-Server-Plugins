/*
* [TF2] Roll The Dice
* 
* Author: linux_lower
* Date: June 6, 2009
* 
* Modified by: InsaneMosquito
* Date: Jan. 2011
* 
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sidewinder>
#include <tf2items_giveweapon>

#define PLUGIN_NAME "[TF2] Roll The Dice"
#define PLUGIN_VERSION 	"0.3.8.4-Fork"
#define PLUGIN_DESC "Let's users roll for special temporary powers."
#define PLUGIN_URL "http://www.team-vipers.com"
#define PLUGIN_AUTHOR "InsaneMosquito"


#define cDefault				0x01
#define cLightGreen 			0x03
#define cGreen					0x04
#define cDarkGreen  			0x05

#define MAX_GOOD_AWARDS			20

#define AWARD_G_GODMODE			0
#define AWARD_G_TOXIC   		1
#define AWARD_G_HEALTH			2
#define AWARD_G_SPEED			3
#define AWARD_G_NOCLIP  		4
#define AWARD_G_LOWGRAVITY 		5
#define AWARD_G_UBER			6
#define AWARD_G_INVIS			7
#define AWARD_G_INSTANTKILL		8
#define AWARD_G_CLOAK			9
#define AWARD_G_CRITS			10
#define AWARD_G_POWERPLAY		11
#define AWARD_G_MINICRITS		12
#define AWARD_G_SENTRY			13
#define AWARD_G_HOMING			14
#define AWARD_G_RUBBERBULLET	15
#define AWARD_G_VALVEROCKETS	16
#define AWARD_G_FIREBULLET		17
#define AWARD_G_FREEZEBULLET	18
#define AWARD_G_HORSEMAN		19

#define MAX_BAD_AWARDS			19

#define AWARD_B_EXPLODE			0
#define AWARD_B_SNAIL			1
#define AWARD_B_FREEZE			2
#define AWARD_B_TIMEBOMB		3
#define AWARD_B_IGNITE			4
#define AWARD_B_HEALTH			5
#define AWARD_B_DRUG			6
#define AWARD_B_BLIND			7
#define AWARD_B_WEAPONS			8
#define AWARD_B_BEACON			9
#define AWARD_B_TAUNT			10
#define AWARD_B_JARATE			11
#define AWARD_B_BONK			12
#define AWARD_B_SCARED			13
#define AWARD_B_BLEED			14
#define AWARD_B_HIGHGRAVITY		15
#define AWARD_B_FREEZEBOMB		16
#define AWARD_B_FIREBOMB		17
#define AWARD_B_NOCRIT			18

#define PLAYER_STATUS			0
#define PLAYER_TIMESTAMP		1
#define PLAYER_EFFECT			2
#define PLAYER_EXTRA			3
#define PLAYER_FLAG				4
#define PLAYER_WEAPONS			5
#define PLAYER_SENTRY_COUNT		6

#define RED_TEAM				2
#define BLUE_TEAM				3

#define DIRTY_HACK				100

#define BLACK					{200,200,200,192}
#define INVIS					{255,255,255,0}
#define NORMAL					{255,255,255,255}

#define MAX_CHAT_TRIGGERS		15
#define MAX_CHAT_TRIGGER_LENGTH 15

#define SIZE_OF_INT		2147483647

	// Sounds
#define REWARD_SENTRYDROP "items/spawn_item.wav"

	// Sourcemod has an incorrect define for ep2v games (TF2/CS:S/etc)
	// We need to fix the define that is used to prevent sentry targetting
//#undef FL_NOTARGET
//#define FL_NOTARGET				(1<<16)

new Handle:c_Enabled   		= INVALID_HANDLE;
new Handle:c_Timelimit		= INVALID_HANDLE;
new Handle:c_Mode	   		= INVALID_HANDLE;
new Handle:c_Disabled  		= INVALID_HANDLE;
new Handle:c_Duration  		= INVALID_HANDLE;
new Handle:c_Teamlimit 		= INVALID_HANDLE;
new Handle:c_Chance	   		= INVALID_HANDLE;
new Handle:c_Distance  		= INVALID_HANDLE;
new Handle:c_Health	   		= INVALID_HANDLE;
new Handle:c_LowGravity   	= INVALID_HANDLE;
new Handle:c_HighGravity   	= INVALID_HANDLE;
new Handle:c_Snail	   		= INVALID_HANDLE;
new Handle:c_Trigger   		= INVALID_HANDLE;
new Handle:c_Admin	   		= INVALID_HANDLE;
new Handle:c_Donator		= INVALID_HANDLE;
new Handle:c_DonatorChance 	= INVALID_HANDLE;
new Handle:c_LogEnabled 	= INVALID_HANDLE;
new Handle:g_StatsDB		= INVALID_HANDLE;
new Handle:c_timebomb_mode	= INVALID_HANDLE;
new Handle:c_timebomb_ticks = INVALID_HANDLE;
new Handle:c_timebomb_radius 	= INVALID_HANDLE;
new Handle:c_freezebomb_mode	= INVALID_HANDLE;
new Handle:c_freezebomb_ticks 	= INVALID_HANDLE;
new Handle:c_freezebomb_radius 	= INVALID_HANDLE;
new Handle:c_freeze_duration 	= INVALID_HANDLE;
new Handle:c_firebomb_mode	= INVALID_HANDLE;
new Handle:c_firebomb_ticks = INVALID_HANDLE;
new Handle:c_firebomb_radius 	= INVALID_HANDLE;
new Handle:c_burn_duration 	= INVALID_HANDLE;
new Handle:c_freezebullet_freeze_duration 	= INVALID_HANDLE;


	// Timebomb, firebomb, freezebomb overrides
new rtd_timebomb_mode;
new orig_timebomb_mode;
new Float:rtd_timebomb_ticks;
new Float:orig_timebomb_ticks;
new Float:rtd_timebomb_radius;
new Float:orig_timebomb_radius;

new rtd_freezebomb_mode;
new orig_freezebomb_mode;
new Float:rtd_freezebomb_ticks;
new Float:orig_freezebomb_ticks;
new Float:rtd_freezebomb_radius;
new Float:orig_freezebomb_radius;
new Float:rtd_freeze_duration;
new Float:orig_freeze_duration;

new rtd_firebomb_mode;
new orig_firebomb_mode;
new Float:rtd_firebomb_ticks;
new Float:orig_firebomb_ticks;
new Float:rtd_firebomb_radius;
new Float:orig_firebomb_radius;
new Float:rtd_burn_duration;
new Float:orig_burn_duration;
new Float:freezebullet_duration;

new c_NumSentries	= 1;

new TrackPlayers[MAXPLAYERS+1][7];

new Disabled_Good_Commands[MAX_GOOD_AWARDS];
new Disabled_Bad_Commands[MAX_BAD_AWARDS];

new Handle:PlayerTimers[MAXPLAYERS+1][2]; // 0 for end effects timer & 1 for repeating timer

new String:chatTriggers[MAX_CHAT_TRIGGERS][MAX_CHAT_TRIGGER_LENGTH];
new g_iTriggers = 0;

new g_cloakOffset;
//new g_wearableOffset;
//new g_shieldOffset;

new bool:g_instantRed = false;
new bool:g_instantBlu = false;
new bool:loaded = false;

new Float:durationFloat;
new durationInt;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public OnPluginStart()
{
	CheckGame();
	CreateConVar("sm_rtd_version", PLUGIN_VERSION, "Current RTD Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_Enabled   = CreateConVar("sm_rtd_enable",    	"1",        "<0/1> Enable RTD");
	c_LogEnabled= CreateConVar("sm_rtd_logenable", 	"0",        "<0/1> Enable RTD Log");
	c_Timelimit = CreateConVar("sm_rtd_timelimit",	"120",      "<0-x> Time in seconds between RTDs");
	c_Mode		= CreateConVar("sm_rtd_mode",      	"1",        "<0/1/2> 0 : Roll the Dice free for all. Players can roll anytime they want, as long as they don't exceed sm_rtd_timelimit. 1 : Legacy mode. Only one player can roll the dice at a time. 2 : Team limit mode. Only a certain amount of players can roll at a given time, on a given team. Set sm_rtd_teamlimit for your team limit amount. Default teamlimit value is 1.");
	c_Disabled  = CreateConVar("sm_rtd_disabled",  	"",         "All the effects you want disabled - Seperated by commas");
	c_Duration  = CreateConVar("sm_rtd_duration",  	"20.0",     "<0.1-x> Time in seconds the RTD effects last.");
	c_Teamlimit = CreateConVar("sm_rtd_teamlimit", 	"1",        "<1-x> Number of players on the same team that can RTD in mode 1");
	c_Chance	= CreateConVar("sm_rtd_chance",    	"0.5",      "<0.1-1.0> Chance of a good award.");
	c_Distance  = CreateConVar("sm_rtd_distance",  	"275.0",    "<any float> Distance for toxic kills");
	c_Health    = CreateConVar("sm_rtd_health",    	"1000",    	"<500/2000/5000/etc> Amount of health given for health award.");
	c_LowGravity   = CreateConVar("sm_rtd_gravity",	"0.1",      "<0.1-x> Low Gravity multiplier.");
	c_HighGravity  = CreateConVar("sm_rtd_highgravity",	"3.0",      "<0.1-x> High Gravity multiplier.");
	c_Snail		= CreateConVar("sm_rtd_snail",     	"50.0",     "<1.0-x> Speed for the snail award.");
	c_Admin		= CreateConVar("sm_rtd_admin",	   	"",			"The access flag if you want to make rtd admin only: 'abcz' (must have all flags)");
	c_Donator 	= CreateConVar("sm_rtd_donator",	"",			"The access flag for donators: 'o' (must have all flags)");
	c_DonatorChance = CreateConVar("sm_rtd_dchance","0.5",		"<0.1-1.0> Chance for a good awards for donators");
	c_timebomb_mode = CreateConVar("sm_rtd_timebomb_mode", "2",	"The way Timebomb rolled as an RTD effect behaves: 0 = Target only; 1 = Target's Team; 2 = Everyone");
	c_timebomb_ticks 	= CreateConVar("sm_rtd_timebomb_ticks", "10.0", "Sets how long the RTD timebomb fuse is.", 0, true, 5.0, true, 120.0);
	c_timebomb_radius 	= CreateConVar("sm_rtd_timebomb_radius", "600", "Sets the RTD timebomb blast radius.", 0, true, 50.0, true, 3000.0);
	c_freezebomb_mode 	= CreateConVar("sm_rtd_freezebomb_mode", "2",	"The way Freezebomb rolled as an RTD effect behaves: 0 = Target only; 1 = Target's Team; 2 = Everyone");
	c_freezebomb_ticks 	= CreateConVar("sm_rtd_freezebomb_ticks", "10.0", "Sets how long the RTD freezebomb fuse is.", 0, true, 5.0, true, 120.0);
	c_freezebomb_radius = CreateConVar("sm_rtd_freezebomb_radius", "600", "Sets the RTD freezebomb blast radius.", 0, true, 50.0, true, 3000.0);
	c_freeze_duration 	= CreateConVar("sm_rtd_freeze_duration", "10.0", "Sets the default duration for RTD freezebomb victims", 0, true, 1.0, true, 120.0);
	c_firebomb_mode 	= CreateConVar("sm_rtd_firebomb_mode", "2",	"The way Firebomb rolled as an RTD effect behaves: 0 = Target only; 1 = Target's Team; 2 = Everyone");
	c_firebomb_ticks 	= CreateConVar("sm_rtd_firebomb_ticks", "10.0", "Sets how long the RTD FireBomb fuse is.", 0, true, 5.0, true, 120.0);
	c_firebomb_radius 	= CreateConVar("sm_rtd_firebomb_radius", "600", "Sets the RTD firebomb blast radius.", 0, true, 50.0, true, 3000.0);
	c_burn_duration	 	= CreateConVar("sm_rtd_burn_duration", "10.0", "Sets the duration of RTD firebomb victims.", 0, true, 0.5, true, 20.0);
	c_freezebullet_freeze_duration = CreateConVar("sm_rtd_freezebullet_duration", "2.0", "Sets the duration of freeze for freezebullet victims.", 0, true, 0.5, true, 20.0);
	

	durationFloat 			= GetConVarFloat(c_Duration);
	durationInt		 		= GetConVarInt(c_Duration);
	rtd_timebomb_mode 		= GetConVarInt(c_timebomb_mode);
	rtd_timebomb_radius 	= GetConVarFloat(c_timebomb_radius);
	rtd_timebomb_ticks 		= GetConVarFloat(c_timebomb_ticks);
	rtd_freezebomb_mode 	= GetConVarInt(c_freezebomb_mode);
	rtd_freezebomb_radius 	= GetConVarFloat(c_freezebomb_radius);
	rtd_freezebomb_ticks 	= GetConVarFloat(c_freezebomb_ticks);
	rtd_freeze_duration 	= GetConVarFloat(c_freeze_duration);
	rtd_firebomb_mode 		= GetConVarInt(c_firebomb_mode);
	rtd_firebomb_radius 	= GetConVarFloat(c_firebomb_radius);
	rtd_firebomb_ticks 		= GetConVarFloat(c_firebomb_ticks);
	rtd_burn_duration 		= GetConVarFloat(c_burn_duration);
	freezebullet_duration	= GetConVarFloat(c_freezebullet_freeze_duration);
	
	c_Trigger   = CreateConVar("sm_rtd_trigger",   "rtd,rollthedice,roll", "All the chat triggers - Seperated by commas.");

	RegConsoleCmd("say", Command_rtd);
	RegConsoleCmd("say_team", Command_rtd);
	RegAdminCmd("sm_forcertd", Command_ForceRTD, ADMFLAG_GENERIC);
	RegAdminCmd("sm_randomrtd", Command_RandomRTD, ADMFLAG_GENERIC);
	
	HookEvent("teamplay_round_active", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	for(new i=0; i<MAXPLAYERS+1; i++)
	{
		PlayerTimers[i][0] = INVALID_HANDLE;
		PlayerTimers[i][1] = INVALID_HANDLE;
	}
	
	if (loaded)
	{
		ResetStatus();
	}
	
	if (c_LogEnabled)
	{
		Stats_Init();
	}
	
	g_cloakOffset = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");
//	g_wearableOffset = FindSendPropInfo("CTFWearableItem", "m_hOwnerEntity");
//	g_shieldOffset = FindSendPropInfo("CTFWearableItemDemoShield", "m_hOwnerEntity");
	
	LoadTranslations("rtd.phrases.txt");
}

public OnConfigsExecuted()
{	
	PrintToServer("[RTD] %T", "Server_Loaded", LANG_SERVER, PLUGIN_VERSION);
	PrintToServer("[RTD] FL_NOTARGET Value: %s %i %f",FL_NOTARGET,FL_NOTARGET,FL_NOTARGET);

	HookConVarChange(c_Disabled, ConVarChange_Disable);
	new String:strDisable[200];
	GetConVarString(c_Disabled, strDisable, sizeof(strDisable));
	Parse_Disabled_Commands(strDisable);
	
	CheckForInstantRespawn();
	
	new Handle:hEnabled = FindConVar("sm_respawn_time_enabled");
	new Handle:hRed = FindConVar("sm_respawn_time_red");
	new Handle:hBlue = FindConVar("sm_respawn_time_blue");
	
	if(hEnabled != INVALID_HANDLE)
		HookConVarChange(FindConVar("sm_respawn_time_enabled"), ConVarChange_RespawnEnabled);
	
	if(hRed != INVALID_HANDLE)
		HookConVarChange(FindConVar("sm_respawn_time_red"), ConVarChange_RespawnRed);
	
	if(hBlue != INVALID_HANDLE)
		HookConVarChange(FindConVar("sm_respawn_time_blue"), ConVarChange_RespawnBlue);
	
	HookConVarChange(c_Trigger, ConVarChange_Trigger);
	HookConVarChange(c_LogEnabled, ConVarChange_LogEnabled);
	new String:strTrig[200];
	GetConVarString(c_Trigger, strTrig, sizeof(strTrig));
	Parse_Chat_Triggers(strTrig);
	
	ResetStatus();
}

public OnAllPluginsLoaded()
{
	orig_timebomb_mode		= GetConVarInt(FindConVar("sm_timebomb_mode"));
	orig_timebomb_radius	= GetConVarFloat(FindConVar("sm_timebomb_radius"));
	orig_timebomb_ticks		= GetConVarFloat(FindConVar("sm_timebomb_ticks"));	
	orig_freezebomb_mode	= GetConVarInt(FindConVar("sm_freezebomb_mode"));
	orig_freezebomb_radius	= GetConVarFloat(FindConVar("sm_freezebomb_radius"));
	orig_freezebomb_ticks	= GetConVarFloat(FindConVar("sm_freezebomb_ticks"));
	orig_freeze_duration	= GetConVarFloat(FindConVar("sm_freeze_duration"));
	orig_firebomb_mode		= GetConVarInt(FindConVar("sm_firebomb_mode"));
	orig_firebomb_radius	= GetConVarFloat(FindConVar("sm_firebomb_radius"));
	orig_firebomb_ticks		= GetConVarFloat(FindConVar("sm_firebomb_ticks"));
	orig_burn_duration		= GetConVarFloat(FindConVar("sm_burn_duration"));	
	loaded = true;
}

public ConVarChange_Trigger(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Parse_Chat_Triggers(newValue);
	PrintToChatAll("[RTD] Chat triggers reparsed.");
}

public ConVarChange_RespawnEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{			
	if(StringToInt(newValue) == 0)
	{
		g_instantBlu = false;
		g_instantRed = false;
	}
}

public ConVarChange_RespawnRed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToFloat(newValue) == 0.0)
	{
		g_instantRed = true;
	}
	else
	{
		g_instantRed = false;
	}
}

public ConVarChange_RespawnBlue(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToFloat(newValue) == 0.0)
	{
		g_instantBlu = true;
	}
	else
	{
		g_instantBlu = false;
	}
}

public ConVarChange_Disable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Parse_Disabled_Commands(newValue);
	PrintToChatAll("[RTD] RTD Disabled commands reparsed.");
}

public ConVarChange_LogEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 1)
	{
		Stats_Init();
	}
}

public OnMapStart()
{
	ResetStatus();
}

public Action:Command_ForceRTD(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[RTD] sm_forcertd <target>");
		return Plugin_Handled;
	}
	
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		ForceRTD(target_list[i]);
	}
	
	return Plugin_Handled;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(GetConVarInt(c_Enabled))
		PrintToChatAll("%c[RTD]%c %T", cGreen, cDefault, "Announcement_Message", LANG_SERVER, cGreen, cDefault);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(c_Enabled))
	{	
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
			// Make sure player does not have Sentry Immunity on spawn
		new flags = GetEntityFlags(client)&~FL_NOTARGET;
		//SetEntProp(client, Prop_Data, "m_fFlags", flags);
		SetEntityFlags(client, flags);

		if(TrackPlayers[client][PLAYER_FLAG])
		{
			new userid = GetEventInt(event, "userid");
			
			switch(TrackPlayers[client][PLAYER_FLAG])
			{
				case AWARD_B_BEACON:
				{
					ServerCommand("sm_beacon #%d", userid);
				}
				case AWARD_B_DRUG:
				{
					ServerCommand("sm_drug #%d", userid);
				}
				case AWARD_B_FREEZE:
				{
					ServerCommand("sm_freeze #%d", userid);
				}
				case AWARD_B_TIMEBOMB:
				{
					ServerCommand("sm_timebomb_mode %i", rtd_timebomb_mode);
					ServerCommand("sm_timebomb_radius %f", rtd_timebomb_radius);
					ServerCommand("sm_timebomb_ticks %f", rtd_timebomb_ticks);					
					ServerCommand("sm_timebomb #%d", userid);
				}
				case AWARD_B_FREEZEBOMB:
				{
					ServerCommand("sm_freezebomb_mode %i", rtd_freezebomb_mode);
					ServerCommand("sm_freezebomb_radius %f", rtd_freezebomb_radius);
					ServerCommand("sm_freezebomb_ticks %f", rtd_freezebomb_ticks);	
					ServerCommand("sm_freeze_duration %f", rtd_freeze_duration);
					ServerCommand("sm_freezebomb #%d", userid);
				}
				case AWARD_B_FIREBOMB:
				{
					ServerCommand("sm_firebomb_mode %i",rtd_firebomb_mode);
					ServerCommand("sm_firebomb_radius %f", rtd_firebomb_radius);
					ServerCommand("sm_firebomb_ticks %f", rtd_firebomb_ticks);	
					ServerCommand("sm_burn_duration %f", rtd_burn_duration);					
					ServerCommand("sm_firebomb #%d", userid);
				}
			}
			
			TrackPlayers[client][PLAYER_FLAG] = 0;
		}
	}
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victimId = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!TrackPlayers[attackerId][PLAYER_STATUS]) return Plugin_Continue;
	
	// If player has instant kills
	if(TrackPlayers[attackerId][PLAYER_EFFECT] == AWARD_G_INSTANTKILL + DIRTY_HACK)
	{
		if(attackerId == victimId) return Plugin_Continue;
		
		// Uber exception
		if(victimId <= 0 || victimId > MaxClients || GetEntProp(victimId, Prop_Send, "m_nPlayerCond") & 32) return Plugin_Continue;
		
		new iHealth = GetEventInt(event, "health");
		
		// Make sure we don't kill them twice
		if(iHealth > 0)
		{			
			SetEntProp(victimId, Prop_Data, "m_iHealth", 0);
		}
		
		PrintToChat(victimId, "%c[RTD]%c %T", cGreen, cDefault, "Instantkill_Notify", LANG_SERVER, cGreen, attackerId, cDefault);
	}
	
	// If player has rubber bullets
	if(TrackPlayers[attackerId][PLAYER_EFFECT] == AWARD_G_RUBBERBULLET + DIRTY_HACK)
	{
		if (attackerId == victimId) return Plugin_Continue;
		
		new Float:aang[3], Float:vvel[3], Float:pvec[3];
			
		// Knockback
		GetClientAbsAngles(attackerId, aang);
		GetEntPropVector(victimId, Prop_Data, "m_vecVelocity", vvel);
			
		if (attackerId == victimId) 
		{
			vvel[2] += 1000.0;
		}
		else 
		{
			GetAngleVectors(aang, pvec, NULL_VECTOR, NULL_VECTOR);
			vvel[0] += pvec[0] * 300.0;
			vvel[1] += pvec[1] * 300.0;
			vvel[2] = 500.0;
		}
			
		TeleportEntity(victimId, NULL_VECTOR, NULL_VECTOR, vvel);
	}
	
		// If player has fire bullets
	if(TrackPlayers[attackerId][PLAYER_EFFECT] == AWARD_G_FIREBULLET + DIRTY_HACK)
	{
		if(attackerId == victimId) return Plugin_Continue;
		
		TF2_IgnitePlayer(victimId, attackerId);
	}
	
			// If player has freeze bullets
	if(TrackPlayers[attackerId][PLAYER_EFFECT] == AWARD_G_FREEZEBULLET + DIRTY_HACK)
	{
		if(attackerId == victimId) return Plugin_Continue;
		
		ServerCommand("sm_freeze #%d %d", GetClientUserId(victimId), freezebullet_duration);
	}
	
	return Plugin_Continue;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
		if(!TrackPlayers[client][PLAYER_STATUS]) return Plugin_Continue;
		
		if(TrackPlayers[client][PLAYER_EFFECT] == (AWARD_G_CRITS + DIRTY_HACK))
		{
			result = true;
			return Plugin_Handled;
		}
		
		if(TrackPlayers[client][PLAYER_EFFECT] == (AWARD_B_NOCRIT))
		{
			result = false;
			return Plugin_Handled;
		}

		return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new death_ringer = GetEventInt(event, "death_flags");
	if(death_ringer & 32) return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!TrackPlayers[client][PLAYER_STATUS]) return Plugin_Continue;
	
	// Code that is needed to reverse RTD effects on DEATH
	if(TrackPlayers[client][PLAYER_EFFECT] >= DIRTY_HACK)
	{
		TrackPlayers[client][PLAYER_EFFECT] -= DIRTY_HACK;
		
		switch(TrackPlayers[client][PLAYER_EFFECT])
		{
			case AWARD_G_LOWGRAVITY:
			{
				SetEntityGravity(client, 1.0);
			}
			case AWARD_G_INVIS:
			{
				Colorize(client, NORMAL);
			}
			case AWARD_G_TOXIC:
			{
				Colorize(client, NORMAL);
			}
			case AWARD_G_GODMODE:
			{
				Colorize(client, NORMAL);
			}
			case AWARD_G_INSTANTKILL:
			{
				Colorize(client, NORMAL);
			}
			case AWARD_G_HOMING:
			{
				SidewinderTrackChance(client, 0);
				SidewinderSentryCritChance(client, 0);
				SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows | NormalFlares | NormalPipes | NormalSyringe, true);
			}
			case AWARD_G_SENTRY:
			{
				PrintCenterText(client," ");
				if(IsValidEntity(TrackPlayers[client][PLAYER_EXTRA]))
				{
					DestroyBuilding(TrackPlayers[client][PLAYER_EXTRA]);
					if(IsClientInGame(client))  
					{
						TrackPlayers[client][PLAYER_EXTRA] = 0;
						TrackPlayers[client][PLAYER_WEAPONS] = c_NumSentries;
					}
				}
			}
		}
	}
	else
	{		
		switch(TrackPlayers[client][PLAYER_EFFECT])
		{
			case AWARD_B_HIGHGRAVITY:
			{
				SetEntityGravity(client, 1.0);
			}
		}
		
		// Special respawn case for servers running instant respawn @ 0.0
		// By this time, the players are already dead, so we need to toggle
		// the effects when they spawn again. Set a flag here.
		if((g_instantBlu && (GetClientTeam(client) == BLUE_TEAM)) || (g_instantRed && (GetClientTeam(client) == RED_TEAM)))
		{
			switch(TrackPlayers[client][PLAYER_EFFECT])
			{
				case AWARD_B_BEACON:
				{
					TrackPlayers[client][PLAYER_FLAG] = AWARD_B_BEACON;
				}
				case AWARD_B_DRUG:
				{
					TrackPlayers[client][PLAYER_FLAG] = AWARD_B_DRUG;
				}
				case AWARD_B_FREEZE:
				{
					TrackPlayers[client][PLAYER_FLAG] = AWARD_B_FREEZE;
				}
				case AWARD_B_TIMEBOMB:
				{
					TrackPlayers[client][PLAYER_FLAG] = AWARD_B_TIMEBOMB;
				}
				case AWARD_B_FREEZEBOMB:
				{
					TrackPlayers[client][PLAYER_FLAG] = AWARD_B_FREEZEBOMB;
				}	
				case AWARD_B_FIREBOMB:
				{
					TrackPlayers[client][PLAYER_FLAG] = AWARD_B_FIREBOMB;
				}
			}
		}
	}	
	
	CleanPlayer(client);
	TrackPlayers[client][PLAYER_TIMESTAMP] = GetTime();
	
	decl String:message[200];
	Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Player_Died", LANG_SERVER, cLightGreen, client, cDefault);

	SayText2(client, message);
	
	return Plugin_Continue;
}

public Parse_Chat_Triggers(const String:strTriggers[])
{
	g_iTriggers = ExplodeString(strTriggers, ",", chatTriggers, MAX_CHAT_TRIGGERS, MAX_CHAT_TRIGGER_LENGTH);
}

public Parse_Disabled_Commands(const String:strDisabled[])
{
	for(new i=0; i<MAX_BAD_AWARDS; i++)
		Disabled_Bad_Commands[i] = 0;
	
	for(new i=0; i<MAX_GOOD_AWARDS; i++)
		Disabled_Good_Commands[i] = 0;
	
	if(StrContains(strDisabled, "godmode") >= 0) 		Disabled_Good_Commands[AWARD_G_GODMODE] = 1;
	if(StrContains(strDisabled, "toxic") >= 0) 			Disabled_Good_Commands[AWARD_G_TOXIC] = 1;
	if(StrContains(strDisabled, "goodhealth") >= 0) 	Disabled_Good_Commands[AWARD_G_HEALTH] = 1;
	if(StrContains(strDisabled, "speed") >= 0) 			Disabled_Good_Commands[AWARD_G_SPEED] = 1;
	if(StrContains(strDisabled, "noclip") >= 0) 		Disabled_Good_Commands[AWARD_G_NOCLIP] = 1;
	if(StrContains(strDisabled, "lowgravity") >= 0)		Disabled_Good_Commands[AWARD_G_LOWGRAVITY] = 1;
	if(StrContains(strDisabled, "uber") >= 0) 			Disabled_Good_Commands[AWARD_G_UBER] = 1;
	if(StrContains(strDisabled, "invis") >= 0) 			Disabled_Good_Commands[AWARD_G_INVIS] = 1;
	if(StrContains(strDisabled, "instantkill") >= 0)	Disabled_Good_Commands[AWARD_G_INSTANTKILL] = 1;
	if(StrContains(strDisabled, "cloak") >= 0) 			Disabled_Good_Commands[AWARD_G_CLOAK] = 1;
	if(StrContains(strDisabled, "crits") >= 0) 			Disabled_Good_Commands[AWARD_G_CRITS] = 1;
	if(StrContains(strDisabled, "powerplay") >= 0) 		Disabled_Good_Commands[AWARD_G_POWERPLAY] = 1;
	if(StrContains(strDisabled, "minicrits") >= 0) 		Disabled_Good_Commands[AWARD_G_MINICRITS] = 1;
	if(StrContains(strDisabled, "homing") >= 0) 		Disabled_Good_Commands[AWARD_G_HOMING] = 1;
	if(StrContains(strDisabled, "sentry") >= 0) 		Disabled_Good_Commands[AWARD_G_SENTRY] = 1;
	if(StrContains(strDisabled, "rubberbullets") >= 0) 	Disabled_Good_Commands[AWARD_G_RUBBERBULLET] = 1;
	if(StrContains(strDisabled, "valverockets") >= 0) 	Disabled_Good_Commands[AWARD_G_VALVEROCKETS] = 1;
	if(StrContains(strDisabled, "firebullets") >= 0) 	Disabled_Good_Commands[AWARD_G_FIREBULLET] = 1;
	if(StrContains(strDisabled, "freezebullets") >= 0) 	Disabled_Good_Commands[AWARD_G_FREEZEBULLET] = 1;
	if(StrContains(strDisabled, "horseman") >= 0) 		Disabled_Good_Commands[AWARD_G_HORSEMAN] = 1;
	
	
	if(StrContains(strDisabled, "explode") >= 0) 		Disabled_Bad_Commands[AWARD_B_EXPLODE] = 1;
	if(StrContains(strDisabled, "snail") >= 0) 			Disabled_Bad_Commands[AWARD_B_SNAIL] = 1;
	if(StrContains(strDisabled, "freeze") >= 0) 		Disabled_Bad_Commands[AWARD_B_FREEZE] = 1;
	if(StrContains(strDisabled, "timebomb") >= 0)		Disabled_Bad_Commands[AWARD_B_TIMEBOMB] = 1;
	if(StrContains(strDisabled, "ignite") >= 0) 		Disabled_Bad_Commands[AWARD_B_IGNITE] = 1;
	if(StrContains(strDisabled, "badhealth") >= 0) 		Disabled_Bad_Commands[AWARD_B_HEALTH] = 1;
	if(StrContains(strDisabled, "drug") >= 0) 			Disabled_Bad_Commands[AWARD_B_DRUG] = 1;
	if(StrContains(strDisabled, "blind") >= 0) 			Disabled_Bad_Commands[AWARD_B_BLIND] = 1;
	if(StrContains(strDisabled, "weapons") >= 0) 		Disabled_Bad_Commands[AWARD_B_WEAPONS] = 1;
	if(StrContains(strDisabled, "beacon") >= 0) 		Disabled_Bad_Commands[AWARD_B_BEACON] = 1;
	if(StrContains(strDisabled, "taunt") >= 0) 			Disabled_Bad_Commands[AWARD_B_TAUNT] = 1;
	if(StrContains(strDisabled, "jarate") >= 0) 		Disabled_Bad_Commands[AWARD_B_JARATE] = 1;
	if(StrContains(strDisabled, "bonk") >= 0) 			Disabled_Bad_Commands[AWARD_B_BONK] = 1;
	if(StrContains(strDisabled, "scared") >= 0) 		Disabled_Bad_Commands[AWARD_B_SCARED] = 1;
	if(StrContains(strDisabled, "bleed") >= 0) 			Disabled_Bad_Commands[AWARD_B_BLEED] = 1;
	if(StrContains(strDisabled, "highgravity") >= 0) 	Disabled_Bad_Commands[AWARD_B_HIGHGRAVITY] = 1;
	if(StrContains(strDisabled, "freezebomb") >= 0) 	Disabled_Bad_Commands[AWARD_B_FREEZEBOMB] = 1;
	if(StrContains(strDisabled, "firebomb") >= 0) 		Disabled_Bad_Commands[AWARD_B_FIREBOMB] = 1;
	if(StrContains(strDisabled, "nocrits") >= 0) 		Disabled_Bad_Commands[AWARD_B_NOCRIT] = 1;
	
	new goodCounter, badCounter;
	
	for(new i=0; i<MAX_GOOD_AWARDS; i++)
		if(Disabled_Good_Commands[i]) goodCounter++;
	
	for(new i=0; i<MAX_BAD_AWARDS; i++)
		if(Disabled_Bad_Commands[i]) badCounter++;
		
	if(goodCounter >= MAX_GOOD_AWARDS || badCounter >= MAX_BAD_AWARDS)
	{
		PrintToServer("[RTD] %T", "Server_Disable_Message", LANG_SERVER);
		PrintToChatAll("[RTD] %T", "Server_Disable_Message", LANG_SERVER);
	}
}

public ResetStatus()
{
	for(new i=0; i<MAXPLAYERS+1; i++)
	{
		CleanPlayer(i);
		TrackPlayers[i][PLAYER_FLAG] = 0;
	}
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	SidewinderTrackChance(client, 0);
	SidewinderSentryCritChance(client, 0);
	SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows | NormalFlares | NormalPipes | NormalSyringe, true);
	CleanPlayer(client);
	TrackPlayers[client][PLAYER_FLAG] = 0;
	return true;
}

public OnClientDisconnect(client)
{	
	if(TrackPlayers[client][PLAYER_STATUS])
		PrintToChatAll("%c[RTD]%c %T", cGreen, cDefault, "Player_Disconnect", LANG_SERVER);
	
	CleanPlayer(client);
	TrackPlayers[client][PLAYER_FLAG] = 0;
	
	SidewinderTrackChance(client, 0);
	SidewinderSentryCritChance(client, 0);
	SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows | NormalFlares | NormalPipes | NormalSyringe, true);
}

public Action:Command_RandomRTD(client, args)
{
	new arrayPlayers[MaxClients];
	new index = 0;
	
	for(new i=1; i<MaxClients; i++)
	{
		if(IsClientConnected(i) && IsPlayerAlive(i) && !IsFakeClient(i) && !TrackPlayers[i][PLAYER_STATUS])
		{
			arrayPlayers[index] = i;
			index++;
		}
	}
	
	if(index > 0)
	{
		new victim = arrayPlayers[GetRandomInt(0, index-1)];
		
		if(ForceRTD(victim))
		{
			ReplyToCommand(client, "%c[RTD]%c %N was forced to roll", cGreen, cDefault, victim);
		}
		else
		{
			ReplyToCommand(client, "%c[RTD]%c Error occured.", cGreen, cDefault);
		}
	}
	else
	{
		ReplyToCommand(client, "%c[RTD]%c No one to target.", cGreen, cDefault);
	}
	
	return Plugin_Handled;
}

stock bool:ForceRTD(client)
{
	// Check to see if client is valid
	if(client <= 0 || !IsClientConnected(client)) return false;	
	
	// Check to see if the person is already rtd'ing
	if(TrackPlayers[client][PLAYER_STATUS])	return false;
	
	if(!IsPlayerAlive(client)) return false;
	
	new bool:success = RollTheDice(client);
	
	if(!success)
		return false;
	
	return true;
}

public Action:Command_rtd(client, args)
{
	// Check to see if client is valid
	if(client <= 0 || !IsClientInGame(client) || !GetConVarInt(c_Enabled)) return Plugin_Continue;
	
	// Check the admin flag cvar
	decl String:strFlags[20];
	GetConVarString(c_Admin, strFlags, sizeof(strFlags));
	if(strlen(strFlags) > 0)
	{
		if(!CheckAdminFlagsByString(client, strFlags))
			return Plugin_Continue;
	}
	
	decl String:strMessage[128];
	GetCmdArgString(strMessage, sizeof(strMessage));
	
	// Check for chat triggers
	new startidx = 0;
	if(strMessage[0] == '"')
	{
		startidx = 1;
		new len = strlen(strMessage);
		
		if(strMessage[len-1] == '"') strMessage[len-1] = '\0';
	}
	
	new bool:cond = false;
	for(new i=0; i<g_iTriggers; i++)
	{
		if(StrEqual(chatTriggers[i], strMessage[startidx], false))
		{
			cond = true;
			continue;
		}
	}
	
	if(StrEqual("!rtd", strMessage[startidx], false)) cond = true;
	
	if(!cond) return Plugin_Continue;
	
	// Check to see if the person is already rtd'ing
	if(TrackPlayers[client][PLAYER_STATUS])
	{
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Already", LANG_SERVER);
		return Plugin_Handled;
	}
	
	// Check to see if the person has waited long enough
	new timeleft = GetTime() - TrackPlayers[client][PLAYER_TIMESTAMP];
	if(TrackPlayers[client][PLAYER_TIMESTAMP] > 0 && timeleft < GetConVarInt(c_Timelimit))
	{
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Wait", LANG_SERVER, cGreen, (GetConVarInt(c_Timelimit)-timeleft), cDefault);
		return Plugin_Handled;
	}
	
	// Check to see if the player is still alive
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Alive", LANG_SERVER);
		return Plugin_Handled;
	}
	
	switch(GetConVarInt(c_Mode))
	{
		// Only one player can rtd at a time
		case 1:
			for(new i=1; i<MAXPLAYERS+1; i++)
			{
				if(TrackPlayers[i][PLAYER_STATUS])
				{
					decl String:message[200];
					Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Player_Occupied_Mode1", LANG_SERVER, cLightGreen, i, cDefault);
					
					// Another player is rtd'ing
					SayText2One(client, i, message);
					return Plugin_Handled;
				}
			}
		
		// Verify that only X ammount of players on a team can rtd
		case 2:
		{
			new counter;
			for(new i=1; i<MAXPLAYERS+1; i++)
			{
				if(TrackPlayers[i][PLAYER_STATUS])
				{
					if(GetClientTeam(i)==GetClientTeam(client))
						counter++;
				}
			}
			
			if(counter >= GetConVarInt(c_Teamlimit))
			{
				PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Occupied_Mode2", LANG_SERVER);
				return Plugin_Handled;
			}
		}
	}
	
	// Player has passed all the checks
	new bool:success = RollTheDice(client);
	
	if(!success)
	{
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Disable_Overload", LANG_SERVER);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

bool:RollTheDice(client)
{
	new bool:goodCommand = false;
	
	new Float:fChance = GetConVarFloat(c_Chance);
	// Check the admin flag cvar
	decl String:strFlags[20];
	GetConVarString(c_Donator, strFlags, sizeof(strFlags));
	if(strlen(strFlags) > 0)
	{
		if(CheckAdminFlagsByString(client, strFlags))
			fChance = GetConVarFloat(c_DonatorChance);
	}
	//if(fChance > GetRandomFloat(0.0, 1.0)) goodCommand = true;
	if(fChance > Math_GetRandomFloat(0.0, 1.0)) goodCommand = true;
	
	new bound;
	if(goodCommand) bound = MAX_GOOD_AWARDS; else bound = MAX_BAD_AWARDS;
	
	//new bool:foundAward = false;
	new bool:foundAward = true;
	new maxRetries = bound;						// We will retry a max number of times equal to the number of awards available
	new currentTry = 0;
	
	new award = Math_GetRandomInt(0, bound-1);
	
	while (UnAcceptable(client, goodCommand, award))
	{
		currentTry++;
		if (currentTry >= maxRetries)
		{
			foundAward = false;
			break;
		}
		award = Math_GetRandomInt(0, bound-1);
	}
	// Give up
	if(!foundAward)
	{
		return false;
	}
	
	GivePlayerEffect(client, goodCommand, award);
	return true;
}

public bool:UnAcceptable(client, bool:goodCommand, award)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(goodCommand)
	{
		if(Disabled_Good_Commands[award]) return true;		
		
		if(award == AWARD_G_UBER && class != TFClass_Medic) return true;
		if(award == AWARD_G_CLOAK && class != TFClass_Spy) return true;	
		if(award == AWARD_G_SPEED && (class == TFClass_Heavy || class == TFClass_Sniper)) return true;
		if(award == AWARD_G_HOMING && (class == TFClass_Scout || class == TFClass_Heavy || class == TFClass_Spy || class == TFClass_Engineer)) return true;
		if(award == AWARD_G_SENTRY && (class != TFClass_Engineer)) return true;
	}
	else
	{ // Bad Command
		if(Disabled_Bad_Commands[award]) return true;
		
		if(award == AWARD_B_SNAIL && (class == TFClass_Heavy || class == TFClass_Sniper)) return true;
	}
	
	return false;
}

public GivePlayerEffect(client, bool:goodCommand, award)
{
	decl String:message[200];
	
	ResetTimers(client);
	
	// MASSIVE SWITCH STATEMENT
	if(goodCommand)
	{
		switch(award)
		{
			case AWARD_G_GODMODE:
			{
				// Setup the proper translation message				
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Godmode_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				// Enable Godmode
				SetGodmode(client, true);
				Colorize(client, BLACK);
				
				// Mark that the player is rtd'ing
				TrackPlayers[client][PLAYER_STATUS] = 1;
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				
				// Setup the timer
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);	
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_TOXIC:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Toxic_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);

				// Make the toxic player black
				Colorize(client, BLACK);

				TrackPlayers[client][PLAYER_STATUS] = 1;

				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);	
				PlayerTimers[client][1] = CreateTimer(0.5, Timer_Toxic, client, TIMER_REPEAT);
			}
			case AWARD_G_HEALTH:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Good_Health_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				SetEntProp(client, Prop_Data, "m_iHealth", GetConVarInt(c_Health));

				CreateParticle("healhuff_red", 5.0, client);
				CreateParticle("healhuff_blu", 5.0, client);
			}
			case AWARD_G_SPEED:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Speed_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TrackPlayers[client][PLAYER_EXTRA] = RoundToFloor(GetEntPropFloat(client, Prop_Send, "m_flMaxspeed"));
				SetEntDataFloat(client, FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), 400.0);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_G_NOCLIP:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Noclip_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
				
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_LOWGRAVITY:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "LowGravity_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				SetEntityGravity(client, GetConVarFloat(c_LowGravity));
				
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);				
			}
			case AWARD_G_UBER:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Uber_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TF_SetUberLevel(client, 100);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Uber, client, TIMER_REPEAT);
			}
			case AWARD_G_INVIS:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Invis_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				Colorize(client, INVIS);
				
				new flags = GetEntityFlags(client)|FL_NOTARGET;
				//SetEntProp(client, Prop_Data, "m_fFlags", flags);
				SetEntityFlags(client, flags);
				
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_INSTANTKILL:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Instantkill_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				Colorize(client, BLACK);
				
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_CLOAK:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Cloak_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TF_SetCloak(client, 100.0);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Cloak, client, TIMER_REPEAT);
			}
			case AWARD_G_CRITS:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Crits_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_POWERPLAY:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "PowerPlay_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TF2_SetPlayerPowerPlay(client, true);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_MINICRITS:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "MiniCrit_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TF2_AddCondition(client, TFCond_Buffed, durationFloat);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}	
			case AWARD_G_SENTRY:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Sentry_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				//TrackPlayers[client][PLAYER_EXTRA] = 0;
				TrackPlayers[client][PLAYER_SENTRY_COUNT] = c_NumSentries;
				PrintToServer("Player Sentry Count: %i", TrackPlayers[client][PLAYER_SENTRY_COUNT]);
				
				//PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_DestroySentry, client, TIMER_REPEAT);
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(0.1, Timer_BuildSentry, client, TIMER_REPEAT); 
			}
			case AWARD_G_HOMING:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Homing_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				TrackPlayers[client][PLAYER_EXTRA] = 0;
				
				new TFClassType:class = TF2_GetPlayerClass(client);
				
				if (class == TFClass_Pyro)										// Check if Pyro 
				{
					new weapon_index = GetPlayerWeaponSlot(client, 1);
					TrackPlayers[client][PLAYER_WEAPONS] = -1;
					if(weapon_index != -1)
					{
						TrackPlayers[client][PLAYER_WEAPONS] = GetEntProp(weapon_index, Prop_Send,  "m_iItemDefinitionIndex");
					}
				
					TF2Items_GiveWeapon(client, 39);
				}
				if (class == TFClass_Sniper)										// Check if Pyro 
				{
					new weapon_index = GetPlayerWeaponSlot(client, 1);
					TrackPlayers[client][PLAYER_WEAPONS] = -1;
					if(weapon_index != -1)
					{
						TrackPlayers[client][PLAYER_WEAPONS] = GetEntProp(weapon_index, Prop_Send,  "m_iItemDefinitionIndex");
					}
				
					TF2Items_GiveWeapon(client, 56);
				}
								
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(0.3, Timer_StartHoming, client, TIMER_REPEAT); 
			}
			case AWARD_G_RUBBERBULLET:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "RubberBullet_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_VALVEROCKETS:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "ValveRocket_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				
				new weapon_index = GetPlayerWeaponSlot(client, 0);
				TrackPlayers[client][PLAYER_WEAPONS] = -1;
				if(weapon_index != -1)
				{
					TrackPlayers[client][PLAYER_WEAPONS] = GetEntProp(weapon_index, Prop_Send,  "m_iItemDefinitionIndex");
				}
				
				TF2Items_GiveWeapon(client, 9205);
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_FIREBULLET:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "FireBullet_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_FREEZEBULLET:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "FreezeBullet_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}			
			case AWARD_G_HORSEMAN:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Horseman_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				ServerCommand("sm_behhh #%d %d", GetClientUserId(client), durationInt);
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);			
			}
		}
		award += DIRTY_HACK; // dirty workaround - oh well
	}
	else
	{ // Bad Command
		switch(award)
		{
			case AWARD_B_EXPLODE:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Explode_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				FakeClientCommand(client, "explode");
			}
			case AWARD_B_SNAIL:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Snail_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TrackPlayers[client][PLAYER_EXTRA] = RoundToFloor(GetEntPropFloat(client, Prop_Send, "m_flMaxspeed"));
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(c_Snail));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_FREEZE:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Freeze_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				ServerCommand("sm_freeze #%d %d", GetClientUserId(client), durationInt);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_TIMEBOMB:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Timebomb_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				ServerCommand("sm_timebomb_mode %i",rtd_timebomb_mode);
				ServerCommand("sm_timebomb_radius %f", rtd_timebomb_radius);
				ServerCommand("sm_timebomb_ticks %f", rtd_timebomb_ticks);		
				ServerCommand("sm_timebomb #%d", GetClientUserId(client));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][1] = CreateTimer(durationFloat-0.5, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_IGNITE:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Ignite_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				TF2_IgnitePlayer(client, client);
			}
			case AWARD_B_HEALTH:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Bad_Health_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				SetEntProp(client, Prop_Data, "m_iHealth", 1);
			}
			case AWARD_B_DRUG:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Drug_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);

				ServerCommand("sm_drug #%d 1", GetClientUserId(client));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_BLIND:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Blind_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				ServerCommand("sm_blind #%d 255", GetClientUserId(client));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_WEAPONS:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Weapons_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				StripToMelee(client);
			}
			case AWARD_B_BEACON:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Beacon_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				ServerCommand("sm_beacon #%d", GetClientUserId(client));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_TAUNT:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Taunt_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				ClientCommand(client, "taunt");
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(0.5, Timer_Taunt, client, TIMER_REPEAT);
			}
			case AWARD_B_JARATE:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Jarate_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TF2_AddCondition(client, TFCond_Jarated, durationFloat);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}	
			case AWARD_B_BONK:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Bonk_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TF2_StunPlayer(client, durationFloat, _, TF_STUNFLAGS_BIGBONK);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}		
			case AWARD_B_SCARED:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Scared_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TF2_StunPlayer(client, durationFloat, 0.85, TF_STUNFLAGS_GHOSTSCARE);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}			
			case AWARD_B_BLEED:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Bleed_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TF2_MakeBleed(client, client, durationFloat);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_B_HIGHGRAVITY:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "HighGravity_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				SetEntityGravity(client, GetConVarFloat(c_HighGravity));
				
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);				
			}
			case AWARD_B_FREEZEBOMB:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Freezebomb_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				ServerCommand("sm_freezebomb_mode %i",rtd_freezebomb_mode);
				ServerCommand("sm_freezebomb_radius %f", rtd_freezebomb_radius);
				ServerCommand("sm_freezebomb_ticks %f", rtd_freezebomb_ticks);	
				ServerCommand("sm_freeze_duration %f", rtd_freeze_duration);
				ServerCommand("sm_freezebomb #%d", GetClientUserId(client));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][1] = CreateTimer(durationFloat-0.5, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_FIREBOMB:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Firebomb_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				ServerCommand("sm_firebomb_mode %i",rtd_firebomb_mode);
				ServerCommand("sm_firebomb_radius %f", rtd_firebomb_radius);
				ServerCommand("sm_firebomb_ticks %f", rtd_firebomb_ticks);	
				ServerCommand("sm_burn_duration %f", rtd_burn_duration);
				ServerCommand("sm_firebomb #%d", GetClientUserId(client));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][1] = CreateTimer(durationFloat-0.5, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}	
			case AWARD_B_NOCRIT:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "NoCrits_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, durationInt, cDefault);
				
				TrackPlayers[client][PLAYER_EXTRA] = durationInt;
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(durationFloat, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}			
		}
	}
	
		// Log this roll to the database
	if(IsClientInGame(client) && !IsFakeClient(client) && DatabaseIntact() && c_LogEnabled)
	{
		decl String:query[392], String:steamid[25], String:buffer[256], String:tbuffer[256], String:dbuffer[256], String:ebuffer[256], String:cbuffer[256], String:teamID[10], String:awardID[10], String:classID[10];
		new team = GetClientTeam(client);
		new String:disposition[1];
		if (goodCommand)
		{
			disposition = "1";		// 1 = Good Command
		}
		else
		{
			disposition = "0";
		}
		
		IntToString(team, teamID, sizeof(teamID));
		IntToString(award, awardID, sizeof(awardID));
		IntToString(_:TF2_GetPlayerClass(client), classID, sizeof(classID));
		
	
		GetClientAuthString(client,steamid, sizeof(steamid));
		SQL_EscapeString(g_StatsDB, steamid, buffer, sizeof(buffer));
		SQL_EscapeString(g_StatsDB, teamID, tbuffer, sizeof(tbuffer));
		SQL_EscapeString(g_StatsDB, disposition, dbuffer, sizeof(dbuffer));
		SQL_EscapeString(g_StatsDB, awardID, ebuffer, sizeof(ebuffer));
		SQL_EscapeString(g_StatsDB, classID, cbuffer, sizeof(cbuffer));

		Format(query, sizeof(query), "INSERT IGNORE INTO `rtd_log` (`steamid`, `rollTime`, `disposition`, `effectID`, `playerClass`, `teamID`) VALUES('%s', NOW(), '%s', '%s', '%s', '%s')", buffer, dbuffer, ebuffer, cbuffer, tbuffer);
		SQL_TQuery(g_StatsDB, T_ErrorOnly, query);
	}

	// Mark the effect that the player is using. Timer_RemovePlayerEffect will read this later
	TrackPlayers[client][PLAYER_EFFECT] = award;
	TrackPlayers[client][PLAYER_TIMESTAMP] = GetTime();
	
	SayText2(client, message);
	
	return;
}

public Action:Timer_RemovePlayerEffect(Handle:Timer, any:client)
{
	if(!IsClientInGame(client)) { PlayerTimers[client][0] = INVALID_HANDLE; return Plugin_Handled; }
	
	if(TrackPlayers[client][PLAYER_EFFECT] >= DIRTY_HACK) // Good command
	{
		TrackPlayers[client][PLAYER_EFFECT] -= DIRTY_HACK;

		switch(TrackPlayers[client][PLAYER_EFFECT])
		{
			case AWARD_G_GODMODE:
			{				
				// Disable Godmode
				SetGodmode(client, false);
				Colorize(client, NORMAL);
			}
			case AWARD_G_TOXIC:
			{
				// Return the player's color
				Colorize(client, NORMAL);
				// Toxic timer should be terminated below
			}
			case AWARD_G_NOCLIP:
			{
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
			case AWARD_G_LOWGRAVITY:
			{
				SetEntityGravity(client, 1.0);
			}
			case AWARD_G_INVIS:
			{
				Colorize(client, NORMAL);
				new flags = GetEntityFlags(client)&~FL_NOTARGET;
				//SetEntProp(client, Prop_Data, "m_fFlags", flags);
				SetEntityFlags(client, flags);
			}
			case AWARD_G_SPEED:
			{				
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", float(TrackPlayers[client][PLAYER_EXTRA]));
			}
			case AWARD_G_INSTANTKILL:
			{
				Colorize(client, NORMAL);
			}
			case AWARD_G_POWERPLAY:
			{
				TF2_SetPlayerPowerPlay(client, false);
			}
			case AWARD_G_HOMING:
			{
				SidewinderTrackChance(client, 0);
				SidewinderSentryCritChance(client, 0);
				SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows | NormalFlares | NormalPipes | NormalSyringe, true);	
				
				new TFClassType:class = TF2_GetPlayerClass(client);
				
				if (class == TFClass_Pyro)										// Check if Pyro and reset secondary weapon
				{
					TF2Items_GiveWeapon(client, TrackPlayers[client][PLAYER_WEAPONS]);
					TrackPlayers[client][PLAYER_WEAPONS] = -1;
				}
			}
			case AWARD_G_SENTRY:
			{
				PrintCenterText(client," ");
				if(IsValidEntity(TrackPlayers[client][PLAYER_EXTRA]))
				{
					DestroyBuilding(TrackPlayers[client][PLAYER_EXTRA]);
					if(IsClientInGame(client))  
					{
						TrackPlayers[client][PLAYER_EXTRA] = 0;
						TrackPlayers[client][PLAYER_WEAPONS] = c_NumSentries;
						PrintToServer("Player Sentry Reset to Count: %i", TrackPlayers[client][PLAYER_SENTRY_COUNT]);
					}
				}
			}
			case AWARD_G_VALVEROCKETS:
			{
				TF2Items_GiveWeapon(client, TrackPlayers[client][PLAYER_WEAPONS]);
				TrackPlayers[client][PLAYER_WEAPONS] = -1;
			}
			case AWARD_G_HORSEMAN:
			{
				FakeClientCommand(client, "explode");				
			}
		}
	}
	else
	{ // Bad Command
		switch(TrackPlayers[client][PLAYER_EFFECT])
		{
			case AWARD_B_SNAIL:
			{
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", float(TrackPlayers[client][PLAYER_EXTRA]));
			}
			case AWARD_B_BLIND:
			{
				ServerCommand("sm_blind #%d 0", GetClientUserId(client));
			}
			case AWARD_B_DRUG:
			{
				ServerCommand("sm_drug #%d", GetClientUserId(client));
			}
			case AWARD_B_BEACON:
			{
				ServerCommand("sm_beacon #%d", GetClientUserId(client));
			}
			case AWARD_B_HIGHGRAVITY:
			{
				SetEntityGravity(client, 1.0);
			}
		}
	}

	// Mark that the player is no longer rtd'ing
	TrackPlayers[client][PLAYER_STATUS] = 0;
	TrackPlayers[client][PLAYER_EFFECT] = 0;
	
	// Set a new timestamp
	TrackPlayers[client][PLAYER_TIMESTAMP] = GetTime();

	CheckSecondTimer(client);

	decl String:message[200];
	Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Effect_Off", LANG_SERVER, cLightGreen, client, cDefault);

	SayText2(client, message);
	
	PlayerTimers[client][0] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_Uber(Handle:timer, any:client)
{
	if(!TrackPlayers[client][PLAYER_STATUS] || TrackPlayers[client][PLAYER_EFFECT] != AWARD_G_UBER + DIRTY_HACK) return Plugin_Stop;
	
	TF_SetUberLevel(client, 100);
	
	return Plugin_Continue;
}

public Action:Timer_Cloak(Handle:timer, any:client)
{
	if(!TrackPlayers[client][PLAYER_STATUS] || TrackPlayers[client][PLAYER_EFFECT] != AWARD_G_CLOAK + DIRTY_HACK) return Plugin_Stop;
	
	TF_SetCloak(client, 100.0);
	
	return Plugin_Continue;
}

public Action:Timer_Countdown(Handle:timer, any:client)
{
	if(!TrackPlayers[client][PLAYER_STATUS]) return Plugin_Stop;
	
	TrackPlayers[client][PLAYER_EXTRA]--;
	
	PrintCenterText(client, "%i", TrackPlayers[client][PLAYER_EXTRA]);
	
	return Plugin_Continue;
}

public Action:Timer_Taunt(Handle:timer, any:client)
{
	if(!TrackPlayers[client][PLAYER_STATUS] || TrackPlayers[client][PLAYER_EFFECT] != AWARD_B_TAUNT) return Plugin_Stop;
	
	ClientCommand(client, "taunt");
	
	return Plugin_Continue;
}

public Action:Timer_Toxic(Handle:Timer, any:client)
{
	if(!TrackPlayers[client][PLAYER_STATUS] || TrackPlayers[client][PLAYER_EFFECT] != AWARD_G_TOXIC + DIRTY_HACK) return Plugin_Stop;
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	
	new team = GetClientTeam(client);
	
	for(new i=1; i<=MaxClients; i++)
	{
		// Check for a valid client
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		
		// Check to make sure the player is on the other team
		if(GetClientTeam(i) == team) continue;
		
		// Godmode/uber exception
		if(GetEntProp(i, Prop_Data, "m_takedamage", 1) == 0 || GetEntProp(i, Prop_Send, "m_nPlayerCond") & 32) continue;
		
		if(TrackPlayers[i][PLAYER_STATUS] && TrackPlayers[i][PLAYER_EFFECT] == AWARD_G_GODMODE + DIRTY_HACK) continue;
		
		new Float:pos[3];
		GetClientEyePosition(i, pos);
		
		new Float:distance = GetVectorDistance(vec, pos);
		
		if(distance < GetConVarFloat(c_Distance))
		{
			KillPlayer(i, client);
			PrintToChat(i, "%c[RTD]%c %T", cGreen, cDefault, "Toxic_Notify", LANG_SERVER, client);
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_StartHoming(Handle:timer, any:client)
{
	if(!TrackPlayers[client][PLAYER_STATUS] || TrackPlayers[client][PLAYER_EFFECT] != AWARD_G_HOMING + DIRTY_HACK) return Plugin_Stop;
	
	SidewinderTrackChance(client, 100);
	SidewinderSentryCritChance(client, 100);
	SidewinderFlags(client, TrackingSentryRockets | TrackingRockets | TrackingArrows | TrackingFlares | TrackingPipes | TrackingSyringe, true);
	
	return Plugin_Continue;
}

public CheckSecondTimer(client)
{
	// Check to see if the secondary timer is running
	if(PlayerTimers[client][1] != INVALID_HANDLE)
	{
		KillTimer(PlayerTimers[client][1]);
		PlayerTimers[client][1] = INVALID_HANDLE;
	}
	
	return;
}

public Colorize(client, color[4])
{	
	//Colorize the weapons
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	
	new String:classname[256];
	new type;
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
	
		if(weapon > -1 )
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			if((StrContains(classname, "tf_weapon_",false) >= 0))
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	//Colorize the wearables, such as hats
	SetWearablesRGBA_Impl( client, "tf_wearable", "CTFWearable",color );
	SetWearablesRGBA_Impl( client, "tf_wearable_demoshield", "CTFWearableDemoShield", color);
	
	//Colorize the player
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	if(color[3] > 0)
		type = 1;
	
	InvisibleHideFixes(client, class, type);
	return;
}

SetWearablesRGBA_Impl( client,  const String:entClass[], const String:serverClass[], color[4])
{
	new ent = -1;
	while( (ent = FindEntityByClassname(ent, entClass)) != -1 )
	{
		if ( IsValidEntity(ent) )
		{		
			if (GetEntDataEnt2(ent, FindSendPropOffs(serverClass, "m_hOwnerEntity")) == client)
			{
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, color[0], color[1], color[2], color[3]);
			}
		}
	}
}

InvisibleHideFixes(client, TFClassType:class, type)
{
	if(class == TFClass_DemoMan)
	{
		new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
		if(decapitations >= 1)
		{
			if(!type)
			{
				//Removes Glowing Eye
				TF2_RemoveCond(client, 18);
			}
			else
			{
				//Add Glowing Eye
				TF2_AddCond(client, 18);
			}
		}
	}
	else if(class == TFClass_Spy)
	{
		new disguiseWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
		if(IsValidEntity(disguiseWeapon))
		{
			if(!type)
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				new color[4] = INVIS;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
			else
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				new color[4] = NORMAL;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
		}
	}
}

stock TF2_AddCond(client, cond) 
{
	new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
	if(!enabled) {
		SetConVarFlags(cvar, flags^FCVAR_NOTIFY^FCVAR_REPLICATED);
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "addcond %i", cond);
	//FakeClientCommand(client, "isLoser");
	if(!enabled) 
	{
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
}

stock TF2_RemoveCond(client, cond) 
{
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
    if(!enabled) 
	{
        SetConVarFlags(cvar, flags^FCVAR_NOTIFY^FCVAR_REPLICATED);
        SetConVarBool(cvar, true);
    }
    FakeClientCommand(client, "removecond %i", cond);
    if(!enabled) {
        SetConVarBool(cvar, false);
        SetConVarFlags(cvar, flags);
    }
} 

public SetGodmode(client, bool:playerState)
{
	if(playerState)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}
	else
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	
	return;
}

public ResetTimers(client)
{
	if(PlayerTimers[client][0] != INVALID_HANDLE)
	{
		KillTimer(PlayerTimers[client][0]);
		PlayerTimers[client][0] = INVALID_HANDLE;
	}
	
	if(PlayerTimers[client][1] != INVALID_HANDLE)
	{
		KillTimer(PlayerTimers[client][1]);
		PlayerTimers[client][1] = INVALID_HANDLE;
	}
	
	return;
}

public CleanPlayer(client)
{
	TrackPlayers[client][PLAYER_STATUS] = 0;
	TrackPlayers[client][PLAYER_EXTRA] = 0;
	TrackPlayers[client][PLAYER_EFFECT] = 0;
	TrackPlayers[client][PLAYER_WEAPONS] = -1;
	TrackPlayers[client][PLAYER_SENTRY_COUNT] = 0;
	
	if((client > 0 && client < MaxClients) && IsClientInGame(client))
	{
		
		new flags = GetEntityFlags(client)&~FL_NOTARGET;
		//SetEntProp(client, Prop_Data, "m_fFlags", flags);
		SetEntityFlags(client, flags);
		
		if(loaded)
		{
				// Reset Original *bomb_mode values
			ServerCommand("sm_timebomb_mode %i",orig_timebomb_mode);
			ServerCommand("sm_timebomb_radius %f", orig_timebomb_radius);
			ServerCommand("sm_timebomb_ticks %f", orig_timebomb_ticks);	
			ServerCommand("sm_freezebomb_mode %i",orig_freezebomb_mode);
			ServerCommand("sm_freezebomb_radius %f", orig_freezebomb_radius);
			ServerCommand("sm_freezebomb_ticks %f", orig_freezebomb_ticks);	
			ServerCommand("sm_freeze_duration %f", orig_freeze_duration);					
			ServerCommand("sm_firebomb_mode %i",orig_firebomb_mode);
			ServerCommand("sm_firebomb_radius %f", orig_firebomb_radius);
			ServerCommand("sm_firebomb_ticks %f", orig_firebomb_ticks);	
			ServerCommand("sm_burn_duration %f", orig_burn_duration);
		}
		ResetTimers(client);
	}
	
	return;
}

stock SayText2(author_index , const String:message[] ) 
{
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE) 
	{
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

stock SayText2One( client_index , author_index , const String:message[] ) 
{
    new Handle:buffer = StartMessageOne("SayText2", client_index);
    if (buffer != INVALID_HANDLE) 
	{
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}  

StripToMelee(client) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client)) 
	{
		for(new i = 0; i <= 5; i++)
		{
			if(i != 2)
			{
				if(TF2_GetPlayerClass(client) != TFClass_Spy)
				{
					TF2_RemoveWeaponSlot(client, i);
				}
				else
				{
					if(i != 4)
					{
						TF2_RemoveWeaponSlot(client, i);
					}
				}
			}
		}
			
		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

CheckGame()
{
	new String:strGame[10];
	GetGameFolderName(strGame, sizeof(strGame));
	
	if(!StrEqual(strGame, "tf"))
	{
		SetFailState("[RTD] Detected game other than TF2. This plugin is only supported for TF2.");
	}
}

CheckForInstantRespawn()
{
	new Handle:enabled = FindConVar("sm_respawn_time_enabled");
	if(enabled == INVALID_HANDLE || GetConVarInt(enabled) <= 0) return;	
	
	new Handle:red = FindConVar("sm_respawn_time_red");
	new Handle:blu = FindConVar("sm_respawn_time_blue");
	
	if(red != INVALID_HANDLE)	
		if(GetConVarFloat(red) == 0.0)
			g_instantRed = true;
	
	if(blu != INVALID_HANDLE)
		if(GetConVarFloat(blu) == 0.0)
			g_instantBlu = true;
}

public Action:Timer_DeleteParticle(Handle:timer, any:iParticle)
{
	if(IsValidEdict(iParticle))
	{
		decl String:strClassname[50];
		GetEdictClassname(iParticle, strClassname, sizeof(strClassname));
		
		if(StrEqual(strClassname, "info_particle_system", false))
			RemoveEdict(iParticle);
	}
}

stock TF_SetUberLevel(client, uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}

stock TF_SetCloak(client, Float:cloaklevel)
{
	SetEntDataFloat(client, g_cloakOffset, cloaklevel);
}

stock CreateParticle(const String:strType[], Float:flTime, iEntity)
{
	new iParticle = CreateEntityByName("info_particle_system");
	
	if(!IsValidEdict(iParticle)) return;
	
	new Float:flPos[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
	TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(iParticle, "effect_name", strType);
	
	SetVariantString("!activator");
	AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);
	
	SetVariantString("head");
	AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);
	
	DispatchKeyValue(iParticle, "targetname", "particle");
	
	DispatchSpawn(iParticle);
	ActivateEntity(iParticle);
	AcceptEntityInput(iParticle, "Start");
	
	CreateTimer(flTime, Timer_DeleteParticle, iParticle);
}

KillPlayer(client, attacker)
{
	new ent = CreateEntityByName("env_explosion");
	
	if (IsValidEntity(ent))
	{
		DispatchKeyValue(ent, "iMagnitude", "1000");
		DispatchKeyValue(ent, "iRadiusOverride", "2");
		SetEntPropEnt(ent, Prop_Data, "m_hInflictor", attacker);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", attacker);
		DispatchKeyValue(ent, "spawnflags", "3964");
		DispatchSpawn(ent);
		
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(ent, "explode", client, client);
		CreateTimer(0.2, RemoveExplosion, ent);
	}
}

public Action:RemoveExplosion(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		new String:edictname[128];
		GetEdictClassname(ent, edictname, 128);
		if(StrEqual(edictname, "env_explosion"))
		{
			RemoveEdict(ent);
		}
	}
}

public OnGameFrame()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		
		if(TrackPlayers[i][PLAYER_STATUS])
		{
			if(TrackPlayers[i][PLAYER_EFFECT] == (AWARD_G_SPEED+DIRTY_HACK))
			{
				SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 400.0);
			}else if(TrackPlayers[i][PLAYER_EFFECT] == AWARD_B_SNAIL)
			{
				SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", GetConVarFloat(c_Snail));
			}
		}			
	}
}

/** - Credits to bl4nk -
 * Checks to see if a client has all of the specified admin flags
 *
 * @param client        Player's index.
 * @param flagString    String of flags to check for.
 * @return                True on admin having all flags, false otherwise.
 */
stock bool:CheckAdminFlagsByString(client, const String:flagString[])
{
    new AdminId:admin = GetUserAdmin(client);
    if (admin != INVALID_ADMIN_ID)
    {
        new count, found, flags = ReadFlagString(flagString);
        for(new i = 0; i <= 20; i++)
        {
            if(flags & (1<<i))
            {
                count++;

                if(GetAdminFlag(admin, AdminFlag:i))
                {
                    found++;
                }
            }
        }

        if(count == found)
        {
            return true;
        }
    }

    return false;
}

/**
 * Credit to -MCG-Retsam
 * Code from First Blood Rewards
 * http://forums.alliedmods.net/showthread.php?p=907628
 */

stock BuildSentry(iBuilder, Float:fOrigin[3], Float:fAngle[3], iLevel=1)
{
        new Float:fBuildMaxs[3];
        fBuildMaxs[0] = 24.0;
        fBuildMaxs[1] = 24.0;
        fBuildMaxs[2] = 66.0;
    
        new Float:fMdlWidth[3];
        fMdlWidth[0] = 1.0;
        fMdlWidth[1] = 0.5;
        fMdlWidth[2] = 0.0;
        
        new String:sModel[64];
        new iTeam = GetClientTeam(iBuilder);
        new iShells, iHealth, iRockets;
        
        if(iLevel == 1)
        {
            sModel = "models/buildables/sentry1.mdl";
            iShells = 200;
            iHealth = 300;
        }
        else if(iLevel == 2)
        {
            sModel = "models/buildables/sentry2.mdl";
            iShells = 120;
            iHealth = 180;
        }
        else if(iLevel == 3)
        {
            sModel = "models/buildables/sentry3.mdl";
            iShells = 144;
            iHealth = 216;
            iRockets = 20;
        }
                 
        new iSentry = CreateEntityByName("obj_sentrygun");
        
        if(IsValidEdict(iSentry)){
          DispatchSpawn(iSentry);
            
          TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);
            
          SetEntityModel(iSentry,sModel);
            
          SetEntProp(iSentry, Prop_Data, "m_CollisionGroup", 5); //players can walk through sentry so they dont get stuck
            
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_flAnimTime"),                 51, 4 , true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nNewSequenceParity"),         4, 4 , true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nResetEventsParity"),         4, 4 , true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoShells") ,               iShells, 4, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iMaxHealth"),                 iHealth, 4, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iHealth"),                    iHealth, 4, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bBuilding"),                  0, 2, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bPlacing"),                   0, 2, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bDisabled"),                  0, 2, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iObjectType"),                3, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iState"),                     1, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeMetal"),              0, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bHasSapper"),                 0, 2, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSkin"),                     (iTeam-2), 1, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bServerOverridePlacement"),     1, 1, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeLevel"),             iLevel, 4, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoRockets"),                 iRockets, 4, true);
           
          SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSequence"), 0, true);
          SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_hBuilder"),     iBuilder, true);
            
          SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flCycle"),                     0.0, true);
          SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPlaybackRate"),             1.0, true);
          SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPercentageConstructed"),     1.0, true);
            
          SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecOrigin"),             fOrigin, true);
          SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_angRotation"),         fAngle, true);
          SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecBuildMaxs"),         fBuildMaxs, true);
          SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_flModelWidthScale"),     fMdlWidth, true);
        	
          SetVariantInt(iTeam);
          AcceptEntityInput(iSentry, "TeamNum", -1, -1, 0);
        
          SetVariantInt(iTeam);
          AcceptEntityInput(iSentry, "SetTeam", -1, -1, 0);
          EmitSoundToAll(REWARD_SENTRYDROP, iSentry, _, _, _, 0.75); 
        }
	return iSentry;
}

stock DestroyBuilding(building)
{
	SetVariantInt(1000);
	AcceptEntityInput(building, "RemoveHealth");
}

public Action:Timer_BuildSentry(Handle:Timer, any:client)
{
	if(IsPlayerAlive(client)) 
	{
		PrintCenterText(client,"(Alt Fire) to drop your extra sentry.");
		if((GetClientButtons(client) & IN_ATTACK2) && TrackPlayers[client][PLAYER_SENTRY_COUNT] > 0)
        {    
			new Float:vicorigvec[3];
			new Float:angl[3];
			GetClientAbsOrigin(client, Float:vicorigvec);
			GetClientAbsAngles(client, Float:angl); 
			TrackPlayers[client][PLAYER_EXTRA] = BuildSentry(client, vicorigvec, angl, 3);
			TrackPlayers[client][PLAYER_SENTRY_COUNT]--;
			PrintToServer("Player Sentry Changed to Count: %i", TrackPlayers[client][PLAYER_SENTRY_COUNT]);
        }
		if (!IsValidEntity(TrackPlayers[client][PLAYER_EXTRA]) && TrackPlayers[client][PLAYER_SENTRY_COUNT] < c_NumSentries)
		{
			TrackPlayers[client][PLAYER_SENTRY_COUNT]++;
		}	
	}
	else
	{
      KillTimer(PlayerTimers[client][0]);
      PlayerTimers[client][0] = INVALID_HANDLE;
    }
		
	return Plugin_Continue;
} 

public Action:Timer_DestroySentry(Handle:Timer, any:client)
{
		PrintCenterText(client,"");
		if(IsValidEntity(TrackPlayers[client][PLAYER_EXTRA]))
        {
			DestroyBuilding(TrackPlayers[client][PLAYER_EXTRA]);
			if(IsClientInGame(client))  
			{
				TrackPlayers[client][PLAYER_EXTRA] = 0;
            }
        }    
        
}

/**
 * Returns a random, uniform Integer number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 * 
 * @param value			Value
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Integer number between min and max
 */
stock Math_GetRandomInt(min, max)
{
	new random = GetURandomInt();
	
	if (random == 0) {
		random++;
	}

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

/**
 * Returns a random, uniform Float number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 * 
 * @param value			Value
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Float number between min and max
 */
stock Float:Math_GetRandomFloat(Float:min, Float:max)
{
	return (GetURandomFloat() * (max  - min)) + min;
}


public DatabaseIntact()
{
	if(g_StatsDB != INVALID_HANDLE)
	{
		return true;
	} else 
	{
		decl String:error[255];
		SQL_GetError(g_StatsDB, error, sizeof(error));
		PrintToServer("Database not intact (%s)", error);
		return false;
	}
}

public T_ErrorOnly(Handle:owner, Handle:result, const String:error[], any:client)
{
	if(result == INVALID_HANDLE)
	{
		LogError("[RTD] MYSQL ERROR (error: %s)", error);
	}
}

stock Stats_Init()
{
	decl String:error[255];
	PrintToServer("[RTD] Connecting to RTD Log database...");
	g_StatsDB = SQL_Connect("sprays", true, error, sizeof(error));
	if(g_StatsDB != INVALID_HANDLE)
	{
		SQL_TQuery(g_StatsDB, T_ErrorOnly, "SET NAMES UTF8", 0, DBPrio_High);
		PrintToServer("[RTD] Connected successfully.");
	} else 
	{
		PrintToServer("Connection Failure!");
		LogError("[RTD] MYSQL ERROR (error: %s)", error);
	}
}