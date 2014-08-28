#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define PLUGIN_VERSION "1.10.0"

public Plugin:myinfo=
{
	name="Freak Fortress 2: Default Abilities",
	author="RainBolt Dash",
	description="FF2: Common abilities used by all bosses",
	version=PLUGIN_VERSION,
};

new Handle:OnHaleJump;
new Handle:OnHaleRage;
new Handle:OnHaleWeighdown;

new Handle:gravityDatapack[MAXPLAYERS+1];

new Handle:jumpHUD;

new bool:enableSuperDuperJump[MAXPLAYERS+1];
new Float:UberRageCount[MAXPLAYERS+1];
new BossTeam=_:TFTeam_Blue;

new Handle:cvarOldJump;

new bool:oldJump;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	OnHaleJump=CreateGlobalForward("VSH_OnDoJump", ET_Hook, Param_CellByRef);
	OnHaleRage=CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	OnHaleWeighdown=CreateGlobalForward("VSH_OnDoWeighdown", ET_Hook);
	return APLRes_Success;
}

public OnPluginStart2()
{
	jumpHUD=CreateHudSynchronizer();

	HookEvent("object_deflected", event_deflect, EventHookMode_Pre);
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("player_death", event_player_death);

	LoadTranslations("freak_fortress_2.phrases");
}

public OnAllPluginsLoaded()
{
	cvarOldJump=FindConVar("ff2_oldjump");
	HookConVarChange(cvarOldJump, CvarChange);
	oldJump=GetConVarBool(cvarOldJump);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	oldJump=bool:StringToInt(newValue);
}
public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=0; client<MaxClients; client++)
	{
		enableSuperDuperJump[client]=false;
		UberRageCount[client]=0.0;
	}

	CreateTimer(0.3, Timer_GetBossTeam);
	CreateTimer(9.11, StartBossTimer);
	return Plugin_Continue;
}

public Action:StartBossTimer(Handle:hTimer)
{
	for(new client=0; FF2_GetBossUserId(client)!=-1; client++)
	{
		if(FF2_HasAbility(client, this_plugin_name, "charge_teleport"))
		{
			FF2_SetBossCharge(client, FF2_GetAbilityArgument(client, this_plugin_name, "charge_teleport", 0, 1), -1.0*FF2_GetAbilityArgumentFloat(client, this_plugin_name, "charge_teleport", 2, 5.0));
		}
	}
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public Action:FF2_OnAbility2(client, const String:plugin_name[], const String:ability_name[], status)
{
	new slot=FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 0);
	if(!slot)
	{
		if(!client)
		{
			new Float:distance=FF2_GetRageDist(client, this_plugin_name, ability_name);
			new Float:newDistance=distance;
			new Action:action=Plugin_Continue;

			Call_StartForward(OnHaleRage);
			Call_PushFloatRef(newDistance);
			Call_Finish(action);
			if(action!=Plugin_Continue && action!=Plugin_Changed)
			{
				return Plugin_Continue;
			}
			else if(action==Plugin_Changed)
			{
				distance=newDistance;
			}
		}
	}

	if(!strcmp(ability_name, "charge_weightdown"))
	{
		Charge_WeighDown(client, slot);
	}
	else if(!strcmp(ability_name, "charge_bravejump"))
	{
		Charge_BraveJump(ability_name, client, slot, status);
	}
	else if(!strcmp(ability_name, "charge_teleport"))
	{
		Charge_Teleport(ability_name, client, slot, status);
	}
	else if(!strcmp(ability_name, "rage_uber"))
	{
		new boss=GetClientOfUserId(FF2_GetBossUserId(client));
		TF2_AddCondition(boss, TFCond_Ubercharged, FF2_GetAbilityArgumentFloat(client, this_plugin_name, ability_name, 1, 5.0));
		SetEntProp(boss, Prop_Data, "m_takedamage", 0);
		CreateTimer(FF2_GetAbilityArgumentFloat(client, this_plugin_name, ability_name, 1, 5.0), Timer_StopUber, client);
	}
	else if(!strcmp(ability_name, "rage_stun"))
	{
		Rage_Stun(ability_name, client);
	}
	else if(!strcmp(ability_name, "rage_stunsg"))
	{
		Rage_StunSentry(ability_name, client);
	}
	else if(!strcmp(ability_name, "rage_preventtaunt"))  //DEPRECATED-to be removed in 2.0.0
	{
		CreateTimer(0.01, Timer_StopTaunt, client);
	}
	else if(!strcmp(ability_name, "rage_instant_teleport"))
	{
		new boss=GetClientOfUserId(FF2_GetBossUserId(client));
		new Float:position[3];
		new bool:otherTeamIsAlive;

		for(new target=1; target<=MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target) && target!=boss && !(FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
			{
				otherTeamIsAlive=true;
				break;
			}
		}

		if(!otherTeamIsAlive)
		{
			return Plugin_Continue;
		}

		new target, tries;
		do
		{
			tries++;
			target=GetRandomInt(1, MaxClients);
			if(tries==100)
			{
				return Plugin_Continue;
			}
		}
		while(!IsValidEdict(target) || target==boss || (FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM) || !IsPlayerAlive(target));

		GetEntPropVector(target, Prop_Data, "m_vecOrigin", position);
		TeleportEntity(boss, position, NULL_VECTOR, NULL_VECTOR);
		TF2_StunPlayer(boss, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, boss);
	}
	return Plugin_Continue;
}

