#include <sourcemod>
#include <freak_fortress_2>
#include <morecolors>
#include <tf2>
#include <clientprefs>

#define VERSION "2.0 alpha"

#define STEAM_LENGTH 20
// 20 is enough for Steam IDs up to STEAM_0:0:1234567890 in length.  This is for future expansion, as they're currently only STEAM_0:0:12345678

#define DEBUG

public Plugin:myinfo = 
{
	name = "Freak Fortress 2 Boss Queue: Fair",
	author = "Powerlord",
	description = "Default Freak Fortress 2 Boss Queue. \"Fair\" refers to everyone getting an equal number of points at round end.",
	version = "1.0",
	url = "<- URL ->"
}

new Handle:g_hPlayerQueue;
new g_Points[MAXPLAYERS+1];
new bool:g_bValidPlayers[MAXPLAYERS+1];

new Handle:g_Cvar_SpecForceBoss = INVALID_HANDLE;

public OnPluginStart()
{
	g_hPlayerQueue = CreateArray();
	
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", Event_RoundWin, EventHookMode_PostNoCopy);
	
	CreateConVar("ff2_bossqueue_fair_version", VERSION, "FF2 Boss Queue: Fair Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	LoadTranslations("freak_fortress_2.phrases");
}

public OnAllPluginsLoaded()
{
	g_Cvar_SpecForceBoss = FindConVar("ff2_spec_forceboss");
	
	FF2_RegisterQueueManager(GetNextPlayers, GetPlayerPoints, GetPlayerPosition);
}

Handle:DbConnect(SQLTCallback:callback, any:data=0)
{
	if (SQL_CheckConfig("freak_fortress_2"))
	{
		SQL_TConnect(callback, "freak_fortress_2", data);
	}
	else
	{
		SQL_TConnect(callback, "default", data);
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	new Handle:data;
	CreateDataTimer(2.0, FetchPoints, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, GetClientUserId(client));
	WritePackString(data, auth);
	ResetPack(data);
}

public Action:FetchPoints(Handle:timer, any:data)
{
	new client = GetClientOfUserId(ReadPackCell(data));
	
	if (client == 0)
	{
		return Plugin_Continue;
	}

	new Handle:db = FF2_GetDatabaseHandle();
	if (db == INVALID_HANDLE)
	{
		LogError("Invalid Database Handle");
		return Plugin_Continue;
	}
	
	new String:auth[STEAM_LENGTH + 1];
	ReadPackString(data, auth, sizeof(auth));
	
	ResetPack(data);
	
	new String:safeAuth[STEAM_LENGTH * 2 + 1];
	SQL_EscapeString(db, auth, safeAuth, sizeof(safeAuth));
	
	new String:query[1024];
	Format(query, sizeof(query), "SELECT points FROM freak_fortress_2 WHERE auth = '%s'", safeAuth);
	
	SQL_TQuery(db, FetchPointsComplete, query, CloneHandle(data));
	
	return Plugin_Continue;
}

public FetchPointsComplete(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = GetClientOfUserId(ReadPackCell(data));
	
	if (client == 0)
	{
		CloseHandle(data);
		return;
	}
	
	if (owner == INVALID_HANDLE || hndl == INVALID_HANDLE)
	{
		CloseHandle(data);
		LogError("%L: Query failed retrieving user points: %s", client, error);
		return;
	}
	
	if (SQL_GetRowCount(hndl) == 0)
	{
		ResetPack(data);
		CreateTimer(5.0, FetchPoints, data, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
		g_Points[client] = 0;
	}
	else
	{
		CloseHandle(data);
		SQL_FetchRow(hndl);
		g_Points[client] = SQL_FetchInt(hndl, 0);
	}
	
	// TODO: Do something with the points
	new size = GetArraySize(g_hPlayerQueue);
	new bool:found = false;
	for (new i = 0; i < size; ++i)
	{
		new player = GetArrayCell(g_hPlayerQueue, i);
		if (g_Points[player] < g_Points[client])
		{
			ShiftArrayUp(g_hPlayerQueue, i);
			SetArrayCell(g_hPlayerQueue, i, client);
			
			found = true;
			break;
		}
	}
	
	if (!found)
	{
		PushArrayCell(g_hPlayerQueue, client);
	}
}

public OnClientDisconnect(client)
{
	SavePoints(client);
	
	g_Points[client] = 0;
	g_bValidPlayers[client] = false;

	new position = FindValueInArray(g_hPlayerQueue, client);
	if (position > -1)
	{
		RemoveFromArray(g_hPlayerQueue, position);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		g_bValidPlayers[i] = false;
		
		if (IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			if (!GetConVarBool(g_Cvar_SpecForceBoss) && GetClientTeam(i) <= _:TFTeam_Spectator)
			{
				continue;
			}
			g_bValidPlayers[i] = true;
		}
	}
}

public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && g_bValidPlayers[i])
		{
			g_Points[i] += 10;
			
			if (g_Points[i] == 0)
			{
				PushArrayCell(g_hPlayerQueue, i);
			}
			else
			{
				CPrintToChat(i,"{olive}[FF2]{default} %t","add_points", 10);
			}
			SavePoints(i);
		}
		g_bValidPlayers[i] = false;
	}
}

