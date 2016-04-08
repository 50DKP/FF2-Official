//Freak Fortress 2 External Integration Subplugin
//Used to balance popular external plugins with FF2
//Currently supports: Goomba Stomp, RTD
#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>
#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <rtd>
#tryinclude <rtd2>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define PLUGIN_VERSION "0.0.0"

ConVar cvarGoomba;
ConVar cvarGoombaDamage;
ConVar cvarGoombaRebound;
ConVar cvarRTD;
ConVar cvarBossRTD;

public Plugin myinfo=
{
	name="Freak Fortress 2 External Integration Subplugin",
	author="Wliu, WildCard65",
	description="Integrates with popular plugins commonly run on FF2 servers",
	version=PLUGIN_VERSION,
};

public void OnPluginStart()
{
	cvarGoomba=CreateConVar("ff2_goomba", "1", "Allow FF2 to integrate with Goomba Stomp?", _, true, 0.0, true, 1.0);
	cvarGoombaDamage=CreateConVar("ff2_goomba_damage", "0.05", "How much the Goomba damage should be multiplied by", _, true, 0.0, true, 1.0);
	cvarGoombaRebound=CreateConVar("ff2_goomba_rebound", "300.0", "How high players should rebound after a Goomba stomp", _, true, 0.0);
	cvarRTD=CreateConVar("ff2_rtd", "1", "Allow FF2 to integrate with RTD?", _, true, 0.0, true, 1.0);
	cvarBossRTD=CreateConVar("ff2_boss_rtd", "0", "Allow the boss to use RTD?", _, true, 0.0, true, 1.0);

	AutoExecConfig(false, "ff2_external_integration", "sourcemod/freak_fortress_2");
}

public Action OnStomp(int attacker, int victim, float &damageMultiplier, float &damageBonus, float &JumpPower)
{
	if(FF2_IsFF2Enabled() && cvarGoomba.BoolValue)
	{
		if(FF2_GetBossIndex(attacker)!=-1)
		{
			float position[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);
			damageMultiplier=900.0;
			JumpPower=0.0;
			PrintCenterText(victim, "Ouch!  Watch your head!");
			PrintCenterText(attacker, "You just goomba stomped somebody!");
			return Plugin_Changed;
		}
		else if(FF2_GetBossIndex(victim)!=-1)
		{
			damageMultiplier=cvarGoombaDamage.FloatValue;
			JumpPower=cvarGoombaRebound.FloatValue;
			PrintCenterText(victim, "You were just goomba stomped!");
			PrintCenterText(attacker, "You just goomba stomped the boss!");
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action RTD_CanRollDice(int client)
{
	return (FF2_GetBossIndex(client)!=-1 && cvarRTD.BoolValue && !cvarBossRTD.BoolValue) ? Plugin_Handled : Plugin_Continue;
}

public Action RTD2_CanRollDice(int client)
{
	return (FF2_GetBossIndex(client)!=-1 && cvarRTD.BoolValue && !cvarBossRTD.BoolValue) ? Plugin_Handled : Plugin_Continue;
}