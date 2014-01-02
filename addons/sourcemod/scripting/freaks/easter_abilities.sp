#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

// #define MB 5
#define ME 2048

#define EF_BONEMERGE			(1 << 0)
#define EF_BONEMERGE_FASTCULL	(1 << 7)

#define PROJECTILE		"model_projectile_replace"
#define OBJECTS			"spawn_many_objects_on_kill"
#define OBJECTS_DEATH	"spawn_many_objects_on_death"

#define PLUGIN_VERSION "1.0.8"

new Handle:hEquipWearable;
new Handle:hSetObjectVelocity;

public Plugin:myinfo=
{
	name="Freak Fortress 2: Easter Abilities",
	author="Powerlord and FlaminSarge",
	description="FF2: Abilities dealing with cosmetics and projectiles",
	version=PLUGIN_VERSION,
};

public OnPluginStart2()
{
	new Handle:hGameConf=LoadGameConfigFile("saxtonhale");
	if(hGameConf==INVALID_HANDLE)
	{
		SetFailState("[FF2 Model] Unable to load gamedata file 'saxtonhale.txt'");
		return;
	}

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFAmmoPack::SetInitialVelocity");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	hSetObjectVelocity=EndPrepSDKCall();
	if(hSetObjectVelocity==INVALID_HANDLE)
	{
		SetFailState("[FF2 Model] Failed to initialize call to CTFAmmoPack::SetInitialVelocity");
		CloseHandle(hGameConf);
		return;
	}
	CloseHandle(hGameConf);
	HookEvent("player_death", event_player_death);
}

public event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!FF2_IsFF2Enabled())
	{
		return;
	}

	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!IsValidClient(client) || !IsValidClient(attacker))
	{
		return;
	}

	//Attacker
	new index=FF2_GetBossIndex(attacker);
	if(index>-1 && FF2_HasAbility(index, this_plugin_name, OBJECTS))
	{
		decl String:classname[64];
		decl String:model[64];
		FF2_GetAbilityArgumentString(index, this_plugin_name, OBJECTS, 1, classname, sizeof(classname));
		FF2_GetAbilityArgumentString(index, this_plugin_name, OBJECTS, 2, model, sizeof(model));
		new skin=FF2_GetAbilityArgument(index, this_plugin_name, OBJECTS, 3, 0);
		new count=FF2_GetAbilityArgument(index, this_plugin_name, OBJECTS, 4, 14);
		new Float:distance=FF2_GetAbilityArgumentFloat(index, this_plugin_name, OBJECTS, 5, 30.0);
		SpawnManyObjects(classname, client, model, skin, count, distance);
		return;
	}
}

stock bool:IsValidClient(client, bool:replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}

public OnEntityCreated(entity, const String:classname[])
{
	if(FF2_IsFF2Enabled() && FF2_GetRoundState()==2 && StrContains(classname, "tf_projectile")>=0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawned);
	}
}

public OnProjectileSpawned(entity)
{
	new owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(IsValidClient(owner))
	{
		new index=FF2_GetBossIndex(owner);
		if(index!=-1 && FF2_HasAbility(index, this_plugin_name, PROJECTILE))
		{
			decl String:projectile[64];
			FF2_GetAbilityArgumentString(index, this_plugin_name, PROJECTILE, 0, projectile, sizeof(projectile));
			
			decl String:classname[64];
			GetEntityClassname(entity, classname, sizeof(classname));
			if(StrEqual(classname, projectile, false))
			{
				decl String:model[PLATFORM_MAX_PATH];
				FF2_GetAbilityArgumentString(index, this_plugin_name, PROJECTILE, 1, model, sizeof(model));
				new Handle:data;
				CreateDataTimer(0.0, Timer_SetProjectileModel, data, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(data, EntIndexToEntRef(entity));
				WritePackString(data, model);
				ResetPack(data);
			}
		}
	}
}

public Action:Timer_SetProjectileModel(Handle:timer, Handle:data)
{
	new entity=EntRefToEntIndex(ReadPackCell(data));
	decl String:model[64];
	ReadPackString(data, model, sizeof(model));
	if(FileExists(model, true) && IsModelPrecached(model) && IsValidEntity(entity))
	{
		new att=AttachProjectileModel(entity, model);
		SetEntProp(att, Prop_Send, "m_nSkin", 0);
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 0);
	}
}

