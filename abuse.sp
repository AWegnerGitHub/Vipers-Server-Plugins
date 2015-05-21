#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sidewinder>
#include <tf2items_giveweapon>

#define PLUGIN_NAME "Admin Abuse"
#define PLUGIN_VERSION 	"0.0.1"
#define PLUGIN_DESC "Make Admin Abuse easier"
#define PLUGIN_URL "http://www.team-vipers.com"
#define PLUGIN_AUTHOR "InsaneMosquito"

#define POWER "viper/472580.mp3"

#define ACTIVE		0
#define WEAPON		1


new TrackAdmins[MAXPLAYERS+1][3];

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
	RegAdminCmd("sm_aboose", Command_AbuseWOClip, ADMFLAG_ROOT);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	TrackAdmins[client][ACTIVE] = 0;
	SidewinderTrackChance(client, 0);
	SidewinderSentryCritChance(client, 0);
	SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows | NormalFlares | NormalPipes | NormalSyringe, true);
	SidewinderDetectClient(client, true);	
	return true;
}

public OnClientDisconnect(client)
{	
	TrackAdmins[client][ACTIVE] = 0;
	
	SidewinderTrackChance(client, 0);
	SidewinderSentryCritChance(client, 0);
	SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows | NormalFlares | NormalPipes | NormalSyringe, true);
	SidewinderDetectClient(client, true);
}

public OnMapStart()
{
	PrecacheSound(POWER);
	decl String:downloadFile[64];
	Format(downloadFile, 64, "sound/%s", POWER);
	AddFileToDownloadsTable(downloadFile);
}

public Action:Command_AbuseWOClip(client, args)
{
	decl String:arg1[32];
	if (args != 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		if(IsClientInGame(i))
		{
			if (TrackAdmins[i][ACTIVE] == 0)
			{
				TF2_SetPlayerPowerPlay(i, true);
				new weapon_index = GetPlayerWeaponSlot(i, 0);
				TrackAdmins[i][WEAPON] = -1;
				if(weapon_index != -1)
				{
					TrackAdmins[i][WEAPON] = GetEntProp(weapon_index, Prop_Send,  "m_iItemDefinitionIndex");
				}

				TF2Items_GiveWeapon(i, 8018);

				new flags = GetEntityFlags(i)|FL_NOTARGET;
				SetEntProp(i, Prop_Data, "m_fFlags", flags);

				SidewinderTrackChance(i, 100);
				SidewinderSentryCritChance(i, 100);
				SidewinderFlags(i, TrackingSentryRockets | TrackingRockets | TrackingArrows | TrackingFlares | TrackingPipes | TrackingSyringe, true);
				SidewinderDetectClient(i, false);
				EmitSoundToAll(POWER);
				TrackAdmins[i][ACTIVE] = 1;
			}
			else
			{
				TF2_SetPlayerPowerPlay(i, false);
				SidewinderTrackChance(i, 0);
				SidewinderSentryCritChance(i, 0);
				SidewinderFlags(i, NormalSentryRockets | NormalRockets | NormalArrows | NormalFlares | NormalPipes | NormalSyringe, true);
				SidewinderDetectClient(i, true);
				new flags = GetEntityFlags(i)&~FL_NOTARGET;
				SetEntProp(i, Prop_Data, "m_fFlags", flags);

				TF2Items_GiveWeapon(i, TrackAdmins[i][WEAPON]);
				TrackAdmins[i][WEAPON] = -1;
				TrackAdmins[i][ACTIVE] = 0;
			}

			LogAction(client, target_list[i], "\"%L\" toggled Admin Abuse on \"%L\" ", client, target_list[i]);
		}
	}
	return Plugin_Continue;
}