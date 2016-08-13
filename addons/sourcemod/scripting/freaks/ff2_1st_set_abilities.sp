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

#define SOUND_SLOW_MO_START "replay/enterperformancemode.wav"  //Used when Ninja Spy enters slow mo
#define SOUND_SLOW_MO_END "replay/exitperformancemode.wav"  //Used when Ninja Spy exits slow mo
#define SOUND_DEMOPAN_RAGE "ui/notification_alert.wav"  //Used when Demopan rages

#define PLUGIN_VERSION "1.10.7"

public Plugin:myinfo=
{
	name="Freak Fortress 2: Abilities of 1st set",
	author="RainBolt Dash",
	description="FF2: Abilities used by Seeldier, Seeman, Demopan, CBS, and Ninja Spy",
	version=PLUGIN_VERSION,
};

#define FLAG_ONSLOWMO			(1<<0)
#define FLAG_SLOWMOREADYCHANGE	(1<<1)

new FF2Flags[MAXPLAYERS+1];
new CloneOwnerIndex[MAXPLAYERS+1]=-1;

new Handle:SlowMoTimer;
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
	new version[3];
	FF2_GetFF2Version(version);
	if(version[0]==1 && (version[1]<10 || (version[1]==10 && version[2]<3)))
	{
		SetFailState("This subplugin depends on at least FF2 v1.10.3");
	}

	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("player_death", OnPlayerDeath);

	cvarTimeScale=FindConVar("host_timescale");
	cvarCheats=FindConVar("sv_cheats");
	cvarKAC=FindConVar("kac_enable");

	LoadTranslations("ff2_1st_set.phrases");
}

public OnMapStart()
{
	PrecacheSound(SOUND_SLOW_MO_START, true);
	PrecacheSound(SOUND_SLOW_MO_END, true);
	PrecacheSound(SOUND_DEMOPAN_RAGE, true);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3, Timer_GetBossTeam, _, TIMER_FLAG_NO_MAPCHANGE);
	for(new client=1; client<=MaxClients; client++)
	{
		FF2Flags[client]=0;
		CloneOwnerIndex[client]=-1;
	}
	return Plugin_Continue;
}

