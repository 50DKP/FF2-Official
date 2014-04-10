#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION 		"0.4.4.2"
#define PLUGIN_PREFIX 		"\x07FFD700[RTD]\x01"
#define MAX_RTD_EFFECTS		35

#define COLOR_PERK_GOOD 	"\x0732CD32"
#define COLOR_PERK_BAD 		"\x078650AC"
#define COLOR_PERK_ORANGE	"\x07FF8C00"
#define COLOR_VINTAGE		"\x07476291"	

#define COLOR_NORMAL		{255,255,255,255}
#define COLOR_BLACK			{200,200,200,192}
#define COLOR_INVIS			{255,255,255,0}
#define COLOR_FROZEN		{64,224,208,50}
#define COLOR_WHITE			{255,255,255,255}
#define COLOR_GREY			{128,128,128,255}
#define COLOR_RED			{255,75,75,255}
#define COLOR_BLUE			{75,75,255,255}

#define SOUND_SANDVICH		"vo/heavy_sandwichtaunt17.wav"
#define SOUND_SPEED			"vo/scout_apexofjump02.wav"
#define SOUND_CHARGED		"vo/medic_autochargeready02.wav"
#define SOUND_CLOAK			"vo/taunts/spy_taunts16.wav"
#define SOUND_EXPLODE		"items/pumpkin_explode1.wav"
#define SOUND_SNAIL			"vo/scout_dominationhvy08.wav"
#define SOUND_BEEP			"buttons/button17.wav"
#define SOUND_FINAL			"weapons/cguard/charging.wav"
#define SOUND_BOOM			"weapons/explode3.wav"
#define SOUND_LOW_HEALTH	"vo/medic_autodejectedtie07.wav"
#define SOUND_MELEE			"vo/heavy_meleedare02.wav"
#define SOUND_BLIP			"buttons/blip1.wav"
#define SOUND_NOSTALGIA		"ui/tv_tune.wav"
#define SOUND_EARTHQUAKE	"ambient/atmosphere/terrain_rumble1.wav"
#define SOUND_SENTRY		"vo/engineer_autobuildingsentry02.wav"
#define SOUND_NOPE			"vo/engineer_no01.wav"
#define SOUND_STRANGE 		"ambient/cow1.wav"
#define SOUND_DISPENSER		"vo/engineer_autobuildingdispenser02.wav"
#define SOUND_SAUCE			"vo/scout_autodejectedtie02.wav"
#define SOUND_TOXIC			"vo/soldier_pickaxetaunt01.wav"
#define SOUND_SSENTRY		"vo/engineer_needsentry01.wav"
#define SOUND_SDISPENSER	"vo/engineer_needdispenser01.wav"
#define SOUND_TIMEBOMB		"vo/heavy_cartmovingforwardoffense15.wav"
#define SOUND_BEACON		"vo/scout_award01.wav"
#define SOUND_GODMODE		"vo/scout_invincible01.wav"
#define SOUND_WCHARGE		"vo/soldier_battlecry01.wav"
#define SOUND_BLIND			"vo/test_one.wav"
#define SOUND_INVIS			"player/spy_cloak.wav"
#define SOUND_INFINTE_AMMO	"vo/taunts/engineer_taunts05.wav"
#define SOUND_CRITS			"vo/taunts/demoman_taunts11.wav"
#define SOUND_DRUGS			"vo/demoman_positivevocalization04.wav"
#define SOUND_HOMING		"vo/sniper_domination16.wav"
#define SOUND_BIGHEAD		"vo/scout_sf12_badmagic16.wav"
#define SOUND_JUMP			"vo/scout_sf12_goodmagic04.wav"
#define SOUND_TINYPLAYER	"vo/scout_sf12_badmagic28.wav"
#define SOUND_NOCLIP		"vo/scout_sf12_goodmagic05.wav"
#define SOUND_LOW_GRAVITY	"vo/scout_sf12_badmagic11.wav"

#define SLOT_PRIMARY 0
#define SLOT_SECONDARY 1
#define SLOT_MELEE 2

#define ITEM_ROCKET_JUMPER 237
#define ITEM_MANGLER 441
#define ITEM_BISON 442
#define ITEM_POMSON 588

enum g_ePerkType
{
	PERK_GOOD=0,
	PERK_BAD
};

#define STRING_PERK_MAXLEN 100
enum g_ePerks
{
	String:g_strPerkName[STRING_PERK_MAXLEN],
	String:g_strPerkDesc[STRING_PERK_MAXLEN],
	String:g_strPerkKey[STRING_PERK_MAXLEN],
	g_ePerkType:g_nPerkType,
	bool:g_bPerkDisabled,	
	Float:g_flPerkTime
};
new g_nPerks[MAX_RTD_EFFECTS][g_ePerks];

enum g_eCurrentPerk
{
	PERK_GODMODE=0,
	PERK_TOXIC,
	PERK_BUFFED_HEALTH,
	PERK_SPEED,
	PERK_NOCLIP,
	PERK_LOW_GRAVITY,
	PERK_UBER,
	PERK_INVIS,
	PERK_CLOAK,
	PERK_CRITS,
	PERK_INFINITE_AMMO,
	PERK_SCARY_BULLETS,
	PERK_SENTRY,
	PERK_HOMING,
	PERK_CHARGE,
	PERK_EXPLODE,
	PERK_SNAIL,
	PERK_FREEZE,
	PERK_TIMEBOMB,
	PERK_IGNITE,
	PERK_LOW_HEALTH,
	PERK_DRUG,
	PERK_BLIND,
	PERK_MELEE,
	PERK_BEACON,
	PERK_TAUNT,
	PERK_NOSTALGIA,
	PERK_EARTHQUAKE,
	PERK_FUNNY_FEELING,
	PERK_SAUCE,
	PERK_DISPENSER,
	PERK_JUMP,
	PERK_INSTANT_KILLS,
	PERK_BIG_HEAD,
	PERK_TINY_PLAYER
};

enum g_eDiceModes
{
	MODE_FREE4ALL=0,
	MODE_LEGACY,
	MODE_TEAMLIMIT
};

enum g_eStatus
{
	STATE_IDLE=0,
	STATE_ROLLING
};

enum g_ePlayerInfo
{
	g_eStatus:g_nPlayerState,
	g_iPlayerLastRoll,
	g_iPlayerTime,
	Handle:g_hPlayerMain,
	Handle:g_hPlayerExtra,
	Handle:g_hPlayerEntities,
	g_eCurrentPerk:g_nPlayerPerk,
	g_iPlayerColor[4]
};

new g_nPlayerData[MAXPLAYERS+1][g_ePlayerInfo];

new Handle:g_hCvarVersion;
new Handle:g_hCvarEnabled;
new Handle:g_hCvarTimelimit;
new Handle:g_hCvarMode;
new Handle:g_hCvarDuration;
new Handle:g_hCvarTeamlimit;
new Handle:g_hCvarChance;
new Handle:g_hCvarDistance;
new Handle:g_hCvarHealth;
new Handle:g_hCvarGravity;
new Handle:g_hCvarSnail;
new Handle:g_hCvarTrigger;
new Handle:g_hCvarAdmin;
new Handle:g_hCvarDonator;
new Handle:g_hCvarDonatorChance;
new Handle:g_hCvarTimebombTick;
new Handle:g_hCvarTimebombDamage;
new Handle:g_hCvarTimebombRadius;
new Handle:g_hCvarBlind;
new Handle:g_hCvarBeaconRadius;
new Handle:g_hCvarScary;
new Handle:g_hCvarSentryLevel;
new Handle:g_hCvarSentryCount;
new Handle:g_hCvarHomingSpeed;
new Handle:g_hCvarHomingReflect;
new Handle:g_hCvarFOV;
new Handle:g_hCvarDispenserLevel;
new Handle:g_hCvarDispenserCount;
new Handle:g_hCvarDisabled;
new Handle:g_hCvarBuddah;
new Handle:g_hCvarSetup;
new Handle:g_hCvarSentryKeep;
new Handle:g_hCvarDispenserKeep;
new Handle:g_hCvarBigHead;
new Handle:g_hCvarTinyPlayer;
new Handle:g_hCvarRespawnStuck;
new Handle:g_hCvarHomingCrits;
new Handle:g_hCvarDebugEffects;

new bool:g_bFirstLoad;

#define MAX_CHAT_TRIGGERS 10
#define STRING_TRIGGERS_MAXLEN 50
new g_iChatTriggers;
new String:g_strChatTriggers[MAX_CHAT_TRIGGERS][STRING_TRIGGERS_MAXLEN];

new String:g_strTeamColors[][] = {"\x07B2B2B2", "\x07B2B2B2", "\x07FF4040", "\x0799CCFF"};

new Float:g_flDiedToxic[MAXPLAYERS+1];
new Float:g_flDiedTimebomb[MAXPLAYERS+1];
new Float:g_flDiedInstant[MAXPLAYERS+1];
new String:g_strClass[][] = {"unknown", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};

new String:g_strSoundScoutBB[][] = {"items/scout_boombox_02.wav", "items/scout_boombox_03.wav", "items/scout_boombox_04.wav", "items/scout_boombox_05.wav"};
new String:g_strSoundHeavyFire[][] = {"vo/heavy_autoonfire01.wav", "vo/heavy_autoonfire02.wav", "vo/heavy_autoonfire03.wav", "vo/heavy_autoonfire04.wav", "vo/heavy_autoonfire05.wav"};
new String:g_strSoundHeavyYell[][] = {"vo/heavy_yell10.wav", "vo/heavy_yell11.wav", "vo/heavy_yell12.wav", "vo/heavy_yell14.wav", "vo/heavy_yell15.wav", "vo/heavy_yell3.wav", "vo/heavy_yell4.wav", "vo/heavy_yell5.wav", "vo/heavy_yell6.wav", "vo/heavy_yell7.wav", "vo/heavy_yell8.wav", "vo/heavy_yell9.wav"};

new g_iOffsetMedigun, g_iOffsetCloak, g_iOffsetSpeed, g_iOffsetClip, g_iOffsetAmmo, g_iOffsetAmmoType, g_iOffsetActive, g_iOffsetDef, g_iOffsetColor, g_iOffsetDecaps, g_iOffsetSniper, g_iOffsetBow, g_iOffsetAirDash, g_iOffsetHeadScale, g_iOffsetModelScale;
new g_iSpriteExplosion, g_iSpriteBeam, g_iSpriteHalo;

new Float:g_flDrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};
new UserMsg:g_FadeUserMsgId;

new Handle:g_hfwdCanRoll;

enum g_eAmmo
{
	g_iWeapon,
	g_iWeaponClip,
	g_iWeaponAmmo
};
new g_nWeaponCache[MAXPLAYERS+1][g_eAmmo];

new bool:g_bHasNextCrit[MAXPLAYERS+1];

enum
{
	ArrayHoming_EntityRef=0,
	ArrayHoming_CurrentTarget
};
#define ARRAY_HOMING_SIZE 2
new Handle:g_hArrayHoming;

new Float:g_iSentryMins[] = {-20.0, -20.0, 0.0};
new Float:g_iSentryMaxs[] = {20.0, 20.0, 66.0};
new Float:g_iDispenserMins[] = {-24.0, -24.0, 0.0};
new Float:g_iDispenserMaxs[] = {24.0, 24.0, 55.0};

new bool:g_bPluginLoaded;

enum eGameMode
{
	GameMode_Other=0,
	GameMode_Arena
};
new eGameMode:g_nGameMode;

#define ArenaRoundState_RoundRunning 7

public Plugin:myinfo = 
{
	name = "TF2: Roll the Dice",
	author = "linux_lover (abkowald@gmail.com)",
	description = "Let's players roll for temporary benefits.",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
};

