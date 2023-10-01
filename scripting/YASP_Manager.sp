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

// Convert type str to enum
public int Native_YASP_GetEnumFromTypeStr(Handle plugin, int numParams)
{
    int size = GetNativeCell(2);

    if (size < 1) return view_as<int>(YASP_UNKNOWN);

    char[] str = new char[size];
    GetNativeString(1, str, size);

    // Compare string
    if (StrEqual("nametag", str))
    {
        return view_as<int>(YASP_NAMETAG);
    }
    if (StrEqual("trail", str))
    {
        return view_as<int>(YASP_TRAIL);
    }

    return view_as<int>(YASP_UNKNOWN);
}

// Convert enum to type str
public int Native_YASP_GetTypeStrFromEnum(Handle plugin, int numParams)
{
    int size = GetNativeCell(3);

    if (size < 1) return -1;

    YASP_ITEMTYPE type = GetNativeCell(1);

    // Compare enum
    switch (type)
    {
        case YASP_NAMETAG:
        {
            SetNativeString(2, "nametag", size);
            return 1;
        }

        case YASP_TRAIL:
        {
            SetNativeString(2, "trail", size);
            return 1;
        }
    }

    return -1;
}