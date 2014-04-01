/*
===Freak Fortress 2===

By Rainbolt Dash: programmer, modeller, mapper, painter.
Author of Demoman The Pirate: http://www.randomfortress.ru/thepirate/
And one of two creators of Floral Defence: http://www.polycount.com/forum/showthread.php?t=73688
And author of VS Saxton Hale Mode

Plugin thread on AlliedMods: http://forums.alliedmods.net/showthread.php?t=182108

Updated by Otokiru, Powerlord, and RavensBro after Rainbolt Dash got sucked into DOTA2

Updated by Wliu, Chris, Lawd, and Carge after Powerlord quit FF2
*/
#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>
#include <sdktools>
#include <sdktools_gamerules>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <clientprefs>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#tryinclude <updater>
#tryinclude <goomba>
#tryinclude <rtd>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.10.0 Beta 3"
#define DEV_VERSION

#define UPDATE_URL "http://198.27.69.149/updater/ff2-official/update.txt"

#define MAXENTITIES 2048
#define MAXSPECIALS 64
#define MAXRANDOMS 16

#define SOUNDEXCEPT_MUSIC 0
#define SOUNDEXCEPT_VOICE 1

#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255
#define MONOCULUS "eyeball_boss"
#define DISABLED_PERKS "toxic,noclip,uber,ammo,instant,jump,tinyplayer"

#if defined _steamtools_included
new bool:steamtools=false;
#endif

new bool:smac=false;

new bool:b_allowBossChgClass=false;
new bool:b_BossChgClassDetected=false;
new OtherTeam=2;
new BossTeam=3;
new playing;
new healthcheckused;
new RedAlivePlayers;
new RoundCount;
new Special[MAXPLAYERS+1];
new Incoming[MAXPLAYERS+1];
new MusicIndex;

new Damage[MAXPLAYERS+1];
new curHelp[MAXPLAYERS+1];	
new uberTarget[MAXPLAYERS+1];
new demoShield[MAXPLAYERS+1];

new FF2flags[MAXPLAYERS+1];

new Boss[MAXPLAYERS+1];
new BossHealthMax[MAXPLAYERS+1];
new BossHealth[MAXPLAYERS+1];
new BossHealthLast[MAXPLAYERS+1];
new BossLives[MAXPLAYERS+1];
new BossLivesMax[MAXPLAYERS+1];
new Float:BossCharge[MAXPLAYERS+1][8];
new Float:Stabbed[MAXPLAYERS+1];
new Float:KSpreeTimer[MAXPLAYERS+1];
new KSpreeCount[MAXPLAYERS+1];
new Float:GlowTimer[MAXPLAYERS+1];
new TFClassType:LastClass[MAXPLAYERS+1];
new shortname[MAXPLAYERS+1];

new timeleft;

new Handle:cvarVersion;
new Handle:cvarPointDelay;
new Handle:cvarAnnounce;
new Handle:cvarEnabled;
new Handle:cvarAliveToEnable;
new Handle:cvarPointType;
new Handle:cvarCrits;
new Handle:cvarFirstRound;
new Handle:cvarCircuitStun;
new Handle:cvarSpecForceBoss;
new Handle:cvarCountdownPlayers;
new Handle:cvarCountdownTime;
new Handle:cvarCountdownHealth;
new Handle:cvarEnableEurekaEffect;
new Handle:cvarForceBossTeam;
new Handle:cvarHealthBar;
new Handle:cvarAllowSpectators;
new Handle:cvarHalloween;
new Handle:cvarLastPlayerGlow;
new Handle:cvarDebug;
new Handle:cvarGoombaDamage;
new Handle:cvarBossRTD;
new Handle:cvarRTDMode;
new Handle:cvarRTDTimeLimit;
new Handle:cvarDisabledRTDPerks;

new Handle:FF2Cookies;

new Handle:jumpHUD;
new Handle:rageHUD;
new Handle:healthHUD;
new Handle:timeleftHUD;
new Handle:abilitiesHUD;
new Handle:doorchecktimer;

new bool:Enabled=true;
new bool:Enabled2=true;
new PointDelay=6;
new Float:Announce=120.0;
new AliveToEnable=5;
new PointType=0;
new bool:BossCrits=true;
new Float:circuitStun=0.0;
new countdownPlayers=1;
new countdownTime=120;
new countdownHealth=2000;
new bool:lastPlayerGlow=true;
new bool:SpecForceBoss=false;
new Float:GoombaDamage=0.05;
new bool:canBossRTD = false;

new Handle:MusicTimer;
new Handle:BossInfoTimer[MAXPLAYERS+1][2];
new Handle:DrawGameTimer;

new RoundCounter;
new botqueuepoints=0;
new Float:HPTime;
new String:currentmap[99];
new bool:checkdoors=false;
new bool:bMedieval;
new FF2CharSet;
new String:FF2CharSetStr[42];

new tf_arena_use_queue;
new mp_teams_unbalance_limit;
new tf_arena_first_blood;
new mp_forcecamera;
new bool:halloween;
new Float:tf_scout_hype_pep_max;
new Handle:cvarNextmap;
new bool:areSubPluginsEnabled;

new bool:isCharSetSelected=false;

new healthBar=-1;
new g_Monoculus=-1;

static bool:executed=false;
static bool:executed2=false;

static const String:ff2versiontitles[][]=
{
	"1.0",
	"1.01",
	"1.01",
	"1.02",
	"1.03",
	"1.04",
	"1.05",
	"1.05",
	"1.06",
	"1.06c",
	"1.06d",
	"1.06e",
	"1.06f",
	"1.06g",
	"1.06h",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 4",
	"1.07 beta 5",
	"1.07 beta 6",
	"1.07",
	"1.0.8",
	"1.0.8",
	"1.0.8",
	"1.0.8",
	"1.0.8",
	"1.9.0",
	"1.9.0",
	"1.9.1",
	"1.9.2",
	"1.9.2",
	"1.10.0",
	"1.10.0"
};

static const String:ff2versiondates[][]=
{
	"6 April 2012",		//1.0
	"14 April 2012",	//1.01
	"14 April 2012",	//1.01
	"17 April 2012",	//1.02
	"19 April 2012",	//1.03
	"21 April 2012",	//1.04
	"29 April 2012",	//1.05
	"29 April 2012",	//1.05
	"1 May 2012",		//1.06
	"22 June 2012",		//1.06c
	"3 July 2012",		//1.06d
	"24 Aug 2012",		//1.06e
	"5 Sep 2012",		//1.06f
	"5 Sep 2012",		//1.06g
	"6 Sep 2012",		//1.06h
	"8 Oct 2012",		//1.07 beta 1
	"8 Oct 2012",		//1.07 beta 1
	"8 Oct 2012",		//1.07 beta 1
	"8 Oct 2012",		//1.07 beta 1
	"8 Oct 2012",		//1.07 beta 1
	"11 Oct 2012",		//1.07 beta 4
	"18 Oct 2012",		//1.07 beta 5
	"9 Nov 2012",		//1.07 beta 6
	"14 Dec 2012",		//1.07
	"October 30, 2013",	//1.0.8
	"October 30, 2013",	//1.0.8
	"October 30, 2013",	//1.0.8
	"October 30, 2013",	//1.0.8
	"October 30, 2013",	//1.0.8
	"March 6, 2014",	//1.9.0
	"March 6, 2014",	//1.9.0
	"March 18, 2014",	//1.9.1
	"March 22, 2014",	//1.9.2
	"March 22, 2014",	//1.9.2
	"April 1, 2014",	//1.10.0
	"April 1, 2014"		//1.10.0
};

