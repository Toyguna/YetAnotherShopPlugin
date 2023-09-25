#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

#include <yasp>

public bool IsClientValid(int client)
{
    return 0 < client <= MaxClients && IsClientConnected(client);
}