/*public Action:FF2_OnSpecialSelected(boss, &special, String:specialName[])  //Re-enable in v2 or whenever the late-loading forward bug is fixed
{
	if(FF2_HasAbility(boss, this_plugin_name, "special_dropprop"))
	{
		decl String:model[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "special_dropprop", 1, model, sizeof(model));
		PrecacheModel(model);
	}
	return Plugin_Continue;
}*/

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(FF2Flags[client] & FLAG_ONSLOWMO)
		{
			if(SlowMoTimer)
			{
				KillTimer(SlowMoTimer);
			}
			Timer_StopSlowMo(INVALID_HANDLE, -1);
			return Plugin_Continue;
		}

		if(IsClientInGame(client) && CloneOwnerIndex[client]!=-1 && GetClientTeam(client)==BossTeam)  //FIXME: IsClientInGame() shouldn't be needed
		{
			CloneOwnerIndex[client]=-1;
			FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_CLASSTIMERDISABLED);
		}
	}
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	FF2Flags[client]=0;
	if(CloneOwnerIndex[client]!=-1)
	{
		CloneOwnerIndex[client]=-1;
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_CLASSTIMERDISABLED);
	}
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

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], status)
{
	new slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0);
	if(!slot)  //Rage
	{
		if(!boss)
		{
			new Action:action=Plugin_Continue;
			Call_StartForward(OnHaleRage);
			new Float:distance=FF2_GetRageDist(boss, this_plugin_name, ability_name);
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
			new client=GetClientOfUserId(FF2_GetBossUserId(boss));
			new Float:charge=FF2_GetBossCharge(boss, 0);
			SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", 100.0);
			TF2_AddCondition(client, TFCond_Charging, 0.25);
			if(charge>10.0 && charge<90.0)
			{
				FF2_SetBossCharge(boss, 0, charge-0.4);
			}
		}
	}
	else if(!strcmp(ability_name, "rage_cloneattack"))
	{
		Rage_Clone(ability_name, boss);
	}
	else if(!strcmp(ability_name, "rage_tradespam"))
	{
		CreateTimer(0.0, Timer_Demopan_Rage, 1, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(!strcmp(ability_name, "rage_cbs_bowrage"))
	{
		Rage_Bow(boss);
	}
	else if(!strcmp(ability_name, "rage_explosive_dance"))
	{
		SetEntityMoveType(GetClientOfUserId(FF2_GetBossUserId(boss)), MOVETYPE_NONE);
		new Handle:data;
		CreateDataTimer(0.15, Timer_Prepare_Explosion_Rage, data);
		WritePackString(data, ability_name);
		WritePackCell(data, boss);
		ResetPack(data);
	}
	else if(!strcmp(ability_name, "rage_matrix_attack"))
	{
		Rage_Slowmo(boss, ability_name);
	}
	return Plugin_Continue;
}

Rage_Clone(const String:ability_name[], boss)
{
	new Handle:bossKV[8];
	decl String:bossName[32];
	new bool:changeModel=bool:FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 1);
	new weaponMode=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 2);
	decl String:model[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 3, model, sizeof(model));
	new class=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 4);
	new Float:ratio=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 5, 0.0);
	new String:classname[64]="tf_weapon_bottle";
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 6, classname, sizeof(classname));
	new index=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 7, 191);
	new String:attributes[64]="68 ; -1";
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 8, attributes, sizeof(attributes));
	new ammo=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 9, -1);
	new clip=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 10, -1);
	new health=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 11, 0);

	new Float:position[3], Float:velocity[3];
	GetEntPropVector(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Data, "m_vecOrigin", position);

	FF2_GetBossSpecial(boss, bossName, sizeof(bossName));

	new maxKV;
	for(maxKV=0; maxKV<8; maxKV++)
	{
		if(!(bossKV[maxKV]=FF2_GetSpecialKV(maxKV)))
		{
			break;
		}
	}

	new alive, dead;
	new Handle:players=CreateArray();
	for(new target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target))
		{
			new TFTeam:team=TFTeam:GetClientTeam(target);
			if(team>TFTeam_Spectator && team!=TFTeam_Blue)
			{
				if(IsPlayerAlive(target))
				{
					alive++;
				}
				else if(FF2_GetBossIndex(target)==-1)  //Don't let dead bosses become clones
				{
					PushArrayCell(players, target);
					dead++;
				}
			}
		}
	}

	new totalMinions=(ratio ? RoundToCeil(alive*ratio) : MaxClients);  //If ratio is 0, use MaxClients instead
	new config=GetRandomInt(0, maxKV-1);
	new clone, temp;
	for(new i=1; i<=dead && i<=totalMinions; i++)
	{
		temp=GetRandomInt(0, GetArraySize(players)-1);
		clone=GetArrayCell(players, temp);
		RemoveFromArray(players, temp);

		FF2_SetFF2flags(clone, FF2_GetFF2flags(clone)|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_CLASSTIMERDISABLED);
		ChangeClientTeam(clone, BossTeam);
		TF2_RespawnPlayer(clone);
		CloneOwnerIndex[clone]=boss;
		TF2_SetPlayerClass(clone, (class ? (TFClassType:class) : (TFClassType:KvGetNum(bossKV[config], "class", 0))), _, false);

		if(changeModel)
		{
			if(model[0]=='\0')
			{
				KvGetString(bossKV[config], "model", model, sizeof(model));
			}
			SetVariantString(model);
			AcceptEntityInput(clone, "SetCustomModel");
			SetEntProp(clone, Prop_Send, "m_bUseClassAnimations", 1);
		}

		switch(weaponMode)
		{
			case 0:
			{
				TF2_RemoveAllWeapons(clone);
			}
			case 1:
			{
				new weapon;
				TF2_RemoveAllWeapons(clone);
				if(classname[0]=='\0')
				{
					classname="tf_weapon_bottle";
				}

				if(attributes[0]=='\0')
				{
					attributes="68 ; -1";
				}

				weapon=SpawnWeapon(clone, classname, index, 101, 0, attributes);
				if(StrEqual(classname, "tf_weapon_builder") && index!=735)  //PDA, normal sapper
				{
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
				}
				else if(StrEqual(classname, "tf_weapon_sapper") || index==735)  //Sappers, normal sapper
				{
					SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
					SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
				}

				if(IsValidEntity(weapon))
				{
					SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", weapon);
					SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
				}

				FF2_SetAmmo(clone, weapon, ammo, clip);
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
		CreateTimer(4.0, Timer_Enable_Damage, GetClientUserId(clone), TIMER_FLAG_NO_MAPCHANGE);

		new Handle:data;
		CreateDataTimer(0.1, Timer_EquipModel, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, GetClientUserId(clone));
		WritePackString(data, model);
	}
	CloseHandle(players);

	new entity, owner;
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
	if(client)
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
		if(GetEntityClassname(attacker, edict, sizeof(edict)) && !strcmp(edict, "trigger_hurt", false))
		{
			new target, Float:position[3];
			new bool:otherTeamIsAlive;
			for(new clone=1; clone<=MaxClients; clone++)
			{
				if(IsValidEntity(clone) && IsClientInGame(clone) && IsPlayerAlive(clone) && GetClientTeam(clone)!=BossTeam)
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
			while(otherTeamIsAlive && (!IsValidEntity(target) || GetClientTeam(target)==BossTeam || !IsPlayerAlive(target)));

			GetEntPropVector(target, Prop_Data, "m_vecOrigin", position);
			TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
			TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Demopan_Rage(Handle:timer, any:count)  //TODO: Make this rage configurable
{
	if(count==13)  //Rage has finished-reset it in 6 seconds (trade_0 is 100% transparent apparently)
	{
		CreateTimer(6.0, Timer_Demopan_Rage, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		decl String:overlay[PLATFORM_MAX_PATH];
		Format(overlay, sizeof(overlay), "r_screenoverlay \"freak_fortress_2/demopan/trade_%i\"", count);

		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);  //Allow normal players to use r_screenoverlay
		for(new client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)!=BossTeam)
			{
				ClientCommand(client, overlay);
			}
		}
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);  //Reset the cheat permissions

		if(count)
		{
			EmitSoundToAll(SOUND_DEMOPAN_RAGE, _, _, _, _, _, _, _, _, _, false);
			CreateTimer(count==1 ? 1.0 : 0.5/float(count), Timer_Demopan_Rage, count+1, TIMER_FLAG_NO_MAPCHANGE);  //Give a longer delay between the first and second overlay for "smoothness"
		}
		else  //Stop the rage
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

Rage_Bow(boss)
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
	new weapon=SpawnWeapon(client, "tf_weapon_compound_bow", 1005, 100, 5, "6 ; 0.5 ; 37 ; 0.0 ; 280 ; 19");
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	new TFTeam:team=(FF2_GetBossTeam()==_:TFTeam_Blue ? TFTeam_Red:TFTeam_Blue);

	new otherTeamAlivePlayers;
	for(new target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && TFTeam:GetClientTeam(target)==team && IsPlayerAlive(target))
		{
			otherTeamAlivePlayers++;
		}
	}

	FF2_SetAmmo(client, weapon, ((otherTeamAlivePlayers>=CBS_MAX_ARROWS) ? CBS_MAX_ARROWS : otherTeamAlivePlayers)-1, 1);  //Put one arrow in the clip
}

public Action:Timer_Prepare_Explosion_Rage(Handle:timer, Handle:data)
{
	new boss=ReadPackCell(data);
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));

	decl String:ability_name[64];
	ReadPackString(data, ability_name, sizeof(ability_name));

	CreateTimer(0.13, Timer_Rage_Explosive_Dance, boss, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	new Float:position[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", position);

	new String:sound[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 1, sound, PLATFORM_MAX_PATH);
	if(strlen(sound))
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
	return Plugin_Continue;
}

public Action:Timer_Rage_Explosive_Dance(Handle:timer, any:boss)
{
	static count;
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	count++;
	if(count<=35 && IsPlayerAlive(client))
	{
		SetEntityMoveType(boss, MOVETYPE_NONE);
		new Float:bossPosition[3], Float:explosionPosition[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);
		explosionPosition[2]=bossPosition[2];
		for(new i; i<5; i++)
		{
			new explosion=CreateEntityByName("env_explosion");
			DispatchKeyValueFloat(explosion, "DamageForce", 180.0);

			SetEntProp(explosion, Prop_Data, "m_iMagnitude", 280, 4);
			SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", 200, 4);
			SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);

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
		SetEntityMoveType(client, MOVETYPE_WALK);
		count=0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Rage_Slowmo(boss, const String:ability_name[])
{
	FF2_SetFF2flags(boss, FF2_GetFF2flags(boss)|FF2FLAG_CHANGECVAR);
	SetConVarFloat(cvarTimeScale, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 2, 0.1));
	new Float:duration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 1.0)+1.0;
	SlowMoTimer=CreateTimer(duration, Timer_StopSlowMo, boss, TIMER_FLAG_NO_MAPCHANGE);
	FF2Flags[boss]=FF2Flags[boss]|FLAG_SLOWMOREADYCHANGE|FLAG_ONSLOWMO;
	UpdateClientCheatValue(1);

	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(client)
	{
		CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(client, BossTeam==_:TFTeam_Blue ? "scout_dodge_blue" : "scout_dodge_red", 75.0)), TIMER_FLAG_NO_MAPCHANGE);
	}

	EmitSoundToAll(SOUND_SLOW_MO_START, _, _, _, _, _, _, _, _, _, false);
	EmitSoundToAll(SOUND_SLOW_MO_START, _, _, _, _, _, _, _, _, _, false);
}