stock FindVersionData(Handle:panel, versionIndex)
{
	switch(versionIndex)
	{
		case 35:  //1.10.0
		{
			DrawPanelText(panel, "1) Balanced Goomba Stomp and RTD (WildCard65)");
			DrawPanelText(panel, "2) Fixed BGM not stopping if the boss suicided at the beginning of the round (Wliu)");
			DrawPanelText(panel, "3) Fixed players not being displayed on the leaderboard if they were respawned as a clone (Wliu)");
			DrawPanelText(panel, "4) Fixed players with 0 damage rarely showing up as 3rd place on the leaderboard (Wliu)");
			DrawPanelText(panel, "5) Fixed a !ff2new bug in 1.9.2 where all versions would be shifted by one page (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 34:  //1.10.0
		{
			DrawPanelText(panel, "6) Fixed ability timers not resetting when the round was over (Wliu)");
			DrawPanelText(panel, "7) Fixed sentries not re-activating after being stunned (Wliu)");
			DrawPanelText(panel, "7) [Server] Added ammo, clip, and health arguments to rage_cloneattack (Wliu)");
			DrawPanelText(panel, "8) [Server] Made !ff2_special display a warning instead of throwing an error when used with rcon (Wliu)");
			DrawPanelText(panel, "9) [Server] Added convar ff2_countdown_players to control when the timer should appear (Wliu/BBG_Theory)");
		}
		case 33:  //1.9.2
		{
			DrawPanelText(panel, "1) Fixed a bug in 1.9.1 that allowed the same player to be the boss over and over again (Wliu)");
			DrawPanelText(panel, "2) Fixed a bug where last player glow was being incorrectly removed on the boss (Wliu)");
			DrawPanelText(panel, "3) Fixed a bug where the boss would be assumed dead (Wliu)");
			DrawPanelText(panel, "4) Fixed having minions on the boss team interfering with certain rage calculations (Wliu)");
			DrawPanelText(panel, "5) Fixed a rare bug where the rage percentage could go above 100% (Wliu)");
			DrawPanelText(panel, "See next page for the server changelog (press 1)");
		}
		case 32:  //1.9.2
		{
			DrawPanelText(panel, "6) [Server] Fixed possible special_noanims errors (Wliu)");
			DrawPanelText(panel, "7) [Server] Added new arguments to rage_cloneattack-no updates necessary (friagram/Wliu)");
			DrawPanelText(panel, "8) [Server] Certain cvars that SMAC detects are now automatically disabled while FF2 is running (Wliu)");
			DrawPanelText(panel, "            Servers can now safely have smac_cvars enabled");
		}
		case 31:  //1.9.1
		{
			DrawPanelText(panel, "1) Fixed some minor leaderboard bugs and also improved the leaderboard text (Wliu)");
			DrawPanelText(panel, "2) Fixed a minor round end bug (Wliu)");
			DrawPanelText(panel, "3) [Server] Fixed improper unloading of subplugins (WildCard65)");
			DrawPanelText(panel, "4) [Server] Removed leftover console messages (Wliu)");
			DrawPanelText(panel, "5) [Server] Fixed sound not precached warnings (Wliu)");
		}
		case 30:  //1.9.0
		{
			DrawPanelText(panel, "1) Removed checkFirstHale (Wliu)");
			DrawPanelText(panel, "2) [Server] Fixed invalid healthbar entity bug (Wliu)");
			DrawPanelText(panel, "3) Changed default medic ubercharge percentage to 40% (Wliu)");
			DrawPanelText(panel, "4) Whitelisted festive variants of weapons (Wliu/BBG_Theory)");
			DrawPanelText(panel, "5) [Server] Added convars to control last player glow and timer health cutoff (Wliu");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 29:  //1.9.0
		{
			DrawPanelText(panel, "6) [Dev] Added new natives/stocks: Debug, FF2_SetClientGlow and FF2_GetClientGlow (Wliu)");
			DrawPanelText(panel, "7) Fixed a few minor !whatsnew bugs (BBG_Theory)");
			DrawPanelText(panel, "8) Fixed Easter Abilities (Wliu)");
			DrawPanelText(panel, "9) Minor grammar/spelling improvements (Wliu)");
			DrawPanelText(panel, "10) [Server] Minor subplugin load/unload fixes (Wliu)");
		}
		case 28:  //1.0.8
		{
			DrawPanelText(panel, "Wliu, Chris, Lawd, and Carge of 50DKP have taken over FF2 development");
			DrawPanelText(panel, "1) Prevented spy bosses from changing disguises (Powerlord)");
			DrawPanelText(panel, "2) Added Saxton Hale stab sounds (Powerlord/AeroAcrobat)");
			DrawPanelText(panel, "3) Made sure that the boss doesn't have any invalid weapons/items (Powerlord)");
			DrawPanelText(panel, "4) Tried fixing the visible weapon bug (Powerlord)");
			DrawPanelText(panel, "5) Whitelisted some more action slot items (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 27:  //1.0.8
		{
			DrawPanelText(panel, "6) Festive Huntsman has the same attributes as the Huntsman now (Powerlord)");
			DrawPanelText(panel, "7) Medigun now overheals 50% more (Powerlord)");
			DrawPanelText(panel, "8) Made medigun transparent if the medic's melee was the Gunslinger (Powerlord)");
			DrawPanelText(panel, "9) Slight tweaks to the view hp commands (Powerlord)");
			DrawPanelText(panel, "10) Whitelisted the Silver/Gold Botkiller Sniper Rifle Mk.II (Powerlord)");
			DrawPanelText(panel, "11) Slight tweaks to boss health calculation (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 26:  //1.0.8
		{
			DrawPanelText(panel, "12) Made sure that spies couldn't quick-backstab the boss (Powerlord)");
			DrawPanelText(panel, "13) Made sure the stab animations were correct (Powerlord)");
			DrawPanelText(panel, "14) Made sure that healthpacks spawned from the Candy Cane are not respawned once someone uses them (Powerlord)");
			DrawPanelText(panel, "15) Healthpacks from the Candy Cane are no longer despawned (Powerlord)");
			DrawPanelText(panel, "16) Slight tweaks to removing laughs (Powerlord)");
			DrawPanelText(panel, "17) [Dev] Added a clip argument to special_noanims.sp (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 25:  //1.0.8
		{
			DrawPanelText(panel, "18) [Dev] sound_bgm is now precached automagically (Powerlord)");
			DrawPanelText(panel, "19) Seeldier's minions can no longer cap (Wliu)");
			DrawPanelText(panel, "20) Fixed sometimes getting stuck when teleporting to a ducking player (Powerlord)");
			DrawPanelText(panel, "21) Multiple English translation improvements (Wliu/Powerlord)");
			DrawPanelText(panel, "22) Fixed Ninja Spy and other bosses that use the matrix ability getting stuck in walls/ceilings (Chris)");
			DrawPanelText(panel, "23) [Dev] Updated item attributes code per the TF2Items update (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 24:  //1.0.8
		{
			DrawPanelText(panel, "24) Fixed duplicate sound downloads for Saxton Hale (Wliu)");
			DrawPanelText(panel, "25) [Server] FF2 now require morecolors, not colors (Powerlord)");
			DrawPanelText(panel, "26) [Server] Added a Halloween mode which will enable characters_halloween.cfg (Wliu)");
			DrawPanelText(panel, "27) Hopefully fixed multiple round-related issues (Wliu)");
			DrawPanelText(panel, "28) [Dev] Started to clean up/format the code (Wliu)");
			DrawPanelText(panel, "29) Changed versioning format to x.y.z and month day, year (Wliu)");
			DrawPanelText(panel, "HAPPY HALLOWEEN!");
		}
		case 23:  //1.07
		{
			DrawPanelText(panel, "1) [Players] Holiday Punch is now replaced by Fists");
			DrawPanelText(panel, "2) [Players] Bosses will have any disguises removed on round start");
			DrawPanelText(panel, "3) [Players] Bosses can no longer see all players health, as it wasn't working any more");
			DrawPanelText(panel, "4) [Server] ff2_addpoints no longer targets SourceTV or replay");
		}
		case 22:  //1.07 beta 6
		{
			DrawPanelText(panel, "1) [Dev] Fixed issue with sound hook not stopping sound when sound_block_vo was in use");
			DrawPanelText(panel, "2) [Dev] If ff2_charset was used, don't run the character set vote");
			DrawPanelText(panel, "3) [Dev] If a vote is already running, Character set vote will retry every 5 seconds or until map changes ");
		}
		case 21:  //1.07 beta 5
		{
			DrawPanelText(panel, "1) [Dev] Fixed issue with character sets not working.");
			DrawPanelText(panel, "2) [Dev] Improved IsValidClient replay check");
			DrawPanelText(panel, "3) [Dev] IsValidClient is now called when loading companion bosses");
			DrawPanelText(panel, "   This should prevent GetEntProp issues with m_iClass");
		}
		case 20:  //1.07 beta 4
		{
			DrawPanelText(panel, "1) [Players] Dead Ringers have no cloak defense buff. Normal cloaks do.");
			DrawPanelText(panel, "2) [Players] Fixed Sniper Rifle reskin behavior");
			DrawPanelText(panel, "3) [Players] Boss has small amount of stun resistance after rage");
			DrawPanelText(panel, "4) [Players] Various bugfixes and changes 1.7.0 beta 1");
		}
		case 19:  //1.07 beta
		{
			DrawPanelText(panel, "22) [Dev] Prevent boss rage from being activated if the boss is already taunting or is dead.");
			DrawPanelText(panel, "23) [Dev] Cache the result of the newer backstab detection");
			DrawPanelText(panel, "24) [Dev] Reworked Medic damage code slightly");
		}
		case 18:  //1.07 beta
		{
			DrawPanelText(panel, "16) [Server] The Boss queue now accepts negative points.");
			DrawPanelText(panel, "17) [Server] Bosses can be forced to a specific team using the new ff2_force_team cvar.");
			DrawPanelText(panel, "18) [Server] Eureka Effect can now be enabled using the new ff2_enable_eureka cvar");
			DrawPanelText(panel, "19) [Server] Bosses models and sounds are now precached the first time they are loaded.");
			DrawPanelText(panel, "20) [Dev] Fixed an issue where FF2 was trying to read cvars before config files were executed.");
			DrawPanelText(panel, "    This change should also make the game a little more multi-mod friendly.");
			DrawPanelText(panel, "21) [Dev] Fixed OnLoadCharacterSet not being fired. This should fix the deadrun plugin.");
			DrawPanelText(panel, "Continued on next page");
		}
		case 17:  //1.07 beta
		{
			DrawPanelText(panel, "10) [Players] Heatmaker gains Focus on hit (varies by charge)");
			DrawPanelText(panel, "11) [Players] Crusader's Crossbow damage has been adjusted to compensate for its speed increase.");
			DrawPanelText(panel, "12) [Players] Cozy Camper now gives you an SMG as well, but it has no crits and reduced damage.");
			DrawPanelText(panel, "13) [Players] Bosses get short defense buff after rage");
			DrawPanelText(panel, "14) [Server] Now attempts to integrate tf2items config");
			DrawPanelText(panel, "15) [Server] Changing the game description now requires Steam Tools");
			DrawPanelText(panel, "Continued on next page");
		}
		case 16:  //1.07 beta
		{
			DrawPanelText(panel, "6) [Players] Removed crits from sniper rifles, now do 2.9x damage");
			DrawPanelText(panel, "   Sydney Sleeper does 2.4x damage, 2.9x if boss's rage is >90pct");
			DrawPanelText(panel, "   Minicrit- less damage, more knockback");
			DrawPanelText(panel, "7) [Players] Baby Face's Blaster will fill boost normally, but will hit 100 and drain+minicrits.");
			DrawPanelText(panel, "8) [Players] Phlogistinator Pyros are invincible while activating the crit-boost taunt.");
			DrawPanelText(panel, "9) [Players] Can't Eureka+destroy dispenser to insta-teleport");
			DrawPanelText(panel, "Continued on next page");
		}
		case 15:  //1.07 beta
		{
			DrawPanelText(panel, "1) [Players] Reworked the crit code a bit. Should be more reliable.");
			DrawPanelText(panel, "2) [Players] Help panel should stop repeatedly popping up on round start.");
			DrawPanelText(panel, "3) [Players] Backstab disguising should be smoother/less obvious");
			DrawPanelText(panel, "4) [Players] Scaled sniper rifle glow time a bit better");
			DrawPanelText(panel, "5) [Players] Fixed Dead Ringer spy death icon");
			DrawPanelText(panel, "Continued on next page");
			
		}
		case 14:  //1.06h
		{
		    DrawPanelText(panel, "1) [Players] Remove MvM powerup_bottle on Bosses. (RavensBro)");
		}
		case 13:  //1.06g
		{
		    DrawPanelText(panel, "1) [Players] Fixed vote for charset. (RavensBro)");
		}		
		case 12:  //1.06f
		{
			DrawPanelText(panel, "1) [Players] Changelog now divided into [Players] and [Dev] sections. (Otokiru)");
			DrawPanelText(panel, "2) [Players] Don't bother reading [Dev] changelogs because you'll have no idea what it's stated. (Otokiru)");
			DrawPanelText(panel, "3) [Players] Fixed civilian glitch. (Otokiru)");
			DrawPanelText(panel, "4) [Players] Fixed hale HP bar. (Valve) lol?");
			DrawPanelText(panel, "5) [Dev] Fixed \"GetEntProp\" reported: Entity XXX (XXX) is invalid on checkFirstHale(). (Otokiru)");
		}
		case 11:  //1.06e
		{

			DrawPanelText(panel, "1) [Players] Remove MvM water-bottle on hales. (Otokiru)");
			DrawPanelText(panel, "2) [Dev] Fixed \"GetEntProp\" reported: Property \"m_iClass\" not found (entity 0/worldspawn) error on checkFirstHale(). (Otokiru)");
			DrawPanelText(panel, "3) [Dev] Change how FF2 check for player weapons. Now also checks when spawned in the middle of the round. (Otokiru)");
			DrawPanelText(panel, "4) [Dev] Changed some FF2 warning messages color such as \"First-Hale Checker\" and \"Change class exploit\". (Otokiru)");
		}
		case 10:  //1.06d
		{
			DrawPanelText(panel, "1) Fix first boss having missing health or abilities. (Otokiru)");
			DrawPanelText(panel, "2) Health bar now goes away if the boss wins the round. (Powerlord)");
			DrawPanelText(panel, "3) Health bar cedes control to Monoculus if he is summoned. (Powerlord)");
			DrawPanelText(panel, "4) Health bar instantly updates if enabled or disabled via cvar mid-game. (Powerlord)");
		}
		case 9:  //1.06c
		{
			DrawPanelText(panel, "1) Remove weapons if a player tries to switch classes when they become boss to prevent an exploit. (Otokiru)");
			DrawPanelText(panel, "2) Reset hale's queue points to prevent the 'retry' exploit. (Otokiru)");
			DrawPanelText(panel, "3) Better detection of backstabs. (Powerlord)");
			DrawPanelText(panel, "4) Boss now has optional life meter on screen. (Powerlord)");
		}
		case 8:  //1.06
		{
			DrawPanelText(panel, "1) Fixed attributes key for weaponN block. Now 1 space needed for explode string.");
			DrawPanelText(panel, "2) Disabled vote for charset when there is only 1 not hidden chatset.");
			DrawPanelText(panel, "3) Fixed \"Invalid key value handle 0 (error 4)\" when when round starts.");
			DrawPanelText(panel, "4) Fixed ammo for special_noanims.ff2\\rage_new_weapon ability.");
			DrawPanelText(panel, "Coming soon: weapon balance will be moved into config file.");
		}
		case 7:  //1.05
		{
			DrawPanelText(panel, "1) Added \"hidden\" key for charsets.");
			DrawPanelText(panel, "2) Added \"sound_stabbed\" key for characters.");
			DrawPanelText(panel, "3) Mantread stomp deals 5x damage to Boss.");
			DrawPanelText(panel, "4) Minicrits will not play loud sound to all players");
			DrawPanelText(panel, "5-11) See next page...");
		}
		case 6:  //1.05
		{
			DrawPanelText(panel, "6) For mappers: Add info_target with name 'hale_no_music'");
			DrawPanelText(panel, "    to prevent Boss' music.");
			DrawPanelText(panel, "7) FF2 renames *.smx from plugins/freaks/ to *.ff2 by itself.");
			DrawPanelText(panel, "8) Third Degree hit adds uber to healers.");
			DrawPanelText(panel, "9) Fixed hard \"ghost_appearation\" in default_abilities.ff2.");
			DrawPanelText(panel, "10) FF2FLAG_HUDDISABLED flag blocks EVERYTHING of FF2's HUD.");
			DrawPanelText(panel, "11) Changed FF2_PreAbility native to fix bug about broken Boss' abilities.");
		}
		case 5:  //1.04
		{
			DrawPanelText(panel, "1) Seeldier's minions have protection (teleport) from pits for first 4 seconds after spawn.");
			DrawPanelText(panel, "2) Seeldier's minions correctly dies when owner-Seeldier dies.");
			DrawPanelText(panel, "3) Added multiplier for brave jump ability in char.configs (arg3, default is 1.0).");
			DrawPanelText(panel, "4) Added config key sound_fail. It calls when Boss fails, but still alive");
			DrawPanelText(panel, "4) Fixed potential exploits associated with feign death.");
			DrawPanelText(panel, "6) Added ff2_reload_subplugins command to reload FF2's subplugins.");
		}
		case 4:  //1.03
		{
			DrawPanelText(panel, "1) Finally fixed exploit about queue points.");
			DrawPanelText(panel, "2) Fixed non-regular bug with 'UTIL_SetModel: not precached'.");
			DrawPanelText(panel, "3) Fixed potential bug about reducing of Boss' health by healing.");
			DrawPanelText(panel, "4) Fixed Boss' stun when round begins.");
		}
		case 3:  //1.02
		{
			DrawPanelText(panel, "1) Added isNumOfSpecial parameter into FF2_GetSpecialKV and FF2_GetBossSpecial natives");
			DrawPanelText(panel, "2) Added FF2_PreAbility forward. Plz use it to prevent FF2_OnAbility only.");
			DrawPanelText(panel, "3) Added FF2_DoAbility native.");
			DrawPanelText(panel, "4) Fixed exploit about queue points...ow wait, it done in 1.01");
			DrawPanelText(panel, "5) ff2_1st_set_abilities.ff2 sets kac_enabled to 0.");
			DrawPanelText(panel, "6) FF2FLAG_HUDDISABLED flag disables Boss' HUD too.");
			DrawPanelText(panel, "7) Added FF2_GetQueuePoints and FF2_SetQueuePoints natives.");
		}
		case 2:  //1.01
		{
			DrawPanelText(panel, "1) Fixed \"classmix\" bug associated with Boss' class restoring.");
			DrawPanelText(panel, "3) Fixed other little bugs.");
			DrawPanelText(panel, "4) Fixed bug about instant kill of Seeldier's minions.");
			DrawPanelText(panel, "5) Now you can use name of Boss' file for \"companion\" Boss' keyvalue.");
			DrawPanelText(panel, "6) Fixed exploit when dead Boss can been respawned after his reconnect.");
			DrawPanelText(panel, "7-10) See next page...");
		}
		case 1:  //1.01
		{
			DrawPanelText(panel, "7) I've missed 2nd item.");
			DrawPanelText(panel, "8) Fixed \"Random\" charpack, there is no vote if only one charpack.");
			DrawPanelText(panel, "9) Fixed bug when boss' music have a chance to DON'T play.");
			DrawPanelText(panel, "10) Fixed bug associated with ff2_enabled in cfg/sourcemod/FreakFortress2.cfg and disabling of pugin.");
		}
		case 0:  //1.0
		{
			DrawPanelText(panel, "1) Boss' health devided by 3,6 in medieval mode");
			DrawPanelText(panel, "2) Restoring player's default class, after his round as Boss");
			DrawPanelText(panel, "===UPDATES OF VS SAXTON HALE MODE===");			
			DrawPanelText(panel, "1) Added !ff2_resetqueuepoints command (also there is admin version)");
			DrawPanelText(panel, "2) Medic is credited 100% of damage done during ubercharge");
			DrawPanelText(panel, "3) If map changes mid-round, queue points not lost");
			DrawPanelText(panel, "4) Dead Ringer will not be able to activate for 2s after backstab");
			DrawPanelText(panel, "5) Added ff2_spec_force_boss cvar");
		}
		default:
		{
			DrawPanelText(panel, "-- Somehow you've managed to find a glitched version page!");
			DrawPanelText(panel, "-- Congratulations.  Now go and fight!");
		}
	}
}

static const maxVersion=(sizeof(ff2versiontitles)-1);

new Specials=0;
new Handle:BossKV[MAXSPECIALS];
new Handle:PreAbility;
new Handle:OnAbility;
new Handle:OnMusic;
new Handle:OnTriggerHurt;
new Handle:OnSpecialSelected;
new Handle:OnAddQueuePoints;
new Handle:OnLoadCharacterSet;

new bool:bBlockVoice[MAXSPECIALS];
new Float:BossSpeed[MAXSPECIALS];
new Float:BossRageDamage[MAXSPECIALS];
new String:ChancesString[64];

public Plugin:myinfo=
{
	name="Freak Fortress 2",
	author="Rainbolt Dash, FlaminSarge, Powerlord, the 50DKP team",
	description="RUUUUNN!! COWAAAARRDSS!",
	version=PLUGIN_VERSION,
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("FF2_IsFF2Enabled", Native_IsEnabled);
	CreateNative("FF2_GetBossUserId", Native_GetBoss);
	CreateNative("FF2_GetBossIndex", Native_GetIndex);
	CreateNative("FF2_GetBossTeam", Native_GetTeam);
	CreateNative("FF2_GetBossSpecial", Native_GetSpecial);
	CreateNative("FF2_GetBossMax", Native_GetHealth);
	CreateNative("FF2_GetBossMaxHealth", Native_GetHealthMax);
	CreateNative("FF2_GetBossCharge", Native_GetBossCharge);
	CreateNative("FF2_SetBossCharge", Native_SetBossCharge);
	CreateNative("FF2_GetClientDamage", Native_GetDamage);
	CreateNative("FF2_GetRoundState", Native_GetRoundState);
	CreateNative("FF2_GetSpecialKV", Native_GetSpecialKV);
	CreateNative("FF2_StopMusic", Native_StopMusic);
	CreateNative("FF2_GetRageDist", Native_GetRageDist);
	CreateNative("FF2_HasAbility", Native_HasAbility); 	
	CreateNative("FF2_DoAbility", Native_DoAbility); 	
	CreateNative("FF2_GetAbilityArgument", Native_GetAbilityArgument); 	
	CreateNative("FF2_GetAbilityArgumentFloat", Native_GetAbilityArgumentFloat); 	
	CreateNative("FF2_GetAbilityArgumentString", Native_GetAbilityArgumentString); 	
	CreateNative("FF2_RandomSound", Native_RandomSound);
	CreateNative("FF2_GetFF2flags", Native_GetFF2flags);
	CreateNative("FF2_SetFF2flags", Native_SetFF2flags);
	CreateNative("FF2_GetQueuePoints", Native_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints", Native_SetQueuePoints);
	CreateNative("FF2_GetClientGlow", Native_GetClientGlow);
	CreateNative("FF2_SetClientGlow", Native_SetClientGlow);
	CreateNative("FF2_Debug", Native_Debug);

	PreAbility=CreateGlobalForward("FF2_PreAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);
	OnAbility=CreateGlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);
	OnMusic=CreateGlobalForward("FF2_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
	OnTriggerHurt=CreateGlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	OnSpecialSelected=CreateGlobalForward("FF2_OnSpecialSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String);
	OnAddQueuePoints=CreateGlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
	OnLoadCharacterSet=CreateGlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_CellByRef, Param_String);

	RegPluginLibrary("freak_fortress_2");

	AskPluginLoad_VSH();
	#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
	#endif
	return APLRes_Success;
}

public OnPluginStart()
{
	LogMessage("===Freak Fortress 2 Initializing-v%s===", PLUGIN_VERSION);

	cvarVersion=CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarPointType=CreateConVar("ff2_point_type", "0", "0-Use ff2_point_alive, 1-Use ff2_point_time", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarPointDelay=CreateConVar("ff2_point_delay", "6", "Seconds to add to the point delay per player", FCVAR_PLUGIN);
	cvarAliveToEnable=CreateConVar("ff2_point_alive", "5", "The control point will only activate when there are this many people or less left alive", FCVAR_PLUGIN);
	cvarAnnounce=CreateConVar("ff2_announce", "120", "Amount of seconds to wait until FF2 info is displayed again.  0 to disable", FCVAR_PLUGIN, true, 0.0);
	cvarEnabled=CreateConVar("ff2_enabled", "1", "0-Disable FF2 (WHY?), 1-Enable FF2", FCVAR_PLUGIN|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	cvarCrits=CreateConVar("ff2_crits", "1", "Can Boss get crits?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarFirstRound=CreateConVar("ff2_first_round", "0", "0-Make the first round arena so that more people can join, 1-Make all rounds FF2", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarCircuitStun=CreateConVar("ff2_circuit_stun", "2", "Amount of seconds the Short Circuit stuns the boss for.  0 to disable", FCVAR_PLUGIN, true, 0.0);
	cvarCountdownPlayers=CreateConVar("ff2_countdown_players", "1", "Amount of players until the countdown timer starts (0 to disable)", FCVAR_PLUGIN, true, 0.0);
	cvarCountdownTime=CreateConVar("ff2_countdown", "120", "Amount of seconds until the round ends in a stalemate", FCVAR_PLUGIN);
	cvarCountdownHealth=CreateConVar("ff2_countdown_health", "2000", "Amount of health the Boss has remaining until the countdown stops", FCVAR_PLUGIN, true, 0.0);
	cvarSpecForceBoss=CreateConVar("ff2_spec_force_boss", "0", "0-Spectators are excluded from the queue system, 1-Spectators are counted in the queue system", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarEnableEurekaEffect=CreateConVar("ff2_enable_eureka", "0", "0-Disable the Eureka Effect, 1-Enable the Eureka Effect", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarForceBossTeam=CreateConVar("ff2_force_team", "0", "0-Boss team depends on FF2 logic, 1-Boss is on a random team each round, 2-Boss is always on Red, 3-Boss is always on Blu", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	cvarHealthBar=CreateConVar("ff2_health_bar", "0", "0-Disable the health bar, 1-Show the health bar", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarHalloween=CreateConVar("ff2_halloween", "2", "0-Disable Halloween mode, 1-Enable Halloween mode, 2-Use TF2 logic (tf_forced_holiday 2)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvarLastPlayerGlow=CreateConVar("ff2_last_player_glow", "1", "0-Don't outline the last player, 1-Outline the last player alive", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarDebug=CreateConVar("ff2_debug", "0", "0-Disable FF2 debug output, 1-Enable debugging (not recommended)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarGoombaDamage=CreateConVar("ff2_goomba_damage", "0.05", "How much the Goomba damage should be multipled by when stomping the boss (requires Goomba Stomp)", FCVAR_PLUGIN, true, 0.01, true, 1.0);
	cvarBossRTD=CreateConVar("ff2_boss_rtd", "0", "Can the boss use rtd? 0 to disallow boss, 1 to allow boss (Requires RTD plugin)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAllowSpectators=FindConVar("mp_allowspectators");

	HookEvent("player_changeclass", OnChangeClass);
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("teamplay_round_win", event_round_end);
	HookEvent("player_changeclass", event_change_class);
	HookEvent("player_spawn", event_player_spawn, EventHookMode_Pre);
	HookEvent("player_death", event_player_death, EventHookMode_Pre);
	HookEvent("player_chargedeployed", event_uberdeployed);
	HookEvent("player_hurt", event_hurt, EventHookMode_Pre);
	HookEvent("object_destroyed", event_destroy, EventHookMode_Pre);
	HookEvent("object_deflected", event_deflect, EventHookMode_Pre);
	HookUserMessage(GetUserMessageId("PlayerJarated"), event_jarate);

	HookConVarChange(cvarEnabled, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarAnnounce, CvarChange);
	HookConVarChange(cvarPointType, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarAliveToEnable, CvarChange);
	HookConVarChange(cvarCrits, CvarChange);
	HookConVarChange(cvarCircuitStun, CvarChange);
	HookConVarChange(cvarHealthBar, HealthbarEnableChanged);
	HookConVarChange(cvarCountdownPlayers, CvarChange);
	HookConVarChange(cvarCountdownTime, CvarChange);
	HookConVarChange(cvarCountdownHealth, CvarChange);
	HookConVarChange(cvarLastPlayerGlow, CvarChange);
	HookConVarChange(cvarSpecForceBoss, CvarChange);
	HookConVarChange(cvarGoombaDamage, CvarChange);
	HookConVarChange(cvarBossRTD, CvarChange);
	cvarNextmap=FindConVar("sm_nextmap");
	HookConVarChange(cvarNextmap, CvarChangeNextmap);

	RegConsoleCmd("ff2", FF2Panel);
	RegConsoleCmd("ff2_hp", Command_GetHPCmd);
	RegConsoleCmd("ff2hp", Command_GetHPCmd);
	RegConsoleCmd("ff2_next", QueuePanelCmd);
	RegConsoleCmd("ff2next", QueuePanelCmd);
	RegConsoleCmd("ff2_classinfo", HelpPanel2Cmd);
	RegConsoleCmd("ff2classinfo", HelpPanel2Cmd);
	RegConsoleCmd("ff2_new", NewPanelCmd);
	RegConsoleCmd("ff2new", NewPanelCmd);
	RegConsoleCmd("ff2music", MusicTogglePanelCmd);
	RegConsoleCmd("ff2_music", MusicTogglePanelCmd);
	RegConsoleCmd("ff2voice", VoiceTogglePanelCmd);
	RegConsoleCmd("ff2_voice", VoiceTogglePanelCmd);
	RegConsoleCmd("ff2_resetpoints", ResetQueuePointsCmd);
	RegConsoleCmd("ff2resetpoints", ResetQueuePointsCmd);
	RegAdminCmd("ff2_resetqueuepoints", ResetQueuePointsCmd, 0);
	RegAdminCmd("ff2_resetq", ResetQueuePointsCmd, 0);
	RegConsoleCmd("hale", FF2Panel);
	RegConsoleCmd("hale_hp", Command_GetHPCmd);
	RegConsoleCmd("halehp", Command_GetHPCmd);
	RegConsoleCmd("hale_next", QueuePanelCmd);
	RegConsoleCmd("halenext", QueuePanelCmd);
	RegConsoleCmd("hale_classinfo", HelpPanel2Cmd);
	RegConsoleCmd("haleclassinfo", HelpPanel2Cmd);
	RegConsoleCmd("hale_new", NewPanelCmd);
	RegConsoleCmd("halenew", NewPanelCmd);
	RegConsoleCmd("halemusic", MusicTogglePanelCmd);
	RegConsoleCmd("hale_music", MusicTogglePanelCmd);
	RegConsoleCmd("halevoice", VoiceTogglePanelCmd);
	RegConsoleCmd("hale_voice", VoiceTogglePanelCmd);
	RegConsoleCmd("hale_resetpoints", ResetQueuePointsCmd);
	RegConsoleCmd("haleresetpoints", ResetQueuePointsCmd);
	RegAdminCmd("hale_resetqueuepoints", ResetQueuePointsCmd, 0);
	RegAdminCmd("hale_resetq", ResetQueuePointsCmd, 0);
	RegConsoleCmd("nextmap", NextMapCmd);
	RegConsoleCmd("say", SayCmd);
	RegConsoleCmd("say_team", SayCmd);

	AddCommandListener(DoTaunt, "taunt"); 
	AddCommandListener(DoTaunt, "+taunt");
	AddCommandListener(DoTaunt, "+use_action_slot_item_server");
	AddCommandListener(DoTaunt, "use_action_slot_item_server");
	AddCommandListener(DoSuicide, "explode");  
	AddCommandListener(DoSuicide, "kill");  
	AddCommandListener(Destroy, "destroy");
	//AddCommandListener(DoJoinTeam, "jointeam");  //TODO

	RegAdminCmd("hale_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable CP. Only with ff2_point_type=0");
	RegAdminCmd("hale_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable CP. Only with ff2_point_type=0");

	RegAdminCmd("ff2_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  ff2_special <boss>.  Forces next round to use that boss");
	RegAdminCmd("ff2_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage:  ff2_addpoints <target> <points>.  Adds queue points to any player");
	RegAdminCmd("ff2_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music");
	RegAdminCmd("ff2_charset", Command_CharSet, ADMFLAG_CHEATS, "Usage:  ff2_charset <charset>.  Forces FF2 to use a given character set");
	RegAdminCmd("ff2_reload_subplugins", Command_ReloadSubPlugins, ADMFLAG_RCON, "Reload FF2's subplugins.");

	RegAdminCmd("hale_select", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage:  hale_addpoints <target> <points>.  Adds queue points to any player");
	RegAdminCmd("hale_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable the control point if ff2_point_type is 0");
	RegAdminCmd("hale_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable the control point if ff2_point_type is 0");
	RegAdminCmd("hale_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music");

	AutoExecConfig(true, "FreakFortress2");

	FF2Cookies=RegClientCookie("ff2_cookies_mk2", "", CookieAccess_Protected);

	jumpHUD=CreateHudSynchronizer();
	rageHUD=CreateHudSynchronizer();
	healthHUD=CreateHudSynchronizer();
	abilitiesHUD=CreateHudSynchronizer();
	timeleftHUD=CreateHudSynchronizer(); 	

	decl String:oldversion[64];
	GetConVarString(cvarVersion, oldversion, sizeof(oldversion));
	if(strcmp(oldversion, PLUGIN_VERSION, false)!=0)
	{
		LogError("[FF2] Warning: Your config may be outdated. Back up tf/cfg/sourcemod/FreakFortress2.cfg and delete it, and this plugin will generate a new one that you can then modify to your original values.");
	}

	LoadTranslations("freak_fortress_2.phrases");
	LoadTranslations("common.phrases");

	AddNormalSoundHook(HookSound);

	AddMultiTargetFilter("@hale", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!hale", BossTargetFilter, "all non-Boss players", false);
	AddMultiTargetFilter("@boss", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!boss", BossTargetFilter, "all non-Boss players", false);

	#if defined _steamtools_included
	steamtools=LibraryExists("SteamTools");
	#endif

	#if defined _updater_included && !defined DEV_VERSION
	if(LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

public bool:BossTargetFilter(const String:pattern[], Handle:clients)
{
	new bool:non=StrContains(pattern, "!", false)!=-1;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && FindValueInArray(clients, client)==-1)
		{
			if(Enabled && IsBoss(client))
			{
				if(!non)
				{
					PushArrayCell(clients, client);
				}
			}
			else if(non)
			{
				PushArrayCell(clients, client);
			}
		}
	}
	return true;
}

public OnLibraryAdded(const String:name[])
{
	#if defined _steamtools_included
	if(strcmp(name, "SteamTools", false)==0)
	{
		steamtools=true;
	}
	#endif

	#if defined _updater_included && !defined DEV_VERSION
	if(StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif

	if(StrEqual(name, "smac"))
	{
		smac=true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	#if defined _steamtools_included
	if(strcmp(name, "SteamTools", false)==0)
	{
		steamtools=false;
	}
	#endif

	if(StrEqual(name, "smac"))
	{
		smac=false;
	}
}

public OnConfigsExecuted()
{
	SetConVarString(FindConVar("ff2_version"), PLUGIN_VERSION);
	Announce=GetConVarFloat(cvarAnnounce);
	PointType=GetConVarInt(cvarPointType);
	PointDelay=GetConVarInt(cvarPointDelay);
	GoombaDamage=GetConVarFloat(cvarGoombaDamage);
	canBossRTD=GetConVarBool(cvarBossRTD);
	if(PointDelay<0)
	{
		PointDelay*=-1;
	}
	AliveToEnable=GetConVarInt(cvarAliveToEnable);
	BossCrits=GetConVarBool(cvarCrits);
	circuitStun=GetConVarFloat(cvarCircuitStun);
	countdownHealth=GetConVarInt(cvarCountdownHealth);

	if(IsFF2Map() && GetConVarBool(cvarEnabled))
	{
		tf_arena_use_queue=GetConVarInt(FindConVar("tf_arena_use_queue"));
		mp_teams_unbalance_limit=GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
		tf_arena_first_blood=GetConVarInt(FindConVar("tf_arena_first_blood"));
		mp_forcecamera=GetConVarInt(FindConVar("mp_forcecamera"));
		tf_scout_hype_pep_max=GetConVarFloat(FindConVar("tf_scout_hype_pep_max"));
		switch(GetConVarInt(cvarHalloween))
		{
			case 1:
			{
				halloween=true;
			}
			case 2:
			{
				new TF2Halloween=GetConVarInt(FindConVar("tf_forced_holiday"));
				if(TF2Halloween==2)
				{
					halloween=true;
				}
			}
			default:
			{
				halloween=false;
			}
		}

		SetupRTD();

		SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
		SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
		SetConVarInt(FindConVar("mp_forcecamera"), 0);
		SetConVarFloat(FindConVar("tf_scout_hype_pep_max"), 100.0);
		#if defined _steamtools_included
		if(steamtools)
		{
			decl String:gameDesc[64];
			if(halloween)
			{
				Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s-HALLOWEEN)", PLUGIN_VERSION);
			}
			else
			{
				Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", PLUGIN_VERSION);
			}
			Steam_SetGameDescription(gameDesc);
		}
		#endif
		Enabled=true;
		Enabled2=true;

		new Float:time=Announce;
		if(time>1.0)
		{
			CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		CheckToChangeMapDoors();
		MapHasMusic(true);
		AddToDownload();
		strcopy(FF2CharSetStr, 2, "");

		if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
		{
			ServerCommand("smac_removecvar sv_cheats");
			ServerCommand("smac_removecvar host_timescale");
		}

		bMedieval=FindEntityByClassname(-1, "tf_logic_medieval")!=-1 || bool:GetConVarInt(FindConVar("tf_medieval"));
		FindHealthBar();
	}
	else
	{
		Enabled=false;
		Enabled2=false;
		if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
		{
			ServerCommand("smac_addcvar sv_cheats replicated ban 0 0");
			ServerCommand("smac_addcvar host_timescale replicated ban 1.0 1.0");
		}
	}
}

public OnMapStart()
{
	HPTime=0.0;
	MusicTimer=INVALID_HANDLE;
	RoundCounter=0;
	doorchecktimer=INVALID_HANDLE;
	RoundCount=0;
	for(new client=0; client<=MaxClients; client++)
	{
		KSpreeTimer[client]=0.0;
		FF2flags[client]=0;
		Incoming[client]=-1;
	}

	for(new specials=0; specials<MAXSPECIALS; specials++)
	{
		if(BossKV[specials]!=INVALID_HANDLE)
		{
			CloseHandle(BossKV[specials]);
			BossKV[specials]=INVALID_HANDLE;
		}
	}
}

public OnMapEnd()
{
	if(Enabled2 || Enabled)
	{
		SetConVarInt(FindConVar("tf_arena_use_queue"), tf_arena_use_queue);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), mp_teams_unbalance_limit);
		SetConVarInt(FindConVar("tf_arena_first_blood"), tf_arena_first_blood);
		SetConVarInt(FindConVar("mp_forcecamera"), mp_forcecamera);
		SetConVarFloat(FindConVar("tf_scout_hype_pep_max"), tf_scout_hype_pep_max);
		#if defined _steamtools_included
		if(steamtools)
		{
			Steam_SetGameDescription("Team Fortress");
		}
		#endif
		DisableSubPlugins();

		if(MusicTimer!=INVALID_HANDLE)
		{
			KillTimer(MusicTimer);
			MusicTimer=INVALID_HANDLE;
		}
	}
}

public OnPluginEnd()
{
	OnMapEnd();
}

public AddToDownload()
{
	Specials=0;
	decl String:config[PLATFORM_MAX_PATH], String:i_str[4];
	if(halloween)
	{
		BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters_halloween.cfg");
	}
	else
	{
		BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters.cfg");
	}

	if(!FileExists(config))
	{
		if(halloween)
		{
			BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters.cfg");
			if(!FileExists(config))
			{
				LogError("[FF2] Freak Fortress 2 disabled-can not find characters.cfg or characters_halloween.cfg!");
				return;
			}
			PrintToServer("[FF2] Warning: Using default characters.cfg-can not find characters_halloween.cfg!");
		}
		else
		{
			LogError("[FF2] Freak Fortress 2 disabled-can not find characters.cfg!");
			return;
		}
	}

	new Handle:Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	new NumOfCharSet=FF2CharSet;
	new Action:act=Plugin_Continue;	
	Call_StartForward(OnLoadCharacterSet);
	Call_PushCellRef(NumOfCharSet);
	decl String:charset[42];
	strcopy(charset, 42, FF2CharSetStr);
	Call_PushStringEx(charset, 42, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(act);
	if(act==Plugin_Changed)
	{
		new i=-1;
		if(strlen(charset))
		{
			KvRewind(Kv);
			for(i=0; ; i++)
			{
				KvGetSectionName(Kv, config, 64);
				if(!strcmp(config, charset, false))
				{
					FF2CharSet=i;
					strcopy(FF2CharSetStr, PLATFORM_MAX_PATH, charset);
					KvGotoFirstSubKey(Kv);
					break;
				}
				if(!KvGotoNextKey(Kv))
				{
					i=-1;
					break;
				}
			}
		}

		if(i==-1)
		{
			FF2CharSet=NumOfCharSet;
			for(i=0; i<FF2CharSet; i++)
			{
				KvGotoNextKey(Kv);
			}
			KvGotoFirstSubKey(Kv);
			KvGetSectionName(Kv, FF2CharSetStr, 64);
		}
	}
	
	KvRewind(Kv);
	for(new i=0; i<FF2CharSet; i++)
	{
		KvGotoNextKey(Kv);
	}

	for(new i=1; i<MAXSPECIALS; i++)
	{
		IntToString(i, i_str, 4);
		KvGetString(Kv, i_str, config, PLATFORM_MAX_PATH);
		if(!config[0])
		{
			break;
		}
		LoadCharacter(config);
	}
	KvGetString(Kv, "chances", ChancesString, 64);
	CloseHandle(Kv);
	AddFileToDownloadsTable("sound/saxton_hale/9000.wav");
	PrecacheSound("saxton_hale/9000.wav", true);
	PrecacheSound("vo/announcer_am_capincite01.wav", true);
	PrecacheSound("vo/announcer_am_capincite03.wav", true);
	PrecacheSound("vo/announcer_am_capenabled01.wav", true);
	PrecacheSound("vo/announcer_am_capenabled02.wav", true);
	PrecacheSound("vo/announcer_am_capenabled03.wav", true);
	PrecacheSound("vo/announcer_am_capenabled04.wav", true);
	PrecacheSound("weapons/barret_arm_zap.wav", true);
	PrecacheSound("vo/announcer_ends_2min.wav", true);
	isCharSetSelected=false;
}

EnableSubPlugins(bool:force=false)
{
	if(areSubPluginsEnabled && !force)
	{
		return;
	}

	areSubPluginsEnabled=true;
	decl String:path[PLATFORM_MAX_PATH], String:filename[PLATFORM_MAX_PATH], String:filename_old[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
	decl FileType:filetype;
	new Handle:directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, PLATFORM_MAX_PATH, filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".smx", false)!=-1)
		{
			Format(filename_old, PLATFORM_MAX_PATH, "%s/%s", path, filename);
			ReplaceString(filename, PLATFORM_MAX_PATH, ".smx", ".ff2", false);
			Format(filename, PLATFORM_MAX_PATH, "%s/%s", path, filename);
			DeleteFile(filename);
			RenameFile(filename, filename_old);
		}
	}

	directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, PLATFORM_MAX_PATH, filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
		{
			ServerCommand("sm plugins load freaks/%s", filename);
		}
	}
}

DisableSubPlugins(bool:force=false)
{
	if(!areSubPluginsEnabled && !force)
	{
		return;
	}

	decl String:path[PLATFORM_MAX_PATH], String:filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
	decl FileType:filetype;
	new Handle:directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, PLATFORM_MAX_PATH, filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
		{
			InsertServerCommand("sm plugins unload freaks/%s", filename);
		}
	}
	ServerExecute();
	areSubPluginsEnabled=false;
}

public LoadCharacter(const String:character[])
{			
	new String:extensions[][]={".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
	decl String:config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/%s.cfg", character);
	if(!FileExists(config))
	{
		LogError("[FF2] Character %s does not exist!", character);
		return;
	}
	BossKV[Specials]=CreateKeyValues("character");
	FileToKeyValues(BossKV[Specials], config);

	new version=KvGetNum(BossKV[Specials], "version", 1);
	if(version!=1)
	{
		LogError("[FF2] Character %s is only compatible with FF2 v%i!", character, version);
		return;
	}

	for(new i=1; ; i++)
	{		
		Format(config, 10, "ability%i", i);
		if(KvJumpToKey(BossKV[Specials], config))
		{
			decl String:plugin_name[64];
			KvGetString(BossKV[Specials], "plugin_name", plugin_name, 64);
			BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "plugins/freaks/%s.ff2", plugin_name);
			if(!FileExists(config))
			{
				LogError("[FF2] Character %s needs plugin %s!", character, plugin_name);
				return;
			}
		}
		else
		{
			break;
		}
	}
	KvRewind(BossKV[Specials]);

	decl String:file[PLATFORM_MAX_PATH];
	decl String:section[64];
	KvSetString(BossKV[Specials], "filename", character);
	KvGetString(BossKV[Specials], "name", config, PLATFORM_MAX_PATH);
	bBlockVoice[Specials]=bool:KvGetNum(BossKV[Specials], "sound_block_vo", 0);
	BossSpeed[Specials]=KvGetFloat(BossKV[Specials], "maxspeed", 340.0);
	BossRageDamage[Specials]=KvGetFloat(BossKV[Specials], "ragedamage", 1900.0);
	KvGotoFirstSubKey(BossKV[Specials]);
	if(halloween)
	{
		BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters_halloween.cfg");
	}
	else
	{
		BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters.cfg");
	}

	while(KvGotoNextKey(BossKV[Specials]))
	{	
		KvGetSectionName(BossKV[Specials], section, 64);
		if(!strcmp(section, "download"))
		{
			for(new i=1; ; i++)
			{
				IntToString(i, file, 4);
				KvGetString(BossKV[Specials], file, config, PLATFORM_MAX_PATH);
				if(!config[0])
				{
					break;
				}
				AddFileToDownloadsTable(config);
			}
		}
		else if(!strcmp(section, "mod_download"))
		{	
			for(new i=1; ; i++)
			{
				IntToString(i, file, 4);
				KvGetString(BossKV[Specials], file, config, PLATFORM_MAX_PATH);
				if(!config[0])
				{
					break;
				}

				for(new extension=0; extension<sizeof(extensions); extension++)
				{
					Format(file, PLATFORM_MAX_PATH, "%s%s", config, extensions[extension]);
					AddFileToDownloadsTable(file);
				}
			}
		}
		else if(!strcmp(section, "mat_download"))
		{	
			for(new i=1; ; i++)
			{
				IntToString(i, file, 4);
				KvGetString(BossKV[Specials], file, config, PLATFORM_MAX_PATH);
				if(!config[0])
				{
					break;
				}
				Format(file, PLATFORM_MAX_PATH, "%s.vtf", config);
				AddFileToDownloadsTable(file);
				Format(file, PLATFORM_MAX_PATH, "%s.vmt", config);
				AddFileToDownloadsTable(file);
			}
		}
	}
	Specials++;
}

public PrecacheCharacter(characterIndex)
{
	decl String:s[PLATFORM_MAX_PATH];
	decl String:s2[PLATFORM_MAX_PATH];
	decl String:s3[64];
	//BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"configs/freak_fortress_2/characters.cfg");

	KvRewind(BossKV[characterIndex]);
	KvGotoFirstSubKey(BossKV[characterIndex]);
	
	while(KvGotoNextKey(BossKV[characterIndex]))
	{	
		KvGetSectionName(BossKV[characterIndex], s3, 64);

		if(!strcmp(s3,"mod_precache"))
		{	
			for(new i=1; ; i++)
			{
				IntToString(i,s2,4);
				KvGetString(BossKV[characterIndex], s2, s, PLATFORM_MAX_PATH);
				if(!s[0])
					break;
				PrecacheModel(s);
			}
		}
		else if(!strcmp(s3, "sound_bgm"))
		{
			for(new i=1; ; i++)
			{
				Format(s2, sizeof(s2), "%s%d", "path", i);
				
				KvGetString(BossKV[characterIndex], s2, s, PLATFORM_MAX_PATH);
				if(!s[0])
					break;
				PrecacheSound(s);
			}
		}
		else if(!StrContains(s3,"sound_") || !strcmp(s3,"catch_phrase"))
		{	
			for(new i=1; ; i++)
			{
				IntToString(i,s2,4);
				KvGetString(BossKV[characterIndex], s2, s, PLATFORM_MAX_PATH);
				if(!s[0])
					break;
				PrecacheSound(s);
			}
		}
	}
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar==cvarPointDelay)
	{
		PointDelay=StringToInt(newValue);
		if(PointDelay<0)
		{
			PointDelay*=-1;
		}
	}
	else if(convar==cvarAnnounce)
	{
		Announce=StringToFloat(newValue);
	}
	else if(convar==cvarPointType)
	{
		PointType=StringToInt(newValue);
	}
	else if(convar==cvarPointDelay)
	{
		PointDelay=StringToInt(newValue);
	}
	else if(convar==cvarAliveToEnable)
	{
		AliveToEnable=StringToInt(newValue);
	}
	else if(convar==cvarCrits)
	{
		BossCrits=bool:StringToInt(newValue);
	}
	else if(convar==cvarCircuitStun)
	{
		circuitStun=StringToFloat(newValue);
	}
	else if(convar==cvarCountdownPlayers)
	{
		countdownPlayers=StringToInt(newValue);
	}
	else if(convar==cvarCountdownTime)
	{
		countdownTime=StringToInt(newValue);
	}
	else if(convar==cvarCountdownHealth)
	{
		countdownHealth=StringToInt(newValue);
	}
	else if(convar==cvarLastPlayerGlow)
	{
		lastPlayerGlow=bool:StringToInt(newValue);
	}
	else if(convar==cvarGoombaDamage)
	{
		GoombaDamage=StringToFloat(newValue);
	}
	else if(convar==cvarBossRTD)
	{
		canBossRTD=bool:StringToInt(newValue);
	}
	else if(convar==cvarDisabledRTDPerks && !StrEqual(newValue, DISABLED_PERKS) && Enabled)
	{
		SetConVarString(cvarDisabledRTDPerks, DISABLED_PERKS);
	}
	else if(convar==cvarRTDTimeLimit && StringToInt(newValue)!=30 && Enabled)
	{
		SetConVarInt(cvarRTDTimeLimit, 30);
	}
	else if(convar==cvarRTDMode && StringToInt(newValue)!=0 && Enabled)
	{
		SetConVarInt(cvarRTDMode, 0);
	}
	else if(convar==cvarSpecForceBoss)
	{
		SpecForceBoss=bool:StringToInt(newValue);
	}
	else if(convar==cvarEnabled)
	{
		if(StringToInt(newValue))
		{
			Enabled2=true;
			#if defined _steamtools_included
			if(steamtools)
			{
				decl String:gameDesc[64];
				if(halloween)
				{
					Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s-HALLOWEEN)", PLUGIN_VERSION);
				}
				else
				{
					Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", PLUGIN_VERSION);
				}
				Steam_SetGameDescription(gameDesc);
			}
			#endif
		}
		else
		{
			Enabled2=false;
			#if defined _steamtools_included
			if(steamtools)
			{
				decl String:gameDesc[64];
				Format(gameDesc, sizeof(gameDesc), "Team Fortress");
				Steam_SetGameDescription(gameDesc);
			}
			#endif
		}
	}
}


public Action:Timer_Announce(Handle:hTimer)
{
	static announcecount=-1;
	announcecount++;
	if(Announce>1.0 && Enabled2)
	{
		switch(announcecount)
		{
			case 1:
			{
				CPrintToChatAll("{olive}[FF2]{default} VS Saxton Hale/Freak Fortress 2 group: {olive}http://steamcommunity.com/groups/vssaxtonhale{default}");
			}
			case 3:
			{
				CPrintToChatAll("{default} === Freak Fortress 2 v%s (based on VS Saxton Hale Mode by {olive}RainBolt Dash{default} and {olive}FlaminSarge{default}) === ", PLUGIN_VERSION);
			}
			case 4:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "type_ff2_to_open_menu");
			}
			case 5:
			{
				announcecount=0;
				CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_last_update", PLUGIN_VERSION, ff2versiondates[maxVersion]);
			}
			default: 
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "type_ff2_to_open_menu");
			}
		}
	}
	return Plugin_Continue;
}

stock bool:IsFF2Map(bool:forceRecalc=false)
{
	static bool:found=false;
	static bool:isFF2Map=false;

	if(forceRecalc)
	{
		isFF2Map=false;
		found=false;
	}

	if(!found)
	{
		decl String:s[PLATFORM_MAX_PATH];
		GetCurrentMap(currentmap, sizeof(currentmap));
		if(FileExists("bNextMapToFF2"))
		{
			isFF2Map=true;
			found=true;
			return true;
		}
		BuildPath(Path_SM, s, PLATFORM_MAX_PATH, "configs/freak_fortress_2/maps.cfg");
		if(!FileExists(s))
		{
			LogError("[FF2] Unable to find %s, disabling plugin.", s);
			isFF2Map=false;
			found=true;
			return false;
		}
		new Handle:fileh=OpenFile(s, "r");
		if(fileh==INVALID_HANDLE)
		{
			LogError("[FF2] Error reading maps from %s, disabling plugin.", s);
			isFF2Map=false;
			found=true;
			return false;
		}
		new pingas=0;
		while(ReadFileLine(fileh, s, sizeof(s)) && (pingas<100))
		{
			pingas++;
			if(pingas==100)
				LogError("[FF2] Breaking infinite loop when trying to check the map.");
			Format(s, strlen(s)-1, s);
			if(strncmp(s, "//", 2, false)==0) continue;
			if((StrContains(currentmap, s, false)==0) || (StrContains(s, "all", false)==0))
			{
				CloseHandle(fileh);
				isFF2Map=true;
				found=true;
				return true;
			}
		}
		CloseHandle(fileh);
	}
	return isFF2Map;
}

stock bool:MapHasMusic(bool:forceRecalc=false)	//SAAAAAARGE
{
	static bool:hasMusic;
	static bool:found=false;
	if(forceRecalc)
	{
		found=false;
		hasMusic=false;
	}
	if(!found)
	{
		new i=-1;
		decl String:name[64];
		while((i=FindEntityByClassname2(i, "info_target"))!=-1)
		{
			GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
			if(strcmp(name, "hale_no_music", false)==0) hasMusic=true;
		}
		found=true;
	}
	return hasMusic;
}
stock bool:CheckToChangeMapDoors()
{
	decl String:s[PLATFORM_MAX_PATH];
	checkdoors=false;
	BuildPath(Path_SM, s, PLATFORM_MAX_PATH, "configs/freak_fortress_2/doors.cfg");
	if(!FileExists(s))
	{
		if(strncmp(currentmap, "vsh_lolcano_pb1", 15, false)==0)
			checkdoors=true;
		return;
	}
	new Handle:fileh=OpenFile(s, "r");
	if(fileh==INVALID_HANDLE)
	{
		if(strncmp(currentmap, "vsh_lolcano_pb1", 15, false)==0)
			checkdoors=true;
		return;
	}
	while(!IsEndOfFile(fileh) && ReadFileLine(fileh, s, sizeof(s)))
	{
		Format(s, strlen(s)-1, s);
		if(strncmp(s, "//", 2, false)==0) continue;
		if(StrContains(currentmap, s, false)!=-1 || StrContains(s, "all", false)==0)
		{
			CloseHandle(fileh);
			checkdoors=true;
			return;
		}
	}
	CloseHandle(fileh);
}
public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(cvarEnabled))
	{
		#if defined _steamtools_included
		if(Enabled2 && steamtools)
		{
			Steam_SetGameDescription("Team Fortress");
		}
		#endif
		Enabled2=false;
	}

	Enabled=Enabled2;
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	if(FileExists("bNextMapToFF2"))
	{
		DeleteFile("bNextMapToFF2");
	}
	DrawGameTimer=INVALID_HANDLE;

	new bool:bBluBoss;
	switch(GetConVarInt(cvarForceBossTeam))
	{
		case 1:
		{
			bBluBoss=GetRandomInt(0, 1)==1;
		}
		case 2:
		{
			bBluBoss=false;
		}
		case 3:
		{
			bBluBoss=true;
		}
		default:
		{
			if(!StrContains(currentmap, "vsh_") || !StrContains(currentmap, "zf_"))
			{
				bBluBoss=true;
			}
			else if(RoundCounter>=3 && GetRandomInt(0, 1))
			{
				bBluBoss=(BossTeam!=3);
				RoundCounter=0;
			}
			else
			{
				bBluBoss=(BossTeam==3);
			}
		}
	}

	if(bBluBoss)
	{
		new score1=GetTeamScore(OtherTeam);
		new score2=GetTeamScore(BossTeam);
		SetTeamScore(2, score1);
		SetTeamScore(3, score2);
		OtherTeam=2;
		BossTeam=3;
	}
	else
	{
		new score1=GetTeamScore(BossTeam);
		new score2=GetTeamScore(OtherTeam);
		SetTeamScore(2, score1);
		SetTeamScore(3, score2);
		BossTeam=2;
		OtherTeam=3;
	}

	playing=0;
	for(new client=1; client<=MaxClients; client++)
	{
		Damage[client]=0;
		uberTarget[client]=-1;
		if(IsValidClient(client) && GetClientTeam(client)>_:TFTeam_Spectator)
		{
			playing++;
		}
	}

	if(GetClientCount()<=1 || playing<=1)
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "needmoreplayers");
		Enabled=false;
		DisableSubPlugins();
		SetControlPoint(true);
		return Plugin_Continue;
	}
	else if(RoundCount==0 && !GetConVarBool(cvarFirstRound))
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "first_round");
		Enabled=false;
		DisableSubPlugins();
		SetArenaCapEnableTime(60.0);
		CreateTimer(71.0, Timer_EnableCap, _, TIMER_FLAG_NO_MAPCHANGE);
		new bool:toRed;
		new team;
		for(new client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && (team=GetClientTeam(client))>1) 
			{
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				if(toRed && team!=_:TFTeam_Red)
				{
					ChangeClientTeam(client, _:TFTeam_Red);
				}
				else if(!toRed && team!=_:TFTeam_Blue)
				{
					ChangeClientTeam(client, _:TFTeam_Blue);
				}
				SetEntProp(client, Prop_Send, "m_lifeState", 0);
				TF2_RespawnPlayer(client);
				toRed=!toRed;
			}
		}
		return Plugin_Continue;
	}

	for(new client=0; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || !IsPlayerAlive(client))
		{
			continue;
		}

		if(!(FF2flags[client] & FF2FLAG_HASONGIVED))
		{
			TF2_RespawnPlayer(client);
		}
	}

	Enabled=true;
	EnableSubPlugins();
	CheckArena();

	new bool:see[MAXPLAYERS+1];
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			new TFTeam:team=TFTeam:GetClientTeam(client);
			if(!see[0] && team==TFTeam_Blue)
			{
				see[0]=true;
			}
			else if(!see[1] && team==TFTeam_Red)
			{
				see[1]=true;
			}
		}
	}

	if(!see[0] || !see[1])
	{
		if(IsValidClient(Boss[0]))
		{
			ChangeClientTeam(Boss[0], BossTeam);
			TF2_RespawnPlayer(Boss[0]);
		}

		for(new client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !IsBoss(client) && GetClientTeam(client)>_:TFTeam_Spectator)
			{
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				ChangeClientTeam(client, OtherTeam);
				SetEntProp(client, Prop_Send, "m_lifeState", 0);
				TF2_RespawnPlayer(client);
				CreateTimer(0.1, MakeNotBoss, GetClientUserId(client));
			}
		}
		return Plugin_Continue;
	}
	see[0]=false;
	see[1]=false;

	for(new client=0; client<=MaxClients; client++)
	{
		Boss[client]=0;
	}

	Boss[0]=FindBosses(see);
	PickSpecial(0, 0);
	see[Boss[0]]=true;
	if((Special[0]<0) || !BossKV[Special[0]])
	{
		LogError("[FF2] I just don't know what went wrong");
		return Plugin_Continue;
	}
	KvRewind(BossKV[Special[0]]);
	BossLivesMax[0]=KvGetNum(BossKV[Special[0]], "lives", 1);
	SetEntProp(Boss[0], Prop_Data, "m_iMaxHealth", 1337);
	if(LastClass[Boss[0]]==TFClass_Unknown)
	{
		LastClass[Boss[0]]=TF2_GetPlayerClass(Boss[0]);
	}

	if(playing>2)
	{
		decl String:companion[64];
		for(new client=1; client<=MaxClients; client++)
		{		
			KvRewind(BossKV[Special[client-1]]);
			KvGetString(BossKV[Special[client-1]], "companion", companion, 64);
			if(StrEqual(companion, ""))
			{
				break;
			}

			new tempBoss=FindBosses(see);
			if(!IsValidClient(tempBoss))
			{
				break;
			}
			Boss[client]=tempBoss;

			if(PickSpecial(client, client-1))
			{
				KvRewind(BossKV[Special[client]]);
				for(new pingas=0; Boss[client]==Boss[client-1] && pingas<100; pingas++)
				{
					Boss[client]=FindBosses(see);
				}
				see[Boss[client]]=true;
				BossLivesMax[client]=KvGetNum(BossKV[Special[client]], "lives", 1);
				SetEntProp(Boss[client], Prop_Data, "m_iMaxHealth", 1337);
				if(LastClass[Boss[client]]==TFClass_Unknown)
				{
					LastClass[Boss[client]]=TF2_GetPlayerClass(Boss[client]);
				}
			}
			else
			{
				Boss[client]=0;
			}
		}
	}
	CreateTimer(0.2, Timer_GogoBoss);
	CreateTimer(3.5, StartResponseTimer);
	CreateTimer(9.1, StartBossTimer);
	CreateTimer(9.6, MessageTimer);

	for(new entity=MaxClients+1; entity<MAXENTITIES; entity++)
	{
		if(!IsValidEdict(entity))
		{
			continue;
		}

		decl String:classname[64];
		GetEdictClassname(entity, classname, 64);
		if(!strcmp(classname, "func_regenerate"))
		{
			AcceptEntityInput(entity, "Kill");
		}
		else if(!strcmp(classname, "func_respawnroomvisualizer"))
		{
			AcceptEntityInput(entity, "Disable");
		}
		else if(!strcmp(classname, "item_ammopack_full") || !strcmp(classname, "item_ammopack_medium"))
		{
			decl Float:position[3];
			new pack;
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);  
			AcceptEntityInput(entity, "Kill");
			pack=CreateEntityByName("item_ammopack_small");
			TeleportEntity(pack, position, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(pack);
		}
	}
	healthcheckused=0;
	return Plugin_Continue;
}

public Action:Timer_EnableCap(Handle:timer)
{
	if(CheckRoundState()==-1)
	{
		SetControlPoint(true);
		if(checkdoors)
		{
			new ent=-1;
			while((ent=FindEntityByClassname2(ent, "func_door"))!=-1)
			{
				AcceptEntityInput(ent, "Open");
				AcceptEntityInput(ent, "Unlock");
			}
			if(doorchecktimer==INVALID_HANDLE)
				doorchecktimer=CreateTimer(5.0, Timer_CheckDoors, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	}
}

public Action:Timer_GogoBoss(Handle:hTimer)
{
	if(!CheckRoundState())
	{
		for(new client=0; client<=MaxClients; client++)
		{
			BossInfoTimer[client][0]=INVALID_HANDLE;
			BossInfoTimer[client][1]=INVALID_HANDLE;
			if(Boss[client])
			{
				CreateTimer(0.1, MakeBoss, client);
				BossInfoTimer[client][0]=CreateTimer(30.0, BossInfoTimer_Begin, client);
			}
		}
	}
	return Plugin_Continue;
}

public Action:BossInfoTimer_Begin(Handle:hTimer, any:client)
{
	BossInfoTimer[client][0]=INVALID_HANDLE;
	BossInfoTimer[client][1]=CreateTimer(0.2, BossInfoTimer_ShowInfo, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:BossInfoTimer_ShowInfo(Handle:hTimer, any:client)
{
	if((FF2flags[Boss[client]] & FF2FLAG_USINGABILITY) || (FF2flags[Boss[client]] & FF2FLAG_HUDDISABLED))
	{
		BossInfoTimer[client][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}

	new bool:see;
	for(new n=1; ; n++)
	{		
		decl String:s[10];
		Format(s, 10, "ability%i", n);
		if(client==-1 || Special[client]==-1 || !BossKV[Special[client]])
		{
			return Plugin_Stop;
		}

		KvRewind(BossKV[Special[client]]);
		if(KvJumpToKey(BossKV[Special[client]], s))
		{
			decl String:plugin_name[64];
			KvGetString(BossKV[Special[client]], "plugin_name", plugin_name, 64);
			if(KvGetNum(BossKV[Special[client]], "buttonmode", 0)==2)
			{
				see=true;
				break;
			}
		}
		else
		{
			break;
		}
	}
	new need_info_bout_reload=see && CheckInfoCookies(Boss[client], 0);
	new need_info_bout_rmb=CheckInfoCookies(Boss[client], 1);
	if(need_info_bout_reload)
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		SetGlobalTransTarget(Boss[client]);
		if(need_info_bout_rmb)
		{
			ShowSyncHudText(Boss[client], abilitiesHUD, "%t\n%t", "ff2_buttons_reload", "ff2_buttons_rmb");
		}
		else
		{
			ShowSyncHudText(Boss[client], abilitiesHUD, "%t", "ff2_buttons_reload");
		}
	}
	else if(need_info_bout_rmb)
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		SetGlobalTransTarget(Boss[client]);
		ShowSyncHudText(Boss[client], abilitiesHUD, "%t", "ff2_buttons_rmb");
	}
	else
	{
		BossInfoTimer[client][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_CheckDoors(Handle:hTimer)
{
	if(!checkdoors)
	{
		doorchecktimer=INVALID_HANDLE;
		return Plugin_Stop;
	}

	if((!Enabled && CheckRoundState()!=-1) || (Enabled && CheckRoundState()!=1))
		return Plugin_Continue;
	new ent=-1;
	while((ent=FindEntityByClassname2(ent, "func_door"))!=-1)
	{
		AcceptEntityInput(ent, "Open");
		AcceptEntityInput(ent, "Unlock");
	}
	return Plugin_Continue;
}

public CheckArena()
{
	if(PointType)
		SetArenaCapEnableTime(float(45+PointDelay*(playing-1)));
	else
	{
		SetArenaCapEnableTime(0.0);
		SetControlPoint(false);
	}
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:sound[512];
	RoundCount++;

	if(!Enabled)
	{
		return Plugin_Continue;
	}

	executed=false;
	executed2=false;
	new bool:bossWin=false;
	if((GetEventInt(event, "team")==BossTeam))
	{
		if(RandomSound("sound_win", sound, PLATFORM_MAX_PATH))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss[0], _, NULL_VECTOR, false, 0.0);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss[0], _, NULL_VECTOR, false, 0.0);
		}

	}

	Native_StopMusic(INVALID_HANDLE, 0);
	if(MusicTimer!=INVALID_HANDLE)
	{
		KillTimer(MusicTimer);
		MusicTimer=INVALID_HANDLE;
	}

	new bool:isBossAlive;
	new temp;
	for(new client=0; client<=MaxClients; client++)
	{
		if(IsValidClient(Boss[client]))
		{
			SetClientGlow(client, 0.0, 0.0);
			if(IsPlayerAlive(Boss[client]))
			{
				isBossAlive=true;
				temp=client;
			}

			for(new slot=0; slot<8; slot++)
			{
				BossCharge[client][slot]=0.0;
			}
		}
		else if(IsValidClient(client))
		{
			SetClientGlow(client, 0.0, 0.0);
			demoShield[client]=0;
		}

		for(new boss=0; boss<=1; boss++)
		{
			if(BossInfoTimer[client][boss]!=INVALID_HANDLE)
			{
				KillTimer(BossInfoTimer[client][boss]);
				BossInfoTimer[client][boss]=INVALID_HANDLE;
			}
		}
	}

	strcopy(sound, 2, "");
	if(isBossAlive)
	{
		decl String:bossName[64];
		decl String:lives[4];
		for(new client=0; Boss[client]; client++)
		{
			KvRewind(BossKV[Special[client]]);
			KvGetString(BossKV[Special[client]], "name", bossName, 64, "=Failed name=");
			if(BossLives[client]>1)
			{
				Format(lives, 4, "x%client", BossLives[client]);
			}
			else
			{
				strcopy(lives, 2, "");
			}
			Format(sound, 512, "%s\n%t", sound, "ff2_alive", bossName, BossHealth[client]-BossHealthMax[client]*(BossLives[client]-1), BossHealthMax[client], lives);
		}

		if(RandomSound("sound_fail", sound, PLATFORM_MAX_PATH, temp))
		{
			EmitSoundToAll(sound);
			EmitSoundToAll(sound);
		}
		bossWin=true;
	}

	new top[3];
	Damage[0]=0;
	for(new client=0; client<=MaxClients; client++)
	{
		if(Damage[client]>=Damage[top[0]])
		{
			top[2]=top[1];
			top[1]=top[0];
			top[0]=client;
		}
		else if(Damage[client]>=Damage[top[1]])
		{
			top[2]=top[1];
			top[1]=client;
		}
		else if(Damage[client]>=Damage[top[2]] && Damage[client]!=0)
		{
			top[2]=client;
		}
	}

	if(Damage[top[0]]>9000)
	{
		CreateTimer(1.0, Timer_NineThousand, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	decl String:first[32];
	if(IsValidClient(top[0]) && !IsBoss(top[0]))
	{
		GetClientName(top[0], first, 32);
	}
	else
	{
		Format(first, 32, "---");
		top[0]=0;
	}

	decl String:second[32];
	if(IsValidClient(top[1]) && !IsBoss(top[1]))
	{
		GetClientName(top[1], second, 32);
	}
	else
	{
		Format(second, 32, "---");
		top[1]=0;
	}

	decl String:third[32];
	if(IsValidClient(top[2]) && !IsBoss(top[2]))
	{
		GetClientName(top[2], third, 32);
	}
	else
	{
		Format(third, 32, "---");
		top[2]=0;
	}

	SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
	PrintCenterTextAll("");
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !(FF2flags[client] & FF2FLAG_HUDDISABLED))
		{
			SetGlobalTransTarget(client);
			if(IsBoss(client))
			{
				if(bossWin)
				{
					ShowHudText(client, -1, "%s\n%t:\n1)%i-%s\n2)%i-%s\n3)%i-%s\n\n%t", sound, "top_3", Damage[top[0]], first, Damage[top[1]], second, Damage[top[2]], third, "boss_win");
				}
				else
				{
					ShowHudText(client, -1, "%s\n%t:\n1)%i-%s\n2)%i-%s\n3)%i-%s\n\n%t", sound, "top_3", Damage[top[0]], first, Damage[top[1]], second, Damage[top[2]], third, "boss_lose");
				}
			}
			else
			{
				ShowHudText(client, -1, "%s\n%t:\n1)%i-%s\n2)%i-%s\n3)%i-%s\n\n%t\n%t", sound, "top_3", Damage[top[0]], first, Damage[top[1]], second, Damage[top[2]], third, "damage_fx", Damage[client], "scores", RoundFloat(Damage[client]/600.0));
			}
		}
	}

	CreateTimer(3.0, Timer_CalcQueuePoints, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
	return Plugin_Continue;
}

public Action:Timer_NineThousand(Handle:timer)
{
	EmitSoundToAll("saxton_hale/9000.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
	return Plugin_Continue;
}

public Action:Timer_CalcQueuePoints(Handle:timer)
{
	CalcQueuePoints();
}

stock CalcQueuePoints()
{
	decl damage;
	botqueuepoints+=5;
	new add_points[MAXPLAYERS+1];
	new add_points2[MAXPLAYERS+1];
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			damage=Damage[client];
			new Handle:event=CreateEvent("player_escort_score", true);
			SetEventInt(event, "player", client);

			new points;
			for(points=0; damage-600>0; damage-=600, points++)
			{
			}
			SetEventInt(event, "points", points);
			FireEvent(event);

			if(IsBoss(client))
			{
				if(IsFakeClient(client))
				{
					botqueuepoints=0;
				}
				else
				{
					add_points[client]=-GetClientQueuePoints(client);
					add_points2[client]=add_points[client];
				}
			}
			else if(!IsFakeClient(client) && (GetClientTeam(client)>_:TFTeam_Spectator || SpecForceBoss))
			{
				add_points[client]=10;
				add_points2[client]=10;
			}
		}
	}

	new Action:act=Plugin_Continue;
	Call_StartForward(OnAddQueuePoints);
	Call_PushArrayEx(add_points2, MAXPLAYERS+1, SM_PARAM_COPYBACK);
	Call_Finish(act);
	switch(act)
	{
		case Plugin_Stop, Plugin_Handled:
		{
			return;
		}
		case Plugin_Changed:
		{
			for(new client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					if(add_points2[client]>0)
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "add_points", add_points2[client]);
					}
					SetClientQueuePoints(client, GetClientQueuePoints(client)+add_points2[client]);
				}
			}
		}
		default:
		{
			for(new client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					if(add_points[client]>0)
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "add_points", add_points[client]);
					}
					SetClientQueuePoints(client, GetClientQueuePoints(client)+add_points[client]);
				}
			}
		}
	}
}

public Action:StartResponseTimer(Handle:hTimer)
{
	decl String:sound[PLATFORM_MAX_PATH];
	if(RandomSound("sound_begin", sound, PLATFORM_MAX_PATH))
	{		
		EmitSoundToAll(sound);
		EmitSoundToAll(sound);
	}
	return Plugin_Continue;
}

public Action:StartBossTimer(Handle:hTimer)
{
	CreateTimer(0.1, GottamTimer);
	new bool:isBossAlive=false;
	for(new client=0; client<=MaxClients; client++)
	{
		if(Boss[client] && IsValidEdict(Boss[client]) && IsPlayerAlive(Boss[client]))
		{
			isBossAlive=true;
			SetEntityMoveType(Boss[client], MOVETYPE_NONE);
		}
	}

	if(!isBossAlive)
	{
		return Plugin_Continue; 		
	}

	playing=0;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsBoss(client) && IsPlayerAlive(client)) 
		{
			playing++;
			CreateTimer(0.15, MakeNotBoss, GetClientUserId(client));
		}
	}

	if(playing<5)
	{
		playing+=2;
	}

	for(new client=0; client<=MaxClients; client++)
	{
		if(Boss[client] && IsValidEdict(Boss[client]) && IsPlayerAlive(Boss[client]))
		{
			BossHealthMax[client]=CalcBossHealthMax(client);
			if(BossHealthMax[client]<5)
			{
				BossHealthMax[client]=1322;
			}
			SetEntProp(Boss[client], Prop_Data, "m_iMaxHealth", BossHealthMax[client]);
			SetBossHealthFix(Boss[client], BossHealthMax[client]);
			BossLives[client]=BossLivesMax[client];
			BossHealth[client]=BossHealthMax[client]*BossLivesMax[client];
			BossHealthLast[client]=BossHealth[client];
		}
	}
	CreateTimer(0.2, BossTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, CheckAlivePlayers);
	CreateTimer(0.2, StartRound);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_MusicPlay, 0, TIMER_FLAG_NO_MAPCHANGE);

	if(!PointType)
	{
		SetControlPoint(false);
	}
	return Plugin_Continue;
}

