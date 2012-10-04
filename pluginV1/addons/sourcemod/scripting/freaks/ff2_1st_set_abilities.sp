#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <colors>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define ME 2048

public Plugin:myinfo = {
	name = "Freak Fortress 2: Abilities of 1st set",
	author = "RainBolt Dash",
};

#define FLAG_ONSLOMO			(1<<0)
#define FLAG_SLOMOREADYCHANGE	(1<<1)
new ff2flags[MAXPLAYERS+1];
new TFClassType:LastClass[MAXPLAYERS+1];
new CloneOwnerIndex[MAXPLAYERS+1];

new Handle:SloMoTimer;

new Handle:OnHaleRage = INVALID_HANDLE;

//new Handle:chargeHUD;
new Handle:cvarTimeScale;
new Handle:cvarCheats;
new Handle:cvarKAC;
new BossTeam=_:TFTeam_Blue;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	OnHaleRage = CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);	
	
	return APLRes_Success;
}


public OnPluginStart2()
{
	//chargeHUD = CreateHudSynchronizer();
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("teamplay_round_win", event_round_end);
	HookEvent("player_death", event_player_death);
	LoadTranslations("ff2_1st_set.phrases");
	//LoadTranslations("freak_fortress_2.phrases");
	
	cvarTimeScale = FindConVar("host_timescale");
	cvarCheats = FindConVar("sv_cheats");
	cvarKAC = FindConVar("kac_enable");
}

public OnMapStart()
{
	PrecacheSound("replay\\exitperformancemode.wav",true);
	PrecacheSound("replay\\enterperformancemode.wav",true);
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3,Timer_GetBossTeam);
	for(new i=0;i<=MaxClients;i++)
	{
		ff2flags[i]=0;
		CloneOwnerIndex[i]=-1;
	}
	return Plugin_Continue;
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new index=0;index<=MaxClients;index++)
		if (ff2flags[index]&FLAG_ONSLOMO)
		{
			if (SloMoTimer)
				KillTimer(SloMoTimer);
			Timer_StopSlomo(INVALID_HANDLE,-1);
			return Plugin_Continue;		
		}
	return Plugin_Continue;
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
	if (cvarKAC && GetConVarBool(cvarKAC))
		SetConVarBool(cvarKAC,false);
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	new slot=FF2_GetAbilityArgument(index,this_plugin_name,ability_name,0);
	if (!slot)
	{
		if (index == 0)		//Starts VSH rage ability forward
		{
			new Action:act = Plugin_Continue;
			Call_StartForward(OnHaleRage);
			new Float:dist=FF2_GetRageDist(index,this_plugin_name,ability_name);
			new Float:newdist=dist;
			Call_PushFloatRef(newdist);
			Call_Finish(act);
			if (act != Plugin_Continue && act != Plugin_Changed)
				return Plugin_Continue;
			if (act == Plugin_Changed) dist = newdist;	
		}
	}
	
	//slot 2
	if (!strcmp(ability_name,"special_democharge"))
	{
		if (action>0)
		{
			new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
			new Float:charge=FF2_GetBossCharge(index,0);
			SetEntPropFloat(Boss, Prop_Send, "m_flChargeMeter", 100.0);		
			TF2_AddCondition(Boss,TFCond_Charging,0.25);	
			if (charge>10.0 && charge<90.0)
				FF2_SetBossCharge(index,0,charge-0.4);
		}
	}
	//slot 0
	else if (!strcmp(ability_name,"rage_cloneattack"))
		Rage_CloneAttack(ability_name,index);					//Seeldier's Clone Attack
	else if (!strcmp(ability_name,"rage_tradespam"))
		Rage_Timer_Demopan_Trade_Spam(INVALID_HANDLE,1);	//Demopan's Trade Span
	else if (!strcmp(ability_name,"rage_cbs_bowrage"))
		Rage_UseBow(index);									//CBS' Bow Rage
	else if (!strcmp(ability_name,"rage_explosive_dance"))
	{														//Seeman's explosive dance
		SetEntityMoveType(GetClientOfUserId(FF2_GetBossUserId(index)), MOVETYPE_NONE);
		new Handle:data;
		CreateDataTimer(0.15,Rage_Timer_Explosive_Dance,data);
		WritePackString(data, ability_name);
		WritePackCell(data, index);
		ResetPack(data);
	}
	//slot -1
	else if (!strcmp(ability_name,"rage_matrix_attack"))	//Ninja Spy's slo-mo attack
		Rage_UseSlomo(index,ability_name);
	return Plugin_Continue;
}		


