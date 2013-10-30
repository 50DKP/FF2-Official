#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>

public OnPluginStart()
{
	RegConsoleCmd("say", SayCmd);
}

public Action:SayCmd(client, args)
{
	decl String:CurrentChat[128];
	if (GetCmdArgString(CurrentChat, sizeof(CurrentChat)) < 1 || (client == 0))
		return Plugin_Continue;
		
	if (!strcmp(CurrentChat, "\"1\""))
	{
		PrintToChatAll("enabled - %i",FF2_IsFF2Enabled());
	}
	if (!strcmp(CurrentChat, "\"2\""))
	{
		PrintToChatAll("state - %i",FF2_GetRoundState());
	}
	if (!strcmp(CurrentChat, "\"30\""))
	{
		PrintToChatAll("userid0 - %i",FF2_GetBossUserId(0));
	}
	if (!strcmp(CurrentChat, "\"31\""))
	{
		PrintToChatAll("userid1 - %i",FF2_GetBossUserId(1));
	}
	if (!strcmp(CurrentChat, "\"40\""))
	{
		PrintToChatAll("index0 - %i",FF2_GetBossIndex(0));
	}
	if (!strcmp(CurrentChat, "\"41\""))
	{
		PrintToChatAll("index - %i",FF2_GetBossIndex(client));
	}
	if (!strcmp(CurrentChat, "\"5\""))
	{
		PrintToChatAll("bteam - %i",FF2_GetBossTeam());
	}
	if (!strcmp(CurrentChat, "\"50\""))
	{
		decl String:s[64];
		new see=FF2_GetBossSpecial(0,s,64);
		PrintToChatAll("special0 - %i %s",see,s);
	}
	if (!strcmp(CurrentChat, "\"51\""))
	{
		decl String:s[64];
		new see=FF2_GetBossSpecial(1,s,64);
		PrintToChatAll("special1 - %i %s",see,s);
	}
	if (!strcmp(CurrentChat, "\"60\""))
	{
		PrintToChatAll("mhp0 - %i",FF2_GetBossMaxHealth(0));
	}
	if (!strcmp(CurrentChat, "\"61\""))
	{
		PrintToChatAll("mhp1 - %i",FF2_GetBossMaxHealth(1));
	}
	if (!strcmp(CurrentChat, "\"7\""))
	{
		PrintToChatAll("rage - %f",FF2_GetRageDist(0,"",""));
	}
	if (!strcmp(CurrentChat, "\"8\""))
	{
		PrintToChatAll("flags - %i",FF2_GetFF2flags(0));
	}
	if (!strcmp(CurrentChat, "\"9\""))
	{
		FF2_DoAbility(0, "default_abilities", "rage_stun", 0, 0);
	}
	return Plugin_Continue;	
}

public Action:FF2_PreAbility( index, const String:plugin_name[], const String:ability_name[], action )
{
	return Plugin_Stop;
}