Rage_Stun(const String:ability_name[], client)
{
	decl Float:bossPosition[3];
	decl Float:clientPosition[3];
	new Float:duration=FF2_GetAbilityArgumentFloat(client, this_plugin_name, ability_name, 1, 5.0);
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	new Float:distance=FF2_GetRageDist(client, this_plugin_name, ability_name);
	GetEntPropVector(boss, Prop_Send, "m_vecOrigin", bossPosition);
	for(new target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target)!=BossTeam)
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", clientPosition);
			if(!TF2_IsPlayerInCondition(target, TFCond_Ubercharged) && (GetVectorDistance(bossPosition, clientPosition)<=distance))
			{
				TF2_StunPlayer(target, duration, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, boss);
				CreateTimer(duration, RemoveEntity, EntIndexToEntRef(AttachParticle(target, "yikes_fx", 75.0)));
			}
		}
	}
}

public Action:Timer_StopUber(Handle:timer, any:client)
{
	SetEntProp(GetClientOfUserId(FF2_GetBossUserId(client)), Prop_Data, "m_takedamage", 2);
	return Plugin_Continue;
}

public Action:Timer_StopTaunt(Handle:timer, any:client)
{
	decl String:name[64];
	FF2_GetBossSpecial(client, name, sizeof(name));
	PrintToServer("[FF2] Warning: \"rage_preventtaunt\" has been deprecated!  Please remove this ability from %s", name);
	return Plugin_Continue;
}

Rage_StunSentry(const String:ability_name[], client)
{
	decl Float:bossPosition[3];
	decl Float:sentryPosition[3];
	GetEntPropVector(GetClientOfUserId(FF2_GetBossUserId(client)), Prop_Send, "m_vecOrigin", bossPosition);
	new Float:duration=FF2_GetAbilityArgumentFloat(client, this_plugin_name, ability_name, 1, 7.0);
	new Float:distance=FF2_GetRageDist(client, this_plugin_name, ability_name);
	new sentry;
	while((sentry=FindEntityByClassname(sentry, "obj_sentrygun"))!=-1)
	{
		GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentryPosition);
		if(GetVectorDistance(bossPosition, sentryPosition)<=distance)
		{
			SetEntProp(sentry, Prop_Send, "m_bDisabled", 1);
			CreateTimer(duration, RemoveEntity, EntIndexToEntRef(AttachParticle(sentry, "yikes_fx", 75.0)));
			CreateTimer(duration, Timer_EnableSentry, EntIndexToEntRef(sentry));
		}
	}
}

public Action:Timer_EnableSentry(Handle:timer, any:sentryid)
{
	new sentry=EntRefToEntIndex(sentryid);
	if(FF2_GetRoundState()==1 && sentry>MaxClients)
	{
		SetEntProp(sentry, Prop_Send, "m_bDisabled", 0);
	}
	return Plugin_Continue;
}

