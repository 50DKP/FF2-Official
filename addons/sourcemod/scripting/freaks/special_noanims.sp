/*
special_noanims:	arg0 - unused.
					arg1 - 1 = Custom Model Rotates (def.0)

rage_new_weapon:	arg0 - slot (def.0)
					arg1 - weapon's classname
					arg2 - weapon's index
					arg3 - weapon's attributes
					arg4 - weapon's slot (0 - primary. 1 - secondary. 2 - melee. 3 - pda. 4 - spy's watches)
					arg5 - weapon's ammo
					arg6 - force switch to this weapon
*/
#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo=
{
	name = "Freak Fortress 2: special_noanims",
	author = "RainBolt Dash",
	description = "FF2: New Weapon and No Animations abilities",
	version = PLUGIN_VERSION
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], action)
{
	if(!strcmp(ability_name, "rage_new_weapon"))
	{
		Rage_NewWeapon(boss, ability_name);
	}
	return Plugin_Continue;
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.41, Timer_Disable_Anims);
	CreateTimer(9.31, Timer_Disable_Anims);
	return Plugin_Continue;
}

public Action:Timer_Disable_Anims(Handle:hTimer)
{
	decl client;
	for(new boss=0; (client=GetClientOfUserId(FF2_GetBossUserId(boss)))>0; boss++)
	{
		if(FF2_HasAbility(boss, this_plugin_name, "special_noanims"))
		{
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", FF2_GetAbilityArgument(boss, this_plugin_name, "special_noanims", 1, 0));
		}
	}
	return Plugin_Continue;
}

Rage_NewWeapon(boss, const String:ability_name[])
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(client<0)
	{
		return;
	}

	decl String:classname[64];
	decl String:attributes[64];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 1, classname, 64);
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 3, attributes, 64);
	new slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 4);
	TF2_RemoveWeaponSlot(client, slot);
	new weapon=SpawnWeapon(client, classname, FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 2, 56), 100, 5, attributes);
	if(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 6))
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}

	new ammo=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 5);
	new clip=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 7);
	if(ammo>0)
	{
		SetAmmo(client, weapon, ammo, clip);
	}
}

stock SetAmmo(client, weapon, ammo, clip=0)
{
	if(IsValidEntity(weapon))
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
		new offset=GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
		SetEntProp(client, Prop_Send, "m_iAmmo", ammo, 4, offset);
	}
}

stock SpawnWeapon(client,String:name[], index, level, quality, String:attribute[])
{
	new Handle:hWeapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, quality);
	new String:attributes[32][32];
	new count = ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		--count;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2=0;
		for(new i=0; i<count; i+=2)
		{
			new attrib=StringToInt(attributes[i]);
			if(attrib==0)
			{
				LogError("Bad weapon attribute passed: %s;%s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}

	if(hWeapon==INVALID_HANDLE)
	{
		return -1;
	}
	new entity=TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}