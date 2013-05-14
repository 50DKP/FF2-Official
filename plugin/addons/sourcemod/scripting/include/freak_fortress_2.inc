#include <sourcemod>

#if defined _freak_fortress_2_included
  #endinput
#endif

#define _freak_fortress_2_included

enum SoundExcept
{
	SoundExcept_Music,
	SoundExcept_Voice,
};

enum FF2AbilityType
{
	FF2Ability_Any = -100,
	FF2Ability_FakeDeath = -1,
	FF2Ability_Rage = 0,
	FF2Ability_BraveJump = 1,
	FF2Ability_Charge = 2,
	FF2Ability_Weighdown = 3,
	FF2Ability_Custom1 = 4,
	FF2Ability_Custom2 = 5,
	FF2Ability_Custom3 = 6,
	FF2Ability_Custom4 = 7,
	FF2Ability_KilledPlayer = 8,
	FF2Ability_Died = 9,
	FF2Ability_Backstab = 10,
};

enum FF2AbilityMode
{
	FF2AbilityMode_Pre,
	FF2AbilityMode_Normal,
};

/**
 * Is Freak Fortress enabled?
 *
 * @return		false - FF2 is disabled
				true - FF2 is enabled
 */
native bool:FF2_IsFF2Enabled();

/**
 * @deprecated
 * Use GameRules_GetRoundState
 * 
 * @return		    	0 - in setup
						1 - action
						2 - someone wins
 */
native FF2_GetRoundState();

/**
 * Gets UserID of current Boss
 *
 * @param index 		Index of boss (0 for normal boss, 1 or higher for companion bosses).
 * @return		    	Userid of boss (-1 if Boss does not exist)
 */
native FF2_GetBossUserId( index = 0 );

/**
 * Gets UserID of current Boss
 *
 * @param index 		Index of boss (0 for normal boss, 1 or higher for companion bosses).
 * @return		    	Client id of boss (-1 if Boss does not exist)
 */
native FF2_GetBossClientId( index = 0 );

/**
 * Gets BossIndex of client
 *
 * @return		    	Boss Index of that client. If client is not a boss, returns -1
 */
native FF2_GetBossIndex( client );

/**
 * Gets the Bosses current team.  As of FF2 2.0, this should always be TFTeam_Blue
 *
 * @return		    	Number of Boss's team
 */
native FF2_GetBossTeam();

/**
 * Gets character name of current Boss
 *
 * @param index 			Index of boss (0, as usual, but companion like Seeldier has 1)
 * @param buffer 			Buffer for boss' character name
 * @param bufferlen			Length of buffer string
 * @param isNumOfSpecial	0 - "index" parameter means index of current boss (0 - player-Seeman, 1 - player-Seeldier, etc.).
 *							1 - "index" means number of special (1 - Saxton's config. 2 - Vagineer's config, etc.)
 *								Don't forget: 1st character from characters.cfg is _0th_ here
 * @return		    		true if Special exists, false if not
 */
native bool:FF2_GetBossSpecial( index = 0, String:buffer[], bufferlen, isNumOfSpecial = 0);

/**
 * Gets number of lives of current Boss
 *
 * @param index 		Index of boss (0 for normal boss, 1 or higher for companion bosses)
 * @return		    	Lives of Boss
 */
native FF2_GetBossLives( index = 0 );

/**
 * Gets max lives of current Boss
 *
 * @param index 		Index of boss (0 for normal boss, 1 or higher for companion bosses)
 * @return		    	Max Lives of Boss
 */
native FF2_GetBossMaxLives( index = 0 );

/**
 * Gets Health of current Boss
 *
 * @param index 		Index of boss (0 for normal boss, 1 or higher for companion bosses)
 * @return		    	Health of Boss
 */
native FF2_GetBossHealth( index = 0 );

/**
 * Gets Max Health of current Boss
 *
 * @param index 		Index of boss (0 for normal boss, 1 or higher for companion bosses)
 * @return		    	Max Health of Boss
 */
