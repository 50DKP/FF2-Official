//Freak Fortress 2 include file.

#define FF2FLAG_UBERREADY				(1 << 1)		//Used when medic says "I'm charged!"
#define FF2FLAG_ISBUFFED				(1 << 2)		//Used when soldier uses backup's buff.
#define FF2FLAG_CLASSTIMERDISABLED 		(1 << 3)		//Used to prevent clients' timer.
#define FF2FLAG_HUDDISABLED				(1 << 4)		//Used to prevent custom hud from clients' timer.
#define FF2FLAG_BOTRAGE					(1 << 5)		//Used by bots to use Boss' rage.
#define FF2FLAG_TALKING					(1 << 6)		//Used by Bosses with "sound_block_vo" to disable block for some lines.
#define FF2FLAG_ALLOWSPAWNINBOSSTEAM	(1 << 7)		//Used to allow spawn players in Boss' team.
#define FF2FLAG_USEBOSSTIMER			(1 << 8)		//Used to prevent Boss' timer.
#define FF2FLAG_USINGABILITY			(1 << 9)		//Used to prevent Boss' hints about abilities buttons.
#define FF2FLAGS_SPAWN					~FF2FLAG_UBERREADY & ~FF2FLAG_ISBUFFED & ~FF2FLAG_TALKING & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM & FF2FLAG_USEBOSSTIMER

#if defined _FF2_included
 #endinput
#endif
#define _FF2_included

/**
 * Is Freak Fortress enabled?
 *
 * @return	False if FF2 is disabled
 *			True if FF2 is enabled
 */
native bool:FF2_IsFF2Enabled();

/**
 * Gets current round state
 *
 * @return	0 - in setup
 *			1 - round is in progress
 *			2 - someone wins/stalemate
 */
native FF2_GetRoundState();

/**
 * Gets UserID of current Boss
 *
 * @param index		Index of boss
 * @return			Userid of boss (-1 if Boss does not exist)
 */
native FF2_GetBossUserId(index=0);

/**
 * Gets BossIndex of client
 *
 * @return	Boss index of that client. If client is not boss, returns -1
 */
native FF2_GetBossIndex(client);

/**
 * Gets current team of Boss
 *
 * @return	Number of boss's team
 */
native FF2_GetBossTeam();

/**
 * Gets character name of current Boss
 *
 * @param index 			Index of boss
 * @param buffer			Buffer for boss' character name
 * @param bufferlength		Length of buffer string
 * @param IndexMeaning		0 - "Index" parameter means index of current Boss
 *							1 - "Index" parameter means number of Boss in characters.cfg-1
 * @return					True if boss exists, false if not
 */
native bool:FF2_GetBossSpecial(index=0, String:buffer[], bufferlength, IndexMeaning=0);

/**
 * Gets Max Health of current Boss
 *
 * @param index 	Index of boss
 * @return			Max health of Boss
 */
native FF2_GetBossMaxHealth(index=0);

/**
 * Gets charge meter value of current Boss
 *
 * @param index		Index of boss
 * @param slot		Slot of charge meter
 *						0 - rage
 *						1 - as usual, used for brave jump or teleport
 *						2 - other charged abilities
 */
native Float:FF2_GetBossCharge(index, slot);

/**
 * Sets charge meter value of current Boss
 *
 * @param index		Index of boss
 * @param slot		Slot of charge meter
 *						0 - rage
 *						1 - as usual, used for brave jump or teleport
 *						2 - other charged abilities
 * @param value		New value of charge
 */
native FF2_SetBossCharge(index, slot, Float:value);

/**
 * Gets damage dealt by this client
 *
 * @param client 	Client's index
 * @return			Damage dealt
 */
native FF2_GetClientDamage(client);

/**
 * Gets Boss's rage distance
 *
 * @param index 		Index of boss
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name	Name of ability (use null string if you want get boss's global "ragedist" value)
 */
native Float:FF2_GetRageDist(index=0, const String:plugin_name[]="", const String:ability_name[]="");

/**
 * Does the Boss have a certain ability?
 *
 * @param index 		Index of boss
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability 
 * @return				True if boss has this ability. False if it doesn't
 */
native bool:FF2_HasAbility(index, const String:plugin_name[], const String:ability_name[]);

/**
 * How should the boss use a certain ability?
 *
 * @param index 		Index of boss
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability
 * @param slot			Slot of charge meter
 *							0 - rage
 *							1 - as usual, used for brave jump or teleport
 *							2 - other charged abilities 
 * @param buttonmode	How to activate the ability
 *							0 - by taunt
 *							1 - by right mouse button or duck
 *							2 - by reload button
 * @noreturn
 */
native FF2_DoAbility(index, const String:plugin_name[], const String:ability_name[], slot, buttonmode=0);

/**
 * Gets integer argument of ability
 *
 * @param index 		Index of boss
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability
 * @param argument 		Number of argument 
 * @param defvalue 		Returns if argument is not defined
 * @return				Value of argument
 */
native FF2_GetAbilityArgument(index, const String:plugin_name[], const String:ability_name[], argument, defvalue=0);

/**
 * Gets float argument of ability
 *
 * @param index 		Index of boss
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability
 * @param argument 		Number of argument 
 * @param defvalue 		Returns if argument is not defined
 * @return				Value of argument
 */
