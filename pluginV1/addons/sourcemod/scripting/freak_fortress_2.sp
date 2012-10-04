//===Freak Fortress 2===
//
//By Rainbolt Dash: programmer, modeller, mapper, painter.
//Author of Demoman The Pirate: http://www.randomfortress.ru/thepirate/
//And one of two creators of Floral Defence: http://www.polycount.com/forum/showthread.php?t=73688
//And author of VS Saxton Hale Mode

//Plugin thread on AlliedMods: http://forums.alliedmods.net/showthread.php?t=182108

//Updated by Otokiru, Powerlord, and RavensBro after Rainbolt Dash got sucked into DOTA2

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <clientprefs>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS

#define ME 2048
#define MAXSPECIALS 64
#define MAXRANDOMS 16
#define PLUGIN_VERSION "1.07"

#define SOUNDEXCEPT_MUSIC 0
#define SOUNDEXCEPT_VOICE 1

#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255
#define MONOCULUS "eyeball_boss"

#if defined _steamtools_included
new bool:steamtools = false;
#endif

new chkFirstHale;
new bool:b_allowBossChgClass = false;
new bool:b_BossChgClassDetected = false;
new OtherTeam=2;
new BossTeam=3;
new FF2RoundState;
new playing;
new healthcheckused;
new RedAlivePlayers;
new RoundCount;
new Special[MAXPLAYERS+1];
new Incoming[MAXPLAYERS+1];
new MusicIndex;

new Damage[MAXPLAYERS + 1];
new curHelp[MAXPLAYERS + 1];	
new uberTarget[MAXPLAYERS + 1];

#define FF2FLAG_UBERREADY				(1 << 1)		//Used when medic says "I'm charged!"
#define FF2FLAG_ISBUFFED				(1 << 2)		//Used when soldier uses backup's buff.
#define FF2FLAG_CLASSTIMERDISABLED 		(1 << 3)		//Used to prevent clients' timer.
#define FF2FLAG_HUDDISABLED				(1 << 4)		//Used to prevent custom hud from clients' timer.
#define FF2FLAG_BOTRAGE					(1 << 5)		//Used by bots to use Boss' rage.
#define FF2FLAG_TALKING					(1 << 6)		//Used by Bosses with "sound_block_vo" to disable block for some lines.
#define FF2FLAG_ALLOWSPAWNINBOSSTEAM	(1 << 7)		//Used to allow spawn players in Boss' team.
#define FF2FLAG_USEBOSSTIMER			(1 << 8)		//Used to prevent Boss' timer.
#define FF2FLAG_USINGABILITY			(1 << 9)		//Used to prevent Boss' hints about abilities buttons.
#define FF2FLAG_CLASSHELPED				(1 << 10)
#define FF2FLAG_HASONGIVED				(1 << 11)
#define FF2FLAGS_SPAWN				~FF2FLAG_UBERREADY & ~FF2FLAG_ISBUFFED & ~FF2FLAG_TALKING & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM & FF2FLAG_USEBOSSTIMER & ~FF2FLAG_USINGABILITY
new FF2flags[MAXPLAYERS + 1];

new Boss[MAXPLAYERS+1];
new BossHealthMax[MAXPLAYERS+1];
new BossHealth[MAXPLAYERS+1];
new BossHealthLast[MAXPLAYERS+1];
new BossLives[MAXPLAYERS+1];
new BossLivesMax[MAXPLAYERS+1];
new Float:BossCharge[MAXPLAYERS+1][8];
new Float:Stabbed[MAXPLAYERS+1];
new Float:KSpreeTimer[MAXPLAYERS+1];
new KSpreeCount[MAXPLAYERS+1];
new Float:GlowTimer[MAXPLAYERS+1];
new TFClassType:LastClass[MAXPLAYERS+1];
new shortname[MAXPLAYERS+1];			//new SerPointsToZeroTarget[MAXPLAYERS+1];

new timeleft;

new Handle:cvarVersion;
new Handle:cvarPointDelay;
new Handle:cvarAnnounce;
new Handle:cvarEnabled;
new Handle:cvarAliveToEnable;
new Handle:cvarPointType;

new Handle:cvarCrits;
new Handle:cvarFirstRound;
new Handle:cvarCircuitStun;
new Handle:cvarSpecForceBoss;
new Handle:cvarUseCountdown;
new Handle:cvarEnableEurekaEffect;
new Handle:cvarForceBossTeam;

new Handle:cvarHealthBar;

new Handle:FF2Cookies;		// "queue_points music monologues classinfo rmb_help reload_help"
/*
new Handle:PointCookie;
new Handle:MusicCookie;
new Handle:VoiceCookie;
new Handle:ClassinfoCookie
*/

new Handle:jumpHUD;
new Handle:rageHUD;
new Handle:healthHUD;
new Handle:timeleftHUD;
new Handle:abilitiesHUD;
new Handle:doorchecktimer;

new bool:Enabled = true;
new bool:Enabled2 = true;
new PointDelay = 6;
new Float:Announce = 120.0;
new AliveToEnable = 5;
new PointType = 0;
new bool:BossCrits = true;
new Float:circuitStun = 0.0;
new UseCountdown = 120;
new bool:SpecForceBoss = false;

new Handle:MusicTimer;
new Handle:BossInfoTimer[MAXPLAYERS+1][2];
new Handle:DrawGameTimer;

new RoundCounter;
new botqueuepoints = 0;
new Float:HPTime;
new String:currentmap[99];
new bool:checkdoors = false;
new bool:bMedieval;
new FF2CharSet;
new String:FF2CharSetStr[42];

new tf_arena_use_queue;
new mp_teams_unbalance_limit;
new tf_arena_first_blood;
new mp_forcecamera;
new Float:tf_scout_hype_pep_max;
new Handle:cvarNextmap;
new bool:isSubPluginsEnabled;

// Healthbar-related things
new g_healthBar = -1;
new g_Monoculus = -1; // Track Monoculus for health bar

static const String:ff2versiontitles[][] = 		//the last line of this is what determines the displayed plugin version
{
	"1.0",
	"1.01",
	"1.01",
	"1.02",
	"1.03",
	"1.04",
	"1.05",
	"1.05",
	"1.06",
	"1.06c",
	"1.06d",
	"1.06e",
	"1.06f",
	"1.06g",
	"1.06h",
	"1.7",
	"1.7",
	"1.7",
	"1.7"
};

static const String:ff2versiondates[][] = 
{
	"6 April 2012",
	"14 April 2012",
	"17 April 2012",
	"17 April 2012",
	"19 April 2012",
	"21 April 2012",
	"29 April 2012",
	"29 April 2012",
	"1 May 2012",
	"22 June 2012",
	"3 July 2012",
	"24 Aug 2012",
	"5 Sep 2012",
	"5 Sep 2012",
	"6 Sep 2012",
	"8 Oct 2012",
	"8 Oct 2012",
	"8 Oct 2012",
	"8 Oct 2012"
};

static const maxversion = (sizeof(ff2versiontitles) - 1);

new Specials = 0;
new Handle:BossKV[MAXSPECIALS];
new Handle:PreAbility;
new Handle:OnAbility;
new Handle:OnMusic;
new Handle:OnTriggerHurt;
new Handle:OnSpecialSelected;
new Handle:OnAddQueuePoints;

new bool:bBlockVoice[MAXSPECIALS];
new Float:BossSpeed[MAXSPECIALS];
new Float:BossRageDamage[MAXSPECIALS];
new String:ChancesString[64];

