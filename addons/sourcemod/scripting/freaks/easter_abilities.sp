#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define ME 2048

#define EF_BONEMERGE			(1<<0)
#define EF_BONEMERGE_FASTCULL	(1<<7)

#define PROJECTILE		"model_projectile_replace"
#define OBJECTS			"spawn_many_objects_on_kill"
#define OBJECTS_DEATH	"spawn_many_objects_on_death"

#define PLUGIN_VERSION "1.9.0"

//new Handle:hSetObjectVelocity;

public Plugin:myinfo=
{
	name="Freak Fortress 2: Easter Abilities",
	author="Powerlord and FlaminSarge, updated by Wliu",
	description="FF2: Abilities dealing with cosmetics and projectiles",
	version=PLUGIN_VERSION,
};

public OnPluginStart2()
{
	/*new Handle:hGameConf=LoadGameConfigFile("saxtonhale");
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
	CloseHandle(hGameConf);*/
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
	new boss=FF2_GetBossIndex(attacker);
	if(boss>-1 && FF2_HasAbility(boss, this_plugin_name, OBJECTS))
	{
		decl String:classname[64];
		decl String:model[64];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS, 1, classname, sizeof(classname));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS, 2, model, sizeof(model));
		new skin=FF2_GetAbilityArgument(boss, this_plugin_name, OBJECTS, 3);
		new count=FF2_GetAbilityArgument(boss, this_plugin_name, OBJECTS, 4, 14);
		new Float:distance=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, OBJECTS, 5, 30.0);
		SpawnManyObjects(classname, client, model, skin, count, distance);
		return;
	}

	boss=FF2_GetBossIndex(client);
	if(boss>-1 && FF2_HasAbility(boss, this_plugin_name, OBJECTS_DEATH))
	{
		decl String:classname[64];
		decl String:model[64];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS_DEATH, 1, classname, sizeof(classname));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS_DEATH, 2, model, sizeof(model));
		new skin=FF2_GetAbilityArgument(boss, this_plugin_name, OBJECTS_DEATH, 3);
		new count=FF2_GetAbilityArgument(boss, this_plugin_name, OBJECTS_DEATH, 4, 14);
		new Float:distance=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, OBJECTS_DEATH, 5, 30.0);
		SpawnManyObjects(classname, client, model, skin, count, distance);
		return;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(FF2_IsFF2Enabled() && FF2_GetRoundState()==1 && StrContains(classname, "tf_projectile")>=0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawned);
	}
}

public OnProjectileSpawned(entity)
{
	new owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(IsValidClient(owner))
	{
		new boss=FF2_GetBossIndex(owner);
		if(boss!=-1 && FF2_HasAbility(boss, this_plugin_name, PROJECTILE))
		{
			decl String:projectile[64];
			FF2_GetAbilityArgumentString(boss, this_plugin_name, PROJECTILE, 1, projectile, sizeof(projectile));

			decl String:classname[64];
			GetEntityClassname(entity, classname, sizeof(classname));
			if(StrEqual(classname, projectile, false))
			{
				decl String:model[PLATFORM_MAX_PATH];
				FF2_GetAbilityArgumentString(boss, this_plugin_name, PROJECTILE, 2, model, sizeof(model));
				PrecacheModel(model);
				SetEntityModel(entity, model);
			}
		}
	}
}

SpawnManyObjects(String:classname[], client, String:model[], skin=0, amount=14, Float:distance=30.0)
{
	/*if(hSetObjectVelocity==INVALID_HANDLE)
	{
		return;
	}*/

	decl Float:position[3], Float:velocity[3];
	new Float:angle[]={90.0, 0.0, 0.0};
	GetClientAbsOrigin(client, position);
	position[2]+=distance;
	for(new i=0; i<amount; i++)
	{
		velocity[0]=GetRandomFloat(-400.0, 400.0);
		velocity[1]=GetRandomFloat(-400.0, 400.0);
		velocity[2]=GetRandomFloat(300.0, 500.0);
		position[0]+=GetRandomFloat(-5.0, 5.0);
		position[1]+=GetRandomFloat(-5.0, 5.0);

		new entity=CreateEntityByName(classname);
		if(!IsValidEntity(entity))
		{
			continue;
		}

		SetEntityModel(entity, model);
		DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");	
		SetEntProp(entity, Prop_Send, "m_nSkin", skin);
		SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 152);
		SetEntProp(entity, Prop_Send, "m_triggerBloat", 24);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", 2);
		//TeleportEntity(entity, position, angle, velocity);
		DispatchSpawn(entity);
		TeleportEntity(entity, position, angle, velocity);
		//SDKCall(hSetObjectVelocity, entity, velocity);
		SetEntProp(entity, Prop_Data, "m_iHealth", 900);
		new offs=GetEntSendPropOffs(entity, "m_vecInitialVelocity", true);
		SetEntData(entity, offs-4, 1, _, true);
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

public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], action)
{
	//NOOP
}