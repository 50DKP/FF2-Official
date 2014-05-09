#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define CBS_MAX_ARROWS 9

#define PLUGIN_VERSION "1.10.0"

public Plugin:myinfo=
{
	name="Freak Fortress 2: Abilities of 1st set",
	author="RainBolt Dash",
	description="FF2: Abilities used by Seeldier, Seeman, Demopan, CBS, and Ninja Spy",
	version=PLUGIN_VERSION,
};

#define FLAG_ONSLOMO			(1<<0)
#define FLAG_SLOMOREADYCHANGE	(1<<1)

new FF2Flags[MAXPLAYERS+1];
new TFClassType:LastClass[MAXPLAYERS+1];
new CloneOwnerIndex[MAXPLAYERS+1];

new Handle:SloMoTimer;
new oldTarget;

new Handle:OnHaleRage=INVALID_HANDLE;

new Handle:cvarTimeScale;
new Handle:cvarCheats;
new Handle:cvarKAC;
new BossTeam=_:TFTeam_Blue;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	OnHaleRage=CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	return APLRes_Success;
}


public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("teamplay_round_win", event_round_end);
	HookEvent("player_death", event_player_death);
	LoadTranslations("ff2_1st_set.phrases");

	cvarTimeScale=FindConVar("host_timescale");
	cvarCheats=FindConVar("sv_cheats");
	cvarKAC=FindConVar("kac_enable");
}