public Plugin:myinfo = {
	name = "Freak Fortress 2",
	author = "Rainbolt Dash, FlaminSarge",
	description = "RUUUUNN!! COWAAAARRDSS!",
	version = PLUGIN_VERSION,
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("FF2_IsFF2Enabled",Native_IsEnabled);
	CreateNative("FF2_GetBossUserId",Native_GetBoss);
	CreateNative("FF2_GetBossIndex",Native_GetIndex);
	CreateNative("FF2_GetBossTeam",Native_GetTeam);
	CreateNative("FF2_GetBossSpecial",Native_GetSpecial);
	CreateNative("FF2_GetBossMax",Native_GetHealth);
	CreateNative("FF2_GetBossMaxHealth",Native_GetHealthMax);
	CreateNative("FF2_GetBossCharge",Native_GetBossCharge);
	CreateNative("FF2_SetBossCharge",Native_SetBossCharge);
	CreateNative("FF2_GetClientDamage",Native_GetDamage);
	CreateNative("FF2_GetRoundState",Native_GetRoundState);
	CreateNative("FF2_GetSpecialKV",Native_GetSpecialKV);
	CreateNative("FF2_StopMusic",Native_StopMusic);
	CreateNative("FF2_GetRageDist",Native_GetRageDist);
	CreateNative("FF2_HasAbility",Native_HasAbility); 	
	CreateNative("FF2_DoAbility",Native_DoAbility); 	
	CreateNative("FF2_GetAbilityArgument",Native_GetAbilityArgument); 	
	CreateNative("FF2_GetAbilityArgumentFloat",Native_GetAbilityArgumentFloat); 	
	CreateNative("FF2_GetAbilityArgumentString",Native_GetAbilityArgumentString); 	
	CreateNative("FF2_RandomSound",Native_RandomSound);
	CreateNative("FF2_GetFF2flags",Native_GetFF2flags);
	CreateNative("FF2_SetFF2flags",Native_SetFF2flags);
	CreateNative("FF2_GetQueuePoints",Native_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints",Native_SetQueuePoints);
	
	PreAbility = CreateGlobalForward("FF2_PreAbility",ET_Hook,Param_Cell,Param_String,Param_String,Param_Cell,Param_CellByRef);
	OnAbility = CreateGlobalForward("FF2_OnAbility",ET_Hook,Param_Cell,Param_String,Param_String,Param_Cell);
	OnMusic = CreateGlobalForward("FF2_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
	OnTriggerHurt = CreateGlobalForward("FF2_OnTriggerHurt",ET_Hook,Param_Cell,Param_Cell,Param_FloatByRef);
	OnSpecialSelected = CreateGlobalForward("FF2_OnSpecialSelected",ET_Hook,Param_Cell,Param_CellByRef,Param_String);
	OnAddQueuePoints = CreateGlobalForward("FF2_OnAddQueuePoints",ET_Hook,Param_Array);
	
	RegPluginLibrary("freak_fortress_2");
	
	AskPluginLoad_VSH();
#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
#endif
	return APLRes_Success;
}

public OnPluginStart()
{
	LogMessage("=== Freak Fortress 2 Initializing - v.%s === ",ff2versiontitles[maxversion]);

	cvarVersion = CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarPointType = CreateConVar("ff2_point_type", "0", "Select condition to enable point (0 - alive players, 1 - time)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarPointDelay = CreateConVar("ff2_point_delay", "6", "Addition (for each player) delay before point's activation.", FCVAR_PLUGIN);
	cvarAliveToEnable = CreateConVar("ff2_point_alive", "5", "Enable control points when there are X people left alive.", FCVAR_PLUGIN);
	cvarAnnounce = CreateConVar("ff2_announce", "120.0", "Info about mode will show every X seconds. Must be greater than 1.0 to show.", FCVAR_PLUGIN, true, 0.0);
	cvarEnabled = CreateConVar("ff2_enabled", "1", "Do you really want set it to 0?", FCVAR_PLUGIN|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	cvarCrits = CreateConVar("ff2_crits", "1", "Can Boss get crits?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarFirstRound = CreateConVar("ff2_first_round", "0", "Disable(0) or Enable(1) FF2 in 1st round.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarCircuitStun = CreateConVar("ff2_circuit_stun", "2", "0 to disable Short Circuit stun, > 0 to make it stun Boss for x seconds", FCVAR_PLUGIN, true, 0.0);
	cvarUseCountdown = CreateConVar("ff2_countdown", "120", "Seconds of deathly countdown (begins when only 1 enemy lefts)", FCVAR_PLUGIN);
	cvarSpecForceBoss = CreateConVar("ff2_spec_force_boss", "0", "Spectators are allowed in Boss' queue.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarEnableEurekaEffect = CreateConVar("ff2_enable_eureka", "0", "1- allow Eureka Effect, else disallow", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarForceBossTeam = CreateConVar("ff2_force_team", "0", "0- Use plugin logic, 1- random team, 2- red, 3- blue", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	
	cvarHealthBar = CreateConVar("ff2_health_bar", "1", "Show boss health bar", FCVAR_PLUGIN, true, 0.0, true, 1.0); // Added by Powerlord
	HookConVarChange(cvarHealthBar, HealthbarEnableChanged);

	HookEvent("player_changeclass", OnChangeClass);
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("teamplay_round_win", event_round_end);
	HookEvent("player_changeclass", event_changeclass);
	HookEvent("player_spawn", event_player_spawn, EventHookMode_Pre);
	HookEvent("player_death", event_player_death, EventHookMode_Pre);
	HookEvent("player_chargedeployed", event_uberdeployed);
	HookEvent("player_hurt", event_hurt,EventHookMode_Pre);
	HookEvent("object_destroyed", event_destroy, EventHookMode_Pre);
	HookEvent("object_deflected", event_deflect, EventHookMode_Pre);
	HookUserMessage(GetUserMessageId("PlayerJarated"), event_jarate);
	HookConVarChange(cvarEnabled, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarAnnounce, CvarChange);
	HookConVarChange(cvarPointType, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarAliveToEnable, CvarChange);
	HookConVarChange(cvarCrits, CvarChange);
	HookConVarChange(cvarCircuitStun, CvarChange);
	HookConVarChange(cvarUseCountdown, CvarChange);
	HookConVarChange(cvarSpecForceBoss, CvarChange);
	cvarNextmap=FindConVar("sm_nextmap");
	HookConVarChange(cvarNextmap,CvarChangeNextmap);

	RegConsoleCmd("ff2", FF2Panel);
	RegConsoleCmd("ff2_hp", Command_GetHPCmd);
	RegConsoleCmd("ff2hp", Command_GetHPCmd);
	RegConsoleCmd("ff2_next", QueuePanelCmd);
	RegConsoleCmd("ff2next", QueuePanelCmd);
	RegConsoleCmd("ff2_classinfo", HelpPanel2Cmd);
	RegConsoleCmd("ff2classinfo", HelpPanel2Cmd);
	RegConsoleCmd("ff2_new", NewPanelCmd);
	RegConsoleCmd("ff2new", NewPanelCmd);
	RegConsoleCmd("ff2music", MusicTogglePanelCmd);
	RegConsoleCmd("ff2_music", MusicTogglePanelCmd);
	RegConsoleCmd("ff2voice", VoiceTogglePanelCmd);
	RegConsoleCmd("ff2_voice", VoiceTogglePanelCmd);
	RegConsoleCmd("ff2_resetpoints", ResetQueuePointsCmd);
	RegConsoleCmd("ff2resetpoints", ResetQueuePointsCmd);
	RegAdminCmd("ff2_resetqueuepoints", ResetQueuePointsCmd, 0);
	RegAdminCmd("ff2_resetq", ResetQueuePointsCmd, 0);
	
	RegConsoleCmd("hale", FF2Panel);
	RegConsoleCmd("hale_hp", Command_GetHPCmd);
	RegConsoleCmd("halehp", Command_GetHPCmd);
	RegConsoleCmd("hale_next", QueuePanelCmd);
	RegConsoleCmd("halenext", QueuePanelCmd);
	RegConsoleCmd("hale_classinfo", HelpPanel2Cmd);
	RegConsoleCmd("haleclassinfo", HelpPanel2Cmd);
	RegConsoleCmd("hale_new", NewPanelCmd);
	RegConsoleCmd("halenew", NewPanelCmd);
	RegConsoleCmd("halemusic", MusicTogglePanelCmd);
	RegConsoleCmd("hale_music", MusicTogglePanelCmd);
	RegConsoleCmd("halevoice", VoiceTogglePanelCmd);
	RegConsoleCmd("hale_voice", VoiceTogglePanelCmd);
	RegConsoleCmd("hale_resetpoints", ResetQueuePointsCmd);
	RegConsoleCmd("haleresetpoints", ResetQueuePointsCmd);
	RegAdminCmd("hale_resetqueuepoints", ResetQueuePointsCmd, 0);
	RegAdminCmd("hale_resetq", ResetQueuePointsCmd, 0);
	RegConsoleCmd("nextmap", NextMapCmd);
	RegConsoleCmd("say", SayCmd);
	RegConsoleCmd("say_team", SayCmd);
	
	AddCommandListener(DoTaunt, "taunt"); 
	AddCommandListener(DoTaunt, "+taunt");
	AddCommandListener(DoTaunt, "+use_action_slot_item_server");
	AddCommandListener(DoTaunt, "use_action_slot_item_server");
	AddCommandListener(DoSuicide, "explode");  
	AddCommandListener(DoSuicide, "kill");  
	AddCommandListener(Destroy, "destroy");

	RegAdminCmd("hale_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable CP. Only with ff2_point_type = 0");
	RegAdminCmd("hale_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable CP. Only with ff2_point_type = 0");

	RegAdminCmd("ff2_special", Command_MakeNextSpecial, ADMFLAG_CHEATS, "Call a special to next round.");
	RegAdminCmd("ff2_addpoints", Command_Points, ADMFLAG_CHEATS, "ff2_addpoints < target > < points > - Add queue points to user.");
	RegAdminCmd("ff2_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable CP. Only with ff2_point_type = 0");
	RegAdminCmd("ff2_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable CP. Only with ff2_point_type = 0");
	RegAdminCmd("ff2_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music.");
	RegAdminCmd("ff2_charset", Command_CharSet, ADMFLAG_CHEATS, "Stop any currently playing Boss music.");
	RegAdminCmd("ff2_reload_subplugins", Command_ReloadSubPlugins, ADMFLAG_RCON, "Reload FF2's subplugins.");

	RegAdminCmd("hale_select", Command_MakeNextSpecial, ADMFLAG_CHEATS, "Call a special to next round.");
	RegAdminCmd("hale_special", Command_MakeNextSpecial, ADMFLAG_CHEATS, "Call a special to next round.");
	RegAdminCmd("hale_addpoints", Command_Points, ADMFLAG_CHEATS, "ff2_addpoints < target > < points > - Add queue points to user.");
	RegAdminCmd("hale_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable CP. Only with ff2_point_type = 0");
	RegAdminCmd("hale_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable CP. Only with ff2_point_type = 0");
	RegAdminCmd("hale_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music.");

	AutoExecConfig(true, "FreakFortress2");

	FF2Cookies = RegClientCookie("ff2_cookies_mk2", "", CookieAccess_Protected);
	/*PointCookie = RegClientCookie("hale_queue_points", "Amount of VSH/FF2 Queue points player has", CookieAccess_Public);
	MusicCookie = RegClientCookie("hale_music_setting", "BossMusic setting", CookieAccess_Public);
	VoiceCookie = RegClientCookie("hale_voice_setting", "BossVoice setting", CookieAccess_Public);
	ClassinfoCookie = RegClientCookie("hale_classinfo", "HaleClassinfo setting", CookieAccess_Public);
	*/
	jumpHUD = CreateHudSynchronizer();
	rageHUD = CreateHudSynchronizer();
	healthHUD = CreateHudSynchronizer();
	abilitiesHUD = CreateHudSynchronizer();
	timeleftHUD = CreateHudSynchronizer(); 	

	decl String:oldversion[64];
	GetConVarString(cvarVersion, oldversion, sizeof(oldversion));
	if (strcmp(oldversion, ff2versiontitles[maxversion], false) != 0)
		LogError("[Freak Fortress 2] Warning: your config may be outdated. Back up your tf/cfg/sourcemod/FreakFortress2.cfg and delete it, and this plugin will generate a new one that you can then modify to your original values.");

	LoadTranslations("freak_fortress_2.phrases");
	LoadTranslations("common.phrases");
	AddNormalSoundHook(HookSound);
	AddMultiTargetFilter("@hale", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!hale", BossTargetFilter, "all non-Boss players", false);
	AddMultiTargetFilter("@boss", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!boss", BossTargetFilter, "all non-Boss players", false);
#if defined _steamtools_included
	steamtools = LibraryExists("SteamTools");
#endif

}

public bool:BossTargetFilter(const String:pattern[], Handle:clients)
{
	new bool:non = StrContains(pattern, "!", false) != -1;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && FindValueInArray(clients, client) == -1)
		{
			if (Enabled && IsBoss(client))
			{
				if (!non)
				{
					PushArrayCell(clients, client);
				}
			}
			else if (non)
			{
				PushArrayCell(clients, client);
			}
		}
	}

	return true;
}

public OnLibraryAdded(const String:name[])
{
#if defined _steamtools_included
	if (strcmp(name, "SteamTools", false) == 0)
		steamtools = true;
#endif
}

public OnLibraryRemoved(const String:name[])
{
#if defined _steamtools_included
	if (strcmp(name, "SteamTools", false) == 0)
		steamtools = false;
#endif
}

public OnConfigsExecuted()
{
	SetConVarString(FindConVar("ff2_version"), ff2versiontitles[maxversion]);
	Announce = GetConVarFloat(cvarAnnounce);
	PointType = GetConVarInt(cvarPointType);
	PointDelay = GetConVarInt(cvarPointDelay);
	if (PointDelay < 0) PointDelay *= -1;
	AliveToEnable = GetConVarInt(cvarAliveToEnable);
	BossCrits = GetConVarBool(cvarCrits);
	circuitStun = GetConVarFloat(cvarCircuitStun);
	
	if (IsFF2Map() && GetConVarBool(cvarEnabled))
	{
		tf_arena_use_queue = GetConVarInt(FindConVar("tf_arena_use_queue"));
		mp_teams_unbalance_limit = GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
		tf_arena_first_blood = GetConVarInt(FindConVar("tf_arena_first_blood"));
		mp_forcecamera = GetConVarInt(FindConVar("mp_forcecamera"));
		tf_scout_hype_pep_max = GetConVarFloat(FindConVar("tf_scout_hype_pep_max"));
		
		SetConVarInt(FindConVar("tf_arena_use_queue"),0);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"),0);
		SetConVarInt(FindConVar("tf_arena_first_blood"),0);
		SetConVarInt(FindConVar("mp_forcecamera"),0);
		SetConVarFloat(FindConVar("tf_scout_hype_pep_max"), 100.0);
#if defined _steamtools_included
		if (steamtools)
		{
			decl String:gameDesc[64];
			Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", ff2versiontitles[maxversion]);
			Steam_SetGameDescription(gameDesc);
		}
#endif
		Enabled = true;
		Enabled2 = true;
		
		new Float:time = Announce;
		if (time > 1.0)
		{
			CreateTimer(time, Timer_Announce,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		
		CheckToChangeMapDoors();

		MapHasMusic(true);
		EnableSubPlugins();
		AddToDownload();
		strcopy(FF2CharSetStr,2,"");
		isSubPluginsEnabled=false;
		
		bMedieval = FindEntityByClassname(-1, "tf_logic_medieval")!= -1 || bool:GetConVarInt(FindConVar("tf_medieval"));
		
		// For healthbar
		FindHealthBar();
	}
	else
	{
		Enabled = false;
		Enabled2 = false;
	}
}

public OnMapStart()
{
	chkFirstHale = 0;
	MusicTimer = INVALID_HANDLE;
	RoundCounter = 0;
	doorchecktimer = INVALID_HANDLE;
	RoundCount = 0;
	for (new i = 0;  i <= MaxClients; i++)
	{
		FF2flags[i] = 0;
		Incoming[i] = -1;
	}
	for (new i = 0; i < MAXSPECIALS; i++)
	{
		BossKV[i] = INVALID_HANDLE;
	}
}

public OnMapEnd()
{
	if (Enabled2 || Enabled)
	{
		SetConVarInt(FindConVar("tf_arena_use_queue"),tf_arena_use_queue);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"),mp_teams_unbalance_limit);
		SetConVarInt(FindConVar("tf_arena_first_blood"),tf_arena_first_blood);
		SetConVarInt(FindConVar("mp_forcecamera"),mp_forcecamera);
		SetConVarFloat(FindConVar("tf_scout_hype_pep_max"), tf_scout_hype_pep_max);
#if defined _steamtools_included
		if (steamtools)
		{
			Steam_SetGameDescription("Team Fortress");
		}
#endif
		DisableSubPlugins();

		if (MusicTimer != INVALID_HANDLE)
		{
			KillTimer(MusicTimer);
			MusicTimer = INVALID_HANDLE;
		}

	}
}

public OnPluginEnd()
{
	OnMapEnd();
}

public AddToDownload()
{
	Specials = 0;
	decl String:s[PLATFORM_MAX_PATH], String:i_str[4];
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"configs/freak_fortress_2/characters.cfg");
	if (!FileExists(s))
	{
		LogError("[FF2] Freak Fortress 2 disables - can not found character config.");
		return;
	}
	new Handle:Kv = CreateKeyValues("");
	FileToKeyValues(Kv, s);
	for (new i=0; i <FF2CharSet; i++)
		KvGotoNextKey(Kv);
	KvGotoFirstSubKey(Kv);
	KvGetSectionName(Kv, s, 64);
	for (new i=1; i<MAXSPECIALS; i++)
	{
		IntToString(i,i_str,4);
		KvGetString(Kv, i_str, s, PLATFORM_MAX_PATH);
		if (!s[0]) break;
		LoadCharacter(s);
	}
	KvGetString(Kv, "chances", ChancesString, 64);
	CloseHandle(Kv);
	AddFileToDownloadsTable("sound/saxton_hale/9000.wav");
	PrecacheSound("saxton_hale/9000.wav",true);
	PrecacheSound("vo/announcer_am_capincite01.wav", true);
	PrecacheSound("vo/announcer_am_capincite03.wav", true);
	PrecacheSound("weapons/barret_arm_zap.wav", true);
	PrecacheSound("vo/announcer_ends_2min.wav", true);
}

EnableSubPlugins(bool:forse = false)
{
	if (isSubPluginsEnabled && !forse)
		return;
	isSubPluginsEnabled=true;
	decl String:path[PLATFORM_MAX_PATH],String:fname[PLATFORM_MAX_PATH],String:fname_old[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
	decl FileType:filetype;
	new Handle:dir = OpenDirectory(path);
	while (ReadDirEntry(dir, fname, PLATFORM_MAX_PATH, filetype))
		if (filetype == FileType_File && StrContains(fname, ".smx",false)!= -1)
		{
			Format(fname_old,PLATFORM_MAX_PATH,"%s/%s",path,fname);
			ReplaceString(fname, PLATFORM_MAX_PATH, ".smx", ".ff2", false);
			Format(fname,PLATFORM_MAX_PATH,"%s/%s",path,fname);
			DeleteFile(fname);
			RenameFile(fname,fname_old);
		}

	dir = OpenDirectory(path);
	while (ReadDirEntry(dir, fname, PLATFORM_MAX_PATH, filetype))
		if (filetype == FileType_File && StrContains(fname, ".ff2",false)!= -1)
			ServerCommand("sm plugins load freaks/%s",fname);
}

DisableSubPlugins(bool:forse = false)
{
	if (!isSubPluginsEnabled && !forse)
		return;
	isSubPluginsEnabled=false;
	decl String:path[PLATFORM_MAX_PATH],String:fname[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
	decl FileType:filetype;
	new Handle:dir = OpenDirectory(path);
	while (ReadDirEntry(dir, fname, PLATFORM_MAX_PATH, filetype))
		if (filetype == FileType_File && StrContains(fname, ".ff2",false)!= -1)
			ServerCommand("sm plugins unload freaks/%s",fname);
}

public LoadCharacter(const String:character[])
{			
	new String:extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
	decl String:s[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"configs/freak_fortress_2/%s.cfg",character);
	if (!FileExists(s))
	{
		LogError("Character %s is not exists",character);
		return;
	}
	BossKV[Specials] = CreateKeyValues("character");
	FileToKeyValues(BossKV[Specials], s);
	for(new n = 1; ; n++)
	{		
		Format(s,10,"ability%i",n);
		if (KvJumpToKey(BossKV[Specials],s))
		{
			decl String:plugin_name[64];
			KvGetString(BossKV[Specials], "plugin_name",plugin_name,64);
			BuildPath(Path_SM, s, PLATFORM_MAX_PATH, "plugins/freaks/%s.ff2",plugin_name);
			if (!FileExists(s))
			{
				LogError("Character %s needs plugin %s",character,plugin_name);
				return;
			}
		}
		else
			break;
	}
	KvRewind(BossKV[Specials]);
	
	decl String:s2[PLATFORM_MAX_PATH];
	decl String:s3[64];
	KvSetString(BossKV[Specials], "filename", character);
	KvGetString(BossKV[Specials], "name", s, PLATFORM_MAX_PATH);
	bBlockVoice[Specials] = bool:KvGetNum(BossKV[Specials],"sound_block_vo",0);
	BossSpeed[Specials] = KvGetFloat(BossKV[Specials],"maxspeed",340.0);
	BossRageDamage[Specials] = KvGetFloat(BossKV[Specials],"ragedamage",1900.0);
	KvGotoFirstSubKey(BossKV[Specials]);
	decl i,is;
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"configs/freak_fortress_2/characters.cfg");
	while (KvGotoNextKey(BossKV[Specials]))
	{	
		KvGetSectionName(BossKV[Specials], s3, 64);
		if (!strcmp(s3,"download"))
		{
			for(i = 1; ; i++)
			{
				IntToString(i,s2,4);
				KvGetString(BossKV[Specials], s2, s, PLATFORM_MAX_PATH);
				if (!s[0])
					break;
				AddFileToDownloadsTable(s);
			}
		}
		else if (!strcmp(s3,"mod_precache"))
		{	
			for(i = 1; ; i++)
			{
				IntToString(i,s2,4);
				KvGetString(BossKV[Specials], s2, s, PLATFORM_MAX_PATH);
				if (!s[0])
					break;
				PrecacheModel(s,true);
			}
		}
		else if (!strcmp(s3,"mod_download"))
		{	
			for(i = 1; ; i++)
			{
				IntToString(i,s2,4);
				KvGetString(BossKV[Specials], s2, s, PLATFORM_MAX_PATH);
				if (!s[0])
					break;
				for (is = 0;  is < sizeof(extensions);  is++)
				{
					Format(s2,PLATFORM_MAX_PATH,"%s%s",s,extensions[is]);
					AddFileToDownloadsTable(s2);
				}
			}
		}
		else if (!strcmp(s3,"mat_download"))
		{	
			for(i = 1; ; i++)
			{
				IntToString(i,s2,4);
				KvGetString(BossKV[Specials], s2, s, PLATFORM_MAX_PATH);
				if (!s[0])
					break;
				Format(s2,PLATFORM_MAX_PATH,"%s.vtf",s);
				AddFileToDownloadsTable(s2);
				Format(s2,PLATFORM_MAX_PATH,"%s.vmt",s);
				AddFileToDownloadsTable(s2);
			}
		}
		else if (!StrContains(s3,"sound_") || !strcmp(s3,"catch_phrase"))
		{	
			for(i = 1; ; i++)
			{
				IntToString(i,s2,4);
				KvGetString(BossKV[Specials], s2, s, PLATFORM_MAX_PATH);
				if (!s[0])
					break;
				PrecacheSound(s,true);
			}
		}
	}
	Specials++;
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarPointDelay)
	{
		PointDelay = StringToInt(newValue);
		if (PointDelay < 0) PointDelay*= -1;
	}
	else if (convar == cvarAnnounce)
		Announce = StringToFloat(newValue);
	else if (convar == cvarPointType)
		PointType = StringToInt(newValue);
	else if (convar == cvarPointDelay)
		PointDelay = StringToInt(newValue);
	else if (convar == cvarAliveToEnable)
		AliveToEnable = StringToInt(newValue);
	else if (convar == cvarCrits)
		BossCrits = bool:StringToInt(newValue);
	else if (convar == cvarCircuitStun)
		circuitStun = StringToFloat(newValue);
	else if (convar == cvarUseCountdown)
		UseCountdown = StringToInt(newValue);
	else if (convar == cvarSpecForceBoss)
		SpecForceBoss = bool:StringToInt(newValue);
	else if (convar == cvarEnabled)
	{
		if (StringToInt(newValue))
		{
			Enabled2 = true;
#if defined _steamtools_included
			if (steamtools)
			{
				decl String:gameDesc[64];
				Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", ff2versiontitles[maxversion]);
				Steam_SetGameDescription(gameDesc);
			}
#endif
		}
		else
		{
			Enabled2 = false;
#if defined _steamtools_included
			if (steamtools)
			{
				decl String:gameDesc[64];
				Format(gameDesc, sizeof(gameDesc), "Team Fortress");
				Steam_SetGameDescription(gameDesc);
			}
#endif
		}
	}
}


public Action:Timer_Announce(Handle:hTimer)
{
	static announcecount = -1;
	announcecount++;
	if (Announce > 1.0 && Enabled2)
	{
		switch (announcecount)
		{
			case 1:
			{
				CPrintToChatAll("{olive}[FF2]{default} VS Saxton Hale/Freak Fortress 2 group: {olive}http://steamcommunity.com/groups/vssaxtonhale{default}");
			}
			case 3:
			{
				CPrintToChatAll("{default} === Freak Fortress 2 v.%s (based on VS Saxton Hale Mode by {olive}RainBolt Dash{default} and {olive}FlaminSarge{default} edit by {olive}RavensBro{default}) === ",ff2versiontitles[maxversion]);
			}
			case 4:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t","type_ff2_to_open_menu");
			}
			case 5:
			{
				announcecount = 0;
				CPrintToChatAll("{olive}[FF2]{default} %t","ff2_last_update",ff2versiontitles[maxversion],ff2versiondates[maxversion]);
			}
			default: 
			{
				CPrintToChatAll("{olive}[FF2]{default} %t","type_ff2_to_open_menu");
			}
		}
	}
	return Plugin_Continue;
}


/* public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (Enabled)
	{
		Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", ff2versiontitles[maxversion]);
		return Plugin_Changed;
	}
	return Plugin_Continue;
} */

stock bool:IsFF2Map(bool:forceRecalc = false)
{
	static bool:found = false;
	static bool:isFF2Map = false;

	if (forceRecalc)
	{
		isFF2Map = false;
		found = false;
	}
	if (!found)
	{
		decl String:s[PLATFORM_MAX_PATH];
		GetCurrentMap(currentmap, sizeof(currentmap));
		if (FileExists("bNextMapToFF2"))
		{
			isFF2Map = true;
			found = true;
			return true;
		}
		BuildPath(Path_SM, s, PLATFORM_MAX_PATH, "configs/freak_fortress_2/maps.cfg");
		if (!FileExists(s))
		{
			LogError("[FF2] Unable to find %s, disabling plugin.", s);
			isFF2Map = false;
			found = true;
			return false;
		}
		new Handle:fileh = OpenFile(s, "r");
		if (fileh == INVALID_HANDLE)
		{
			LogError("[FF2] Error reading maps from %s, disabling plugin.", s);
			isFF2Map = false;
			found = true;
			return false;
		}
		new pingas = 0;
		while (ReadFileLine(fileh, s, sizeof(s)) && (pingas < 100))
		{
			pingas++;
			if (pingas == 100)
				LogError("[FF2] Breaking infinite loop when trying to check the map.");
			Format(s, strlen(s)-1, s);
			if (strncmp(s, "//", 2, false) == 0) continue;
			if ((StrContains(currentmap, s, false) == 0) || (StrContains(s, "all", false) == 0))
			{
				CloseHandle(fileh);
				isFF2Map = true;
				found = true;
				return true;
			}
		}
		CloseHandle(fileh);
	}
	return isFF2Map;
}

stock bool:MapHasMusic(bool:forceRecalc = false)	//SAAAAAARGE
{
	static bool:hasMusic;
	static bool:found = false;
	if (forceRecalc)
	{
		found = false;
		hasMusic = false;
	}
	if (!found)
	{
		new i = -1;
		decl String:name[64];
		while ((i = FindEntityByClassname2(i, "info_target")) != -1)
		{
			GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
			if (strcmp(name, "hale_no_music", false) == 0) hasMusic = true;
		}
		found = true;
	}
	return hasMusic;
}
stock bool:CheckToChangeMapDoors()
{
	decl String:s[PLATFORM_MAX_PATH];
	checkdoors = false;
	BuildPath(Path_SM, s, PLATFORM_MAX_PATH, "configs/freak_fortress_2/doors.cfg");
	if (!FileExists(s))
	{
		if (strncmp(currentmap, "vsh_lolcano_pb1", 15, false) == 0)
			checkdoors = true;
		return;
	}
	new Handle:fileh = OpenFile(s, "r");
	if (fileh == INVALID_HANDLE)
	{
		if (strncmp(currentmap, "vsh_lolcano_pb1", 15, false) == 0)
			checkdoors = true;
		return;
	}
	while (!IsEndOfFile(fileh) && ReadFileLine(fileh, s, sizeof(s)))
	{
		Format(s, strlen(s)-1, s);
		if (strncmp(s, "//", 2, false) == 0) continue;
		if (StrContains(currentmap, s, false) != -1 || StrContains(s, "all", false) == 0)
		{
			CloseHandle(fileh);
			checkdoors = true;
			return;
		}
	}
	CloseHandle(fileh);
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
#if defined _steamtools_included
		if (Enabled2 && steamtools)
		{
			Steam_SetGameDescription("Team Fortress");
		}
#endif
		Enabled2 = false;
	}
	Enabled = Enabled2;
	if (!Enabled)
		return Plugin_Continue;
	FF2RoundState = 0;
	if (FileExists("bNextMapToFF2"))
		DeleteFile("bNextMapToFF2");
	DrawGameTimer = INVALID_HANDLE;
	
	new bool:bBluBoss;
	new convarsetting = GetConVarInt(cvarForceBossTeam);
	switch (convarsetting)
	{
		case 3: bBluBoss = true;
		case 2: bBluBoss = false;
		case 1: bBluBoss = GetRandomInt(0, 1) == 1;
		default:
		{
			if (!StrContains(currentmap, "vsh_") || !StrContains(currentmap, "zf_")) bBluBoss = true;
			else if (RoundCounter >= 3 && GetRandomInt(0, 1))
			{
				bBluBoss = (BossTeam != 3);
				RoundCounter = 0;
			}
			else bBluBoss = (BossTeam == 3);
		}
	}
	
	if (bBluBoss)
	{
		new score1 = GetTeamScore(OtherTeam);
		new score2 = GetTeamScore(BossTeam);
		SetTeamScore(2,score1);
		SetTeamScore(3,score2);
		OtherTeam = 2;
		BossTeam = 3;
	}
	else
	{
		new score1 = GetTeamScore(BossTeam);
		new score2 = GetTeamScore(OtherTeam);
		SetTeamScore(2,score1);
		SetTeamScore(3,score2);
		BossTeam = 2;
		OtherTeam = 3;
	}
	playing = 0;
	for (new ionplay = 1;  ionplay <= MaxClients;  ionplay++)
	{
		Damage[ionplay] = 0;
		uberTarget[ionplay] = -1;
		if (IsValidClient(ionplay))
		{
			if (GetClientTeam(ionplay) > _:TFTeam_Spectator) playing++;
		}
	}
	if (GetClientCount() <= 1 || playing < 2)
	{
		CPrintToChatAll("{olive}[FF2]{default} %t","needmoreplayers");
		Enabled = false;
		DisableSubPlugins();
		SetControlPoint(true);
		return Plugin_Continue;
	}
	else if (RoundCount == 0 && !GetConVarBool(cvarFirstRound))
	{
		CPrintToChatAll("{olive}[FF2]{default} %t","first_round");
		Enabled = false;
		DisableSubPlugins();
		SetArenaCapEnableTime(60.0);
		CreateTimer(71.0, Timer_EnableCap, _, TIMER_FLAG_NO_MAPCHANGE);
		new bool:tored;
		decl team;
		for (new ionplay = 1;  ionplay <= MaxClients;  ionplay++)
		{
			if (IsValidClient(ionplay) && (team = GetClientTeam(ionplay)) > 1) 
			{
				SetEntProp(ionplay, Prop_Send, "m_lifeState", 2);
				if (tored && team!= _:TFTeam_Red)
					ChangeClientTeam(ionplay,_:TFTeam_Red);
				else if (!tored && team!= _:TFTeam_Blue)
					ChangeClientTeam(ionplay,_:TFTeam_Blue);
				SetEntProp(ionplay, Prop_Send, "m_lifeState", 0);
				TF2_RespawnPlayer(ionplay);
				tored = !tored;
			}
		}
		return Plugin_Continue;
	}
	Enabled = true;
	EnableSubPlugins();

	CheckArena();
	
	new bool:see[MAXPLAYERS + 1];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			new TFTeam:team=TFTeam:GetClientTeam(i);
			if (!see[0] && team == TFTeam_Blue)
				see[0]=true;
			else if (!see[1] && team == TFTeam_Red)
				see[1]=true;
		}
	}
	if (!see[0] || !see[1])
	{
		if (IsValidClient(Boss[0]))
		{
			//SetEntProp(Boss[0], Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(Boss[0], BossTeam);
			//SetEntProp(Boss[0], Prop_Send, "m_lifeState", 0);
			TF2_RespawnPlayer(Boss[0]);
		}
		for (new i = 1;  i <= MaxClients;  i++)
		{
			if (IsValidClient(i) && !IsBoss(i) && GetClientTeam(i) > _:TFTeam_Spectator)
			{
				SetEntProp(i, Prop_Send, "m_lifeState", 2);
				ChangeClientTeam(i, OtherTeam);
				SetEntProp(i, Prop_Send, "m_lifeState", 0);
				TF2_RespawnPlayer(i);
				CreateTimer(0.1, MakeNotBoss, GetClientUserId(i));
			}
		}
		return Plugin_Continue;
	}
	see[0]=false;
	see[1]=false;
	for(new i = 0; i <= MaxClients; i++)
		Boss[i] = 0;
	decl String:s[64];
	Boss[0] = FindBosses(see);
	PickSpecial(0,0);
	see[Boss[0]] = true;
	if ((Special[0] < 0) || !BossKV[Special[0]])
	{
		LogError("[FF2] I just don't know what went wrong");
		return Plugin_Continue;
	}
	KvRewind(BossKV[Special[0]]);
	BossLivesMax[0] = KvGetNum(BossKV[Special[0]], "lives",1);
	SetEntProp(Boss[0], Prop_Data, "m_iMaxHealth",1337);
	if (LastClass[Boss[0]] == TFClass_Unknown)
		LastClass[Boss[0]] = TF2_GetPlayerClass(Boss[0]);
	if (playing > 2)
		for (new i = 1; i <= MaxClients; i++)
		{		
			KvRewind(BossKV[Special[i-1]]);
			KvGetString(BossKV[Special[i-1]], "companion", s, 64);
			if (StrEqual(s,""))
				break;
			Boss[i] = FindBosses(see);
			if (PickSpecial(i,i-1))
			{
				KvRewind(BossKV[Special[i]]);
				for (new pingas = 0; Boss[i] == Boss[i-1] && pingas < 100; pingas++)
					Boss[i] = FindBosses(see);
				see[Boss[i]] = true;
				BossLivesMax[i] = KvGetNum(BossKV[Special[i]], "lives",1);
				SetEntProp(Boss[i], Prop_Data, "m_iMaxHealth",1337);
				if (LastClass[Boss[i]] == TFClass_Unknown)
					LastClass[Boss[i]] = TF2_GetPlayerClass(Boss[i]);
			}
			else
				Boss[i] = 0;
		}
	CreateTimer(0.2,Timer_GogoBoss);
	CreateTimer(9.1, StartBossTimer);
	CreateTimer(3.5, StartResponceTimer);
	CreateTimer(9.6, MessageTimer);

	decl ent2;
	decl Float:pos[3];
	for(new ent = MaxClients+1; ent < ME; ent++)
	{
		if (!IsValidEdict(ent))
			continue;
		GetEdictClassname(ent, s, 64);
		if (!strcmp(s,"func_regenerate"))
			AcceptEntityInput(ent, "Kill");
		else if (!strcmp(s, "func_respawnroomvisualizer"))
			AcceptEntityInput(ent, "Disable");
		else if (!strcmp(s, "item_ammopack_full") || !strcmp(s, "item_ammopack_medium"))
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);  
			AcceptEntityInput(ent, "Kill");
			ent2 = CreateEntityByName("item_ammopack_small");
			TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(ent2);
		}
	}
	healthcheckused = 0;
	return Plugin_Continue;
}

public Action:Timer_EnableCap(Handle:timer)
{
	if (FF2RoundState == -1)
	{
		SetControlPoint(true);
		if (checkdoors)
		{
			new ent = -1;
			while ((ent = FindEntityByClassname2(ent, "func_door")) != -1)
			{
				AcceptEntityInput(ent, "Open");
				AcceptEntityInput(ent, "Unlock");
			}
			if (doorchecktimer == INVALID_HANDLE)
				doorchecktimer = CreateTimer(5.0, Timer_CheckDoors, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	}
}

public Action:Timer_GogoBoss(Handle:hTimer)
{
	if (!FF2RoundState)
	{
		decl i;
		for(i = 0; i <= MaxClients; i++)
		{
			BossInfoTimer[i][0]=INVALID_HANDLE;
			BossInfoTimer[i][1]=INVALID_HANDLE;
			if (Boss[i])
			{
				CreateTimer(0.1,MakeBoss,i);
				BossInfoTimer[i][0] = CreateTimer(30.0,BossInfoTimer_begin,i);
			}
		}
	}
	return Plugin_Continue;
}

public Action:BossInfoTimer_begin(Handle:hTimer,any:index)
{
	BossInfoTimer[index][0]=INVALID_HANDLE;
	BossInfoTimer[index][1]=CreateTimer(0.2,BossInfoTimer_showinfo,index,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:BossInfoTimer_showinfo(Handle:hTimer,any:index)
{
	if (FF2flags[Boss[index]] & FF2FLAG_USINGABILITY)
	{
		BossInfoTimer[index][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	if (FF2flags[Boss[index]] & FF2FLAG_HUDDISABLED)
	{
		BossInfoTimer[index][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	new bool:see;
	for(new n = 1; ; n++)
	{		
		decl String:s[10];
		Format(s,10,"ability%i",n);
		if (index == -1 || Special[index] == -1 || !BossKV[Special[index]])
			return Plugin_Stop;
		KvRewind(BossKV[Special[index]]);
		if (KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:plugin_name[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name,64);
			if (KvGetNum(BossKV[Special[index]], "buttonmode",0) == 2)
			{
				see=true;
				break;
			}
		}
		else
			break;
	}
	new need_info_bout_reload=see && CheckInfoCookies(Boss[index],0);
	new need_info_bout_rmb=CheckInfoCookies(Boss[index],1);
	if (need_info_bout_reload)
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		SetGlobalTransTarget(Boss[index]);
		if (need_info_bout_rmb)
			ShowSyncHudText(Boss[index], abilitiesHUD, "%t\n%t","ff2_buttons_reload","ff2_buttons_rmb");
		else
			ShowSyncHudText(Boss[index], abilitiesHUD, "%t","ff2_buttons_reload");
	}
	else if (need_info_bout_rmb)
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		SetGlobalTransTarget(Boss[index]);
		ShowSyncHudText(Boss[index], abilitiesHUD, "%t","ff2_buttons_rmb");
	}
	else
	{
		BossInfoTimer[index][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_CheckDoors(Handle:hTimer)
{
	if (!checkdoors)
	{
		doorchecktimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if ((!Enabled && FF2RoundState != -1) || (Enabled && FF2RoundState != 1))
		return Plugin_Continue;
	new ent = -1;
	while ((ent = FindEntityByClassname2(ent, "func_door")) != -1)
	{
		AcceptEntityInput(ent, "Open");
		AcceptEntityInput(ent, "Unlock");
	}
	return Plugin_Continue;
}

public CheckArena()
{
	if (PointType)
		SetArenaCapEnableTime(float(45 + PointDelay * (playing - 1)));
	else
	{
		SetArenaCapEnableTime(0.0);
		SetControlPoint(false);
	}
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:s[512];

	RoundCount++;
	if (!Enabled)
		return Plugin_Continue;

	FF2RoundState = 2;
	if ((GetEventInt(event, "team") == BossTeam))
	{
		if (RandomSound("sound_win",s,PLATFORM_MAX_PATH))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE,s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss[0], _, NULL_VECTOR, false, 0.0);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE,s,_, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss[0], _, NULL_VECTOR, false, 0.0);
		}

	}
	Native_StopMusic(INVALID_HANDLE,0);
	if (MusicTimer != INVALID_HANDLE)
	{
		KillTimer(MusicTimer);
		MusicTimer = INVALID_HANDLE;
	}
	new isAliveBosses = 0;
	for (new i = 0; i <= MaxClients; i++)
	{
		GlowTimer[i] = 0.0;
		if (IsValidClient(Boss[i]))
		{
			SetEntProp(Boss[i], Prop_Send, "m_bGlowEnabled", 0);
			if (IsPlayerAlive(Boss[i]))
				isAliveBosses = i;
		}
		if (BossInfoTimer[i][0] != INVALID_HANDLE)
		{
			KillTimer(BossInfoTimer[i][0]);
			BossInfoTimer[i][0] = INVALID_HANDLE;
		}
		if (BossInfoTimer[i][1] != INVALID_HANDLE)
		{
			KillTimer(BossInfoTimer[i][1]);
			BossInfoTimer[i][1] = INVALID_HANDLE;
		}
	}
	strcopy(s,2,"");
	if (isAliveBosses)
	{
		decl String:name1[64];
		decl String:s2[4];
		for(new i = 0; Boss[i]; i++)
		{
			KvRewind(BossKV[Special[i]]);
			KvGetString(BossKV[Special[i]], "name", name1, 64," = Failed name = ");
			if (BossLives[i] > 1)
				Format(s2,4,"x%i",BossLives[i]);
			else
				strcopy(s2,2,"");
			Format(s,512,"%s\n%t",s,"ff2_alive",name1,BossHealth[i]-BossHealthMax[i]*(BossLives[i]-1),BossHealthMax[i],s2);
		}
		if (RandomSound("sound_fail",s,PLATFORM_MAX_PATH,isAliveBosses))
		{
			EmitSoundToAll(s);
			EmitSoundToAll(s);
		}
	}
	new top[3];
	Damage[0] = 0;
	for (new i = 0; i <= MaxClients; i++)
	{
		if (Damage[i] >= Damage[top[0]])
		{
			top[2] = top[1];
			top[1] = top[0];
			top[0] = i;
		}
		else if (Damage[i] >= Damage[top[1]])
		{
			top[2] = top[1];
			top[1] = i;
		}
		else if (Damage[i] >= Damage[top[2]])
		{
			top[2] = i;
		}
	}
	if (Damage[top[0]] > 9000)
	{
		CreateTimer(1.0, Timer_NineThousand, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	decl String:s0[32];
	if (IsValidClient(top[0]) && (GetClientTeam(top[0]) >= 1)) 
		GetClientName(top[0], s0, 32);
	else
	{
		Format(s0,32,"---");
		top[0] = 0;
	}
	decl String:s1[32];
	if (IsValidClient(top[1]) && (GetClientTeam(top[1]) >= 1)) 
		GetClientName(top[1], s1, 32);
	else
	{
		Format(s1,32,"---");
		top[1] = 0;
	}
	decl String:s2[32];
	if (IsValidClient(top[2]) && (GetClientTeam(top[2]) >= 1)) 
		GetClientName(top[2], s2, 32);
	else
	{
		Format(s2,32,"---");
		top[2] = 0;
	}
	SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
	PrintCenterTextAll(""); 	//Should clear center text
	for (new i = 1;  i <= MaxClients;  i++)
	{
		if (IsValidClient(i) && !(FF2flags[i] & FF2FLAG_HUDDISABLED))
		{
			SetGlobalTransTarget(i);
			ShowHudText(i, -1, "%s\n%t:\n1)%i - %s\n2)%i - %s\n3)%i - %s\n\n%t\n%t",s,"top_3",Damage[top[0]],s0,Damage[top[1]],s1,Damage[top[2]],s2,"damage_fx",Damage[i],"scores",RoundFloat(Damage[i]/600.0));
		}
	}
	CreateTimer(3.0, Timer_CalcQueuePoints, _, TIMER_FLAG_NO_MAPCHANGE);		//CalcQueuePoints
	
	UpdateHealthBar();

	return Plugin_Continue;
}

public Action:Timer_NineThousand(Handle:timer)
{
	EmitSoundToAll("saxton_hale/9000.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
	return Plugin_Continue;
}

public Action:Timer_CalcQueuePoints(Handle:timer)
{
	CalcQueuePoints();
}
stock CalcQueuePoints()
{
	decl j, damage;
	botqueuepoints += 5;
	new add_points[MAXPLAYERS+1];
	new add_points2[MAXPLAYERS+1];
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			damage = Damage[i];
			new Handle:aevent = CreateEvent("player_escort_score", true);
			SetEventInt(aevent, "player", i);
			for (j = 0; damage-600 > 0; damage-= 600,j++) {}
			SetEventInt(aevent, "points", j);
			FireEvent(aevent);
			if (IsBoss(i))
			{
				if (IsFakeClient(i))
					botqueuepoints = 0;
				else
				{
					add_points[i]=-GetClientQueuePoints(i);
					add_points2[i]=add_points[i];
				}
			}
			else if (!IsFakeClient(i) && (GetClientTeam(i) > _:TFTeam_Spectator || SpecForceBoss))
			{
				add_points[i]=10;
				add_points2[i]=10;
			}
		}
	}
	new Action:act = Plugin_Continue;
	Call_StartForward(OnAddQueuePoints);
	Call_PushArrayEx(add_points2,MAXPLAYERS+1,SM_PARAM_COPYBACK);
	Call_Finish(act);
	switch (act)
	{
		case Plugin_Stop, Plugin_Handled:
			return;
		case Plugin_Changed:
		{
			for(new i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))
				{
					if (add_points2[i]>0)
						CPrintToChat(i,"{olive}[FF2]{default} %t","add_points",add_points2[i]);
					SetClientQueuePoints(i,GetClientQueuePoints(i)+add_points2[i]);
				}
		}
		default:
		{
			for(new i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))
				{
					if (add_points[i]>0)
						CPrintToChat(i,"{olive}[FF2]{default} %t","add_points",add_points[i]);
					SetClientQueuePoints(i,GetClientQueuePoints(i)+add_points[i]);
				}
		}
	}
}

public Action:StartResponceTimer(Handle:hTimer)
{
	decl String:s[PLATFORM_MAX_PATH];
	if (RandomSound("sound_begin",s,PLATFORM_MAX_PATH))
	{		
		EmitSoundToAll(s);
		EmitSoundToAll(s);
	}
	return Plugin_Continue;
}

public Action:StartBossTimer(Handle:hTimer)
{
	CreateTimer(0.1, GottamTimer);
	new bool:b = false;
	for(new i = 0; i <= MaxClients; i++)
		if (Boss[i] && IsValidEdict(Boss[i]) && IsPlayerAlive(Boss[i]))
		{
			b = true;
			if (!IsPlayerAlive(Boss[i]))
				TF2_RespawnPlayer(Boss[i]);
			SetEntityMoveType(Boss[i], MOVETYPE_NONE);
		}
	if (!b)
	{
		FF2RoundState = 2;
		return Plugin_Continue; 		
	}	
	playing = 0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && !IsBoss(client) && IsPlayerAlive(client)) 
		{
			playing++;
			CreateTimer(0.15, MakeNotBoss, GetClientUserId(client));
		}
	}
	if (playing < 5)
		playing+= 2;
	for(new i = 0; i <= MaxClients; i++)
		if (Boss[i] && IsValidEdict(Boss[i]) && IsPlayerAlive(Boss[i]))
		{
			BossHealthMax[i] = CalcBossHealthMax(i);
			if (BossHealthMax[i] < 5)
				BossHealthMax[i] = 1322;
			
			SetEntProp(Boss[i], Prop_Data, "m_iMaxHealth",BossHealthMax[i]);
			SetBossHealthFix(Boss[i], BossHealthMax[i]);
			BossLives[i] = BossLivesMax[i];
			BossHealth[i] = BossHealthMax[i]*BossLivesMax[i];
			BossHealthLast[i] = BossHealth[i];
		}
	CreateTimer(0.2, BossTimer,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, CheckAlivePlayers);
	CreateTimer(0.2, StartRound);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if (!PointType)
		SetControlPoint(false);
	CreateTimer(2.0, Timer_MusicPlay,0, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:Timer_MusicPlay(Handle:timer,any:client)
{
	if (MusicTimer != INVALID_HANDLE)
	{
		KillTimer(MusicTimer);
		MusicTimer = INVALID_HANDLE;
	}
	if (timer != INVALID_HANDLE && MapHasMusic())	//timer will be INVALID_HANDLE  if called from native
	{
		MusicIndex = -1;
		return Plugin_Continue;
	}
	KvRewind(BossKV[Special[0]]);
	if (KvJumpToKey(BossKV[Special[0]],"sound_bgm"))
	{
		decl String:s[PLATFORM_MAX_PATH];
		MusicIndex = 0;
		do
		{
			MusicIndex++;
			Format(s,10,"time%i",MusicIndex);
		}
		while (KvGetFloat(BossKV[Special[0]], s,0.0) > 1);
		MusicIndex = GetRandomInt(1,MusicIndex-1);
		Format(s,10,"time%i",MusicIndex);
		new Float:time = KvGetFloat(BossKV[Special[0]], s);
		Format(s,10,"path%i",MusicIndex);
		KvGetString(BossKV[Special[0]], s,s, PLATFORM_MAX_PATH);
		new Action:act = Plugin_Continue;
		Call_StartForward(OnMusic);
		decl String:sound2[PLATFORM_MAX_PATH];
		new Float:time2 = time;
		strcopy(sound2, PLATFORM_MAX_PATH, s);
		Call_PushStringEx(sound2, PLATFORM_MAX_PATH, 0, SM_PARAM_COPYBACK);
		Call_PushFloatRef(time2);
		Call_Finish(act);
		switch (act)
		{
			case Plugin_Stop, Plugin_Handled:
			{
				strcopy(s, sizeof(s), "");
				time = -1.0;
			}
			case Plugin_Changed:
			{
				strcopy(s, PLATFORM_MAX_PATH, sound2);
				time = time2;
			}
		}
		if (strlen(s[0]) > 5)
		{
			if (!client)
				EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, s);
			else if (CheckSoundException(client, SOUNDEXCEPT_MUSIC))
				EmitSoundToClient(client,s);
			decl userid;
			if (!client)
				userid = 0;
			else
				userid = GetClientUserId(client);
			if (time > 1)
				MusicTimer = CreateTimer(time, Timer_MusicTheme,userid, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action:Timer_MusicTheme(Handle:timer,any:userid)
{
	MusicTimer = INVALID_HANDLE;
	if (Enabled && FF2RoundState == 1)
	{	
		KvRewind(BossKV[Special[0]]);
		if (KvJumpToKey(BossKV[Special[0]],"sound_bgm"))
		{
			decl client;
			if (!userid)
				client = 0;
			else
				client = GetClientOfUserId(userid);
			decl String:s[PLATFORM_MAX_PATH];
			MusicIndex = 0;
			do
			{
				MusicIndex++;
				Format(s,10,"time%i",MusicIndex);
			}
			while (KvGetFloat(BossKV[Special[0]], s) > 1);
			MusicIndex = GetRandomInt(1,MusicIndex-1);
			Format(s,10,"time%i",MusicIndex);
			new Float:time = KvGetFloat(BossKV[Special[0]],s);
			Format(s,10,"path%i",MusicIndex);
			KvGetString(BossKV[Special[0]], s,s, PLATFORM_MAX_PATH);
			
			new Action:act = Plugin_Continue;
			Call_StartForward(OnMusic);
			decl String:sound2[PLATFORM_MAX_PATH];
			new Float:time2 = time;
			strcopy(sound2, PLATFORM_MAX_PATH, s);
			Call_PushStringEx(sound2, PLATFORM_MAX_PATH, 0, SM_PARAM_COPYBACK);
			Call_PushFloatRef(time2);
			Call_Finish(act);
			switch (act)
			{
				case Plugin_Stop, Plugin_Handled:
				{
					strcopy(s, sizeof(s), "");
					time = -1.0;
				}
				case Plugin_Changed:
				{
					strcopy(s, PLATFORM_MAX_PATH, sound2);
					time = time2;
				}
			}
			if (strlen(s[0]) > 5)
			{
				if (!client)
					EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, s,_, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				else if (CheckSoundException(client, SOUNDEXCEPT_MUSIC))
					EmitSoundToClient(client,s);
				if (time > 1)
					MusicTimer = CreateTimer(time, Timer_MusicTheme,userid, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	else
		return Plugin_Stop;
	return Plugin_Continue;
}

stock EmitSoundToAllExcept(exceptiontype = SOUNDEXCEPT_MUSIC, const String:sample[],
				 entity = SOUND_FROM_PLAYER,
				 channel = SNDCHAN_AUTO,
				 level = SNDLEVEL_NORMAL,
				 flags = SND_NOFLAGS,
				 Float:volume = SNDVOL_NORMAL,
				 pitch = SNDPITCH_NORMAL,
				 speakerentity = -1,
				 const Float:origin[3] = NULL_VECTOR,
				 const Float:dir[3] = NULL_VECTOR,
				 bool:updatePos = true,
				 Float:soundtime = 0.0)
{
	new clients[MaxClients];
	new total = 0;
	for (new i = 1;  i <= MaxClients;  i++)
	{
		if (IsValidEdict(i) && IsClientInGame(i))
		{
			if (CheckSoundException(i, exceptiontype))
				clients[total++] = i;
		}
	}

	if (!total)
	{
		return;
	}

	EmitSound(clients, total, sample, entity, channel, 
		level, flags, volume, pitch, speakerentity,
		origin, dir, updatePos, soundtime);
}

stock CheckInfoCookies(client,infonum)
{
	if (!IsValidClient(client)) return false;
	if (IsFakeClient(client)) return true;
	if (!AreClientCookiesCached(client)) return true;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s, 24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	new see=StringToInt(ff2cookies_values[4+infonum]);
	return (see>0 ? see : 0);
}

stock SetInfoCookies(client,infonum,value)
{
	if (!IsValidClient(client)) return ;
	if (IsFakeClient(client)) return ;
	if (!AreClientCookiesCached(client)) return ;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s, 24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	Format(s,24,"%s %s %s %s",ff2cookies_values[0],ff2cookies_values[1],ff2cookies_values[2],ff2cookies_values[3]);
	for(new i=0;i<infonum;i++)
		Format(s,24,"%s %s",s,ff2cookies_values[4+i]);
	Format(s,24,"%s %i",s,value);
	for(new i=infonum+1;i<4;i++)
		Format(s,24,"%s %s",s,ff2cookies_values[4+i]);
	SetClientCookie(client, FF2Cookies, s);
}


stock bool:CheckSoundException(client, excepttype)
{
	if (!IsValidClient(client)) return false;
	if (IsFakeClient(client)) return true;
	if (!AreClientCookiesCached(client)) return true;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s, 24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	if (excepttype == SOUNDEXCEPT_VOICE)
		return StringToInt(ff2cookies_values[2])==1;
	return StringToInt(ff2cookies_values[1])==1;
}

SetClientSoundOptions(client, excepttype, bool:on)
{
	if (!IsValidClient(client)) return;
	if (IsFakeClient(client)) return;
	if (!AreClientCookiesCached(client)) return;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s,24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	if (excepttype == SOUNDEXCEPT_VOICE)
	{
		if (on)
			ff2cookies_values[2][0] = '1';
		else
			ff2cookies_values[2][0] = '0';
	}
	else
	{
		if (on)
			ff2cookies_values[1][0] = '1';
		else
			ff2cookies_values[1][0] = '0';
	}
	Format(s,24,"%s %s %s %s %s %s %s %s",ff2cookies_values[0],ff2cookies_values[1],ff2cookies_values[2],ff2cookies_values[3],ff2cookies_values[4],ff2cookies_values[5],ff2cookies_values[6],ff2cookies_values[7]);
	SetClientCookie(client, FF2Cookies, s);
}

public Action:GottamTimer(Handle:hTimer)
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsValidClient(i) && IsPlayerAlive(i))
			SetEntityMoveType(i, MOVETYPE_WALK);
}

public Action:StartRound(Handle:hTimer)
{
	FF2RoundState = 1;
	for(new i = 0; i <= MaxClients; i++)
	{
		if (!IsValidClient(Boss[i]))
			continue;
		EquipBoss(i);
	}
	CreateTimer(10.0,Timer_SkipFF2Panel);
	
	UpdateHealthBar();
	
	return Plugin_Handled;
}

public Action:Timer_SkipFF2Panel(Handle:hTimer)
{
	new bool:added[MAXPLAYERS+1];
	new i,j;
	do
	{
		new client = FindBosses(added);
		added[client] = true;
		if (client && !IsBoss(client))
		{
			CPrintToChat(client,"{olive}[FF2]{default} %t","to0_near");
			i++;
		}
		j++;
	}
	while (i < 3 && j <= MaxClients);
}

public Action:MessageTimer(Handle:hTimer)
{
	if (FF2RoundState!= 1)
		return Plugin_Continue;

	if (checkdoors)
	{
		new ent = -1;
		while ((ent = FindEntityByClassname2(ent, "func_door")) != -1)
		{
			AcceptEntityInput(ent, "Open");
			AcceptEntityInput(ent, "Unlock");
		}
		if (doorchecktimer == INVALID_HANDLE)
			doorchecktimer = CreateTimer(5.0, Timer_CheckDoors, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	SetHudTextParams(-1.0, 0.4, 10.0, 255, 255, 255, 255);
	new String:s[512];
	decl String:s2[4];
	decl String:name[64];
	for(new i = 0; Boss[i]; i++)
	{
		if (!IsValidEdict(Boss[i])) continue;
		CreateTimer(0.1,MakeBoss,i);
		KvRewind(BossKV[Special[i]]);
		KvGetString(BossKV[Special[i]], "name",name, 64," = Failed name = ");
		if (BossLives[i] > 1)
			Format(s2,4,"x%i",BossLives[i]);
		else
			strcopy(s2,2,"");
		Format(s, 512, "%s\n%t",s,"ff2_start",Boss[i],name,BossHealth[i]-BossHealthMax[i]*(BossLives[i]-1),s2);
	}

	for (new i = 1;  i <= MaxClients;  i++)
		if (IsValidClient(i) && !(FF2flags[i] & FF2FLAG_HUDDISABLED))
		{
			SetGlobalTransTarget(i);
			ShowHudText(i, -1, s);
		}
	return Plugin_Continue;
}

public Action:MakeModelTimer(Handle:hTimer,any:index)
{		
	if (!Boss[index] || !IsValidEdict(Boss[index]) || !IsClientInGame(Boss[index]) || !IsPlayerAlive(Boss[index]) || (FF2RoundState == 2))
		return Plugin_Stop;
	decl String:s[PLATFORM_MAX_PATH];
	KvRewind(BossKV[Special[index]]);
	KvGetString(BossKV[Special[index]], "model",s, PLATFORM_MAX_PATH);
	SetVariantString(s);
	AcceptEntityInput(Boss[index], "SetCustomModel");
	SetEntProp(Boss[index], Prop_Send, "m_bUseClassAnimations",1);
	//TF2_StunPlayer(Boss[index], 5.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT,Boss[index]); 				
	return Plugin_Continue;
}

EquipBoss(index)
{
	DoOverlay(Boss[index],"");
	TF2_RemoveAllWeapons(Boss[index]);
	decl String:s[64];
	decl String:s2[128];
	for(new j = 1; ; j++)
	{
		KvRewind(BossKV[Special[index]]);
		Format(s,10,"weapon%i",j);
		if (KvJumpToKey(BossKV[Special[index]],s))
		{
			KvGetString(BossKV[Special[index]], "name",s, 64);
			KvGetString(BossKV[Special[index]], "attributes",s2, 128);
			Format(s2,128,"68 ; 2 ; 2 ; 3.0 ; 259 ; 1 ; 269 ; 1 ; %s",s2);
			new BossWeapon = SpawnWeapon(Boss[index],s,KvGetNum(BossKV[Special[index]], "index"),101,5,s2);
			if (!KvGetNum(BossKV[Special[index]], "show",0))
				SetEntProp(BossWeapon, Prop_Send, "m_iWorldModelIndex", -1);
			SetEntPropEnt(Boss[index], Prop_Send, "m_hActiveWeapon",BossWeapon);
			KvGoBack(BossKV[Special[index]]);
			new TFClassType:tclass = TFClassType:KvGetNum(BossKV[Special[index]], "class",1);
			if (TF2_GetPlayerClass(Boss[index])!= tclass)
				TF2_SetPlayerClass(Boss[index], tclass);
		}
		else
			break;
	}
}

public OnChangeClass(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
    new iClient = GetClientOfUserId(GetEventInt(event, "userid")), 
            TFClassType:oldclass = TF2_GetPlayerClass(iClient), 
            iTeam   = GetClientTeam(iClient); 
     
    if(iTeam==BossTeam && !b_allowBossChgClass && IsPlayerAlive(iClient) && GetBossIndex(iClient) !=-1)  
    { 
        CPrintToChat(iClient,"{olive}[FF2] {default}Do NOT change class when you're a HALE!");
        b_BossChgClassDetected = true; 
        TF2_SetPlayerClass(iClient, oldclass); 
    } 
} 

public Action:MakeBoss(Handle:hTimer,any:index)
{
	if (!Boss[index] || !IsValidEdict(Boss[index]) || !IsClientInGame(Boss[index]))
		return Plugin_Continue;
	KvRewind(BossKV[Special[index]]);
	TF2_SetPlayerClass(Boss[index], TFClassType:KvGetNum(BossKV[Special[index]], "class",1));
	if (GetClientTeam(Boss[index]) != BossTeam)
	{
		b_allowBossChgClass = true;
		SetEntProp(Boss[index], Prop_Send, "m_lifeState", 2);
		ChangeClientTeam(Boss[index], BossTeam);
		SetEntProp(Boss[index], Prop_Send, "m_lifeState", 0);
		TF2_RespawnPlayer(Boss[index]);
		b_allowBossChgClass = false;
	}
	if (!IsPlayerAlive(Boss[index]))
	{
		if (FF2RoundState == 0) TF2_RespawnPlayer(Boss[index]);
		else return Plugin_Continue;
	}
	
	CreateTimer(0.2, MakeModelTimer,index);
	if (!IsVoteInProgress() && GetClientClassinfoCookie(Boss[index]))
		HelpPanelBoss(index);
	
	if (!IsPlayerAlive(Boss[index]))
		return Plugin_Continue;

	new ent = -1;
	while ((ent = FindEntityByClassname2(ent, "tf_wearable")) != -1)
	{
		if (IsBoss(GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")))
		{
			switch (GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 438, 463, 167, 477, 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542: {}
				default:	AcceptEntityInput(ent, "kill");
			}
		}
	}
	while ((ent = FindEntityByClassname2(ent, "tf_wearable_demoshield")) != -1)
	{
		if (IsBoss(GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")))
			AcceptEntityInput(ent, "kill");
	}
	
	while ((ent = FindEntityByClassname2(ent, "tf_usableitem")) != -1)
	{
		if (IsBoss(GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")))
		{
			switch (GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 438, 463, 167, 477, 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542: {}
				default:	AcceptEntityInput(ent, "kill");
			}
		}
	}	
	while ((ent = FindEntityByClassname2(ent, "tf_powerup_bottle")) != -1)
	{
		if (IsBoss(GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")))
			AcceptEntityInput(ent, "kill");
	}
    
	EquipBoss(index); 	
	KSpreeCount[index] = 0;
	BossCharge[index][0] = 0.0;
	SetEntProp(Boss[index], Prop_Data, "m_iMaxHealth",BossHealthMax[index]);

	SetClientQueuePoints(Boss[index], 0);	
	
	if (chkFirstHale == 0)
	{
		if (GetConVarBool(cvarFirstRound) && RoundCount == 0)
			cFH(Boss[index]);
		else if (!GetConVarBool(cvarFirstRound) && RoundCount == 1)
			cFH(Boss[index]);
	}
	
	return Plugin_Continue;
}

public cFH(any:i)
{
	if(i > 0)
		CreateTimer(3.0,checkFirstHale,i);
}

public Action:checkFirstHale(Handle:timer,any:i)
{
	b_allowBossChgClass = true;
	if (GetBossIndex(i)!=-1 && i > 0)
	{
		CPrintToChat(i,"{olive}[FF2] {default}First-round Hale Bug Check!");
		ForcePlayerSuicide(i);
		if (TF2_GetPlayerClass(i) == TFClass_Soldier)
			TF2_SetPlayerClass(i, TFClass_Scout);
		else
			TF2_SetPlayerClass(i, TFClass_Soldier);
		TF2_RespawnPlayer(i);
		TF2_RemoveAllWeapons(i);
		CPrintToChat(i,"{olive}[FF2] {default}We'll fix you up when the game starts.");
	}
	b_allowBossChgClass = false;
	chkFirstHale++;
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if (!Enabled) return Plugin_Continue;
	//if (hItem != INVALID_HANDLE) return Plugin_Continue;
	switch (iItemDefinitionIndex)
	{
		case 39, 351:
		{
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "25 ; 0.5 ; 207 ; 1.33 ; 144 ; 1.0 ; 58 ; 3.2", true);
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 40:
		{
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "165 ; 1.0");
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 648:
		{
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "279 ; 2.0");
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 444:
		{
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "58 ; 1.5");
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 220:
		{
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "328 ; 1.0", true);
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 226:
		{
//			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "116 ; 4.0", true);
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "140 ; 10.0");
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 305:
		{
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "17 ; 0.1 ; 2 ; 1.2"); // ; 266 ; 1.0");
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 56:
		{
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "2 ; 1.5");
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 38, 457:
		{
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "", true);
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
//		case 132, 266, 482:
//		{
//			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "202 ; 0.5 ; 125 ; -15", true);
//			if (hItemOverride != INVALID_HANDLE)
//			{
//				hItem = hItemOverride;
//				return Plugin_Changed;
//			}
//		}
		case 43, 239:
		{
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, 239, "107 ; 1.5 ; 1 ; 0.5 ; 128 ; 1 ; 191 ; -7", true);
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 415:
		{
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, "265 ; 99999.0 ; 178 ; 0.6 ; 2 ; 1.1 ; 3 ; 0.5", true);
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
//		case 526:
	}
	if (TF2_GetPlayerClass(client) == TFClass_Soldier && (strncmp(classname, "tf_weapon_rocketlauncher", 24, false) == 0 || strncmp(classname, "tf_weapon_shotgun", 17, false) == 0))
	{
		new Handle:hItemOverride;
		if (iItemDefinitionIndex == 127) hItemOverride = PrepareItemHandle(hItem, _, _, "265 ; 99999.0 ; 179 ; 1.0");
		else hItemOverride = PrepareItemHandle(hItem, _, _, "265 ; 99999.0");
		if (hItemOverride != INVALID_HANDLE)
		{
			hItem = hItemOverride;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:Timer_NoHonorBound(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		new index = ((IsValidEntity(weapon) && weapon > MaxClients) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
		new active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new String:classname[64];
		if (IsValidEdict(active)) GetEdictClassname(active, classname, sizeof(classname));
		if (index == 357 && active == weapon && strcmp(classname, "tf_weapon_katana", false) == 0)
		{
			SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
			if (GetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy") < 1)
				SetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
		}
	}
}
stock Handle:PrepareItemHandle(Handle:hItem, String:name[] = "", index = -1, const String:att[] = "", bool:dontpreserve = false)
{
	static Handle:hWeapon;
	new addattribs = 0;

	new String:weaponAttribsArray[32][32];
	new attribCount = ExplodeString(att, " ; ", weaponAttribsArray, 32, 32);

	new flags = OVERRIDE_ATTRIBUTES;
	if (!dontpreserve) flags |= PRESERVE_ATTRIBUTES;
	if (hWeapon == INVALID_HANDLE) hWeapon = TF2Items_CreateItem(flags);
	else TF2Items_SetFlags(hWeapon, flags);
//	new Handle:hWeapon = TF2Items_CreateItem(flags);	//INVALID_HANDLE;
	if (hItem != INVALID_HANDLE)
	{
		addattribs = TF2Items_GetNumAttributes(hItem);
		if (addattribs > 0)
		{
			for (new i = 0; i < 2 * addattribs; i += 2)
			{
				new bool:dontAdd = false;
				new attribIndex = TF2Items_GetAttributeId(hItem, i);
				for (new z = 0; z < attribCount+i; z += 2)
				{
					if (StringToInt(weaponAttribsArray[z]) == attribIndex)
					{
						dontAdd = true;
						break;
					}
				}
				if (!dontAdd)
				{
					IntToString(attribIndex, weaponAttribsArray[i+attribCount], 32);
					FloatToString(TF2Items_GetAttributeValue(hItem, i), weaponAttribsArray[i+1+attribCount], 32);
				}
			}
			attribCount += 2 * addattribs;
		}
		CloseHandle(hItem);	//probably returns false but whatever
	}

	if (name[0] != '\0')
	{
		flags |= OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(hWeapon, name);
	}
	if (index != -1)
	{
		flags |= OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(hWeapon, index);
	}
	if (attribCount > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, (attribCount/2));
		new i2 = 0;
		for (new i = 0; i < attribCount && i < 32; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}
	TF2Items_SetFlags(hWeapon, flags);
	return hWeapon;
}

public Action:MakeNotBoss(Handle:hTimer,any:clientid)
{
	new client = GetClientOfUserId(clientid);
	if (!IsValidClient(client) || !IsPlayerAlive(client) || FF2RoundState == 2 || IsBoss(client))
		return Plugin_Continue;
	if (LastClass[client] != TFClass_Unknown)
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		TF2_SetPlayerClass(client,LastClass[client]);
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
		LastClass[client] = TFClass_Unknown;
		TF2_RespawnPlayer(client);
	}
	if (!IsVoteInProgress() && GetClientClassinfoCookie(client))
		HelpPanel2(client);

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0); 
	if (GetClientTeam(client) != OtherTeam)
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		ChangeClientTeam(client, OtherTeam);
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
		TF2_RespawnPlayer(client);
	}
	CreateTimer(0.1, checkItems, client);
	return Plugin_Continue;
}

public Action:checkItems(Handle:hTimer,any:client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || FF2RoundState == 2 || IsBoss(client))
		return Plugin_Continue;
	SetEntityRenderColor(client, 255, 255, 255, 255);
	new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	new index = -1;
	
	if (bMedieval)
		return Plugin_Continue;
	if (IsValidEdict(weapon) && (weapon > 0))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch (index)
		{
			case 41:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				weapon = SpawnWeapon(client,"tf_weapon_minigun",15,1,0,"");
			}
			case 402:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				SpawnWeapon(client,"tf_weapon_sniperrifle",14,1,0,"");
			}
			case 237:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				weapon = SpawnWeapon(client,"tf_weapon_rocketlauncher",18,1,0,"");
				SetAmmo(client, 0, 20);
			}
			case 17, 204, 36, 412:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				SpawnWeapon(client,"tf_weapon_syringegun_medic",17,1,10,"17 ;  0.05 ;  144 ;  1");
			}
		}
	}
	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (weapon && IsValidEdict(weapon))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch (index)
		{
			case 57, 231:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				weapon = SpawnWeapon(client,"tf_weapon_smg",16,1,0,"");
			}
			case 265:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				weapon = SpawnWeapon(client,"tf_weapon_pipebomblauncher",20,1,0,"");
				SetAmmo(client,1,24);
			}
			case 39, 351:
			{
				if (GetEntProp(weapon, Prop_Send, "m_iEntityQuality") != 10)
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
					weapon = SpawnWeapon(client, "tf_weapon_flaregun", 39, 5, 10, "25 ;  0.5 ;  207 ;  1.33 ;  144 ;  1.0 ;  58 ;  5.0");
				}
			}
		}
	}
	if (FindPlayerBack(client))
	{
		RemovePlayerBack(client);
		weapon = SpawnWeapon(client,"tf_weapon_smg",16,1,0,"");
	}
	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if (weapon && IsValidEdict(weapon))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch (index)
		{
			case 331:
			{
				TF2_RemoveWeaponSlot(client,TFWeaponSlot_Melee);
				weapon = SpawnWeapon(client,"tf_weapon_fists",195,1,6,"");
			}
			case 357:
			{
				CreateTimer(1.0, Timer_NoHonorBound, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			case 589:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				weapon = SpawnWeapon(client, "tf_weapon_wrench", 7, 1, 0, "");
			}
		}
	}
	weapon = GetPlayerWeaponSlot(client, 4);
	if (weapon > 0 && IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 60)
	{
		TF2_RemoveWeaponSlot(client,4);
		weapon = SpawnWeapon(client,"tf_weapon_invis",297,1,6,"");
	}
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		new mediquality = (weapon > MaxClients && IsValidEdict(weapon) ? GetEntProp(weapon, Prop_Send, "m_iEntityQuality") : -1);
		if (mediquality != 10)
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			weapon = SpawnWeapon(client, "tf_weapon_medigun", 29, 5, 10, "10 ;  1.25 ;  178 ;  0.75"); 	//200 ;  1 for area of effect healing	// ;  178 ;  0.75 ;  128 ;  1.0 Faster switch-to
			SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 0.41);
		}
	}
	return Plugin_Continue;
}


stock RemovePlayerBack(client)
{
	new edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 57 || idx == 231) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}

stock FindPlayerBack(client)
{
	new edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 57 || idx == 231) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
				return true;
		}
	}
	return false;
}

public Action:event_destroy(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (Enabled)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (!GetRandomInt(0,2) && IsBoss(attacker))
		{
			decl String:s[PLATFORM_MAX_PATH];
			if (RandomSound("sound_kill_buildable",s,PLATFORM_MAX_PATH))
			{
				EmitSoundToAll(s);
				EmitSoundToAll(s);
			}
		}
	}
	return Plugin_Continue;
}

public Action:event_changeclass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (Enabled)
		CreateTimer(0.1,Timer_changeclass,GetEventInt(event, "userid"));
	return Plugin_Continue;
}

public Action:Timer_changeclass(Handle:hTimer,any:userid)
{
	new client = GetClientOfUserId(userid);
	new index = GetBossIndex(client);
	if (index == -1 || Special[index] == -1 || !BossKV[Special[index]])
		return Plugin_Continue;
	KvRewind(BossKV[Special[index]]);
	new TFClassType:tclass = TFClassType:KvGetNum(BossKV[Special[index]], "class",0);
	if (TF2_GetPlayerClass(client) != tclass)
		TF2_SetPlayerClass(client, tclass);
	
	return Plugin_Continue;
}

public Action:event_uberdeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled)
		return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if (IsValidEntity(medigun))
		{
			decl String:s[64];
			GetEdictClassname(medigun, s, sizeof(s));
			if (!strcmp(s,"tf_weapon_medigun"))
			{
				TF2_AddCondition(client,TFCond_HalloweenCritCandy,0.5);
				new target = GetHealingTarget(client);
				if (IsValidClient(target, false) && IsPlayerAlive(target))
					TF2_AddCondition(target,TFCond_HalloweenCritCandy,0.5);
				SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel",1.51);
				CreateTimer(0.4,Timer_Lazor,EntIndexToEntRef(medigun),TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Lazor(Handle:hTimer,any:medigunid)
{
	new medigun = EntRefToEntIndex(medigunid);
	if (medigun && IsValidEntity(medigun) && FF2RoundState == 1)
	{
		new client = GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		if (client < 1)
			return Plugin_Stop;
		new Float:charge = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == medigun)
		{
			new target = GetHealingTarget(client);
			if (charge > 0.05)
			{
				TF2_AddCondition(client,TFCond_HalloweenCritCandy,0.5);
				if (IsValidClient(target, false) && IsPlayerAlive(target))
					TF2_AddCondition(target,TFCond_HalloweenCritCandy,0.5);
			}
		}
		if (charge <= 0.05)
		{
			CreateTimer(3.0,Timer_Lazor2,EntIndexToEntRef(medigun));
			FF2flags[client] &= ~FF2FLAG_UBERREADY;
			return Plugin_Stop;
		}
	}
	else
		return Plugin_Stop;
	return Plugin_Continue;
}

public Action:Timer_Lazor2(Handle:hTimer,any:medigunid)
{
	new medigun = EntRefToEntIndex(medigunid);
	if (IsValidEntity(medigun))
		SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel",GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+0.41);
	return Plugin_Continue;
}
public Action:Command_GetHPCmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	Command_GetHP(client);
	return Plugin_Handled;
}

public Action:Command_GetHP(client)
{
	if (!Enabled || FF2RoundState!= 1)
		return Plugin_Continue;
	if (IsBoss(client) || RoundFloat(HPTime) <= 0)
	{
		new String:s[512];
		decl String:s2[4];
		decl String:name[64];
		for (new i = 0; Boss[i]; i++)
		{
			KvRewind(BossKV[Special[i]]);
			KvGetString(BossKV[Special[i]], "name", name, 64," = Failed name = ");
			if (BossLives[i] > 1)
				Format(s2,4,"x%i",BossLives[i]);
			else
				strcopy(s2,2,"");
			Format(s,512,"%s\n%t",s,"ff2_hp",name,BossHealth[i]-BossHealthMax[i]*(BossLives[i]-1),BossHealthMax[i],s2);
			BossHealthLast[i] = BossHealth[i]-BossHealthMax[i]*(BossLives[i]-1);
		}
		for (new i = 1;  i <= MaxClients;  i++)
			if (IsValidClient(i) && !(FF2flags[i] & FF2FLAG_HUDDISABLED))
			{
				SetGlobalTransTarget(i);
				PrintCenterText(i,s); 	
			}
		CPrintToChatAll("{olive}[FF2]{default} %s",s);
		
		if (RoundFloat(HPTime) <= 0)
		{
			healthcheckused++;
			HPTime = (healthcheckused < 3 ? 20.0 : 80.0);
		}
		return Plugin_Continue;
	}
	if (RedAlivePlayers > 1)
	{
		new String:s[128];
		for (new i = 0; Boss[i]; i++)
			Format(s,128,"%s %i,",s,BossHealthLast[i]);
		CPrintToChat(client,"{olive}[FF2]{default} %t","wait_hp",RoundFloat(HPTime), s);
	}
	return Plugin_Continue;
}

public Action:Command_MakeNextSpecial(client, args)
{
	decl String:arg[32];
	decl String:Special_Name[64];
	if (args < 1)
	{
		ReplyToCommand(client, "[FF2] Usage: ff2_special < boss > ");
		return Plugin_Handled;
	}
	GetCmdArgString(arg, sizeof(arg));
	decl i;
	for (i = 0; i < Specials; i++)
	{
		KvRewind(BossKV[i]);
		KvGetString(BossKV[i], "name",Special_Name, 64);
		if (StrContains(Special_Name,arg,false) >= 0)
		{
			Incoming[0] = i;
			ReplyToCommand(client, "[FF2] Set the next Special to %s", Special_Name);
			return Plugin_Handled;
		}
		KvGetString(BossKV[i], "filename",Special_Name, 64);
		if (StrContains(Special_Name,arg,false) >= 0)
		{
			Incoming[0] = i;
			KvGetString(BossKV[i], "name",Special_Name, 64);
			ReplyToCommand(client, "[FF2] Set the next Special to %s", Special_Name);
			return Plugin_Handled;
		}
	}
	ReplyToCommand(client, "[FF2] Boss not be found.");
	return Plugin_Handled;
}

public Action:Command_Points(client, args)
{
	if (!Enabled2)
		return Plugin_Continue;
	if (args != 2)
	{
		ReplyToCommand(client, "[FF2] Usage: ff2_addpoints < target > < points > ");
		return Plugin_Handled;
	}

	decl String:s2[80];

	decl String:targetname[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetname, sizeof(targetname));
	GetCmdArg(2, s2, sizeof(s2));
	new points = StringToInt(s2);
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			targetname,
			client,
			target_list,
			MaxClients,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0;  i < target_count;  i++)
	{
		SetClientQueuePoints(target_list[i],GetClientQueuePoints(target_list[i])+points);
		ReplyToCommand(client, "[FF2] Added %d queue points to %s", points, target_name);
	}

	return Plugin_Handled;
}

public Action:Command_StopMusic(client, args)
{
	if (!Enabled2)
		return Plugin_Continue;
	Native_StopMusic(INVALID_HANDLE,0);
	ReplyToCommand(client, "[FF2] Stopped boss music.");
	return Plugin_Handled;
}

public Action:Command_CharSet(client, args)
{
	decl String:arg[32];
	if (args < 1)
	{
		ReplyToCommand(client, "[FF2] Usage: ff2_charset < charset > ");
		return Plugin_Handled;
	}
	GetCmdArgString(arg, 32);
	decl String:s[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"configs/freak_fortress_2/characters.cfg");
	new Handle:Kv = CreateKeyValues("");
	FileToKeyValues(Kv, s);
	new i=0;
	for(;;)
	{
		KvGetSectionName(Kv, s, 64);
		if (StrContains(s,arg,false) >= 0)
		{
			ReplyToCommand(client, "[FF2] Charset for Nextmap is %s",s);
			break;
		}
		if (!KvGotoNextKey(Kv))
		{
			ReplyToCommand(client, "[FF2] ff2_charset: Charset not found ");
			return Plugin_Handled;			
		}
	}
	CloseHandle(Kv);
	FF2CharSet=i;
	return Plugin_Handled;
}

public Action:Command_ReloadSubPlugins(client, args)
{
	if (Enabled)
	{
		DisableSubPlugins(true);
		EnableSubPlugins(true);
	}	
	ReplyToCommand(client, "[FF2] Subplugins reloaded.");	
	return Plugin_Handled;
}

public Action:Command_Point_Disable(client, args)
{
	if (Enabled) SetControlPoint(false);
	return Plugin_Handled;
}

public Action:Command_Point_Enable(client, args)
{
	if (Enabled) SetControlPoint(true);
	return Plugin_Handled;
}
stock SetControlPoint(bool:enable)
{
	new CPm = MaxClients+1; 	
	while ((CPm = FindEntityByClassname2(CPm, "team_control_point")) != -1)
	{
		if (CPm > MaxClients && IsValidEdict(CPm))
		{
			AcceptEntityInput(CPm, (enable ? "ShowModel" : "HideModel"));
			SetVariantInt(enable ? 0 : 1);
			AcceptEntityInput(CPm, "SetLocked");
		}
	}
}
stock SetArenaCapEnableTime(Float:time)
{
	new ent = -1;
	decl String:strTime[32];
	FloatToString(time, strTime, sizeof(strTime));
	if ((ent = FindEntityByClassname2(-1, "tf_logic_arena")) != -1 && IsValidEdict(ent))
	{
		DispatchKeyValue(ent, "CapEnableDelay", strTime);
	}
}

public OnClientPutInServer(client)
{
	FF2flags[client] = 0;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	Damage[client] = 0;
	uberTarget[client] = -1;
	if (!AreClientCookiesCached(client)) return ;
	new String:s[24];
	GetClientCookie(client, FF2Cookies, s,24);
	if (!s[0])
		SetClientCookie(client, FF2Cookies, "0 1 1 1 3 3 3");
	LastClass[client]=TFClass_Unknown;
}

public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled)
		return Plugin_Continue;
		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client, false))
		return Plugin_Continue;
		
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	
	if (b_BossChgClassDetected)
	{
		TF2_RemoveAllWeapons(client);
		b_BossChgClassDetected = false;
	}
	
	if ((FF2RoundState != 1 || !(FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM)))
		CreateTimer(0.1, MakeNotBoss, GetClientUserId(client));
	else
		CreateTimer(0.1, checkItems, client);
		
	FF2flags[client] = FF2FLAGS_SPAWN;
	return Plugin_Continue;
}

