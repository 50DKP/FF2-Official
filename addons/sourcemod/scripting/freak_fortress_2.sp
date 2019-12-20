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
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
//#tryinclude <smac>
#tryinclude <goomba>
#tryinclude <tf2attributes>
#tryinclude <updater>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define MAJOR_REVISION "1"
#define MINOR_REVISION "11"
#define STABLE_REVISION "0"
#define DEV_REVISION "Beta"
#if !defined DEV_REVISION
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION  //1.11.0
#else
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION..." "...DEV_REVISION
#endif

#define UPDATE_URL "http://50dkp.github.io/FF2-Official/update.txt"
#define CHANGELOG_URL "http://50dkp.github.io/FF2-Official/changelog.html"

#define MAXENTITIES 2048
#define MAXSPECIALS 128
#define MAXRANDOMS 32

#define SOUNDEXCEPT_MUSIC 0
#define SOUNDEXCEPT_VOICE 1
#define TOGGLE_COMPANION 2

#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255
#define MONOCULUS "eyeball_boss"

#if defined _steamtools_included
bool steamtools=false;
#endif

#if defined _tf2attributes_included
bool tf2attributes=false;
#endif

#if defined _goomba_included
bool goomba=false;
#endif

bool tf2x10=false;

bool smac=false;

int OtherTeam=2;
int BossTeam=3;
int playing;
int healthcheckused;
int RedAlivePlayers;
int BlueAlivePlayers;
int RoundCount;
int Special[MAXPLAYERS+1];
int Incoming[MAXPLAYERS+1];

int Damage[MAXPLAYERS+1];
int uberTarget[MAXPLAYERS+1];
int detonations[MAXPLAYERS+1];
bool playBGM[MAXPLAYERS+1]=true;

char currentBGM[MAXPLAYERS+1][PLATFORM_MAX_PATH];

int FF2flags[MAXPLAYERS+1];

int Boss[MAXPLAYERS+1];
int BossHealthMax[MAXPLAYERS+1];
int BossHealth[MAXPLAYERS+1];
int BossHealthLast[MAXPLAYERS+1];
int BossLives[MAXPLAYERS+1];
int BossLivesMax[MAXPLAYERS+1];
int BossRageDamage[MAXPLAYERS+1];
float BossCharge[MAXPLAYERS+1][8];
float Stabbed[MAXPLAYERS+1];
float Marketed[MAXPLAYERS+1];
float KSpreeTimer[MAXPLAYERS+1];
int KSpreeCount[MAXPLAYERS+1];
float GlowTimer[MAXPLAYERS+1];
int shortname[MAXPLAYERS+1];
bool emitRageSound[MAXPLAYERS+1];
bool bossHasReloadAbility[MAXPLAYERS+1];
bool bossHasRightMouseAbility[MAXPLAYERS+1];
bool DmgTriple[MAXPLAYERS+1];
bool SelfKnockback[MAXPLAYERS+1];
bool randomCrits[MAXPLAYERS+1];

int timeleft;

ConVar cvarVersion;
ConVar cvarPointDelay;
ConVar cvarAnnounce;
ConVar cvarEnabled;
ConVar cvarAliveToEnable;
ConVar cvarPointType;
ConVar cvarCrits;
ConVar cvarFirstRound;  //DEPRECATED
ConVar cvarArenaRounds;
ConVar cvarCircuitStun;
ConVar cvarSpecForceBoss;
ConVar cvarCountdownPlayers;
ConVar cvarCountdownTime;
ConVar cvarCountdownHealth;
ConVar cvarCountdownResult;
ConVar cvarEnableEurekaEffect;
ConVar cvarForceBossTeam;
ConVar cvarHealthBar;
ConVar cvarLastPlayerGlow;
ConVar cvarBossTeleporter;
ConVar cvarBossSuicide;
ConVar cvarShieldCrits;
ConVar cvarDuoToggle;
ConVar cvarCaberDetonations;
ConVar cvarGoombaDamage;
ConVar cvarGoombaRebound;
ConVar cvarBossRTD;
ConVar cvarDeadRingerHud;
ConVar cvarUpdater;
ConVar cvarDebug;
ConVar cvarPreroundBossDisconnect;
ConVar ff2_fix_boss_skin;
ConVar ff2_attribute_manage;
ConVar ff2_changelog_url;

Handle FF2Cookies;

Handle jumpHUD;
Handle rageHUD;
Handle livesHUD;
Handle timeleftHUD;
Handle abilitiesHUD;
Handle infoHUD;

bool Enabled=true;
bool Enabled2=true;
int PointDelay=6;
float Announce=120.0;
int AliveToEnable=5;
int PointType;
int arenaRounds;
float circuitStun;
int countdownPlayers=1;
int countdownTime=120;
int countdownHealth=2000;
bool SpecForceBoss;
bool lastPlayerGlow=true;
bool bossTeleportation=true;
int shieldCrits;
int allowedDetonations;
float GoombaDamage=0.05;
float reboundPower=300.0;
bool canBossRTD;
bool DeadRingerHud;

Handle MusicTimer[MAXPLAYERS+1];
Handle BossInfoTimer[MAXPLAYERS+1][2];
Handle DrawGameTimer;
Handle doorCheckTimer;

int botqueuepoints;
float HPTime;
char currentmap[99];
bool checkDoors=false;
bool bMedieval;
bool firstBlood;

int tf_arena_use_queue;
int mp_teams_unbalance_limit;
int tf_arena_first_blood;
int mp_forcecamera;
int tf_dropped_weapon_lifetime;
float tf_feign_death_activate_damage_scale;
float tf_feign_death_damage_scale;
char mp_humans_must_join_team[16];

Handle cvarNextmap;
bool areSubPluginsEnabled;

int FF2CharSet;
int validCharsets[64];
char FF2CharSetString[42];
bool isCharSetSelected=false;

int healthBar=-1;
int g_Monoculus=-1;

static bool executed=false;
static bool executed2=false;

int changeGamemode;

enum Operators
{
	Operator_None=0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

static const char ff2versiontitles[][]=
{
	"1.0",
	"1.01",
	"1.02",
	"1.03",
	"1.04",
	"1.05",
	"1.06",
	"1.06c",
	"1.06d",
	"1.06e",
	"1.06f",
	"1.06g",
	"1.06h",
	"1.07 beta 1",
	"1.07 beta 4",
	"1.07 beta 5",
	"1.07 beta 6",
	"1.07",
	"1.0.8",
	"1.9.0",
	"1.9.1",
	"1.9.2",
	"1.9.3",
	"1.10.0",
	"1.10.1",
	"1.10.2",
	"1.10.3",
	"1.10.4",
	"1.10.5",
	"1.10.6",
	"1.10.7",
	"1.10.8",
	"1.10.9",
	"1.10.10",
	"1.10.11",
	"1.10.12",
	"1.10.13",
	"1.10.14"
};

static const char ff2versiondates[]="October 21, 2016";		//1.10.14

static const int maxVersion=sizeof(ff2versiontitles)-1;

int Specials;
Handle BossKV[MAXSPECIALS];
Handle PreAbility;
Handle OnAbility;
Handle OnMusic;
Handle OnTriggerHurt;
Handle OnSpecialSelected;
Handle OnAddQueuePoints;
Handle OnLoadCharacterSet;
Handle OnLoseLife;
Handle OnAlivePlayersChanged;

bool bBlockVoice[MAXSPECIALS];
float BossSpeed[MAXSPECIALS];

char ChancesString[512];
int chances[MAXSPECIALS*2];  //This is multiplied by two because it has to hold both the boss indices and chances
int chancesIndex;

public Plugin myinfo=
{
	name="Freak Fortress 2",
	author="Rainbolt Dash, FlaminSarge, Powerlord, the 50DKP team",
	description="RUUUUNN!! COWAAAARRDSS!",
	version=PLUGIN_VERSION,
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char plugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myself, plugin, sizeof(plugin));
	if(!StrContains(plugin, "freaks/"))  //Prevent plugins/freaks/freak_fortress_2.ff2 from loading if it exists -.-
	{
		strcopy(error, err_max, "There is a duplicate copy of Freak Fortress 2 inside the /plugins/freaks folder.  Please remove it");
		return APLRes_Failure;
	}

