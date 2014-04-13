//Freak Fortress 2 v2
//By Powerlord
//Stripped and rewritten by WildCard65.

//Freak Fortress 2 v1
//By Rainbolt Dash: programmer, modeller, mapper, painter.
//Author of Demoman The Pirate: http://www.randomfortress.ru/thepirate/
//And one of two creators of Floral Defence: http://www.polycount.com/forum/showthread.php?t=73688
//And author of VS Saxton Hale Mode

#include <freak_fortress_2>

// STEAM_0:0:123456789 plus terminator
#define STEAM_LENGTH 20
#define SOUND_SHIELD_ZAP "player/spy_shield_break.wav"
#define PLUGIN_VERSION "2.0 alpha"
#define REPAIR_RATES "2,4,8"
#define REPAIR_DISTANCE 300
#define REPAIR_TICK 0.5
#define REPAIR_SENTRY 1
#define GHOST_ALPHA 0
#define GHOST_TAUNT 0
#define GHOST_TP 1
#define GHOST_MODE 3
#define GHOST_ENABLED 1
#define DEBUG

#if defined _rtd_included
//RTD defines
#define PLUGIN_VERSION "2.0 alpha"
#define RTD_DISABLEDPERKS "toxic,noclip,instant,tinyplayer"
#define RTD_TIMELIMIT 30
#define RTD_MODE 0
#define RTD_CHANCE 0.25
#define RTD_HEALTH 2000
#define RTD_SETUP 1

//RTD Cvars
new Handle:g_hFF2RTD;
new Handle:g_hRTD_Mode;
new Handle:g_hRTD_TimeLimit;
new Handle:g_hRTD_Chance;
new Handle:g_hRTD_DChance;
new Handle:g_hRTD_Health;
new Handle:g_hRTD_Setup;
new Handle:g_hRTD_DisabledPerks;

//RTD Vars
new bool:g_bBossRTD=false;
#endif

#if defined _goomba_included_
//Goomba CVars
new Handle:g_hFF2GoombaMultiplier;
new Handle:g_hFF2GoombaJumpPower;

//Goomba Vars
new Float:g_fGoomaJump=500.0;
new Float:g_fGoombaDMGMultiplier=0.05;
#endif

#if defined _smac_included
//Smac Forward
new Handle:g_hSmacSafety;
#endif

//Cvars:
new Handle:g_hFF2Version;
new Handle:g_hFF2Enabled;
new Handle:g_hFF2SpyDamage;

//Incless plugin support related cvars:
new Handle:g_hBRDistance;
new Handle:g_hBRRepairTick;
new Handle:g_hBRRepairRates;
new Handle:g_hBRRepairSentry;
new Handle:g_hGMEnabled;
new Handle:g_hGMThirdPerson;
new Handle:g_hGMPowers;
new Handle:g_hGMTaunt;
new Handle:g_hGMAlpha;

//Vars
new bool:g_bCEnabled=true;
new bool:g_bMEnabled=false;
new bool:g_bAbilityUsed=false;
new Float:g_fSpyDamage=0.1;
new Handle:g_hMaps;
new Handle:g_hSubPlugins;

enum FF2PlayerPrefs
{
	FF2PlayerPref_PlayMusic,
	FF2PlayerPref_PlayVoice,
	FF2PlayerPref_ShowClassInfo,
	FF2PlayerPref_HideHud,
}

