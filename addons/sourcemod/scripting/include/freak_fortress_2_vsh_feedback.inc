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
	return (Enabled ? 2 : 0);
}


public Native_VSHGetHale(Handle:plugin, numParams)
{
	return (IsValidClient(Boss[0]) ? GetClientUserId(Boss[0]) : -1);
}

public Native_VSHGetTeam(Handle:plugin, numParams)
{
	return BossTeam;
}

public Native_VSHGetSpecial(Handle:plugin, numParams)
{
	return Special[0];
}

public Native_VSHGetHealth(Handle:plugin, numParams)
{
	return BossHealth[0];
}

public Native_VSHGetHealthMax(Handle:plugin, numParams)
{
	return BossHealthMax[0];
}

public Native_VSHGetRoundState(Handle:plugin, numParams)
{
	return CheckRoundState();
}

public Native_VSHGetDamage(Handle:plugin, numParams)
{
	new client=GetNativeCell(1);
	return (IsValidClient(client) ? Damage[client] : 0);
}