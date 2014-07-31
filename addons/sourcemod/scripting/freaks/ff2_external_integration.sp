//Freak Fortress 2 External Integration Subplugin
//Used to balance popular external plugins with FF2
//Currently supports: Goomba Stomp, RTD
#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>

#define PLUGIN_VERSION "2.0.0"

//Note to Wliu, since were only using forwards... we do not need to check for the library.

#if defined _goomba_included
new Handle:cvarGoombaDamage;
new Handle:cvarGoombaRebound;
new Float:goombaDamage;
new Float:goombaReboundPower;
new Handle:g_hBossGoombaOverride;
new Handle:g_hPlayerGoombaOverride;
#endif

#if defined _rtd_included
new Handle:cvarBossRTD;
new bool:canBossRTD;
new Handle:g_hRtdOverride;
#endif

public Plugin:myinfo=
{
	name="Freak Fortress 2 External Integration Subplugin",
	author="Wliu, WildCard65",
	description="Integrates with popular plugins commonly run on FF2 servers",
	version=PLUGIN_VERSION,
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
#if defined _goomba_included_
	g_hBossGoombaOverride = CreateGlobalForward("OnFF2BossStompOverride", ET_Event, Param_Cell, Param_Cell, Param_CellByRef, Param_CellByRef, Param_CellByRef);
	g_hPlayerGoombaOverride = CreateGlobalForward("OnFF2PlayerStompOverride", ET_Event, Param_Cell, Param_Cell, Param_CellByRef, Param_CellByRef, Param_CellByRef);
#endif
#if defined _rtd_included
	g_hRtdOverride = CreateGlobalForward("OnFF2RtdOverride", ET_Event, Param_Cell);
#endif
	RegPluginLibrary("ff2 external");
	return APLRes_Success;
}

public OnPluginStart()
{
#if defined _goomba_included_
	cvarGoombaDamage=CreateConVar("ff2_goomba_damage", "0.05", "How much the Goomba damage should be multipled by when goomba stomping the boss (requires Goomba Stomp)", FCVAR_PLUGIN, true, 0.01, true, 1.0);
	cvarGoombaRebound=CreateConVar("ff2_goomba_jump", "300.0", "How high players should rebound after goomba stomping the boss (requires Goomba Stomp)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(cvarGoombaDamage, CvarChange);
	HookConVarChange(cvarGoombaRebound, CvarChange);
#endif
#if defined _rtd_included
	cvarBossRTD=CreateConVar("ff2_boss_rtd", "0", "Can the boss use rtd? 0 to disallow boss, 1 to allow boss (requires RTD)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(cvarBossRTD, CvarChange);
#endif
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
#if defined _goomba_included_
	if(convar==cvarGoombaDamage)
	{
		GoombaDamage=StringToFloat(newValue);
	}
	else if(convar==cvarGoombaRebound)
	{
		reboundPower=StringToFloat(newValue);
	}
#endif
#if defined _rtd_included
	if(convar==cvarBossRTD)
	{
		canBossRTD=bool:StringToInt(newValue);
	}
#endif
}

public OnConfigsExecuted()
{
#if defined _goomba_included_
	GoombaDamage=GetConVarFloat(cvarGoombaDamage);
	reboundPower=GetConVarFloat(cvarGoombaRebound);
#endif
#if defined _rtd_included
	canBossRTD=GetConVarBool(cvarBossRTD);
#endif
}

#if defined _goomba_included_
public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower)
{
	if (!FF2_IsFF2Enabled())
		return Plugin_Continue;
	new g_cBoss = GetClientOfUserId(FF2_GetBossUserId(attacker));
	if (IsValidClient(g_cBoss) && attacker == g_cBoss)
	{
		new Action:ret = Plugin_Continue, Float:dmgMult, Float:dmgBonus, Float:jmpPower;
		Call_StartForward(g_hPlayerGoombaOverride);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_PushCellRef(dmgMult);
		Call_PushCellRef(dmgBonus);
		Call_PushCellRef(jmpPower);
		Call_Finish(ret);
		switch (ret)
		{
			case Plugin_Handled:
				return Plugin_Handled;
			case Plugin_Changed:
			{
				damageMultiplier = dmgMult;
				damageBonus = dmgBonus;
				JumpPower = jmpPower;
				return Plugin_Changed;
			}
			case Plugin_Continue:
			{
				damageBonus = 0.0;
				damageMultiplier = 3.0;
				JumpPower = 0.0;
				return Plugin_Changed;
			}
		}
	}
	if (IsValidClient(g_cBoss) && victim == g_cBoss)
	{
		new Action:ret = Plugin_Continue, Float:dmgMult, Float:dmgBonus, Float:jmpPower;
		Call_StartForward(g_hBossGoombaOverride);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_PushCellRef(dmgMult);
		Call_PushCellRef(dmgBonus);
		Call_PushCellRef(jmpPower);
		Call_Finish(ret);
		switch (ret)
		{
			case Plugin_Handled:
				return Plugin_Handled;
			case Plugin_Changed:
			{
				damageMultiplier = dmgMult;
				damageBonus = dmgBonus;
				JumpPower = jmpPower;
				return Plugin_Changed;
			}
			case Plugin_Continue:
			{
				damageBonus = 0.0;
				damageMultiplier = g_fGoombaDmg;
				JumpPower = g_fGoombaJump;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}
#endif

#if defined _rtd_included
public Action:RTD_CanRollDice(client)
{
	if (!FF2_IsFF2Enabled())
		return Plugin_Continue;
	new g_cBoss = GetClientOfUserId(FF2_GetBossUserId(attacker));
	if (IsValidClient(g_cBoss) && g_cBoss != client)
		return Plugin_Continue;
	new Action:ret = Plugin_Continue;
	Call_StartForward(g_hRtdOverride);
	Call_PushCell(client);
	Call_Finish(ret);
	switch (ret)
	{
		case Plugin_Handled:
			return Plugin_Handled;
		case Plugin_Continue:
		{
			if (g_bBossRtd)
				return Plugin_Continue;
			else
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
#endif

stock bool:IsValidClient(client, bool:replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}
