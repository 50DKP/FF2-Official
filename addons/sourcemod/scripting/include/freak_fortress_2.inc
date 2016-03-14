//Freak Fortress 2 include file.
#include <morecolors>
#include <sdktools>

#define FF2FLAG_UBERREADY				(1<<1)		//Used when medic says "I'm charged!"
#define FF2FLAG_ISBUFFED				(1<<2)		//Used when soldier uses the Battalion's Backup
#define FF2FLAG_CLASSTIMERDISABLED 		(1<<3)		//Used to prevent clients' timer
#define FF2FLAG_HUDDISABLED				(1<<4)		//Used to prevent custom hud from clients' timer
#define FF2FLAG_BOTRAGE					(1<<5)		//Used by bots to use Boss's rage
#define FF2FLAG_TALKING					(1<<6)		//Used by Bosses with "sound_block_vo" to disable block for some lines
#define FF2FLAG_ALLOWSPAWNINBOSSTEAM	(1<<7)		//Used to allow spawn players in Boss's team
#define FF2FLAG_USEBOSSTIMER			(1<<8)		//Used to prevent Boss's timer
#define FF2FLAG_USINGABILITY			(1<<9)		//Used to prevent Boss's hints about abilities buttons
#define FF2FLAG_CLASSHELPED				(1<<10)
#define FF2FLAG_HASONGIVED				(1<<11)
#define FF2FLAG_CHANGECVAR				(1<<12)		//Used to prevent SMAC from kicking bosses who are using certain rages (NYI)
#define FF2FLAG_ALLOW_HEALTH_PICKUPS	(1<<13)		//Used to prevent bosses from picking up health
#define FF2FLAG_ALLOW_AMMO_PICKUPS		(1<<14)		//Used to prevent bosses from picking up ammo
#define FF2FLAG_ROCKET_JUMPING			(1<<15)		//Used when a soldier is rocket jumping
#define FF2FLAGS_SPAWN					~FF2FLAG_UBERREADY & ~FF2FLAG_ISBUFFED & ~FF2FLAG_TALKING & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM & ~FF2FLAG_CHANGECVAR & ~FF2FLAG_ROCKET_JUMPING & FF2FLAG_USEBOSSTIMER & FF2FLAG_USINGABILITY

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
 * Gets the version of FF2 running on the server
 *
 * @param version   An array of size 3 that will contain the major, minor, and stable version numbers respectively
 * @return			True if the server is running a dev version of FF2, false otherwise
 */
native FF2_GetFF2Version(version[]=0);

/**
 * Gets current round state
 *
 * @return	0 - in setup
 *			1 - round is in progress (due to a bug in arena mode, stalemate will also return 1)
 *			2 - someone wins
 */
native FF2_GetRoundState();

/**
 * Gets UserID of current Boss
 *
 * @param boss		Boss's index
 * @return			Userid of boss (-1 if Boss does not exist)
 */
native FF2_GetBossUserId(boss=0);

/**
 * Gets the boss index of a client
 *
 * @param client	The client used to search for the boss index
 * @return			Boss index of that client.  If client is not boss, returns -1
 */
native FF2_GetBossIndex(client);

/**
 * Gets current team of Boss
 * @return			Number of boss's team
 */
native FF2_GetBossTeam();

/**
 * Gets the character name of the Boss
 *
 * @param boss	 			Boss's index
 * @param buffer			Buffer for boss' character name
 * @param bufferLength		Length of buffer string
 * @param bossMeaning		0 - "boss" parameter means index of current Boss
 *							1 - "boss" parameter means number of Boss in characters.cfg-1
 * @return					True if boss exists, false if not
 */
native bool:FF2_GetBossSpecial(boss=0, String:buffer[], bufferLength, bossMeaning=0);

/**
 * Gets the current health value of the Boss
 *
 * @param boss		Boss's index
 * @return			Current health of the Boss
 */
native FF2_GetBossHealth(boss=0);

/**
 * Sets the health of the Boss
 *
 * @param boss		Boss's index
 * @param health	New health value
 * @noreturn
 */
native FF2_SetBossHealth(boss, health);

/**
 * Gets the max health of the Boss
 *
 * @param boss	 	Boss's index
 * @return			Max health of the Boss
 */
native FF2_GetBossMaxHealth(boss=0);

/**
 * Sets the max health of the Boss
 *
 * @param boss		Boss's index
 * @param health	New max health value
 * @noreturn
 */
native FF2_SetBossMaxHealth(boss, health);