enum FF2Stats
{
	FF2Stat_UserId=0,
	FF2Stat_Damage,
	FF2Stat_Healing,
	FF2Stat_Lifelength,
	FF2Stat_Points,
};

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
	decl String:gameDir[8];
	GetGameFolderName(gameDir, sizeof(gameDir));
	if (!StrEqual(gameDir, "tf"))
	{
		Format(error, err_max, "Freak Fortress 2 only works in TF2.");
		return APLRes_Failure;
	}
	RegPluginLibrary("freak_fortress_2");
	CreateNative("FF2_IsEnabled", Native_FF2_IsEnabled);
	CreateNative("CreateFF2Cvar", Native_CreateFF2Cvar);
	CreateNative("IsFF2Map", Native_IsFF2Map);
	CreateNative("RegisterSubPlugin", Native_RegisterSubPlugin);
	#if defined _smac_included
	g_hSmacSafety = CreateGlobalForward("CheckCvar", ET_Event, Param_String);
	#endif
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hMaps = CreateArray(PLATFORM_MAX_PATH);
	ParseMaps();
	LogMessageEx("Freak Fortress 2 V%s loaded.", PLUGIN_VERSION);
	g_hFF2Version = CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version.", FCVAR_REPLICATED|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_hFF2Enabled = CreateConVar("ff2_enabled", "1", "Can we play FF2? 1=yes; 0=no", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hFF2SpyDamage = CreateConVar("ff2_spydamage", "0.1", "How much damage do spy backstabs do to hale.", FCVAR_PLUGIN, true, 0.01, true, 1.0);
	HookConVarChange(g_hFF2Version, CvarChange);
	HookConVarChange(g_hFF2Enabled, CvarChange);
	HookConVarChange(g_hFF2SpyDamage, CvarChange);
	#if defined _rtd_included
	g_hFF2RTD = CreateConVar("ff2_bossrtd", "0", "Allow the boss to roll the dice. 1=Yes 0=No", FCVAR_PLUGIN,  true, 0.0, true, 1.0);
	HookConVarChange(g_hFF2RTD, RTDCvars);
	#endif
	#if defined _goomba_included_
	g_hFF2GoombaMultiplier = CreateConVar("ff2_goombadmg", "0.05", "Damage multiplier to override goomba with when hale is stomped.", FCVAR_PLUGIN, true, 0.01, true, 1.0);
	g_hFF2GoombaJumpPower = CreateConVar("ff2_goombajump", "500.0", "Jump power to override goomba with when the hale is stomped.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hFF2GoombaMultiplier, GoombaCvars);
	HookConVarChange(g_hFF2GoombaJumpPower, GoombaCvars);
	#endif
	/*g_Cvar_ArenaQueue = FindConVar("tf_arena_use_queue");
	g_Cvar_UnbalanceLimit = FindConVar("mp_teams_unbalance_limit");
	g_Cvar_Autobalance = FindConVar("mp_autobalance");
	g_Cvar_FirstBlood = FindConVar("tf_arena_first_blood");
	g_Cvar_ForceCamera = FindConVar("mp_forcecamera");
	g_Cvar_Medieval = FindConVar("tf_medieval");

	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_round_start", Event_ArenaRoundStart);
	HookEvent("arena_win_panel", Event_ArenaWinPanel, EventHookMode_Pre);
	HookEvent("post_inventory_application", Event_PostInventoryApplication);*/
	AutoExecConfig(true, "FreakFortress2");
	decl String:oldversion[64];
	GetConVarString(g_hFF2Version, oldversion, sizeof(oldversion));
	if(strcmp(oldversion, PLUGIN_VERSION, false)!=0)
	{
		LogError("[FF2] Warning: Your config may be outdated. Back up tf/cfg/sourcemod/FreakFortress2.cfg and delete it, and this plugin will generate a new one that you can then modify to your original values.");
	}
	g_bCEnabled = GetConVarBool(g_hFF2Enabled);
}

public OnPluginEnd()
{
	CloseHandle(g_hMaps);
}

public OnMapStart()
{
	CheckMap();
	if (g_bMEnabled)
	{
	}
}

public OnMapEnd()
{
}

CheckMap()
{
	decl String:mapName[PLATFORM_MAX_PATH], String:strBuffer[PLATFORM_MAX_PATH];
	GetCurrentMap(mapName, PLATFORM_MAX_PATH);
	for (new i = 0; i < GetArraySize(g_hMaps); i++)
	{
		GetArrayString(g_hMaps, i, strBuffer, PLATFORM_MAX_PATH);
		if (StrContains(strBuffer, "!") == 0)
		{
			ReplaceString(strBuffer, PLATFORM_MAX_PATH, "!", "");
			if (StrContains(mapName, strBuffer) == 0)
			{
				PrintToServer("Denying map %s", mapName);
				g_bMEnabled = false;
			}
		}
		else if (StrContains(mapName, strBuffer) == 0)
		{
			g_bMEnabled = true;
		}
	}
	g_bMEnabled = false;
}