public OnPluginStart()
{
	g_hArrayHoming = CreateArray(ARRAY_HOMING_SIZE);
	
	if(CannotRunPlugin())
	{
		return;
	}
	
	RunFileChecks();	
	LoadTranslations("rtd.phrases");
	if(!ParseEffects()) return;
	
	g_hCvarVersion = CreateConVar("sm_rtd_version", PLUGIN_VERSION, "Current RTD Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hCvarEnabled = CreateConVar("sm_rtd_enabled", "1", "0/1 - Enable or disable the plugin.");
	g_hCvarTimelimit = CreateConVar("sm_rtd_timelimit", "120", "Seconds before a player can roll again.");
	g_hCvarMode = CreateConVar("sm_rtd_mode", "1", "0 - Roll all the time | 1 - One player can roll at a time | 2 - Team limit mode.");
	g_hCvarDuration = CreateConVar("sm_rtd_duration", "20.0", "Seconds that rtd effects last.");
	g_hCvarTeamlimit = CreateConVar("sm_rtd_teamlimit", "1", "Team limit for mode 2.");
	g_hCvarChance = CreateConVar("sm_rtd_chance", "0.5", "0.0-1.0 - Chance of a good effect.", _, true, 0.0, true, 1.0);
	g_hCvarDistance = CreateConVar("sm_rtd_distance", "275.0", "Death radius for toxic kills.");
	g_hCvarHealth = CreateConVar("sm_rtd_health", "1000", "Amount of health given upon increased health.");
	g_hCvarGravity = CreateConVar("sm_rtd_gravity", "0.1", "Low gravity multiplier.");
	g_hCvarSnail = CreateConVar("sm_rtd_snail", "50.0", "Speed for snail effect.");
	g_hCvarTrigger = CreateConVar("sm_rtd_trigger", "rollthedice,roll", "Chat triggers seperated by commas.");
	g_hCvarAdmin = CreateConVar("sm_rtd_admin", "", "Set the admin flag required for access. (must have all flags 'o' or 'ao')");
	g_hCvarDonator = CreateConVar("sm_rtd_donator", "", "Set the admin flag required for donators. (must have all flags 'o' or 'ao')");
	g_hCvarDonatorChance = CreateConVar("sm_rtd_dchance", "0.8", "Chance for a good effect if you are a donator.");
	g_hCvarTimebombTick = CreateConVar("sm_rtd_timebomb_tick", "10", "Number of timebomb ticks (each a second long).");
	g_hCvarTimebombDamage = CreateConVar("sm_rtd_timebomb_damage", "180", "Health damage to do to enemies when timebomb goes off.");
	g_hCvarTimebombRadius = CreateConVar("sm_rtd_timebomb_radius", "600.0", "Radius for timebomb effect.");
	g_hCvarBlind = CreateConVar("sm_rtd_blind", "255", "Blind amount. Set between 0 - 255.");
	g_hCvarBeaconRadius = CreateConVar("sm_rtd_beacon_radius", "375", "Radius for beacon effect.");
	g_hCvarScary = CreateConVar("sm_rtd_scary", "3.0", "Seconds of stun that scary bullets will deal.");
	g_hCvarSentryLevel = CreateConVar("sm_rtd_sentry_level", "2", "Sentry level to be spawned during the sentry effect.");
	g_hCvarSentryCount = CreateConVar("sm_rtd_sentry_count", "1", "Number of sentries that can be spawned during the sentry effect.");
	g_hCvarSentryKeep = CreateConVar("sm_rtd_sentry_keep", "0", "0/1 - Keep the sentry after the effect is over.");
	g_hCvarFOV = CreateConVar("sm_rtd_fov", "160", "The value to change the FOV to on the funny feeling effect.");
	g_hCvarDispenserLevel = CreateConVar("sm_rtd_dispenser_level", "3", "Dispenser level to spawn for effect.");
	g_hCvarDispenserCount = CreateConVar("sm_rtd_dispenser_count", "1", "Number of dispensers that can be spawned during the dispenser effect.");
	g_hCvarDispenserKeep = CreateConVar("sm_rtd_dispenser_keep", "1", "0/1 - Keep the dispenser after the effect is over.");
	g_hCvarBigHead = CreateConVar("sm_rtd_bighead_scale", "3.0", "Multipler to scale the player's head for the 'big head' perk. 1.0 is regular size.");
	g_hCvarTinyPlayer = CreateConVar("sm_rtd_tinyplayer_scale", "0.1", "Multiple to scale the player model for the 'tiny player' perk. 1.0 is regular size.");
	g_hCvarRespawnStuck = CreateConVar("sm_rtd_respawn_stuck", "1", "0/1 - Respawn if player is stuck after 'noclip' or 'tiny player' perks.");
	g_hCvarHomingSpeed = CreateConVar("sm_rtd_homing_speed", "0.5", "Speed multiplier for homing rockets.");
	g_hCvarHomingReflect = CreateConVar("sm_rtd_homing_reflect", "0.1", "Speed multiplier increase for each reflection.");
	g_hCvarHomingCrits = CreateConVar("sm_rtd_homing_crits", "1", "0/1 - Making homing projectiles crits.");
	g_hCvarDebugEffects = CreateConVar("sm_rtd_debug_effects", "0", "0/1 - Log effects given to players in the regular logs file.");
	
	g_hCvarDisabled = CreateConVar("sm_rtd_disabled", "", "Enter the effects you'd like to disable, seperated by commas.");
	g_hCvarBuddah = CreateConVar("sm_rtd_buddah", "1", "Set to 1 to make godmode give you buddah (takes dmg blast). Set to 0 to give you normal godmode.");
	g_hCvarSetup = CreateConVar("sm_rtd_setup", "1", "0/1 - Enable or disable RTD rolls during setup.");
	
	LookupOffset(g_iOffsetMedigun, "CWeaponMedigun", "m_flChargeLevel");
	LookupOffset(g_iOffsetCloak, "CTFPlayer", "m_flCloakMeter");
	LookupOffset(g_iOffsetSpeed, "CTFPlayer", "m_flMaxspeed");
	LookupOffset(g_iOffsetClip, "CTFWeaponBase", "m_iClip1");
	LookupOffset(g_iOffsetAmmo, "CTFPlayer","m_iAmmo");
	LookupOffset(g_iOffsetAmmoType, "CBaseCombatWeapon", "m_iPrimaryAmmoType");
	LookupOffset(g_iOffsetActive, "CTFPlayer", "m_hActiveWeapon");
	LookupOffset(g_iOffsetDef, "CBaseCombatWeapon", "m_iItemDefinitionIndex");
	LookupOffset(g_iOffsetColor, "CBaseEntity", "m_clrRender");
	LookupOffset(g_iOffsetDecaps, "CTFPlayer", "m_iDecapitations");
	LookupOffset(g_iOffsetSniper, "CTFSniperRifle", "m_flChargedDamage");
	LookupOffset(g_iOffsetBow, "CTFCompoundBow", "m_flChargeBeginTime");
	LookupOffset(g_iOffsetAirDash, "CTFPlayer", "m_iAirDash");
	LookupOffset(g_iOffsetHeadScale, "CTFPlayer", "m_flHeadScale");
	LookupOffset(g_iOffsetModelScale, "CTFPlayer", "m_flModelScale");
	
	HookConVarChange(g_hCvarTrigger, Changed_Trigger);
	HookConVarChange(g_hCvarDisabled, Changed_Disabled);
	
	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");
	AddCommandListener(Listener_Voice, "voicemenu");
	
	RegAdminCmd("sm_forcertd", Command_ForceRTD, ADMFLAG_GENERIC);
	RegAdminCmd("sm_randomrtd", Command_RandomRTD, ADMFLAG_GENERIC);
	RegAdminCmd("sm_rtd_reloadconfigs", Command_Reload, ADMFLAG_ROOT);
	
	CreateTimer(0.3, Timer_Invis, _, TIMER_REPEAT);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundActive);

	g_hfwdCanRoll = CreateGlobalForward("RTD_CanRollDice", ET_Event, Param_Cell);
	
	PrintToServer("TF2: Roll the Dice: v%s loaded!", PLUGIN_VERSION);
	g_bPluginLoaded = true;
	
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	
	AddNormalSoundHook(NormalSoundHook);
	g_FadeUserMsgId = GetUserMessageId("Fade");
}

public OnPluginEnd()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && g_nPlayerData[i][g_nPlayerState] == STATE_ROLLING)
		{
			TerminateEffect(i, g_nPlayerData[i][g_nPlayerPerk], false);
		}
	}
	
	ClearPlayerData();
}