native Float:FF2_GetAbilityArgumentFloat(index, const String:plugin_name[], const String:ability_name[], argument, Float:defvalue=0.0);

/**
 * Gets string argument of ability
 *
 * @param index 		Index of boss
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability
 * @param argument 		Number of argument 
 * @param buffer 		Buffer for value of argument
 * @param bufferlength	Length of buffer string
 * @noreturn
 */
native FF2_GetAbilityArgumentString( index, const String:plugin_name[], const String:ability_name[], argument, String:buffer[], bufferlength);

/**
 * Starts random boss sound from its config file
 *
 * @param keyvalue	Name of sound container
 * @param string	Buffer for result sound path
 * @param length	Length of buffer
 * @param index		Index of boss
 * @param slot		Only for "sound_ability" - slot of ability
 * @return			True if sound has been found.  False if not
 */
native bool:FF2_RandomSound(const String: keyvalue[], String: string[], length, index=0, slot=0);

/**
 * Stops boss's music for all players
 *
 * @param index		Client's index.  0 is for all clients.
 * @noreturn
 */
native FF2_StopMusic(client=0);

/**
 * Gets keyvalues handle of Boss
 *
 * @param index				Index of Boss
 * @param SpecialIndex		0 - "Index" parameter means the index of the boss
 *							1 - "Index" parameter means number of the boss in characters.cfg-1
 * @return					Handle of Boss' keyvalues
 */
native Handle:FF2_GetSpecialKV(index, SpecialIndex=0);

/**
 * Gets client's flags for FF2 
 *
 * @param index		Client's index
 * @return			Flags
 */
native FF2_GetFF2flags(client);

/**
 * Sets client's flags for FF2 
 *
 * @param index		Client's index
 * @param flags		New values
 * @noreturn
 */
native FF2_SetFF2flags(index, flags);

/**
 * Gets client's queue points
 *
 * @param index		Client's index
 * @return			Client's queue points
 */
native FF2_GetQueuePoints(client);

/**
 * Sets client's queue points
 *
 * @param index		Client's index
 * @param value		New value of client's queue points.
 * @noreturn
 */
native FF2_SetQueuePoints(client, value);

/**
 * FF2_OnAbility:
 * Begins when Boss uses ability (Rage, jump, teleport, etc)
 * Calls every 0.2 seconds for charge abilities
 *
 * Use FF2_PreAbility with enabled=false ONLY to prevent FF2_OnAbility!
 *
 * @param index 		Index of boss
 * @param plugin_name	Name of plugin with this ability
 * @param ability_name 	Name of ability
 * @param slot 			Slot of ability
 *							0 - Rage
 *							1 - Jump/teleport
 *							2 - Other charge
 * @param action		Action of ability (for slot=1 or 2)
 *							0 - Not in use
 *							1 - Charging
 *							2 - Charged
 *							3 - In use
 * @return				Plugin_Stop can not prevent Ability. Use FF2_PreAbility with enabled=false
 */
forward FF2_PreAbility(index, const String:plugin_name[], const String:ability_name[], action, &enabled=true);
forward Action:FF2_OnAbility(index, const String:plugin_name[], const String:ability_name[], action);

/**
 * Begins when Boss gets hurt by environmental damage
 *
 * @param index 		Index of boss
 * @param triggerhurt	Entity index of "trigger_hurt"
 * @param damage 		Damage by "trigger_hurt".  Cutomizable.
 * @return				Plugin_Stop will prevent forward, Plugin_Changed will change damage.
 */
forward Action:FF2_OnTriggerHurt(index, triggerhurt, &Float:damage);

/**
 * Begins when Boss' music begins
 *
 * @param path 			Path to music sound file
 * @param time			Length of music
 * @return				Plugin_Stop will prevent music, Plugin_Changed will change it.
 */
forward Action:FF2_OnMusic(String:path[], &Float:time);


/**
 * Begins when FF2 picks Special for Boss
 *
 * @param index 		Index of boss
 * @param SpecialNum	Number of boss
 * @param SpecialName	Name of boss
 * @return				You can NOT use Plugin_Stop to prevent this, but you can change SpecialName and use Plugin_Changed to change the boss.  If you want to change SpecialNum, then make SpecialName null.
 */
forward Action:FF2_OnSpecialSelected(index, &SpecialNum, String:SpecialName[]);

/**
 * Begins when FF2 adds queue points.
 *
 * @param	add_points[MAXPLAYERS+1]	
 *				Use array to get and/or change additional points.
 * @return	Plugin_Stop will prevent this, Plugin_Changed will change it.
 */
forward Action:FF2_OnAddQueuePoints( add_points[MAXPLAYERS+1] );

/**
 * Begins when FF2 picks aCharacter Set for the map
 *
 * @param CharSetNum	Number of boss
 * @param CharSetName	Name of boss
 * @return				You can NOT use Plugin_Stop to prevent this, but you can change CharSetName and use Plugin_Changed to change the character set.  If you want to change CharSetNum, then make CharSetName null.
 */
forward Action:FF2_OnLoadCharacterSet(CharSetNum, String:CharSetName[]);

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
}
#endif