native FF2_GetBossMaxHealth( index = 0 );

/**
 * Gets charge meter value of current Boss
 *
 * @param index			Index of boss (0 for normal boss, 1 or higher for companion bosses)
 * @param slot			Slot of charge meter
 *							0 - rage
 *							1 - brave jump or teleport
 *							0 - other charged abilities
 */
native Float:FF2_GetBossCharge( index, slot );

/**
 * Sets charge meter value of current Boss
 *
 * @param index			Index of boss (0 for normal boss, 1 or higher for companion bosses)
 * @param slot			Slot of charge meter
 *							0 - rage
 *							1 - as usual, used for brave jump or teleport
 *							0 - other charged abilities
 * @param value			New value of charge
 */
native FF2_SetBossCharge( index, slot, Float:value );

/**
 * Gets damage, dealt by this client to boss
 *
 * @param client 		Client's index.
 * @return		    	Damage, dealt by this client.
 */
native FF2_GetClientDamage( client );

/**
 * Gets Boss' rage distance
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability (use null string if you want get boss' global "ragedist" value)
 * @return		    	
 */
native Float:FF2_GetRageDist( index = 0 , const String:plugin_name[]="", const String:ability_name[]="" );

/**
 * Does Boss have ability?
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability 
 * @return				true if Boss has this ability. false is hasn't
 */
native bool:FF2_HasAbility( index, const String:plugin_name[], const String:ability_name[] );

/**
 * Does Boss have ability in the current subplugin?
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param ability_name 	Name of ability 
 * @return				true if Boss has this ability. false is hasn't
 */
native bool:FF2_HasAbilityEx( index, const String:ability_name[] );

/**
 * Force a boss to do an ability
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability
 * @param slot			Slot of charge meter
 *							0 - rage
 *							1 - as usual, used for brave jump or teleport
 *							0 - other charged abilities 
 * @param buttonmode	There is 2 buttonmodes today:
 *							0 - by taunt
 *							1 - by right mouse button or duck
 *							2 - by reload button
 * @noreturn
 */
native FF2_DoAbility(index, const String:plugin_name[], const String:ability_name[], slot, buttonmode = 0);


/**
 * Gets integer argument of ability
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability
 * @param argument 		Number of argument 
 * @param defvalue 		Returns if argument is not defined
 * @return				Value of argument
 */
native FF2_GetAbilityArgument( index, const String:plugin_name[], const String:ability_name[], argument, defvalue = 0 );

/**
 * Gets float argument of ability
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability
 * @param argument 		Number of argument 
 * @param defvalue 		Returns if argument is not defined
 * @return				Value of argument
 */
native Float:FF2_GetAbilityArgumentFloat( index, const String:plugin_name[], const String:ability_name[], argument, Float:defvalue = 0.0);

/**
 * Gets string argument of ability
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability
 * @param argument 		Number of argument 
 * @param buffer 		Buffer for value of argument
 * @param bufferlen		Length of buffer string
 * @noreturn
 */
native FF2_GetAbilityArgumentString( index, const String:plugin_name[], const String:ability_name[], argument, String:buffer[], bufferlen);

/**
 * Starts random boss' sound from his config file
 *
 * @param keyvalue		Name of sound container, for example "sound_kspree"
 * @param str			Buffer for result sound path
 * @param length		Length of "str" buffer
 * @param index			Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param slot			Only for "sound_ability": slot of ability.
 * @return				true if sound has been found. false if not
 */
native bool:FF2_RandomSound( const String: keyvalue[], String: str[], length, index = 0, slot = 0 );

/**
 * Stops boss' music for all players
 *
 * @param index			Client's index. 0 is "for all".
 * @noreturn
 */
native FF2_StopMusic( client = 0 );