ParseMaps()
{
	decl String:mapsPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, mapsPath, PLATFORM_MAX_PATH, "%s%s", FF2_CONFIGS, FF2_MAPFILE);
	if (!FileExists(mapsPath))
	{
		g_bMEnabled = false;
		SetFailState("We can't find file %s", mapsPath);
	}
	new Handle:mapHandle = OpenFile(mapsPath, "r");
	decl String:mapName[PLATFORM_MAX_PATH];
	while (!IsEndOfFile(mapHandle))
	{
		ReadFileLine(mapHandle, mapName, PLATFORM_MAX_PATH);
		PushArrayString(g_hMaps, mapName);
	}
	CloseHandle(mapHandle);
}

public OnConfigsExecuted()
{
	if (g_bMEnabled)
	{
		g_fSpyDamage = GetConVarFloat(g_hFF2SpyDamage);
		#if defined _rtd_included
		g_bBossRTD = GetConVarBool(g_hFF2RTD);
		#endif
		#if defined _goomba_included
		g_fGoomaJump = GetConVarFloat(g_hFF2GoombaJumpPower);
		g_fGoombaDMGMultiplier = GetConVarFloat(g_hFF2GoombaMultiplier);
		#endif
		#if defined _rtd_included
		SetupRTD();
		#endif
		SetupInclessSupports();
	}
}

SetupInclessSupports()
{
	g_hBRDistance = FindConVar("br_max_distance");
	g_hBRRepairSentry = FindConVar("br_repair_sentry");
	g_hBRRepairTick = FindConVar("br_tick_seconds");
	g_hBRRepairRates = FindConVar("br_repair_rates");
	g_hGMEnabled = FindConVar("ghostmode_enablemode");
	g_hGMThirdPerson = FindConVar("ghostmode_thirdperson");
	g_hGMPowers = FindConVar("ghostmode_powers");
	g_hGMTaunt = FindConVar("ghostmode_taunt");
	g_hGMAlpha = FindConVar("ghostmode_alpha");
	if (g_hBRDistance != INVALID_HANDLE)
	{
		SetConVarInt(g_hBRDistance, REPAIR_DISTANCE);
		HookConVarChange(g_hBRDistance, CvarChange);
	}
	if (g_hBRRepairSentry != INVALID_HANDLE)
	{
		SetConVarInt(g_hBRRepairSentry, REPAIR_SENTRY);
		HookConVarChange(g_hBRRepairSentry, CvarChange);
	}
	if (g_hBRRepairRates != INVALID_HANDLE)
	{
		SetConVarString(g_hBRRepairRates, REPAIR_RATES);
		HookConVarChange(g_hBRRepairRates, CvarChange);
	}
	if (g_hBRRepairTick != INVALID_HANDLE)
	{
		SetConVarFloat(g_hBRRepairTick, REPAIR_TICK);
		HookConVarChange(g_hBRRepairTick, CvarChange);
	}
	if (g_hGMEnabled != INVALID_HANDLE)
	{
		SetConVarInt(g_hGMEnabled, GHOST_ENABLED);
		HookConVarChange(g_hGMEnabled, CvarChange);
	}
	if (g_hGMThirdPerson != INVALID_HANDLE)
	{
		SetConVarInt(g_hGMThirdPerson, GHOST_TP);
		HookConVarChange(g_hGMThirdPerson, CvarChange);
	}
	if (g_hGMPowers != INVALID_HANDLE)
	{
		SetConVarInt(g_hGMPowers, GHOST_MODE);
		HookConVarChange(g_hGMPowers, CvarChange);
	}
	if (g_hGMTaunt != INVALID_HANDLE)
	{
		SetConVarInt(g_hGMTaunt, GHOST_TAUNT);
		HookConVarChange(g_hGMTaunt, CvarChange);
	}
	if (g_hGMAlpha != INVALID_HANDLE)
	{
		SetConVarInt(g_hGMAlpha, GHOST_ALPHA);
		HookConVarChange(g_hGMAlpha, CvarChange);
	}
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hFF2Enabled)
		g_bCEnabled = bool:StringToInt(newValue);
	if (convar == g_hFF2SpyDamage)
		g_fSpyDamage = StringToFloat(newValue);
	if (convar == g_hBRDistance && StringToInt(newValue) != REPAIR_DISTANCE)
		SetConVarInt(g_hBRDistance, REPAIR_DISTANCE);
	if (convar == g_hBRRepairSentry && StringToInt(newValue) != REPAIR_SENTRY)
		SetConVarInt(g_hBRRepairSentry, REPAIR_SENTRY);
	if (convar == g_hBRRepairTick && StringToFloat(newValue) != REPAIR_TICK)
		SetConVarFloat(g_hBRRepairTick, REPAIR_TICK);
	if (convar == g_hGMEnabled && StringToInt(newValue) != GHOST_ENABLED)
		SetConVarInt(g_hGMEnabled, GHOST_ENABLED);
	if (convar == g_hGMThirdPerson && StringToInt(newValue) != GHOST_TP)
		SetConVarInt(g_hGMThirdPerson, GHOST_TP);
	if (convar == g_hGMPowers && StringToInt(newValue) != GHOST_MODE)
		SetConVarInt(g_hGMPowers, GHOST_MODE);
	if (convar == g_hGMTaunt && StringToInt(newValue) != GHOST_TAUNT)
		SetConVarInt(g_hGMTaunt, GHOST_TAUNT);
	if (convar == g_hGMAlpha && StringToInt(newValue) != GHOST_ALPHA)
		SetConVarInt(g_hGMAlpha, GHOST_ALPHA);
	if (convar == g_hBRRepairRates && !StrEqual(newValue, REPAIR_RATES))
		SetConVarString(g_hBRRepairRates, REPAIR_RATES);
	if (convar == g_hFF2Version && !StrEqual(newValue, PLUGIN_VERSION))
	{
		LogMessage("PLEASE DO NOT CHANGE ff2_version!");
		SetConVarString(g_hFF2Version, PLUGIN_VERSION, true, true);
	}
}

