//Freak Fortress 2 v2
//By Powerlord

//Freak Fortress 2 v1
//By Rainbolt Dash: programmer, modeller, mapper, painter.
//Author of Demoman The Pirate: http://www.randomfortress.ru/thepirate/
//And one of two creators of Floral Defence: http://www.polycount.com/forum/showthread.php?t=73688
//And author of VS Saxton Hale Mode

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2_morestocks>
#include <tf2items>
#include <tf2attributes>
#include <sdkhooks>
#include <morecolors>

#include <freak_fortress_2>
#include "freak_fortress_2/natives.inc"

#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>

#define TARGET_RED "@red"
#define TARGET_BLU "@blue"

#define FF2_CONFIGS "configs/freak_fortress_2"
#define BOSS_FILE "characters.cfg"
#define DOORS_FILE "doors.cfg"
#define WEAPONS_FILE "weapons.cfg"

#define SOUND_SHIELD_ZAP "player/spy_shield_break.wav"

#define PLUGIN_VERSION "2.0 alpha"

#define MAXBOSSES 128

#pragma semicolon 1

#define SET_AND_BOSS_LENGTH 64

enum FF2Stats
{
	FF2Stat_UserId=0,
	FF2Stat_Damage,
	FF2Stat_Healing,
	FF2Stat_Lifelength,
	FF2Stat_Points,
};

enum FF2WeaponSpecials
{
	FF2WeaponSpecial_PreventDamage,
	FF2WeaponSpecial_RemoveOnDamage,
	FF2WeaponSpecial_JarateOnChargedHit,
	
}

enum FF2WeaponModType
{
	FF2WeaponMod_AddAttrib,
	FF2WeaponMod_RemoveAttrib,
	FF2WeaponMod_Replace,
	FF2WeaponMod_OnHit,
	FF2WeaponMod_OnTakeDamage,
}

// Weapon Special Abilities

new String:WeaponSpecials[][] = {
	"drop health pack on kill",
	"glow on scoped hit",
	"prevent damage",
	"remove on damage"
};

// KeyValues isn't the best structure, but otherwise we'd be parsing it into a bunch of constructs
new Handle:g_KeyValues_WeaponMods = INVALID_HANDLE;

// Boss flags are loaded from boss configs
new g_BossFlags[MAXPLAYERS+1];

// FF2 status
// ------------------------
new String:g_ConfigPath[PLATFORM_MAX_PATH];
// These will be set as maps change.  Enabled and FirstRound correspond to cvars
// Enabled is directly affected by g_bFF2Map
// Setting active while not setting enabled is a bug
new bool:g_bEnabled;
new bool:g_bFirstRound;
new bool:g_bFF2Map;
new bool:g_bActive;
// ------------------------

// Valve Cvars
// ------------------------
new Handle:g_Cvar_ArenaQueue;
new Handle:g_Cvar_UnbalanceLimit;
new Handle:g_Cvar_Autobalance;
new Handle:g_Cvar_FirstBlood;
new Handle:g_Cvar_ForceCamera;
new Handle:g_Cvar_Medieval;
// ------------------------

// Valve Cvar Old Values
new bool:g_OldArenaQueue;
new g_OldUnbalUnbalanceLimit;
new bool:g_OldAutobalance;
new bool:g_OldFirstBlood;
// No Medieval here as it doesn't take effect until map change

// Our Cvars
// ------------------------
new Handle:g_Cvar_Enabled;
new Handle:g_Cvar_FirstRound;
new Handle:g_Cvar_PointType;
new Handle:g_Cvar_PointDelay;
new Handle:g_Cvar_PointAlive;
new Handle:g_Cvar_Announce;
new Handle:g_Cvar_Crits;
new Handle:g_Cvar_ShortCircuit;
new Handle:g_Cvar_Countdown;
new Handle:g_Cvar_SpecForceBoss;
// ------------------------

// All boss sets.
// ------------------------
new Handle:g_Array_BossSets;
// ------------------------

// Current set and its bosses
// ------------------------
new String:g_CurrentBossSet[SET_AND_BOSS_LENGTH];
new Handle:g_Trie_Bosses; // adt_trie of KeyValues handles of all bosses in the current set
new Handle:g_Array_BossNames; // adt_array of keys to g_Trie_Bosses
// ------------------------