public OnConfigsExecuted()
{
	if(!g_bFirstLoad && g_bPluginLoaded)
	{
		ParseChatTriggers();
		ParseDisabledEffects();
		
		g_bFirstLoad = true;
	}
	
	SetConVarString(g_hCvarVersion, PLUGIN_VERSION);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnMapStart()
{
	ClearPlayerData();
	
	for(new i=1; i<=9; i++)
	{
		decl String:strSound[40];
		
		Format(strSound, sizeof(strSound), "vo/%s_paincrticialdeath01.wav", g_strClass[i]);
		PrecacheSound(strSound);
		
		Format(strSound, sizeof(strSound), "vo/%s_paincrticialdeath02.wav", g_strClass[i]);
		PrecacheSound(strSound);
		
		Format(strSound, sizeof(strSound), "vo/%s_paincrticialdeath03.wav", g_strClass[i]);
		PrecacheSound(strSound);
	}
	
	PrecacheSound(SOUND_SANDVICH);
	PrecacheSound(SOUND_SPEED);
	PrecacheSound(SOUND_CHARGED);
	PrecacheSound(SOUND_CLOAK);
	PrecacheSound(SOUND_EXPLODE);
	PrecacheSound(SOUND_SNAIL);
	PrecacheSound(SOUND_BEEP);
	PrecacheSound(SOUND_FINAL);
	PrecacheSound(SOUND_BOOM);
	PrecacheSound(SOUND_LOW_HEALTH);
	PrecacheSound(SOUND_MELEE);
	PrecacheSound(SOUND_BLIP);
	PrecacheSound(SOUND_NOSTALGIA);
	PrecacheSound(SOUND_EARTHQUAKE);
	PrecacheSound(SOUND_SENTRY);
	PrecacheSound(SOUND_NOPE);
	PrecacheSound(SOUND_STRANGE);
	PrecacheSound(SOUND_DISPENSER);
	PrecacheSound(SOUND_SAUCE);
	PrecacheSound(SOUND_TOXIC);
	PrecacheSound(SOUND_SSENTRY);
	PrecacheSound(SOUND_SDISPENSER);
	PrecacheSound(SOUND_TIMEBOMB);
	PrecacheSound(SOUND_BEACON);
	PrecacheSound(SOUND_GODMODE);
	PrecacheSound(SOUND_WCHARGE);
	PrecacheSound(SOUND_BLIND);
	PrecacheSound(SOUND_INVIS);
	PrecacheSound(SOUND_INFINTE_AMMO);
	PrecacheSound(SOUND_CRITS);
	PrecacheSound(SOUND_DRUGS);
	PrecacheSound(SOUND_HOMING);
	PrecacheSound(SOUND_BIGHEAD);
	PrecacheSound(SOUND_JUMP);
	PrecacheSound(SOUND_TINYPLAYER);
	PrecacheSound(SOUND_NOCLIP);
	PrecacheSound(SOUND_LOW_GRAVITY);
	
	g_iSpriteBeam = PrecacheModel("materials/sprites/laser.vmt");
	g_iSpriteExplosion = PrecacheModel("sprites/sprite_fire01.vmt");
	g_iSpriteHalo = PrecacheModel("materials/sprites/halo01.vmt");
	
	for(new i=0; i<sizeof(g_strSoundHeavyFire); i++)
	{
		PrecacheSound(g_strSoundHeavyFire[i]);
	}
	for(new i=0; i<sizeof(g_strSoundHeavyYell); i++)
	{
		PrecacheSound(g_strSoundHeavyYell[i]);
	}
	for(new i=0; i<sizeof(g_strSoundScoutBB); i++)
	{
		PrecacheSound(g_strSoundScoutBB[i]);
	}
	
	ClearArray(g_hArrayHoming);
	
	g_nGameMode = GameMode_Other;
	if(FindEntityByClassname(MaxClients+1, "tf_logic_arena") > MaxClients)
	{
		g_nGameMode = GameMode_Arena;
	}
}

public OnClientDisconnect(client)
{
	if(g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING)
	{
		PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Disconnected", LANG_SERVER, g_strTeamColors[GetClientTeam(client)], client, 0x01);
	}
	
	ClearPlayerData(client);
	g_flDiedToxic[client] = 0.0;
	g_flDiedTimebomb[client] = 0.0;
	g_flDiedInstant[client] = 0.0;
	g_bHasNextCrit[client] = false;
	ClearWeaponCache(client);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:gameDir[8];
	GetGameFolderName(gameDir, sizeof(gameDir));
	if (!StrEqual(gameDir, "tf"))
	{
		Format(error, err_max, "This plugin only works in TF2.");
		return APLRes_Failure;
	}
	CreateNative("RTD_Roll", Native_Roll);
	
	RegPluginLibrary("TF2: Roll the Dice");
	
	return APLRes_Success;
}

ClearPlayerData(client=0, bool:bResetTime=true)
{
	if(client != 0)
	{
		g_nPlayerData[client][g_nPlayerState] = STATE_IDLE;
		if(bResetTime) g_nPlayerData[client][g_iPlayerLastRoll] = 0;
		g_nPlayerData[client][g_iPlayerTime] = 0;
		KillTimerSafe(g_nPlayerData[client][g_hPlayerExtra]);
		KillTimerSafe(g_nPlayerData[client][g_hPlayerMain]);
		KillEntities(client);
		g_nPlayerData[client][g_nPlayerPerk] = g_eCurrentPerk:0;
		g_nPlayerData[client][g_iPlayerColor] = {0, 0, 0, 0};
	}else{
		for(new i=0; i<MAXPLAYERS+1; i++)
		{
			g_nPlayerData[i][g_nPlayerState] = STATE_IDLE;
			if(bResetTime) g_nPlayerData[i][g_iPlayerLastRoll] = 0;
			g_nPlayerData[i][g_iPlayerTime] = 0;
			KillTimerSafe(g_nPlayerData[i][g_hPlayerExtra]);
			KillTimerSafe(g_nPlayerData[i][g_hPlayerMain]);
			KillEntities(i);
			g_nPlayerData[i][g_nPlayerPerk] = g_eCurrentPerk:0;
			g_nPlayerData[i][g_iPlayerColor] = {0, 0, 0, 0};
		}
	}
}

public Action:Listener_Say(client, const String:command[], argc)
{
	if(!client || client > MaxClients || !IsClientInGame(client)) return Plugin_Continue;
	
	decl String:strChat[100];
	GetCmdArgString(strChat, sizeof(strChat));
	new iStart;
	if(strChat[iStart] == '"') iStart++;
	if(strChat[iStart] == '!') iStart++;
	new iLength = strlen(strChat[iStart]);
	if(strChat[iLength+iStart-1] == '"')
	{
		strChat[iLength--+iStart-1] = '\0';
	}	
	
	if(StrContains(strChat[iStart], "effect") != -1 && iLength <= 7)
	{
		ShowEffectsMenu(client);
	}else if(StrContains(strChat[iStart], "rtd", false) != -1 && iLength <= 3)
	{
		RTD(client);
		return Plugin_Stop;
	}else{
		for(new i=0; i<g_iChatTriggers; i++)
		{
			if(strcmp(strChat[iStart], g_strChatTriggers[i], false) == 0)
			{
				RTD(client);
				return Plugin_Stop;
			}
		}
	}
	
	return Plugin_Continue;
}

ShowEffectsMenu(client, iStartItem=0)
{
	new Handle:hMenu = CreateMenu(MenuHandler_Effects);
	
	SetMenuTitle(hMenu, "%T\n ", "RTD_Effects_Title", LANG_SERVER);
	
	for(new i=0; i<sizeof(g_nPerks); i++)
	{
		if(g_nPerks[i][g_nPerkType] == PERK_GOOD && !g_nPerks[i][g_bPerkDisabled])
		{
			decl String:strInfo[10];
			IntToString(i, strInfo, sizeof(strInfo));
			AddMenuItem(hMenu, strInfo, g_nPerks[i][g_strPerkName]);
		}
	}
	
	AddMenuItem(hMenu, "", " ", ITEMDRAW_SPACER);
	
	for(new i=0; i<sizeof(g_nPerks); i++)
	{
		if(g_nPerks[i][g_nPerkType] == PERK_BAD && !g_nPerks[i][g_bPerkDisabled])
		{
			decl String:strInfo[10];
			IntToString(i, strInfo, sizeof(strInfo));
			AddMenuItem(hMenu, strInfo, g_nPerks[i][g_strPerkName]);
		}
	}

	SetMenuExitBackButton(hMenu, false);
	SetMenuExitButton(hMenu, true);
	
	DisplayMenuAtItem(hMenu, client, iStartItem, MENU_TIME_FOREVER);
}

public MenuHandler_Effects(Handle:hMenu, MenuAction:action, client, menu_item)
{
	if(action == MenuAction_Select)
	{
		decl String:strInfo[10];
		GetMenuItem(hMenu, menu_item, strInfo, sizeof(strInfo));
		new iPerk = StringToInt(strInfo);
		
		if(iPerk >= 0 && iPerk < sizeof(g_nPerks))
		{
			PrintToChat(client, "%s %s%s\x01: %s", PLUGIN_PREFIX, g_nPerks[iPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[iPerk][g_strPerkName], g_nPerks[iPerk][g_strPerkDesc]);
		}
		
		ShowEffectsMenu(client, (menu_item/7)*7);
	}else if(action == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
}

public Changed_Trigger(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	ParseChatTriggers();
}

public Changed_Disabled(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	ParseDisabledEffects();
}

ParseChatTriggers()
{
	g_iChatTriggers = 0;
	
	decl String:strCvar[250];
	GetConVarString(g_hCvarTrigger, strCvar, sizeof(strCvar));
	
	for(new i=0; i<ExplodeString(strCvar, ",", g_strChatTriggers, sizeof(g_strChatTriggers), sizeof(g_strChatTriggers[])); i++)
	{
		LogMessage("Added chat trigger: %s", g_strChatTriggers[i]);
		g_iChatTriggers++;
	}
}

ProcessTranslations()
{
	for(new i=0; i<sizeof(g_nPerks); i++)
	{
		LookupTranslation(g_nPerks[i][g_strPerkName], STRING_PERK_MAXLEN);
		LookupTranslation(g_nPerks[i][g_strPerkDesc], STRING_PERK_MAXLEN);
	}
}

LookupTranslation(String:strTranslation[], maxlength)
{
	if(maxlength < 1 || strncmp(strTranslation, "#", 1) != 0) return;
	
	Format(strTranslation, maxlength, "%T", strTranslation, LANG_SERVER);
}

bool:CannotRunPlugin()
{
	decl String:strGame[10];
	GetGameFolderName(strGame, sizeof(strGame));
	
	if(strcmp(strGame, "tf") != 0)
	{
		SetFailState("This plugin will only run with TF2.");
		return true;
	}
	
	decl String:strPath[150];
	BuildPath(Path_SM, strPath, sizeof(strPath), "translations/rtd.phrases.txt");
	if(!FileExists(strPath))
	{
		SetFailState("Missing \"rtd.phrases.txt\" in the translations/ folder.");
		return true;
	}
	
	return false;
}

bool:CheckAdminFlag(client)
{
	decl String:strCvar[20];
	strCvar[0] = '\0';
	GetConVarString(g_hCvarAdmin, strCvar, sizeof(strCvar));
	
	if(strlen(strCvar) > 0)
	{
		return bool:!(GetUserFlagBits(client) & ReadFlagString(strCvar));
	}
	
	return false;
}

bool:CheckDonateFlag(client)
{
	decl String:strCvar[20];
	strCvar[0] = '\0';
	GetConVarString(g_hCvarDonator, strCvar, sizeof(strCvar));
	
	if(strlen(strCvar) > 0)
	{
		return bool:(GetUserFlagBits(client) & ReadFlagString(strCvar));
	}
	
	return false;
}

RTD(client)
{
	if(!GetConVarInt(g_hCvarEnabled))
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Disabled", LANG_SERVER);
		return;
	}

	if(GetForwardFunctionCount(g_hfwdCanRoll) > 0)
	{
		Call_StartForward(g_hfwdCanRoll);
		Call_PushCell(client);
		new Action:result = Plugin_Continue;
		Call_Finish(result);
		if(result != Plugin_Continue)
		{
			PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Access_Denied", LANG_SERVER);
			return;
		}
	}

	if(!RTD_IsInRound())
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_NotInRound", LANG_SERVER);
		return;
	}
	
	if(CheckAdminFlag(client))
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Access_Denied", LANG_SERVER);
		return;
	}
	
	if(g_nPlayerData[client][g_nPlayerState] != STATE_IDLE)
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_InRoll", LANG_SERVER);
		return;
	}
	
	new iTimeLeft = GetTime() - g_nPlayerData[client][g_iPlayerLastRoll];
	if(g_nPlayerData[client][g_iPlayerLastRoll] && iTimeLeft < GetConVarInt(g_hCvarTimelimit))
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Wait", LANG_SERVER, 0x04, GetConVarInt(g_hCvarTimelimit)-iTimeLeft, 0x01);
		return;
	}
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Alive", LANG_SERVER);
		return;
	}
	
	new iTeam = GetClientTeam(client);
	switch(g_eDiceModes:GetConVarInt(g_hCvarMode))
	{
		case MODE_LEGACY:
		{
			for(new i=1; i<=MaxClients; i++)
			{
				if(g_nPlayerData[i][g_nPlayerState] == STATE_ROLLING)
				{
					PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Busy_Mode1", LANG_SERVER, g_strTeamColors[GetClientTeam(i)], i, 0x01);
					return;
				}
			}
		}
		case MODE_TEAMLIMIT:
		{
			new iCounter;
			for(new i=1; i<=MaxClients; i++)
			{
				if(g_nPlayerData[i][g_nPlayerState] == STATE_ROLLING)
				{
					if(GetClientTeam(i) == iTeam) iCounter++;
				}
			}
			
			if(iCounter >= GetConVarInt(g_hCvarTeamlimit))
			{
				PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Busy_Mode2", LANG_SERVER);
				return;
			}
		}
	}
	
	new Float:flChance = GetConVarFloat(g_hCvarChance);
	if(CheckDonateFlag(client))
	{
		flChance = GetConVarFloat(g_hCvarDonatorChance);
	}
	
	new g_ePerkType:nType = flChance > GetURandomFloat() ? PERK_GOOD : PERK_BAD;
	
	new Handle:hPerks = CreateArray();
	
	for(new i=0; i<sizeof(g_nPerks); i++)
	{
		if(g_nPerks[i][g_bPerkDisabled]) continue;
		
		if(g_nPerks[i][g_nPerkType] == nType && CanBeRolled(client, g_eCurrentPerk:i))
		{
			PushArrayCell(hPerks, i);
		}
	}
	
	new iNumPerks = GetArraySize(hPerks);
	
	if(!iNumPerks)
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_No_Effects", LANG_SERVER);
		return;
	}
	
	new g_eCurrentPerk:nPerk = g_eCurrentPerk:GetArrayCell(hPerks, GetRandomInt(0, iNumPerks-1));
	
	CloseHandle(hPerks);

	InitiateEffect(client, nPerk);
}

bool:RTD_IsInRound()
{
	new RoundState:nRoundState = GameRules_GetRoundState();
	//PrintToServer("Game Mode: %d\nm_bInWaitingForPlayers: %d\nm_bInSetup: %d\nRound: %d", g_nGameMode, GameRules_GetProp("m_bInWaitingForPlayers", 1), GameRules_GetProp("m_bInSetup", 1), nRoundState);
	if(GameRules_GetProp("m_bInWaitingForPlayers", 1) || (!GetConVarBool(g_hCvarSetup) && GameRules_GetProp("m_bInSetup", 1)) || (g_nGameMode == GameMode_Arena && nRoundState != RoundState:ArenaRoundState_RoundRunning) || (g_nGameMode == GameMode_Other && nRoundState != RoundState_RoundRunning && nRoundState != RoundState_Stalemate))
	{
		return false;
	}
	
	return true;
}

bool:CanBeRolled(client, g_eCurrentPerk:nPerk)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	switch(nPerk)
	{
		case PERK_UBER:
		{
			new iWeapon = GetPlayerWeaponSlot(client, SLOT_SECONDARY);
			if(iWeapon > MaxClients && IsValidEntity(iWeapon))
			{
				decl String:strClass[20];
				GetEdictClassname(iWeapon, strClass, sizeof(strClass));
				if(strcmp(strClass, "tf_weapon_medigun") == 0)
				{
					return true;
				}
			}
			
			return false;
			
		}
		case PERK_CLOAK: if(class != TFClass_Spy) return false;
		case PERK_SPEED: if(class == TFClass_Scout) return false;
		case PERK_HOMING:
		{
			new String:strPrimary[40];
			new String:strSecondary[40];
			new iPrimary = GetPlayerWeaponSlot(client, SLOT_PRIMARY);
			new iSecondary = GetPlayerWeaponSlot(client, SLOT_SECONDARY);
			if(iPrimary > MaxClients && IsValidEntity(iPrimary)) GetEdictClassname(iPrimary, strPrimary, sizeof(strPrimary));
			if(iSecondary > MaxClients && IsValidEntity(iSecondary)) GetEdictClassname(iSecondary, strSecondary, sizeof(strSecondary));
			
			if(strcmp(strPrimary, "tf_weapon_rocketlauncher") == 0 || strcmp(strPrimary, "tf_weapon_rocketlauncher_directhit") == 0 ||
				strcmp(strPrimary, "tf_weapon_compound_bow") == 0 || strcmp(strSecondary, "tf_weapon_flaregun") == 0)
			{
				if(iPrimary > MaxClients && GetItemDefinition(iPrimary) == ITEM_ROCKET_JUMPER) return false;
				
				return true;
			}
			
			return false;
		}
		case PERK_CHARGE:
		{
			new iPrimary = GetPlayerWeaponSlot(client, SLOT_PRIMARY);
			if(iPrimary > MaxClients && IsValidEntity(iPrimary))
			{
				decl String:strPrimary[40];
				GetEdictClassname(iPrimary, strPrimary, sizeof(strPrimary));
				if(strcmp(strPrimary, "tf_weapon_sniperrifle") == 0 || strcmp(strPrimary, "tf_weapon_sniperrifle_decap") == 0 || strcmp(strPrimary, "tf_weapon_compound_bow") == 0)
				{
					return true;
				}
			}
			
			return false;
		}
		case PERK_JUMP: if(class != TFClass_Scout) return false;
	}
	
	return true;
}