#if defined _smac_included
public Action:SMAC_OnCheatDetected(client, const String:module[], DetectionType:type, Handle:info)
{
	if (!g_bCEnabled || !g_bMEnabled)
		return Plugin_Continue;
	if (type == Detection_CvarViolation && g_bAbilityUsed)
	{
		decl String:CVarName[256];
		KvGetString(info, "cvar", CVarName, sizeof(CVarName));
		new Action:result = Plugin_Continue;
		Call_StartForward(g_hSmacSafety);
		Call_PushString(CVarName);
		Call_Finish(_:result);
		return result;
	}
	return Plugin_Continue;
}
#endif

#if defined _rtd_included
SetupRTD()
{
	g_hRTD_TimeLimit = FindConVar("sm_rtd_timelimit");
	g_hRTD_Mode = FindConVar("sm_rtd_mode");
	g_hRTD_Chance = FindConVar("sm_rtd_chance");
	g_hRTD_Health = FindConVar("sm_rtd_health");
	g_hRTD_DChance = FindConVar("sm_rtd_dchance");
	g_hRTD_DisabledPerks = FindConVar("sm_rtd_disabled");
	g_hRTD_Setup = FindConVar("sm_rtd_setup");
	if (g_hRTD_TimeLimit != INVALID_HANDLE)
	{
		SetConVarInt(g_hRTD_TimeLimit, RTD_TIMELIMIT);
		HookConVarChange(g_hRTD_TimeLimit, RTDCvars);
	}
	if (g_hRTD_Mode != INVALID_HANDLE)
	{
		SetConVarInt(g_hRTD_Mode, RTD_MODE);
		HookConVarChange(g_hRTD_Mode, RTDCvars);
	}
	if (g_hRTD_Chance != INVALID_HANDLE)
	{
		SetConVarFloat(g_hRTD_Chance, RTD_CHANCE);
		HookConVarChange(g_hRTD_Chance, RTDCvars);
	}
	if (g_hRTD_DChance != INVALID_HANDLE)
	{
		SetConVarFloat(g_hRTD_DChance, RTD_CHANCE);
		HookConVarChange(g_hRTD_DChance, RTDCvars);
	}
	if (g_hRTD_Health != INVALID_HANDLE)
	{
		SetConVarInt(g_hRTD_Health, RTD_HEALTH);
		HookConVarChange(g_hRTD_Health, RTDCvars);
	}
	if (g_hRTD_Health != INVALID_HANDLE)
	{
		SetConVarInt(g_hRTD_Health, RTD_HEALTH);
		HookConVarChange(g_hRTD_Health, RTDCvars);
	}
	if (g_hRTD_Setup != INVALID_HANDLE)
	{
		SetConVarInt(g_hRTD_Setup, RTD_SETUP);
		HookConVarChange(g_hRTD_Setup, RTDCvars);
	}
}

