#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <colors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define MB 3
#define ME 2048

public Plugin:myinfo = {
	name = "Freak Fortress 2: Default Abilities",
	author = "RainBolt Dash",
};

new Handle:OnHaleJump = INVALID_HANDLE;
new Handle:OnHaleRage = INVALID_HANDLE;
new Handle:OnHaleWeighdown = INVALID_HANDLE;

new Handle:jumpHUD;

new bool:bEnableSuperDuperJump[MB];
new Float:UberRageCount[MB];
new BossTeam=_:TFTeam_Blue;

new Handle:cvarOldJump = INVALID_HANDLE;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	OnHaleJump = CreateGlobalForward("VSH_OnDoJump", ET_Hook, Param_CellByRef);
	OnHaleRage = CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	OnHaleWeighdown = CreateGlobalForward("VSH_OnDoWeighdown", ET_Hook);
	
	return APLRes_Success;
}

public OnPluginStart2()
{
	jumpHUD = CreateHudSynchronizer();
	HookEvent("object_deflected", event_deflect, EventHookMode_Pre);
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("player_death", event_player_death);
	LoadTranslations("freak_fortress_2.phrases");
	
	cvarOldJump = CreateConVar("ff2_oldjump", "0", "Use old Saxton Hale jump equations", FCVAR_PLUGIN, true, 0.0, true, 1.0);
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=0;i<MB;i++)
	{
		bEnableSuperDuperJump[i]=false;
		UberRageCount[i]=0.0;
	}
	CreateTimer(0.3,Timer_GetBossTeam);
	CreateTimer(9.11, StartBossTimer);
	return Plugin_Continue;
}

public Action:StartBossTimer(Handle:hTimer)
{
	for(new index=0;(FF2_GetBossUserId(index)!=-1);index++)
	{	
		if (FF2_HasAbility(index,this_plugin_name,"charge_teleport"))
		{
			FF2_SetBossCharge(index,FF2_GetAbilityArgument(index,this_plugin_name,"charge_teleport",0,1),-1.0*FF2_GetAbilityArgumentFloat(index,this_plugin_name,"charge_teleport",2,5.0));
		}
	}
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}


public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	new slot=FF2_GetAbilityArgument(index,this_plugin_name,ability_name,0);
	if (!slot)
	{
		if (!index)		//Starts VSH rage ability forward
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
	//slot 3
	if (!strcmp(ability_name,"charge_weightdown"))
		Charge_OnWeightDown(index,slot);	
	//slot 1 and 2
	else if (!strcmp(ability_name,"charge_bravejump"))
		Charge_OnBraveJump(ability_name,index,slot,action);				//Brave Jump
	else if (!strcmp(ability_name,"charge_teleport"))
		Charge_OnTeleporter(ability_name,index,slot,action);		//Teleporter (HHH)
	//slot 0
	else if (!strcmp(ability_name,"rage_uber"))	
	{														//Uber-rage (Vagineer)
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		TF2_AddCondition(Boss,TFCond_Ubercharged,FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,5.0));
		SetEntProp(Boss, Prop_Data, "m_takedamage", 0);
		CreateTimer(FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,5.0),Rage_Timer_UnuseUber,index);
	}
	else if (!strcmp(ability_name,"rage_stun"))	
		Rage_UseStun(ability_name,index);						//Stun rage (a lot of bosses)
	else if (!strcmp(ability_name,"rage_stunsg"))	
		Rage_UseStunSG(ability_name,index);						//Stuns sentries (a lot of bosses, again)
	else if (!strcmp(ability_name,"rage_preventtaunt"))	
		CreateTimer(0.01, Rage_Timer_Break_Taunt,index);	//Remove taunt condition from boss
	else if (!strcmp(ability_name,"rage_instant_teleport"))	
	{														//(Unused ability) instant teleport to random enemy
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		new pingas;
		decl target,Float:pos[3];
		new bool:RedAlivePlayers;
		for(new i=1;i<=MaxClients;i++)
			if(IsValidEdict(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
			{
				RedAlivePlayers=true;
				break;
			}
		
		if (!RedAlivePlayers)
			return Plugin_Continue;
		
		do
		{
			pingas++;
			target=GetRandomInt(1,MaxClients);
			if (pingas==100)
				return Plugin_Continue;
		}
		while (!IsValidEdict(target) || (GetClientTeam(target)==BossTeam) || !IsPlayerAlive(target));
		
		GetEntPropVector(target, Prop_Data, "m_vecOrigin", pos);
		TeleportEntity(Boss, pos, NULL_VECTOR, NULL_VECTOR);
		TF2_StunPlayer(Boss, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, Boss);
	}
	return Plugin_Continue;
}

Rage_UseStun(const String:ability_name[],index)
{
	decl Float:pos[3];
	decl Float:pos2[3];
	decl i;
	new Float:duration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,5.0);
	decl String:s[64];
	FloatToString(duration,s,64);
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
	new Float:ragedist=FF2_GetRageDist(index,this_plugin_name,ability_name);
	for(i=1;i<=MaxClients;i++)
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if (!TF2_IsPlayerInCondition(i,TFCond_Ubercharged) && (GetVectorDistance(pos,pos2)<ragedist))
			{
				TF2_StunPlayer(i, duration, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, Boss);
				CreateTimer(duration, RemoveEnt, EntIndexToEntRef(AttachParticle(i,"yikes_fx",75.0)));	
			}
		}
}

