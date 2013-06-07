#include <sourcemod>

#if defined _freak_fortress_2_included
  #endinput
#endif

#define _freak_fortress_2_included

#define FF2_FLAG_UBERREADY				(1 << 0)		//Used when medic says "I'm charged!"
#define FF2_FLAG_ISBUFFED				(1 << 1)		//Used when soldier uses backup's buff.
#define FF2_FLAG_CLASSTIMERDISABLED 		(1 << 2)		//Used to prevent clients' timer.
#define FF2_FLAG_HUDDISABLED				(1 << 3)		//Used to prevent custom hud from clients' timer.
#define FF2_FLAG_BOTRAGE					(1 << 4)		//Used by bots to use Boss' rage.
#define FF2_FLAG_TALKING					(1 << 5)		//Used by Bosses with "sound_block_vo" to disable block for some lines.
#define FF2_FLAG_ALLOWSPAWNINBOSSTEAM	(1 << 6)		//Used to allow spawn players in Boss' team.
#define FF2_FLAG_USEBOSSTIMER			(1 << 7)		//Used to prevent Boss' timer.
#define FF2_FLAG_USINGABILITY			(1 << 8)		//Used to prevent Boss' hints about abilities buttons.
#define FF2_FLAGS_NONE				(0)
#define FF2_FLAGS_SPAWN				~FF2FLAG_UBERREADY & ~FF2FLAG_ISBUFFED & ~FF2FLAG_TALKING & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM & FF2FLAG_USEBOSSTIMER

enum FF2_SoundExcept
{
	FF2_SoundExcept_Music,
	FF2_SoundExcept_Voice,
};

enum FF2_AbilityType
{
	FF2_Ability_Any = -100,
	FF2_Ability_FakeDeath = -1,
	FF2_Ability_Rage = 0,
	FF2_Ability_BraveJump = 1,
	FF2_Ability_Charge = 2,
	FF2_Ability_Weighdown = 3,
	FF2_Ability_Custom1 = 4,
	FF2_Ability_Custom2 = 5,
	FF2_Ability_Custom3 = 6,
	FF2_Ability_Custom4 = 7,
	FF2_Ability_KilledPlayer = 8,
	FF2_Ability_Died = 9,
	FF2_Ability_Backstab = 10,
};

enum FF2_AbilityActionType
{
	FF2_AbilityAction_None,
	FF2_AbilityAction_Charging,
	FF2_AbilityAction_FullyCharged,
	FF2_AbilityAction_OnUse,
}

enum FF2_AbilityHookMode
{
	FF2_AbilityHookMode_Pre,
	FF2_AbilityHookMode_Normal,
};

enum FF2_ButtonMode
{
	FF2_ButtonMode_Taunt,
	FF2_ButtonMode_DuckOrAttack2,
	FF2_ButtonMode_Reload,
}

enum FF2_AbilityMode
{
	FF2_AbilityMode_Active,
	FF2_AbilityMode_Passive,
}

#define FF2_BOSSFLAG_ALLOW_HEALTH_PICKUP (1<<0)
#define FF2_BOSSFLAG_ALLOW_AMMO_PICKUP (1<<1)
#define FF2_BOSSFLAG_ALLOW_HEALTH_AND_AMMO_PICKUP ((1<<0)|(1<<1))
#define FF2_BOSSFLAGS_NONE (0)

#define FF2_CHARGE_OTHER 0
#define FF2_CHARGE_RAGE 0
#define FF2_CHARGE_WEIGHDOWN 1
#define FF2_CHARGE_TELEPORT 1

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
native bool:FF2_GetBossSpecial( index = 0, String:buffer[], bufferlen, isNumOfSpecial = 0 );
native bool:FF2_GetBossName( index = 0, String:buffer[], bufferlen, isNumOfSpecial = 0 );

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
 * @param charge_type	See FF2_CHARGE constants
 * 
 * @return charge percent
 */
native Float:FF2_GetBossCharge( index, charge_type = FF2_CHARGE_RAGE );

/**
 * Sets charge meter value of current Boss
 *
 * @param index			Index of boss (0 for normal boss, 1 or higher for companion bosses)
 * @param charge_type	See FF2_CHARGE constants
 * @param value			New value of charge
 * @noreturn
 */
native FF2_SetBossCharge( index, charge_type, Float:value );

/**
 * Gets damage, dealt by this client to boss
 *
 * @param client 		Client index.
 * @return		    	Damage dealt by this client.
 */
native FF2_GetClientDamage( client );

/**
 * Gets damage, dealt by this client to boss
 *
 * @param client 		Client index.
 * @return		    	Healing done by this client.
 */
native FF2_GetClientHealing( client );

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
 * Only works for v1 abilities.
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability 
 * @return				true if Boss has this ability. false if is hasn't
 */
