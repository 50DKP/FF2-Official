#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>

#pragma newdecls required

#define PROJECTILE		"replace projectile model"
#define OBJECTS			"spawn many objects on kill"
#define OBJECTS_DEATH	"spawn many objects on death"

#define PLUGIN_NAME "easter abilities"
#define PLUGIN_VERSION "2.0.0"

public Plugin myinfo=
{
	name="Freak Fortress 2: Easter Abilities",
	author="Powerlord and FlaminSarge, updated by Wliu",
	description="FF2: Abilities dealing with cosmetics and projectiles",
	version=PLUGIN_VERSION,
};

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
	PrecacheSound("items/pumpkin_pickup.wav");

	FF2_RegisterSubplugin(PLUGIN_NAME);
}

/*public Action FF2_OnBossSelected(int boss, int& special, char[] specialName)  //Re-enable in v2 or whenever the late-loading forward bug is fixed
{
	if(FF2_HasAbility(boss, PLUGIN_NAME, OBJECTS))
	{
		char model[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, OBJECTS, "model", model, sizeof(model));
		PrecacheModel(model);
	}
	else if(FF2_HasAbility(boss, PLUGIN_NAME, OBJECTS_DEATH))
	{
		char model[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, OBJECTS_DEATH, "model", model, sizeof(model));
		PrecacheModel(model);
	}
	return Plugin_Continue;
}*/

public void OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!client || !attacker || !IsClientInGame(client) || !IsClientInGame(attacker))
	{
		return;
	}

	int boss=FF2_GetBossIndex(attacker);
	if(boss!=-1 && FF2_HasAbility(boss, PLUGIN_NAME, OBJECTS))
	{
		char classname[PLATFORM_MAX_PATH], model[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, OBJECTS, "classname", classname, sizeof(classname));
		FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, OBJECTS, "model", model, sizeof(model));
		int skin=FF2_GetAbilityArgument(boss, PLUGIN_NAME, OBJECTS, "skin");
		int count=FF2_GetAbilityArgument(boss, PLUGIN_NAME, OBJECTS, "count", 14);
		float distance=FF2_GetAbilityArgumentFloat(boss, PLUGIN_NAME, OBJECTS, "distance", 30.0);
		SpawnManyObjects(classname, client, model, skin, count, distance);
		return;
	}

	boss=FF2_GetBossIndex(client);
	if(boss!=-1 && FF2_HasAbility(boss, PLUGIN_NAME, OBJECTS_DEATH))
	{
		char classname[PLATFORM_MAX_PATH], model[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, OBJECTS_DEATH, "classname", classname, sizeof(classname));
		FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, OBJECTS_DEATH, "model", model, sizeof(model));
		int skin=FF2_GetAbilityArgument(boss, PLUGIN_NAME, OBJECTS_DEATH, "skin");
		int count=FF2_GetAbilityArgument(boss, PLUGIN_NAME, OBJECTS_DEATH, "count", 14);
		float distance=FF2_GetAbilityArgumentFloat(boss, PLUGIN_NAME, OBJECTS_DEATH, "distance", 30.0);
		SpawnManyObjects(classname, client, model, skin, count, distance);
		return;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(FF2_IsFF2Enabled() && IsValidEntity(entity) && StrContains(classname, "tf_projectile")>=0)
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
		if(boss>=0 && FF2_HasAbility(boss, PLUGIN_NAME, PROJECTILE))
		{
			char projectile[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, PROJECTILE, "classname", projectile, sizeof(projectile));

			char classname[PLATFORM_MAX_PATH];
			GetEntityClassname(entity, classname, sizeof(classname));
			if(StrEqual(classname, projectile, false))
			{
				char model[PLATFORM_MAX_PATH];
				FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, PROJECTILE, "model", model, sizeof(model));
				if(IsModelPrecached(model))
				{
					SetEntityModel(entity, model);
				}
				else
				{
					char bossName[64];
					FF2_GetBossName(boss, bossName, sizeof(bossName));
					LogError("[FF2 Easter Abilities] Model %s (used by boss %s for ability %s) isn't precached!", model, bossName, PROJECTILE);
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
			LogError("[FF2 Easter Abilities] Invalid entity while spawning classname %s-check your configs!", classname);
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