public RTDCvars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hFF2RTD)
		g_bBossRTD = bool:StringToInt(newValue);
	if (convar == g_hRTD_Mode && StringToInt(newValue) != RTD_MODE)
		SetConVarInt(g_hRTD_Mode, RTD_MODE);
	if (convar == g_hRTD_TimeLimit && StringToInt(newValue) != RTD_TIMELIMIT)
		SetConVarInt(g_hRTD_TimeLimit, RTD_TIMELIMIT);
	if (convar == g_hRTD_DChance && StringToFloat(newValue) != RTD_CHANCE)
		SetConVarInt(g_hRTD_DChance, RTD_TIMELIMIT);
	if (convar == g_hRTD_Chance && StringToFloat(newValue) != RTD_CHANCE)
		SetConVarInt(g_hRTD_Chance, RTD_TIMELIMIT);
	if (convar == g_hRTD_Health && StringToInt(newValue) != RTD_HEALTH)
		SetConVarInt(g_hRTD_Health, RTD_HEALTH);
	if (convar == g_hRTD_Setup && StringToInt(newValue) != RTD_SETUP)
		SetConVarInt(g_hRTD_Setup, RTD_SETUP);
	if (convar == g_hRTD_DisabledPerks && !StrEqual(newValue, RTD_DISABLEDPERKS))
		SetConVarString(g_hRTD_DisabledPerks, RTD_DISABLEDPERKS);
}

public Action:RTD_CanRollDice(client)
{
	if (!g_bCEnabled || !g_bMEnabled)
		return Plugin_Continue;
	//TODO: Code function to check if client is the boss.
	if (!g_bBossRTD)
	{
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
#endif

#if defined _goomba_included_
public GoombaCvars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hFF2GoombaJumpPower)
		g_fGoomaJump = GetConVarFloat(g_hFF2GoombaJumpPower);
	if (convar == g_hFF2GoombaMultiplier)
		g_fGoombaDMGMultiplier = GetConVarFloat(g_hFF2GoombaMultiplier);
}

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower)
{
	if (!g_bCEnabled || !g_bMEnabled)
		return Plugin_Continue;
	//TODO: Code function to check if attacker or victim is the boss.
	JumpPower = g_fGoomaJump;
	damageBonus = 0.0;
	damageMultiplier = g_fGoombaDMGMultiplier;
	return Plugin_Changed;
}
#endif

#if defined _Amplifier_included
public Action:OnAmplify(builder,client,TFCond:condition)
{
	if (!g_bCEnabled || !g_bMEnabled)
		return Plugin_Continue;
	if (TF2_GetPlayerClass(client) == TFClass_Engineer && !TF2_IsPlayerInCondition(client, TFCond_Buffed))
		TF2_AddCondition(client, TFCond_Buffed, 0.3);
	return Plugin_Continue;
}
#endif

public Native_FF2_IsEnabled(Handle:plugin, numParams)
{
	if (!g_bCEnabled || !g_bMEnabled)
		return _:false;
	return _:true;
}

public Native_CreateFF2Cvar(Handle:plugin, numParams)
{
	if (numParams < 3)
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid # of parameters, expected min 3 got %i", numParams);
	new nlength, dvlength, dlength, flags, Float:min, Float:max, bool:hMin, bool:hMax;
	new ConVarChanged:func;
	GetNativeStringLength(1, nlength);
	GetNativeStringLength(2, dvlength);
	GetNativeStringLength(4, dlength);
	decl String:cName[nlength], String:cDefaultValue[dvlength], String:desc[dlength];
	GetNativeString(1, cName, nlength);
	GetNativeString(2, cDefaultValue, dvlength);
	func = GetNativeCell(3);
	flags = GetNativeCell(5);
	hMin = bool:GetNativeCell(6);
	min = Float:GetNativeCell(7);
	hMax = bool:GetNativeCell(8);
	max = Float:GetNativeCell(9);
	new Handle:tempCvar = CreateConVar(cName, cDefaultValue, desc, flags, hMin, min, hMax, max);
	HookConVarChange(tempCvar, func);
	return _:tempCvar;
}

public Native_IsFF2Map(Handle:plugin, numParams)
{
	return _:g_bMEnabled;
}

public Native_RegisterSubPlugin(Handle:plugin, numParams)
{
	SetNativeCellRef(3, FF2_SubReasons_NotCoded);
	return _:false; //TODO: Code subplugin registering.
}
