#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

#include <yasp>
#include <morecolors>

#include <YASP_Util.sp>
#include <YASP_Manager.sp>
#include <YASP_Database.sp>
#include <YASP_Items.sp>
#include <YASP_Credits.sp>

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

public ConVar g_cvDatabaseCfg; /* yasp_database_configuration */

public ConVar g_cvChatPrefix; /* yasp_chat_prefix */
public ConVar g_cvShopTitle; /* yasp_shop_title */
public ConVar g_cvInventoryTitle; /* yasp_inventory_title */

public ConVar g_cvCommandCredits;/* yasp_command_credits */
public ConVar g_cvCommandShop; /* yasp_command_shop */
public ConVar g_cvCommandSetCredits; /* yasp_command_setcredits */
public ConVar g_cvCommandInventory; /* yasp_command_inventory */

public ConVar g_cvPointsOnKill; /* yasp_points_onkill */
public ConVar g_cvPointsOnAssist; /* yasp_points_onassist */
public ConVar g_cvPointsOnUber; /* yasp_points_onuber */
public ConVar g_cvPointsOnCap; /* yasp_points_oncap */
public ConVar g_cvPointsOnDestroySapper; /* yasp_points_ondestroysapper */
public ConVar g_cvPointsOnDestoryBuilding;

public ConVar g_cvPointsOnPlay; /* yasp_points_onplay */
public ConVar g_cvPointsOnPlayInterval; /* yasp_points_onplay_interval */


// ==================== [ GLOBAL VARIABLES ] ==================== //

char CFGDIR_SHOP[PLATFORM_MAX_PATH] = "addons/sourcemod/configs/YetAnotherShopPlugin/shop.cfg";
char CFGDIR_TYPE_NAMETAG[PLATFORM_MAX_PATH] = "addons/sourcemod/configs/YetAnotherShopPlugin/type/nametag.cfg";

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
	
	Items_Init();
}

public void OnPluginEnd()
{
	YASP_SaveAllClientData();
}

public APLRes AskPluginLoad2()
{
	RegisterNatives();

	return APLRes_Success;
}

public void OnClientPutInServer(int client)
{

}

public void OnClientAuthorized(int client)
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

	CreateNative("YASP_GiveItemToClient", Native_YASP_GiveItemToClient);
}

void CreateConVars()
{
	// Database Configuration
	g_cvDatabaseCfg = CreateConVar("yasp_database_configuration", "yasp", "Configuration of database.");
	
	// Customization
	g_cvChatPrefix = CreateConVar("yasp_chat_prefix", "[YASP]", "Prefix of chat messages.");
	g_cvShopTitle = CreateConVar("yasp_shop_title", "Shop", "Title of shop menu.");
	g_cvInventoryTitle = CreateConVar("yasp_inventory_title", "Inventory", "Title of inventory menu.");

	// Commands
	g_cvCommandCredits = CreateConVar("yasp_command_credits", "sm_credits", "Command to see credits. (Command must start with 'sm_')");
	g_cvCommandShop = CreateConVar("yasp_command_shop", "sm_shop", "Command to access shop. (Command must start with 'sm_')");
	g_cvCommandSetCredits = CreateConVar("yasp_command_setcredits", "sm_setcredits", "Set credits of user. (Command must start with 'sm_')");
	g_cvCommandInventory = CreateConVar("yasp_command_inventory", "sm_inventory", "Opens inventory menu. (Command must start with 'sm_')");

	// Points
	g_cvPointsOnKill = CreateConVar("yasp_points_onkill", "2", "Points gained on kill.");
	g_cvPointsOnAssist = CreateConVar("yasp_points_onassist", "2", "Points gained on assist.");
	g_cvPointsOnUber = CreateConVar("yasp_points_onuber", "2", "Points gained on uber.");
	g_cvPointsOnCap = CreateConVar("yasp_points_oncap", "2", "Points gained on cap.");
	g_cvPointsOnDestroySapper = CreateConVar("yasp_points_ondestroysapper", "2", "Points gained on sapper destroy.");
	g_cvPointsOnDestoryBuilding = CreateConVar("yasp_points_ondestroybuilding", "2", "Points gained on building destroy.");

	g_cvPointsOnPlay = CreateConVar("yasp_points_onplay", "2", "Points gained while playing.");
	g_cvPointsOnPlayInterval = CreateConVar("yasp_points_onplayer_interval", "30.0", "Interval between 'yasp_points_onplay', 0 or less to disable. (In seconds)", _, true, 15.0);
}

