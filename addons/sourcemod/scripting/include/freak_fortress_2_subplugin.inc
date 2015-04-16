#include <freak_fortress_2>

#define this_plugin_name myPluginName

new String:myPluginName[80];

GetMyPluginName()
{
	decl String:pluginName[80];
	GetPluginFilename(INVALID_HANDLE, pluginName, sizeof(pluginName));
	new i=strlen(pluginName);
	while (i > -1)
	{
		if (pluginName[i] == '/' || pluginName[i] == '\\')
		{
			break;
		}
		i--;
	}
	strcopy(myPluginName, sizeof(myPluginName), pluginName[i+1]);
}

public OnPluginStart()
{
	GetMyPluginName();
#if !defined NO_PLUGINSTART2
	OnPluginStart2();
#endif
}

public FF2_PreAbility(boss, const String:pluginName[], const String:abilityName[], slot, &bool:enabled)
{
	if (!StrEqual(pluginName, myPluginName))
		return;
#if defined PREABILITY2
#if defined PREABILITY2_NOPNAME
	FF2_PreAbility2(boss, abilityName, enabled);
#else
	FF2_PreAbility2(boss, pluginName, abilityName, enabled);
#endif
#endif
}

public Action:FF2_OnAbility(boss, const String:pluginName[], const String:abilityName[], status)
{
	if (pluginName[0] != '\0' && myPluginName[0] != '\0' && !StrEqual(pluginName, myPluginName))
		return;
#if !defined NO_ONABILITY2
	FF2_OnAbility2(boss, pluginName, abilityName, status);
#endif
}