// Available boss abilities
// ------------------------
// The array is the keys to the map
new Handle:g_Array_AbilityList;
new Handle:g_Trie_AbilityMap;
// ------------------------


// Boss Tracking Variables
// ------------------------
new g_CurrentBossCount;
// Client ID of current bosses, based on boss index
new g_CurrentBosses[MAXPLAYERS]; // Do NOT change this to MAXPLAYERS+1
// Stores handles to KeyValues for bosses currently in play, based on boss index
new Handle:g_KeyValues_CurrentBosses[MAXPLAYERS]; // Do NOT change this to MAXPLAYERS+1
// ------------------------

new g_BossesMaxHealth[MAXPLAYERS] = { 1, ... };
new g_BossesMaxLives[MAXPLAYERS] = { 1, ... };
new g_BossesHealth[MAXPLAYERS] = { 1, ... };
new g_BossesLives[MAXPLAYERS] = { 1, ... };

// Player data
// ------------------------
// Damage and healing done by non-bosses
// Note that damage done by targets being healed by medigun are
// counted as damage
new g_CurrentStats[MAXPLAYERS+1][FF2Stats];
new g_OldHealing[MAXPLAYERS+1];

new g_PlayersRemaining;
new TFTeam:g_BossTeam = TFTeam_Blue;
new TFTeam:g_OtherTeam = TFTeam_Red; // We're lazy
// ------------------------

// Map status
// ------------------------
new g_RoundStartTime;
new g_CurrentRound;
// ------------------------

public Plugin:myinfo = 
{
	name = "Freak Fortress 2",
	author = "Powerlord & Rainbolt Dash",
	description = "Freak Fortress 2 is an \"all versus one (or two)\" game mode for Team Fortress 2",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/forumdisplay.php?f=154"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (GetFeatureStatus(FeatureType_Capability, "SDKHook_DmgCustomInOTD") != FeatureStatus_Available)
	{
		strcopy(error, err_max, "SDKHooks 2.1 or newer is required");
		return APLRes_Failure;
	}

	RegPluginLibrary("freak_fortress_2");

	CreateFF2Natives();
	CreateVSHNatives();

	return APLRes_Success;
}

