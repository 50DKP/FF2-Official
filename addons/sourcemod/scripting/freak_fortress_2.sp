/*
===Freak Fortress 2===

By Rainbolt Dash: programmer, modeller, mapper, painter.
Author of Demoman The Pirate: http://www.randomfortress.ru/thepirate/
And one of two creators of Floral Defence: http://www.polycount.com/forum/showthread.php?t=73688
And author of VS Saxton Hale Mode
And notoriously famous for creating plugins with terrible code and then abandoning them.

Plugin thread on AlliedMods: http://forums.alliedmods.net/showthread.php?t=182108

Updated by Otokiru, Powerlord, and RavensBro after Rainbolt Dash got sucked into DOTA2

Updated by Wliu, Chris, Lawd, and Carge after Powerlord quit FF2
*/
#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>
#include <adt_array>
#include <clientprefs>
#include <morecolors>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#tryinclude <smac>
#tryinclude <updater>
#define REQUIRE_PLUGIN

#define MAJOR_REVISION "2"
#define MINOR_REVISION "0"
#define STABLE_REVISION "0"
#define DEV_REVISION "alpha"
#if !defined DEV_REVISION
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION  //2.0.0
#else
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION..."-"...DEV_REVISION  //semver.org
#endif

#define UPDATE_URL "http://50dkp.github.io/FF2-Official/update.txt"

#define MAXENTITIES 2048

#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255
#define MONOCULUS "eyeball_boss"

#define FF2_CONFIGS "configs/freak_fortress_2"
#define FF2_SETTINGS "data/freak_fortress_2"
#define BOSS_CONFIG "characters.cfg"
#define DOORS_CONFIG "doors.cfg"
#define WEAPONS_CONFIG "weapons.cfg"
#define MAPS_CONFIG	"maps.cfg"
#define CHANGELOG "changelog.txt"

#if defined _steamtools_included
new bool:steamtools;
#endif

new TFTeam:OtherTeam=TFTeam_Red;
new TFTeam:BossTeam=TFTeam_Blue;
new playing;
new healthcheckused;
new RedAlivePlayers;
new BlueAlivePlayers;
new RoundCount;
new character[MAXPLAYERS+1];
new Incoming[MAXPLAYERS+1];

new Damage[MAXPLAYERS+1];
new uberTarget[MAXPLAYERS+1];
new shield[MAXPLAYERS+1];
new detonations[MAXPLAYERS+1];
new bool:playBGM[MAXPLAYERS+1]=true;
new queuePoints[MAXPLAYERS+1];
new muteSound[MAXPLAYERS+1];
new bool:displayInfo[MAXPLAYERS+1];

new String:currentBGM[MAXPLAYERS+1][PLATFORM_MAX_PATH];

new FF2Flags[MAXPLAYERS+1];

new Boss[MAXPLAYERS+1];
new BossHealthMax[MAXPLAYERS+1];
new BossHealth[MAXPLAYERS+1];
new BossHealthLast[MAXPLAYERS+1];
new BossLives[MAXPLAYERS+1];
new BossLivesMax[MAXPLAYERS+1];
new BossRageDamage[MAXPLAYERS+1];
new Float:BossSpeed[MAXPLAYERS+1];
new Float:BossCharge[MAXPLAYERS+1][8];
new Float:Stabbed[MAXPLAYERS+1];
new Float:Marketed[MAXPLAYERS+1];
new Float:KSpreeTimer[MAXPLAYERS+1];
new KSpreeCount[MAXPLAYERS+1];
new Float:GlowTimer[MAXPLAYERS+1];
new shortname[MAXPLAYERS+1];
new bool:emitRageSound[MAXPLAYERS+1];
new bool:bossHasReloadAbility[MAXPLAYERS+1];
new bool:bossHasRightMouseAbility[MAXPLAYERS+1];

new timeleft;

new Handle:cvarVersion;
new Handle:cvarPointDelay;
new Handle:cvarAnnounce;
new Handle:cvarEnabled;
new Handle:cvarAliveToEnable;
new Handle:cvarPointType;
new Handle:cvarCrits;
new Handle:cvarArenaRounds;
new Handle:cvarCircuitStun;
new Handle:cvarSpecForceBoss;
new Handle:cvarCountdownPlayers;
new Handle:cvarCountdownTime;
new Handle:cvarCountdownHealth;
new Handle:cvarCountdownResult;
new Handle:cvarEnableEurekaEffect;
new Handle:cvarForceBossTeam;
new Handle:cvarHealthBar;
new Handle:cvarLastPlayerGlow;
new Handle:cvarBossTeleporter;
new Handle:cvarBossSuicide;
new Handle:cvarShieldCrits;
new Handle:cvarCaberDetonations;
new Handle:cvarUpdater;
new Handle:cvarDebug;
new Handle:cvarPreroundBossDisconnect;

new Handle:bossesArray;
new Handle:bossesArrayShadow; // FIXME: ULTRA HACKY HACK
new Handle:voicesArray; // TODO: Rename this or remove it in favor of something else
new Handle:subpluginArray;
new Handle:chancesArray;

new Handle:FF2Cookie_QueuePoints;
new Handle:FF2Cookie_MuteSound;
new Handle:FF2Cookie_DisplayInfo;

new Handle:changelogMenu;

new Handle:jumpHUD;
new Handle:rageHUD;
new Handle:livesHUD;
new Handle:timeleftHUD;
new Handle:abilitiesHUD;
new Handle:infoHUD;

new bool:Enabled=true;
new bool:Enabled2=true;
new PointDelay=6;
new Float:Announce=120.0;
new AliveToEnable=5;
new PointType;
new bool:BossCrits=true;
new arenaRounds;
new Float:circuitStun;
new countdownPlayers=1;
new countdownTime=120;
new countdownHealth=2000;
new bool:SpecForceBoss;
new bool:lastPlayerGlow=true;
new bool:bossTeleportation=true;
new shieldCrits;
new allowedDetonations;

new Handle:MusicTimer[MAXPLAYERS+1];
new Handle:BossInfoTimer[MAXPLAYERS+1][2];
new Handle:DrawGameTimer;
new Handle:doorCheckTimer;

new botqueuepoints;
new Float:HPTime;
new String:currentmap[99];
new bool:checkDoors;
new bool:bMedieval;
new bool:firstBlood;

new tf_arena_use_queue;
new mp_teams_unbalance_limit;
new tf_arena_first_blood;
new mp_forcecamera;
new tf_dropped_weapon_lifetime;
new Float:tf_feign_death_activate_damage_scale;
new Float:tf_feign_death_damage_scale;
new String:mp_humans_must_join_team[16];

new Handle:cvarNextmap;

new FF2CharSet;
new validCharsets[64];
new String:FF2CharSetString[42];
new bool:isCharSetSelected;

new healthBar=-1;
new g_Monoculus=-1;

static bool:executed;
static bool:executed2;

new changeGamemode;

//new Handle:kvWeaponSpecials;
new Handle:kvWeaponMods;

enum FF2RoundState
{
	FF2RoundState_Loading=-1,
	FF2RoundState_Setup,
	FF2RoundState_RoundRunning,
	FF2RoundState_RoundEnd,
}

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

/*new String:WeaponSpecials[][]=
{
	"drop health pack on kill",
	"glow on scoped hit",
	"prevent damage",
	"remove on damage",
	"drain boost when full"
};*/

enum Operators
{
	Operator_None=0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

new Handle:PreAbility;
new Handle:OnAbility;
new Handle:OnMusic;
new Handle:OnTriggerHurt;
new Handle:OnBossSelected;
new Handle:OnAddQueuePoints;
new Handle:OnLoadCharacterSet;
new Handle:OnLoseLife;
new Handle:OnAlivePlayersChanged;
new Handle:OnParseUnknownVariable;

public Plugin:myinfo=
{
	name="Freak Fortress 2",
	author="Rainbolt Dash, FlaminSarge, Powerlord, the 50DKP team",
	description="RUUUUNN!! COWAAAARRDSS!",
	version=PLUGIN_VERSION,
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:plugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myself, plugin, sizeof(plugin));
	if(!StrContains(plugin, "freak_fortress_2/"))  //Prevent plugins/freak_fortress_2/freak_fortress_2.smx from loading if it exists -.-
	{
		strcopy(error, err_max, "There is a duplicate copy of Freak Fortress 2 inside the /plugins/freak_fortress_2 folder.  Please remove it");
		return APLRes_Failure;
	}

	CreateNative("FF2_IsFF2Enabled", Native_IsFF2Enabled);
	CreateNative("FF2_RegisterSubplugin", Native_RegisterSubplugin);
	CreateNative("FF2_UnregisterSubplugin", Native_UnregisterSubplugin);
	CreateNative("FF2_GetFF2Version", Native_GetFF2Version);
	CreateNative("FF2_GetRoundState", Native_GetRoundState);
	CreateNative("FF2_GetBossUserId", Native_GetBossUserId);
	CreateNative("FF2_GetBossIndex", Native_GetBossIndex);
	CreateNative("FF2_GetBossTeam", Native_GetBossTeam);
	CreateNative("FF2_GetBossName", Native_GetBossName);
	CreateNative("FF2_GetBossKV", Native_GetBossKV);
	CreateNative("FF2_GetBossHealth", Native_GetBossHealth);
	CreateNative("FF2_SetBossHealth", Native_SetBossHealth);
	CreateNative("FF2_GetBossMaxHealth", Native_GetBossMaxHealth);
	CreateNative("FF2_SetBossMaxHealth", Native_SetBossMaxHealth);
	CreateNative("FF2_GetBossLives", Native_GetBossLives);
	CreateNative("FF2_SetBossLives", Native_SetBossLives);
	CreateNative("FF2_GetBossMaxLives", Native_GetBossMaxLives);
	CreateNative("FF2_SetBossMaxLives", Native_SetBossMaxLives);
	CreateNative("FF2_GetBossCharge", Native_GetBossCharge);
	CreateNative("FF2_SetBossCharge", Native_SetBossCharge);
	CreateNative("FF2_GetBossRageDamage", Native_GetBossRageDamage);
	CreateNative("FF2_SetBossRageDamage", Native_SetBossRageDamage);
	CreateNative("FF2_GetBossRageDistance", Native_GetBossRageDistance);
	CreateNative("FF2_GetClientDamage", Native_GetClientDamage);
	CreateNative("FF2_SetClientDamage", Native_SetClientDamage);
	CreateNative("FF2_HasAbility", Native_HasAbility);
	CreateNative("FF2_GetAbilityArgument", Native_GetAbilityArgument);
	CreateNative("FF2_GetAbilityArgumentFloat", Native_GetAbilityArgumentFloat);
	CreateNative("FF2_GetAbilityArgumentString", Native_GetAbilityArgumentString);
	CreateNative("FF2_UseAbility", Native_UseAbility);
	CreateNative("FF2_GetFF2Flags", Native_GetFF2Flags);
	CreateNative("FF2_SetFF2Flags", Native_SetFF2Flags);
	CreateNative("FF2_GetQueuePoints", Native_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints", Native_SetQueuePoints);
	CreateNative("FF2_StartMusic", Native_StartMusic);
	CreateNative("FF2_StopMusic", Native_StopMusic);
	CreateNative("FF2_FindSound", Native_FindSound);
	CreateNative("FF2_GetClientGlow", Native_GetClientGlow);
	CreateNative("FF2_SetClientGlow", Native_SetClientGlow);
	CreateNative("FF2_Debug", Native_Debug);
	CreateNative("FF2_SetSoundFlags", Native_SetSoundFlags);
	CreateNative("FF2_ClearSoundFlags", Native_ClearSoundFlags);
	CreateNative("FF2_CheckSoundFlags", Native_CheckSoundFlags);

	PreAbility=CreateGlobalForward("FF2_PreAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);  //Boss, plugin name, ability name, slot, enabled
	OnAbility=CreateGlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_Cell);  //Boss, plugin name, ability name, slot, status
	OnMusic=CreateGlobalForward("FF2_OnMusic", ET_Hook, Param_Cell, Param_String, Param_CellByRef);
	OnTriggerHurt=CreateGlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	OnBossSelected=CreateGlobalForward("FF2_OnBossSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String, Param_Cell);  //Boss, character index, character name, preset
	OnAddQueuePoints=CreateGlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
	OnLoadCharacterSet=CreateGlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_String);
	OnLoseLife=CreateGlobalForward("FF2_OnLoseLife", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);  //Boss, lives left, max lives
	OnAlivePlayersChanged=CreateGlobalForward("FF2_OnAlivePlayersChanged", ET_Hook, Param_Cell, Param_Cell);  //Players, bosses
	OnParseUnknownVariable=CreateGlobalForward("FF2_OnParseUnknownVariable", ET_Hook, Param_String, Param_FloatByRef);  //Variable, value

	RegPluginLibrary("freak_fortress_2");

	subpluginArray=CreateArray(64); // Create this as soon as possible so that subplugins have access to it

	#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
	#endif
	return APLRes_Success;
}

public OnPluginStart()
{
	LogMessage("===Freak Fortress 2 Initializing-v%s===", PLUGIN_VERSION);

	cvarVersion=CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarPointType=CreateConVar("ff2_point_type", "0", "0-Use ff2_point_alive, 1-Use ff2_point_time", _, true, 0.0, true, 1.0);
	cvarPointDelay=CreateConVar("ff2_point_delay", "6", "Seconds to add to the point delay per player", _, true, 0.0);
	cvarAliveToEnable=CreateConVar("ff2_point_alive", "5", "The control point will only activate when there are this many people or less left alive");
	cvarAnnounce=CreateConVar("ff2_announce", "120", "Amount of seconds to wait until FF2 info is displayed again.  0 to disable", _, true, 0.0);
	cvarEnabled=CreateConVar("ff2_enabled", "1", "0-Disable FF2 (WHY?), 1-Enable FF2", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	cvarCrits=CreateConVar("ff2_crits", "0", "Can the boss get random crits?", _, true, 0.0, true, 1.0);
	cvarArenaRounds=CreateConVar("ff2_arena_rounds", "1", "Number of rounds to make arena before switching to FF2 (helps for slow-loading players)", _, true, 0.0);
	cvarCircuitStun=CreateConVar("ff2_circuit_stun", "2", "Amount of seconds the Short Circuit stuns the boss for.  0 to disable", _, true, 0.0);
	cvarCountdownPlayers=CreateConVar("ff2_countdown_players", "1", "Amount of players until the countdown timer starts (0 to disable)", _, true, 0.0);
	cvarCountdownTime=CreateConVar("ff2_countdown", "120", "Amount of seconds until the round ends in a stalemate");
	cvarCountdownHealth=CreateConVar("ff2_countdown_health", "2000", "Amount of health the Boss has remaining until the countdown stops", _, true, 0.0);
	cvarCountdownResult=CreateConVar("ff2_countdown_result", "0", "0-Kill players when the countdown ends, 1-End the round in a stalemate", _, true, 0.0, true, 1.0);
	cvarSpecForceBoss=CreateConVar("ff2_spec_force_boss", "0", "0-Spectators are excluded from the queue system, 1-Spectators are counted in the queue system", _, true, 0.0, true, 1.0);
	cvarEnableEurekaEffect=CreateConVar("ff2_enable_eureka", "0", "0-Disable the Eureka Effect, 1-Enable the Eureka Effect", _, true, 0.0, true, 1.0);
	cvarForceBossTeam=CreateConVar("ff2_force_team", "0", "0-Boss is always on Blu, 1-Boss is on a random team each round, 2-Boss is always on Red", _, true, 0.0, true, 3.0);
	cvarHealthBar=CreateConVar("ff2_health_bar", "0", "0-Disable the health bar, 1-Show the health bar", _, true, 0.0, true, 1.0);
	cvarLastPlayerGlow=CreateConVar("ff2_last_player_glow", "1", "0-Don't outline the last player, 1-Outline the last player alive", _, true, 0.0, true, 1.0);
	cvarBossTeleporter=CreateConVar("ff2_boss_teleporter", "0", "-1 to disallow all bosses from using teleporters, 0 to use TF2 logic, 1 to allow all bosses", _, true, -1.0, true, 1.0);
	cvarBossSuicide=CreateConVar("ff2_boss_suicide", "0", "Allow the boss to suicide after the round starts?", _, true, 0.0, true, 1.0);
	cvarPreroundBossDisconnect=CreateConVar("ff2_replace_disconnected_boss", "1", "If a boss disconnects before the round starts, use the next player in line instead? 0 - No, 1 - Yes", _, true, 0.0, true, 1.0);
	cvarCaberDetonations=CreateConVar("ff2_caber_detonations", "5", "Amount of times somebody can detonate the Ullapool Caber");
	cvarShieldCrits=CreateConVar("ff2_shield_crits", "0", "0 to disable grenade launcher crits when equipping a shield, 1 for minicrits, 2 for crits", _, true, 0.0, true, 2.0);
	cvarUpdater=CreateConVar("ff2_updater", "1", "0-Disable Updater support, 1-Enable automatic updating (recommended, requires Updater)", _, true, 0.0, true, 1.0);
	cvarDebug=CreateConVar("ff2_debug", "0", "0-Disable FF2 debug output, 1-Enable debugging (not recommended)", _, true, 0.0, true, 1.0);

	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("teamplay_broadcast_audio", OnBroadcast, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_chargedeployed", OnUberDeployed);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("object_destroyed", OnObjectDestroyed, EventHookMode_Pre);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Pre);
	HookEvent("deploy_buff_banner", OnDeployBackup);

	HookUserMessage(GetUserMessageId("PlayerJarated"), OnJarate);  //Used to subtract rage when a boss is jarated (not through Sydney Sleeper)

	AddCommandListener(OnCallForMedic, "voicemenu");    //Used to activate rages
	AddCommandListener(OnSuicide, "explode");           //Used to stop boss from suiciding
	AddCommandListener(OnSuicide, "kill");              //Used to stop boss from suiciding
	AddCommandListener(OnSuicide, "spectate");			//Used to stop boss from suiciding
	AddCommandListener(OnJoinTeam, "jointeam");         //Used to make sure players join the right team
	AddCommandListener(OnJoinTeam, "autoteam");         //Used to make sure players don't kill themselves and change team
	AddCommandListener(OnChangeClass, "joinclass");     //Used to make sure bosses don't change class

	HookConVarChange(cvarEnabled, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarAnnounce, CvarChange);
	HookConVarChange(cvarPointType, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarAliveToEnable, CvarChange);
	HookConVarChange(cvarCrits, CvarChange);
	HookConVarChange(cvarCircuitStun, CvarChange);
	HookConVarChange(cvarHealthBar, HealthbarEnableChanged);
	HookConVarChange(cvarCountdownPlayers, CvarChange);
	HookConVarChange(cvarCountdownTime, CvarChange);
	HookConVarChange(cvarCountdownHealth, CvarChange);
	HookConVarChange(cvarLastPlayerGlow, CvarChange);
	HookConVarChange(cvarSpecForceBoss, CvarChange);
	HookConVarChange(cvarBossTeleporter, CvarChange);
	HookConVarChange(cvarShieldCrits, CvarChange);
	HookConVarChange(cvarCaberDetonations, CvarChange);
	HookConVarChange(cvarUpdater, CvarChange);
	HookConVarChange(cvarNextmap=FindConVar("sm_nextmap"), CvarChangeNextmap);

	RegConsoleCmd("ff2", FF2Panel);
	RegConsoleCmd("ff2_hp", Command_GetHPCmd);
	RegConsoleCmd("ff2_next", QueuePanelCmd);
	RegConsoleCmd("ff2_classinfo", Command_HelpPanelClass);
	RegConsoleCmd("ff2_changelog", Command_ShowChangelog);
	RegConsoleCmd("ff2_music", MusicTogglePanelCmd);
	RegConsoleCmd("ff2_voice", VoiceTogglePanelCmd);
	RegConsoleCmd("ff2_resetpoints", ResetQueuePointsCmd);

	RegConsoleCmd("nextmap", Command_Nextmap);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	RegAdminCmd("ff2_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  ff2_special <boss>.  Forces next round to use that boss");
	RegAdminCmd("ff2_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage:  ff2_addpoints <target> <points>.  Adds queue points to any player");
	RegAdminCmd("ff2_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_start_music", Command_StartMusic, ADMFLAG_CHEATS, "Start the Boss's music");
	RegAdminCmd("ff2_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music");
	RegAdminCmd("ff2_resetqueuepoints", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("ff2_resetq", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("ff2_charset", Command_Charset, ADMFLAG_CHEATS, "Usage:  ff2_charset <charset>.  Forces FF2 to use a given character set");
	RegAdminCmd("ff2_reload_subplugins", Command_ReloadSubPlugins, ADMFLAG_RCON, "Reload FF2's subplugins.");

	AutoExecConfig(true, "freak_fortress_2", "sourcemod/freak_fortress_2");

	FF2Cookie_QueuePoints=RegClientCookie("ff2_cookie_queuepoints", "Client's queue points", CookieAccess_Protected);
	FF2Cookie_MuteSound=RegClientCookie("ff2_cookie_mutesound", "Client's sound preferences", CookieAccess_Public);
	FF2Cookie_DisplayInfo=RegClientCookie("ff2_cookie_displayinfo", "Client's display info preferences", CookieAccess_Public);

	jumpHUD=CreateHudSynchronizer();
	rageHUD=CreateHudSynchronizer();
	livesHUD=CreateHudSynchronizer();
	abilitiesHUD=CreateHudSynchronizer();
	timeleftHUD=CreateHudSynchronizer();
	infoHUD=CreateHudSynchronizer();

	bossesArray=CreateArray();
	bossesArrayShadow=CreateArray();
	voicesArray=CreateArray();

	decl String:oldVersion[64];
	GetConVarString(cvarVersion, oldVersion, sizeof(oldVersion));
	if(!StrEqual(oldVersion, PLUGIN_VERSION, false))
	{
		PrintToServer("[FF2] Warning: Your config may be outdated. Back up tf/cfg/sourcemod/freak_fortress_2.cfg and delete it, and this plugin will generate a new one that you can then modify to your original values.");
	}

	LoadTranslations("freak_fortress_2.phrases");
	LoadTranslations("common.phrases");

	AddNormalSoundHook(HookSound);

	AddMultiTargetFilter("@hale", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!hale", BossTargetFilter, "all non-Boss players", false);
	AddMultiTargetFilter("@boss", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!boss", BossTargetFilter, "all non-Boss players", false);

	#if defined _steamtools_included
	steamtools=LibraryExists("SteamTools");
	#endif
}

public bool:BossTargetFilter(const String:pattern[], Handle:clients)
{
	new bool:non=StrContains(pattern, "!", false)!=-1;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && FindValueInArray(clients, client)==-1)
		{
			if(Enabled && IsBoss(client))
			{
				if(!non)
				{
					PushArrayCell(clients, client);
				}
			}
			else if(non)
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
	if(StrEqual(name, "SteamTools", false))
	{
		steamtools=true;
	}
	#endif

	#if defined _updater_included && !defined DEV_REVISION
	if(StrEqual(name, "updater") && GetConVarBool(cvarUpdater))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

public OnLibraryRemoved(const String:name[])
{
	#if defined _steamtools_included
	if(StrEqual(name, "SteamTools", false))
	{
		steamtools=false;
	}
	#endif

	#if defined _updater_included
	if(StrEqual(name, "updater"))
	{
		Updater_RemovePlugin();
	}
	#endif
}

public OnConfigsExecuted()
{
	tf_arena_use_queue=GetConVarInt(FindConVar("tf_arena_use_queue"));
	mp_teams_unbalance_limit=GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
	tf_arena_first_blood=GetConVarInt(FindConVar("tf_arena_first_blood"));
	mp_forcecamera=GetConVarInt(FindConVar("mp_forcecamera"));
	tf_dropped_weapon_lifetime=bool:GetConVarInt(FindConVar("tf_dropped_weapon_lifetime"));
	tf_feign_death_activate_damage_scale=GetConVarFloat(FindConVar("tf_feign_death_activate_damage_scale"));
	tf_feign_death_damage_scale=GetConVarFloat(FindConVar("tf_feign_death_damage_scale"));
	GetConVarString(FindConVar("mp_humans_must_join_team"), mp_humans_must_join_team, sizeof(mp_humans_must_join_team));

	if(IsFF2Map() && GetConVarBool(cvarEnabled))
	{
		EnableFF2();
	}
	else
	{
		DisableFF2();
	}

	#if defined _updater_included && !defined DEV_REVISION
	if(LibraryExists("updater") && GetConVarBool(cvarUpdater))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

public OnMapStart()
{
	HPTime=0.0;
	doorCheckTimer=INVALID_HANDLE;
	RoundCount=0;
	for(new client; client<=MaxClients; client++)
	{
		KSpreeTimer[client]=0.0;
		FF2Flags[client]=0;
		Incoming[client]=-1;
		MusicTimer[client]=INVALID_HANDLE;
	}

	for(new index; index<GetArraySize(bossesArray); index++)
	{
		if(GetArrayCell(bossesArray, index)!=INVALID_HANDLE)
		{
			CloseHandle(GetArrayCell(bossesArray, index));
			SetArrayCell(bossesArray, index, INVALID_HANDLE);
		}
		if(GetArrayCell(bossesArrayShadow, index)!=INVALID_HANDLE)
		{
			CloseHandle(GetArrayCell(bossesArrayShadow, index));
			SetArrayCell(bossesArrayShadow, index, INVALID_HANDLE);
		}
	}
}

public OnMapEnd()
{
	if(Enabled || Enabled2)
	{
		DisableFF2();  //This resets all the variables for safety
	}
}

public OnPluginEnd()
{
	OnMapEnd();
}

public EnableFF2()
{
	Enabled=true;
	Enabled2=true;

	new String:config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2_SETTINGS, WEAPONS_CONFIG);

	if(kvWeaponMods!=INVALID_HANDLE)
	{
		CloseHandle(kvWeaponMods);
	}
	kvWeaponMods=CreateKeyValues("FF2Weapons");

	if(!FileToKeyValues(kvWeaponMods, config))
	{
		LogError("[FF2 Configs] Failed to load weapon configuration file!");
		Enabled=false;
		Enabled2=false;
		return;
	}

	ParseChangelog();

	//Cache cvars
	SetConVarString(FindConVar("ff2_version"), PLUGIN_VERSION);
	Announce=GetConVarFloat(cvarAnnounce);
	PointType=GetConVarInt(cvarPointType);
	PointDelay=GetConVarInt(cvarPointDelay);
	AliveToEnable=GetConVarInt(cvarAliveToEnable);
	BossCrits=GetConVarBool(cvarCrits);
	arenaRounds=GetConVarInt(cvarArenaRounds);
	circuitStun=GetConVarFloat(cvarCircuitStun);
	countdownHealth=GetConVarInt(cvarCountdownHealth);
	countdownPlayers=GetConVarInt(cvarCountdownPlayers);
	countdownTime=GetConVarInt(cvarCountdownTime);
	lastPlayerGlow=GetConVarBool(cvarLastPlayerGlow);
	bossTeleportation=GetConVarBool(cvarBossTeleporter);
	shieldCrits=GetConVarInt(cvarShieldCrits);
	allowedDetonations=GetConVarInt(cvarCaberDetonations);

	//Set some Valve cvars to what we want them to be
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_forcecamera"), 0);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);
	SetConVarFloat(FindConVar("tf_feign_death_activate_damage_scale"), 0.3);
	SetConVarFloat(FindConVar("tf_feign_death_damage_scale"), 0.0);
	SetConVarString(FindConVar("mp_humans_must_join_team"), "any");

	new Float:time=Announce;
	if(time>1.0)
	{
		CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	CheckToChangeMapDoors();
	MapHasMusic(true);
	FindCharacters();
	strcopy(FF2CharSetString, 2, "");

	bMedieval=FindEntityByClassname(-1, "tf_logic_medieval")!=-1 || bool:GetConVarInt(FindConVar("tf_medieval"));
	FindHealthBar();

	#if defined _steamtools_included
	if(steamtools)
	{
		decl String:gameDesc[64];
		Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", PLUGIN_VERSION);
		Steam_SetGameDescription(gameDesc);
	}
	#endif

	changeGamemode=0;
}

public DisableFF2()
{
	Enabled=false;
	Enabled2=false;

	SetConVarInt(FindConVar("tf_arena_use_queue"), tf_arena_use_queue);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), mp_teams_unbalance_limit);
	SetConVarInt(FindConVar("tf_arena_first_blood"), tf_arena_first_blood);
	SetConVarInt(FindConVar("mp_forcecamera"), mp_forcecamera);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), tf_dropped_weapon_lifetime);
	SetConVarFloat(FindConVar("tf_feign_death_activate_damage_scale"), tf_feign_death_activate_damage_scale);
	SetConVarFloat(FindConVar("tf_feign_death_damage_scale"), tf_feign_death_damage_scale);
	SetConVarString(FindConVar("mp_humans_must_join_team"), mp_humans_must_join_team);

	if(doorCheckTimer!=INVALID_HANDLE)
	{
		KillTimer(doorCheckTimer);
		doorCheckTimer=INVALID_HANDLE;
	}

	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(BossInfoTimer[client][1]!=INVALID_HANDLE)
			{
				KillTimer(BossInfoTimer[client][1]);
				BossInfoTimer[client][1]=INVALID_HANDLE;
			}
		}

		if(MusicTimer[client]!=INVALID_HANDLE)
		{
			KillTimer(MusicTimer[client]);
			MusicTimer[client]=INVALID_HANDLE;
		}

		bossHasReloadAbility[client]=false;
		bossHasRightMouseAbility[client]=false;
	}

	#if defined _steamtools_included
	if(steamtools)
	{
		Steam_SetGameDescription("Team Fortress");
	}
	#endif

	changeGamemode=0;
}

public FindCharacters()
{
	chancesArray=CreateArray();

	decl String:config[PLATFORM_MAX_PATH], String:charset[42];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2_SETTINGS, BOSS_CONFIG);

	if(!FileExists(config))
	{
		LogError("[FF2 Bosses] Disabling Freak Fortress 2 - can not find %s!", config);
		Enabled2=false;
		return;
	}

	new Handle:kv=CreateKeyValues("");
	FileToKeyValues(kv, config);

	new Action:action;
	Call_StartForward(OnLoadCharacterSet);
	strcopy(charset, sizeof(charset), FF2CharSetString);
	Call_PushStringEx(charset, sizeof(charset), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(action);
	if(action==Plugin_Changed)
	{
		if(strlen(charset))
		{
			new i;

			KvRewind(kv);
			while(KvGotoNextKey(kv))
			{
				KvGetSectionName(kv, config, sizeof(config));
				if(StrEqual(config, charset))
				{
					FF2CharSet=i;
					strcopy(FF2CharSetString, sizeof(FF2CharSetString), charset);
					break;
				}
				i++;
			}
		}
	}

	KvRewind(kv);
	KvJumpToKey(kv, FF2CharSetString); // This *should* always return true

	if(KvGotoFirstSubKey(kv, false))
	{
		new index;
		do
		{
			KvGetSectionName(kv, config, sizeof(config));
			int chance=KvGetNum(kv, NULL_STRING, -1);

			if(chance<0)
			{
				LogError("[FF2 Bosses] Character %s has an invalid chance - assuming 0", config);
			}

			for(new j; j<chance; j++)
			{
				PushArrayCell(chancesArray, index);
			}

			if(chance>0)
			{
				LoadCharacter(config);
			}
			index++;
		}
		while(KvGotoNextKey(kv, false));
	}
	else
	{
		LogError("[FF2 Bosses] Disabling Freak Fortress 2 - no bosses in character set %s!", FF2CharSetString);
		Enabled2=false;
		return;
	}

	CloseHandle(kv);

	if(FileExists("sound/saxton_hale/9000.wav", true))
	{
		AddFileToDownloadsTable("sound/saxton_hale/9000.wav");
		PrecacheSound("saxton_hale/9000.wav", true);
	}
	PrecacheSound("vo/announcer_am_capincite01.mp3", true);
	PrecacheSound("vo/announcer_am_capincite03.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled01.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled02.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled03.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled04.mp3", true);
	PrecacheSound("weapons/barret_arm_zap.wav", true);
	PrecacheSound("vo/announcer_ends_5min.mp3", true);
	PrecacheSound("vo/announcer_ends_2min.mp3", true);
	PrecacheSound("player/doubledonk.wav", true);
	isCharSetSelected=false;
}

stock ParseChangelog()
{
	decl String:changelog[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, changelog, sizeof(changelog), "%s/%s", FF2_SETTINGS, CHANGELOG);
	if(!FileExists(changelog))
	{
		LogError("[FF2] Changelog %s does not exist!", changelog);
		return;
	}

	new Handle:kv=CreateKeyValues("Changelog");
	FileToKeyValues(kv, changelog);

	changelogMenu=CreateMenu(Handler_ChangelogMenu);
	SetMenuTitle(changelogMenu, "%t", "Changelog");

	new i, j;
	if(KvGotoFirstSubKey(kv))
	{
		decl String:version[64], String:text[256], String:temp[70];
		do
		{
			KvGetSectionName(kv, version, sizeof(version));
			Format(temp, sizeof(temp), "%i", i);
			AddMenuItem(changelogMenu, temp, version, ITEMDRAW_DISABLED);
			i++;

			if(KvGotoFirstSubKey(kv, false))
			{
				j=0;
				do
				{
					KvGetString(kv, NULL_STRING, text, sizeof(text));
					Format(temp, sizeof(temp), "%s %i", version, j);
					AddMenuItem(changelogMenu, temp, text, ITEMDRAW_DISABLED);
					j++;
				}
				while(KvGotoNextKey(kv, false));
				KvGoBack(kv);
			}
		}
		while(KvGotoNextKey(kv));
	}
	else
	{
		LogError("[FF2] Changelog %s is empty!", changelog);
	}
}

public LoadCharacter(const String:characterName[])
{
	decl String:config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s.cfg", FF2_CONFIGS, characterName);
	if(!FileExists(config))
	{
		LogError("[FF2 Bosses] Character %s does not exist!", characterName);
		return;
	}

	new Handle:kv=CreateKeyValues("character");
	PushArrayCell(bossesArray, kv);
	FileToKeyValues(kv, config);

	kv=CreateKeyValues("character");
	PushArrayCell(bossesArrayShadow, kv);
	FileToKeyValues(kv, config);

	new version=KvGetNum(kv, "version", 1);
	if(version!=StringToInt(MAJOR_REVISION))
	{
		LogError("[FF2 Bosses] Character %s is only compatible with FF2 v%i!", characterName, version);
		return;
	}

	if(KvJumpToKey(kv, "abilities"))
	{
		if(KvGotoFirstSubKey(kv))
		{
			decl String:pluginName[64];
			do
			{
				KvGetSectionName(kv, pluginName, sizeof(pluginName));
				if(FindStringInArray(subpluginArray, pluginName)<0)
				{
					LogError("[FF2 Bosses] Character %s needs plugin %s!", characterName, pluginName);
					return;
				}
			}
			while(KvGotoNextKey(kv));
		}
	}
	KvRewind(kv);

	decl String:file[PLATFORM_MAX_PATH], String:section[64];
	new String:extensions[][]={".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
	KvSetString(kv, "filename", characterName);
	KvGetString(kv, "name", config, sizeof(config));
	PushArrayCell(voicesArray, KvGetNum(kv, "block voice", 0));
	KvGotoFirstSubKey(kv);

	while(KvGotoNextKey(kv))
	{
		KvGetSectionName(kv, section, sizeof(section));
		if(StrEqual(section, "downloads"))
		{
			while(KvGotoNextKey(kv))
			{
				KvGetSectionName(kv, file, sizeof(file));
				if(KvGetNum(kv, "model"))
				{
					for(new extension; extension<sizeof(extensions); extension++)
					{
						Format(file, sizeof(file), "%s%s", file, extensions[extension]);
						if(FileExists(file, true))
						{
							AddFileToDownloadsTable(file);
						}
						else
						{
							LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, file);
						}
					}

					if(KvGetNum(kv, "phy"))
					{
						Format(file, sizeof(file), "%s.phy", file);
						if(FileExists(file, true))
						{
							AddFileToDownloadsTable(file);
						}
						else
						{
							LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, file);
						}
					}
				}
				else if(KvGetNum(kv, "material"))
				{
					Format(file, sizeof(file), "%s.vmt", file);
					if(FileExists(file, true))
					{
						AddFileToDownloadsTable(file);
					}
					else
					{
						LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, file);
					}

					Format(file, sizeof(file), "%s.vtf", file);
					if(FileExists(file, true))
					{
						AddFileToDownloadsTable(file);
					}
					else
					{
						LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, file);
					}
				}
				else if(FileExists(file, true))
				{
					AddFileToDownloadsTable(file);
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, file);
				}
			}
		}
	}
}