/**
 * Gets the current number of lives of the Boss
 *
 * @param boss		Boss's index
 * @return 			Number of lives the boss has remaining
 */
native FF2_GetBossLives(boss);

/**
 * Sets the current number of lives of the Boss
 *
 * @param boss		Boss's index
 * @param lives		New number of lives
 * @noreturn
 */
native FF2_SetBossLives(boss, lives);

/**
 * Gets the max number of lives of the Boss
 *
 * @param boss		Boss's index
 * @return			Max number of lives of the Boss
 */
native FF2_GetBossMaxLives(boss);

/**
 * Sets the max number of lives of the Boss
 *
 * @param boss		Boss's index
 * @param lives		New max number of lives
 * @noreturn
 */
native FF2_SetBossMaxLives(boss, lives);

/**
 * Gets the charge meter value of the Boss
 *
 * @param boss		Boss's index
 * @param slot		Slot of charge meter
 *						0 - rage
 *						1 - as usual, used for brave jump or teleport
 *						2 - other charged abilities
 * @return			Charge value of the Boss
 */
native Float:FF2_GetBossCharge(boss, slot);

/**
 * Sets the charge meter value of the Boss
 *
 * @param boss		Boss's index
 * @param slot		Slot of charge meter
 *						0 - rage
 *						1 - as usual, used for brave jump or teleport
 *						2 - other charged abilities
 * @param value		New value of charge
 * @noreturn
 */
native FF2_SetBossCharge(boss, slot, Float:value);

/**
 * Gets how much damage is needed in order to activate the rage of the current boss
 *
 * @param boss	Boss index
 * @return		Total damage needed
 */
native FF2_GetBossRageDamage(boss);

/**
 * Sets how much damage is needed in order to activate the rage of the current boss
 *
 * @param boss		Boss index
 * @param damage	New damage value
 * @noreturn
 */
native FF2_SetBossRageDamage(boss, damage);

/**
 * Gets damage dealt by this client
 *
 * @param client 	Client's index
 * @return			Damage dealt
 */
native FF2_GetClientDamage(client);

/**
 * Gets an ability's rage distance
 *
 * @param boss			Boss's index
 * @param pluginName	Name of plugin with this ability
 * @param abilityName	Name of ability (use null string if you want get boss's global "ragedist" value)
 * @return				Ability's rage distance
 */
native Float:FF2_GetRageDist(boss=0, const String:pluginName[]="", const String:abilityName[]="");

/**
 * Finds if a Boss has a certain ability
 *
 * @param boss			Boss's index
 * @param pluginName	Name of plugin with this ability
 * @param abilityName 	Name of ability
 * @return				True if the boss has this ability, false if it doesn't
 */
native bool:FF2_HasAbility(boss, const String:pluginName[], const String:abilityName[]);

/**
 * Determines how the Boss should use a certain ability
 *
 * @param boss			Boss's index
 * @param pluginName	Name of plugin with this ability
 * @param abilityName 	Name of ability
 * @param slot			Slot of charge meter
 *							0 - rage
 *							1 - as usual, used for brave jump or teleport
 *							2 - other charged abilities
 * @param buttonMode	How to activate the ability
 *							0 - by taunt
 *							1 - by right mouse button or duck
 *							2 - by reload button
 * @noreturn
 */
native FF2_DoAbility(boss, const String:pluginName[], const String:abilityName[], slot, buttonMode=0);

/**
 * Gets the integer value of an ability argument
 *
 * @param boss			Boss's index
 * @param pluginName	Name of plugin with this ability
 * @param abilityName 	Name of ability
 * @param argument 		Number of argument
 * @param defValue 		Returns if argument is not defined
 * @return				Value of argument
 */
native FF2_GetAbilityArgument(boss, const String:pluginName[], const String:abilityName[], argument, defValue=0);

/**
 * Gets the float value of an ability argument
 *
 * @param boss			Boss's index
 * @param pluginName	Name of plugin with this ability
 * @param abilityName 	Name of ability
 * @param argument 		Number of argument
 * @param defValue 		Returns if argument is not defined
 * @return				Value of argument
 */
native Float:FF2_GetAbilityArgumentFloat(boss, const String:plugin_name[], const String:ability_name[], argument, Float:defValue=0.0);

/**
 * Gets the string value of an ability argument
 *
 * @param boss			Boss's index
 * @param pluginName	Name of plugin with this ability
 * @param abilityName 	Name of ability
 * @param argument 		Number of argument
 * @param buffer 		Buffer for value of argument
 * @param bufferLength	Length of buffer string
 * @noreturn
 */
