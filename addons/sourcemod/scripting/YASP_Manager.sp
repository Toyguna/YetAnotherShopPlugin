#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

#include <yasp>

// ==================== [ GLOBAL VARIABLES ] ==================== //

public int ga_iPlayerCredits[MAXPLAYERS + 1];
public bool ga_bPlayerInvLoaded[MAXPLAYERS + 1] = { false, ... };

// ==================== [ NATIVES ] ==================== //
public int Native_YASP_GetClientCredits(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (!IsClientValid(client)) return -1;

    return ga_iPlayerCredits[client];
}

public int Native_YASP_SetClientCredits(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (!IsClientValid(client)) return 0;

    int amount = GetNativeCell(2);

    ga_iPlayerCredits[client] = amount;

    return 1;
}

public int Native_YASP_SaveClientData(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));

    PrintToServer("[YASP] %T", "DB_SaveClient", LANG_SERVER, name, client);
    DB_SaveClient(client);

    return 1;
}

public int Native_YASP_AddClientCredits(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (!IsClientValid(client)) return 0;

    int amount = GetNativeCell(2);

    ga_iPlayerCredits[client] += amount;

    return 1;
}

public int Native_YASP_LoadClientData(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    DB_LoadClient(client);

    return 1;
}

public int Native_YASP_SaveAllClientData(Handle plugin, int numParams)
{
    DB_SaveAllClients();

    return 1;
}