public PrecacheCharacter(characterIndex)
{
	decl String:file[PLATFORM_MAX_PATH], String:filePath[PLATFORM_MAX_PATH], String:bossName[64];
	new Handle:kv=GetArrayCell(bossesArray, characterIndex);
	KvRewind(kv);
	KvGetString(kv, "filename", bossName, sizeof(bossName));

	if(KvJumpToKey(kv, "sounds"))
	{
		KvGotoFirstSubKey(kv);
		do
		{
			KvGetSectionName(kv, file, sizeof(file));
			Format(filePath, sizeof(filePath), "sound/%s", file);  //Sounds doesn't include the sound/ prefix, so add that
			if(FileExists(filePath, true))
			{
				PrecacheSound(file); // PrecacheSound is relative to the sounds/ folder
			}
			else
			{
				LogError("[FF2 Bosses] Character %s is missing file '%s'!", bossName, filePath);
			}

			if(KvGetNum(kv, "download"))
			{
				if(FileExists(filePath, true))
				{
					AddFileToDownloadsTable(filePath); // ...but AddFileToDownloadsTable isn't
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", bossName, filePath);
				}
			}
		}
		while(KvGotoNextKey(kv));
	}

	KvRewind(kv);
	if(KvJumpToKey(kv, "downloads"))
	{
		KvGotoFirstSubKey(kv);
		do
		{
			if(KvGetNum(kv, "precache"))
			{
				KvGetSectionName(kv, file, sizeof(file));
				Format(filePath, sizeof(filePath), "%s.mdl", file);  //Models specified in the config don't include an extension
				if(FileExists(filePath, true))
				{
					PrecacheModel(filePath);
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", bossName, filePath);
				}
			}
		}
		while(KvGotoNextKey(kv));
	}
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar==cvarPointDelay)
	{
		PointDelay=StringToInt(newValue);
	}
	else if(convar==cvarAnnounce)
	{
		Announce=StringToFloat(newValue);
	}
	else if(convar==cvarPointType)
	{
		PointType=StringToInt(newValue);
	}
	else if(convar==cvarPointDelay)
	{
		PointDelay=StringToInt(newValue);
	}
	else if(convar==cvarAliveToEnable)
	{
		AliveToEnable=StringToInt(newValue);
	}
	else if(convar==cvarCrits)
	{
		BossCrits=bool:StringToInt(newValue);
	}
	else if(convar==cvarArenaRounds)
	{
		arenaRounds=StringToInt(newValue);
	}
	else if(convar==cvarCircuitStun)
	{
		circuitStun=StringToFloat(newValue);
	}
	else if(convar==cvarCountdownPlayers)
	{
		countdownPlayers=StringToInt(newValue);
	}
	else if(convar==cvarCountdownTime)
	{
		countdownTime=StringToInt(newValue);
	}
	else if(convar==cvarCountdownHealth)
	{
		countdownHealth=StringToInt(newValue);
	}
	else if(convar==cvarLastPlayerGlow)
	{
		lastPlayerGlow=bool:StringToInt(newValue);
	}
	else if(convar==cvarSpecForceBoss)
	{
		SpecForceBoss=bool:StringToInt(newValue);
	}
	else if(convar==cvarBossTeleporter)
	{
		bossTeleportation=bool:StringToInt(newValue);
	}
	else if(convar==cvarShieldCrits)
	{
		shieldCrits=StringToInt(newValue);
	}
	else if(convar==cvarCaberDetonations)
	{
		allowedDetonations=StringToInt(newValue);
	}
	else if(convar==cvarUpdater)
	{
		#if defined _updater_included && !defined DEV_REVISION
		GetConVarInt(cvarUpdater) ? Updater_AddPlugin(UPDATE_URL) : Updater_RemovePlugin();
		#endif
	}
	else if(convar==cvarEnabled)
	{
		StringToInt(newValue) ? (changeGamemode=Enabled ? 0 : 1) : (changeGamemode=!Enabled ? 0 : 2);
	}
}

#if defined _smac_included
public Action:SMAC_OnCheatDetected(client, const String:module[], DetectionType:type, Handle:info)
{
	Debug("SMAC: Cheat detected!");
	if(type==Detection_CvarViolation)
	{
		Debug("SMAC: Cheat was a cvar violation!");
		decl String:cvar[PLATFORM_MAX_PATH];
		KvGetString(info, "cvar", cvar, sizeof(cvar));
		Debug("Cvar was %s", cvar);
		if((StrEqual(cvar, "sv_cheats") || StrEqual(cvar, "host_timescale")) && !(FF2Flags[Boss[client]] & FF2FLAG_CHANGECVAR))
		{
			Debug("SMAC: Ignoring violation");
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
#endif

public Action:Timer_Announce(Handle:timer)
{
	static announcecount=-1;
	announcecount++;
	if(Announce>1.0 && Enabled2)
	{
		switch(announcecount)
		{
			case 1:
			{
				CPrintToChatAll("%t", "VSH and FF2 Group");
			}
			case 3:
			{
				CPrintToChatAll("%t", "FF2 Contributors", PLUGIN_VERSION);
			}
			case 4:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "Type ff2 to Open Menu");
			}
			case 5:
			{
				announcecount=0;
				CPrintToChatAll("{olive}[FF2]{default} %t", "Last FF2 Update", PLUGIN_VERSION);
			}
			default:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "Type ff2 to Open Menu");
			}
		}
	}
	return Plugin_Continue;
}

stock bool:IsFF2Map()
{
	decl String:config[PLATFORM_MAX_PATH];
	GetCurrentMap(currentmap, sizeof(currentmap));
	if(FileExists("bNextMapToFF2"))
	{
		return true;
	}

	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2_SETTINGS, MAPS_CONFIG);
	if(!FileExists(config))
	{
		LogError("[FF2] Unable to find %s, disabling plugin.", config);
		return false;
	}

	new Handle:file=OpenFile(config, "r");
	if(file==INVALID_HANDLE)
	{
		LogError("[FF2] Error reading maps from %s, disabling plugin.", config);
		return false;
	}

	new tries;
	while(ReadFileLine(file, config, sizeof(config)) && tries<100)
	{
		tries++;
		if(tries==100)
		{
			LogError("[FF2] Breaking infinite loop when trying to check the map.");
			return false;
		}

		Format(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
		{
			continue;
		}

		if(!StrContains(currentmap, config, false) || !StrContains(config, "all", false))
		{
			CloseHandle(file);
			return true;
		}
	}
	CloseHandle(file);
	return false;
}

stock bool:MapHasMusic(bool:forceRecalc=false)  //SAAAAAARGE
{
	static bool:hasMusic;
	static bool:found;
	if(forceRecalc)
	{
		found=false;
		hasMusic=false;
	}

	if(!found)
	{
		new entity=-1;
		decl String:name[64];
		while((entity=FindEntityByClassname2(entity, "info_target"))!=-1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if(StrEqual(name, "hale_no_music", false))
			{
				hasMusic=true;
			}
		}
		found=true;
	}
	return hasMusic;
}

stock bool:CheckToChangeMapDoors()
{
	if(!Enabled || !Enabled2)
	{
		return;
	}

	decl String:config[PLATFORM_MAX_PATH];
	checkDoors=false;
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2_SETTINGS, DOORS_CONFIG);
	if(!FileExists(config))
	{
		if(!strncmp(currentmap, "vsh_lolcano_pb1", 15, false))
		{
			checkDoors=true;
		}
		return;
	}

	new Handle:file=OpenFile(config, "r");
	if(file==INVALID_HANDLE)
	{
		if(!strncmp(currentmap, "vsh_lolcano_pb1", 15, false))
		{
			checkDoors=true;
		}
		return;
	}

	while(!IsEndOfFile(file) && ReadFileLine(file, config, sizeof(config)))
	{
		Format(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
		{
			continue;
		}

		if(StrContains(currentmap, config, false)!=-1 || !StrContains(config, "all", false))
		{
			CloseHandle(file);
			checkDoors=true;
			return;
		}
	}
	CloseHandle(file);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(changeGamemode==1)
	{
		EnableFF2();
	}
	else if(changeGamemode==2)
	{
		DisableFF2();
	}

	if(!GetConVarBool(cvarEnabled))
	{
		#if defined _steamtools_included
		if(steamtools)
		{
			Steam_SetGameDescription("Team Fortress");
		}
		#endif
		Enabled2=false;
	}

	Enabled=Enabled2;
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	if(FileExists("bNextMapToFF2"))
	{
		DeleteFile("bNextMapToFF2");
	}

	new bool:blueBoss;
	switch(GetConVarInt(cvarForceBossTeam))
	{
		case 1:
		{
			blueBoss=bool:GetRandomInt(0, 1);
		}
		case 2:
		{
			blueBoss=false;
		}
		default:
		{
			blueBoss=true;
		}
	}

	if(blueBoss)
	{
		SetTeamScore(_:TFTeam_Red, GetTeamScore(_:OtherTeam));
		SetTeamScore(_:TFTeam_Blue, GetTeamScore(_:BossTeam));
		OtherTeam=TFTeam_Red;
		BossTeam=TFTeam_Blue;
	}
	else
	{
		SetTeamScore(_:TFTeam_Red, GetTeamScore(_:BossTeam));
		SetTeamScore(_:TFTeam_Blue, GetTeamScore(_:OtherTeam));
		OtherTeam=TFTeam_Blue;
		BossTeam=TFTeam_Red;
	}

	playing=0;
	for(new client=1; client<=MaxClients; client++)
	{
		Damage[client]=0;
		uberTarget[client]=-1;
		emitRageSound[client]=true;
		if(IsValidClient(client) && TF2_GetClientTeam(client)>TFTeam_Spectator)
		{
			playing++;
		}
	}

	if(GetClientCount()<=1 || playing<=1)  //Not enough players D:
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "More Players Needed");
		Enabled=false;
		//DisableSubPlugins();
		SetControlPoint(true);
		return Plugin_Continue;
	}
	else if(RoundCount<arenaRounds)  //We're still in arena mode
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "Arena Rounds Left", arenaRounds-RoundCount);  //Waiting for players to finish loading.  FF2 will start in {1} more rounds
		Enabled=false;
		//DisableSubPlugins();
		SetArenaCapEnableTime(60.0);
		CreateTimer(71.0, Timer_EnableCap, _, TIMER_FLAG_NO_MAPCHANGE);
		new bool:toRed;
		new TFTeam:team;
		for(new client; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && (team=TF2_GetClientTeam(client))>TFTeam_Spectator)
			{
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				if(toRed && team!=TFTeam_Red)
				{
					TF2_ChangeClientTeam(client, TFTeam_Red);
				}
				else if(!toRed && team!=TFTeam_Blue)
				{
					TF2_ChangeClientTeam(client, TFTeam_Blue);
				}
				SetEntProp(client, Prop_Send, "m_lifeState", 0);
				TF2_RespawnPlayer(client);
				toRed=!toRed;
			}
		}
		return Plugin_Continue;
	}

	for(new client; client<=MaxClients; client++)
	{
		Boss[client]=0;
		if(IsValidClient(client) && IsPlayerAlive(client) && !(FF2Flags[client] & FF2FLAG_HASONGIVED))
		{
			TF2_RespawnPlayer(client);
		}
	}

	Enabled=true;
	//EnableSubPlugins();
	CheckArena();

	new bool:omit[MaxClients+1];
	Boss[0]=GetClientWithMostQueuePoints(omit);
	omit[Boss[0]]=true;

	new bool:teamHasPlayers[TFTeam];
	for(new client=1; client<=MaxClients; client++)  //Find out if each team has at least one player on it
	{
		if(IsValidClient(client))
		{
			new TFTeam:team=TF2_GetClientTeam(client);
			if(team>TFTeam_Spectator)
			{
				teamHasPlayers[team]=true;
			}

			if(teamHasPlayers[TFTeam_Blue] && teamHasPlayers[TFTeam_Red])
			{
				break;
			}
		}
	}

	if(!teamHasPlayers[TFTeam_Blue] || !teamHasPlayers[TFTeam_Red])  //If there's an empty team make sure it gets populated
	{
		if(IsValidClient(Boss[0]) && TF2_GetClientTeam(Boss[0])!=BossTeam)
		{
			AssignTeam(Boss[0], BossTeam);
		}

		for(new client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !IsBoss(client) && TF2_GetClientTeam(client)!=OtherTeam)
			{
				CreateTimer(0.1, MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		return Plugin_Continue;  //NOTE: This is needed because OnRoundStart gets fired a second time once both teams have players
	}

	PickCharacter(0, 0);
	if((character[0]<0) || !GetArrayCell(bossesArray, character[0]))
	{
		LogError("[FF2 Bosses] Couldn't find a boss!");
		return Plugin_Continue;
	}

	FindCompanion(0, playing, omit);  //Find companions for the boss!

	for(new boss; boss<=MaxClients; boss++)
	{
		BossInfoTimer[boss][0]=INVALID_HANDLE;
		BossInfoTimer[boss][1]=INVALID_HANDLE;
		if(Boss[boss])
		{
			CreateTimer(0.3, MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
			BossInfoTimer[boss][0]=CreateTimer(30.2, BossInfoTimer_Begin, boss, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	CreateTimer(3.5, StartResponseTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.1, StartBossTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.6, MessageTimer, _, TIMER_FLAG_NO_MAPCHANGE);

	for(new entity=MaxClients+1; entity<MAXENTITIES; entity++)
	{
		if(!IsValidEntity(entity))
		{
			continue;
		}

		decl String:classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(StrEqual(classname, "func_regenerate"))
		{
			AcceptEntityInput(entity, "Kill");
		}
		else if(StrEqual(classname, "func_respawnroomvisualizer"))
		{
			AcceptEntityInput(entity, "Disable");
		}
	}

	healthcheckused=0;
	firstBlood=true;
	return Plugin_Continue;
}

public Action:Timer_EnableCap(Handle:timer)
{
	if((Enabled || Enabled2) && CheckRoundState()==FF2RoundState_Loading)
	{
		SetControlPoint(true);
		if(checkDoors)
		{
			new ent=-1;
			while((ent=FindEntityByClassname2(ent, "func_door"))!=-1)
			{
				AcceptEntityInput(ent, "Open");
				AcceptEntityInput(ent, "Unlock");
			}

			if(doorCheckTimer==INVALID_HANDLE)
			{
				doorCheckTimer=CreateTimer(5.0, Timer_CheckDoors, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:BossInfoTimer_Begin(Handle:timer, any:boss)
{
	BossInfoTimer[boss][0]=INVALID_HANDLE;
	BossInfoTimer[boss][1]=CreateTimer(0.2, BossInfoTimer_ShowInfo, boss, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:BossInfoTimer_ShowInfo(Handle:timer, any:boss)
{
	if(!IsValidClient(Boss[boss]))
	{
		BossInfoTimer[boss][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}

	if(bossHasReloadAbility[boss])
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		SetGlobalTransTarget(Boss[boss]);
		if(bossHasRightMouseAbility[boss])
		{
			FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t\n%t", "Ability uses Reload", "Ability uses Right Mouse");
		}
		else
		{
			FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t", "Ability uses Reload");
		}
	}
	else if(bossHasRightMouseAbility[boss])
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		SetGlobalTransTarget(Boss[boss]);
		FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t", "Ability uses Right Mouse");
	}
	else
	{
		BossInfoTimer[boss][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_CheckDoors(Handle:timer)
{
	if(!checkDoors)
	{
		doorCheckTimer=INVALID_HANDLE;
		return Plugin_Stop;
	}

	if((!Enabled && CheckRoundState()!=FF2RoundState_Loading) || (Enabled && CheckRoundState()!=FF2RoundState_RoundRunning))
	{
		return Plugin_Continue;
	}

	new entity=-1;
	while((entity=FindEntityByClassname2(entity, "func_door"))!=-1)
	{
		AcceptEntityInput(entity, "Open");
		AcceptEntityInput(entity, "Unlock");
	}
	return Plugin_Continue;
}

public CheckArena()
{
	if(PointType)
	{
		SetArenaCapEnableTime(float(45+PointDelay*(playing-1)));
	}
	else
	{
		SetArenaCapEnableTime(0.0);
		SetControlPoint(false);
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundCount++;

	if(!Enabled)
	{
		return Plugin_Continue;
	}

	executed=false;
	executed2=false;
	new bool:bossWin;
	decl String:sound[PLATFORM_MAX_PATH];
	if((TFTeam:GetEventInt(event, "team")==BossTeam))
	{
		bossWin=true;
		if(FindSound("win", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, Boss[0]);
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, Boss[0]);
		}
	}

	StopMusic();
	DrawGameTimer=INVALID_HANDLE;

	new bool:isBossAlive;
	for(new boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]))
		{
			SetClientGlow(Boss[boss], 0.0, 0.0);
			SDKUnhook(boss, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal
			if(IsPlayerAlive(Boss[boss]))
			{
				isBossAlive=true;
			}

			for(new slot=1; slot<8; slot++)
			{
				BossCharge[boss][slot]=0.0;
			}

			bossHasReloadAbility[boss]=false;
			bossHasRightMouseAbility[boss]=false;
		}
		else if(IsValidClient(boss))  //Boss here is actually a client index
		{
			SetClientGlow(boss, 0.0, 0.0);
			shield[boss]=0;
			detonations[boss]=0;
		}

		for(new timer; timer<=1; timer++)
		{
			if(BossInfoTimer[boss][timer]!=INVALID_HANDLE)
			{
				KillTimer(BossInfoTimer[boss][timer]);
				BossInfoTimer[boss][timer]=INVALID_HANDLE;
			}
		}
	}

	new boss;
	if(isBossAlive)
	{
		new String:text[128];  //Do not decl this
		decl String:bossName[64], String:lives[8];
		for(new target; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				boss=Boss[target];
				KvRewind(GetArrayCell(bossesArray, character[boss]));
				KvGetString(GetArrayCell(bossesArray, character[boss]), "name", bossName, sizeof(bossName), "=Failed name=");
				BossLives[boss]>1 ? Format(lives, sizeof(lives), "x%i", BossLives[boss]) : strcopy(lives, 2, "");
				Format(text, sizeof(text), "%s\n%t", text, "Boss Win Final Health", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
				CPrintToChatAll("{olive}[FF2]{default} %t", "Boss Win Final Health", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
			}
		}

		SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
		for(new client; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				FF2_ShowHudText(client, -1, "%s", text);
			}
		}

		if(!bossWin && FindSound("lose", sound, sizeof(sound), boss))
		{
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, Boss[0]);
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, Boss[0]);
		}
	}

	new top[3];
	Damage[0]=0;
	for(new client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || Damage[client]<=0 || IsBoss(client))
		{
			continue;
		}

		if(Damage[client]>=Damage[top[0]])
		{
			top[2]=top[1];
			top[1]=top[0];
			top[0]=client;
		}
		else if(Damage[client]>=Damage[top[1]])
		{
			top[2]=top[1];
			top[1]=client;
		}
		else if(Damage[client]>=Damage[top[2]])
		{
			top[2]=client;
		}
	}

	if(Damage[top[0]]>9000)
	{
		CreateTimer(1.0, Timer_NineThousand, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	decl String:leaders[3][32];
	for(new i; i<=2; i++)
	{
		if(IsValidClient(top[i]))
		{
			GetClientName(top[i], leaders[i], 32);
		}
		else
		{
			Format(leaders[i], 32, "---");
			top[i]=0;
		}
	}

	SetHudTextParams(-1.0, 0.3, 10.0, 255, 255, 255, 255);
	PrintCenterTextAll("");

	new String:text[128];  //Do not decl this
	for(new client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			//TODO:  Clear HUD text here
			if(IsBoss(client))
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "Top 3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], (bossWin ? "Boss Victory" : "Boss Defeat"));
			}
			else
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t\n%t", text, "Top 3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "Total Damage Dealt", Damage[client], "Points Earned", RoundFloat(Damage[client]/600.0));
			}
		}
	}

	CreateTimer(3.0, Timer_CalcQueuePoints, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
	return Plugin_Continue;
}

public Action:OnBroadcast(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:sound[PLATFORM_MAX_PATH];
    GetEventString(event, "sound", sound, sizeof(sound));
    if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:Timer_NineThousand(Handle:timer)
{
	EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, _, _, _, _, _, _, _, false);
	EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, _, _, _, _, _, _, _, false);
	return Plugin_Continue;
}

public Action:Timer_CalcQueuePoints(Handle:timer)
{
	new damage;
	botqueuepoints+=5;
	new add_points[MaxClients+1];
	new add_points2[MaxClients+1];
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			damage=Damage[client];
			new Handle:event=CreateEvent("player_escort_score", true);
			SetEventInt(event, "player", client);

			new points;
			while(damage-600>0)
			{
				damage-=600;
				points++;
			}
			SetEventInt(event, "points", points);
			FireEvent(event);

			if(IsBoss(client))
			{
				if(IsFakeClient(client))
				{
					botqueuepoints=0;
				}
				else
				{
					add_points[client]=-GetClientQueuePoints(client);
					add_points2[client]=add_points[client];
				}
			}
			else if(!IsFakeClient(client) && (TF2_GetClientTeam(client)>TFTeam_Spectator || SpecForceBoss))
			{
				add_points[client]=10;
				add_points2[client]=10;
			}
		}
	}

	new Action:action;
	Call_StartForward(OnAddQueuePoints);
	Call_PushArrayEx(add_points2, MaxClients+1, SM_PARAM_COPYBACK);
	Call_Finish(action);
	switch(action)
	{
		case Plugin_Stop, Plugin_Handled:
		{
			return;
		}
		case Plugin_Changed:
		{
			for(new client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					if(add_points2[client]>0)
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "Points Earned", add_points2[client]);
					}
					SetClientQueuePoints(client, GetClientQueuePoints(client)+add_points2[client]);
				}
			}
		}
		default:
		{
			for(new client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					if(add_points[client]>0)
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "Points Earned", add_points[client]);
					}
					SetClientQueuePoints(client, GetClientQueuePoints(client)+add_points[client]);
				}
			}
		}
	}
}