public Action:ClientTimer(Handle:hTimer)
{
	if (FF2RoundState > 1 || FF2RoundState == -1)
		return Plugin_Stop;
	decl String:wepclassname[32];
	new i = -1;
	decl TFCond:cond;
	for(new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && !IsBoss(client) && !(FF2flags[client] & FF2FLAG_CLASSTIMERDISABLED))
		{
			if (!(FF2flags[client] & FF2FLAG_HUDDISABLED))
			{
				SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
				if (!IsPlayerAlive(client))
				{
					new obstarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
					if (IsValidClient(obstarget) && !IsBoss(obstarget) && obstarget != client)
						ShowSyncHudText(client, rageHUD, "Damage: %d - %N's Damage: %d", Damage[client], obstarget, Damage[obstarget]);
					else
						ShowSyncHudText(client, rageHUD, "Damage: %d", Damage[client]);
					continue;
				}
				ShowSyncHudText(client, rageHUD, "Damage: %d", Damage[client]);
			}
			if (!IsPlayerAlive(client)) continue;
			new TFClassType:class = TF2_GetPlayerClass(client);
			new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (weapon <= MaxClients || !IsValidEntity(weapon) || !GetEdictClassname(weapon, wepclassname, sizeof(wepclassname))) strcopy(wepclassname, sizeof(wepclassname), "");
			new bool:validwep = (strncmp(wepclassname, "tf_wea", 6, false) == 0);
			new index = (validwep ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if (class == TFClass_Medic)
			{
				if (weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
				{
					new medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					decl String:mediclassname[64];
					if (IsValidEdict(medigun) && GetEdictClassname(medigun, mediclassname, sizeof(mediclassname)) && strcmp(mediclassname, "tf_weapon_medigun", false) == 0)
					{
						new charge = RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") * 100);
						if (!(FF2flags[client] & FF2FLAG_HUDDISABLED))
						{
							SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
							ShowSyncHudText(client, jumpHUD, "%T: %i", "uber-charge", client, charge);
						}
						if (charge == 100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
						{
							FakeClientCommandEx(client, "voicemenu 1 7");
							FF2flags[client] |= FF2FLAG_UBERREADY;
						}
					}
				}
				if (weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
				{
					new healtarget = GetHealingTarget(client,true);
					if (IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget) == TFClass_Scout)
					{
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
					}
				}
			}
			if (RedAlivePlayers == 1 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.3);
				new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				if (class == TFClass_Engineer && (IsValidEntity(primary) && primary > MaxClients ? GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex") : -1) == 141) SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
				TF2_AddCondition(client, TFCond_Buffed, 0.3);
				continue;
			}
			if (RedAlivePlayers == 2 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				TF2_AddCondition(client,TFCond_Buffed,0.3);
			if (bMedieval)
				continue;
			cond = TFCond_HalloweenCritCandy;
			if (TF2_IsPlayerInCondition(client, TFCond_CritCola) && (class == TFClass_Scout || class == TFClass_Heavy))
			{
				TF2_AddCondition(client,cond,0.3);
				continue;
			}
			new medic = -1;
			for(i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i) && IsPlayerAlive(i) && GetHealingTarget(i,true) == client)
				{
					medic = i;
					break;
				}
			}
			new bool:addthecrit = false;
			if (validwep && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
			{
				decl String:classname[64];
				if (!GetEdictClassname(weapon, classname, sizeof(classname))) strcopy(classname, sizeof(classname), "");
				if (strcmp(classname, "tf_weapon_knife", false) != 0)
					addthecrit = true;
			}
			switch (index)
			{
				case 305, 14, 56, 201, 230, 402, 16, 203, 58, 526: addthecrit = true;
				case 22, 23, 160, 209, 294, 449:
				{
					addthecrit = true;
					if (class == TFClass_Scout && cond == TFCond_HalloweenCritCandy) cond = TFCond_Buffed;
				}
				case 656:
				{
					addthecrit = true;
					cond = TFCond_Buffed;
				}
			}
			switch (class)
			{
				case TFClass_Medic:
				{
					if (weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						new medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
						if (IsValidEdict(medigun))
						{
							SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255,0,0.2,0.0,0.1);
							new charge = RoundFloat(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
							ShowHudText(client, -1,"%T: %i","uber-charge", client,charge);
							if (charge == 100 && !(FF2flags[client]&FF2FLAG_UBERREADY))
							{
								FakeClientCommand(client,"voicemenu 1 7");
								FF2flags[client]|= FF2FLAG_UBERREADY;
							}
						}
					}
					if (weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
					{
						new healtarget = GetHealingTarget(client,true);
						if (IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget) == TFClass_Scout)
						{
							TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
						}
					}
				}
				case TFClass_DemoMan: if (!IsValidEntity(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))) addthecrit = true;
				case TFClass_Spy: if (validwep && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
				{
					if (!TF2_IsPlayerCritBuffed(client) && !TF2_IsPlayerInCondition(client, TFCond_Buffed) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !GetEntProp(client, Prop_Send, "m_bFeignDeathReady"))
					{
						TF2_AddCondition(client, TFCond_CritCola, 0.3);
					}
				}
				case TFClass_Engineer: if (weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && index == 141)
				{
					new sentry = FindSentry(client);
					if (IsValidEntity(sentry) && IsBoss(GetEntPropEnt(sentry, Prop_Send, "m_hEnemy")))
					{
						SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
						TF2_AddCondition(client, TFCond_Kritzkrieged, 0.3);
					}
					else
					{
						if (GetEntProp(client, Prop_Send, "m_iRevengeCrits")) SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);
						else if (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) && !TF2_IsPlayerInCondition(client, TFCond_Healing))
						{
							TF2_RemoveCondition(client, TFCond_Kritzkrieged);
						}
					}
				}/*
				case TFClass_Soldier: if (TF2_IsPlayerInCondition(client,TFCond_Healing) && IsValidEdict((weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 226 && !(FF2flags[client]&FF2FLAG_ISBUFFED))
				{			
					if (medic == -1)
					{
						new Float:charge = GetEntPropFloat(client, Prop_Send, "m_flRageMeter")+0.5;
						if (charge <= 100.0)
							SetEntPropFloat(client, Prop_Send, "m_flRageMeter",charge);
						else	
							SetEntPropFloat(client, Prop_Send, "m_flRageMeter",100.0); 																	
					}	
					else
					{	
						new Float:charge = GetEntPropFloat(client, Prop_Send, "m_flRageMeter")+1;
						if (charge <= 100.0)
							SetEntPropFloat(client, Prop_Send, "m_flRageMeter",charge);
						else
							SetEntPropFloat(client, Prop_Send, "m_flRageMeter",100.0);
						SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255,0,0.2,0.0,0.1);
						ShowHudText(medic, -1,"%T: %i","medic-sol_rage", medic,charge);
					}
				}*/
			}
			if (addthecrit)
			{
				TF2_AddCondition(client, cond, 0.3);
				if (medic!= -1 && cond != TFCond_Buffed) TF2_AddCondition(client, TFCond_Buffed, 0.3);
			}
		}
	}
	return Plugin_Continue;
}

public Action:BackUpBuffTimer(Handle:hTimer,any:clientid)
{
	new client = GetClientOfUserId(clientid);
	TF2_RemoveCondition(client,TFCond_Buffed);
	FF2flags[client] &= ~FF2FLAG_ISBUFFED;
	return Plugin_Continue;
}

stock FindSentry(client)
{
	new i = -1;
	while ((i = FindEntityByClassname2(i, "obj_sentrygun")) != -1)
	{
		if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client) return i;
	}
	return -1;
}

