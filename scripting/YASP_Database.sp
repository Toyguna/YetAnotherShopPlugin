#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

#include <yasp>

public Database hDatabase = null;

public void DB_Connect()
{
    ConVar cfg = FindConVar("yasp_database_cfg");

    if (cfg == null) {
        PrintToServer("[YASP] %T", "Err_DatabaseConnect")   
    }

    char buffer[32];
    cfg.GetString(buffer, sizeof(buffer));

    Database.Connect(DB_GetDatabase, buffer);
}

public void DB_GetDatabase(Database db, const char[] error, any data)
{
    if (db == null)
    {
        PrintToServer("[YASP] %T", "Err_DatabaseConnect")   
        LogError("[YASP] Database failure: %s", error);
    } 
    else 
    {
        hDatabase = db;
        PrintToServer("[YASP] %T", "DB_DatabaseConnect")

        DB_ValidateDatabase();
    }
}

public void DB_SaveClient(int client)
{
    if (IsDatabaseNull()) return;
    if (!IsClientValid(client)) 
    {
        PrintToServer("[YASP] Error: %T", "DB_FailSaveClient_Invalid", LANG_SERVER, client);
        return;
    }
    if (IsFakeClient(client)) return;
    
    if (!DB_ClientHasEntry(client))
    {
        DB_CreateClientEntry(client);
    }
}

public void DB_LoadClient(int client)
{
    if (IsDatabaseNull()) return;
    if (!IsClientValid(client)) 
    {
        PrintToServer("[YASP] Error: %T", "DB_FailLoadClient_Invalid", LANG_SERVER, client);
        return;
    }
    if (IsFakeClient(client)) return;
    if (!DB_ClientHasEntry(client)) return;

    PrintToServer("[YASP] %T", "DB_LoadClient", LANG_SERVER, client);

    // finish
    ga_bPlayerInvLoaded[client] = true;
}

public void DB_ValidateDatabase() 
{
    if (IsDatabaseNull()) return;

    PrintToServer("[YASP] %T", "DB_ValidateDatabase", LANG_SERVER);

    bool created = false;

    char query[200] = "SELECT count(*) AS count FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'yamp';";
    
    int count;

    DBResultSet hQuery;

    SQL_LockDatabase(hDatabase);
    hQuery = SQL_Query(hDatabase, query);

    while (SQL_FetchRow(hQuery))
    {
        count = SQL_FetchInt(hQuery, 0);
    }

    SQL_UnlockDatabase(hDatabase);
    delete hQuery;

    created = count > 0;

    if (created)
    {
        DB_RepairDatabase();
    }
    else 
    {
        PrintToServer("[YASP] %T", "DB_CreateDatabase", LANG_SERVER);
        DB_CreateDatabase();
    }
}

public void DB_CreateDatabase()
{
    if (IsDatabaseNull()) return;

    // users
    SQL_FastQuery(hDatabase, "CREATE TABLE users(user_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT, auth_id VARCHAR(20) NOT NULL, credits BIGINT NOT NULL);");

    // items
    SQL_FastQuery(hDatabase, "CREATE TABLE items(item_id INT NOT NULL PRIMARY KEY, item_name VARCHAR(128) NOT NULL, item_price INT NOT NULL);");
    
    // inventory
    SQL_FastQuery(hDatabase, "CREATE TABLE inventory(user_id INT NOT NULL, item_id INT NOT NULL);");
}

public void DB_RepairDatabase()
{
    if (IsDatabaseNull()) return; 

    PrintToServer("[YASP] %T", "DB_RepairDatabase", LANG_SERVER);

    bool users, items, inventory;

    SQL_LockDatabase(hDatabase);

    users = SQL_FastQuery(hDatabase, "SELECT * FROM users;");
    items = SQL_FastQuery(hDatabase, "SELECT * FROM items;");
    inventory = SQL_FastQuery(hDatabase, "SELECT * FROM inventory;");

    int repairs = users + items + inventory; // get num of tables repaired

    SQL_UnlockDatabase(hDatabase);

    // drop and recreate tables (RIP ENTRIES LUL)
    if (users)
    {
        SQL_LockDatabase(hDatabase);

        SQL_Query(hDatabase, "DROP TABLE users;");
        inventory = true;
    
        SQL_UnlockDatabase(hDatabase);
    }

    if (items)
    {
        SQL_LockDatabase(hDatabase);

        SQL_Query(hDatabase, "DROP TABLE items;");
    
        SQL_UnlockDatabase(hDatabase);
    }

    if (inventory)
    {
        SQL_LockDatabase(hDatabase);

        SQL_Query(hDatabase, "DROP TABLE inventory;");
    
        SQL_UnlockDatabase(hDatabase);
    }
    
    DB_CreateDatabase();

    PrintToServer(" L %T", "DB_SuccessRepairDatabase", LANG_SERVER, repairs);
}

public void DB_SaveAllClients()
{
    PrintToServer("[YASP] %T", "DB_SaveAllClients", LANG_SERVER);

    for (int i = 0; i < MaxClients; i++)
    {
        PrintToServer(" L %T", "DB_SaveClient", LANG_SERVER, i);
        DB_SaveClient(i);
    }
}

public void DB_CreateClientEntry(int client)
{
    if (IsDatabaseNull()) return;
    if (!IsClientValid(client)) return;
    if (IsFakeClient(client)) return;

    char auth_id[YASP_STEAMAUTH_2];
    GetClientAuthId(client, AuthId_Steam2, auth_id, sizeof(auth_id));

    int credits = YASP_GetClientCredits(client);

    char query[200];
    Format(query, sizeof(query), "INSERT INTO users (auth_id, credits) VALUES ('%s', %d);", auth_id, credits);

    SQL_LockDatabase(hDatabase);
    SQL_FastQuery(hDatabase, query);
    SQL_UnlockDatabase(hDatabase);
}

public bool DB_ClientHasEntry(int client)
{
    if (IsDatabaseNull()) return false;
    if (!IsClientValid(client)) return false;
    if (IsFakeClient(client)) return false;

    char auth_id[YASP_STEAMAUTH_2];
    GetClientAuthId(client, AuthId_Steam2, auth_id, sizeof(auth_id));

    char query[200];
    Format(query, sizeof(query), "SELECT * FROM users WHERE auth_id = '%s';", auth_id)

    SQL_LockDatabase(hDatabase);
    SQL_FastQuery(hDatabase, query);
    SQL_UnlockDatabase(hDatabase);

    return true;
}

// ==================== [ UTILITY ] ==================== //

public bool IsDatabaseNull()
{
    return hDatabase == null;
}