public Action:Rage_Timer_UnuseUber(Handle:hTimer,any:index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	SetEntProp(Boss, Prop_Data, "m_takedamage", 2);
	return Plugin_Continue;
}

public Action:Rage_Timer_Break_Taunt(Handle:hTimer,any:index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	if (!GetEntProp(Boss, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(Boss, Prop_Send, "m_hHighFivePartner")))
	{
		TF2_RemoveCondition(Boss,TFCond_Taunting);
		new Float:up[3];
		up[2]=220.0;
		TeleportEntity(Boss,NULL_VECTOR, NULL_VECTOR,up);
	}
	return Plugin_Continue;
}

Rage_UseStunSG(const String:ability_name[],index)
{
	decl Float:pos[3];
	decl Float:pos2[3];
	GetEntPropVector(GetClientOfUserId(FF2_GetBossUserId(index)), Prop_Send, "m_vecOrigin", pos);
	new i;
	new Float:duration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,7.0);
	new Float:ragedist=FF2_GetRageDist(index,this_plugin_name,ability_name);
	while ((i = FindEntityByClassname(i, "obj_sentrygun")) != -1)
	{
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
		if (GetVectorDistance(pos,pos2)<ragedist)
		{
			SetEntProp(i, Prop_Send, "m_bDisabled", 1);
			CreateTimer(duration, RemoveEnt, EntIndexToEntRef(AttachParticle(i,"yikes_fx",75.0)));
			CreateTimer(duration, EnableSG, EntIndexToEntRef(i));	
		}
	}
}

public Action:EnableSG(Handle:hTimer,any:iid)
{
	new i=EntRefToEntIndex(iid);
	if (FF2_GetRoundState()==1 && i>MaxClients)
		SetEntProp(i, Prop_Send, "m_bDisabled", 0);
	return Plugin_Continue;
}

