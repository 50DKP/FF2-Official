#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>

#pragma newdecls required

#define PLUGIN_NAME "default abilities"
#define PLUGIN_VERSION "2.0.0"

public Plugin myinfo=
{
	name="Freak Fortress 2: Default Abilities",
	author="RainBolt Dash",
	description="FF2: Common abilities used by all bosses",
	version=PLUGIN_VERSION,
};

Handle OnSuperJump;
Handle OnRage;
Handle OnWeighdown;

Handle gravityDatapack[MAXPLAYERS+1];

Handle jumpHUD;

bool enableSuperDuperJump[MAXPLAYERS+1];
float UberRageCount[MAXPLAYERS+1];
TFTeam BossTeam=TFTeam_Blue;

ConVar cvarOldJump;
ConVar cvarBaseJumperStun;

bool oldJump;
bool removeBaseJumperOnStun;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	OnSuperJump=CreateGlobalForward("FF2_OnSuperJump", ET_Hook, Param_Cell, Param_CellByRef);  //Boss, super duper jump
	OnRage=CreateGlobalForward("FF2_OnRage", ET_Hook, Param_Cell, Param_CellByRef);  //Boss, distance
	OnWeighdown=CreateGlobalForward("FF2_OnWeighdown", ET_Hook, Param_Cell);  //Boss
	return APLRes_Success;
}

public void OnPluginStart()
{
	cvarOldJump=CreateConVar("ff2_oldjump", "0", "Use old VSH jump equations", _, true, 0.0, true, 1.0);
	cvarBaseJumperStun=CreateConVar("ff2_base_jumper_stun", "0", "Whether or not the Base Jumper should be disabled when a player gets stunned", _, true, 0.0, true, 1.0);

	cvarOldJump.AddChangeHook(CvarChange);
	cvarBaseJumperStun.AddChangeHook(CvarChange);

	jumpHUD=CreateHudSynchronizer();

	HookEvent("object_deflected", OnDeflect, EventHookMode_Pre);
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("player_death", OnPlayerDeath);

	LoadTranslations("freak_fortress_2.phrases");

	AutoExecConfig(true, "default_abilities", "sourcemod/freak_fortress_2");

	FF2_RegisterSubplugin(PLUGIN_NAME);
}

public void OnConfigsExecuted()
{
	oldJump=cvarOldJump.BoolValue;
	removeBaseJumperOnStun=cvarBaseJumperStun.BoolValue;
}

public void CvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar==cvarOldJump)
	{
		oldJump=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarBaseJumperStun)
	{
		removeBaseJumperOnStun=view_as<bool>(StringToInt(newValue));
	}
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(FF2_IsFF2Enabled())
	{
		for(int client; client<MaxClients; client++)
		{
			enableSuperDuperJump[client]=false;
			UberRageCount[client]=0.0;
		}

		CreateTimer(0.3, Timer_GetBossTeam, _, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(9.11, StartBossTimer, _, TIMER_FLAG_NO_MAPCHANGE);  //TODO: Investigate.
	}
	return Plugin_Continue;
}

public Action StartBossTimer(Handle timer)  //TODO: What.
{
	for(int boss; FF2_GetBossUserId(boss)!=-1; boss++)
	{
		if(FF2_HasAbility(boss, PLUGIN_NAME, "teleport"))
		{
			FF2_SetBossCharge(boss, FF2_GetAbilityArgument(boss, PLUGIN_NAME, "teleport", "slot", 1), -1.0*FF2_GetAbilityArgumentFloat(boss, PLUGIN_NAME, "teleport", "cooldown", 5.0));
		}
	}
}