public Action:Timer_StopSlowMo(Handle:timer, any:boss)
{
	SlowMoTimer=INVALID_HANDLE;
	oldTarget=0;
	SetConVarFloat(cvarTimeScale, 1.0);
	UpdateClientCheatValue(0);
	if(boss!=-1)
	{
		FF2_SetFF2flags(boss, FF2_GetFF2flags(boss) & ~FF2FLAG_CHANGECVAR);
		FF2Flags[boss]&=~FLAG_ONSLOWMO;
	}
	EmitSoundToAll(SOUND_SLOW_MO_END, _, _, _, _, _, _, _, _, _, false);
	EmitSoundToAll(SOUND_SLOW_MO_END, _, _, _, _, _, _, _, _, _, false);
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:velocity[3], Float:angles[3], &weapon)
{
	new boss=FF2_GetBossIndex(client);
	if(boss==-1 || !(FF2Flags[boss] & FLAG_ONSLOWMO))
	{
		return Plugin_Continue;
	}

	if(buttons & IN_ATTACK)
	{
		FF2Flags[boss]&=~FLAG_SLOWMOREADYCHANGE;
		CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_matrix_attack", 3, 0.2), Timer_SlowMoChange, boss, TIMER_FLAG_NO_MAPCHANGE);

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
		if(target && target<=MaxClients)
		{
			new Handle:data;
			CreateDataTimer(0.15, Timer_Rage_SlowMo_Attack, data);
			WritePackCell(data, GetClientUserId(client));
			WritePackCell(data, GetClientUserId(target));
			ResetPack(data);
		}
		CloseHandle(trace);
	}
	return Plugin_Continue;
}

