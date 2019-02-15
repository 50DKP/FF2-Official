//Freak Fortress 2 include file.
#include <morecolors>
#include <sdktools>

#define FF2FLAG_UBERREADY               (1<<1)      //Used when medic says "I'm charged!"
#define FF2FLAG_ISBUFFED                (1<<2)      //Used when soldier uses the Battalion's Backup
#define FF2FLAG_CLASSTIMERDISABLED      (1<<3)      //Used to prevent clients' timer
#define FF2FLAG_HUDDISABLED             (1<<4)      //Used to prevent custom hud from clients' timer
#define FF2FLAG_BOTRAGE                 (1<<5)      //Used by bots to use Boss's rage
#define FF2FLAG_ALLOWSPAWNINBOSSTEAM    (1<<6)      //Used to allow spawn players in Boss's team
#define FF2FLAG_USEBOSSTIMER            (1<<7)      //Used to prevent Boss's timer
#define FF2FLAG_USINGABILITY            (1<<8)      //Used to prevent Boss's hints about abilities buttons
#define FF2FLAG_CLASSHELPED             (1<<9)
#define FF2FLAG_HASONGIVED              (1<<10)
#define FF2FLAG_CHANGECVAR              (1<<11)     //Used to prevent SMAC from kicking bosses who are using certain rages (NYI)
#define FF2FLAG_ALLOW_HEALTH_PICKUPS    (1<<12)     //Used to prevent bosses from picking up health
#define FF2FLAG_ALLOW_AMMO_PICKUPS      (1<<13)     //Used to prevent bosses from picking up ammo
#define FF2FLAG_BLAST_JUMPING           (1<<14)     //Used when a soldier is rocket jumping
#define FF2FLAGS_SPAWN                  ~FF2FLAG_UBERREADY & ~FF2FLAG_ISBUFFED & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM & ~FF2FLAG_CHANGECVAR & ~FF2FLAG_BLAST_JUMPING & FF2FLAG_USEBOSSTIMER & FF2FLAG_USINGABILITY

#define FF2SOUND_MUTENONE 0
#define FF2SOUND_MUTEMUSIC 1<<0
#define FF2SOUND_MUTEVOICE 1<<1
#define FF2SOUND_MUTEALL FF2SOUND_MUTEMUSIC | FF2SOUND_MUTEVOICE

#if defined _FF2_included
 #endinput
#endif
#define _FF2_included

/**
 * Is Freak Fortress 2 enabled?
 *
 * @return False if FF2 is disabled
 *         True if FF2 is enabled
 */
native bool:FF2_IsFF2Enabled();

/**
 * Register a subplugin with FF2
 *
 * @param pluginName Name of the subplugin to register
 *
 * @noreturn
 */
native FF2_RegisterSubplugin(String:pluginName[]);

/**
 * Unregister a subplugin with FF2
 *
 * @param pluginName Name of the subplugin to unregister
 *
 * @noreturn
 */
native FF2_UnregisterSubplugin(String:pluginName[]);

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
 * @return -1 - game is still loading
 *          0 - in setup
 *          1 - round is in progress (due to a bug in arena mode, stalemate will also return 1)
 *          2 - someone wins
 */
native FF2_GetRoundState();

/**
 * Gets the userid of the boss
 *
 * @param boss      Boss's index
 * @return          Userid of boss (-1 if Boss does not exist)
 */
native FF2_GetBossUserId(boss=0);

/**
 * Gets the boss index of a client
 *
 * @param client    The client used to search for the boss index
 * @return          Boss index of that client.  If client is not boss, returns -1
 */
native FF2_GetBossIndex(client);

/**
 * Gets the boss's team
 * @return          Boss's team
 */
native TFTeam:FF2_GetBossTeam();

/**
 * Gets the character name of the boss
 *
 * @param boss              Boss's index
 * @param bossName          Buffer for boss's character name
 * @param length            Length of buffer string
 * @return                  True if boss exists, false if not
 */
native bool:FF2_GetBossName(boss=0, String:bossName[], length);