native bool:FF2_HasAbility( index, const String:plugin_name[], const String:ability_name[] );

/**
 * Does Boss have ability?
 * Only works for v2 abilities.
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param ability_name 	Name of ability
 * @param ability_type	Only return true if the ability is of this type.  Set to FF2_Ability_Any to ignore type.
 * 						Type is always ignored for passive abilities..
 * @return				true if Boss has this ability. false if it hasn't
 */
native bool:FF2_HasAbilityEx( index, const String:ability_name[], FF2_AbilityType:ability_type = FF2_Ability_Any );

/**
 * Force a boss to do an ability
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability
 * @param charge_type	See FF2_CHARGE constants
 * @param buttonmode	There are 3 buttonmodes:
 *							0 - by taunt
 *							1 - by right mouse button or duck
 *							2 - by reload button
 * @noreturn
 */
native FF2_DoAbility(index, const String:plugin_name[], const String:ability_name[], charge_type, buttonmode = 0 );

/**
 * Force a boss to do a v2 non-passive ability
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param ability_name 	Name of ability
 * @param slot			See FF2_CHARGE constants
 * @param buttonmode	See FF2_ButtomMode enum
 * @param ability_type	Only do the ability if it's a specific type, defaults to any
 * 
 * @noreturn
 */
native FF2_DoAbilityEx(index, const String:ability_name[], charge_type, FF2_ButtonMode:buttonmode = FF2_ButtonMode_Taunt, FF2_AbilityType:ability_type = FF2_Ability_Any  );

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
 * Gets integer argument of ability
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param ability_name 	Name of ability
 * @param argument 		Number of argument 
 * @param defvalue 		Returns if argument is not defined
 * @param ability_type	
 * @return				Value of argument
 */
native FF2_GetAbilityArgumentEx( index, const String:ability_name[], argument, defvalue = 0, FF2AbilityType:type = FF2Ability_Any );

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
native Float:FF2_GetAbilityArgumentFloat( index, const String:plugin_name[], const String:ability_name[], argument, Float:defvalue = 0.0 );

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
native Float:FF2_GetAbilityArgumentFloatEx( index, const String:ability_name[], argument, Float:defvalue = 0.0, FF2AbilityType:type = FF2Ability_Any );

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
native FF2_GetAbilityArgumentString( index, const String:plugin_name[], const String:ability_name[], argument, String:buffer[], bufferlen );

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
native FF2_GetAbilityArgumentStringEx( index, const String:ability_name[], argument, String:buffer[], bufferlen, FF2AbilityType:type = FF2Ability_Any );

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
native Handle:FF2_GetSpecialKV( index = 0, isNumOfSpecial = 0 );
native Handle:FF2_GetBossKV( index = 0, isNumOfSpecial = 0 );

/**
 * Gets client's flags for FF2 
 *
 * @param client		Client's index
 * @return				Flags
 */
native FF2_GetFF2flags( client );

/**
 * Sets client's flags for FF2 
 *
 * @param client		Client's index
 * @param flags			New values
 * @noreturn
 */
native FF2_SetFF2flags( client, flags );

/**
 * Gets boss's boss flags for FF2
 * See BOSSFLAG constants for flag definitions
 *
 * @param index			Boss's index
 * @return				Flags
 */
native FF2_GetBossFlags( index = 0 );

/**
 * Sets boss's boss flags for FF2 
 * See BOSSFLAG constants for flag definitions
 *
 * @param index			Boss's index
 * @param flags			New values
 * @noreturn
 */
native FF2_SetBossFlags( index, flags );

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
 * Begins when Boss uses a v1 ability (stun rage,jump,uber rage etc)
 * For v2 abilities, use FF2_HookAbility or FF2_HookPassiveAbility
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
 * @return		    	Plugin_Stop can not prevent Ability. Use FF2_PreAbility with enabled = false
 */
forward FF2_PreAbility( index, const String:plugin_name[], const String:ability_name[], action, &enabled = true );
forward Action:FF2_OnAbility( index, const String:plugin_name[], const String:ability_name[], action );

funcenum FF2_Ability
{
	/**
	 * Runs when Boss uses ability (stun rage,jump,uber rage etc)
	 * The Action version is intended for a prehook
	 * 
	 * @param index 	Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
	 * @return	    	Plugin_Stop or Plugin_Handled in PreAbility will prevent Ability;
	 * 					Plugin_Stop will stop any later callbacks from being processed for this ability
	 */
	Action:public( index ),
	
	/**
	 * Runs when Boss uses ability (stun rage,jump,uber rage etc)
	 * Called each 0.2 seconds for charge abilities
	 * 
	 * @param index 	Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
	 * @param action	Action of ability (for 	FF2_Ability_BraveJump or FF2_Ability_Charge)
	 * 					See FF2_AbilityActionType for valid actions
	 * @return	    	Plugin_Stop or Plugin_Handled in PreAbility will prevent Ability;
	 * 					Plugin_Stop will stop any later callbacks from being processed for this ability
	 */
	Action:public( index, FF2_AbilityActionType:action ),
	
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
	 * @param action	Action of ability (for 	FF2_Ability_BraveJump or FF2_Ability_Charge)
	 * 					See FF2_AbilityActionType for valid actions
	 * @noreturn
	 */
	public( index, FF2_AbilityActionType:action ),
}