public Action:StartResponseTimer(Handle:timer)
{
	decl String:sound[PLATFORM_MAX_PATH];
	if(FindSound("begin", sound, sizeof(sound)))
	{
		EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
		EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
	}
	return Plugin_Continue;
}

public Action:StartBossTimer(Handle:timer)
{
	CreateTimer(0.1, Timer_Move, _, TIMER_FLAG_NO_MAPCHANGE);
	new bool:isBossAlive;
	for(new boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			isBossAlive=true;
			SetEntityMoveType(Boss[boss], MOVETYPE_NONE);
		}
	}

	if(!isBossAlive)
	{
		return Plugin_Continue;
	}

	playing=0;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsBoss(client) && IsPlayerAlive(client))
		{
			playing++;
			CreateTimer(0.15, MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);  //TODO:  Is this needed?
		}
	}

	CreateTimer(0.2, BossTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, StartRound, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_PrepareBGM, 0, TIMER_FLAG_NO_MAPCHANGE);

	if(!PointType)
	{
		SetControlPoint(false);
	}
	return Plugin_Continue;
}

public Action:Timer_PrepareBGM(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(CheckRoundState()!=FF2RoundState_RoundRunning || (!client && MapHasMusic()) || (!client && userid))
	{
		return Plugin_Stop;
	}

	if(!client)
	{
		for(client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				if(playBGM[client])
				{
					StopMusic(client);
					RequestFrame(PlayBGM, client); // Naydef: We might start playing the music before it gets stopped
				}
				else if(MusicTimer[client]!=INVALID_HANDLE)
				{
					KillTimer(MusicTimer[client]);
					MusicTimer[client]=INVALID_HANDLE;
				}
			}
			else if(MusicTimer[client]!=INVALID_HANDLE)
			{
				KillTimer(MusicTimer[client]);
				MusicTimer[client]=INVALID_HANDLE;
			}
		}
	}
	else
	{
		if(playBGM[client])
		{
			StopMusic(client);
			RequestFrame(PlayBGM, client); // Naydef: We might start playing the music before it gets stopped
		}
		else if(MusicTimer[client]!=INVALID_HANDLE)
		{
			KillTimer(MusicTimer[client]);
			MusicTimer[client]=INVALID_HANDLE;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

PlayBGM(client)
{
	new Handle:kv=GetArrayCell(bossesArray, character[0]);
	KvRewind(kv);
	if(KvJumpToKey(kv, "sounds"))
	{
		new Handle:musicArray=CreateArray(PLATFORM_MAX_PATH);
		new Handle:timeArray=CreateArray();
		decl String:music[PLATFORM_MAX_PATH];
		KvGotoFirstSubKey(kv);
		do
		{
			KvGetSectionName(kv, music, sizeof(music));
			new time=KvGetNum(kv, "time");
			if(time>0)
			{
				if(FindStringInArray(musicArray, music)>=0)
				{
					decl String:bossName[64];
					KvRewind(kv);
					KvGetString(kv, "name", bossName, sizeof(bossName));
					PrintToServer("[FF2 Bosses] Character %s has a duplicate sound '%s'!", bossName, music);
					continue; // We ignore all duplicates
				}
				PushArrayString(musicArray, music);
				PushArrayCell(timeArray, time);
			}
			else if(time<0)
			{
				decl String:bossName[64];
				KvRewind(kv);
				KvGetString(kv, "name", bossName, sizeof(bossName));
				PrintToServer("[FF2 Bosses] Character %s has an invalid time for sound '%s'!", bossName, music);
			}
		}
		while(KvGotoNextKey(kv));

		if(!GetArraySize(musicArray)) // No music found, exiting!
		{
			return;
		}
		new index=GetRandomInt(0, GetArraySize(musicArray)-1);

		new Action:action;
		Call_StartForward(OnMusic);
		decl String:temp[PLATFORM_MAX_PATH];
		new String:buffer[PLATFORM_MAX_PATH];
		new time2=GetArrayCell(timeArray, index);
		GetArrayString(musicArray, index, temp, sizeof(temp));
		Call_PushCell(client);
		Call_PushStringEx(temp, sizeof(temp), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCellRef(time2);
		Call_Finish(action);
		switch(action)
		{
			case Plugin_Stop, Plugin_Handled:
			{
				return;
			}
			case Plugin_Changed:
			{
				SetArrayString(musicArray, index, temp);
				SetArrayCell(timeArray, index, time2);
			}
		}

		GetArrayString(musicArray, index, buffer, sizeof(buffer));
		Format(temp, sizeof(temp), "sound/%s", buffer);
		if(FileExists(temp, true))
		{
			if(CheckSoundFlags(client, FF2SOUND_MUTEMUSIC))
			{
				GetArrayString(musicArray, index, currentBGM[client], sizeof(music));
				EmitSoundToClient(client, currentBGM[client]);
				MusicTimer[client]=CreateTimer(float(GetArrayCell(timeArray, index)), Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			decl String:bossName[64];
			KvRewind(kv);
			KvGetString(kv, "name", bossName, sizeof(bossName));
			PrintToServer("[FF2 Bosses] Character %s is missing BGM file '%s'!", bossName, music);
		}
	}
}

StartMusic(client=0)
{
	if(client<=0)  //Start music for all clients
	{
		StopMusic();
		for(new target; target<=MaxClients; target++)
		{
			playBGM[target]=true;  //This includes the 0th index
		}
		CreateTimer(0.1, Timer_PrepareBGM, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		StopMusic(client);
		playBGM[client]=true;
		CreateTimer(0.1, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

StopMusic(client=0, bool:permanent=false)
{
	if(client<=0)  //Stop music for all clients
	{
		if(permanent)
		{
			playBGM[0]=false;
		}

		for(client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				StopSound(client, SNDCHAN_AUTO, currentBGM[client]);

				if(MusicTimer[client]!=INVALID_HANDLE)
				{
					KillTimer(MusicTimer[client]);
					MusicTimer[client]=INVALID_HANDLE;
				}
			}

			strcopy(currentBGM[client], PLATFORM_MAX_PATH, "");
			if(permanent)
			{
				playBGM[client]=false;
			}
		}
	}
	else
	{
		StopSound(client, SNDCHAN_AUTO, currentBGM[client]);
		StopSound(client, SNDCHAN_AUTO, currentBGM[client]);

		if(MusicTimer[client]!=INVALID_HANDLE)
		{
			KillTimer(MusicTimer[client]);
			MusicTimer[client]=INVALID_HANDLE;
		}

		strcopy(currentBGM[client], PLATFORM_MAX_PATH, "");
		if(permanent)
		{
			playBGM[client]=false;
		}
	}
}

stock EmitSoundToAllExcept(soundFlags, const String:sample[], entity=SOUND_FROM_PLAYER, channel=SNDCHAN_AUTO, level=SNDLEVEL_NORMAL, flags=SND_NOFLAGS, Float:volume=SNDVOL_NORMAL, pitch=SNDPITCH_NORMAL, speakerentity=-1, const Float:origin[3]=NULL_VECTOR, const Float:dir[3]=NULL_VECTOR, bool:updatePos=true, Float:soundtime=0.0)
{
	new clients[MaxClients+1], total;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsClientInGame(client))
		{
			if(CheckSoundFlags(client, soundFlags))
			{
				clients[total++]=client;
			}
		}
	}

	if(!total)
	{
		return;
	}

	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

public bool:CheckSoundFlags(client, soundFlags)
{
	if(!IsValidClient(client))
	{
		return false;
	}

	if(IsFakeClient(client))
	{
		return false;
	}

	if(muteSound[client] & soundFlags)
	{
		return false;
	}
	return true;
}

public SetSoundFlags(client, soundFlags)
{
	if(!IsValidClient(client) || IsFakeClient(client))
	{
		return;
	}

	decl String:buffer[5];
	GetClientCookie(client, FF2Cookie_MuteSound, buffer, sizeof(buffer));
	IntToString((StringToInt(buffer) | soundFlags), buffer, sizeof(buffer));
	SetClientCookie(client, FF2Cookie_MuteSound, buffer);
	muteSound[client] |= soundFlags;
}

public ClearSoundFlags(client, soundFlags)
{
	if(!IsValidClient(client) || IsFakeClient(client))
	{
		return;
	}

	decl String:buffer[5];
	GetClientCookie(client, FF2Cookie_MuteSound, buffer, sizeof(buffer));
	IntToString((StringToInt(buffer) & ~soundFlags), buffer, sizeof(buffer));
	SetClientCookie(client, FF2Cookie_MuteSound, buffer);
	muteSound[client]&=~soundFlags;
}

public Action:Timer_Move(Handle:timer)
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}

public Action:StartRound(Handle:timer)
{
	CreateTimer(10.0, Timer_NextBossPanel, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
	return Plugin_Handled;
}

public Action:Timer_NextBossPanel(Handle:timer)
{
	new clients;
	new bool:added[MaxClients+1];
	while(clients<3)  //TODO: Make this configurable?
	{
		new client=GetClientWithMostQueuePoints(added);
		if(!IsValidClient(client))  //No more players left on the server
		{
			break;
		}

		if(!IsBoss(client))
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "Next Boss");  //"You will become the Boss soon. Type {olive}/ff2next{default} to make sure."
			clients++;
		}
		added[client]=true;
	}
}

public Action:MessageTimer(Handle:timer)
{
	if(CheckRoundState()!=FF2RoundState_Setup)
	{
		return Plugin_Continue;
	}

	if(checkDoors)
	{
		new entity=-1;
		while((entity=FindEntityByClassname2(entity, "func_door"))!=-1)
		{
			AcceptEntityInput(entity, "Open");
			AcceptEntityInput(entity, "Unlock");
		}

		if(doorCheckTimer==INVALID_HANDLE)
		{
			doorCheckTimer=CreateTimer(5.0, Timer_CheckDoors, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
	new String:text[512];  //Do not decl this
	decl String:textChat[512];
	decl String:lives[8];
	decl String:name[64];
	for(new client; client<=MaxClients; client++)
	{
		if(IsBoss(client))
		{
			new boss=Boss[client];
			KvRewind(GetArrayCell(bossesArray, character[boss]));
			KvGetString(GetArrayCell(bossesArray, character[boss]), "name", name, sizeof(name), "=Failed name=");
			if(BossLives[boss]>1)
			{
				Format(lives, sizeof(lives), "x%i", BossLives[boss]);
			}
			else
			{
				strcopy(lives, 2, "");
			}

			Format(text, sizeof(text), "%s\n%t", text, "Boss Info", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
			Format(textChat, sizeof(textChat), "{olive}[FF2]{default} %t!", "Boss Info", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
			ReplaceString(textChat, sizeof(textChat), "\n", "");  //Get rid of newlines
			CPrintToChatAll("%s", textChat);
		}
	}

	for(new client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			FF2_ShowSyncHudText(client, infoHUD, text);
		}
	}
	return Plugin_Continue;
}

public Action:MakeModelTimer(Handle:timer, any:boss)
{
	new client=Boss[boss];
	if(IsValidClient(client) && IsPlayerAlive(client) && CheckRoundState()!=FF2RoundState_RoundEnd)
	{
		decl String:model[PLATFORM_MAX_PATH];
		KvRewind(GetArrayCell(bossesArray, character[boss]));
		KvGetString(GetArrayCell(bossesArray, character[boss]), "model", model, sizeof(model));
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

EquipBoss(boss)
{
	new client=Boss[boss];
	DoOverlay(client, "");
	TF2_RemoveAllWeapons(client);
	decl String:classname[64], String:attributes[256], String:bossName[64];

	new Handle:kv=GetArrayCell(bossesArray, character[boss]);
	KvRewind(kv);
	KvGetString(kv, "name", bossName, sizeof(bossName), "=Failed Name=");
	if(KvJumpToKey(kv, "weapons"))
	{
		KvGotoFirstSubKey(kv);
		do
		{
			decl String:sectionName[32];
			KvGetSectionName(kv, sectionName, sizeof(sectionName));
			new index=StringToInt(sectionName);
			//NOTE: StringToInt returns 0 on failure which corresponds to tf_weapon_bat,
			//so there's no way to distinguish between an invalid string and 0.
			//Blocked on bug 6438: https://bugs.alliedmods.net/show_bug.cgi?id=6438
			if(index>=0)
			{
				KvJumpToKey(kv, sectionName);
				KvGetString(kv, "classname", classname, sizeof(classname));
				if(classname[0]=='\0')
				{
					LogError("[FF2 Bosses] No classname specified for weapon %i (character %s)!", index, bossName);
					continue;
				}

				KvGetString(kv, "attributes", attributes, sizeof(attributes));
				if(attributes[0]!='\0')
				{
					Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1 ; %s", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2 , attributes);
						//68: +2 cap rate
						//2: x3.1 damage
				}
				else
				{
					Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2);
						//68: +2 cap rate
						//2: x3.1 damage
				}

				new weapon=SpawnWeapon(client, classname, index, 101, 5, attributes);
				if(StrEqual(classname, "tf_weapon_builder", false) && index!=735)  //PDA, normal sapper
				{
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
				}
				else if(StrEqual(classname, "tf_weapon_sapper", false) || index==735)  //Sappers
				{
					SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
					SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
				}

				if(!KvGetNum(kv, "show", 0))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
				}
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
			}
			else
			{
				LogError("[FF2 Bosses] Invalid weapon index %s specified for character %s!", sectionName, bossName);
			}
		}
		while(KvGotoNextKey(kv));
	}

	KvRewind(kv);
	new TFClassType:class=TFClassType:KvGetNum(kv, "class", 1);
	if(TF2_GetPlayerClass(client)!=class)
	{
		TF2_SetPlayerClass(client, class, _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	}
}

public Action:MakeBoss(Handle:timer, any:boss)
{
	new client=Boss[boss];
	if(!IsValidClient(client) || CheckRoundState()==FF2RoundState_Loading)
	{
		return Plugin_Continue;
	}

	if(!IsPlayerAlive(client))
	{
		if(CheckRoundState()==FF2RoundState_Setup)
		{
			TF2_RespawnPlayer(client);
		}
		else
		{
			return Plugin_Continue;
		}
	}

	new Handle:kv=GetArrayCell(bossesArray, character[boss]);
	KvRewind(kv);
	if(TF2_GetClientTeam(client)!=BossTeam)
	{
		AssignTeam(client, BossTeam);
	}

	BossHealthMax[boss]=ParseFormula(boss, "health", RoundFloat(Pow((760.8+float(playing))*(float(playing)-1.0), 1.0341)+2046.0));
	BossLivesMax[boss]=BossLives[boss]=ParseFormula(boss, "lives", 1);
	BossHealth[boss]=BossHealthLast[boss]=BossHealthMax[boss]*BossLivesMax[boss];
	BossRageDamage[boss]=ParseFormula(boss, "rage damage", 1900);
	BossSpeed[boss]=float(ParseFormula(boss, "speed", 340));

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	TF2_RemovePlayerDisguise(client);
	TF2_SetPlayerClass(client, TFClassType:KvGetNum(kv, "class", 1), _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal

	switch(KvGetNum(kv, "pickups", 0))  //Check if the boss is allowed to pickup health/ammo
	{
		case 1:
		{
			FF2Flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS;
		}
		case 2:
		{
			FF2Flags[client]|=FF2FLAG_ALLOW_AMMO_PICKUPS;
		}
		case 3:
		{
			FF2Flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
		}
	}

	CreateTimer(0.2, MakeModelTimer, boss, TIMER_FLAG_NO_MAPCHANGE);
	if(!IsVoteInProgress() && GetClientClassInfoCookie(client))
	{
		HelpPanelBoss(boss);
	}

	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	new entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_wear*"))!=-1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		{
			switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items
				{
					//NOOP
				}
				default:
				{
					TF2_RemoveWearable(client, entity);
				}
			}
		}
	}

	entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle"))!=-1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		{
			TF2_RemoveWearable(client, entity);
		}
	}

	EquipBoss(boss);
	KSpreeCount[boss]=0;
	BossCharge[boss][0]=0.0;
	SetClientQueuePoints(client, 0);
	return Plugin_Continue;
}

/*Soon(TM)
CreateWeaponModsKeyValues()
{
	if(kvWeaponSpecials!=INVALID_HANDLE)
	{
		CloseHandle(kvWeaponSpecials);
	}

	kvWeaponSpecials=CreateKeyValues("WeaponSpecials");
	for(new i=0; i<sizeof(WeaponSpecials); i++)
	{
		KvJumpToKey(kvWeaponSpecials, WeaponSpecials[i], true);

		KvJumpToKey(kvWeaponSpecials, "ByClassname", true);
		KvGoBack(kvWeaponSpecials);

		KvJumpToKey(kvWeaponSpecials, "ByIndex", true);
		KvGoBack(kvWeaponSpecials);

		KvGoBack(kvWeaponSpecials);
	}
}*/

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:item)
{
	if(!Enabled /*|| item!=INVALID_HANDLE*/)
	{
		return Plugin_Continue;
	}

	//TODO: "onhit", "ontakedamage"
	//TODO: Also support comma-delimited strings, eg "38, 457" or "tf_weapon_knife, tf_weapon_katana"
	static Handle:weapon;
	if(weapon!=INVALID_HANDLE)
	{
		CloseHandle(weapon);
		weapon=INVALID_HANDLE;
	}

	if(!IsBoss(client))
	{
		decl String:itemString[8];
		IntToString(iItemDefinitionIndex, itemString, sizeof(itemString));

		KvRewind(kvWeaponMods);
		new bool:differentClass;
		if(KvJumpToKey(kvWeaponMods, classname) || KvJumpToKey(kvWeaponMods, itemString))
		{
			Debug("Entered classname %s or index %i", classname, iItemDefinitionIndex);
			if(KvJumpToKey(kvWeaponMods, "replace"))
			{
				Debug("\tEntered replace");
				new String:newClass[64];
				KvGetString(kvWeaponMods, "classname", newClass, sizeof(newClass));
				Debug("\t\tNew classname is %s", newClass);

				new flags=OVERRIDE_ITEM_DEF|OVERRIDE_ATTRIBUTES|FORCE_GENERATION;
				new index=KvGetNum(kvWeaponMods, "index", -1);
				if(index<0)
				{
					LogError("[FF2 Weapons] \"replace\" is missing item definition index for classname %s or index %i!", classname, iItemDefinitionIndex);
					return Plugin_Stop;
				}

				if(!StrEqual(classname, newClass))
				{
					flags|=OVERRIDE_CLASSNAME;
					differentClass=true;
					strcopy(classname, 64, newClass);
				}

				new level=KvGetNum(kvWeaponMods, "level", -1);
				if(level>-1)
				{
					flags|=OVERRIDE_ITEM_LEVEL;
				}
				else if(differentClass)  //If level wasn't set and we're switching classnames automatically set the level to 1
				{
					level=1;
				}

				new quality=KvGetNum(kvWeaponMods, "quality", -1);
				if(quality>-1)
				{
					flags|=OVERRIDE_ITEM_QUALITY;
				}
				else if(differentClass)  //Ditto here
				{
					quality=0;
				}

				weapon=TF2Items_CreateItem(flags);
				TF2Items_SetClassname(weapon, classname);
				TF2Items_SetQuality(weapon, quality);
				TF2Items_SetLevel(weapon, level);
				Debug("\t\tGave new weapon with classname %s, index %i, quality %i, and level %i", classname, index, quality, level);
				new entity=TF2Items_GiveNamedItem(client, weapon);
				EquipPlayerWeapon(client, entity);

				CloseHandle(weapon);
				weapon=INVALID_HANDLE;

				KvGoBack(kvWeaponMods);
			}

			if(KvJumpToKey(kvWeaponMods, "add"))
			{
				Debug("\tEntered add");
				decl String:attributes[32][8];
				new attribCount;
				for(new key; KvGotoNextKey(kvWeaponMods); key+=2)
				{
					if(key>=32)
					{
						LogError("[FF2 Weapons] Weapon %s (index %i) has more than 16 attributes, ignoring the rest", classname, iItemDefinitionIndex);
						break;
					}

					attribCount++;
					KvGetSectionName(kvWeaponMods, attributes[key], 8);
					KvGetString(kvWeaponMods, attributes[key], attributes[key+1], 8);
					Debug("\t\tAttribute set %i is %s ; %s", attribCount, attributes[key], attributes[key+1]);
				}

				if(attribCount)
				{
					new entity=FindEntityByClassname(-1, classname);
					for(new attribute; attribute<attribCount; attribute+=2)
					{
						new attrib=StringToInt(attributes[attribute]);
						if(!attrib)  //StringToInt will return 0 on failure, which probably means the attribute was specified by name, not index
						{
							TF2Attrib_SetByName(entity, attributes[attribute], StringToFloat(attributes[attribute+1]));
							Debug("\t\tAdded attribute set %s ; %s", attributes[attribute], attributes[attribute+1]);
						}
						else if(attrib<0)
						{
							LogError("[FF2 Weapons] Ignoring attribute %i passed for weapon %s (index %i) while adding attributes", attrib, classname, iItemDefinitionIndex);
						}
						else
						{
							TF2Attrib_SetByDefIndex(entity, attrib, StringToFloat(attributes[attribute+1]));
							Debug("\t\tAdded attribute set %s ; %s", attributes[attribute], attributes[attribute+1]);
						}
					}
				}
				KvGoBack(kvWeaponMods);
			}

			if(KvJumpToKey(kvWeaponMods, "remove"))
			{
				Debug("\tEntered remove");
				decl String:attributes[16][8];
				new entity=FindEntityByClassname(-1, classname);
				for(new key; KvGotoNextKey(kvWeaponMods) && key<16; key++)
				{
					KvGetSectionName(kvWeaponMods, attributes[key], 8);
					new attribute=StringToInt(attributes[key]);
					if(!attribute)  //StringToInt will return 0 on failure, which probably means the attribute was specified by name, not index
					{
						if(StrEqual(attributes[key], "all"))
						{
							TF2Attrib_RemoveAll(entity);
							Debug("\t\tRemoved all attributes");
							break;  //Just exit the for loop since we've already removed all attributes
						}
						else
						{
							TF2Attrib_RemoveByName(entity, attributes[key]);
							Debug("\t\tRemoved attribute %s", attributes[key]);
						}
					}
					else if(attribute<0)
					{
						LogError("[FF2 Weapons] Ignoring attribute %s passed for weapon %s (index %i) while removing attributes", attributes[key], classname, iItemDefinitionIndex);
					}
					else
					{
						TF2Attrib_RemoveByDefIndex(entity, attribute);
						Debug("\t\tRemoved attribute %i", attribute);
					}
				}
				KvGoBack(kvWeaponMods);
			}

			/*if(KvJumpToKey(kvWeaponMods, "remove"))  //TODO: remove-all (TF2Attrib)
			{
				Debug("\tEntered remove");
				if(KvGotoFirstSubKey(kvWeaponMods, false))
				{
					Debug("\t\tEntered first subkey");
					decl attributes[64];
					new attribCount=1;

					attributes[0]=KvGetNum(kvWeaponMods, "1");
					Debug("\t\tKeyvalues classname>removeattribs: First attrib was %i", attributes[0]);

					for(new key=2; KvGotoNextKey(kvWeaponMods, false); key++)
					{
						decl String:temp[4];
						IntToString(key, temp, sizeof(temp));
						attributes[key]=KvGetNum(kvWeaponMods, temp);
						Debug("\t\tKeyvalues classname>removeattribs: Got attrib %i", attributes[key]);
						attribCount++;
					}
					Debug("\t\tFinal attrib count was %i", attribCount);

					if(attribCount>0)
					{
						new i=0;
						for(new attribute=0; attribute<attribCount && i<16; attribute++)
						{
							if(!attributes[attribute])
							{
								LogError("[FF2 Weapons] Bad weapon attribute passed for weapon %s", classname);
								CloseHandle(weapon);
								weapon=INVALID_HANDLE;
								return Plugin_Stop;
							}

							Debug("\t\tRemoved attribute %i", attributes[attribute]);
							new entity=FindEntityByClassname(-1, classname);
							if(entity!=-1)
							{
								TF2Attrib_RemoveByDefIndex(entity, attributes[attribute]);
							}
							i++;
						}
					}
				}
				else
				{
					LogError("[FF2 Weapons] There was nothing under \"remove\" for classname %s!", classname);
				}
				KvGoBack(kvWeaponMods);
			}*/

			/*if(KvJumpToKey(kvWeaponMods, "add"))  //TODO: Preserve attributes
			{
				if(KvGotoFirstSubKey(kvWeaponMods, false))
				{
					Debug("\t\tEntered first subkey");
					new String:attributes[64][64];
					new attribCount=1;

					KvGetSectionName(kvWeaponMods, attributes[0], sizeof(attributes));
					KvGetString(kvWeaponMods, attributes[0], attributes[1], sizeof(attributes));
					Debug("\t\tFirst attrib set was %s ; %s", attributes[0], attributes[1]);

					for(new key=3; KvGotoNextKey(kvWeaponMods); key+=2)
					{
						KvGetSectionName(kvWeaponMods, attributes[key], sizeof(attributes));
						KvGetString(kvWeaponMods, attributes[key], attributes[key+1], sizeof(attributes));
						Debug("\t\tGot attrib set %s ; %s", attributes[key], attributes[key+1]);
						attribCount++;
					}
					Debug("\t\tFinal attrib count was %i", attribCount);

					if(attribCount%2!=0)
					{
						attribCount--;
					}

					if(attribCount>0)
					{
						new i=0;
						for(new attribute=0; attribute<attribCount && i<16; attribute+=2)
						{
							new attrib=StringToInt(attributes[attribute]);
							if(attrib==0)
							{
								LogError("[FF2 Weapons] Bad weapon attribute passed for weapon %s: %s ; %s", classname, attributes[attribute], attributes[attribute+1]);
								CloseHandle(weapon);
								weapon=INVALID_HANDLE;
								return Plugin_Stop;
							}

							Debug("\t\tKeyvalues classname>addattribs: Added attrib set %s ; %s", attributes[attribute], attributes[attribute+1]);
							new entity=FindEntityByClassname(-1, classname);
							{  //FIXME: THIS BRACKET
								TF2Attrib_SetByDefIndex(entity, StringToInt(attributes[attribute]), StringToFloat(attributes[attribute+1]));
							}
							i++;
						}
					}
				}
				else
				{
					LogError("[FF2 Weapons] There was nothing under \"Addattribs\" for classname %s!", classname);
				}
				KvGoBack(kvWeaponMods);
			}*/
		}

		/*if(differentClass)
		{
			Debug("Keyvalues differentClass: Gave weapon!");
			TF2Items_GiveNamedItem(client, weapon);
			CloseHandle(weapon);
			weapon=INVALID_HANDLE;
			return Plugin_Stop;
		}*/
	}

	switch(iItemDefinitionIndex)
	{
		case 38, 457:  //Axtinguisher, Postal Pummeler
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "", false);
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 39, 351, 1081:  //Flaregun, Detonator, Festive Flaregun
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "25 ; 0.5 ; 58 ; 3.2 ; 144 ; 1.0 ; 207 ; 1.33", false);
				//25: -50% ammo
				//58: 220% self damage force
				//144: NOPE
				//207: +33% damage to self
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 40, 1146:  //Backburner, Festive Backburner
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "165 ; 1.0");
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 224:  //L'etranger
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "85 ; 0.5 ; 157 ; 1.0 ; 253 ; 1.0");
				//85: +50% time needed to regen cloak
				//157: +1 second needed to fully disguise
				//253: +1 second needed to fully cloak
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 239, 1084, 1100:  //GRU, Festive GRU, Bread Bite
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 191 ; -7 ; 772 ; 1.5", false);
				//1: -50% damage
				//107: +50% move speed
				//128: Only when weapon is active
				//191: -7 health/second
				//772: Holsters 50% slower
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 56, 1005, 1092:  //Huntsman, Festive Huntsman, Fortified Compound
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.5 ; 76 ; 2");
				//2: +50% damage
				//76: +100% ammo
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		/*case 132, 266, 482:  //Eyelander, HHHH, Nessie's Nine Iron - commented out because
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "202 ; 0.5 ; 125 ; -15", false);
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}*/
		case 226:  //Battalion's Backup
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "140 ; 10.0");
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 231:  //Darwin's Danger Shield
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "26 ; 50");  //+50 health
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 305, 1079:  //Crusader's Crossbow, Festive Crusader's Crossbow
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.2 ; 17 ; 0.15");
				//2: +20% damage
				//17: +15% uber on hit
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 331:  //Fists of Steel
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "205 ; 0.8 ; 206 ; 2.0 ; 772 ; 2.0", false);
				//205: -80% damage from ranged while active
				//206: +100% damage from melee while active
				//772: Holsters 100% slower
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 415:  //Reserve Shooter
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1 ; 3 ; 0.5 ; 114 ; 1 ; 179 ; 1 ; 547 ; 0.6", false);
				//2: +10% damage bonus
				//3: -50% clip size
				//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
				//179: Minicrits become crits
				//547: Deploys 40% faster
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 444:  //Mantreads
		{
			TF2Attrib_SetByDefIndex(client, 58, 1.5);
		}
		case 648:  //Wrap Assassin
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "279 ; 2.0");
				//279: 2 ornaments
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 656:  //Holiday Punch
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "199 ; 0 ; 547 ; 0 ; 358 ; 0 ; 362 ; 0 ; 363 ; 0 ; 369 ; 0", false);
				//199: Holsters 100% faster
				//547: Deploys 100% faster
				//Other attributes: Because TF2Items doesn't feel like stripping the Holiday Punch's attributes for some reason
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 772:  //Baby Face's Blaster
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.25 ; 109 ; 0.5 ; 125 ; -25 ; 394 ; 0.85 ; 418 ; 1 ; 419 ; 100 ; 532 ; 0.5 ; 651 ; 0.5 ; 709 ; 1", false);
				//2: +25% damage bonus
				//109: -50% health from packs on wearer
				//125: -25 max health
				//394: 15% firing speed bonus hidden
				//418: Build hype for faster speed
				//419: Hype resets on jump
				//532: Hype decays
				//651: Fire rate increases as health decreases
				//709: Weapon spread increases as health decreases
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 1103:  //Back Scatter
		{
			new Handle:itemOverride=PrepareItemHandle(item, _, _, "179 ; 1");
				//179: Crit instead of mini-critting
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
	}

	if(TF2_GetPlayerClass(client)==TFClass_Soldier && (!StrContains(classname, "tf_weapon_rocketlauncher", false) || !StrContains(classname, "tf_weapon_shotgun", false)))
	{
		new Handle:itemOverride;
		if(iItemDefinitionIndex==127)  //Direct Hit
		{
			itemOverride=PrepareItemHandle(item, _, _, "114 ; 1 ; 179 ; 1.0");
				//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
				//179: Mini-crits become crits
		}
		else
		{
			itemOverride=PrepareItemHandle(item, _, _, "114 ; 1");
				//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
		}

		if(itemOverride!=INVALID_HANDLE)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}

	if(!StrContains(classname, "tf_weapon_syringegun_medic"))  //Syringe guns
	{
		new Handle:itemOverride=PrepareItemHandle(item, _, _, "17 ; 0.05 ; 144 ; 1", false);
			//17: 5% uber on hit
			//144: Sets weapon mode - *possibly* the overdose speed effect
		if(itemOverride!=INVALID_HANDLE)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	else if(!StrContains(classname, "tf_weapon_medigun"))  //Mediguns
	{
		new Handle:itemOverride=PrepareItemHandle(item, _, _, "10 ; 1.75 ; 11 ; 1.5 ; 144 ; 2.0 ; 199 ; 0.75 ; 314 ; 4 ; 547 ; 0.75", false);
			//10: +75% faster charge rate
			//11: +50% overheal bonus
			//144: Quick-fix speed/jump effects
			//199: Deploys 25% faster
			//314: Ubercharge lasts 4 seconds longer (aka 50% longer)
			//547: Holsters 25% faster
		if(itemOverride!=INVALID_HANDLE)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:Timer_NoHonorBound(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		new melee=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		new index=((IsValidEntity(melee) && melee>MaxClients) ? GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex") : -1);
		new weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new String:classname[64];
		if(IsValidEntity(weapon))
		{
			GetEntityClassname(weapon, classname, sizeof(classname));
		}
		if(index==357 && weapon==melee && StrEqual(classname, "tf_weapon_katana", false))
		{
			SetEntProp(melee, Prop_Send, "m_bIsBloody", 1);
			if(GetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy")<1)
			{
				SetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
			}
		}
	}
}

/*
 * Prepares a new item handle based on an existing one
 *
 * @param item			Existing item handle
 * @param classname		Classname of the weapon
 * @param index			Index of the weapon
 * @param attributeList	String of attributes in a 'name ; value' pattern (optional)
 * @param preserve		Whether to preserve existing attributes or to overwrite them
 *
 * @return				Item handle on success, INVALID_HANDLE on failure
 */
stock Handle:PrepareItemHandle(Handle:item, String:classname[]="", index=-1, const String:attributeList[]="", bool:preserve=true)
{
	// TODO: This duplicates a whole lot of logic in SpawnWeapon
	static Handle:weapon;
	new addattribs;

	new String:attributes[32][32];
	new count=ExplodeString(attributeList, ";", attributes, 32, 32);

	if(count==1) // ExplodeString returns the original string if no matching delimiter was found so we need to special-case this
	{
		if(attributeList[0]!='\0') // Ignore empty attribute list
		{
			LogError("[FF2 Weapons] Unbalanced attributes array '%s' for weapon %s", attributeList, classname);
			if(weapon!=INVALID_HANDLE)
			{
				CloseHandle(weapon);
				weapon=INVALID_HANDLE;
			}
			return weapon;
		}
		else
		{
			count=0;
		}
	}
	else if(count % 2) // Unbalanced array, eg "2 ; 10 ; 3"
	{
		LogError("[FF2 Weapons] Unbalanced attributes array %s for weapon %s", attributeList, classname);
		if(weapon!=INVALID_HANDLE)
		{
			CloseHandle(weapon);
			weapon=INVALID_HANDLE;
		}
		return weapon;
	}

	new flags=OVERRIDE_ATTRIBUTES;
	if(preserve)
	{
		flags|=PRESERVE_ATTRIBUTES;
	}

	if(weapon==INVALID_HANDLE)
	{
		weapon=TF2Items_CreateItem(flags);
	}
	else
	{
		TF2Items_SetFlags(weapon, flags);
	}

	if(item!=INVALID_HANDLE)
	{
		addattribs=TF2Items_GetNumAttributes(item);
		if(addattribs>0)
		{
			for(new i; i<2*addattribs; i+=2)
			{
				new bool:dontAdd;
				new attribIndex=TF2Items_GetAttributeId(item, i);
				for(new z; z<count+i; z+=2)
				{
					if(StringToInt(attributes[z])==attribIndex)
					{
						dontAdd=true;
						break;
					}
				}

				if(!dontAdd)
				{
					IntToString(attribIndex, attributes[i+count], 32);
					FloatToString(TF2Items_GetAttributeValue(item, i), attributes[i+1+count], 32);
				}
			}
			count+=2*addattribs;
		}

		if(weapon!=item)  //FlaminSarge: Item might be equal to weapon, so closing item's handle would also close weapon's
		{
			CloseHandle(item);  //probably returns false but whatever (rswallen-apparently not)
		}
	}

	if(classname[0]!='\0')
	{
		flags|=OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(weapon, classname);
	}

	if(index!=-1)
	{
		flags|=OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(weapon, index);
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		new i2;
		for(new i; i<count && i2<16; i+=2)
		{
			new attrib=StringToInt(attributes[i]);
			if(!attrib)
			{
				LogError("[FF2 Weapons] Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				CloseHandle(weapon);
				weapon=INVALID_HANDLE;
				return weapon;
			}

			TF2Items_SetAttribute(weapon, i2, StringToInt(attributes[i]), StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}
	TF2Items_SetFlags(weapon, flags);
	return weapon;
}

public Action:MakeNotBoss(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==FF2RoundState_RoundEnd || IsBoss(client) || (FF2Flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		return Plugin_Continue;
	}

	if(!IsVoteInProgress() && GetClientClassInfoCookie(client) && !(FF2Flags[client] & FF2FLAG_CLASSHELPED))
	{
		HelpPanelClass(client);
	}

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);  //This really shouldn't be needed but I've been noticing players who still have glow

	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client)); //Temporary: Reset health to avoid an overheal bug
	if(TF2_GetClientTeam(client)==BossTeam)
	{
		AssignTeam(client, OtherTeam);
	}

	CreateTimer(0.1, CheckItems, userid, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:CheckItems(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==FF2RoundState_RoundEnd || IsBoss(client) || (FF2Flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		return Plugin_Continue;
	}

	SetEntityRenderColor(client, 255, 255, 255, 255);
	shield[client]=0;
	new index=-1;
	new civilianCheck[MaxClients+1];

	//Cloak and Dagger is NEVER allowed, even in Medieval mode
	new weapon=GetPlayerWeaponSlot(client, 4);
	if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==60)  //Cloak and Dagger
	{
		TF2_RemoveWeaponSlot(client, 4);
		SpawnWeapon(client, "tf_weapon_invis", 30);
	}

	if(bMedieval)
	{
		return Plugin_Continue;
	}

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(weapon))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(index)
		{
			case 41:  //Natascha
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				SpawnWeapon(client, "tf_weapon_minigun", 15);
			}
			case 237:  //Rocket Jumper
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				SpawnWeapon(client, "tf_weapon_rocketlauncher", 18, 1, 0, "114 ; 1");
					//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
				FF2_SetAmmo(client, weapon, 20);
			}
			case 402:  //Bazaar Bargain
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				SpawnWeapon(client, "tf_weapon_sniperrifle", 14);
			}
		}
	}
	else
	{
		civilianCheck[client]++;
	}

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(weapon))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(index)
		{
			case 265:  //Stickybomb Jumper
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				SpawnWeapon(client, "tf_weapon_pipebomblauncher", 20);
				FF2_SetAmmo(client, weapon, 24);
			}
		}

		if(TF2_GetPlayerClass(client)==TFClass_Medic)
		{
			if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee)==142)  //Gunslinger (Randomizer, etc. compatability)
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, 75);
			}
		}
	}
	else
	{
		civilianCheck[client]++;
	}

	new playerBack=FindPlayerBack(client, 57);  //Razorback
	shield[client]=IsValidEntity(playerBack) ? playerBack : 0;
	if(IsValidEntity(FindPlayerBack(client, 642)))  //Cozy Camper
	{
		SpawnWeapon(client, "tf_weapon_smg", 16, 1, 6, "149 ; 1.5 ; 15 ; 0.0 ; 1 ; 0.85");
	}

	if(IsValidEntity(FindPlayerBack(client, 444)))  //Mantreads
	{
		TF2Attrib_SetByDefIndex(client, 58, 1.5);  //+50% increased push force
	}
	else
	{
		TF2Attrib_RemoveByDefIndex(client, 58);
	}

	new entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable_demoshield"))!=-1)  //Demoshields
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			shield[client]=entity;
		}
	}

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(weapon))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(index)
		{
			case 43:  //KGB
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				SpawnWeapon(client, "tf_weapon_fists", 239, 1, 6, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 191 ; -7 ; 772 ; 1.5");  //GRU
					//1: -50% damage
					//107: +50% move speed
					//128: Only when weapon is active
					//191: -7 health/second
					//772: Holsters 50% slower
			}
			case 357:  //Half-Zatoichi
			{
				CreateTimer(1.0, Timer_NoHonorBound, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			case 589:  //Eureka Effect
			{
				if(!GetConVarBool(cvarEnableEurekaEffect))
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
					SpawnWeapon(client, "tf_weapon_wrench", 7);
				}
			}
		}
	}
	else
	{
		civilianCheck[client]++;
	}

	if(civilianCheck[client]==3)
	{
		civilianCheck[client]=0;
		Debug("Respawning %N to avoid civilian bug", client);
		TF2_RespawnPlayer(client);
	}
	civilianCheck[client]=0;
	return Plugin_Continue;
}

