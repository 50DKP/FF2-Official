#if defined _rtd_included
  #endinput
#endif
#define _rtd_included

public SharedPlugin:__pl_rtd = 
{
	name = "TF2: Roll the Dice",
	file = "rtd.smx",
	required = 1
};

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

/**
 * Called everytime rtd is activated to determine if the player can use the dice mod.
 * Return Plugin_Continue to allow, anything else denies them access.
 *
 * @note The force and random admin RTD commands do not call this.
 *
 * @param client		Client Index.
 */
forward Action:RTD_CanRollDice(client);

/**
 * Roll a random effect on a given player.
 *
 * @param client		Client Index.
 * @param perk			Perk you'd like to force. Set to PERK_NONE to randomly pick one.
 */
native RTD_Roll(client, g_eCurrentPerk:nPerk=g_eCurrentPerk:-1);

public SharedPlugin:__pl_rtd =
{
	name = "TF2: Roll the Dice",
	file = "rtd.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_rtd_SetNTVOptional()
{
	MarkNativeAsOptional("RTD_Roll");
}
#endif