public OnPluginStart()
{
	new cells = ByteCountToCells(SET_AND_BOSS_LENGTH);
	g_Array_BossSets = CreateArray(cells);
	g_Trie_Bosses = CreateTrie();
	g_Array_BossNames = CreateArray(cells);
	g_Array_AbilityList = CreateArray(cells);
	g_Trie_AbilityMap = CreateTrie();

	g_Cvar_ArenaQueue = FindConVar("tf_arena_use_queue");
	g_Cvar_UnbalanceLimit = FindConVar("mp_teams_unbalance_limit");
	g_Cvar_Autobalance = FindConVar("mp_autobalance");
	g_Cvar_FirstBlood = FindConVar("tf_arena_first_blood");
	g_Cvar_ForceCamera = FindConVar("mp_forcecamera");
	g_Cvar_Medieval = FindConVar("tf_medieval");
	
	CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_Cvar_Enabled = CreateConVar("ff2_enabled", "1", "Enable Freak Fortress 2? If you want to control this from another plugin, comment out the ff2_enabled line in the config file", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_FirstRound = CreateConVar("ff2_first_round", "0", "Should first round be FF2? Set to 0 for normal arena", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_Announce = CreateConVar("ff2_announce", "120", "How often in seconds should we advertise information about FF2? Set to 0 to hide", FCVAR_NONE, true, 0.0);
	g_Cvar_Crits = CreateConVar("ff2_crits", "0", "Can bosses get crits?", FCVAR_NONE, true, 0.0, true, 1.0);
	//g_Cvar_Countdown = CreateConVar("ff2_countdown", "", "", FCVAR_NONE, true, 60.0);
	//g_Cvar_PointAlive = CreateConVar("ff2_point_alive", "5", "", FCVAR_NONE, true, 0.0, true, 1.0);
	//g_Cvar_PointDelay = CreateConVar("ff2_point_delay", "60", "", FCVAR_NONE, true, 60.0);
	//g_Cvar_PointType = CreateConVar("ff2_point_type", "0", "", FCVAR_NONE, true, 0.0, true, 1.0);
	//g_Cvar_ShortCircuit = CreateConVar("ff2_shortcircuit_stun", "2", "", FCVAR_NONE, true, 0.0);
	//g_Cvar_SpecForceBoss = CreateConVar("ff2_spec_forceboss", "0", "", FCVAR_NONE, true, 0.0, true, 1.0);

	HookConVarChange(g_Cvar_ArenaQueue, CvarChange_ForceFalse);
	HookConVarChange(g_Cvar_Autobalance, CvarChange_ForceFalse);
	SetConVarInt(g_Cvar_UnbalanceLimit, CvarChange_ForceZero);
	HookConVarChange(g_Cvar_FirstBlood, CvarChange_ForceFalse);
	//SetConVarInt(g_Cvar_ForceCamera, CvarChange_ForceZero);
	
	BuildPath(Path_SM, g_ConfigPath, PLATFORM_MAX_PATH, "configs/freak_fortress_2");
}

public OnMapStart()
{
	g_bFF2Map = false;
	
	decl String:mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	
	// Get the map prefix
	new pos = FindCharInString(mapName, '_');
	decl String:mapPrefix[10]; // 10 is arbitrary, but it had to be longer than "deathrun"
	strcopy(mapPrefix, (pos < sizeof(mapPrefix) ? pos : sizeof(mapPrefix)), mapName);
	
	decl String:mapConfig[PLATFORM_MAX_PATH];
	Format(mapConfig, PLATFORM_MAX_PATH, "%s/%s", g_ConfigPath, "maps.cfg");
	
	new Handle:fh = OpenFile(mapConfig, "r");
	
	if (fh == INVALID_HANDLE)
	{
		LogError("Could not open %s, falling back to defaults", mapConfig);
		if (StrEqual(mapPrefix, "vsh", false) || StrEqual(mapPrefix, "arena", false))
		{
			g_bFF2Map = true;
		}
	}
	else
	{
		while (!IsEndOfFile(fh))
		{
			decl String:line[10];
			ReadFileLine(fh, line, sizeof(line));
			TrimString(line);
			if (StrEqual(mapPrefix, line, false))
			{
				g_bFF2Map = true;
				break; // No point continuing to loop if we found it
			}
		}
		CloseHandle(fh);
	}
	
	// Check to see if we still need g_OldHealing later
	for (new i = 1; i <= MaxClients; ++i)
	{
		g_OldHealing[i] = 0;
	}
	
}

public OnConfigsExecuted()
{
	g_CurrentRound = 0;

	// These values are read once to prevent issues mid-map
	g_bEnabled = g_bFF2Map && GetConVarBool(g_Cvar_Enabled);
	g_bActive = false;

	g_OldArenaQueue = GetConVarBool(g_Cvar_ArenaQueue);
	g_OldUnbalUnbalanceLimit = GetConVarInt(g_Cvar_UnbalanceLimit);
	g_OldAutobalance = GetConVarBool(g_Cvar_Autobalance);
	g_OldFirstBlood = GetConVarBool(g_Cvar_FirstBlood);

	g_bFirstRound = GetConVarBool(g_Cvar_FirstRound);
	
	if (g_bEnabled && g_bFirstRound)
	{
		PrepareFF2();
		ChangeValveCvars();
	}
	
	// Don't bother parsing the various boss and weapons files unless we're actually loaded
	if (g_bEnabled)
	{
		new String:configFile[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, configFile, PLATFORM_MAX_PATH, "%s/%s", FF2_CONFIGS, WEAPONS_FILE);
		
		if (g_KeyValues_WeaponMods != INVALID_HANDLE)
		{
			CloseHandle(g_KeyValues_WeaponMods);
		}
		
		if (!FileToKeyValues(g_KeyValues_WeaponMods, configFile))
		{
			SetFailState("Failed to load weapon configuration file.");
		}
		
		BuildPath(Path_SM, configFile, PLATFORM_MAX_PATH, "%s/%s", FF2_CONFIGS, BOSS_FILE);
		
		new Handle:bossFile;
		if (!FileToKeyValues(bossFile, configFile))
		{
			SetFailState("Failed to load boss character list file.");
		}

		new bool:found = false;
		
		if (strlen(g_CurrentBossSet) > 0 && KvJumpToKey(bossFile, g_CurrentBossSet))
		{
			found = ReadBossSet(bossFile);
		}
		
		// Was an else if, but we want found from above to be processed, too
		if (!found && KvGotoFirstSubKey(bossFile))
		{
			// Couldn't find the selected set, so we fell back to the first set
			KvGetSectionName(bossFile, g_CurrentBossSet, sizeof(g_CurrentBossSet));
			found = ReadBossSet(bossFile);
		}
		
		if (!found)
		{
			// Couldn't find any sets?
			SetFailState("Could not locate valid boss set in boss list file.");
		}
		
		
		
	}
}

bool:ReadBossSet(Handle:bossFile)
{
	if (KvGotoFirstSubKey(bossFile, false))
	{
		new count = 0;
		do
		{
			decl String:boss[128];
			KvGetString(bossFile, NULL_STRING, boss, sizeof(boss));
			
			new Handle:bossConfig = ReadBoss(boss);
			if (bossConfig == INVALID_HANDLE)
			{
				continue;
			}
			
			PushArrayString(g_Array_BossNames, boss);
			SetTrieValue(g_Trie_Bosses, boss, bossConfig);
			
			count++;
			
		} while (KvGotoNextKey(bossFile, false));
		
		KvGoBack(bossFile);
		
		if (count == 0)
		{
			LogError("No valid bosses in selected set: %s", g_CurrentBossSet);
			return false;
		}
		
		LogMessage("Loaded %d bosses from %s", count, GetArraySize(g_Array_BossNames));
	}
	else
	{
		LogError("No bosses in selected set: %s", g_CurrentBossSet);
		return false;
	}
	
	return true;
}

Handle:ReadBoss(const String:boss[])
{
	decl bossFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, bossFile, PLATFORM_MAX_PATH, "%s/%s.cfg", FF2_CONFIGS, boss);
	
	new Handle:bossConfig;
	
	if (!FileToKeyValues(bossConfig, bossFile))
	{
		LogError("Could not parse boss configuraton: %s", boss);
		return INVALID_HANDLE;
	}
	
	return bossConfig;
	
}

public OnClientConnected(client)
{
	SDKHook(client, SDKHook_StartTouch, Hook_StartTouch);
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

// This combines with bossflags to make it so bosses can't pick up health or ammo by default
public Action:Hook_StartTouch(entity, other)
{
	if (!g_bEnabled || !IsValidEntity(entity) || !IsValidEntity(other) || entity < 0 || entity > MaxClients
		|| !IsBoss(entity) || other <= MaxClients)
	{
		return Plugin_Continue;
	}
	
	new String:classname[64];
	GetEntityClassname(other, classname, sizeof(classname));
	
	// Ammo
	if (g_BossFlags[entity] & BOSSFLAG_ALLOW_AMMO_PICKUP != BOSSFLAG_ALLOW_AMMO_PICKUP)
	{
		// Boss isn't allowed to pick up ammo packs
		if (StrEqual(classname, "item_ammopack_full") || StrEqual(classname, "item_ammopack_medium")
			|| StrEqual(classname, "item_ammopack_small") || StrEqual(classname, "tf_ammo_pack"))
		{
			return Plugin_Stop;
		}
	}
	
	// Health
	if (g_BossFlags[entity] & BOSSFLAG_ALLOW_HEALTH_PICKUP != BOSSFLAG_ALLOW_HEALTH_PICKUP)
	{
		if (StrEqual(classname, "item_healthkit_full") || StrEqual(classname, "item_healthkit_medium") 
			|| StrEqual(classname, "item_healthkit_small"))
		{
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon,
	Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	// victim and attacker should both be players
	if (victim <= 0 || victim > MaxClients || attacker <= 0 || attacker > MaxClients)
	{
		return Plugin_Continue;
	}
	
	new bossIndex = GetBossIndex(victim);
	if (bossIndex == -1)
	{
		// Player took damage
		if (IsBoss(attacker))
		{
			// Break any demoshields they have
			new entity = -1;
			while ((entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) != -1)
			{
				if (victim == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
				{
					AcceptEntityInput(entity, "Kill");
					
					new Float:victimPos[3];
					GetClientAbsOrigin(victim, victimPos);
					
					EmitSoundToAll(SOUND_SHIELD_ZAP, victim, SNDCHAN_ITEM, _, _, 130);
					
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		} // if (IsBoss(attacker))
	}
	else
	{
		// Boss took damage
		if (!IsBoss(attacker))
		{
			switch (damagecustom)
			{
				case TF_CUSTOM_BACKSTAB:
				{
					damage = (g_BossesMaxHealth[bossIndex] * g_BossesMaxLives[bossIndex]) / 10.0;
					
					// Both users need to be informed
					
					return Plugin_Changed;
				}
				
				case TF_CUSTOM_BOOTS_STOMP:
				{
					damage = 1000.0;
					damagetype &= ~DMG_CRIT;
					return Plugin_Changed;
				}
				
				case TF_CUSTOM_HEADSHOT, TF_CUSTOM_HEADSHOT_DECAPITATION:
				{
					
				}
				
				case TF_CUSTOM_TELEFRAG:
				{
					damage = (g_BossesMaxHealth[bossIndex] * g_BossesMaxLives[bossIndex]) / 10.0;
				}
				
				default:
				{
					
				}
			}
		} // if (!IsBoss(attacker))
	}
	
	return Plugin_Continue;
}

public Event_PostInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsBoss(client))
	{
		// Reapply Boss Weapons
	}
	else
	{
		ApplyClientWeaponChanges(client);
	}
}

ApplyBossLoadout(client, const String:boss[])
{
	if (!IsBoss(client))
	{
		return;
	}
	
	// Remove all weapons
	TF2_RemoveAllWeapons(client);

	// Remove all attributes
	TF2Attrib_RemoveAll(client);
	
	// Remove all wearables
	new wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			AcceptEntityInput(wearable, "Kill");
		}
	}
	
	// Remove all canteens
	wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			AcceptEntityInput(wearable, "Kill");
		}
	}
	
	// boss specific items.
	// TODO
}

ApplyClientWeaponChanges(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	for (new i = 0; i < 6; ++i)
	{
		// Check primary
		new weapon = GetPlayerWeaponSlot(client, i);
		if (weapon == -1 || !IsValidEntity(weapon))
		{
			continue;
		}
		
		new String:weaponClass[64];
		new itemDefinitionIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		
		GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));
		new Handle:data = INVALID_HANDLE;
		
		// Replace weapons
		data = GetWeaponModsByClassname(weaponClass, FF2WeaponMod_Replace);
		if (data != INVALID_HANDLE)
		{
			if (ReplaceWeapon(client, i, weapon, data))
			{
				GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));
			}
			CloseHandle(data);
		}
		
		data = GetWeaponModsById(itemDefinitionIndex, FF2WeaponMod_Replace);
		if (data != INVALID_HANDLE)
		{
			if (ReplaceWeapon(client, i, weapon, data))
			{
				GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));
			}
			CloseHandle(data);
		}
		
		// Remove attribs
		data = GetWeaponModsByClassname(weaponClass, FF2WeaponMod_RemoveAttrib);
		if (data != INVALID_HANDLE)
		{
			RemoveWeaponAttribs(weapon, data);
			CloseHandle(data);
		}
		
		data = GetWeaponModsById(itemDefinitionIndex, FF2WeaponMod_RemoveAttrib);
		if (data != INVALID_HANDLE)
		{
			RemoveWeaponAttribs(weapon, data);
			CloseHandle(data);
		}
		
		// Add attribs
		data = GetWeaponModsByClassname(weaponClass, FF2WeaponMod_AddAttrib);
		if (data != INVALID_HANDLE)
		{
			SetWeaponAttribs(weapon, data);
			CloseHandle(data);
		}
		
		data = GetWeaponModsById(itemDefinitionIndex, FF2WeaponMod_AddAttrib);
		if (data != INVALID_HANDLE)
		{
			SetWeaponAttribs(weapon, data);
			CloseHandle(data);
		}
		
	}
	
}