public OnMapStart()
{
	PrecacheSound("replay\\exitperformancemode.wav",true);
	PrecacheSound("replay\\enterperformancemode.wav",true);
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3, Timer_GetBossTeam);
	for(new client=0; client<=MaxClients; client++)
	{
		FF2Flags[client]=0;
		CloneOwnerIndex[client]=-1;
	}
	return Plugin_Continue;
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=0; client<=MaxClients; client++)
	{
		if(FF2Flags[client] & FLAG_ONSLOMO)
		{
			if(SloMoTimer)
			{
				KillTimer(SloMoTimer);
			}
			Timer_StopSlomo(INVALID_HANDLE, -1);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public Action:Timer_GetBossTeam(Handle:timer)
{
	if(cvarKAC && GetConVarBool(cvarKAC))
	{
		SetConVarBool(cvarKAC, false);
	}
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public Action:FF2_OnAbility2(client, const String:plugin_name[], const String:ability_name[], status)
{
	new slot=FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 0);
	if(!slot)
	{
		if(client==0)
		{
			new Action:action=Plugin_Continue;
			Call_StartForward(OnHaleRage);
			new Float:distance=FF2_GetRageDist(client, this_plugin_name, ability_name);
			new Float:newDistance=distance;
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

	if(!strcmp(ability_name, "special_democharge"))
	{
		if(status>0)
		{
			new boss=GetClientOfUserId(FF2_GetBossUserId(client));
			new Float:charge=FF2_GetBossCharge(client, 0);
			SetEntPropFloat(boss, Prop_Send, "m_flChargeMeter", 100.0);		
			TF2_AddCondition(boss, TFCond_Charging, 0.25);	
			if(charge>10.0 && charge<90.0)
			{
				FF2_SetBossCharge(client, 0, charge-0.4);
			}
		}
	}
	else if(!strcmp(ability_name, "rage_cloneattack"))
	{
		Rage_Clone(ability_name, client);
	}
	else if(!strcmp(ability_name, "rage_tradespam"))
	{
		Timer_Demopan_Rage(INVALID_HANDLE, 1);
	}
	else if(!strcmp(ability_name, "rage_cbs_bowrage"))
	{
		Rage_Bow(client);
	}
	else if(!strcmp(ability_name, "rage_explosive_dance"))
	{
		SetEntityMoveType(GetClientOfUserId(FF2_GetBossUserId(client)), MOVETYPE_NONE);
		new Handle:data;
		CreateDataTimer(0.15, Timer_Prepare_Explosion_Rage, data);
		WritePackString(data, ability_name);
		WritePackCell(data, client);
		ResetPack(data);
	}
	else if(!strcmp(ability_name, "rage_matrix_attack"))
	{
		Rage_Slowmo(client, ability_name);
	}
	return Plugin_Continue;
}		

Rage_Clone(const String:ability_name[], client)
{
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	new Handle:bossKV[8];
	decl String:bossName[32];
	new bool:changeModel=bool:FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 1);
	new weaponMode=FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 2);
	decl String:model[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(client, this_plugin_name, ability_name, 3, model, sizeof(model));
	new class=FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 4);
	new Float:ratio=FF2_GetAbilityArgumentFloat(client, this_plugin_name, ability_name, 5, 0.0);
	new String:classname[64]="tf_weapon_bottle";
	FF2_GetAbilityArgumentString(client, this_plugin_name, ability_name, 6, classname, sizeof(classname));
	new index=FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 7, 191);
	new String:attributes[64]="68 ; -1";
	FF2_GetAbilityArgumentString(client, this_plugin_name, ability_name, 8, attributes, sizeof(attributes));
	new ammo=FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 9, 0);
	new clip=FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 10, 0);
	new health=FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 11, 0);
	new Float:position[3];
	new Float:velocity[3];

	GetEntPropVector(boss, Prop_Data, "m_vecOrigin", position);
	FF2_GetBossSpecial(client, bossName, 32);

	new maxKV;
	for(maxKV=0; maxKV<8; maxKV++)
	{
		if(!(bossKV[maxKV]=FF2_GetSpecialKV(maxKV)))
		{
			break;
		}
	}

	new alive=0;
	new dead=0;
	new Handle:players=CreateArray();
	for(new target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target))
		{
			new team=GetClientTeam(target);
			if(team>_:TFTeam_Spectator && team!=BossTeam)
			{
				if(IsPlayerAlive(target))
				{
					alive++;
				}
				else
				{
					PushArrayCell(players, target);
					dead++;
				}
			}
		}
	}

	new totalMinions=RoundToCeil(alive*ratio);
	if(ratio==0.0)
	{
		totalMinions=MaxClients;
	}
	new config=GetRandomInt(0, maxKV-1);
	new clone, temp;
	for(new i=1; i<=dead && i<=totalMinions; i++)
	{
		temp=GetRandomInt(0, GetArraySize(players)-1);
		clone=GetArrayCell(players, temp);
		RemoveFromArray(players, temp);
		if(LastClass[clone]==TFClass_Unknown)
		{
			LastClass[clone]=TF2_GetPlayerClass(clone);
		}

		FF2_SetFF2flags(clone, FF2_GetFF2flags(clone)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
		ChangeClientTeam(clone, BossTeam);
		TF2_RespawnPlayer(clone);
		CloneOwnerIndex[clone]=client;
		if(class)
		{
			TF2_SetPlayerClass(clone, TFClassType:class);
		}
		else
		{
			TF2_SetPlayerClass(clone, TFClassType:KvGetNum(bossKV[config], "class", 0));
		}

		if(changeModel)
		{
			if(model[0]=='\0')
			{
				KvGetString(bossKV[config], "model", model, PLATFORM_MAX_PATH);
			}
			SetVariantString(model);
			AcceptEntityInput(clone, "SetCustomModel");
			SetEntProp(clone, Prop_Send, "m_bUseClassAnimations", 1);
		}

		switch(weaponMode)
		{
			case 0:
			{
				TF2_RemoveAllWeapons2(clone);
			}
			case 1:
			{
				new weapon;
				TF2_RemoveAllWeapons2(clone);
				if(classname[0]=='\0')
				{
					classname="tf_weapon_bottle";
				}

				if(attributes[0]=='\0')
				{
					attributes="68 ; -1";
				}
				weapon=SpawnWeapon(clone, classname, index, 101, 0, attributes);
				if(IsValidEdict(weapon))
				{
					SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", weapon);
					SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
				}

				SetAmmo(clone, weapon, ammo, clip);
			}
		}

		if(health)
		{
			SetEntProp(clone, Prop_Data, "m_iMaxHealth", health);
			SetEntProp(clone, Prop_Data, "m_iHealth", health);
			SetEntProp(clone, Prop_Send, "m_iHealth", health);
		}

		velocity[0]=GetRandomFloat(300.0, 500.0)*(GetRandomInt(0, 1) ? 1:-1);
		velocity[1]=GetRandomFloat(300.0, 500.0)*(GetRandomInt(0, 1) ? 1:-1);
		velocity[2]=GetRandomFloat(300.0, 500.0);
		TeleportEntity(clone, position, NULL_VECTOR, velocity);

		PrintHintText(clone, "%t", "seeldier_rage_message", bossName);

		SetEntProp(clone, Prop_Data, "m_takedamage", 0);
		SDKHook(clone, SDKHook_OnTakeDamage, SaveMinion);
		CreateTimer(4.0, Timer_Enable_Damage, GetClientUserId(clone));

		new Handle:data;
		CreateDataTimer(0.1, Timer_EquipModel, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, GetClientUserId(clone));
		WritePackString(data, model);
	}
	CloseHandle(players);

	new entity;
	new owner;
	while((entity=FindEntityByClassname(entity, "tf_wearable"))!=-1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
		{
			TF2_RemoveWearable(owner, entity);
		}
	}

	while((entity=FindEntityByClassname(entity, "tf_wearable_demoshield"))!=-1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
		{
			TF2_RemoveWearable(owner, entity);
		}
	}

	while((entity=FindEntityByClassname(entity, "tf_powerup_bottle"))!=-1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
		{
			TF2_RemoveWearable(owner, entity);
		}
	}
}

