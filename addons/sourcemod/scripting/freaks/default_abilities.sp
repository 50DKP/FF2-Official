#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define PLUGIN_VERSION "1.10.4"

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
new Handle:cvarBaseJumperStun;

new bool:oldJump;
new bool:removeBaseJumperOnStun;

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

	HookEvent("object_deflected", OnDeflect, EventHookMode_Pre);
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("player_death", OnPlayerDeath);

	LoadTranslations("freak_fortress_2.phrases");
}

public OnAllPluginsLoaded()
{
	cvarOldJump=FindConVar("ff2_oldjump");  //Created in freak_fortress_2.sp
	cvarBaseJumperStun=FindConVar("ff2_base_jumper_stun");

	HookConVarChange(cvarOldJump, CvarChange);
	HookConVarChange(cvarBaseJumperStun, CvarChange);

	oldJump=GetConVarBool(cvarOldJump);
	removeBaseJumperOnStun=GetConVarBool(cvarBaseJumperStun);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar==cvarOldJump)
	{
		oldJump=bool:StringToInt(newValue);
	}
	else if(convar==cvarBaseJumperStun)
	{
		removeBaseJumperOnStun=bool:StringToInt(newValue);
	}
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client; client<MaxClients; client++)
	{
		enableSuperDuperJump[client]=false;
		UberRageCount[client]=0.0;
	}

	CreateTimer(0.3, Timer_GetBossTeam, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.11, StartBossTimer, _, TIMER_FLAG_NO_MAPCHANGE);  //TODO: Investigate.
	return Plugin_Continue;
}

public Action:StartBossTimer(Handle:timer)  //TODO: What.
{
	for(new boss; FF2_GetBossUserId(boss)!=-1; boss++)
	{
		if(FF2_HasAbility(boss, this_plugin_name, "charge_teleport"))
		{
			FF2_SetBossCharge(boss, FF2_GetAbilityArgument(boss, this_plugin_name, "charge_teleport", 0, 1), -1.0*FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "charge_teleport", 2, 5.0));
		}
	}
}

public Action:Timer_GetBossTeam(Handle:timer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], status)
{
	new slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0);
	if(!slot)  //Rage
	{
		if(!boss)  //Boss indexes are just so amazing
		{
			new Float:distance=FF2_GetRageDist(boss, this_plugin_name, ability_name);
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
		Charge_WeighDown(boss, slot);
	}
	else if(!strcmp(ability_name, "charge_bravejump"))
	{
		Charge_BraveJump(ability_name, boss, slot, status);
	}
	else if(!strcmp(ability_name, "charge_teleport"))
	{
		Charge_Teleport(ability_name, boss, slot, status);
	}
	else if(!strcmp(ability_name, "rage_uber"))
	{
		new client=GetClientOfUserId(FF2_GetBossUserId(boss));
		TF2_AddCondition(client, TFCond_Ubercharged, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 5.0));
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 5.0), Timer_StopUber, boss);
	}
	else if(!strcmp(ability_name, "rage_stun"))
	{
		Rage_Stun(ability_name, boss);
	}
	else if(!strcmp(ability_name, "rage_stunsg"))
	{
		Rage_StunSentry(ability_name, boss);
	}
	else if(!strcmp(ability_name, "rage_preventtaunt"))  //DEPRECATED-to be removed in 2.0.0
	{
		decl String:name[64];
		FF2_GetBossSpecial(boss, name, sizeof(name));
		PrintToServer("[FF2] Warning: \"rage_preventtaunt\" has been deprecated!  Please remove this ability from %s", name);
	}
	else if(!strcmp(ability_name, "rage_instant_teleport"))
	{
		new client=GetClientOfUserId(FF2_GetBossUserId(boss));
		new Float:position[3];
		new bool:otherTeamIsAlive;

		for(new target=1; target<=MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target) && target!=client && !(FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
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
		while(!IsValidEdict(target) || target==client || (FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM) || !IsPlayerAlive(target));

		GetEntPropVector(target, Prop_Data, "m_vecOrigin", position);
		TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
		TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, client);
	}
	return Plugin_Continue;
}

Rage_Stun(const String:ability_name[], boss)
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	new Float:bossPosition[3], Float:targetPosition[3];
	new Float:duration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 5.0);
	new Float:distance=FF2_GetRageDist(boss, this_plugin_name, ability_name);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);

	for(new target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target)!=BossTeam)
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition);
			if(!TF2_IsPlayerInCondition(target, TFCond_Ubercharged) && (GetVectorDistance(bossPosition, targetPosition)<=distance))
			{
				if(removeBaseJumperOnStun)
				{
					TF2_RemoveCondition(target, TFCond_Parachute);
				}
				TF2_StunPlayer(target, duration, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, client);
				CreateTimer(duration, RemoveEntity, EntIndexToEntRef(AttachParticle(target, "yikes_fx", 75.0)));
			}
		}
	}
}

public Action:Timer_StopUber(Handle:timer, any:boss)
{
	SetEntProp(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Data, "m_takedamage", 2);
	return Plugin_Continue;
}

Rage_StunSentry(const String:ability_name[], boss)
{
	new Float:bossPosition[3], Float:sentryPosition[3];
	GetEntPropVector(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Send, "m_vecOrigin", bossPosition);
	new Float:duration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 7.0);
	new Float:distance=FF2_GetRageDist(boss, this_plugin_name, ability_name);

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