public Action Timer_GetBossTeam(Handle timer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public void FF2_OnAbility(int boss, const char[] pluginName, const char[] abilityName, int slot, int status)
{
	if(!StrEqual(pluginName, PLUGIN_NAME, false))
	{
		return;
	}

	if(!slot)  //Rage
	{
		if(!boss)  //Boss indexes are just so amazing
		{
			int distance=FF2_GetBossRageDistance(boss, PLUGIN_NAME, abilityName);
			int newDistance=distance;

			Action action;
			Call_StartForward(OnRage);
			Call_PushCell(boss);
			Call_PushCellRef(newDistance);
			Call_Finish(action);
			if(action==Plugin_Handled || action==Plugin_Stop)
			{
				return;
			}
			else if(action==Plugin_Changed)
			{
				distance=newDistance;  //FIXME: This is...useless.
			}
		}
	}

	if(StrEqual(abilityName, "weightdown", false))
	{
		Charge_WeighDown(boss, slot);
	}
	else if(StrEqual(abilityName, "bravejump", false))
	{
		Charge_BraveJump(abilityName, boss, slot, status);
	}
	else if(StrEqual(abilityName, "teleport", false))
	{
		Charge_Teleport(abilityName, boss, slot, status);
	}
	else if(StrEqual(abilityName, "uber", false))
	{
		int client=GetClientOfUserId(FF2_GetBossUserId(boss));
		TF2_AddCondition(client, TFCond_Ubercharged, FF2_GetAbilityArgumentFloat(boss, PLUGIN_NAME, abilityName, "duration", 5.0));
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		CreateTimer(FF2_GetAbilityArgumentFloat(boss, PLUGIN_NAME, abilityName, "duration", 5.0), Timer_StopUber, boss, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(StrEqual(abilityName, "stun", false))
	{
		Rage_Stun(abilityName, boss);
	}
	else if(StrEqual(abilityName, "stun sentry gun", false))
	{
		Rage_StunSentry(abilityName, boss);
	}
	else if(StrEqual(abilityName, "instant teleport", false))
	{
		int client=GetClientOfUserId(FF2_GetBossUserId(boss));
		float position[3];
		bool otherTeamIsAlive;

		for(int target=1; target<=MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target) && target!=client && !(FF2_GetFF2Flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
			{
				otherTeamIsAlive=true;
				break;
			}
		}

		if(!otherTeamIsAlive)
		{
			return;
		}

		int target, tries;
		do
		{
			tries++;
			target=GetRandomInt(1, MaxClients);
			if(tries==100)
			{
				return;
			}
		}
		while(!IsValidEntity(target) || target==client || (FF2_GetFF2Flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM) || !IsPlayerAlive(target));

		GetEntPropVector(target, Prop_Data, "m_vecOrigin", position);
		TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
		TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, client);
	}
}

void Rage_Stun(const char[] abilityName, int boss)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	float bossPosition[3], targetPosition[3];
	float duration=FF2_GetAbilityArgumentFloat(boss, PLUGIN_NAME, abilityName, "duration", 5.0);
	int distance=FF2_GetBossRageDistance(boss, PLUGIN_NAME, abilityName);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);

	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && TF2_GetClientTeam(target)!=BossTeam)
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition);
			if(!TF2_IsPlayerInCondition(target, TFCond_Ubercharged) && (GetVectorDistance(bossPosition, targetPosition)<=distance))
			{
				if(removeBaseJumperOnStun)
				{
					TF2_RemoveCondition(target, TFCond_Parachute);
				}
				TF2_StunPlayer(target, duration, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, client);
				CreateTimer(duration, RemoveEntity, EntIndexToEntRef(AttachParticle(target, "yikes_fx", 75.0)), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action Timer_StopUber(Handle timer, int boss)
{
	SetEntProp(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Data, "m_takedamage", 2);
	return Plugin_Continue;
}

void Rage_StunSentry(const char[] abilityName, int boss)
{
	float bossPosition[3], sentryPosition[3];
	GetEntPropVector(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Send, "m_vecOrigin", bossPosition);
	float duration=FF2_GetAbilityArgumentFloat(boss, PLUGIN_NAME, abilityName, "duration", 7.0);
	int distance=FF2_GetBossRageDistance(boss, PLUGIN_NAME, abilityName);

	int sentry;
	while((sentry=FindEntityByClassname(sentry, "obj_sentrygun"))!=-1)
	{
		GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentryPosition);
		if(GetVectorDistance(bossPosition, sentryPosition)<=distance)
		{
			SetEntProp(sentry, Prop_Send, "m_bDisabled", 1);
			CreateTimer(duration, RemoveEntity, EntIndexToEntRef(AttachParticle(sentry, "yikes_fx", 75.0)), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(duration, Timer_EnableSentry, EntIndexToEntRef(sentry), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_EnableSentry(Handle timer, int sentryid)
{
	int sentry=EntRefToEntIndex(sentryid);
	if(FF2_GetRoundState()==1 && sentry>MaxClients)
	{
		SetEntProp(sentry, Prop_Send, "m_bDisabled", 0);
	}
	return Plugin_Continue;
}

void Charge_BraveJump(const char[] abilityName, int boss, int slot, int status)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	float charge=FF2_GetBossCharge(boss, slot);
	float multiplier=FF2_GetAbilityArgumentFloat(boss, PLUGIN_NAME, abilityName, "multiplier", 1.0);

	switch(status)
	{
		case 1:
		{
			SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, jumpHUD, "%t", "Super Jump Cooldown", -RoundFloat(charge));
		}
		case 2:
		{
			SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
			if(enableSuperDuperJump[boss])
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 64, 64, 255);
				FF2_ShowSyncHudText(client, jumpHUD, "%t", "Super Duper Jump");
			}
			else
			{
				FF2_ShowSyncHudText(client, jumpHUD, "%t", "Super Jump Charge", RoundFloat(charge));
			}
		}
		case 3:
		{
			bool superJump=enableSuperDuperJump[boss];
			Action action;
			Call_StartForward(OnSuperJump);
			Call_PushCell(boss);
			Call_PushCellRef(superJump);
			Call_Finish(action);
			if(action==Plugin_Handled || action==Plugin_Stop)
			{
				return;
			}
			else if(action==Plugin_Changed)
			{
				enableSuperDuperJump[client]=superJump;
			}

			float position[3], velocity[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

			if(oldJump)
			{
				if(enableSuperDuperJump[boss])
				{
					velocity[2]=750+(charge/4)*13.0+2000;
					enableSuperDuperJump[boss]=false;
				}
				else
				{
					velocity[2]=750+(charge/4)*13.0;
				}
				SetEntProp(client, Prop_Send, "m_bJumping", 1);
				velocity[0]*=(1+Sine((charge/4)*FLOAT_PI/50));
				velocity[1]*=(1+Sine((charge/4)*FLOAT_PI/50));
			}
			else
			{
				float angles[3];
				GetClientEyeAngles(client, angles);
				if(enableSuperDuperJump[boss])
				{
					velocity[0]+=Cosine(DegToRad(angles[0]))*Cosine(DegToRad(angles[1]))*500*multiplier;
					velocity[1]+=Cosine(DegToRad(angles[0]))*Sine(DegToRad(angles[1]))*500*multiplier;
					velocity[2]=(750.0+175.0*charge/70+2000)*multiplier;
					enableSuperDuperJump[boss]=false;
				}
				else
				{
					velocity[0]+=Cosine(DegToRad(angles[0]))*Cosine(DegToRad(angles[1]))*100*multiplier;
					velocity[1]+=Cosine(DegToRad(angles[0]))*Sine(DegToRad(angles[1]))*100*multiplier;
					velocity[2]=(750.0+175.0*charge/70)*multiplier;
				}
			}

			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
			char sound[PLATFORM_MAX_PATH];
			if(FF2_FindSound("ability", sound, sizeof(sound), boss, true, slot))
			{
				if(FF2_CheckSoundFlags(client, FF2SOUND_MUTEVOICE))
				{
					EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
					EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
				}

				for(int target=1; target<=MaxClients; target++)
				{
					if(IsClientInGame(target) && target!=client && FF2_CheckSoundFlags(target, FF2SOUND_MUTEVOICE))
					{
						EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
						EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
					}
				}
			}
		}
	}
}

void Charge_Teleport(const char[] abilityName, int boss, int slot, int status)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	float charge=FF2_GetBossCharge(boss, slot);
	switch(status)
	{
		case 1:
		{
			SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, jumpHUD, "%t", "Teleportation Cooldown", -RoundFloat(charge));
		}
		case 2:
		{
			SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, jumpHUD, "%t", "Teleportation Charge", RoundFloat(charge));
		}
		case 3:
		{
			Action action;
			bool superJump=enableSuperDuperJump[boss];
			Call_StartForward(OnSuperJump);
			Call_PushCell(boss);
			Call_PushCellRef(superJump);
			Call_Finish(action);
			if(action==Plugin_Handled || action==Plugin_Stop)
			{
				return;
			}
			else if(action==Plugin_Changed)
			{
				enableSuperDuperJump[boss]=superJump;
			}

			if(enableSuperDuperJump[boss])
			{
				enableSuperDuperJump[boss]=false;
			}
			else if(charge<100)
			{
				CreateTimer(0.1, Timer_ResetCharge, boss*10000+slot, TIMER_FLAG_NO_MAPCHANGE);  //FIXME: Investigate.
				return;
			}

			int tries;
			bool otherTeamIsAlive;
			for(int target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && IsPlayerAlive(target) && target!=client && !(FF2_GetFF2Flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
				{
					otherTeamIsAlive=true;
					break;
				}
			}

			int target;
			do
			{
				tries++;
				target=GetRandomInt(1, MaxClients);
				if(tries==100)
				{
					return;
				}
			}
			while(otherTeamIsAlive && (!IsValidEntity(target) || target==client || (FF2_GetFF2Flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM) || !IsPlayerAlive(target)));

			char particle[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, abilityName, "particle", particle, sizeof(particle));
			if(strlen(particle)>0)
			{
				CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(client, particle)), TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(client, particle, _, false)), TIMER_FLAG_NO_MAPCHANGE);
			}

			float position[3];
			GetEntPropVector(target, Prop_Data, "m_vecOrigin", position);
			if(IsValidEntity(target))
			{
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", position);
				SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + (enableSuperDuperJump ? 4.0:2.0));
				if(GetEntProp(target, Prop_Send, "m_bDucked"))
				{
					float temp[3]={24.0, 24.0, 62.0};  //Compiler won't accept directly putting it into SEPV -.-
					SetEntPropVector(client, Prop_Send, "m_vecMaxs", temp);
					SetEntProp(client, Prop_Send, "m_bDucked", 1);
					SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
					CreateTimer(0.2, Timer_StunBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
				}
				else
				{
					TF2_StunPlayer(client, (enableSuperDuperJump ? 4.0 : 2.0), 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, target);
				}

				TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
				if(strlen(particle)>0)
				{
					CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(client, particle)), TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(client, particle, _, false)), TIMER_FLAG_NO_MAPCHANGE);
				}
			}

			char sound[PLATFORM_MAX_PATH];
			if(FF2_FindSound("ability", sound, sizeof(sound), boss, true, slot))
			{
				if(FF2_CheckSoundFlags(client, FF2SOUND_MUTEVOICE))
				{
					EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
					EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
				}

				for(int enemy=1; enemy<=MaxClients; enemy++)
				{
					if(IsClientInGame(enemy) && enemy!=client && FF2_CheckSoundFlags(enemy, FF2SOUND_MUTEVOICE))
					{
						EmitSoundToClient(enemy, sound, client, _, _, _, _, _, client, position);
						EmitSoundToClient(enemy, sound, client, _, _, _, _, _, client, position);
					}
				}
			}
		}
	}
}

