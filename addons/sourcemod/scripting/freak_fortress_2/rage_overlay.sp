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
#include <freak_fortress_2_subplugin>

new TFTeam:BossTeam=TFTeam_Blue;

#define PLUGIN_VERSION "2.0.0"

public Plugin:myinfo=
{
	name="Freak Fortress 2: rage_overlay",
	author="Jery0987, RainBolt Dash",
	description="FF2: Ability that covers all living, non-boss team players screens with an image",
	version=PLUGIN_VERSION,
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", OnRoundStart);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(FF2_IsFF2Enabled())
	{
		CreateTimer(0.3, Timer_GetBossTeam);
	}
	return Plugin_Continue;
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], slot, status)
{
	if(StrEqual(ability_name, "rage_overlay"))
	{
		Rage_Overlay(boss, ability_name);
	}
}

Rage_Overlay(boss, const String:ability_name[])
{
	decl String:overlay[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, "overlay", overlay, PLATFORM_MAX_PATH);
	Format(overlay, PLATFORM_MAX_PATH, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(new target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && TF2_GetClientTeam(target)!=BossTeam)
		{
			ClientCommand(target, overlay);
		}
	}

	CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, "duration", 6.0), Timer_Remove_Overlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
}

public Action:Timer_Remove_Overlay(Handle:timer)
{
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(new target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && TF2_GetClientTeam(target)!=BossTeam)
		{
			ClientCommand(target, "r_screenoverlay \"\"");
		}
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	return Plugin_Continue;
}