Charge_BraveJump(const String:ability_name[], client, slot, status)
{
	new Float:charge=FF2_GetBossCharge(client, slot);
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	new Float:multiplier=FF2_GetAbilityArgumentFloat(client, this_plugin_name, ability_name, 3, 1.0);

	switch(status)
	{
		case 1:
		{
			if(!(FF2_GetFF2flags(boss) & FF2FLAG_HUDDISABLED) && !(GetClientButtons(boss) & IN_SCORE))
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
				ShowSyncHudText(boss, jumpHUD, "%t", "jump_status_2", -RoundFloat(charge));
			}
		}
		case 2:
		{
			if(!(FF2_GetFF2flags(boss) & FF2FLAG_HUDDISABLED) && !(GetClientButtons(boss) & IN_SCORE))
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
				if(enableSuperDuperJump[client])
				{
					SetHudTextParams(-1.0, 0.88, 0.15, 255, 64, 64, 255);
					ShowSyncHudText(boss, jumpHUD, "%t", "super_duper_jump");
				}
				else
				{
					ShowSyncHudText(boss, jumpHUD, "%t", "jump_status", RoundFloat(charge));
				}
			}
		}
		case 3:
		{
			new bool:superJump=enableSuperDuperJump[client];
			new Action:action=Plugin_Continue;
			Call_StartForward(OnHaleJump);
			Call_PushCellRef(superJump);
			Call_Finish(action);
			if(action!=Plugin_Continue && action!=Plugin_Changed)
			{
				return;
			}
			else if(action==Plugin_Changed)
			{
				enableSuperDuperJump[client]=superJump;
			}

			new Float:position[3], Float:velocity[3];
			GetEntPropVector(boss, Prop_Send, "m_vecOrigin", position);
			GetEntPropVector(boss, Prop_Data, "m_vecVelocity", velocity);

			if(oldJump)
			{
				if(enableSuperDuperJump[client])
				{
					velocity[2]=750+(charge/4)*13.0+2000;
					enableSuperDuperJump[client]=false;
				}
				else
				{
					velocity[2]=750+(charge/4)*13.0;
				}
				SetEntProp(boss, Prop_Send, "m_bJumping", 1);
				velocity[0]*=(1+Sine((charge/4)*FLOAT_PI/50));
				velocity[1]*=(1+Sine((charge/4)*FLOAT_PI/50));
			}
			else
			{
				new Float:angles[3];
				GetClientEyeAngles(boss, angles);
				if(enableSuperDuperJump[client])
				{
					velocity[0]+=Cosine(DegToRad(angles[0]))*Cosine(DegToRad(angles[1]))*500*multiplier;
					velocity[1]+=Cosine(DegToRad(angles[0]))*Sine(DegToRad(angles[1]))*500*multiplier;
					velocity[2]=(750.0+175.0*charge/70+2000)*multiplier;
					enableSuperDuperJump[client]=false;
				}
				else
				{
					velocity[0]+=Cosine(DegToRad(angles[0]))*Cosine(DegToRad(angles[1]))*100*multiplier;
					velocity[1]+=Cosine(DegToRad(angles[0]))*Sine(DegToRad(angles[1]))*100*multiplier;
					velocity[2]=(750.0+175.0*charge/70)*multiplier;
				}
			}

			TeleportEntity(boss, NULL_VECTOR, NULL_VECTOR, velocity);
			decl String:sound[PLATFORM_MAX_PATH];
			if(FF2_RandomSound("sound_ability", sound, PLATFORM_MAX_PATH, client, slot))
			{
				EmitSoundToAll(sound, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);
				EmitSoundToAll(sound, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);

				for(new target=1; target<=MaxClients; target++)
				{
					if(IsClientInGame(target) && target!=boss)
					{
						EmitSoundToClient(target, sound, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);
						EmitSoundToClient(target, sound, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);
					}
				}
			}
		}
	}
}