public Action:Timer_MusicPlay(Handle:timer, any:client)
{
	if(CheckRoundState()!=1)
	{
		return Plugin_Continue;
	}

	if(MusicTimer!=INVALID_HANDLE)
	{
		KillTimer(MusicTimer);
		MusicTimer=INVALID_HANDLE;
	}

	if(timer!=INVALID_HANDLE && MapHasMusic())
	{
		MusicIndex=-1;
		return Plugin_Continue;
	}

	KvRewind(BossKV[Special[0]]);
	if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
	{
		decl String:music[PLATFORM_MAX_PATH];
		MusicIndex=0;
		do
		{
			MusicIndex++;
			Format(music, 10, "time%i", MusicIndex);
		}
		while(KvGetFloat(BossKV[Special[0]], music, 0.0)>1);

		MusicIndex=GetRandomInt(1, MusicIndex-1);
		Format(music, 10, "time%i", MusicIndex);
		new Float:time=KvGetFloat(BossKV[Special[0]], music);
		Format(music, 10, "path%i", MusicIndex);
		KvGetString(BossKV[Special[0]], music, music, PLATFORM_MAX_PATH);

		new Action:action=Plugin_Continue;
		Call_StartForward(OnMusic);
		decl String:sound2[PLATFORM_MAX_PATH];
		new Float:time2=time;
		strcopy(sound2, PLATFORM_MAX_PATH, music);
		Call_PushStringEx(sound2, PLATFORM_MAX_PATH, 0, SM_PARAM_COPYBACK);
		Call_PushFloatRef(time2);
		Call_Finish(action);
		switch(action)
		{
			case Plugin_Stop, Plugin_Handled:
			{
				strcopy(music, sizeof(music), "");
				time=-1.0;
			}
			case Plugin_Changed:
			{
				strcopy(music, PLATFORM_MAX_PATH, sound2);
				time=time2;
			}
		}

		if(strlen(music[0])>5)
		{
			if(!client)
			{
				EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, music);
			}
			else if(CheckSoundException(client, SOUNDEXCEPT_MUSIC))
			{
				EmitSoundToClient(client, music);
			}

			new userid;
			if(!client)
			{
				userid=0;
			}
			else
			{
				userid=GetClientUserId(client);
			}

			if(time>1)
			{
				MusicTimer=CreateTimer(time, Timer_MusicTheme, userid, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_MusicTheme(Handle:timer, any:userid)
{
	MusicTimer=INVALID_HANDLE;
	if(Enabled && CheckRoundState()==1)
	{
		KvRewind(BossKV[Special[0]]);
		if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
		{
			new client;
			if(!userid)
			{
				client=0;
			}
			else
			{
				client=GetClientOfUserId(userid);
			}

			decl String:music[PLATFORM_MAX_PATH];
			MusicIndex=0;
			do
			{
				MusicIndex++;
				Format(music, 10, "time%i",MusicIndex);
			}
			while(KvGetFloat(BossKV[Special[0]], music)>1);

			MusicIndex=GetRandomInt(1, MusicIndex-1);
			Format(music, 10, "time%i", MusicIndex);
			new Float:time=KvGetFloat(BossKV[Special[0]], music);
			Format(music, 10, "path%i", MusicIndex);
			KvGetString(BossKV[Special[0]], music, music, PLATFORM_MAX_PATH);

			new Action:action=Plugin_Continue;
			Call_StartForward(OnMusic);
			decl String:sound2[PLATFORM_MAX_PATH];
			new Float:time2=time;
			strcopy(sound2, PLATFORM_MAX_PATH, music);
			Call_PushStringEx(sound2, PLATFORM_MAX_PATH, 0, SM_PARAM_COPYBACK);
			Call_PushFloatRef(time2);
			Call_Finish(action);
			switch(action)
			{
				case Plugin_Stop, Plugin_Handled:
				{
					strcopy(music, sizeof(music), "");
					time=-1.0;
				}
				case Plugin_Changed:
				{
					strcopy(music, PLATFORM_MAX_PATH, sound2);
					time=time2;
				}
			}

			if(strlen(music[0])>5)
			{
				if(!client)
				{
					EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, music, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				}
				else if(CheckSoundException(client, SOUNDEXCEPT_MUSIC))
				{
					EmitSoundToClient(client, music);
				}

				if(time>1)
				{
					MusicTimer=CreateTimer(time, Timer_MusicTheme, userid, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

stock EmitSoundToAllExcept(exceptiontype=SOUNDEXCEPT_MUSIC, const String:sample[],
				 entity=SOUND_FROM_PLAYER,
				 channel=SNDCHAN_AUTO,
				 level=SNDLEVEL_NORMAL,
				 flags=SND_NOFLAGS,
				 Float:volume=SNDVOL_NORMAL,
				 pitch=SNDPITCH_NORMAL,
				 speakerentity=-1,
				 const Float:origin[3]=NULL_VECTOR,
				 const Float:dir[3]=NULL_VECTOR,
				 bool:updatePos=true,
				 Float:soundtime=0.0)
{
	new clients[MaxClients];
	new total=0;
	for(new i=1;  i<=MaxClients;  i++)
	{
		if(IsValidEdict(i) && IsClientInGame(i))
		{
			if(CheckSoundException(i, exceptiontype))
				clients[total++]=i;
		}
	}

	if(!total)
	{
		return;
	}

	EmitSound(clients, total, sample, entity, channel, 
		level, flags, volume, pitch, speakerentity,
		origin, dir, updatePos, soundtime);
}

stock CheckInfoCookies(client,infonum)
{
	if(!IsValidClient(client)) return false;
	if(IsFakeClient(client)) return true;
	if(!AreClientCookiesCached(client)) return true;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s, 24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	new see=StringToInt(ff2cookies_values[4+infonum]);
	return (see>0 ? see : 0);
}

stock SetInfoCookies(client,infonum,value)
{
	if(!IsValidClient(client)) return ;
	if(IsFakeClient(client)) return ;
	if(!AreClientCookiesCached(client)) return ;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s, 24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	Format(s,24,"%s %s %s %s",ff2cookies_values[0],ff2cookies_values[1],ff2cookies_values[2],ff2cookies_values[3]);
	for(new i=0;i<infonum;i++)
		Format(s,24,"%s %s",s,ff2cookies_values[4+i]);
	Format(s,24,"%s %i",s,value);
	for(new i=infonum+1;i<4;i++)
		Format(s,24,"%s %s",s,ff2cookies_values[4+i]);
	SetClientCookie(client, FF2Cookies, s);
}


stock bool:CheckSoundException(client, excepttype)
{
	if(!IsValidClient(client)) return false;
	if(IsFakeClient(client)) return true;
	if(!AreClientCookiesCached(client)) return true;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s, 24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	if(excepttype==SOUNDEXCEPT_VOICE)
		return StringToInt(ff2cookies_values[2])==1;
	return StringToInt(ff2cookies_values[1])==1;
}

SetClientSoundOptions(client, excepttype, bool:on)
{
	if(!IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client))
	{
		return;
	}

	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s, 24);
	ExplodeString(s, " ", ff2cookies_values, 8, 5);
	if(excepttype==SOUNDEXCEPT_VOICE)
	{
		if(on)
		{
			ff2cookies_values[2][0]='1';
		}
		else
		{
			ff2cookies_values[2][0]='0';
		}
	}
	else
	{
		if(on)
		{
			ff2cookies_values[1][0]='1';
		}
		else
		{
			ff2cookies_values[1][0]='0';
		}
	}
	Format(s, 24, "%s %s %s %s %s %s %s %s", ff2cookies_values[0], ff2cookies_values[1], ff2cookies_values[2], ff2cookies_values[3], ff2cookies_values[4], ff2cookies_values[5], ff2cookies_values[6], ff2cookies_values[7]);
	SetClientCookie(client, FF2Cookies, s);
}

public Action:GottamTimer(Handle:hTimer)
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}

public Action:StartRound(Handle:hTimer)
{
	for(new client=0; client<=MaxClients; client++)
	{
		if(!IsValidClient(Boss[client]))
		{
			continue;
		}

		TF2_RemovePlayerDisguise(Boss[client]);
		new bool:primary=IsValidEntity(GetPlayerWeaponSlot(Boss[client], TFWeaponSlot_Primary));
		new bool:secondary=IsValidEntity(GetPlayerWeaponSlot(Boss[client], TFWeaponSlot_Secondary));
		new bool:melee=IsValidEntity(GetPlayerWeaponSlot(Boss[client], TFWeaponSlot_Melee));
		if((!primary && !secondary && !melee) || (primary || secondary || melee))
		{
			CreateTimer(0.05, Timer_ReEquipBoss, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	CreateTimer(10.0, Timer_SkipFF2Panel);
	UpdateHealthBar();
	return Plugin_Handled;
}

public Action:Timer_ReEquipBoss(Handle:timer, any:client)
{
	if(IsValidClient(Boss[client]))
	{
		EquipBoss(client);
	}
}

public Action:Timer_SkipFF2Panel(Handle:hTimer)
{
	new bool:added[MAXPLAYERS+1];
	new i, j;
	do
	{
		new client=FindBosses(added);
		added[client]=true;
		if(client && !IsBoss(client))
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "to0_near");
			i++;
		}
		j++;
	}
	while(i<3 && j<=MaxClients);
}

public Action:MessageTimer(Handle:hTimer)
{
	if(CheckRoundState()!=0)
	{
		return Plugin_Continue;
	}

	if(checkdoors)
	{
		new entity=-1;
		while((entity=FindEntityByClassname2(entity, "func_door"))!=-1)
		{
			AcceptEntityInput(entity, "Open");
			AcceptEntityInput(entity, "Unlock");
		}

		if(doorchecktimer==INVALID_HANDLE)
		{
			doorchecktimer=CreateTimer(5.0, Timer_CheckDoors, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	}

	SetHudTextParams(-1.0, 0.4, 10.0, 255, 255, 255, 255);
	new String:text[512];
	decl String:lives[4];
	decl String:name[64];
	for(new client=0; Boss[client]; client++)
	{
		if(!IsValidEdict(Boss[client]))
		{
			continue;
		}

		CreateTimer(0.1, MakeBoss, client);
		KvRewind(BossKV[Special[client]]);
		KvGetString(BossKV[Special[client]], "name", name, 64, "=Failed name=");
		if(BossLives[client]>1)
		{
			Format(lives, 4, "x%i", BossLives[client]);
		}
		else
		{
			strcopy(lives, 2, "");
		}
		Format(text, 512, "%s\n%t", text, "ff2_start", Boss[client], name, BossHealth[client]-BossHealthMax[client]*(BossLives[client]-1), lives);
	}

	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !(FF2flags[client] & FF2FLAG_HUDDISABLED))
		{
			SetGlobalTransTarget(client);
			ShowHudText(client, -1, text);
		}
	}
	return Plugin_Continue;
}

public Action:MakeModelTimer(Handle:hTimer, any:client)
{		
	if(!Boss[client] || !IsValidEdict(Boss[client]) || !IsClientInGame(Boss[client]) || !IsPlayerAlive(Boss[client]) || CheckRoundState()==2)
	{
		return Plugin_Stop;
	}

	decl String:model[PLATFORM_MAX_PATH];
	KvRewind(BossKV[Special[client]]);
	KvGetString(BossKV[Special[client]], "model", model, PLATFORM_MAX_PATH);
	SetVariantString(model);
	AcceptEntityInput(Boss[client], "SetCustomModel");
	SetEntProp(Boss[client], Prop_Send, "m_bUseClassAnimations", 1);
	return Plugin_Continue;
}

EquipBoss(client)
{
	DoOverlay(Boss[client], "");
	TF2_RemoveAllWeapons2(Boss[client]);
	decl String:weapon[64];
	decl String:attributes[128];
	for(new i=1; ; i++)
	{
		KvRewind(BossKV[Special[client]]);
		Format(weapon, 10, "weapon%i", i);
		if(KvJumpToKey(BossKV[Special[client]], weapon))
		{
			KvGetString(BossKV[Special[client]], "name", weapon, 64);
			KvGetString(BossKV[Special[client]], "attributes", attributes, 128);
			if(attributes[0]!='\0')
			{
				if(BossCrits)
				{
					Format(attributes, sizeof(attributes), "68 ; 2.0 ; 2 ; 3.0 ; 259 ; 1.0 ; %s", attributes);
						//68: +2 cap rate
						//2: x3 damage
						//259: Mantreads effect (broken)
				}
				else
				{
					Format(attributes, sizeof(attributes), "68 ; 2.0 ; 2 ; 3 ; 259 ; 1.0 ; 15 ; 1 ; %s", attributes);
						//68: +2 cap rate
						//2: x3 damage
						//259: Mantreads effect (broken)
						//15: No crits
				}
			}
			else
			{
				if(BossCrits)
				{
					attributes="68 ; 2.0 ; 2 ; 3 ; 259 ; 1.0";
						//68: +2 cap rate
						//2: x3 damage
						//259: Mantreads effect (broken)
				}
				else
				{
					attributes="68 ; 2.0 ; 2 ; 3 ; 259 ; 1.0 ; 15 ; 1";
						//68: +2 cap rate
						//2: x3 damage
						//259: Mantreads effect (broken)
						//15: No crits
				}
			}

			new BossWeapon=SpawnWeapon(Boss[client], weapon, KvGetNum(BossKV[Special[client]], "index"), 101, 5, attributes);
			if(!KvGetNum(BossKV[Special[client]], "show", 0))
			{
				SetEntProp(BossWeapon, Prop_Send, "m_iWorldModelIndex", -1);
				SetEntProp(BossWeapon, Prop_Send, "m_nModelIndexOverrides", -1, _, 0);
			}
			SetEntPropEnt(Boss[client], Prop_Send, "m_hActiveWeapon", BossWeapon);

			KvGoBack(BossKV[Special[client]]);
			new TFClassType:class=TFClassType:KvGetNum(BossKV[Special[client]], "class", 1);
			if(TF2_GetPlayerClass(Boss[client])!=class)
			{
				TF2_SetPlayerClass(Boss[client], class);
			}
		}
		else
		{
			break;
		}
	}
}

public OnChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid")), TFClassType:oldclass=TF2_GetPlayerClass(client), team=GetClientTeam(client);
	if(team==BossTeam && !b_allowBossChgClass && IsPlayerAlive(client) && GetBossIndex(client)!=-1)
	{
		CPrintToChat(client, "{olive}[FF2]{default} Do NOT change class when you're a HALE!");
		b_BossChgClassDetected=true;
		TF2_SetPlayerClass(client, oldclass);
		CreateTimer(0.2, MakeModelTimer, client);
	}
}

public Action:MakeBoss(Handle:hTimer, any:client)
{
	if(!Boss[client] || !IsValidEdict(Boss[client]) || !IsClientInGame(Boss[client]))
	{
		return Plugin_Continue;
	}

	KvRewind(BossKV[Special[client]]);
	TF2_RemovePlayerDisguise(Boss[client]);
	TF2_SetPlayerClass(Boss[client], TFClassType:KvGetNum(BossKV[Special[client]], "class", 1));

	if(GetClientTeam(Boss[client])!=BossTeam)
	{
		b_allowBossChgClass=true;
		SetEntProp(Boss[client], Prop_Send, "m_lifeState", 2);
		ChangeClientTeam(Boss[client], BossTeam);
		SetEntProp(Boss[client], Prop_Send, "m_lifeState", 0);
		TF2_RespawnPlayer(Boss[client]);
		b_allowBossChgClass=false;
	}

	if(!IsPlayerAlive(Boss[client]))
	{
		if(CheckRoundState()==0)
		{
			TF2_RespawnPlayer(Boss[client]);
		}
		else
		{
			return Plugin_Continue;
		}
	}

	CreateTimer(0.2, MakeModelTimer, client);
	if(!IsVoteInProgress() && GetClientClassinfoCookie(Boss[client]))
	{
		HelpPanelBoss(client);
	}

	if(!IsPlayerAlive(Boss[client]))
	{
		return Plugin_Continue;
	}

	new entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable"))!=-1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		{
			switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 438, 463, 167, 477, 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 1015, 5607:  //Action slot items
				{
				}
				default:
				{
					TF2_RemoveWearable(Boss[client], entity);
				}
			}
		}
	}

	entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle"))!=-1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		{
			TF2_RemoveWearable(Boss[client], entity);
		}
	}
   
	entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable_demoshield"))!=-1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		{
			TF2_RemoveWearable(Boss[client], entity);
		}
	}

	entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_usableitem"))!=-1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		{
			switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 438, 463, 167, 477, 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542:  //Action slot items
				{
				}
				default:
				{
					TF2_RemoveWearable(Boss[client], entity);
				}
			}
		}
	}

	EquipBoss(client); 	
	KSpreeCount[client]=0;
	BossCharge[client][0]=0.0;
	SetEntProp(Boss[client], Prop_Data, "m_iMaxHealth", BossHealthMax[client]);
	SetClientQueuePoints(Boss[client], 0);
	return Plugin_Continue;
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if(!Enabled) return Plugin_Continue;
	//if(hItem!=INVALID_HANDLE) return Plugin_Continue;
	switch(iItemDefinitionIndex)
	{
		case 38, 457:  //Axtinguisher, Postal Pummeler
		{
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "", true);
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}
		case 39, 351, 1081:  //Flaregun, Detonator, Festive Flaregun
		{
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "25 ; 0.5 ; 207 ; 1.33 ; 144 ; 1.0 ; 58 ; 3.2", true);
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}
		case 40:  //Backburner
		{
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "165 ; 1.0");
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}
		case 43, 239, 1084:  //KGB, GRU, Festive GRU
		{
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, 239, "107 ; 1.5 ; 1 ; 0.5 ; 128 ; 1 ; 191 ; -7", true);
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}
		case 56, 1005, 1092:  //Huntsman, Festive Huntsman, Fortified Compound
		{
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "2 ; 1.5");
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}
/*		case 132, 266, 482:
		{
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "202 ; 0.5 ; 125 ; -15", true);
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}*/
		case 220:  //Shortstop
		{
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "328 ; 1.0", true);
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}
		case 226:  //Battalion's Backup
		{
//			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "116 ; 4.0", true);
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "140 ; 10.0");
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}
		case 305, 1079:  //Crusader's Crossbow, Festive Crusader's Crossbow
		{
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "17 ; 0.1 ; 2 ; 1.2"); //; 266 ; 1.0");
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}
		case 415:  //Reserve Shooter
		{
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "265 ; 99999.0 ; 178 ; 0.6 ; 2 ; 1.1 ; 3 ; 0.5", true);
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}
		case 444:  //Mantreads
		{
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "58 ; 1.5");
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}
		case 648:  //Wrap Assassin
		{
			new Handle:hItemOverride=PrepareItemHandle(hItem, _, _, "279 ; 2.0");
			if(hItemOverride!=INVALID_HANDLE)
			{
				hItem=hItemOverride;
				return Plugin_Changed;
			}
		}
	}

	if(TF2_GetPlayerClass(client)==TFClass_Soldier && (strncmp(classname, "tf_weapon_rocketlauncher", 24, false)==0 || strncmp(classname, "tf_weapon_shotgun", 17, false)==0))
	{
		new Handle:hItemOverride;
		if(iItemDefinitionIndex==127)  //Direct Hit
		{
			hItemOverride=PrepareItemHandle(hItem, _, _, "265 ; 99999.0 ; 179 ; 1.0");
		}
		else
		{
			hItemOverride=PrepareItemHandle(hItem, _, _, "265 ; 99999.0");
		}

		if(hItemOverride!=INVALID_HANDLE)
		{
			hItem=hItemOverride;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:Timer_NoHonorBound(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		new weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		new index=((IsValidEntity(weapon) && weapon>MaxClients) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
		new active=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new String:classname[64];
		if(IsValidEdict(active)) GetEdictClassname(active, classname, sizeof(classname));
		if(index==357 && active==weapon && strcmp(classname, "tf_weapon_katana", false)==0)
		{
			SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
			if(GetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy")<1)
				SetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
		}
	}
}

stock Handle:PrepareItemHandle(Handle:hItem, String:name[]="", index=-1, const String:att[]="", bool:dontpreserve=false)
{
	static Handle:hWeapon;
	new addattribs=0;

	new String:weaponAttribsArray[32][32];
	new attribCount=ExplodeString(att, ";", weaponAttribsArray, 32, 32);
	
	if(attribCount%2!=0)
	{
		--attribCount;
	}

	new flags=OVERRIDE_ATTRIBUTES;
	if(!dontpreserve) flags|=PRESERVE_ATTRIBUTES;
	if(hWeapon==INVALID_HANDLE) hWeapon=TF2Items_CreateItem(flags);
	else TF2Items_SetFlags(hWeapon, flags);
//	new Handle:hWeapon=TF2Items_CreateItem(flags);	//INVALID_HANDLE;
	if(hItem!=INVALID_HANDLE)
	{
		addattribs=TF2Items_GetNumAttributes(hItem);
		if(addattribs>0)
		{
			for(new i=0; i<2*addattribs; i+=2)
			{
				new bool:dontAdd=false;
				new attribIndex=TF2Items_GetAttributeId(hItem, i);
				for(new z=0; z<attribCount+i; z+=2)
				{
					if(StringToInt(weaponAttribsArray[z])==attribIndex)
					{
						dontAdd=true;
						break;
					}
				}
				if(!dontAdd)
				{
					IntToString(attribIndex, weaponAttribsArray[i+attribCount], 32);
					FloatToString(TF2Items_GetAttributeValue(hItem, i), weaponAttribsArray[i+1+attribCount], 32);
				}
			}
			attribCount+=2*addattribs;
		}
		CloseHandle(hItem);	//probably returns false but whatever
	}

	if(name[0]!='\0')
	{
		flags|=OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(hWeapon, name);
	}
	if(index!=-1)
	{
		flags|=OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(hWeapon, index);
	}
	if(attribCount>0)
	{
		TF2Items_SetNumAttributes(hWeapon, (attribCount/2));
		new i2=0;
		for(new i=0; i<attribCount && i2<16; i+=2)
		{
			new attrib=StringToInt(weaponAttribsArray[i]);
			if(attrib==0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", weaponAttribsArray[i], weaponAttribsArray[i+1]);
				CloseHandle(hWeapon);
				return INVALID_HANDLE;
			}
			
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}
	TF2Items_SetFlags(hWeapon, flags);
	return hWeapon;
}

public Action:MakeNotBoss(Handle:hTimer, any:clientid)
{
	new client=GetClientOfUserId(clientid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==2 || IsBoss(client))
	{
		return Plugin_Continue;
	}

	if(LastClass[client]!=TFClass_Unknown)
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		TF2_SetPlayerClass(client,LastClass[client]);
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
		LastClass[client]=TFClass_Unknown;
		TF2_RespawnPlayer(client);
	}

	if(!IsVoteInProgress() && GetClientClassinfoCookie(client) && !(FF2flags[client] & FF2FLAG_CLASSHELPED))
	{
		HelpPanel2(client);
	}

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	
	if(GetClientTeam(client)!=OtherTeam)
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		ChangeClientTeam(client, OtherTeam);
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
		TF2_RespawnPlayer(client);
	}

	CreateTimer(0.1, checkItems, client);
	return Plugin_Continue;
}

public Action:checkItems(Handle:hTimer, any:client)  //Weapon balance 2
{
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==2 || IsBoss(client))
	{
		return Plugin_Continue;
	}

	SetEntityRenderColor(client, 255, 255, 255, 255);
	new weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	new index=-1;
	new civilianCheck[MAXPLAYERS+1];
	
	if(bMedieval)  //Make sure players can't stay cloaked forever in medieval mode
	{
		weapon=GetPlayerWeaponSlot(client, 4);
		if(weapon && IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==60)  //Cloak and Dagger
		{
			TF2_RemoveWeaponSlot2(client, 4);
			weapon=SpawnWeapon(client, "tf_weapon_invis", 30, 1, 0, "");
		}
		return Plugin_Continue;
	}

	if(weapon && IsValidEdict(weapon))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(index)
		{
			case 41:  //Natascha
			{
				TF2_RemoveWeaponSlot2(client, TFWeaponSlot_Primary);
				weapon=SpawnWeapon(client, "tf_weapon_minigun", 15, 1, 0, "");
			}
			case 402:  //Bazaar Bargain
			{
				TF2_RemoveWeaponSlot2(client, TFWeaponSlot_Primary);
				SpawnWeapon(client, "tf_weapon_sniperrifle", 14, 1, 0, "");
			}
			case 237:  //Rocket Jumper
			{
				TF2_RemoveWeaponSlot2(client, TFWeaponSlot_Primary);
				weapon=SpawnWeapon(client, "tf_weapon_rocketlauncher", 18, 1, 0, "265 ; 99999.0");
					//265: Mini-crits airborne targets for 99999 seconds
				SetAmmo(client, 0, 20);
			}
			case 17, 204, 36, 412:  //Syringe Guns
			{
				if(GetEntProp(weapon, Prop_Send, "m_iEntityQuality")!=10)
				{
					TF2_RemoveWeaponSlot2(client, TFWeaponSlot_Primary);
					SpawnWeapon(client, "tf_weapon_syringegun_medic", 17, 1, 10, "17 ; 0.05 ; 144 ; 1");
						//17: +5 uber/hit
						//144:  NOOP
				}
			}
		}
	}
	else
	{
		civilianCheck[client]++;
	}

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(weapon && IsValidEdict(weapon))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(index)
		{
			case 57, 231:  //Razorback, Darwin's Danger Shield
			{
				TF2_RemoveWeaponSlot2(client, TFWeaponSlot_Secondary);
				weapon=SpawnWeapon(client, "tf_weapon_smg", 16, 1, 0, "");
			}
			case 265:  //Stickybomb Jumper
			{
				TF2_RemoveWeaponSlot2(client, TFWeaponSlot_Secondary);
				weapon=SpawnWeapon(client, "tf_weapon_pipebomblauncher", 20, 1, 0, "");
				SetAmmo(client, 1, 24);
			}
		}
	}
	else
	{
		civilianCheck[client]++;
	}

	if(IsValidEntity(FindPlayerBack(client, {57, 231}, 2)))  //Razorback, Darwin's Danger Shield
	{
		RemovePlayerBack(client, {57 , 231}, 2);
		weapon=SpawnWeapon(client, "tf_weapon_smg", 16, 1, 0, "");
	}

	if(IsValidEntity(FindPlayerBack(client, {642}, 1)))  //Cozy Camper
	{
		weapon=SpawnWeapon(client, "tf_weapon_smg", 16, 1, 6, "149 ; 1.5 ; 15 ; 0.0 ; 1 ; 0.85");
	}

	new entity=-1;
	if((entity=FindEntityByClassname2(entity, "tf_wearable_demoshield"))!=-1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			demoShield[client]=entity;
		}
	}

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(weapon && IsValidEdict(weapon))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(index)
		{
			case 331:  //Fists of Steel
			{
				TF2_RemoveWeaponSlot2(client, TFWeaponSlot_Melee);
				weapon=SpawnWeapon(client, "tf_weapon_fists", 5, 1, 6, "");
			}
			case 357:  //Half-Zatoichi
			{
				CreateTimer(1.0, Timer_NoHonorBound, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			case 589:  //Eureka Effect
			{
				if(!GetConVarBool(cvarEnableEurekaEffect))
				{
					TF2_RemoveWeaponSlot2(client, TFWeaponSlot_Melee);
					weapon=SpawnWeapon(client, "tf_weapon_wrench", 7, 1, 0, "");
				}
			}
		}
	}
	else
	{
		civilianCheck[client]++;
	}

	weapon=GetPlayerWeaponSlot(client, 4);
	if(weapon && IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==60)  //Cloak and Dagger
	{
		TF2_RemoveWeaponSlot2(client, 4);
		weapon=SpawnWeapon(client, "tf_weapon_invis", 30, 1, 0, "");
	}

	if(TF2_GetPlayerClass(client)==TFClass_Medic)
	{
		weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		new mediquality=(weapon>MaxClients && IsValidEdict(weapon) ? GetEntProp(weapon, Prop_Send, "m_iEntityQuality") : -1);
		if(mediquality!=10)
		{
			TF2_RemoveWeaponSlot2(client, TFWeaponSlot_Secondary);
			weapon=SpawnWeapon(client, "tf_weapon_medigun", 29, 5, 10, "10 ; 1.25 ; 178 ; 0.75 ; 144 ; 2.0 ; 11 ; 1.5");  //200 ; 1 for area of effect healing	//; 178 ; 0.75 ; 128 ; 1.0 Faster switch-to
			if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee)==142)  //Gunslinger (Randomizer, etc. compatability)
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, 75);
			}
			SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 0.40);
		}
	}
	
	if(civilianCheck[client]==3 && !(FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		civilianCheck[client]=0;
		CPrintToChat(client, "{olive}[FF2]{default} Respawning you because you have no weapons!");
		TF2_RespawnPlayer(client);
	}
	civilianCheck[client]=0;
	return Plugin_Continue;
}

