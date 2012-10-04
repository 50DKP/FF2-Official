new Handle:OnIsVSHMap;
new Handle:OnIsEnabled;
new Handle:OnGetHale;
new Handle:OnGetTeam;
new Handle:OnGetSpecial;
new Handle:OnGetHealth;
new Handle:OnGetHealthMax;
new Handle:OnGetDamage;
new Handle:OnGetRoundState;

AskPluginLoad_VSH()
{
	CreateNative("VSH_IsSaxtonHaleModeMap", Native_VSHIsVSHMap);
	OnIsVSHMap = CreateGlobalForward("VSH_OnIsSaxtonHaleModeMap", ET_Hook, Param_CellByRef);
	
	CreateNative("VSH_IsSaxtonHaleModeEnabled", Native_VSHIsEnabled);
	OnIsEnabled = CreateGlobalForward("VSH_OnIsSaxtonHaleModeEnabled", ET_Hook, Param_CellByRef);
	
	CreateNative("VSH_GetSaxtonHaleUserId", Native_VSHGetHale);
	OnGetHale = CreateGlobalForward("VSH_OnGetSaxtonHaleUserId", ET_Hook, Param_CellByRef);
	
	CreateNative("VSH_GetSaxtonHaleTeam", Native_VSHGetTeam);
	OnGetTeam = CreateGlobalForward("VSH_OnGetSaxtonHaleTeam", ET_Hook, Param_CellByRef);
	
	CreateNative("VSH_GetSpecialRoundIndex", Native_VSHGetSpecial);
	OnGetSpecial = CreateGlobalForward("VSH_OnGetSpecialRoundIndex", ET_Hook, Param_CellByRef);
	
	CreateNative("VSH_GetSaxtonHaleHealth", Native_VSHGetHealth);
	OnGetHealth = CreateGlobalForward("VSH_OnGetSaxtonHaleHealth", ET_Hook, Param_CellByRef);
	
	CreateNative("VSH_GetSaxtonHaleHealthMax", Native_VSHGetHealthMax);
	OnGetHealthMax = CreateGlobalForward("VSH_OnGetSaxtonHaleHealthMax", ET_Hook, Param_CellByRef);
	
	CreateNative("VSH_GetClientDamage", Native_VSHGetDamage);
	OnGetDamage = CreateGlobalForward("VSH_OnGetClientDamage", ET_Hook, Param_Cell,Param_CellByRef);
	
	CreateNative("VSH_GetRoundState", Native_VSHGetRoundState);
	OnGetRoundState = CreateGlobalForward("VSH_OnGetRoundState", ET_Hook, Param_CellByRef);

	RegPluginLibrary("saxtonhale");
}

public Native_VSHIsVSHMap(Handle:plugin, numParams)
{
	return IsFF2Map();
/*	new result=false;
	new result2=result;

	new Action:act = Plugin_Continue;
	Call_StartForward(OnIsVSHMap);
	Call_PushCellRef(result2);
	Call_Finish(act);
	if (act==Plugin_Changed)
		result=result2;		
	return result;*/
}

public Native_VSHIsEnabled(Handle:plugin, numParams)
{
	new result=(Enabled?2:0);
	new result2=result;

	new Action:act = Plugin_Continue;
	Call_StartForward(OnIsEnabled);
	Call_PushCellRef(result2);
	Call_Finish(act);
	if (act==Plugin_Changed)
		result=result2;		
	return result;
}


public Native_VSHGetHale(Handle:plugin, numParams)
{
	decl result;
	if (IsValidClient(Boss[0]))
		result=GetClientUserId(Boss[0]);
	else
		result=-1;
	new result2=result;
		
	new Action:act = Plugin_Continue;
	Call_StartForward(OnGetHale);
	Call_PushCellRef(result2);
	Call_Finish(act);
	if (act==Plugin_Changed)
		result=result2;		
	return result;

}

public Native_VSHGetTeam(Handle:plugin, numParams)
{
	new result=BossTeam;
	new result2=result;
	
	new Action:act = Plugin_Continue;
	Call_StartForward(OnGetTeam);
	Call_PushCellRef(result2);
	Call_Finish(act);
	if (act==Plugin_Changed)
		result=result2;		
	return result;
}

public Native_VSHGetSpecial(Handle:plugin, numParams)
{
	new result=Special[0];
	new result2=result;
	
	new Action:act = Plugin_Continue;
	Call_StartForward(OnGetSpecial);
	Call_PushCellRef(result2);
	Call_Finish(act);
	if (act==Plugin_Changed)
		result=result2;	
		
	return result;
}

public Native_VSHGetHealth(Handle:plugin, numParams)
{
	new result=BossHealth[0];
	new result2=result;
	
	new Action:act = Plugin_Continue;
	Call_StartForward(OnGetHealth);
	Call_PushCellRef(result2);
	Call_Finish(act);
	if (act==Plugin_Changed)
		result=result2;	
		
	return result;
}

public Native_VSHGetHealthMax(Handle:plugin, numParams)
{
	new result=BossHealthMax[0];
	new result2=result;
	
	new Action:act = Plugin_Continue;
	Call_StartForward(OnGetHealthMax);
	Call_PushCellRef(result2);
	Call_Finish(act);
	if (act==Plugin_Changed)
		result=result2;	
		
	return result;
}

public Native_VSHGetRoundState(Handle:plugin, numParams)
{
	new result=FF2RoundState;
	new result2=result;
	
	new Action:act = Plugin_Continue;
	Call_StartForward(OnGetRoundState);
	Call_PushCellRef(result2);
	Call_Finish(act);
	if (act==Plugin_Changed)
		result=result2;	
		
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
	new result2=result;
	
	new Action:act = Plugin_Continue;
	Call_StartForward(OnGetDamage);
	Call_PushCell(client);
	Call_PushCellRef(result2);
	Call_Finish(act);
	if (act==Plugin_Changed)
		result=result2;	
		
	return result;
}