Charge_OnBraveJump(const String:ability_name[],index,slot,action)
{
	new Float:charge=FF2_GetBossCharge(index,slot);
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new Float:multiplier=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,3,1.0);
	switch (action)
	{
		case 1:
		{
			if (!(FF2_GetFF2flags(Boss) & FF2FLAG_HUDDISABLED))
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
				ShowSyncHudText(Boss, jumpHUD, "%t","jump_status_2",-RoundFloat(charge));
			}
		}
		case 2:
		{
			if (!(FF2_GetFF2flags(Boss) & FF2FLAG_HUDDISABLED))
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
				if (bEnableSuperDuperJump[index])
				{
					SetHudTextParams(-1.0, 0.88, 0.15, 255, 64, 64, 255);
					ShowSyncHudText(Boss, jumpHUD,"%t","super_duper_jump");
				}	
				else
					ShowSyncHudText(Boss, jumpHUD, "%t","jump_status",RoundFloat(charge));
			}
		}
		case 3:
		{
			new Action:act = Plugin_Continue;
			new bool:super = bEnableSuperDuperJump[index];
			Call_StartForward(OnHaleJump);
			Call_PushCellRef(super);
			Call_Finish(act);
			if (act != Plugin_Continue && act != Plugin_Changed)
				return;
			if (act == Plugin_Changed) bEnableSuperDuperJump[index] = super;
			
			decl Float:pos[3];
			decl Float:vel[3];

			GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
			GetEntPropVector(Boss, Prop_Data, "m_vecVelocity", vel);
			
			if (GetConVarBool(cvarOldJump))
			{
				if (bEnableSuperDuperJump[index])
				{
					vel[2]=750 + (charge / 4) * 13.0 + 2000;
					bEnableSuperDuperJump[index] = false;
				}
				else
					vel[2]=750 + (charge / 4) * 13.0;
				SetEntProp(Boss, Prop_Send, "m_bJumping", 1);
				vel[0] *= (1+Sine((charge / 4) * FLOAT_PI / 50));
				vel[1] *= (1+Sine((charge / 4) * FLOAT_PI / 50));
			}
			else
			{
				decl Float:rot[3];
				GetClientEyeAngles(Boss, rot);
				if (bEnableSuperDuperJump[index])
				{
					vel[2]=(750.0+175.0*charge/70+2000)*multiplier;
					vel[0]+=Cosine(DegToRad(rot[0]))*Cosine(DegToRad(rot[1]))*500*multiplier;
					vel[1]+=Cosine(DegToRad(rot[0]))*Sine(DegToRad(rot[1]))*500*multiplier;
					bEnableSuperDuperJump[index]=false;
				}
				else
				{
					vel[2]=(750.0+175.0*charge/70)*multiplier;
					vel[0]+=Cosine(DegToRad(rot[0]))*Cosine(DegToRad(rot[1]))*100*multiplier;
					vel[1]+=Cosine(DegToRad(rot[0]))*Sine(DegToRad(rot[1]))*100*multiplier;
				}
			}
			TeleportEntity(Boss, NULL_VECTOR, NULL_VECTOR, vel);
			decl String:s[PLATFORM_MAX_PATH];
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

Charge_OnTeleporter(const String:ability_name[],index,slot,action)
{
	new Float:charge=FF2_GetBossCharge(index,slot);
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	switch (action)
	{
		case 1:
		{
			if (!(FF2_GetFF2flags(Boss) & FF2FLAG_HUDDISABLED))
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
				ShowSyncHudText(Boss, jumpHUD, "%t","teleport_status_2",-RoundFloat(charge));
			}
		}	
		case 2:
		{
			if (!(FF2_GetFF2flags(Boss) & FF2FLAG_HUDDISABLED))
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
				ShowSyncHudText(Boss, jumpHUD, "%t","teleport_status",RoundFloat(charge));
			}
		}
		case 3:
		{
			new Action:act = Plugin_Continue;
			new bool:super = bEnableSuperDuperJump[index];
			Call_StartForward(OnHaleJump);
			Call_PushCellRef(super);
			Call_Finish(act);
			if (act != Plugin_Continue && act != Plugin_Changed)
				return ;
			if (act == Plugin_Changed) bEnableSuperDuperJump[index] = super;
			
			decl Float:pos[3];
			decl target;
			if (bEnableSuperDuperJump[index])
				bEnableSuperDuperJump[index]=false;
			else if (charge<100)
			{
				CreateTimer(0.1, Timer_ResetCharge,index*10000+slot);
				return;
			}
			new pingas;
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
					return;
			}
			while (RedAlivePlayers && (!IsValidEdict(target) || (target==Boss) || !IsPlayerAlive(target)));
			GetEntPropVector(target, Prop_Data, "m_vecOrigin", pos);
			decl String:s[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name,4,s,128);
			if (strlen(s) > 0)
			{
				CreateTimer(3.0, RemoveEnt, EntIndexToEntRef(AttachParticle(Boss,s)));		
				CreateTimer(3.0, RemoveEnt, EntIndexToEntRef(AttachParticle(Boss,s,_,false)));		
			}
			if (IsValidEdict(target))
			{
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
				SetEntPropFloat(Boss, Prop_Send, "m_flNextAttack", GetGameTime() + (bEnableSuperDuperJump ? 4.0 : 2.0));
				if (GetEntProp(target, Prop_Send, "m_bDucked"))
				{
					decl Float:collisionvec[3];
					collisionvec[0] = 24.0;
					collisionvec[1] = 24.0;
					collisionvec[2] = 62.0;
					SetEntPropVector(Boss, Prop_Send, "m_vecMaxs", collisionvec);
					SetEntProp(Boss, Prop_Send, "m_bDucked", 1);
					SetEntityFlags(Boss, FL_DUCKING);
					CreateTimer(0.2, Timer_StunBoss,index, TIMER_FLAG_NO_MAPCHANGE);
				}
				else TF2_StunPlayer(Boss, (bEnableSuperDuperJump ? 4.0 : 2.0), 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, target);
				TeleportEntity(Boss, pos, NULL_VECTOR, NULL_VECTOR);
				if (strlen(s) > 0)
				{	
					CreateTimer(3.0, RemoveEnt, EntIndexToEntRef(AttachParticle(Boss, s, _, false)));
					CreateTimer(3.0, RemoveEnt, EntIndexToEntRef(AttachParticle(Boss, s)));
				}
			}
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

public Action:Timer_ResetCharge(Handle:timer, any:index)
{
	new slot=index%10000;
	index/=1000;
	FF2_SetBossCharge(index,slot,0.0);
}

public Action:Timer_StunBoss(Handle:timer, any:index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	if (!IsValidEdict(Boss)) return;
	TF2_StunPlayer(Boss, (bEnableSuperDuperJump[index] ? 4.0 : 2.0), 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, Boss);
}

Charge_OnWeightDown(index,slot)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	if (Boss<=0 || !(GetClientButtons(Boss) & IN_DUCK))
		return;
	new Float:charge=FF2_GetBossCharge(index,slot)+0.2;
	if (!(GetEntityFlags(Boss) & FL_ONGROUND))
	{
		if (charge >= 4.0)
		{
			decl Float:ang[3];
			GetClientEyeAngles(Boss, ang);
			if (ang[0]>60.0)
			{
				new Action:act = Plugin_Continue;
				Call_StartForward(OnHaleWeighdown);
				Call_Finish(act);
				if (act != Plugin_Continue && act != Plugin_Changed)
					return ;
					
				new Float:fVelocity[3];
				GetEntPropVector(Boss, Prop_Data, "m_vecVelocity", fVelocity);
				fVelocity[2] = -1000.0;
				TeleportEntity(Boss, NULL_VECTOR, NULL_VECTOR, fVelocity);
				SetEntityGravity(Boss, 6.0);
				CreateTimer(2.0, Charge_Timer_GravityCat, Boss, TIMER_FLAG_NO_MAPCHANGE);
				CPrintToChat(Boss, "{olive}[FF2]{default} %t","used_weighdown");
				FF2_SetBossCharge(index,slot,0.0);
			}
		}
		else
			FF2_SetBossCharge(index,slot,charge);
	}
	else if (charge>0.3 || charge<0)
		FF2_SetBossCharge(index,slot,0.0);
}