	CreateNative("FF2_IsFF2Enabled", Native_IsEnabled);
	CreateNative("FF2_GetFF2Version", Native_FF2Version);
	CreateNative("FF2_GetForkVersion", Native_ForkVersion);
	CreateNative("FF2_GetBossUserId", Native_GetBoss);
	CreateNative("FF2_GetBossIndex", Native_GetIndex);
	CreateNative("FF2_GetBossTeam", Native_GetTeam);
	CreateNative("FF2_GetBossSpecial", Native_GetSpecial);
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
	CreateNative("FF2_GetClientDamage", Native_GetDamage);
	CreateNative("FF2_GetRoundState", Native_GetRoundState);
	CreateNative("FF2_GetSpecialKV", Native_GetSpecialKV);
	CreateNative("FF2_StartMusic", Native_StartMusic);
	CreateNative("FF2_StopMusic", Native_StopMusic);
	CreateNative("FF2_GetRageDist", Native_GetRageDist);
	CreateNative("FF2_HasAbility", Native_HasAbility);
	CreateNative("FF2_DoAbility", Native_DoAbility);
	CreateNative("FF2_GetAbilityArgument", Native_GetAbilityArgument);
	CreateNative("FF2_GetAbilityArgumentFloat", Native_GetAbilityArgumentFloat);
	CreateNative("FF2_GetAbilityArgumentString", Native_GetAbilityArgumentString);
	CreateNative("FF2_GetArgNamedI", Native_GetArgNamedI);
	CreateNative("FF2_GetArgNamedF", Native_GetArgNamedF);
	CreateNative("FF2_GetArgNamedS", Native_GetArgNamedS);
	CreateNative("FF2_RandomSound", Native_RandomSound);
	CreateNative("FF2_GetFF2flags", Native_GetFF2flags);
	CreateNative("FF2_SetFF2flags", Native_SetFF2flags);
	CreateNative("FF2_GetQueuePoints", Native_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints", Native_SetQueuePoints);
	CreateNative("FF2_GetClientGlow", Native_GetClientGlow);
	CreateNative("FF2_SetClientGlow", Native_SetClientGlow);
	CreateNative("FF2_GetAlivePlayers", Native_GetAlivePlayers);  //TODO: Deprecated, remove in 2.0.0
	CreateNative("FF2_GetBossPlayers", Native_GetBossPlayers);  //TODO: Deprecated, remove in 2.0.0
	CreateNative("FF2_Debug", Native_Debug);

	PreAbility=CreateGlobalForward("FF2_PreAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);  //Boss, plugin name, ability name, slot, enabled
	OnAbility=CreateGlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);  //Boss, plugin name, ability name, status
	OnMusic=CreateGlobalForward("FF2_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
	OnTriggerHurt=CreateGlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	OnSpecialSelected=CreateGlobalForward("FF2_OnSpecialSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String, Param_Cell);  //Boss, character index, character name, preset
	OnAddQueuePoints=CreateGlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
	OnLoadCharacterSet=CreateGlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_CellByRef, Param_String);
	OnLoseLife=CreateGlobalForward("FF2_OnLoseLife", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);  //Boss, lives left, max lives
	OnAlivePlayersChanged=CreateGlobalForward("FF2_OnAlivePlayersChanged", ET_Hook, Param_Cell, Param_Cell);  //Players, bosses

	RegPluginLibrary("freak_fortress_2");

	AskPluginLoad_VSH();
	#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
	#endif

	#if defined _tf2attributes_included
	MarkNativeAsOptional("TF2Attrib_SetByDefIndex");
	MarkNativeAsOptional("TF2Attrib_RemoveByDefIndex");
	#endif
	return APLRes_Success;
}

public void OnPluginStart()
{
	LogMessage("===Freak Fortress 2 Initializing-v%s===", PLUGIN_VERSION);

	cvarVersion=CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarPointType=CreateConVar("ff2_point_type", "0", "0-Use ff2_point_alive, 1-Use ff2_point_time", _, true, 0.0, true, 1.0);
	cvarPointDelay=CreateConVar("ff2_point_delay", "6", "Seconds to add to the point delay per player");
	cvarAliveToEnable=CreateConVar("ff2_point_alive", "5", "The control point will only activate when there are this many people or less left alive");
	cvarAnnounce=CreateConVar("ff2_announce", "120", "Amount of seconds to wait until FF2 info is displayed again.  0 to disable", _, true, 0.0);
	cvarEnabled=CreateConVar("ff2_enabled", "1", "0-Disable FF2 (WHY?), 1-Enable FF2", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	cvarCrits=CreateConVar("ff2_crits", "0", "Can the boss get random crits?", _, true, 0.0, true, 1.0);
	cvarFirstRound=CreateConVar("ff2_first_round", "-1", "This cvar is deprecated.  Please use 'ff2_arena_rounds' instead by setting this cvar to -1", _, true, -1.0, true, 1.0);  //DEPRECATED
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
	cvarDuoToggle=CreateConVar("ff2_companion_toggle", "1", "0-Disable, 1-Players can toggle being a companion", _, true, 0.0, true, 1.0);
	cvarGoombaDamage=CreateConVar("ff2_goomba_damage", "0.05", "How much the Goomba damage should be multipled by when goomba stomping the boss (requires Goomba Stomp)", _, true, 0.01, true, 1.0);
	cvarGoombaRebound=CreateConVar("ff2_goomba_jump", "300.0", "How high players should rebound after goomba stomping the boss (requires Goomba Stomp)", _, true, 0.0);
	cvarBossRTD=CreateConVar("ff2_boss_rtd", "0", "Can the boss use rtd? 0 to disallow boss, 1 to allow boss (requires RTD)", _, true, 0.0, true, 1.0);
	cvarDeadRingerHud=CreateConVar("ff2_deadringer_hud", "1", "Dead Ringer indicator? 0 to disable, 1 to enable", _, true, 0.0, true, 1.0);
	cvarUpdater=CreateConVar("ff2_updater", "1", "0-Disable Updater support, 1-Enable automatic updating (recommended, requires Updater)", _, true, 0.0, true, 1.0);
	cvarDebug=CreateConVar("ff2_debug", "0", "0-Disable FF2 debug output, 1-Enable debugging (not recommended)", _, true, 0.0, true, 1.0);
	ff2_fix_boss_skin=CreateConVar("ff2_fix_boss_skin", "1", "Make FF2 remove wearables in a new way(fixes certain buggy models having bad skin)? 0 - No, 1 - Yes", _, true, 0.0, true, 1.0);
	ff2_attribute_manage=CreateConVar("ff2_attribute_manage", "0", "0-FF2 will leave TF2x10 manage weapons, which have their attributes changed by FF2 1-FF2 will continue changing weapon attributes 2-Force disable weapon attribute changes(even when TF2x10 is absent)", _, true, 0.0, true, 1.0);
	ff2_changelog_url=CreateConVar("ff2_changelog_url", CHANGELOG_URL, "FF2 Changelog URL. Normally you are not supposed to change this...");

	//The following are used in various subplugins
	CreateConVar("ff2_oldjump", "0", "Use old Saxton Hale jump equations", _, true, 0.0, true, 1.0);
	CreateConVar("ff2_base_jumper_stun", "0", "Whether or not the Base Jumper should be disabled when a player gets stunned", _, true, 0.0, true, 1.0);

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
	HookConVarChange(cvarGoombaDamage, CvarChange);
	HookConVarChange(cvarGoombaRebound, CvarChange);
	HookConVarChange(cvarBossRTD, CvarChange);
	HookConVarChange(cvarUpdater, CvarChange);
	HookConVarChange(cvarDeadRingerHud, CvarChange);
	HookConVarChange(cvarNextmap=FindConVar("sm_nextmap"), CvarChangeNextmap);

	RegConsoleCmd("ff2", FF2Panel);
	RegConsoleCmd("ff2_hp", Command_GetHPCmd);
	RegConsoleCmd("ff2hp", Command_GetHPCmd);
	RegConsoleCmd("ff2_next", QueuePanelCmd);
	RegConsoleCmd("ff2next", QueuePanelCmd);
	RegConsoleCmd("ff2_classinfo", Command_HelpPanelClass);
	RegConsoleCmd("ff2classinfo", Command_HelpPanelClass);
	RegConsoleCmd("ff2_infotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("ff2infotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("ff2_new", NewPanelCmd);
	RegConsoleCmd("ff2new", NewPanelCmd);
	RegConsoleCmd("ff2music", MusicTogglePanelCmd);
	RegConsoleCmd("ff2_music", MusicTogglePanelCmd);
	RegConsoleCmd("ff2voice", VoiceTogglePanelCmd);
	RegConsoleCmd("ff2_voice", VoiceTogglePanelCmd);
	RegConsoleCmd("ff2_resetpoints", ResetQueuePointsCmd);
	RegConsoleCmd("ff2resetpoints", ResetQueuePointsCmd);
	RegConsoleCmd("ff2_companion", CompanionTogglePanelCmd);
	RegConsoleCmd("ff2companion", CompanionTogglePanelCmd);

	RegConsoleCmd("hale", FF2Panel);
	RegConsoleCmd("hale_hp", Command_GetHPCmd);
	RegConsoleCmd("halehp", Command_GetHPCmd);
	RegConsoleCmd("hale_next", QueuePanelCmd);
	RegConsoleCmd("halenext", QueuePanelCmd);
	RegConsoleCmd("hale_classinfo", Command_HelpPanelClass);
	RegConsoleCmd("haleclassinfo", Command_HelpPanelClass);
	RegConsoleCmd("hale_infotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("haleinfotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("hale_new", NewPanelCmd);
	RegConsoleCmd("halenew", NewPanelCmd);
	RegConsoleCmd("halemusic", MusicTogglePanelCmd);
	RegConsoleCmd("hale_music", MusicTogglePanelCmd);
	RegConsoleCmd("halevoice", VoiceTogglePanelCmd);
	RegConsoleCmd("hale_voice", VoiceTogglePanelCmd);
	RegConsoleCmd("hale_resetpoints", ResetQueuePointsCmd);
	RegConsoleCmd("haleresetpoints", ResetQueuePointsCmd);
	RegConsoleCmd("hale_companion", CompanionTogglePanelCmd);
	RegConsoleCmd("halecompanion", CompanionTogglePanelCmd);

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

	RegAdminCmd("hale_select", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage:  hale_addpoints <target> <points>.  Adds queue points to any player");
	RegAdminCmd("hale_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable the control point if ff2_point_type is 0");
	RegAdminCmd("hale_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable the control point if ff2_point_type is 0");
	RegAdminCmd("hale_start_music", Command_StartMusic, ADMFLAG_CHEATS, "Start the Boss's music");
	RegAdminCmd("hale_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music");
	RegAdminCmd("hale_resetqueuepoints", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("hale_resetq", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");

	AutoExecConfig(true, "FreakFortress2");

	FF2Cookies=RegClientCookie("ff2_cookies_mk2", "", CookieAccess_Protected);

	jumpHUD=CreateHudSynchronizer();
	rageHUD=CreateHudSynchronizer();
	livesHUD=CreateHudSynchronizer();
	abilitiesHUD=CreateHudSynchronizer();
	timeleftHUD=CreateHudSynchronizer();
	infoHUD=CreateHudSynchronizer();

	char oldVersion[64];
	GetConVarString(cvarVersion, oldVersion, sizeof(oldVersion));
	if(strcmp(oldVersion, PLUGIN_VERSION, false))
	{
		PrintToServer("[FF2] Warning: Your config may be outdated. Back up tf/cfg/sourcemod/FreakFortress2.cfg and delete it, and this plugin will generate a new one that you can then modify to your original values.");
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

	#if defined _goomba_included
	goomba=LibraryExists("goomba");
	#endif

	#if defined _tf2attributes_included
	tf2attributes=LibraryExists("tf2attributes");
	#endif
	
	tf2x10=LibraryExists("tf2x10");
}

public bool BossTargetFilter(const char[] pattern, Handle clients)
{
	bool non=StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && FindValueInArray(clients, client)==-1)
		{
			if(IsBoss(client))
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

public void OnLibraryAdded(const char[] name)
{
	#if defined _steamtools_included
	if(!strcmp(name, "SteamTools", false))
	{
		steamtools=true;
	}
	#endif

	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
	{
		tf2attributes=true;
	}
	#endif

	#if defined _goomba_included
	if(!strcmp(name, "goomba", false))
	{
		goomba=true;
	}
	#endif

	if(!strcmp(name, "smac", false))
	{
		smac=true;
	}

	#if defined _updater_included && !defined DEV_REVISION
	if(StrEqual(name, "updater") && GetConVarBool(cvarUpdater))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	
	if(StrEqual(name, "tf2x10"))
	{
		tf2x10=true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _steamtools_included
	if(!strcmp(name, "SteamTools", false))
	{
		steamtools=false;
	}
	#endif

	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
	{
		tf2attributes=false;
	}
	#endif

	#if defined _goomba_included
	if(!strcmp(name, "goomba", false))
	{
		goomba=false;
	}
	#endif

	if(!strcmp(name, "smac", false))
	{
		smac=false;
	}

	#if defined _updater_included
	if(StrEqual(name, "updater"))
	{
		Updater_RemovePlugin();
	}
	#endif
	
	if(StrEqual(name, "tf2x10"))
	{
		tf2x10=false;
	}
}

public void OnConfigsExecuted()
{
	tf_arena_use_queue=GetConVarInt(FindConVar("tf_arena_use_queue"));
	mp_teams_unbalance_limit=GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
	tf_arena_first_blood=GetConVarInt(FindConVar("tf_arena_first_blood"));
	mp_forcecamera=GetConVarInt(FindConVar("mp_forcecamera"));
	tf_dropped_weapon_lifetime=view_as<bool>(GetConVarInt(FindConVar("tf_dropped_weapon_lifetime")));
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

public void OnMapStart()
{
	HPTime=0.0;
	doorCheckTimer=INVALID_HANDLE;
	RoundCount=0;
	for(int client; client<=MaxClients; client++)
	{
		KSpreeTimer[client]=0.0;
		FF2flags[client]=0;
		Incoming[client]=-1;
		MusicTimer[client]=INVALID_HANDLE;
	}

	for(int specials; specials<MAXSPECIALS; specials++)
	{
		if(BossKV[specials]!=INVALID_HANDLE)
		{
			CloseHandle(BossKV[specials]);
			BossKV[specials]=INVALID_HANDLE;
		}
	}
}

public void OnMapEnd()
{
	if(Enabled || Enabled2)
	{
		DisableFF2();
	}
}

public void OnPluginEnd()
{
	OnMapEnd();
}

public void EnableFF2()
{
	Enabled=true;
	Enabled2=true;

	//Cache cvars
	SetConVarString(FindConVar("ff2_version"), PLUGIN_VERSION);
	Announce=GetConVarFloat(cvarAnnounce);
	PointType=GetConVarInt(cvarPointType);
	PointDelay=GetConVarInt(cvarPointDelay);
	if(PointDelay<0)
	{
		PointDelay*=-1;
	}
	GoombaDamage=GetConVarFloat(cvarGoombaDamage);
	reboundPower=GetConVarFloat(cvarGoombaRebound);
	canBossRTD=GetConVarBool(cvarBossRTD);
	DeadRingerHud=GetConVarBool(cvarDeadRingerHud);
	AliveToEnable=GetConVarInt(cvarAliveToEnable);
	if(GetConVarInt(cvarFirstRound)!=-1)
	{
		arenaRounds=GetConVarInt(cvarFirstRound) ? 0 : 1;
	}
	else
	{
		arenaRounds=GetConVarInt(cvarArenaRounds);
	}
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

	float time=Announce;
	if(time>1.0)
	{
		CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	CheckToChangeMapDoors();
	MapHasMusic(true);
	FindCharacters();
	strcopy(FF2CharSetString, 2, "");

	if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
	{
		ServerCommand("smac_removecvar sv_cheats");
		ServerCommand("smac_removecvar host_timescale");
	}

	bMedieval=FindEntityByClassname(-1, "tf_logic_medieval")!=-1 || view_as<bool>(GetConVarInt(FindConVar("tf_medieval")));
	FindHealthBar();

	#if defined _steamtools_included
	if(steamtools)
	{
		char gameDesc[64];
		Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", PLUGIN_VERSION);
		Steam_SetGameDescription(gameDesc);
	}
	#endif

	changeGamemode=0;
}

public void DisableFF2()
{
	Enabled=false;
	Enabled2=false;

	DisableSubPlugins();

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

	for(int client=1; client<=MaxClients; client++)
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

	if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
	{
		ServerCommand("smac_addcvar sv_cheats replicated ban 0 0");
		ServerCommand("smac_addcvar host_timescale replicated ban 1.0 1.0");
	}

	#if defined _steamtools_included
	if(steamtools)
	{
		Steam_SetGameDescription("Team Fortress");
	}
	#endif

	changeGamemode=0;
}

public void FindCharacters()  //TODO: Investigate KvGotoFirstSubKey; KvGotoNextKey
{
	char config[PLATFORM_MAX_PATH], key[4], charset[42];
	Specials=0;
	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters.cfg");

	if(!FileExists(config))
	{
		LogError("[FF2] Freak Fortress 2 disabled-can not find characters.cfg!");
		Enabled2=false;
		return;
	}

	Handle Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	int NumOfCharSet=FF2CharSet;

	Action action=Plugin_Continue;
	Call_StartForward(OnLoadCharacterSet);
	Call_PushCellRef(NumOfCharSet);
	strcopy(charset, sizeof(charset), FF2CharSetString);
	Call_PushStringEx(charset, sizeof(charset), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(action);
	if(action==Plugin_Changed)
	{
		int i=-1;
		if(strlen(charset))
		{
			KvRewind(Kv);
			for(i=0; ; i++)
			{
				KvGetSectionName(Kv, config, sizeof(config));
				if(!strcmp(config, charset, false))
				{
					FF2CharSet=i;
					strcopy(FF2CharSetString, PLATFORM_MAX_PATH, charset);
					KvGotoFirstSubKey(Kv);
					break;
				}

				if(!KvGotoNextKey(Kv))
				{
					i=-1;
					break;
				}
			}
		}

		if(i==-1)
		{
			FF2CharSet=NumOfCharSet;
			for(i=0; i<FF2CharSet; i++)
			{
				KvGotoNextKey(Kv);
			}
			KvGotoFirstSubKey(Kv);
			KvGetSectionName(Kv, FF2CharSetString, sizeof(FF2CharSetString));
		}
	}

	KvRewind(Kv);
	for(int i; i<FF2CharSet; i++)
	{
		KvGotoNextKey(Kv);
	}

	for(int i=1; i<MAXSPECIALS; i++)
	{
		IntToString(i, key, sizeof(key));
		KvGetString(Kv, key, config, PLATFORM_MAX_PATH);
		if(!config[0])  //TODO: Make this more user-friendly (don't immediately break-they might have missed a number)
		{
			break;
		}
		LoadCharacter(config);
	}

	KvGetString(Kv, "chances", ChancesString, sizeof(ChancesString));
	CloseHandle(Kv);

	if(ChancesString[0])
	{
		char stringChances[MAXSPECIALS*2][8];

		int amount=ExplodeString(ChancesString, ";", stringChances, MAXSPECIALS*2, 8);
		if(amount % 2)
		{
			LogError("[FF2 Bosses] Invalid chances string, disregarding chances");
			strcopy(ChancesString, sizeof(ChancesString), "");
			amount=0;
		}

		chances[0]=StringToInt(stringChances[0]);
		chances[1]=StringToInt(stringChances[1]);
		for(chancesIndex=2; chancesIndex<amount; chancesIndex++)
		{
			if(chancesIndex % 2)
			{
				if(StringToInt(stringChances[chancesIndex])<=0)
				{
					LogError("[FF2 Bosses] Character %i cannot have a zero or negative chance, disregarding chances", chancesIndex-1);
					strcopy(ChancesString, sizeof(ChancesString), "");
					break;
				}
				chances[chancesIndex]=StringToInt(stringChances[chancesIndex])+chances[chancesIndex-2];
			}
			else
			{
				chances[chancesIndex]=StringToInt(stringChances[chancesIndex]);
			}
		}
	}

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

void EnableSubPlugins(bool force=false)
{
	if(areSubPluginsEnabled && !force)
	{
		return;
	}

	areSubPluginsEnabled=true;
	char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH], filename_old[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "plugins/freaks");
	FileType filetype;
	Handle directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".smx", false)!=-1)
		{
			Format(filename_old, sizeof(filename_old), "%s/%s", path, filename);
			ReplaceString(filename, sizeof(filename), ".smx", ".ff2", false);
			Format(filename, sizeof(filename), "%s/%s", path, filename);
			DeleteFile(filename); // Just in case filename.ff2 also exists: delete it and replace it with the new .smx version
			RenameFile(filename, filename_old);
		}
	}

	directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
		{
			ServerCommand("sm plugins load freaks/%s", filename);
		}
	}
}

void DisableSubPlugins(bool force=false)
{
	if(!areSubPluginsEnabled && !force)
	{
		return;
	}

	char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
	FileType filetype;
	Handle directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
		{
			InsertServerCommand("sm plugins unload freaks/%s", filename);  //ServerCommand will not work when switching maps
		}
	}
	ServerExecute();
	areSubPluginsEnabled=false;
}

public void LoadCharacter(const char[] character)
{
	char extensions[][]={".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
	char config[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, config, sizeof(config), "configs/freak_fortress_2/%s.cfg", character);
	if(!FileExists(config))
	{
		LogError("[FF2 Bosses] Character %s does not exist!", character);
		return;
	}
	BossKV[Specials]=CreateKeyValues("character");
	FileToKeyValues(BossKV[Specials], config);

	int version=KvGetNum(BossKV[Specials], "version", StringToInt(MAJOR_REVISION));
	if(version!=StringToInt(MAJOR_REVISION))
	{
		LogError("[FF2 Bosses] Character %s is only compatible with FF2 v%i!", character, version);
		return;
	}

	int minor_version=KvGetNum(BossKV[Specials], "version_minor", StringToInt(MINOR_REVISION));
	if(minor_version>StringToInt(MINOR_REVISION))
	{
		LogError("[FF2 Bosses] Character %s requires newer version of FF2(at least %s.%i.x)!", character, MAJOR_REVISION, minor_version);
		return;
	}

	int stable_version=KvGetNum(BossKV[Specials], "version_stable", StringToInt(STABLE_REVISION));
	if(stable_version>StringToInt(STABLE_REVISION))
	{
		LogError("[FF2 Bosses] Character %s requires newer version of FF2(at least %s.%s.%i)!", character, MAJOR_REVISION, MINOR_REVISION, stable_version);
		return;
	}

	for(int i=1; ; i++)
	{
		Format(config, 10, "ability%i", i);
		if(KvJumpToKey(BossKV[Specials], config))
		{
			char plugin_name[64];
			KvGetString(BossKV[Specials], "plugin_name", plugin_name, sizeof(plugin_name));
			BuildPath(Path_SM, config, sizeof(config), "plugins/freaks/%s.ff2", plugin_name);
			if(!FileExists(config))
			{
				LogError("[FF2 Bosses] Character %s needs plugin %s!", character, plugin_name);
				return;
			}
		}
		else
		{
			break;
		}
	}
	KvRewind(BossKV[Specials]);

	char key[PLATFORM_MAX_PATH], section[64];
	KvSetString(BossKV[Specials], "filename", character);
	KvGetString(BossKV[Specials], "name", config, sizeof(config));
	bBlockVoice[Specials]=view_as<bool>(KvGetNum(BossKV[Specials], "sound_block_vo", 0));
	BossSpeed[Specials]=KvGetFloat(BossKV[Specials], "maxspeed", 340.0);
	KvGotoFirstSubKey(BossKV[Specials]);

	while(KvGotoNextKey(BossKV[Specials]))
	{
		KvGetSectionName(BossKV[Specials], section, sizeof(section));
		if(!strcmp(section, "download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
				{
					break;
				}

				if(FileExists(config, true))
				{
					AddFileToDownloadsTable(config);
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, config);
				}
			}
		}
		else if(!strcmp(section, "mod_download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
				{
					break;
				}

				for(int extension; extension<sizeof(extensions); extension++)
				{
					Format(key, PLATFORM_MAX_PATH, "%s%s", config, extensions[extension]);
					if(FileExists(key, true))
					{
						AddFileToDownloadsTable(key);
					}
					else
					{
						LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, key);
					}
				}
			}
		}
		else if(!strcmp(section, "mat_download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
				{
					break;
				}
				Format(key, sizeof(key), "%s.vtf", config);
				if(FileExists(key, true))
				{
					AddFileToDownloadsTable(key);
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, key);
				}
				Format(key, sizeof(key), "%s.vmt", config);
				if(FileExists(key, true))
				{
					AddFileToDownloadsTable(key);
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, key);
				}
			}
		}
	}
	Specials++;
}

public void PrecacheCharacter(int characterIndex)
{
	char file[PLATFORM_MAX_PATH], filePath[PLATFORM_MAX_PATH], key[8], section[16], bossName[64];
	KvRewind(BossKV[characterIndex]);
	KvGetString(BossKV[characterIndex], "filename", bossName, sizeof(bossName));
	KvGotoFirstSubKey(BossKV[characterIndex]);
	while(KvGotoNextKey(BossKV[characterIndex]))
	{
		KvGetSectionName(BossKV[characterIndex], section, sizeof(section));
		if(StrEqual(section, "sound_bgm"))
		{
			for(int i=1; ; i++)
			{
				Format(key, sizeof(key), "path%d", i);
				KvGetString(BossKV[characterIndex], key, file, sizeof(file));
				if(!file[0])
				{
					break;
				}

				Format(filePath, sizeof(filePath), "sound/%s", file);  //Sounds doesn't include the sound/ prefix, so add that
				if(FileExists(filePath, true))
				{
					PrecacheSound(file);
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
				}
			}
		}
		else if(StrEqual(section, "mod_precache") || !StrContains(section, "sound_") || !StrContains(section, "catch_"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[characterIndex], key, file, sizeof(file));
				if(!file[0])
				{
					break;
				}

				if(StrEqual(section, "mod_precache"))
				{
					if(FileExists(file, true))
					{
						PrecacheModel(file);
					}
					else
					{
						LogError("[FF2 Bosses] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
					}
				}
				else
				{
					Format(filePath, sizeof(filePath), "sound/%s", file);  //Sounds doesn't include the sound/ prefix, so add that
					if(FileExists(filePath, true))
					{
						PrecacheSound(file);
					}
					else
					{
						LogError("[FF2 Bosses] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
					}
				}
			}
		}
	}
}

public void CvarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar==cvarPointDelay)
	{
		PointDelay=StringToInt(newValue);
		if(PointDelay<0)
		{
			PointDelay*=-1;
		}
	}
	else if(convar==cvarAnnounce)
	{
		Announce=StringToFloat(newValue);
	}
	else if(convar==cvarPointType)
	{
		PointType=StringToInt(newValue);
	}
	else if(convar==cvarAliveToEnable)
	{
		AliveToEnable=StringToInt(newValue);
	}
	else if(convar==cvarFirstRound)  //DEPRECATED
	{
		if(StringToInt(newValue)!=-1)
		{
			arenaRounds=StringToInt(newValue) ? 0 : 1;
		}
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
		lastPlayerGlow=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarSpecForceBoss)
	{
		SpecForceBoss=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarBossTeleporter)
	{
		bossTeleportation=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarShieldCrits)
	{
		shieldCrits=StringToInt(newValue);
	}
	else if(convar==cvarCaberDetonations)
	{
		allowedDetonations=StringToInt(newValue);
	}
	else if(convar==cvarGoombaDamage)
	{
		GoombaDamage=StringToFloat(newValue);
	}
	else if(convar==cvarGoombaRebound)
	{
		reboundPower=StringToFloat(newValue);
	}
	else if(convar==cvarBossRTD)
	{
		canBossRTD=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarDeadRingerHud)
	{
		DeadRingerHud=view_as<bool>(StringToInt(newValue));
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

public Action Timer_Announce(Handle timer)
{
	static int announcecount=-1;
	announcecount++;
	if(Announce>1.0 && Enabled2)
	{
		switch(announcecount)
		{
		case 1:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_group");
			}
		case 3:
			{
				CPrintToChatAll("%t", "ff2_info", PLUGIN_VERSION);
			}
		case 4:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "type_ff2_to_open_menu");
			}
		case 5:
			{
				announcecount=0;
				CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_last_update", PLUGIN_VERSION, ff2versiondates);
			}
		default:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "type_ff2_to_open_menu");
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsFF2Map()
{
	char config[PLATFORM_MAX_PATH];
	GetCurrentMap(currentmap, sizeof(currentmap));
	if(FileExists("bNextMapToFF2"))
	{
		return true;
	}

	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/maps.cfg");
	if(!FileExists(config))
	{
		LogError("[FF2] Unable to find %s, disabling plugin.", config);
		return false;
	}

	Handle file=OpenFile(config, "r");
	if(file==INVALID_HANDLE)
	{
		LogError("[FF2] Error reading maps from %s, disabling plugin.", config);
		return false;
	}

	int tries;
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

stock bool MapHasMusic(bool forceRecalc=false)  //SAAAAAARGE
{
	static bool hasMusic;
	static bool found;
	if(forceRecalc)
	{
		found=false;
		hasMusic=false;
	}

	if(!found)
	{
		int entity=-1;
		char name[64];
		while((entity=FindEntityByClassname2(entity, "info_target"))!=-1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if(!strcmp(name, "hale_no_music", false))
			{
				hasMusic=true;
			}
		}
		found=true;
	}
	return hasMusic;
}

stock bool CheckToChangeMapDoors()
{
	if(!Enabled || !Enabled2)
	{
		return;
	}

	char config[PLATFORM_MAX_PATH];
	checkDoors=false;
	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/doors.cfg");
	if(!FileExists(config))
	{
		if(!strcmp(currentmap, "vsh_lolcano_pb1", false))
		{
			checkDoors=true;
		}
		return;
	}

	Handle file=OpenFile(config, "r");
	if(file==INVALID_HANDLE)
	{
		if(!strcmp(currentmap, "vsh_lolcano_pb1", false))
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

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
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

	bool blueBoss;
	switch(GetConVarInt(cvarForceBossTeam))
	{
	case 1:
		{
			blueBoss=view_as<bool>(GetRandomInt(0, 1));
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
		SetTeamScore(view_as<int>(TFTeam_Red), GetTeamScore(OtherTeam));
		SetTeamScore(view_as<int>(TFTeam_Blue), GetTeamScore(BossTeam));
		OtherTeam=view_as<int>(TFTeam_Red);
		BossTeam=view_as<int>(TFTeam_Blue);
	}
	else
	{
		SetTeamScore(view_as<int>(TFTeam_Red), GetTeamScore(BossTeam));
		SetTeamScore(view_as<int>(TFTeam_Blue), GetTeamScore(OtherTeam));
		OtherTeam=view_as<int>(TFTeam_Blue);
		BossTeam=view_as<int>(TFTeam_Red);
	}

	playing=0;
	for(int client=1; client<=MaxClients; client++)
	{
		Damage[client]=0;
		uberTarget[client]=-1;
		emitRageSound[client]=true;
		if(IsValidClient(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
		{
			playing++;
		}
	}

	if(GetClientCount()<=1 || playing<=1)  //Not enough players D:
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "needmoreplayers");
		Enabled=false;
		DisableSubPlugins();
		SetControlPoint(true);
		return Plugin_Continue;
	}
	else if(RoundCount<arenaRounds)  //We're still in arena mode
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "arena_round", arenaRounds-RoundCount);
		Enabled=false;
		DisableSubPlugins();
		SetArenaCapEnableTime(60.0);
		CreateTimer(71.0, Timer_EnableCap, _, TIMER_FLAG_NO_MAPCHANGE);
		bool toRed;
		TFTeam team;
		for(int client; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && (team=view_as<TFTeam>(GetClientTeam(client)))>TFTeam_Spectator)
			{
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				if(toRed && team!=TFTeam_Red)
				{
					ChangeClientTeam(client, view_as<int>(TFTeam_Red));
				}
				else if(!toRed && team!=TFTeam_Blue)
				{
					ChangeClientTeam(client, view_as<int>(TFTeam_Blue));
				}
				SetEntProp(client, Prop_Send, "m_lifeState", 0);
				TF2_RespawnPlayer(client);
				toRed=!toRed;
			}
		}
		return Plugin_Continue;
	}

	for(int client; client<=MaxClients; client++)
	{
		Boss[client]=0;
		if(IsValidClient(client) && IsPlayerAlive(client) && !(FF2flags[client] & FF2FLAG_HASONGIVED))
		{
			TF2_RespawnPlayer(client);
		}
	}

	Enabled=true;
	EnableSubPlugins();
	CheckArena();

	bool[] omit=new bool[MaxClients+1];
	Boss[0]=GetClientWithMostQueuePoints(omit);
	omit[Boss[0]]=true;

	bool teamHasPlayers[TFTeam];
	for(int client=1; client<=MaxClients; client++)  //Find out if each team has at least one player on it
	{
		if(IsValidClient(client))
		{
			TFTeam team=view_as<TFTeam>(GetClientTeam(client));
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
		if(IsValidClient(Boss[0]) && GetClientTeam(Boss[0])!=BossTeam)
		{
			AssignTeam(Boss[0], BossTeam);
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !IsBoss(client) && GetClientTeam(client)!=OtherTeam)
			{
				CreateTimer(0.1, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		return Plugin_Continue;  //NOTE: This is needed because OnRoundStart gets fired a second time once both teams have players
	}

	PickCharacter(0, 0);
	if((Special[0]<0) || !BossKV[Special[0]])
	{
		LogError("[FF2 Bosses] Couldn't find a boss!");
		return Plugin_Continue;
	}

	FindCompanion(0, playing, omit);  //Find companions for the boss!

	for(int boss; boss<=MaxClients; boss++)
	{
		BossInfoTimer[boss][0]=INVALID_HANDLE;
		BossInfoTimer[boss][1]=INVALID_HANDLE;
		if(Boss[boss])
		{
			CreateTimer(0.3, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
			BossInfoTimer[boss][0]=CreateTimer(30.2, BossInfoTimer_Begin, boss, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	CreateTimer(3.5, StartResponseTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.1, StartBossTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.6, MessageTimer, _, TIMER_FLAG_NO_MAPCHANGE);

	for(int entity=MaxClients+1; entity<MAXENTITIES; entity++)
	{
		if(!IsValidEntity(entity))
		{
			continue;
		}

		char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!strcmp(classname, "func_regenerate"))
		{
			AcceptEntityInput(entity, "Kill");
		}
		else if(!strcmp(classname, "func_respawnroomvisualizer"))
		{
			AcceptEntityInput(entity, "Disable");
		}
	}

	healthcheckused=0;
	firstBlood=true;
	return Plugin_Continue;
}

public Action Timer_EnableCap(Handle timer)
{
	if((Enabled || Enabled2) && CheckRoundState()==-1)
	{
		SetControlPoint(true);
		if(checkDoors)
		{
			int ent=-1;
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

public Action BossInfoTimer_Begin(Handle timer, any boss)
{
	BossInfoTimer[boss][0]=INVALID_HANDLE;
	BossInfoTimer[boss][1]=CreateTimer(0.2, BossInfoTimer_ShowInfo, boss, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action BossInfoTimer_ShowInfo(Handle timer, any boss)
{
	if(!IsValidClient(Boss[boss]))
	{
		BossInfoTimer[boss][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}

	if(bossHasReloadAbility[boss])
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		if(bossHasRightMouseAbility[boss])
		{
			FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t\n%t", "ff2_buttons_reload", "ff2_buttons_rmb");
		}
		else
		{
			FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t", "ff2_buttons_reload");
		}
	}
	else if(bossHasRightMouseAbility[boss])
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t", "ff2_buttons_rmb");
	}
	else
	{
		BossInfoTimer[boss][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_CheckDoors(Handle timer)
{
	if(!checkDoors)
	{
		doorCheckTimer=INVALID_HANDLE;
		return Plugin_Stop;
	}

	if((!Enabled && CheckRoundState()!=-1) || (Enabled && CheckRoundState()!=1))
	{
		return Plugin_Continue;
	}

	int entity=-1;
	while((entity=FindEntityByClassname2(entity, "func_door"))!=-1)
	{
		AcceptEntityInput(entity, "Open");
		AcceptEntityInput(entity, "Unlock");
	}
	return Plugin_Continue;
}

public void CheckArena()
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

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	RoundCount++;

	if(!Enabled)
	{
		return Plugin_Continue;
	}

	executed=false;
	executed2=false;
	bool bossWin=false;
	char sound[PLATFORM_MAX_PATH];
	if((GetEventInt(event, "team")==BossTeam))
	{
		bossWin=true;
		if(RandomSound("sound_win", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[0], _, _, false);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[0], _, _, false);
		}
	}

	StopMusic();
	DrawGameTimer=INVALID_HANDLE;

	bool isBossAlive;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]))
		{
			SetClientGlow(Boss[boss], 0.0, 0.0);
			SDKUnhook(boss, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal
			if(IsPlayerAlive(Boss[boss]))
			{
				isBossAlive=true;
			}

			for(int slot=1; slot<8; slot++)
			{
				BossCharge[boss][slot]=0.0;
			}

			bossHasReloadAbility[boss]=false;
			bossHasRightMouseAbility[boss]=false;
		}
		else if(IsValidClient(boss))  //Boss here is actually a client index
		{
			SetClientGlow(boss, 0.0, 0.0);
			detonations[boss]=0;
		}

		for(int timer; timer<=1; timer++)
		{
			if(BossInfoTimer[boss][timer]!=INVALID_HANDLE)
			{
				KillTimer(BossInfoTimer[boss][timer]);
				BossInfoTimer[boss][timer]=INVALID_HANDLE;
			}
		}
	}

	int boss;
	if(isBossAlive)
	{
		char text[128];
		char bossName[64], lives[8];
		for(int target; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				boss=Boss[target];
				KvRewind(BossKV[Special[boss]]);
				KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "=Failed name=");
				BossLives[boss]>1 ? Format(lives, sizeof(lives), "x%i", BossLives[boss]) : strcopy(lives, 2, "");
				Format(text, sizeof(text), "%s\n%t", text, "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
				CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
			}
		}

		SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
		for(int client; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				FF2_ShowHudText(client, -1, "%s", text);
			}
		}

		if(!bossWin && RandomSound("sound_fail", sound, sizeof(sound), boss))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
		}
	}

	int top[3];
	Damage[0]=0;
	for(int client=1; client<=MaxClients; client++)
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

	char leaders[3][32];
	for(int i; i<=2; i++)
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

	char text[128];  //Do not decl this
	for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			SetGlobalTransTarget(client);
			//TODO:  Clear HUD text here
			if(IsBoss(client))
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], (bossWin ? "boss_win" : "boss_lose"));
			}
			else
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "damage_fx", Damage[client], "scores", RoundFloat(Damage[client]/600.0));
			}
		}
	}

	CreateTimer(3.0, Timer_CalcQueuePoints, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
	return Plugin_Continue;
}

public Action OnBroadcast(Handle event, const char[] name, bool dontBroadcast)
{
	char sound[PLATFORM_MAX_PATH];
	GetEventString(event, "sound", sound, sizeof(sound));
	if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Timer_NineThousand(Handle timer)
{
	EmitSoundToAll("saxton_hale/9000.wav", _, _, _, _, _, _, _, _, _, false);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, _, _, _, _, _, _, _, false);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, _, _, _, _, _, _, _, false);
	return Plugin_Continue;
}

public Action Timer_CalcQueuePoints(Handle timer)
{
	int damage;
	botqueuepoints+=5;
	int[] add_points=new int[MaxClients+1];
	int[] add_points2=new int[MaxClients+1];
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			damage=Damage[client];
			Handle event=CreateEvent("player_escort_score", true);
			SetEventInt(event, "player", client);

			int points;
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
			else if(!IsFakeClient(client) && (GetClientTeam(client)>view_as<int>(TFTeam_Spectator) || SpecForceBoss))
			{
				add_points[client]=10;
				add_points2[client]=10;
			}
		}
	}

	Action action;
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
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					if(add_points2[client]>0)
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "add_points", add_points2[client]);
					}
					SetClientQueuePoints(client, GetClientQueuePoints(client)+add_points2[client]);
				}
			}
		}
	default:
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					if(add_points[client]>0)
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "add_points", add_points[client]);
					}
					SetClientQueuePoints(client, GetClientQueuePoints(client)+add_points[client]);
				}
			}
		}
	}
}