SavePoints(client)
{
	if (!g_bValidPlayers[client])
	{
		return;
	}
	
	new String:auth[STEAM_LENGTH + 1];
	if (GetClientAuthString(client, auth, sizeof(auth)))
	{
		new Handle:data = CreateDataPack();
		
		WritePackCell(data, GetClientUserId(client));
		WritePackString(data, auth);
		
		DbConnect(UpdateQueuePoints, data);
	}
	else
	{
		LogError("%L: Could not get auth for client", client);
	}

}

public UpdateQueuePoints(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = GetClientOfUserId(ReadPackCell(data));
	if (client == 0)
	{
		return;
	}
	
	new points = (g_Points[client] > 0 ? g_Points[client] : 0);

	new String:auth[STEAM_LENGTH + 1];
	ReadPackString(data, auth, STEAM_LENGTH + 1);
	
	new String:safeAuth[STEAM_LENGTH * 2 + 1];
	SQL_EscapeString(hndl, auth, safeAuth, sizeof(safeAuth));
	
	new String:query[1024];
	Format(query, sizeof(query), "UPDATE ff2_queue_points SET points = %d, time = %d WHERE auth = %s", points, GetTime(), safeAuth);
	
	SQL_TQuery(hndl, UpdateQueuePointsComplete, query, data);
	
	#if defined DEBUG
	LogMessage("%L: Dispatched query: %s", client, query);
	#endif
}

public UpdateQueuePointsComplete(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE || hndl == INVALID_HANDLE)
	{
		LogError("%L: Query failed updating user: %s, userid: %d", GetClientOfUserId(data), error);
		return;
	}
}

/**
 * Get the next count players and, optionally, remove them from the queue
 * 
 * Players that are currently bosses will not show in the queue
 * 
 * @param count		Number of players to retrieve. count is updated if the queue size is smaller than the count.
 * @param clients[]	Array of players retrieved
 * @param bool		If true, remove players from the queue.  This is the only way to remove players from the queue and reset their queue points!
 */
public GetNextPlayers(&count, clients[], bool:remove)
{
	// Get the next count players.  Adjust count if less players are there
	new size = GetArraySize(g_hPlayerQueue);
	if (count > size - 1)
	{
		count = size - 1;
	}
	
	for (new i = 0; i < count; ++i)
	{
		clients[i] = GetArrayCell(g_hPlayerQueue, i);
	}
	
	if (remove)
	{
		for (new i = 0; i < count; ++i)
		{
			
			RemoveFromArray(g_hPlayerQueue, 0);
			g_Points[clients[i]] = -10;
			SavePoints(clients[i]);
		}
	}
}

/**
 * Returns a player's position number in the queue
 * 
 * @param client	Client index
 * @return			Position in queue or -1 if not found
 */
public GetPlayerPosition(client)
{
	return FindValueInArray(g_hPlayerQueue, client);
}

/**
 * Returns a player's points
 * 
 * Note: This returns the cached copy of their point total
 * 
 * @param client	Client Index
 * @return 			Number of points.
 */
public GetPlayerPoints(client)
{
	return g_Points[client];
}