/**
 * Gets a Boss's KV handle
 *
 * @param boss              Boss's index
 * @return                  Boss's KV handle or INVALID_HANDLE if boss index is invalid
 */
native Handle:FF2_GetBossKV(boss=0);

/**
 * Gets the current health value of the Boss
 *
 * @param boss      Boss's index
 * @return          Current health of the Boss
 */
native FF2_GetBossHealth(boss=0);

/**
 * Sets the health of the Boss
 *
 * @param boss      Boss's index
 * @param health    New health value
 * @noreturn
 */
native FF2_SetBossHealth(boss, health);

/**
 * Gets the max health of the Boss
 *
 * @param boss      Boss's index
 * @return          Max health of the Boss
 */
native FF2_GetBossMaxHealth(boss=0);

/**
 * Sets the max health of the Boss
 *
 * @param boss      Boss's index
 * @param health    New max health value
 * @noreturn
 */
native FF2_SetBossMaxHealth(boss, health);

/**
 * Gets the current number of lives of the Boss
 *
 * @param boss      Boss's index
 * @return          Number of lives the boss has remaining
 */
native FF2_GetBossLives(boss=0);

/**
 * Sets the current number of lives of the Boss
 *
 * @param boss      Boss's index
 * @param lives     New number of lives
 * @noreturn
 */
native FF2_SetBossLives(boss, lives);

/**
 * Gets the max number of lives of the Boss
 *
 * @param boss      Boss's index
 * @return          Max number of lives of the Boss
 */
native FF2_GetBossMaxLives(boss=0);

/**
 * Sets the max number of lives of the Boss
 *
 * @param boss      Boss's index
 * @param lives     New max number of lives
 * @noreturn
 */
native FF2_SetBossMaxLives(boss, lives);

/**
 * Gets the charge meter value of the Boss
 *
 * @param boss      Boss's index
 * @param slot      Slot of charge meter
 *                      0 - rage
 *                      1 - as usual, used for brave jump or teleport
 *                      2 - other charged abilities
 * @return          Charge value of the Boss
 */
native Float:FF2_GetBossCharge(boss, slot);

/**
 * Sets the charge meter value of the Boss
 *
 * @param boss      Boss's index
 * @param slot      Slot of charge meter
 *                      0 - rage
 *                      1 - as usual, used for brave jump or teleport
 *                      2 - other charged abilities
 * @param value     New value of charge
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
 * Gets an ability's rage distance
 *
 * @param boss          Boss index
 * @param pluginName    Name of plugin with this ability
 * @param abilityName   Name of ability (use an empty string if you want get the boss's global "rage distance" value)
 * @return              Ability's rage distance
 */
native FF2_GetBossRageDistance(boss=0, const String:pluginName[]="", const String:abilityName[]="");

/**
 * Gets damage dealt by this client
 *
 * @param client    Client's index
 * @return          Damage dealt
 */
native FF2_GetClientDamage(client);

/**
 * Sets damage dealt by this client
 *
 * @param client 	Client's index
 * @param damage	New damage dealt
 * @noreturn
 */
native FF2_SetClientDamage(client, damage);

/**
 * Finds if a Boss has a certain ability
 *
 * @param boss          Boss's index
 * @param pluginName    Name of plugin with this ability
 * @param abilityName   Name of ability
 * @return              True if the boss has this ability, false if it doesn't
 */
native bool:FF2_HasAbility(boss, const String:pluginName[], const String:abilityName[]);

/**
 * Gets the integer value of an ability argument
 *
 * @param boss          Boss's index
 * @param pluginName    Name of plugin with this ability
 * @param abilityName   Name of ability
 * @param argument      Name of argument
 * @param defaultValue  Value to return if argument does not exist
 * @return              Value of argument
 */
native FF2_GetAbilityArgument(boss, const String:pluginName[], const String:abilityName[], const String:argument[], defaultValue=0);

/**
 * Gets the float value of an ability argument
 *
 * @param boss          Boss's index
 * @param pluginName    Name of plugin with this ability
 * @param abilityName   Name of ability
 * @param argument      Name of argument
 * @param defaultValue  Value to return if argument does not exist
 * @return              Value of argument
 */