native FF2_GetAbilityArgumentString(boss, const String:pluginName[], const String:abilityName[], argument, String:buffer[], bufferLength);

/**
 * Starts a random Boss sound from its config file
 *
 * @param keyvalue		Name of sound container
 * @param buffer		Buffer for result sound path
 * @param bufferLength	Length of buffer
 * @param boss			Boss's index
 * @param slot			Only for "sound_ability" - slot of ability
 * @return				True if sound has been found, false otherwise
 */
native bool:FF2_RandomSound(const String:keyvalue[], String:buffer[], bufferLength, boss=0, slot=0);

/**
 * Starts the Boss's music for the specified clients
 *
 * @param client	Client's index (0 for all clients)
 * @noreturn
 */
native FF2_StartMusic(client=0);

/**
 * Stops the Boss's music for the specified clients
 *
 * @param client	Client's index (0 for all clients)
 * @noreturn
 */
native FF2_StopMusic(client=0);

/**
 * Gets a Boss's KV handle
 *
 * @param boss				Boss's index
 * @param specialIndex		0 - 'boss' parameter refers to the index of the boss
 *							1 - 'boss' parameter refers to the index of the boss in characters.cfg-1
 * @return					Handle of Boss's keyvalues
 */
native Handle:FF2_GetSpecialKV(boss, specialIndex=0);

/**
 * Gets a client's flags for FF2
 *
 * @param client	Client's index
 * @return			Client's FF2 flags
 */
native FF2_GetFF2flags(client);

/**
 * Sets a client's flags for FF2
 *
 * @param client	Client's index
 * @param flags		New flag values
 * @noreturn
 */
native FF2_SetFF2flags(client, flags);

/**
 * Gets a client's queue points
 *
 * @param client	Client's index
 * @return			Client's queue points
 */
native FF2_GetQueuePoints(client);

/**
 * Sets a client's queue points
 *
 * @param client	Client's index
 * @param value		New value of client's queue points
 * @noreturn
 */
native FF2_SetQueuePoints(client, value);

/**
 * Gets a client's glow timer
 *
 * @param client	Client's index
 * @return			Number of seconds left until client glow disappears (-1 if invalid client)
 */
native Float:FF2_GetClientGlow(client);

/**
 * Sets a client's glow timer
 *
 * @param client	Client's index
 * @param time1		Number of seconds to add to the glow timer (can be negative)
 * @param time2		New value of glow timer
 * @noreturn
 */
native FF2_SetClientGlow(client, Float:time1, Float:time2=-1.0);

/**
 * Retrieves the number of alive players left (not including bosses)
 *
 * @return			Number of non-boss players left alive
 */
#pragma deprecated Use FF2_OnAlivePlayersChanged
native FF2_GetAlivePlayers();

/**
 * Retrieves the number of boss players left (including minions)
 *
 * @return			Number of boss players left alive
 */
#pragma deprecated Use FF2_OnAlivePlayersChanged
native FF2_GetBossPlayers();

/**
 * Returns whether or not debug is enabled
 * @return			True if enabled, false otherwise
 */
native bool:FF2_Debug();

/**
 * FF2_ONABILITY IS KNOWN TO BE BUGGED AND WILL NOT BE FIXED TO PRESERVE BACKWARDS COMPATABILITY.  DO NOT USE IT.
 * Called when a Boss uses an ability (Rage, jump, teleport, etc)
 * Called every 0.2 seconds for charge abilities
 *
 * Use FF2_PreAbility with enabled=false ONLY to prevent FF2_OnAbility!
 *
 * @param boss	 		Boss's index
 * @param pluginName	Name of plugin with this ability
 * @param abilityName 	Name of ability
 * @param slot			Slot of ability (THIS DOES NOT RETURN WHAT YOU THINK IT RETURNS FOR FF2_ONABILITY-if you insist on using this, refer to freak_fortress_2.sp to see what it actually does)
 * 							0 - Rage or life-loss
 * 							1 - Jump or teleport
 * 							2 - Other
 * @param status		Status of ability (DO NOT ACCESS THIS.  IT DOES NOT EXIST AND MIGHT CRASH YOUR SERVER)
 * @return				Plugin_Stop can not prevent the ability. Use FF2_PreAbility with enabled=false
 */
