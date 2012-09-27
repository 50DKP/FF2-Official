#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <sdkhooks>
#include <morecolors>

#include <freak_fortress_2>
#include "freak_fortress_2/natives.inc"

#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>

#define PLUGIN_VERSION "2.0 alpha"

#pragma semicolon 1

enum FF2Stats
{
	FF2Stat_Damage,
	FF2Stat_Healing,
};

// Current set and its bosses
new String:g_CurrentBossSet[64];
new Handle:g_Array_Bosses;

// Damage and healing done by non-bosses
// Note that damage done by targets being healed by medigun are
// counted as damage
new g_CurrentStats[MAXPLAYERS][FF2Stats];

// The array is the keys to the map
new Handle:g_Array_AbilityList;
new Handle:g_Trie_AbilityMap;

new Handle:g_CurrentBosses;

public Plugin:myinfo = 
{
	name = "Freak Fortress 2",
	author = "Powerlord",
	description = "Freak Fortress 2 is an \"all versus one (or two)\" game mode for Team Fortress 2",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/forumdisplay.php?f=154"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateFF2Natives();
	CreateVSHNatives();
	
	RegPluginLibrary("freak_fortress_2");
	return APLRes_Success;
}

public OnPluginStart()
{
	new cells = ByteCountToCells(64);
	g_Array_Bosses = CreateArray(cells);
	g_Array_AbilityList = CreateArray(cells);
	g_Trie_AbilityMap = CreateTrie();
}

public OnConfigsExecuted()
{
	
}

public ResetData()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		for (new j = 0; j < _:FF2Stats; j++)
		{
			g_CurrentStats[i][j] = 0;
		}
	}
}

public PrecacheBoss(String:bossname[])
{
	//TODO
	
}

public LoadBoss(client, String:bossName[])
{
	//TODO
	
}