void ReadShop()
{
	PrintToServer("[YASP] %T", "ReadShop_Begin", LANG_SERVER);

	gsm_ShopItems.Clear();

	KeyValues kv = new KeyValues("ShopItems");
	bool success = kv.ImportFromFile(CFGDIR_SHOP);

	if (!success)
	{
		PrintToServer("[YASP] %T", "ReadShop_Fail_Dir", LANG_SERVER);
		return;
	}

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
	char key[YASP_MAX_ITEM_CLASS_LENGTH];

	kv.GotoFirstSubKey(false);

	ArrayList tasks = new ArrayList(sizeof(YASP_ShopItem));

	// iterate over items in category
	do
	{
		kv.GetSectionName(key, sizeof(key));

		YASP_ShopItem item;
		item = ReadShopItem(kv, category);

		tasks.PushArray(item, sizeof(item));
		
	}
	while(kv.GotoNextKey(false));

	gsm_ShopItems.SetValue(category, tasks, true);
}

YASP_ShopItem ReadShopItem(KeyValues kv, char category[YASP_MAX_SHOP_CATEGORY_LENGTH])
{
	YASP_ShopItem item;

	// class
	char class[YASP_MAX_ITEM_CLASS_LENGTH];
	kv.GetSectionName(class, sizeof(class));

	// display
	char display[YASP_MAX_ITEM_NAME_LENGTH];
	kv.GetString("display", display, sizeof(display));

	// buyable
	bool buyable;
	buyable = view_as<bool>(kv.GetNum("buyable", 0));

	// price
	int price;
	price = kv.GetNum("price", 0);

	// refundable
	float refundable;
	refundable = kv.GetFloat("refundable", 1.0);

	// type
	char str_type[YASP_MAX_ITEM_TYPE_LENGTH];
	kv.GetString("type", str_type, sizeof(str_type));

	YASP_ITEMTYPE type = YASP_GetEnumFromTypeStr(str_type, sizeof(str_type));

	item.class = class;
	item.display = display;
	item.category = category;
	item.buyable = buyable;
	item.price = price;
	item.refundable = refundable;
	item.type = type;

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

	char cmd_inventory[YASP_MAX_COMMAND_LENGTH];
	g_cvCommandInventory.GetString(cmd_inventory, sizeof(cmd_inventory));

	RegConsoleCmd(cmd_credits, Command_Credits, "Show client credits.");
	RegConsoleCmd(cmd_shop, Command_Shop, "Open shop.");
	RegConsoleCmd(cmd_inventory, Command_Inventory, "Open inventory.");
	
	RegAdminCmd(cmd_setcredits, Command_SetCredits, ADMFLAG_CONVARS, "Set credits of client.");
}

void LoadPlayer(int client)
{
	Inventory_CreateList(client);

	DB_LoadClient(client);
}

void UnloadPlayer(int client)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	PrintToServer("[YASP] %T", "DB_SaveClient", LANG_SERVER, name, client);
	DB_SaveClient(client);

	Inventory_Unload(client);

	SetClientInventoryLoaded(client, false);
	ga_iPlayerCredits[client] = 0;
}

void HookEvents()
{
	// EventHookMode_Post
	HookEvent("player_death", EventPost_PlayerDeath, EventHookMode_Post);
	HookEvent("player_chargedeployed", EventPost_PlayerUber, EventHookMode_Post);
	HookEvent("teamplay_point_captured", EventPost_TeamCapture, EventHookMode_Post);
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
	int assister_id = event.GetInt("assister");

	int victim = GetClientOfUserId(victim_id);
	int killer = GetClientOfUserId(killer_id);
	int assister = GetClientOfUserId(assister_id);

	// Give credits
	Credits_OnKill(killer, victim);
	Credits_OnAssist(assister);
}

public void EventPost_PlayerUber(Event event, const char[] name, bool dontBroadcast)
{
	int medic_id = event.GetInt("userid");
	
	int medic = GetClientOfUserId(medic_id);

	// Give credits
	Credits_OnUber(medic);
}

public void EventPost_TeamCapture(Event event, const char[] name, bool dontBroadcast)
{
	char str_cappers[MAXPLAYERS + 1];
	event.GetString("cappers", str_cappers, sizeof(str_cappers));
	
	for (int i = 0; i < sizeof(str_cappers); i++)
	{
		int client = StringToInt(str_cappers[i]);

		if (!IsClientValid(client)) continue;

		// Give credits
		Credits_OnCap(client);
	}
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
	if (!GetClientInventoryLoaded(client)) return Plugin_Handled;

	Menu menu = MenuConstructor_Shop();
	menu.Display(client, 60);

	return Plugin_Handled;
}

