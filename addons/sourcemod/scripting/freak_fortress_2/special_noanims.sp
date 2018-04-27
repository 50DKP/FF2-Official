/*
special_noanims:	slot - unused.
					arg1 - 1=Custom Model Rotates (def.0)

rage_new_weapon:	slot - slot (def.0)
					arg1 - weapon's classname
					arg2 - weapon's index
					arg3 - weapon's attributes
					arg4 - weapon's slot (0 - primary. 1 - secondary. 2 - melee. 3 - pda. 4 - spy's watches)
					arg5 - weapon's ammo (set to 1 for clipless weapons, then set the actual ammo using clip)
					arg6 - force switch to this weapon
					arg7 - weapon's clip
*/
#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>

#pragma newdecls required

#define PLUGIN_NAME "noanims and new weapon"
#define PLUGIN_VERSION "2.0.0"

public Plugin myinfo=
{
	name="Freak Fortress 2: special_noanims",
	author="RainBolt Dash, Wliu",
	description="FF2: New Weapon and No Animations abilities",
	version=PLUGIN_VERSION
};

public void OnPluginStart()
{
	int version[3];
	FF2_GetFF2Version(version);
	if(version[0]==1 && (version[1]<10 || (version[1]==10 && version[2]<3)))
	{
		SetFailState("This subplugin depends on at least FF2 v1.10.3");
	}

	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);

	FF2_RegisterSubplugin(PLUGIN_NAME);
}

public void FF2_OnAbility(int boss, const char[] pluginName, const char[] abilityName, int slot, int status)
{
	if(!StrEqual(pluginName, PLUGIN_NAME, false))
	{
		return;
	}

	if(StrEqual(abilityName, "equip weapon", false))
	{
		Rage_New_Weapon(boss, abilityName);
	}
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(FF2_IsFF2Enabled())
	{
		CreateTimer(0.41, Timer_Disable_Anims, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(9.31, Timer_Disable_Anims, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action Timer_Disable_Anims(Handle timer)
{
	int client;
	for(int boss; (client=GetClientOfUserId(FF2_GetBossUserId(boss)))>0; boss++)
	{
		if(FF2_HasAbility(boss, PLUGIN_NAME, "no animations"))
		{
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", FF2_GetAbilityArgument(boss, PLUGIN_NAME, "no animations", "rotate model", 0));
		}
	}
	return Plugin_Continue;
}

void Rage_New_Weapon(int boss, const char[] abilityName)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}

	char classname[64], attributes[256];
	FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, abilityName, "classname", classname, sizeof(classname));
	FF2_GetAbilityArgumentString(boss, PLUGIN_NAME, abilityName, "attributes", attributes, sizeof(attributes));

	int slot=FF2_GetAbilityArgument(boss, PLUGIN_NAME, abilityName, "slot");
	TF2_RemoveWeaponSlot(client, slot);

	int index=FF2_GetAbilityArgument(boss, PLUGIN_NAME, abilityName, "index");
	int weapon=SpawnWeapon(client, classname, index, 101, 5, attributes);
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

	if(FF2_GetAbilityArgument(boss, PLUGIN_NAME, abilityName, "set as active weapon"))
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}

	int ammo=FF2_GetAbilityArgument(boss, PLUGIN_NAME, abilityName, "ammo", 0);
	int clip=FF2_GetAbilityArgument(boss, PLUGIN_NAME, abilityName, "clip", 0);
	if(ammo || clip)
	{
		FF2_SetAmmo(client, weapon, ammo, clip);
	}
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int quality, char[] attribute)
{
	Handle weapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	char attributes[32][32];
	int count=ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2=0;
		for(int i=0; i<count; i+=2)
		{
			int attrib=StringToInt(attributes[i]);
			if(!attrib)
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

	if(weapon==null)
	{
		return -1;
	}

	int entity=TF2Items_GiveNamedItem(client, weapon);
	delete weapon;
	EquipPlayerWeapon(client, entity);
	return entity;
}