/**
 * @param classname		Classname to check
 * @param type			FF2WeaponModType you want
 * @returns 			Datapack with requested data
 * However, the datapack format is dependent on the FF2WeaponModType: [] specifies repeating sets of values corresponding to count
 * FF2WeaponMod_Replace - String classname, int item definition index, int quality, int level
 * FF2WeaponMod_RemoveAttrib - int count, [String definition]
 * FF2WeaponMod_AddAttrib - int count, [String definition, Float value]
 */
Handle:GetWeaponModsByClassname(const String:classname[64], FF2WeaponModType:type)
{
	new bool:change = false;
	
	// TODO lookup if we have any mods
	
	if (!change)
	{
		return INVALID_HANDLE;
	}
	
	new Handle:data = CreateDataPack();
	
	// set data
	
	ResetPack(data);
	return data;
}

/**
 * @param iDefinitionIndex	Item Definition Index to check
 * @param type			FF2WeaponModType you want
 * @returns 			Datapack with requested data
 * However, the datapack format is dependent on the FF2WeaponModType: [] specifies repeating sets of values corresponding to count
 * FF2WeaponMod_Replace - String classname, int item definition index, int quality, int level
 * FF2WeaponMod_RemoveAttrib - int count, [String definition]
 * FF2WeaponMod_AddAttrib - int count, [String definition, Float value]
 */