public Action:Timer_Rage_SlowMo_Attack(Handle:timer, Handle:data)
{
	new client=GetClientOfUserId(ReadPackCell(data));
	new target=GetClientOfUserId(ReadPackCell(data));
	if(client && target && IsClientInGame(client) && IsClientInGame(target))
	{
		new Float:clientPosition[3], Float:targetPosition[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPosition);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition);
		if(GetVectorDistance(clientPosition, targetPosition)<=1500 && target!=oldTarget)
		{
			SetEntProp(client, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
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


public Action:Timer_SlowMoChange(Handle:timer, any:boss)
{
	FF2Flags[boss]|=FLAG_SLOWMOREADYCHANGE;
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

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new boss=FF2_GetBossIndex(attacker);

	if(boss!=-1)
	{
		if(FF2_HasAbility(boss, this_plugin_name, "special_dropprop"))
		{
			decl String:model[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(boss, this_plugin_name, "special_dropprop", 1, model, sizeof(model));
			if(model[0]!='\0')  //Because you never know when someone is careless and doesn't specify a model...
			{
				if(!IsModelPrecached(model))  //Make sure the boss author precached the model (similar to above)
				{
					new String:bossName[64];
					FF2_GetBossSpecial(boss, bossName, sizeof(bossName));
					if(!FileExists(model, true))
					{
						LogError("[FF2 Bosses] Model '%s' doesn't exist!  Please check %s's config", model, bossName);
						return Plugin_Continue;
					}

					LogError("[FF2 Bosses] Model '%s' isn't precached!  Please check %s's \"mod_precache\"", model, bossName);
					PrecacheModel(model);
				}

				if(FF2_GetAbilityArgument(boss, this_plugin_name, "special_dropprop", 3, 0))
				{
					CreateTimer(0.01, Timer_RemoveRagdoll, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
				}

				new prop=CreateEntityByName("prop_physics_override");
				if(IsValidEntity(prop))
				{
					SetEntityModel(prop, model);
					SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
					SetEntProp(prop, Prop_Send, "m_CollisionGroup", 1);
					SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16);
					DispatchSpawn(prop);

					new Float:position[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
					position[2]+=20;
					TeleportEntity(prop, position, NULL_VECTOR, NULL_VECTOR);
					new Float:duration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_dropprop", 2, 0.0);
					if(duration>0.5)
					{
						CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(prop), TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}

		if(FF2_HasAbility(boss, this_plugin_name, "special_cbs_multimelee"))
		{
			if(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon")==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
			{
				TF2_RemoveWeaponSlot(attacker, TFWeaponSlot_Melee);
				new weapon;
				switch(GetRandomInt(0, 2))
				{
					case 0:
					{
						weapon=SpawnWeapon(attacker, "tf_weapon_club", 171, 101, 5, "68 ; 2 ; 2 ; 3.0");
					}
					case 1:
					{
						weapon=SpawnWeapon(attacker, "tf_weapon_club", 193, 101, 5, "68 ; 2 ; 2 ; 3.0");
					}
					case 2:
					{
						weapon=SpawnWeapon(attacker, "tf_weapon_club", 232, 101, 5, "68 ; 2 ; 2 ; 3.0");
					}
				}
				SetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon", weapon);
			}
		}
	}

	boss=FF2_GetBossIndex(client);
	if(boss!=-1 && FF2_HasAbility(boss, this_plugin_name, "rage_cloneattack") && FF2_GetAbilityArgument(boss, this_plugin_name, "rage_cloneattack", 12, 1) && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		for(new target=1; target<=MaxClients; target++)
		{
			if(CloneOwnerIndex[target]==boss)
			{
				CloneOwnerIndex[target]=-1;
				FF2_SetFF2flags(target, FF2_GetFF2flags(target) & ~FF2FLAG_CLASSTIMERDISABLED);
				if(IsClientInGame(target) && GetClientTeam(target)==BossTeam)
				{
					ChangeClientTeam(target, (BossTeam==_:TFTeam_Blue) ? (_:TFTeam_Red) : (_:TFTeam_Blue));
				}
			}
		}
	}

	if(CloneOwnerIndex[client]!=-1 && GetClientTeam(client)==BossTeam)  //Switch clones back to the other team after they die
	{
		CloneOwnerIndex[client]=-1;
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_CLASSTIMERDISABLED);
		ChangeClientTeam(client, (BossTeam==_:TFTeam_Blue) ? (_:TFTeam_Red) : (_:TFTeam_Blue));
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

public Action:Timer_RemoveEntity(Handle:timer, any:entid)
{
	new entity=EntRefToEntIndex(entid);
	if(IsValidEntity(entity) && entity>MaxClients)
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

stock UpdateClientCheatValue(value)
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			SendConVarValue(client, cvarCheats, value ? "1" : "0");
		}
	}
}
