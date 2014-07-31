#if defined _ff2_external_included
  #endinput
#endif
#define _ff2_external_included

#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <rtd>
#define REQUIRE_PLUGIN

#if defined _goomba_included_
/*
 * This forward is for subplugin authors to use as it will tell FF2 if it's override for the enemy of the boss needs to be cancelled out.
 * Note: This is called when the boss is stomping the player.
 * @return Plugin_Continue to allow FF2 to do it's override, Plugin_Changed to override FF2's override, Plugin_Handled to stop stomp alltogether.
 */
forward Action:OnFF2PlayerStompOverride(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower);

/*
 * This forward is for subplugin authors to use as it will tell FF2 if it's override for the boss needs to be cancelled out.
 * Note: This is called when the boss is being stomped.
 * @return Plugin_Continue to allow FF2 to do it's override, Plugin_Changed to override FF2's override, Plugin_Handled to stop stomp alltogether.
 */
forward Action:OnFF2BossStompOverride(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower);
#endif

#if defined _rtd_included
/*
 * This forward is for subplugin authors to use as it will tell FF2 if it's override needs to be cancelled out.
 * @return Plugin_Continue to allow FF2 to do it's override, Plugin_Handled to stop roll alltogether.
 */
forward Action:OnFF2RtdOverride(client);
#endif

public SharedPlugin:__pl_ff2_external_2 =
{
	name = "ff2 external",
	file = "ff2_external_integration.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