InitiateEffect(client, g_eCurrentPerk:nPerk)
{
	ClearPlayerData(client);

	g_nPlayerData[client][g_iPlayerLastRoll] = GetTime();
	g_nPlayerData[client][g_nPlayerState] = STATE_ROLLING;
	g_nPlayerData[client][g_nPlayerPerk] = nPerk;
	
	new Float:flDuration = GetConVarFloat(g_hCvarDuration);
	if(g_nPerks[nPerk][g_flPerkTime] > 0.0) flDuration = g_nPerks[nPerk][g_flPerkTime];
	
	g_nPlayerData[client][g_iPlayerTime] = RoundToFloor(flDuration);
	
	if(GetConVarBool(g_hCvarDebugEffects))
	{
		LogMessage("Perk launched on %N: \"%s\" (id:%d) for %0.1fs.", client, g_nPerks[nPerk][g_strPerkName], _:nPerk, flDuration);
	}
	
	new iTeam = GetClientTeam(client);
	switch(nPerk)
	{
		case PERK_GODMODE:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToClient(client, SOUND_GODMODE);
			
			SetGodmode(client, true);
			ColorizePlayer(client, COLOR_BLACK);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);
		}
		case PERK_TOXIC:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToClient(client, SOUND_TOXIC);
			
			AddEntityToClient(client, AttachParticle(client, "eb_aura_angry01", _, 5.0));
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(0.5, Timer_Toxic, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);
			
		}
		case PERK_BUFFED_HEALTH:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			g_bHasNextCrit[client] = true;
			
			EmitSoundToAll(SOUND_SANDVICH, client);
			new iHealth = GetClientHealth(client) + GetConVarInt(g_hCvarHealth);
			SetEntityHealth(client, iHealth);
			PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Health", LANG_SERVER, COLOR_PERK_ORANGE, iHealth, 0x01);
			
			AttachParticle(client, iTeam == _:TFTeam_Blue ? "medic_megaheal_blue_shower" : "medic_megaheal_red_shower", "head", _, 5.0);
			
			g_nPlayerData[client][g_nPlayerState] = STATE_IDLE;
		}
		case PERK_SPEED:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToAll(SOUND_SPEED, client);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, flDuration);
			
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);
		}
		case PERK_NOCLIP:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToClient(client, SOUND_NOCLIP);
			SetEntityMoveType(client, MOVETYPE_NOCLIP);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);			
		}
		case PERK_LOW_GRAVITY:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToClient(client, SOUND_LOW_GRAVITY);
			SetEntityGravity(client, GetConVarFloat(g_hCvarGravity));
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);				
		}
		case PERK_UBER:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToAll(SOUND_CHARGED, client);
			
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);			
		}
		case PERK_INVIS:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToClient(client, SOUND_INVIS);
			
			ColorizePlayer(client, COLOR_INVIS);
			SetSentryTarget(client, false);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);
		}
		case PERK_CLOAK:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToAll(SOUND_CLOAK, client);
			
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);				
		}
		case PERK_CRITS:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToClient(client, SOUND_CRITS);
			
			TF2_AddCondition(client, TFCond_CritOnFirstBlood, flDuration);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);			
		}
		case PERK_INFINITE_AMMO:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToClient(client, SOUND_INFINTE_AMMO);
			
			ClearWeaponCache(client);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);			
		}
		case PERK_SCARY_BULLETS:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			AddEntityToClient(client, AttachParticle(client, "ghost_glow", _, 30.0));
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);
		}
		case PERK_SENTRY, PERK_DISPENSER:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			PrintToChat(client, "%s %s", PLUGIN_PREFIX, g_nPerks[_:nPerk][g_strPerkDesc]);
			
			g_nPlayerData[client][g_nPlayerPerk] == PERK_SENTRY ? EmitSoundToClient(client, SOUND_SSENTRY) : EmitSoundToClient(client, SOUND_SDISPENSER);
			
			g_nPlayerData[client][g_iPlayerTime] = 0;
			
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);			
		}		
		case PERK_HOMING:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToClient(client, SOUND_HOMING);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);		
		}
		case PERK_CHARGE:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToClient(client, SOUND_WCHARGE);
			
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);			
		}
		case PERK_EXPLODE:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			EmitSoundToAll(SOUND_EXPLODE, client);
			
			AttachParticle(client, "bombinomicon_burningdebris", _, 2.0, 5.0);
			g_nPlayerData[client][g_nPlayerState] = STATE_IDLE;
			
			FakeClientCommand(client, "explode");
		}
		case PERK_SNAIL:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);
			
			EmitSoundToAll(SOUND_SNAIL, client);			
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);			
		}
		case PERK_FREEZE:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);		
			
			SetEntityMoveType(client, MOVETYPE_NONE);
			ColorizePlayer(client, COLOR_INVIS);
			
			new iRagDoll = CreateRagdoll(client);
			if(iRagDoll > MaxClients && IsValidEntity(iRagDoll))
			{
				AddEntityToClient(client, iRagDoll);
				SetClientViewEntity(client, iRagDoll);
				SetThirdPerson(client, true);
			}
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);
		}
		case PERK_TIMEBOMB:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			EmitSoundToClient(client, SOUND_TIMEBOMB);
			
			g_nPlayerData[client][g_iPlayerTime] = GetConVarInt(g_hCvarTimebombTick);
			
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(1.0, Timer_Timebomb, client, TIMER_REPEAT);			
		}
		case PERK_IGNITE:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			EmitSoundToAll(g_strSoundHeavyFire[GetRandomIntBetween(0, sizeof(g_strSoundHeavyFire)-1)], client);
			TF2_IgnitePlayer(client, client);
			
			AttachParticle(client, "cinefx_goldrush_flames", "head", 0.0, 2.0);
			
			g_nPlayerData[client][g_nPlayerState] = STATE_IDLE;			
		}
		case PERK_LOW_HEALTH:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			EmitSoundToAll(SOUND_LOW_HEALTH, client);
			SetEntityHealth(client, 1);
			
			AttachParticle(client, iTeam == _:TFTeam_Red ? "healthlost_red" : "healthlost_blu", "head", 0.0, 5.0);
			
			g_nPlayerData[client][g_nPlayerState] = STATE_IDLE;			
		}
		case PERK_DRUG:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			EmitSoundToClient(client, SOUND_DRUGS);
			
			g_nPlayerData[client][g_iPlayerTime] = GetConVarInt(g_hCvarTimebombTick);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Drug, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);
		}
		case PERK_BLIND:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			EmitSoundToClient(client, SOUND_BLIND);
			
			BlindPlayer(client, GetConVarInt(g_hCvarBlind));
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);			
		}
		case PERK_MELEE:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			EmitSoundToAll(SOUND_MELEE, client);
			StripWeapons(client);
			
			g_nPlayerData[client][g_nPlayerState] = STATE_IDLE;		
		}
		case PERK_BEACON:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			EmitSoundToClient(client, SOUND_BEACON);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Beacon, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);			
		}
		case PERK_TAUNT:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(0.5, Timer_Taunt, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);	
		}
		case PERK_NOSTALGIA:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);		
			
			EmitSoundToClient(client, SOUND_NOSTALGIA);
			SetClientOverlay(client, "debug/yuv");
			
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);				
		}
		case PERK_EARTHQUAKE:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);		
			
			EmitSoundToAll(SOUND_EARTHQUAKE, client);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(0.25, Timer_EarthQuake, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);
		}
		case PERK_FUNNY_FEELING:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);		
			
			SetClientFOV(client, GetConVarInt(g_hCvarFOV));
			EmitSoundToClient(client, SOUND_STRANGE);
			
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);			
		}
		case PERK_SAUCE:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			EmitSoundToAll(SOUND_SAUCE, client);
			
			TF2_AddCondition(client, TFCond_Milked, flDuration);
			TF2_AddCondition(client, TFCond_Jarated, flDuration);
			TF2_MakeBleed(client, client, 5.0);			
			
			g_nPlayerData[client][g_nPlayerState] = STATE_IDLE;				
		}
		case PERK_JUMP:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			EmitSoundToClient(client, SOUND_JUMP);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);				
		}
		case PERK_INSTANT_KILLS:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01);
			
			EmitSoundToClient(client, g_strSoundHeavyYell[GetRandomIntBetween(0, sizeof(g_strSoundHeavyYell)-1)]);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);				
		}
		case PERK_BIG_HEAD:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);		
			
			EmitSoundToClient(client, SOUND_BIGHEAD);
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);				
		}
		case PERK_TINY_PLAYER:
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_Time", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, g_nPerks[_:nPerk][g_nPerkType] == PERK_GOOD ? COLOR_PERK_GOOD : COLOR_PERK_BAD, g_nPerks[_:nPerk][g_strPerkName], 0x01, "\x04", RoundToFloor(flDuration), 0x01);		
			
			EmitSoundToClient(client, SOUND_TINYPLAYER);
			
			ResizePlayer(client, GetConVarFloat(g_hCvarTinyPlayer));
			
			g_nPlayerData[client][g_hPlayerExtra] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			g_nPlayerData[client][g_hPlayerMain] = CreateTimer(flDuration, Timer_EffectEnd, client, TIMER_REPEAT);				
		}
	}
}

TerminateEffect(client, g_eCurrentPerk:nPerk, bool:bIsAlive=true)
{
	ClearPlayerData(client);
	
	//new iTeam = GetClientTeam(client);
	switch(nPerk)
	{
		case PERK_GODMODE:
		{
			SetGodmode(client, false);
			ColorizePlayer(client, COLOR_NORMAL);
			
			PrintCenterText(client, " ");
		}
		case PERK_NOCLIP:
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			
			PrintCenterText(client, " ");
			
			if(bIsAlive && IsEntityStuck(client))
			{
				PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Stuck", LANG_SERVER);
				TF2_RespawnPlayer(client);
			}
		}
		case PERK_LOW_GRAVITY:
		{
			SetEntityGravity(client, 1.0);
			
			PrintCenterText(client, " ");
		}
		case PERK_INVIS:
		{
			ColorizePlayer(client, COLOR_NORMAL);
			SetSentryTarget(client, true);
			
			PrintCenterText(client, " ");
		}
		case PERK_CRITS:
		{
			PrintCenterText(client, " ");
		}
		case PERK_INFINITE_AMMO:
		{
			PrintCenterText(client, " ");
		}
		case PERK_SCARY_BULLETS:
		{
			PrintCenterText(client, " ");
		}
		case PERK_HOMING:
		{
			PrintCenterText(client, " ");
		}
		case PERK_SNAIL:
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
			
			PrintCenterText(client, " ");
		}
		case PERK_FREEZE:
		{
			SetClientViewEntity(client, client);
			
			SetEntityMoveType(client, MOVETYPE_WALK);
			ColorizePlayer(client, COLOR_NORMAL);
			SetThirdPerson(client, false);
			
			PrintCenterText(client, " ");
		}
		case PERK_TIMEBOMB:
		{
			SetEntityRenderMode(client, RENDER_NORMAL);
			SetEntityRenderColor(client);
		}
		case PERK_DRUG:
		{
			new Float:flPos[3];
			GetClientAbsOrigin(client, flPos);
			
			new Float:flAng[3];
			GetClientEyeAngles(client, flAng);
			
			flAng[2] = 0.0;
			
			TeleportEntity(client, flPos, flAng, NULL_VECTOR);
			
			new iClients[2];
			iClients[0] = client;
			
			new Handle:message = StartMessageEx(g_FadeUserMsgId, iClients, 1);
			BfWriteShort(message, 1536);
			BfWriteShort(message, 1536);
			BfWriteShort(message, (0x0001 | 0x0010));
			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
			EndMessage();
		}
		case PERK_BLIND:
		{
			BlindPlayer(client, 0);
			
			PrintCenterText(client, " ");
		}
		case PERK_NOSTALGIA:
		{
			SetClientOverlay(client, "");
		}
		case PERK_FUNNY_FEELING:
		{
			SetClientFOV(client, GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
		}
		case PERK_JUMP:
		{
			PrintCenterText(client, " ");
		}
		case PERK_INSTANT_KILLS:
		{
			PrintCenterText(client, " ");
		}
		case PERK_BIG_HEAD:
		{
			PrintCenterText(client, " ");
		}
		case PERK_TINY_PLAYER:
		{
			PrintCenterText(client, " ");
			ResizePlayer(client, 1.0);
			
			if(bIsAlive && IsPlayerAlive(client))
			{
				CreateTimer(0.1, Timer_CheckStuck, GetClientUserId(client));
			}
		}
	}
	
	g_nPlayerData[client][g_iPlayerColor] = {0, 0, 0, 0};
	g_nPlayerData[client][g_iPlayerLastRoll] = GetTime();	
}

public Action:Timer_CheckStuck(Handle:hTimer, any:iUserId)
{
	new client = GetClientOfUserId(iUserId);
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && IsEntityStuck(client))
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Stuck", LANG_SERVER);
		TF2_RespawnPlayer(client);
	}
}

