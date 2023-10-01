#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

#include <yasp>

#include <YASP_Util.sp>
#include <YASP_Manager.sp>
#include <YASP_Database.sp>
#include <YASP_Items.sp>

#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "YetAnotherShopPlugin",
	author = "Toyguna",
	description = "YetAnotherShopPlugin (YASP) is a shop plugin for TF2.",
	version = "1.0.0",
	url = "https://github.com/Toyguna/YetAnotherShopPlugin"
};

// ==================== [ CONVARS ] ==================== //

public ConVar g_cvDatabaseCfg;

public ConVar g_cvChatPrefix;

public ConVar g_cvCommandCredits;
public ConVar g_cvCommandShop;
public ConVar g_cvCommandSetCredits;

public ConVar g_cvPointsOnKill;

public ConVar g_cvPointsOnPlay;
public ConVar g_cvPointsOnPlayInterval;


// ==================== [ GLOBAL VARIABLES ] ==================== //

char CFG_SHOP_DIR[PLATFORM_MAX_PATH] = "addons/sourcemod/configs/yasp_shop.cfg";

public StringMap gsm_ShopItems;

// ==================== [ FORWARDS ] ==================== //

public void OnPluginStart()
{
	LoadTranslations("yasp.phrases");
	LoadTranslations("common.phrases");

	InitVariables();

	CreateConVars();
	AutoExecConfig(true);

	ReadShop();

	DB_Connect();

	HookEvents();
	InitCommands();

	HookCreditsOnPlay();
}

public void OnPluginEnd()
{

}

public APLRes AskPluginLoad2()
{
	RegisterNatives();

	return APLRes_Success;
}

public void OnClientPutInServer(int client)
{
	LoadPlayer(client);
}

public void OnClientDisconnect(int client)
{
	UnloadPlayer(client);
}

public void OnConfigsExecuted()
{
	ReadShop();
}

// ==================== [ INITIALIZATION ] ==================== //

void RegisterNatives()
{
	CreateNative("YASP_GetClientCredits", Native_YASP_GetClientCredits);
	CreateNative("YASP_SetClientCredits", Native_YASP_SetClientCredits);
	CreateNative("YASP_AddClientCredits", Native_YASP_AddClientCredits);
	
	CreateNative("YASP_SaveClientData", Native_YASP_SaveClientData);
	CreateNative("YASP_LoadClientData", Native_YASP_LoadClientData);
	CreateNative("YASP_SaveAllClientData", Native_YASP_SaveAllClientData);

	CreateNative("YASP_GetEnumFromTypeStr", Native_YASP_GetEnumFromTypeStr);
	CreateNative("YASP_GetTypeStrFromEnum", Native_YASP_GetTypeStrFromEnum);
}

void CreateConVars()
{
	// Database Configuration
	g_cvDatabaseCfg = CreateConVar("yasp_database_configuration", "yasp", "Configuration of database.");
	
	// Customization
	g_cvChatPrefix = CreateConVar("yasp_chat_prefix", "[YASP]", "Prefix of chat messages.");

	// Commands
	g_cvCommandCredits = CreateConVar("yasp_command_credits", "sm_credits", "Command to see credits. (Command must start with 'sm_')");
	g_cvCommandShop = CreateConVar("yasp_command_shop", "sm_shop", "Command to access shop. (Command must start with 'sm_')");
	
	g_cvCommandSetCredits = CreateConVar("yasp_command_setcredits", "sm_setcredits", "Set credits of user. (Command must start with 'sm_')");

	// Points
	g_cvPointsOnPlay = CreateConVar("yasp_points_onplay", "2", "Points gained while playing.");
	g_cvPointsOnPlayInterval = CreateConVar("yasp_points_onplayer_interval", "30.0", "Interval between 'yasp_points_onplay', 0 or less to disable. (In seconds)", _, true, 15.0);
	
	g_cvPointsOnKill = CreateConVar("yasp_points_onkill", "2", "Points gained on kill.");
}

void ReadShop()
{
	PrintToServer("[YASP] %T", "ReadShop_Begin", LANG_SERVER);

	gsm_ShopItems.Clear();

	KeyValues kv = new KeyValues("ShopItems");
	kv.ImportFromFile(CFG_SHOP_DIR);

	char key[YASP_MAX_SHOP_CATEGORY_LENGTH];

	kv.GotoFirstSubKey();

	// iterate over categories
	do
	{
		kv.GetSectionName(key, sizeof(key));

		ReadShopCategory(kv, key);
		kv.GoBack();
	}
	while(kv.GotoNextKey());

	delete kv;

	PrintToServer("[YASP] %T", "ReadShop_Finish", LANG_SERVER);
}

void ReadShopCategory(KeyValues kv, char category[YASP_MAX_SHOP_CATEGORY_LENGTH])
{
	char key[YASP_MAX_ITEM_ID_LENGTH];

	kv.GotoFirstSubKey(false);

	ArrayList tasks = new ArrayList(sizeof(YASP_ShopItem));

	// iterate over items in category
	do
	{
		kv.GetSectionName(key, sizeof(key));

		YASP_ShopItem item;
		item = ReadShopItem(kv);

		tasks.PushArray(item, sizeof(item));
		
	}
	while(kv.GotoNextKey(false));

	gsm_ShopItems.SetValue(category, tasks, true);
}