public Action:BossTimer(Handle:hTimer)
{
	new bool:bIsEveryponyDead=true;
	for (new index = 0;index<=MaxClients; index++)
	{
		if (!IsValidClient(Boss[index], false))
			break;
		if (!IsPlayerAlive(Boss[index]))
			continue;
		if (FF2RoundState == 2)
			break;
		bIsEveryponyDead = false;
		if (!(FF2flags[Boss[index]] & FF2FLAG_USEBOSSTIMER))
			continue;
		if (TF2_IsPlayerInCondition(Boss[index],TFCond_Jarated))
			TF2_RemoveCondition(Boss[index],TFCond_Jarated);
		if (TF2_IsPlayerInCondition(Boss[index], TFCond_MarkedForDeath))
			TF2_RemoveCondition(Boss[index], TFCond_MarkedForDeath);
		SetEntPropFloat(Boss[index], Prop_Data, "m_flMaxspeed", BossSpeed[Special[index]]+0.7*(100-BossHealth[index]*100/BossLivesMax[index]/BossHealthMax[index]));
		if (BossHealth[index] <= 0 && IsPlayerAlive(Boss[index]))
			BossHealth[index] = 1;
		SetBossHealthFix(Boss[index], BossHealth[index]);
	
		if (!(FF2flags[Boss[index]] & FF2FLAG_HUDDISABLED))
		{
			SetHudTextParams(-1.0, 0.77, 0.15, 255, 255, 255, 255);
			ShowSyncHudText(Boss[index], healthHUD, "%t","health",BossHealth[index]-BossHealthMax[index]*(BossLives[index]-1),BossHealthMax[index]);
			if (RoundFloat(BossCharge[index][0]) == 100)
			{
				if (IsFakeClient(Boss[index]) && !(FF2flags[Boss[index]] & FF2FLAG_BOTRAGE))
				{
					CreateTimer(1.0, Timer_BotRage,index, TIMER_FLAG_NO_MAPCHANGE);
					FF2flags[Boss[index]] |= FF2FLAG_BOTRAGE;
				}
				else
				{
					SetHudTextParams(-1.0, 0.83, 0.15, 255, 64, 64, 255);
					ShowSyncHudText(Boss[index], rageHUD,"%t","do_rage");
				}
			}
			else
			{
				SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255);
				ShowSyncHudText(Boss[index], rageHUD,"%t","rage_meter",RoundFloat(BossCharge[index][0]));
			}	
		}
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
		
		if (GlowTimer[index] <= 0.0)
		{
			SetEntProp(Boss[index], Prop_Send, "m_bGlowEnabled", 0);
			GlowTimer[index] = 0.0;
		}
		else
			GlowTimer[index] -= 0.2;
		decl slot,j,buttonmode,count;
		decl String:lives[MAXRANDOMS][3];
		for(new n = 1; ; n++)
		{		
			decl String:s[10];
			Format(s,10,"ability%i",n);
			KvRewind(BossKV[Special[index]]);
			if (KvJumpToKey(BossKV[Special[index]],s))
			{
				decl String:plugin_name[64];
				KvGetString(BossKV[Special[index]], "plugin_name",plugin_name,64);
				slot = KvGetNum(BossKV[Special[index]], "arg0",0);
				buttonmode = KvGetNum(BossKV[Special[index]], "buttonmode",0);
				if (slot < 1)
					continue;
					
				KvGetString(BossKV[Special[index]], "life",s,10,"");
				if (!s[0])
				{
					decl String:ability_name[64];
					KvGetString(BossKV[Special[index]], "name",ability_name,64);
					UseAbility(ability_name,plugin_name,index,slot,buttonmode);
				}
				else		
				{
					count = ExplodeString(s, " ", lives, MAXRANDOMS, 3);
					for(j = 0; j < count; j++)
						if (StringToInt(lives[j]) == BossLives[index])
						{
							decl String:ability_name[64];
							KvGetString(BossKV[Special[index]], "name",ability_name,64);
							UseAbility(ability_name,plugin_name,index,slot,buttonmode);
							break;
						}
				}
			}
			else
				break;
		}
	
		if (RedAlivePlayers == 1)
		{
			new String:s[512];
			decl String:name1[64];
			for(new i = 0; Boss[i]; i++)
			{
				KvRewind(BossKV[Special[i]]);
				KvGetString(BossKV[Special[i]], "name", name1, 64," = Failed name = ");
				if (BossLives[i] > 1)
					Format(s,512,"%s\n%s's HP: %i of %ix%i",s,name1,BossHealth[i]-BossHealthMax[i]*(BossLives[i]-1),BossHealthMax[i],BossLives[i]);
				else
					Format(s,512,"%s\n%s's HP: %i of %i",s,name1,BossHealth[i]-BossHealthMax[i]*(BossLives[i]-1),BossHealthMax[i]);
			}
			for (new i = 1;  i <= MaxClients;  i++)
				if (IsValidClient(i) && !(FF2flags[i] & FF2FLAG_HUDDISABLED))
				{
					SetGlobalTransTarget(i);
					PrintCenterText(i,s); 	
				}
		}
		if (OnlyScoutsLeft())
		{
			if (BossCharge[index][0] < 100)
				BossCharge[index][0] += 0.2;
		}
		HPTime-= 0.2;
		if (HPTime < 0)
			HPTime = 0.0;
		for(new i = 0; i <= MaxClients; i++)
			if (KSpreeTimer[i] > 0) 
				KSpreeTimer[i]-= 0.2; 	
	}
	if (bIsEveryponyDead)
		return Plugin_Stop;
	return Plugin_Continue;
}