/**
 * Gets keyvalues handle of Boss
 *
 * @param index				Index of Boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param isNumOfSpecial	0 - "index" parameter means index of current boss (0 - player-Seeman, 1 - player-Seeldier, etc.).
 *							1 - "index" means number of special (1 - Saxton's config. 2 - Vagineer's config, etc.)
 *								Don't forget: 1st chatacter from chatacters.cfg is _0th_ here
 * @return					Handle of Boss' keyvalues
 */
native Handle:FF2_GetSpecialKV( index , isNumOfSpecial = 0);

/**
 * Gets client's flags for FF2 
 *
 * @param index			Client's index
 * @return				Flags
 */
native FF2_GetFF2flags( client );

/**
 * Sets client's flags for FF2 
 *
 * @param index			Client's index
 * @param flags			New values
 * @noreturn
 */
native FF2_SetFF2flags( index, flags );

/**
 * Gets client's queue points
 *
 * @param index			Client's index
 * @return				Client's queue points
 */
native FF2_GetQueuePoints( client );

/**
 * Sets client's queue points
 *
 * @param index			Client's index
 * @param value			New value of client's queue points.
 * @noreturn
 */
native FF2_SetQueuePoints( client, value );

/**
 * FF2_OnAbility:
 * Begins when Boss uses ability (stun rage,jump,uber rage etc)
 * Calls each 0.2 seconds for charge abilities
 *
 * Use FF2_PreAbility with enabled=false only to prevent FF2_OnAbility!
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability
 * @param action		Action of ability (for slot=1 or 2)
 *							0 - not on use
 *							1 - on charging
 *							2 - is charged
 *							3 - on use
 * @return		    	Plugin_Stop can not preve Ability. Use FF2_PreAbility with enabled = false
 */
 // In 1.08 or newer, only use this if you're intercepting abilities from other plugins, otherwise use FF_PreAbilityEx
forward FF2_PreAbility( index, const String:plugin_name[], const String:ability_name[], action, &enabled = true );

// To be deprecated in 1.08 in favor of FF2_OnAbilityEx and FF2_RegisterSubplugin, return type ignored either way
forward Action:FF2_OnAbility( index, const String:plugin_name[], const String:ability_name[], action );

// Coming soon
/**
 * Begins when Boss uses ability (stun rage,jump,uber rage etc)
 * Calls each 0.2 seconds for charge abilities
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param ability_name 	Name of ability
 * @param action		Action of ability (for slot=1 or 2)
 *							0 - not on use
 *							1 - on charging
 *							2 - is charged
 *							3 - on use
 * @return		    	Plugin_Stop in PreAbility will prevent Ability;
 */
//functag public Action:FF2_PreAbilityEx( index, const String:ability_name[], action );
//functag public FF2_OnAbilityEx( index, const String:ability_name[], action );

funcenum FF2_Ability
{
	/**
	 * Runs when Boss uses ability (stun rage,jump,uber rage etc)
	 * 
	 * @param index 	Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
	 * @return		    Plugin_Stop in PreAbility will prevent Ability;
	 */
	Action:public( index ),
	
	/**
	 * Runs when Boss uses ability (stun rage,jump,uber rage etc)
	 * Called each 0.2 seconds for charge abilities
	 * 
	 * @param index 	Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
	 * @param action	Action of ability (for slot=1 or 2)
	 *						0 - not on use
	 *						1 - on charging
	 *						2 - is charged
	 *						3 - on use
	 * @return	    	Plugin_Stop in PreAbility will prevent Ability;
	 */
	Action:public( index, action ),
	
	/**
	 * Runs when Boss uses ability (stun rage,jump,uber rage etc)
	 * 
	 * @param index 	Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
	 * @noreturn
	 */
	public( index ),

	/**
	 * Runs when Boss uses ability (stun rage,jump,uber rage etc)
	 * Called each 0.2 seconds for charge abilities
	 * 
	 * @param index 	Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
	 * @param action	Action of ability (for slot=1 or 2)
	 *						0 - not on use
	 *						1 - on charging
	 *						2 - is charged
	 *						3 - on use
	 * @noreturn
	 */
	public( index, action ),
}

