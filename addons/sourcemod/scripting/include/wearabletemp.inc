/* TEMPORARY STUFF FOR TF2 WEARABLES; TO BE REMOVED AS SOON AS SOURCEMOD ADDS WEARABLE SUPPORT */
//Created by friagram
new Handle:hRemoveWearable=INVALID_HANDLE; 
new Handle:hEquipWearable=INVALID_HANDLE; 
new Handle:hIsWearable=INVALID_HANDLE;

stock TF2_RemoveWearable(client, wearable) 
{
	if(hRemoveWearable==INVALID_HANDLE)	
	{
		new Handle:hGameConfigtemp=LoadGameConfigFile("equipwearable");
		if(hGameConfigtemp==INVALID_HANDLE)
		{
			LogError("[FF2] EquipWearable gamedata could not be found; make sure /gamedata/equipwearable.txt exists.");
			PrintToServer("[FF2] WARNING: Using legacy method of removing wearables, VISUAL GLITCHES MAY OCCUR!");
			AcceptEntityInput(wearable, "kill");
			return;
		}

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConfigtemp, SDKConf_Virtual, "RemoveWearable");
		CloseHandle(hGameConfigtemp);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		if((hRemoveWearable=EndPrepSDKCall())==INVALID_HANDLE)
		{
			LogError("[FF2] Couldn't load SDK functions (CTFPlayer::RemoveWearable). SDK call failed.");
			PrintToServer("[FF2] WARNING: Using legacy method of removing wearables, VISUAL GLITCHES MAY OCCUR!");
			AcceptEntityInput(wearable, "kill");
			return;
		}
	}
	SDKCall(hRemoveWearable, client, wearable);
}

stock TF2_EquipWearable(client, wearable)
{
	if(hEquipWearable==INVALID_HANDLE)
	{
		new Handle:hGameConfigtemp=LoadGameConfigFile("equipwearable");
		if(hGameConfigtemp==INVALID_HANDLE)
		{
			LogError("[FF2] EquipWearable gamedata could not be found; make sure /gamedata/equipwearable.txt exists.");
			PrintToServer("[FF2] WARNING: Using legacy method of removing wearables, VISUAL GLITCHES MAY OCCUR!");
			AcceptEntityInput(wearable, "kill");
			return;
		}

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConfigtemp, SDKConf_Virtual, "EquipWearable");
		CloseHandle(hGameConfigtemp);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		if((hEquipWearable=EndPrepSDKCall())==INVALID_HANDLE)
		{
			LogError("[FF2] Couldn't load SDK functions (CTFPlayer::EquipWearable). SDK call failed.");
			PrintToServer("[FF2] WARNING: Using legacy method of removing wearables, VISUAL GLITCHES MAY OCCUR!");
			AcceptEntityInput(wearable, "kill");
			return;
		}
	}
	SDKCall(hEquipWearable, client, wearable);
} 

stock TF2_IsWearable(wearable)
{
	if(hIsWearable==INVALID_HANDLE)	
	{
		new Handle:hGameConfigtemp=LoadGameConfigFile("equipwearable");
		if(hGameConfigtemp==INVALID_HANDLE)
		{
			LogError("[FF2] EquipWearable gamedata could not be found; make sure /gamedata/equipwearable.txt exists.");
			PrintToServer("[FF2] WARNING: Using legacy method of removing wearables, VISUAL GLITCHES MAY OCCUR!");
			AcceptEntityInput(wearable, "kill");
			return false;
		}

		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGameConfigtemp, SDKConf_Virtual, "IsWearable");
		CloseHandle(hGameConfigtemp);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		if((hIsWearable=EndPrepSDKCall())==INVALID_HANDLE)
		{
			LogError("[FF2] Couldn't load SDK functions (CTFPlayer::IsWearable). SDK call failed.");
			PrintToServer("[FF2] WARNING: Using legacy method of removing wearables, VISUAL GLITCHES MAY OCCUR!");
			AcceptEntityInput(wearable, "kill");
			return false;
		}
	}
	return SDKCall(hIsWearable, wearable);
}

stock TF2_RemoveWeaponSlot2(client, slot)
{
	decl wearable;
	new weaponIndex;
	while((weaponIndex=GetPlayerWeaponSlot(client, slot))!=-1)
	{
		wearable=GetEntPropEnt(weaponIndex, Prop_Send, "m_hExtraWearable");
		if(IsValidEntity(wearable))
		{
			TF2_RemoveWearable(client, wearable);
		}
		RemovePlayerItem(client, weaponIndex);
		AcceptEntityInput(weaponIndex, "Kill");
	}
}