public Action Command_Inventory(int client, int args)
{
	if (!GetClientInventoryLoaded(client)) return Plugin_Handled;

	Menu menu = MenuConstructor_Inventory(client);
	menu.Display(client, 60);

	return Plugin_Handled;
}

// ==================== [ MENUS ] ==================== //


// ==================== [ Shop ]

public Menu MenuConstructor_Shop()
{
	Menu menu = new Menu(MenuCallback_Shop);
	
	char title[32];
	g_cvShopTitle.GetString(title, sizeof(title));

	menu.SetTitle(title);

	StringMapSnapshot snapshot = gsm_ShopItems.Snapshot();

	char category[YASP_MAX_SHOP_CATEGORY_LENGTH];

	for (int i = 0; i < snapshot.Length; i++)
	{
		snapshot.GetKey(i, category, sizeof(category));

		menu.AddItem(category, category);
	}

	delete snapshot;

	return menu;
}

public Menu MenuConstructor_ShopCategory(char category[YASP_MAX_SHOP_CATEGORY_LENGTH])
{
	Menu page = new Menu(MenuCallback_ShopCategory);
	SetMenuExitBackButton(page, true);

	page.SetTitle(category);

	ArrayList items;
	gsm_ShopItems.GetValue(category, items);

	char class[YASP_MAX_ITEM_CLASS_LENGTH];
	char display[YASP_MAX_ITEM_NAME_LENGTH];

	for (int i = 0; i < items.Length; i++)
	{
		YASP_ShopItem item;
		items.GetArray(i, item, sizeof(item));

		class = item.class;
		display = item.display;

		page.AddItem(class, display);
	}

	return page;
}

public Menu MenuConstructor_ShopItemPage(YASP_ShopItem item, char category[YASP_MAX_SHOP_CATEGORY_LENGTH])
{
	Menu itempage = new Menu(MenuCallback_ShopItemPage);

	int cancel = ITEMDRAW_DEFAULT;
	if (!item.buyable) cancel = ITEMDRAW_DISABLED;

	itempage.SetTitle(item.display);

	itempage.AddItem("1", "", ITEMDRAW_SPACER);
	
	// item name
	char str_buyitem[YASP_MAX_ITEM_NAME_LENGTH + 6];
	Format(str_buyitem, sizeof(str_buyitem), "Item: %s", item.display);
	itempage.AddItem("2", str_buyitem, cancel);

	// price
	if (cancel == ITEMDRAW_DEFAULT)
	{
		char str_priceitem[40];
		Format(str_priceitem, sizeof(str_priceitem), "Price: %d", item.price);
		itempage.AddItem("3", str_priceitem, ITEMDRAW_DEFAULT);
	}

	itempage.AddItem("4", "", ITEMDRAW_SPACER);

	// buy button
	itempage.AddItem("buy", "Buy", cancel);

	// cancel button
	itempage.AddItem("cancel", "Cancel");

	itempage.AddItem(category, "category", ITEMDRAW_SPACER);

	char str_price[33];
	IntToString(item.price, str_price, sizeof(str_price));
	itempage.AddItem(str_price, "price", ITEMDRAW_SPACER);

	itempage.AddItem(item.class, "class", ITEMDRAW_SPACER);

	return itempage;
}