public Action:Timer_BotRage(Handle:timer,any:index)
{
	if (!IsValidClient(Boss[index], false)) return;
	if (!TF2_IsPlayerInCondition(Boss[index], TFCond_Taunting)) FakeClientCommandEx(Boss[index], "taunt");
}

stock OnlyScoutsLeft()
{
	for (new client = 1;  client <= MaxClients;  client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client) && !IsBoss(client) && TF2_GetPlayerClass(client) != TFClass_Scout)
			return false;
	}
	return true;
}

public Action:Destroy(client, const String:command[], argc)
{
	if (!Enabled || IsBoss(client))
		return Plugin_Continue;
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Engineer && TF2_IsPlayerInCondition(client, TFCond_Taunting) && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 589)
		return Plugin_Handled;
	return Plugin_Continue;
}
stock GetIndexOfWeaponSlot(client, slot)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	return (weapon > MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}
public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if (TF2_GetPlayerClass(client) == TFClass_Scout && condition == TFCond_CritHype)
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);	//recalc their speed
	}
}

public Action:DoTaunt(client, const String:command[], argc)
{
	if (!Enabled)
		return Plugin_Continue;
	else
	{
		if (FF2RoundState == 0)
			return Plugin_Handled;
		else
			if (!IsBoss(client))
				return Plugin_Continue;
	}
	if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
		return Plugin_Handled;
	
	new index = GetBossIndex(client);
	if (index == -1 || !Boss[index] || !IsValidEdict(Boss[index]))
		return Plugin_Continue;
	if (RoundFloat(BossCharge[index][0]) == 100)
	{
		decl i,j,count;
		decl String:s[10];
		decl String:lives[MAXRANDOMS][3];
		for(i = 1; i < MAXRANDOMS; i++)
		{
			Format(s,10,"ability%i",i);
			KvRewind(BossKV[Special[index]]);
			if (KvJumpToKey(BossKV[Special[index]],s))
			{
				if (KvGetNum(BossKV[Special[index]], "arg0",0))
					continue;
				KvGetString(BossKV[Special[index]], "life",s,10); 		
				if (!s[0])
				{
					decl String:ability_name[64], String:plugin_name[64];
					KvGetString(BossKV[Special[index]], "plugin_name",plugin_name,64);
					KvGetString(BossKV[Special[index]], "name",ability_name,64);
					UseAbility(ability_name,plugin_name,index,0);
				}
				else	
				{
					count = ExplodeString(s, " ", lives, MAXRANDOMS, 3);
					for(j = 0; j < count; j++)
						if (StringToInt(lives[j]) == BossLives[index])
						{
							decl String:ability_name[64], String:plugin_name[64];
							KvGetString(BossKV[Special[index]], "plugin_name",plugin_name,64);
							KvGetString(BossKV[Special[index]], "name",ability_name,64);
							UseAbility(ability_name,plugin_name,index,0);
							break;
						}
				}					
			}
		}
		
		decl Float:pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		decl String:s2[PLATFORM_MAX_PATH];
		if (RandomSoundAbility("sound_ability",s2,PLATFORM_MAX_PATH))
		{
			FF2flags[Boss[index]] |= FF2FLAG_TALKING;
			EmitSoundToAll(s2, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
			EmitSoundToAll(s2, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
		
			for (i = 1;  i <= MaxClients;  i++)
				if (IsClientInGame(i) && i!= Boss[index])
				{
					EmitSoundToClient(i,s2, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
					EmitSoundToClient(i,s2, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
				}
			FF2flags[Boss[index]] &= ~FF2FLAG_TALKING;
		}
	}
	return Plugin_Continue;
}

public Action:DoSuicide(client, const String:command[], argc)
{
	if (Enabled && IsBoss(client) && FF2RoundState <= 0)
		return Plugin_Handled;
	return Plugin_Continue;
}


public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (Enabled && client && GetClientHealth(client) <= 0 && FF2RoundState == 1)
	{
		OnPlayerDeath(client,GetClientOfUserId(GetEventInt(event, "attacker")),(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) != 0);
	}
	return Plugin_Continue;
}

OnPlayerDeath(client,attacker,bool:fake = false)
{
	if (FF2RoundState != 1)
		return;

	CreateTimer(0.1,CheckAlivePlayers);
			
	DoOverlay(client,"");
	
	decl String:s[PLATFORM_MAX_PATH]; 	
	if (!IsBoss(client))
	{
		if (fake)
			return;
		CreateTimer(1.0,Timer_Damage,GetClientUserId(client));
		if (IsBoss(attacker))
		{	
			new index = GetBossIndex(attacker);
			if (RandomSound("sound_hit",s,PLATFORM_MAX_PATH,index))
			{
				EmitSoundToAll(s);
				EmitSoundToAll(s);
			}
			if (!GetRandomInt(0,2))
			{
				new Handle:data;
				CreateDataTimer(0.1,PlaySoundKill,data);
				WritePackCell(data, GetClientUserId(client));
				WritePackCell(data, index);
				ResetPack(data);
			}
			if (KSpreeTimer[index] > 0)
				KSpreeCount[index]++;
			else
				KSpreeCount[index] = 1;
			if (KSpreeCount[index] == 3) 
			{
				if (RandomSound("sound_kspree",s,PLATFORM_MAX_PATH,index))
				{
					EmitSoundToAll(s);
					EmitSoundToAll(s);
				}
				KSpreeCount[index] = 0;
			}
			else
				KSpreeTimer[index] = 5.0;
		}
	}
	else
	{		
		new index = GetBossIndex(client);
		if (index == -1)
			return;
		BossHealth[index] = 0;
		if (RandomSound("sound_death",s,PLATFORM_MAX_PATH,index))
		{
			EmitSoundToAll(s);
			EmitSoundToAll(s);
		}
		if (BossHealth[index] < 0)
			BossHealth[index] = 0;
		
		UpdateHealthBar();
		
		CreateTimer(0.5,Timer_RestoreLastClass,GetClientUserId(client));
		return;
	}
	if (TF2_GetPlayerClass(client) == TFClass_Engineer && !fake)
	{
		FakeClientCommand(client, "destroy 2");
		for (new ent = MaxClients+1; ent < ME; ent++)
		if (IsValidEdict(ent))
		{
			GetEdictClassname(ent, s, sizeof(s));
			if (!StrContains(s,"obj_sentrygun") && (GetEntPropEnt(ent, Prop_Send, "m_hBuilder") == client))
			{
				SetVariantInt(GetEntPropEnt(ent, Prop_Send, "m_iMaxHealth")+1);
				AcceptEntityInput(ent, "RemoveHealth");
					
				new Handle:tevent = CreateEvent("object_removed", true);
				SetEventInt(tevent, "userid", GetClientUserId(client));
				SetEventInt(tevent, "index", ent);
				FireEvent(tevent);
				AcceptEntityInput(ent, "kill");
			}
		}
	}	
	return;
}

public Action:Timer_RestoreLastClass(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if (LastClass[client])
		TF2_SetPlayerClass(client,LastClass[client]);
	LastClass[client] = TFClass_Unknown;
	if (BossTeam == _:TFTeam_Red)
		ChangeClientTeam(client, _:TFTeam_Blue);
	else
		ChangeClientTeam(client, _:TFTeam_Red);
	return Plugin_Continue;
}

public Action:PlaySoundKill(Handle:hTimer,Handle:data)
{
	new client = GetClientOfUserId(ReadPackCell(data));
	if (!client)
		return Plugin_Continue;
	new String:classnames[][]={"","scout","sniper","soldier","demoman","medic","heavy","pyro","spy","engineer"};
	decl String:s[32],String:s2[PLATFORM_MAX_PATH];
	Format(s,32,"sound_kill_%s",classnames[TF2_GetPlayerClass(client)]);
	if (RandomSound(s,s2,PLATFORM_MAX_PATH,ReadPackCell(data)))
	{
		EmitSoundToAll(s2);
		EmitSoundToAll(s2);
	}
	return Plugin_Continue;
}

public Action:Timer_Damage(Handle:hTimer,any:id)
{
	new client = GetClientOfUserId(id);
	if (IsValidClient(client, false))
		CPrintToChat(client,"{olive}[FF2] %t. %t{default}","damage",Damage[client],"scores",RoundFloat(Damage[client]/600.0));
	return Plugin_Continue;
}

public Action:event_deflect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled || GetEventInt(event, "weaponid"))
		return Plugin_Continue;
	new index = GetBossIndex(GetClientOfUserId(GetEventInt(event, "ownerid")));
	if (index!= -1)
	{
		BossCharge[index][0]+= 7;
		if (BossCharge[index][0] > 100)
			BossCharge[index][0] = 100.0;
	}
	return Plugin_Continue;
}

public Action:event_jarate(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client = BfReadByte(bf);
	new victim = BfReadByte(bf);
	new index = GetBossIndex(victim);
	if (index == -1) return Plugin_Continue;
	new jar = GetPlayerWeaponSlot(client, 1);
	if (jar != -1 && GetEntProp(jar, Prop_Send, "m_iItemDefinitionIndex") == 58 && GetEntProp(jar, Prop_Send, "m_iEntityLevel") != -122)
	{
		BossCharge[index][0] -= 8.0;
		if (BossCharge[index][0] < 0)
			BossCharge[index][0] = 0.0;
	}
	return Plugin_Continue;
}

public Action:CheckAlivePlayers(Handle:hTimer)
{
	if (FF2RoundState == 2)
		return Plugin_Continue;
	RedAlivePlayers = 0;
	new BlueAlivePlayers = 0;
	for(new i = 1; i <= MaxClients; i++)
		if(IsValidEdict(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (GetClientTeam(i) == OtherTeam)
				RedAlivePlayers++;
			if (IsBoss(i))
				BlueAlivePlayers++;
		}
	
	if (RedAlivePlayers == 0)
		ForceTeamWin(BossTeam);
	else if ((RedAlivePlayers == 1) && BlueAlivePlayers && !DrawGameTimer)
	{
		if (BossHealth[0] > 2000 && UseCountdown>1)
		{
			if (FindEntityByClassname2(-1, "team_control_point") != -1)
			{
				timeleft = UseCountdown;
				DrawGameTimer=CreateTimer(1.0,Timer_DrawGame,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				EmitSoundToAll("vo/announcer_ends_2min.wav");
				EmitSoundToAll("vo/announcer_ends_2min.wav");
			}
		}
		else if (Boss[0])
		{
			decl String:s[PLATFORM_MAX_PATH];
			if (RandomSound("sound_lastman",s,PLATFORM_MAX_PATH))
			{
				decl Float:pos[3];
				GetEntPropVector(Boss[0], Prop_Send, "m_vecOrigin", pos);
				EmitSoundToAll(s);
				EmitSoundToAll(s);
			}
		}
		
	}	
	else if (!PointType && (RedAlivePlayers <= (AliveToEnable = GetConVarInt(cvarAliveToEnable))))
	{
		PrintHintTextToAll("%t","point_enable", AliveToEnable);
		if (RedAlivePlayers == AliveToEnable)
			EmitSoundToAll("vo/announcer_am_capenabled02.wav");
		SetControlPoint(true);
	}
	return Plugin_Continue;
}

public Action:Timer_DrawGame(Handle:timer)
{
	if (BossHealth[0] < 2000 || FF2RoundState!= 1)
		return Plugin_Stop;
	new time = timeleft;
	timeleft--;
	decl String:s1[6];
	if (time/60 > 9)
		IntToString(time/60,s1,6);
	else
		Format(s1,6,"0%i",time/60);
	if (time%60 > 9)
		Format(s1,6,"%s:%i",s1,time%60);
	else
		Format(s1,6,"%s:0%i",s1,time%60);
	SetHudTextParams(-1.0, 0.17, 1.1, 255, 255, 255, 255);
	for(new i = 1; i <= MaxClients; i++)
		if (IsValidClient(i) && IsClientConnected(i) && !(FF2flags[i] & FF2FLAG_HUDDISABLED))
			ShowSyncHudText(i, timeleftHUD,s1);
	if (time == 60)
		EmitSoundToAll("vo/announcer_ends_60sec.wav");
	else if (time == 30)
			EmitSoundToAll("vo/announcer_ends_30sec.wav");
	else if (time == 10)
			EmitSoundToAll("vo/announcer_ends_10sec.wav");
	else if (!time)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			if (!IsPlayerAlive(i)) continue;
			ForcePlayerSuicide(i);
		} // Thx MasterOfTheXP
		return Plugin_Stop; 		
	}
	else if (time <= 5)
	{
		decl String:s[PLATFORM_MAX_PATH];
		Format(s,PLATFORM_MAX_PATH,"vo/announcer_ends_%isec.wav",time);
		EmitSoundToAll(s);
	}
	return Plugin_Continue;
}

public Action:event_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled)
		return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "damageamount");
	new custom = GetEventInt(event, "custom");
	new index = GetBossIndex(client);
	if (index == -1 || !Boss[index] || !IsValidEdict(Boss[index]) || client == attacker)
		return Plugin_Continue;
		
	if (custom == 16) damage = 9001; 	
	if (custom == TF_CUSTOM_BOOTS_STOMP) damage *= 5;
	if (GetEventBool(event, "minicrit") && GetEventBool(event, "allseecrit")) SetEventBool(event, "allseecrit", false);
	if (custom == TF_CUSTOM_BACKSTAB)
		damage = RoundFloat(BossHealthMax[index]*(LastBossIndex()+1)*BossLivesMax[index]*(0.12-Stabbed[index]/90));
	if (custom == 16 || custom == TF_CUSTOM_BOOTS_STOMP) SetEventInt(event, "damageamount", damage);
	
	decl i;
	for(i = 1; i < BossLives[index]; i++)
	{
		//if (BossHealth[index] >= BossHealthMax[index]*i && BossHealth[index]-damage < BossHealthMax[index]*i)
		if (BossHealth[index]-damage < BossHealthMax[index]*i)
		{	
			decl String:s[PLATFORM_MAX_PATH];
			decl String:lives[MAXRANDOMS][3];
			decl count,j;
			for(new n = 1; n < MAXRANDOMS; n++)
			{
				Format(s,10,"ability%i",n);
				KvRewind(BossKV[Special[index]]);
				if (KvJumpToKey(BossKV[Special[index]],s))
				{
					if (KvGetNum(BossKV[Special[index]], "arg0",0)!= -1)
						continue;
					KvGetString(BossKV[Special[index]], "life",s,10); 	
					if (!s[0])
					{
						decl String:ability_name[64], String:plugin_name[64];
						KvGetString(BossKV[Special[index]], "plugin_name",plugin_name,64);
						KvGetString(BossKV[Special[index]], "name",ability_name,64);
						UseAbility(ability_name,plugin_name,index,-1);
					}
					else		
					{
						count = ExplodeString(s, " ", lives, MAXRANDOMS, 3);
						for(j = 0; j < count; j++)
							if (StringToInt(lives[j]) == BossLives[index])
							{
								decl String:ability_name[64], String:plugin_name[64];
								KvGetString(BossKV[Special[index]], "plugin_name",plugin_name,64);
								KvGetString(BossKV[Special[index]], "name",ability_name,64);
								UseAbility(ability_name,plugin_name,index,-1);
								break;
							}
					}
				}
			}
				
			BossLives[index]--;
			decl String:aname[64];
			KvRewind(BossKV[Special[index]]);
			KvGetString(BossKV[Special[index]], "name", aname, 64," = Failed name = ");
			Format(s,256,"%t","ff2_lives_left",aname,BossLives[index]); 	
			for (j = 1;  j <= MaxClients; j++)
				if (IsValidClient(j) && !(FF2flags[j] & FF2FLAG_HUDDISABLED))
				{
					SetGlobalTransTarget(j);
					PrintCenterText(j,s); 	
				}
			if (RandomSound("sound_nextlife",s,PLATFORM_MAX_PATH))
			{		
				EmitSoundToAll(s);
				EmitSoundToAll(s);
			}
			
			UpdateHealthBar();
		}
	}
	BossHealth[index]-= damage;
	BossCharge[index][0]+= damage*100.0/BossRageDamage[Special[index]];
	if (custom == 16) SetEventInt(event, "damageamount", 9001);
	Damage[attacker]+= damage;
	new healers[MAXPLAYERS];
	new healercount = 0;
	for(i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i) && (GetHealingTarget(i,true) == attacker))
		{
			healers[healercount] = i;
			healercount++;
		}
	}
	for(i = 0; i < healercount; i++)
	{
		if(IsValidClient(healers[i]) && IsPlayerAlive(healers[i]))
		{
			if (damage < 10 || TF2_IsPlayerInCondition(healers[i], TFCond_Ubercharged))
				Damage[healers[i]] += damage;
			else
				Damage[healers[i]]+= damage/(healercount+1); 	
		}
	}
	if (BossCharge[index][0] > 100)
		BossCharge[index][0] = 100.0;
	return Plugin_Continue;
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (!Enabled || !IsValidEdict(attacker))
		return Plugin_Continue;
	if ((attacker <= 0 || client == attacker) && IsBoss(client))
		return Plugin_Handled;
	if (TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
		return Plugin_Continue;
	if (FF2RoundState == 0 && IsBoss(client))
	{
		damage *= 0.0;
		return Plugin_Changed;
	}

	decl Float:Pos[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", Pos);
	if (IsBoss(attacker))
	{
		if (IsValidClient(client) && !IsBoss(client) && !TF2_IsPlayerInCondition(client, TFCond_Bonked) && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
		{
			if (TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
			{
				ScaleVector(damageForce, 9.0);
				damage *= 0.3;
				return Plugin_Changed;
			}
			new ent = -1;
			while ((ent = FindEntityByClassname2(ent, "tf_wearable_demoshield")) != -1)
			{
				if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(ent, Prop_Send, "m_bDisguiseWearable"))
				{
					AcceptEntityInput(ent, "Kill");
					EmitSoundToClient(client,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(client,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					TF2_AddCondition(client,TFCond_Bonked,0.1);
					return Plugin_Continue;
				}
			}
			switch (TF2_GetPlayerClass(client))
			{
				case TFClass_Spy: if (GetEntProp(client, Prop_Send, "m_bFeignDeathReady") || TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
				{
					if (damagetype & DMG_CRIT) damagetype &= ~DMG_CRIT;
					damage = 620.0;
					return Plugin_Changed;
				}
				case TFClass_Soldier: if (IsValidEdict((weapon = GetPlayerWeaponSlot(client, 1))) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 226 && !(FF2flags[client]&FF2FLAG_ISBUFFED))
				{
					SetEntPropFloat(client, Prop_Send, "m_flRageMeter",100.0);
					FF2flags[client] |= FF2FLAG_ISBUFFED;
				}
			}
			new buffweapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
			new buffindex = (IsValidEntity(buffweapon) && buffweapon > MaxClients ? GetEntProp(buffweapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if (buffindex == 226)
				CreateTimer(0.25, Timer_CheckBuffRage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			if (damage <= 160.0)
			{
				damage*= 3;
				return Plugin_Changed;
			}
		}
	}
	else
	{
		new index = GetBossIndex(client);
		if (index!= -1)
		{
			if (attacker <= MaxClients)
			{
				if (!IsValidEntity(weapon) && (damagetype & DMG_CRUSH) == DMG_CRUSH && damage == 1000.0)	//THIS IS A TELEFRAG
				{
					damage = (BossHealth[index] > 9001 ? 9001.0 : float(GetEntProp(Boss[index], Prop_Send, "m_iHealth"))+90.0);
					new teleowner = FindTeleOwner(attacker);
					if (IsValidClient(teleowner) && teleowner != attacker)
					{
						Damage[teleowner]+= 9001*3/5;
						if (!(FF2flags[teleowner] & FF2FLAG_HUDDISABLED))
							PrintCenterText(teleowner, "TELEFRAG ASSIST! Nice job setting up!");
					}
					if (!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
						PrintCenterText(attacker,"TELEFRAG! You are a pro.");
					if (!(FF2flags[client] & FF2FLAG_HUDDISABLED))
						PrintCenterText(client,"TELEFRAG! Be careful around quantum tunneling devices!");
					return Plugin_Changed;
				}
				new wepindex = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
				switch (wepindex)
				{
					case 593:	//Third Degree
					{
						new healers[MAXPLAYERS];
						new healercount = 0;
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsValidClient(i) && IsPlayerAlive(i) && (GetHealingTarget(i, true) == attacker))
							{
								healers[healercount] = i;
								healercount++;
							}
						}
						for (new i = 0; i < healercount; i++)
						{
							if (IsValidClient(healers[i]) && IsPlayerAlive(healers[i]))
							{
								new medigun = GetPlayerWeaponSlot(healers[i], TFWeaponSlot_Secondary);
								if (IsValidEntity(medigun))
								{
									new String:s[64];
									GetEdictClassname(medigun, s, sizeof(s));
									if (strcmp(s, "tf_weapon_medigun", false) == 0)
									{
										new Float:uber = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") + (0.1 / healercount);
										new Float:max = 1.0;
										if (GetEntProp(medigun, Prop_Send, "m_bChargeRelease")) max = 1.5;
										if (uber > max) uber = max;
										SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
									}
								}
							}
						}
					}
					case 14,201,664:
					{
						new Float:chargelevel = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
						new Float:time = 2.0;
						time += 4*(chargelevel/100);
						SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
						GlowTimer[index]+= RoundToCeil(time);
						if (GlowTimer[index] > 30.0) GlowTimer[index] = 30.0;
					}
					case 355:
					{
						BossCharge[index][0] -= 5.0;
						if (BossCharge[index][0] < 0)
							BossCharge[index][0] = 0.0;
					}
					case 132, 266, 482: IncrementHeadCount(attacker);
					case 214:	//applejack...no wait...powerjack!
					{
						new health = GetClientHealth(attacker);
						new max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						new newhealth = health+50;
						if (health < max+25)
						{
							if (newhealth > max+25) newhealth = max+25;
							SetEntProp(attacker, Prop_Data, "m_iHealth", newhealth);
							SetEntProp(attacker, Prop_Send, "m_iHealth", newhealth);
						}
						if (TF2_IsPlayerInCondition(attacker, TFCond_OnFire)) TF2_RemoveCondition(attacker, TFCond_OnFire);
					}
					case 317: SpawnSmallHealthPackAt(client, GetClientTeam(attacker));
					case 357:
					{
						SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
						if (GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy") < 1)
							SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
						new health = GetClientHealth(attacker);
						new max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						new newhealth = health+35;
						if (health < max+25)
						{
							if (newhealth > max+25) newhealth = max+25;
							SetEntProp(attacker, Prop_Data, "m_iHealth", newhealth);
							SetEntProp(attacker, Prop_Send, "m_iHealth", newhealth);
						}
						if (TF2_IsPlayerInCondition(attacker, TFCond_OnFire)) TF2_RemoveCondition(attacker, TFCond_OnFire);
					}
					case 528:
					{
						if (circuitStun > 0.0)
						{
							TF2_StunPlayer(client, circuitStun, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
							EmitSoundToAll("weapons/barret_arm_zap.wav", client);
							EmitSoundToClient(client, "weapons/barret_arm_zap.wav");
						}
					}
					case 656:
					{
						CreateTimer(0.1, Timer_StopTickle, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						if (TF2_IsPlayerInCondition(attacker, TFCond_Dazed)) TF2_RemoveCondition(attacker, TFCond_Dazed);
					}
				}
				new activeweapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
				if (activeweapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary))
				{
					new windex = (IsValidEntity(activeweapon) && activeweapon > MaxClients ? GetEntProp(activeweapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
					if (windex == 14 || windex == 201)
					{
						new Float:chargelevel = (IsValidEntity(activeweapon) && activeweapon > MaxClients ? GetEntPropFloat(activeweapon, Prop_Send, "m_flChargedDamage") : 0.0);
						new Float:time = 2.0;
						time += 4*(chargelevel/100);
						SetEntProp(Boss[index], Prop_Send, "m_bGlowEnabled", 1);
						GlowTimer[index]+= RoundToCeil(time);
						if (GlowTimer[index] > 30.0) GlowTimer[index] = 30.0;
					}
				}
				
				new bool:bIsBackstab = false;
				if (GetFeatureStatus(FeatureType_Capability, "SDKHook_DmgCustomInOTD") == FeatureStatus_Available) // new way to check backstabs
				{
					if (damagecustom == TF_CUSTOM_BACKSTAB)
					{
						bIsBackstab = true;
					}
				}
				else if (activeweapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage > 1000.0)	//lousy way of checking backstabs
				{
					decl String:wepclassname[32];
					if (GetEdictClassname(activeweapon, wepclassname, sizeof(wepclassname)) && strcmp(wepclassname, "tf_weapon_knife", false) == 0)	//more robust knife check
					{
						bIsBackstab = true;
					}
				}

				if (bIsBackstab)
				{
					new Float:changedamage = BossHealthMax[index]*(LastBossIndex()+1)*BossLivesMax[index]*(0.12-Stabbed[index]/90);
					Damage[attacker]+= RoundFloat(changedamage);
					if (BossHealth[index] > RoundFloat(changedamage)) damage = 0.0;
					else damage = changedamage;
					BossHealth[index]-= RoundFloat(changedamage);
					BossCharge[index][0]+= changedamage*100/BossRageDamage[Special[index]];
					if (BossCharge[index][0] > 100.0)
						BossCharge[index][0] = 100.0;
					EmitSoundToClient(client,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(client,"player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker,"player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
					new Float:NextAttackTime=GetGameTime()+2.0;
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", NextAttackTime);
					if (!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
						PrintCenterText(attacker,"You backstabbed him!");
					if (!(FF2flags[client] & FF2FLAG_HUDDISABLED))
						PrintCenterText(client,"You were just backstabbed!");
					new Handle:stabevent = CreateEvent("player_hurt", true);
					SetEventInt(stabevent, "userid", GetClientUserId(client));
					SetEventInt(stabevent, "health", BossHealth[index]);
					SetEventInt(stabevent, "attacker", GetClientUserId(attacker));
					SetEventInt(stabevent, "damageamount", RoundFloat(changedamage));
					SetEventInt(stabevent, "custom", TF_CUSTOM_BACKSTAB);
					SetEventBool(stabevent, "crit", true);
					SetEventBool(stabevent, "minicrit", false);
					SetEventBool(stabevent, "allseecrit", true);
					decl String:s[PLATFORM_MAX_PATH];
					if (RandomSound("sound_stabbed",s,PLATFORM_MAX_PATH,index))
					{
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE,s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss[0], _, NULL_VECTOR, false, 0.0);
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE,s,_, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss[0], _, NULL_VECTOR, false, 0.0);
					}
					SetEventInt(stabevent, "weaponid", TF_WEAPON_KNIFE);
					FireEvent(stabevent);
					if (wepindex == 225 || wepindex == 574)
						CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker));
					new invis_watch=GetPlayerWeaponSlot(attacker, TFWeaponSlot_PDA);
					new iw_index = (IsValidEntity(invis_watch) && invis_watch > MaxClients ? GetEntProp(invis_watch, Prop_Send, "m_iItemDefinitionIndex") : -1);
					if (iw_index==59)	//Dead Ringer						
						SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", NextAttackTime);
					else if (wepindex == 356)
					{
						new health = GetClientHealth(attacker) + 100;
						if (health > 270) health = 270;
						SetEntProp(attacker, Prop_Data, "m_iHealth", health);
						SetEntProp(attacker, Prop_Send, "m_iHealth", health);
					}
					if (Stabbed[index] < 5)
						Stabbed[index]++;
					new healers[MAXPLAYERS];
					new healercount = 0;
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsValidClient(i) && IsPlayerAlive(i) && (GetHealingTarget(i,true) == attacker))
						{
							healers[healercount] = i;
							healercount++;
						}
					}
					for(new i = 0; i < healercount; i++)
					{
						if(IsValidClient(healers[i]) && IsPlayerAlive(healers[i]))
						{
							if (TF2_IsPlayerInCondition(healers[i], TFCond_Ubercharged))
								Damage[healers[i]]+= RoundFloat(changedamage);
							else
								Damage[healers[i]]+= RoundFloat(changedamage/(healercount+1));
						}
					}
					return Plugin_Changed;
				}
			}
			else
			{
				decl String:s[64];
				if (GetEdictClassname(attacker, s, sizeof(s)) && strcmp(s, "trigger_hurt", false) == 0)
				{
					new Action:act = Plugin_Continue;
					Call_StartForward(OnTriggerHurt);
					Call_PushCell(index);
					Call_PushCell(attacker);
					new Float:damage2 = damage;
					Call_PushFloatRef(damage2);
					Call_Finish(act);
					if (act!= Plugin_Stop && act!= Plugin_Handled)
					{
						if (act == Plugin_Changed)
							damage = damage2;
						if (damage > 1500.0)
							damage = 1500.0;
						if (strcmp(currentmap, "arena_arakawa_b3", false) == 0 && damage > 1000.0) damage = 490.0;
						BossHealth[index]-= RoundFloat(damage);
						BossCharge[index][0]+= damage*100/BossRageDamage[Special[index]];
						if (BossHealth[index] <= 0) damage *= 5;
						if (BossCharge[index][0] > 100)
							BossCharge[index][0] = 100.0;
						return Plugin_Changed;
					}
					else
					{
						return act;
					}
				}
			}
		}
		else
		{
			if (IsValidClient(client, false) && TF2_GetPlayerClass(client) == TFClass_Soldier)
			{
				if (damagetype & DMG_FALL)
				{
					new secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if (secondary <= 0 || !IsValidEntity(secondary))
					{
						damage  /= 10.0;
						return Plugin_Changed;
					}
				}/*
				else if (IsValidEdict((weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 226)
				{					
					new Float:charge = GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
					if (charge > 20)
						SetEntPropFloat(client, Prop_Send, "m_flRageMeter",charge-20.0);
					else
						SetEntPropFloat(client, Prop_Send, "m_flRageMeter",0.0);
				}*/
			}
		}
	}
	return Plugin_Continue;
}
public Action:Timer_CheckBuffRage(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
	}
}

stock SpawnSmallHealthPackAt(client, ownerteam = 0)
{
	if (!IsValidClient(client, false) || !IsPlayerAlive(client)) return;
	new healthpack = CreateEntityByName("item_healthkit_small");
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += 20.0;
	if (IsValidEntity(healthpack))
	{
		DispatchSpawn(healthpack);
		SetEntProp(healthpack, Prop_Send, "m_iTeamNum", ownerteam, 4);
		SetEntityMoveType(healthpack, MOVETYPE_FLYGRAVITY);
		new Float:vel[3];
		vel[0] = float(GetRandomInt(0, 10)), vel[1] = float(GetRandomInt(0, 10)), vel[2] = 50.0; 	//I did this because setting it on the creation of the vel variable was creating a compiler error for me.
		TeleportEntity(healthpack, pos, NULL_VECTOR, vel);
		CreateTimer(17.0, Timer_RemoveCandycaneHealthPack, EntIndexToEntRef(healthpack), TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:Timer_RemoveCandycaneHealthPack(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if (entity > MaxClients && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}
public Action:Timer_StopTickle(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client)) return;
	if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner"))) TF2_RemoveCondition(client, TFCond_Taunting);
}

stock IncrementHeadCount(client)
{
	if (!TF2_IsPlayerInCondition(client, TFCond_DemoBuff)) TF2_AddCondition(client, TFCond_DemoBuff, -1.0);
	new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
	SetEntProp(client, Prop_Send, "m_iDecapitations", decapitations+1);
	new health = GetClientHealth(client);
	SetEntProp(client, Prop_Data, "m_iHealth", health+15);
	SetEntProp(client, Prop_Send, "m_iHealth", health+15);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}
stock SwitchToOtherWeapon(client)
{
	new ammo = GetAmmo(client, 0);
	new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	new clip = (IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iClip1") : -1);
	if (!(ammo == 0 && clip <= 0)) SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	else SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary));
}
stock FindTeleOwner(client)
{
	if (!IsValidClient(client)) return -1;
	if (!IsPlayerAlive(client)) return -1;
	new tele = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	decl String:classname[32];
	if (IsValidEntity(tele) && GetEdictClassname(tele, classname, sizeof(classname)) && strcmp(classname, "obj_teleporter", false) == 0)
	{
		new owner = GetEntPropEnt(tele, Prop_Send, "m_hBuilder");
		if (IsValidClient(owner, false)) return owner;
	}
	return -1;
}
stock TF2_IsPlayerCritBuffed(client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond:34) || TF2_IsPlayerInCondition(client, TFCond:35) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill));
}

public Action:Timer_DisguiseBackstab(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client, false))
		RandomlyDisguise(client);
	return Plugin_Continue;
}

stock RandomlyDisguise(client)	//mechamechamechamechamecha
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_AddCondition(client, TFCond_Disguised, 99999.0);
		new disguisetarget = -1;
		new team = GetClientTeam(client);

		new Handle:hArray = CreateArray();
		for (new clientcheck = 0;  clientcheck <= MaxClients;  clientcheck++) {
			if (IsValidClient(clientcheck) && GetClientTeam(clientcheck) == team && clientcheck != client)
			{
				new TFClassType:class = TF2_GetPlayerClass(clientcheck);
				if (class == TFClass_Scout || class == TFClass_Medic || class == TFClass_Engineer || class == TFClass_Sniper || class == TFClass_Pyro)
					PushArrayCell(hArray, clientcheck);
			}
		}
		if (GetArraySize(hArray) <= 0) disguisetarget = client;
		else disguisetarget = GetArrayCell(hArray, GetRandomInt(0, GetArraySize(hArray)-1));
		if (!IsValidClient(disguisetarget)) disguisetarget = client;
		new disguisehealth = GetRandomInt(75,125);
		new class = GetRandomInt(0, 4);
		new TFClassType:classarray[] = { TFClass_Scout, TFClass_Pyro, TFClass_Medic, TFClass_Engineer, TFClass_Sniper };
//		new disguiseclass = classarray[class];
		new disguiseclass = _:(disguisetarget != client ? (TF2_GetPlayerClass(disguisetarget)) : classarray[class]);
//		new weapon = GetEntPropEnt(disguisetarget, Prop_Send, "m_hActiveWeapon");
		CloseHandle(hArray);

		SetEntProp(client, Prop_Send, "m_nDisguiseClass", disguiseclass);
		SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
		SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", disguisetarget);
		SetEntProp(client, Prop_Send, "m_iDisguiseHealth", disguisehealth);
		TF2_DisguisePlayer(client, TFTeam:team, TFClassType:disguiseclass);
		FakeClientCommandEx(client, "lastdisguise");
		TF2_AddCondition(client, TFCond_Disguised, 99999.0);
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!Enabled) return Plugin_Continue;
	if (FF2RoundState != 1) return Plugin_Continue;
	if (IsBoss(client) && !BossCrits)
	{
		result = false;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock FindBosses(bool:array[])
{
	new tBoss; 	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (SpecForceBoss)
		{
			if (IsValidEdict(i) && IsClientConnected(i) &&
				GetClientQueuePoints(i) >= GetClientQueuePoints(tBoss) && !array[i])
					tBoss = i;
		}
		else
		{
			if (IsValidEdict(i) && IsClientConnected(i) && GetClientTeam(i) > _:TFTeam_Spectator &&
				GetClientQueuePoints(i) >= GetClientQueuePoints(tBoss) && !array[i])
					tBoss = i;
		}
	}
	return tBoss;
}

stock LastBossIndex()
{
	for(new i = 1; i <= MaxClients; i++)
		if (!Boss[i])
			return i-1;
	return 0;
}

stock GetBossIndex(client)
{
	for(new i = 0; i <= MaxClients; i++)
		if (Boss[i] == client)
			return i; 	
	return -1;
}

stock CalcBossHealthMax(index)
{
	decl String:formula[128];
	new String:s[128];
	new String:s2[2];
	
	new brackets;
	new Float:summ[32];
	new _operator[32];
		
	KvRewind(BossKV[Special[index]]);
	KvGetString(BossKV[Special[index]], "health_formula",formula, 128,"((760+n)*n)^1.04");
	ReplaceString(formula,128," ","");
	new len = strlen(formula);
	for(new i = 0; i <= len; i++)
	{			
		strcopy(s2,2,formula[i]);
		if ((s2[0] >= '0' && s2[0] <= '9') || s2[0] == '.')
		{
			StrCat(s,128,s2);
			continue;
		}
		if (s2[0] == '(')
		{
			brackets++;
			summ[brackets] = 0.0;
			_operator[brackets] = 0;
		}
		else 
		{
			if (s[0]!= 0)
			{
				switch (_operator[brackets])
				{
					case 0,1:
						summ[brackets]+= StringToFloat(s);
					case 2:
						summ[brackets]-= StringToFloat(s);
					case 3:
						summ[brackets]*= StringToFloat(s);
					case 4:
					{
						new Float:see = StringToFloat(s);
						if (FloatAbs(see-0.0) < 0.01) {brackets = 1; break; }
						summ[brackets] /= see;
					}
					case 5:
						summ[brackets] = Pow(summ[brackets],StringToFloat(s));
				}
				_operator[brackets] = 0;
			}
			if (s2[0] == ')')
			{
				brackets--;
				switch (_operator[brackets])
				{
					case 2:
					{
						summ[brackets]-= summ[brackets+1];
					}
					case 3:
						summ[brackets]*= summ[brackets+1];
					case 4:
					{
						if (FloatAbs(summ[brackets+1]-0.0) < 0.01) {brackets = 1; break; }
						summ[brackets] /= summ[brackets+1];
					}
					case 5:
						summ[brackets] = Pow(summ[brackets],summ[brackets+1]);
					default:
						summ[brackets]+= summ[brackets+1];
				}
				_operator[brackets] = 0;
			}
		}
		strcopy(s,128,"");
		switch (s2[0])
		{
			case '+':
				_operator[brackets] = 1;
			case '-':
				_operator[brackets] = 2;
			case '*':
				_operator[brackets] = 3;
			case '/','\\':
				_operator[brackets] = 4;
			case '^':
				_operator[brackets] = 5;
			case 'n','x':
			{
				switch (_operator[brackets])
				{
					case 1:
						summ[brackets]+= playing;
					case 2:
						summ[brackets]-= playing;
					case 4:					
						summ[brackets] /= playing;
					case 5:
						summ[brackets] = Pow(summ[brackets],Float:playing);
					default:
						summ[brackets]*= playing;
				}
				_operator[brackets] = 0;
			}
		}
	}
	decl health;
	if (brackets)
	{
		LogError("[FF2] Wrong Boss' health formula! Using default!");
		health = RoundFloat(Pow(((760.0+playing)*(playing-1)),1.04));
	}
	else health = RoundFloat(summ[0]);
	if (bMedieval) health = RoundFloat(health/3.6);
	return health;
}

stock bool:HasAbility(index,const String:plugin_name[],const String:ability_name[])
{
	if (!Enabled)
		return false;
	if (index == -1 || Special[index] == -1 || !BossKV[Special[index]])
		return false;
	KvRewind(BossKV[Special[index]]);
	if (!BossKV[Special[index]])
	{
		LogError("failed KV: %i %i",index,Special[index]);
		return false;
	}
	decl String:s[12];
	for(new i = 1; i < MAXRANDOMS; i++)
	{
		Format(s,12,"ability%i",i);
		if (KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if (!strcmp(ability_name,ability_name2))
			{
				decl String:plugin_name2[64];
				KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
				if (!plugin_name[0] || !plugin_name2[0] || !strcmp(plugin_name,plugin_name2))
					return true;
			}
			KvGoBack(BossKV[Special[index]]);
		}
	}
	return false;
}

stock GetAbilityArgument(index,const String:plugin_name[],const String:ability_name[],arg,defvalue = 0)
{
	if (index == -1 || Special[index] == -1 || !BossKV[Special[index]])
		return 0;
	KvRewind(BossKV[Special[index]]);
	decl String:s[10];
	for(new i = 1; i < MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if (KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if (strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			decl String:plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if (plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s,10,"arg%i",arg);
			return KvGetNum(BossKV[Special[index]], s,defvalue);
		}
	}
	return 0;
}

stock Float:GetAbilityArgumentFloat(index,const String:plugin_name[],const String:ability_name[],arg,Float:defvalue = 0.0)
{	
	if (index == -1 || Special[index] == -1 || !BossKV[Special[index]])
		return 0.0;
	KvRewind(BossKV[Special[index]]);
	decl String:s[10];
	for(new i = 1; i < MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if (KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if (strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			decl String:plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if (plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s,10,"arg%i",arg);
			new Float:see = KvGetFloat(BossKV[Special[index]], s,defvalue);
			return see;
		}
	}
	return 0.0;
}

stock GetAbilityArgumentString(index,const String:plugin_name[],const String:ability_name[],arg,String:buffer[],buflen,const String:defvalue[] = "")
{	
	if (index == -1 || Special[index] == -1 || !BossKV[Special[index]])
	{
		strcopy(buffer,buflen,"");
		return;
	}
	KvRewind(BossKV[Special[index]]);
	decl String:s[10];
	for(new i = 1; i < MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if (KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if (strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			decl String:plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if (plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s,10,"arg%i",arg);
			KvGetString(BossKV[Special[index]], s,buffer,buflen,defvalue);
		}
	}
}

stock bool:RandomSound(const String: keyvalue[], String: str[],length,index = 0)
{
	strcopy(str,1,"");
	if (index<0 || Special[index]<0 || !BossKV[Special[index]])
		return false;
	KvRewind(BossKV[Special[index]]);
	if (!KvJumpToKey(BossKV[Special[index]],keyvalue))
	{
		KvRewind(BossKV[Special[index]]);
		return false;
	}
	decl String:s[4];
	new i = 1;
	for(;;)
	{
		IntToString(i,s,4);
		KvGetString(BossKV[Special[index]], s, str, length);
		if (!str[0])
			break;
		i++;
	}
	if (i == 1)
		return false;
	IntToString(GetRandomInt(1,i-1),s,4);
	KvGetString(BossKV[Special[index]], s, str, length);
	return true;
}

stock bool:RandomSoundAbility(const String: keyvalue[], String: str[],length,index = 0,slot = 0)
{
	if (index == -1 || Special[index] == -1 || !BossKV[Special[index]])
		return false;
	KvRewind(BossKV[Special[index]]);
	if (!KvJumpToKey(BossKV[Special[index]],keyvalue))
		return false;
	decl String:s[10];
	new i = 1,j = 1,see[MAXRANDOMS];
	for(;;)
	{
		IntToString(i,s,4);
		KvGetString(BossKV[Special[index]], s, str, length);
		if (!str[0])
			break;
		Format(s,10,"slot%i",i);
		if (KvGetNum(BossKV[Special[index]],s,0) == slot)
		{
			see[j] = i;
			j++;
		}
		i++;
	}
	if (j == 1)
		return false;
	IntToString(see[GetRandomInt(1,j-1)],s,4);
	KvGetString(BossKV[Special[index]], s, str, length);
	return true;
}

ForceTeamWin(team)
{
	new ent = FindEntityByClassname2(-1, "team_control_point_master");
	if (ent == -1)
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(ent, "SetWinner");
}

public bool:PickSpecial(index,index2)
{
	if (index == index2)
	{
		Special[index] = Incoming[index];
		Incoming[index] = -1;
		if (Special[index] != -1)
			return true;
		new chances[MAXSPECIALS];
		new chances_index;
		new String:s_chances[MAXSPECIALS*2][8];
		if (ChancesString[0])
		{
			ExplodeString(ChancesString, " ; ", s_chances,MAXSPECIALS*2,8);
			chances[0]=StringToInt(s_chances[1]);
			for(chances_index = 3; s_chances[chances_index][0]; chances_index+=2)
				chances[chances_index/2]=StringToInt(s_chances[chances_index])+chances[chances_index/2-1];
			chances_index-=2;
		}
		new pingas;
		do
		{
			if (ChancesString[0])
			{
				new random_num = GetRandomInt(0,chances[chances_index/2]);
				decl see;
				for(see = 0; random_num > chances[see]; see++) {}
				decl String:name1[64];
				Special[index] = StringToInt(s_chances[see*2])-1;
				KvRewind(BossKV[Special[index]]);
				KvGetString(BossKV[Special[index]], "name", name1, 64," = Failed name = ");
			}
			else
			{
				Special[index] = GetRandomInt(0,Specials-1);
				KvRewind(BossKV[Special[index]]);
			}
			pingas++;
		}
		while (pingas < 100 && KvGetNum(BossKV[Special[index]], "blocked",0));
		if (pingas == 100)
			Special[index] = 0;
	}
	else
	{	
		decl String:s2[64];
		decl String:s1[64];
		KvRewind(BossKV[Special[index2]]);
		KvGetString(BossKV[Special[index2]], "companion", s2, 64," = Failed name2 = ");
		decl i;
		for(i = 0; i < Specials; i++)
		{
			KvRewind(BossKV[i]);
			KvGetString(BossKV[i], "name", s1, 64," = Failed name1 = ");
			if (!strcmp(s1,s2,false))
			{
				Special[index] = i;
				break;
			}
			KvGetString(BossKV[i], "filename", s1, 64," = Failed name1 = ");
			if (!strcmp(s1,s2,false))
			{
				Special[index] = i;
				break;
			}
		}
		if (i == Specials)
			return false;
	}
	new Action:act = Plugin_Continue;
	Call_StartForward(OnSpecialSelected);
	Call_PushCell(index);
	new SpecialNum=Special[index];
	Call_PushCellRef(SpecialNum);
	decl String:s[64];
	KvRewind(BossKV[Special[index]]);
	KvGetString(BossKV[Special[index]], "name", s, 64);
	Call_PushStringEx(s, 64, 0, SM_PARAM_COPYBACK);
	Call_Finish(act);
	if (act == Plugin_Changed)
	{
		if (s[0])
		{
			decl String:s2[64];
			for(new j = 0; BossKV[j] && j < MAXSPECIALS; j++)
			{
				KvRewind(BossKV[j]);
				KvGetString(BossKV[j], "name", s2, 64);
				if (!strcmp(s,s2))
				{
					Special[index] = j; 	
					return true;
				}
			}
		}		
		Special[index]=SpecialNum;
		return true;
	}
	return true;
}

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0;  i < count;  i+= 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon == INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

public HintPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	return;
}

public QueuePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 == 10)
		TurnToZeroPanel(param1,param1);
	return false;  
}


public Action:QueuePanelCmd(client, Args)
{
	if (!Enabled2)
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	SetGlobalTransTarget(client);
	decl String:s[512];
	Format(s,512,"%t","thequeue"); 	
	new i,tBoss,bool:added[MAXPLAYERS+1];
	decl j;
	SetPanelTitle(panel, s); 	
	for(j = 0; j <= MaxClients; j++)
		if ((tBoss = Boss[i]) && IsValidEdict(tBoss) && IsClientInGame(tBoss))
		{
			added[tBoss] = true;
			Format(s,64,"%N - %i",tBoss,GetClientQueuePoints(tBoss));
			DrawPanelItem(panel,s);
			i++;
		}
	DrawPanelText(panel,"---");
	new pingas;
	do
	{
		tBoss = FindBosses(added); 	
		if (tBoss && IsValidEdict(tBoss) && IsClientInGame(tBoss))
		{		
			if (client == tBoss)
			{
				Format(s,64,"%N - %i",tBoss,GetClientQueuePoints(tBoss));
				DrawPanelText(panel,s);
				i--;
			}
			else
			{
				Format(s,64,"%N - %i",tBoss,GetClientQueuePoints(tBoss));
				DrawPanelItem(panel,s);
			}
			added[tBoss] = true;
			i++;
		}
		pingas++;
	}
	while (i < 9 && pingas < 100);
	for(; i < 9; i++)
		DrawPanelItem(panel,"");
	Format(s,64,"%t (%t)","your_points",GetClientQueuePoints(client),"to0");
	DrawPanelItem(panel,s);
	SendPanelToClient(panel, client, QueuePanelH, 9001);
	CloseHandle(panel);
	return Plugin_Handled;
}

public Action:ResetQueuePointsCmd(client, args)
{
	if (!Enabled2)
		return Plugin_Continue;
	if (client && !args)			//default players
	{
		TurnToZeroPanel(client,client);
		return Plugin_Handled;
	}
	if (!client)		//No confirmation for console
	{
		TurnToZeroPanelH(INVALID_HANDLE, MenuAction_Select, client, 1);
		return Plugin_Handled;
	}
	new AdminId:admin = GetUserAdmin(client);	//default players again
	if((admin == INVALID_ADMIN_ID) || !GetAdminFlag(admin, Admin_Cheats))
	{
		TurnToZeroPanel(client,client);
		return Plugin_Handled;
	}	
	//admins
	if (args != 1)
	{
		ReplyToCommand(client, "[FF2] Usage: ff2_resetqueuepoints < target >");
		return Plugin_Handled;
	}

	decl String:targetname[MAX_TARGET_LENGTH];
	GetCmdArg(1, targetname, MAX_TARGET_LENGTH);
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[1], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			targetname,
			client,
			target_list,
			1,
			0,
			target_name,
			MAX_TARGET_LENGTH,
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	TurnToZeroPanel(client,target_list[0]);
	return Plugin_Handled;
}

public TurnToZeroPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 == 1)
	{
		if (shortname[param1] == param1)
			CPrintToChat(param1,"{olive}[FF2]{default} %t","to0_done");
		else
		{
			CPrintToChat(param1,"{olive}[FF2]{default} %t","to0_done_admin",shortname[param1]);
			CPrintToChat(shortname[param1],"{olive}[FF2]{default} %t","to0_done_by_admin",param1);
		}
		SetClientQueuePoints(shortname[param1],0);
	}
}