stock RemovePlayerTarge(client)
{
	new entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable_demoshield"))!=-1)
	{
		new index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if((index==131 || index==406) && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))  //The Chargin' Targe, Splendid Screen
		{
			TF2_RemoveWearable(client, entity);
		}
	}
}

stock RemovePlayerBack(client, indices[], len)
{
	if(len<=0)
	{
		return;
	}

	new entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable"))!=-1)
	{
		decl String:netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				for(new i=0; i<len; i++)
				{
					if(index==indices[i])
					{
						TF2_RemoveWearable(client, entity);
					}
				}
			}
		}
	}
	
	entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle"))!=-1)
	{
		decl String:netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFPowerupBottle"))
		{
			new index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				for(new i=0; i<len; i++)
				{
					if(index==indices[i])
					{
						AcceptEntityInput(entity, "Kill");
					}
				}
			}
		}
	}
}

stock FindPlayerBack(client, indices[], len)
{
	if(len<=0)
	{
		return -1;
	}

	new entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable"))!=-1)
	{
		decl String:netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				for(new i=0; i<len; i++)
				{
					if(index==indices[i])
					{
						return entity;
					}
				}
			}
		}
	}
	
	entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle"))!=-1)
	{
		decl String:netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFPowerupBottle"))
		{
			new index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				for(new i=0; i<len; i++)
				{
					if(index==indices[i])
					{
						return entity;
					}
				}
			}
		}
	}
	return -1;
}