Handle:GetWeaponModsById(iDefinitionIndex, FF2WeaponModType:type)
{
	new bool:change = false;
	
	new Handle:data = CreateDataPack();

	// TODO lookup if we have any mods
	
	switch (type)
	{
		case FF2WeaponMod_AddAttrib:
		{
			//adt_array of keys and adt_trie of key/values
		}
		
		case FF2WeaponMod_RemoveAttrib:
		{
			//adt_array of strings
		}
		
		case FF2WeaponMod_Replace:
		{
			//adt_
		}
		
		case FF2WeaponMod_OnTakeDamage:
		{
		}
		
		case FF2WeaponMod_OnHit:
		{
		}
		
	}
	
	if (!change)
	{
		CloseHandle(data);
		return INVALID_HANDLE;
	}
	
	// set data
	
	ResetPack(data);
	return data;
}

SetWeaponAttribs(weapon, Handle:data)
{
	if (!IsValidEntity(weapon))
	{
		LogError("Weapon %d is invalid", weapon);
		return;
	}
	
	new attribCount = ReadPackCell(data);
	
	for (new i = 0; i < attribCount; i++)
	{
		new String:attribName[128];
		ReadPackString(data, attribName, sizeof(attribName));
		new attribValue = ReadPackCell(data);
		TF2Attrib_SetByName(weapon, attribName, float(attribValue));
	}
	
	ResetPack(data);
}