public Action:TurnToZeroPanel(caller,client)
{
	if (!Enabled2)
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	decl String:s[512];
	SetGlobalTransTarget(caller);
	if (caller == client)
		Format(s,512,"%t","to0_title");
	else
		Format(s,512,"%t","to0_title_admin",client);
	PrintToChat(caller,s);
	SetPanelTitle(panel,s);
	Format(s,512,"%t","Yes");
	DrawPanelItem(panel,s);
	Format(s,512,"%t","No");
	DrawPanelItem(panel,s);
	shortname[caller]=client;
	SendPanelToClient(panel, caller, TurnToZeroPanelH, 9001);
	CloseHandle(panel);
	return Plugin_Handled;
}

bool:GetClientClassinfoCookie(client)
{
	if (!IsValidClient(client)) return false;
	if (IsFakeClient(client)) return false;
	if (!AreClientCookiesCached(client)) return true;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s,24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	return StringToInt(ff2cookies_values[3])==1;
}

GetClientQueuePoints(client)
{
	if (!IsValidClient(client)) return 0;
	if (IsFakeClient(client))
		return botqueuepoints;
	if (!AreClientCookiesCached(client)) return 0;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s,24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	return StringToInt(ff2cookies_values[0]);
}

SetClientQueuePoints(client, points)
{
	if (!IsValidClient(client)) return;
	if (IsFakeClient(client)) return;
	if (!AreClientCookiesCached(client)) return;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s,24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	Format(s,24,"%i %s %s %s %s %s %s",points,ff2cookies_values[1],ff2cookies_values[2],ff2cookies_values[3],ff2cookies_values[4],ff2cookies_values[5],ff2cookies_values[6],ff2cookies_values[7]);
	SetClientCookie(client, FF2Cookies, s);
}

