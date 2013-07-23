#include <sourcemod>
#include <functions>

#if defined _freak_fortress_2_natives
  #endinput
#endif
#define _freak_fortress_2_natives

// FF2 Forwards
new Handle:g_Forward_PreAbility;
new Handle:g_Forward_OnAbility;
new Handle:g_Forward_OnTriggerHurt;
new Handle:g_Forward_OnMusic;
new Handle:g_Forward_OnSpecialSelected;
new Handle:g_Forward_OnSpecialSelectedEx;
new Handle:g_Forward_OnAddQueuePoints;
new Handle:g_Forward_OnLoadCharacterSet;
new Handle:g_Forward_OnLoadCharacterSetEx;

// VSH Forwards
new Handle:g_Forward_OnHaleJump;
new Handle:g_Forward_OnHaleRage;
new Handle:g_Forward_OnHaleWeighdown;
new Handle:g_Forward_OnHaleMusic;

/*
new Handle:g_Forward_OnIsVSHMap;
new Handle:g_Forward_OnIsEnabled;
new Handle:g_Forward_OnGetHale;
new Handle:g_Forward_OnGetTeam;
new Handle:g_Forward_OnGetSpecial;
new Handle:g_Forward_OnGetHealth;
new Handle:g_Forward_OnGetHealthMax;
new Handle:g_Forward_OnGetDamage;
new Handle:g_Forward_OnGetRoundState;
*/

