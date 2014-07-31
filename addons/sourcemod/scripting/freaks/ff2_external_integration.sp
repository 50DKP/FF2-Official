//Freak Fortress 2 External Integration Subplugin
//Used to balance popular external plugins with FF2
//Currently supports: Goomba Stomp, RTD
#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>
#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <rtd>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "2.0.0"

#if defined _goomba_included
new bool:goomba;
#endif

#if defined _rtd_included
new bool:rtd;
#endif

new Handle:cvarGoombaDamage;
new Handle:cvarGoombaRebound;
new Handle:cvarBossRTD;

new Float:goombaDamage;
new Float:goombaReboundPower;
new bool:canBossRTD;