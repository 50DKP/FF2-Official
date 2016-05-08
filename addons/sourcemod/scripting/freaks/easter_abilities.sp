#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define PROJECTILE		"model_projectile_replace"
#define OBJECTS			"spawn_many_objects_on_kill"
#define OBJECTS_DEATH	"spawn_many_objects_on_death"

#define PLUGIN_VERSION "1.10.7"

public Plugin:myinfo=
{
	name="Freak Fortress 2: Easter Abilities",
	author="Powerlord and FlaminSarge, updated by Wliu",
	description="FF2: Abilities dealing with cosmetics and projectiles",
	version=PLUGIN_VERSION,
};

public OnPluginStart2()
{
	HookEvent("player_death", OnPlayerDeath);
	PrecacheSound("items/pumpkin_pickup.wav");
}

/*public Action:FF2_OnSpecialSelected(boss, &special, String:specialName[])  //Re-enable in v2 or whenever the late-loading forward bug is fixed
{
	if(FF2_HasAbility(boss, this_plugin_name, OBJECTS))
	{
		decl String:model[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS, 2, model, sizeof(model));
		PrecacheModel(model);
	}
	else if(FF2_HasAbility(boss, this_plugin_name, OBJECTS_DEATH))
	{
		decl String:model[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS_DEATH, 2, model, sizeof(model));
		PrecacheModel(model);
	}
	return Plugin_Continue;
}*/

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!client || !attacker || !IsClientInGame(client) || !IsClientInGame(attacker))
	{
		return;
	}

	new boss=FF2_GetBossIndex(attacker);
	if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, OBJECTS))
	{
		decl String:classname[PLATFORM_MAX_PATH], String:model[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS, 1, classname, sizeof(classname));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS, 2, model, sizeof(model));
		new skin=FF2_GetAbilityArgument(boss, this_plugin_name, OBJECTS, 3);
		new count=FF2_GetAbilityArgument(boss, this_plugin_name, OBJECTS, 4, 14);
		new Float:distance=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, OBJECTS, 5, 30.0);
		SpawnManyObjects(classname, client, model, skin, count, distance);
		return;
	}

	boss=FF2_GetBossIndex(client);
	if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, OBJECTS_DEATH))
	{
		decl String:classname[PLATFORM_MAX_PATH], String:model[PLATFORM_MAX_PATH];
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
	if(IsValidEntity(entity) && StrContains(classname, "tf_projectile")>=0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawned);
	}
}

public OnProjectileSpawned(entity)
{
	new client=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client>0 && client<=MaxClients && IsClientInGame(client))
	{
		new boss=FF2_GetBossIndex(client);
		if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, PROJECTILE))
		{
			decl String:projectile[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(boss, this_plugin_name, PROJECTILE, 1, projectile, sizeof(projectile));

			decl String:classname[PLATFORM_MAX_PATH];
			GetEntityClassname(entity, classname, sizeof(classname));
			if(StrEqual(classname, projectile, false))
			{
				decl String:model[PLATFORM_MAX_PATH];
				FF2_GetAbilityArgumentString(boss, this_plugin_name, PROJECTILE, 2, model, sizeof(model));
				if(IsModelPrecached(model))
				{
					SetEntityModel(entity, model);
				}
				else
				{
					decl String:bossName[64];
					FF2_GetBossSpecial(boss, bossName, sizeof(bossName));
					LogError("[FF2 Bosses] Model %s (used by boss %s for ability %s) isn't precached!", model, bossName, PROJECTILE);
				}
			}
		}
	}
}

SpawnManyObjects(String:classname[], client, String:model[], skin=0, amount=14, Float:distance=30.0)
{
	if(!client || !IsClientInGame(client))
	{
		return;
	}

	new Float:position[3], Float:velocity[3];
	new Float:angle[]={90.0, 0.0, 0.0};
	GetClientAbsOrigin(client, position);
	position[2]+=distance;
	for(new i; i<amount; i++)
	{
		velocity[0]=GetRandomFloat(-400.0, 400.0);
		velocity[1]=GetRandomFloat(-400.0, 400.0);
		velocity[2]=GetRandomFloat(300.0, 500.0);
		position[0]+=GetRandomFloat(-5.0, 5.0);
		position[1]+=GetRandomFloat(-5.0, 5.0);

		new entity=CreateEntityByName(classname);
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
		new offs=GetEntSendPropOffs(entity, "m_vecInitialVelocity", true);
		SetEntData(entity, offs-4, 1, _, true);
	}
}

public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], action)
{
	//NOOP
}