native Float:FF2_GetAbilityArgumentFloat(boss, const String:pluginName[], const String:abilityName[], const String:argument[], Float:defaultValue=0.0);

/**
 * Gets the string value of an ability argument
 *
 * @param boss          Boss's index
 * @param pluginName    Name of plugin with this ability
 * @param abilityName   Name of ability
 * @param argument      Name of argument
 * @param buffer        Buffer for value of argument
 * @param bufferLength  Length of buffer string
 * @param defaultValue  Value to return if argument does not exist
 * @noreturn
 */
native FF2_GetAbilityArgumentString(boss, const String:pluginName[], const String:abilityName[], const String:argument[], String:buffer[], bufferLength, String:defaultValue[]="");

/**
 * Determines how the Boss should use a certain ability
 *
 * @param boss          Boss's index
 * @param pluginName    Name of plugin with this ability
 * @param abilityName   Name of ability
 * @param slot          Slot of charge meter
 *                          0 - rage
 *                          1 - as usual, used for brave jump or teleport
 *                          2 - other charged abilities
 * @param buttonMode    How to activate the ability
 *                          0 - by calling for medic
 *                          1 - by right mouse button or duck
 *                          2 - by reload button
 * @noreturn
 */
native FF2_UseAbility(boss, const String:pluginName[], const String:abilityName[], slot, buttonMode=0);

/**
 * Gets a client's FF2 flags
 *
 * @param client    Client's index
 * @return          Client's FF2 flags
 */
native FF2_GetFF2Flags(client);

/**
 * Sets a client's FF2 flags
 *
 * @param client    Client's index
 * @param flags     New flag values
 * @noreturn
 */
native FF2_SetFF2Flags(client, flags);

/**
 * Gets a client's queue points
 *
 * @param client    Client's index
 * @return          Client's queue points
 */
native FF2_GetQueuePoints(client);

/**
 * Sets a client's queue points
 *
 * @param client    Client's index
 * @param value     New value of client's queue points
 * @noreturn
 */
native FF2_SetQueuePoints(client, value);

/**
 * Starts the Boss's music for the specified clients
 *
 * @param client    Client's index (0 for all clients)
 * @noreturn
 */
native FF2_StartMusic(client=0);

/**
 * Stops the Boss's music for the specified clients
 *
 * @param client    Client's index (0 for all clients)
 * @noreturn
 */
native FF2_StopMusic(client=0);

/**
 * Finds a random Boss sound from its config file
 *
 * @param sound         Sound string to look for
 * @param file          Buffer for sound file
 * @param length        Length of sound
 * @param boss          Boss's index
 * @param ability       True if the sound should be played for abilities
 * @param slot          Slot of ability - only checked if 'ability' is true
 * @return              True if a sound was found, false otherwise
 */
native bool:FF2_FindSound(const String:sound[], String:file[], length, boss=0, bool:ability=false, slot=0);

/**
 * Gets a client's glow timer
 *
 * @param client    Client's index
 * @return          Number of seconds left until client glow disappears (-1 if invalid client)
 */
native Float:FF2_GetClientGlow(client);

/**
 * Sets a client's glow timer
 *
 * @param client    Client's index
 * @param time1     Number of seconds to add to the glow timer (can be negative)
 * @param time2     New value of glow timer
 * @noreturn
 */
native FF2_SetClientGlow(client, Float:time1, Float:time2=-1.0);

/**
 * Returns whether or not debug is enabled
 * @return          True if enabled, false otherwise
 */
native bool:FF2_Debug();

/**
 * Set sound flags for specified client
 *
 * @param client    Client's index
 * @param flags     Flags which to set
 * @noreturn
 */
native FF2_SetSoundFlags(client, flags);

/**
 * Clear sound flags for specified client
 *
 * @param client    Client's index
 * @param flags     Flags which to clear
 * @noreturn
 */
native FF2_ClearSoundFlags(client, flags);

/**
 * Check sound flags for specified client
 *
 * @param client    Client's index
 * @param flags     Flags which to check
 * @return          True if the client does _not_ have the given flags, false otherwise
 */