public Action StartResponseTimer(Handle timer)
{
	char sound[PLATFORM_MAX_PATH];
	if(RandomSound("sound_begin", sound, sizeof(sound)))
	{
		EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
		EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
	}
	return Plugin_Continue;
}

public Action StartBossTimer(Handle timer)
{
	CreateTimer(0.1, Timer_Move, _, TIMER_FLAG_NO_MAPCHANGE);
	bool isBossAlive;
	for(int boss; boss<=MaxClients; boss++)
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
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsBoss(client) && IsPlayerAlive(client))
		{
			playing++;
			CreateTimer(0.15, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);  //TODO:  Is this needed?
		}
	}
	
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			BossHealthMax[boss]=ParseFormula(boss, "health_formula", "(((760.8+n)*(n-1))^1.0341)+2046", RoundFloat(Pow((760.8+float(playing))*(float(playing)-1.0), 1.0341)+2046.0));
			BossHealth[boss]=BossHealthMax[boss]*BossLivesMax[boss];
			BossHealthLast[boss]=BossHealth[boss];
		}
	}

	CreateTimer(0.2, BossTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, Timer_StartRound, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_PrepareBGM, 0, TIMER_FLAG_NO_MAPCHANGE);

	if(!PointType)
	{
		SetControlPoint(false);
	}
	return Plugin_Continue;
}