/**
 * Called when a boss that uses this subplugin loads
 */
//functag public FF2_StartPlugin();

/**
 * Called when a boss that uses this subplugin unloads
 */
//functag public FF2_StopPlugin();

/**
 * Register a subplugin.
 * 
 * @param ability		Function called whenever one of this plugin's abilities are called. Pass _ or INVALID_FUNCTION if you don't have activated abilities.
 * @param preability	Function called vefore one of this plugin's abilities are called.
 * @param start			Function called whenever a boss loads that uses abilities from this plugin. Used for non-activated abilities, such as event-triggered.
 * @param stop			Called whenever a boss unloads that used abilities from this plugin. Used for non-activated abilities, such as event-triggered.
 */
//native FF2_RegisterSubplugin(FF2_OnAbilityEx:ability = INVALID_FUNCTION, FF2_PreAbilityEx:preability, FF2_StartPlugin:start = INVALID_FUNCTION, FF2_StopPlugin:stop = INVALID_FUNCTION);

//native FF2_UnregisterSubplugin();

//native FF2_GetMySubpluginName(String:name[], maxlength);

/**
 * Register a boss ability, including slot number and argument types for arg1 and higher
 * (i.e. Param_Cell, Param_Float, or Param_String)
 * This should be done in OnAllPluginsLoaded.
 * 
 * @error if incorrect ParamTypes are used.  This only supports Cell, Float, and String.
 * @noreturn
 */
native FF2_RegisterAbility(String:abilityName[], defaultSlot=0, ParamType:...);

/**
 * Unregister a boss ability.
 * 
 * @noreturn
 */
native FF2_UnregisterAbility(String:abilityName[]);

/**
 * Unregister all abilities registered to this subplugin
 * This should be done in OnPluginEnd.
 * 
 * @noreturn
 */
native FF2_UnregisterAllAbilities();

/**
 * Check if a named ability has been registered
 * 
 * @return true if ability is registered
 */
native bool:FF2_IsAbilityRegistered(String:abilityName[]);

/**
 * Hook a previously registered ability
 *
 * @noreturn
 */
native FF2_HookAbility(String:abilityName[], FF2_Ability:callback, FF2AbilityMode:mode=FF2AbilityMode_Normal);

/**
 * Unhook a previously registered ability
 * 
 * @noreturn
 */
native FF2_UnhookAbility(String:abilityName[], FF2_Ability:callback, FF2AbilityMode:mode=FF2AbilityMode_Normal);

/**
 * Unhook all abilities this plugin has hooked.
 * 
 * This MUST be called in OnPluginEnd if you hooked any abilities.
 * (SourceMod gives plugins no way of knowing when other plugins are unloaded)
 */
native FF2_UnhookAllAbilities();

/**
 * Wrapper around EmitSoundToAll that uses the FF2 sound exception system
 * 
 * @param exceptiontype	Which type of sound this is.
 * @param sample		Sound file name relative to the "sounds" folder.
 * @param entity		Entity to emit from.
 * @param channel		Channel to emit with.
 * @param level			Sound level.
 * @param flags			Sound flags.
 * @param volume		Sound volume.
 * @param pitch			Sound pitch.
 * @param speakerentity	Unknown.
 * @param origin		Sound origin.
 * @param dir			Sound direction.
 * @param updatePos		Unknown (updates positions?)
 * @param soundtime		Alternate time to play sound for.
 * @noreturn
 */
native FF2_EmitSoundToAllExcept(SoundExcept:exceptiontype = SoundExcept_Music,
				const String:sample[],
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
				Float:soundtime = 0.0);

/**
 * Begins when Boss hurts by pit, sawblade etc.
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param triggerhurt	Entity index of "trigger_hurt"
 * @param damage 		Damage by the trigger_hurt, also you can change it.
 * @return		    	Plugin_Stop will prevent forward, Plugin_Changed will change damage;
 */
forward Action:FF2_OnTriggerHurt( index, triggerhurt, &Float:damage);