native bool:FF2_CheckSoundFlags(client, flags);

/**
 * Called whenever a boss uses an ability (Rage, jump, teleport, etc)
 * Called every 0.2 seconds for charge abilities
 *
 * @param boss          Boss's index
 * @param pluginName    Name of plugin with this ability
 * @param abilityName   Name of ability
 * @param slot          Slot of ability
 *                         -1 - Life-loss
 *                          0 - Rage
 *                          1 - Jump or teleport
 *                          2 - Other
 * @param status        Status of ability (FF2_OnAbility only)
 *                          0 - Not in use
 *                          1 - Recharging
 *                          2 - Ready
 *                          3 - In use
 * @return              Plugin_Handled or Plugin_Stop for FF2_PreAbility to prevent FF2_OnAbility
 */
forward Action:FF2_PreAbility(boss, const String:pluginName[], const String:abilityName[], slot);
forward FF2_OnAbility(boss, const String:pluginName[], const String:abilityName[], slot, status);

/**
 * Called when a boss rages
 *
 * @param boss          Boss's index
 * @param distance      Rage distance
 * @return              Plugin_Changed to change rage distance, Plugin_Handled or Plugin_Stop to prevent rage
 */
forward Action:FF2_OnRage(boss, &distance);

/**
 * Called when a boss super jumps (this includes teleports)
 *
 * @param boss              Boss's index
 * @param superDuperJump    Whether or not super duper jump is enabled
 * @return                  Plugin_Changed to change super duper jump status, Plugin_Handled or Plugin_Stop to prevent super jump
 */
forward Action:FF2_OnSuperJump(boss, &bool:superDuperJump);

/**
 * Called when a boss uses weighdown
 *
 * @param boss          Boss's index
 * @return              Plugin_Handled or Plugin_Stop to prevent weighdown
 */
forward Action:FF2_OnWeighdown(boss);

/**
 * Called when a Boss gets hurt by environmental damage
 *
 * @param boss          Boss's index
 * @param triggerHurt   Entity index of "trigger_hurt"
 * @param damage        Damage by "trigger_hurt".  Cutomizable.
 * @return              Plugin_Stop will prevent damage, Plugin_Changed will change damage.
 */
forward Action:FF2_OnTriggerHurt(boss, triggerHurt, &Float:damage);

/**
 * Called when a Boss's music begins for a client
 *
 * @param client        Client the music is starting for
 * @param path          Path to music sound file
 * @param time          Music length
 * @return              Plugin_Stop will prevent music, Plugin_Changed will change it.
 */
forward Action:FF2_OnMusic(client, String:path[], &time);

/**
 * Called when FF2 picks a boss
 *
 * @param boss			Boss index
 * @param character   	Character index
 * @param characterName	Character name
 * @param preset		True if the boss was set using a command such as ff2_special
 * @return				You can NOT use Plugin_Stop to prevent this, but you can change characterName and use Plugin_Changed to change the boss.  If you want to change 'character', then make 'characterName' null.
 */
forward Action:FF2_OnBossSelected(boss, &character, String:characterName[], bool:preset);

/**
 * Called when FF2 adds queue points
 *
 * @param add_points    Array that contains each player's queue points
 *
 * @return	Plugin_Stop will prevent this, Plugin_Changed will change it.
 */
forward Action:FF2_OnAddQueuePoints(add_points[MAXPLAYERS+1]);

/**
 * Called when FF2 picks a character set for the map
 *
 * @param characterSet	Name of character set
 * @return				You can NOT use Plugin_Stop to prevent this, but you can change characterSet and return Plugin_Changed to change the character set.
 */
forward Action:FF2_OnLoadCharacterSet(String:characterSet[]);

/**
 * Called when a boss loses a life
 *
 * @param boss      Boss's index
 * @param lives     Number of lives left
 * @param maxLives  Max number of lives
 * @return          Plugin_Stop or Plugin_Handled to prevent damage that would remove a life, Plugin_Changed if you want to change the number of lives left.  Setting lives to a value greater than maxLives will also set maxLives to that value.
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
 * Called when an unknown variable is encountered while parsing a formula
 *
 * @param variable      Unknown variable
 * @param variableValue Value of the variable
 * @return              Plugin_Changed to allocate variableValue to the unknown variable
 */
