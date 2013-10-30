//Freak Fortress 2
//Template of ability plugin
//DON'T FORGET RENAME COMPILED PLUGIN FROM *.SMX TO *.FF2!!!

#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define ME 2048


public Plugin:myinfo = {
	name = "Freak Fortress 2: Template of ability plugin",
	author = "RainBolt Dash",
};

//new Handle:OnHaleRage;		//Uncomment it if you want to use some rages as "true rage", like Saxton's stun
//new BossTeam;					//Uncomment it, if you want to use check players' Team

//Poot your natives here
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//OnHaleRage = CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef); //Uncomment it if you want to use some rages as "true rage" like Saxton's stun
	
	return APLRes_Success;
}


//Poot your hooks etc. here
public OnPluginStart2()
{
	LoadTranslations("freak_fortress_2.phrases");
	//LoadTranslations("put_your_here.phrases");
	
	//HookEvent("teamplay_round_start", event_round_start);

}

/*
//Uncomment it, if you want to use check players' Team

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
*/

// Put your abilities (Rages, Charges etc here)
// Calls each 0.2 seconds for charge abilities
// It calls from FF2_OnAbility() fuction of freak_fortress_2_subplugin.inc
// It needs to filter by plugin name
public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	new slot=FF2_GetAbilityArgument(index,this_plugin_name,ability_name,0);
	/*
	//				Uncomment it if you want use this rage as "true rage"m like Saxton's stun
	if (!slot)
	{
		if (index == 0)		//Starts VSH rage ability forward
		{
			new Action:act = Plugin_Continue;
			Call_StartForward(OnHaleRage);
			new Float:dist=FF2_GetRageDist(index,this_plugin_name,ability_name);
			new Float:newdist=dist;
			Call_PushFloatRef(newdist);
			Call_Finish(act);
			if (act != Plugin_Continue && act != Plugin_Changed)
				return Plugin_Continue;
			if (act == Plugin_Changed) dist = newdist;	
		}
	}
	*/
	
	//slot 2
	if (!strcmp(ability_name,"charge_yourability"))
		charge_yourability(ability_name,index,slot);
	//slot 1
	else if (!strcmp(ability_name,"charge_your_other_ability"))
		charge_your_other_ability(ability_name,index);
	//slot 0
	else if (!strcmp(ability_name,"rage_this_is_my_ability"))
		rage_this_is_my_ability(ability_name,slot);
	//slot -1
	else if (!strcmp(ability_name,"rage_when_fakedied"))
		rage_when_fakedied(ability_name,index,slot);
	return Plugin_Continue;
}		

charge_yourability(const String:ability_name[],index,slot)
{
	//I use this lines to remove compile warnings
	strcmp(ability_name,ability_name);
	slot+=0;
	index+=0;
	//do something
}

charge_your_other_ability(const String:ability_name[],index)
{
	//I use this lines to remove compile warnings
	strcmp(ability_name,ability_name);
	index+=0;
	//do something
}

rage_this_is_my_ability(const String:ability_name[],slot)
{
	//I use this lines to remove compile warnings
	strcmp(ability_name,ability_name);
	slot+=0;
	//do something
}

rage_when_fakedied(const String:ability_name[],index,slot)
{
	//I use this lines to remove compile warnings
	strcmp(ability_name,ability_name);
	slot+=0;
	index+=0;
	BossTeam+=0;
	//do something
}