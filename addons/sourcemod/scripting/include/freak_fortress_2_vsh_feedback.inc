AskPluginLoad_VSH()
{
	CreateNative("VSH_IsSaxtonHaleModeMap", Native_VSHIsVSHMap);
	
	CreateNative("VSH_IsSaxtonHaleModeEnabled", Native_VSHIsEnabled);
	
	CreateNative("VSH_GetSaxtonHaleUserId", Native_VSHGetHale);
	
	CreateNative("VSH_GetSaxtonHaleTeam", Native_VSHGetTeam);
	
	CreateNative("VSH_GetSpecialRoundIndex", Native_VSHGetSpecial);
	
	CreateNative("VSH_GetSaxtonHaleHealth", Native_VSHGetHealth);
	
	CreateNative("VSH_GetSaxtonHaleHealthMax", Native_VSHGetHealthMax);
	
	CreateNative("VSH_GetClientDamage", Native_VSHGetDamage);
	
	CreateNative("VSH_GetRoundState", Native_VSHGetRoundState);

	RegPluginLibrary("saxtonhale");
}

public Native_VSHIsVSHMap(Handle:plugin, numParams)
{
	return IsFF2Map();
}

public Native_VSHIsEnabled(Handle:plugin, numParams)
{
	new result=(Enabled?2:0);
	return result;
}


public Native_VSHGetHale(Handle:plugin, numParams)
{
	decl result;
	if (IsValidClient(Boss[0]))
		result=GetClientUserId(Boss[0]);
	else
		result=-1;
	return result;

}

public Native_VSHGetTeam(Handle:plugin, numParams)
{
	new result=BossTeam;
	return result;
}

public Native_VSHGetSpecial(Handle:plugin, numParams)
{
	new result=Special[0];
	return result;
}

public Native_VSHGetHealth(Handle:plugin, numParams)
{
	new result=BossHealth[0];
	return result;
}

public Native_VSHGetHealthMax(Handle:plugin, numParams)
{
	new result=BossHealthMax[0];
	return result;
}

public Native_VSHGetRoundState(Handle:plugin, numParams)
{
	new result=FF2RoundState;
	return result;
}

public Native_VSHGetDamage(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	decl result;
	if (!IsValidClient(client))
		result=0;
	else
		result=Damage[client];
		
	return result;
}
