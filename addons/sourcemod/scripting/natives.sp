#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>

public OnPluginStart()
{
	RegConsoleCmd("say", SayCmd);
}

public Action:SayCmd(client, args)
{
	decl String:chat[128];
	if(GetCmdArgString(chat, sizeof(chat))<=0 || client<=0)
	{
		return Plugin_Continue;
	}

	if(!strcmp(chat, "\"1\""))
	{
		PrintToChatAll("enabled - %i", FF2_IsFF2Enabled());
	}
	else if(!strcmp(chat, "\"2\""))
	{
		PrintToChatAll("state - %i", FF2_GetRoundState());
	}
	else if(!strcmp(chat, "\"30\""))
	{
		PrintToChatAll("userid0 - %i", FF2_GetBossUserId(0));
	}
	else if(!strcmp(chat, "\"31\""))
	{
		PrintToChatAll("userid1 - %i", FF2_GetBossUserId(1));
	}
	else if(!strcmp(chat, "\"40\""))
	{
		PrintToChatAll("index0 - %i", FF2_GetBossIndex(0));
	}
	else if(!strcmp(chat, "\"41\""))
	{
		PrintToChatAll("index - %i", FF2_GetBossIndex(client));
	}
	else if(!strcmp(chat, "\"5\""))
	{
		PrintToChatAll("bteam - %i", FF2_GetBossTeam());
	}
	else if(!strcmp(chat, "\"50\""))
	{
		decl String:boss[64];
		new exists=FF2_GetBossSpecial(0, boss, 64);
		PrintToChatAll("special0 - %i %s", exists, boss);
	}
	else if(!strcmp(chat, "\"51\""))
	{
		decl String:boss[64];
		new exists=FF2_GetBossSpecial(1, boss, 64);
		PrintToChatAll("special1 - %i %s", exists, boss);
	}
	else if(!strcmp(chat, "\"60\""))
	{
		PrintToChatAll("mhp0 - %i", FF2_GetBossMaxHealth(0));
	}
	else if(!strcmp(chat, "\"61\""))
	{
		PrintToChatAll("mhp1 - %i", FF2_GetBossMaxHealth(1));
	}
	else if(!strcmp(chat, "\"7\""))
	{
		PrintToChatAll("rage - %f", FF2_GetRageDist(0, "", ""));
	}
	else if(!strcmp(chat, "\"8\""))
	{
		PrintToChatAll("flags - %i", FF2_GetFF2flags(0));
	}
	else if(!strcmp(chat, "\"9\""))
	{
		FF2_DoAbility(0, "default_abilities", "rage_stun", 0, 0);
	}
	return Plugin_Continue;	
}