stock RemovePlayerTarge(client)
{
	new entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable_demoshield"))!=-1)
	{
		new index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			if(index==131 || index==406 || index==1099 || index==1144)  //Chargin' Targe, Splendid Screen, Tide Turner, Festive Chargin' Targe
			{
				TF2_RemoveWearable(client, entity);
			}
		}
	}
}

stock RemovePlayerBack(client, indices[], length)
{
	if(length<=0)
	{
		return;
	}

	new entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable"))!=-1)
	{
		decl String:netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				for(new i; i<length; i++)
				{
					if(index==indices[i])
					{
						TF2_RemoveWearable(client, entity);
					}
				}
			}
		}
	}
}

stock FindPlayerBack(client, index)
{
	new entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable"))!=-1)
	{
		decl String:netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable") && GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")==index && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			return entity;
		}
	}
	return -1;
}

public Action:OnObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled)
	{
		new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
		if(!GetRandomInt(0, 2) && IsBoss(attacker))
		{
			decl String:sound[PLATFORM_MAX_PATH];
			if(FindSound("destroy building", sound, sizeof(sound)))
			{
				EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, attacker);
				EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, attacker);
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnUberDeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(Enabled && IsValidClient(client) && IsPlayerAlive(client))
	{
		new medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(medigun))
		{
			decl String:classname[64];
			GetEntityClassname(medigun, classname, sizeof(classname));
			if(StrEqual(classname, "tf_weapon_medigun"))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5, client);
				new target=GetHealingTarget(client);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5, client);
					uberTarget[client]=target;
				}
				else
				{
					uberTarget[client]=-1;
				}
				CreateTimer(0.4, Timer_Uber, EntIndexToEntRef(medigun), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Uber(Handle:timer, any:medigunid)
{
	new medigun=EntRefToEntIndex(medigunid);
	if(medigun && IsValidEntity(medigun) && CheckRoundState()==FF2RoundState_RoundRunning)
	{
		new client=GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		new Float:charge=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		if(IsValidClient(client, false) && IsPlayerAlive(client) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==medigun)
		{
			new target=GetHealingTarget(client);
			if(charge>0.05)
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5);
					uberTarget[client]=target;
				}
				else
				{
					uberTarget[client]=-1;
				}
			}
			else
			{
				return Plugin_Stop;
			}
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Command_GetHPCmd(client, args)
{
	if(!IsValidClient(client) || !Enabled || CheckRoundState()!=FF2RoundState_RoundRunning)
	{
		return Plugin_Continue;
	}

	Command_GetHP(client);
	return Plugin_Handled;
}

public Action:Command_GetHP(client)  //TODO: This can rarely show a very large negative number if you time it right
{
	if(IsBoss(client) || GetGameTime()>=HPTime)
	{
		new String:text[512];  //Do not decl this
		decl String:lives[8], String:name[64];
		for(new target; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				new boss=Boss[target];
				KvRewind(GetArrayCell(bossesArray, character[boss]));
				KvGetString(GetArrayCell(bossesArray, character[boss]), "name", name, sizeof(name), "=Failed name=");
				if(BossLives[boss]>1)
				{
					Format(lives, sizeof(lives), "x%i", BossLives[boss]);
				}
				else
				{
					strcopy(lives, 2, "");
				}
				Format(text, sizeof(text), "%s\n%t", text, "Boss Current Health", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
				CPrintToChatAll("{olive}[FF2]{default} %t", "Boss Current Health", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
				BossHealthLast[boss]=BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
			}
		}

		for(new target; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && !(FF2Flags[target] & FF2FLAG_HUDDISABLED))
			{
				SetGlobalTransTarget(target);
				PrintCenterText(target, text);
			}
		}

		if(GetGameTime()>=HPTime)
		{
			healthcheckused++;
			HPTime=GetGameTime()+(healthcheckused<3 ? 20.0 : 80.0);
		}
		return Plugin_Continue;
	}

	if(RedAlivePlayers>1)
	{
		new String:waitTime[128];
		for(new target; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				Format(waitTime, sizeof(waitTime), "%s %i,", waitTime, BossHealthLast[Boss[target]]);
			}
		}
		CPrintToChat(client, "{olive}[FF2]{default} %t", "Wait for Health Value", RoundFloat(HPTime-GetGameTime()), waitTime);
	}
	return Plugin_Continue;
}