RemoveWeaponAttribs(weapon, Handle:data)
{
	if (!IsValidEntity(weapon))
	{
		LogError("Weapon %d is invalid", weapon);
		return;
	}
	
	new attribCount = ReadPackCell(data);
	
	for (new i = 0; i < attribCount; i++)
	{
		new String:attribName[128];
		ReadPackString(data, attribName, sizeof(attribName));
		TF2Attrib_RemoveByName(weapon, attribName);
	}
	
	ResetPack(data);
}

bool:ReplaceWeapon(client, slot, weapon, Handle:data)
{
	TF2_RemoveWeaponSlot(client, slot);
	
	new String:classname[64];
	ReadPackString(data, classname, sizeof(classname));

	new itemDefinitionIndex = ReadPackCell(data);
	new quality = ReadPackCell(data);
	new level = ReadPackCell(data);
	
	if (strlen(classname) == 0 || itemDefinitionIndex == 0 || quality == 0 || level == 0)
	{
		return false;
	}
	
	new Handle:newWeapon = TF2Items_CreateItem(OVERRIDE_ALL);
	TF2Items_SetClassname(newWeapon, classname);
	TF2Items_SetItemIndex(newWeapon, itemDefinitionIndex);
	TF2Items_SetQuality(newWeapon, quality);
	TF2Items_SetLevel(newWeapon, level);
	
	new attribCount = ReadPackCell(data);
	
	TF2Items_SetNumAttributes(newWeapon, attribCount);
	
	for (new i = 0; i < attribCount; ++i)
	{
		new attribId = ReadPackCell(data);
		new Float:value = ReadPackFloat(data);
		
		TF2Items_SetAttribute(newWeapon, i, attribId, value);
	}
	
	weapon = TF2Items_GiveNamedItem(client, newWeapon);
	
	EquipPlayerWeapon(client, weapon);
	
	CloseHandle(newWeapon);

	ResetPack(data);
	return true;
}