Charge_Teleport(const String:ability_name[], client, slot, status)
{
	new Float:charge=FF2_GetBossCharge(client, slot);
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	switch(status)
	{
		case 1:
		{
			if(!(FF2_GetFF2flags(boss) & FF2FLAG_HUDDISABLED) && !(GetClientButtons(boss) & IN_SCORE))
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
				ShowSyncHudText(boss, jumpHUD, "%t", "teleport_status_2", -RoundFloat(charge));
			}
		}
		case 2:
		{
			if(!(FF2_GetFF2flags(boss) & FF2FLAG_HUDDISABLED) && !(GetClientButtons(boss) & IN_SCORE))
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
				ShowSyncHudText(boss, jumpHUD, "%t", "teleport_status", RoundFloat(charge));
			}
		}
		case 3:
		{
			new Action:action=Plugin_Continue;
			new bool:superJump=enableSuperDuperJump[client];
			Call_StartForward(OnHaleJump);
			Call_PushCellRef(superJump);
			Call_Finish(action);
			if(action!=Plugin_Continue && action!=Plugin_Changed)
			{
				return;
			}
			else if(action==Plugin_Changed)
			{
				enableSuperDuperJump[client]=superJump;
			}

			if(enableSuperDuperJump[client])
			{
				enableSuperDuperJump[client]=false;
			}
			else if(charge<100)
			{
				CreateTimer(0.1, Timer_ResetCharge, client*10000+slot);
				return;
			}

			new tries;
			new bool:otherTeamIsAlive;
			for(new target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && IsPlayerAlive(target) && target!=boss && !(FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
				{
					otherTeamIsAlive=true;
					break;
				}
			}

			new target;
			do
			{
				tries++;
				target=GetRandomInt(1, MaxClients);
				if(tries==100)
				{
					return;
				}
			}
			while(otherTeamIsAlive && (!IsValidEdict(target) || target==boss || (FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM) || !IsPlayerAlive(target)));

			decl String:particle[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(client, this_plugin_name, ability_name, 4, particle, 128);
			if(strlen(particle)>0)
			{
				CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(boss, particle)));
				CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(boss, particle, _, false)));
			}

			decl Float:position[3];
			GetEntPropVector(target, Prop_Data, "m_vecOrigin", position);
			if(IsValidEdict(target))
			{
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", position);
				SetEntPropFloat(boss, Prop_Send, "m_flNextAttack", GetGameTime() + (enableSuperDuperJump ? 4.0:2.0));
				if(GetEntProp(target, Prop_Send, "m_bDucked"))
				{
					new Float:vectorsMax[3]={24.0, 24.0, 62.0};
					SetEntPropVector(boss, Prop_Send, "m_vecMaxs", vectorsMax);
					SetEntProp(boss, Prop_Send, "m_bDucked", 1);
					SetEntityFlags(boss, GetEntityFlags(boss)|FL_DUCKING);
					CreateTimer(0.2, Timer_StunBoss, client, TIMER_FLAG_NO_MAPCHANGE);
				}
				else
				{
					TF2_StunPlayer(boss, (enableSuperDuperJump ? 4.0:2.0), 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, target);
				}

				TeleportEntity(boss, position, NULL_VECTOR, NULL_VECTOR);
				if(strlen(particle)>0)
				{
					CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(boss, particle)));
					CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(boss, particle, _, false)));
				}
			}

			decl String:sound[PLATFORM_MAX_PATH];
			if(FF2_RandomSound("sound_ability", sound, PLATFORM_MAX_PATH, client, slot))
			{
				EmitSoundToAll(sound, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);
				EmitSoundToAll(sound, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);

				for(new enemy=1; enemy<=MaxClients; enemy++)
				{
					if(IsClientInGame(enemy) && enemy!=boss)
					{
						EmitSoundToClient(enemy, sound, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);
						EmitSoundToClient(enemy, sound, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);
					}
				}
			}
		}
	}
}

public Action:Timer_ResetCharge(Handle:timer, any:client)
{
	new slot=client%10000;
	client/=1000;
	FF2_SetBossCharge(client, slot, 0.0);
}

public Action:Timer_StunBoss(Handle:timer, any:client)
{
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	if(!IsValidEdict(boss))
	{
		return;
	}
	TF2_StunPlayer(boss, (enableSuperDuperJump[client] ? 4.0 : 2.0), 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, boss);
}