public Action:Command_SetNextBoss(client, args)
{
	decl String:name[64], String:boss[64];

	if(args<1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_special <boss>");
		return Plugin_Handled;
	}
	GetCmdArgString(name, sizeof(name));

	for(new config; config<GetArraySize(bossesArray); config++)
	{
		new Handle:kv=GetArrayCell(bossesArray, config);
		KvRewind(kv);
		KvGetString(kv, "name", boss, sizeof(boss));
		if(StrContains(boss, name, false)!=-1)
		{
			Incoming[0]=config;
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		KvGetString(kv, "filename", boss, sizeof(boss));
		if(StrContains(boss, name, false)!=-1)
		{
			Incoming[0]=config;
			KvGetString(kv, "name", boss, sizeof(boss));
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Boss could not be found!");
	return Plugin_Handled;
}

public Action:Command_Points(client, args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	if(args!=2)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_addpoints <target> <points>");
		return Plugin_Handled;
	}

	decl String:stringPoints[8];
	decl String:pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, stringPoints, sizeof(stringPoints));
	new points=StringToInt(stringPoints);

	new String:targetName[MAX_TARGET_LENGTH];
	new targets[MAXPLAYERS], matches;
	new bool:targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches>1)
	{
		for(new target; target<matches; target++)
		{
			if(!IsClientSourceTV(targets[target]) && !IsClientReplay(targets[target]))
			{
				SetClientQueuePoints(targets[target], GetClientQueuePoints(targets[target])+points);
				LogAction(client, targets[target], "\"%L\" added %d queue points to \"%L\"", client, points, targets[target]);
			}
		}
	}
	else
	{
		SetClientQueuePoints(targets[0], GetClientQueuePoints(targets[0])+points);
		LogAction(client, targets[0], "\"%L\" added %d queue points to \"%L\"", client, points, targets[0]);
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Added %d queue points to %s", points, targetName);
	return Plugin_Handled;
}

public Action:Command_StartMusic(client, args)
{
	if(Enabled2)
	{
		if(args)
		{
			decl String:pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			new String:targetName[MAX_TARGET_LENGTH];
			new targets[MAXPLAYERS], matches;
			new bool:targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches>1)
			{
				for(new target; target<matches; target++)
				{
					StartMusic(targets[target]);
				}
			}
			else
			{
				StartMusic(targets[0]);
			}
			CReplyToCommand(client, "{olive}[FF2]{default} Started boss music for %s.", targetName);
		}
		else
		{
			StartMusic();
			CReplyToCommand(client, "{olive}[FF2]{default} Started boss music for all clients.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_StopMusic(client, args)
{
	if(Enabled2)
	{
		if(args)
		{
			decl String:pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			new String:targetName[MAX_TARGET_LENGTH];
			new targets[MAXPLAYERS], matches;
			new bool:targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches>1)
			{
				for(new target; target<matches; target++)
				{
					StopMusic(targets[target], true);
				}
			}
			else
			{
				StopMusic(targets[0], true);
			}
			CReplyToCommand(client, "{olive}[FF2]{default} Stopped boss music for %s.", targetName);
		}
		else
		{
			StopMusic(_, true);
			CReplyToCommand(client, "{olive}[FF2]{default} Stopped boss music for all clients.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_Charset(client, args)
{
	if(!args)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_charset <charset>");
		return Plugin_Handled;
	}

	decl String:charset[32], String:rawText[16][16];
	GetCmdArgString(charset, sizeof(charset));
	new amount=ExplodeString(charset, " ", rawText, 16, 16);
	for(new i; i<amount; i++)
	{
		StripQuotes(rawText[i]);
	}
	ImplodeStrings(rawText, amount, " ", charset, sizeof(charset));

	decl String:config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2_SETTINGS, BOSS_CONFIG);

	new Handle:Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	for(new i; ; i++)
	{
		KvGetSectionName(Kv, config, sizeof(config));
		if(StrContains(config, charset, false)>=0)
		{
			CReplyToCommand(client, "{olive}[FF2]{default} Charset for nextmap is %s", config);
			isCharSetSelected=true;
			FF2CharSet=i;
			break;
		}

		if(!KvGotoNextKey(Kv))
		{
			CReplyToCommand(client, "{olive}[FF2]{default} Charset not found");
			break;
		}
	}
	CloseHandle(Kv);
	return Plugin_Handled;
}

public Action:Command_ReloadSubPlugins(client, args)
{
	if(Enabled)
	{
		//DisableSubPlugins(true);
		//EnableSubPlugins(true);
		decl String:path[PLATFORM_MAX_PATH], String:filename[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, sizeof(path), "plugins/freak_fortress_2");
		decl FileType:filetype;
		new Handle:directory=OpenDirectory(path);
		while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
		{
			if(filetype==FileType_File && StrContains(filename, ".smx", false)!=-1)
			{
				ServerCommand("sm plugins unload freak_fortress_2/%s", filename);
				ServerCommand("sm plugins load freak_fortress_2/%s", filename);
			}
		}
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Reloaded subplugins!");
	return Plugin_Handled;
}

public Action:Command_Point_Disable(client, args)
{
	if(Enabled)
	{
		SetControlPoint(false);
	}
	return Plugin_Handled;
}

public Action:Command_Point_Enable(client, args)
{
	if(Enabled)
	{
		SetControlPoint(true);
	}
	return Plugin_Handled;
}

stock SetControlPoint(bool:enable)
{
	new controlPoint=MaxClients+1;
	while((controlPoint=FindEntityByClassname2(controlPoint, "team_control_point"))!=-1)
	{
		if(controlPoint>MaxClients && IsValidEntity(controlPoint))
		{
			AcceptEntityInput(controlPoint, (enable ? "ShowModel" : "HideModel"));
			SetVariantInt(enable ? 0 : 1);
			AcceptEntityInput(controlPoint, "SetLocked");
		}
	}
}

stock SetArenaCapEnableTime(Float:time)
{
	new entity=-1;
	if((entity=FindEntityByClassname2(-1, "tf_logic_arena"))!=-1 && IsValidEntity(entity))
	{
		decl String:timeString[32];
		FloatToString(time, timeString, sizeof(timeString));
		DispatchKeyValue(entity, "CapEnableDelay", timeString);
	}
}

public OnClientPostAdminCheck(client)
{
	// TODO: Hook these inside of EnableFF2() or somewhere instead
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);

	FF2Flags[client]=0;
	Damage[client]=0;
	uberTarget[client]=-1;

	if(playBGM[0])
	{
		playBGM[client]=true;
		if(Enabled)
		{
			CreateTimer(0.1, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		playBGM[client]=false;
	}
}

public OnClientCookiesCached(client)
{
	decl String:buffer[4];
	GetClientCookie(client, FF2Cookie_QueuePoints, buffer, sizeof(buffer));
	if(!buffer[0])
	{
		SetClientCookie(client, FF2Cookie_QueuePoints, "0");
	}
	queuePoints[client]=StringToInt(buffer);

	GetClientCookie(client, FF2Cookie_MuteSound, buffer, sizeof(buffer));
	if(!buffer[0])
	{
		SetClientCookie(client, FF2Cookie_MuteSound, "0");
	}
	muteSound[client]=StringToInt(buffer);

	GetClientCookie(client, FF2Cookie_DisplayInfo, buffer, sizeof(buffer));
	if(!buffer[0])
	{
		SetClientCookie(client, FF2Cookie_DisplayInfo, "1");
		buffer="1";
	}
	displayInfo[client]=bool:StringToInt(buffer);
}

public OnClientDisconnect(client)
{
	if(Enabled)
	{
		if(IsBoss(client) && !CheckRoundState() && GetConVarBool(cvarPreroundBossDisconnect))
		{
			new boss=GetBossIndex(client);
			new bool:omit[MaxClients+1];
			omit[client]=true;
			Boss[boss]=GetClientWithMostQueuePoints(omit);

			if(Boss[boss])
			{
				CreateTimer(0.1, MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
				CPrintToChat(Boss[boss], "{olive}[FF2]{default} %t", "Replace Disconnected Boss");
				CPrintToChatAll("{olive}[FF2]{default} %t", "Boss Disconnected", client, Boss[boss]);
			}
		}

		if(IsClientInGame(client) && IsPlayerAlive(client) && CheckRoundState()==FF2RoundState_RoundRunning)
		{
			CreateTimer(0.1, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	if(MusicTimer[client]!=INVALID_HANDLE)
	{
		KillTimer(MusicTimer[client]);
		MusicTimer[client]=INVALID_HANDLE;
	}
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled && CheckRoundState()==FF2RoundState_RoundRunning)
	{
		CreateTimer(0.1, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:OnPostInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");

	if(IsBoss(client))
	{
		CreateTimer(0.1, MakeBoss, GetBossIndex(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	if(!(FF2Flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		if(!(FF2Flags[client] & FF2FLAG_HASONGIVED))
		{
			FF2Flags[client]|=FF2FLAG_HASONGIVED;
			RemovePlayerBack(client, {57, 133, 405, 444, 608, 642}, 7);
			RemovePlayerTarge(client);
			TF2_RemoveAllWeapons(client);
			TF2_RegeneratePlayer(client);
			CreateTimer(0.1, Timer_RegenPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		CreateTimer(0.2, MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	FF2Flags[client]&=~(FF2FLAG_UBERREADY|FF2FLAG_ISBUFFED|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_USINGABILITY|FF2FLAG_CLASSHELPED|FF2FLAG_CHANGECVAR|FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS|FF2FLAG_BLAST_JUMPING);
	FF2Flags[client]|=FF2FLAG_USEBOSSTIMER;
	return Plugin_Continue;
}

public Action:Timer_RegenPlayer(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_RegeneratePlayer(client);
	}
}

public Action:ClientTimer(Handle:timer)
{
	if(!Enabled || CheckRoundState()==FF2RoundState_RoundEnd || CheckRoundState()==FF2RoundState_Loading)
	{
		return Plugin_Stop;
	}

	decl String:classname[32];
	new TFCond:cond;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsBoss(client) && !(FF2Flags[client] & FF2FLAG_CLASSTIMERDISABLED))
		{
			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
			if(!IsPlayerAlive(client))
			{
				new observer=GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if(IsValidClient(observer) && !IsBoss(observer) && observer!=client)
				{
					FF2_ShowSyncHudText(client, rageHUD, "%t-%t", "Your Damage Dealt", Damage[client], "Spectator Damage Dealt", observer, Damage[observer]);
				}
				else
				{
					FF2_ShowSyncHudText(client, rageHUD, "%t", "Your Damage Dealt", Damage[client]);
				}
				continue;
			}
			FF2_ShowSyncHudText(client, rageHUD, "%t", "Your Damage Dealt", Damage[client]);

			new TFClassType:class=TF2_GetPlayerClass(client);
			new weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(weapon<=MaxClients || !IsValidEntity(weapon) || !GetEntityClassname(weapon, classname, sizeof(classname)))
			{
				strcopy(classname, sizeof(classname), "");
			}
			new bool:validwep=!StrContains(classname, "tf_weapon", false);

			new index=(validwep ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if(class==TFClass_Medic)
			{
				if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
				{
					new medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					decl String:mediclassname[64];
					if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
					{
						new charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
						SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
						FF2_ShowSyncHudText(client, jumpHUD, "%T: %i", "Ubercharge", client, charge);

						if(charge==100 && !(FF2Flags[client] & FF2FLAG_UBERREADY))
						{
							FakeClientCommandEx(client, "voicemenu 1 7");
							FF2Flags[client]|=FF2FLAG_UBERREADY;
						}
					}
				}
				else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
				{
					new healtarget=GetHealingTarget(client, true);
					if(IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget)==TFClass_Scout)
					{
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
					}
				}
			}
			else if(class==TFClass_Soldier)
			{
				if((FF2Flags[client] & FF2FLAG_ISBUFFED) && !(GetEntProp(client, Prop_Send, "m_bRageDraining")))
				{
					FF2Flags[client]&=~FF2FLAG_ISBUFFED;
				}
			}

			if(RedAlivePlayers==1 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.3);
				if(class==TFClass_Engineer && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(classname, "tf_weapon_sentry_revenge", false))
				{
					SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
				}
				TF2_AddCondition(client, TFCond_Buffed, 0.3);

				if(lastPlayerGlow)
				{
					SetClientGlow(client, 3600.0);
				}
				continue;
			}
			else if(RedAlivePlayers==2 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_AddCondition(client, TFCond_Buffed, 0.3);
			}

			if(bMedieval)
			{
				continue;
			}

			cond=TFCond_HalloweenCritCandy;
			if(TF2_IsPlayerInCondition(client, TFCond_CritCola) && (class==TFClass_Scout || class==TFClass_Heavy))
			{
				TF2_AddCondition(client, cond, 0.3);
				continue;
			}

			new healer=-1;
			for(new healtarget=1; healtarget<=MaxClients; healtarget++)
			{
				if(IsValidClient(healtarget) && IsPlayerAlive(healtarget) && GetHealingTarget(healtarget, true)==client)
				{
					healer=healtarget;
					break;
				}
			}

			new bool:addthecrit;
			if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) && StrContains(classname, "tf_weapon_knife", false)==-1)  //Every melee except knives
			{
				addthecrit=true;
				if(index==416)  //Market Gardener
				{
					addthecrit=FF2Flags[client] & FF2FLAG_BLAST_JUMPING ? true : false;
				}
			}
			else if((!StrContains(classname, "tf_weapon_smg") && index!=751) ||  //Cleaner's Carbine
			         !StrContains(classname, "tf_weapon_compound_bow") ||
			         !StrContains(classname, "tf_weapon_crossbow") ||
			         !StrContains(classname, "tf_weapon_pistol") ||
			         !StrContains(classname, "tf_weapon_handgun_scout_secondary"))
			{
				addthecrit=true;
				if(class==TFClass_Scout && cond==TFCond_HalloweenCritCandy)
				{
					cond=TFCond_Buffed;
				}
			}

			if(index==16 && IsValidEntity(FindPlayerBack(client, 642)))  //SMG, Cozy Camper
			{
				addthecrit=false;
			}

			switch(class)
			{
				case TFClass_Medic:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						new medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
						decl String:mediclassname[64];
						if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
						{
							SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
							new charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
							FF2_ShowHudText(client, -1, "%T: %i", "Ubercharge", client, charge);
							if(charge==100 && !(FF2Flags[client] & FF2FLAG_UBERREADY))
							{
								FakeClientCommand(client, "voicemenu 1 7");  //"I am fully charged!"
								FF2Flags[client]|= FF2FLAG_UBERREADY;
							}
						}
					}
					else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
					{
						new healtarget=GetHealingTarget(client, true);
						if(IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget)==TFClass_Scout)
						{
							TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
						}
					}
				}
				case TFClass_DemoMan:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && !IsValidEntity(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)) && shieldCrits)  //Demoshields
					{
						addthecrit=true;
						if(shieldCrits==1)
						{
							cond=TFCond_Buffed;
						}
					}
				}
				case TFClass_Spy:
				{
					if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						if(!TF2_IsPlayerCritBuffed(client) && !TF2_IsPlayerInCondition(client, TFCond_Buffed) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Disguised))
						{
							TF2_AddCondition(client, TFCond_CritCola, 0.3);
						}
					}
				}
				case TFClass_Engineer:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(classname, "tf_weapon_sentry_revenge", false))
					{
						new sentry=FindSentry(client);
						if(IsValidEntity(sentry) && IsBoss(GetEntPropEnt(sentry, Prop_Send, "m_hEnemy")))
						{
							SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
							TF2_AddCondition(client, TFCond_Kritzkrieged, 0.3);
						}
						else
						{
							if(GetEntProp(client, Prop_Send, "m_iRevengeCrits"))
							{
								SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);
							}
							else if(TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) && !TF2_IsPlayerInCondition(client, TFCond_Healing))
							{
								TF2_RemoveCondition(client, TFCond_Kritzkrieged);
							}
						}
					}
				}
			}

			if(addthecrit)
			{
				TF2_AddCondition(client, cond, 0.3);
				if(healer!=-1 && cond!=TFCond_Buffed)
				{
					TF2_AddCondition(client, TFCond_Buffed, 0.3);
				}
			}
		}
	}
	return Plugin_Continue;
}

stock FindSentry(client)
{
	new entity=-1;
	while((entity=FindEntityByClassname2(entity, "obj_sentrygun"))!=-1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client)
		{
			return entity;
		}
	}
	return -1;
}

public Action:BossTimer(Handle:timer)
{
	if(!Enabled || CheckRoundState()==FF2RoundState_RoundEnd)
	{
		return Plugin_Stop;
	}

	new bool:validBoss;
	for(new boss; boss<=MaxClients; boss++)
	{
		new client=Boss[boss];
		if(!IsValidClient(client) || !IsPlayerAlive(client) || !(FF2Flags[client] & FF2FLAG_USEBOSSTIMER))
		{
			continue;
		}
		validBoss=true;

		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", BossSpeed[boss]+0.7*(100-BossHealth[boss]*100/BossLivesMax[boss]/BossHealthMax[boss]));

		if(BossHealth[boss]<=0 && IsPlayerAlive(client))  //Wat.  TODO:  Investigate
		{
			BossHealth[boss]=1;
		}

		if(BossLivesMax[boss]>1)
		{
			SetHudTextParams(-1.0, 0.77, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, livesHUD, "%t", "Boss Lives Left", BossLives[boss], BossLivesMax[boss]);
		}

		if(RoundFloat(BossCharge[boss][0])==100.0)
		{
			if(IsFakeClient(client) && !(FF2Flags[client] & FF2FLAG_BOTRAGE))
			{
				CreateTimer(1.0, Timer_BotRage, boss, TIMER_FLAG_NO_MAPCHANGE);
				FF2Flags[client]|=FF2FLAG_BOTRAGE;
			}
			else
			{
				SetHudTextParams(-1.0, 0.83, 0.15, 255, 64, 64, 255);
				FF2_ShowSyncHudText(client, rageHUD, "%t", "Activate Rage");

				decl String:sound[PLATFORM_MAX_PATH];
				if(FindSound("full rage", sound, sizeof(sound), boss) && emitRageSound[boss])
				{
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, client);
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, client);

					emitRageSound[boss]=false;
				}
			}
		}
		else
		{
			SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, rageHUD, "%t", "Rage Meter", RoundFloat(BossCharge[boss][0]));
		}
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);

		SetClientGlow(client, -0.2);

		new Handle:kv=GetArrayCell(bossesArray, character[boss]);
		KvRewind(kv);
		if(KvJumpToKey(kv, "abilities"))
		{
			decl String:ability[10];
			KvGotoFirstSubKey(kv);
			do
			{
				decl String:pluginName[64];
				KvGetSectionName(kv, pluginName, sizeof(pluginName));
				KvGotoFirstSubKey(kv);
				do
				{
					decl String:abilityName[64];
					KvGetSectionName(kv, abilityName, sizeof(abilityName));
					new slot=KvGetNum(kv, "slot", 0);
					new buttonmode=KvGetNum(kv, "buttonmode", 0);
					if(slot<1) // We don't care about rage/life-loss abilities here
					{
						continue;
					}

					KvGetString(kv, "life", ability, sizeof(ability), "");
					if(!ability[0]) // Just a regular ability that doesn't care what life the boss is on
					{
						UseAbility(boss, pluginName, abilityName, slot, buttonmode);
					}
					else // But these do
					{
						decl String:temp[3];
						new Handle:livesArray=CreateArray(sizeof(temp));
						new count=ExplodeStringIntoArrayList(ability, " ", livesArray, sizeof(temp));
						for(new n; n<count; n++)
						{
							GetArrayString(livesArray, n, temp, sizeof(temp));
							if(StringToInt(temp)==BossLives[boss])
							{
								UseAbility(boss, pluginName, abilityName, slot, buttonmode);
								break;
							}
						}
					}
				}
				while(KvGotoNextKey(kv));
				KvGoBack(kv);
			}
			while(KvGotoNextKey(kv));
		}

		if(RedAlivePlayers==1)
		{
			new String:message[512];  //Do not decl this
			decl String:name[64];
			for(new target; target<=MaxClients; target++)  //TODO: Why is this for loop needed when we're already in a boss for loop
			{
				if(IsBoss(target))
				{
					new boss2=GetBossIndex(target);
					KvRewind(GetArrayCell(bossesArray, character[boss2]));
					KvGetString(GetArrayCell(bossesArray, character[boss2]), "name", name, sizeof(name), "=Failed name=");
					//Format(bossLives, sizeof(bossLives), ((BossLives[boss2]>1) ? ("x%i", BossLives[boss2]) : ("")));
					decl String:bossLives[10];
					if(BossLives[boss2]>1)
					{
						Format(bossLives, sizeof(bossLives), "x%i", BossLives[boss2]);
					}
					else
					{
						Format(bossLives, sizeof(bossLives), "");
					}
					Format(message, sizeof(message), "%s\n%t", message, "Boss Current Health", name, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives);
				}
			}

			for(new target; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && !(FF2Flags[target] & FF2FLAG_HUDDISABLED))
				{
					SetGlobalTransTarget(target);
					PrintCenterText(target, message);
				}
			}

			if(lastPlayerGlow)
			{
				SetClientGlow(client, 3600.0);
			}
		}

		if(BossCharge[boss][0]<100.0)
		{
			BossCharge[boss][0]+=OnlyScoutsLeft()*0.2;
			if(BossCharge[boss][0]>100.0)
			{
				BossCharge[boss][0]=100.0;
			}
		}

		HPTime-=0.2;
		if(HPTime<0)
		{
			HPTime=0.0;
		}

		for(new client2; client2<=MaxClients; client2++)
		{
			if(KSpreeTimer[client2]>0)
			{
				KSpreeTimer[client2]-=0.2;
			}
		}
	}

	if(!validBoss)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_BotRage(Handle:timer, any:bot)
{
	if(IsValidClient(Boss[bot], false))
	{
		FakeClientCommandEx(Boss[bot], "voicemenu 0 0");
	}
}

stock OnlyScoutsLeft()
{
	new scouts;
	for(new client; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client) && TF2_GetClientTeam(client)!=BossTeam)
		{
			if(TF2_GetPlayerClass(client)!=TFClass_Scout)
			{
				return 0;
			}
			else
			{
				scouts++;
			}
		}
	}
	return scouts;
}

stock GetIndexOfWeaponSlot(client, slot)
{
	new weapon=GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(Enabled)
	{
		if(IsBoss(client) && (condition==TFCond_Jarated || condition==TFCond_MarkedForDeath || (condition==TFCond_Dazed && TF2_IsPlayerInCondition(client, TFCond:42))))
		{
			TF2_RemoveCondition(client, condition);
		}
		else if(!IsBoss(client) && condition==TFCond_BlastJumping)
		{
			FF2Flags[client]|=FF2FLAG_BLAST_JUMPING;
		}
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(Enabled)
	{
		if(TF2_GetPlayerClass(client)==TFClass_Scout && condition==TFCond_CritHype)
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
		}
		else if(!IsBoss(client) && condition==TFCond_BlastJumping)
		{
			FF2Flags[client]&=~FF2FLAG_BLAST_JUMPING;
		}
	}
}