public Action:Timer_Toxic(Handle:hTimer, any:client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING && g_nPlayerData[client][g_nPlayerPerk] == PERK_TOXIC)
	{
		new Float:flPos1[3];
		GetClientAbsOrigin(client, flPos1);
		new iTeam = GetClientTeam(client);
		
		for(new i=1; i<=MaxClients; i++)
		{
			if(i != client && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != iTeam)
			{
				if(!TF2_IsPlayerInCondition(i, TFCond_Ubercharged) && !HasGodmode(i))
				{
					new Float:flPos2[3];
					GetClientAbsOrigin(i, flPos2);
					
					new Float:flDistance = GetVectorDistance(flPos1, flPos2);
					if(flDistance < GetConVarFloat(g_hCvarDistance))
					{
						g_flDiedToxic[i] = GetEngineTime();
						SDKHooks_TakeDamage(i, 0, client, 900.0, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH|DMG_ALWAYSGIB);
					}
				}
			}
		}
		
		return Plugin_Continue;
	}
	
	g_nPlayerData[client][g_hPlayerExtra] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_Countdown(Handle:hTimer, any:client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING && g_nPlayerData[client][g_iPlayerTime])
	{
		g_nPlayerData[client][g_iPlayerTime]--;
		PrintCenterText(client, "%d", g_nPlayerData[client][g_iPlayerTime]);
		
		return Plugin_Continue;
	}
	
	g_nPlayerData[client][g_hPlayerExtra] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_EffectEnd(Handle:hTimer, any:client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING)
	{
		TerminateEffect(client, g_nPlayerData[client][g_nPlayerPerk]);
		
		PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_End", LANG_SERVER, g_strTeamColors[GetClientTeam(client)], client, 0x01);
	}
	
	g_nPlayerData[client][g_hPlayerMain] = INVALID_HANDLE;
	return Plugin_Stop;	
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	if(GetEventInt(hEvent, "death_flags") & TF_DEATHFLAG_DEADRINGER) return Plugin_Continue;
	
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iVictim >= 1 && iVictim <= MaxClients && IsClientInGame(iVictim))
	{
		if(iAttacker >= 1 && iAttacker <= MaxClients && IsClientInGame(iAttacker))
		{
			if(g_flDiedToxic[iVictim] != 0.0)
			{
				if(GetEngineTime() - g_flDiedToxic[iVictim] <= 0.1) // 0.02246
				{			
					new iDamageBits = GetEventInt(hEvent, "damagebits");
					SetEventInt(hEvent, "damagebits",  iDamageBits |= DMG_CRIT);
					SetEventString(hEvent, "weapon_logclassname", "rtd_toxic");
					SetEventString(hEvent, "weapon", "tf_pumpkin_bomb");
					SetEventInt(hEvent, "customkill", TF_CUSTOM_PUMPKIN_BOMB);
					SetEventInt(hEvent, "playerpenetratecount", 0);
					g_flDiedToxic[iVictim] = 0.0;
					
					decl String:strSound[40];
					Format(strSound, sizeof(strSound), "vo/%s_paincrticialdeath0%d.wav", g_strClass[TF2_GetPlayerClass(iVictim)], GetRandomIntBetween(1, 3));
					EmitSoundToAll(strSound, iVictim);
					
					return Plugin_Continue;
				}
				g_flDiedToxic[iVictim] = 0.0;
			}else if(g_flDiedTimebomb[iVictim] != 0.0)
			{
				if(GetEngineTime() - g_flDiedTimebomb[iVictim] <= 0.1) // 0.02246
				{
					new iDamageBits = GetEventInt(hEvent, "damagebits");
					SetEventInt(hEvent, "damagebits",  iDamageBits |= DMG_CRIT);
					SetEventString(hEvent, "weapon_logclassname", "rtd_timebomb");
					SetEventString(hEvent, "weapon", "taunt_soldier");
					SetEventInt(hEvent, "customkill", TF_CUSTOM_TAUNT_GRENADE);
					SetEventInt(hEvent, "playerpenetratecount", 0);
					g_flDiedTimebomb[iVictim] = 0.0;
					
					return Plugin_Continue;
				}
				g_flDiedTimebomb[iVictim] = 0.0;
			}else if(g_flDiedInstant[iVictim] != 0.0)
			{
				if(GetEngineTime() - g_flDiedInstant[iVictim] <= 0.1) // 0.02246
				{
					new iDamageBits = GetEventInt(hEvent, "damagebits");
					SetEventInt(hEvent, "damagebits",  iDamageBits |= DMG_CRIT);
					SetEventString(hEvent, "weapon_logclassname", "rtd_instant_kills");
					SetEventString(hEvent, "weapon", "purgatory");
					SetEventInt(hEvent, "customkill", 0);
					SetEventInt(hEvent, "playerpenetratecount", 0);
					g_flDiedInstant[iVictim] = 0.0;
					
					EmitSoundToAll(g_strSoundHeavyYell[GetRandomIntBetween(0, sizeof(g_strSoundHeavyYell)-1)], iAttacker); 
					
					return Plugin_Continue;				
				}
				g_flDiedInstant[iVictim] = 0.0;
			}
		}
		
		if(g_nPlayerData[iVictim][g_nPlayerState] == STATE_IDLE) return Plugin_Continue;
		
		TerminateEffect(iVictim, g_nPlayerData[iVictim][g_nPlayerPerk], false);
		
		PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Died", LANG_SERVER, g_strTeamColors[GetClientTeam(iVictim)], iVictim, 0x01);
	}
	
	return Plugin_Continue;
}

KillTimerSafe(&Handle:hTimer)
{
	if(hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}

AddEntityToClient(client, iEntity)
{
	if(iEntity > MaxClients)
	{
		if(g_nPlayerData[client][g_hPlayerEntities] == INVALID_HANDLE)
		{
			g_nPlayerData[client][g_hPlayerEntities] = CreateArray();
		}
		
		PushArrayCell(g_nPlayerData[client][g_hPlayerEntities], EntIndexToEntRef(iEntity));
	}
}

KillEntities(client)
{
	new Handle:hArray = g_nPlayerData[client][g_hPlayerEntities];
	if(hArray != INVALID_HANDLE)
	{
		for(new i=0; i<GetArraySize(hArray); i++)
		{
			new iRef = GetArrayCell(hArray, i);
			if(iRef != 0)
			{
				new iEntity = EntRefToEntIndex(iRef);
				if(iEntity > MaxClients && IsValidEntity(iEntity))
				{
					AcceptEntityInput(iEntity, "Kill");
				}
			}
		}
		CloseHandle(hArray);
	}
	g_nPlayerData[client][g_hPlayerEntities] = INVALID_HANDLE;
}

AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flOffsetZ=0.0, Float:flSelfDestruct=0.0)
{
	new iParticle = CreateEntityByName("info_particle_system");
	if(iParticle > MaxClients && IsValidEntity(iParticle))
	{
		new Float:flPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += flOffsetZ;
		
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
		DispatchSpawn(iParticle);
		
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iEntity);
		ActivateEntity(iParticle);
		
		if(strlen(strAttachPoint))
		{
			SetVariantString(strAttachPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset");
		}
		
		AcceptEntityInput(iParticle, "start");
		
		if(flSelfDestruct > 0.0) CreateTimer(flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iParticle));
		
		return iParticle;
	}
	
	return 0;
}

public Action:Timer_DeleteParticle(Handle:hTimer, any:iRefEnt)
{
	new iEntity = EntRefToEntIndex(iRefEnt);
	if(iEntity > MaxClients)
	{
		AcceptEntityInput(iEntity, "Kill");
	}
	
	return Plugin_Handled;
}

stock SetGodmode(client, bool:bEnabled)
{
	new iGodmode = GetConVarInt(g_hCvarBuddah) ? 1 : 0;
	return SetEntProp(client, Prop_Data, "m_takedamage", bEnabled ? iGodmode : 2, 1);
}

stock bool:HasGodmode(client)
{
	return GetEntProp(client, Prop_Data, "m_takedamage") != 2;
}

stock ColorizePlayer(client, iColor[4])
{
	g_nPlayerData[client][g_iPlayerColor] = iColor;
	
	SetEntityColor(client, iColor);
	
	for(new i=0; i<3; i++)
	{
		new iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			SetEntityColor(iWeapon, iColor);
		}
	}
	
	decl String:strClass[20];
	for(new i=MaxClients+1; i<GetMaxEntities(); i++)
	{
		if(IsValidEntity(i))
		{
			GetEdictClassname(i, strClass, sizeof(strClass));
			if((strncmp(strClass, "tf_wearable", 11) == 0 || strncmp(strClass, "tf_powerup", 10) == 0) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityColor(i, iColor);
			}
		}
	}

	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
	if(iWeapon > MaxClients && IsValidEntity(iWeapon))
	{
		SetEntityColor(iWeapon, iColor);
	}
	
	// Player is recognized as invisible
	if(iColor[3] == 0)
	{
		if(GetDecaps(client) > 0 && TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
		{
			TF2_RemoveCondition(client, TFCond_DemoBuff);
		}
	}else{
		if(GetDecaps(client) > 0 && !TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
		{
			TF2_AddCondition(client, TFCond_DemoBuff, 1000.0);
		}
	}
}

public Action:Timer_Invis(Handle:hTimer, any:junk)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsColorSet(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			new iColor[4];
			for(new c=0; c<4; c++) iColor[c] = g_nPlayerData[i][g_iPlayerColor][c];
			ColorizePlayer(i, iColor);
		}
	}
	
	return Plugin_Continue;
}

bool:IsColorSet(client)
{
	if(g_nPlayerData[client][g_iPlayerColor][0] == 0 && g_nPlayerData[client][g_iPlayerColor][1] == 0 && g_nPlayerData[client][g_iPlayerColor][2] == 0 && g_nPlayerData[client][g_iPlayerColor][3] == 0)
	{
		return false;
	}
	
	return true;
}

stock SetEntityColor(iEntity, iColor[4])
{
	SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iEntity, iColor[0], iColor[1], iColor[2], iColor[3]);
}

stock GetRandomIntBetween(iStart, iEnd)
{
	if(iStart == iEnd) return iStart;
	
	new iModifier;
	if(iStart == 0)
	{
		iStart += 1;
		iEnd += 1;
		
		iModifier = -1;
	}
	
	return (GetURandomInt() % iEnd) + iStart + iModifier;
}

bool:IsEntityStuck(iEntity)
{
	if(!GetConVarBool(g_hCvarRespawnStuck)) return false;
	
	new Float:flOrigin[3];
	new Float:flMins[3];
	new Float:flMaxs[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flOrigin);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", flMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", flMaxs);
	
	TR_TraceHullFilter(flOrigin, flOrigin, flMins, flMaxs, MASK_SOLID, TraceFilterNotSelf, iEntity);
	return TR_DidHit();
}

public bool:TraceFilterNotSelf(entity, contentsMask, any:client)
{
	if(entity == client)
	{
		return false;
	}
	
	return true;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(g_nPlayerData[client][g_nPlayerState] != STATE_ROLLING) return Plugin_Continue;
	
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{		
		switch(g_nPlayerData[client][g_nPlayerPerk])
		{
			case PERK_UBER:
			{
				new iWeapon = GetPlayerWeaponSlot(client, SLOT_SECONDARY);
				if(iWeapon > MaxClients && IsValidEntity(iWeapon))
				{
					decl String:strClass[20];
					GetEdictClassname(iWeapon, strClass, sizeof(strClass));
					if(strcmp(strClass, "tf_weapon_medigun") == 0)
					{
						SetEntDataFloat(iWeapon, g_iOffsetMedigun, 1.0, true);
					}
				}
			}
			case PERK_CLOAK:
			{
				SetEntDataFloat(client, g_iOffsetCloak, 100.0);
			}
			case PERK_INFINITE_AMMO:
			{
				new iWeapon = GetActiveWeapon(client);
				if(iWeapon > MaxClients)
				{
					SetMetalAmount(client, 200);
					
					new iWeaponDef = GetItemDefinition(iWeapon);
					if(iWeaponDef == ITEM_MANGLER || iWeaponDef == ITEM_BISON || iWeaponDef == ITEM_POMSON)
					{
						SetEntPropFloat(iWeapon, Prop_Send, "m_flEnergy", 20.0);
					}
					
					if(g_nWeaponCache[client][g_iWeapon] != iWeapon)
					{
						g_nWeaponCache[client][g_iWeapon] = iWeapon;
						
						g_nWeaponCache[client][g_iWeaponClip] = GetWeaponClip(iWeapon);
						g_nWeaponCache[client][g_iWeaponAmmo] = GetWeaponAmmo(client, iWeapon);
					}else{
						new iClip = GetWeaponClip(iWeapon);
						if(iClip != -1)
						{
							if(iClip > g_nWeaponCache[client][g_iWeaponClip])
							{
								g_nWeaponCache[client][g_iWeaponClip] = iClip;
							}else if(iClip < g_nWeaponCache[client][g_iWeaponClip])
							{
								SetWeaponClip(iWeapon, g_nWeaponCache[client][g_iWeaponClip]);
							}
						}
						
						new iAmmo = GetWeaponAmmo(client, iWeapon);
						if(iAmmo != -1)
						{
							if(iAmmo > g_nWeaponCache[client][g_iWeaponAmmo])
							{
								g_nWeaponCache[client][g_iWeaponAmmo] = iAmmo;
							}else if(iAmmo < g_nWeaponCache[client][g_iWeaponAmmo])
							{
								SetWeaponAmmo(client, iWeapon, g_nWeaponCache[client][g_iWeaponAmmo]);
							}
						}
					}
				}
				
				if(TF2_GetPlayerClass(client) == TFClass_Engineer)
				{
					SetEntData(client, g_iOffsetAmmo+(4*3), 200, 4, true);
				}
				
				SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", 100.0);
			}
			case PERK_CHARGE:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Slowed))
				{
					new iPrimary = GetPlayerWeaponSlot(client, SLOT_PRIMARY);
					if(iPrimary > MaxClients)
					{
						decl String:strPrimary[40];
						GetEdictClassname(iPrimary, strPrimary, sizeof(strPrimary));
						if(strcmp(strPrimary, "tf_weapon_sniperrifle") == 0)
						{
							SetEntDataFloat(iPrimary, g_iOffsetSniper, 150.0, true);
						}else if(strcmp(strPrimary, "tf_weapon_compound_bow") == 0)
						{
							SetEntDataFloat(iPrimary, g_iOffsetBow, GetGameTime()-1.0, true);
						}
					}
				}
			}
			case PERK_SNAIL:
			{
				SetEntDataFloat(client, g_iOffsetSpeed, GetConVarFloat(g_hCvarSnail));
			}
			case PERK_FREEZE:
			{
				if(buttons & IN_ATTACK)
				{
					buttons &= ~IN_ATTACK;
					return Plugin_Changed;
				}
			}
			case PERK_JUMP:
			{
				SetEntData(client, g_iOffsetAirDash, 0);
			}
			case PERK_BIG_HEAD:
			{
				SetEntDataFloat(client, g_iOffsetHeadScale, GetConVarFloat(g_hCvarBigHead));
			}
		}
	}
	
	return Plugin_Continue;
}