public Action Timer_PrepareBGM(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(CheckRoundState()!=1 || (!client && MapHasMusic()) || (!client && userid))
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
					RequestFrame(PlayBGM, GetClientUserId(client)); // Naydef: We might start playing the music before it gets stopped
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
			RequestFrame(PlayBGM, GetClientUserId(client)); // Naydef: We might start playing the music before it gets stopped
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

void PlayBGM(int userid)
{
	int client=GetClientOfUserId(userid);
	if(!IsValidClient(client))
	{
		return;
	}

	KvRewind(BossKV[Special[0]]);
	if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
	{
		char music[PLATFORM_MAX_PATH];
		int index;
		do
		{
			index++;
			Format(music, 10, "time%i", index);
		}
		while(KvGetFloat(BossKV[Special[0]], music)>1);

		index=GetRandomInt(1, index-1);
		Format(music, 10, "time%i", index);
		float time=KvGetFloat(BossKV[Special[0]], music);
		Format(music, 10, "path%i", index);
		KvGetString(BossKV[Special[0]], music, music, sizeof(music));

		Action action;
		Call_StartForward(OnMusic);
		char temp[PLATFORM_MAX_PATH];
		float time2=time;
		strcopy(temp, sizeof(temp), music);
		Call_PushStringEx(temp, sizeof(temp), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushFloatRef(time2);
		Call_Finish(action);
		switch(action)
		{
		case Plugin_Stop, Plugin_Handled:
			{
				return;
			}
		case Plugin_Changed:
			{
				strcopy(music, sizeof(music), temp);
				time=time2;
			}
		}

		Format(temp, sizeof(temp), "sound/%s", music);
		if(FileExists(temp, true))
		{
			if(CheckSoundException(client, SOUNDEXCEPT_MUSIC))
			{
				strcopy(currentBGM[client], PLATFORM_MAX_PATH, music);
				ClientCommand(client, "playgamesound \"%s\"", music);
				if(time>1)
				{
					MusicTimer[client]=CreateTimer(time, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		else
		{
			char bossName[64];
			KvRewind(BossKV[Special[0]]);
			KvGetString(BossKV[Special[0]], "filename", bossName, sizeof(bossName));
			PrintToServer("[FF2 Bosses] Character %s is missing BGM file '%s'!", bossName, music);
		}
	}
}

void StartMusic(int client=0)
{
	if(client<=0)  //Start music for all clients
	{
		StopMusic();
		for(int target; target<=MaxClients; target++)
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

void StopMusic(int client=0, bool permanent=false)
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

stock void EmitSoundToAllExcept(int exceptiontype=SOUNDEXCEPT_MUSIC, const char[] sample, int entity=SOUND_FROM_PLAYER, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL, int speakerentity=-1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos=true, float soundtime=0.0)
{
	int[] clients=new int[MaxClients];
	int total;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsClientInGame(client))
		{
			if(CheckSoundException(client, exceptiontype))
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

stock bool CheckSoundException(int client, int soundException)
{
	if(!IsValidClient(client))
	{
		return false;
	}

	if(IsFakeClient(client) || !AreClientCookiesCached(client))
	{
		return true;
	}

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	if(soundException==SOUNDEXCEPT_VOICE)
	{
		return StringToInt(cookieValues[2])==1;
	}
	return StringToInt(cookieValues[1])==1;
}

void SetClientSoundOptions(int client, int soundException, bool enable)
{
	if(!IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client))
	{
		return;
	}

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	if(soundException==SOUNDEXCEPT_VOICE)
	{
		if(enable)
		{
			cookieValues[2][0]='1';
		}
		else
		{
			cookieValues[2][0]='0';
		}
	}
	else
	{
		if(enable)
		{
			cookieValues[1][0]='1';
		}
		else
		{
			cookieValues[1][0]='0';
		}
	}
	Format(cookies, sizeof(cookies), "%s %s %s %s %s %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[3], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
	SetClientCookie(client, FF2Cookies, cookies);
}

void SetClientPreferences(int client, int type, bool enable)
{
	if(!IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client))
	{
		return;
	}

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	if(type==TOGGLE_COMPANION)
	{
		if(enable)
		{
			cookieValues[4][0]='1';
		}
		else
		{
			cookieValues[4][0]='0';
		}
	}
	Format(cookies, sizeof(cookies), "%s %s %s %s %s %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[3], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
	SetClientCookie(client, FF2Cookies, cookies);
}

public Action Timer_Move(Handle timer)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}

public Action Timer_StartRound(Handle timer)
{
	CreateTimer(10.0, Timer_NextBossPanel, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
	return Plugin_Handled;
}

public Action Timer_NextBossPanel(Handle timer)
{
	int clients;
	bool[] added=new bool[MaxClients+1];
	while(clients<3)  //TODO: Make this configurable?
	{
		int client=GetClientWithMostQueuePoints(added);
		if(!IsValidClient(client))  //No more players left on the server
		{
			break;
		}

		if(!IsBoss(client))
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "to0_near");  //"You will become the Boss soon. Type {olive}/ff2next{default} to make sure."
			clients++;
		}
		added[client]=true;
	}
}

public Action MessageTimer(Handle timer)
{
	if(CheckRoundState())
	{
		return Plugin_Continue;
	}

	if(checkDoors)
	{
		int entity=-1;
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
	char text[512];
	char textChat[512];
	char lives[8];
	char name[64];
	for(int client; client<=MaxClients; client++)
	{
		if(IsBoss(client))
		{
			int boss=Boss[client];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", name, sizeof(name), "=Failed name=");
			if(BossLives[boss]>1)
			{
				Format(lives, sizeof(lives), "x%i", BossLives[boss]);
			}
			else
			{
				strcopy(lives, 2, "");
			}

			Format(text, sizeof(text), "%s\n%t", text, "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
			Format(textChat, sizeof(textChat), "{olive}[FF2]{default} %t!", "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
			ReplaceString(textChat, sizeof(textChat), "\n", "");  //Get rid of newlines
			CPrintToChatAll("%s", textChat);
		}
	}

	for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			SetGlobalTransTarget(client);
			FF2_ShowSyncHudText(client, infoHUD, text);
		}
	}
	return Plugin_Continue;
}

public Action MakeModelTimer(Handle timer, any client)
{
	if(IsValidClient(Boss[client]) && IsPlayerAlive(Boss[client]) && CheckRoundState()!=2)
	{
		char model[PLATFORM_MAX_PATH];
		KvRewind(BossKV[Special[client]]);
		KvGetString(BossKV[Special[client]], "model", model, PLATFORM_MAX_PATH);
		SetVariantString(model);
		AcceptEntityInput(Boss[client], "SetCustomModel");
		SetEntProp(Boss[client], Prop_Send, "m_bUseClassAnimations", 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

void EquipBoss(int boss)
{
	int client=Boss[boss];
	DoOverlay(client, "");
	TF2_RemoveAllWeapons(client);
	char key[10], classname[64], attributes[256];
	for(int i=1; ; i++)
	{
		KvRewind(BossKV[Special[boss]]);
		char bossName[64];
		KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName));
		Format(key, sizeof(key), "weapon%i", i);
		if(KvJumpToKey(BossKV[Special[boss]], key))
		{
			KvGetString(BossKV[Special[boss]], "name", classname, sizeof(classname));
			KvGetString(BossKV[Special[boss]], "attributes", attributes, sizeof(attributes));
			if(!KvGetNum(BossKV[Special[boss]], "override", 0))
			{
				if(attributes[0]!='\0')
				{
					Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1 ; %s", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2 ,attributes);
					//68: +2 cap rate
					//2: x3.1 damage
				}
				else
				{
					Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2);
					//68: +2 cap rate
					//2: x3.1 damage
				}
			}

			int index=KvGetNum(BossKV[Special[boss]], "index");
			int level=KvGetNum(BossKV[Special[boss]], "level", 101);
			int quality=KvGetNum(BossKV[Special[boss]], "quality", 5);
			int weapon=FF2_SpawnWeapon(client, classname, index, level, quality, attributes, view_as<bool>(KvGetNum(BossKV[Special[boss]], "show", 0)));
			if(weapon==-1)
			{
				LogError("Tried to give weapon to boss %s, but an error occured!", bossName);
				return;
			}
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

			if(!KvGetNum(BossKV[Special[boss]], "show", 0))
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
			}
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
		else
		{
			break;
		}
	}

	KvGoBack(BossKV[Special[boss]]);
	TFClassType player_class=view_as<TFClassType>(GetClassForBoss(BossKV[Special[Boss[client]]]));
	if(TF2_GetPlayerClass(client)!=player_class)
	{
		TF2_SetPlayerClass(client, player_class, _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	}
}

public Action Timer_MakeBoss(Handle timer, any boss)
{
	int client=Boss[boss];
	if(!IsValidClient(client) || CheckRoundState()==-1)
	{
		return Plugin_Continue;
	}

	if(!IsPlayerAlive(client))
	{
		if(!CheckRoundState())
		{
			TF2_RespawnPlayer(client);
		}
		else
		{
			return Plugin_Continue;
		}
	}

	KvRewind(BossKV[Special[boss]]);
	if(GetClientTeam(client)!=BossTeam)
	{
		AssignTeam(client, BossTeam);
	}

	BossRageDamage[boss]=ParseFormula(boss, "ragedamage", "1900", 1900);
	if(BossRageDamage[boss]<0)	// -1 or below, disable RAGE
	{
		BossRageDamage[boss]=99999;
	}

	BossLivesMax[boss]=KvGetNum(BossKV[Special[boss]], "lives", 1);
	if(BossLivesMax[boss]<=0)
	{
		char bossName[64];
		KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName));
		PrintToServer("[FF2 Bosses] Warning: Boss %s has an invalid amount of lives, setting to 1", bossName);
		BossLivesMax[boss]=1;
	}

	BossHealthMax[boss]=ParseFormula(boss, "health_formula", "(((760.8+n)*(n-1))^1.0341)+2046", RoundFloat(Pow((760.8+float(playing))*(float(playing)-1.0), 1.0341)+2046.0));
	BossLives[boss]=BossLivesMax[boss];
	BossHealth[boss]=BossHealthMax[boss]*BossLivesMax[boss];
	BossHealthLast[boss]=BossHealth[boss];

	DmgTriple[boss]=false;
	if(KvGetNum(BossKV[Special[boss]], "triple", 1))
	{
		DmgTriple[boss]=true;
	}
	
	if(KvGetNum(BossKV[Special[boss]], "knockback", -1)>=0)
	{
		SelfKnockback[boss]=view_as<bool>(KvGetNum(BossKV[Special[boss]], "knockback", -1));
	}
	else if(KvGetNum(BossKV[Special[boss]], "rocketjump", -1)>=0)
	{
		SelfKnockback[boss]=view_as<bool>(KvGetNum(BossKV[Special[boss]], "rocketjump", -1));
	}
	else
	{
		SelfKnockback[boss]=false;
	}

	if(KvGetNum(BossKV[Special[boss]], "crits", -1) >= 0)
	{
		randomCrits[boss]=view_as<bool>(KvGetNum(BossKV[Special[boss]], "crits", -1));
	}
	else
	{
		randomCrits[boss]=cvarCrits.BoolValue;
	}

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	TF2_RemovePlayerDisguise(client);
	TF2_SetPlayerClass(client, GetClassForBoss(BossKV[Special[boss]]), _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal

	switch(KvGetNum(BossKV[Special[boss]], "pickups", 0))  //Check if the boss is allowed to pickup health/ammo
	{
	case 1:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS;
		}
	case 2:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_AMMO_PICKUPS;
		}
	case 3:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
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

	int entity=-1;
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

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle &item)
{
	if(!Enabled /*|| item!=INVALID_HANDLE*/)
	{
		return Plugin_Continue;
	}

	if(IsBoss(client) && StrEqual(classname, "tf_wearable", false) && GetConVarBool(ff2_fix_boss_skin))
	{
		if(!(FF2flags[client] & FF2FLAG_ALLOW_BOSS_WEARABLES))
		{
			return Plugin_Handled;
		}
	}
	
	if((!ff2_attribute_manage.IntValue && tf2x10) || ff2_attribute_manage.IntValue==2)
	{
		return Plugin_Continue;
	}
	else
	{
		switch(iItemDefinitionIndex)
		{
		case 38, 457:  //Axtinguisher, Postal Pummeler
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
		case 39, 351, 1081:  //Flaregun, Detonator, Festive Flaregun
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "25 ; 0.5 ; 58 ; 3.2 ; 144 ; 1.0 ; 207 ; 1.33", true);
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
				Handle itemOverride=PrepareItemHandle(item, _, _, "165 ; 1.0");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
		case 224:  //L'etranger
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "85 ; 0.5 ; 157 ; 1.0 ; 253 ; 1.0");
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
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 191 ; -7 ; 772 ; 1.5", true);
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
				Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.5 ; 76 ; 2");
				//2: +50% damage
				//76: +100% ammo
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
		case 226:  //Battalion's Backup
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "140 ; 10.0");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
		case 231:  //Darwin's Danger Shield
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 50");  //+50 health
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
		case 305, 1079:  //Crusader's Crossbow, Festive Crusader's Crossbow
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.2 ; 17 ; 0.15");
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
				Handle itemOverride=PrepareItemHandle(item, _, _, "205 ; 0.8 ; 206 ; 2.0 ; 772 ; 2.0", true);
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
				Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1 ; 3 ; 0.5 ; 114 ; 1 ; 179 ; 1 ; 547 ; 0.6", true);
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
				#if defined _tf2attributes_included
				if(tf2attributes)
				{
					TF2Attrib_SetByDefIndex(client, 58, 1.5);
				}
				#endif
			}
		case 648:  //Wrap Assassin
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "279 ; 2.0");
				//279: 2 ornaments
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
		case 656:  //Holiday Punch
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "199 ; 0 ; 547 ; 0 ; 358 ; 0 ; 362 ; 0 ; 363 ; 0 ; 369 ; 0", true);
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
				Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.25 ; 109 ; 0.5 ; 125 ; -25 ; 394 ; 0.85 ; 418 ; 1 ; 419 ; 100 ; 532 ; 0.5 ; 651 ; 0.5 ; 709 ; 1", true);
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
				Handle itemOverride=PrepareItemHandle(item, _, _, "179 ; 1");
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
			Handle itemOverride;
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
			Handle itemOverride=PrepareItemHandle(item, _, _, "17 ; 0.05 ; 144 ; 1", true);
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
			Handle itemOverride=PrepareItemHandle(item, _, _, "10 ; 1.75 ; 11 ; 1.5 ; 144 ; 2.0 ; 199 ; 0.75 ; 314 ; 4 ; 547 ; 0.75", true);
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
		
	}
	return Plugin_Continue;
}

public Action Timer_NoHonorBound(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int melee=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		int index=((IsValidEntity(melee) && melee>MaxClients) ? GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex") : -1);
		int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		char classname[64];
		if(IsValidEntity(weapon))
		{
			GetEntityClassname(weapon, classname, sizeof(classname));
		}
		if(index==357 && weapon==melee && !strcmp(classname, "tf_weapon_katana", false))
		{
			SetEntProp(melee, Prop_Send, "m_bIsBloody", 1);
			if(GetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy")<1)
			{
				SetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
			}
		}
	}
}

stock Handle PrepareItemHandle(Handle item, char[] name="", int index=-1, const char[] att="", bool dontPreserve=false)
{
	static Handle weapon;
	int addattribs;

	char weaponAttribsArray[32][32];
	int attribCount=ExplodeString(att, ";", weaponAttribsArray, 32, 32);

	if(attribCount % 2)
	{
		--attribCount;
	}

	int flags=OVERRIDE_ATTRIBUTES;
	if(!dontPreserve)
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
			for(int i; i<2*addattribs; i+=2)
			{
				bool dontAdd=false;
				int attribIndex=TF2Items_GetAttributeId(item, i);
				for(int z; z<attribCount+i; z+=2)
				{
					if(StringToInt(weaponAttribsArray[z])==attribIndex)
					{
						dontAdd=true;
						break;
					}
				}

				if(!dontAdd)
				{
					IntToString(attribIndex, weaponAttribsArray[i+attribCount], 32);
					FloatToString(TF2Items_GetAttributeValue(item, i), weaponAttribsArray[i+1+attribCount], 32);
				}
			}
			attribCount+=2*addattribs;
		}

		if(weapon!=item)  //FlaminSarge: Item might be equal to weapon, so closing item's handle would also close weapon's
		{
			CloseHandle(item);  //probably returns false but whatever (rswallen-apparently not)
		}
	}

	if(name[0]!='\0')
	{
		flags|=OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(weapon, name);
	}

	if(index!=-1)
	{
		flags|=OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(weapon, index);
	}

	if(attribCount>0)
	{
		TF2Items_SetNumAttributes(weapon, attribCount/2);
		int i2;
		for(int i; i<attribCount && i2<16; i+=2)
		{
			int attrib=StringToInt(weaponAttribsArray[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", weaponAttribsArray[i], weaponAttribsArray[i+1]);
				CloseHandle(weapon);
				return INVALID_HANDLE;
			}

			TF2Items_SetAttribute(weapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
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

public Action Timer_MakeNotBoss(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==2 || IsBoss(client) || (FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		return Plugin_Continue;
	}

	if(!IsVoteInProgress() && GetClientClassInfoCookie(client) && !(FF2flags[client] & FF2FLAG_CLASSHELPED))
	{
		HelpPanelClass(client);
	}

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);  //This really shouldn't be needed but I've been noticing players who still have glow

	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client)); //Temporary: Reset health to avoid an overheal bug
	if(GetClientTeam(client)==BossTeam)
	{
		AssignTeam(client, OtherTeam);
	}

	CreateTimer(0.1, Timer_CheckItems, userid, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_CheckItems(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==2 || IsBoss(client) || (FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		return Plugin_Continue;
	}

	SetEntityRenderColor(client, 255, 255, 255, 255);
	int index=-1;
	int[] civilianCheck=new int[MaxClients+1];

	//Cloak and Dagger is NEVER allowed, even in Medieval mode
	int weapon=GetPlayerWeaponSlot(client, 4);
	if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==60)  //Cloak and Dagger
	{
		TF2_RemoveWeaponSlot(client, 4);
		FF2_SpawnWeapon(client, "tf_weapon_invis", 30, 1, 0, "");
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
				FF2_SpawnWeapon(client, "tf_weapon_minigun", 15, 1, 0, "");
			}
		case 237:  //Rocket Jumper
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				FF2_SpawnWeapon(client, "tf_weapon_rocketlauncher", 18, 1, 0, "114 ; 1");
				//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
				FF2_SetAmmo(client, weapon, 20);
			}
		case 402:  //Bazaar Bargain
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				FF2_SpawnWeapon(client, "tf_weapon_sniperrifle", 14, 1, 0, "");
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
				FF2_SpawnWeapon(client, "tf_weapon_pipebomblauncher", 20, 1, 0, "");
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

	if(IsValidEntity(FindPlayerBack(client, 642)))  //Cozy Camper
	{
		FF2_SpawnWeapon(client, "tf_weapon_smg", 16, 1, 6, "149 ; 1.5 ; 15 ; 0.0 ; 1 ; 0.85");
	}

	#if defined _tf2attributes_included
	if(tf2attributes)
	{
		if(IsValidEntity(FindPlayerBack(client, 444)))  //Mantreads
		{
			TF2Attrib_SetByDefIndex(client, 58, 1.5);  //+50% increased push force
		}
		else
		{
			TF2Attrib_RemoveByDefIndex(client, 58);
		}
	}
	#endif

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(weapon))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(index)
		{
		case 43:  //KGB
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				FF2_SpawnWeapon(client, "tf_weapon_fists", 239, 1, 6, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 191 ; -7 ; 772 ; 1.5");  //GRU
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
					FF2_SpawnWeapon(client, "tf_weapon_wrench", 7, 1, 0, "");
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
		FF2Dbg("Respawning %N to avoid civilian bug", client);
		TF2_RespawnPlayer(client);
	}
	civilianCheck[client]=0;
	return Plugin_Continue;
}

stock void RemovePlayerTarge(int client)
{
	int entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable_demoshield"))!=-1)
	{
		int index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			if(index==131 || index==406 || index==1099 || index==1144)  //Chargin' Targe, Splendid Screen, Tide Turner, Festive Chargin' Targe
			{
				TF2_RemoveWearable(client, entity);
			}
		}
	}
}

stock void RemovePlayerBack(int client, int[] indices, int length)
{
	if(length<=0)
	{
		return;
	}

	int entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable"))!=-1)
	{
		char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			int index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				for(int i; i<length; i++)
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

stock int FindPlayerBack(int client, int index)
{
	int entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable*"))!=-1)
	{
		char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrContains(netclass, "CTFWearable")!=-1 && GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")==index && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			return entity;
		}
	}
	return -1;
}

public Action OnObjectDestroyed(Handle event, const char[] name, bool dontBroadcast)
{
	if(Enabled)
	{
		int attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
		if(!GetRandomInt(0, 2) && IsBoss(attacker))
		{
			char sound[PLATFORM_MAX_PATH];
			if(RandomSound("sound_kill_buildable", sound, sizeof(sound)))
			{
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
			}
		}
	}
	return Plugin_Continue;
}

public Action OnUberDeployed(Handle event, const char[] name, bool dontBroadcast)
{
	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(Enabled && IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)!=BossTeam)
	{
		int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(medigun))
		{
			char classname[64];
			GetEntityClassname(medigun, classname, sizeof(classname));
			if(StrEqual(classname, "tf_weapon_medigun"))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5, client);
				int target=GetHealingTarget(client);
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

public Action Timer_Uber(Handle timer, any medigunid)
{
	int medigun=EntRefToEntIndex(medigunid);
	if(medigun && IsValidEntity(medigun) && CheckRoundState()==1)
	{
		int client=GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		bool uber_deployed=view_as<bool>(GetEntProp(medigun, Prop_Send, "m_bChargeRelease"));
		if(IsValidClient(client, false) && IsPlayerAlive(client) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==medigun)
		{
			if(uber_deployed)
			{
				int target=GetHealingTarget(client);
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

				if(!TF2_IsPlayerInCondition(client, TFCond_Ubercharged))	// TF2 bug where extended Uber causes Medic to lose it after some time
				{
					TF2_AddCondition(client, TFCond_Ubercharged, 0.5);
				}
			}
			else
			{
				uberTarget[client]=-1;
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

public Action CompanionTogglePanelCmd(int client, int args)
{
	if(!IsValidClient(client) || !GetConVarBool(cvarDuoToggle))
	{
		return Plugin_Continue;
	}

	CompanionTogglePanel(client);
	return Plugin_Handled;
}

Action CompanionTogglePanel(int client, bool menuentered=false)
{
	if(!Enabled || !IsValidClient(client) || !GetConVarBool(cvarDuoToggle))
	{
		return Plugin_Continue;
	}

	Menu ff2_menu=new Menu(CompanionTogglePanelH);
	ff2_menu.SetTitle("Toggle being a Freak Fortress 2 companion...");
	ff2_menu.AddItem("", "On");
	ff2_menu.AddItem("", "Off");
	ff2_menu.ExitBackButton=menuentered;
	ff2_menu.ExitButton=true;
	ff2_menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public int CompanionTogglePanelH(Menu menu, MenuAction action, int client, int selection)
{
	if(IsValidClient(client) && action==MenuAction_Select)
	{
		selection++;
		if(selection==2)
		{
			SetClientPreferences(client, TOGGLE_COMPANION, false);
			CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_companion_off");
		}
		else
		{
			SetClientPreferences(client, TOGGLE_COMPANION, true);
			CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_companion_on");
		}
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if(action==MenuAction_Cancel)
	{
		if(selection==MenuCancel_ExitBack)
		{
			FF2Panel(client, 0);
		}
		else if(selection==MenuCancel_Exit)
		{
			return 0;
		}
	}
	return 0;
}

public Action Command_GetHPCmd(int client, int args)
{
	if(!IsValidClient(client) || !Enabled || CheckRoundState()!=1)
	{
		return Plugin_Continue;
	}

	Command_GetHP(client);
	return Plugin_Handled;
}

public Action Command_GetHP(int client)  //TODO: This can rarely show a very large negative number if you time it right
{
	if(IsBoss(client) || GetGameTime()>=HPTime)
	{
		char text[512], lives[8], name[64];
		for(int target; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				int boss=Boss[target];
				KvRewind(BossKV[Special[boss]]);
				KvGetString(BossKV[Special[boss]], "name", name, sizeof(name), "=Failed name=");
				if(BossLives[boss]>1)
				{
					Format(lives, sizeof(lives), "x%i", BossLives[boss]);
				}
				else
				{
					strcopy(lives, 2, "");
				}
				Format(text, sizeof(text), "%s\n%t", text, "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
				CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
				BossHealthLast[boss]=BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
			}
		}

		for(int target; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
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
		char waitTime[128];
		for(int target; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				Format(waitTime, sizeof(waitTime), "%s %i,", waitTime, BossHealthLast[Boss[target]]);
			}
		}
		CPrintToChat(client, "{olive}[FF2]{default} %t", "wait_hp", RoundFloat(HPTime-GetGameTime()), waitTime);
	}
	return Plugin_Continue;
}

public Action Command_SetNextBoss(int client, int args)
{
	char name[64], boss[64];

	if(args<1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_special <boss>");
		return Plugin_Handled;
	}
	GetCmdArgString(name, sizeof(name));

	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if(StrContains(boss, name, false)!=-1)
		{
			Incoming[0]=config;
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		KvGetString(BossKV[config], "filename", boss, sizeof(boss));
		if(StrContains(boss, name, false)!=-1)
		{
			Incoming[0]=config;
			KvGetString(BossKV[config], "name", boss, sizeof(boss));
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Boss could not be found!");
	return Plugin_Handled;
}

public Action Command_Points(int client, int args)
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

	char stringPoints[8];
	char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, stringPoints, sizeof(stringPoints));
	int points=StringToInt(stringPoints);

	char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches>1)
	{
		for(int target; target<matches; target++)
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

public Action Command_StartMusic(int client, int args)
{
	if(Enabled2)
	{
		if(args)
		{
			char pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			char targetName[MAX_TARGET_LENGTH];
			int targets[MAXPLAYERS], matches;
			bool targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches>1)
			{
				for(int target; target<matches; target++)
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

public Action Command_StopMusic(int client, int args)
{
	if(Enabled2)
	{
		if(args)
		{
			char pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			char targetName[MAX_TARGET_LENGTH];
			int targets[MAXPLAYERS], matches;
			bool targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches>1)
			{
				for(int target; target<matches; target++)
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

public Action Command_Charset(int client, int args)
{
	if(!args)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_charset <charset>");
		return Plugin_Handled;
	}

	char charset[32], rawText[16][16];
	GetCmdArgString(charset, sizeof(charset));
	int amount=ExplodeString(charset, " ", rawText, 16, 16);
	for(int i; i<amount; i++)
	{
		StripQuotes(rawText[i]);
	}
	ImplodeStrings(rawText, amount, " ", charset, sizeof(charset));

	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters.cfg");

	Handle Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	for(int i; ; i++)
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

public Action Command_ReloadSubPlugins(int client, int args)
{
	if(Enabled)
	{
		DisableSubPlugins(true);
		EnableSubPlugins(true);
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Reloaded subplugins!");
	return Plugin_Handled;
}

public Action Command_Point_Disable(int client, int args)
{
	if(Enabled)
	{
		SetControlPoint(false);
	}
	return Plugin_Handled;
}

public Action Command_Point_Enable(int client, int args)
{
	if(Enabled)
	{
		SetControlPoint(true);
	}
	return Plugin_Handled;
}

stock void SetControlPoint(bool enable)
{
	int controlPoint=MaxClients+1;
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

stock void SetArenaCapEnableTime(float time)
{
	int entity=-1;
	if((entity=FindEntityByClassname2(-1, "tf_logic_arena"))!=-1 && IsValidEntity(entity))
	{
		char timeString[32];
		FloatToString(time, timeString, sizeof(timeString));
		DispatchKeyValue(entity, "CapEnableDelay", timeString);
	}
}

public void OnClientPostAdminCheck(int client)
{
	// TODO: Hook these inside of EnableFF2() or somewhere instead
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);

	FF2flags[client]=0;
	Damage[client]=0;
	uberTarget[client]=-1;

	if(AreClientCookiesCached(client))
	{
		char buffer[24];
		GetClientCookie(client, FF2Cookies, buffer, sizeof(buffer));
		if(!buffer[0])
		{
			SetClientCookie(client, FF2Cookies, "0 1 1 1 1 3 3");
			//Queue points | music exception | voice exception | class info | companion toggle | UNUSED | UNUSED
		}
	}

	//We use the 0th index here because client indices can change.
	//If this is false that means music is disabled for all clients, so don't play it for new clients either.
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

public void OnClientDisconnect(int client)
{
	if(Enabled)
	{
		if(IsBoss(client) && !CheckRoundState() && GetConVarBool(cvarPreroundBossDisconnect))
		{
			int boss=GetBossIndex(client);
			bool[] omit=new bool[MaxClients+1];
			omit[client]=true;
			Boss[boss]=GetClientWithMostQueuePoints(omit);

			if(Boss[boss])
			{
				CreateTimer(0.1, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
				CPrintToChat(Boss[boss], "{olive}[FF2]{default} %t", "Replace Disconnected Boss");
				CPrintToChatAll("{olive}[FF2]{default} %t", "Boss Disconnected", client, Boss[boss]);
			}
		}

		if(IsClientInGame(client) && IsPlayerAlive(client) && CheckRoundState()==1)
		{
			CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	FF2flags[client]=0;
	Damage[client]=0;
	uberTarget[client]=-1;

	if(MusicTimer[client]!=INVALID_HANDLE)
	{
		KillTimer(MusicTimer[client]);
		MusicTimer[client]=INVALID_HANDLE;
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(Enabled && CheckRoundState()==1)
	{
		CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action OnPostInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");

	if(IsBoss(client))
	{
		CreateTimer(0.1, Timer_MakeBoss, GetBossIndex(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	if(!(FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		if(!(FF2flags[client] & FF2FLAG_HASONGIVED))
		{
			FF2flags[client]|=FF2FLAG_HASONGIVED;
			RemovePlayerBack(client, {57, 133, 405, 444, 608, 642}, 7);
			RemovePlayerTarge(client);
			TF2_RemoveAllWeapons(client);
			TF2_RegeneratePlayer(client);
			CreateTimer(0.1, Timer_RegenPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		CreateTimer(0.2, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	FF2flags[client]&=~(FF2FLAG_UBERREADY|FF2FLAG_ISBUFFED|FF2FLAG_TALKING|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_USINGABILITY|FF2FLAG_CLASSHELPED|FF2FLAG_CHANGECVAR|FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS|FF2FLAG_ROCKET_JUMPING);
	FF2flags[client]|=FF2FLAG_USEBOSSTIMER;
	return Plugin_Continue;
}

public Action Timer_RegenPlayer(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_RegeneratePlayer(client);
	}
}

public Action ClientTimer(Handle timer)
{
	if(!Enabled || CheckRoundState()==2 || CheckRoundState()==-1)
	{
		return Plugin_Stop;
	}

	char classname[32];
	TFCond cond;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsBoss(client) && !(FF2flags[client] & FF2FLAG_CLASSTIMERDISABLED))
		{
			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
			if(!IsPlayerAlive(client))
			{
				int observer=GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
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

			TFClassType player_class=TF2_GetPlayerClass(client);
			int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(weapon<=MaxClients || !IsValidEntity(weapon) || !GetEntityClassname(weapon, classname, sizeof(classname)))
			{
				strcopy(classname, sizeof(classname), "");
			}
			bool validwep=!StrContains(classname, "tf_weapon", false);

			int index=(validwep ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if(player_class==TFClass_Medic)
			{
				if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
				{
					int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					char mediclassname[64];
					if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
					{
						int charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
						SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
						FF2_ShowSyncHudText(client, jumpHUD, "%T: %i", "uber-charge", client, charge);

						if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
						{
							FakeClientCommandEx(client, "voicemenu 1 7");
							FF2flags[client]|=FF2FLAG_UBERREADY;
						}
					}
				}
				else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
				{
					int healtarget=GetHealingTarget(client, true);
					if(IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget)==TFClass_Scout)
					{
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
					}
				}
			}
			// Chdata's Deadringer Notifier
			else if(DeadRingerHud && TF2_GetPlayerClass(client)==TFClass_Spy)
			{
				if(GetClientCloakIndex(client)==59)
				{
					int drstatus=TF2_IsPlayerInCondition(client, TFCond_Cloaked) ? 2 : GetEntProp(client, Prop_Send, "m_bFeignDeathReady") ? 1 : 0;

					char s[64];

					switch (drstatus)
					{
					case 1:
						{
							SetHudTextParams(-1.0, 0.83, 0.35, 90, 255, 90, 255, 0, 0.0, 0.0, 0.0);
							Format(s, sizeof(s), "%T", "Dead Ringer Ready", client);
						}
					case 2:
						{
							SetHudTextParams(-1.0, 0.83, 0.35, 255, 64, 64, 255, 0, 0.0, 0.0, 0.0);
							Format(s, sizeof(s), "%T", "Dead Ringer Active", client);
						}
					default:
						{
							SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
							Format(s, sizeof(s), "%T", "Dead Ringer Inactive", client);
						}
					}

					if(!(GetClientButtons(client) & IN_SCORE))
					{
						ShowSyncHudText(client, jumpHUD, "%s", s);
					}
				}
			}
			else if(player_class==TFClass_Soldier)
			{
				if((FF2flags[client] & FF2FLAG_ISBUFFED) && !(GetEntProp(client, Prop_Send, "m_bRageDraining")))
				{
					FF2flags[client]&=~FF2FLAG_ISBUFFED;
				}
			}

			if(RedAlivePlayers==1 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.3);
				if(player_class==TFClass_Engineer && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(classname, "tf_weapon_sentry_revenge", false))
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
			if(TF2_IsPlayerInCondition(client, TFCond_CritCola) && (player_class==TFClass_Scout || player_class==TFClass_Heavy))
			{
				TF2_AddCondition(client, cond, 0.3);
				continue;
			}

			int healer=-1;
			for(int healtarget=1; healtarget<=MaxClients; healtarget++)
			{
				if(IsValidClient(healtarget) && IsPlayerAlive(healtarget) && GetHealingTarget(healtarget, true)==client)
				{
					healer=healtarget;
					break;
				}
			}

			bool addthecrit=false;
			if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) && StrContains(classname, "tf_weapon_knife", false)==-1)  //Every melee except knives
			{
				addthecrit=true;
				if(index==416)  //Market Gardener
				{
					addthecrit=FF2flags[client] & FF2FLAG_ROCKET_JUMPING ? true : false;
				}
			}
			else if((!StrContains(classname, "tf_weapon_smg") && index!=751) ||  //Cleaner's Carbine
					!StrContains(classname, "tf_weapon_compound_bow") ||
					!StrContains(classname, "tf_weapon_crossbow") ||
					!StrContains(classname, "tf_weapon_pistol") ||
					!StrContains(classname, "tf_weapon_handgun_scout_secondary"))
			{
				addthecrit=true;
				if(player_class==TFClass_Scout && cond==TFCond_HalloweenCritCandy)
				{
					cond=TFCond_Buffed;
				}
			}

			if(index==16 && IsValidEntity(FindPlayerBack(client, 642)))  //SMG, Cozy Camper
			{
				addthecrit=false;
			}

			switch(player_class)
			{
			case TFClass_Medic:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
						char mediclassname[64];
						if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
						{
							SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
							int charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
							FF2_ShowHudText(client, -1, "%T: %i", "uber-charge", client, charge);
							if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
							{
								FakeClientCommand(client, "voicemenu 1 7");  //"I am fully charged!"
								FF2flags[client]|= FF2FLAG_UBERREADY;
							}
						}
					}
					else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
					{
						int healtarget=GetHealingTarget(client, true);
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
						int sentry=FindSentry(client);
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

stock int FindSentry(int client)
{
	int entity=-1;
	while((entity=FindEntityByClassname2(entity, "obj_sentrygun"))!=-1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client)
		{
			return entity;
		}
	}
	return -1;
}

public Action BossTimer(Handle timer)
{
	if(!Enabled || CheckRoundState()==2)
	{
		return Plugin_Stop;
	}

	bool validBoss=false;
	for(int boss; boss<=MaxClients; boss++)
	{
		int client=Boss[boss];
		if(!IsValidClient(client) || !IsPlayerAlive(client) || !(FF2flags[client] & FF2FLAG_USEBOSSTIMER))
		{
			continue;
		}
		validBoss=true;

		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", BossSpeed[Special[boss]]+0.7*(100-BossHealth[boss]*100/BossLivesMax[boss]/BossHealthMax[boss]));

		if(BossHealth[boss]<=0 && IsPlayerAlive(client))  //Wat.  TODO:  Investigate
		{
			BossHealth[boss]=1;
		}

		if(BossLivesMax[boss]>1)
		{
			SetHudTextParams(-1.0, 0.77, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, livesHUD, "%t", "Boss Lives Left", BossLives[boss], BossLivesMax[boss]);
		}

		if(BossRageDamage[boss]<2)	// When RAGE is infinite
		{
			BossCharge[boss][0]=100.0;
		}

		if(BossRageDamage[boss]>99998)	// When RAGE is disabled
		{
			BossCharge[boss][0]=0.0;	// We don't want things like Sydney Sleeper acting up
		}
		else if(RoundFloat(BossCharge[boss][0])==100.0)
		{
			if(IsFakeClient(client) && !(FF2flags[client] & FF2FLAG_BOTRAGE))
			{
				CreateTimer(1.0, Timer_BotRage, boss, TIMER_FLAG_NO_MAPCHANGE);
				FF2flags[client]|=FF2FLAG_BOTRAGE;
			}
			else
			{
				SetHudTextParams(-1.0, 0.83, 0.15, 255, 64, 64, 255);
				FF2_ShowSyncHudText(client, rageHUD, "%t", "do_rage");

				char sound[PLATFORM_MAX_PATH];
				if(RandomSound("sound_full_rage", sound, sizeof(sound), boss) && emitRageSound[boss])
				{
					float position[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

					FF2flags[client]|=FF2FLAG_TALKING;
					EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
					EmitSoundToAll(sound, client, _, _, _, _, _, client, position);

					for(int target=1; target<=MaxClients; target++)
					{
						if(IsClientInGame(target) && target!=client)
						{
							EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
							EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
						}
					}
					FF2flags[client]&=~FF2FLAG_TALKING;
					emitRageSound[boss]=false;
				}
			}
		}
		else	// RAGE is not infinite, disabled, full
		{
			SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, rageHUD, "%t", "rage_meter", RoundFloat(BossCharge[boss][0]));
		}
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);

		SetClientGlow(client, -0.2);
		
		for(int i=1; i<4; i++)
		{
			ActivateAbilitySlot(boss, i, true);
		}

		if(RedAlivePlayers==1)
		{
			char message[512];  //Do not decl this
			char name[64];
			for(int target; target<=MaxClients; target++)  //TODO: Why is this for loop needed when we're already in a boss for loop
			{
				if(IsBoss(target))
				{
					int boss2=GetBossIndex(target);
					KvRewind(BossKV[Special[boss2]]);
					KvGetString(BossKV[Special[boss2]], "name", name, sizeof(name), "=Failed name=");
					//Format(bossLives, sizeof(bossLives), ((BossLives[boss2]>1) ? ("x%i", BossLives[boss2]) : ("")));
					char bossLives[10];
					if(BossLives[boss2]>1)
					{
						Format(bossLives, sizeof(bossLives), "x%i", BossLives[boss2]);
					}
					else
					{
						Format(bossLives, sizeof(bossLives), "");
					}
					Format(message, sizeof(message), "%s\n%t", message, "ff2_hp", name, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives);
				}
			}

			for(int target; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
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

		for(int client2; client2<=MaxClients; client2++)
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

public Action Timer_BotRage(Handle timer, any bot)
{
	if(IsValidClient(Boss[bot], false))
	{
		FakeClientCommandEx(Boss[bot], "voicemenu 0 0");
	}
}

stock int OnlyScoutsLeft()
{
	int scouts;
	for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)!=BossTeam)
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

stock int GetIndexOfWeaponSlot(int client, int slot)
{
	int weapon=GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(Enabled)
	{
		if(IsBoss(client) && (condition==TFCond_Jarated || condition==TFCond_MarkedForDeath || (condition==TFCond_Dazed && TF2_IsPlayerInCondition(client, view_as<TFCond>(42)))))
		{
			TF2_RemoveCondition(client, condition);
		}
		else if(!IsBoss(client) && condition==TFCond_BlastJumping)
		{
			FF2flags[client]|=FF2FLAG_ROCKET_JUMPING;
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(Enabled)
	{
		if(TF2_GetPlayerClass(client)==TFClass_Scout && condition==TFCond_CritHype)
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
		}
		else if(!IsBoss(client) && condition==TFCond_BlastJumping)
		{
			FF2flags[client]&=~FF2FLAG_ROCKET_JUMPING;
		}
	}
}

public Action OnCallForMedic(int client, const char[] command, int args)
{
	if(!IsPlayerAlive(client) || CheckRoundState()!=1 || !IsBoss(client) || args!=2)
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(client);
	if(boss==-1 || !Boss[boss] || !IsValidEntity(Boss[boss]))
	{
		return Plugin_Continue;
	}

	char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
	{
		return Plugin_Continue;
	}

	if(RoundFloat(BossCharge[boss][0])==100 && BossRageDamage[boss]<99999)
	{
		ActivateAbilitySlot(boss, 0);

		float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

		char sound[PLATFORM_MAX_PATH];
		if(RandomSoundAbility("sound_ability", sound, sizeof(sound), boss))
		{
			FF2flags[Boss[boss]]|=FF2FLAG_TALKING;
			EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
			EmitSoundToAll(sound, client, _, _, _, _, _, client, position);

			for(int target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && target!=Boss[boss])
				{
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
				}
			}
			FF2flags[Boss[boss]]&=~FF2FLAG_TALKING;
		}
		emitRageSound[boss]=true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void ActivateAbilitySlot(int boss, int slot, bool buttonmodeactive=false)
{
	char ability[12], lives[MAXRANDOMS][3];
	for(int i=1; i<=MAXRANDOMS; i++)
	{
		Format(ability, sizeof(ability), "ability%i", i);
		KvRewind(BossKV[Special[boss]]);
		if(KvJumpToKey(BossKV[Special[boss]], ability))
		{
			
			int ability_slot=KvGetNum(BossKV[Special[boss]], "slot", -2);
			if(ability_slot==-2)
			{
				ability_slot=KvGetNum(BossKV[Special[boss]], "arg0", -2);
				if(ability_slot==-2)
				{
					ability_slot=0;
				}
			}
			if(ability_slot!=slot)
			{
				continue;
			}
			int buttonmode=(buttonmodeactive) ? (KvGetNum(BossKV[Special[boss]], "buttonmode", 0)) : 0;

			KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability));
			if(!ability[0])
			{
				char abilityName[64], pluginName[64];
				KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
				KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
				if(!UseAbility(abilityName, pluginName, boss, slot, buttonmode))
				{
					return;
				}
			}
			else
			{
				int count=ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
				for(int j; j<count; j++)
				{
					if(StringToInt(lives[j])==BossLives[boss])
					{
						char abilityName[64], pluginName[64];
						KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
						KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
						if(!UseAbility(abilityName, pluginName, boss, slot, buttonmode))
						{
							return;
						}
						break;
					}
				}
			}
		}
	}
}

public Action OnSuicide(int client, const char[] command, int args)
{
	bool canBossSuicide=GetConVarBool(cvarBossSuicide);
	if(IsBoss(client) && (canBossSuicide ? !CheckRoundState() : true) && CheckRoundState()!=2)
	{
		CPrintToChat(client, "{olive}[FF2]{default} %t", canBossSuicide ? "Boss Suicide Pre-round" : "Boss Suicide Denied");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnChangeClass(int client, const char[] command, int args)
{
	if(IsBoss(client) && IsPlayerAlive(client))
	{
		//Don't allow the boss to switch classes but instead set their *desired* class (for the next round)
		char player_class[16];
		GetCmdArg(1, player_class, sizeof(player_class));
		if(TF2_GetClass(player_class)!=TFClass_Unknown)  //Ignore cases where the client chooses an invalid class through the console
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TF2_GetClass(player_class));
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnJoinTeam(int client, const char[] command, int args)
{
	// Only block the commands when FF2 is actively running
	if(!Enabled || RoundCount<arenaRounds || CheckRoundState()==-1)
	{
		return Plugin_Continue;
	}

	// autoteam doesn't come with arguments
	if(StrEqual(command, "autoteam", false))
	{
		int team=view_as<int>(TFTeam_Unassigned), oldTeam=GetClientTeam(client);
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
			ChangeClientTeam(client, team);
		}
		return Plugin_Handled;
	}

	if(!args)
	{
		return Plugin_Continue;
	}

	int team=view_as<int>(TFTeam_Unassigned), oldTeam=GetClientTeam(client);
	char teamString[10];
	GetCmdArg(1, teamString, sizeof(teamString));

	if(StrEqual(teamString, "red", false))
	{
		team=view_as<int>(TFTeam_Red);
	}
	else if(StrEqual(teamString, "blue", false))
	{
		team=view_as<int>(TFTeam_Blue);
	}
	else if(StrEqual(teamString, "auto", false))
	{
		team=OtherTeam;
	}
	else if(StrEqual(teamString, "spectate", false) && !IsBoss(client) && GetConVarBool(FindConVar("mp_allowspectators")))
	{
		team=view_as<int>(TFTeam_Spectator);
	}

	if(team==BossTeam && !IsBoss(client))
	{
		team=OtherTeam;
	}
	else if(team==OtherTeam && IsBoss(client))
	{
		team=BossTeam;
	}

	if(team>view_as<int>(TFTeam_Unassigned) && team!=oldTeam)
	{
		ChangeClientTeam(client, team);
	}

	if(CheckRoundState()!=1 && !IsBoss(client) || !IsPlayerAlive(client))  //No point in showing the VGUI if they can't change teams
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

public Action OnPlayerDeath(Handle event, const char[] eventName, bool dontBroadcast)
{
	if(!Enabled || CheckRoundState()!=1)
	{
		return Plugin_Continue;
	}

	int client=GetClientOfUserId(GetEventInt(event, "userid")), attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	char sound[PLATFORM_MAX_PATH];
	CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	DoOverlay(client, "");
	if(!IsBoss(client))
	{
		if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			CreateTimer(1.0, Timer_Damage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}

		if(IsBoss(attacker))
		{
			int boss=GetBossIndex(attacker);
			if(firstBlood)  //TF_DEATHFLAG_FIRSTBLOOD is broken
			{
				if(RandomSound("sound_first_blood", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
				}
				firstBlood=false;
			}

			if(RedAlivePlayers!=1 && KSpreeCount[boss]!=3)  //Don't conflict with end-of-round sounds or killing spree
			{
				int ClassKill=GetRandomInt(0, 2);
				if((ClassKill==1) && RandomSound("sound_hit", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
				}
				else if(ClassKill==2)
				{
					char classnames[][]={"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
					char player_class[32];
					Format(player_class, sizeof(player_class), "sound_kill_%s", classnames[TF2_GetPlayerClass(client)]);
					if(RandomSound(player_class, sound, sizeof(sound), boss))
					{
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
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
				if(RandomSound("sound_kspree", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
				}
				KSpreeCount[boss]=0;
			}
			else
			{
				KSpreeTimer[boss]=GetGameTime()+5.0;
			}
			
			ActivateAbilitySlot(boss, 4);
		}
	}
	else
	{
		int boss=GetBossIndex(client);
		if(boss==-1 || (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			return Plugin_Continue;
		}

		if(RandomSound("sound_death", sound, sizeof(sound), boss))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
		}

		ActivateAbilitySlot(boss, 5);

		BossHealth[boss]=0;
		UpdateHealthBar();

		Stabbed[boss]=0.0;
		Marketed[boss]=0.0;
	}

	if(TF2_GetPlayerClass(client)==TFClass_Engineer && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		char name[PLATFORM_MAX_PATH];
		FakeClientCommand(client, "destroy 2");
		for(int entity=MaxClients+1; entity<MAXENTITIES; entity++)
		{
			if(IsValidEntity(entity))
			{
				GetEntityClassname(entity, name, sizeof(name));
				if(!StrContains(name, "obj_sentrygun") && (GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client))
				{
					SetVariantInt(GetEntPropEnt(entity, Prop_Send, "m_iMaxHealth")+1);
					AcceptEntityInput(entity, "RemoveHealth");

					Handle eventRemoveObject=CreateEvent("object_removed", true);
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

public Action Timer_Damage(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client, false))
	{
		CPrintToChat(client, "{olive}[FF2] %t. %t{default}", "damage", Damage[client], "scores", RoundFloat(Damage[client]/600.0));
	}
	return Plugin_Continue;
}

public Action OnObjectDeflected(Handle event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || GetEventInt(event, "weaponid"))  //0 means that the client was airblasted, which is what we want
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(GetClientOfUserId(GetEventInt(event, "ownerid")));
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

public Action OnJarate(UserMsg msg_id, Handle bf, const players[], int playersNum, bool reliable, bool init)
{
	int client=BfReadByte(bf);
	int victim=BfReadByte(bf);
	int boss=GetBossIndex(victim);
	if(boss!=-1)
	{
		int jarate=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(jarate!=-1)
		{
			int index=GetEntProp(jarate, Prop_Send, "m_iItemDefinitionIndex");
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

public Action OnDeployBackup(Handle event, const char[] name, bool dontBroadcast)
{
	if(Enabled && GetEventInt(event, "buff_type")==2)
	{
		FF2flags[GetClientOfUserId(GetEventInt(event, "buff_owner"))]|=FF2FLAG_ISBUFFED;
	}
	return Plugin_Continue;
}

public Action Timer_CheckAlivePlayers(Handle timer)
{
	if(CheckRoundState()==2)
	{
		return Plugin_Continue;
	}

	RedAlivePlayers=0;
	BlueAlivePlayers=0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(GetClientTeam(client)==OtherTeam)
			{
				RedAlivePlayers++;
			}
			else if(GetClientTeam(client)==BossTeam)
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
		char sound[PLATFORM_MAX_PATH];
		if(RandomSound("sound_lastman", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
		}
	}
	else if(!PointType && RedAlivePlayers<=AliveToEnable && !executed)
	{
		PrintHintTextToAll("%t", "point_enable", AliveToEnable);
		if(RedAlivePlayers==AliveToEnable)
		{
			char sound[64];
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

public Action Timer_DrawGame(Handle timer)
{
	if(BossHealth[0]<countdownHealth || CheckRoundState()!=1 || RedAlivePlayers>countdownPlayers)
	{
		executed2=false;
		return Plugin_Stop;
	}

	int time=timeleft;
	timeleft--;
	char timeDisplay[6];
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
	for(int client; client<=MaxClients; client++)
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
			char sound[PLATFORM_MAX_PATH];
			Format(sound, PLATFORM_MAX_PATH, "vo/announcer_ends_%isec.mp3", time);
			EmitSoundToAll(sound);
		}
	case 0:
		{
			if(!GetConVarBool(cvarCountdownResult))
			{
				for(int client=1; client<=MaxClients; client++)  //Thx MasterOfTheXP
				{
					if(IsClientInGame(client) && IsPlayerAlive(client))
					{
						ForcePlayerSuicide(client);
					}
				}
			}
			else
			{
				ForceTeamWin(0);  //Stalemate
			}
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || CheckRoundState()!=1)
	{
		return Plugin_Continue;
	}

	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	int boss=GetBossIndex(client);
	int damage=GetEventInt(event, "damageamount");
	int custom=GetEventInt(event, "custom");

	if(client==attacker && GetBossIndex(attacker)!=-1 && SelfKnockback[GetBossIndex(attacker)])
	{
		return Plugin_Continue;
	}

	if(boss==-1 || !Boss[boss] || !IsValidEntity(Boss[boss]) || client==attacker)
	{
		return Plugin_Continue;
	}

	if(custom==TF_CUSTOM_TELEFRAG)
	{
		damage=IsPlayerAlive(attacker) ? 9001 : 1;
	}
	else if(custom==TF_CUSTOM_BOOTS_STOMP)
	{
		damage*=5;
	}

	if(GetEventBool(event, "minicrit") && GetEventBool(event, "allseecrit"))
	{
		SetEventBool(event, "allseecrit", false);
	}

	if(custom==TF_CUSTOM_TELEFRAG || custom==TF_CUSTOM_BOOTS_STOMP)
	{
		SetEventInt(event, "damageamount", damage);
	}

	for(int lives=1; lives<BossLives[boss]; lives++)
	{
		if(BossHealth[boss]-damage<=BossHealthMax[boss]*lives)
		{
			SetEntityHealth(client, (BossHealth[boss]-damage)-BossHealthMax[boss]*(lives-1)); //Set the health early to avoid the boss dying from fire, etc.

			Action action=Plugin_Continue;  //Used for the forward
			int bossLives=BossLives[boss];
			Call_StartForward(OnLoseLife);
			Call_PushCell(boss);
			Call_PushCellRef(bossLives);
			Call_PushCell(BossLivesMax[boss]);
			Call_Finish(action);
			if(action==Plugin_Stop || action==Plugin_Handled)
			{
				return action;
			}
			else if(action==Plugin_Changed)
			{
				if(bossLives>BossLivesMax[boss])
				{
					BossLivesMax[boss]=bossLives;
				}
				BossLives[boss]=bossLives;
			}

			char ability[PLATFORM_MAX_PATH];
			ActivateAbilitySlot(boss, -1);
			BossLives[boss]=lives;

			char bossName[64];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "=Failed name=");

			strcopy(ability, sizeof(ability), BossLives[boss]==1 ? "ff2_life_left" : "ff2_lives_left");
			for(int target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
				{
					PrintCenterText(target, "%t", ability, bossName, BossLives[boss]);
				}
			}

			if(BossLives[boss]==1 && RandomSound("sound_last_life", ability, sizeof(ability), boss))
			{
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, ability, _, _, _, _, _, _, _, _, _, false);
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, ability, _, _, _, _, _, _, _, _, _, false);
			}
			else if(RandomSound("sound_nextlife", ability, sizeof(ability), boss))
			{
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, ability, _, _, _, _, _, _, _, _, _, false);
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, ability, _, _, _, _, _, _, _, _, _, false);
			}

			UpdateHealthBar();
			break;
		}
	}

	BossHealth[boss]-=damage;
	BossCharge[boss][0]+=damage*100.0/BossRageDamage[boss];
	Damage[attacker]+=damage;

	int healers[MAXPLAYERS];
	int healerCount;
	for(int target; target<=MaxClients; target++)
	{
		if(IsValidClient(target) && IsPlayerAlive(target) && (GetHealingTarget(target, true)==attacker))
		{
			healers[healerCount]=target;
			healerCount++;
		}
	}

	for(int target; target<healerCount; target++)
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

	if(IsValidClient(attacker))
	{
		int weapon=GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
		if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==1104)  //Air Strike-moved from OTD
		{
			static int airStrikeDamage;
			airStrikeDamage+=damage;
			if(airStrikeDamage>=200)
			{
				SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
				airStrikeDamage-=200;
			}
		}
	}

	if(BossCharge[boss][0]>100.0)
	{
		BossCharge[boss][0]=100.0;
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!Enabled || !IsValidEntity(attacker))
	{
		return Plugin_Continue;
	}

	if((attacker<=0 || client==attacker) && IsBoss(client) && !SelfKnockback[GetBossIndex(client)])
	{
		return Plugin_Handled;
	}

	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
	{
		return Plugin_Continue;
	}

	if(!CheckRoundState() && IsBoss(client))
	{
		damage*=0.0;
		return Plugin_Changed;
	}

	float position[3];
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
				TF2_AddCondition(client, TFCond_Bonked, 0.1);
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
			{
				damage*=0.25;
				return Plugin_Changed;
			}

			if(damage)
			{
				if(RemoveShield(client, attacker, position))
				{
					return Plugin_Handled;
				}
			}

			if(TF2_GetPlayerClass(client)==TFClass_Soldier && IsValidEntity((weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)))
					&& GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==226 && !(FF2flags[client] & FF2FLAG_ISBUFFED))  //Battalion's Backup
			{
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
			}

			if(damage<=160.0 && DmgTriple[GetBossIndex(attacker)])
			{
				damage*=3;
				return Plugin_Changed;
			}
		}
	}
	else
	{
		int boss=GetBossIndex(client);
		if(boss!=-1)
		{
			if(attacker<=MaxClients)
			{
				bool bIsTelefrag, bIsBackstab;
				if(damagecustom==TF_CUSTOM_BACKSTAB)
				{
					bIsBackstab=true;
				}
				else if(damagecustom==TF_CUSTOM_TELEFRAG)
				{
					bIsTelefrag=true;
				}

				int index;
				char classname[64];
				if(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients)
				{
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(!HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))  //Dang spell Monoculuses
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

				//Sniper rifles aren't handled by the switch/case because of the amount of reskins there are
				if(!StrContains(classname, "tf_weapon_sniperrifle"))
				{
					if(CheckRoundState()!=2)
					{
						float charge=(IsValidEntity(weapon) && weapon>MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
						if(index==752)  //Hitman's Heatmaker
						{
							float focus=10+(charge/10);
							if(TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
							{
								focus/=3;
							}
							float rage=GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
							SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage+focus>100) ? 100.0 : rage+focus);
						}
						else if(index!=230 && index!=402 && index!=526 && index!=30665)  //Sydney Sleeper, Bazaar Bargain, Machina, Shooting Star
						{
							float time=(GlowTimer[boss]>10 ? 1.0 : 2.0);
							time+=(GlowTimer[boss]>10 ? (GlowTimer[boss]>20 ? 1.0 : 2.0) : 4.0)*(charge/100.0);
							SetClientGlow(Boss[boss], time);
							if(GlowTimer[boss]>30.0)
							{
								GlowTimer[boss]=30.0;
							}
						}

						if(!(damagetype & DMG_CRIT))
						{
							if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
							{
								damage*=2.2;
							}
							else
							{
								if(index!=230 || BossCharge[boss][0]>90.0)  //Sydney Sleeper
								{
									damage*=3.0;
								}
								else
								{
									damage*=2.4;
								}
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
							damage=85.0;  //Final damage 255
							return Plugin_Changed;
						}
					}
				case 132, 266, 482, 1082:  //Eyelander, HHHH, Nessie's Nine Iron, Festive Eyelander
					{
						IncrementHeadCount(attacker);
					}
				case 214:  //Powerjack
					{
						int health=GetClientHealth(attacker);
						int newhealth=health+50;
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
						int health=GetClientHealth(attacker);
						int newhealth=health+50;
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
						SpawnSmallHealthPackAt(client, GetClientTeam(attacker));
					}
				case 327:  //Claidheamh Mòr
					{
						int health=GetClientHealth(attacker);
						int newhealth=health+25;
						if(newhealth<=GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						{
							SetEntityHealth(attacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}

						float charge=GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter");
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

						int health=GetClientHealth(attacker);
						int max=GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						int newhealth=health+50;
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
						if(FF2flags[attacker] & FF2FLAG_ROCKET_JUMPING)
						{
							damage=(Pow(float(BossHealthMax[boss]), 0.74074)+512.0-(Marketed[client]/128.0*float(BossHealthMax[boss])))/3.0;
							damagetype|=DMG_CRIT;

							if(Marketed[client]<5)
							{
								Marketed[client]++;
							}

							PrintHintText(attacker, "%t", "Market Gardener");  //You just market-gardened the boss!
							PrintHintText(client, "%t", "Market Gardened");  //You just got market-gardened!

							EmitSoundToClient(attacker, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);
							EmitSoundToClient(client, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);

							char sound[PLATFORM_MAX_PATH];
							if(RandomSound("sound_marketed", sound, sizeof(sound)))
							{
								EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
								EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
							}

							ActivateAbilitySlot(boss, 7);
							return Plugin_Changed;
						}
					}
				case 525, 595:  //Diamondback, Manmelter
					{
						if(GetEntProp(attacker, Prop_Send, "m_iRevengeCrits"))  //If a revenge crit was used, give a damage bonus
						{
							damage=85.0;  //255 final damage
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
						int healers[MAXPLAYERS];
						int healerCount;
						for(int healer; healer<=MaxClients; healer++)
						{
							if(IsValidClient(healer) && IsPlayerAlive(healer) && (GetHealingTarget(healer, true)==attacker))
							{
								healers[healerCount]=healer;
								healerCount++;
							}
						}

						for(int healer; healer<healerCount; healer++)
						{
							if(IsValidClient(healers[healer]) && IsPlayerAlive(healers[healer]))
							{
								int medigun=GetPlayerWeaponSlot(healers[healer], TFWeaponSlot_Secondary);
								if(IsValidEntity(medigun))
								{
									char medigunClassname[64];
									GetEntityClassname(medigun, medigunClassname, sizeof(medigunClassname));
									if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
									{
										float uber=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+(0.1/healerCount);
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
				}

				if(bIsBackstab)
				{
					damage=BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.12-Stabbed[boss]/90)/3;
					damagetype|=DMG_CRIT;
					damagecustom=0;

					EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
					EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
					EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);

					int viewmodel=GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
					if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
					{
						int melee=GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
						int animation=41;
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

					if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(attacker, "%t", "Backstab");
					}

					if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(client, "%t", "Backstabbed");
					}

					if(index==225 || index==574)  //Your Eternal Reward, Wanga Prick
					{
						CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
					}
					else if(index==356)  //Conniver's Kunai
					{
						int health=GetClientHealth(attacker)+200;
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

					char sound[PLATFORM_MAX_PATH];
					if(RandomSound("sound_stabbed", sound, sizeof(sound), boss))
					{
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[boss], _, _, false);
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[boss], _, _, false);
					}
					
					ActivateAbilitySlot(boss, 6);

					if(Stabbed[boss]<3)
					{
						Stabbed[boss]++;
					}
					return Plugin_Changed;
				}
				else if(bIsTelefrag)
				{
					damagecustom=0;
					if(!IsPlayerAlive(attacker))
					{
						damage=1.0;
						return Plugin_Changed;
					}
					damage=(BossHealth[boss]>9001 ? 9001.0 : float(GetEntProp(Boss[boss], Prop_Send, "m_iHealth"))+90.0);

					int teleowner=FindTeleOwner(attacker);
					if(IsValidClient(teleowner) && teleowner!=attacker)
					{
						Damage[teleowner]+=9001*3/5;
						if(!(FF2flags[teleowner] & FF2FLAG_HUDDISABLED))
						{
							PrintHintText(teleowner, "%t", "Telefrag Assist");
						}
					}

					if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(attacker, "%t", "Telefragger");
					}

					if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(client, "%t", "Telefragged");
					}

					char sound[PLATFORM_MAX_PATH];
					if(RandomSound("sound_telefraged", sound, sizeof(sound)))
					{
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
					}
					return Plugin_Changed;
				}
			}
			else
			{
				char classname[64];
				if(GetEntityClassname(attacker, classname, sizeof(classname)) && !strcmp(classname, "trigger_hurt", false))
				{
					Action action=Plugin_Continue;
					Call_StartForward(OnTriggerHurt);
					Call_PushCell(boss);
					Call_PushCell(attacker);
					float damage2=damage;
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

						if(!strcmp(currentmap, "arena_arakawa_b3", false) && damage>1000.0)
						{
							damage=490.0;
						}
						BossHealth[boss]-=RoundFloat(damage);
						BossCharge[boss][0]+=damage*100.0/BossRageDamage[boss];
						if(BossHealth[boss]<=0)  //Wat
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
			int index=((IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") && attacker<=MaxClients) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
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

			if(IsValidClient(client, false) && TF2_GetPlayerClass(client)==TFClass_Soldier)  //TODO: LOOK AT THIS
			{
				if(damagetype & DMG_FALL)
				{
					int secondary=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(secondary<=0 || !IsValidEntity(secondary))
					{
						damage/=10.0;
						return Plugin_Changed;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action TF2_OnPlayerTeleport(int client, int teleporter, bool &result)
{
	if(IsBoss(client))
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

public Action OnStomp(int attacker, int victim, float &damageMultiplier, float &damageBonus, float &JumpPower)
{
	if(!Enabled || !IsValidClient(attacker) || !IsValidClient(victim) || attacker==victim)
	{
		return Plugin_Continue;
	}

	if(IsBoss(attacker))
	{
		float position[3];
		GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);
		if(RemoveShield(victim, attacker, position))
		{
			return Plugin_Handled;
		}
		damageMultiplier=900.0;
		JumpPower=0.0;
		return Plugin_Changed;
	}
	else if(IsBoss(victim))
	{
		damageMultiplier=GoombaDamage;
		JumpPower=reboundPower;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public int OnStompPost(int attacker, int victim, float damageMultiplier, float damageBonus, float jumpPower)
{
	if(IsBoss(victim))
	{
		PrintHintText(victim, "%t", "Player Goomba Stomped");
		PrintHintText(attacker, "%t", "Player Goomba Stomper");
		UpdateHealthBar();
	}
	else if(IsBoss(attacker))
	{
		PrintHintText(victim, "%t", "Boss Goomba Stomped");
		PrintHintText(attacker, "%t", "Boss Goomba Stomper");
	}
}

public Action RTD_CanRollDice(int client)
{
	if(IsBoss(client) && !canBossRTD)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action RTD2_CanRollDice(int client)
{
	if(IsBoss(client) && !canBossRTD)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnGetMaxHealth(int client, int &maxHealth)
{
	if(IsBoss(client))
	{
		int boss=GetBossIndex(client);
		SetEntityHealth(client, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1));
		maxHealth=BossHealthMax[boss];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock int GetClientCloakIndex(int client)
{
	if(!IsValidClient(client, false))
	{
		return -1;
	}

	int weapon=GetPlayerWeaponSlot(client, 4);
	if(!IsValidEntity(weapon))
	{
		return -1;
	}

	char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if(strncmp(classname, "tf_wea", 6, false))
	{
		return -1;
	}
	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

stock void SpawnSmallHealthPackAt(int client, int team=0)
{
	if(!IsValidClient(client, false) || !IsPlayerAlive(client))
	{
		return;
	}

	int healthpack=CreateEntityByName("item_healthkit_small");
	float position[3];
	GetClientAbsOrigin(client, position);
	position[2]+=20.0;
	if(IsValidEntity(healthpack))
	{
		DispatchKeyValue(healthpack, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(healthpack);
		SetEntProp(healthpack, Prop_Send, "m_iTeamNum", team, 4);
		SetEntityMoveType(healthpack, MOVETYPE_VPHYSICS);
		float velocity[3];
		velocity[0]=float(GetRandomInt(-10, 10)), velocity[1]=float(GetRandomInt(-10, 10)), velocity[2]=50.0;  //I did this because setting it on the creation of the vel variable was creating a compiler error for me.
		TeleportEntity(healthpack, position, NULL_VECTOR, velocity);
	}
}

stock void IncrementHeadCount(int client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
	{
		TF2_AddCondition(client, TFCond_DemoBuff, -1.0);
	}

	int decapitations=GetEntProp(client, Prop_Send, "m_iDecapitations");
	int health=GetClientHealth(client);
	SetEntProp(client, Prop_Send, "m_iDecapitations", decapitations+1);
	SetEntityHealth(client, health+15);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}

stock int FindTeleOwner(int client)
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return -1;
	}

	int teleporter=GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	char classname[32];
	if(IsValidEntity(teleporter) && GetEntityClassname(teleporter, classname, sizeof(classname)) && !strcmp(classname, "obj_teleporter", false))
	{
		int owner=GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
		if(IsValidClient(owner, false))
		{
			return owner;
		}
	}
	return -1;
}

stock int TF2_IsPlayerCritBuffed(int client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, view_as<TFCond>(34)) || TF2_IsPlayerInCondition(client, view_as<TFCond>(35)) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph));
}

public Action Timer_DisguiseBackstab(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client, false))
	{
		RandomlyDisguise(client);
	}
	return Plugin_Continue;
}

stock TFClassType GetClassForBoss(Handle keyvalue)
{
	char buffer[16];
	TFClassType result=TFClass_Unknown;
	KvGetString(keyvalue, "class", buffer, sizeof(buffer));
	if(buffer[0]!='\0')
	{
		result=TF2_GetClass(buffer);
		if(result)
		{
			return result;
		}
	}
	result=view_as<TFClassType>(StringToInt(buffer));
	
	//Some checks because there are so many kinds of people here...
	if(result<=TFClass_Unknown || result>TFClass_Engineer)
	{
		result=TFClass_Scout; 
	}
	return result;
}

stock void AssignTeam(int client, int team)
{
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))  //Living spectator check: 0 means that no class is selected
	{
		FF2Dbg("%N does not have a desired class!", client);
		if(IsBoss(client))
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", GetClassForBoss(BossKV[Special[Boss[client]]]));  //So we assign one to prevent living spectators
		}
		else
		{
			FF2Dbg("%N was not a boss and did not have a desired class!  Please report this to https://github.com/50DKP/FF2-Official");
		}
	}

	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);

	if(GetEntProp(client, Prop_Send, "m_iObserverMode") && IsPlayerAlive(client))  //Welp
	{
		FF2Dbg("%N is a living spectator!  Please report this to https://github.com/50DKP/FF2-Official", client);
		if(IsBoss(client))
		{
			TF2_SetPlayerClass(client, view_as<TFClassType>(GetClassForBoss(BossKV[Special[Boss[client]]])));
		}
		else
		{
			FF2Dbg("Additional information: %N was not a boss");
			TF2_SetPlayerClass(client, TFClass_Scout);
		}
		TF2_RespawnPlayer(client);
	}
}

stock void RandomlyDisguise(int client)	//Original code was mecha's, but the original code is broken and this uses a better method now.
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int disguiseTarget=-1;
		int team=GetClientTeam(client);

		Handle disguiseArray=CreateArray();
		for(int clientcheck; clientcheck<=MaxClients; clientcheck++)
		{
			if(IsValidClient(clientcheck) && GetClientTeam(clientcheck)==team && clientcheck!=client)
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

		int player_class=GetRandomInt(0, 4);
		TFClassType classArray[]={TFClass_Scout, TFClass_Pyro, TFClass_Medic, TFClass_Engineer, TFClass_Sniper};
		CloseHandle(disguiseArray);

		if(TF2_GetPlayerClass(client)==TFClass_Spy)
		{
			TF2_DisguisePlayer(client, view_as<TFTeam>(team), classArray[player_class], disguiseTarget);
		}
		else
		{
			TF2_AddCondition(client, TFCond_Disguised, -1.0);
			SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
			SetEntProp(client, Prop_Send, "m_nDisguiseClass", classArray[player_class]);
			SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", disguiseTarget);
			SetEntProp(client, Prop_Send, "m_iDisguiseHealth", 200);
		}
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if(IsBoss(client) && CheckRoundState()==1 && !TF2_IsPlayerCritBuffed(client) && !randomCrits[GetBossIndex(client)])
	{
		result=false;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock int GetClientWithMostQueuePoints(bool[] omit)
{
	int winner;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && GetClientQueuePoints(client)>=GetClientQueuePoints(winner) && !omit[client])
		{
			if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
			{
				winner=client;
			}
		}
	}
	return winner;
}

stock int GetClientWithCompanionToggle(bool[] omit)
{
	int companion;
	char cookies[24];
	char cookieValues[8][5];
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && GetClientQueuePoints(client)>=GetClientQueuePoints(companion) && !omit[client])
		{
			if(!IsFakeClient(client) && AreClientCookiesCached(client) && GetConVarBool(cvarDuoToggle)) // Skip clients who have disabled being able to be selected as a companion
			{
				GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
				ExplodeString(cookies, " ", cookieValues, 8, 5);
				if(StringToInt(cookieValues[4])==0)
				{
					continue;
				}
			}
			
			if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
			{
				companion=client;
			}
		}
	}
	
	if(!companion)
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && GetClientQueuePoints(client)>=GetClientQueuePoints(companion) && !omit[client])
			{
				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator)) // Ignore the companion toggle pref if we can't find available clients
				{
					companion=client;
				}
			}		
		}
	}
	return companion;
}

stock int LastBossIndex()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(!Boss[client])
		{
			return client-1;
		}
	}
	return 0;
}

stock int GetBossIndex(int client)
{
	if(client>0 && client<=MaxClients)
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Boss[boss]==client)
			{
				return boss;
			}
		}
	}
	return -1;
}

stock void Operate(Handle sumArray, int &bracket, float value, Handle _operator)
{
	float sum=GetArrayCell(sumArray, bracket);
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

stock void OperateString(Handle sumArray, int &bracket, char[] value, int size, Handle _operator)
{
	if(!StrEqual(value, ""))  //Make sure 'value' isn't blank
	{
		Operate(sumArray, bracket, StringToFloat(value), _operator);
		strcopy(value, size, "");
	}
}

stock int ParseFormula(int boss, const char[] key, const char[] defaultFormula, int defaultValue)
{
	char formula[1024], bossName[64];
	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "=Failed name=");
	KvGetString(BossKV[Special[boss]], key, formula, sizeof(formula), defaultFormula);

	int size=1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
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

	Handle sumArray=CreateArray(_, size), _operator=CreateArray(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	SetArrayCell(sumArray, 0, 0.0);  //TODO:  See if these can be placed naturally in the loop
	SetArrayCell(_operator, bracket, Operator_None);

	char character[2], value[16];  //We don't decl value because we directly append characters to it and there's no point in decl'ing character
	for(int i; i<=strlen(formula); i++)
	{
		character[0]=formula[i];  //Find out what the next char in the formula is
		switch(character[0])
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
				StrCat(value, sizeof(value), character);  //Constant?  Just add it to the current value
			}
		case 'n', 'x':  //n and x denote player variables
			{
				Operate(sumArray, bracket, float(playing), _operator);
			}
		case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(character[0])
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
		}
	}

	int result=RoundFloat(GetArrayCell(sumArray, 0));
	CloseHandle(sumArray);
	CloseHandle(_operator);
	if(result<=0)
	{
		LogError("[FF2] %s has an invalid %s formula, using default!", bossName, key);
		return defaultValue;
	}

	//To-do: Make this even more configurable
	if(bMedieval && StrEqual(key, "health_formula", false))
	{
		return RoundFloat(result/3.6);
	}
	return result;
}

stock int GetAbilityArgument(int index, const char[] plugin_name, const char[] ability_name, int arg, int defvalue=0)
{
	char str[10];
	Format(str, sizeof(str), "arg%i", arg);
	return GetArgumentI(index, plugin_name, ability_name, str, defvalue);
}

stock float GetAbilityArgumentFloat(int index, const char[] plugin_name, const char[] ability_name, int arg, float defvalue=0.0)
{
	char str[10];
	Format(str, sizeof(str), "arg%i", arg);
	return GetArgumentF(index, plugin_name, ability_name, str, defvalue);
}

stock void GetAbilityArgumentString(int index, const char[] plugin_name, const char[] ability_name, int arg, char[] buffer, int buflen, const char[] defvalue="")
{
	char str[10];
	Format(str, sizeof(str), "arg%i", arg);
	GetArgumentS(index, plugin_name, ability_name, str, buffer, buflen, defvalue);
}

stock int GetArgumentI(int index, const char[] plugin_name, const char[] ability_name, const char[] arg, int defvalue=0)
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
	{
		return 0;
	}
	KvRewind(BossKV[Special[index]]);
	char s[10];
	for(int i=1; i<=MAXRANDOMS; i++)
	{
		Format(s, sizeof(s), "ability%i", i);
		if(KvJumpToKey(BossKV[Special[index]], s))
		{
			char ability_name2[64];
			KvGetString(BossKV[Special[index]], "name", ability_name2, sizeof(ability_name2));
			if(strcmp(ability_name, ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			char plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name", plugin_name2, sizeof(plugin_name2));
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			return KvGetNum(BossKV[Special[index]], arg, defvalue);
		}
	}
	return 0;
}

stock float GetArgumentF(int index, const char[] plugin_name, const char[] ability_name, const char[] arg, float defvalue=0.0)
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
	{
		return 0.0;
	}
	KvRewind(BossKV[Special[index]]);
	char s[10];
	for(int i=1; i<=MAXRANDOMS; i++)
	{
		Format(s, sizeof(s), "ability%i", i);
		if(KvJumpToKey(BossKV[Special[index]], s))
		{
			char ability_name2[64];
			KvGetString(BossKV[Special[index]], "name", ability_name2, sizeof(ability_name2));
			if(strcmp(ability_name, ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			char plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name", plugin_name2, sizeof(plugin_name2));
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name, plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			float see=KvGetFloat(BossKV[Special[index]], arg, defvalue);
			return see;
		}
	}
	return 0.0;
}

stock void GetArgumentS(int index, const char[] plugin_name, const char[] ability_name, const char[] arg, char[] buffer, int buflen, const char[] defvalue="")
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
	{
		strcopy(buffer, buflen, "");
		return;
	}
	KvRewind(BossKV[Special[index]]);
	char s[10];
	for(int i=1; i<=MAXRANDOMS; i++)
	{
		Format(s, sizeof(s), "ability%i", i);
		if(KvJumpToKey(BossKV[Special[index]], s))
		{
			char ability_name2[64];
			KvGetString(BossKV[Special[index]], "name", ability_name2, sizeof(ability_name2));
			if(strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			char plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name", plugin_name2, sizeof(plugin_name2));
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name, plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			KvGetString(BossKV[Special[index]], arg, buffer, buflen, defvalue);
		}
	}
}

stock bool RandomSound(const char[] sound, char[] file, int length, int boss=0)
{
	if(boss<0 || Special[boss]<0 || !BossKV[Special[boss]])
	{
		return false;
	}

	KvRewind(BossKV[Special[boss]]);
	if(!KvJumpToKey(BossKV[Special[boss]], sound))
	{
		KvRewind(BossKV[Special[boss]]);
		return false;  //Requested sound not implemented for this boss
	}

	char key[4];
	int sounds;
	while(++sounds)  //Just keep looping until there's no keys left
	{
		IntToString(sounds, key, sizeof(key));
		KvGetString(BossKV[Special[boss]], key, file, length);
		if(!file[0])
		{
			sounds--;  //This sound wasn't valid, so don't include it
			break;  //Assume that there's no more sounds
		}
	}

	if(!sounds)
	{
		return false;  //Found sound, but no sounds inside of it
	}

	IntToString(GetRandomInt(1, sounds), key, sizeof(key));
	KvGetString(BossKV[Special[boss]], key, file, length);  //Populate file
	return true;
}

stock bool RandomSoundAbility(const char[] sound, char[] file, int length, int boss=0, int slot=0)
{
	if(boss<0 || Special[boss]<0 || !BossKV[Special[boss]])
	{
		return false;
	}

	KvRewind(BossKV[Special[boss]]);
	if(!KvJumpToKey(BossKV[Special[boss]], sound))
	{
		return false;  //Sound doesn't exist
	}

	char key[10];
	int sounds, matches, match[MAXRANDOMS];
	while(++sounds)
	{
		IntToString(sounds, key, 4);
		KvGetString(BossKV[Special[boss]], key, file, length);
		if(!file[0])
		{
			break;  //Assume that there's no more sounds
		}

		Format(key, sizeof(key), "slot%i", sounds);
		if(KvGetNum(BossKV[Special[boss]], key, 0)==slot)
		{
			match[matches]=sounds;  //Found a match: let's store it in the array
			matches++;
		}
	}

	if(!matches)
	{
		return false;  //Found sound, but no sounds inside of it
	}

	IntToString(match[GetRandomInt(0, matches-1)], key, 4);
	KvGetString(BossKV[Special[boss]], key, file, length);  //Populate file
	return true;
}

stock bool RandomSoundVo(const char[] sound, char[] file, int length, int boss=0, const char[] oldFile)
{
	if(boss<0 || Special[boss]<0 || !BossKV[Special[boss]])
	{
		return false;
	}

	KvRewind(BossKV[Special[boss]]);
	if(!KvJumpToKey(BossKV[Special[boss]], sound))
	{
		return false;  //Sound doesn't exist
	}

	char key[10], replacement[PLATFORM_MAX_PATH];
	int sounds, matches, match[MAXRANDOMS];
	while(++sounds)
	{
		IntToString(sounds, key, 4);
		KvGetString(BossKV[Special[boss]], key, file, length);
		if(!file[0])
		{
			break;  //Assume that there's no more sounds
		}

		Format(key, sizeof(key), "vo%i", sounds);
		KvGetString(BossKV[Special[boss]], key, replacement, sizeof(replacement));
		if(StrEqual(replacement, oldFile, false))
		{
			match[matches] = sounds;  //Found a match: let's store it in the array
			matches++;
		}
	}

	if(!matches)
	{
		return false;  //Found sound, but no sounds inside of it
	}

	IntToString(match[GetRandomInt(0, matches-1)], key, 4);
	KvGetString(BossKV[Special[boss]], key, file, length);  //Populate file
	return true;
}

void ForceTeamWin(int team)
{
	int entity=FindEntityByClassname2(-1, "team_control_point_master");
	if(!IsValidEntity(entity))
	{
		entity=CreateEntityByName("team_control_point_master");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(entity, "SetWinner");
}

public bool PickCharacter(int boss, int companion)
{
	if(boss==companion)
	{
		Special[boss]=Incoming[boss];
		Incoming[boss]=-1;
		if(Special[boss]!=-1)  //We've already picked a boss through Command_SetNextBoss
		{
			Action action;
			Call_StartForward(OnSpecialSelected);
			Call_PushCell(boss);
			int characterIndex=Special[boss];
			Call_PushCellRef(characterIndex);
			char newName[64];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", newName, sizeof(newName));
			Call_PushStringEx(newName, sizeof(newName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(true);  //Preset
			Call_Finish(action);
			if(action==Plugin_Changed)
			{
				if(newName[0])
				{
					char characterName[64];
					int foundExactMatch=-1, foundPartialMatch=-1;
					for(int character; BossKV[character] && character<MAXSPECIALS; character++)
					{
						KvRewind(BossKV[character]);
						KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch=character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false)!=-1)
						{
							foundPartialMatch=character;
						}

						//Do the same thing as above here, but look at the filename instead of the boss name
						KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch=character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false)!=-1)
						{
							foundPartialMatch=character;
						}
					}

					if(foundExactMatch!=-1)
					{
						Special[boss]=foundExactMatch;
					}
					else if(foundPartialMatch!=-1)
					{
						Special[boss]=foundPartialMatch;
					}
					else
					{
						return false;
					}
					PrecacheCharacter(Special[boss]);
					return true;
				}
				Special[boss]=characterIndex;
				PrecacheCharacter(Special[boss]);
				return true;
			}
			PrecacheCharacter(Special[boss]);
			return true;
		}

		for(int tries; tries<100; tries++)
		{
			if(ChancesString[0])
			{
				int characterIndex=chancesIndex;  //Don't touch chancesIndex since it doesn't get reset
				int i=GetRandomInt(0, chances[characterIndex-1]);

				while(characterIndex>=2 && i<chances[characterIndex-1])
				{
					Special[boss]=chances[characterIndex-2]-1;
					characterIndex-=2;
				}
			}
			else
			{
				Special[boss]=GetRandomInt(0, Specials-1);
			}

			KvRewind(BossKV[Special[boss]]);
			if(KvGetNum(BossKV[Special[boss]], "blocked"))
			{
				Special[boss]=-1;
				continue;
			}

			if(playing<4)	// Block companion bosses if less than 4 players are playing
			{
				char companionName[64];
				KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName));
				if(strlen(companionName))
				{
					Special[boss]=-1;
					continue;
				}
			}
			break;
		}
	}
	else
	{
		char bossName[64], companionName[64];
		KvRewind(BossKV[Special[boss]]);
		KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName), "=Failed companion name=");

		int character;
		while(character<Specials)  //Loop through all the bosses to find the companion we're looking for
		{
			KvRewind(BossKV[character]);
			KvGetString(BossKV[character], "name", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				Special[companion]=character;
				break;
			}

			KvGetString(BossKV[character], "filename", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				Special[companion]=character;
				break;
			}
			character++;
		}

		if(character==Specials)  //Companion not found
		{
			return false;
		}
	}

	//All of the following uses `companion` because it will always be the boss index we want
	Action action;
	Call_StartForward(OnSpecialSelected);
	Call_PushCell(companion);
	int characterIndex=Special[companion];
	Call_PushCellRef(characterIndex);
	char newName[64];
	KvRewind(BossKV[Special[companion]]);
	KvGetString(BossKV[Special[companion]], "name", newName, sizeof(newName));
	Call_PushStringEx(newName, sizeof(newName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(false);  //Not preset
	Call_Finish(action);
	if(action==Plugin_Changed)
	{
		if(newName[0])
		{
			char characterName[64];
			int foundExactMatch=-1, foundPartialMatch=-1;
			for(int character; BossKV[character] && character<MAXSPECIALS; character++)
			{
				KvRewind(BossKV[character]);
				KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch=character;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch=character;
				}

				//Do the same thing as above here, but look at the filename instead of the boss name
				KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch=character;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch=character;
				}
			}

			if(foundExactMatch!=-1)
			{
				Special[companion]=foundExactMatch;
			}
			else if(foundPartialMatch!=-1)
			{
				Special[companion]=foundPartialMatch;
			}
			else
			{
				return false;
			}
			PrecacheCharacter(Special[companion]);
			return true;
		}
		Special[companion]=characterIndex;
		PrecacheCharacter(Special[companion]);
		return true;
	}
	PrecacheCharacter(Special[companion]);
	return true;
}

void FindCompanion(int boss, int players, bool[] omit)
{
	static int playersNeeded=3;
	char companionName[64];
	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName));
	if(playersNeeded<players && strlen(companionName))  //Only continue if we have enough players and if the boss has a companion
	{
		int companion=GetClientWithCompanionToggle(omit);
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

public int HintPanelH(Menu menu, MenuAction action, int client, int selection)
{
	if(IsValidClient(client) && (action==MenuAction_Select || (action==MenuAction_Cancel && selection==MenuCancel_Exit)))
	{
		FF2flags[client]|=FF2FLAG_CLASSHELPED;
	}
	else if(action==MenuAction_End)
	{
		delete menu;
	}
	else if(action==MenuAction_Cancel)
	{
		if(selection==MenuCancel_ExitBack)
		{
			FF2Panel(client, 0);
		}
		else if(selection==MenuCancel_Exit)
		{
			return 0;
		}
	}
	return 0;
}

public int QueuePanelH(Handle menu, MenuAction action, int client, int selection)
{
	if(action==MenuAction_Select && selection==10)
	{
		TurnToZeroPanel(client, client);
	}
	return false;
}


public Action QueuePanelCmd(int client, int args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	char text[64];
	int items;
	bool[] added=new bool[MaxClients+1];

	Handle panel=CreatePanel();
	SetGlobalTransTarget(client);
	Format(text, sizeof(text), "%t", "thequeue");  //"Boss Queue"
	SetPanelTitle(panel, text);
	for(int boss; boss<=MaxClients; boss++)  //Add the current bosses to the top of the list
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
		int target=GetClientWithMostQueuePoints(added);  //Get whoever has the highest queue points out of those who haven't been listed yet
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

	Format(text, sizeof(text), "%t (%t)", "your_points", GetClientQueuePoints(client), "to0");  //"Your queue point(s) is {1} (set to 0)"
	DrawPanelItem(panel, text);

	SendPanelToClient(panel, client, QueuePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public Action ResetQueuePointsCmd(int client, int args)
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

	AdminId admin=GetUserAdmin(client);	 //Normal players
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

	char pattern[MAX_TARGET_LENGTH];
	GetCmdArg(1, pattern, sizeof(pattern));
	char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, 1, 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches>1)
	{
		for(int target; target<matches; target++)
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

public int TurnToZeroPanelH(Handle menu, MenuAction action, int client, int position)
{
	if(action==MenuAction_Select && position==1)
	{
		if(shortname[client]==client)
		{
			CPrintToChat(client,"{olive}[FF2]{default} %t", "to0_done");  //Your queue points have been reset to {olive}0{default}
		}
		else
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "to0_done_admin", shortname[client]);  //{olive}{1}{default}'s queue points have been reset to {olive}0{default}
			CPrintToChat(shortname[client], "{olive}[FF2]{default} %t", "to0_done_by_admin", client);  //{olive}{1}{default} reset your queue points to {olive}0{default}
			LogAction(client, shortname[client], "\"%L\" reset \"%L\"'s queue points to 0", client, shortname[client]);
		}
		SetClientQueuePoints(shortname[client], 0);
	}
}

public Action TurnToZeroPanel(int client, int target)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	Handle panel=CreatePanel();
	char text[128];
	SetGlobalTransTarget(client);
	if(client==target)
	{
		Format(text, sizeof(text), "%t", "to0_title");  //Do you really want to set your queue points to 0?
	}
	else
	{
		Format(text, sizeof(text), "%t", "to0_title_admin", target);  //Do you really want to set {1}'s queue points to 0?
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

bool GetClientClassInfoCookie(int client)
{
	if(!IsValidClient(client) || IsFakeClient(client))
	{
		return false;
	}

	if(!AreClientCookiesCached(client))
	{
		return true;
	}

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	return StringToInt(cookieValues[3])==1;
}

int GetClientQueuePoints(int client)
{
	if(!IsValidClient(client) || !AreClientCookiesCached(client))
	{
		return 0;
	}

	if(IsFakeClient(client))
	{
		return botqueuepoints;
	}

	char cookies[24], cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	return StringToInt(cookieValues[0]);
}

void SetClientQueuePoints(int client, int points)
{
	if(IsValidClient(client) && !IsFakeClient(client) && AreClientCookiesCached(client))
	{
		char cookies[24], cookieValues[8][5];
		GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
		ExplodeString(cookies, " ", cookieValues, 8, 5);
		Format(cookies, sizeof(cookies), "%i %s %s %s %s %s %s %s", points, cookieValues[1], cookieValues[2], cookieValues[3], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
		SetClientCookie(client, FF2Cookies, cookies);
	}
}

stock bool IsBoss(int client)
{
	if(IsValidClient(client) && Enabled)
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Boss[boss]==client)
			{
				return true;
			}
		}
	}
	return false;
}

void DoOverlay(int client, const char[] overlay)
{
	int flags=GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	if(overlay[0]=='\0')
	{
		ClientCommand(client, "r_screenoverlay off");
	}
	else
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	}
	SetCommandFlags("r_screenoverlay", flags);
}

public int FF2PanelH(Menu menu, MenuAction action, int client, int selection)
{
	if(action==MenuAction_Select)
	{
		selection++;
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
				NewPanelChangelog(client, true);
			}
		case 4:
			{
				QueuePanelCmd(client, 0);
			}
		case 5:
			{
				MusicTogglePanel(client, true);
			}
		case 6:
			{
				VoiceTogglePanel(client, true);
			}
		case 7:
			{
				HelpPanel3(client, true);
			}
		case 8:
			{
				CompanionTogglePanel(client, true);
			}
		default:
			{
				return 0;
			}
		}
	}
	else if(action==MenuAction_End)
	{
		delete menu;
	}
	else if(action==MenuAction_Cancel)
	{
		if(selection==MenuCancel_ExitBack)
		{
			FF2Panel(client, 0);
		}
		else if(selection==MenuCancel_Exit)
		{
			return 0;
		}
	}
	return 0;
}

public Action FF2Panel(int client, int args)  //._.
{
	if(Enabled2 && IsValidClient(client, false))
	{
		Menu ff2_menu=new Menu(FF2PanelH);
		ff2_menu.Pagination=false;
		ff2_menu.ExitButton=true;
		char text[256];
		SetGlobalTransTarget(client);
		Format(text, sizeof(text), "%t", "menu_1");  //What's up?
		ff2_menu.SetTitle(text);
		Format(text, sizeof(text), "%t", "menu_2");  //Investigate the boss's current health level (/ff2hp)
		ff2_menu.AddItem("", text);
		Format(text, sizeof(text), "%t", "menu_7");  //Changes to my class in FF2 (/ff2classinfo)
		ff2_menu.AddItem("", text);
		Format(text, sizeof(text), "%t", "menu_4");  //What's new? (/ff2new).
		ff2_menu.AddItem("", text);
		Format(text, sizeof(text), "%t", "menu_5");  //Queue points
		ff2_menu.AddItem("", text);
		Format(text, sizeof(text), "%t", "menu_8");  //Toggle music (/ff2music)
		ff2_menu.AddItem("", text);
		Format(text, sizeof(text), "%t", "menu_9");  //Toggle monologues (/ff2voice)
		ff2_menu.AddItem("", text);
		Format(text, sizeof(text), "%t", "menu_9a");  //Toggle info about changes of classes in FF2
		ff2_menu.AddItem("", text);
		if(GetConVarBool(cvarDuoToggle))
		{
			Format(text, sizeof(text), "%t", "menu_10");  //Toggle companions (/ff2companion)
			ff2_menu.AddItem("", text);
		}
		ff2_menu.Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action NewPanelCmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	NewPanelChangelog(client);
	return Plugin_Handled;
}

Action NewPanelChangelog(int client, bool menuentered=false)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	Menu version_menu=new Menu(NewPanelH);
	version_menu.ExitButton=true;
	version_menu.ExitBackButton=menuentered;
	version_menu.SetTitle("FF2 Changelog - Current version: %s\n", ff2versiontitles[maxVersion]);
	char text_buffer[32];

	SetGlobalTransTarget(client);
	for(int i=maxVersion; i; i--)
	{
		if(i!=maxVersion)
		{
			Format(text_buffer, sizeof(text_buffer), "FF2 %s", ff2versiontitles[i]);
		}
		else
		{
			Format(text_buffer, sizeof(text_buffer), "FF2 %s <- Current version", ff2versiontitles[i]);
		}
		version_menu.AddItem(ff2versiontitles[i], text_buffer);
	}
	version_menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public int NewPanelH(Menu menu, MenuAction action, int client, int param2)
{
	if(action==MenuAction_Select)
	{
		char buffer[32];
		menu.GetItem(param2, buffer, sizeof(buffer));
		char full_url[192];
		ff2_changelog_url.GetString(full_url, sizeof(full_url));
		Format(full_url, sizeof(full_url), "%s#%s", full_url, buffer);
		ShowMOTDPanel(client, "FF2 Version Info", full_url, MOTDPANEL_TYPE_URL);
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if(action==MenuAction_Cancel)
	{
		if(param2==MenuCancel_ExitBack)
		{
			FF2Panel(client, 0);
		}
		else if(param2==MenuCancel_Exit)
		{
			return 0;
		}
	}
	return 0;
}

public Action HelpPanel3Cmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	HelpPanel3(client);
	return Plugin_Handled;
}

Action HelpPanel3(int client, bool menuentered=false)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	Menu ff2_menu=new Menu(ClassInfoTogglePanelH);
	ff2_menu.SetTitle("Turn the Freak Fortress 2 class info...");
	ff2_menu.AddItem("", "On");
	ff2_menu.AddItem("", "Off");
	ff2_menu.ExitButton=true;
	ff2_menu.ExitBackButton=menuentered;
	ff2_menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int ClassInfoTogglePanelH(Menu menu, MenuAction action, int client, int selection)
{
	if(IsValidClient(client))
	{
		if(action==MenuAction_Select)
		{
			selection++;
			char cookies[24];
			char cookieValues[8][5];
			GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
			ExplodeString(cookies, " ", cookieValues, 8, 5);
			if(selection==2)
			{
				Format(cookies, sizeof(cookies), "%s %s %s 0 %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
			}
			else
			{
				Format(cookies, sizeof(cookies), "%s %s %s 1 %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
			}
			SetClientCookie(client, FF2Cookies, cookies);
			CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_classinfo", selection==2 ? "off" : "on");
			menu.Display(client, MENU_TIME_FOREVER);
		}
		else if(action==MenuAction_Cancel)
		{
			if(selection==MenuCancel_ExitBack)
			{
				FF2Panel(client, 0);
			}
			else if(selection==MenuCancel_Exit)
			{
				return 0;
			}
		}
	}
	return 0;
}

public Action Command_HelpPanelClass(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	HelpPanelClass(client);
	return Plugin_Handled;
}

Action HelpPanelClass(int client)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(client);
	if(boss!=-1)
	{
		HelpPanelBoss(boss);
		return Plugin_Continue;
	}

	char text[512];
	TFClassType player_class=TF2_GetPlayerClass(client);
	SetGlobalTransTarget(client);
	switch(player_class)
	{
	case TFClass_Scout:
		{
			Format(text, sizeof(text), "%t", "help_scout");
		}
	case TFClass_Soldier:
		{
			Format(text, sizeof(text), "%t", "help_soldier");
		}
	case TFClass_Pyro:
		{
			Format(text, sizeof(text), "%t", "help_pyro");
		}
	case TFClass_DemoMan:
		{
			Format(text, sizeof(text), "%t", "help_demo");
		}
	case TFClass_Heavy:
		{
			Format(text, sizeof(text), "%t", "help_heavy");
		}
	case TFClass_Engineer:
		{
			Format(text, sizeof(text), "%t", "help_engineer");
		}
	case TFClass_Medic:
		{
			Format(text, sizeof(text), "%t", "help_medic");
		}
	case TFClass_Sniper:
		{
			Format(text, sizeof(text), "%t", "help_sniper");
		}
	case TFClass_Spy:
		{
			Format(text, sizeof(text), "%t", "help_spy");
		}
	default:
		{
			Format(text, sizeof(text), "");
		}
	}

	if(player_class!=TFClass_Sniper)
	{
		Format(text, sizeof(text), "%t\n%s", "help_melee", text);
	}

	Panel panel=new Panel();
	panel.SetTitle(text);
	panel.DrawItem("Exit");
	panel.Send(client, HintPanelH, 20);
	delete panel;
	return Plugin_Continue;
}

void HelpPanelBoss(int boss)
{
	if(!IsValidClient(Boss[boss]))
	{
		return;
	}

	char text[512], language[20];
	GetLanguageInfo(GetClientLanguage(Boss[boss]), language, 8, text, 8);
	Format(language, sizeof(language), "description_%s", language);

	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], language, text, sizeof(text));
	if(!text[0])
	{
		KvGetString(BossKV[Special[boss]], "description_en", text, sizeof(text));  //Default to English if their language isn't available
		if(!text[0])
		{
			return;
		}
	}
	ReplaceString(text, sizeof(text), "\\n", "\n");

	Panel panel=new Panel();
	panel.SetTitle(text);
	panel.DrawItem("Exit");
	panel.Send(Boss[boss], HintPanelH, 20);
	delete(panel);
}

public Action MusicTogglePanelCmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	MusicTogglePanel(client);
	return Plugin_Handled;
}

void MusicTogglePanel(int client, bool menuentered=false)
{
	if(!Enabled || !IsValidClient(client))
	{
		return;
	}

	Menu ff2_menu=new Menu(MusicTogglePanelH);
	ff2_menu.ExitBackButton=menuentered;
	ff2_menu.ExitButton=true;
	ff2_menu.SetTitle("Turn the Freak Fortress 2 music...");
	ff2_menu.AddItem("", "On");
	ff2_menu.AddItem("", "Off");
	ff2_menu.Display(client, MENU_TIME_FOREVER);
}

public int MusicTogglePanelH(Menu menu, MenuAction action, int client, int selection)
{
	if(IsValidClient(client) && action==MenuAction_Select)
	{
		selection++;
		if(selection==2)  //Off
		{
			SetClientSoundOptions(client, SOUNDEXCEPT_MUSIC, false);
			StopMusic(client, true);
		}
		else  //On
		{
			//If they already have music enabled don't do anything
			if(!CheckSoundException(client, SOUNDEXCEPT_MUSIC))
			{
				SetClientSoundOptions(client, SOUNDEXCEPT_MUSIC, true);
				StartMusic(client);
			}
		}
		CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_music", selection==2 ? "off" : "on");
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if(action==MenuAction_Cancel)
	{
		if(selection==MenuCancel_ExitBack)
		{
			FF2Panel(client, 0);
		}
		else if(selection==MenuCancel_Exit)
		{
			return 0;
		}
	}
	return 0;
}

public Action VoiceTogglePanelCmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	VoiceTogglePanel(client);
	return Plugin_Handled;
}

Action VoiceTogglePanel(int client, bool menuentered=false)
{
	if(!Enabled || !IsValidClient(client))
	{
		return Plugin_Continue;
	}

	Menu ff2_menu=new Menu(VoiceTogglePanelH);
	ff2_menu.SetTitle("Turn the Freak Fortress 2 voices...");
	ff2_menu.AddItem("", "On");
	ff2_menu.AddItem("", "Off");
	ff2_menu.ExitBackButton=menuentered;
	ff2_menu.ExitButton=true;
	ff2_menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public int VoiceTogglePanelH(Menu menu, MenuAction action, int client, int selection)
{
	if(IsValidClient(client))
	{
		if(action==MenuAction_Select)
		{
			selection++;
			if(selection==2)
			{
				SetClientSoundOptions(client, SOUNDEXCEPT_VOICE, false);
			}
			else
			{
				SetClientSoundOptions(client, SOUNDEXCEPT_VOICE, true);
			}

			CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_voice", selection==2 ? "off" : "on");
			if(selection==2)
			{
				CPrintToChat(client, "%t", "ff2_voice2");
			}
			menu.Display(client, MENU_TIME_FOREVER);
		}
		else if(action==MenuAction_End)
		{
			delete menu;
		}
		else if(action==MenuAction_Cancel)
		{
			if(selection==MenuCancel_ExitBack)
			{
				FF2Panel(client, 0);
			}
			else if(selection==MenuCancel_Exit)
			{
				return 0;
			}
		}
	}
	return 0;
}

public Action HookSound(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!Enabled || !IsValidClient(client) || channel<1)
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(client);
	if(boss==-1)
	{
		return Plugin_Continue;
	}

	if(channel==SNDCHAN_VOICE || (channel==SNDCHAN_STATIC && !StrContains(sound, "vo")))
	{
		if(FF2flags[Boss[boss]] & FF2FLAG_TALKING)
		{
			return Plugin_Continue;
		}
		char newSound[PLATFORM_MAX_PATH];
		if(RandomSoundVo("catch_replace", newSound, sizeof(newSound), boss, sound))
		{
			strcopy(sound, sizeof(sound), newSound);
			return Plugin_Changed;
		}

		if(RandomSound("catch_phrase", newSound, sizeof(newSound), boss))
		{
			strcopy(sound, sizeof(sound), newSound);
			return Plugin_Changed;
		}

		if(bBlockVoice[Special[boss]])
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

stock int GetHealingTarget(int client, bool checkgun=false)
{
	int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
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
		char classname[64];
		GetEntityClassname(medigun, classname, sizeof(classname));
		if(!strcmp(classname, "tf_weapon_medigun", false))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			{
				return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
			}
		}
	}
	return -1;
}

stock bool IsValidClient(int client, bool replaycheck=true)
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

public void CvarChangeNextmap(Handle convar, const char[] oldValue, const char[] newValue)
{
	CreateTimer(0.1, Timer_DisplayCharsetVote, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DisplayCharsetVote(Handle timer)
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

	Handle menu=CreateMenu(Handler_VoteCharset, view_as<MenuAction>(MENU_ACTIONS_ALL));
	SetMenuTitle(menu, "%t", "select_charset");  //"Please vote for the character set for the next map."

	char config[PLATFORM_MAX_PATH], charset[64];
	BuildPath(Path_SM, config, sizeof(config), "configs/freak_fortress_2/characters.cfg");

	Handle Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	AddMenuItem(menu, "Random", "Random");
	int total, charsets;
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
		Handle voteDuration=FindConVar("sm_mapvote_voteduration");
		VoteMenuToAll(menu, voteDuration ? GetConVarInt(voteDuration) : 20);
	}
	return Plugin_Continue;
}
public int Handler_VoteCharset(Handle menu, MenuAction action, int param1, int param2)
{
	if(action==MenuAction_VoteEnd)
	{
		FF2CharSet=param1 ? param1-1 : validCharsets[GetRandomInt(1, FF2CharSet)]-1;  //If param1 is 0 then we need to find a random charset

		char nextmap[32];
		GetConVarString(cvarNextmap, nextmap, sizeof(nextmap));
		GetMenuItem(menu, param1, FF2CharSetString, sizeof(FF2CharSetString));
		CPrintToChatAll("{olive}[FF2]{default} %t", "nextmap_charset", nextmap, FF2CharSetString);  //"The character set for {1} will be {2}."
		isCharSetSelected=true;
	}
	else if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Command_Nextmap(int client, int args)
{
	if(FF2CharSetString[0])
	{
		char nextmap[42];
		GetConVarString(cvarNextmap, nextmap, sizeof(nextmap));
		CPrintToChat(client, "{olive}[FF2]{default} %t", "nextmap_charset", nextmap, FF2CharSetString);
	}
	return Plugin_Handled;
}

public Action Command_Say(int client, int args)
{
	char chat[128];
	if(GetCmdArgString(chat, sizeof(chat))<1 || !client)
	{
		return Plugin_Continue;
	}

	if(!strcmp(chat, "\"nextmap\"") && FF2CharSetString[0])
	{
		Command_Nextmap(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

bool UseAbility(const char[] ability_name, const char[] plugin_name, int boss, int slot, int buttonMode=0)
{
	bool enabled=true;
	Call_StartForward(PreAbility);
	Call_PushCell(boss);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	Call_PushCell(slot);
	Call_PushCellRef(enabled);
	Call_Finish();

	if(!enabled)
	{
		return false;
	}

	Action action=Plugin_Continue;
	Call_StartForward(OnAbility);
	Call_PushCell(boss);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	if(slot<0 || slot>3)
	{
		Call_PushCell(3);  //Status - we're assuming here a life-loss ability will always be in use if it gets called
		Call_Finish(action);
	}
	else if(!slot)
	{
		FF2flags[Boss[boss]]&=~FF2FLAG_BOTRAGE;
		Call_PushCell(3);  //Status - we're assuming here a rage ability will always be in use if it gets called
		Call_Finish(action);

		if(BossRageDamage[boss]>1)	// No 0.2 second delay upon RAGE to refill meter
		{
			BossCharge[boss][slot]=0.0;
		}
	}
	else
	{
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
		int button;
		switch(buttonMode)
		{
		case 1:
			{
				button=IN_DUCK|IN_ATTACK2;
				bossHasRightMouseAbility[boss]=true;
			}
		case 2:
			{
				button=IN_RELOAD;
				bossHasReloadAbility[boss]=true;
			}
		case 3:
			{
				button=IN_ATTACK3;
			}
		case 4:
			{
				button=IN_DUCK;
			}
		case 5:
			{
				button=IN_SCORE;
			}
		default:
			{
				button=IN_ATTACK2;
				bossHasRightMouseAbility[boss]=true;
			}
		}

		if(GetClientButtons(Boss[boss]) & button)
		{
			for(int timer; timer<=1; timer++)
			{
				if(BossInfoTimer[boss][timer]!=INVALID_HANDLE)
				{
					KillTimer(BossInfoTimer[boss][timer]);
					BossInfoTimer[boss][timer]=INVALID_HANDLE;
				}
			}

			if(BossCharge[boss][slot]>=0.0)
			{
				Call_PushCell(2);  //Status
				Call_Finish(action);
				float charge_time;
				if(GetArgumentI(boss, plugin_name, ability_name, "slot", -2)!=-2)
				{
					charge_time=GetArgumentF(boss, plugin_name, ability_name, "charge time", 1.5);
				}
				else
				{
					charge_time=GetAbilityArgumentFloat(boss, plugin_name, ability_name, 1, 1.5);
				}
				float charge=100.0*0.2/charge_time;
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
				Call_PushCell(1);  //Status
				Call_Finish(action);
				BossCharge[boss][slot]+=0.2;
			}
		}
		else if(BossCharge[boss][slot]>0.3)
		{
			float angles[3];
			GetClientEyeAngles(Boss[boss], angles);
			if(angles[0]<-45.0)
			{
				Call_PushCell(3);
				Call_Finish(action);
				Handle data;
				CreateDataTimer(0.1, Timer_UseBossCharge, data);
				WritePackCell(data, boss);
				WritePackCell(data, slot);
				float cooldown;
				if(GetArgumentI(boss, plugin_name, ability_name, "slot", -2)!=-2)
				{
					cooldown=GetArgumentF(boss, plugin_name, ability_name, "cooldown", 5.0);
				}
				else
				{
					cooldown=GetAbilityArgumentFloat(boss, plugin_name, ability_name, 2, 5.0);
				}
				WritePackFloat(data, -1.0*cooldown);
				ResetPack(data);
			}
			else
			{
				Call_PushCell(0);  //Status
				Call_Finish(action);
				BossCharge[boss][slot]=0.0;
			}
		}
		else if(BossCharge[boss][slot]<0.0)
		{
			Call_PushCell(1);  //Status
			Call_Finish(action);
			BossCharge[boss][slot]+=0.2;
		}
		else
		{
			Call_PushCell(0);  //Status
			Call_Finish(action);
		}
	}
	return true;
}

public Action Timer_UseBossCharge(Handle timer, Handle data)
{
	BossCharge[ReadPackCell(data)][ReadPackCell(data)]=ReadPackFloat(data);
	return Plugin_Continue;
}

stock bool RemoveShield(int client, int attacker, float position[3])
{
	char classname[64];
	int entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_wear*"))!=-1)
	{
		GetEntityClassname(entity, classname, sizeof(classname));
		if(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")==57 || StrContains(classname, "demoshield")>-1)
		{
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				TF2_RemoveWearable(client, entity);
				AcceptEntityInput(entity, "Kill"); //Guarantee
				EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
				EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
				EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
				EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
				TF2_AddCondition(client, TFCond_Bonked, 0.1); // Shows "MISS!" upon breaking shield
				return true;
			}
		}
	}
	return false;
}

public int Native_IsEnabled(Handle plugin, int numParams)
{
	return Enabled;
}

public int Native_FF2Version(Handle plugin, int numParams)
{
	int version[3];  //Blame the compiler for this mess -.-
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

public int Native_ForkVersion(Handle plugin, int numParams)
{
	int fversion[3];
	fversion[0]=0;
	fversion[1]=0;
	fversion[2]=0;
	SetNativeArray(1, fversion, sizeof(fversion));
	return false;
}

public int Native_GetBoss(Handle plugin, int numParams)
{
	int boss=GetNativeCell(1);
	if(boss>=0 && boss<=MaxClients && IsValidClient(Boss[boss]))
	{
		return GetClientUserId(Boss[boss]);
	}
	return -1;
}

public int Native_GetIndex(Handle plugin, int numParams)
{
	return GetBossIndex(GetNativeCell(1));
}

public int Native_GetTeam(Handle plugin, int numParams)
{
	return BossTeam;
}

public int Native_GetSpecial(Handle plugin, int numParams)
{
	int index=GetNativeCell(1), dstrlen=GetNativeCell(3), see=GetNativeCell(4);
	char[] s=new char[dstrlen];
	if(see)
	{
		if(index<0) return false;
		if(!BossKV[index]) return false;
		KvRewind(BossKV[index]);
		KvGetString(BossKV[index], "name", s, dstrlen);
		SetNativeString(2, s,dstrlen);
	}
	else
	{
		if(index<0) return false;
		if(Special[index]<0) return false;
		if(!BossKV[Special[index]]) return false;
		KvRewind(BossKV[Special[index]]);
		KvGetString(BossKV[Special[index]], "name", s, dstrlen);
		SetNativeString(2, s,dstrlen);
	}
	return true;
}

public int Native_GetBossHealth(Handle plugin, int numParams)
{
	return BossHealth[GetNativeCell(1)];
}

public int Native_SetBossHealth(Handle plugin, int numParams)
{
	BossHealth[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetBossMaxHealth(Handle plugin, int numParams)
{
	return BossHealthMax[GetNativeCell(1)];
}

public int Native_SetBossMaxHealth(Handle plugin, int numParams)
{
	BossHealthMax[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetBossLives(Handle plugin, int numParams)
{
	return BossLives[GetNativeCell(1)];
}

public int Native_SetBossLives(Handle plugin, int numParams)
{
	BossLives[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetBossMaxLives(Handle plugin, int numParams)
{
	return BossLivesMax[GetNativeCell(1)];
}

public int Native_SetBossMaxLives(Handle plugin, int numParams)
{
	BossLivesMax[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetBossCharge(Handle plugin, int numParams)
{
	return view_as<int>(BossCharge[GetNativeCell(1)][GetNativeCell(2)]);
}

public int Native_SetBossCharge(Handle plugin, int numParams)  //TODO: This duplicates logic found in Timer_UseBossCharge
{
	BossCharge[GetNativeCell(1)][GetNativeCell(2)]=view_as<float>(GetNativeCell(3));
}

public int Native_GetBossRageDamage(Handle plugin, int numParams)
{
	return BossRageDamage[GetNativeCell(1)];
}

public int Native_SetBossRageDamage(Handle plugin, int numParams)
{
	BossRageDamage[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetRoundState(Handle plugin, int numParams)
{
	if(CheckRoundState()<=0)
	{
		return 0;
	}
	return CheckRoundState();
}

public int Native_GetRageDist(Handle plugin, int numParams)
{
	int index=GetNativeCell(1);
	char plugin_name[64];
	GetNativeString(2,plugin_name,64);
	char ability_name[64];
	GetNativeString(3,ability_name,64);

	if(!BossKV[Special[index]]) return view_as<int>(0.0);
	KvRewind(BossKV[Special[index]]);
	float see;
	if(!ability_name[0])
	{
		return view_as<int>(KvGetFloat(BossKV[Special[index]], "ragedist", 400.0));
	}
	char s[10];
	for(int i=1; i<=MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			char ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if(strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			if((see=KvGetFloat(BossKV[Special[index]],"dist",-1.0))<0)
			{
				KvRewind(BossKV[Special[index]]);
				see=KvGetFloat(BossKV[Special[index]],"ragedist",400.0);
			}
			return view_as<int>(see);
		}
	}
	return view_as<int>(0.0);
}

public int Native_HasAbility(Handle plugin, int numParams)
{
	char pluginName[64], abilityName[64];

	int boss=GetNativeCell(1);
	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	if(boss==-1 || Special[boss]==-1 || !BossKV[Special[boss]])
	{
		return false;
	}

	KvRewind(BossKV[Special[boss]]);
	if(!BossKV[Special[boss]])
	{
		LogError("Failed KV: %i %i", boss, Special[boss]);
		return false;
	}

	char ability[12];
	for(int i=1; i<=MAXRANDOMS; i++)
	{
		Format(ability, sizeof(ability), "ability%i", i);
		if(KvJumpToKey(BossKV[Special[boss]], ability))  //Does this ability number exist?
		{
			char abilityName2[64];
			KvGetString(BossKV[Special[boss]], "name", abilityName2, sizeof(abilityName2));
			if(StrEqual(abilityName, abilityName2))  //Make sure the ability names are equal
			{
				char pluginName2[64];
				KvGetString(BossKV[Special[boss]], "plugin_name", pluginName2, sizeof(pluginName2));
				if(!pluginName[0] || !pluginName2[0] || StrEqual(pluginName, pluginName2))  //Make sure the plugin names are equal
				{
					return true;
				}
			}
			KvGoBack(BossKV[Special[boss]]);
		}
	}
	return false;
}

public int Native_DoAbility(Handle plugin, int numParams)
{
	char plugin_name[64];
	char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	UseAbility(ability_name, plugin_name, GetNativeCell(1), GetNativeCell(4), GetNativeCell(5));
}

public int Native_GetAbilityArgument(Handle plugin, int numParams)
{
	char plugin_name[64];
	char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	return GetAbilityArgument(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5));
}

public int Native_GetAbilityArgumentFloat(Handle plugin, int numParams)
{
	char plugin_name[64];
	char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	return view_as<int>(GetAbilityArgumentFloat(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5)));
}

public int Native_GetAbilityArgumentString(Handle plugin, int numParams)
{
	char plugin_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	char ability_name[64];
	GetNativeString(3, ability_name, sizeof(ability_name));
	int dstrlen=GetNativeCell(6);
	char[] s=new char[dstrlen+1];
	GetAbilityArgumentString(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), s, dstrlen);
	SetNativeString(5, s, dstrlen);
}

public int Native_GetArgNamedI(Handle plugin, int numParams)
{
	char plugin_name[64];
	char ability_name[64];
	char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	return GetArgumentI(GetNativeCell(1), plugin_name, ability_name, argument, GetNativeCell(5));
}

public int Native_GetArgNamedF(Handle plugin, int numParams)
{
	char plugin_name[64];
	char ability_name[64];
	char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	return view_as<int>(GetArgumentF(GetNativeCell(1), plugin_name, ability_name, argument, GetNativeCell(5)));
}

public int Native_GetArgNamedS(Handle plugin, int numParams)
{
	char plugin_name[64];
	char ability_name[64];
	char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	int dstrlen=GetNativeCell(6);
	char[] s=new char[dstrlen+1];
	GetArgumentS(GetNativeCell(1), plugin_name, ability_name, argument, s, dstrlen);
	SetNativeString(5, s, dstrlen);
}

public int Native_GetDamage(Handle plugin, int numParams)
{
	int client=GetNativeCell(1);
	if(!IsValidClient(client))
	{
		return 0;
	}
	return Damage[client];
}

public int Native_GetFF2flags(Handle plugin, int numParams)
{
	return FF2flags[GetNativeCell(1)];
}

public int Native_SetFF2flags(Handle plugin, int numParams)
{
	FF2flags[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetQueuePoints(Handle plugin, int numParams)
{
	return GetClientQueuePoints(GetNativeCell(1));
}

public int Native_SetQueuePoints(Handle plugin, int numParams)
{
	SetClientQueuePoints(GetNativeCell(1), GetNativeCell(2));
}

public int Native_GetSpecialKV(Handle plugin, int numParams)
{
	int index=GetNativeCell(1);
	bool isNumOfSpecial=view_as<bool>(GetNativeCell(2));
	if(isNumOfSpecial)
	{
		if(index!=-1 && index<Specials)
		{
			if(BossKV[index]!=INVALID_HANDLE)
			{
				KvRewind(BossKV[index]);
			}
			return view_as<int>(BossKV[index]);
		}
	}
	else
	{
		if(index!=-1 && index<=MaxClients && Special[index]!=-1 && Special[index]<MAXSPECIALS)
		{
			if(BossKV[Special[index]]!=INVALID_HANDLE)
			{
				KvRewind(BossKV[Special[index]]);
			}
			return view_as<int>(BossKV[Special[index]]);
		}
	}
	return view_as<int>(INVALID_HANDLE);
}

public int Native_StartMusic(Handle plugin, int numParams)
{
	StartMusic(GetNativeCell(1));
}

public int Native_StopMusic(Handle plugin, int numParams)
{
	StopMusic(GetNativeCell(1));
}

public int Native_RandomSound(Handle plugin, int numParams)
{
	int length=GetNativeCell(3)+1;
	int boss=GetNativeCell(4);
	int slot=GetNativeCell(5);
	char[] sound=new char[length];
	int kvLength;

	GetNativeStringLength(1, kvLength);
	kvLength++;

	char[] keyvalue=new char[kvLength];
	GetNativeString(1, keyvalue, kvLength);

	bool soundExists;
	if(!strcmp(keyvalue, "sound_ability"))
	{
		soundExists=RandomSoundAbility(keyvalue, sound, length, boss, slot);
	}
	else
	{
		soundExists=RandomSound(keyvalue, sound, length, boss);
	}
	SetNativeString(2, sound, length);
	return soundExists;
}

public int Native_GetClientGlow(Handle plugin, int numParams)
{
	int client=GetNativeCell(1);
	if(IsValidClient(client))
	{
		return view_as<int>(GlowTimer[client]);
	}
	else
	{
		return -1;
	}
}

public int Native_SetClientGlow(Handle plugin, int numParams)
{
	SetClientGlow(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public int Native_GetAlivePlayers(Handle plugin, int numParams)
{
	return RedAlivePlayers;
}

public int Native_GetBossPlayers(Handle plugin, int numParams)
{
	return BlueAlivePlayers;
}

public int Native_Debug(Handle plugin, int numParams)
{
	return GetConVarBool(cvarDebug);
}

public int Native_IsVSHMap(Handle plugin, int numParams)
{
	return false;
}

public Action VSH_OnIsSaxtonHaleModeEnabled(int &result)
{
	if((!result || result==1) && Enabled)
	{
		result=2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleTeam(int &result)
{
	if(Enabled)
	{
		result=BossTeam;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleUserId(int &result)
{
	if(Enabled && IsClientConnected(Boss[0]))
	{
		result=GetClientUserId(Boss[0]);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSpecialRoundIndex(int &result)
{
	if(Enabled)
	{
		result=Special[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleHealth(int &result)
{
	if(Enabled)
	{
		result=BossHealth[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleHealthMax(int &result)
{
	if(Enabled)
	{
		result=BossHealthMax[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetClientDamage(int client, int &result)
{
	if(Enabled)
	{
		result=Damage[client];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetRoundState(int &result)
{
	if(Enabled)
	{
		result=CheckRoundState();
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnTakeDamagePost(int client, int attacker, int inflictor, float damage, int damagetype)
{
	if(IsBoss(client))
	{
		UpdateHealthBar();
	}
}

public void OnEntityCreated(int entity, const char[] classname)
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
}

public void OnEntityDestroyed(int entity)
{
	if(entity==g_Monoculus)
	{
		g_Monoculus=FindEntityByClassname2(-1, MONOCULUS);
		if(g_Monoculus==entity)
		{
			g_Monoculus=FindEntityByClassname2(entity, MONOCULUS);
			if(!IsValidEntity(g_Monoculus) || g_Monoculus==-1)
			{
				FindHealthBar();
			}
		}
	}
}

public void OnItemSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPickup);
	SDKHook(entity, SDKHook_Touch, OnPickup);
}

public Action OnPickup(int entity, int client)  //Thanks friagram!
{
	if(IsBoss(client))
	{
		char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!StrContains(classname, "item_healthkit") && !(FF2flags[client] & FF2FLAG_ALLOW_HEALTH_PICKUPS))
		{
			return Plugin_Handled;
		}
		else if((!StrContains(classname, "item_ammopack") || StrEqual(classname, "tf_ammo_pack")) && !(FF2flags[client] & FF2FLAG_ALLOW_AMMO_PICKUPS))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public int CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
	case RoundState_Init, RoundState_Pregame:
		{
			return -1;
		}
	case RoundState_StartGame, RoundState_Preround:
		{
			return 0;
		}
	case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return 1;
		}
	default:
		{
			return 2;
		}
	}
	#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=9
	return -1;  //Compiler bug-doesn't recognize 'default' as a valid catch-all
	#endif
}

void FindHealthBar()
{
	healthBar=FindEntityByClassname2(-1, HEALTHBAR_CLASS);
	if(!IsValidEntity(healthBar))
	{
		healthBar=CreateEntityByName(HEALTHBAR_CLASS);
	}
}

public void HealthbarEnableChanged(Handle convar, const char[] oldValue, const char[] newValue)
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

void UpdateHealthBar()
{
	if(!Enabled || !GetConVarBool(cvarHealthBar) || IsValidEntity(g_Monoculus) || !IsValidEntity(healthBar) || CheckRoundState()==-1)
	{
		return;
	}

	int healthAmount, maxHealthAmount, bosses, healthPercent;
	for(int boss; boss<=MaxClients; boss++)
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

void SetClientGlow(int client, float time1, float time2=-1.0)
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

#include <freak_fortress_2_vsh_feedback>