public Action:event_destroy(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled)
	{
		new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
		if(!GetRandomInt(0,2) && IsBoss(attacker))
		{
			decl String:s[PLATFORM_MAX_PATH];
			if(RandomSound("sound_kill_buildable",s,PLATFORM_MAX_PATH))
			{
				EmitSoundToAll(s);
				EmitSoundToAll(s);
			}
		}
	}
	return Plugin_Continue;
}

public Action:event_change_class(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled)
	{
		CreateTimer(0.1, Timer_Change_Class, GetEventInt(event, "userid"));
	}
	return Plugin_Continue;
}

public Action:Timer_Change_Class(Handle:hTimer, any:userid)
{
	new client=GetClientOfUserId(userid);
	new boss=GetBossIndex(client);
	if(boss==-1 || Special[boss]==-1 || !BossKV[Special[boss]])
	{
		return Plugin_Continue;
	}

	KvRewind(BossKV[Special[boss]]);
	new TFClassType:class=TFClassType:KvGetNum(BossKV[Special[boss]], "class", 0);
	if(TF2_GetPlayerClass(client)!=class)
	{
		TF2_SetPlayerClass(client, class);
	}
	return Plugin_Continue;
}

public Action:event_uberdeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		new medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(medigun))
		{
			decl String:s[64];
			GetEdictClassname(medigun, s, sizeof(s));
			if(!strcmp(s,"tf_weapon_medigun"))
			{
				TF2_AddCondition(client,TFCond_HalloweenCritCandy,0.5, client);
				new target=GetHealingTarget(client);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5, client);
					uberTarget[client]=target;
				}
				else uberTarget[client]=-1;
				SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel",1.51);
				CreateTimer(0.4,Timer_Lazor,EntIndexToEntRef(medigun),TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Lazor(Handle:hTimer,any:medigunid)
{
	new medigun=EntRefToEntIndex(medigunid);
	if(medigun && IsValidEntity(medigun) && CheckRoundState()==1)
	{
		new client=GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		if(client<1)
			return Plugin_Stop;
		new Float:charge=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		if(IsValidClient(client, false) && IsPlayerAlive(client) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==medigun)
		{
			new target=GetHealingTarget(client);
			if(charge>0.05)
			{
				TF2_AddCondition(client,TFCond_HalloweenCritCandy,0.5);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5);
					uberTarget[client]=target;
				}
				else uberTarget[client]=-1;
			}
		}
		if(charge<=0.05)
		{
			CreateTimer(3.0,Timer_Lazor2,EntIndexToEntRef(medigun));
			FF2flags[client]&=~FF2FLAG_UBERREADY;
			return Plugin_Stop;
		}
	}
	else
		return Plugin_Stop;
	return Plugin_Continue;
}

public Action:Timer_Lazor2(Handle:hTimer,any:medigunid)
{
	new medigun=EntRefToEntIndex(medigunid);
	if(IsValidEntity(medigun))
		SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel",GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+0.41);
	return Plugin_Continue;
}

public Action:Command_GetHPCmd(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	Command_GetHP(client);
	return Plugin_Handled;
}

public Action:Command_GetHP(client)  //TODO: This can rarely show a very large negative number if you time it right
{
	if(!Enabled || CheckRoundState()!=1)
	{
		return Plugin_Continue;
	}

	if(IsBoss(client) || GetGameTime()>=HPTime)
	{
		new String:health[512];
		decl String:lives[4];
		decl String:name[64];
		for(new boss=0; Boss[boss]; boss++)
		{
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", name, 64, "=Failed name=");
			if(BossLives[boss]>1)
			{
				Format(lives, 4, "x%i", BossLives[boss]);
			}
			else
			{
				strcopy(lives, 2, "");
			}
			Format(health, 512, "%s\n%t", health, "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
			BossHealthLast[boss]=BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
		}

		for(new target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
			{
				SetGlobalTransTarget(target);
				PrintCenterText(target, health); 	
			}
		}
		CPrintToChatAll("{olive}[FF2]{default} %s", health);

		if(GetGameTime()>=HPTime)
		{
			healthcheckused++;
			HPTime=GetGameTime()+(healthcheckused<3 ? 20.0:80.0);
		}
		return Plugin_Continue;
	}

	if(RedAlivePlayers>1)
	{
		new String:waitTime[128];
		for(new boss=0; Boss[boss]; boss++)
		{
			Format(waitTime, 128, "%s %i,", waitTime, BossHealthLast[boss]);
		}
		CPrintToChat(client, "{olive}[FF2]{default} %t", "wait_hp", RoundFloat(HPTime-GetGameTime()), waitTime);
	}
	return Plugin_Continue;
}

public Action:Command_SetNextBoss(client, args)
{
	if(!IsValidClient(client))
	{
		CReplyToCommand(client, "{olive}[FF2]{default} This command must be used in-game and without RCON.");
		return Plugin_Handled;
	}

	decl String:name[32];
	decl String:boss[64];

	if(args<1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_special <boss>");
		return Plugin_Handled;
	}
	GetCmdArgString(name, sizeof(name));

	for(new config=0; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		KvGetString(BossKV[config], "name", boss, 64);
		if(StrContains(boss, name, false)>=0)
		{
			Incoming[0]=config;
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		KvGetString(BossKV[config], "filename", boss, 64);
		if(StrContains(boss, name, false)>=0)
		{
			Incoming[0]=config;
			KvGetString(BossKV[config], "name", boss, 64);
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Boss could not be found!");
	return Plugin_Handled;
}

public Action:Command_Points(client, args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	if(args!=2)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_addpoints <target> <points>");
		return Plugin_Handled;
	}

	decl String:queuePoints[80];
	decl String:targetname[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetname, sizeof(targetname));
	GetCmdArg(2, queuePoints, sizeof(queuePoints));
	new points=StringToInt(queuePoints);

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if((target_count=ProcessTargetString(targetname, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml))<=0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new target=0; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
		{
			continue;
		}

		SetClientQueuePoints(target_list[target], GetClientQueuePoints(target_list[target])+points);
		LogAction(client, target_list[target], "\"%L\" added %d queue points to \"%L\"", client, points, target_list[target]);
		CReplyToCommand(client, "{olive}[FF2]{default} Added %d queue points to %s", points, target_name);
	}

	return Plugin_Handled;
}

public Action:Command_StopMusic(client, args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	Native_StopMusic(INVALID_HANDLE, 0);
	CReplyToCommand(client, "{olive}[FF2]{default} Stopped boss music.");
	return Plugin_Handled;
}

public Action:Command_CharSet(client, args)
{
	decl String:arg[32];
	if(args<1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_charset <charset>");
		return Plugin_Handled;
	}
	GetCmdArgString(arg, 32);
	decl String:s[PLATFORM_MAX_PATH];
	if(halloween)
	{
		BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"configs/freak_fortress_2/characters_halloween.cfg");
	}
	else
	{
		BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"configs/freak_fortress_2/characters.cfg");
	}

	new Handle:Kv=CreateKeyValues("");
	FileToKeyValues(Kv, s);
	new i=0;
	for(;;)
	{
		KvGetSectionName(Kv, s, 64);
		if(StrContains(s,arg,false)>=0)
		{
			CReplyToCommand(client, "{default}[FF2]{olive} Charset for nextmap is %s",s);
			break;
		}
		if(!KvGotoNextKey(Kv))
		{
			CReplyToCommand(client, "{default}[FF2]{olive} ff2_charset: Charset not found ");
			return Plugin_Handled;			
		}
	}
	CloseHandle(Kv);
	FF2CharSet=i;
	isCharSetSelected=true;
	return Plugin_Handled;
}

public Action:Command_ReloadSubPlugins(client, args)
{
	if(Enabled)
	{
		DisableSubPlugins(true);
		EnableSubPlugins(true);
	}	
	CReplyToCommand(client, "{olive}[FF2]{default} Reloaded subplugins!");	
	return Plugin_Handled;
}

public Action:Command_Point_Disable(client, args)
{
	if(Enabled) SetControlPoint(false);
	return Plugin_Handled;
}

public Action:Command_Point_Enable(client, args)
{
	if(Enabled) SetControlPoint(true);
	return Plugin_Handled;
}

stock SetControlPoint(bool:enable)
{
	new CPm=MaxClients+1; 	
	while((CPm=FindEntityByClassname2(CPm, "team_control_point"))!=-1)
	{
		if(CPm>MaxClients && IsValidEdict(CPm))
		{
			AcceptEntityInput(CPm, (enable ? "ShowModel" : "HideModel"));
			SetVariantInt(enable ? 0 : 1);
			AcceptEntityInput(CPm, "SetLocked");
		}
	}
}
stock SetArenaCapEnableTime(Float:time)
{
	new ent=-1;
	decl String:strTime[32];
	FloatToString(time, strTime, sizeof(strTime));
	if((ent=FindEntityByClassname2(-1, "tf_logic_arena"))!=-1 && IsValidEdict(ent))
	{
		DispatchKeyValue(ent, "CapEnableDelay", strTime);
	}
}

public OnClientPutInServer(client)
{
	FF2flags[client]=0;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	Damage[client]=0;
	uberTarget[client]=-1;
	if(!AreClientCookiesCached(client))
	{
		return;
	}

	new String:buffer[24];
	GetClientCookie(client, FF2Cookies, buffer, 24);
	if(!buffer[0])
	{
		SetClientCookie(client, FF2Cookies, "0 1 1 1 3 3 3");
	}
	LastClass[client]=TFClass_Unknown;
}

public Action:Timer_RegenPlayer(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_RegeneratePlayer(client);
	}
}

public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client, false))
	{
		return Plugin_Continue;
	}

	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");

	if(b_BossChgClassDetected)
	{
		TF2_RemoveAllWeapons2(client);
		b_BossChgClassDetected=false;
	}

	if(GetBossIndex(client)>=0 && CheckRoundState()==0)
	{
		TF2_RemoveAllWeapons2(client);
	}

	if((CheckRoundState()!=1 || !(FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM)))
	{
		if(!(FF2flags[client] & FF2FLAG_HASONGIVED))
		{
			FF2flags[client]|=FF2FLAG_HASONGIVED;
			RemovePlayerBack(client, {57, 133, 231, 405, 444, 608, 642}, 7);
			RemovePlayerTarge(client);
			TF2_RemoveAllWeapons2(client);
			TF2_RegeneratePlayer(client);
			CreateTimer(0.1, Timer_RegenPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		CreateTimer(0.2, MakeNotBoss, GetClientUserId(client));
	}
	else
	{
		CreateTimer(0.1, checkItems, client);
	}

	FF2flags[client]&=~(FF2FLAG_UBERREADY | FF2FLAG_ISBUFFED | FF2FLAG_TALKING | FF2FLAG_ALLOWSPAWNINBOSSTEAM | FF2FLAG_USINGABILITY | FF2FLAG_CLASSHELPED);
	FF2flags[client]|=FF2FLAG_USEBOSSTIMER;
	return Plugin_Continue;
}

public Action:ClientTimer(Handle:hTimer)
{
	if(CheckRoundState()==2 || CheckRoundState()==-1)
	{
		return Plugin_Stop;
	}

	decl String:wepclassname[32];
	decl TFCond:cond;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsBoss(client) && !(FF2flags[client] & FF2FLAG_CLASSTIMERDISABLED))
		{
			if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
			{
				SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
				if(!IsPlayerAlive(client))
				{
					new observer=GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
					if(IsValidClient(observer) && !IsBoss(observer) && observer!=client)
					{
						ShowSyncHudText(client, rageHUD, "Damage: %d-%N's Damage: %d", Damage[client], observer, Damage[observer]);
					}
					else
					{
						ShowSyncHudText(client, rageHUD, "Damage: %d", Damage[client]);
					}
					continue;
				}
				ShowSyncHudText(client, rageHUD, "Damage: %d", Damage[client]);
			}

			new TFClassType:class=TF2_GetPlayerClass(client);
			new weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(weapon<=MaxClients || !IsValidEntity(weapon) || !GetEdictClassname(weapon, wepclassname, sizeof(wepclassname)))
			{
				strcopy(wepclassname, sizeof(wepclassname), "");
			}
			new bool:validwep=(strncmp(wepclassname, "tf_wea", 6, false)==0);

			if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				if(GetClientCloakIndex(client)==59)
				{
					if(TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
					{
						TF2_RemoveCondition(client, TFCond_DeadRingered);
					}
				}
				else
				{
					TF2_AddCondition(client, TFCond_DeadRingered, 0.3);
				}
			}

			new index=(validwep ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if(class==TFClass_Medic)
			{
				if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
				{
					new medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					decl String:mediclassname[64];
					if(IsValidEdict(medigun) && GetEdictClassname(medigun, mediclassname, sizeof(mediclassname)) && strcmp(mediclassname, "tf_weapon_medigun", false)==0)
					{
						new charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
						if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
						{
							SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
							ShowSyncHudText(client, jumpHUD, "%T: %i", "uber-charge", client, charge);
						}

						if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
						{
							FakeClientCommandEx(client, "voicemenu 1 7");
							FF2flags[client]|=FF2FLAG_UBERREADY;
						}
					}
				}
				else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
				{
					new healtarget=GetHealingTarget(client, true);
					if(IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget)==TFClass_Scout)
					{
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
					}
				}
			}

			if(RedAlivePlayers==1 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.3);
				if(class==TFClass_Engineer && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(wepclassname, "tf_weapon_sentry_revenge", false))
				{
					SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
				}
				TF2_AddCondition(client, TFCond_Buffed, 0.3);

				if(lastPlayerGlow)
				{
					SetClientGlow(client, 3600.0);
				}
				continue;
			}
			else if(RedAlivePlayers==2 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_AddCondition(client, TFCond_Buffed, 0.3);
			}

			if(bMedieval)
			{
				continue;
			}

			cond=TFCond_HalloweenCritCandy;
			if(TF2_IsPlayerInCondition(client, TFCond_CritCola) && (class==TFClass_Scout || class==TFClass_Heavy))
			{
				TF2_AddCondition(client, cond, 0.3);
				continue;
			}

			new healer=-1;
			for(new healtarget=1; healtarget<=MaxClients; healtarget++)
			{
				if(IsValidClient(healtarget) && IsPlayerAlive(healtarget) && GetHealingTarget(healtarget, true)==client)
				{
					healer=healtarget;
					break;
				}
			}

			new bool:addthecrit=false;
			if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
			{
				if(strcmp(wepclassname, "tf_weapon_knife", false)!=0)
				{
					addthecrit=true;
				}
			}

			switch(index)
			{
				case 16, 56, 58, 203, 305, 1005, 1079, 1092:  //SMG, Huntsman, Jarate, Strange SMG, Crusader's Crossbow, Festive Huntsman, Festive Crossbow, Fortified Compound
				{
					addthecrit=true;
				}
				case 22, 23, 160, 209, 294, 449, 773:  //Pistols
				{
					addthecrit=true;
					if(class==TFClass_Scout && cond==TFCond_HalloweenCritCandy)
					{
						cond=TFCond_Buffed;
					}
				}
				case 656:  //Holiday Punch
				{
					addthecrit=true;
					cond=TFCond_Buffed;
				}
			}

			if(index==16 && addthecrit && IsValidEntity(FindPlayerBack(client, {642}, 1)))  //SMG
			{
				addthecrit=false;
			}

			switch(class)
			{
				case TFClass_Medic:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						new medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
						if(IsValidEdict(medigun))
						{
							SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
							new charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
							ShowHudText(client, -1, "%T: %i", "uber-charge", client, charge);
							if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
							{
								FakeClientCommand(client,"voicemenu 1 7");
								FF2flags[client]|= FF2FLAG_UBERREADY;
							}
						}
					}
					else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
					{
						new healtarget=GetHealingTarget(client, true);
						if(IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget)==TFClass_Scout)
						{
							TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
						}
					}
				}
				case TFClass_DemoMan:
				{
					if(!IsValidEntity(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)))
					{
						addthecrit=true;
					}
				}
				case TFClass_Spy:
				{
					if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						if(!TF2_IsPlayerCritBuffed(client) && !TF2_IsPlayerInCondition(client, TFCond_Buffed) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !GetEntProp(client, Prop_Send, "m_bFeignDeathReady"))
						{
							TF2_AddCondition(client, TFCond_CritCola, 0.3);
						}
					}
				}
				case TFClass_Engineer:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(wepclassname, "tf_weapon_sentry_revenge", false))
					{
						new sentry=FindSentry(client);
						if(IsValidEntity(sentry) && IsBoss(GetEntPropEnt(sentry, Prop_Send, "m_hEnemy")))
						{
							SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
							TF2_AddCondition(client, TFCond_Kritzkrieged, 0.3);
						}
						else
						{
							if(GetEntProp(client, Prop_Send, "m_iRevengeCrits"))
							{
								SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);
							}
							else if(TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) && !TF2_IsPlayerInCondition(client, TFCond_Healing))
							{
								TF2_RemoveCondition(client, TFCond_Kritzkrieged);
							}
						}
					}
				}
			}

			if(addthecrit)
			{
				TF2_AddCondition(client, cond, 0.3);
				if(healer!=-1 && cond!=TFCond_Buffed)
				{
					TF2_AddCondition(client, TFCond_Buffed, 0.3);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:BackUpBuffTimer(Handle:hTimer, any:clientid)
{
	new client=GetClientOfUserId(clientid);
	TF2_RemoveCondition(client, TFCond_Buffed);
	FF2flags[client]&=~FF2FLAG_ISBUFFED;
	return Plugin_Continue;
}

stock FindSentry(client)
{
	new entity=-1;
	while((entity=FindEntityByClassname2(entity, "obj_sentrygun"))!=-1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client)
		{
			return entity;
		}
	}
	return -1;
}

public Action:BossTimer(Handle:hTimer)
{
	new bool:bIsEveryponyDead=true;
	for(new client=0; client<=MaxClients; client++)
	{
		if(!IsValidClient(Boss[client], false) || CheckRoundState()==2)
		{
			break;
		}
		else if(!IsPlayerAlive(Boss[client]) || !(FF2flags[Boss[client]] & FF2FLAG_USEBOSSTIMER))
		{
			continue;
		}

		bIsEveryponyDead=false;
		if(TF2_IsPlayerInCondition(Boss[client], TFCond_Jarated))
		{
			TF2_RemoveCondition(Boss[client], TFCond_Jarated);
		}

		if(TF2_IsPlayerInCondition(Boss[client], TFCond_MarkedForDeath))
		{
			TF2_RemoveCondition(Boss[client], TFCond_MarkedForDeath);
		}

		if(TF2_IsPlayerInCondition(Boss[client], TFCond:42) && TF2_IsPlayerInCondition(Boss[client], TFCond_Dazed))
		{
			TF2_RemoveCondition(Boss[client], TFCond_Dazed);
		}

		SetEntPropFloat(Boss[client], Prop_Data, "m_flMaxspeed", BossSpeed[Special[client]]+0.7*(100-BossHealth[client]*100/BossLivesMax[client]/BossHealthMax[client]));

		if(BossHealth[client]<=0 && IsPlayerAlive(Boss[client]))  //Wat.  TODO:  Investigate
		{
			BossHealth[client]=1;
		}
		SetBossHealthFix(Boss[client], BossHealth[client]);

		if(!(FF2flags[Boss[client]] & FF2FLAG_HUDDISABLED))
		{
			SetHudTextParams(-1.0, 0.77, 0.15, 255, 255, 255, 255);
			ShowSyncHudText(Boss[client], healthHUD, "%t", "health", BossHealth[client]-BossHealthMax[client]*(BossLives[client]-1), BossHealthMax[client]);
			if(RoundFloat(BossCharge[client][0])==100)
			{
				if(IsFakeClient(Boss[client]) && !(FF2flags[Boss[client]] & FF2FLAG_BOTRAGE))
				{
					CreateTimer(1.0, Timer_BotRage, client, TIMER_FLAG_NO_MAPCHANGE);
					FF2flags[Boss[client]]|=FF2FLAG_BOTRAGE;
				}
				else
				{
					SetHudTextParams(-1.0, 0.83, 0.15, 255, 64, 64, 255);
					ShowSyncHudText(Boss[client], rageHUD, "%t", "do_rage");
				}
			}
			else
			{
				SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255);
				ShowSyncHudText(Boss[client], rageHUD, "%t", "rage_meter", RoundFloat(BossCharge[client][0]));
			}	
		}
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);

		SetClientGlow(client, -0.2);

		decl String:lives[MAXRANDOMS][3];
		for(new i=1; ; i++)
		{		
			decl String:ability[10];
			Format(ability, 10, "ability%i", i);
			KvRewind(BossKV[Special[client]]);
			if(KvJumpToKey(BossKV[Special[client]], ability))
			{
				decl String:plugin_name[64];
				KvGetString(BossKV[Special[client]], "plugin_name", plugin_name, 64);
				new slot=KvGetNum(BossKV[Special[client]], "arg0", 0);
				new buttonmode=KvGetNum(BossKV[Special[client]], "buttonmode", 0);
				if(slot<1)
				{
					continue;
				}

				KvGetString(BossKV[Special[client]], "life", ability, 10, "");
				if(!ability[0])
				{
					decl String:ability_name[64];
					KvGetString(BossKV[Special[client]], "name", ability_name, 64);
					UseAbility(ability_name, plugin_name, client, slot, buttonmode);
				}
				else
				{
					new count=ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
					for(new n=0; n<count; n++)
					{
						if(StringToInt(lives[n])==BossLives[client])
						{
							decl String:ability_name[64];
							KvGetString(BossKV[Special[client]], "name", ability_name, 64);
							UseAbility(ability_name, plugin_name, client, slot, buttonmode);
							break;
						}
					}
				}
			}
			else
			{
				break;
			}
		}

		if(RedAlivePlayers==1)
		{
			new String:message[512];
			decl String:name[64];
			for(new boss=0; Boss[boss]; boss++)
			{
				KvRewind(BossKV[Special[boss]]);
				KvGetString(BossKV[Special[boss]], "name", name, 64, "=Failed name=");
				if(BossLives[boss]>1)
				{
					Format(message, 512, "%s\n%s's HP: %i of %ix%i", message, name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], BossLives[boss]);
				}
				else
				{
					Format(message, 512, "%s\n%s's HP: %i of %i", message, name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss]);
				}
			}

			for(new client2=1; client2<=MaxClients; client2++)
			{
				if(IsValidClient(client2) && !(FF2flags[client2] & FF2FLAG_HUDDISABLED))
				{
					SetGlobalTransTarget(client2);
					PrintCenterText(client2, message); 	
				}
			}

			if(lastPlayerGlow)
			{
				SetClientGlow(client, 3600.0);
			}
		}

		if(BossCharge[client][0]<100)
		{
			BossCharge[client][0]+=OnlyScoutsLeft()*0.2;
			if(BossCharge[client][0]>100)
			{
				BossCharge[client][0]=100.0;
			}
		}

		HPTime-=0.2;
		if(HPTime<0)
		{
			HPTime=0.0;
		}

		for(new client2=0; client2<=MaxClients; client2++)
		{
			if(KSpreeTimer[client2]>0)
			{
				KSpreeTimer[client2]-=0.2;
			}
		}
	}

	if(bIsEveryponyDead)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_BotRage(Handle:timer, any:bot)
{
	if(!IsValidClient(Boss[bot], false))
	{
		return;
	}

	if(!TF2_IsPlayerInCondition(Boss[bot], TFCond_Taunting))
	{
		FakeClientCommandEx(Boss[bot], "taunt");
	}
}

stock OnlyScoutsLeft()
{
	new scouts=0;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && GetClientTeam(client)==BossTeam)
		{
			continue;
		}

		if(IsValidClient(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client)!=TFClass_Scout)
		{
			return 0;
		}
		else if(IsValidClient(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client)==TFClass_Scout)
		{
			scouts++;
		}
	}
	return scouts;
}

public Action:Destroy(client, const String:command[], argc)
{
	if(!Enabled || IsBoss(client))
	{
		return Plugin_Continue;
	}

	if(IsValidClient(client) && TF2_GetPlayerClass(client)==TFClass_Engineer && TF2_IsPlayerInCondition(client, TFCond_Taunting) && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee)==589)  //Eureka Effect
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock GetIndexOfWeaponSlot(client, slot)
{
	new weapon=GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(TF2_GetPlayerClass(client)==TFClass_Scout && condition==TFCond_CritHype)
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
	}
}

public Action:DoTaunt(client, const String:command[], argc)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}
	else
	{
		if(CheckRoundState()==0)
		{
			return Plugin_Handled;
		}
		else
		{
			if(!IsBoss(client))
			{
				return Plugin_Continue;
			}
		}
	}

	if(!IsPlayerAlive(client) || TF2_IsPlayerInCondition(client, TFCond_Taunting))
	{
		return Plugin_Handled;
	}

	new boss=GetBossIndex(client);
	if(boss==-1 || !Boss[boss] || !IsValidEdict(Boss[boss]))
	{
		return Plugin_Continue;
	}

	if(RoundFloat(BossCharge[boss][0])==100)
	{
		decl String:ability[10];
		decl String:lives[MAXRANDOMS][3];
		for(new i=1; i<MAXRANDOMS; i++)
		{
			Format(ability, sizeof(ability), "ability%i", i);
			KvRewind(BossKV[Special[boss]]);
			if(KvJumpToKey(BossKV[Special[boss]], ability))
			{
				if(KvGetNum(BossKV[Special[boss]], "arg0", 0))
				{
					continue;
				}

				KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability));
				if(!ability[0])
				{
					decl String:abilityName[64], String:pluginName[64];
					KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
					KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
					UseAbility(abilityName, pluginName, boss, 0);
				}
				else	
				{
					new count=ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
					for(new j=0; j<count; j++)
					{
						if(StringToInt(lives[j])==BossLives[boss])
						{
							decl String:abilityName[64], String:pluginName[64];
							KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
							KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
							UseAbility(abilityName, pluginName, boss, 0);
							break;
						}
					}
				}					
			}
		}
		
		decl Float:position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

		decl String:sound[PLATFORM_MAX_PATH];
		if(RandomSoundAbility("sound_ability", sound, PLATFORM_MAX_PATH))
		{
			FF2flags[Boss[boss]]|=FF2FLAG_TALKING;
			EmitSoundToAll(sound, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, position, NULL_VECTOR, true, 0.0);
			EmitSoundToAll(sound, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, position, NULL_VECTOR, true, 0.0);
		
			for(new target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && target!=Boss[boss])
				{
					EmitSoundToClient(target, sound, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, position, NULL_VECTOR, true, 0.0);
					EmitSoundToClient(target, sound, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, position, NULL_VECTOR, true, 0.0);
				}
			}
			FF2flags[Boss[boss]]&=~FF2FLAG_TALKING;
		}
	}
	return Plugin_Continue;
}