CreateFF2Natives()
{
	CreateNative("FF2_IsFF2Enabled", Native_IsFF2Enabled);
	CreateNative("FF2_IsFF2ModeMap", Native_IsFF2ModeMap);
	CreateNative("FF2_GetRoundState", Native_GetRoundState);
	CreateNative("FF2_GetBossUserId", Native_GetBossUserId);
	CreateNative("FF2_GetBossClientId", Native_GetBossClientId);
	CreateNative("FF2_GetBossTeam", Native_GetBossTeam);
	CreateNative("FF2_GetBossHealth", Native_GetBossHealth);
	CreateNative("FF2_GetBossMaxHealth", Native_GetBossMaxHealth);
	CreateNative("FF2_GetClientDamage", Native_GetClientDamage);
	CreateNative("FF2_GetBossIndex", Native_GetBossIndex);
	CreateNative("FF2_GetBossSpecial", Native_GetBossSpecial);
	CreateNative("FF2_GetBossCharge", Native_GetBossCharge);
	CreateNative("FF2_SetBossCharge", Native_SetBossCharge);
	CreateNative("FF2_GetClientHealing", Native_GetClientHealing);
	CreateNative("FF2_GetRageDist", Native_GetRageDist);
	CreateNative("FF2_HasAbility", Native_HasAbility);
	CreateNative("FF2_HasAbilityEx", Native_HasAbilityEx);
	CreateNative("FF2_DoAbility", Native_DoAbility);
	CreateNative("FF2_DoAbilityEx", Native_DoAbilityEx);
	CreateNative("FF2_GetAbilityArgument", Native_GetAbilityArgument);
	CreateNative("FF2_GetAbilityArgumentFloat", Native_GetAbilityArgumentFloat);
	CreateNative("FF2_GetAbilityArgumentString", Native_GetAbilityArgumentString);
	CreateNative("FF2_RandomSound", Native_RandomSound);
	CreateNative("FF2_StopMusic", Native_StopMusic);
	CreateNative("FF2_GetSpecialKV", Native_GetSpecialKV);
	CreateNative("FF2_GetFF2flags", Native_GetFF2flags);
	CreateNative("FF2_SetFF2flags", Native_SetFF2flags);
	CreateNative("FF2_GetQueuePoints", Native_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints", Native_SetQueuePoints);
	CreateNative("FF2_EmitSoundToAllExcept", Native_EmitSoundToAllExcept);
	CreateNative("FF2_GetDatabaseHandle", Native_GetDatabaseHandle);

	g_Forward_PreAbility = CreateGlobalForward("FF2_PreAbility", ET_Ignore, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);
	g_Forward_OnAbility = CreateGlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);
	g_Forward_OnTriggerHurt = CreateGlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	g_Forward_OnMusic = CreateGlobalForward("FF2_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
	g_Forward_OnSpecialSelected = CreateGlobalForward("FF2_OnSpecialSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String);
	g_Forward_OnSpecialSelectedEx = CreateGlobalForward("FF2_OnSpecialSelectedEx", ET_Hook, Param_Cell, Param_String);
	g_Forward_OnAddQueuePoints = CreateGlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
	g_Forward_OnLoadCharacterSet = CreateGlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_Cell, Param_String);
	g_Forward_OnLoadCharacterSetEx = CreateGlobalForward("FF2_OnLoadCharacterSetEx", ET_Hook, Param_String);
}

CreateVSHNatives()
{
	CreateNative("VSH_IsSaxtonHaleModeEnabled", Native_IsFF2Enabled);
	CreateNative("VSH_IsSaxtonHaleModeMap", Native_IsFF2ModeMap);
	CreateNative("VSH_GetRoundState", Native_GetRoundState);
	CreateNative("VSH_GetSaxtonHaleUserId", Native_GetBossUserId);
	CreateNative("VSH_GetSaxtonHaleTeam", Native_GetBossTeam);
	CreateNative("VSH_GetSaxtonHaleHealth", Native_GetBossHealth);
	CreateNative("VSH_GetSaxtonHaleHealthMax", Native_GetBossMaxHealth);
	CreateNative("VSH_GetClientDamage", Native_GetClientDamage);

	g_Forward_OnHaleJump = CreateGlobalForward("VSH_OnDoJump", ET_Hook, Param_CellByRef);
	g_Forward_OnHaleRage = CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	g_Forward_OnHaleWeighdown = CreateGlobalForward("VSH_OnDoWeighdown", ET_Hook);
	g_Forward_OnHaleMusic = CreateGlobalForward("VSH_OnMusic", ET_Hook, Param_String, Param_FloatByRef);

	/*
	g_Forward_OnIsVSHMap = CreateGlobalForward("VSH_OnIsSaxtonHaleModeMap", ET_Hook, Param_CellByRef);
	g_Forward_OnIsEnabled = CreateGlobalForward("VSH_OnIsSaxtonHaleModeEnabled", ET_Hook, Param_CellByRef);
	g_Forward_OnGetHale = CreateGlobalForward("VSH_OnGetSaxtonHaleUserId", ET_Hook, Param_CellByRef);
	g_Forward_OnGetTeam = CreateGlobalForward("VSH_OnGetSaxtonHaleTeam", ET_Hook, Param_CellByRef);
	g_Forward_OnGetSpecial = CreateGlobalForward("VSH_OnGetSpecialRoundIndex", ET_Hook, Param_CellByRef);
	g_Forward_OnGetHealth = CreateGlobalForward("VSH_OnGetSaxtonHaleHealth", ET_Hook, Param_CellByRef);
	g_Forward_OnGetHealthMax = CreateGlobalForward("VSH_OnGetSaxtonHaleHealthMax", ET_Hook, Param_CellByRef);
	g_Forward_OnGetDamage = CreateGlobalForward("VSH_OnGetClientDamage", ET_Hook, Param_Cell,Param_CellByRef);
	g_Forward_OnGetRoundState = CreateGlobalForward("VSH_OnGetRoundState", ET_Hook, Param_CellByRef);
	*/
	RegPluginLibrary("saxtonhale");
}

public Native_IsFF2Enabled(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_IsFF2ModeMap(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetRoundState(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetBossUserId(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetBossClientId(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetBossIndex(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetBossTeam(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetBossSpecial(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetBossHealth(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetBossMaxHealth(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetBossCharge(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_SetBossCharge(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetClientDamage(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetClientHealing(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetRageDist(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_HasAbility(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_HasAbilityEx(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_DoAbility(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_DoAbilityEx(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetAbilityArgument(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetAbilityArgumentFloat(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetAbilityArgumentString(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_RandomSound(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_StopMusic(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetSpecialKV(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetFF2flags(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_SetFF2flags(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetQueuePoints(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_SetQueuePoints(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_EmitSoundToAllExcept(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_RegisterAbility(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_UnregisterAbility(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetRandomAbility(Handle:plugin, numParams)
{
	//TODO
	
}

public Native_GetDatabaseHandle(Handle:plugin, numParams)
{
	return DbConnect();
}