ResizePlayer(client, Float:flMult)
{
	SetEntDataFloat(client, g_iOffsetModelScale, flMult);
}

GetDecaps(client)
{
	return GetEntData(client, g_iOffsetDecaps);
}

SetSentryTarget(client, bool:bTarget)
{
	new iFlags = GetEntityFlags(client);	
	if(bTarget)
	{
		SetEntityFlags(client, iFlags &~ FL_NOTARGET);
	}else{
		SetEntityFlags(client, iFlags | FL_NOTARGET);
	}
}

CreateRagdoll(client, Float:flSelfDestruct=0.0)
{
	new iRag = CreateEntityByName("tf_ragdoll");
	if(iRag > MaxClients && IsValidEntity(iRag))
	{
		new Float:flPos[3];
		new Float:flAng[3];
		new Float:flVel[3];
		GetClientAbsOrigin(client, flPos);
		GetClientAbsAngles(client, flAng);
		
		TeleportEntity(iRag, flPos, flAng, flVel);
		
		SetEntProp(iRag, Prop_Send, "m_iPlayerIndex", client);
		SetEntProp(iRag, Prop_Send, "m_bIceRagdoll", 1);
		SetEntProp(iRag, Prop_Send, "m_iTeam", GetClientTeam(client));
		SetEntProp(iRag, Prop_Send, "m_iClass", _:TF2_GetPlayerClass(client));
		SetEntProp(iRag, Prop_Send, "m_bOnGround", 1);
		
		SetEntityMoveType(iRag, MOVETYPE_NONE);
		
		DispatchSpawn(iRag);
		ActivateEntity(iRag);
		
		
		if(flSelfDestruct > 0.0) CreateTimer(flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iRag));
		
		return iRag;
	}
	
	return 0;
}

public Action:Timer_Timebomb(Handle:hTimer, any:client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING && g_nPlayerData[client][g_nPlayerPerk] == PERK_TIMEBOMB)
	{
		g_nPlayerData[client][g_iPlayerTime]--;
		
		if(g_nPlayerData[client][g_iPlayerTime] > 0)
		{
			new iColor;
			if(g_nPlayerData[client][g_iPlayerTime] > 1)
			{
				iColor = RoundToFloor(g_nPlayerData[client][g_iPlayerTime] * (128.0 / GetConVarInt(g_hCvarTimebombTick)));
				EmitSoundToAll(SOUND_BEEP, client);
			}else{
				EmitSoundToAll(SOUND_FINAL, client);
			}
			
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, 255, 128, iColor, 255);
			
			PrintCenterTextAll("%T", "RTD_Timebomb", LANG_SERVER, g_nPlayerData[client][g_iPlayerTime], client);
			
			new Float:flPos[3];
			GetClientAbsOrigin(client, flPos);
			flPos[2] += 10.0;
			
			TE_SetupBeamRingPoint(flPos, 10.0, GetConVarFloat(g_hCvarTimebombRadius) / 3.0, g_iSpriteBeam, g_iSpriteHalo, 0, 15, 0.5, 5.0, 0.0, COLOR_GREY, 10, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(flPos, 10.0, GetConVarFloat(g_hCvarTimebombRadius) / 3.0, g_iSpriteBeam, g_iSpriteHalo, 0, 10, 0.6, 10.0, 0.5, COLOR_WHITE, 10, 0);
			TE_SendToAll();
			
			return Plugin_Continue;
		}else{
			new Float:flPos[3];
			GetClientEyePosition(client, flPos);
			
			if(g_iSpriteExplosion > -1)
			{
				TE_SetupExplosion(flPos, g_iSpriteExplosion, 5.0, 1, 0, GetConVarInt(g_hCvarTimebombRadius), 5000);
				TE_SendToAll();				
			}
			
			EmitSoundToAll(SOUND_BOOM, client);
			AttachParticle(client, "bomibomicon_ring", _, 10.0, 5.0);
			
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client);
			
			new iTeam = GetClientTeam(client);
			new Float:flPos1[3];
			GetClientAbsOrigin(client, flPos1);
			
			new iPlayerDamage;
			for(new i=1; i<=MaxClients; i++)
			{
				if(i != client && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != iTeam)
				{
					if(!TF2_IsPlayerInCondition(i, TFCond_Ubercharged) && !HasGodmode(i))
					{
						new Float:flPos2[3];
						GetClientAbsOrigin(i, flPos2);
						
						if(GetVectorDistance(flPos1, flPos2) <= GetConVarFloat(g_hCvarTimebombRadius))
						{
							new iDamage = GetConVarInt(g_hCvarTimebombDamage);
							iPlayerDamage += iDamage; 
							if(GetClientHealth(i) - iDamage <= 0)
							{
								AttachParticle(i, "ExplosionCore_Wall", _, 30.0, 5.0);
							}							
							
							g_flDiedTimebomb[i] = GetEngineTime();
							SDKHooks_TakeDamage(i, 0, client, GetConVarFloat(g_hCvarTimebombDamage), DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH|DMG_ALWAYSGIB);
						}
					}
				}
			}
			
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Timebomb_Result", LANG_SERVER, g_strTeamColors[iTeam], client, 0x01, COLOR_PERK_ORANGE, iPlayerDamage, 0x01);
			
			g_nPlayerData[client][g_hPlayerMain] = INVALID_HANDLE;
			TerminateEffect(client, PERK_TIMEBOMB, false);
			
			ForcePlayerSuicide(client);
		}
	}
	
	g_nPlayerData[client][g_hPlayerMain] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_Drug(Handle:hTimer, any:client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING && g_nPlayerData[client][g_nPlayerPerk] == PERK_DRUG)
	{
		new Float:flPos[3];
		GetClientAbsOrigin(client, flPos);
		
		new Float:flAng[3];
		GetClientAbsAngles(client, flAng);
		
		flAng[2] = g_flDrugAngles[GetRandomIntBetween(0, 100) % 20];
		
		TeleportEntity(client, flPos, flAng, NULL_VECTOR);
		
		new iClients[2];
		iClients[0] = client;
		
		new Handle:message = StartMessageEx(g_FadeUserMsgId, iClients, 1);
		BfWriteShort(message, 255);
		BfWriteShort(message, 255);
		BfWriteShort(message, (0x0002));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, 128);
		
		EndMessage();
		
		return Plugin_Continue;
	}
	
	g_nPlayerData[client][g_hPlayerExtra] = INVALID_HANDLE;
	return Plugin_Stop;	
}

BlindPlayer(client, iAmount)
{
	new iTargets[2];
	iTargets[0] = client;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, iTargets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if(iAmount == 0)
	{
		BfWriteShort(message, (0x0001 | 0x0010));
	}else{
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, iAmount);
	
	EndMessage();
}

StripWeapons(client)
{
	TF2_RemoveWeaponSlot(client, SLOT_PRIMARY);
	TF2_RemoveWeaponSlot(client, SLOT_SECONDARY);
	
	new iWeapon = GetPlayerWeaponSlot(client, SLOT_MELEE);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon))
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
	}
}

public Action:Timer_Beacon(Handle:hTimer, any:client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING && g_nPlayerData[client][g_nPlayerPerk] == PERK_BEACON)
	{
		new iTeam = GetClientTeam(iTeam);
		
		new Float:flPos[3];
		GetClientAbsOrigin(client, flPos);
		flPos[2] += 10.0;
		
		TE_SetupBeamRingPoint(flPos, 10.0, GetConVarFloat(g_hCvarBeaconRadius), g_iSpriteBeam, g_iSpriteHalo, 0, 15, 0.5, 5.0, 0.0, COLOR_GREY, 10, 0);
		TE_SendToAll();
		
		if(iTeam == _:TFTeam_Red)
		{
			TE_SetupBeamRingPoint(flPos, 10.0, GetConVarFloat(g_hCvarBeaconRadius), g_iSpriteBeam, g_iSpriteHalo, 0, 10, 0.6, 10.0, 0.5, COLOR_RED, 10, 0);
		}else{
			TE_SetupBeamRingPoint(flPos, 10.0, GetConVarFloat(g_hCvarBeaconRadius), g_iSpriteBeam, g_iSpriteHalo, 0, 10, 0.6, 10.0, 0.5, COLOR_BLUE, 10, 0);
		}
		TE_SendToAll();
		
		EmitSoundToAll(SOUND_BLIP, client);
		
		return Plugin_Continue;
	}
	
	g_nPlayerData[client][g_hPlayerExtra] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_Taunt(Handle:hTimer, any:client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING && g_nPlayerData[client][g_nPlayerPerk] == PERK_TAUNT)
	{
		FakeClientCommand(client, "+taunt");
		
		return Plugin_Continue;
	}
	
	g_nPlayerData[client][g_hPlayerExtra] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Event_PlayerSpawn(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_bHasNextCrit[client] = false;
		
		if(g_nPlayerData[client][g_nPlayerState] != STATE_ROLLING) return;
		
		TerminateEffect(client, g_nPlayerData[client][g_nPlayerPerk], false);
		
		
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Respawn", LANG_SERVER, g_strTeamColors[GetClientTeam(client)], client, 0x01);
	}
}

public Action:Command_ForceRTD(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] sm_forcertd \"targetname/#userid\" perk_id");
		return Plugin_Handled;
	}
	
	new String:strTarget[32];
	GetCmdArg(1, strTarget, sizeof(strTarget));
	
	new String:strKey[40];
	GetCmdArg(2, strKey, sizeof(strKey));
	new iOverride = -1;
	if(strlen(strKey))
	{
		new iIndex = -1;
		if(IsCharNumeric(strKey[0]))
		{
			iIndex = StringToInt(strKey);
		}else{
			for(new i=0; i<sizeof(g_nPerks); i++)
			{
				if(!g_nPerks[i][g_bPerkDisabled] && strcmp(strKey, g_nPerks[i][g_strPerkKey], false) == 0)
				{
					iIndex = i;
					break;
				}
			}
		}
		
		if(iIndex > -1 && iIndex < MAX_RTD_EFFECTS)
		{
			iOverride = iIndex;
			ReplyToCommand(client, "%s Perk forced: %s", PLUGIN_PREFIX, g_nPerks[iIndex][g_strPerkName]);
		}
	}
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	
	if((target_count = ProcessTargetString(
			strTarget,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToCommand(client, "%s %T", PLUGIN_PREFIX, "RTD_NoTargets", LANG_SERVER);
		return Plugin_Handled;
	}
	
	for(new i=0; i<target_count; i++)
	{
		ShowActivity2(client, "[RTD] ", "Forced perk on %N.", target_list[i]);
		ForceRTD(client, target_list[i], true, g_eCurrentPerk:iOverride);
	}
	
	return Plugin_Handled;
}

public Action:Command_RandomRTD(client, args)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		new Handle:hPlayers = CreateArray();
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && ForceRTD(client, i, false))
			{
				PushArrayCell(hPlayers, i);
			}
		}
		
		new iNumPlayers = GetArraySize(hPlayers);
		if(!iNumPlayers)
		{
			CloseHandle(hPlayers);
			ReplyToCommand(client, "%s %T", PLUGIN_PREFIX, "RTD_NoTargets", LANG_SERVER);
			return Plugin_Handled;
		}
		
		new iRandomPlayer = GetArrayCell(hPlayers, GetRandomInt(0, iNumPlayers-1));
		CloseHandle(hPlayers);
		
		ForceRTD(client, iRandomPlayer);
	}
	
	return Plugin_Handled;
}

public Event_RoundStart(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	ClearArray(g_hArrayHoming);
	ClearPlayerData(_, false);
}

public Event_RoundActive(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	if(GetConVarBool(g_hCvarEnabled) && RTD_IsInRound())
	{
		switch(GetRandomIntBetween(1, 2))
		{
			case 1: PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Advert1", LANG_SERVER, COLOR_PERK_ORANGE, 0x01);
			case 2: PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Advert1", LANG_SERVER, COLOR_PERK_ORANGE, 0x01);
		}
	}
}