public Action:OnCallForMedic(client, const String:command[], args)
{
	if(!Enabled || !IsPlayerAlive(client) || CheckRoundState()!=FF2RoundState_RoundRunning || !IsBoss(client) || args!=2)
	{
		return Plugin_Continue;
	}

	new boss=GetBossIndex(client);

	decl String:arg1[4], String:arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
	{
		return Plugin_Continue;
	}

	if(RoundFloat(BossCharge[boss][0])==100)
	{
		new Handle:kv=GetArrayCell(bossesArray, character[boss]);
		KvRewind(kv);
		if(KvJumpToKey(kv, "abilities"))
		{
			decl String:ability[10];
			KvGotoFirstSubKey(kv);
			do
			{
				decl String:pluginName[64];
				KvGetSectionName(kv, pluginName, sizeof(pluginName));
				KvGotoFirstSubKey(kv);
				do
				{
					decl String:abilityName[64];
					KvGetSectionName(kv, abilityName, sizeof(abilityName));
					if(KvGetNum(kv, "slot")) // Rage is slot 0
					{
						continue;
					}

					KvGetString(kv, "life", ability, sizeof(ability), "");
					if(!ability[0]) // Just a regular ability that doesn't care what life the boss is on
					{
						if(!UseAbility(boss, pluginName, abilityName, 0))
						{
							return Plugin_Continue;
						}
					}
					else // But these do
					{
						decl String:temp[3];
						new Handle:livesArray=CreateArray(sizeof(temp));
						new count=ExplodeStringIntoArrayList(ability, " ", livesArray, sizeof(temp));
						for(new n; n<count; n++)
						{
							GetArrayString(livesArray, n, temp, sizeof(temp));
							if(StringToInt(temp)==BossLives[boss])
							{
								if(!UseAbility(boss, pluginName, abilityName, 0))
								{
									return Plugin_Continue;
								}
								break;
							}
						}
					}
				}
				while(KvGotoNextKey(kv));
				KvGoBack(kv);
			}
			while(KvGotoNextKey(kv));
		}

		decl String:sound[PLATFORM_MAX_PATH];
		if(FindSound("ability", sound, sizeof(sound), boss, true))
		{
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, client);
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, client);
		}
		emitRageSound[boss]=true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnSuicide(client, const String:command[], args)
{
	new bool:canBossSuicide=GetConVarBool(cvarBossSuicide);
	if(Enabled && IsBoss(client) && (canBossSuicide ? CheckRoundState()!=FF2RoundState_Setup : true) && CheckRoundState()!=FF2RoundState_RoundEnd)
	{
		CPrintToChat(client, "{olive}[FF2]{default} %t", canBossSuicide ? "Boss Suicide Pre-round" : "Boss Suicide Denied");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnChangeClass(client, const String:command[], args)
{
	if(Enabled && IsBoss(client) && IsPlayerAlive(client))
	{
		//Don't allow the boss to switch classes but instead set their *desired* class (for the next round)
		decl String:class[16];
		GetCmdArg(1, class, sizeof(class));
		if(TF2_GetClass(class)!=TFClass_Unknown)  //Ignore cases where the client chooses an invalid class through the console
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TF2_GetClass(class));
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnJoinTeam(client, const String:command[], args)
{
	// Only block the commands when FF2 is actively running
	if(!Enabled || RoundCount<arenaRounds || CheckRoundState()==FF2RoundState_Loading)
	{
		return Plugin_Continue;
	}

	// autoteam doesn't come with arguments
	if(StrEqual(command, "autoteam", false))
	{
		new TFTeam:team=TFTeam_Unassigned, TFTeam:oldTeam=TF2_GetClientTeam(client);
		if(IsBoss(client))
		{
			team=BossTeam;
		}
		else
		{
			team=OtherTeam;
		}

		if(team!=oldTeam)
		{
			TF2_ChangeClientTeam(client, team);
		}
		return Plugin_Handled;
	}

	if(!args)
	{
		return Plugin_Continue;
	}

	new TFTeam:team=TFTeam_Unassigned, TFTeam:oldTeam=TF2_GetClientTeam(client), String:teamString[10];
	GetCmdArg(1, teamString, sizeof(teamString));

	if(StrEqual(teamString, "red", false))
	{
		team=TFTeam_Red;
	}
	else if(StrEqual(teamString, "blue", false))
	{
		team=TFTeam_Blue;
	}
	else if(StrEqual(teamString, "auto", false))
	{
		team=OtherTeam;
	}
	else if(StrEqual(teamString, "spectate", false) && !IsBoss(client) && GetConVarBool(FindConVar("mp_allowspectators")))
	{
		team=TFTeam_Spectator;
	}

	if(team==BossTeam && !IsBoss(client))
	{
		team=OtherTeam;
	}
	else if(team==OtherTeam && IsBoss(client))
	{
		team=BossTeam;
	}

	if(team>TFTeam_Unassigned && team!=oldTeam)
	{
		TF2_ChangeClientTeam(client, team);
	}

	if(CheckRoundState()!=FF2RoundState_RoundRunning && !IsBoss(client) || !IsPlayerAlive(client))  //No point in showing the VGUI if they can't change teams
	{
		switch(team)
		{
			case TFTeam_Red:
			{
				ShowVGUIPanel(client, "class_red");
			}
			case TFTeam_Blue:
			{
				ShowVGUIPanel(client, "class_blue");
			}
		}
	}
	return Plugin_Handled;
}

public Action:OnPlayerDeath(Handle:event, const String:eventName[], bool:dontBroadcast)
{
	if(!Enabled || CheckRoundState()!=FF2RoundState_RoundRunning)
	{
		return Plugin_Continue;
	}

	new client=GetClientOfUserId(GetEventInt(event, "userid")), attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	decl String:sound[PLATFORM_MAX_PATH];
	CreateTimer(0.1, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	DoOverlay(client, "");
	if(!IsBoss(client))
	{
		if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			CreateTimer(1.0, Timer_Damage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}

		if(IsBoss(attacker))
		{
			new boss=GetBossIndex(attacker);
			if(firstBlood)  //TF_DEATHFLAG_FIRSTBLOOD is broken
			{
				if(FindSound("first blood", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, attacker);
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, attacker);
				}
				firstBlood=false;
			}

			if(RedAlivePlayers!=1)  //Don't conflict with end-of-round sounds
			{
				if(GetRandomInt(0, 1) && FindSound("kill", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, attacker);
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, attacker);
				}
				else if(!GetRandomInt(0, 2))  //1/3 chance for "sound_kill_<class>"
				{
					new String:classnames[][]={"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
					decl String:class[32];
					Format(class, sizeof(class), "kill %s", classnames[TF2_GetPlayerClass(client)]);
					if(FindSound(class, sound, sizeof(sound), boss))
					{
						EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, attacker);
						EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, attacker);
					}
				}
			}

			if(GetGameTime()<=KSpreeTimer[boss])
			{
				KSpreeCount[boss]++;
			}
			else
			{
				KSpreeCount[boss]=1;
			}

			if(KSpreeCount[boss]==3)
			{
				if(FindSound("kspree", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, attacker);
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, attacker);
				}
				KSpreeCount[boss]=0;
			}
			else
			{
				KSpreeTimer[boss]=GetGameTime()+5.0;
			}
		}
	}
	else
	{
		new boss=GetBossIndex(client);
		if(boss==-1 || (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			return Plugin_Continue;
		}

		if(FindSound("lose", sound, sizeof(sound), boss))
		{
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, client);
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, client);
		}

		BossHealth[boss]=0;
		UpdateHealthBar();

		Stabbed[boss]=0.0;
		Marketed[boss]=0.0;
	}

	if(TF2_GetPlayerClass(client)==TFClass_Engineer && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		decl String:name[PLATFORM_MAX_PATH];
		FakeClientCommand(client, "destroy 2");
		for(new entity=MaxClients+1; entity<MAXENTITIES; entity++)
		{
			if(IsValidEntity(entity))
			{
				GetEntityClassname(entity, name, sizeof(name));
				if(!StrContains(name, "obj_sentrygun") && (GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client))
				{
					SetVariantInt(GetEntPropEnt(entity, Prop_Send, "m_iMaxHealth")+1);
					AcceptEntityInput(entity, "RemoveHealth");

					new Handle:eventRemoveObject=CreateEvent("object_removed", true);
					SetEventInt(eventRemoveObject, "userid", GetClientUserId(client));
					SetEventInt(eventRemoveObject, "index", entity);
					FireEvent(eventRemoveObject);
					AcceptEntityInput(entity, "kill");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Damage(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(IsValidClient(client, false))
	{
		CPrintToChat(client, "{olive}[FF2] %t. %t{default}", "Total Damage Dealt", Damage[client], "Points Earned", RoundFloat(Damage[client]/600.0));
	}
	return Plugin_Continue;
}

public Action:OnObjectDeflected(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!Enabled || GetEventInt(event, "weaponid"))  //0 means that the client was airblasted, which is what we want
	{
		return Plugin_Continue;
	}

	new boss=GetBossIndex(GetClientOfUserId(GetEventInt(event, "ownerid")));
	if(boss!=-1 && BossCharge[boss][0]<100.0)
	{
		BossCharge[boss][0]+=7.0;  //TODO: Allow this to be customizable
		if(BossCharge[boss][0]>100.0)
		{
			BossCharge[boss][0]=100.0;
		}
	}
	return Plugin_Continue;
}

public Action:OnJarate(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client=BfReadByte(bf);
	new victim=BfReadByte(bf);
	new boss=GetBossIndex(victim);
	if(boss!=-1)
	{
		new jarate=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(jarate!=-1)
		{
			new index=GetEntProp(jarate, Prop_Send, "m_iItemDefinitionIndex");
			if((index==58 || index==1083 || index==1105) && GetEntProp(jarate, Prop_Send, "m_iEntityLevel")!=-122)  //-122 is the Jar of Ants which isn't really Jarate
			{
				BossCharge[boss][0]-=8.0;  //TODO: Allow this to be customizable
				if(BossCharge[boss][0]<0.0)
				{
					BossCharge[boss][0]=0.0;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnDeployBackup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled && GetEventInt(event, "buff_type")==2)
	{
		FF2Flags[GetClientOfUserId(GetEventInt(event, "buff_owner"))]|=FF2FLAG_ISBUFFED;
	}
	return Plugin_Continue;
}

public Action:CheckAlivePlayers(Handle:timer)
{
	if(CheckRoundState()==FF2RoundState_RoundEnd)
	{
		return Plugin_Continue;
	}

	RedAlivePlayers=0;
	BlueAlivePlayers=0;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(TF2_GetClientTeam(client)==OtherTeam)
			{
				RedAlivePlayers++;
			}
			else if(TF2_GetClientTeam(client)==BossTeam)
			{
				BlueAlivePlayers++;
			}
		}
	}

	Call_StartForward(OnAlivePlayersChanged);  //Let subplugins know that the number of alive players just changed
	Call_PushCell(RedAlivePlayers);
	Call_PushCell(BlueAlivePlayers);
	Call_Finish();

	if(!RedAlivePlayers)
	{
		ForceTeamWin(BossTeam);
	}
	else if(RedAlivePlayers==1 && BlueAlivePlayers && Boss[0] && !DrawGameTimer)
	{
		decl String:sound[PLATFORM_MAX_PATH];
		if(FindSound("lastman", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, Boss[0]);
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, Boss[0]);
		}
	}
	else if(!PointType && RedAlivePlayers<=AliveToEnable && !executed)
	{
		PrintHintTextToAll("%t", "Point Unlocked", AliveToEnable);
		if(RedAlivePlayers==AliveToEnable)
		{
			new String:sound[64];
			if(GetRandomInt(0, 1))
			{
				Format(sound, sizeof(sound), "vo/announcer_am_capenabled0%i.mp3", GetRandomInt(1, 4));
			}
			else
			{
				Format(sound, sizeof(sound), "vo/announcer_am_capincite0%i.mp3", GetRandomInt(0, 1) ? 1 : 3);
			}
			EmitSoundToAll(sound);
		}
		SetControlPoint(true);
		executed=true;
	}

	if(RedAlivePlayers<=countdownPlayers && BossHealth[0]>countdownHealth && countdownTime>1 && !executed2)
	{
		if(FindEntityByClassname2(-1, "team_control_point")!=-1)
		{
			timeleft=countdownTime;
			DrawGameTimer=CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		executed2=true;
	}
	return Plugin_Continue;
}

public Action:Timer_DrawGame(Handle:timer)
{
	if(BossHealth[0]<countdownHealth || CheckRoundState()!=FF2RoundState_RoundRunning || RedAlivePlayers>countdownPlayers)
	{
		executed2=false;
		return Plugin_Stop;
	}

	new time=timeleft;
	timeleft--;
	decl String:timeDisplay[6];
	if(time/60>9)
	{
		IntToString(time/60, timeDisplay, sizeof(timeDisplay));
	}
	else
	{
		Format(timeDisplay, sizeof(timeDisplay), "0%i", time/60);
	}

	if(time%60>9)
	{
		Format(timeDisplay, sizeof(timeDisplay), "%s:%i", timeDisplay, time%60);
	}
	else
	{
		Format(timeDisplay, sizeof(timeDisplay), "%s:0%i", timeDisplay, time%60);
	}

	SetHudTextParams(-1.0, 0.17, 1.1, 255, 255, 255, 255);
	for(new client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			FF2_ShowSyncHudText(client, timeleftHUD, timeDisplay);
		}
	}

	switch(time)
	{
		case 300:
		{
			EmitSoundToAll("vo/announcer_ends_5min.mp3");
		}
		case 120:
		{
			EmitSoundToAll("vo/announcer_ends_2min.mp3");
		}
		case 60:
		{
			EmitSoundToAll("vo/announcer_ends_60sec.mp3");
		}
		case 30:
		{
			EmitSoundToAll("vo/announcer_ends_30sec.mp3");
		}
		case 10:
		{
			EmitSoundToAll("vo/announcer_ends_10sec.mp3");
		}
		case 1, 2, 3, 4, 5:
		{
			decl String:sound[PLATFORM_MAX_PATH];
			Format(sound, sizeof(sound), "vo/announcer_ends_%isec.mp3", time);
			EmitSoundToAll(sound);
		}
		case 0:
		{
			if(!GetConVarBool(cvarCountdownResult))
			{
				for(new client=1; client<=MaxClients; client++)  //Thx MasterOfTheXP
				{
					if(IsClientInGame(client) && IsPlayerAlive(client))
					{
						ForcePlayerSuicide(client);
					}
				}
			}
			else
			{
				ForceTeamWin(TFTeam_Unassigned);  //Stalemate
			}
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)  //TODO: Can this be removed?
{
	if(Enabled && CheckRoundState()==FF2RoundState_RoundRunning && GetEventBool(event, "minicrit") && GetEventBool(event, "allseecrit"))
	{
		Debug("allseecrit removed");
		SetEventBool(event, "allseecrit", false);
	}
	return Plugin_Continue;
}

public Action:OnTakeDamageAlive(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(!Enabled || !IsValidEntity(attacker))
	{
		return Plugin_Continue;
	}

	if((attacker<=0 || client==attacker) && IsBoss(client))
	{
		damage=0.0;
		return Plugin_Changed;
	}

	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
	{
		return Plugin_Continue;
	}

	if(CheckRoundState()==FF2RoundState_Setup && IsBoss(client))
	{
		damage=0.0;
		return Plugin_Changed;
	}

	new Float:position[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);
	if(IsBoss(attacker))
	{
		if(IsValidClient(client) && !IsBoss(client) && !TF2_IsPlayerInCondition(client, TFCond_Bonked))
		{
			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
			{
				ScaleVector(damageForce, 9.0);
				damage*=0.3;
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))
			{
				damage*=9;
				TF2_AddCondition(client, TFCond_Bonked, 0.1);  //In other words, no damage is actually taken
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
			{
				damage*=0.25;
				return Plugin_Changed;
			}

			if(shield[client] && damage)
			{
				RemoveShield(client, attacker, position);
				return Plugin_Handled;
			}

			if(TF2_GetPlayerClass(client)==TFClass_Soldier
			&& IsValidEntity((weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)))
			&& GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==226  //Battalion's Backup
			&& !(FF2Flags[client] & FF2FLAG_ISBUFFED))
			{
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
			}
		}
	}
	else
	{
		new boss=GetBossIndex(client);
		if(boss!=-1)
		{
			if(attacker<=MaxClients)
			{
				new index;
				decl String:classname[64];
				if(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients)
				{
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(!StrContains(classname, "eyeball_boss"))  //Dang spell Monoculuses
					{
						index=-1;
						Format(classname, sizeof(classname), "");
					}
					else
					{
						index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					}
				}
				else
				{
					index=-1;
					Format(classname, sizeof(classname), "");
				}

				/*if(KvJumpToKey(kvWeaponMods, "onhit"))
				{
					//TODO
				}

				if(KvJumpToKey(kvWeaponMods, "ontakedamage"))
				{
					//TODO
				}*/

				//Sniper rifles aren't handled by the switch/case because of the amount of reskins there are
				if(!StrContains(classname, "tf_weapon_sniperrifle"))
				{
					if(CheckRoundState()!=FF2RoundState_RoundEnd)
					{
						new Float:charge=(IsValidEntity(weapon) && weapon>MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
						if(index==752)  //Hitman's Heatmaker
						{
							new Float:focus=10+(charge/10);
							if(TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
							{
								focus/=3;
							}
							new Float:rage=GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
							SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage+focus>100) ? 100.0 : rage+focus);
						}
						else if(index!=230 && index!=402 && index!=526 && index!=30665)  //Sydney Sleeper, Bazaar Bargain, Machina, Shooting Star
						{
							new Float:time=(GlowTimer[boss]>10 ? 1.0 : 2.0);
							time+=(GlowTimer[boss]>10 ? (GlowTimer[boss]>20 ? 1.0 : 2.0) : 4.0)*(charge/100.0);
							SetClientGlow(Boss[boss], time);
							if(GlowTimer[boss]>30.0)
							{
								GlowTimer[boss]=30.0;
							}
						}

						if(!(damagetype & DMG_CRIT) && !TF2_IsPlayerInCondition(attacker, TFCond_CritCola) && !TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
						{
							if(index!=230 || BossCharge[boss][0]>90.0)  //Sydney Sleeper
							{
								damage*=3.0;
							}
							else
							{
								damage*=2.4;
							}
							return Plugin_Changed;
						}
					}
				}

				switch(index)
				{
					case 61, 1006:  //Ambassador, Festive Ambassador
					{
						if(damagecustom==TF_CUSTOM_HEADSHOT)
						{
							damage=255.0;
							return Plugin_Changed;
						}
					}
					case 132, 266, 482, 1082:  //Eyelander, HHHH, Nessie's Nine Iron, Festive Eyelander
					{
						IncrementHeadCount(attacker);
					}
					case 214:  //Powerjack
					{
						new health=GetClientHealth(attacker);
						new newhealth=health+50;
						if(newhealth<=GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						{
							SetEntityHealth(attacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
					}
					case 310:  //Warrior's Spirit
					{
						new health=GetClientHealth(attacker);
						new newhealth=health+50;
						if(newhealth<=GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						{
							SetEntityHealth(attacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
					}
					case 317:  //Candycane
					{
						SpawnSmallHealthPackAt(client, TF2_GetClientTeam(attacker));
					}
					case 327:  //Claidheamh Mòr
					{
						new health=GetClientHealth(attacker);
						new newhealth=health+25;
						if(newhealth<=GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						{
							SetEntityHealth(attacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}

						new Float:charge=GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter");
						if(charge+25.0>=100.0)
						{
							SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", 100.0);
						}
						else
						{
							SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", charge+25.0);
						}
					}
					case 355:  //Fan O' War
					{
						if(BossCharge[boss][0]>0.0)
						{
							BossCharge[boss][0]-=5.0;
							if(BossCharge[boss][0]<0.0)
							{
								BossCharge[boss][0]=0.0;
							}
						}
					}
					case 357:  //Half-Zatoichi
					{
						SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
						if(GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy")<1)
						{
							SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
						}

						new health=GetClientHealth(attacker);
						new max=GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						new newhealth=health+50;
						if(health<max+100)
						{
							if(newhealth>max+100)
							{
								newhealth=max+100;
							}
							SetEntityHealth(attacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
					}
					case 416:  //Market Gardener (courtesy of Chdata)
					{
						if(FF2Flags[attacker] & FF2FLAG_BLAST_JUMPING)
						{
							damage=(Pow(float(BossHealthMax[boss]), 0.74074)+512.0-(Marketed[client]/128.0*float(BossHealthMax[boss])));
							damagetype|=DMG_CRIT;

							if(Marketed[client]<5)
							{
								Marketed[client]++;
							}

							PrintHintText(attacker, "%t", "Market Gardener");  //You just market-gardened the boss!
							PrintHintText(client, "%t", "Market Gardened");  //You just got market-gardened!

							EmitSoundToClient(attacker, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);
							EmitSoundToClient(client, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);
							return Plugin_Changed;
						}
					}
					case 525, 595:  //Diamondback, Manmelter
					{
						if(GetEntProp(attacker, Prop_Send, "m_iRevengeCrits"))  //If a revenge crit was used, give a damage bonus
						{
							damage=255.0;
							return Plugin_Changed;
						}
					}
					case 528:  //Short Circuit
					{
						if(circuitStun)
						{
							TF2_StunPlayer(client, circuitStun, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
							EmitSoundToAll("weapons/barret_arm_zap.wav", client);
							EmitSoundToClient(client, "weapons/barret_arm_zap.wav");
						}
					}
					case 593:  //Third Degree
					{
						new healers[MAXPLAYERS];
						new healerCount;
						for(new healer; healer<=MaxClients; healer++)
						{
							if(IsValidClient(healer) && IsPlayerAlive(healer) && (GetHealingTarget(healer, true)==attacker))
							{
								healers[healerCount]=healer;
								healerCount++;
							}
						}

						for(new healer; healer<healerCount; healer++)
						{
							if(IsValidClient(healers[healer]) && IsPlayerAlive(healers[healer]))
							{
								new medigun=GetPlayerWeaponSlot(healers[healer], TFWeaponSlot_Secondary);
								if(IsValidEntity(medigun))
								{
									decl String:medigunClassname[64];
									GetEntityClassname(medigun, medigunClassname, sizeof(medigunClassname));
									if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
									{
										new Float:uber=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+(0.1/healerCount);
										if(uber>1.0)
										{
											uber=1.0;
										}
										SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
									}
								}
							}
						}
					}
					case 594:  //Phlogistinator
					{
						if(!TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph))
						{
							damage/=2.0;
							return Plugin_Changed;
						}
					}
					case 1099:  //Tide Turner
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", 100.0);
					}
					case 1104:
					{
						static Float:airStrikeDamage;
						airStrikeDamage+=damage;
						if(airStrikeDamage>=200.0)
						{
							SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
							airStrikeDamage-=200.0;
						}
					}
				}

				if(damagecustom==TF_CUSTOM_BACKSTAB)
				{
					damage=BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.12-Stabbed[boss]/90);
					damagetype|=DMG_CRIT;
					damagecustom=0;

					EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
					EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
					EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);

					new viewmodel=GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
					if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
					{
						new melee=GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
						new animation=41;
						switch(melee)
						{
							case 225, 356, 423, 461, 574, 649, 1071:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan
							{
								animation=15;
							}
							case 638:  //Sharp Dresser
							{
								animation=31;
							}
						}
						SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
					}

					if(!(FF2Flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(attacker, "%t", "Backstab");
					}

					if(!(FF2Flags[client] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(client, "%t", "Backstabbed");
					}

					if(index==225 || index==574)  //Your Eternal Reward, Wanga Prick
					{
						CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
					}
					else if(index==356)  //Conniver's Kunai
					{
						new health=GetClientHealth(attacker)+200;
						if(health>500)
						{
							health=500;
						}
						SetEntityHealth(attacker, health);
					}
					else if(index==461)  //Big Earner
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", 100.0);  //Full cloak
						TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);  //Speed boost
					}

					if(GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary)==525)  //Diamondback
					{
						SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits")+2);
					}

					decl String:sound[PLATFORM_MAX_PATH];
					if(FindSound("stabbed", sound, sizeof(sound), boss))
					{
						EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, client);
						EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, client);
					}

					if(Stabbed[boss]<3)
					{
						Stabbed[boss]++;
					}
					return Plugin_Changed;
				}
				else if(damagecustom==TF_CUSTOM_TELEFRAG)
				{
					damagecustom=0;
					if(!IsPlayerAlive(attacker))
					{
						damage=1.0;
						return Plugin_Changed;
					}
					damage=(BossHealth[boss]>9001 ? 9001.0 : float(GetEntProp(Boss[boss], Prop_Send, "m_iHealth"))+90.0);

					new teleowner=FindTeleOwner(attacker);
					if(IsValidClient(teleowner) && teleowner!=attacker)
					{
						Damage[teleowner]+=9001*3/5;
						if(!(FF2Flags[teleowner] & FF2FLAG_HUDDISABLED))
						{
							PrintHintText(teleowner, "TELEFRAG ASSIST!  Nice job setting it up!");
						}
					}

					if(!(FF2Flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(attacker, "TELEFRAG! You are a pro!");
					}

					if(!(FF2Flags[client] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(client, "TELEFRAG! Be careful around quantum tunneling devices!");
					}
					return Plugin_Changed;
				}
				else if(damagecustom==TF_CUSTOM_BOOTS_STOMP)
				{
					damage*=5;
					return Plugin_Changed;
				}
			}
			else
			{
				decl String:classname[64];
				if(GetEntityClassname(attacker, classname, sizeof(classname)) && StrEqual(classname, "trigger_hurt", false))
				{
					new Action:action;
					Call_StartForward(OnTriggerHurt);
					Call_PushCell(boss);
					Call_PushCell(attacker);
					new Float:damage2=damage;
					Call_PushFloatRef(damage2);
					Call_Finish(action);
					if(action!=Plugin_Stop && action!=Plugin_Handled)
					{
						if(action==Plugin_Changed)
						{
							damage=damage2;
						}

						if(damage>1500.0)
						{
							damage=1500.0;
						}

						BossHealth[boss]-=RoundFloat(damage);
						BossCharge[boss][0]+=damage*100.0/BossRageDamage[boss];
						if(BossHealth[boss]<=0)  //TODO: Wat
						{
							damage*=5;
						}

						if(BossCharge[boss][0]>100.0)
						{
							BossCharge[boss][0]=100.0;
						}
						return Plugin_Changed;
					}
					else
					{
						return action;
					}
				}
			}

			if(BossCharge[boss][0]>100.0)
			{
				BossCharge[boss][0]=100.0;
			}
		}
		else
		{
			new index=(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if(index==307)  //Ullapool Caber
			{
				if(detonations[attacker]<allowedDetonations)
				{
					detonations[attacker]++;
					PrintHintText(attacker, "%t", "Detonations Left", allowedDetonations-detonations[attacker]);
					if(allowedDetonations-detonations[attacker])  //Don't reset their caber if they have 0 detonations left
					{
						SetEntProp(weapon, Prop_Send, "m_bBroken", 0);
						SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public OnTakeDamageAlivePost(client, attacker, inflictor, Float:damageFloat, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3], damagecustom)
{
	if(Enabled && IsBoss(client))
	{
		new boss=GetBossIndex(client);
		new damage=RoundFloat(damageFloat);
		for(new lives=1; lives<BossLives[boss]; lives++)
		{
			if(BossHealth[boss]-damage<=BossHealthMax[boss]*lives)
			{
				SetEntityHealth(client, (BossHealth[boss]-damage)-BossHealthMax[boss]*(lives-1));  //Set the health early to avoid the boss dying from fire, etc.

				new Action:action, bossLives=BossLives[boss];  //Used for the forward
				Call_StartForward(OnLoseLife);
				Call_PushCell(boss);
				Call_PushCellRef(bossLives);
				Call_PushCell(BossLivesMax[boss]);
				Call_Finish(action);
				if(action==Plugin_Stop || action==Plugin_Handled)  //Don't allow any damage to be taken and also don't let the life-loss go through
				{
					SetEntityHealth(client, BossHealth[boss]);
					return;
				}
				else if(action==Plugin_Changed)
				{
					if(bossLives>BossLivesMax[boss])  //If the new amount of lives is greater than the max, set the max to the new amount
					{
						BossLivesMax[boss]=bossLives;
					}
					BossLives[boss]=lives=bossLives;
				}

				decl String:ability[PLATFORM_MAX_PATH];  //FIXME: Create a new variable for the translation string later on
				new Handle:kv=GetArrayCell(bossesArray, character[boss]);
				KvRewind(kv);
				if(KvJumpToKey(kv, "abilities"))
				{
					KvGotoFirstSubKey(kv);
					do
					{
						decl String:pluginName[64];
						KvGetSectionName(kv, pluginName, sizeof(pluginName));
						KvGotoFirstSubKey(kv);
						do
						{
							decl String:abilityName[64];
							KvGetSectionName(kv, abilityName, sizeof(abilityName));
							if(KvGetNum(kv, "slot")!=-1) // Only activate for life-loss abilities
							{
								continue;
							}

							KvGetString(kv, "life", ability, 10, "");
							if(!ability[0]) // Just a regular ability that doesn't care what life the boss is on
							{
								UseAbility(boss, pluginName, abilityName, -1);
							}
							else // But these do
							{
								decl String:temp[3];
								new Handle:livesArray=CreateArray(sizeof(temp));
								new count=ExplodeStringIntoArrayList(ability, " ", livesArray, sizeof(temp));
								for(new n; n<count; n++)
								{
									GetArrayString(livesArray, n, temp, sizeof(temp));
									if(StringToInt(temp)==BossLives[boss])
									{
										UseAbility(boss, pluginName, abilityName, -1);
										break;
									}
								}
							}
						}
						while(KvGotoNextKey(kv));
						KvGoBack(kv);
					}
					while(KvGotoNextKey(kv));
				}
				BossLives[boss]=lives;

				decl String:bossName[64];
				KvRewind(kv);
				KvGetString(kv, "name", bossName, sizeof(bossName), "=Failed name=");

				strcopy(ability, sizeof(ability), BossLives[boss]==1 ? "Boss with 1 Life Left" : "Boss with Multiple Lives Left");
				for(new target=1; target<=MaxClients; target++)
				{
					if(IsValidClient(target) && !(FF2Flags[target] & FF2FLAG_HUDDISABLED))
					{
						SetGlobalTransTarget(target);
						PrintCenterText(target, "%t", ability, bossName, BossLives[boss]);
					}
				}

				if(BossLives[boss]==1 && FindSound("last life", ability, sizeof(ability), boss))
				{
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, ability, client);
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, ability, client);
				}
				else if(FindSound("next life", ability, sizeof(ability), boss))
				{
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, ability, client);
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, ability, client);
				}

				UpdateHealthBar();
				break;
			}
		}

		BossHealth[boss]-=damage;
		BossCharge[boss][0]+=damage*100.0/BossRageDamage[boss];

		if(IsValidClient(attacker))
		{
			Damage[attacker]+=damage;
		}

		new healers[MaxClients+1];
		new healerCount;
		for(new target; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && IsPlayerAlive(target) && (GetHealingTarget(target, true)==attacker))
			{
				healers[healerCount]=target;
				healerCount++;
			}
		}

		for(new target; target<healerCount; target++)
		{
			if(IsValidClient(healers[target]) && IsPlayerAlive(healers[target]))
			{
				if(damage<10 || uberTarget[healers[target]]==attacker)
				{
					Damage[healers[target]]+=damage;
				}
				else
				{
					Damage[healers[target]]+=damage/(healerCount+1);
				}
			}
		}

		if(BossCharge[boss][0]>100.0)
		{
			BossCharge[boss][0]=100.0;
		}
		UpdateHealthBar();
	}
}

public Action:TF2_OnPlayerTeleport(client, teleporter, &bool:result)
{
	if(Enabled && IsBoss(client))
	{
		switch(bossTeleportation)
		{
			case -1:  //No bosses are allowed to use teleporters
			{
				result=false;
			}
			case 1:  //All bosses are allowed to use teleporters
			{
				result=true;
			}
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:OnGetMaxHealth(client, &maxHealth)
{
	if(Enabled && IsBoss(client))
	{
		new boss=GetBossIndex(client);
		SetEntityHealth(client, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1));
		maxHealth=BossHealthMax[boss];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock GetClientCloakIndex(client)
{
	if(!IsValidClient(client, false))
	{
		return -1;
	}

	new weapon=GetPlayerWeaponSlot(client, 4);
	if(!IsValidEntity(weapon))
	{
		return -1;
	}

	decl String:classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if(strncmp(classname, "tf_wea", 6, false))
	{
		return -1;
	}
	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

stock SpawnSmallHealthPackAt(client, TFTeam:team)
{
	if(!IsValidClient(client, false) || !IsPlayerAlive(client))
	{
		return;
	}

	new healthpack=CreateEntityByName("item_healthkit_small"), Float:position[3];
	GetClientAbsOrigin(client, position);
	position[2]+=20.0;
	if(IsValidEntity(healthpack))
	{
		DispatchKeyValue(healthpack, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(healthpack);
		SetEntProp(healthpack, Prop_Send, "m_iTeamNum", _:team, 4);
		SetEntityMoveType(healthpack, MOVETYPE_VPHYSICS);
		new Float:velocity[3];//={float(GetRandomInt(-10, 10)), float(GetRandomInt(-10, 10)), 50.0};  //Q_Q
		velocity[0]=float(GetRandomInt(-10, 10)), velocity[1]=float(GetRandomInt(-10, 10)), velocity[2]=50.0;  //I did this because setting it on the creation of the vel variable was creating a compiler error for me.
		TeleportEntity(healthpack, position, NULL_VECTOR, velocity);
	}
}

stock IncrementHeadCount(client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
	{
		TF2_AddCondition(client, TFCond_DemoBuff, -1.0);
	}

	new decapitations=GetEntProp(client, Prop_Send, "m_iDecapitations");
	new health=GetClientHealth(client);
	SetEntProp(client, Prop_Send, "m_iDecapitations", decapitations+1);
	SetEntityHealth(client, health+15);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}

stock FindTeleOwner(client)
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return -1;
	}

	new teleporter=GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	decl String:classname[32];
	if(IsValidEntity(teleporter) && GetEntityClassname(teleporter, classname, sizeof(classname)) && StrEqual(classname, "obj_teleporter", false))
	{
		new owner=GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
		if(IsValidClient(owner, false))
		{
			return owner;
		}
	}
	return -1;
}

stock TF2_IsPlayerCritBuffed(client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond:34) || TF2_IsPlayerInCondition(client, TFCond:35) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph));
}

public Action:Timer_DisguiseBackstab(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(IsValidClient(client, false))
	{
		RandomlyDisguise(client);
	}
	return Plugin_Continue;
}

stock AssignTeam(client, TFTeam:team)
{
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))  //Living spectator check: 0 means that no class is selected
	{
		Debug("%N does not have a desired class!", client);
		if(IsBoss(client))
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", KvGetNum(GetArrayCell(bossesArray, character[Boss[client]]), "class", 1));  //So we assign one to prevent living spectators
		}
		else
		{
			Debug("%N was not a boss and did not have a desired class!  Please report this to https://github.com/50DKP/FF2-Official");
		}
	}

	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	TF2_ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);

	if(GetEntProp(client, Prop_Send, "m_iObserverMode") && IsPlayerAlive(client))  //Welp
	{
		Debug("%N is a living spectator!  Please report this to https://github.com/50DKP/FF2-Official", client);
		if(IsBoss(client))
		{
			TF2_SetPlayerClass(client, TFClassType:KvGetNum(GetArrayCell(bossesArray, character[Boss[client]]), "class", 1));
		}
		else
		{
			Debug("Additional information: %N was not a boss");
			TF2_SetPlayerClass(client, TFClass_Scout);
		}
		TF2_RespawnPlayer(client);
	}
}

stock RandomlyDisguise(client)	//Original code was mecha's, but the original code is broken and this uses a better method now.
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		new disguiseTarget=-1;
		new TFTeam:team=TF2_GetClientTeam(client);

		new Handle:disguiseArray=CreateArray();
		for(new clientcheck; clientcheck<=MaxClients; clientcheck++)
		{
			if(IsValidClient(clientcheck) && TF2_GetClientTeam(clientcheck)==team && clientcheck!=client)
			{
				PushArrayCell(disguiseArray, clientcheck);
			}
		}

		if(GetArraySize(disguiseArray)<=0)
		{
			disguiseTarget=client;
		}
		else
		{
			disguiseTarget=GetArrayCell(disguiseArray, GetRandomInt(0, GetArraySize(disguiseArray)-1));
			if(!IsValidClient(disguiseTarget))
			{
				disguiseTarget=client;
			}
		}

		new class=GetRandomInt(0, 4);
		new TFClassType:classArray[]={TFClass_Scout, TFClass_Pyro, TFClass_Medic, TFClass_Engineer, TFClass_Sniper};
		CloseHandle(disguiseArray);

		if(TF2_GetPlayerClass(client)==TFClass_Spy)
		{
			TF2_DisguisePlayer(client, team, classArray[class], disguiseTarget);
		}
		else
		{
			TF2_AddCondition(client, TFCond_Disguised, -1.0);
			SetEntProp(client, Prop_Send, "m_nDisguiseTeam", _:team);
			SetEntProp(client, Prop_Send, "m_nDisguiseClass", classArray[class]);
			SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", disguiseTarget);
			SetEntProp(client, Prop_Send, "m_iDisguiseHealth", 200);
		}
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(Enabled && IsBoss(client) && CheckRoundState()==FF2RoundState_RoundRunning && !TF2_IsPlayerCritBuffed(client) && !BossCrits)
	{
		result=false;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock GetClientWithMostQueuePoints(bool:omit[])
{
	new winner;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && GetClientQueuePoints(client)>=GetClientQueuePoints(winner) && !omit[client])
		{
			if(SpecForceBoss || TF2_GetClientTeam(client)>TFTeam_Spectator)
			{
				winner=client;
			}
		}
	}
	return winner;
}

stock LastBossIndex()
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(!Boss[client])
		{
			return client-1;
		}
	}
	return 0;
}

stock Operate(Handle:sumArray, &bracket, Float:value, Handle:_operator)
{
	new Float:sum=GetArrayCell(sumArray, bracket);
	switch(GetArrayCell(_operator, bracket))
	{
		case Operator_Add:
		{
			SetArrayCell(sumArray, bracket, sum+value);
		}
		case Operator_Subtract:
		{
			SetArrayCell(sumArray, bracket, sum-value);
		}
		case Operator_Multiply:
		{
			SetArrayCell(sumArray, bracket, sum*value);
		}
		case Operator_Divide:
		{
			if(!value)
			{
				LogError("[FF2 Bosses] Detected a divide by 0!");
				bracket=0;
				return;
			}
			SetArrayCell(sumArray, bracket, sum/value);
		}
		case Operator_Exponent:
		{
			SetArrayCell(sumArray, bracket, Pow(sum, value));
		}
		default:
		{
			SetArrayCell(sumArray, bracket, value);  //This means we're dealing with a constant
		}
	}
	SetArrayCell(_operator, bracket, Operator_None);
}

stock OperateString(Handle:sumArray, &bracket, String:value[], size, Handle:_operator)
{
	if(!StrEqual(value, ""))  //Make sure 'value' isn't blank
	{
		Operate(sumArray, bracket, StringToFloat(value), _operator);
		strcopy(value, size, "");
	}
}

/*
 * Parses a mathematical formula and returns the result,
 * or `defaultValue` if there is an error while parsing
 *
 * Variables may be present in the formula as long as they
 * are in the format `{variable}`.  Unknown variables will
 * be passed to the `OnParseUnknownVariable` forward
 *
 * Known variables include:
 * - players
 * - lives
 * - health
 * - speed
 *
 * @param boss          Boss index
 * @param key           The key to retrieve the formula from.  If the
 *                      key is nested, the nested sections must be
 *                      delimited by a `>` symbol like so:
 *                      "plugin name > ability name > distance"
 * @param defaultValue  The default value to return in case of error
 * @return The value of the formula, or `defaultValue` in case of error
 */
stock ParseFormula(boss, const String:key[], defaultValue)
{
	decl String:formula[1024], String:bossName[64];
	new Handle:kv=GetArrayCell(bossesArrayShadow, character[boss]);
	KvRewind(kv);
	KvGetString(kv, "name", bossName, sizeof(bossName), "=Failed name=");

	decl String:keyPortions[5][128];
	new portions=ExplodeString(key, ">", keyPortions, sizeof(keyPortions), 128);
	for(new i=1; i<portions; i++)
	{
		KvJumpToKey(kv, keyPortions[i]);
	}
	KvGetString(kv, keyPortions[portions-1], formula, sizeof(formula));

	if(!formula[0])
	{
		return defaultValue;
	}

	new size=1;
	new matchingBrackets;
	for(new i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i]=='(')
		{
			if(!matchingBrackets)
			{
				size++;
			}
			else
			{
				matchingBrackets--;
			}
		}
		else if(formula[i]==')')
		{
			matchingBrackets++;
		}
	}

	new Handle:sumArray=CreateArray(_, size), Handle:_operator=CreateArray(_, size);
	new bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	new bool:escapeCharacter;
	SetArrayCell(sumArray, 0, 0.0);  //TODO:  See if these can be placed naturally in the loop
	SetArrayCell(_operator, bracket, Operator_None);

	new String:currentCharacter[2], String:value[16], String:variable[16];  //We don't decl these because we directly append characters to them and there's no point in decl'ing currentCharacter
	for(new i; i<=strlen(formula); i++)
	{
		currentCharacter[0]=formula[i];  //Find out what the next char in the formula is
		switch(currentCharacter[0])
		{
			case ' ', '\t':  //Ignore whitespace
			{
				continue;
			}
			case '(':
			{
				bracket++;  //We've just entered a new parentheses so increment the bracket value
				SetArrayCell(sumArray, bracket, 0.0);
				SetArrayCell(_operator, bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(GetArrayCell(_operator, bracket)!=Operator_None)  //Something like (5*)
				{
					LogError("[FF2 Bosses] %s's %s formula has an invalid operator at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogError("[FF2 Bosses] %s's %s formula has an unbalanced parentheses at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				Operate(sumArray, bracket, GetArrayCell(sumArray, bracket+1), _operator);
			}
			case '\0':  //End of formula
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), currentCharacter);  //Constant?  Just add it to the current value
			}
			/*case 'n', 'x':  //n and x denote player variables
			{
				Operate(sumArray, bracket, float(playing), _operator);
			}*/
			case '{':
			{
				escapeCharacter=true;
			}
			case '}':
			{
				if(!escapeCharacter)
				{
					LogError("[FF2 Bosses] %s's %s formula has an invalid escape character at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}
				escapeCharacter=false;

				if(StrEqual(variable, "players", false))
				{
					Operate(sumArray, bracket, float(playing), _operator);
				}
				else if(StrEqual(variable, "health", false))
				{
					Operate(sumArray, bracket, float(BossHealth[boss]), _operator);
				}
				else if(StrEqual(variable, "lives", false))
				{
					Operate(sumArray, bracket, float(BossLives[boss]), _operator);
				}
				else if(StrEqual(variable, "speed", false))
				{
					Operate(sumArray, bracket, BossSpeed[boss], _operator);
				}
				else
				{
					new Action:action, Float:variableValue;
					Call_StartForward(OnParseUnknownVariable);
					Call_PushString(variable);
					Call_PushFloatRef(variableValue);
					Call_Finish();

					if(action==Plugin_Changed)
					{
						Operate(sumArray, bracket, variableValue, _operator);
					}
					else
					{
						LogError("[FF2 Bosses] %s's %s formula has an unknown variable '%s'", bossName, key, variable);
						CloseHandle(sumArray);
						CloseHandle(_operator);
						return defaultValue;
					}
				}
				Format(variable, sizeof(variable), ""); // Reset the variable holder
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(currentCharacter[0])
				{
					case '+':
					{
						SetArrayCell(_operator, bracket, Operator_Add);
					}
					case '-':
					{
						SetArrayCell(_operator, bracket, Operator_Subtract);
					}
					case '*':
					{
						SetArrayCell(_operator, bracket, Operator_Multiply);
					}
					case '/':
					{
						SetArrayCell(_operator, bracket, Operator_Divide);
					}
					case '^':
					{
						SetArrayCell(_operator, bracket, Operator_Exponent);
					}
				}
			}
			default:
			{
				if(escapeCharacter)  //Absorb all the characters into 'variable' if we hit an escape character
				{
					StrCat(variable, sizeof(variable), currentCharacter);
				}
				else
				{
					LogError("[FF2 Bosses] %s's %s formula has an invalid character at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}
			}
		}
	}

	new result=RoundFloat(GetArrayCell(sumArray, 0));
	CloseHandle(sumArray);
	CloseHandle(_operator);
	if(result<=0)
	{
		LogError("[FF2 Bosses] %s has an invalid %s formula, using default!", bossName, key);
		return defaultValue;
	}

	if(bMedieval && StrEqual(key, "health"))
	{
		return RoundFloat(result/3.6);  //TODO: Make this configurable
	}
	return result;
}

stock GetAbilityArgument(boss, const String:pluginName[], const String:abilityName[], const String:argument[], defaultValue=0)
{
	if(HasAbility(boss, pluginName, abilityName))
	{
		return KvGetNum(GetArrayCell(bossesArrayShadow, character[boss]), argument, defaultValue);
	}
	return defaultValue;
}

stock Float:GetAbilityArgumentFloat(boss, const String:pluginName[], const String:abilityName[], const String:argument[], Float:defaultValue=0.0)
{
	if(HasAbility(boss, pluginName, abilityName))
	{
		return KvGetFloat(GetArrayCell(bossesArrayShadow, character[boss]), argument, defaultValue);
	}
	return defaultValue;
}

stock GetAbilityArgumentString(boss, const String:pluginName[], const String:abilityName[], const String:argument[], String:abilityString[], length, const String:defaultValue[]="")
{
	strcopy(abilityString, length, defaultValue);
	if(HasAbility(boss, pluginName, abilityName))
	{
		KvGetString(GetArrayCell(bossesArrayShadow, character[boss]), argument, abilityString, length, defaultValue);
	}
}

stock bool:FindSound(const String:sound[], String:file[], length, boss=0, bool:ability=false, slot=0)
{
	new Handle:kv=GetArrayCell(bossesArrayShadow, character[boss]);
	if(boss<0 || character[boss]<0 || !kv)
	{
		return false;
	}

	KvRewind(kv);
	if(!KvJumpToKey(kv, "sounds"))
	{
		return false;  //Boss doesn't have any sounds
	}

	new Handle:soundsArray=CreateArray(PLATFORM_MAX_PATH);
	decl String:match[PLATFORM_MAX_PATH];
	KvGotoFirstSubKey(kv);
	do  //Just keep looping until there's no keys left
	{
		if(KvGetNum(kv, sound))
		{
			if(!ability || KvGetNum(kv, "slot")==slot)
			{
				KvGetSectionName(kv, match, sizeof(match));
				if(FindStringInArray(soundsArray, match)>=0)
				{
					decl String:bossName[64];
					KvRewind(kv);
					KvGetString(kv, "name", bossName, sizeof(bossName));
					PrintToServer("[FF2 Bosses] Character %s has a duplicate sound '%s'!", bossName, match);
					continue; // We ignore all duplicates
				}
				PushArrayString(soundsArray, match);
			}
		}
	}
	while(KvGotoNextKey(kv));

	if(!GetArraySize(soundsArray))
	{
		return false;  //No sounds matching what we want
	}

	GetArrayString(soundsArray, GetRandomInt(0, GetArraySize(soundsArray)-1), file, length);
	return true;
}

ForceTeamWin(TFTeam:team)
{
	new entity=FindEntityByClassname2(-1, "team_control_point_master");
	if(!IsValidEntity(entity))
	{
		entity=CreateEntityByName("team_control_point_master");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "Enable");
	}
	SetVariantInt(_:team);
	AcceptEntityInput(entity, "SetWinner");
}

public bool:PickCharacter(boss, companion)
{
	if(boss==companion)
	{
		character[boss]=Incoming[boss];
		Incoming[boss]=-1;
		if(character[boss]!=-1)  //We've already picked a boss through Command_SetNextBoss
		{
			new Action:action;
			Call_StartForward(OnBossSelected);
			Call_PushCell(boss);
			new newCharacter=character[boss];
			Call_PushCellRef(newCharacter);
			decl String:newName[64];
			KvRewind(GetArrayCell(bossesArray, character[boss]));
			KvGetString(GetArrayCell(bossesArray, character[boss]), "name", newName, sizeof(newName));
			Call_PushStringEx(newName, sizeof(newName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(true);  //Preset
			Call_Finish(action);
			if(action==Plugin_Changed)
			{
				if(newName[0])
				{
					decl String:characterName[64];
					new foundExactMatch=-1, foundPartialMatch=-1;
					for(new characterIndex; characterIndex<GetArraySize(bossesArray) && GetArrayCell(bossesArray, characterIndex); characterIndex++)
					{
						KvRewind(GetArrayCell(bossesArray, characterIndex));
						KvGetString(GetArrayCell(bossesArray, characterIndex), "name", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch=characterIndex;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false)!=-1)
						{
							foundPartialMatch=characterIndex;
						}

						//Do the same thing as above here, but look at the filename instead of the boss name
						KvGetString(GetArrayCell(bossesArray, characterIndex), "filename", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch=characterIndex;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false)!=-1)
						{
							foundPartialMatch=characterIndex;
						}
					}

					if(foundExactMatch!=-1)
					{
						character[boss]=foundExactMatch;
					}
					else if(foundPartialMatch!=-1)
					{
						character[boss]=foundPartialMatch;
					}
					else
					{
						return false;
					}
					PrecacheCharacter(character[boss]);
					return true;
				}
				character[boss]=newCharacter;
				PrecacheCharacter(character[boss]);
				return true;
			}
			PrecacheCharacter(character[boss]);
			return true;
		}

		for(new tries; tries<100; tries++)
		{
			character[boss]=GetRandomInt(0, GetArraySize(chancesArray)-1);

			// TODO: It would be awesome if we didn't have to check for this.
			// Then we wouldn't need to wrap all of this in a for loop.
			// FindCharacters() doesn't deal with the individual boss KVs though...
			// And supplying 0 as the boss's chance won't load the character.
			KvRewind(GetArrayCell(bossesArray, character[boss]));
			if(KvGetNum(GetArrayCell(bossesArray, character[boss]), "hidden"))
			{
				character[boss]=-1;
				continue;
			}
			break;
		}
	}
	else
	{
		decl String:bossName[64], String:companionName[64];
		KvRewind(GetArrayCell(bossesArray, character[boss]));
		KvGetString(GetArrayCell(bossesArray, character[boss]), "companion", companionName, sizeof(companionName), "=Failed companion name=");

		new characterIndex;
		while(characterIndex<GetArraySize(bossesArray))  //Loop through all the bosses to find the companion we're looking for
		{
			KvRewind(GetArrayCell(bossesArray, characterIndex));
			KvGetString(GetArrayCell(bossesArray, characterIndex), "name", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				character[companion]=characterIndex;
				break;
			}

			KvGetString(GetArrayCell(bossesArray, characterIndex), "filename", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				character[companion]=characterIndex;
				break;
			}
			characterIndex++;
		}

		if(characterIndex==GetArraySize(bossesArray))  //Companion not found
		{
			return false;
		}
	}

	//All of the following uses `companion` because it will always be the boss index we want
	new Action:action;
	Call_StartForward(OnBossSelected);
	Call_PushCell(companion);
	new newCharacter=character[companion];
	Call_PushCellRef(newCharacter);
	decl String:newName[64];
	KvRewind(GetArrayCell(bossesArray, character[companion]));
	KvGetString(GetArrayCell(bossesArray, character[companion]), "name", newName, sizeof(newName));
	Call_PushStringEx(newName, sizeof(newName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(false);  //Not preset
	Call_Finish(action);
	if(action==Plugin_Changed)
	{
		if(newName[0])
		{
			decl String:characterName[64];
			new foundExactMatch=-1, foundPartialMatch=-1;
			for(new characterIndex; characterIndex<GetArraySize(bossesArray) && GetArrayCell(bossesArray, characterIndex); characterIndex++)
			{
				KvRewind(GetArrayCell(bossesArray, characterIndex));
				KvGetString(GetArrayCell(bossesArray, characterIndex), "name", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch=characterIndex;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch=characterIndex;
				}

				//Do the same thing as above here, but look at the filename instead of the boss name
				KvGetString(GetArrayCell(bossesArray, characterIndex), "filename", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch=characterIndex;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch=characterIndex;
				}
			}

			if(foundExactMatch!=-1)
			{
				character[companion]=foundExactMatch;
			}
			else if(foundPartialMatch!=-1)
			{
				character[companion]=foundPartialMatch;
			}
			else
			{
				return false;
			}
			PrecacheCharacter(character[companion]);
			return true;
		}
		character[companion]=newCharacter;
		PrecacheCharacter(character[companion]);
		return true;
	}
	PrecacheCharacter(character[companion]);
	return true;
}

FindCompanion(boss, players, bool:omit[])
{
	static playersNeeded=3;
	decl String:companionName[64];
	KvRewind(GetArrayCell(bossesArray, character[boss]));
	KvGetString(GetArrayCell(bossesArray, character[boss]), "companion", companionName, sizeof(companionName));
	if(playersNeeded<players && strlen(companionName))  //Only continue if we have enough players and if the boss has a companion
	{
		new companion=GetClientWithMostQueuePoints(omit);
		Boss[companion]=companion;  //Woo boss indexes!
		omit[companion]=true;
		if(PickCharacter(boss, companion))  //TODO: This is a bit misleading
		{
			playersNeeded++;
			FindCompanion(companion, players, omit);  //Make sure this companion doesn't have a companion of their own
		}
		else  //Can't find the companion's character, so just play without the companion
		{
			LogError("[FF2 Bosses] Could not find boss %s!", companionName);
			Boss[companion]=0;
			omit[companion]=false;
		}
	}
	playersNeeded=3;  //Reset the amount of players needed back to 3 after we're done
}

/*
 * Equips a new weapon for a given client
 *
 * @param client		Client to equip new weapon for
 * @param classname		Classname of the weapon
 * @param index			Index of the weapon
 * @param level			Level of the weapon
 * @param quality		Quality of the weapon
 * @param attributeList	String of attributes in a 'name ; value' pattern (optional)
 *
 * @return				Weapon entity index on success, -1 on failure
 */
stock SpawnWeapon(client, String:classname[], index, level=1, quality=0, String:attributeList[]="")
{
	new Handle:weapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(weapon==INVALID_HANDLE)
	{
		return -1;
	}

	TF2Items_SetClassname(weapon, classname);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	new String:attributes[32][32];
	new count=ExplodeString(attributeList, ";", attributes, 32, 32);

	if(count==1) // ExplodeString returns the original string if no matching delimiter was found so we need to special-case this
	{
		if(attributeList[0]!='\0') // Ignore empty attribute list
		{
			LogError("[FF2 Weapons] Unbalanced attributes array '%s' for weapon %s", attributeList, classname);
			CloseHandle(weapon);
			return -1;
		}
		else
		{
			TF2Items_SetNumAttributes(weapon, 0);
		}
	}
	else if(count % 2) // Unbalanced array, eg "2 ; 10 ; 3"
	{
		LogError("[FF2 Weapons] Unbalanced attributes array '%s' for weapon %s", attributeList, classname);
		CloseHandle(weapon);
		return -1;
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		new i2;
		for(new i; i<count; i+=2)
		{
			new attribute=StringToInt(attributes[i]);
			if(!attribute)
			{
				LogError("[FF2 Weapons] Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				CloseHandle(weapon);
				return -1;
			}

			TF2Items_SetAttribute(weapon, i2, attribute, StringToFloat(attributes[i+1]));
			i2++;
		}
	}

	new entity=TF2Items_GiveNamedItem(client, weapon);
	CloseHandle(weapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

public HintPanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(IsValidClient(client) && (action==MenuAction_Select || (action==MenuAction_Cancel && selection==MenuCancel_Exit)))
	{
		FF2Flags[client]|=FF2FLAG_CLASSHELPED;
	}
	return;
}

public QueuePanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(action==MenuAction_Select && selection==10)
	{
		TurnToZeroPanel(client, client);
	}
	return false;
}


public Action:QueuePanelCmd(client, args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	decl String:text[64];
	new items;
	new bool:added[MaxClients+1];

	new Handle:panel=CreatePanel();
	SetGlobalTransTarget(client);
	Format(text, sizeof(text), "%t", "Boss Queue");  //"Boss Queue"
	SetPanelTitle(panel, text);
	for(new boss; boss<=MaxClients; boss++)  //Add the current bosses to the top of the list
	{
		if(IsBoss(boss))
		{
			added[boss]=true;  //Don't want the bosses to show up again in the actual queue list
			Format(text, sizeof(text), "%N-%i", boss, GetClientQueuePoints(boss));
			DrawPanelItem(panel, text);
			items++;
		}
	}

	DrawPanelText(panel, "---");
	do
	{
		new target=GetClientWithMostQueuePoints(added);  //Get whoever has the highest queue points out of those who haven't been listed yet
		if(!IsValidClient(target))  //When there's no players left, fill up the rest of the list with blank lines
		{
			DrawPanelItem(panel, "");
			items++;
			continue;
		}

		Format(text, sizeof(text), "%N-%i", target, GetClientQueuePoints(target));
		if(client!=target)
		{
			DrawPanelItem(panel, text);
			items++;
		}
		else
		{
			DrawPanelText(panel, text);  //DrawPanelText() is white, which allows the client's points to stand out
		}
		added[target]=true;
	}
	while(items<9);

	Format(text, sizeof(text), "%t (%t)", "Your Queue Points", GetClientQueuePoints(client), "Reset Queue Points");  //"Your queue point(s) is {1} (set to 0)"
	DrawPanelItem(panel, text);

	SendPanelToClient(panel, client, QueuePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public Action:ResetQueuePointsCmd(client, args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	if(client && !args)  //Normal players
	{
		TurnToZeroPanel(client, client);
		return Plugin_Handled;
	}

	if(!client)  //No confirmation for console
	{
		TurnToZeroPanelH(INVALID_HANDLE, MenuAction_Select, client, 1);
		return Plugin_Handled;
	}

	new AdminId:admin=GetUserAdmin(client);	 //Normal players
	if((admin==INVALID_ADMIN_ID) || !GetAdminFlag(admin, Admin_Cheats))
	{
		TurnToZeroPanel(client, client);
		return Plugin_Handled;
	}

	if(args!=1)  //Admins
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_resetqueuepoints <target>");
		return Plugin_Handled;
	}

	decl String:pattern[MAX_TARGET_LENGTH];
	GetCmdArg(1, pattern, sizeof(pattern));
	new String:targetName[MAX_TARGET_LENGTH];
	new targets[MAXPLAYERS], matches;
	new bool:targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, 1, 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches>1)
	{
		for(new target; target<matches; target++)
		{
			TurnToZeroPanel(client, targets[target]);  //FIXME:  This can only handle one client currently and doesn't iterate through all clients
		}
	}
	else
	{
		TurnToZeroPanel(client, targets[0]);
	}
	return Plugin_Handled;
}

public TurnToZeroPanelH(Handle:menu, MenuAction:action, client, position)
{
	if(action==MenuAction_Select && position==1)
	{
		if(shortname[client]==client)
		{
			CPrintToChat(client,"{olive}[FF2]{default} %t", "Reset Queue Points Done");  //Your queue points have been reset to {olive}0{default}
		}
		else
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "Reset Player's Points Done", shortname[client]);  //{olive}{1}{default}'s queue points have been reset to {olive}0{default}
			CPrintToChat(shortname[client], "{olive}[FF2]{default} %t", "Queue Points Reset by Admin", client);  //{olive}{1}{default} reset your queue points to {olive}0{default}
		}
		SetClientQueuePoints(shortname[client], 0);
	}
}

public Action:TurnToZeroPanel(client, target)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	new Handle:panel=CreatePanel();
	decl String:text[128];
	SetGlobalTransTarget(client);
	if(client==target)
	{
		Format(text, sizeof(text), "%t", "Reset Queue Points Confirmation");  //Do you really want to set your queue points to 0?
	}
	else
	{
		Format(text, sizeof(text), "%t", "Reset Player's Queue Points", client);  //Do you really want to set {1}'s queue points to 0?
	}

	PrintToChat(client, text);
	SetPanelTitle(panel, text);
	Format(text, sizeof(text), "%t", "Yes");
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%t", "No");
	DrawPanelItem(panel, text);
	shortname[client]=target;
	SendPanelToClient(panel, client, TurnToZeroPanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

bool:GetClientClassInfoCookie(client)
{
	if(!IsValidClient(client) || IsFakeClient(client))
	{
		return false;
	}

	return displayInfo[client];
}

GetClientQueuePoints(client)
{
	if(!IsValidClient(client))
	{
		return 0;
	}

	if(IsFakeClient(client))
	{
		return botqueuepoints;
	}

	return queuePoints[client];
}

SetClientQueuePoints(client, points)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		decl String:buffer[12];
		IntToString(points, buffer, sizeof(buffer));
		SetClientCookie(client, FF2Cookie_QueuePoints, buffer);
		queuePoints[client] = points;
	}
}

stock bool:IsBoss(client)
{
	if(IsValidClient(client))
	{
		for(new boss; boss<=MaxClients; boss++)
		{
			if(Boss[boss]==client)
			{
				return true;
			}
		}
	}
	return false;
}

DoOverlay(client, const String:overlay[])
{
	new flags=GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", flags);
}

public Action:FF2Panel(client, args)  //._.
{
	if(Enabled2 && IsValidClient(client, false))
	{
		new Handle:panel=CreatePanel();
		decl String:text[512];
		SetGlobalTransTarget(client);
		Format(text, sizeof(text), "%t", "What's Up");
		SetPanelTitle(panel, text);
		Format(text, sizeof(text), "%t", "Observe Health Value");
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "Class Changes");
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "What's New in FF2");
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "View Queue Points");
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "Toggle Music");
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "Toggle Monologue");
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "Toggle Class Changes");
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "Exit Menu");
		DrawPanelItem(panel, text);
		SendPanelToClient(panel, client, Handler_FF2Panel, MENU_TIME_FOREVER);
		CloseHandle(panel);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Handler_FF2Panel(Handle:menu, MenuAction:action, client, selection)
{
	if(action==MenuAction_Select)
	{
		switch(selection)
		{
			case 1:
			{
				Command_GetHP(client);
			}
			case 2:
			{
				HelpPanelClass(client);
			}
			case 3:
			{
				ShowChangelog(client);
			}
			case 4:
			{
				QueuePanelCmd(client, 0);
			}
			case 5:
			{
				MusicTogglePanel(client);
			}
			case 6:
			{
				VoiceTogglePanel(client);
			}
			case 7:
			{
				HelpPanel3(client);
			}
			default:
			{
				return;
			}
		}
	}
}

public Handler_ChangelogMenu(Handle:menu, MenuAction:action, client, selection)
{
	//noop
}

public Action:Command_ShowChangelog(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	ShowChangelog(client);
	return Plugin_Handled;
}

public Action:ShowChangelog(client)
{
	if(Enabled2)
	{
		DisplayMenu(changelogMenu, client, MENU_TIME_FOREVER);
	}
	return Plugin_Continue;
}

public Action:HelpPanel3Cmd(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	HelpPanel3(client);
	return Plugin_Handled;
}

public Action:HelpPanel3(client)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	new Handle:panel=CreatePanel();
	SetPanelTitle(panel, "Turn the Freak Fortress 2 class info...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, ClassInfoTogglePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}


public ClassInfoTogglePanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(IsValidClient(client))
	{
		if(action==MenuAction_Select)
		{
			SetClientCookie(client, FF2Cookie_DisplayInfo, selection==2 ? "0" : "1");
			displayInfo[client] = selection==2 ? false : true;
			CPrintToChat(client, "{olive}[FF2]{default} %t", "FF2 Class Info", selection==2 ? "off" : "on");
		}
	}
}

public Action:Command_HelpPanelClass(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	HelpPanelClass(client);
	return Plugin_Handled;
}

public Action:HelpPanelClass(client)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	new boss=GetBossIndex(client);
	if(boss!=-1)
	{
		HelpPanelBoss(boss);
		return Plugin_Continue;
	}

	decl String:text[512];
	new TFClassType:class=TF2_GetPlayerClass(client);
	SetGlobalTransTarget(client);
	switch(class)
	{
		case TFClass_Scout:
		{
			Format(text, sizeof(text), "%t", "Scout Advice");
		}
		case TFClass_Soldier:
		{
			Format(text, sizeof(text), "%t", "Soldier Advice");
		}
		case TFClass_Pyro:
		{
			Format(text, sizeof(text), "%t", "Pyro Advice");
		}
		case TFClass_DemoMan:
		{
			Format(text, sizeof(text), "%t", "Demo Advice");
		}
		case TFClass_Heavy:
		{
			Format(text, sizeof(text), "%t", "Heavy Advice");
		}
		case TFClass_Engineer:
		{
			Format(text, sizeof(text), "%t", "Engineer Advice");
		}
		case TFClass_Medic:
		{
			Format(text, sizeof(text), "%t", "Medic Advice");
		}
		case TFClass_Sniper:
		{
			Format(text, sizeof(text), "%t", "Sniper Advice");
		}
		case TFClass_Spy:
		{
			Format(text, sizeof(text), "%t", "Spy Advice");
		}
		default:
		{
			Format(text, sizeof(text), "");
		}
	}

	if(class!=TFClass_Sniper)
	{
		Format(text, sizeof(text), "%t\n%s", "Melee Advice", text);
	}

	new Handle:panel=CreatePanel();
	SetPanelTitle(panel, text);
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, HintPanelH, 20);
	CloseHandle(panel);
	return Plugin_Continue;
}

HelpPanelBoss(boss)
{
	if(!IsValidClient(Boss[boss]))
	{
		return;
	}

	new Handle:kv=GetArrayCell(bossesArray, character[boss]);
	KvRewind(kv);
	if(KvJumpToKey(kv, "description"))
	{
		decl String:text[512], String:language[8];
		GetLanguageInfo(GetClientLanguage(Boss[boss]), language, sizeof(language));
		//KvSetEscapeSequences(kv, true);  //Not working
		KvGetString(kv, language, text, sizeof(text));
		if(!text[0])
		{
			KvGetString(kv, "en", text, sizeof(text));  //Default to English if their language isn't available
			if(!text[0])
			{
				return;
			}
		}
		ReplaceString(text, sizeof(text), "\\n", "\n");
		//KvSetEscapeSequences(kv, false);  //We don't want to interfere with the download paths

		new Handle:panel=CreatePanel();
		SetPanelTitle(panel, text);
		DrawPanelItem(panel, "Exit");
		SendPanelToClient(panel, Boss[boss], HintPanelH, 20);
		CloseHandle(panel);
	}
}

public Action:MusicTogglePanelCmd(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	MusicTogglePanel(client);
	return Plugin_Handled;
}

public Action:MusicTogglePanel(client)
{
	if(!Enabled || !IsValidClient(client))
	{
		return Plugin_Continue;
	}

	new Handle:panel=CreatePanel();
	SetPanelTitle(panel, "Turn the Freak Fortress 2 music...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, MusicTogglePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Continue;
}

public MusicTogglePanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(IsValidClient(client) && action==MenuAction_Select)
	{
		if(selection==2)  //Off
		{
			SetSoundFlags(client, FF2SOUND_MUTEMUSIC);
			StopMusic(client, true);
		}
		else  //On
		{
			//If they already have music enabled don't do anything
			if(!CheckSoundFlags(client, FF2SOUND_MUTEMUSIC))
			{
				ClearSoundFlags(client, FF2SOUND_MUTEMUSIC);
				StartMusic(client);
			}
		}
		CPrintToChat(client, "{olive}[FF2]{default} %t", "FF2 Music", selection==2 ? "off" : "on");
	}
}

public Action:VoiceTogglePanelCmd(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	VoiceTogglePanel(client);
	return Plugin_Handled;
}

public Action:VoiceTogglePanel(client)
{
	if(!Enabled || !IsValidClient(client))
	{
		return Plugin_Continue;
	}

	new Handle:panel=CreatePanel();
	SetPanelTitle(panel, "Turn the Freak Fortress 2 voices...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, VoiceTogglePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Continue;
}

public VoiceTogglePanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(IsValidClient(client))
	{
		if(action==MenuAction_Select)
		{
			if(selection==2)
			{
				SetSoundFlags(client, FF2SOUND_MUTEVOICE);
			}
			else
			{
				ClearSoundFlags(client, FF2SOUND_MUTEVOICE);
			}

			CPrintToChat(client, "{olive}[FF2]{default} %t", "FF2 Voice", selection==2 ? "off" : "on");
			if(selection==2)
			{
				CPrintToChat(client, "%t", "FF2 Voice 2");
			}
		}
	}
}

public Action:HookSound(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &client, &channel, &Float:volume, &level, &pitch, &flags, String:soundEntry[PLATFORM_MAX_PATH], &seed)
{
	if(!Enabled || !IsValidClient(client) || channel<1)
	{
		return Plugin_Continue;
	}

	new boss=GetBossIndex(client);
	if(boss==-1)
	{
		return Plugin_Continue;
	}

	if(channel==SNDCHAN_VOICE)
	{
		decl String:newSound[PLATFORM_MAX_PATH];
		if(FindSound("catch phrase", newSound, sizeof(newSound), boss))
		{
			strcopy(sound, sizeof(sound), newSound);
			return Plugin_Changed;
		}

		if(GetArrayCell(voicesArray, character[boss]))
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

stock GetHealingTarget(client, bool:checkgun=false)
{
	new medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
		{
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		}
		return -1;
	}

	if(IsValidEntity(medigun))
	{
		decl String:classname[64];
		GetEntityClassname(medigun, classname, sizeof(classname));
		if(StrEqual(classname, "tf_weapon_medigun", false))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			{
				return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
			}
		}
	}
	return -1;
}

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

public CvarChangeNextmap(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CreateTimer(0.1, Timer_DisplayCharsetVote, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_DisplayCharsetVote(Handle:timer)
{
	if(isCharSetSelected)
	{
		return Plugin_Continue;
	}

	if(IsVoteInProgress())
	{
		CreateTimer(5.0, Timer_DisplayCharsetVote, _, TIMER_FLAG_NO_MAPCHANGE);  //Try again in 5 seconds if there's a different vote going on
		return Plugin_Continue;
	}

	new Handle:menu=CreateMenu(Handler_VoteCharset, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "%t", "Vote for Character Set");  //"Please vote for the character set for the next map."

	decl String:config[PLATFORM_MAX_PATH], String:charset[64];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2_SETTINGS, BOSS_CONFIG);

	new Handle:Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	AddMenuItem(menu, "Random", "Random");
	new total, charsets;
	do
	{
		total++;
		if(KvGetNum(Kv, "hidden", 0))  //Hidden charsets are hidden for a reason :P
		{
			continue;
		}
		charsets++;
		validCharsets[charsets]=total;

		KvGetSectionName(Kv, charset, sizeof(charset));
		AddMenuItem(menu, charset, charset);
	}
	while(KvGotoNextKey(Kv));
	CloseHandle(Kv);

	if(charsets>1)  //We have enough to call a vote
	{
		FF2CharSet=charsets;  //Temporary so that if the vote result is random we know how many valid charsets are in the validCharset array
		new Handle:voteDuration=FindConVar("sm_mapvote_voteduration");
		VoteMenuToAll(menu, voteDuration ? GetConVarInt(voteDuration) : 20);
	}
	return Plugin_Continue;
}

public Handler_VoteCharset(Handle:menu, MenuAction:action, param1, param2)
{
	if(action==MenuAction_VoteEnd)
	{
		FF2CharSet=param1 ? param1-1 : validCharsets[GetRandomInt(1, FF2CharSet)]-1;  //If param1 is 0 then we need to find a random charset

		decl String:nextmap[32];
		GetConVarString(cvarNextmap, nextmap, sizeof(nextmap));
		GetMenuItem(menu, param1, FF2CharSetString, sizeof(FF2CharSetString));
		CPrintToChatAll("{olive}[FF2]{default} %t", "Character Set Next Map", nextmap, FF2CharSetString);  //"The character set for {1} will be {2}."
		isCharSetSelected=true;
	}
	else if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Command_Nextmap(client, args)
{
	if(FF2CharSetString[0])
	{
		decl String:nextmap[42];
		GetConVarString(cvarNextmap, nextmap, sizeof(nextmap));
		CPrintToChat(client, "{olive}[FF2]{default} %t", "Character Set Next Map", nextmap, FF2CharSetString);
	}
	return Plugin_Handled;
}

public Action:Command_Say(client, args)
{
	decl String:chat[128];
	if(GetCmdArgString(chat, sizeof(chat))<1 || !client)
	{
		return Plugin_Continue;
	}

	if(StrEqual(chat, "\"nextmap\"") && FF2CharSetString[0])
	{
		Command_Nextmap(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

public Action:Timer_UseBossCharge(Handle:timer, Handle:data)
{
	BossCharge[ReadPackCell(data)][ReadPackCell(data)]=ReadPackFloat(data);
	return Plugin_Continue;
}

stock RemoveShield(client, attacker, Float:position[3])
{
	TF2_RemoveWearable(client, shield[client]);
	EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	TF2_AddCondition(client, TFCond_Bonked, 0.1); // Shows "MISS!" upon breaking shield
	shield[client]=0;
}

//Natives aren't inlined because of https://github.com/50DKP/FF2-Official/issues/263

public bool:IsFF2Enabled()
{
	return Enabled;
}

public Native_IsFF2Enabled(Handle:plugin, numParams)
{
	return IsFF2Enabled();
}

public RegisterSubplugin(String:pluginName[])
{
	PushArrayString(subpluginArray, pluginName);
}

public Native_RegisterSubplugin(Handle:plugin, numParams)
{
	decl String:pluginName[64];
	GetNativeString(1, pluginName, sizeof(pluginName));
	RegisterSubplugin(pluginName);
}

public UnregisterSubplugin(String:pluginName[])
{
	new index=FindStringInArray(subpluginArray, pluginName);
	if(index>=0)
	{
		RemoveFromArray(subpluginArray, index);
	}
}

public Native_UnregisterSubplugin(Handle:plugin, numParams)
{
	decl String:pluginName[64];
	GetNativeString(1, pluginName, sizeof(pluginName));
	UnregisterSubplugin(pluginName);
}

public bool:GetFF2Version()
{
	new version[3];  //Blame the compiler for this mess -.-
	version[0]=StringToInt(MAJOR_REVISION);
	version[1]=StringToInt(MINOR_REVISION);
	version[2]=StringToInt(STABLE_REVISION);
	SetNativeArray(1, version, sizeof(version));
	#if !defined DEV_REVISION
		return false;
	#else
		return true;
	#endif
}

public Native_GetFF2Version(Handle:plugin, numParams)
{
	return GetFF2Version();
}

public Native_GetRoundState(Handle:plugin, numParams)
{
	return _:CheckRoundState();
}

public GetBossUserId(boss)
{
	if(boss>=0 && boss<=MaxClients && IsValidClient(Boss[boss]))
	{
		return GetClientUserId(Boss[boss]);
	}
	return -1;
}

public Native_GetBossUserId(Handle:plugin, numParams)
{
	return GetBossUserId(GetNativeCell(1));
}

public GetBossIndex(client)
{
	if(client>0 && client<=MaxClients)
	{
		for(new boss; boss<=MaxClients; boss++)
		{
			if(Boss[boss]==client)
			{
				return boss;
			}
		}
	}
	return -1;
}

public Native_GetBossIndex(Handle:plugin, numParams)
{
	return GetBossIndex(GetNativeCell(1));
}

public TFTeam:GetBossTeam()
{
	return BossTeam;
}

public Native_GetBossTeam(Handle:plugin, numParams)
{
	return _:GetBossTeam();
}

public bool:GetBossName(boss, String:bossName[], length)
{
	if(boss>=0 && boss<=MaxClients && character[boss]>=0 && character[boss]<GetArraySize(bossesArray) && GetArrayCell(bossesArray, character[boss])!=INVALID_HANDLE)
	{
		KvRewind(GetArrayCell(bossesArrayShadow, character[boss]));
		KvGetString(GetArrayCell(bossesArray, character[boss]), "name", bossName, length);
		return true;
	}
	return false;
}

public Native_GetBossName(Handle:plugin, numParams)
{
	new length=GetNativeCell(3);
	decl String:bossName[length];
	new bool:bossExists=GetBossName(GetNativeCell(1), bossName, length);
	SetNativeString(2, bossName, length);
	return bossExists;
}

public Handle:GetBossKV(boss)
{
	if(boss>=0 && boss<=MaxClients && character[boss]>=0 && character[boss]<GetArraySize(bossesArray) && GetArrayCell(bossesArray, character[boss])!=INVALID_HANDLE)
	{
		KvRewind(GetArrayCell(bossesArrayShadow, character[boss]));
		return GetArrayCell(bossesArray, character[boss]);
	}
	return INVALID_HANDLE;
}

public Native_GetBossKV(Handle:plugin, numParams)
{
	return _:GetBossKV(GetNativeCell(1));
}

public GetBossHealth(boss)
{
	return BossHealth[boss];
}

public Native_GetBossHealth(Handle:plugin, numParams)
{
	return GetBossHealth(GetNativeCell(1));
}

public SetBossHealth(boss, health)
{
	BossHealth[boss]=health;
}

public Native_SetBossHealth(Handle:plugin, numParams)
{
	SetBossHealth(GetNativeCell(1), GetNativeCell(2));
}

public GetBossMaxHealth(boss)
{
	return BossHealthMax[boss];
}

public Native_GetBossMaxHealth(Handle:plugin, numParams)
{
	return GetBossMaxHealth(GetNativeCell(1));
}

public SetBossMaxHealth(boss, health)
{
	BossHealthMax[boss]=health;
}

public Native_SetBossMaxHealth(Handle:plugin, numParams)
{
	SetBossMaxHealth(GetNativeCell(1), GetNativeCell(2));
}

public GetBossLives(boss)
{
	return BossLives[boss];
}

public Native_GetBossLives(Handle:plugin, numParams)
{
	return GetBossLives(GetNativeCell(1));
}

public SetBossLives(boss, lives)
{
	BossLives[boss]=lives;
}

public Native_SetBossLives(Handle:plugin, numParams)
{
	SetBossLives(GetNativeCell(1), GetNativeCell(2));
}

public GetBossMaxLives(boss)
{
	return BossLivesMax[boss];
}

public Native_GetBossMaxLives(Handle:plugin, numParams)
{
	return GetBossMaxLives(GetNativeCell(1));
}

public SetBossMaxLives(boss, lives)
{
	BossLivesMax[boss]=lives;
}

public Native_SetBossMaxLives(Handle:plugin, numParams)
{
	SetBossMaxLives(GetNativeCell(1), GetNativeCell(2));
}

public Float:GetBossCharge(boss, slot)
{
	return BossCharge[boss][slot];
}

public Native_GetBossCharge(Handle:plugin, numParams)
{
	return _:GetBossCharge(GetNativeCell(1), GetNativeCell(2));
}

public SetBossCharge(boss, slot, Float:charge)  //FIXME: This duplicates logic found in Timer_UseBossCharge
{
	BossCharge[boss][slot]=charge;
}

public Native_SetBossCharge(Handle:plugin, numParams)
{
	SetBossCharge(GetNativeCell(1), GetNativeCell(2), Float:GetNativeCell(3));
}

public GetBossRageDamage(boss)
{
	return BossRageDamage[boss];
}

public Native_GetBossRageDamage(Handle:plugin, numParams)
{
	return GetBossRageDamage(GetNativeCell(1));
}

public SetBossRageDamage(boss, damage)
{
	BossRageDamage[boss]=damage;
}

public Native_SetBossRageDamage(Handle:plugin, numParams)
{
	SetBossRageDamage(GetNativeCell(1), GetNativeCell(2));
}

public Native_SetSoundFlags(Handle:plugin, numParams)
{
	SetSoundFlags(GetNativeCell(1), GetNativeCell(2));
}

public Native_ClearSoundFlags(Handle:plugin, numParams)
{
	ClearSoundFlags(GetNativeCell(1), GetNativeCell(2));
}

public Native_CheckSoundFlags(Handle:plugin, numParams)
{
	return CheckSoundFlags(GetNativeCell(1), GetNativeCell(2));
}

public GetBossRageDistance(boss, const String:pluginName[], const String:abilityName[])
{
	if(!GetArrayCell(bossesArrayShadow, character[boss]))  //Invalid boss
	{
		return 0;
	}

	KvRewind(GetArrayCell(bossesArrayShadow, character[boss]));
	if(!abilityName[0])  //Return the global rage distance if there's no ability specified
	{
		return ParseFormula(boss, "rage distance", 400);
	}

	if(HasAbility(boss, pluginName, abilityName))
	{
		decl String:key[128];
		Format(key, sizeof(key), "%s > %s > distance", pluginName, abilityName);

		new distance;
		if((distance=ParseFormula(boss, key, -1))<0)  //Distance doesn't exist, return the global rage distance instead
		{
			KvRewind(GetArrayCell(bossesArrayShadow, character[boss]));
			distance=ParseFormula(boss, "rage distance", 400);
		}
		return distance;
	}
	return 0;
}

public Native_GetBossRageDistance(Handle:plugin, numParams)
{
	decl String:pluginName[64], String:abilityName[64];
	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	return GetBossRageDistance(GetNativeCell(1), pluginName, abilityName);
}

public GetClientDamage(client)
{
	return Damage[client];
}

public Native_GetClientDamage(Handle:plugin, numParams)
{
	return GetClientDamage(GetNativeCell(1));
}

public SetClientDamage(client, damage)
{
	Damage[client]=damage;
}

public Native_SetClientDamage(Handle:plugin, numParams)
{
	SetClientDamage(GetNativeCell(1), GetNativeCell(2));
}

public bool:HasAbility(boss, const String:pluginName[], const String:abilityName[])
{
	if(boss==-1 || character[boss]==-1 || !GetArrayCell(bossesArrayShadow, character[boss]))  //Invalid boss
	{
		return false;
	}

	new Handle:kv=GetArrayCell(bossesArrayShadow, character[boss]);
	KvRewind(kv);
	if(KvJumpToKey(kv, "abilities") && KvJumpToKey(kv, pluginName) && KvJumpToKey(kv, abilityName))
	{
		return true;
	}
	return false;
}

public Native_HasAbility(Handle:plugin, numParams)
{
	decl String:pluginName[64], String:abilityName[64];
	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	return HasAbility(GetNativeCell(1), pluginName, abilityName);
}

public GetAbilityArgumentWrapper(boss, const String:pluginName[], const String:abilityName[], const String:argument[], defaultValue)
{
	return GetAbilityArgument(boss, pluginName, abilityName, argument, defaultValue);
}

public Native_GetAbilityArgument(Handle:plugin, numParams)
{
	decl String:pluginName[64], String:abilityName[64], String:argument[64];
	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	GetNativeString(4, argument, sizeof(argument));
	return GetAbilityArgumentWrapper(GetNativeCell(1), pluginName, abilityName, argument, GetNativeCell(5));
}

public Float:GetAbilityArgumentFloatWrapper(boss, const String:pluginName[], const String:abilityName[], const String:argument[], Float:defaultValue)
{
	return GetAbilityArgumentFloat(boss, pluginName, abilityName, argument, defaultValue);
}

public Native_GetAbilityArgumentFloat(Handle:plugin, numParams)
{
	decl String:pluginName[64], String:abilityName[64], String:argument[64];
	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	GetNativeString(4, argument, sizeof(argument));
	return _:GetAbilityArgumentFloatWrapper(GetNativeCell(1), pluginName, abilityName, argument, Float:GetNativeCell(5));
}

public GetAbilityArgumentStringWrapper(boss, const String:pluginName[], const String:abilityName[], const String:argument[], String:abilityString[], length, const String:defaultValue[])
{
	GetAbilityArgumentString(boss, pluginName, abilityName, argument, abilityString, length, defaultValue);
}

public Native_GetAbilityArgumentString(Handle:plugin, numParams)
{
	decl String:pluginName[64], String:abilityName[64], String:defaultValue[64], String:argument[64];
	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	GetNativeString(4, argument, sizeof(argument));
	GetNativeString(7, defaultValue, sizeof(defaultValue));
	new length=GetNativeCell(6);
	decl String:abilityString[length];
	GetAbilityArgumentStringWrapper(GetNativeCell(1), pluginName, abilityName, argument, abilityString, length, defaultValue);
	SetNativeString(5, abilityString, length);
}

bool:UseAbility(boss, const String:pluginName[], const String:abilityName[], slot, buttonMode=0)
{
	new Action:action;
	Call_StartForward(PreAbility);
	Call_PushCell(boss);
	Call_PushString(pluginName);
	Call_PushString(abilityName);
	Call_PushCell(slot);
	Call_Finish(action);

	if(action==Plugin_Handled || action==Plugin_Stop)
	{
		return false;
	}

	Call_StartForward(OnAbility);
	Call_PushCell(boss);
	Call_PushString(pluginName);
	Call_PushString(abilityName);
	Call_PushCell(slot);
	if(slot==-1)
	{
		Call_PushCell(3);  //We're assuming here a life-loss ability will always be in use if it gets called
		Call_Finish();
	}
	else if(!slot)
	{
		FF2Flags[Boss[boss]]&=~FF2FLAG_BOTRAGE;
		Call_PushCell(3);  //We're assuming here a rage ability will always be in use if it gets called
		Call_Finish();
		BossCharge[boss][slot]=0.0;
	}
	else
	{
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
		new button;
		switch(buttonMode)
		{
			case 2:
			{
				button=IN_RELOAD;
				bossHasReloadAbility[boss]=true;
			}
			default:
			{
				button=IN_DUCK|IN_ATTACK2;
				bossHasRightMouseAbility[boss]=true;
			}
		}

		if(GetClientButtons(Boss[boss]) & button)
		{
			for(new timer; timer<=1; timer++)
			{
				if(BossInfoTimer[boss][timer]!=INVALID_HANDLE)
				{
					KillTimer(BossInfoTimer[boss][timer]);
					BossInfoTimer[boss][timer]=INVALID_HANDLE;
				}
			}

			if(BossCharge[boss][slot]>=0.0)
			{
				Call_PushCell(2);  //Ready
				Call_Finish();
				new Float:charge=100.0*0.2/GetAbilityArgumentFloat(boss, pluginName, abilityName, "charge", 1.5);
				if(BossCharge[boss][slot]+charge<100.0)
				{
					BossCharge[boss][slot]+=charge;
				}
				else
				{
					BossCharge[boss][slot]=100.0;
				}
			}
			else
			{
				Call_PushCell(1);  //Recharging
				Call_Finish();
				BossCharge[boss][slot]+=0.2;
			}
		}
		else if(BossCharge[boss][slot]>0.3)
		{
			new Float:angles[3];
			GetClientEyeAngles(Boss[boss], angles);
			if(angles[0]<-45.0)
			{
				Call_PushCell(3);  //In use
				Call_Finish();
				new Handle:data;
				CreateDataTimer(0.1, Timer_UseBossCharge, data);
				WritePackCell(data, boss);
				WritePackCell(data, slot);
				WritePackFloat(data, -1.0*GetAbilityArgumentFloat(boss, pluginName, abilityName, "cooldown", 5.0));
				ResetPack(data);
			}
			else
			{
				Call_PushCell(0);  //Not in use
				Call_Finish();
				BossCharge[boss][slot]=0.0;
			}
		}
		else if(BossCharge[boss][slot]<0.0)
		{
			Call_PushCell(1);  //Recharging
			Call_Finish();
			BossCharge[boss][slot]+=0.2;
		}
		else
		{
			Call_PushCell(0);  //Not in use
			Call_Finish();
		}
	}
	return true;
}

public Native_UseAbility(Handle:plugin, numParams)
{
	decl String:pluginName[64], String:abilityName[64];
	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	UseAbility(GetNativeCell(1), pluginName, abilityName, GetNativeCell(4), GetNativeCell(5));
}

public GetFF2Flags(client)
{
	return FF2Flags[client];
}

public Native_GetFF2Flags(Handle:plugin, numParams)
{
	return GetFF2Flags(GetNativeCell(1));
}

public SetFF2Flags(client, flags)
{
	FF2Flags[client]=flags;
}

public Native_SetFF2Flags(Handle:plugin, numParams)
{
	SetFF2Flags(GetNativeCell(1), GetNativeCell(2));
}

public Native_GetQueuePoints(Handle:plugin, numParams)
{
	return GetClientQueuePoints(GetNativeCell(1));
}

public Native_SetQueuePoints(Handle:plugin, numParams)
{
	SetClientQueuePoints(GetNativeCell(1), GetNativeCell(2));
}

public Native_StartMusic(Handle:plugin, numParams)
{
	StartMusic(GetNativeCell(1));
}

public Native_StopMusic(Handle:plugin, numParams)
{
	StopMusic(GetNativeCell(1));
}

public Native_FindSound(Handle:plugin, numParams)
{
	decl String:kv[64];
	GetNativeString(1, kv, sizeof(kv));

	new length=GetNativeCell(3);
	decl String:sound[length];
	new bool:soundExists=FindSound(kv, sound, length, GetNativeCell(4), bool:GetNativeCell(5), GetNativeCell(6));
	SetNativeString(2, sound, length);
	return soundExists;
}

public Float:GetClientGlow(client)
{
	return GlowTimer[client];
}

public Native_GetClientGlow(Handle:plugin, numParams)
{
	return _:GetClientGlow(GetNativeCell(1));
}

SetClientGlow(client, Float:time1, Float:time2=-1.0)
{
	if(IsValidClient(client))
	{
		GlowTimer[client]+=time1;
		if(time2>=0)
		{
			GlowTimer[client]=time2;
		}

		if(GlowTimer[client]<=0.0)
		{
			GlowTimer[client]=0.0;
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		}
	}
}

public Native_SetClientGlow(Handle:plugin, numParams)
{
	SetClientGlow(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public Native_Debug(Handle:plugin, numParams)
{
	return GetConVarBool(cvarDebug);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(GetConVarBool(cvarHealthBar))
	{
		if(StrEqual(classname, HEALTHBAR_CLASS))
		{
			healthBar=entity;
		}

		if(!IsValidEntity(g_Monoculus) && StrEqual(classname, MONOCULUS))
		{
			g_Monoculus=entity;
		}
	}

	if(StrContains(classname, "item_healthkit")!=-1 || StrContains(classname, "item_ammopack")!=-1 || StrEqual(classname, "tf_ammo_pack"))
	{
		SDKHook(entity, SDKHook_Spawn, OnItemSpawned);
	}

	if(StrEqual(classname, "tf_logic_koth"))
	{
		SDKHook(entity, SDKHook_Spawn, Spawn_Koth);
	}
}

public OnEntityDestroyed(entity)
{
	if(entity==g_Monoculus)
	{
		g_Monoculus=FindEntityByClassname(-1, MONOCULUS);
		if(g_Monoculus==entity)
		{
			g_Monoculus=FindEntityByClassname(entity, MONOCULUS);
		}
	}
}

public Action:Spawn_Koth(entity)
{
	DispatchSpawn(CreateEntityByName("tf_logic_arena"));
	return Plugin_Stop;  //Stop koth logic from being created
}

public OnItemSpawned(entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPickup);
	SDKHook(entity, SDKHook_Touch, OnPickup);
}

public Action:OnPickup(entity, client)  //Thanks friagram!
{
	if(IsBoss(client))
	{
		decl String:classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!StrContains(classname, "item_healthkit") && !(FF2Flags[client] & FF2FLAG_ALLOW_HEALTH_PICKUPS))
		{
			return Plugin_Handled;
		}
		else if((!StrContains(classname, "item_ammopack") || StrEqual(classname, "tf_ammo_pack")) && !(FF2Flags[client] & FF2FLAG_ALLOW_AMMO_PICKUPS))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public FF2RoundState:CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return FF2RoundState_Loading;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return FF2RoundState_Setup;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return FF2RoundState_RoundRunning;
		}
		default:
		{
			return FF2RoundState_RoundEnd;
		}
	}
	return FF2RoundState_Loading;  //Compiler bug-doesn't recognize 'default' as a valid catch-all
}

FindHealthBar()
{
	healthBar=FindEntityByClassname(-1, HEALTHBAR_CLASS);
	if(!IsValidEntity(healthBar))
	{
		healthBar=CreateEntityByName(HEALTHBAR_CLASS);
	}
}

public HealthbarEnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(Enabled && GetConVarBool(cvarHealthBar) && IsValidEntity(healthBar))
	{
		UpdateHealthBar();
	}
	else if(!IsValidEntity(g_Monoculus) && IsValidEntity(healthBar))
	{
		SetEntProp(healthBar, Prop_Send, HEALTHBAR_PROPERTY, 0);
	}
}

UpdateHealthBar()
{
	if(!Enabled || !GetConVarBool(cvarHealthBar) || IsValidEntity(g_Monoculus) || !IsValidEntity(healthBar) || CheckRoundState()==FF2RoundState_Loading)
	{
		return;
	}

	new healthAmount, maxHealthAmount, bosses, healthPercent;
	for(new boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			bosses++;
			healthAmount+=BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
			maxHealthAmount+=BossHealthMax[boss];
		}
	}

	if(bosses)
	{
		healthPercent=RoundToCeil(float(healthAmount)/float(maxHealthAmount)*float(HEALTHBAR_MAX));
		if(healthPercent>HEALTHBAR_MAX)
		{
			healthPercent=HEALTHBAR_MAX;
		}
		else if(healthPercent<=0)
		{
			healthPercent=1;
		}
	}
	SetEntProp(healthBar, Prop_Send, HEALTHBAR_PROPERTY, healthPercent);
}
