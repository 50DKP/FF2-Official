//Freak Fortress 2 External Integration Subplugin
//Used to balance popular external plugins with FF2
//Currently supports: Goomba Stomp, RTD
#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>
#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <rtd>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "2.0.0"

new Handle:cvarGoomba;
new Handle:cvarGoombaDamage;
new Handle:cvarGoombaRebound;
new Handle:cvarRTD;
new Handle:cvarBossRTD;

new bool:goomba;
new Float:goombaDamage;
new Float:goombaRebound;
new bool:rtd;
new bool:canBossRTD;

public Plugin:myinfo=
{
	name="Freak Fortress 2 External Integration Subplugin",
	author="Wliu, WildCard65",
	description="Integrates with popular plugins commonly run on FF2 servers",
	version=PLUGIN_VERSION,
};

public OnPluginStart()
{
	cvarGoomba=CreateConVar("ff2_goomba", "1", "Allow FF2 to integrate with Goomba Stomp?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarGoombaDamage=CreateConVar("ff2_goomba_damage", "0.05", "How much the Goomba damage should be multiplied by", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarGoombaRebound=CreateConVar("ff2_goomba_rebound", "300.0", "How high players should rebound after a Goomba stomp", FCVAR_PLUGIN, true, 0.0);
	cvarRTD=CreateConVar("ff2_rtd", "1", "Allow FF2 to integrate with RTD?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarBossRTD=CreateConVar("ff2_boss_rtd", "0", "Allow the boss to use RTD?", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(cvarGoomba, CvarChange);
	HookConVarChange(cvarGoombaDamage, CvarChange);
	HookConVarChange(cvarGoombaRebound, CvarChange);
	HookConVarChange(cvarRTD, CvarChange);
	HookConVarChange(cvarBossRTD, CvarChange);

	AutoExecConfig(false, "ff2_external_integration", "sourcemod/freak_fortress_2");
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	switch(convar)
	{
		case cvarGoomba:
		{
			goomba=bool:StringToInt(newValue);
		}
		case cvarGoombaDamage:
		{
			goombaDamage=StringToFloat(newValue);
		}
		case cvarGoombaRebound:
		{
			goombaRebound=StringToFloat(newValue);
		}
		case cvarRTD:
		{
			rtd=bool:StringToInt(newValue);
		}
		case cvarBossRTD:
		{
			rtd=bool:StringToInt(newValue);
		}
	}
}

public OnConfigsExecuted()
{
	goomba=GetConVarBool(cvarGoomba);
	goombaDamage=GetConVarFloat(cvarGoombaDamage);
	goombaRebound=GetConVarFloat(cvarGoombaRebound);
	rtd=GetConVarBool(cvarRTD);
	canBossRTD=GetConVarBool(cvarBossRTD);
}

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower)
{
	if(goomba)
	{
		if(FF2_GetBossIndex(client)!=-1)
		{
			new Float:position[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);
			damageMultiplier=900.0;
			JumpPower=0.0;
			PrintCenterText(victim, "Ouch!  Watch your head!");
			PrintCenterText(attacker, "You just goomba stomped somebody!");
			return Plugin_Changed;
		}
		else if(FF2_GetBossIndex(client)!=-1)
		{
			damageMultiplier=goombaDamage;
			JumpPower=goombaRebound;
			PrintCenterText(victim, "You were just goomba stomped!");
			PrintCenterText(attacker, "You just goomba stomped the boss!");
			UpdateHealthBar();
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:RTD_CanRollDice(client)
{
	return (FF2_GetBossIndex(client)!=-1 && rtd && !canBossRTD) ? Plugin_Handled : Plugin_Continue;
}