/**
 * Begins when Boss' music begins
 *
 * @param path 			Path to music sound file
 * @param time			Length of music
 * @return		    	Plugin_Stop will prevent music, Plugin_Changed will change it;
 */
forward Action:FF2_OnMusic( String:path[], &Float:time );


/**
 * @deprecated		No longer called. Use FF2_OnSpecialSelectedEx.
 */
#pragma deprecated		No longer called. Use FF2_OnSpecialSelectedEx.
forward Action:FF2_OnSpecialSelected( index, &SpecialNum, String:SpecialName[]);

/**
 * Begins when FF2 picks Special for Boss
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param SpecialName	Name of Special ("Vagineer", "Ninja Spy" etc)
 * @return		    	You can NOT use Plugin_Stop to prevent this, but
 *							you can change SpecialName and use Plugin_Changed to change Special;
 */
forward Action:FF2_OnSpecialSelectedEx( index, String:SpecialName[]);

/**
 * Begins when FF2 adds queue points.
 *
 * @param add_points[MAXPLAYERS+1]	
 *						Use array to get and\or change additional points.
 * @return		    	Plugin_Stop will prevent this (do you really need it?), Plugin_Changed will change it;
 */
forward Action:FF2_OnAddQueuePoints( add_points[MAXPLAYERS+1] );

/**
 * @deprecated		No longer called. Use FF2_OnLoadCharacterSetEx.
 */
#pragma deprecated		No longer called. Use FF2_OnLoadCharacterSetEx.
forward Action:FF2_OnLoadCharacterSet( CharSetNum, String:CharSetName[] );

/**
 * Begins when FF2 picks Character Set for map
 *
 * @param CharSetName	Name of Character Set ("Freak Fortress 2", "Vs Saxton Hale" etc)
 * @return		    	You can NOT use Plugin_Stop to prevent this, but
 *							you can change CharSetName and use Plugin_Changed to change Special;
 *							if you want to change CharSetNum, then set CharSetName to null string ("").
 */
forward Action:FF2_OnLoadCharacterSetEx(String:CharSetName[] );

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

public __pl_FF2_SetNTVOptional()
{
	MarkNativeAsOptional("FF2_IsFF2Enabled");
	MarkNativeAsOptional("FF2_GetBossUserId");
	MarkNativeAsOptional("FF2_GetBossIndex");
	MarkNativeAsOptional("FF2_GetBossTeam");
	MarkNativeAsOptional("FF2_GetBossSpecial");
	MarkNativeAsOptional("FF2_GetBossMaxHealth");
	MarkNativeAsOptional("FF2_GetBossCharge");
	MarkNativeAsOptional("FF2_SetBossCharge");
	MarkNativeAsOptional("FF2_GetClientDamage");
	MarkNativeAsOptional("FF2_GetRoundState");	
	MarkNativeAsOptional("FF2_GetRageDist");
	MarkNativeAsOptional("FF2_HasAbility");	
	MarkNativeAsOptional("FF2_GetAbilityArgument");		
	MarkNativeAsOptional("FF2_GetAbilityArgumentFloat");		
	MarkNativeAsOptional("FF2_GetAbilityArgumentString");		
	MarkNativeAsOptional("FF2_RandomSound");	
	MarkNativeAsOptional("FF2_StopMusic");	
	MarkNativeAsOptional("FF2_GetSpecialKV");		
	MarkNativeAsOptional("FF2_GetQueuePoints");		
	MarkNativeAsOptional("FF2_SetQueuePoints");		
	MarkNativeAsOptional("FF2_GetFF2flags");		
	MarkNativeAsOptional("FF2_SetFF2flags");		
	MarkNativeAsOptional("FF2_DoAbility");
	//MarkNativeAsOptional("FF2_RegisterSubplugin");
	//MarkNativeAsOptional("FF2_UnregisterSubplugin");
	//MarkNativeAsOptional("FF2_GetMySubpluginName");

}