Charge_BraveJump(const String:ability_name[], boss, slot, status)
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	new Float:charge=FF2_GetBossCharge(boss, slot);
	new Float:multiplier=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 3, 1.0);

	switch(status)
	{
		case 1:
		{
			SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, jumpHUD, "%t", "jump_status_2", -RoundFloat(charge));
		}
		case 2:
		{
			SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
			if(enableSuperDuperJump[boss])
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 64, 64, 255);
				FF2_ShowSyncHudText(client, jumpHUD, "%t", "super_duper_jump");
			}
			else
			{
				FF2_ShowSyncHudText(client, jumpHUD, "%t", "jump_status", RoundFloat(charge));
			}
		}
		case 3:
		{
			new bool:superJump=enableSuperDuperJump[boss];
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
				new Float:angles[3];
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
			decl String:sound[PLATFORM_MAX_PATH];
			if(FF2_RandomSound("sound_ability", sound, PLATFORM_MAX_PATH, boss, slot))
			{
				EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
				EmitSoundToAll(sound, client, _, _, _, _, _, client, position);

				for(new target=1; target<=MaxClients; target++)
				{
					if(IsClientInGame(target) && target!=client)
					{
						EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
						EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
					}
				}
			}
		}
	}
}

Charge_Teleport(const String:ability_name[], boss, slot, status)
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	new Float:charge=FF2_GetBossCharge(boss, slot);
	switch(status)
	{
		case 1:
		{
			SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, jumpHUD, "%t", "teleport_status_2", -RoundFloat(charge));
		}
		case 2:
		{
			SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, jumpHUD, "%t", "teleport_status", RoundFloat(charge));
		}
		case 3:
		{
			new Action:action=Plugin_Continue;
			new bool:superJump=enableSuperDuperJump[boss];
			Call_StartForward(OnHaleJump);
			Call_PushCellRef(superJump);
			Call_Finish(action);
			if(action!=Plugin_Continue && action!=Plugin_Changed)
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
				CreateTimer(0.1, Timer_ResetCharge, boss*10000+slot);  //FIXME: Investigate.
				return;
			}

			new tries;
			new bool:otherTeamIsAlive;
			for(new target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && IsPlayerAlive(target) && target!=client && !(FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
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
			while(otherTeamIsAlive && (!IsValidEdict(target) || target==client || (FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM) || !IsPlayerAlive(target)));

			decl String:particle[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 3, particle, sizeof(particle));
			if(strlen(particle)>0)
			{
				CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(client, particle)));
				CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(client, particle, _, false)));
			}

			new Float:position[3];
			GetEntPropVector(target, Prop_Data, "m_vecOrigin", position);
			if(IsValidEdict(target))
			{
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", position);
				SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + (enableSuperDuperJump ? 4.0:2.0));
				if(GetEntProp(target, Prop_Send, "m_bDucked"))
				{
					new Float:temp[3]={24.0, 24.0, 62.0};  //Compiler won't accept directly putting it into SEPV -.-
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
					CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(client, particle)));
					CreateTimer(3.0, RemoveEntity, EntIndexToEntRef(AttachParticle(client, particle, _, false)));
				}
			}

			decl String:sound[PLATFORM_MAX_PATH];
			if(FF2_RandomSound("sound_ability", sound, PLATFORM_MAX_PATH, boss, slot))
			{
				EmitSoundToAll(sound, boss, _, _, _, _, _, boss, position);
				EmitSoundToAll(sound, boss, _, _, _, _, _, boss, position);

				for(new enemy=1; enemy<=MaxClients; enemy++)
				{
					if(IsClientInGame(enemy) && enemy!=boss)
					{
						EmitSoundToClient(enemy, sound, boss, _, _, _, _, _, boss, position);
						EmitSoundToClient(enemy, sound, client, _, _, _, _, _, boss, position);
					}
				}
			}
		}
	}
}

public Action:Timer_ResetCharge(Handle:timer, any:boss)  //FIXME: What.
{
	new slot=boss%10000;
	boss/=1000;
	FF2_SetBossCharge(boss, slot, 0.0);
}

public Action:Timer_StunBoss(Handle:timer, any:boss)
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!IsValidEdict(client))
	{
		return;
	}
	TF2_StunPlayer(client, (enableSuperDuperJump[boss] ? 4.0 : 2.0), 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, client);
}

Charge_WeighDown(boss, slot)  //TODO: Create a HUD for this
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(client<=0 || !(GetClientButtons(client) & IN_DUCK))
	{
		return;
	}

	new Float:charge=FF2_GetBossCharge(boss, slot)+0.2;
	if(!(GetEntityFlags(client) & FL_ONGROUND))
	{
		if(charge>=4.0)
		{
			new Float:angles[3];
			GetClientEyeAngles(client, angles);
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
				if(gravityDatapack[client]==INVALID_HANDLE)
				{
					gravityDatapack[client]=CreateDataTimer(2.0, Timer_ResetGravity, data, TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(data, GetClientUserId(client));
					WritePackFloat(data, GetEntityGravity(client));
					ResetPack(data);
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

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
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
	new client=GetClientOfUserId(userid);
	new ragdoll=-1;
	if(client && IsClientInGame(client))
	{
		ragdoll=GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
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
	new Float:position[3];
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

public Action:OnDeflect(Handle:event, const String:name[], bool:dontBroadcast)
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