bool:ForceRTD(client, iVictim, bool:bLaunchEffect=true, g_eCurrentPerk:nPerkOverride=g_eCurrentPerk:-1)
{
	if(!RTD_IsInRound())
	{
		if(bLaunchEffect) PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_NotInRound", LANG_SERVER);
		return false;
	}
	
	if(g_nPlayerData[iVictim][g_nPlayerState] != STATE_IDLE)
	{
		if(bLaunchEffect) PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_InRoll", LANG_SERVER);
		return false;
	}
	
	if(!IsPlayerAlive(iVictim))
	{
		if(bLaunchEffect) PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Alive", LANG_SERVER);
		return false;
	}
	
	new Float:flChance = GetConVarFloat(g_hCvarChance);
	if(CheckDonateFlag(iVictim))
	{
		flChance = GetConVarFloat(g_hCvarDonatorChance);
	}
	
	new g_ePerkType:nType = flChance > GetURandomFloat() ? PERK_GOOD : PERK_BAD;
	
	new Handle:hPerks = CreateArray();
	
	for(new i=0; i<sizeof(g_nPerks); i++)
	{
		if(g_nPerks[i][g_bPerkDisabled]) continue;
		
		if(g_nPerks[i][g_nPerkType] == nType && CanBeRolled(iVictim, g_eCurrentPerk:i))
		{
			PushArrayCell(hPerks, i);
		}
	}
	
	new iNumPerks = GetArraySize(hPerks);
	
	if(!iNumPerks)
	{
		if(bLaunchEffect) PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_No_Effects", LANG_SERVER);
		return false;
	}

	new g_eCurrentPerk:nPerk = g_eCurrentPerk:GetArrayCell(hPerks, GetRandomInt(0, iNumPerks-1));
	
	CloseHandle(hPerks);
	
	if(!bLaunchEffect) return true;
	if(_:nPerkOverride > -1 && _:nPerkOverride < MAX_RTD_EFFECTS) nPerk = nPerkOverride;
	
	InitiateEffect(iVictim, nPerk);
	return true;
}

public Native_Roll(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new iPerk = GetNativeCell(2);
	
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		ForceRTD(client, client, _, g_eCurrentPerk:iPerk);
	}
	
	ThrowNativeError(SP_ERROR_PARAM, "Invalid client, must be in game and alive.");
	return false;
}

GetWeaponClip(iWeapon)
{
	return GetEntData(iWeapon, g_iOffsetClip);
}

SetWeaponClip(iWeapon, iAmount)
{
	return SetEntData(iWeapon, g_iOffsetClip, iAmount, _, true);
}

GetWeaponAmmo(client, iWeapon)
{
	new iAmmoType = GetEntData(iWeapon, g_iOffsetAmmoType, 1);
	// Prevent infinite ammo with lunchbox and sandman weapons
	if(iAmmoType == 4) return -1;
	
	return GetEntData(client, g_iOffsetAmmo + iAmmoType * 4);
}

SetWeaponAmmo(client, iWeapon, iAmount)
{
	return SetEntData(client, g_iOffsetAmmo + GetEntData(iWeapon, g_iOffsetAmmoType, 1) * 4, iAmount);
}

GetActiveWeapon(client)
{
	return GetEntDataEnt2(client, g_iOffsetActive);
}

GetItemDefinition(iWeapon)
{
	return GetEntData(iWeapon, g_iOffsetDef);
}

ClearWeaponCache(client)
{
	g_nWeaponCache[client][g_iWeapon] = 0;
	g_nWeaponCache[client][g_iWeaponClip] = 0;
	g_nWeaponCache[client][g_iWeaponAmmo] = 0;
}

LookupOffset(&iOffset, const String:strClass[], const String:strProp[])
{
	iOffset = FindSendPropInfo(strClass, strProp);
	if(iOffset <= 0)
	{
		SetFailState("Could not locate offset for %s::%s!", strClass, strProp);
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	// Tried to use this forward as limited as possible. The two functions below for Lucky Sandvich and Homing Rockets
	// are not necessary so if tf_weapon_criticals is set to 0, you lose minor functionality.
	if(g_bHasNextCrit[client])
	{
		result = true;
		g_bHasNextCrit[client] = false;
		
		return Plugin_Changed;
	}

	if(g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING && g_nPlayerData[client][g_nPlayerPerk] == PERK_HOMING && GetConVarBool(g_hCvarHomingCrits))
	{
		if(strcmp(weaponname, "tf_weapon_rocketlauncher") == 0 || strcmp(weaponname, "tf_weapon_rocketlauncher_directhit") == 0 ||
			strcmp(weaponname, "tf_weapon_compound_bow") == 0 || strcmp(weaponname, "tf_weapon_flaregun") == 0 ||
			strcmp(weaponname, "tf_weapon_crossbow") == 0 || strcmp(weaponname, "tf_weapon_flaregun_revenge") == 0)
		{
			result = true;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

SetClientOverlay(client, String:strOverlay[])
{
	new iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", iFlags);
	
	ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay);
}

EarthQuakeEffect(client)
{
	new iFlags = GetCommandFlags("shake") & (~FCVAR_CHEAT);
	SetCommandFlags("shake", iFlags);

	FakeClientCommand(client, "shake");
	
	iFlags = GetCommandFlags("shake") | (FCVAR_CHEAT);
	SetCommandFlags("shake", iFlags);
}

public Action:Timer_EarthQuake(Handle:hTimer, any:client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING && g_nPlayerData[client][g_nPlayerPerk] == PERK_EARTHQUAKE)
	{
		EarthQuakeEffect(client);
		
		return Plugin_Continue;
	}
	
	g_nPlayerData[client][g_hPlayerExtra] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Event_PlayerHurt(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iVictim != iAttacker && iVictim >= 1 && iVictim <= MaxClients && IsClientInGame(iVictim) && iAttacker >= 1 && iAttacker <= MaxClients && IsClientInGame(iAttacker))
	{
		if(g_nPlayerData[iAttacker][g_nPlayerState] == STATE_ROLLING)
		{
			switch(g_nPlayerData[iAttacker][g_nPlayerPerk])
			{
				case PERK_SCARY_BULLETS:
				{
					if(IsPlayerAlive(iVictim) && GetEventInt(hEvent, "health") > 0 && !TF2_IsPlayerInCondition(iVictim, TFCond_Dazed))
					{
						TF2_StunPlayer(iVictim, GetConVarFloat(g_hCvarScary), _, TF_STUNFLAGS_GHOSTSCARE);
					}
				}
			}
		}
	}
}

public Action:Listener_Voice(client, const String:command[], argc)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		if(g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING && (g_nPlayerData[client][g_nPlayerPerk] == PERK_SENTRY || g_nPlayerData[client][g_nPlayerPerk] == PERK_DISPENSER))
		{
			new iMax = (g_nPlayerData[client][g_nPlayerPerk] == PERK_SENTRY) ? GetConVarInt(g_hCvarSentryCount) : GetConVarInt(g_hCvarDispenserCount);
			if(g_nPlayerData[client][g_iPlayerTime] < iMax)
			{
				new Float:flPos[3];
				new Float:flAng[3];
				GetClientEyePosition(client, flPos);
				GetClientEyeAngles(client, flAng);
				new Handle:hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, client);
				if(hTrace != INVALID_HANDLE && TR_DidHit(hTrace))
				{
					new Float:flEndPos[3];
					TR_GetEndPosition(flEndPos, hTrace);
					flEndPos[2] += 5.0;
					
					new Float:flMins[3];
					new Float:flMaxs[3];
					if(g_nPlayerData[client][g_nPlayerPerk] == PERK_SENTRY)
					{
						flMins = g_iSentryMins;
						flMaxs = g_iSentryMaxs;
					}else{
						flMins = g_iDispenserMins;
						flMaxs = g_iDispenserMaxs;
					}
					if(CanBuildHere(flEndPos, flMins, flMaxs))
					{
						GetClientAbsAngles(client, flAng);
						
						EmitSoundToAll(g_nPlayerData[client][g_nPlayerPerk] == PERK_SENTRY ? SOUND_SENTRY : SOUND_DISPENSER, client);
						new iBuilding = (g_nPlayerData[client][g_nPlayerPerk] == PERK_SENTRY) ? BuildSentry(client, flEndPos, flAng, GetConVarInt(g_hCvarSentryLevel)) : BuildDispenser(client, flEndPos, flAng, GetConVarInt(g_hCvarDispenserLevel));
						if(iBuilding > MaxClients && IsValidEntity(iBuilding))
						{
							if((g_nPlayerData[client][g_nPlayerPerk] == PERK_SENTRY && !GetConVarBool(g_hCvarSentryKeep)) ||
								(g_nPlayerData[client][g_nPlayerPerk] == PERK_DISPENSER && !GetConVarBool(g_hCvarDispenserKeep))) AddEntityToClient(client, iBuilding);
							
							AttachParticle(iBuilding, "ping_circle", _, 2.0, 2.0);
						}
						
						g_nPlayerData[client][g_iPlayerTime]++;
						new iLimit = g_nPlayerData[client][g_nPlayerPerk] == PERK_SENTRY ? GetConVarInt(g_hCvarSentryCount) : GetConVarInt(g_hCvarDispenserCount);
						PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Building_Limit", LANG_SERVER, g_nPlayerData[client][g_iPlayerTime], iLimit);
						
						if(((g_nPlayerData[client][g_nPlayerPerk] == PERK_DISPENSER && GetConVarBool(g_hCvarDispenserKeep)) || (g_nPlayerData[client][g_nPlayerPerk] == PERK_SENTRY && GetConVarBool(g_hCvarSentryKeep))) && g_nPlayerData[client][g_iPlayerTime] == iLimit)
						{
							TerminateEffect(client, g_nPlayerData[client][g_nPlayerPerk]);
							PrintToChatAll("%s %T", PLUGIN_PREFIX, "RTD_Effect_End", LANG_SERVER, g_strTeamColors[GetClientTeam(client)], client, 0x01);							
						}
						
						CloseHandle(hTrace);
						return Plugin_Handled;
					}
					
					CloseHandle(hTrace);
				}
				
				PrintToChat(client, "%s %T", PLUGIN_PREFIX, "RTD_Building_Placement", LANG_SERVER);
				EmitSoundToClient(client, SOUND_NOPE);
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

bool:CanBuildHere(Float:flPos[3], Float:flMins[3], Float:flMaxs[3])
{
	TR_TraceHull(flPos, flPos, flMins, flMaxs, MASK_SOLID);
	return !TR_DidHit();
}

public bool:TraceFilterIgnorePlayers(entity, contentsMask, any:client)
{
	if(entity >= 1 && entity <= MaxClients)
	{
		return false;
	}
	
	return true;
}

BuildDispenser(iBuilder, Float:flOrigin[3], Float:flAngles[3], iLevel=1)
{
	new String:strModel[100];
	
	new iTeam = GetClientTeam(iBuilder);
	new iHealth;
	new iAmmo = 400;
	if(iLevel == 2)
	{
		strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl2.mdl");
		iHealth = 180;
	}else if(iLevel == 3)
	{
		strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl3.mdl");
		iHealth = 216;
	}else{
		// Assume level 1
		strcopy(strModel, sizeof(strModel), "models/buildables/dispenser.mdl");
		iHealth = 150;		
	}
	
	new iDispenser = CreateEntityByName("obj_dispenser");
	if(iDispenser > MaxClients && IsValidEntity(iDispenser))
	{
		DispatchSpawn(iDispenser);
		
		TeleportEntity(iDispenser, flOrigin, flAngles, NULL_VECTOR);
		
		SetEntityModel(iDispenser, strModel);
		
		SetVariantInt(iTeam);
		AcceptEntityInput(iDispenser, "TeamNum");
		SetVariantInt(iTeam);
		AcceptEntityInput(iDispenser, "SetTeam");
		
		ActivateEntity(iDispenser);
		
		SetEntProp(iDispenser, Prop_Send, "m_iAmmoMetal", iAmmo);
		SetEntProp(iDispenser, Prop_Send, "m_iHealth", iHealth);
		SetEntProp(iDispenser, Prop_Send, "m_iMaxHealth", iHealth);
		SetEntProp(iDispenser, Prop_Send, "m_iObjectType", _:TFObject_Dispenser);
		SetEntProp(iDispenser, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(iDispenser, Prop_Send, "m_nSkin", iTeam-2);
		SetEntProp(iDispenser, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
		SetEntPropFloat(iDispenser, Prop_Send, "m_flPercentageConstructed", 1.0);
		SetEntPropVector(iDispenser, Prop_Send, "m_vecBuildMaxs", g_iDispenserMaxs);
		SetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder", iBuilder);		
		
		return iDispenser;
	}
	
	return 0;	
}

BuildSentry(iBuilder, Float:flOrigin[3], Float:flAngles[3], iLevel=1)
{
	new String:strModel[100];
	
	new iTeam = GetClientTeam(iBuilder);
	new iShells, iHealth;
	new iRockets = 20;
	if(iLevel == 2)
	{
		strcopy(strModel, sizeof(strModel), "models/buildables/sentry2.mdl");
		iShells = 200;
		iHealth = 180;
	}else if(iLevel == 3)
	{
		strcopy(strModel, sizeof(strModel), "models/buildables/sentry3.mdl");
		iShells = 200;
		iHealth = 216;
	}else{
		// Assume level 1
		strcopy(strModel, sizeof(strModel), "models/buildables/sentry1.mdl");
		iShells = 150;
		iHealth = 150;
	}
	
	new iSentry = CreateEntityByName("obj_sentrygun");
	if(iSentry > MaxClients && IsValidEntity(iSentry))
	{
		DispatchSpawn(iSentry);
		
		TeleportEntity(iSentry, flOrigin, flAngles, NULL_VECTOR);
		
		SetEntityModel(iSentry, strModel);
		
		SetEntProp(iSentry, Prop_Send, "m_iAmmoShells", iShells);
		SetEntProp(iSentry, Prop_Send, "m_iHealth", iHealth);
		SetEntProp(iSentry, Prop_Send, "m_iMaxHealth", iHealth);
		SetEntProp(iSentry, Prop_Send, "m_iObjectType", _:TFObject_Sentry);
		SetEntProp(iSentry, Prop_Send, "m_iState", 1);
		
		SetEntProp(iSentry, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(iSentry, Prop_Send, "m_nSkin", iTeam-2);
		SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel", iLevel);
		SetEntProp(iSentry, Prop_Send, "m_iAmmoRockets", iRockets);
		
		SetEntPropEnt(iSentry, Prop_Send, "m_hBuilder", iBuilder);
		
		SetEntPropFloat(iSentry, Prop_Send, "m_flPercentageConstructed", 1.0);
		
		SetEntPropVector(iSentry, Prop_Send, "m_vecBuildMaxs", g_iSentryMaxs);
		
		return iSentry;
	}
	
	return 0;
}

public OnEntityCreated(entity, const String:classname[])
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(g_nPlayerData[i][g_nPlayerState] == STATE_ROLLING && g_nPlayerData[i][g_nPlayerPerk] == PERK_HOMING && IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(strcmp(classname, "tf_projectile_rocket") == 0 || strcmp(classname, "tf_projectile_arrow") == 0 ||
				strcmp(classname, "tf_projectile_flare") == 0 || strcmp(classname, "tf_projectile_energy_ball") == 0 ||
				strcmp(classname, "tf_projectile_healing_bolt") == 0)
			{
				CreateTimer(0.2, Timer_CheckOwnership, EntIndexToEntRef(entity));
			}
			
			return;
		}
	}
}

public Action:Timer_CheckOwnership(Handle:hTimer, any:iRef)
{
	new iProjectile = EntRefToEntIndex(iRef);
	if(iProjectile > MaxClients && IsValidEntity(iProjectile))
	{
		new iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
		if(iLauncher >= 1 && iLauncher <= MaxClients && g_nPlayerData[iLauncher][g_nPlayerState] == STATE_ROLLING && g_nPlayerData[iLauncher][g_nPlayerPerk] == PERK_HOMING && IsClientInGame(iLauncher) && IsPlayerAlive(iLauncher))
		{
			// Check to make sure the projectile isn't already being homed
			if(GetEntProp(iProjectile, Prop_Send, "m_nForceBone") != 0) return Plugin_Handled;	
			SetEntProp(iProjectile, Prop_Send, "m_nForceBone", 1);
			
			new iData[ARRAY_HOMING_SIZE];
			iData[ArrayHoming_EntityRef] = EntIndexToEntRef(iProjectile);
			PushArrayArray(g_hArrayHoming, iData);
		}
	}
	
	return Plugin_Handled;
}

public OnGameFrame()
{
	// Using this method instead of SDKHooks because the Think functions are not called consistently for all projectiles
	for(new i=GetArraySize(g_hArrayHoming)-1; i>=0; i--)
	{
		new iData[ARRAY_HOMING_SIZE];
		GetArrayArray(g_hArrayHoming, i, iData);
		
		if(iData[ArrayHoming_EntityRef] == 0)
		{
			RemoveFromArray(g_hArrayHoming, i);
			continue;
		}
		
		new iProjectile = EntRefToEntIndex(iData[ArrayHoming_EntityRef]);
		if(iProjectile > MaxClients)
		{
			HomingProjectile_Think(iProjectile, iData[ArrayHoming_EntityRef], i, iData[ArrayHoming_CurrentTarget]);
		}else{
			RemoveFromArray(g_hArrayHoming, i);
		}
	}
}

public HomingProjectile_Think(iProjectile, iRefProjectile, iArrayIndex, iCurrentTarget)
{
	new iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	
	if(!HomingProjectile_IsValidTarget(iCurrentTarget, iProjectile, iTeam))
	{
		HomingProjectile_FindTarget(iProjectile, iRefProjectile, iArrayIndex);
	}else{
		HomingProjectile_TurnToTarget(iCurrentTarget, iProjectile);
	}
}

bool:HomingProjectile_IsValidTarget(client, iProjectile, iTeam)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != iTeam)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked)) return false;
		
		if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
		{
			return false;
		}
		
		new Float:flStart[3];
		GetClientEyePosition(client, flStart);
		new Float:flEnd[3];
		GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flEnd);
		
		new Handle:hTrace = TR_TraceRayFilterEx(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceFilterHoming, iProjectile);
		if(hTrace != INVALID_HANDLE)
		{
			if(TR_DidHit(hTrace))
			{
				CloseHandle(hTrace);
				return false;
			}
			
			CloseHandle(hTrace);
			return true;
		}
	}
	
	return false;
}