forward FF2_PreAbility(boss, const String:pluginName[], const String:abilityName[], slot, &bool:enabled);
forward Action:FF2_OnAbility(boss, const String:pluginName[], const String:abilityName[], slot, status);

/**
 * Called when a Boss gets hurt by environmental damage
 *
 * @param boss	 		Boss's index
 * @param triggerHurt	Entity index of "trigger_hurt"
 * @param damage 		Damage by "trigger_hurt".  Cutomizable.
 * @return				Plugin_Stop will prevent forward, Plugin_Changed will change damage.
 */
forward Action:FF2_OnTriggerHurt(boss, triggerHurt, &Float:damage);

/**
 * Called when a Boss's music begins
 *
 * @param path 			Path to music sound file
 * @param time			Length of music
 * @return				Plugin_Stop will prevent music, Plugin_Changed will change it.
 */
forward Action:FF2_OnMusic(String:path[], &Float:time);


/**
 * Called when FF2 picks a character for a Boss
 *
 * @param boss			Boss index
 * @param character   	Character index
 * @param characterName	Character name
 * @param preset		True if the boss was set using a command such as ff2_special
 * @return				You can NOT use Plugin_Stop to prevent this, but you can change characterName and use Plugin_Changed to change the boss.  If you want to change 'character', then make 'characterName' null.
 */
forward Action:FF2_OnSpecialSelected(boss, &character, String:characterName[], bool:preset);

/**
 * Called when FF2 adds queue points
 *
 * @param add_points	Array that contains each player's queue points
 *
 * @return	Plugin_Stop will prevent this, Plugin_Changed will change it.
 */
forward Action:FF2_OnAddQueuePoints(add_points[MAXPLAYERS+1]);

/**
 * Called when FF2 picks a character set for the map
 *
 * @param charSetNum	Number of character set
 * @param charSetName	Name of character set
 * @return				You can NOT use Plugin_Stop to prevent this, but you can change charSetName and use Plugin_Changed to change the character set.  If you want to change charSetNum, then make charSetName null.
 */
forward Action:FF2_OnLoadCharacterSet(&charSetNum, String:charSetName[]);

/**
 * Called when a Boss loses a life
 *
 * @param boss		Boss's index
 * @param lives		Number of lives left
 * @param maxLives	Max number of lives
 * @return			Plugin_Stop or Plugin_Handled to prevent damage that would remove a life, Plugin_Changed if you want to change the number of lives left.
 */
forward Action:FF2_OnLoseLife(boss, &lives, maxLives);

/**
 * Called when the number of alive players changes.  Note that this will never be 0 as FF2 does not re-calculate the number of players once the round ends.
 *
 * @param players	Number of alive players left on the non-boss team
 * @param bosses	Number of alive players left on the boss team (this includes minions as well)
 * @noreturn
 */
forward Action:FF2_OnAlivePlayersChanged(players, bosses);

/**
 *
 * Gives ammo to a weapon
 *
 * @param client	Client's index
 * @param weapon	Weapon
 * @param ammo		Ammo (set to 1 for clipless weapons, then set the actual ammo using clip)
 * @param clip		Clip
 * @noreturn
 */
stock FF2_SetAmmo(client, weapon, ammo=-1, clip=-1)
{
	if(IsValidEntity(weapon))
	{
		if(clip>-1)
		{
			SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
		}

		new ammoType=(ammo>-1 ? GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType") : -1);
		if(ammoType!=-1)
		{
			SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, ammoType);
		}
		else if(ammo>-1)  //Only complain if we're trying to set ammo
		{
			decl String:classname[64], String:bossName[32];
			GetEdictClassname(weapon, classname, sizeof(classname));
			FF2_GetBossSpecial(FF2_GetBossIndex(client), bossName, sizeof(bossName));
			LogError("[FF2] Cannot give ammo to weapon %s (boss %s)-check your config!", classname, bossName);
		}
	}
}

/**
 * Sends a synced HUD message according to FF2's rules
 * Will only send if the client hasn't disabled their HUD and isn't checking the scoreboard
 *
 * Uses the same params and return values as ShowSyncHudText
 */
stock FF2_ShowSyncHudText(client, Handle:sync, const String:buffer[], any:...)
{
	if(!(FF2_GetFF2flags(client) & FF2FLAG_HUDDISABLED) && !(GetClientButtons(client) & IN_SCORE))
	{
		decl String:message[256];
		VFormat(message, sizeof(message), buffer, 4);
		ShowSyncHudText(client, sync, message);
	}
}

