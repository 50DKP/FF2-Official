#include <sourcemod>
#include <freak_fortress_2>
#include <morecolors>

#define VERSION "2.0 alpha"

public Plugin:myinfo = 
{
	name = "Freak Fortress 2 Boss Queue: Fair",
	author = "Powerlord",
	description = "Default Freak Fortress 2 Boss Queue",
	version = "1.0",
	url = "<- URL ->"
}

new Handle:g_hPlayerQueue;
new Handle:g_hDb;
new Handle:g_hUpdateQuery;
new g_Points[MAXPLAYERS+1];

public OnPluginStart()
{
	g_hPlayerQueue = CreateArray();
	
	new String:error[1024];
	g_hDb = SQL_Connect("freak_fortress_2", true, error, sizeof(error));
	if (g_hDb == INVALID_HANDLE)
	{
		SetFailState("Could not connect to database: %s", error);
	}
	
	// TODO: Check that the DB exists here
	
	FF2_RegisterQueueManager(GetNextPlayers, GetPlayerPoints, GetPlayerPosition);
	HookEvent("teamplay_round_win", Event_RoundWin, EventHookMode_PostNoCopy);
}

public OnClientAuthorized(client, const String:auth[])
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	new String:safeAuth[41];
	SQL_EscapeString(g_hDb, auth, safeAuth, sizeof(safeAuth));
	
	new String:query[1024];
	Format(query, sizeof(query), "SELECT points FROM ff2_queue_points WHERE auth = '%s'", safeAuth);
	
	SQL_TQuery(g_hDb, FetchPoints, query, GetClientUserId(client));
}

public OnClientDisconnect(client)
{
	g_Points[client] = 0;
	
	new position = FindValueInArray(g_hPlayerQueue, client);
	if (position > -1)
	{
		RemoveFromArray(g_hPlayerQueue, position);
	}
}

public FetchPoints(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	if (owner == INVALID_HANDLE || hndl == INVALID_HANDLE)
	{
		LogError("Query failed retrieving user points: %s", error);
		return;
	}
	
	new time = GetTime();
	
	if (SQL_GetRowCount(hndl) == 0)
	{
		new String:auth[20];
		GetClientAuthString(client, auth, sizeof(auth));
		
		new String:safeAuth[41];
		SQL_EscapeString(g_hDb, auth, safeAuth, sizeof(safeAuth));
		
		new String:query[1024];
		Format(query, sizeof(query), "INSERT INTO points (auth, points, time) VALUES ('%s', 0, %d)", safeAuth, time);
		SQL_TQuery(g_hDb, AddNewUser, query, data);
		
		g_Points[client] = 0;
	}
	else
	{
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

public AddNewUser(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE || hndl == INVALID_HANDLE)
	{
		LogError("Query failed adding new user: %s, userid: %d", error, data);
		return;
	}
	
}

public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			g_Points[i] += 10;
			
			if (g_Points[i] == 0)
			{
				PushArrayCell(g_hPlayerQueue, i);
			}
			else
			{
				// Do update query here
			}
		}
	}
}


// Users returned here should be REMOVED from the array
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
		}
	}
}

public GetPlayerPosition(client)
{
	// Get the position in the queue of a specific client
}

public GetPlayerPoints(client)
{
	// Get the number of points for a specific client
}
