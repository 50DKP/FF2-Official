new String:this_plugin_name[80];

GetThisPluginName()
{
	decl String:s[80];
	GetPluginFilename(INVALID_HANDLE,s,80);
	ReplaceString(s, 80,".ff2", "",false);
	new see=-1;
	new see2=-1;
	new see3=-1;
	for(;;)
	{
		see=StrContains(s[see3+1],"/");
		see2=StrContains(s[see3+1],"\\");
		if ((see2<see && see2!=-1) || see==-1)
		{
			if (see2==-1) break;
			see3=see2;
		}
		else if ((see<see2 && see!=-1) || see2==-1)
		{
			if (see==-1) break;
			see3=see;
		}
	}
	strcopy(this_plugin_name,80,s[see3+1]);
}

public OnPluginStart()
{
	OnPluginStart2();
	
	GetThisPluginName();
}

public Action:FF2_OnAbility(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (plugin_name[0])
	{
		if (strcmp(this_plugin_name,plugin_name))
			return Plugin_Continue;	
	}
	FF2_OnAbility2(index,plugin_name,ability_name,action);
	return Plugin_Continue;
}