stock IsBoss(client)
{
	if (client <= 0)
		return 0;
	for(new i = 0; i <= MaxClients; i++)
		if (Boss[i] == client)
			return 1;
	return 0;
}

DoOverlay(client,const String:overlay[])
{	
	new iFlags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", iFlags & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", iFlags);
}
public FF2PanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
				Command_GetHP(param1);
			case 2:
				HelpPanel2(param1);
			case 3:
				NewPanel(param1, maxversion);
			case 4:
				QueuePanelCmd(param1,0);
			case 5:
				MusicTogglePanel(param1);
			case 6:
				VoiceTogglePanel(param1);
			case 7:
				HelpPanel3(param1);
			default: return;
		} 
	}
}
  
public Action:FF2Panel(client, args)
{
	if (!Enabled2 || !IsValidClient(client, false))
		return Plugin_Continue;
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 0.8);
	new Handle:panel = CreatePanel();
	decl String:s[256];
	SetGlobalTransTarget(client);
	Format(s,256,"%t","menu_1");
	SetPanelTitle(panel, s);
	Format(s,256,"%t","menu_3");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_7");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_4");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_5");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_8");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_9");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_9a");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_6");
	DrawPanelItem(panel, s);
	SendPanelToClient(panel, client, FF2PanelH, 9001);
	CloseHandle(panel);
	return Plugin_Handled;
}

public NewPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				if (curHelp[param1] <= 0)
					NewPanel(param1, 0);
				else
					NewPanel(param1, --curHelp[param1]);
			}
			case 2:
			{
				if (curHelp[param1] >= maxversion)
					NewPanel(param1, maxversion);
				else
					NewPanel(param1, ++curHelp[param1]);
			}
			default: return;
		}
	}
}
public Action:NewPanelCmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	NewPanel(client, maxversion);
	return Plugin_Handled;
}
public Action:NewPanel(client, versionindex)
{
	if (!Enabled2)
		return Plugin_Continue;
	curHelp[client] = versionindex;
	new Handle:panel = CreatePanel();
	decl String:s[90];
	SetGlobalTransTarget(client);
	Format(s,90," = %t: = ","whatsnew", ff2versiontitles[versionindex],ff2versiondates[versionindex]);
	SetPanelTitle(panel, s);
	FindVersionData(panel, versionindex);
	if (versionindex > 0)
		Format(s,90, "%t", "older");
	else
		Format(s,90, "%t", "noolder");
	DrawPanelItem(panel, s);  
	if (versionindex < maxversion)
		Format(s,90, "%t", "newer");
	else
		Format(s,90, "%t", "nonewer");
	DrawPanelItem(panel, s);  
	Format(s,512,"%t","menu_6");
	DrawPanelItem(panel,s);    
	SendPanelToClient(panel, client, NewPanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}

stock FindVersionData(Handle:panel, versionindex)
{
	switch (versionindex)
	{
		case 14: // 1.06h
		{
		    DrawPanelText(panel, "1) [Players] Remove MvM powerup_bottle on Bosses. (RavensBro)");
		}
		
		case 13: // 1.06g
		{
		    DrawPanelText(panel, "1) [Players] Fixed vote for charset. (RavensBro)");
		}		
		
		case 12: // 1.06f
		{
			DrawPanelText(panel, "1) [Players] Changelog now divided into [Players] and [Dev] sections. (Otokiru)");
			DrawPanelText(panel, "2) [Players] Don't bother reading [Dev] changelogs because you'll have no idea what it's stated. (Otokiru)");
			DrawPanelText(panel, "3) [Players] Fixed civilian glitch. (Otokiru)");
			DrawPanelText(panel, "4) [Players] Fixed hale HP bar. (Valve) lol?");
			DrawPanelText(panel, "5) [Dev] Fixed \"GetEntProp\" reported: Entity XXX (XXX) is invalid on checkFirstHale(). (Otokiru)");
		}
		
		case 11: // 1.06e
		{

			DrawPanelText(panel, "1) [Players] Remove MvM water-bottle on hales. (Otokiru)");
			DrawPanelText(panel, "2) [Dev] Fixed \"GetEntProp\" reported: Property \"m_iClass\" not found (entity 0/worldspawn) error on checkFirstHale(). (Otokiru)");
			DrawPanelText(panel, "3) [Dev] Change how FF2 check for player weapons. Now also checks when spawned in the middle of the round. (Otokiru)");
			DrawPanelText(panel, "4) [Dev] Changed some FF2 warning messages color such as \"First-Hale Checker\" and \"Change class exploit\". (Otokiru)");
		}
		
		case 10: // 1.06d
		{
			DrawPanelText(panel, "1) Fix first boss having missing health or abilities. (Otokiru)");
			DrawPanelText(panel, "2) Health bar now goes away if the boss wins the round. (Powerlord)");
			DrawPanelText(panel, "3) Health bar cedes control to Monoculus if he is summoned. (Powerlord)");
			DrawPanelText(panel, "4) Health bar instantly updates if enabled or disabled via cvar mid-game. (Powerlord)");
		}
		
		
		case 9: //1.06c
		{
			DrawPanelText(panel, "1) Remove weapons if a player tries to switch classes when they become boss to prevent an exploit. (Otokiru)");
			DrawPanelText(panel, "2) Reset hale's queue points to prevent the 'retry' exploit. (Otokiru)");
			DrawPanelText(panel, "3) Better detection of backstabs. (Powerlord)");
			DrawPanelText(panel, "4) Boss now has optional life meter on screen. (Powerlord)");
		}
		case 8: //1.06
		{
			DrawPanelText(panel, "1) Fixed attributes key for weaponN block. Now 1 space needed for explode string.");
			DrawPanelText(panel, "2) Disabled vote for charset when there is only 1 not hidden chatset.");
			DrawPanelText(panel, "3) Fixed \"Invalid key value handle 0 (error 4)\" when when round starts.");
			DrawPanelText(panel, "4) Fixed ammo for special_noanims.ff2\\rage_new_weapon ability.");
			DrawPanelText(panel, "Coming soon: weapon balance will be moved into config file.");
		}
		case 7: //1.05
		{
			DrawPanelText(panel, "1) Added \"hidden\" key for charsets.");
			DrawPanelText(panel, "2) Added \"sound_stabbed\" key for characters.");
			DrawPanelText(panel, "3) Mantread stomp deals 5x damage to Boss.");
			DrawPanelText(panel, "4) Minicrits will not play loud sound to all players");
			DrawPanelText(panel, "5-11) See next page...");
		}
		case 6: //1.05
		{
			DrawPanelText(panel, "6) For mappers: Add info_target with name 'hale_no_music'");
			DrawPanelText(panel, "    to prevent Boss' music.");
			DrawPanelText(panel, "7) FF2 renames *.smx from plugins/freaks/ to *.ff2 by itself.");
			DrawPanelText(panel, "8) Third Degree hit adds uber to healers.");
			DrawPanelText(panel, "9) Fixed hard \"ghost_appearation\" in default_abilities.ff2.");
			DrawPanelText(panel, "10) FF2FLAG_HUDDISABLED flag blocks EVERYTHING of FF2's HUD.");
			DrawPanelText(panel, "11) Changed FF2_PreAbility native to fix bug about broken Boss' abilities.");
		}
		case 5: //1.04
		{
			DrawPanelText(panel, "1) Seeldier's minions have protection (teleport) from pits for first 4 seconds after spawn.");
			DrawPanelText(panel, "2) Seeldier's minions correctly dies when owner-Seeldier dies.");
			DrawPanelText(panel, "3) Added multiplier for brave jump ability in char.configs (arg3, default is 1.0).");
			DrawPanelText(panel, "4) Added config key sound_fail. It calls when Boss fails, but still alive");
			DrawPanelText(panel, "4) Fixed potential exploits associated with feign death.");
			DrawPanelText(panel, "6) Added ff2_reload_subplugins command to reload FF2's subplugins.");
		}
		case 4: //1.03
		{
			DrawPanelText(panel, "1) Finally fixed exploit about queue points.");
			DrawPanelText(panel, "2) Fixed non-regular bug with 'UTIL_SetModel: not precached'.");
			DrawPanelText(panel, "3) Fixed potential bug about reducing of Boss' health by healing.");
			DrawPanelText(panel, "4) Fixed Boss' stun when round begins.");
		}
		case 3: //1.02
		{
			DrawPanelText(panel, "1) Added isNumOfSpecial parameter into FF2_GetSpecialKV and FF2_GetBossSpecial natives");
			DrawPanelText(panel, "2) Added FF2_PreAbility forward. Plz use it to prevent FF2_OnAbility only.");
			DrawPanelText(panel, "3) Added FF2_DoAbility native.");
			DrawPanelText(panel, "4) Fixed exploit about queue points...ow wait, it done in 1.01");
			DrawPanelText(panel, "5) ff2_1st_set_abilities.ff2 sets kac_enabled to 0.");
			DrawPanelText(panel, "6) FF2FLAG_HUDDISABLED flag disables Boss' HUD too.");
			DrawPanelText(panel, "7) Added FF2_GetQueuePoints and FF2_SetQueuePoints natives.");
		}
		case 2: //1.01
		{
			DrawPanelText(panel, "1) Fixed \"classmix\" bug associated with Boss' class restoring.");
			DrawPanelText(panel, "3) Fixed other little bugs.");
			DrawPanelText(panel, "4) Fixed bug about instant kill of Seeldier's minions.");
			DrawPanelText(panel, "5) Now you can use name of Boss' file for \"companion\" Boss' keyvalue.");
			DrawPanelText(panel, "6) Fixed exploit when dead Boss can been respawned after his reconnect.");
			DrawPanelText(panel, "7-10) See next page...");
		}
		case 1: //1.01
		{
			DrawPanelText(panel, "7) I've missed 2nd item.");
			DrawPanelText(panel, "8) Fixed \"Random\" charpack, there is no vote if only one charpack.");
			DrawPanelText(panel, "9) Fixed bug when boss' music have a chance to DON'T play.");
			DrawPanelText(panel, "10) Fixed bug associated with ff2_enabled in cfg/sourcemod/FreakFortress2.cfg and disabling of pugin.");
		}
		case 0: //1.0
		{
			DrawPanelText(panel, "1) Boss' health devided by 3,6 in medieval mode");
			DrawPanelText(panel, "2) Restoring player's default class, after his round as Boss");
			DrawPanelText(panel, "===UPDATES OF VS SAXTON HALE MODE===");			
			DrawPanelText(panel, "1) Added !ff2_resetqueuepoints command (also there is admin version)");
			DrawPanelText(panel, "2) Medic is credited 100% of damage done during ubercharge");
			DrawPanelText(panel, "3) If map changes mid-round, queue points not lost");
			DrawPanelText(panel, "4) Dead Ringer will not be able to activate for 2s after backstab");
			DrawPanelText(panel, "5) Added ff2_spec_force_boss cvar");
		}
		default:
		{
			DrawPanelText(panel, "-- Somehow you've managed to find a glitched version page!");
			DrawPanelText(panel, "-- Congratulations. Now go fight Boss.");
		}
	}
}

public Action:HelpPanel3Cmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	HelpPanel3(client);
	return Plugin_Handled;
}

public Action:HelpPanel3(client)
{
	if (!Enabled2) 
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Turn the Freak Fortress 2 class info...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, ClassinfoTogglePanelH,9001);
	CloseHandle(panel);
	return Plugin_Handled;
}


public ClassinfoTogglePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (IsValidClient(param1))
	{
		if (action == MenuAction_Select)
		{
			decl String:s[24];
			decl String:ff2cookies_values[8][5];
			GetClientCookie(param1, FF2Cookies, s, 24);
			ExplodeString(s, " ", ff2cookies_values,8,5);
			if (param2 == 2)
				Format(s,24,"%s %s %s 0 %s %s %s",ff2cookies_values[0],ff2cookies_values[1],ff2cookies_values[2],ff2cookies_values[4],ff2cookies_values[5],ff2cookies_values[6],ff2cookies_values[7]);
			else
				Format(s,24,"%s %s %s 1 %s %s %s",ff2cookies_values[0],ff2cookies_values[1],ff2cookies_values[2],ff2cookies_values[4],ff2cookies_values[5],ff2cookies_values[6],ff2cookies_values[7]);
			SetClientCookie(param1, FF2Cookies,s);
			CPrintToChat(param1,"{olive}[VSH]{default} %t","ff2_classinfo", param2 == 2 ? "off" : "on");
		}
	}
}

public Action:HelpPanel2Cmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	HelpPanel2(client);
	return Plugin_Handled;
}

public Action:HelpPanel2(client)
{
	if (!Enabled)
		return Plugin_Continue;
	new index=GetBossIndex(client);
	if (index!=-1)
	{
		HelpPanelBoss(index);
		return Plugin_Continue;
	}
	decl String:s[512];
	new TFClassType:class = TF2_GetPlayerClass(client);
	SetGlobalTransTarget(client);
	switch (class)
	{
		case TFClass_Scout:
			Format(s,512,"%t","help_scout");
		case TFClass_Soldier:
			Format(s,512,"%t","help_soldier");
		case TFClass_Pyro:
			Format(s,512,"%t","help_pyro");
		case TFClass_DemoMan:
			Format(s,512,"%t","help_demo");
		case TFClass_Heavy:
			Format(s,512,"%t","help_heavy");
		case TFClass_Engineer:
			Format(s,512,"%t","help_eggineer");
		case TFClass_Medic:
			Format(s,512,"%t","help_medic");
		case TFClass_Sniper:
			Format(s,512,"%t","help_sniper");
		case TFClass_Spy:
			Format(s,512,"%t","help_spie");
		default:
			Format(s, 512, "");
	}
	new Handle:panel = CreatePanel();
	if (class!= TFClass_Sniper)
		Format(s,512,"%t\n%s","help_melee",s);
	SetPanelTitle(panel,s);
	DrawPanelItem(panel,"Exit");
	SendPanelToClient(panel, client, HintPanelH, 20);
	CloseHandle(panel);
	return Plugin_Continue;
}