//Seeldier's clone attack rage
Rage_CloneAttack(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new bool:changemodel=bool:FF2_GetAbilityArgument(index,this_plugin_name,ability_name,1);
	new weaponmode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name,2);
	decl weapon;
	new Handle:BossKV[8];
	decl Float:pos[3];
	decl Float:vel[3];
	decl String:s[PLATFORM_MAX_PATH];
	decl String:bossname[32];
	
	GetEntPropVector(Boss, Prop_Data, "m_vecOrigin", pos);
	FF2_GetBossSpecial(index,bossname,32);
	decl maxkv;
	for(maxkv=0;maxkv<8;maxkv++)
	{
		if (!(BossKV[maxkv]=FF2_GetSpecialKV(maxkv)))
			break;
	}
	for(new client=1;client<=MaxClients;client++)
		if (IsValidEdict(client) && IsClientConnected(client) && !IsPlayerAlive(client) && GetClientTeam(client)>_:TFTeam_Spectator)
		{
			if (LastClass[client] == TFClass_Unknown)
				LastClass[client] = TF2_GetPlayerClass(client);
			FF2_SetFF2flags(client,FF2_GetFF2flags(client)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
			ChangeClientTeam(client, BossTeam);
			TF2_RespawnPlayer(client);
			CloneOwnerIndex[client]=index;
			if (changemodel)
			{
				new see=GetRandomInt(0,maxkv-1);
				TF2_SetPlayerClass(client,TFClassType:KvGetNum(BossKV[see], "class",0));
				KvGetString(BossKV[see], "model",s, PLATFORM_MAX_PATH);
				SetVariantString(s);
				AcceptEntityInput(client, "SetCustomModel");
				SetEntProp(client, Prop_Send, "m_bUseClassAnimations",1);
			}
			switch (weaponmode)
			{
				case 0:
					TF2_RemoveAllWeapons(client);
				case 1:
				{
					TF2_RemoveAllWeapons(client);
					weapon=SpawnWeapon(client,"tf_weapon_bottle",191,34,0,"");
					if (IsValidEdict(weapon))
					{
						SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon",weapon);
						SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
					}
				}
			}
			
			vel[0]=GetRandomFloat(300.0,500.0)*(GetRandomInt(1,0)?1:-1);
			vel[1]=GetRandomFloat(300.0,500.0)*(GetRandomInt(1,0)?1:-1);
			vel[2]=GetRandomFloat(300.0,500.0);
			TeleportEntity(client, pos, NULL_VECTOR, vel);
			PrintHintText(client,"%t","seeldier_rage_message",bossname);
			SetEntProp(client, Prop_Data, "m_takedamage", 0);
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_SaveMinion);
			CreateTimer(4.0,Timer_Enable_Damage,GetClientUserId(client));
		}
	new ent = MaxClients+1;
	decl owner;
	while ((ent = FindEntityByClassname(ent, "tf_wearable")) != -1)
	{
		if ((owner=GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
			AcceptEntityInput(ent, "kill");
	}
	while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1)
	{
		if ((owner=GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
			AcceptEntityInput(ent, "kill");
	}
}

public Action:Timer_Enable_Damage(Handle:hTimer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if (client>0)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		FF2_SetFF2flags(client,FF2_GetFF2flags(client) & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage_SaveMinion);
	}
	return Plugin_Continue;
}

//If Seeldier's minion was spawned in a pit.
public Action:OnTakeDamage_SaveMinion(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (attacker>MaxClients)
	{
		decl String:s[64];
		if (GetEdictClassname(attacker, s, 64) && !strcmp(s, "trigger_hurt", false))
		{
			new pingas;
			decl target,Float:pos[3];
			new bool:RedAlivePlayers;
			for(new i=1;i<=MaxClients;i++)
				if(IsValidEdict(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
				{
					RedAlivePlayers=true;
					break;
				}
			do
			{
				pingas++;
				target=GetRandomInt(1,MaxClients);
				if (pingas==100)
					return Plugin_Continue;
			}
			while (RedAlivePlayers && (!IsValidEdict(target) || (GetClientTeam(target)==BossTeam) || !IsPlayerAlive(target)));
			
			GetEntPropVector(target, Prop_Data, "m_vecOrigin", pos);
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
			TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, client);
			
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}


//Demopan's trade spam rage
public Action:Rage_Timer_Demopan_Trade_Spam(Handle:hTimer,any:count)
{
	decl i;
	if (count==13)
		CreateTimer(6.0,Rage_Timer_Demopan_Trade_Spam,9001);
	else if (count>13)
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
		for (i=1; i<=MaxClients; i++)
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
				ClientCommand(i, "r_screenoverlay \"freak_fortress_2/demopan/trade_0\"");
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
		return Plugin_Stop;			
	}
	else
	{
		decl String:s[128];
		Format(s,128,"r_screenoverlay \"freak_fortress_2/demopan/trade_%i\"",count);
		EmitSoundToAll("ui\\notification_alert.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
		for (i=1; i<=MaxClients; i++)
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
				ClientCommand(i,s);
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
		if (count>1)
			CreateTimer(0.5/(_:count*1.0),Rage_Timer_Demopan_Trade_Spam,count+1);	
		else
			CreateTimer(1.0,Rage_Timer_Demopan_Trade_Spam,2);
	}
	return Plugin_Continue;
}

//CBS's bow rage
Rage_UseBow(index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Primary);
	SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_compound_bow", 56, 100, 5, "6 ; 0.5 ; 37 ; 0.0"));
	SetAmmo(Boss, TFWeaponSlot_Primary,9);
}


//Seeman's explosive dance
public Action:Rage_Timer_Explosive_Dance(Handle:hTimer,Handle:data)
{
	decl String:ability_name[64];
	ReadPackString(data, ability_name,64);
	new index=ReadPackCell(data);
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	CreateTimer(0.13, Rage_Timer_Explosive_DanceB, index, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	decl Float:pos[3];
	GetEntPropVector(Boss, Prop_Data, "m_vecOrigin", pos);
	new String:s[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name,1,s,PLATFORM_MAX_PATH);
	if (strlen(s))
	{
		EmitSoundToAll(s, Boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss, pos, NULL_VECTOR, true, 0.0);
		EmitSoundToAll(s, Boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss, pos, NULL_VECTOR, true, 0.0);
		for (new i=1; i<=MaxClients; i++)
			if (IsClientInGame(i) && (i!=Boss))
			{
				EmitSoundToClient(i,s, Boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss, pos, NULL_VECTOR, true, 0.0);
				EmitSoundToClient(i,s, Boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss, pos, NULL_VECTOR, true, 0.0);
			}
	}
	return Plugin_Continue;
}

public Action:Rage_Timer_Explosive_DanceB(Handle:hTimer,any:index)
{
	static count=0;
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	count++;
	if (count<=35 && IsPlayerAlive(Boss))
	{
		SetEntityMoveType(Boss, MOVETYPE_NONE);
		decl proj;
		decl Float:pos[3],Float:pos2[3];
		GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
		pos2[2]=pos[2];
		for(new i=0;i<5;i++)
		{
			proj = CreateEntityByName("env_explosion");   
			DispatchKeyValueFloat(proj, "DamageForce", 180.0);

			SetEntProp(proj, Prop_Data, "m_iMagnitude", 280, 4);
			SetEntProp(proj, Prop_Data, "m_iRadiusOverride", 200, 4);
			SetEntPropEnt(proj, Prop_Data, "m_hOwnerEntity", Boss);

			DispatchSpawn(proj);
  
			pos2[0]=pos[0]+GetRandomInt(-350,350);
			pos2[1]=pos[1]+GetRandomInt(-350,350);
			if (!(GetEntityFlags(Boss) & FL_ONGROUND))
				pos2[2]=pos[2]+GetRandomInt(-150,150);
			else			
				pos2[2]=pos[2]+GetRandomInt(0,100);
			TeleportEntity(proj, pos2, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(proj, "Explode");
			AcceptEntityInput(proj, "kill");
		
		/*	proj = CreateEntityByName("tf_projectile_rocket");
			SetVariantInt(BossTeam);
			AcceptEntityInput(proj, "TeamNum", -1, -1, 0);
			SetVariantInt(BossTeam);
			AcceptEntityInput(proj, "SetTeam", -1, -1, 0); 
			SetEntPropEnt(proj, Prop_Send, "m_hOwnerEntity",Boss);
			decl Float:pos[3];
			new Float:rot[3]={0.0,90.0,0.0};
			new Float:see[3]={0.0,0.0,-1000.0};
			GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
			pos[0]+=GetRandomInt(-250,250);
			pos[1]+=GetRandomInt(-250,250);
			pos[2]+=40;
			TeleportEntity(proj, pos, rot,see);
			SetEntDataFloat(proj, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, 300.0, true);
			DispatchSpawn(proj);
			CreateTimer(0.1,Rage_Timer_Explosive_Dance_Boom,EntIndextoEntRef(proj));*/
		}
	}
	else
	{
		SetEntityMoveType(Boss, MOVETYPE_WALK);		
		count=0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


//Ninja Spy's slo-mo rage
Rage_UseSlomo(index,const String:ability_name[])
{
	SetConVarFloat(cvarTimeScale, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,0.1));
	new Float:duration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,1.0)+1.0;
	SloMoTimer=CreateTimer(duration,Timer_StopSlomo,index);
	ff2flags[index]=ff2flags[index]|FLAG_SLOMOREADYCHANGE|FLAG_ONSLOMO;
	UpdateClientCheatValue("1");
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	if (Boss>0)
		CreateTimer(duration, RemoveEnt, EntIndexToEntRef(AttachParticle(Boss,"scout_dodge_blue",75.0)));	
	EmitSoundToAll("replay\\enterperformancemode.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
	EmitSoundToAll("replay\\enterperformancemode.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
}

public Action:Timer_StopSlomo(Handle:hTimer,any:index)
{
	SloMoTimer=INVALID_HANDLE;
	SetConVarFloat(cvarTimeScale, 1.0);
	UpdateClientCheatValue("0");
	if (index!=-1)
		ff2flags[index]&=~FLAG_ONSLOMO;
	EmitSoundToAll("replay\\exitperformancemode.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
	EmitSoundToAll("replay\\exitperformancemode.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{	
	new index=FF2_GetBossIndex(client);
	if (index==-1 || !(ff2flags[index] & FLAG_ONSLOMO))
		return Plugin_Continue;
		
	if (buttons & IN_ATTACK /*&& ff2flags[index] & FLAG_SLOMOREADYCHANGE*/)
	{
		ff2flags[index]&=~FLAG_SLOMOREADYCHANGE;
		CreateTimer(FF2_GetAbilityArgumentFloat(index,this_plugin_name,"rage_matrix_attack",3,0.2),Timer_FLAG_SLOMOREADYCHANGE,index);
		
		decl Float:pos[3], Float:pos2[3], Float:rot[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos); 
		pos[2]+=65;
		GetClientEyeAngles(client, rot);
		
		new Handle:hTrace = TR_TraceRayFilterEx(pos, rot, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf);
		TR_GetEndPosition(pos2, hTrace);
		pos2[2]+=100;
		SubtractVectors(pos2,pos,vel);
		NormalizeVector(vel,vel);
		ScaleVector(vel,2012.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
		new target=TR_GetEntityIndex(hTrace);
		if (target>0 && target<=MaxClients)
		{
			new Handle:data;
			CreateDataTimer(0.15,Rage_Timer_NinjaAttacks,data);
			WritePackCell(data, GetClientUserId(client));
			WritePackCell(data, GetClientUserId(target));
			ResetPack(data);
		}
		CloseHandle(hTrace);
	}
		
	return Plugin_Continue;
}

public Action:Rage_Timer_NinjaAttacks(Handle:hTimer,Handle:data)
{
	new client=GetClientOfUserId(ReadPackCell(data));
	new target=GetClientOfUserId(ReadPackCell(data));
	if (target>0)
	{
		decl Float:pos[3], Float:pos2[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos); 
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos2); 
		if (GetVectorDistance(pos,pos2)<1500)
		{
			SDKHooks_TakeDamage(target,client,client,900.0);
			TeleportEntity(client, pos2, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

public bool:TraceRayDontHitSelf(entity, mask)
{
	if (!entity || entity>MaxClients)
		return true;
	if (FF2_GetBossIndex(entity)==-1)
		return true;
	return false; 
}


public Action:Timer_FLAG_SLOMOREADYCHANGE(Handle:hTimer,any:index)
{
	ff2flags[index]|=FLAG_SLOMOREADYCHANGE;
	return Plugin_Continue;
}


//Unused single rocket shoot charge
/*Charge_RocketSpawn(const String:ability_name[],index,slot,action)
{
	if (FF2_GetBossCharge(index,0)<10)
		return;
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new Float:see=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,5.0);
	new Float:charge=FF2_GetBossCharge(index,slot);
	switch (action)
	{
		case 2:
		{
			SetHudTextParams(-1.0, 0.93, 0.15, 255, 255, 255, 255);
			if (charge+1<see)
				FF2_SetBossCharge(index,slot,charge+1);
			else
				FF2_SetBossCharge(index,slot,see);
			ShowSyncHudText(Boss, chargeHUD, "%t","charge_status",RoundFloat(charge*100/see));
		}
		case 3:
		{				
			FF2_SetBossCharge(index,0,charge-10);
			decl Float:pos[3];
			decl Float:rot[3];
			decl Float:vel[3];
			GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
			GetClientEyeAngles(Boss,rot);
			pos[2]+=63;
				
			new proj = CreateEntityByName("tf_projectile_rocket");
			SetVariantInt(BossTeam);
			AcceptEntityInput(proj, "TeamNum", -1, -1, 0);
			SetVariantInt(BossTeam);
			AcceptEntityInput(proj, "SetTeam", -1, -1, 0); 
			SetEntPropEnt(proj, Prop_Send, "m_hOwnerEntity",Boss);		
			new Float:speed=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,3,1000.0);
			vel[0]=Cosine(DegToRad(rot[0]))*Cosine(DegToRad(rot[1]))*speed;
			vel[1]=Cosine(DegToRad(rot[0]))*Sine(DegToRad(rot[1]))*speed;
			vel[2]=Sine(DegToRad(rot[0]))*speed;
			vel[2]*=-1;
			TeleportEntity(proj, pos, rot,vel);
			SetEntDataFloat(proj, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,5,150.0), true);
			DispatchSpawn(proj);
			new String:s[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name,4,s,PLATFORM_MAX_PATH);
			if (strlen(s)>5)
				SetEntityModel(proj,s);
			FF2_SetBossCharge(index,slot,-5*FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0));
			if (FF2_RandomSound("sound_ability",s,PLATFORM_MAX_PATH,index,slot))
			{
				EmitSoundToAll(s, Boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss, pos, NULL_VECTOR, true, 0.0);
				EmitSoundToAll(s, Boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss, pos, NULL_VECTOR, true, 0.0);
			
				for (new i=1; i<=MaxClients; i++)
					if (IsClientInGame(i) && i!=Boss)
					{
						EmitSoundToClient(i,s, Boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss, pos, NULL_VECTOR, true, 0.0);
						EmitSoundToClient(i,s, Boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss, pos, NULL_VECTOR, true, 0.0);
					}
			}
		}
	}
}
*/


public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;
	new attacker=GetClientOfUserId(GetEventInt(event,"attacker"));
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new a_index=FF2_GetBossIndex(attacker);
	new v_index=FF2_GetBossIndex(client);
	if (a_index != -1)
	{
		if (FF2_HasAbility(a_index,this_plugin_name,"special_dropprop"))				//Demopan's "drop stout shako on death"
		{
			if (FF2_GetAbilityArgument(a_index,this_plugin_name,"special_dropprop",3,0))
				CreateTimer(0.01,Timer_RemoveRagdoll,GetEventInt(event, "userid"));
			new prop = CreateEntityByName("prop_physics_override");
			if (IsValidEntity(prop))
			{
				decl String:s[PLATFORM_MAX_PATH];
				FF2_GetAbilityArgumentString(a_index,this_plugin_name,"special_dropprop",1,s,PLATFORM_MAX_PATH);
				SetEntityModel(prop,s);
				SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
				SetEntProp(prop, Prop_Send, "m_CollisionGroup", 1);
				SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16);
				DispatchSpawn(prop);
				decl Float:pos[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				pos[2]+=20;				
				TeleportEntity(prop, pos, NULL_VECTOR, NULL_VECTOR);
				new Float:duration=FF2_GetAbilityArgumentFloat(a_index,this_plugin_name,"special_dropprop",2,0.0);
				if (duration>0.5)
					CreateTimer(duration,RemoveEnt,EntIndexToEntRef(prop));
			}
		}
		if (FF2_HasAbility(a_index,this_plugin_name,"special_cbs_multimelee"))		//Melee multiple weapons (CBS)
		{
			if (GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon")==GetPlayerWeaponSlot(attacker,TFWeaponSlot_Melee))
			{
				TF2_RemoveWeaponSlot(attacker, TFWeaponSlot_Melee);
				decl weapon;
				switch (GetRandomInt(0,2))
				{
					case 0:
						weapon=SpawnWeapon(attacker,"tf_weapon_club",171,101,5,"68 ; 2 ; 2 ; 3.0");
					case 1:
						weapon=SpawnWeapon(attacker,"tf_weapon_club",193,101,5,"68 ; 2 ; 2 ; 3.0");
					case 2:
						weapon=SpawnWeapon(attacker,"tf_weapon_club",232,101,5,"68 ; 2 ; 2 ; 3.0");				
				}
				SetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon",weapon);
			}
		}
	}
	else
	{
		if (GetClientTeam(client)==BossTeam)
			CreateTimer(0.5,Timer_RestoreLastClass,GetClientUserId(client));
	}	
	if (v_index != -1)
	{
		if (FF2_HasAbility(v_index,this_plugin_name,"rage_cloneattack"))
		{
			for(new target = 1; target <= MaxClients; target++)
				if (CloneOwnerIndex[target] == v_index && IsValidEdict(target) && IsClientConnected(target) && IsPlayerAlive(target) && GetClientTeam(target)==BossTeam)
					CreateTimer(0.5,Timer_RestoreLastClass,GetClientUserId(target));
		}
	}
	return Plugin_Continue;
}

public Action:Timer_RestoreLastClass(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if (LastClass[client])
		TF2_SetPlayerClass(client,LastClass[client]);
	LastClass[client] = TFClass_Unknown;
	if (BossTeam == _:TFTeam_Red)
		ChangeClientTeam(client, _:TFTeam_Blue);
	else
		ChangeClientTeam(client, _:TFTeam_Red);
	return Plugin_Continue;
}

public Action:Timer_RemoveRagdoll(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	decl ragdoll;
	if (client>0 && (ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll"))>MaxClients)
		AcceptEntityInput(ragdoll, "Kill");
}

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock SetAmmo(client, slot, ammo)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

public Action:RemoveEnt(Handle:timer, any:entid)
{
	new ent=EntRefToEntIndex(entid);
	if (IsValidEdict(ent))
	{
		if (ent>MaxClients)
			AcceptEntityInput(ent, "Kill");
	}
}

stock AttachParticle(ent, String:particleType[],Float:offset=0.0,bool:battach=true)
{
	new particle = CreateEntityByName("info_particle_system");

	decl String:tName[128];
	decl Float:pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	pos[2]+=offset;
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

	Format(tName, sizeof(tName), "target%i", ent);
	DispatchKeyValue(ent, "targetname", tName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	if (battach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity",ent);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

//By Mecha the Slag
UpdateClientCheatValue(const String:Value[])
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEdict(i) && IsClientConnected(i) && !IsFakeClient(i))
		{
			SendConVarValue(i, cvarCheats, Value);
		}
	}
}