public OnClientDisconnect_Post(client)
{
	g_OldHealing[client] = 0;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (g_bActive && !GetConVarBool(g_Cvar_Crits) && IsBoss(client))
	{
		result = false;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

bool:IsBoss(client)
{
	return (GetBossIndex(client) != -1);
}

GetBossIndex(client)
{
	if (!g_bActive)
	{
		return -1;
	}
	
	for (new i = 0; i < g_CurrentBossCount; ++i)
	{
		if (g_CurrentBosses[i] == client)
		{
			return i;
		}
	}
	
	return -1;
}

GetBossMaxHealth(bossIndex)
{
	
}

GetBossMaxLives(bossIndex)
{
	
}

PrintToNonBosses(const String:message, ...)
{
	
}

/**
 * Called before players can move
 * Initial boss selection here.
 */
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled || !g_bFF2Map)
		return;

	g_CurrentRound++;
	
	if (g_CurrentRound == 1 && !g_bFirstRound)
		return;

	for (new i = 1; i <= MaxClients; i++)
	{
		g_BossFlags[i] = 0;
		for (new j = 0; j < _:FF2Stats; j++)
		{
			g_CurrentStats[i][j] = 0;
		}
	}

}

/**
 * Called when players unfreeze and can move around.  This is when the arena clock would start.
 * Force the boss back to the boss class and loadout here
 */
public Event_ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled || !g_bFF2Map)
		return;

	g_PlayersRemaining = GetTeamClientCount(_:g_OtherTeam);
	
	g_RoundStartTime = GetTime();
	// TODO fix boss here
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && TFTeam:GetClientTeam(i) == g_OtherTeam)
		{
			new userId = GetClientUserId(i);
			g_CurrentStats[i][FF2Stat_UserId] = userId;
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled && g_CurrentRound == 1 && !g_bFirstRound)
	{
		ChangeValveCvars();
	}
}

public Action:Event_ArenaWinPanel(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}

	new Handle:top = CreateArray();
	//new top[3];
	
	for (new i = 1; i < MaxClients; ++i)
	{
		if (!IsBoss(i))
		{
			new damage = g_CurrentStats[i][FF2Stat_Damage];
			g_CurrentStats[i][FF2Stat_Healing] = TF2_GetRoundScoreData(i, TF2Score_HealPoints);

			/*
			if (damage == 0)
			{
				continue;
			}
			*/
			
			
			new size = GetArraySize(top);
			
			new insertPoint = -1;
			
			for (new j = 0; j < 3; j++)
			{
				if (size == j)
				{
					insertPoint = j;
					break;
				}
				
				if (damage > GetArrayCell(top, j))
				{
					insertPoint = j;
					break;
				}
				
			}
			if (insertPoint > -1)
			{
				ShiftArrayUp(top, insertPoint);
				SetArrayCell(top, insertPoint, i);
			}
		}
	}
	
	ResizeArray(top, 3);
	
	new TFTeam:winner = TFTeam:GetEventInt(event, "winning_team");
	
	new currentPlayer;
	if (winner == g_BossTeam)
	{
		currentPlayer = 4;
	}
	else
	{
		currentPlayer = 1;
	}

	for (new i = 0; i < 3; i++)
	{
		decl String:player[9]; // in format "player_1"
		decl String:player_damage[16]; // in format "player_1_damage"
		decl String:player_healing[17]; // in format "player_1_healing"
		decl String:player_lifetime[17]; // in format "player_1_lifetime"
		decl String:player_kills[14]; // in format "player_1_kills"
		
		Format(player, sizeof(player), "%s%d", "player_", currentPlayer);
		
		Format(player_damage, sizeof(player_damage), "%s%s", player, "_damage");
		Format(player_healing, sizeof(player_healing), "%s%s", player, "_healing");
		Format(player_lifetime, sizeof(player_lifetime), "%s%s", player, "_lifetime");
		Format(player_kills, sizeof(player_kills), "%s%s", player, "_kills");
		
		new client = GetArrayCell(top, i);
		
		// TODO Fix these values
		SetEventInt(event, player, g_CurrentStats[client][FF2Stat_UserId]);
		SetEventInt(event, player_damage, g_CurrentStats[client][FF2Stat_Damage]);
		SetEventInt(event, player_healing, g_CurrentStats[client][FF2Stat_Healing]);
		SetEventInt(event, player_lifetime, g_CurrentStats[client][FF2Stat_Lifelength]);
		SetEventInt(event, player_kills, g_CurrentStats[client][FF2Stat_Points]);
		
		currentPlayer++;
	}
	
	return Plugin_Changed;
}