public Action:HelpPanelBoss(index)
{
	decl String:s[512];
	decl String:lang[20];
	GetLanguageInfo(GetClientLanguage(Boss[index]),lang,8,s,8);
	Format(lang,20,"description_%s",lang);	
	KvRewind(BossKV[Special[index]]);
	KvGetString(BossKV[Special[index]], lang, s, 512);
	if (!s[0])
		return Plugin_Continue;
	ReplaceString(s,512,"\\n","\n");
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel,s);
	DrawPanelItem(panel,"Exit");
	SendPanelToClient(panel, Boss[index], HintPanelH, 20);
	CloseHandle(panel);
	return Plugin_Continue;
}

public Action:MusicTogglePanelCmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	MusicTogglePanel(client);
	return Plugin_Handled;
}

public Action:MusicTogglePanel(client)
{
	if (!Enabled || !IsValidClient(client)) 
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Turn the Freak Fortress 2 music...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, MusicTogglePanelH,9001);
	CloseHandle(panel);
	return Plugin_Continue;
}

public MusicTogglePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (IsValidClient(param1))
	{
		if (action == MenuAction_Select)
		{
			if (param2 == 2)
			{
				SetClientSoundOptions(param1, SOUNDEXCEPT_MUSIC, false);
				KvRewind(BossKV[Special[0]]);
				if (KvJumpToKey(BossKV[Special[0]],"sound_bgm"))
				{	
					decl String:s[PLATFORM_MAX_PATH];
					Format(s,10,"path%i",MusicIndex);
					KvGetString(BossKV[Special[0]], s,s, PLATFORM_MAX_PATH);
					StopSound(param1, SNDCHAN_AUTO, s);
					StopSound(param1, SNDCHAN_AUTO, s);
				}
			}
			else
				SetClientSoundOptions(param1, SOUNDEXCEPT_MUSIC, true);
			CPrintToChat(param1,"{olive}[FF2]{default} %t","ff2_music", param2 == 2 ? "off" : "on");
		}
	}
}
public Action:VoiceTogglePanelCmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	VoiceTogglePanel(client);
	return Plugin_Handled;
}
public Action:VoiceTogglePanel(client)
{
	if (!Enabled || !IsValidClient(client)) 
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Turn the Freak Fortress 2 voices...");
	DrawPanelItem(panel, "On");   
	DrawPanelItem(panel, "Off");   
	SendPanelToClient(panel, client, VoiceTogglePanelH,9001);
	CloseHandle(panel);
	return Plugin_Continue;
}

public VoiceTogglePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (IsValidClient(param1))
	{
		if (action == MenuAction_Select)
		{
			if (param2 == 2)
				SetClientSoundOptions(param1, SOUNDEXCEPT_VOICE, false);
			else
				SetClientSoundOptions(param1, SOUNDEXCEPT_VOICE, true);
			CPrintToChat(param1,"{olive}[FF2]{default} %t","ff2_voice", param2 == 2 ? "off" : "on");
			if (param2 == 2) CPrintToChat(param1, "%t","ff2_voice2");
		}
	}
}

public Action:HookSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!Enabled || ent<1 || ent>MaxClients || channel<1)
		return Plugin_Continue;
	new index = GetBossIndex(ent);
	if (index == -1)
		return Plugin_Continue;
	if (!StrContains(sample,"vo") && !(FF2flags[Boss[index]] & FF2FLAG_TALKING))
	{
		if (bBlockVoice[Special[index]])
			return Plugin_Handled;
		decl String:sample2[PLATFORM_MAX_PATH];
		if (RandomSound("catch_phrase",sample2,PLATFORM_MAX_PATH,index))
		{
			strcopy(sample,PLATFORM_MAX_PATH,sample2);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock SetAmmo(client, slot, ammo)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}
stock GetAmmo(client, slot)
{
	if (!IsValidClient(client)) return 0;
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{   
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		return GetEntData(client, iAmmoTable+iOffset);
	}
	return 0;
}
stock GetHealingTarget(client,bool:checkgun = false)
{
	decl String:s[64];
	new medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		return -1;
	}
	if (!IsValidEdict(medigun))
		return -1;
	GetEdictClassname(medigun, s, sizeof(s));
	if (strcmp(s, "tf_weapon_medigun", false) == 0)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	}
	return -1;
}

stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		decl String:adminname[32];
	//	decl String:auth[32];
		decl String:name[32];
		new AdminId:admin;
		GetClientName(client, name, sizeof(name));
	//	GetClientAuthString(client, auth, sizeof(auth));
		if (strcmp(name, "replay", false) == 0 && IsFakeClient(client)) return false;
		if ((admin = GetUserAdmin(client)) != INVALID_ADMIN_ID)
		{
			GetAdminUsername(admin, adminname, sizeof(adminname));
			if (strcmp(adminname, "Replay", false) == 0 || strcmp(adminname, "SourceTV", false) == 0) return false;
		}
	}
	return true;
}

public NextmapPanelH(Handle:menu, MenuAction:action, param1, param2)
{	
	if (action == MenuAction_Select && param2 == 1)
	{
		new clients[1];
		clients[0] = param1;
		if (!IsVoteInProgress())
			VoteMenu(menu, clients,param1, 1,9001);
	}
	return;
}


public NextmapPanelH2(Handle:menu,num_votes,num_clients,const client_info[][2],num_items, const item_info[][2])
{
	decl String:mode[42], String:nextmap[42];
	GetMenuItem(menu, item_info[0][VOTEINFO_ITEM_INDEX], mode,42);
	if (mode[0] == '0')
		FF2CharSet = GetRandomInt(0,FF2CharSet);
	else
		FF2CharSet=mode[0]-'0'-1;
	GetConVarString(cvarNextmap,nextmap,42);
	strcopy(FF2CharSetStr,42,mode[StrContains(mode," ")+1]);
	CPrintToChatAll("%t","nextmap_charset",nextmap,FF2CharSetStr);
}

public CvarChangeNextmap(Handle:convar, const String:oldValue[], const String:newValue[])
{	
	CreateTimer(0.1,Timer_CvarChangeNextmap);
}

public Action:Timer_CvarChangeNextmap(Handle:hTimer)
{		
	if (IsVoteInProgress())
		return Plugin_Continue;
	new Handle:dVoteMenu = CreateMenu(NextmapPanelH, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(dVoteMenu, "%t","select_charset");
	SetVoteResultCallback(dVoteMenu, NextmapPanelH2);

	decl String:s[PLATFORM_MAX_PATH], String:s2[64];
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"configs/freak_fortress_2/characters.cfg");
	new Handle:Kv = CreateKeyValues("");
	FileToKeyValues(Kv, s);
	AddMenuItem(dVoteMenu,"0 Random", "Random");
	new i,j;
	do
	{
		i++;
		if (KvGetNum(Kv, "hidden",0))
			continue;
		j++;
		KvGetSectionName(Kv, s, 64);
		Format(s2,64,"%i %s",i,s);
		AddMenuItem(dVoteMenu,s2,s);
	}
	while (KvGotoNextKey(Kv));
	CloseHandle(Kv);
	if (j > 1)
	{
		FF2CharSet = i;
		new Handle:see = FindConVar("sm_mapvote_voteduration");
		if (see)
			VoteMenuToAll(dVoteMenu, GetConVarInt(see));
		else
			VoteMenuToAll(dVoteMenu, 20); 
	}

	return Plugin_Continue;
}

public Action:NextMapCmd(client, args)
{
	if (!FF2CharSetStr[0])
		return Plugin_Continue;
	decl String:nextmap[42];
	GetConVarString(cvarNextmap,nextmap,42);
	CPrintToChat(client,"%t","nextmap_charset",nextmap,FF2CharSetStr);
	return Plugin_Handled;
}

public Action:SayCmd(client, args)
{
	decl String:CurrentChat[128];
	if (GetCmdArgString(CurrentChat, sizeof(CurrentChat)) < 1 || (client == 0))
		return Plugin_Continue;
	if (!strcmp(CurrentChat, "\"nextmap\"") && FF2CharSetStr[0])
	{
		NextMapCmd(client,0);
		return Plugin_Handled;
	}
	return Plugin_Continue;	
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
stock SetBossHealthFix(client, oldhealth)
{
	new originalhealth = oldhealth;
	if (originalhealth < 4096)
	{
		SetEntProp(client, Prop_Send, "m_iHealth", originalhealth);
		return;
	}
	oldhealth = oldhealth % 4096;
	if (oldhealth < 5) originalhealth += 10;

	SetEntProp(client, Prop_Send, "m_iHealth", originalhealth);
}

UseAbility(const String:ability_name[],const String:plugin_name[], index, slot, buttonmode = 0)
{
	new bool:enabled = true;
	Call_StartForward(PreAbility);
	Call_PushCell(index);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	Call_PushCell(slot);
	Call_PushCellRef(enabled);
	Call_Finish();

	if (!enabled)
		return;
	
	new Action:act = Plugin_Continue;
	Call_StartForward(OnAbility);
	Call_PushCell(index);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	if (slot == -1)
	{
		Call_PushCell(0);
		Call_Finish(act);
	}
	else if (!slot)
	{
		FF2flags[Boss[index]] &= ~FF2FLAG_BOTRAGE; 	
		Call_PushCell(0);
		Call_Finish(act);
		BossCharge[index][slot] = 0.0;
	}
	else
	{
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
		new RainbowDash = GetClientButtons(Boss[index]);
		decl button;
		switch (buttonmode)
		{
			//case 0: it's a taunt!
			case 2: button = IN_RELOAD;
			default: button = IN_DUCK | IN_ATTACK2;
		}
		if (RainbowDash & button)
		{
			if (!(FF2flags[Boss[index]] & FF2FLAG_USINGABILITY))
			{
				FF2flags[Boss[index]] |= FF2FLAG_USINGABILITY;
				switch (buttonmode)
				{
					//case 0: it's a taunt!
					case 2: SetInfoCookies(Boss[index],0,CheckInfoCookies(Boss[index],0)-1);
					default: SetInfoCookies(Boss[index],1,CheckInfoCookies(Boss[index],1)-1);
				}
			}
			if (BossCharge[index][slot] >= 0)
			{
				Call_PushCell(2);
				Call_Finish(act);
				new Float:see = 100.0*0.2/GetAbilityArgumentFloat(index,plugin_name,ability_name,1,1.5);
				if (BossCharge[index][slot]+see < 100)
					BossCharge[index][slot]+= see;
				else
					BossCharge[index][slot] = 100.0;
			}
			else
			{
				Call_PushCell(1);
				Call_Finish(act);
				BossCharge[index][slot]+= 0.2;
			}
		}
		else if (BossCharge[index][slot] > 0)
		{	
			new Float:ang[3];
			GetClientEyeAngles(Boss[index], ang);
			if (ang[0] < -45.0)
			{
				Call_PushCell(3);
				Call_Finish(act);
				new Handle:data;
				CreateDataTimer(0.1,Timer_UseBossCharge,data);
				WritePackCell(data, index);
				WritePackCell(data, slot);
				WritePackFloat(data, -1.0*GetAbilityArgumentFloat(index,plugin_name,ability_name,2,5.0));
				ResetPack(data);
			}
			else
			{
				Call_PushCell(0);
				Call_Finish(act);
				BossCharge[index][slot] = 0.0;
			}
		}
		else if (BossCharge[index][slot] < 0)
		{
			Call_PushCell(1);
			Call_Finish(act);
			BossCharge[index][slot]+= 0.2;
		}
		else
		{
			Call_PushCell(0);
			Call_Finish(act);
		}
	}
}
	
public Action:Timer_UseBossCharge(Handle:hTimer,Handle:data)
{
	BossCharge[ReadPackCell(data)][ReadPackCell(data)] = ReadPackFloat(data);
	return Plugin_Continue;
}

public Native_IsEnabled(Handle:plugin,numParams)
{
	return Enabled;
}

public Native_GetBoss(Handle:plugin,numParams)
{
	new i = GetNativeCell(1);
	if (i > -1 && i < MaxClients+1 && IsValidClient(Boss[i]))
		return GetClientUserId(Boss[i]);
	return -1;
}

public Native_GetIndex(Handle:plugin,numParams)
{
	return GetBossIndex(GetNativeCell(1));
}

public Native_GetTeam(Handle:plugin,numParams)
{
	return BossTeam;
}

public Native_GetSpecial(Handle:plugin,numParams)
{
	new index = GetNativeCell(1);
	new dstrlen = GetNativeCell(3);
	decl String:s[dstrlen];
	//if (isNumOfSpecial)
	new see=GetNativeCell(4);
	if (see)
	{
		if (index<0) return false;
		if (!BossKV[index]) return false;
		KvRewind(BossKV[index]);
		KvGetString(BossKV[index], "name", s, dstrlen);
		SetNativeString(2, s,dstrlen);
	}
	else
	{
		if (index<0) return false;
		if (Special[index]<0) return false;
		if (!BossKV[Special[index]]) return false;
		KvRewind(BossKV[Special[index]]);
		KvGetString(BossKV[Special[index]], "name", s, dstrlen);
		SetNativeString(2, s,dstrlen);
	}
	return true;
}

public Native_GetHealth(Handle:plugin,numParams)
{
	return BossHealth[GetNativeCell(1)];
}

public Native_GetHealthMax(Handle:plugin,numParams)
{
	return BossHealthMax[GetNativeCell(1)];
}

public Native_GetBossCharge(Handle:plugin,numParams)
{
	new index = GetNativeCell(1);
	new slot = GetNativeCell(2);
	return _:BossCharge[index][slot];
}

public Native_SetBossCharge(Handle:plugin,numParams)
{
	new index = GetNativeCell(1);
	new slot = GetNativeCell(2);
	BossCharge[index][slot] = Float:GetNativeCell(3);
}

public Native_GetRoundState(Handle:plugin,numParams)
{
	if (FF2RoundState <= 0)
		return 0;
	return FF2RoundState;
}

public Native_GetRageDist(Handle:plugin,numParams)
{
	new index = GetNativeCell(1);
	decl String:plugin_name[64]; 	
	GetNativeString(2,plugin_name,64);
	decl String:ability_name[64]; 	
	GetNativeString(3,ability_name,64);

	if (!BossKV[Special[index]]) return _:0.0;
	KvRewind(BossKV[Special[index]]);
	decl Float:see;
	if (!ability_name[0])
	{
		return _:KvGetFloat(BossKV[Special[index]],"ragedist",400.0);
	}
	decl String:s[10];
	for(new i = 1; i < MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if (KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if (strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			if ((see = KvGetFloat(BossKV[Special[index]],"dist",-1.0)) < 0)
			{
				KvRewind(BossKV[Special[index]]);
				see = KvGetFloat(BossKV[Special[index]],"ragedist",400.0);
			}
			return _:see;
		}
	}
	return _:0.0;
}

public Native_HasAbility(Handle:plugin,numParams)
{
	decl String:plugin_name[64]; 	
	decl String:ability_name[64]; 	
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	//return HasAbility(index,plugin_name,ability_name);
	return HasAbility(GetNativeCell(1),plugin_name,ability_name);
}

//native FF2_DoAbility(index, const String:plugin_name[], const String:ability_name[], slot, buttonmode = 0)
public Native_DoAbility(Handle:plugin,numParams)
{
	decl String:plugin_name[64]; 	
	decl String:ability_name[64]; 	
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	//UseAbility(const String:ability_name[],const String:plugin_name[], index, slot, buttonmode = 0)
	UseAbility(ability_name,plugin_name, GetNativeCell(1), GetNativeCell(4), GetNativeCell(5));
}

public Native_GetAbilityArgument(Handle:plugin,numParams)
{ 
	decl String:plugin_name[64]; 	
	decl String:ability_name[64]; 	
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	//return GetAbilityArgument(index,plugin_name,ability_name,s,defvalue);
	return GetAbilityArgument(GetNativeCell(1),plugin_name,ability_name,GetNativeCell(4),GetNativeCell(5));
}

public Native_GetAbilityArgumentFloat(Handle:plugin,numParams)
{ 
	decl String:plugin_name[64]; 	
	decl String:ability_name[64]; 	
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	//return _:GetAbilityArgumentFloat(index,plugin_name,ability_name,argument,defvalue);
	return _:GetAbilityArgumentFloat(GetNativeCell(1),plugin_name,ability_name,GetNativeCell(4),GetNativeCell(5));
}

public Native_GetAbilityArgumentString(Handle:plugin,numParams)
{ 
	decl String:plugin_name[64]; 	
	GetNativeString(2,plugin_name,64);
	decl String:ability_name[64]; 	
	GetNativeString(3,ability_name,64);
	new dstrlen = GetNativeCell(6);
	new String:s[dstrlen+1];
	//GetAbilityArgumentString(index,plugin_name,ability_name,argument,s,dstrlen);
	GetAbilityArgumentString(GetNativeCell(1),plugin_name,ability_name,GetNativeCell(4),s,dstrlen);
	SetNativeString(5,s,dstrlen); 	
}

public Native_GetDamage(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	if (!IsValidClient(client))
		return 0;
	return Damage[client];
}

public Native_GetFF2flags(Handle:plugin,numParams)
{
	return FF2flags[GetNativeCell(1)];
}

public Native_SetFF2flags(Handle:plugin,numParams)
{
	FF2flags[GetNativeCell(1)]=GetNativeCell(2);
}

public Native_GetQueuePoints(Handle:plugin,numParams)
{
	return GetClientQueuePoints(GetNativeCell(1));
}

public Native_SetQueuePoints(Handle:plugin,numParams)
{
	SetClientQueuePoints(GetNativeCell(1),GetNativeCell(2));
}

public Native_GetSpecialKV(Handle:plugin,numParams)
{
	new index = GetNativeCell(1);
	new bool:isNumOfSpecial = bool:GetNativeCell(2);
	if (isNumOfSpecial)
	{
		if (index!= -1 && index < Specials)
		{
			if (BossKV[index] != INVALID_HANDLE)
				KvRewind(BossKV[index]);
			return _:BossKV[index];
		}
	}
	else
	{
		if (index!= -1 && index < MaxClients+1 && Special[index]!= -1 && Special[index] < MAXSPECIALS)
		{
			if (BossKV[Special[index]] != INVALID_HANDLE)
				KvRewind(BossKV[Special[index]]);
			return _:BossKV[Special[index]];
		}
	}
	return _:INVALID_HANDLE; 	
}

public Native_StartMusic(Handle:plugin,numParams)
{
	Timer_MusicPlay(INVALID_HANDLE,GetNativeCell(1));
}

public Native_StopMusic(Handle:plugin,numParams)
{
	if (!BossKV[Special[0]]) return;
	KvRewind(BossKV[Special[0]]);
	if (KvJumpToKey(BossKV[Special[0]],"sound_bgm"))
	{	
		decl String:s[PLATFORM_MAX_PATH];
		Format(s,10,"path%i",MusicIndex);
		KvGetString(BossKV[Special[0]], s,s, PLATFORM_MAX_PATH);
		decl client;
		if (plugin == INVALID_HANDLE)
			client = 0;
		else
			client = GetNativeCell(1);
		if (!client)
			for (new i = 1 ;  i <= MaxClients;  i++)
			{
				if (!IsValidClient(i)) continue;
				StopSound(i, SNDCHAN_AUTO, s);
				StopSound(i, SNDCHAN_AUTO, s);
			}
		else
		{
			StopSound(client, SNDCHAN_AUTO, s);
			StopSound(client, SNDCHAN_AUTO, s);
		}
	}	
}

public Native_RandomSound(Handle:plugin,numParams)
{
	new length = GetNativeCell(3)+1;
	new index = GetNativeCell(4);
	new slot = GetNativeCell(5);
	new String:str[length];
	
	decl alength;
	GetNativeStringLength(1, alength);
	alength++;
	decl String:keyvalue[alength];
	
	GetNativeString(1,keyvalue,alength);
	decl bool:see;
	if (!strcmp(keyvalue,"sound_ability"))
		see = RandomSoundAbility(keyvalue, str,length,index,slot);
	else
		see = RandomSound(keyvalue, str,length,index);
	SetNativeString(2,str,length);
	return see;
}

public Native_IsVSHMap(Handle:plugin, numParams)
{
	return false;
}

public Action:VSH_OnIsSaxtonHaleModeEnabled(&result)
{
	if ((!result || result == 1) && Enabled)
	{
		result = 2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleTeam(&result)
{
	if (Enabled)
	{
		result = BossTeam; 	
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleUserId(&result)
{
	if (Enabled && IsClientConnected(Boss[0]))
	{
		result = GetClientUserId(Boss[0]);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSpecialRoundIndex(&result)
{
	if (Enabled)
	{
		result = Special[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleHealth(&result)
{
	if (Enabled)
	{
		result = BossHealth[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleHealthMax(&result)
{
	if (Enabled)
	{
		result = BossHealthMax[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetClientDamage(client,&result)
{
	if (Enabled)
	{
		result = Damage[client];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetRoundState(&result)
{
	if (Enabled)
	{
		result = FF2RoundState;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

UpdateHealthBar()
{
	// Adjust health bar
	if (!GetConVarBool(cvarHealthBar) || g_Monoculus != -1)
	{
		return;
	}
	new healthAmount = 0;
	new maxHealthAmount = 0;
	
	new count = 0;
	
	for (new i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(Boss[i]) && IsPlayerAlive(Boss[i]))
		{
			count++;
			healthAmount += BossHealth[i]-BossHealthMax[i]*(BossLives[i]-1);
			maxHealthAmount += BossHealthMax[i];
		}
	}
	
	new healthPercent = 0;

	if (count > 0)
	{
		healthPercent = RoundToCeil(float(healthAmount) / float(maxHealthAmount) * float(HEALTHBAR_MAX));

		if (healthPercent > HEALTHBAR_MAX)
		{
			healthPercent = HEALTHBAR_MAX;
		}
		else if (healthPercent <= 0)
		{
			healthPercent = 1;
		}
	}
	
	//PrintToChatAll("Updating healthbar to %d", healthPercent);
	
	SetEntProp(g_healthBar, Prop_Send, HEALTHBAR_PROPERTY, healthPercent);
}

public OnTakeDamagePost(client, attacker, inflictor, Float:damage, damagetype)
{
	if (IsBoss(client))
	{
		new index = GetBossIndex(client);
		
		if (index == -1)
			return;
		
		if (TF2_IsPlayerInCondition(Boss[index],TFCond_Jarated))
			TF2_RemoveCondition(Boss[index],TFCond_Jarated);
		
		//if (TF2_IsPlayerInCondition(Boss[index], TFCond_Milked))
		//	TF2_RemoveCondition(Boss[index],TFCond_Milked);
		
		if (TF2_IsPlayerInCondition(Boss[index], TFCond_MarkedForDeath))
			TF2_RemoveCondition(Boss[index], TFCond_MarkedForDeath);

		UpdateHealthBar();
	}
}

// These are solely for tracking Monoculus and auto-disabling/enabling the healthbar
public OnEntityCreated(entity, const String:classname[])
{
	if (!GetConVarBool(cvarHealthBar))
	{
		return;
	}

	if (StrEqual(classname, HEALTHBAR_CLASS))
	{
		g_healthBar = entity;
	}
	if (g_Monoculus == -1 && StrEqual(classname, MONOCULUS))
	{
		g_Monoculus = entity;
	}
}

public OnEntityDestroyed(entity)
{
	if (entity == -1)
	{
		return;
	}
	
	if (entity == g_Monoculus)
	{
		g_Monoculus = FindEntityByClassname(-1, MONOCULUS);
		if (g_Monoculus == entity)
		{
			g_Monoculus = FindEntityByClassname(entity, MONOCULUS);
		}
	}	
}

FindHealthBar()
{
	g_healthBar = FindEntityByClassname(-1, HEALTHBAR_CLASS);
	
	// This shouldn't happen, but just in case...
	if (g_healthBar == -1)
	{
		g_healthBar = CreateEntityByName(HEALTHBAR_CLASS);
	}
}

public HealthbarEnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Easier than checking newvalue and oldvalue
	if (GetConVarBool(cvarHealthBar))
	{
		UpdateHealthBar();
	}
	else if (g_Monoculus == -1)
	{
		SetEntProp(g_healthBar, Prop_Send, HEALTHBAR_PROPERTY, 0);
	}
}


#include < freak_fortress_2_vsh_feedback > 