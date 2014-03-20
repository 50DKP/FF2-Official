new String:this_plugin_name[80];

GetThisPluginName()
{
	decl String:pluginName[80];
	GetPluginFilename(INVALID_HANDLE, pluginName, 80);
	ReplaceString(pluginName, 80, ".ff2", "", false);
	new forwardSlash=-1;
	new backwardSlash=-1;
	new finalPluginName=-1;
	for(;;)
	{
		forwardSlash=StrContains(pluginName[finalPluginName+1], "/");
		backwardSlash=StrContains(pluginName[finalPluginName+1], "\\");
		if((backwardSlash<forwardSlash && backwardSlash!=-1) || forwardSlash==-1)
		{
			if(backwardSlash==-1)
			{
				break;
			}
			finalPluginName=backwardSlash;
		}
		else if((forwardSlash<backwardSlash && forwardSlash!=-1) || backwardSlash==-1)
		{
			if(forwardSlash==-1)
			{
				break;
			}
			finalPluginName=forwardSlash;
		}
	}
	strcopy(this_plugin_name, 80, pluginName[finalPluginName+1]);
}

public OnPluginStart()
{
	OnPluginStart2();
	GetThisPluginName();
}

public Action:FF2_OnAbility(client, const String:plugin_name[], const String:ability_name[], status)
{
	if(plugin_name[0])
	{
		if(strcmp(this_plugin_name, plugin_name))
		{
			return Plugin_Continue;
		}
	}
	FF2_OnAbility2(client, plugin_name, ability_name, status);
	return Plugin_Continue;
}