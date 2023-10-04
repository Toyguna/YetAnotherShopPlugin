#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

#include <yasp>

public Database hDatabase = null;

public void DB_Connect()
{
	ConVar cfg = FindConVar("yasp_database_configuration");

	if (cfg == null) {
		PrintToServer("[YASP] %T", "Err_DatabaseConnect", LANG_SERVER);
		return; 
	}

	char buffer[32];
	cfg.GetString(buffer, sizeof(buffer));

	Database.Connect(DB_GetDatabase, buffer);
}

public void DB_GetDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		PrintToServer("[YASP] %T", "Err_DatabaseConnect", LANG_SERVER)   
		LogError("[YASP] Database failure: %s", error);
	} 
	else 
	{
		hDatabase = db;
		PrintToServer("[YASP] %T", "DB_DatabaseConnect", LANG_SERVER)

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

	char auth_id[YASP_STEAMAUTH_2];
	GetClientAuthId(client, AuthId_Steam2, auth_id, sizeof(auth_id));

	int user_id = DB_GetClientUserId(client);
	if (user_id == -1) return;

	char query[200];

	// Save Credits
	int credits = YASP_GetClientCredits(client);

	Format(query, sizeof(query), "UPDATE users SET credits = %d WHERE user_id = %d;", credits, user_id);
	SQL_LockDatabase(hDatabase);
	SQL_FastQuery(hDatabase, query);
	SQL_UnlockDatabase(hDatabase);

	// Save Inventory
	if (!GetClientInventoryLoaded(client)) return;

	//  - delete items
	Format(query, sizeof(query), "DELETE FROM inventory WHERE user_id = %d;", user_id);

	SQL_LockDatabase(hDatabase);
	SQL_FastQuery(hDatabase, query);
	SQL_UnlockDatabase(hDatabase);

	//  - save items

	ArrayList inv = Inventory_GetInventory(client);
	ArrayList inv_equipped = Inventory_GetEquipped(client);

	char class[YASP_MAX_ITEM_CLASS_LENGTH];

	for (int i = 0; i < inv.Length; i++)
	{
		int id = inv.Get(i);
		bool equipped = inv_equipped.FindValue(id) != -1;

		ICI_GetClassOfId(id, class, sizeof(class));

		Format(query, sizeof(query), "INSERT INTO inventory(user_id, item_class, equipped) VALUES (%d, '%s', %b);", user_id, class, equipped);

		SQL_LockDatabase(hDatabase);
		SQL_FastQuery(hDatabase, query);
		SQL_UnlockDatabase(hDatabase);
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

	int user_id = DB_GetClientUserId(client);
	if (user_id == -1) return;

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	PrintToServer("[YASP] %T", "DB_LoadClient", LANG_SERVER, name, client);

	char query[200];

	// Load Credits
	int credits;

	Format(query, sizeof(query), "SELECT * FROM users WHERE user_id = %d;", user_id);
	
	SQL_LockDatabase(hDatabase);
	DBResultSet hQuery1 = SQL_Query(hDatabase, query);
	
	while (SQL_FetchRow(hQuery1))
	{
		credits = SQL_FetchInt(hQuery1, 2);
	}

	SQL_UnlockDatabase(hDatabase);
	delete hQuery1;

	YASP_SetClientCredits(client, credits);

	// Load Inventory
	SetClientInventoryLoaded(client, false);

	Format(query, sizeof(query), "SELECT * FROM inventory WHERE user_id = %d;", user_id);

	SQL_LockDatabase(hDatabase);
	DBResultSet hQuery2 = SQL_Query(hDatabase, query);

	char class[YASP_MAX_ITEM_CLASS_LENGTH];

	while (SQL_FetchRow(hQuery2))
	{
		SQL_FetchString(hQuery2, 1, class, sizeof(class));

		int id = ICI_GetIdOfClass(class);
		if (id == -1) continue;

		Inventory_AddItem(client, id);
	}

	SQL_UnlockDatabase(hDatabase);
	delete hQuery2;

	// finish
	SetClientInventoryLoaded(client, true);
}

public void DB_ValidateDatabase() 
{
	if (IsDatabaseNull()) return;

	PrintToServer("[YASP] %T", "DB_ValidateDatabase", LANG_SERVER);

	bool created = false;

	char db_cfg[64];
	ConVar cfg = FindConVar("yasp_database_configuration");
	if (cfg == null) return;
	cfg.GetString(db_cfg, sizeof(db_cfg));

	char query[200];
	Format(query, sizeof(query), "SELECT count(*) AS count FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '%s';", db_cfg);
	
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

	DB_UpdateItems(GetShopItemsMap());
}

public void DB_CreateDatabase()
{
	if (IsDatabaseNull()) return;

	// users
	SQL_FastQuery(hDatabase, "CREATE TABLE users(user_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT, auth_id VARCHAR(30) NOT NULL, credits BIGINT NOT NULL);");

	// items
	SQL_FastQuery(hDatabase, "CREATE TABLE items(item_class VARCHAR(128) NOT NULL PRIMARY KEY);");
	
	// inventory
	SQL_FastQuery(hDatabase, "CREATE TABLE inventory(user_id INT NOT NULL, item_class VARCHAR(128) NOT NULL PRIMARY KEY, equipped BOOL NOT NULL);");
}

public void DB_RepairDatabase()
{
	if (IsDatabaseNull()) return;

	bool users, items, inventory;

	SQL_LockDatabase(hDatabase);

	users = SQL_FastQuery(hDatabase, "SELECT user_id, auth_id, credits FROM users;");
	items = SQL_FastQuery(hDatabase, "SELECT item_class FROM items;");
	inventory = SQL_FastQuery(hDatabase, "SELECT user_id, item_class, equipped FROM inventory;");

	int repairs;

	SQL_UnlockDatabase(hDatabase);

	// drop and recreate tables (RIP ENTRIES LUL)
	if (!users)
	{
		SQL_LockDatabase(hDatabase);

		SQL_Query(hDatabase, "DROP TABLE users;");
		inventory = false;

		repairs++;
	
		SQL_UnlockDatabase(hDatabase);
	}

	if (!items)
	{
		SQL_LockDatabase(hDatabase);

		SQL_Query(hDatabase, "DROP TABLE items;");
		
		repairs++;
	
		SQL_UnlockDatabase(hDatabase);
	}

	if (!inventory)
	{
		SQL_LockDatabase(hDatabase);

		SQL_Query(hDatabase, "DROP TABLE inventory;");

		repairs++;
	
		SQL_UnlockDatabase(hDatabase);
	}
	
	if (repairs == 0) {
		PrintToServer(" L %T", "DB_ValidationNoIssues", LANG_SERVER);

		return;
	}

	DB_CreateDatabase();

	PrintToServer("[YASP] %T", "DB_RepairDatabase", LANG_SERVER);
	PrintToServer(" L %T", "DB_SuccessRepairDatabase", LANG_SERVER, repairs);
}

public void DB_SaveAllClients()
{
	PrintToServer("[YASP] %T", "DB_SaveAllClients", LANG_SERVER);
	char name[MAX_NAME_LENGTH];

	for (int i = 0; i < MaxClients; i++)
	{
		if (!IsClientValid(i)) continue;

		GetClientName(i, name, sizeof(name));
		PrintToServer(" L %T", "DB_SaveClient", LANG_SERVER, name, i);
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

	if (StrEqual(auth_id, "STEAM_ID_STOP_IGNORING_RETVAL")) return;	

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	int credits = YASP_GetClientCredits(client);

	if (credits == -1) credits = 0;

	PrintToServer("[YASP] %T", "DB_CreateClientEntry", LANG_SERVER, name, client);

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

	int count = 0;

	SQL_LockDatabase(hDatabase);
	DBResultSet hQuery = SQL_Query(hDatabase, query);
	count = SQL_GetRowCount(hQuery);
	SQL_UnlockDatabase(hDatabase);

	delete hQuery;
	return count > 0;
}

public int DB_GetClientUserId(int client)
{
	if (IsDatabaseNull()) return -1;
	if (!IsClientValid(client)) return -1;
	if (IsFakeClient(client)) return -1;

	char auth_id[YASP_STEAMAUTH_2];
	GetClientAuthId(client, AuthId_Steam2, auth_id, sizeof(auth_id));

	int userid = -1;

	char query[200];
	Format(query, sizeof(query), "SELECT * FROM users WHERE auth_id = '%s';", auth_id);

	SQL_LockDatabase(hDatabase);
	DBResultSet hQuery = SQL_Query(hDatabase, query);

	while (SQL_FetchRow(hQuery))
	{
		userid = SQL_FetchInt(hQuery, 0);
	}

	SQL_UnlockDatabase(hDatabase);
	delete hQuery;

	return userid;
}

void DB_UpdateItems(StringMap shop)
{
	// drop table: 'items'
	SQL_LockDatabase(hDatabase);
	SQL_FastQuery(hDatabase, "DELETE FROM items;");
	SQL_UnlockDatabase(hDatabase);

	StringMapSnapshot snapshot = shop.Snapshot();

	// iterate over categories
	for (int i = 0; i < snapshot.Length; i++)
	{
		char key[YASP_MAX_SHOP_CATEGORY_LENGTH];
		snapshot.GetKey(i, key, sizeof(key));

		ArrayList list;
		shop.GetValue(key, list);

		// iterate over items in category
		for (int j = 0; j < list.Length; j++)
		{
			YASP_ShopItem item;
			list.GetArray(j, item, sizeof(item));

			DB_AddItem(item);
		}
	}

	delete snapshot;
}

void DB_AddItem(YASP_ShopItem item)
{
	// class
	char class[YASP_MAX_ITEM_CLASS_LENGTH];
	class = item.class;

	char query[200];
	Format(query, sizeof(query), "INSERT INTO items(item_class) VALUES ('%s');", class);

	SQL_LockDatabase(hDatabase);
	SQL_FastQuery(hDatabase, query);
	SQL_UnlockDatabase(hDatabase);
}

// ==================== [ UTILITY ] ==================== //

public bool IsDatabaseNull()
{
	return hDatabase == null;
}