public Action:DoSuicide(client, const String:command[], argc)
{
	if(Enabled && IsBoss(client) && CheckRoundState()<=0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:DoJoinTeam(client, const String:command[], argc)
{
	if(!Enabled)
		return Plugin_Continue;
	
	if(RoundCount==0 && GetConVarBool(cvarFirstRound))
		return Plugin_Continue;
	
	if(argc==0)
		return Plugin_Continue;
	
	decl String:teamString[10];
	GetCmdArg(1, teamString, sizeof(teamString));
	
	new team=_:TFTeam_Unassigned;
	
	if(StrEqual(teamString, "red", false))
	{
		team=_:TFTeam_Red;
	}
	else if(StrEqual(teamString, "blue", false))
	{
		team=_:TFTeam_Blue;
	}
	else if(StrEqual(teamString, "auto", false))
	{
		team=OtherTeam;
	}
	else if(StrEqual(teamString, "spectator", false))
	{
		if(GetConVarBool(cvarAllowSpectators))
			team=_:TFTeam_Spectator;
		else
			team=OtherTeam;
	}
	
	if(team==BossTeam)
		team=OtherTeam;
	
	if(team>_:TFTeam_Unassigned)
		ChangeClientTeam(client, team);

	switch(team)
	{
		case TFTeam_Red:
		{
			ShowVGUIPanel(client, "class_red");
		}
		
		case TFTeam_Blue:
		{
			ShowVGUIPanel(client, "class_blue");
		}
	}
	
	return Plugin_Handled;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(Enabled && client && GetClientHealth(client)<=0 && CheckRoundState()==1)
	{
		OnPlayerDeath(client, GetClientOfUserId(GetEventInt(event, "attacker")), (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)!=0);
	}
	return Plugin_Continue;
}

OnPlayerDeath(client, attacker, bool:fake=false)
{
	if(CheckRoundState()!=1)
	{
		return;
	}

	CreateTimer(0.1, CheckAlivePlayers);
	DoOverlay(client,"");
	decl String:sound[PLATFORM_MAX_PATH];
	if(!IsBoss(client))
	{
		if(fake)
		{
			return;
		}

		CreateTimer(1.0, Timer_Damage, GetClientUserId(client));
		if(IsBoss(attacker))
		{	
			new boss=GetBossIndex(attacker);
			if(RandomSound("sound_hit", sound, PLATFORM_MAX_PATH, boss))
			{
				EmitSoundToAll(sound);
				EmitSoundToAll(sound);
			}

			if(!GetRandomInt(0, 2))
			{
				new Handle:data;
				CreateDataTimer(0.1, PlaySoundKill, data);
				WritePackCell(data, GetClientUserId(client));
				WritePackCell(data, boss);
				ResetPack(data);
			}

			if(GetGameTime()<=KSpreeTimer[boss])
			{
				KSpreeCount[boss]++;
			}
			else
			{
				KSpreeCount[boss]=1;
			}

			if(KSpreeCount[boss]==3) 
			{
				if(RandomSound("sound_kspree", sound, PLATFORM_MAX_PATH, boss))
				{
					EmitSoundToAll(sound);
					EmitSoundToAll(sound);
				}
				KSpreeCount[boss]=0;
			}
			else
			{
				KSpreeTimer[boss]=GetGameTime()+5.0;
			}
		}
	}
	else
	{		
		new boss=GetBossIndex(client);
		if(boss==-1)
		{
			return;
		}

		BossHealth[boss]=0;
		if(RandomSound("sound_death", sound, PLATFORM_MAX_PATH, boss))
		{
			EmitSoundToAll(sound);
			EmitSoundToAll(sound);
		}

		if(BossHealth[boss]<0)
		{
			BossHealth[boss]=0;
		}
		UpdateHealthBar();

		CreateTimer(0.5, Timer_RestoreLastClass, GetClientUserId(client));
		return;
	}

	if(TF2_GetPlayerClass(client)==TFClass_Engineer && !fake)
	{
		decl String:name[PLATFORM_MAX_PATH];
		FakeClientCommand(client, "destroy 2");
		for(new entity=MaxClients+1; entity<MAXENTITIES; entity++)
		{
			if(IsValidEdict(entity))
			{
				GetEdictClassname(entity, name, sizeof(name));
				if(!StrContains(name, "obj_sentrygun") && (GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client))
				{
					SetVariantInt(GetEntPropEnt(entity, Prop_Send, "m_iMaxHealth")+1);
					AcceptEntityInput(entity, "RemoveHealth");

					new Handle:event=CreateEvent("object_removed", true);
					SetEventInt(event, "userid", GetClientUserId(client));
					SetEventInt(event, "index", entity);
					FireEvent(event);
					AcceptEntityInput(entity, "kill");
				}
			}
		}
	}	
	return;
}

public Action:Timer_RestoreLastClass(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(LastClass[client])
	{
		TF2_SetPlayerClass(client, LastClass[client]);
	}

	LastClass[client]=TFClass_Unknown;
	if(BossTeam==_:TFTeam_Red)
	{
		ChangeClientTeam(client, _:TFTeam_Blue);
	}
	else
	{
		ChangeClientTeam(client, _:TFTeam_Red);
	}
	return Plugin_Continue;
}

public Action:PlaySoundKill(Handle:hTimer,Handle:data)
{
	new client=GetClientOfUserId(ReadPackCell(data));
	if(!client)
		return Plugin_Continue;
	new String:classnames[][]={"","scout","sniper","soldier","demoman","medic","heavy","pyro","spy","engineer"};
	decl String:s[32],String:s2[PLATFORM_MAX_PATH];
	Format(s,32,"sound_kill_%s",classnames[TF2_GetPlayerClass(client)]);
	if(RandomSound(s,s2,PLATFORM_MAX_PATH,ReadPackCell(data)))
	{
		EmitSoundToAll(s2);
		EmitSoundToAll(s2);
	}
	return Plugin_Continue;
}

public Action:Timer_Damage(Handle:hTimer, any:id)
{
	new client=GetClientOfUserId(id);
	if(IsValidClient(client, false))
	{
		CPrintToChat(client,"{olive}[FF2] %t. %t{default}","damage",Damage[client],"scores",RoundFloat(Damage[client]/600.0));
	}
	return Plugin_Continue;
}

public Action:event_deflect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!Enabled || GetEventInt(event, "weaponid"))
	{
		return Plugin_Continue;
	}

	new boss=GetBossIndex(GetClientOfUserId(GetEventInt(event, "ownerid")));
	if(boss!=-1 && BossCharge[boss][0]<100)
	{
		BossCharge[boss][0]+=7;
		if(BossCharge[boss][0]>100)
		{
			BossCharge[boss][0]=100.0;
		}
	}
	return Plugin_Continue;
}

public Action:event_jarate(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client=BfReadByte(bf);
	new victim=BfReadByte(bf);
	new boss=GetBossIndex(victim);
	if(boss!=-1)
	{
		new jarate=GetPlayerWeaponSlot(client, 1);
		if(jarate!=-1 && GetEntProp(jarate, Prop_Send, "m_iItemDefinitionIndex")==58 && GetEntProp(jarate, Prop_Send, "m_iEntityLevel")!=-122 && BossCharge[boss][0]>0)  //Obviously, Jarate
		{
			BossCharge[boss][0]-=8.0;
			if(BossCharge[boss][0]<0)
			{
				BossCharge[boss][0]=0.0;
			}
		}
	}
	return Plugin_Continue;
}

public Action:CheckAlivePlayers(Handle:hTimer)
{
	if(CheckRoundState()==2)
	{
		return Plugin_Continue;
	}

	RedAlivePlayers=0;
	new BlueAlivePlayers=0;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidEdict(client) && IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(GetClientTeam(client)==OtherTeam)
			{
				RedAlivePlayers++;
			}
			if(IsBoss(client))
			{
				BlueAlivePlayers++;
			}
		}
	}

	if(RedAlivePlayers==0)
	{
		ForceTeamWin(BossTeam);
	}
	else if(RedAlivePlayers==1 && BlueAlivePlayers && Boss[0] && !DrawGameTimer)
	{
		decl String:sound[PLATFORM_MAX_PATH];
		if(RandomSound("sound_lastman", sound, PLATFORM_MAX_PATH))
		{
			EmitSoundToAll(sound);
			EmitSoundToAll(sound);
		}
	}
	else if(!PointType && RedAlivePlayers<=(AliveToEnable=GetConVarInt(cvarAliveToEnable)) && !executed)
	{
		PrintHintTextToAll("%t", "point_enable", AliveToEnable);
		if(RedAlivePlayers==AliveToEnable)
		{
			new String:sound[64];
			if(GetRandomInt(0, 1))
			{
				Format(sound, sizeof(sound), "vo/announcer_am_capenabled0%i.wav", GetRandomInt(1, 4));
				EmitSoundToAll(sound);
			}
			else
			{
				new i=GetRandomInt(1, 4);
				if(i%2==0)
				{
					i--;
				}
				Format(sound, sizeof(sound), "vo/announcer_am_capincite0%i.wav", i);
				EmitSoundToAll(sound);
			}
		}
		SetControlPoint(true);
		executed=true;
	}

	if(RedAlivePlayers<=countdownPlayers && BossHealth[0]>countdownHealth && countdownTime>1 && !executed2)
	{
		if(FindEntityByClassname2(-1, "team_control_point")!=-1)
		{
			timeleft=countdownTime;
			DrawGameTimer=CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			EmitSoundToAll("vo/announcer_ends_2min.wav");
			EmitSoundToAll("vo/announcer_ends_2min.wav");
		}
		executed2=true;
	}
	return Plugin_Continue;
}

public Action:Timer_DrawGame(Handle:timer)
{
	if(BossHealth[0]<countdownHealth || CheckRoundState()!=1)
	{
		return Plugin_Stop;
	}

	new time=timeleft;
	timeleft--;
	decl String:timedisplay[6];
	if(time/60>9)
	{
		IntToString(time/60, timedisplay, 6);
	}
	else
	{
		Format(timedisplay, 6, "0%i", time/60);
	}

	if(time%60>9)
	{
		Format(timedisplay, 6, "%s:%i", timedisplay, time%60);
	}
	else
	{
		Format(timedisplay, 6, "%s:0%i", timedisplay, time%60);
	}

	SetHudTextParams(-1.0, 0.17, 1.1, 255, 255, 255, 255);
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsClientConnected(client) && !(FF2flags[client] & FF2FLAG_HUDDISABLED))
		{
			ShowSyncHudText(client, timeleftHUD, timedisplay);
		}
	}

	switch(time)
	{
		case 60:
		{
			EmitSoundToAll("vo/announcer_ends_60sec.wav");
		}
		case 30:
		{
			EmitSoundToAll("vo/announcer_ends_30sec.wav");
		}
		case 10:
		{
			EmitSoundToAll("vo/announcer_ends_10sec.wav");
		}
		case 1-5:
		{
			decl String:sound[PLATFORM_MAX_PATH];
			Format(sound, PLATFORM_MAX_PATH, "vo/announcer_ends_%isec.wav", time);
			EmitSoundToAll(sound);
		}
		case 0:  //Thx MasterOfTheXP
		{
			for(new client=1; client<=MaxClients; client++)
			{
				if(!IsClientInGame(client) || !IsPlayerAlive(client))
				{
					continue;
				}
				ForcePlayerSuicide(client);
			}
			return Plugin_Stop; 		
		}
	}
	return Plugin_Continue;
}

public Action:event_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage=GetEventInt(event, "damageamount");
	new custom=GetEventInt(event, "custom");
	new index=GetBossIndex(client);
	if(index==-1 || !Boss[index] || !IsValidEdict(Boss[index]) || client==attacker)
		return Plugin_Continue;
		
	if(custom==TF_CUSTOM_TELEFRAG) damage=(IsPlayerAlive(attacker) ? 9001 : 1);
	if(custom==TF_CUSTOM_BOOTS_STOMP) damage*=5;
	if(GetEventBool(event, "minicrit") && GetEventBool(event, "allseecrit")) SetEventBool(event, "allseecrit", false);
	if(custom==TF_CUSTOM_BACKSTAB)
		damage=RoundFloat(BossHealthMax[index]*(LastBossIndex()+1)*BossLivesMax[index]*(0.12-Stabbed[index]/90));
	if(custom==TF_CUSTOM_TELEFRAG || custom==TF_CUSTOM_BOOTS_STOMP) SetEventInt(event, "damageamount", damage);
	
	decl i;
	for(i=1; i<BossLives[index]; i++)
	{
		//if(BossHealth[index]>=BossHealthMax[index]*i && BossHealth[index]-damage<BossHealthMax[index]*i)
		if(BossHealth[index]-damage<BossHealthMax[index]*i)
		{	
			decl String:s[PLATFORM_MAX_PATH];
			decl String:lives[MAXRANDOMS][3];
			decl count,j;
			for(new n=1; n<MAXRANDOMS; n++)
			{
				Format(s,10,"ability%i",n);
				KvRewind(BossKV[Special[index]]);
				if(KvJumpToKey(BossKV[Special[index]],s))
				{
					if(KvGetNum(BossKV[Special[index]], "arg0",0)!=-1)
						continue;
					KvGetString(BossKV[Special[index]], "life",s,10); 	
					if(!s[0])
					{
						decl String:ability_name[64], String:plugin_name[64];
						KvGetString(BossKV[Special[index]], "plugin_name",plugin_name,64);
						KvGetString(BossKV[Special[index]], "name",ability_name,64);
						UseAbility(ability_name,plugin_name,index,-1);
					}
					else		
					{
						count=ExplodeString(s, " ", lives, MAXRANDOMS, 3);
						for(j=0; j<count; j++)
							if(StringToInt(lives[j])==BossLives[index])
							{
								decl String:ability_name[64], String:plugin_name[64];
								KvGetString(BossKV[Special[index]], "plugin_name",plugin_name,64);
								KvGetString(BossKV[Special[index]], "name",ability_name,64);
								UseAbility(ability_name,plugin_name,index,-1);
								break;
							}
					}
				}
			}
				
			BossLives[index]--;
			decl String:aname[64];
			KvRewind(BossKV[Special[index]]);
			KvGetString(BossKV[Special[index]], "name", aname, 64,"=Failed name=");
			if(BossLives[index]==1)
			{
				strcopy(s,256,"ff2_life_left");
			}
			else
			{
				strcopy(s,256,"ff2_lives_left");
			}
			//Format(s,256,"%t","ff2_lives_left",aname,BossLives[index]); 	
			for(j=1;  j<=MaxClients; j++)
				if(IsValidClient(j) && !(FF2flags[j] & FF2FLAG_HUDDISABLED))
				{
					//SetGlobalTransTarget(j);
					//PrintCenterText(j,s);
					PrintCenterText(j,"%t",s,aname,BossLives[index]);
				}
			if(RandomSound("sound_nextlife",s,PLATFORM_MAX_PATH))
			{		
				EmitSoundToAll(s);
				EmitSoundToAll(s);
			}
			
			UpdateHealthBar();
		}
	}
	BossHealth[index]-=damage;
	BossCharge[index][0]+=damage*100.0/BossRageDamage[Special[index]];
	if(custom==16) SetEventInt(event, "damageamount", 9001);
	Damage[attacker]+=damage;
	new healers[MAXPLAYERS];
	new healercount=0;
	for(i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i) && (GetHealingTarget(i,true)==attacker))
		{
			healers[healercount]=i;
			healercount++;
		}
	}
	for(i=0; i<healercount; i++)
	{
		if(IsValidClient(healers[i]) && IsPlayerAlive(healers[i]))
		{
			if(damage<10 || uberTarget[healers[i]]==attacker)
				Damage[healers[i]]+=damage;
			else
				Damage[healers[i]]+=damage/(healercount+1); 	
		}
	}
	if(BossCharge[index][0]>100)
		BossCharge[index][0]=100.0;
	return Plugin_Continue;
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(!Enabled || !IsValidEdict(attacker))
		return Plugin_Continue;
		
	static bool:foundDmgCustom=false;
	static bool:dmgCustomInOTD=false;
	
	if(!foundDmgCustom)
	{
		dmgCustomInOTD=(GetFeatureStatus(FeatureType_Capability, "SDKHook_DmgCustomInOTD")==FeatureStatus_Available);
		foundDmgCustom=true;
	}
	
	if((attacker<=0 || client==attacker) && IsBoss(client))
		return Plugin_Handled;
	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
		return Plugin_Continue;
	if(CheckRoundState()==0 && IsBoss(client))
	{
		damage*=0.0;
		return Plugin_Changed;
	}

	decl Float:Pos[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", Pos);
	if(IsBoss(attacker))
	{
		if(IsValidClient(client) && !IsBoss(client) && !TF2_IsPlayerInCondition(client, TFCond_Bonked) && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
		{
			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
			{
				ScaleVector(damageForce, 9.0);
				damage*=0.3;
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))
			{
				damage*=9;
				TF2_AddCondition(client, TFCond_Bonked, 0.1);
				return Plugin_Changed;
			}

			if(demoShield[client])
			{
				TF2_RemoveWearable(client, demoShield[client]);
				EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
				EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
				EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
				EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
				TF2_AddCondition(client, TFCond_Bonked, 0.1);
				demoShield[client]=0;
				return Plugin_Continue;
			}

			switch(TF2_GetPlayerClass(client))
			{
				case TFClass_Spy:
				{
					if(GetEntProp(client, Prop_Send, "m_bFeignDeathReady") && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						if(damagetype & DMG_CRIT) damagetype&=~DMG_CRIT;
						damage=620.0;
						return Plugin_Changed;
					}
					if(TF2_IsPlayerInCondition(client, TFCond_Cloaked) && TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
					{
						if(damagetype & DMG_CRIT) damagetype&=~DMG_CRIT;
						damage=850.0;
						return Plugin_Changed;
					}
					if(GetEntProp(client, Prop_Send, "m_bFeignDeathReady") || TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
					{
						if(damagetype & DMG_CRIT) damagetype&=~DMG_CRIT;
						damage=620.0;
						return Plugin_Changed;
					}
				}
				case TFClass_Soldier:
				{
					if(IsValidEdict((weapon=GetPlayerWeaponSlot(client, 1))) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==226 && !(FF2flags[client]&FF2FLAG_ISBUFFED))
					{
						SetEntPropFloat(client, Prop_Send, "m_flRageMeter",100.0);
						FF2flags[client]|=FF2FLAG_ISBUFFED;
					}
				}
			}
			new buffweapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
			new buffindex=(IsValidEntity(buffweapon) && buffweapon>MaxClients ? GetEntProp(buffweapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if(buffindex==226)
				CreateTimer(0.25, Timer_CheckBuffRage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			if(damage<=160.0)
			{
				damage*=3;
				return Plugin_Changed;
			}
		}
	}
	else
	{
		new boss=GetBossIndex(client);
		if(boss!=-1)
		{
			if(attacker<=MaxClients)
			{
				new bool:bIsTelefrag=false;
				new bool:bIsBackstab=false;
				
				if(dmgCustomInOTD)
				{
					if(damagecustom==TF_CUSTOM_BACKSTAB)
					{
						bIsBackstab=true;
					}
					else if(damagecustom==TF_CUSTOM_TELEFRAG)
					{
						bIsTelefrag=true;
					}
				}
				else if(weapon!=4095 && IsValidEdict(weapon) && weapon==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage>1000.0)
				{
					decl String:wepclassname[32];
					if(GetEdictClassname(weapon, wepclassname, sizeof(wepclassname)) && strcmp(wepclassname, "tf_weapon_knife", false)==0)
					{
						bIsBackstab=true;
					}
				}
				else if(!IsValidEntity(weapon) && (damagetype & DMG_CRUSH)==DMG_CRUSH && damage==1000.0)
				{
					bIsTelefrag=true;
				}

				if(bIsTelefrag)
				{
					if(!IsPlayerAlive(attacker))
					{
						damage=1.0;
						return Plugin_Changed;
					}
					damage=(BossHealth[boss]>9001 ? 9001.0 : float(GetEntProp(Boss[boss], Prop_Send, "m_iHealth"))+90.0);

					new teleowner=FindTeleOwner(attacker);
					if(IsValidClient(teleowner) && teleowner!=attacker)
					{
						Damage[teleowner]+=9001*3/5;
						if(!(FF2flags[teleowner] & FF2FLAG_HUDDISABLED))
						{
							PrintCenterText(teleowner, "TELEFRAG ASSIST!  Nice job setting it up!");
						}
					}

					if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						PrintCenterText(attacker, "TELEFRAG! You are a pro!");
					}

					if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						PrintCenterText(client, "TELEFRAG! Be careful around quantum tunneling devices!");
					}
					return Plugin_Changed;
				}

				new wepindex=(IsValidEntity(weapon) && weapon>MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
				switch(wepindex)
				{
					case 593:	//Third Degree
					{
						new healers[MAXPLAYERS];
						new healercount=0;
						for(new healer=1; healer<=MaxClients; healer++)
						{
							if(IsValidClient(healer) && IsPlayerAlive(healer) && (GetHealingTarget(healer, true)==attacker))
							{
								healers[healercount]=healer;
								healercount++;
							}
						}

						for(new healer=0; healer<healercount; healer++)
						{
							if(IsValidClient(healers[healer]) && IsPlayerAlive(healers[healer]))
							{
								new medigun=GetPlayerWeaponSlot(healers[healer], TFWeaponSlot_Secondary);
								if(IsValidEntity(medigun))
								{
									new String:classname[64];
									GetEdictClassname(medigun, classname, sizeof(classname));
									if(strcmp(classname, "tf_weapon_medigun", false)==0)
									{
										new Float:uber=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+(0.1/healercount);
										new Float:max=1.0;
										if(GetEntProp(medigun, Prop_Send, "m_bChargeRelease"))
										{
											max=1.5;
										}

										if(uber>max)
										{
											uber=max;
										}
										SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
									}
								}
							}
						}
					}
					case 14, 201, 230, 402, 526, 664, 752, 792, 801, 851, 881, 890, 899, 908, 957, 966:
					{
						switch(wepindex)
						{
							case 14, 201, 664, 792, 801, 851, 881, 890, 899, 908, 957, 966:
							{
								if(CheckRoundState()!=2)
								{
									new Float:chargelevel=(IsValidEntity(weapon) && weapon>MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
									new Float:time=(GlowTimer[boss]>10 ? 1.0 : 2.0);
									time+=(GlowTimer[boss]>10 ? (GlowTimer[boss]>20 ? 1.0 : 2.0) : 4.0)*(chargelevel/100.0);
									SetClientGlow(boss, time);
									if(GlowTimer[boss]>30.0)
									{
										GlowTimer[boss]=30.0;
									}
								}
							}
						}

						if(wepindex==752 && CheckRoundState()!=2)  //Hitman's Heatmaker
						{
							new Float:chargelevel=(IsValidEntity(weapon) && weapon>MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
							new Float:add=10+(chargelevel/10);
							if(TF2_IsPlayerInCondition(attacker, TFCond:46))
							{
								add/=3;
							}
							new Float:rage=GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
							SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage+add>100) ? 100.0 : rage+add);
						}

						if(!(damagetype & DMG_CRIT))
						{
							if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed) || TF2_IsPlayerInCondition(attacker, TFCond_CritHype))
							{
								damage*=1.7;
							}
							else
							{
								if(wepindex!=230 || BossCharge[boss][0]>90)  //Sydney Sleeper
								{
									damage*=2.9;
								}
								else
								{
									damage*=2.4;
								}
							}
							return Plugin_Changed;
						}
					}
					case 355:  //Fan O' War
					{
						if(BossCharge[boss][0]>0)
						{
							BossCharge[boss][0]-=5.0;
							if(BossCharge[boss][0]<0)
							{
								BossCharge[boss][0]=0.0;
							}
						}
					}
					case 132, 266, 482, 1082:  //Eyelander, HHHH, Nessie's Nine Iron, Festive Eyelander
					{
						IncrementHeadCount(attacker);
					}
					case 214:  //Powerjack
					{
						new health=GetClientHealth(attacker);
						new max=GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						new newhealth=health+50;
						if(health<max+100)
						{
							if(newhealth>max+100)
							{
								newhealth=max+100;
							}
							SetEntProp(attacker, Prop_Data, "m_iHealth", newhealth);
							SetEntProp(attacker, Prop_Send, "m_iHealth", newhealth);
						}

						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
					}
					case 317:  //Candycane
					{
						SpawnSmallHealthPackAt(client, GetClientTeam(attacker));
					}
					case 357:  //Half-Zatoichi
					{
						SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
						if(GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy")<1)
						{
							SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
						}

						new health=GetClientHealth(attacker);
						new max=GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						new newhealth=health+50;
						if(health<max+100)
						{
							if(newhealth>max+100)
							{
								newhealth=max+100;
							}
							SetEntProp(attacker, Prop_Data, "m_iHealth", newhealth);
							SetEntProp(attacker, Prop_Send, "m_iHealth", newhealth);
						}
						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
					}
					case 528:  //Short Circuit
					{
						if(circuitStun>0.0)
						{
							TF2_StunPlayer(client, circuitStun, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
							EmitSoundToAll("weapons/barret_arm_zap.wav", client);
							EmitSoundToClient(client, "weapons/barret_arm_zap.wav");
						}
					}
					case 656:  //Holiday Punch
					{
						CreateTimer(0.1, Timer_StopTickle, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						if(TF2_IsPlayerInCondition(attacker, TFCond_Dazed))
						{
							TF2_RemoveCondition(attacker, TFCond_Dazed);
						}
					}
				}

				if(bIsBackstab)
				{
					new Float:changedamage=BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.12-Stabbed[boss]/90);
					new iChangeDamage=RoundFloat(changedamage);
					Damage[attacker]+=iChangeDamage;
					if(BossHealth[boss]>iChangeDamage)
					{
						damage=0.0;
					}
					else
					{
						damage=changedamage;
					}

					BossHealth[boss]-=iChangeDamage;
					BossCharge[boss][0]+=changedamage*100/BossRageDamage[Special[boss]];
					if(BossCharge[boss][0]>100.0)
					{
						BossCharge[boss][0]=100.0;
					}

					EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(client, "player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);
					new viewmodel=GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
					if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
					{
						new melee=GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
						new animation=15;
						switch(melee)
						{
							case 727:  //Black Rose
							{
								animation=41;
							}
							case 4, 194, 665, 794, 803, 883, 892, 901, 910:  //Knife, Strange Knife, Festive Knife, Botkiller Knifes
							{
								animation=10;
							}
							case 638:  //Sharp Dresser
							{
								animation=31;
							}
						}
						SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
					}

					if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						PrintCenterText(attacker, "You backstabbed the boss!");
					}

					if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						PrintCenterText(client, "You were just backstabbed!");
					}

					new Handle:stabevent=CreateEvent("player_hurt", true);
					SetEventInt(stabevent, "userid", GetClientUserId(client));
					SetEventInt(stabevent, "health", BossHealth[boss]);
					SetEventInt(stabevent, "attacker", GetClientUserId(attacker));
					SetEventInt(stabevent, "damageamount", iChangeDamage);
					SetEventInt(stabevent, "custom", TF_CUSTOM_BACKSTAB);
					SetEventBool(stabevent, "crit", true);
					SetEventBool(stabevent, "minicrit", false);
					SetEventBool(stabevent, "allseecrit", true);
					SetEventInt(stabevent, "weaponid", TF_WEAPON_KNIFE);
					FireEvent(stabevent);
					if(wepindex==225 || wepindex==574)  //Your Eternal Reward, Wanga Prick
					{
						CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker));
					}
					else if(wepindex==356)  //Conniver's Kunai
					{
						new health=GetClientHealth(attacker)+200;
						if(health>500)
						{
							health=500;
						}
						SetEntProp(attacker, Prop_Data, "m_iHealth", health);
						SetEntProp(attacker, Prop_Send, "m_iHealth", health);
					}

					decl String:sound[PLATFORM_MAX_PATH];
					if(RandomSound("sound_stabbed", sound, PLATFORM_MAX_PATH, boss))
					{
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss[boss], _, NULL_VECTOR, false, 0.0);
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss[boss], _, NULL_VECTOR, false, 0.0);
					}

					if(Stabbed[boss]<3)
					{
						Stabbed[boss]++;
					}

					new healers[MAXPLAYERS];
					new healercount=0;
					for(new healer=1; healer<=MaxClients; healer++)
					{
						if(IsValidClient(healer) && IsPlayerAlive(healer) && (GetHealingTarget(healer, true)==attacker))
						{
							healers[healercount]=healer;
							healercount++;
						}
					}

					for(new healer=0; healer<healercount; healer++)
					{
						if(IsValidClient(healers[healer]) && IsPlayerAlive(healers[healer]))
						{
							if(uberTarget[healers[healer]]==attacker)
							{
								Damage[healers[healer]]+=iChangeDamage;
							}
							else
							{
								Damage[healers[healer]]+=RoundFloat(changedamage/(healercount+1));
							}
						}
					}
					return Plugin_Changed;
				}
			}
			else
			{
				decl String:classname[64];
				if(GetEdictClassname(attacker, classname, sizeof(classname)) && strcmp(classname, "trigger_hurt", false)==0)
				{
					new Action:act=Plugin_Continue;
					Call_StartForward(OnTriggerHurt);
					Call_PushCell(boss);
					Call_PushCell(attacker);
					new Float:damage2=damage;
					Call_PushFloatRef(damage2);
					Call_Finish(act);
					if(act!=Plugin_Stop && act!=Plugin_Handled)
					{
						if(act==Plugin_Changed)
						{
							damage=damage2;
						}

						if(damage>1500.0)
						{
							damage=1500.0;
						}

						if(strcmp(currentmap, "arena_arakawa_b3", false)==0 && damage>1000.0)
						{
							damage=490.0;
						}
						BossHealth[boss]-=RoundFloat(damage);
						BossCharge[boss][0]+=damage*100/BossRageDamage[Special[boss]];
						if(BossHealth[boss]<=0)
						{
							damage*=5;
						}

						if(BossCharge[boss][0]>100)
						{
							BossCharge[boss][0]=100.0;
						}
						return Plugin_Changed;
					}
					else
					{
						return act;
					}
				}
			}
		}
		else  //Wat.  TODO:  LOOK AT THIS
		{
			if(IsValidClient(client, false) && TF2_GetPlayerClass(client)==TFClass_Soldier)
			{
				if(damagetype & DMG_FALL)
				{
					new secondary=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(secondary<=0 || !IsValidEntity(secondary))
					{
						damage/=10.0;
						return Plugin_Changed;
					}
				}/*
				else if(IsValidEdict((weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==226)
				{					
					new Float:charge=GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
					if(charge>20)
						SetEntPropFloat(client, Prop_Send, "m_flRageMeter",charge-20.0);
					else
						SetEntPropFloat(client, Prop_Send, "m_flRageMeter",0.0);
				}*/
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower)
{
	Debug("Stomp happening!");
	if(!Enabled || !IsValidClient(attacker) || !IsValidClient(victim) || attacker==victim)
	{
		return Plugin_Continue;
	}

	if(IsBoss(attacker))
	{
		decl Float:Pos[3];
		GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", Pos);
		Debug("Boss is stomping");
		damageMultiplier=900.0;
		JumpPower=0.0;
		PrintCenterText(victim, "Ouch!  Watch your head!");
		PrintCenterText(attacker, "You just goomba stomped somebody!");
		return Plugin_Changed;
	}
	else if(IsBoss(victim))
	{
		Debug("Boss is being stomped");
		damageMultiplier=GoombaDamage;
		JumpPower=5000.0;
		PrintCenterText(victim, "You were just goomba stomped!");
		PrintCenterText(attacker, "You just goomba stomped the boss!");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

SetupRTD()
{
	cvarDisabledRTDPerks=FindConVar("sm_rtd_disabled");
	cvarRTDMode=FindConVar("sm_rtd_mode");
	cvarRTDTimeLimit=FindConVar("sm_rtd_timelimit");
	if(cvarDisabledRTDPerks!=INVALID_HANDLE)
	{
		SetConVarString(cvarDisabledRTDPerks, DISABLED_PERKS);
		HookConVarChange(cvarDisabledRTDPerks, CvarChange);
	}

	if(cvarRTDMode!=INVALID_HANDLE)
	{
		SetConVarInt(cvarRTDMode, 0);
		HookConVarChange(cvarRTDMode, CvarChange);
	}

	if(cvarRTDTimeLimit!=INVALID_HANDLE)
	{
		SetConVarInt(cvarRTDTimeLimit, 30);
		HookConVarChange(cvarRTDTimeLimit, CvarChange);
	}
}

public Action:RTD_CanRollDice(client)
{
	new Handle:message=CreateHudSynchronizer();
	if(IsBoss(client) && Enabled)
	{
		if(!canBossRTD)
		{
			SetHudTextParams(-1.0, 0.5, 6.0, 255, 0, 0, 255, 2);
			ShowSyncHudText(client, message, "You cannot roll the die as a boss!");
			CloseHandle(message);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:Timer_CheckBuffRage(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
	}
}

stock GetClientCloakIndex(client)
{
	if(!IsValidClient(client, false))
	{
		return -1;
	}

	new wep=GetPlayerWeaponSlot(client, 4);
	if(!IsValidEntity(wep))
	{
		return -1;
	}

	new String:classname[64];
	GetEntityClassname(wep, classname, sizeof(classname));
	if(strncmp(classname, "tf_wea", 6, false)!=0)
	{
		return -1;
	}
	return GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex");
}
stock SpawnSmallHealthPackAt(client, ownerteam=0)
{
	if(!IsValidClient(client, false) || !IsPlayerAlive(client))
	{
		return;
	}
	new healthpack=CreateEntityByName("item_healthkit_small");
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2]+=20.0;
	if(IsValidEntity(healthpack))
	{
		DispatchKeyValue(healthpack, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(healthpack);
		SetEntProp(healthpack, Prop_Send, "m_iTeamNum", ownerteam, 4);
		SetEntityMoveType(healthpack, MOVETYPE_VPHYSICS);
		new Float:vel[3];//={float(GetRandomInt(-10, 10)), float(GetRandomInt(-10, 10)), 50.0};  //Q_Q
		vel[0]=float(GetRandomInt(-10, 10)), vel[1]=float(GetRandomInt(-10, 10)), vel[2]=50.0;  //I did this because setting it on the creation of the vel variable was creating a compiler error for me.
		TeleportEntity(healthpack, pos, NULL_VECTOR, vel);
	}
}

public Action:Timer_StopTickle(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}

	if(!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner")))
	{
		TF2_RemoveCondition(client, TFCond_Taunting);
	}
}

stock IncrementHeadCount(client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
	{
		TF2_AddCondition(client, TFCond_DemoBuff, -1.0);
	}
	new decapitations=GetEntProp(client, Prop_Send, "m_iDecapitations");
	SetEntProp(client, Prop_Send, "m_iDecapitations", decapitations+1);
	new health=GetClientHealth(client);
	SetEntProp(client, Prop_Data, "m_iHealth", health+15);
	SetEntProp(client, Prop_Send, "m_iHealth", health+15);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}

stock SwitchToOtherWeapon(client)
{
	new ammo=GetAmmo(client, 0);
	new weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	new clip=(IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iClip1") : -1);
	if(!(ammo==0 && clip<=0))
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary));
	}
}

stock FindTeleOwner(client)
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return -1;
	}

	new teleporter=GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	decl String:classname[32];
	if(IsValidEntity(teleporter) && GetEdictClassname(teleporter, classname, sizeof(classname)) && strcmp(classname, "obj_teleporter", false)==0)
	{
		new owner=GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
		if(IsValidClient(owner, false))
		{
			return owner;
		}
	}
	return -1;
}

stock TF2_IsPlayerCritBuffed(client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond:34) || TF2_IsPlayerInCondition(client, TFCond:35) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph));
}

