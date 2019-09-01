#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

#define PROJECTILE		"model_projectile_replace"
#define OBJECTS			"spawn_many_objects_on_kill"
#define OBJECTS_DEATH	"spawn_many_objects_on_death"

#define PLUGIN_VERSION "1.10.8"

public Plugin myinfo=
{
	name="Freak Fortress 2: Easter Abilities",
	author="Powerlord and FlaminSarge, updated by Wliu",
	description="FF2: Abilities dealing with cosmetics and projectiles",
	version=PLUGIN_VERSION,
};

public void OnPluginStart2()
{
	HookEvent("player_death", OnPlayerDeath);
	PrecacheSound("items/pumpkin_pickup.wav");
}

public void OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!client || !attacker || !IsClientInGame(client) || !IsClientInGame(attacker))
	{
		return;
	}

	int boss=FF2_GetBossIndex(attacker);
	if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, OBJECTS))
	{
		char classname[PLATFORM_MAX_PATH], model[PLATFORM_MAX_PATH];
		FF2_GetArgS(boss, this_plugin_name, OBJECTS, "classname", 1, classname, sizeof(classname));
		FF2_GetArgS(boss, this_plugin_name, OBJECTS, "model", 2, model, sizeof(model));
		int skin=FF2_GetArgI(boss, this_plugin_name, OBJECTS, "skin", 3);
		int count=FF2_GetArgI(boss, this_plugin_name, OBJECTS, "amount", 4, 14);
		float distance=FF2_GetArgF(boss, this_plugin_name, OBJECTS, "distance", 5, 30.0);
		SpawnManyObjects(classname, client, model, skin, count, distance);
		return;
	}

	boss=FF2_GetBossIndex(client);
	if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, OBJECTS_DEATH))
	{
		char classname[PLATFORM_MAX_PATH], model[PLATFORM_MAX_PATH];
		FF2_GetArgS(boss, this_plugin_name, OBJECTS_DEATH, "classname", 1, classname, sizeof(classname));
		FF2_GetArgS(boss, this_plugin_name, OBJECTS_DEATH, "model", 2, model, sizeof(model));
		int skin=FF2_GetArgI(boss, this_plugin_name, OBJECTS_DEATH, "skin", 3);
		int count=FF2_GetArgI(boss, this_plugin_name, OBJECTS_DEATH, "amount", 4, 14);
		float distance=FF2_GetArgF(boss, this_plugin_name, OBJECTS_DEATH, "distance", 5, 30.0);
		SpawnManyObjects(classname, client, model, skin, count, distance);
		return;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(IsValidEntity(entity) && StrContains(classname, "tf_projectile")>=0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawned);
	}
}

public void OnProjectileSpawned(int entity)
{
	int client=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client>0 && client<=MaxClients && IsClientInGame(client))
	{
		int boss=FF2_GetBossIndex(client);
		if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, PROJECTILE))
		{
			char projectile[PLATFORM_MAX_PATH];
			FF2_GetArgS(boss, this_plugin_name, PROJECTILE, "classname", 1, projectile, sizeof(projectile));

			char classname[PLATFORM_MAX_PATH];
			GetEntityClassname(entity, classname, sizeof(classname));
			if(StrEqual(classname, projectile, false))
			{
				char model[PLATFORM_MAX_PATH];
				FF2_GetArgS(boss, this_plugin_name, PROJECTILE, "model", 2, model, sizeof(model));
				if(model[0]=='\0')
				{
					char bossName[64];
					FF2_GetBossSpecial(boss, bossName, sizeof(bossName));
					LogError("[FF2 Bosses] Empty model string (used by boss %s for ability %s)!", bossName, PROJECTILE);
					return;
				}
				if(IsModelPrecached(model))
				{
					SetEntityModel(entity, model);
				}
				else
				{
					char bossName[64];
					FF2_GetBossSpecial(boss, bossName, sizeof(bossName));
					LogError("[FF2 Bosses] Model %s (used by boss %s for ability %s) isn't precached!", model, bossName, PROJECTILE);
				}
			}
		}
	}
}

void SpawnManyObjects(char[] classname, int client, char[] model, int skin=0, int amount=14, float distance=30.0)
{
	if(!client || !IsClientInGame(client))
	{
		return;
	}

	float position[3], velocity[3];
	float angle[]={90.0, 0.0, 0.0};
	GetClientAbsOrigin(client, position);
	position[2]+=distance;
	for(int i; i<amount; i++)
	{
		velocity[0]=GetRandomFloat(-400.0, 400.0);
		velocity[1]=GetRandomFloat(-400.0, 400.0);
		velocity[2]=GetRandomFloat(300.0, 500.0);
		position[0]+=GetRandomFloat(-5.0, 5.0);
		position[1]+=GetRandomFloat(-5.0, 5.0);

		int entity=CreateEntityByName(classname);
		if(!IsValidEntity(entity))
		{
			LogError("[FF2] Invalid entity while spawning objects for Easter Abilities-check your configs!");
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
		DispatchSpawn(entity);
		TeleportEntity(entity, position, angle, velocity);
		SetEntProp(entity, Prop_Data, "m_iHealth", 900);
		int offs=GetEntSendPropOffs(entity, "m_vecInitialVelocity", true);
		SetEntData(entity, offs-4, 1, _, true);
	}
}

public Action FF2_OnAbility2(int index, const char[] plugin_name, const char[] ability_name, int action)
{
	//NOOP
}