/**
 * Runs when a passive ability is toggled
 * Passive abilities are startedwhen a boss character is loaded and stopped when a boss is unloaded
 * NOTE: They are NOT unloaded when a boss dies.
 * 
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param start			True if ability is starting, false if it is stopping
 */
functag FF2_ToggleAbility public( index, bool:start );

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
native FF2_EmitSoundToAllExcept( SoundExcept:exceptiontype = SoundExcept_Music,
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
				Float:soundtime = 0.0 );

/**
 * Register a boss ability, including slot number and argument types for arg1 and higher
 * (i.e. Param_Cell, Param_Float, or Param_String)
 * 
 * This should be called by subplugins when they are loaded
 * 
 * @param ability_name	Name of ability
 * @param default_slot	slot of ability.
 * @error if incorrect ParamTypes are used.  This only supports Cell, Float, and String.
 * @noreturn
 */
native FF2_RegisterAbility( const String:ability_name[], default_slot=0, ParamType:... );

/**
 * Register a passive boss ability, including argument types for arg1 and higher
 * (i.e. Param_Cell, Param_Float, or Param_String)
 * 
 * This should be called by subplugins when they are loaded
 * 
 * Use this to write manual events and the like that aren't a registered ability type.
 * Prior to this release, that would include a player_death hook for a boss's death
 * 
 * @param ability_name	Name of ability
 * @error if incorrect ParamTypes are used.  This only supports Cell, Float, and String.
 * @noreturn
 */
native FF2_RegisterPassiveAbility( const String:ability_name[], ParamType:... );

/**
 * Broadcast when an FF2 ability is registered by a plugin
 * 
 * @param ability_name		Ability that was registered
 */
forward FF2_OnAbilityRegistered( const String:ability_name[] );

/**
 * Unregister a boss ability.
 * Do this in OnPluginEnd for subplugins
 * 
 * @param ability_name		Ability that was unregistered
 * @noreturn
 */
native FF2_UnregisterAbility( const String:ability_name[] );

/**
 * Broadcast when an FF2 ability is unregistered by a plugin
 * 
 * @param ability_name		Ability that was unregistered
 */
forward FF2_OnAbilityUnregistered( const String:ability_name[] );

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
native bool:FF2_IsAbilityRegistered( const String:ability_name[] );

/**
 * Hook a previously registered ability
 * This is separate from register because you can hook abilities from other plugins
 *
 * @param ability_name	Name of ability
 * @param callback		Callback for when an ability is used
 * @param mode			What king of hook (pre or normal)
 * @error 				If ability hasn't been registered as passive
 * @noreturn
 */
native FF2_HookAbility( const String:ability_name[], FF2_Ability:callback, FF2_AbilityHookMode:mode = FF2_AbilityHookMode_Normal );

/**
 * Hook a previously registered passive ability.  The callback will be called when a relevant boss is loaded or unloaded.
 * 
 * @param ability_name 	Name of ability
 * @param callback		Callback for when ability is started or stopped
 * @error 				If ability hasn't been registered as passive
 * @noreturn
 */
native FF2_HookPassiveAbility( const String:ability_name[], FF2_ToggleAbility:callback );

/**
 * Unhook a previously registered ability
 * @param ability_name	Name of ability
 * @param callback		Callback for when an ability is used
 * @param mode			What king of hook (pre or normal)
 * @noreturn
 */
native FF2_UnhookAbility( const String:abilityName[], FF2_Ability:callback, FF2_AbilityHookMode:mode = FF2_AbilityHookMode_Normal );

/**
 * Unhook a previously registered passive ability
 * 
 * @param ability_name 	Name of ability
 * @param callback		Callback for when ability is started or stopped
 * @noreturn
 */
native FF2_UnhookPassiveAbility( const String:ability_name[], FF2_ToggleAbility:callback );

/**
 * Unhook all abilities this plugin has hooked.
 * 
 * This MUST be called in OnPluginEnd if you hooked any abilities.
 * (SourceMod gives plugins no way of knowing when other plugins are unloaded)
 */
native FF2_UnhookAllAbilities();