public Action:Timer_EquipModel(Handle:timer, any:pack)
{
	ResetPack(pack);
	new client=GetClientOfUserId(ReadPackCell(pack));
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:model[PLATFORM_MAX_PATH];
		ReadPackString(pack, model, PLATFORM_MAX_PATH);
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

public Action:Timer_Enable_Damage(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(client>0)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM);
		SDKUnhook(client, SDKHook_OnTakeDamage, SaveMinion);
	}
	return Plugin_Continue;
}

public Action:SaveMinion(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(attacker>MaxClients)
	{
		decl String:edict[64];
		if(GetEdictClassname(attacker, edict, 64) && !strcmp(edict, "trigger_hurt", false))
		{
			new target, Float:position[3];
			new bool:otherTeamIsAlive;
			for(new clone=1; clone<=MaxClients; clone++)
			{
				if(IsValidEdict(clone) && IsClientInGame(clone) && IsPlayerAlive(clone) && GetClientTeam(clone)!=BossTeam)
				{
					otherTeamIsAlive=true;
					break;
				}
			}

			new tries;
			do
			{
				tries++;
				target=GetRandomInt(1, MaxClients);
				if(tries==100)
				{
					return Plugin_Continue;
				}
			}
			while(otherTeamIsAlive && (!IsValidEdict(target) || (GetClientTeam(target)==BossTeam) || !IsPlayerAlive(target)));
			
			GetEntPropVector(target, Prop_Data, "m_vecOrigin", position);
			TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
			TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Demopan_Rage(Handle:timer, any:count)
{
	if(count==13)
	{
		CreateTimer(6.0, Timer_Demopan_Rage, 9001);
	}
	else if(count>13)
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
		for(new client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)!=BossTeam)
			{
				ClientCommand(client, "r_screenoverlay \"freak_fortress_2/demopan/trade_0\"");
			}
		}
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
		return Plugin_Stop;			
	}
	else
	{
		decl String:overlay[128];
		Format(overlay, 128, "r_screenoverlay \"freak_fortress_2/demopan/trade_%i\"", count);
		EmitSoundToAll("ui\\notification_alert.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
		for(new client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)!=BossTeam)
			{
				ClientCommand(client, overlay);
			}
		}

		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
		if(count>1)
		{
			CreateTimer(0.5/(_:count*1.0), Timer_Demopan_Rage, count+1);
		}
		else
		{
			CreateTimer(1.0, Timer_Demopan_Rage, 2);
		}
	}
	return Plugin_Continue;
}