/**
 * Prepare the next round for FF2
 */
PrepareFF2()
{
	g_bActive = true;
	ChangeValveCvars();
}

ChangeValveCvars()
{
	SetConVarBool(g_Cvar_ArenaQueue, false);
	SetConVarBool(g_Cvar_Autobalance, false);
	SetConVarInt(g_Cvar_UnbalanceLimit, 0);
	SetConVarBool(g_Cvar_FirstBlood, false);
	SetConVarInt(g_Cvar_ForceCamera, 0);
}

public CvarChange_ForceFalse(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!g_bEnabled)
	{
		return;
	}
	
	if (GetConVarBool(convar))
	{
		SetConVarBool(convar, false);
	}
}

public CvarChange_ForceZero(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!g_bEnabled)
	{
		return;
	}
	
	if (!GetConVarInt(convar))
	{
		SetConVarInt(convar, 0);
	}
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

public GetCharacterSets()
{
	ClearArray(g_Array_BossSets);
	new Handle:characterKv = OpenCharacterKv();
	
	do
	{
		decl String:charSet[SET_AND_BOSS_LENGTH];
		KvGetString(characterKv, NULL_STRING, charSet, sizeof(charSet));
		if (!StrEqual(charSet, ""))
		{
			PushArrayString(g_Array_BossSets, charSet);
		}
	} while (KvGotoNextKey(characterKv));

	CloseHandle(characterKv);
}

public bool:DownloadBossSet(String:setName[])
{
	new Handle:characterKv = OpenCharacterKv();
	
	if (!KvJumpToKey(characterKv, setName) || !KvGotoFirstSubKey(characterKv, false))
	{
		return false;
	}
	
	do
	{
		decl String:bossName[SET_AND_BOSS_LENGTH];
		KvGetString(characterKv, NULL_STRING, bossName, SET_AND_BOSS_LENGTH);
		if (!StrEqual(bossName, ""))
		{
			decl String:bossFile[PLATFORM_MAX_PATH];
			Format(bossFile, PLATFORM_MAX_PATH, "%s/%s.%s", g_ConfigPath, bossName, ".cfg");
			// We have the boss name
			new Handle:bossKv = CreateKeyValues("Character");
			if (!FileToKeyValues(bossKv, bossFile))
			{
				CloseHandle(bossKv);
				continue;
			}
			
			// TODO Load the various sections
		}
	} while (KvGotoNextKey(characterKv, false));
	
	CloseHandle(characterKv);
	return true;
}

public Handle:OpenCharacterKv()
{
	decl String:characterFile[PLATFORM_MAX_PATH];
	Format(characterFile, PLATFORM_MAX_PATH, "%s/%s", g_ConfigPath, "characters.cfg");
	
	new Handle:characterKv = CreateKeyValues("Boss Sets");
	if (!FileToKeyValues(characterKv, characterFile))
	{
		CloseHandle(characterKv);
		SetFailState("Could not locate boss character set file: %s", characterFile);
	}

	return characterKv;
}

public Handle:LoadBoss(client, String:bossName[])
{
	//TODO
	
}