/**
 * Sends a HUD message according to FF2's rules
 * Will only send if the client hasn't disabled their HUD and isn't checking the scoreboard
 *
 * Uses the same params and return values as ShowHudText
 */
stock FF2_ShowHudText(client, channel, const String:buffer[], any:...)
{
	if(!(FF2_GetFF2flags(client) & FF2FLAG_HUDDISABLED) && !(GetClientButtons(client) & IN_SCORE))
	{
		decl String:message[256];
		VFormat(message, sizeof(message), buffer, 4);
		ShowHudText(client, channel, message);
	}
}

/**
 * Used to consolidate debug messages
 *
 * @param buffer	Debug string to display
 * @param any:...	Formatting rules
 * @noreturn
 */
stock Debug(String:buffer[], any:...)
{
	if(FF2_Debug())
	{
		decl String:message[192];
		VFormat(message, sizeof(message), buffer, 2);
		CPrintToChatAll("{olive}[FF2 {darkorange}DEBUG{olive}]{default} %s", message);
		PrintToServer("[FF2 DEBUG] %s", message);
	}
}

// These exist for compatibility reasons (<1.10.1)
#pragma deprecated Use TF2_RemoveWeaponSlot
stock TF2_RemoveWeaponSlot2(client, slot)
{
	TF2_RemoveWeaponSlot(client, slot);
}

#pragma deprecated Use TF2_RemoveAllWeapons
stock TF2_RemoveAllWeapons2(client)
{
	for(new slot=0; slot<=5; slot++)
	{
		TF2_RemoveWeaponSlot(client, slot);
	}
}

public SharedPlugin:__pl_FF2=
{
	name="freak_fortress_2",
	file="freak_fortress_2.smx",
	#if defined REQUIRE_PLUGIN
		required=1,
	#else
		required=0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_FF2_SetNTVOptional()
{
	MarkNativeAsOptional("FF2_IsFF2Enabled");
	MarkNativeAsOptional("FF2_GetFF2Version");
	MarkNativeAsOptional("FF2_GetBossUserId");
	MarkNativeAsOptional("FF2_GetBossIndex");
	MarkNativeAsOptional("FF2_GetBossTeam");
	MarkNativeAsOptional("FF2_GetBossSpecial");
	MarkNativeAsOptional("FF2_GetBossHealth");
	MarkNativeAsOptional("FF2_SetBossHealth");
	MarkNativeAsOptional("FF2_GetBossMaxHealth");
	MarkNativeAsOptional("FF2_SetBossMaxHealth");
	MarkNativeAsOptional("FF2_GetBossLives");
	MarkNativeAsOptional("FF2_SetBossLives");
	MarkNativeAsOptional("FF2_GetBossMaxLives");
	MarkNativeAsOptional("FF2_SetBossMaxLives");
	MarkNativeAsOptional("FF2_GetBossCharge");
	MarkNativeAsOptional("FF2_SetBossCharge");
	MarkNativeAsOptional("FF2_GetBossRageDamage");
	MarkNativeAsOptional("FF2_SetBossRageDamage");
	MarkNativeAsOptional("FF2_GetClientDamage");
	MarkNativeAsOptional("FF2_GetRoundState");
	MarkNativeAsOptional("FF2_GetRageDist");
	MarkNativeAsOptional("FF2_HasAbility");
	MarkNativeAsOptional("FF2_GetAbilityArgument");
	MarkNativeAsOptional("FF2_GetAbilityArgumentFloat");
	MarkNativeAsOptional("FF2_GetAbilityArgumentString");
	MarkNativeAsOptional("FF2_RandomSound");
	MarkNativeAsOptional("FF2_StartMusic");
	MarkNativeAsOptional("FF2_StopMusic");
	MarkNativeAsOptional("FF2_GetSpecialKV");
	MarkNativeAsOptional("FF2_GetQueuePoints");
	MarkNativeAsOptional("FF2_SetQueuePoints");
	MarkNativeAsOptional("FF2_GetFF2flags");
	MarkNativeAsOptional("FF2_SetFF2flags");
	MarkNativeAsOptional("FF2_DoAbility");
	MarkNativeAsOptional("FF2_GetClientGlow");
	MarkNativeAsOptional("FF2_SetClientGlow");
	MarkNativeAsOptional("FF2_GetAlivePlayers");
	MarkNativeAsOptional("FF2_GetBossPlayers");
	MarkNativeAsOptional("FF2_Debug");
}
#endif