Rage_Bow(client)
{
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	TF2_RemoveWeaponSlot2(boss, TFWeaponSlot_Primary);
	new weapon=SpawnWeapon(boss, "tf_weapon_compound_bow", 1005, 100, 5, "6 ; 0.5 ; 37 ; 0.0 ; 280 ; 19");
	SetEntPropEnt(boss, Prop_Send, "m_hActiveWeapon", weapon);
	new TFTeam:team=(FF2_GetBossTeam()==_:TFTeam_Blue ? TFTeam_Red:TFTeam_Blue);

	new otherTeamAlivePlayers=0;
	for(new target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && TFTeam:GetClientTeam(target)==team && IsPlayerAlive(target))
		{
			otherTeamAlivePlayers++;
		}
	}

	SetAmmo(boss, weapon, ((otherTeamAlivePlayers>=CBS_MAX_ARROWS) ? CBS_MAX_ARROWS:otherTeamAlivePlayers));
}

public Action:Timer_Prepare_Explosion_Rage(Handle:timer, Handle:data)
{
	decl String:ability_name[64];
	ReadPackString(data, ability_name, 64);

	new client=ReadPackCell(data);
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));

	CreateTimer(0.13, Timer_Rage_Explosive_Dance, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	decl Float:position[3];
	GetEntPropVector(boss, Prop_Data, "m_vecOrigin", position);

	new String:sound[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(client, this_plugin_name, ability_name, 1, sound, PLATFORM_MAX_PATH);
	if(strlen(sound))
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
	return Plugin_Continue;
}

public Action:Timer_Rage_Explosive_Dance(Handle:timer, any:client)
{
	static count=0;
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	count++;
	if(count<=35 && IsPlayerAlive(boss))
	{
		SetEntityMoveType(boss, MOVETYPE_NONE);
		new explosion;
		decl Float:bossPosition[3], Float:explosionPosition[3];
		GetEntPropVector(boss, Prop_Send, "m_vecOrigin", bossPosition);
		explosionPosition[2]=bossPosition[2];
		for(new i=0;i<5;i++)
		{
			explosion=CreateEntityByName("env_explosion");   
			DispatchKeyValueFloat(explosion, "DamageForce", 180.0);

			SetEntProp(explosion, Prop_Data, "m_iMagnitude", 280, 4);
			SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", 200, 4);
			SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", boss);

			DispatchSpawn(explosion);

			explosionPosition[0]=bossPosition[0]+GetRandomInt(-350, 350);
			explosionPosition[1]=bossPosition[1]+GetRandomInt(-350, 350);
			if(!(GetEntityFlags(boss) & FL_ONGROUND))
			{
				explosionPosition[2]=bossPosition[2]+GetRandomInt(-150, 150);
			}
			else
			{
				explosionPosition[2]=bossPosition[2]+GetRandomInt(0,100);
			}
			TeleportEntity(explosion, explosionPosition, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(explosion, "Explode");
			AcceptEntityInput(explosion, "kill");
		
			/*proj=CreateEntityByName("tf_projectile_rocket");
			SetVariantInt(BossTeam);
			AcceptEntityInput(proj, "TeamNum", -1, -1, 0);
			SetVariantInt(BossTeam);
			AcceptEntityInput(proj, "SetTeam", -1, -1, 0); 
			SetEntPropEnt(proj, Prop_Send, "m_hOwnerEntity",boss);
			decl Float:position[3];
			new Float:rot[3]={0.0,90.0,0.0};
			new Float:see[3]={0.0,0.0,-1000.0};
			GetEntPropVector(boss, Prop_Send, "m_vecOrigin", position);
			position[0]+=GetRandomInt(-250,250);
			position[1]+=GetRandomInt(-250,250);
			position[2]+=40;
			TeleportEntity(proj, position, rot,see);
			SetEntDataFloat(proj, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, 300.0, true);
			DispatchSpawn(proj);
			CreateTimer(0.1,Timer_Rage_Explosive_Dance_Boom,EntIndextoEntRef(proj));*/
		}
	}
	else
	{
		SetEntityMoveType(boss, MOVETYPE_WALK);		
		count=0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Rage_Slowmo(client, const String:ability_name[])
{
	FF2_SetFF2flags(client, FF2_GetFF2flags(client)|FF2FLAG_CHANGECVAR);
	SetConVarFloat(cvarTimeScale, FF2_GetAbilityArgumentFloat(client, this_plugin_name, ability_name, 2, 0.1));
	new Float:duration=FF2_GetAbilityArgumentFloat(client, this_plugin_name, ability_name, 1, 1.0)+1.0;
	SloMoTimer=CreateTimer(duration, Timer_StopSlomo, client);
	FF2Flags[client]=FF2Flags[client]|FLAG_SLOMOREADYCHANGE|FLAG_ONSLOMO;
	UpdateClientCheatValue(1);
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	if(boss>0)
	{
		if(BossTeam==_:TFTeam_Blue)
		{
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(boss, "scout_dodge_blue", 75.0)));
		}
		else
		{
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(boss, "scout_dodge_red", 75.0)));
		}
	}
	EmitSoundToAll("replay\\enterperformancemode.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
	EmitSoundToAll("replay\\enterperformancemode.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
}

public Action:Timer_StopSlomo(Handle:timer, any:client)
{
	SloMoTimer=INVALID_HANDLE;
	oldTarget=0;
	SetConVarFloat(cvarTimeScale, 1.0);
	UpdateClientCheatValue(0);
	if(client!=-1)
	{
		FF2_SetFF2flags(client, FF2_GetFF2flags(client)&~FF2FLAG_CHANGECVAR);
		FF2Flags[client]&=~FLAG_ONSLOMO;
	}
	EmitSoundToAll("replay\\exitperformancemode.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
	EmitSoundToAll("replay\\exitperformancemode.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:velocity[3], Float:angles[3], &weapon)
{	
	new boss=FF2_GetBossIndex(client);
	if(boss==-1 || !(FF2Flags[boss] & FLAG_ONSLOMO))
	{
		return Plugin_Continue;
	}

	if(buttons & IN_ATTACK)
	{
		FF2Flags[boss]&=~FLAG_SLOMOREADYCHANGE;
		CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_matrix_attack", 3, 0.2), Timer_SlomoChange, boss);

		new Float:bossPosition[3], Float:endPosition[3], Float:eyeAngles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition); 
		bossPosition[2]+=65;
		GetClientEyeAngles(client, eyeAngles);

		new Handle:trace=TR_TraceRayFilterEx(bossPosition, eyeAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf);
		TR_GetEndPosition(endPosition, trace);
		endPosition[2]+=100;
		SubtractVectors(endPosition, bossPosition, velocity);
		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, 2012.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		new target=TR_GetEntityIndex(trace);
		if(target>0 && target<=MaxClients)
		{
			new Handle:data;
			CreateDataTimer(0.15, Timer_Rage_Slomo_Attack, data);
			WritePackCell(data, GetClientUserId(client));
			WritePackCell(data, GetClientUserId(target));
			ResetPack(data);
		}
		CloseHandle(trace);
	}
	return Plugin_Continue;
}

public Action:Timer_Rage_Slomo_Attack(Handle:timer, Handle:data)
{
	new client=GetClientOfUserId(ReadPackCell(data));
	new target=GetClientOfUserId(ReadPackCell(data));
	if(target>0)
	{
		new Float:clientPosition[3], Float:targetPosition[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPosition); 
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition); 
		if(GetVectorDistance(clientPosition, targetPosition)<=1500 && target!=oldTarget)
		{
			SetEntProp(client, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(FF2_GetBossIndex(client), GetEntityFlags(FF2_GetBossIndex(client))|FL_DUCKING);
			SDKHooks_TakeDamage(target, client, client, 900.0);
			TeleportEntity(client, targetPosition, NULL_VECTOR, NULL_VECTOR);
			oldTarget=target;
		}
	}
}

public bool:TraceRayDontHitSelf(entity, mask)
{
	if(!entity || entity>MaxClients)
	{
		return true;
	}

	if(FF2_GetBossIndex(entity)==-1)
	{
		return true;
	}
	return false; 
}


public Action:Timer_SlomoChange(Handle:timer, any:client)
{
	FF2Flags[client]|=FLAG_SLOMOREADYCHANGE;
	return Plugin_Continue;
}


//Unused single rocket shoot charge
/*Charge_RocketSpawn(const String:ability_name[],index,slot,action)
{
	if(FF2_GetBossCharge(index,0)<10)
		return;
	new boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new Float:see=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,5.0);
	new Float:charge=FF2_GetBossCharge(index,slot);
	switch(action)
	{
		case 2:
		{
			SetHudTextParams(-1.0, 0.93, 0.15, 255, 255, 255, 255);
			if(charge+1<see)
				FF2_SetBossCharge(index,slot,charge+1);
			else
				FF2_SetBossCharge(index,slot,see);
			ShowSyncHudText(boss, chargeHUD, "%t","charge_status",RoundFloat(charge*100/see));
		}
		case 3:
		{				
			FF2_SetBossCharge(index,0,charge-10);
			decl Float:position[3];
			decl Float:rot[3];
			decl Float:velocity[3];
			GetEntPropVector(boss, Prop_Send, "m_vecOrigin", position);
			GetClientEyeAngles(boss,rot);
			position[2]+=63;
				
			new proj=CreateEntityByName("tf_projectile_rocket");
			SetVariantInt(BossTeam);
			AcceptEntityInput(proj, "TeamNum", -1, -1, 0);
			SetVariantInt(BossTeam);
			AcceptEntityInput(proj, "SetTeam", -1, -1, 0); 
			SetEntPropEnt(proj, Prop_Send, "m_hOwnerEntity",boss);		
			new Float:speed=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,3,1000.0);
			velocity[0]=Cosine(DegToRad(rot[0]))*Cosine(DegToRad(rot[1]))*speed;
			velocity[1]=Cosine(DegToRad(rot[0]))*Sine(DegToRad(rot[1]))*speed;
			velocity[2]=Sine(DegToRad(rot[0]))*speed;
			velocity[2]*=-1;
			TeleportEntity(proj, position, rot,velocity);
			SetEntDataFloat(proj, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,5,150.0), true);
			DispatchSpawn(proj);
			new String:s[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name,4,s,PLATFORM_MAX_PATH);
			if(strlen(s)>5)
				SetEntityModel(proj,s);
			FF2_SetBossCharge(index,slot,-5*FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0));
			if(FF2_RandomSound("sound_ability",s,PLATFORM_MAX_PATH,index,slot))
			{
				EmitSoundToAll(s, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);
				EmitSoundToAll(s, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);
			
				for(new i=1; i<=MaxClients; i++)
					if(IsClientInGame(i) && i!=boss)
					{
						EmitSoundToClient(i,s, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);
						EmitSoundToClient(i,s, boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, boss, position, NULL_VECTOR, true, 0.0);
					}
			}
		}
	}
}
*/


public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
	{
		return Plugin_Continue;
	}

	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new bossAttacker=FF2_GetBossIndex(attacker);
	new bossClient=FF2_GetBossIndex(client);
	if(bossAttacker!=-1)
	{
		if(FF2_HasAbility(bossAttacker, this_plugin_name, "special_dropprop"))
		{
			if(FF2_GetAbilityArgument(bossAttacker,this_plugin_name,"special_dropprop", 3, 0))
			{
				CreateTimer(0.01, Timer_RemoveRagdoll, GetEventInt(event, "userid"));
			}

			new prop=CreateEntityByName("prop_physics_override");
			if(IsValidEntity(prop))
			{
				decl String:model[PLATFORM_MAX_PATH];
				FF2_GetAbilityArgumentString(bossAttacker, this_plugin_name, "special_dropprop", 1, model, PLATFORM_MAX_PATH);
				SetEntityModel(prop, model);
				SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
				SetEntProp(prop, Prop_Send, "m_CollisionGroup", 1);
				SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16);
				DispatchSpawn(prop);
				new Float:position[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
				position[2]+=20;				
				TeleportEntity(prop, position, NULL_VECTOR, NULL_VECTOR);
				new Float:duration=FF2_GetAbilityArgumentFloat(bossAttacker, this_plugin_name, "special_dropprop", 2, 0.0);
				if(duration>0.5)
				{
					CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(prop));
				}
			}
		}

		if(FF2_HasAbility(bossAttacker, this_plugin_name, "special_cbs_multimelee"))
		{
			if(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon")==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
			{
				TF2_RemoveWeaponSlot2(attacker, TFWeaponSlot_Melee);
				new weapon;
				switch(GetRandomInt(0, 2))
				{
					case 0:
					{
						weapon=SpawnWeapon(attacker,"tf_weapon_club", 171, 101, 5, "68 ; 2 ; 2 ; 3.0");
					}
					case 1:
					{
						weapon=SpawnWeapon(attacker,"tf_weapon_club", 193, 101, 5, "68 ; 2 ; 2 ; 3.0");
					}
					case 2:
					{
						weapon=SpawnWeapon(attacker,"tf_weapon_club", 232, 101, 5, "68 ; 2 ; 2 ; 3.0");
					}
				}
				SetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon", weapon);
			}
		}
	}
	else
	{
		if(GetClientTeam(client)==BossTeam)
		{
			CreateTimer(0.5, Timer_RestoreLastClass, GetClientUserId(client));
		}
	}

	if(bossClient!=-1)
	{
		if(FF2_HasAbility(bossClient, this_plugin_name, "rage_cloneattack"))
		{
			for(new target=1; target<=MaxClients; target++)
			{
				if(CloneOwnerIndex[target]==bossClient && IsValidEdict(target) && IsClientConnected(target) && IsPlayerAlive(target) && GetClientTeam(target)==BossTeam)
				{
					CreateTimer(0.5, Timer_RestoreLastClass, GetClientUserId(target));
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_RestoreLastClass(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(LastClass[client])
	{
		TF2_SetPlayerClass(client, LastClass[client]);
	}
	LastClass[client]=TFClass_Unknown;

	if(BossTeam==_:TFTeam_Red)
	{
		ChangeClientTeam(client, _:TFTeam_Blue);
	}
	else
	{
		ChangeClientTeam(client, _:TFTeam_Red);
	}
	return Plugin_Continue;
}

public Action:Timer_RemoveRagdoll(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	new ragdoll;
	if(client>0 && (ragdoll=GetEntPropEnt(client, Prop_Send, "m_hRagdoll"))>MaxClients)
	{
		AcceptEntityInput(ragdoll, "Kill");
	}
}

stock SpawnWeapon(client, String:name[], index, level, quality, String:attribute[])
{
	new Handle:weapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	new String:attributes[32][32];
	new count = ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		new i2=0;
		for(new i=0; i<count; i+=2)
		{
			new attrib=StringToInt(attributes[i]);
			if(attrib==0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if(weapon==INVALID_HANDLE)
	{
		return -1;
	}
	new entity=TF2Items_GiveNamedItem(client, weapon);
	CloseHandle(weapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock SetAmmo(client, weapon, ammo=0, clip=0)
{
	if(IsValidEntity(weapon))
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
		new offset=GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
		if(offset!=-1)
		{
			if(ammo>0)
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, 4, offset);
			}
		}
		else
		{
			new String:classname[64];
			GetEdictClassname(weapon, classname, sizeof(classname));
			new String:bossName[32];
			FF2_GetBossSpecial(client, bossName, sizeof(bossName));
			LogError("[FF2] Cannot give ammo to weapon %s (boss %s)-check your config!", classname, bossName);
		}
	}
}

public Action:Timer_RemoveEntity(Handle:timer, any:entid)
{
	new entity=EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MaxClients)
	{
		if(TF2_IsWearable(entity))
		{
			for(new client=1; client<MaxClients; client++)
			{
				if(IsValidEdict(client) && IsClientInGame(client))
				{
					TF2_RemoveWearable(client, entity);
				}
			}
		}
		else
		{
			AcceptEntityInput(entity, "Kill");
		}
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

//By Mecha the Slag
UpdateClientCheatValue(const value)
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidEdict(client) && IsClientConnected(client) && !IsFakeClient(client))
		{
			decl String:cheatValue[2];
			IntToString(value, cheatValue, sizeof(cheatValue));
			SendConVarValue(client, cvarCheats, cheatValue);
		}
	}
}