public Action Timer_ResetCharge(Handle timer, int boss)  //FIXME: What.
{
	int slot=boss%10000;
	boss/=1000;
	FF2_SetBossCharge(boss, slot, 0.0);
}

public Action Timer_StunBoss(Handle timer, int boss)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!IsValidEntity(client))
	{
		return;
	}
	TF2_StunPlayer(client, (enableSuperDuperJump[boss] ? 4.0 : 2.0), 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, client);
}

void Charge_WeighDown(int boss, int slot)  //TODO: Create a HUD for this
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(client<=0 || !(GetClientButtons(client) & IN_DUCK))
	{
		return;
	}

	float charge=FF2_GetBossCharge(boss, slot)+0.2;
	if(!(GetEntityFlags(client) & FL_ONGROUND))
	{
		if(charge>=4.0)
		{
			float angles[3];
			GetClientEyeAngles(client, angles);
			if(angles[0]>60.0)
			{
				Action action;
				Call_StartForward(OnWeighdown);
				Call_PushCell(boss);
				Call_Finish(action);
				if(action==Plugin_Handled || action==Plugin_Stop)
				{
					return;
				}

				DataPack data;
				float velocity[3];
				if(gravityDatapack[client]==null)
				{
					gravityDatapack[client]=CreateDataTimer(2.0, Timer_ResetGravity, data, TIMER_FLAG_NO_MAPCHANGE);
					data.WriteCell(GetClientUserId(client));
					data.WriteFloat(GetEntityGravity(client));
					data.Reset();
				}

				GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
				velocity[2]=-1000.0;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
				SetEntityGravity(client, 6.0);

				FF2_SetBossCharge(boss, slot, 0.0);
			}
		}
		else
		{
			FF2_SetBossCharge(boss, slot, charge);
		}
	}
	else if(charge>0.3 || charge<0)
	{
		FF2_SetBossCharge(boss, slot, 0.0);
	}
}