/**
 * Begins when Boss hurts by pit, sawblade etc.
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param triggerhurt	Entity index of "trigger_hurt"
 * @param damage 		Damage by the trigger_hurt, also you can change it.
 * @return		    	Plugin_Stop will prevent forward, Plugin_Changed will change damage;
 */
forward Action:FF2_OnTriggerHurt( index, triggerhurt, &Float:damage );

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
forward Action:FF2_OnSpecialSelected( index, &SpecialNum, String:SpecialName[] );

/**
 * Begins when FF2 picks Special for Boss
 *
 * @param index 		Index of boss (0, as usual, but, for example, companion like Seeldier has 1)
 * @param SpecialName	Name of Special ("Vagineer", "Ninja Spy" etc)
 * @return		    	You can NOT use Plugin_Stop to prevent this, but
 *							you can change SpecialName and use Plugin_Changed to change Special;
 */
forward Action:FF2_OnSpecialSelectedEx( index, String:SpecialName[] );

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
forward Action:FF2_OnLoadCharacterSetEx( String:CharSetName[] );

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
	MarkNativeAsOptional("FF2_GetRoundState");
	MarkNativeAsOptional("FF2_GetBossUserId");
	MarkNativeAsOptional("FF2_GetBossClientId");
	MarkNativeAsOptional("FF2_GetBossIndex");
	MarkNativeAsOptional("FF2_GetBossTeam");
	MarkNativeAsOptional("FF2_GetBossSpecial");
	MarkNativeAsOptional("FF2_GetBossName");
	MarkNativeAsOptional("FF2_GetBossLives");
	MarkNativeAsOptional("FF2_GetBossMaxLives");
	MarkNativeAsOptional("FF2_GetBossHealth");
	MarkNativeAsOptional("FF2_GetBossMaxHealth");
	MarkNativeAsOptional("FF2_GetBossCharge");
	MarkNativeAsOptional("FF2_SetBossCharge");
	MarkNativeAsOptional("FF2_GetClientDamage");
	MarkNativeAsOptional("FF2_GetClientHealing");
	MarkNativeAsOptional("FF2_GetRageDist");
	MarkNativeAsOptional("FF2_HasAbility");
	MarkNativeAsOptional("FF2_HasAbilityEx");
	MarkNativeAsOptional("FF2_DoAbility");
	MarkNativeAsOptional("FF2_DoAbilityEx");
	MarkNativeAsOptional("FF2_GetAbilityArgument");
	MarkNativeAsOptional("FF2_GetAbilityArgumentEx");
	MarkNativeAsOptional("FF2_GetAbilityArgumentFloat");
	MarkNativeAsOptional("FF2_GetAbilityArgumentFloatEx");
	MarkNativeAsOptional("FF2_GetAbilityArgumentString");
	MarkNativeAsOptional("FF2_GetAbilityArgumentStringEx");
	MarkNativeAsOptional("FF2_RandomSound");
	MarkNativeAsOptional("FF2_StopMusic");
	MarkNativeAsOptional("FF2_GetSpecialKV");
	MarkNativeAsOptional("FF2_GetBossKV");
	MarkNativeAsOptional("FF2_GetFF2flags");
	MarkNativeAsOptional("FF2_SetFF2flags");
	MarkNativeAsOptional("FF2_GetFF2Flags");
	MarkNativeAsOptional("FF2_SetFF2Flags");
	MarkNativeAsOptional("FF2_GetBossFlags");
	MarkNativeAsOptional("FF2_SetBossFlags");
	MarkNativeAsOptional("FF2_GetQueuePoints");
	MarkNativeAsOptional("FF2_SetQueuePoints");
	MarkNativeAsOptional("FF2_EmitSoundToAllExcept");
	MarkNativeAsOptional("FF2_RegisterAbility");
	MarkNativeAsOptional("FF2_UnregisterAbility");
	MarkNativeAsOptional("FF2_UnregisterAllAbilities");
	MarkNativeAsOptional("FF2_IsAbilityRegistered");
	MarkNativeAsOptional("FF2_SetAbilityArgumentDefault");
	MarkNativeAsOptional("FF2_SetAbilityArgumentDefaultFloat");
	MarkNativeAsOptional("FF2_SetAbilityArgumentDefaultString");
	MarkNativeAsOptional("FF2_GetAbilityArgumentDefault");
	MarkNativeAsOptional("FF2_GetAbilityArgumentDefaultFloat");
	MarkNativeAsOptional("FF2_GetAbilityArgumentDefaultString");
	MarkNativeAsOptional("FF2_HookAbility");
	MarkNativeAsOptional("FF2_HookPassiveAbility");
	MarkNativeAsOptional("FF2_UnhookAbility");
	MarkNativeAsOptional("FF2_UnhookPassiveAbility");
	MarkNativeAsOptional("FF2_UnhookAllAbilities");
}
