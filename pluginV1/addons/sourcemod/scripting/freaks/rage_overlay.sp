// rage_overlay:		arg0 - slot (def.0)
//						arg1 - path to overlay ("root" is \tf\materials\)
//						arg2 - duration (def.6)

#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new BossTeam=_:TFTeam_Blue;

public Plugin:myinfo = {
	name = "Freak Fortress 2: rage_overlay",
	author = "Jery0987, RainBolt Dash",
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3,Timer_GetBossTeam);
	return Plugin_Continue;
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (!strcmp(ability_name,"rage_overlay"))
		Rage_Overlay(index,ability_name);
	return Plugin_Continue;
}

Rage_Overlay(index,const String:ability_name[])
{
	decl String:overlay[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name,1,overlay,PLATFORM_MAX_PATH);
		//this_plugin_name is from freak_fortress_2_subplugin
	Format(overlay,PLATFORM_MAX_PATH,"r_screenoverlay \"%s\"",overlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
			//This is good place for GetClientTeam(i)!=BossTeam - we don't want attack blue teammates with overlays
		{
			ClientCommand(i, overlay);
		}
	CreateTimer(FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,6.0),Clean_Screen);	//Make one timer for all players, not for each.
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	//return do not needed
}

public Action:Clean_Screen(Handle:hTimer)
{
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
			ClientCommand(i, "r_screenoverlay \"\"");
		}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	return Plugin_Continue;
}