public Action Timer_ResetGravity(Handle timer, DataPack data)
{
	int client=GetClientOfUserId(data.ReadCell());
	if(client && IsValidEntity(client) && IsClientInGame(client))
	{
		SetEntityGravity(client, data.ReadFloat());
	}
	gravityDatapack[client]=null;
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int boss=FF2_GetBossIndex(GetClientOfUserId(event.GetInt("attacker")));
	if(boss!=-1 && FF2_HasAbility(boss, PLUGIN_NAME, "special_dissolve"))
	{
		CreateTimer(0.1, Timer_DissolveRagdoll, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action Timer_DissolveRagdoll(Handle timer, int userid)
{
	int client=GetClientOfUserId(userid);
	int ragdoll=-1;
	if(client && IsClientInGame(client))
	{
		ragdoll=GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	}

	if(IsValidEntity(ragdoll))
	{
		DissolveRagdoll(ragdoll);
	}
}

int DissolveRagdoll(int ragdoll)
{
	int dissolver=CreateEntityByName("env_entity_dissolver");
	if(dissolver==-1)
	{
		return;
	}

	DispatchKeyValue(dissolver, "dissolvetype", "0");
	DispatchKeyValue(dissolver, "magnitude", "200");
	DispatchKeyValue(dissolver, "target", "!activator");

	AcceptEntityInput(dissolver, "Dissolve", ragdoll);
	AcceptEntityInput(dissolver, "Kill");
}

public Action RemoveEntity(Handle timer, int entid)
{
	int entity=EntRefToEntIndex(entid);
	if(IsValidEntity(entity) && entity>MaxClients)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

stock int AttachParticle(int entity, char[] particleType, float offset=0.0, bool attach=true)
{
	int particle=CreateEntityByName("info_particle_system");

	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2]+=offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

public Action OnDeflect(Event event, const char[] name, bool dontBroadcast)
{
	int boss=FF2_GetBossIndex(GetClientOfUserId(event.GetInt("userid")));
	if(boss!=-1)
	{
		if(UberRageCount[boss]>11)
		{
			UberRageCount[boss]-=10;
		}
	}
	return Plugin_Continue;
}

public Action FF2_OnTriggerHurt(int boss, int triggerhurt, float& damage)
{
	enableSuperDuperJump[boss]=true;
	if(FF2_GetBossCharge(boss, 1)<0)
	{
		FF2_SetBossCharge(boss, 1, 0.0);
	}
	return Plugin_Continue;
}
