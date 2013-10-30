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

// native bool:FF2_IsFF2Enabled();
public Native_IsFF2Enabled(Handle:plugin, numParams)
{
	//TODO
	
}

// native bool:FF2_IsFF2ModeMap(const String:map[]);
public Native_IsFF2ModeMap(Handle:plugin, numParams)
{
	//TODO
	
}

// native FF2_GetRoundState();
public Native_GetRoundState(Handle:plugin, numParams)
{
	//TODO
	
}

// native FF2_GetBossUserId( index = 0 );
public Native_GetBossUserId(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetBossClientId( index = 0 );
public Native_GetBossClientId(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetBossClientId( index = 0 );
public Native_GetBossIndex(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetBossTeam();
public Native_GetBossTeam(Handle:plugin, numParams)
{
	//TODO
	
}

//native bool:FF2_GetBossSpecial( index = 0, String:buffer[], bufferlen, isNumOfSpecial = 0 );
//native bool:FF2_GetBossName( index = 0, String:buffer[], bufferlen, isNumOfSpecial = 0 );
public Native_GetBossSpecial(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetBossLives( index = 0 );
public Native_GetBossLives(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetBossMaxLives( index = 0 );
public Native_GetBossMaxLives(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetBossHealth( index = 0 );
public Native_GetBossHealth(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetBossMaxHealth( index = 0 );
public Native_GetBossMaxHealth(Handle:plugin, numParams)
{
	//TODO
	
}

//native Float:FF2_GetBossCharge( index, charge_type = FF2_CHARGE_RAGE );
public Native_GetBossCharge(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_SetBossCharge( index, charge_type, Float:value );
public Native_SetBossCharge(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetClientDamage( client );
public Native_GetClientDamage(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetClientHealing( client );
public Native_GetClientHealing(Handle:plugin, numParams)
{
	//TODO
	
}

//native Float:FF2_GetRageDist( index = 0 , const String:plugin_name[]="", const String:ability_name[]="" );
public Native_GetRageDist(Handle:plugin, numParams)
{
	//TODO
	
}

//native bool:FF2_HasAbility( index, const String:plugin_name[], const String:ability_name[] );
public Native_HasAbility(Handle:plugin, numParams)
{
	//TODO
	
}

//native bool:FF2_HasAbilityEx( index, const String:ability_name[], FF2_AbilityType:ability_type = FF2_Ability_Any );
public Native_HasAbilityEx(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_DoAbility(index, const String:plugin_name[], const String:ability_name[], charge_type, buttonmode = 0 );
public Native_DoAbility(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_DoAbilityEx(index, const String:ability_name[], charge_type, FF2_ButtonMode:buttonmode = FF2_ButtonMode_Taunt, FF2_AbilityType:ability_type = FF2_Ability_Any  );
public Native_DoAbilityEx(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetAbilityArgument( index, const String:plugin_name[], const String:ability_name[], argument, defvalue = 0 );
public Native_GetAbilityArgument(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetAbilityArgumentEx( index, const String:ability_name[], argument, defvalue = 0, FF2_AbilityType:type = FF2_Ability_Any );
public Native_GetAbilityArgumentEx(Handle:plugin, numParams)
{
	//TODO
	
}

//native Float:FF2_GetAbilityArgumentFloat( index, const String:plugin_name[], const String:ability_name[], argument, Float:defvalue = 0.0 );
public Native_GetAbilityArgumentFloat(Handle:plugin, numParams)
{
	//TODO
	
}

//native Float:FF2_GetAbilityArgumentFloatEx( index, const String:ability_name[], argument, Float:defvalue = 0.0, FF2_AbilityType:type = FF2_Ability_Any );
public Native_GetAbilityArgumentFloatEx(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetAbilityArgumentString( index, const String:plugin_name[], const String:ability_name[], argument, String:buffer[], bufferlen );
public Native_GetAbilityArgumentString(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetAbilityArgumentStringEx( index, const String:ability_name[], argument, String:buffer[], bufferlen, FF2_AbilityType:type = FF2_Ability_Any );
public Native_GetAbilityArgumentStringEx(Handle:plugin, numParams)
{
	//TODO
	
}

//native bool:FF2_RandomSound( const String: keyvalue[], String: str[], length, index = 0, slot = 0 );
public Native_RandomSound(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_StopMusic( client = 0 );
public Native_StopMusic(Handle:plugin, numParams)
{
	//TODO
	
}

//native Handle:FF2_GetSpecialKV( index = 0, isNumOfSpecial = 0 );
public Native_GetSpecialKV(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetFF2flags( client );
public Native_GetFF2flags(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_SetFF2flags( client, flags );
public Native_SetFF2flags(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetBossFlags( index = 0 );
public Native_GetBossFlags(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_SetBossFlags( index, flags );
public Native_SetBossFlags(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_GetQueuePoints( client );
public Native_GetQueuePoints(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_SetQueuePoints( client, value );
public Native_SetQueuePoints(Handle:plugin, numParams)
{
	//TODO
	
}

/*native FF2_EmitSoundToAllExcept( FF2_SoundExcept:exceptiontype = FF2_SoundExcept_Music,
				const String:sample[],
				entity = SOUND_FROM_PLAYER,
				channel = SNDCHAN_AUTO,
				level = SNDLEVEL_NORMAL,
				flags = SND_NOFLAGS,
				Float:volume = SNDVOL_NORMAL,
				pitch = SNDPITCH_NORMAL,
				speakerentity = -1,
				const Float:origin[3] = NULL_VECTOR,
				const Float:dir[3] = NULL_VECTOR,
				bool:updatePos = true,
				Float:soundtime = 0.0 );*/
public Native_EmitSoundToAllExcept(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_RegisterAbility( const String:ability_name[], default_slot=0, ParamType:... );
public Native_RegisterAbility(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_RegisterPassiveAbility( const String:ability_name[], ParamType:... );
public Native_RegisterPassiveAbility(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_UnregisterAbility( const String:ability_name[] );
public Native_UnregisterAbility(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_UnregisterAllAbilities();
public Native_UnregisterAllAbilities(Handle:plugin, numParams)
{
	//TODO
	
}

//native bool:FF2_IsAbilityRegistered( const String:ability_name[] );
public Native_IsAbilityRegistered(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_HookAbility( const String:ability_name[], FF2_Ability:callback, FF2_AbilityHookMode:mode = FF2_AbilityHookMode_Normal );
public Native_HookAbility(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_HookPassiveAbility( const String:ability_name[], FF2_ToggleAbility:callback );
public Native_HookPassiveAbility(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_UnhookAbility( const String:abilityName[], FF2_Ability:callback, FF2_AbilityHookMode:mode = FF2_AbilityHookMode_Normal );
public Native_UnhookAbility(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_UnhookPassiveAbility( const String:ability_name[], FF2_ToggleAbility:callback );
public Native_UnhookPassiveAbility(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_UnhookAllAbilities();
public Native_UnhookAllAbilities(Handle:plugin, numParams)
{
	//TODO
	
}

//native FF2_RegisterQueueManager(FF2_GetNextPlayers:nextPlayerFunc, FF2_GetPlayerPoints:getPlayerPointsFunc, FF2_GetPlayerPosition:getPlayerPositionFunc);
public Native_RegisterQueueManager(Handle:plugin, numParams)
{
	new Function:nextPlayers = GetNativeCell(1);
	new Function:playerPoints = GetNativeCell(2);
	new Function:playerPosition = GetNativeCell(3);
	
	AddToForward(g_Forward_GetNextPlayers, plugin, nextPlayers);
	AddToForward(g_Forward_GetPlayerPoints, plugin, playerPoints);
	AddToForward(g_Forward_GetPlayerPosition, plugin, playerPosition);
}

public Native_GetDatabaseHandle(Handle:plugin, numParams)
{
	return _:CloneHandle(g_hDb);
}
