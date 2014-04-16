#if defined _freak_fortress_2_included
  #endinput
#endif
#pragma semicolon 1
#define _freak_fortress_2_included
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <morecolors>
#undef REQUIRE_PLUGIN
//#tryinclude <tf2attributes>
#tryinclude <rtd>
#tryinclude <Amplifier>
//#tryinclude <friendly> //Got to suggest to friendly plugin maker for better forwards.
#tryinclude <goomba>
//#tryinclude <nativevotes>
#tryinclude <smac>
#tryinclude <updater>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#define MAX_SUBPLUGIN_NAME 256

enum FF2_SubPluginFlags
{
	FF2_SubPluginFlags_None=0,
	FF2_SubPluginFlags_UnloadNormal=(1<<1),
	FF2_SubPluginFlags_UnloadMapEnd=(1<<2),
	FF2_SubPluginFlags_StartMapStart=(1<<3),
	FF2_SubPluginFlags_StartRoundStart=(1<<4),
	FF2_SubPluginFlags_Normal=FF2_SubPluginFlags_UnloadNormal|FF2_SubPluginFlags_StartRoundStart,
};

enum FF2_SubReason
{
	FF2_SubReason_None=0, //This will be returned if all goes right.
	FF2_SubReason_NotCoded, //This will be returned until native is coded.
	FF2_SubReason_Exists, //This will be returned when your already registered. Mate.
	FF2_SubReason_TrieError, //This will be returned if it failed to get added to trie.
	FF2_SubReason_UnKnown, //This will be returned if someone bugged out in code.
};

enum FF2_Flags
{
	FF2_Flags_None=0,
	FF2_Flags_UberReady=(1<<0),
	FF2_Flags_IsBuffed=(1<<1),
	FF2_Flags_ClassTimerDisabled=(1<<2),
	FF2_Flags_HudDisabled=(1<<3),
	FF2_Flags_BotRage=(1<<4),
	FF2_Flags_Talking=(1<<5),
	FF2_Flags_AllowSpawnInBossTeam=(1<<6),
	FF2_Flags_UseBossTimer=(1<<7),
	FF2_Flags_UsingAbility=(1<<8),
	Spawn=~FF2_Flags_UberReady & ~FF2_Flags_IsBuffed & ~FF2_Flags_Talking & ~FF2_Flags_AllowSpawnInBossTeam & FF2_Flags_UseBossTimer,
};

enum FF2_SoundExcept
{
	FF2_SoundExcept_Music,
	FF2_SoundExcept_Voice,
};

enum FF2_AbilityType
{
};

enum FF2_AbilityActionType
{
	FF2_AbilityAction_None,
	FF2_AbilityAction_Charging,
	FF2_AbilityAction_FullyCharged,
	FF2_AbilityAction_OnUse,
};

enum FF2_AbilityHookMode
{
	FF2_AbilityHookMode_Pre,
	FF2_AbilityHookMode_Normal,
	FF2_AbilityHookMode_Post,
};

enum FF2_ButtonMode
{
	FF2_ButtonMode_Taunt,
	FF2_ButtonMode_DuckOrAttack2,
	FF2_ButtonMode_Reload,
	FF2_ButtonMode_Duck,
};

enum FF2_AbilityMode
{
	FF2_AbilityMode_Active,
	FF2_AbilityMode_Passive,
};

#define FF2_BOSSFLAG_ALLOW_HEALTH_PICKUP (1<<0)
#define FF2_BOSSFLAG_ALLOW_AMMO_PICKUP (1<<1)
#define FF2_BOSSFLAG_ALLOW_HEALTH_AND_AMMO_PICKUP ((1<<0)|(1<<1))
#define FF2_BOSSFLAGS_NONE (0)
#define FF2_CONFIGS "configs/freak_fortress_2/"
#define FF2_MAPFILE "maps.cfg"

/*
 * Is FF2 enabled?
 * @return		Boolean of either true for it being enabled or false for it not being enabled.
 */
native bool:FF2_IsEnabled();

/*
 * Create a cvar that appears in FF2's main config file.
 * Params are the same for CreateConVar except the additional one found for HookConVarChange.
 * @return Handle for ConVar.
 */
native Handle:CreateFF2Cvar(const String:name[], const String:defaultValue[], ConVarChanged:callback, const String:description[]="", flags=FCVAR_PLUGIN, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0);

/*
 * Returns either true or false if the current map can be ff2.
 */
native bool:IsFF2Map();

/*
 * This function tag replaces OnPluginStart();
 * Still need OnPluginStart(); to call native to see if your registered, if not call your start function, will pester for an extension to block sm plugins load from being used on your subplugin.
 */
functag public FF2SubStart();

/*
 * This function tag replaces OnPluginEnd();
 * Please note you 100% still need OnPluginEnd(); for when your plugin is unloaded from sm plugins unload, will pester for an extension to block sm plugins unload from being used on your subplugin.
 */
functag public FF2SubEnd();

/*
 * Subplugins must 100% call this in order for there abilities to be registered.
 * @subPluginName	Unique string to name your subplugin as.
 * @subFlags		Flags that'll control how subplugin should be loaded and unloaded.
 * @onStart		See functag FF2SubStart
 * @onEnd		See functag FF2SubEnd
 * @reason		A reason from FF2_SubReason enum that explains why it returned false.
 * @return		Boolean if it's registered or not.
 */
native bool:RegisterSubPlugin(const String:subPluginName[MAX_SUBPLUGIN_NAME], FF2_SubPluginFlags:subFlags=FF2_SubPluginFlags_Normal, FF2SubStart:onStart, FF2SubEnd:onEnd, &FF2_SubReason:reason);

/*
 * This function is called before FF2 Configs are executed, all cvars for your subplugin must be registered here as well as registering yourself.
 * It replaces AskPluginToLoad2();
 */
forward FF2_SubPluginPreLoad();

#if defined _smac_included
/*
 *  This forward is only useful if your going to change a cvar on a client that smac protects.
 * @return	Return anything greater then Plugin_Continue if the cvar string is one of yours.
 */
forward Action:FF2_CheckCvar(const String:cvarName[]);
#endif

public SharedPlugin:__pl_FF2 =
{
	name = "freak_fortress_2",
	file = "freak_fortress_2.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_FF2_SetNTVOptional()
{
	MarkNativeAsOptional("FF2_IsEnabled");
	MarkNativeAsOptional("CreateFF2Cvar");
}
#endif
