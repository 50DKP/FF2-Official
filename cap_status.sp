#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "Get Control Point Status",
	author = "Powerlord",
	description = "Returns a control point's name (target?)",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	RegAdminCmd("capstatus", Cmd_CapStatus, ADMFLAG_CONFIG, "Get Cap names and status");
	RegAdminCmd("capname", Cmd_CPName, ADMFLAG_CONFIG, "Get Cap name");
	RegAdminCmd("mastername", Cmd_MasterName, ADMFLAG_CONFIG, "Get Cap name");
	RegAdminCmd("arenatimer", Cmd_ArenaTimer, ADMFLAG_CONFIG, "Check if an arena timer exists");
}

#define POINT_NAME 0
#define TRIGGER_NAME 1


enum ControlPoint
{
	CP_Point,
	CP_Trigger,
	String:CP_PointName[64],
}

new g_ControlPointData[9][ControlPoint];


//new g_ControlPoints[9];
//new String:g_ControlPointNames[9][2][64];

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "team_control_point"))
	{
		SDKHook(entity, SDKHook_SpawnPost, CPSpawn_Hook);
	}
	
	if (StrEqual(classname, "trigger_capture_area"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TriggerSpawn_Hook);
	}
}

public OnEntityDestroyed(entity)
{
	for (new i = 0; i < sizeof(g_ControlPointData); ++i)
	{
		if (g_ControlPointData[i][CP_Point] == entity)
		{
			//g_ControlPoints[i] = 0;
			g_ControlPointData[i][CP_Point] = 0;
			g_ControlPointData[i][CP_Trigger] = 0;
			g_ControlPointData[i][CP_PointName][0] = '\0';
			break;
		}
	}
}

public CPSpawn_Hook(entity)
{
	new index = GetEntProp(entity, Prop_Data, "m_iPointIndex");
	g_ControlPointData[index][CP_Point] = entity;
	//g_ControlPoints[index] = entity;
	
	GetEntPropString(entity, Prop_Data, "m_iName", g_ControlPointData[index][CP_PointName], sizeof(g_ControlPointData[][]));
}

public TriggerSpawn_Hook(entity)
{
	new String:pointName[64];
	GetEntPropString(entity, Prop_Data, "m_iszCapPointName", pointName, sizeof(pointName));
	
	for (new i = 0; i < sizeof(g_ControlPointData); ++i)
	{
		if (StrEqual(pointName, g_ControlPointData[i][CP_PointName]))
		{
			g_ControlPointData[i][CP_Trigger] = entity;
			break;
		}
	}
}


public Action:Cmd_CPName(client, args)
{
	new point = -1;
	
	while ((point = FindEntityByClassname(point, "team_control_point")) != -1)
	{
		decl String:name[64];
		GetEntPropString(point, Prop_Data, "m_iName", name, sizeof(name));
		
		decl String:target[64];
		GetEntPropString(point, Prop_Data, "m_target", target, sizeof(target));
		
		ReplyToCommand(client, "cp name: \"%s\", target: \"%s\"", name, target);
	}
	
	return Plugin_Handled;
}

public Action:Cmd_CapStatus(client, args)
{
	new point = -1;
	
	while ((point = FindEntityByClassname(point, "team_control_point")) != -1)
	{
		decl String:name[64];
		GetEntPropString(point, Prop_Data, "m_iName", name, sizeof(name));
		
		
		
		ReplyToCommand(client, "cp index: %d, name: \"%s\", locked: %d", GetEntProp(point, Prop_Data, "m_iPointIndex"), name,
			GetEntProp(point, Prop_Data, "m_bLocked"));
	}
	
	return Plugin_Handled;
}

public Action:Cmd_MasterName(client, args)
{
	new point = -1;
	
	while ((point = FindEntityByClassname(point, "team_control_point_master")) != -1)
	{
		decl String:name[64];
		GetEntPropString(point, Prop_Data, "m_iName", name, sizeof(name));
		
		decl String:target[64];
		GetEntPropString(point, Prop_Data, "m_target", target, sizeof(target));
		
		ReplyToCommand(client, "cp name: \"%s\", target: \"%s\"", name, target);
	}
	
	return Plugin_Handled;
}

public Action:Cmd_ArenaTimer(client, args)
{
	new timer = FindEntityByClassname(-1, "team_round_timer");
	if (timer > -1)
	{
		ReplyToCommand(client, "Found timer: %d", timer);
	}
	else
	{
		ReplyToCommand(client, "No timer found.");
	}
	
	return Plugin_Handled;
}