public Action:Charge_Timer_GravityCat(Handle:timer, any:client)
{
	if (client && IsValidEdict(client))
		SetEntityGravity(client, 1.0);
	return Plugin_Continue;
}


public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new index=FF2_GetBossIndex(GetClientOfUserId(GetEventInt(event, "attacker")));
	if (index!=-1 && FF2_HasAbility(index,this_plugin_name,"special_dissolve"))
		CreateTimer(0.1,Timer_DissolveRagdoll,GetEventInt(event, "userid"));
	return Plugin_Continue;
}

public Action:Timer_DissolveRagdoll(Handle:timer, any:userid)
{
	new victim = GetClientOfUserId(userid);
	decl ragdoll;
	if (victim>0 && IsClientConnected(victim))
		ragdoll = GetEntPropEnt(victim, Prop_Send, "m_hRagdoll");
	else
		ragdoll = -1;
	if (ragdoll != -1)
	{
		DissolveRagdoll(ragdoll);
	}
}

DissolveRagdoll(ragdoll)
{
	new dissolver = CreateEntityByName("env_entity_dissolver");

	if (dissolver == -1)
		return;

	DispatchKeyValue(dissolver, "dissolvetype", "0");
	DispatchKeyValue(dissolver, "magnitude", "200");
	DispatchKeyValue(dissolver, "target", "!activator");

	AcceptEntityInput(dissolver, "Dissolve", ragdoll);
	AcceptEntityInput(dissolver, "Kill");
}

public Action:RemoveEnt(Handle:timer, any:entid)
{
	new ent=EntRefToEntIndex(entid);
	if (IsValidEdict(ent))
	{
		if (ent>MaxClients)
			AcceptEntityInput(ent, "Kill");
		else
			LogError("Kill player %i? You are kidding, right?",ent);
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

public Action:event_deflect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new index=FF2_GetBossIndex(GetClientOfUserId(GetEventInt(event, "userid")));
	if (index!=-1)
		if (UberRageCount[index] > 11)
			UberRageCount[index] -= 10;
	return Plugin_Continue;
}

public Action:FF2_OnTriggerHurt(index,triggerhurt,&Float:damage)
{
	bEnableSuperDuperJump[index]=true;
	if (FF2_GetBossCharge(index,1)<0)
		FF2_SetBossCharge(index,1,0.0);
	return Plugin_Continue;
}