stock CreateVM(client, String:model[])
{
	new ent=CreateEntityByName("tf_wearable_vm");
	if(!IsValidEntity(ent)) return -1;
	SetEntProp(ent, Prop_Send, "m_nModelIndex", PrecacheModel(model));
	SetEntProp(ent, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
	SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	SetEntProp(ent, Prop_Send, "m_usSolidFlags", 4);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 11);
	DispatchSpawn(ent);
	SetVariantString("!activator");
	ActivateEntity(ent);
	TF2_EquipWearable(client, ent);
	return ent;
}

stock TF2_EquipWearable(client, entity)
{
	SDKCall(hEquipWearable, client, entity);
}

stock AttachProjectileModel(entity, String:strModel[], String:strAnim[]="")
{
	if(!IsValidEntity(entity)) return -1;
	new model=CreateEntityByName("prop_dynamic");
	if(IsValidEdict(model))
	{
		decl Float:pos[3];
		decl Float:ang[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);
		TeleportEntity(model, pos, ang, NULL_VECTOR);
		DispatchKeyValue(model, "model", strModel);
		DispatchSpawn(model);
		SetVariantString("!activator");
		AcceptEntityInput(model, "SetParent", entity, model, 0);
		if(strAnim[0]!='\0')
		{
			SetVariantString(strAnim);
			AcceptEntityInput(model, "SetDefaultAnimation");
			SetVariantString(strAnim);
			AcceptEntityInput(model, "SetAnimation");
		}
		SetEntPropEnt(model, Prop_Send, "m_hOwnerEntity", entity);
		return model;
	} else {
		LogError("(AttachProjectileModel): Could not create prop_dynamic");
	}
	return -1;
}

stock SpawnManyHealthPacks()
{
	SpawnManyObjects("tf_health_kit", client, model, skin, num, offsz);
}

stock SpawnManyAmmoPacks()
{
	SpawnManyObjects("tf_ammo_pack", client, model, skin, num, offsz);
}

SpawnManyObjects(String:classname[], client, String:model[], skin=0, num=14, Float:offsz=30.0)
{
	if(hSetObjectVelocity==INVALID_HANDLE) return;
	decl Float:pos[3], Float:vel[3], Float:ang[3];
	ang[0]=90.0;
	ang[1]=0.0;
	ang[2]=0.0;
	GetClientAbsOrigin(client, pos);
	pos[2] += offsz;
	for(new i=0; i < num; i++)
	{
		vel[0]=GetRandomFloat(-400.0, 400.0);
		vel[1]=GetRandomFloat(-400.0, 400.0);
		vel[2]=GetRandomFloat(300.0, 500.0);
		pos[0] += GetRandomFloat(-5.0, 5.0);
		pos[1] += GetRandomFloat(-5.0, 5.0);
		new ent=CreateEntityByName(classname);
		if(!IsValidEntity(ent)) continue;
		SetEntityModel(ent, model);
		DispatchKeyValue(ent, "OnPlayerTouch", "!self,Kill,,0,-1");	//for safety, but it shouldn't act like a normal ammopack
		SetEntProp(ent, Prop_Send, "m_nSkin", skin);
		SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
//		SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);
//		SetEntProp(ent, Prop_Send, "movetype", 5);
//		SetEntProp(ent, Prop_Send, "movecollide", 0);
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 152);
		SetEntProp(ent, Prop_Send, "m_triggerBloat", 24);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(ent, Prop_Send, "m_iTeamNum", 2);
		TeleportEntity(ent, pos, ang, vel);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, vel);
		SDKCall(hSetObjectVelocity, ent, vel);
		SetEntProp(ent, Prop_Data, "m_iHealth", 900);
		new offs=GetEntSendPropOffs(ent, "m_vecInitialVelocity", true);
		SetEntData(ent, offs-4, 1, _, true);
/*		SetEntData(ent, offs-13, 0, 1, true);
		SetEntData(ent, offs-11, 1, 1, true);
		SetEntData(ent, offs-15, 1, 1, true);
		SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);
		SetEntProp(ent, Prop_Data, "m_nNextThinkTick", GetEntProp(client, Prop_Send, "m_nTickBase") + 3);
		SetEntPropVector(ent, Prop_Data, "m_vecAbsVelocity", vel);
		SetEntPropVector(ent, Prop_Data, "m_vecVelocity", vel);
		SetEntPropVector(ent, Prop_Send, "m_vecInitialVelocity", vel);
		SetEntProp(ent, Prop_Send, "m_bClientSideAnimation", 1);
		PrintToChatAll("aeiou %d %d %d %d %d", GetEntData(ent, offs-16, 1), GetEntData(ent, offs-15, 1), GetEntData(ent, offs-14, 1), GetEntData(ent, offs-13, 1), GetEntData(ent, offs-12, 1));
		*/
	}
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	// No active abilities...
}