forward Action:FF2_OnParseUnknownVariable(String:variable[], &Float:variableValue);

/**
 * Gives ammo to a weapon
 *
 * @param client    Client's index
 * @param weapon    Weapon
 * @param ammo      Ammo (set to 1 for clipless weapons, then set the actual ammo using clip)
 * @param clip      Clip
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
			FF2_GetBossName(FF2_GetBossIndex(client), bossName, sizeof(bossName));
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
	if(!(FF2_GetFF2Flags(client) & FF2FLAG_HUDDISABLED) && !(GetClientButtons(client) & IN_SCORE))
	{
		decl String:message[256];
		SetGlobalTransTarget(client);
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
	if(!(FF2_GetFF2Flags(client) & FF2FLAG_HUDDISABLED) && !(GetClientButtons(client) & IN_SCORE))
	{
		decl String:message[256];
		SetGlobalTransTarget(client);
		VFormat(message, sizeof(message), buffer, 4);
		ShowHudText(client, channel, message);
	}
}

/**
 * Breaks a string into pieces and stores each piece into an ArrayList.
 * Based off of string.inc's ExplodeString
 *
 * @param text				The string to split.
 * @param split				The string to use as a split delimiter.
 * @param list			    An ArrayList to store the split strings.
 * @param maxStringLength   Maximum length of each string buffer.
 * @return					Number of strings retrieved.
 */
stock int ExplodeStringIntoArrayList(const String:text[], const String:split[], Handle:list, maxStringLength)
{
	new reloc_idx, index, total;
	new String:temp[maxStringLength];

	if(!split[0])
	{
		return 0;
	}

	while((index=SplitString(text[reloc_idx], split, temp, maxStringLength))!=-1)
	{
		reloc_idx+=index;
		PushArrayString(list, temp);
		total++;
	}

	PushArrayString(list, text[reloc_idx]);
	total++;

	return total;
}

/**
 * Used to consolidate debug messages
 *
 * @param buffer    Debug string to display
 * @param any:...   Formatting rules
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
    MarkNativeAsOptional("FF2_RegisterSubplugin");
    MarkNativeAsOptional("FF2_UnregisterSubplugin");
	MarkNativeAsOptional("FF2_GetFF2Version");
	MarkNativeAsOptional("FF2_GetRoundState");
	MarkNativeAsOptional("FF2_GetBossUserId");
	MarkNativeAsOptional("FF2_GetBossIndex");
	MarkNativeAsOptional("FF2_GetBossTeam");
	MarkNativeAsOptional("FF2_GetBossName");
	MarkNativeAsOptional("FF2_GetBossKV");
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
	MarkNativeAsOptional("FF2_GetBossRageDistance");
	MarkNativeAsOptional("FF2_GetClientDamage");
	MarkNativeAsOptional("FF2_SetClientDamage");
	MarkNativeAsOptional("FF2_HasAbility");
	MarkNativeAsOptional("FF2_GetAbilityArgument");
	MarkNativeAsOptional("FF2_GetAbilityArgumentFloat");
	MarkNativeAsOptional("FF2_GetAbilityArgumentString");
	MarkNativeAsOptional("FF2_UseAbility");
	MarkNativeAsOptional("FF2_GetFF2Flags");
	MarkNativeAsOptional("FF2_SetFF2Flags");
	MarkNativeAsOptional("FF2_GetQueuePoints");
	MarkNativeAsOptional("FF2_SetQueuePoints");
	MarkNativeAsOptional("FF2_StartMusic");
	MarkNativeAsOptional("FF2_StopMusic");
	MarkNativeAsOptional("FF2_FindSound");
	MarkNativeAsOptional("FF2_GetClientGlow");
	MarkNativeAsOptional("FF2_SetClientGlow");
	MarkNativeAsOptional("FF2_Debug");
}
#endif
