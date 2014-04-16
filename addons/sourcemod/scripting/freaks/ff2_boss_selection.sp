#include <freak_fortress_2>

#define VERSION "1.7"

new String:Incoming[MAXPLAYERS+1][64];

new g_NextHale = -1;
new Handle:g_NextHaleTimer = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Freak Fortress 2: Boss Selection",
	description = "Allows players select their bosses by /ff2boss",
	author = "RainBolt Dash and Powerlord",
	version = VERSION,
};

public FF2_SubPluginPreLoad()
{
	new FF2_SubReason:reason;
	if (!RegisterSubPlugin("Boss selection", FF2_SubPluginFlags_StartMapStart|FF2_SubPluginFlags_UnloadMapEnd, BossSelectionStart, BossSelectionEnd, reason))
	{
		if (reason != FF2_SubReason_Exists)
			SetFailState("Oh my. I failed to load D':");
	}
}

public BossSelectionStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("ff2_boss_selection");
}

public BossSelectionEnd()
{
}