Charge_WeighDown(client, slot)
{
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	if(boss<=0 || !(GetClientButtons(boss) & IN_DUCK))
	{
		return;
	}

	new Float:charge=FF2_GetBossCharge(client, slot)+0.2;
	if(!(GetEntityFlags(boss) & FL_ONGROUND))
	{
		if(charge>=4.0)
		{
			new Float:angles[3];
			GetClientEyeAngles(boss, angles);
			if(angles[0]>60.0)
			{
				new Action:action=Plugin_Continue;
				Call_StartForward(OnHaleWeighdown);
				Call_Finish(action);
				if(action!=Plugin_Continue && action!=Plugin_Changed)
				{
					return;
				}

				new Handle:data;
				new Float:velocity[3];
				if(gravityDatapack[boss]==INVALID_HANDLE)
				{
					gravityDatapack[boss]=CreateDataTimer(2.0, Timer_ResetGravity, data, TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(data, GetClientUserId(boss));
					WritePackFloat(data, GetEntityGravity(boss));
					ResetPack(data);
				}

				GetEntPropVector(boss, Prop_Data, "m_vecVelocity", velocity);
				velocity[2]=-1000.0;
				TeleportEntity(boss, NULL_VECTOR, NULL_VECTOR, velocity);
				SetEntityGravity(boss, 6.0);

				//CPrintToChat(boss, "{olive}[FF2]{default} %t", "used_weighdown");  //Pretty spammy and you don't see super jump having this message
				FF2_SetBossCharge(client, slot, 0.0);
			}
		}
		else
		{
			FF2_SetBossCharge(client, slot, charge);
		}
	}
	else if(charge>0.3 || charge<0)
	{
		FF2_SetBossCharge(client, slot, 0.0);
	}
}

public Action:Timer_ResetGravity(Handle:timer, Handle:data)
{
	new client=GetClientOfUserId(ReadPackCell(data));
	if(client && IsValidEdict(client) && IsClientInGame(client))
	{
		SetEntityGravity(client, ReadPackFloat(data));
	}
	gravityDatapack[client]=INVALID_HANDLE;
	return Plugin_Continue;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new boss=FF2_GetBossIndex(GetClientOfUserId(GetEventInt(event, "attacker")));
	if(boss!=-1 && FF2_HasAbility(boss, this_plugin_name, "special_dissolve"))
	{
		CreateTimer(0.1, Timer_DissolveRagdoll, GetEventInt(event, "userid"));
	}
	return Plugin_Continue;
}

public Action:Timer_DissolveRagdoll(Handle:timer, any:userid)
{
	new victim=GetClientOfUserId(userid);
	new ragdoll=-1;
	if(victim>0 && IsClientConnected(victim))
	{
		ragdoll=GetEntPropEnt(victim, Prop_Send, "m_hRagdoll");
	}

	if(ragdoll!=-1)
	{
		DissolveRagdoll(ragdoll);
	}
}

DissolveRagdoll(ragdoll)
{
	new dissolver=CreateEntityByName("env_entity_dissolver");
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

public Action:RemoveEntity(Handle:timer, any:entid)
{
	new entity=EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MaxClients)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

stock AttachParticle(entity, String:particleType[], Float:offset=0.0, bool:attach=true)
{
	new particle=CreateEntityByName("info_particle_system");

	decl String:targetName[128];
	decl Float:position[3];
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

public Action:event_deflect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new boss=FF2_GetBossIndex(GetClientOfUserId(GetEventInt(event, "userid")));
	if(boss!=-1)
	{
		if(UberRageCount[boss]>11)
		{
			UberRageCount[boss]-=10;
		}
	}
	return Plugin_Continue;
}

public Action:FF2_OnTriggerHurt(boss, triggerhurt, &Float:damage)
{
	enableSuperDuperJump[boss]=true;
	if(FF2_GetBossCharge(boss, 1)<0)
	{
		FF2_SetBossCharge(boss, 1, 0.0);
	}
	return Plugin_Continue;
}
