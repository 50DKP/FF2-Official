/*
rage_overlay:	slot - slot (def.0)
				arg1 - path to overlay ("root" is \tf\materials\)
				arg2 - duration (def.6)
*/
#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>

#pragma newdecls required

TFTeam BossTeam=TFTeam_Blue;

#define PLUGIN_NAME "rage overlay"
#define PLUGIN_VERSION "2.0.0"

public Plugin myinfo=
{
	name="Freak Fortress 2: rage_overlay",
	author="Jery0987, RainBolt Dash",
	description="FF2: Ability that covers all living, non-boss team players screens with an image",
	version=PLUGIN_VERSION,
};

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", OnRoundStart);

	FF2_RegisterSubplugin(PLUGIN_NAME);
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(FF2_IsFF2Enabled())
	{
		CreateTimer(0.3, Timer_GetBossTeam, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action Timer_GetBossTeam(Handle hTimer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public void FF2_OnAbility(int boss, const char[] pluginName, const char[] abilityName, int slot, int status)
{
	if(!StrEqual(pluginName, PLUGIN_NAME, false))
	{
		return;
	}

	if(StrEqual(abilityName, "create overlay", false))
	{
		Rage_Overlay(boss, abilityName);
	}
}

void Rage_Overlay(int boss, const char[] abilityName)
{
	char overlay[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, abilityName, "overlay", overlay, sizeof(overlay));
	Format(overlay, PLATFORM_MAX_PATH, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && TF2_GetClientTeam(target)!=BossTeam)
		{
			ClientCommand(target, overlay);
		}
	}

	CreateTimer(FF2_GetAbilityArgumentFloat(boss, PLUGIN_NAME, abilityName, "duration", 6.0), Timer_Remove_Overlay, TIMER_FLAG_NO_MAPCHANGE);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
}

public Action Timer_Remove_Overlay(Handle timer)
{
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && TF2_GetClientTeam(target)!=BossTeam)
		{
			ClientCommand(target, "r_screenoverlay \"\"");
		}
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	return Plugin_Continue;
}