public bool:TraceFilterHoming(entity, contentsMask, any:iProjectile)
{
	if(entity == iProjectile || (entity >= 1 && entity <= MaxClients))
	{
		return false;
	}
	
	return true;
}

HomingProjectile_FindTarget(iProjectile, iRefProjectile, iArrayIndex)
{
	new iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	new Float:flPos1[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flPos1);
	
	new iBestTarget;
	new Float:flBestLength = 99999.9;
	for(new i=1; i<=MaxClients; i++)
	{
		if(HomingProjectile_IsValidTarget(i, iProjectile, iTeam))
		{
			new Float:flPos2[3];
			GetClientEyePosition(i, flPos2);
			
			new Float:flDistance = GetVectorDistance(flPos1, flPos2);
			
			//if(flDistance < 70.0) continue;
			
			if(flDistance < flBestLength)
			{
				iBestTarget = i;
				flBestLength = flDistance;
			}
		}
	}
	
	if(iBestTarget >= 1 && iBestTarget <= MaxClients)
	{
		new iData[ARRAY_HOMING_SIZE];
		iData[ArrayHoming_EntityRef] = iRefProjectile;
		iData[ArrayHoming_CurrentTarget] = iBestTarget;
		SetArrayArray(g_hArrayHoming, iArrayIndex, iData);
		
		HomingProjectile_TurnToTarget(iBestTarget, iProjectile);
	}else{
		new iData[ARRAY_HOMING_SIZE];
		iData[ArrayHoming_EntityRef] = iRefProjectile;
		iData[ArrayHoming_CurrentTarget] = 0;
		SetArrayArray(g_hArrayHoming, iArrayIndex, iData);
	}
}

HomingProjectile_TurnToTarget(client, iProjectile)
{
	new Float:flTargetPos[3];
	GetClientAbsOrigin(client, flTargetPos);
	new Float:flRocketPos[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flRocketPos);

	new Float:flInitialVelocity[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", flInitialVelocity);
	new Float:flSpeedInit = GetVectorLength(flInitialVelocity);
	new Float:flSpeedBase = flSpeedInit * GetConVarFloat(g_hCvarHomingSpeed);
	
	//flTargetPos[2] += 50.0;
	flTargetPos[2] += 30 + Pow(GetVectorDistance(flTargetPos, flRocketPos), 2.0) / 10000;
	
	new Float:flNewVec[3];
	SubtractVectors(flTargetPos, flRocketPos, flNewVec);
	NormalizeVector(flNewVec, flNewVec);
	
	new Float:flAng[3];
	GetVectorAngles(flNewVec, flAng);

	new Float:flSpeedNew = flSpeedBase + GetEntProp(iProjectile, Prop_Send, "m_iDeflected") * flSpeedBase * GetConVarFloat(g_hCvarHomingReflect);
	
	ScaleVector(flNewVec, flSpeedNew);
	TeleportEntity(iProjectile, NULL_VECTOR, flAng, flNewVec);
}

SetClientFOV(client, iAmount)
{
	SetEntProp(client, Prop_Send, "m_iFOV", iAmount);
}

bool:ParseEffects()
{
	new String:strPath[192];
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/rtd_effects.cfg");
	
	if(!FileExists(strPath))
	{
		SetFailState("Failed to find rtd_effects.cfg in configs/ folder!");
		return false;
	}
	
	new Handle:hKv = CreateKeyValues("Effects");
	if(FileToKeyValues(hKv, strPath) && KvGotoFirstSubKey(hKv))
	{
		new iPerksGood, iPerksBad;
		decl String:strSection[15];
		do
		{
			KvGetSectionName(hKv, strSection, sizeof(strSection));
			new iPerkIndex = StringToInt(strSection);
			if(iPerkIndex < 0 || iPerkIndex >= sizeof(g_nPerks))
			{
				LogMessage("Perk index: \"%s\" is not valid. Must be between 0 - %d. Edit the plugin & recompile to increase limits.", strSection, sizeof(g_nPerks));
				continue;
			}
			
			KvGetString(hKv, "name", g_nPerks[iPerkIndex][g_strPerkName], STRING_PERK_MAXLEN);
			KvGetString(hKv, "description", g_nPerks[iPerkIndex][g_strPerkDesc], STRING_PERK_MAXLEN);
			KvGetString(hKv, "key", g_nPerks[iPerkIndex][g_strPerkKey], STRING_PERK_MAXLEN);
			
			decl String:strBuffer[STRING_PERK_MAXLEN];
			KvGetString(hKv, "type", strBuffer, sizeof(strBuffer));
			if(strcmp(strBuffer, "bad", false) == 0)
			{
				iPerksBad++;
				g_nPerks[iPerkIndex][g_nPerkType] = PERK_BAD;
			}else{
				iPerksGood++;
				g_nPerks[iPerkIndex][g_nPerkType] = PERK_GOOD;
			}
			
			KvGetString(hKv, "customtime", strBuffer, sizeof(strBuffer));
			new Float:flTime = StringToFloat(strBuffer);
			if(flTime > 0.0)
			{
				g_nPerks[iPerkIndex][g_flPerkTime] = flTime;
			}else{
				g_nPerks[iPerkIndex][g_flPerkTime] = 0.0;
			}
		}while(KvGotoNextKey(hKv));
		
		if(hKv != INVALID_HANDLE) CloseHandle(hKv);
		LogMessage("Loaded %d effects: (%d good) (%d bad).", iPerksGood+iPerksBad, iPerksGood, iPerksBad);
		ProcessTranslations();	
		
		return true;
	}
	
	if(hKv != INVALID_HANDLE) CloseHandle(hKv);
	return false;
}

public Action:Command_Reload(client, args)
{
	ParseEffects();
	
	return Plugin_Handled;
}

ParseDisabledEffects()
{
	decl String:strDisabled[255];
	GetConVarString(g_hCvarDisabled, strDisabled, sizeof(strDisabled));
	
	for(new i=0; i<sizeof(g_nPerks); i++)
	{
		g_nPerks[i][g_bPerkDisabled] = false;
		
		if(StrContains(strDisabled, g_nPerks[i][g_strPerkKey], false) != -1)
		{
			g_nPerks[i][g_bPerkDisabled] = true;
			
			LogMessage("Perk disabled: %s.", g_nPerks[i][g_strPerkName]);
		}
	}
}

RunFileChecks()
{
	decl String:strPath[255];
	BuildPath(Path_SM, strPath, sizeof(strPath), "translations/rtd.phrases.txt");
	if(FileExists(strPath))
	{
		LogMessage("File test for rtd.phrases.txt: PASSED!");
	}else{
		LogMessage("File test for rtd.phrases.txt: FAILED. You are missing this file!");
	}
	
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/rtd_effects.cfg");
	if(FileExists(strPath))
	{
		LogMessage("File test for rtd_effects.cfg: PASSED!");
	}else{
		LogMessage("File test for rtd_effects.cfg: FAILED. You are missing this file!");
	}	
}

SetThirdPerson(client, bool:bEnabled)
{
	if(bEnabled)
	{
		SetVariantInt(1);
	}else{
		SetVariantInt(0);
	}
	
	AcceptEntityInput(client, "SetForcedTauntCam");
}

SetMetalAmount(client, iMetal)
{
	return SetEntData(client, g_iOffsetAmmo+(4*3), iMetal);  
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(attacker >= 1 && attacker <= MaxClients && victim >= 1 && victim <= MaxClients && IsClientInGame(victim) && attacker != victim && IsClientInGame(attacker) && IsPlayerAlive(attacker))
	{
		if(g_nPlayerData[attacker][g_nPlayerState] == STATE_ROLLING)
		{
			switch(g_nPlayerData[attacker][g_nPlayerPerk])
			{
				case PERK_INSTANT_KILLS:
				{
					damage = 900.0;
					g_flDiedInstant[victim] = GetEngineTime();
					return Plugin_Changed;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:NormalSoundHook(clients[64], &numClients, String:sSample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(channel == SNDCHAN_VOICE && entity >= 1 && entity <= MaxClients && g_nPlayerData[entity][g_nPlayerState] == STATE_ROLLING)
	{
		switch(g_nPlayerData[entity][g_nPlayerPerk])
		{
			case PERK_BIG_HEAD:
			{
				pitch = 60;
				flags |= SND_CHANGEPITCH;
				return Plugin_Changed;
			}
			case PERK_TINY_PLAYER:
			{
				pitch = 150;
				flags |= SND_CHANGEPITCH;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(g_nPlayerData[client][g_nPlayerState] == STATE_ROLLING)
	{
		switch(g_nPlayerData[client][g_nPlayerPerk])
		{
			case PERK_TAUNT:
			{
				if(condition == TFCond_Taunting)
				{
					EmitSoundToAll(g_strSoundScoutBB[GetRandomIntBetween(0, sizeof(g_strSoundScoutBB)-1)], client);
				}
			}
		}
	}
}