public Action:Timer_DisguiseBackstab(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(IsValidClient(client, false))
	{
		RandomlyDisguise(client);
	}
	return Plugin_Continue;
}

stock RandomlyDisguise(client)	//Original code was mecha's, but the original code is broken and this uses a better method now.
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		new disguiseTarget=-1;
		new team=GetClientTeam(client);

		new Handle:disguiseArray=CreateArray();
		for(new clientcheck=0; clientcheck<=MaxClients; clientcheck++)
		{
			if(IsValidClient(clientcheck) && GetClientTeam(clientcheck)==team && clientcheck!=client)
			{
				PushArrayCell(disguiseArray, clientcheck);
			}
		}

		if(GetArraySize(disguiseArray)<=0)
		{
			disguiseTarget=client;
		}
		else
		{
			disguiseTarget=GetArrayCell(disguiseArray, GetRandomInt(0, GetArraySize(disguiseArray)-1));
			if(!IsValidClient(disguiseTarget))
			{
				disguiseTarget=client;
			}
		}

		new class=GetRandomInt(0, 4);
		new TFClassType:classArray[]={TFClass_Scout, TFClass_Pyro, TFClass_Medic, TFClass_Engineer, TFClass_Sniper};
		CloseHandle(disguiseArray);

		if(TF2_GetPlayerClass(client)==TFClass_Spy)
		{
			TF2_DisguisePlayer(client, TFTeam:team, classArray[class], disguiseTarget);
		}
		else
		{
			TF2_AddCondition(client, TFCond_Disguised, -1.0);
			SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
			SetEntProp(client, Prop_Send, "m_nDisguiseClass", classArray[class]);
			SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", disguiseTarget);
			SetEntProp(client, Prop_Send, "m_iDisguiseHealth", 200);
		}
	}
}

/*public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(!Enabled || !IsValidClient(client, false))
	{
		return Plugin_Continue;
	}

	if(IsBoss(client))
	{
		if(CheckRoundState()!=-1)
		{
			return Plugin_Continue;
		}

		if(TF2_IsPlayerCritBuffed(client))
		{
			return Plugin_Continue;
		}

		if(!BossCrits)
		{
			result=false;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}*/

stock FindBosses(bool:array[])
{
	new tBoss; 	
	for(new i=1; i<=MaxClients; i++)
	{
		if(SpecForceBoss)
		{
			if(IsValidEdict(i) && IsClientConnected(i) &&
				GetClientQueuePoints(i)>=GetClientQueuePoints(tBoss) && !array[i])
					tBoss=i;
		}
		else
		{
			if(IsValidEdict(i) && IsClientConnected(i) && GetClientTeam(i)>_:TFTeam_Spectator &&
				GetClientQueuePoints(i)>=GetClientQueuePoints(tBoss) && !array[i])
					tBoss=i;
		}
	}
	return tBoss;
}

stock LastBossIndex()
{
	for(new i=1; i<=MaxClients; i++)
		if(!Boss[i])
			return i-1;
	return 0;
}

stock GetBossIndex(client)
{
	for(new i=0; i<=MaxClients; i++)
		if(Boss[i]==client)
			return i; 	
	return -1;
}

stock CalcBossHealthMax(index)
{
	decl String:formula[128];
	new String:s[128];
	new String:s2[2];
	
	new brackets;
	new Float:summ[32];
	new _operator[32];
		
	KvRewind(BossKV[Special[index]]);
	KvGetString(BossKV[Special[index]], "health_formula",formula, 128,"((760+n)*n)^1.04");
	ReplaceString(formula,128," ","");
	new len=strlen(formula);
	for(new i=0; i<=len; i++)
	{			
		strcopy(s2,2,formula[i]);
		if((s2[0]>='0' && s2[0]<='9') || s2[0]=='.')
		{
			StrCat(s,128,s2);
			continue;
		}
		if(s2[0]=='(')
		{
			brackets++;
			summ[brackets]=0.0;
			_operator[brackets]=0;
		}
		else 
		{
			if(s[0]!=0)
			{
				switch(_operator[brackets])
				{
					case 0,1:
						summ[brackets]+=StringToFloat(s);
					case 2:
						summ[brackets]-=StringToFloat(s);
					case 3:
						summ[brackets]*=StringToFloat(s);
					case 4:
					{
						new Float:see=StringToFloat(s);
						if(FloatAbs(see-0.0)<0.01) {brackets=1; break; }
						summ[brackets]/= see;
					}
					case 5:
						summ[brackets]=Pow(summ[brackets],StringToFloat(s));
				}
				_operator[brackets]=0;
			}
			if(s2[0]==')')
			{
				brackets--;
				switch(_operator[brackets])
				{
					case 2:
					{
						summ[brackets]-=summ[brackets+1];
					}
					case 3:
						summ[brackets]*=summ[brackets+1];
					case 4:
					{
						if(FloatAbs(summ[brackets+1]-0.0)<0.01) {brackets=1; break; }
						summ[brackets]/= summ[brackets+1];
					}
					case 5:
						summ[brackets]=Pow(summ[brackets],summ[brackets+1]);
					default:
						summ[brackets]+=summ[brackets+1];
				}
				_operator[brackets]=0;
			}
		}
		strcopy(s,128,"");
		switch(s2[0])
		{
			case '+':
				_operator[brackets]=1;
			case '-':
				_operator[brackets]=2;
			case '*':
				_operator[brackets]=3;
			case '/','\\':
				_operator[brackets]=4;
			case '^':
				_operator[brackets]=5;
			case 'n','x':
			{
				switch(_operator[brackets])
				{
					case 1:
						summ[brackets]+=playing;
					case 2:
						summ[brackets]-=playing;
					case 4:					
						summ[brackets]/= playing;
					case 5:
						summ[brackets]=Pow(summ[brackets],Float:playing);
					default:
						summ[brackets]*=playing;
				}
				_operator[brackets]=0;
			}
		}
	}
	decl health;
	if(brackets)
	{
		LogError("[FF2] Wrong Boss' health formula! Using default!");
		health=RoundFloat(Pow(((760.0+playing)*(playing-1)),1.04));
	}
	else health=RoundFloat(summ[0]);
	if(bMedieval) health=RoundFloat(health/3.6);
	return health;
}

stock bool:HasAbility(index,const String:plugin_name[],const String:ability_name[])
{
	if(!Enabled)
		return false;
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return false;
	KvRewind(BossKV[Special[index]]);
	if(!BossKV[Special[index]])
	{
		LogError("failed KV: %i %i",index,Special[index]);
		return false;
	}
	decl String:s[12];
	for(new i=1; i<MAXRANDOMS; i++)
	{
		Format(s,12,"ability%i",i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if(!strcmp(ability_name,ability_name2))
			{
				decl String:plugin_name2[64];
				KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
				if(!plugin_name[0] || !plugin_name2[0] || !strcmp(plugin_name,plugin_name2))
					return true;
			}
			KvGoBack(BossKV[Special[index]]);
		}
	}
	return false;
}

stock GetAbilityArgument(index,const String:plugin_name[],const String:ability_name[],arg,defvalue=0)
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return 0;
	KvRewind(BossKV[Special[index]]);
	decl String:s[10];
	for(new i=1; i<MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if(strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			decl String:plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s,10,"arg%i",arg);
			return KvGetNum(BossKV[Special[index]], s,defvalue);
		}
	}
	return 0;
}

stock Float:GetAbilityArgumentFloat(index,const String:plugin_name[],const String:ability_name[],arg,Float:defvalue=0.0)
{	
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return 0.0;
	KvRewind(BossKV[Special[index]]);
	decl String:s[10];
	for(new i=1; i<MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if(strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			decl String:plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s,10,"arg%i",arg);
			new Float:see=KvGetFloat(BossKV[Special[index]], s,defvalue);
			return see;
		}
	}
	return 0.0;
}

stock GetAbilityArgumentString(index,const String:plugin_name[],const String:ability_name[],arg,String:buffer[],buflen,const String:defvalue[]="")
{	
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
	{
		strcopy(buffer,buflen,"");
		return;
	}
	KvRewind(BossKV[Special[index]]);
	decl String:s[10];
	for(new i=1; i<MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if(strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			decl String:plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s,10,"arg%i",arg);
			KvGetString(BossKV[Special[index]], s,buffer,buflen,defvalue);
		}
	}
}

stock bool:RandomSound(const String: keyvalue[], String: str[],length,index=0)
{
	strcopy(str,1,"");
	if(index<0 || Special[index]<0 || !BossKV[Special[index]])
		return false;
	KvRewind(BossKV[Special[index]]);
	if(!KvJumpToKey(BossKV[Special[index]],keyvalue))
	{
		KvRewind(BossKV[Special[index]]);
		return false;
	}
	decl String:s[4];
	new i=1;
	for(;;)
	{
		IntToString(i,s,4);
		KvGetString(BossKV[Special[index]], s, str, length);
		if(!str[0])
			break;
		i++;
	}
	if(i==1)
		return false;
	IntToString(GetRandomInt(1,i-1),s,4);
	KvGetString(BossKV[Special[index]], s, str, length);
	return true;
}

stock bool:RandomSoundAbility(const String: keyvalue[], String: str[],length,index=0,slot=0)
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return false;
	KvRewind(BossKV[Special[index]]);
	if(!KvJumpToKey(BossKV[Special[index]],keyvalue))
		return false;
	decl String:s[10];
	new i=1,j=1,see[MAXRANDOMS];
	for(;;)
	{
		IntToString(i,s,4);
		KvGetString(BossKV[Special[index]], s, str, length);
		if(!str[0])
			break;
		Format(s,10,"slot%i",i);
		if(KvGetNum(BossKV[Special[index]],s,0)==slot)
		{
			see[j]=i;
			j++;
		}
		i++;
	}
	if(j==1)
		return false;
	IntToString(see[GetRandomInt(1,j-1)],s,4);
	KvGetString(BossKV[Special[index]], s, str, length);
	return true;
}

ForceTeamWin(team)
{
	new ent=FindEntityByClassname2(-1, "team_control_point_master");
	if(ent==-1)
	{
		ent=CreateEntityByName("team_control_point_master");
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(ent, "SetWinner");
}

public bool:PickSpecial(index, index2)
{
	if(index==index2)
	{
		Special[index]=Incoming[index];
		Incoming[index]=-1;
		if(Special[index]!=-1)
		{
			PrecacheCharacter(Special[index]);
			return true;
		}

		new chances[MAXSPECIALS];
		new chances_index;
		new String:s_chances[MAXSPECIALS*2][8];
		if(ChancesString[0])
		{
			ExplodeString(ChancesString, ";", s_chances, MAXSPECIALS*2, 8);
			chances[0]=StringToInt(s_chances[1]);
			for(chances_index=3; s_chances[chances_index][0]; chances_index+=2)
			{
				chances[chances_index/2]=StringToInt(s_chances[chances_index])+chances[chances_index/2-1];
			}
			chances_index-=2;
		}

		new pingas;
		do
		{
			if(ChancesString[0])
			{
				new random_num=GetRandomInt(0, chances[chances_index/2]);
				decl see;
				for(see=0; random_num>chances[see]; see++)
				{
				}

				decl String:name1[64];
				Special[index]=StringToInt(s_chances[see*2])-1;
				KvRewind(BossKV[Special[index]]);
				KvGetString(BossKV[Special[index]], "name", name1, 64, "=Failed name=");
			}
			else
			{
				Special[index]=GetRandomInt(0, Specials-1);
				KvRewind(BossKV[Special[index]]);
			}
			pingas++;
		}
		while(pingas<100 && KvGetNum(BossKV[Special[index]], "blocked", 0));

		if(pingas==100)
		{
			Special[index]=0;
		}
	}
	else
	{	
		decl String:s2[64];
		decl String:s1[64];
		KvRewind(BossKV[Special[index2]]);
		KvGetString(BossKV[Special[index2]], "companion", s2, 64, "=Failed name2=");
		decl i;
		for(i=0; i<Specials; i++)
		{
			KvRewind(BossKV[i]);
			KvGetString(BossKV[i], "name", s1, 64, "=Failed name1=");
			if(!strcmp(s1,s2,false))
			{
				Special[index]=i;
				break;
			}
			KvGetString(BossKV[i], "filename", s1, 64, "=Failed name1=");
			if(!strcmp(s1, s2, false))
			{
				Special[index]=i;
				break;
			}
		}

		if(i==Specials)
		{
			return false;
		}
	}
	new Action:act=Plugin_Continue;
	Call_StartForward(OnSpecialSelected);
	Call_PushCell(index);
	new SpecialNum=Special[index];
	Call_PushCellRef(SpecialNum);
	decl String:s[64];
	KvRewind(BossKV[Special[index]]);
	KvGetString(BossKV[Special[index]], "name", s, 64);
	Call_PushStringEx(s, 64, 0, SM_PARAM_COPYBACK);
	Call_Finish(act);
	if(act==Plugin_Changed)
	{
		if(s[0])
		{
			decl String:s2[64];
			for(new j=0; BossKV[j] && j<MAXSPECIALS; j++)
			{
				KvRewind(BossKV[j]);
				KvGetString(BossKV[j], "name", s2, 64);
				if(!strcmp(s,s2))
				{
					Special[index]=j; 	
					PrecacheCharacter(Special[index]);
					return true;
				}
			}
		}		
		Special[index]=SpecialNum;
		PrecacheCharacter(Special[index]);
		return true;
	}
	PrecacheCharacter(Special[index]);
	return true;
}

stock SpawnWeapon(client, String:name[], index, level, qual, String:att[])
{
	new Handle:hWeapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon==INVALID_HANDLE)
	{
		return -1;
	}

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count=ExplodeString(att, ";", atts, 32, 32);

	if(count%2!=0)
	{
		--count;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2=0;
		for(new i=0;  i<count;  i+=2)
		{
			new attrib=StringToInt(atts[i]);
			if(attrib==0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				CloseHandle(hWeapon);
				return -1;
			}
			
			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	new entity=TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

public HintPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(!IsValidClient(param1)) return;
	if(action==MenuAction_Select || (action==MenuAction_Cancel && param2==MenuCancel_Exit)) FF2flags[param1]|=FF2FLAG_CLASSHELPED;
	
	return;
}

public QueuePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(action==MenuAction_Select && param2==10)
		TurnToZeroPanel(param1,param1);
	return false;  
}


public Action:QueuePanelCmd(client, Args)
{
	if(!Enabled2)
		return Plugin_Continue;
	new Handle:panel=CreatePanel();
	SetGlobalTransTarget(client);
	decl String:s[512];
	Format(s,512,"%t","thequeue"); 	
	new i,tBoss,bool:added[MAXPLAYERS+1];
	decl j;
	SetPanelTitle(panel, s); 	
	for(j=0; j<=MaxClients; j++)
		if((tBoss=Boss[i]) && IsValidEdict(tBoss) && IsClientInGame(tBoss))
		{
			added[tBoss]=true;
			Format(s,64,"%N-%i",tBoss,GetClientQueuePoints(tBoss));
			DrawPanelItem(panel,s);
			i++;
		}
	DrawPanelText(panel,"---");
	new pingas;
	do
	{
		tBoss=FindBosses(added); 	
		if(tBoss && IsValidEdict(tBoss) && IsClientInGame(tBoss))
		{		
			if(client==tBoss)
			{
				Format(s,64,"%N-%i",tBoss,GetClientQueuePoints(tBoss));
				DrawPanelText(panel,s);
				i--;
			}
			else
			{
				Format(s,64,"%N-%i",tBoss,GetClientQueuePoints(tBoss));
				DrawPanelItem(panel,s);
			}
			added[tBoss]=true;
			i++;
		}
		pingas++;
	}
	while(i<9 && pingas<100);
	for(; i<9; i++)
		DrawPanelItem(panel,"");
	Format(s,64,"%t (%t)","your_points",GetClientQueuePoints(client),"to0");
	DrawPanelItem(panel,s);
	SendPanelToClient(panel, client, QueuePanelH, 9001);
	CloseHandle(panel);
	return Plugin_Handled;
}

public Action:ResetQueuePointsCmd(client, args)
{
	if(!Enabled2)
		return Plugin_Continue;
	if(client && !args)			//default players
	{
		TurnToZeroPanel(client,client);
		return Plugin_Handled;
	}
	if(!client)		//No confirmation for console
	{
		TurnToZeroPanelH(INVALID_HANDLE, MenuAction_Select, client, 1);
		return Plugin_Handled;
	}
	new AdminId:admin=GetUserAdmin(client);	//default players again
	if((admin==INVALID_ADMIN_ID) || !GetAdminFlag(admin, Admin_Cheats))
	{
		TurnToZeroPanel(client,client);
		return Plugin_Handled;
	}	
	//admins
	if(args!=1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_resetqueuepoints <target>");
		return Plugin_Handled;
	}

	decl String:targetname[MAX_TARGET_LENGTH];
	GetCmdArg(1, targetname, MAX_TARGET_LENGTH);
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[1], target_count;
	new bool:tn_is_ml;

	if((target_count=ProcessTargetString(
			targetname,
			client,
			target_list,
			1,
			0,
			target_name,
			MAX_TARGET_LENGTH,
			tn_is_ml))<=0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	TurnToZeroPanel(client,target_list[0]);
	return Plugin_Handled;
}

public TurnToZeroPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(action==MenuAction_Select && param2==1)
	{
		if(shortname[param1]==param1)
			CPrintToChat(param1,"{olive}[FF2]{default} %t","to0_done");
		else
		{
			CPrintToChat(param1,"{olive}[FF2]{default} %t","to0_done_admin",shortname[param1]);
			CPrintToChat(shortname[param1],"{olive}[FF2]{default} %t","to0_done_by_admin",param1);
		}
		SetClientQueuePoints(shortname[param1],0);
	}
}

public Action:TurnToZeroPanel(caller,client)
{
	if(!Enabled2)
		return Plugin_Continue;
	new Handle:panel=CreatePanel();
	decl String:s[512];
	SetGlobalTransTarget(caller);
	if(caller==client)
		Format(s,512,"%t","to0_title");
	else
		Format(s,512,"%t","to0_title_admin",client);
	PrintToChat(caller,s);
	SetPanelTitle(panel,s);
	Format(s,512,"%t","Yes");
	DrawPanelItem(panel,s);
	Format(s,512,"%t","No");
	DrawPanelItem(panel,s);
	shortname[caller]=client;
	SendPanelToClient(panel, caller, TurnToZeroPanelH, 9001);
	CloseHandle(panel);
	return Plugin_Handled;
}

bool:GetClientClassinfoCookie(client)
{
	if(!IsValidClient(client)) return false;
	if(IsFakeClient(client)) return false;
	if(!AreClientCookiesCached(client)) return true;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s,24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	return StringToInt(ff2cookies_values[3])==1;
}

GetClientQueuePoints(client)
{
	if(!IsValidClient(client)) return 0;
	if(IsFakeClient(client))
		return botqueuepoints;
	if(!AreClientCookiesCached(client)) return 0;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s,24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	return StringToInt(ff2cookies_values[0]);
}

SetClientQueuePoints(client, points)
{
	if(!IsValidClient(client)) return;
	if(IsFakeClient(client)) return;
	if(!AreClientCookiesCached(client)) return;
	decl String:s[24];
	decl String:ff2cookies_values[8][5];
	GetClientCookie(client, FF2Cookies, s,24);
	ExplodeString(s, " ", ff2cookies_values,8,5);
	Format(s,24,"%i %s %s %s %s %s %s",points,ff2cookies_values[1],ff2cookies_values[2],ff2cookies_values[3],ff2cookies_values[4],ff2cookies_values[5],ff2cookies_values[6],ff2cookies_values[7]);
	SetClientCookie(client, FF2Cookies, s);
}

stock IsBoss(client)
{
	if(client<=0)
	{
		return 0;
	}

	for(new boss=0; boss<=MaxClients; boss++)
	{
		if(Boss[boss]==client)
		{
			return 1;
		}
	}
	return 0;
}

DoOverlay(client, const String:overlay[])
{	
	new iFlags=GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", iFlags & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", iFlags);
}

public FF2PanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(action==MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
				Command_GetHP(param1);
			case 2:
				HelpPanel2(param1);
			case 3:
				NewPanel(param1, maxVersion);
			case 4:
				QueuePanelCmd(param1,0);
			case 5:
				MusicTogglePanel(param1);
			case 6:
				VoiceTogglePanel(param1);
			case 7:
				HelpPanel3(param1);
			default: return;
		} 
	}
}
  
public Action:FF2Panel(client, args)
{
	if(!Enabled2 || !IsValidClient(client, false))
		return Plugin_Continue;
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 0.8);
	new Handle:panel=CreatePanel();
	decl String:s[256];
	SetGlobalTransTarget(client);
	Format(s,256,"%t","menu_1");
	SetPanelTitle(panel, s);
	Format(s,256,"%t","menu_3");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_7");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_4");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_5");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_8");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_9");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_9a");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_6");
	DrawPanelItem(panel, s);
	SendPanelToClient(panel, client, FF2PanelH, 9001);
	CloseHandle(panel);
	return Plugin_Handled;
}

public NewPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(action==MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
			{
				if(curHelp[param1]<=0)
					NewPanel(param1, 0);
				else
					NewPanel(param1, --curHelp[param1]);
			}
			case 2:
			{
				if(curHelp[param1]>=maxVersion)
					NewPanel(param1, maxVersion);
				else
					NewPanel(param1, ++curHelp[param1]);
			}
			default: return;
		}
	}
}

public Action:NewPanelCmd(client, args)
{
	if(!IsValidClient(client)) return Plugin_Continue;
	NewPanel(client, maxVersion);
	return Plugin_Handled;
}
public Action:NewPanel(client, versionIndex)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	curHelp[client]=versionIndex;
	new Handle:panel=CreatePanel();
	decl String:whatsNew[90];

	SetGlobalTransTarget(client);
	Format(whatsNew, 90, "=%t:=", "whatsnew", ff2versiontitles[versionIndex], ff2versiondates[versionIndex]);
	SetPanelTitle(panel, whatsNew);
	FindVersionData(panel, versionIndex);
	if(versionIndex>0)
	{
		Format(whatsNew, 90, "%t", "older");
	}
	else
	{
		Format(whatsNew, 90, "%t", "noolder");
	}

	DrawPanelItem(panel, whatsNew);  
	if(versionIndex<maxVersion)
	{
		Format(whatsNew, 90, "%t", "newer");
	}
	else
	{
		Format(whatsNew, 90, "%t", "nonewer");
	}

	DrawPanelItem(panel, whatsNew);  
	Format(whatsNew, 512, "%t", "menu_6");
	DrawPanelItem(panel, whatsNew);    
	SendPanelToClient(panel, client, NewPanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Continue;
}