public int MenuCallback_Shop(Menu menu, MenuAction action, int param1, int param2)
{
	char category[YASP_MAX_SHOP_CATEGORY_LENGTH];

	Menu page;

	switch (action)
	{
		case MenuAction_Select:
		{
			menu.GetItem(param2, category, sizeof(category));

			page = MenuConstructor_ShopCategory(category);
			page.Display(param1, 60);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public int MenuCallback_ShopCategory(Menu menu, MenuAction action, int param1, int param2)
{
	char category[YASP_MAX_SHOP_CATEGORY_LENGTH];
	menu.GetTitle(category, sizeof(category));

	char class[YASP_MAX_ITEM_CLASS_LENGTH];

	switch (action)
	{
		case MenuAction_Select:
		{
			menu.GetItem(param2, class, sizeof(class));

			YASP_ShopItem item;

			ArrayList list;
			gsm_ShopItems.GetValue(category, list);

			for (int i = 0; i < list.Length; i++)
			{
				list.GetArray(i, item, sizeof(item));

				if (StrEqual(item.class, class)) break;
			}

			Menu itempage = MenuConstructor_ShopItemPage(item, category);

			itempage.Display(param1, 60);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Menu main;
				main = MenuConstructor_Shop();

				main.Display(param1, 60);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public int MenuCallback_ShopItemPage(Menu menu, MenuAction action, int param1, int param2)
{
	char key[32];

	char category[YASP_MAX_SHOP_CATEGORY_LENGTH];
	char str_price[33];
	char class[YASP_MAX_ITEM_CLASS_LENGTH];

	int price;

	char prefix[YASP_MAX_PREFIX_LENGTH];
	g_cvChatPrefix.GetString(prefix, sizeof(prefix));

	switch (action)
	{
		case MenuAction_Select:
		{
			menu.GetItem(param2, key, sizeof(key));

			if (StrEqual("buy", key))
			{
				int credits = YASP_GetClientCredits(param1);

				GetMenuItem(menu, param2 + 3, str_price, sizeof(str_price));
				price = StringToInt(str_price);

				GetMenuItem(menu, param2 + 4, class, sizeof(class));

				int itemid = ICI_GetIdOfClass(class);

				if (Inventory_HasItem(param1, itemid))
				{
					PrintToChat(param1, "%s %T", prefix, "Shop_AlreadyOwn", LANG_SERVER);
				}
				else if (credits >= price)
				{
					YASP_SetClientCredits(param1, credits - price);

					YASP_GiveItemToClient(param1, class);
				}
				else
				{
					PrintToChat(param1, "%s %T", prefix, "Shop_NotEnoughCredits", LANG_SERVER);
				}
			}

			if (StrEqual("cancel", key))
			{
				GetMenuItem(menu, param2 + 1, category, sizeof(category));

				Menu menucategory = MenuConstructor_ShopCategory(category);

				menucategory.Display(param1, 60);
			}
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

// ==================== [ Inventory ]
public Menu MenuConstructor_Inventory(int client)
{
	Menu menu = new Menu(MenuCallback_Inventory);
	
	char title[32];
	g_cvInventoryTitle.GetString(title, sizeof(title));
	menu.SetTitle(title);

	ArrayList categories = new ArrayList(YASP_MAX_SHOP_CATEGORY_LENGTH);
	ArrayList list = Inventory_GetInventory(client);

	YASP_ShopItem item;
	char class[YASP_MAX_ITEM_CLASS_LENGTH];

	for (int i = 0; i < list.Length; i++)
	{
		int itemid = list.Get(i);

		ICI_GetClassOfId(itemid, class, sizeof(class));
		GetShopItem(class, item, sizeof(item));

		if (categories.FindString(item.category) != -1) continue;

		categories.PushString(item.category);

		menu.AddItem(item.category, item.category);
	}

	delete categories;
	return menu;
}

public Menu MenuConstructor_InventoryCategory(int client, char category[YASP_MAX_SHOP_CATEGORY_LENGTH])
{
	Menu menucategory = new Menu(MenuCallback_InventoryCategory);
	SetMenuExitBackButton(menucategory, true);
	menucategory.SetTitle(category);

	ArrayList inv = Inventory_GetInventory(client);

	YASP_ShopItem item;
	char class[YASP_MAX_ITEM_CLASS_LENGTH];

	for (int i = 0; i < inv.Length; i++)
	{
		int itemid = inv.Get(i);
		ICI_GetClassOfId(itemid, class, sizeof(class));

		GetShopItem(class, item, sizeof(item));

		if (StrEqual(category, item.category))
		{
			menucategory.AddItem(class, class);
		}
	}

	return menucategory;
}

public Menu MenuConstructor_InventoryItem(int client, char class[YASP_MAX_ITEM_CLASS_LENGTH])
{
	Menu menu = new Menu(MenuCallback_InventoryItem);
	SetMenuExitBackButton(menu, true);

	YASP_ShopItem item;
	GetShopItem(class, item, sizeof(item));

	menu.SetTitle(item.display);

	int itemid = ICI_GetIdOfClass(class);

	ArrayList equips = Inventory_GetEquipped(client);
	bool item_equipped = equips.FindValue(itemid) != -1;

	// class id (id: 0)
	menu.AddItem(class, "", ITEMDRAW_SPACER);

	// item name
	char str_display[YASP_MAX_ITEM_NAME_LENGTH + 7];
	Format(str_display, sizeof(str_display), "Item: %s", item.display);
	menu.AddItem("display", str_display);

	// spacer
	menu.AddItem("2", "", ITEMDRAW_SPACER);

	// equip/dequip
	if (!item_equipped)
	{
		menu.AddItem("equip", "Equip Item");
	}
	else
	{
		menu.AddItem("dequip", "Dequip Item");
	}

	// spacer
	menu.AddItem("3", "", ITEMDRAW_SPACER);

	// refund
	if (item.refundable < 0)
	{
		menu.AddItem("refund", "Refund Item", ITEMDRAW_DISABLED);
	}
	else
	{
		menu.AddItem("refund", "Refund Item");
	}

	// spacer
	menu.AddItem("4", "", ITEMDRAW_SPACER);

	return menu;
}

public int MenuCallback_Inventory(Menu menu, MenuAction action, int param1, int param2)
{
	char category[YASP_MAX_SHOP_CATEGORY_LENGTH];

	switch(action)
	{
		case MenuAction_Select:
		{
			GetMenuItem(menu, param2, category, sizeof(category));

			Menu menucategory = MenuConstructor_InventoryCategory(param1, category);
			menucategory.Display(param1, 60);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public int MenuCallback_InventoryCategory(Menu menu, MenuAction action, int param1, int param2)
{
	char item[YASP_MAX_SHOP_CATEGORY_LENGTH];

	switch(action)
	{
		case MenuAction_Select:
		{
			GetMenuItem(menu, param2, item, sizeof(item));

			Menu itemmenu = MenuConstructor_InventoryItem(param1, item);
			itemmenu.Display(param1, 60);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Menu invmenu = MenuConstructor_Inventory(param1);
				invmenu.Display(param1, 60);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public int MenuCallback_InventoryItem(Menu menu, MenuAction action, int param1, int param2)
{
	char key[YASP_MAX_ITEM_CLASS_LENGTH];
	char class[YASP_MAX_ITEM_CLASS_LENGTH];

	char prefix[YASP_MAX_PREFIX_LENGTH];
	g_cvChatPrefix.GetString(prefix, sizeof(prefix));

	switch(action)
	{
		case MenuAction_Select:
		{
			GetMenuItem(menu, param2, key, sizeof(key));

			GetMenuItem(menu, 0, class, sizeof(class));

			if (StrEqual(key, "refund"))
			{
				Inventory_RefundItem(param1, class);
				PrintToChat(param1, "%s %T", prefix, "Shop_RefundItem", LANG_SERVER);
			}

			if (StrEqual(key, "equip"))
			{
				int itemid = ICI_GetIdOfClass(class);

				Inventory_EquipItem(param1, itemid);

				Menu itemmenu = MenuConstructor_InventoryItem(param1, class);
				itemmenu.Display(param1, 60);
			}

			if (StrEqual(key, "dequip"))
			{
				int itemid = ICI_GetIdOfClass(class);
				
				Inventory_DequipItem(param1, itemid);
				
				Menu itemmenu = MenuConstructor_InventoryItem(param1, class);
				itemmenu.Display(param1, 60);
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				GetMenuItem(menu, 0, class, sizeof(class));

				YASP_ShopItem item;
				GetShopItem(class, item, sizeof(item));

				Menu categorymenu = MenuConstructor_InventoryCategory(param1, item.category);
				categorymenu.Display(param1, 60);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

// ==================== [ GETTERS ] ==================== //

public StringMap GetShopItemsMap()
{
	return gsm_ShopItems;
}

public bool GetShopItem(char class[YASP_MAX_ITEM_CLASS_LENGTH], YASP_ShopItem buffer, int size)
{
	if (size < 1) return false;

	bool found = false;

	YASP_ShopItem item;
	ArrayList list;
	StringMapSnapshot snapshot = gsm_ShopItems.Snapshot();

	char key[YASP_MAX_SHOP_CATEGORY_LENGTH];

	for (int i = 0; i < snapshot.Length; i++)
	{
		snapshot.GetKey(i, key, sizeof(key));

		gsm_ShopItems.GetValue(key, list);

		for (int j = 0; j < list.Length; j++)
		{
			list.GetArray(j, item, sizeof(item));

			if (StrEqual(item.class, class)) {
				list.GetArray(j, buffer, size);

				found = true;
				break;
			}
		}
	}

	delete snapshot;
	return found;
}