YASP_ShopItem ReadShopItem(KeyValues kv)
{
	YASP_ShopItem item;

	// id
	char id[YASP_MAX_ITEM_ID_LENGTH];
	kv.GetSectionName(id, sizeof(id));

	// display
	char display[YASP_MAX_ITEM_NAME_LENGTH];
	kv.GetString("display", display, sizeof(display));

	// buyable
	bool buyable;
	buyable = view_as<bool>(kv.GetNum("buyable", 0));

	// price
	int price;
	price = kv.GetNum("price", 0);

	// type
	char type[YASP_MAX_ITEM_TYPE_LENGTH];
	kv.GetString("type", type, sizeof(type));

	item.Init(id, display, buyable, price, YASP_NAMETAG);

	return item;
}

void InitVariables()
{
	gsm_ShopItems = new StringMap();
}

void InitCommands()
{
	char cmd_credits[YASP_MAX_COMMAND_LENGTH];
	g_cvCommandCredits.GetString(cmd_credits, sizeof(cmd_credits));

	char cmd_shop[YASP_MAX_COMMAND_LENGTH];
	g_cvCommandShop.GetString(cmd_shop, sizeof(cmd_shop));

	char cmd_setcredits[YASP_MAX_COMMAND_LENGTH];
	g_cvCommandSetCredits.GetString(cmd_setcredits, sizeof(cmd_setcredits));

	RegConsoleCmd(cmd_credits, Command_Credits, "Show client credits.");
	RegConsoleCmd(cmd_shop, Command_Shop, "Open shop.");

	RegAdminCmd(cmd_setcredits, Command_SetCredits, ADMFLAG_CONVARS, "Set credits of client.");
}

void LoadPlayer(int client)
{
	ga_bPlayerInvLoaded[client] = false;
	DB_LoadClient(client);
}

void UnloadPlayer(int client)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	PrintToServer("[YASP] %T", "DB_SaveClient", LANG_SERVER, name, client);
	DB_SaveClient(client);

	ga_bPlayerInvLoaded[client] = false;
	ga_iPlayerCredits[client] = 0;
}

void HookEvents()
{
	// EventHookMode_Post
	HookEvent("player_death", EventPost_PlayerDeath, EventHookMode_Post);
}

void HookCreditsOnPlay()
{
	int enable = g_cvPointsOnPlay.IntValue;
	if (enable < 1) return;

	float interval = g_cvPointsOnPlayInterval.FloatValue;
	CreateTimer(interval, Credits_OnPlay, _, TIMER_REPEAT);
}

// ==================== [ FUNCTIONS ] ==================== //

// ==================== [ EVENTS ] ==================== //

public void EventPost_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim_id = event.GetInt("userid");
	int killer_id = event.GetInt("attacker");

	int victim = GetClientOfUserId(victim_id);
	int killer = GetClientOfUserId(killer_id);

	// Give credits
	Credits_OnKill(killer);
}


// ==================== [ COMMANDS ] ==================== //

public Action Command_Credits(int client, int args)
{
	int credits = YASP_GetClientCredits(client);

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	char prefix[YASP_MAX_PREFIX_LENGTH];
	g_cvChatPrefix.GetString(prefix, sizeof(prefix));

	PrintToChatAll("%s %T", prefix, "Command_Credits", LANG_SERVER, name, credits);

	return Plugin_Handled;
}

public Action Command_SetCredits(int client, int args)
{
	// 1: user
	// 2: credit amount

	if (args != 2)
	{
		PrintToChat(client, "[YASP] Usage: !<command> user amount");
		return Plugin_Handled;
	}

	int credits;

	char target[MAX_TARGET_LENGTH];
	int target_list[1];

	GetCmdArg(1, target, sizeof(target));
	credits = GetCmdArgInt(2);

	char s_temp[1];
	bool b_temp;

	int foundclients = ProcessTargetString(target, 0, target_list, sizeof(target_list), 0, s_temp, sizeof(s_temp), b_temp);

	if(foundclients > 2)
	{
		PrintToChat(client, "[YASP] Too many matches.");
		return Plugin_Handled;
	}

	if (foundclients != 1)
	{
		PrintToChat(client, "[YASP] No clients found.");
		return Plugin_Handled;
	}

	int reciever = target_list[0];

	YASP_SetClientCredits(reciever, credits);

	char name[MAX_NAME_LENGTH];
	GetClientName(reciever, name, sizeof(name));

	PrintToServer("[YASP] %T", "DB_SaveClient", LANG_SERVER, name, reciever);
	DB_SaveClient(reciever);

	PrintToChat(client, "[YASP] Set credits of %s to %d.", name, credits);

	return Plugin_Handled;
}

public Action Command_Shop(int client, int args)
{
	return Plugin_Handled;
}

// ==================== [ MENUS ] ==================== //


// ==================== [ CREDITS ] ==================== //

public Action Credits_OnPlay(Handle timer)
{
	int amount = g_cvPointsOnPlay.IntValue;

	for (int i = 0; i < MaxClients; i++)
	{
		if (!IsClientValid(i)) continue;
		if (IsFakeClient(i)) continue;

		YASP_AddClientCredits(i, amount);
	}

	return Plugin_Continue;
}

public void Credits_OnKill(int killer)
{
	int amount = g_cvPointsOnKill.IntValue;

	YASP_AddClientCredits(killer, amount);
}

// ==================== [ GETTERS ] ==================== //
public StringMap GetShopItemsMap()
{
	return gsm_ShopItems;
}