public Action:HelpPanel3Cmd(client, args)
{
	if(!IsValidClient(client)) return Plugin_Continue;
	HelpPanel3(client);
	return Plugin_Handled;
}

public Action:HelpPanel3(client)
{
	if(!Enabled2) 
		return Plugin_Continue;
	new Handle:panel=CreatePanel();
	SetPanelTitle(panel, "Turn the Freak Fortress 2 class info...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, ClassinfoTogglePanelH,9001);
	CloseHandle(panel);
	return Plugin_Handled;
}


public ClassinfoTogglePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(IsValidClient(param1))
	{
		if(action==MenuAction_Select)
		{
			decl String:s[24];
			decl String:ff2cookies_values[8][5];
			GetClientCookie(param1, FF2Cookies, s, 24);
			ExplodeString(s, " ", ff2cookies_values,8,5);
			if(param2==2)
				Format(s,24,"%s %s %s 0 %s %s %s",ff2cookies_values[0],ff2cookies_values[1],ff2cookies_values[2],ff2cookies_values[4],ff2cookies_values[5],ff2cookies_values[6],ff2cookies_values[7]);
			else
				Format(s,24,"%s %s %s 1 %s %s %s",ff2cookies_values[0],ff2cookies_values[1],ff2cookies_values[2],ff2cookies_values[4],ff2cookies_values[5],ff2cookies_values[6],ff2cookies_values[7]);
			SetClientCookie(param1, FF2Cookies,s);
			CPrintToChat(param1,"{olive}[VSH]{default} %t","ff2_classinfo", param2==2 ? "off" : "on");
		}
	}
}

public Action:HelpPanel2Cmd(client, args)
{
	if(!IsValidClient(client)) return Plugin_Continue;
	HelpPanel2(client);
	return Plugin_Handled;
}

public Action:HelpPanel2(client)
{
	if(!Enabled)
		return Plugin_Continue;
	new index=GetBossIndex(client);
	if(index!=-1)
	{
		HelpPanelBoss(index);
		return Plugin_Continue;
	}
	decl String:s[512];
	new TFClassType:class=TF2_GetPlayerClass(client);
	SetGlobalTransTarget(client);
	switch(class)
	{
		case TFClass_Scout:
			Format(s,512,"%t","help_scout");
		case TFClass_Soldier:
			Format(s,512,"%t","help_soldier");
		case TFClass_Pyro:
			Format(s,512,"%t","help_pyro");
		case TFClass_DemoMan:
			Format(s,512,"%t","help_demo");
		case TFClass_Heavy:
			Format(s,512,"%t","help_heavy");
		case TFClass_Engineer:
			Format(s,512,"%t","help_eggineer");
		case TFClass_Medic:
			Format(s,512,"%t","help_medic");
		case TFClass_Sniper:
			Format(s,512,"%t","help_sniper");
		case TFClass_Spy:
			Format(s,512,"%t","help_spie");
		default:
			Format(s, 512, "");
	}
	new Handle:panel=CreatePanel();
	if(class!=TFClass_Sniper)
		Format(s,512,"%t\n%s","help_melee",s);
	SetPanelTitle(panel,s);
	DrawPanelItem(panel,"Exit");
	SendPanelToClient(panel, client, HintPanelH, 20);
	CloseHandle(panel);
	return Plugin_Continue;
}

public Action:HelpPanelBoss(index)
{
	decl String:s[512];
	decl String:lang[20];
	GetLanguageInfo(GetClientLanguage(Boss[index]),lang,8,s,8);
	Format(lang,20,"description_%s",lang);	
	KvRewind(BossKV[Special[index]]);
	KvGetString(BossKV[Special[index]], lang, s, 512);
	if(!s[0])
		return Plugin_Continue;
	ReplaceString(s,512,"\\n","\n");
	new Handle:panel=CreatePanel();
	SetPanelTitle(panel,s);
	DrawPanelItem(panel,"Exit");
	SendPanelToClient(panel, Boss[index], HintPanelH, 20);
	CloseHandle(panel);
	return Plugin_Continue;
}

public Action:MusicTogglePanelCmd(client, args)
{
	if(!IsValidClient(client)) return Plugin_Continue;
	MusicTogglePanel(client);
	return Plugin_Handled;
}

public Action:MusicTogglePanel(client)
{
	if(!Enabled || !IsValidClient(client)) 
		return Plugin_Continue;
	new Handle:panel=CreatePanel();
	SetPanelTitle(panel, "Turn the Freak Fortress 2 music...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, MusicTogglePanelH,9001);
	CloseHandle(panel);
	return Plugin_Continue;
}

public MusicTogglePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(IsValidClient(param1))
	{
		if(action==MenuAction_Select)
		{
			if(param2==2)
			{
				SetClientSoundOptions(param1, SOUNDEXCEPT_MUSIC, false);
				KvRewind(BossKV[Special[0]]);
				if(KvJumpToKey(BossKV[Special[0]],"sound_bgm"))
				{	
					decl String:s[PLATFORM_MAX_PATH];
					Format(s,10,"path%i",MusicIndex);
					KvGetString(BossKV[Special[0]], s,s, PLATFORM_MAX_PATH);
					StopSound(param1, SNDCHAN_AUTO, s);
					StopSound(param1, SNDCHAN_AUTO, s);
				}
			}
			else
				SetClientSoundOptions(param1, SOUNDEXCEPT_MUSIC, true);
			CPrintToChat(param1,"{olive}[FF2]{default} %t","ff2_music", param2==2 ? "off" : "on");
		}
	}
}

public Action:VoiceTogglePanelCmd(client, args)
{
	if(!IsValidClient(client)) return Plugin_Continue;
	VoiceTogglePanel(client);
	return Plugin_Handled;
}

public Action:VoiceTogglePanel(client)
{
	if(!Enabled || !IsValidClient(client)) 
		return Plugin_Continue;
	new Handle:panel=CreatePanel();
	SetPanelTitle(panel, "Turn the Freak Fortress 2 voices...");
	DrawPanelItem(panel, "On");   
	DrawPanelItem(panel, "Off");   
	SendPanelToClient(panel, client, VoiceTogglePanelH,9001);
	CloseHandle(panel);
	return Plugin_Continue;
}

public VoiceTogglePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(IsValidClient(param1))
	{
		if(action==MenuAction_Select)
		{
			if(param2==2)
				SetClientSoundOptions(param1, SOUNDEXCEPT_VOICE, false);
			else
				SetClientSoundOptions(param1, SOUNDEXCEPT_VOICE, true);
			CPrintToChat(param1,"{olive}[FF2]{default} %t","ff2_voice", param2==2 ? "off" : "on");
			if(param2==2) CPrintToChat(param1, "%t","ff2_voice2");
		}
	}
}

public Action:HookSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(!Enabled || ent<1 || ent>MaxClients || channel<1)
		return Plugin_Continue;
	new index=GetBossIndex(ent);
	if(index==-1)
		return Plugin_Continue;
	if(!StrContains(sample,"vo") && !(FF2flags[Boss[index]] & FF2FLAG_TALKING))
	{
		if(bBlockVoice[Special[index]])
			return Plugin_Stop;
		decl String:sample2[PLATFORM_MAX_PATH];
		if(RandomSound("catch_phrase",sample2,PLATFORM_MAX_PATH,index))
		{
			strcopy(sample,PLATFORM_MAX_PATH,sample2);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock SetAmmo(client, slot, ammo)
{
	new weapon=GetPlayerWeaponSlot(client, slot);
	if(IsValidEntity(weapon))
	{
		new iOffset=GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable=FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

stock GetAmmo(client, slot)
{
	if(!IsValidClient(client)) return 0;
	new weapon=GetPlayerWeaponSlot(client, slot);
	if(IsValidEntity(weapon))
	{   
		new iOffset=GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable=FindSendPropInfo("CTFPlayer", "m_iAmmo");
		return GetEntData(client, iAmmoTable+iOffset);
	}
	return 0;
}

stock GetHealingTarget(client,bool:checkgun=false)
{
	decl String:s[64];
	new medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		return -1;
	}
	if(!IsValidEdict(medigun))
		return -1;
	GetEdictClassname(medigun, s, sizeof(s));
	if(strcmp(s, "tf_weapon_medigun", false)==0)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	}
	return -1;
}

stock IsValidClient(client, bool:replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}

public NextmapPanelH(Handle:menu, MenuAction:action, param1, param2)
{	
	if(action==MenuAction_Select && param2==1)
	{
		new clients[1];
		clients[0]=param1;
		if(!IsVoteInProgress())
			VoteMenu(menu, clients,param1, 1,9001);
	}
	else if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return;
}


public NextmapPanelH2(Handle:menu,num_votes,num_clients,const client_info[][2],num_items, const item_info[][2])
{
	decl String:mode[42], String:nextmap[42];
	GetMenuItem(menu, item_info[0][VOTEINFO_ITEM_INDEX], mode,42);
	if(mode[0]=='0')
		FF2CharSet=GetRandomInt(0,FF2CharSet);
	else
		FF2CharSet=mode[0]-'0'-1;
	GetConVarString(cvarNextmap,nextmap,42);
	strcopy(FF2CharSetStr,42,mode[StrContains(mode," ")+1]);
	CPrintToChatAll("%t","nextmap_charset",nextmap,FF2CharSetStr);
	isCharSetSelected=true;
}

public CvarChangeNextmap(Handle:convar, const String:oldValue[], const String:newValue[])
{	
	CreateTimer(0.1, Timer_CvarChangeNextmap);
}

public Action:Timer_CvarChangeNextmap(Handle:hTimer)
{
	if(isCharSetSelected)
	{
		return Plugin_Continue;
	}

	if(IsVoteInProgress())
	{
		CreateTimer(5.0, Timer_CvarChangeNextmap, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	new Handle:dVoteMenu=CreateMenu(NextmapPanelH, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(dVoteMenu, "%t", "select_charset");
	SetVoteResultCallback(dVoteMenu, NextmapPanelH2);

	decl String:config[PLATFORM_MAX_PATH], String:s2[64];
	if(halloween)
	{
		BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters_halloween.cfg");
	}
	else
	{
		BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters.cfg");
	}
	new Handle:Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	AddMenuItem(dVoteMenu, "0 Random", "Random");
	new i, j;
	do
	{
		i++;
		if(KvGetNum(Kv, "hidden", 0))
		{
			continue;
		}
		j++;
		KvGetSectionName(Kv, config, 64);
		Format(s2, 64, "%i %s", i, config);
		AddMenuItem(dVoteMenu, s2, config);
	}
	while(KvGotoNextKey(Kv));
	CloseHandle(Kv);

	if(j>1)
	{
		FF2CharSet=i;
		new Handle:see=FindConVar("sm_mapvote_voteduration");
		if(see)
		{
			VoteMenuToAll(dVoteMenu, GetConVarInt(see));
		}
		else
		{
			VoteMenuToAll(dVoteMenu, 20); 
		}
	}
	return Plugin_Continue;
}

public Action:NextMapCmd(client, args)
{
	if(!FF2CharSetStr[0])
	{
		return Plugin_Continue;
	}
	decl String:nextmap[42];
	GetConVarString(cvarNextmap, nextmap, 42);
	CPrintToChat(client, "%t", "nextmap_charset", nextmap, FF2CharSetStr);
	return Plugin_Handled;
}

public Action:SayCmd(client, args)
{
	decl String:CurrentChat[128];
	if(GetCmdArgString(CurrentChat, sizeof(CurrentChat))<1 || client==0)
	{
		return Plugin_Continue;
	}

	if(!strcmp(CurrentChat, "\"nextmap\"") && FF2CharSetStr[0])
	{
		NextMapCmd(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;	
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

stock SetBossHealthFix(client, oldHealth)  //Wat.  TODO: 2.0.0
{
	new originalHealth=oldHealth;
	SetEntProp(client, Prop_Send, "m_iHealth", originalHealth);
}

UseAbility(const String:ability_name[], const String:plugin_name[], client, slot, buttonMode=0)
{
	new bool:enabled=true;
	Call_StartForward(PreAbility);
	Call_PushCell(client);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	Call_PushCell(slot);
	Call_PushCellRef(enabled);
	Call_Finish();

	if(!enabled)
	{
		return;
	}

	new Action:action=Plugin_Continue;
	Call_StartForward(OnAbility);
	Call_PushCell(client);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	if(slot==-1)
	{
		Call_PushCell(0);
		Call_Finish(action);
	}
	else if(!slot)
	{
		FF2flags[Boss[client]]&=~FF2FLAG_BOTRAGE; 	
		Call_PushCell(0);
		Call_Finish(action);
		BossCharge[client][slot]=0.0;
	}
	else
	{
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
		new button;
		switch(buttonMode)
		{
			case 2:
			{
				button=IN_RELOAD;
			}
			default:
			{
				button=IN_DUCK|IN_ATTACK2;
			}
		}

		if(GetClientButtons(Boss[client]) & button)
		{
			if(!(FF2flags[Boss[client]] & FF2FLAG_USINGABILITY))
			{
				FF2flags[Boss[client]]|=FF2FLAG_USINGABILITY;
				switch(buttonMode)
				{
					case 2:
					{
						SetInfoCookies(Boss[client], 0, CheckInfoCookies(Boss[client], 0)-1);
					}
					default:
					{
						SetInfoCookies(Boss[client], 1, CheckInfoCookies(Boss[client], 1)-1);
					}
				}
			}

			if(BossCharge[client][slot]>=0)
			{
				Call_PushCell(2);
				Call_Finish(action);
				new Float:charge=100.0*0.2/GetAbilityArgumentFloat(client, plugin_name, ability_name, 1, 1.5);
				if(BossCharge[client][slot]+charge<100)
				{
					BossCharge[client][slot]+=charge;
				}
				else
				{
					BossCharge[client][slot]=100.0;
				}
			}
			else
			{
				Call_PushCell(1);
				Call_Finish(action);
				BossCharge[client][slot]+=0.2;
			}
		}
		else if(BossCharge[client][slot]>0.3)
		{	
			new Float:angles[3];
			GetClientEyeAngles(Boss[client], angles);
			if(angles[0]<-45.0)
			{
				Call_PushCell(3);
				Call_Finish(action);
				new Handle:data;
				CreateDataTimer(0.1, Timer_UseBossCharge, data);
				WritePackCell(data, client);
				WritePackCell(data, slot);
				WritePackFloat(data, -1.0*GetAbilityArgumentFloat(client, plugin_name, ability_name, 2, 5.0));
				ResetPack(data);
			}
			else
			{
				Call_PushCell(0);
				Call_Finish(action);
				BossCharge[client][slot]=0.0;
			}
		}
		else if(BossCharge[client][slot]<0)
		{
			Call_PushCell(1);
			Call_Finish(action);
			BossCharge[client][slot]+=0.2;
		}
		else
		{
			Call_PushCell(0);
			Call_Finish(action);
		}
	}
}
	
public Action:Timer_UseBossCharge(Handle:hTimer,Handle:data)
{
	BossCharge[ReadPackCell(data)][ReadPackCell(data)]=ReadPackFloat(data);
	return Plugin_Continue;
}

public Native_IsEnabled(Handle:plugin, numParams)
{
	return Enabled;
}

public Native_GetBoss(Handle:plugin, numParams)
{
	new i=GetNativeCell(1);
	if(i>-1 && i<MaxClients+1 && IsValidClient(Boss[i]))
		return GetClientUserId(Boss[i]);
	return -1;
}

public Native_GetIndex(Handle:plugin, numParams)
{
	return GetBossIndex(GetNativeCell(1));
}

public Native_GetTeam(Handle:plugin, numParams)
{
	return BossTeam;
}

public Native_GetSpecial(Handle:plugin, numParams)
{
	new index=GetNativeCell(1);
	new dstrlen=GetNativeCell(3);
	decl String:s[dstrlen];
	new see=GetNativeCell(4);
	if(see)
	{
		if(index<0) return false;
		if(!BossKV[index]) return false;
		KvRewind(BossKV[index]);
		KvGetString(BossKV[index], "name", s, dstrlen);
		SetNativeString(2, s,dstrlen);
	}
	else
	{
		if(index<0) return false;
		if(Special[index]<0) return false;
		if(!BossKV[Special[index]]) return false;
		KvRewind(BossKV[Special[index]]);
		KvGetString(BossKV[Special[index]], "name", s, dstrlen);
		SetNativeString(2, s,dstrlen);
	}
	return true;
}

public Native_GetHealth(Handle:plugin, numParams)
{
	return BossHealth[GetNativeCell(1)];
}

public Native_GetHealthMax(Handle:plugin, numParams)
{
	return BossHealthMax[GetNativeCell(1)];
}

public Native_GetBossCharge(Handle:plugin, numParams)
{
	new client=GetNativeCell(1);
	new slot=GetNativeCell(2);
	return _:BossCharge[client][slot];
}

public Native_SetBossCharge(Handle:plugin, numParams)
{
	new client=GetNativeCell(1);
	new slot=GetNativeCell(2);
	BossCharge[client][slot]=Float:GetNativeCell(3);
}

public Native_GetRoundState(Handle:plugin, numParams)
{
	if(CheckRoundState()<=0)
	{
		return 0;
	}
	return CheckRoundState();
}

public Native_GetRageDist(Handle:plugin, numParams)
{
	new index=GetNativeCell(1);
	decl String:plugin_name[64]; 	
	GetNativeString(2,plugin_name,64);
	decl String:ability_name[64]; 	
	GetNativeString(3,ability_name,64);

	if(!BossKV[Special[index]]) return _:0.0;
	KvRewind(BossKV[Special[index]]);
	decl Float:see;
	if(!ability_name[0])
	{
		return _:KvGetFloat(BossKV[Special[index]],"ragedist",400.0);
	}
	decl String:s[10];
	for(new i=1; i<MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if(strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			if((see=KvGetFloat(BossKV[Special[index]],"dist",-1.0))<0)
			{
				KvRewind(BossKV[Special[index]]);
				see=KvGetFloat(BossKV[Special[index]],"ragedist",400.0);
			}
			return _:see;
		}
	}
	return _:0.0;
}

public Native_HasAbility(Handle:plugin, numParams)
{
	decl String:plugin_name[64]; 	
	decl String:ability_name[64]; 	
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	return HasAbility(GetNativeCell(1),plugin_name,ability_name);
}

public Native_DoAbility(Handle:plugin, numParams)
{
	decl String:plugin_name[64]; 	
	decl String:ability_name[64]; 	
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	UseAbility(ability_name,plugin_name, GetNativeCell(1), GetNativeCell(4), GetNativeCell(5));
}

public Native_GetAbilityArgument(Handle:plugin, numParams)
{ 
	decl String:plugin_name[64]; 	
	decl String:ability_name[64]; 	
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	return GetAbilityArgument(GetNativeCell(1),plugin_name,ability_name,GetNativeCell(4),GetNativeCell(5));
}

public Native_GetAbilityArgumentFloat(Handle:plugin, numParams)
{ 
	decl String:plugin_name[64]; 	
	decl String:ability_name[64]; 	
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	return _:GetAbilityArgumentFloat(GetNativeCell(1),plugin_name,ability_name,GetNativeCell(4),GetNativeCell(5));
}

public Native_GetAbilityArgumentString(Handle:plugin, numParams)
{ 
	decl String:plugin_name[64]; 	
	GetNativeString(2,plugin_name,64);
	decl String:ability_name[64]; 	
	GetNativeString(3,ability_name,64);
	new dstrlen=GetNativeCell(6);
	new String:s[dstrlen+1];
	GetAbilityArgumentString(GetNativeCell(1),plugin_name,ability_name,GetNativeCell(4),s,dstrlen);
	SetNativeString(5,s,dstrlen); 	
}

public Native_GetDamage(Handle:plugin, numParams)
{
	new client=GetNativeCell(1);
	if(!IsValidClient(client))
	{
		return 0;
	}
	return Damage[client];
}

public Native_GetFF2flags(Handle:plugin, numParams)
{
	return FF2flags[GetNativeCell(1)];
}

public Native_SetFF2flags(Handle:plugin, numParams)
{
	FF2flags[GetNativeCell(1)]=GetNativeCell(2);
}

public Native_GetQueuePoints(Handle:plugin, numParams)
{
	return GetClientQueuePoints(GetNativeCell(1));
}

public Native_SetQueuePoints(Handle:plugin, numParams)
{
	SetClientQueuePoints(GetNativeCell(1), GetNativeCell(2));
}

public Native_GetSpecialKV(Handle:plugin, numParams)
{
	new index=GetNativeCell(1);
	new bool:isNumOfSpecial=bool:GetNativeCell(2);
	if(isNumOfSpecial)
	{
		if(index!=-1 && index<Specials)
		{
			if(BossKV[index]!=INVALID_HANDLE)
			{
				KvRewind(BossKV[index]);
			}
			return _:BossKV[index];
		}
	}
	else
	{
		if(index!=-1 && index<MaxClients+1 && Special[index]!=-1 && Special[index]<MAXSPECIALS)
		{
			if(BossKV[Special[index]]!=INVALID_HANDLE)
			{
				KvRewind(BossKV[Special[index]]);
			}
			return _:BossKV[Special[index]];
		}
	}
	return _:INVALID_HANDLE; 	
}

public Native_StartMusic(Handle:plugin, numParams)
{
	Timer_MusicPlay(INVALID_HANDLE,GetNativeCell(1));
}

public Native_StopMusic(Handle:plugin, numParams)
{
	if(!BossKV[Special[0]])
	{
		return;
	}

	KvRewind(BossKV[Special[0]]);
	if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
	{
		decl String:music[PLATFORM_MAX_PATH];
		Format(music, sizeof(music), "path%i", MusicIndex);
		KvGetString(BossKV[Special[0]], music, music, PLATFORM_MAX_PATH);

		new client;
		if(plugin==INVALID_HANDLE)
		{
			client=0;
		}
		else
		{
			client=GetNativeCell(1);
		}

		if(!client)
		{
			for(new target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target))
				{
					StopSound(target, SNDCHAN_AUTO, music);
					StopSound(target, SNDCHAN_AUTO, music);
				}
			}
		}
		else
		{
			StopSound(client, SNDCHAN_AUTO, music);
			StopSound(client, SNDCHAN_AUTO, music);
		}
	}	
}

public Native_RandomSound(Handle:plugin, numParams)
{
	new length=GetNativeCell(3)+1;
	new index=GetNativeCell(4);
	new slot=GetNativeCell(5);
	new String:str[length];
	decl alength;

	GetNativeStringLength(1, alength);
	alength++;

	decl String:keyvalue[alength];
	GetNativeString(1, keyvalue, alength);
	decl bool:see;
	if(!strcmp(keyvalue, "sound_ability"))
	{
		see=RandomSoundAbility(keyvalue, str, length, index, slot);
	}
	else
	{
		see=RandomSound(keyvalue, str,length,index);
	}
	SetNativeString(2, str, length);
	return see;
}

public Native_GetClientGlow(Handle:plugin, numParams)
{
	new client=GetNativeCell(1);
	if(IsValidClient(client))
	{
		return _:GlowTimer[client];
	}
	else
	{
		return -1;
	}
}

public Native_SetClientGlow(Handle:plugin, numParams)
{
	SetClientGlow(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public Native_Debug(Handle:plugin, numParams)
{
	return GetConVarBool(cvarDebug);
}

public Native_IsVSHMap(Handle:plugin, numParams)
{
	return false;
}

public Action:VSH_OnIsSaxtonHaleModeEnabled(&result)
{
	if((!result || result==1) && Enabled)
	{
		result=2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleTeam(&result)
{
	if(Enabled)
	{
		result=BossTeam; 	
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleUserId(&result)
{
	if(Enabled && IsClientConnected(Boss[0]))
	{
		result=GetClientUserId(Boss[0]);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSpecialRoundIndex(&result)
{
	if(Enabled)
	{
		result=Special[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleHealth(&result)
{
	if(Enabled)
	{
		result=BossHealth[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleHealthMax(&result)
{
	if(Enabled)
	{
		result=BossHealthMax[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetClientDamage(client, &result)
{
	if(Enabled)
	{
		result=Damage[client];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetRoundState(&result)
{
	if(Enabled)
	{
		result=CheckRoundState();
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnTakeDamagePost(client, attacker, inflictor, Float:damage, damagetype)
{
	if(IsBoss(client))
	{
		new boss=GetBossIndex(client);
		if(boss==-1)
		{
			return;
		}

		if(TF2_IsPlayerInCondition(Boss[boss],TFCond_Jarated))
		{
			TF2_RemoveCondition(Boss[boss],TFCond_Jarated);
		}
		else if(TF2_IsPlayerInCondition(Boss[boss], TFCond_MarkedForDeath))
		{
			TF2_RemoveCondition(Boss[boss], TFCond_MarkedForDeath);
		}
		UpdateHealthBar();
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(!GetConVarBool(cvarHealthBar))
	{
		return;
	}

	if(StrEqual(classname, HEALTHBAR_CLASS))
	{
		healthBar=entity;
	}

	if(g_Monoculus==-1 && StrEqual(classname, MONOCULUS))
	{
		g_Monoculus=entity;
	}
}

public OnEntityDestroyed(entity)
{
	if(entity==-1)
	{
		return;
	}

	if(entity==g_Monoculus)
	{
		g_Monoculus=FindEntityByClassname(-1, MONOCULUS);
		if(g_Monoculus==entity)
		{
			g_Monoculus=FindEntityByClassname(entity, MONOCULUS);
		}
	}	
}

public CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return -1;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return 0;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return 1;
		}
		default:
		{
			return 2;
		}
	}
	return -1;
}

FindHealthBar()
{
	healthBar=FindEntityByClassname(-1, HEALTHBAR_CLASS);
	if(healthBar==-1)
	{
		healthBar=CreateEntityByName(HEALTHBAR_CLASS);
	}
}

public HealthbarEnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarBool(cvarHealthBar))
	{
		UpdateHealthBar();
	}
	else if(g_Monoculus==-1)
	{
		SetEntProp(healthBar, Prop_Send, HEALTHBAR_PROPERTY, 0);
	}
}

UpdateHealthBar()
{
	if(!GetConVarBool(cvarHealthBar) || g_Monoculus!=-1 || CheckRoundState()==-1)
	{
		return;
	}
	new healthAmount=0;
	new maxHealthAmount=0;
	
	new count=0;
	
	for(new client=0; client<MaxClients; client++)
	{
		if(IsValidClient(Boss[client]) && IsPlayerAlive(Boss[client]))
		{
			count++;
			healthAmount+=BossHealth[client]-BossHealthMax[client]*(BossLives[client]-1);
			maxHealthAmount+=BossHealthMax[client];
		}
	}

	new healthPercent=0;
	if(count>0)
	{
		healthPercent=RoundToCeil(float(healthAmount)/float(maxHealthAmount)*float(HEALTHBAR_MAX));
		if(healthPercent>HEALTHBAR_MAX)
		{
			healthPercent=HEALTHBAR_MAX;
		}
		else if(healthPercent<=0)
		{
			healthPercent=1;
		}
	}
	SetEntProp(healthBar, Prop_Send, HEALTHBAR_PROPERTY, healthPercent);
}

SetClientGlow(client, Float:time1, Float:time2=-1.0)
{
	if(!IsValidClient(client) && !IsValidClient(Boss[client]))
	{
		return;
	}

	GlowTimer[client]+=time1;
	if(time2>=0)
	{
		GlowTimer[client]=time2;
	}

	if(GlowTimer[client]<=0.0)
	{
		GlowTimer[client]=0.0;
		if(IsValidClient(Boss[client]))
		{
			SetEntProp(Boss[client], Prop_Send, "m_bGlowEnabled", 0);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
	}
	else
	{
		if(IsValidClient(Boss[client]))
		{
			SetEntProp(Boss[client], Prop_Send, "m_bGlowEnabled", 1);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		}
	}
}
#include <freak_fortress_2_vsh_feedback>