#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

#include <yasp>

// ==================== [ GLOBAL VARIABLES ] ==================== //

public ArrayList ga_sItemClassId;
public StringMap gsm_aPlayerInventory;
public StringMap gsm_aPlayerEquipped;

public bool ga_bPlayerInvLoaded[MAXPLAYERS + 1] = { false, ... };

// ==================== [ ENUMS ] ==================== //

enum YASP_ITEMTYPE
{
	YASP_UNKNOWN,
	YASP_NAMETAG,
	YASP_TRAIL
}

// ==================== [ STRUCTS ] ==================== //

enum struct YASP_ShopItem
{
	char class[YASP_MAX_ITEM_CLASS_LENGTH];
	char display[YASP_MAX_ITEM_NAME_LENGTH];

	bool buyable;
	int price;
	float refundable;

	YASP_ITEMTYPE type;
}

// ==================== [ INITIALIZE ] ==================== //

public void Items_Init()
{
	ga_sItemClassId = new ArrayList(YASP_MAX_ITEM_CLASS_LENGTH);
	gsm_aPlayerInventory = new StringMap();
	gsm_aPlayerEquipped = new StringMap();

	ICI_InitializeArray();
}

// ==================== [ FUNCTIONS ] ==================== //


// =============== [ ga_sItemClassId ]
public void ICI_InitializeArray()
{
	StringMap shop = GetShopItemsMap();

	StringMapSnapshot snapshot = shop.Snapshot();
	char key[YASP_MAX_SHOP_CATEGORY_LENGTH];
	char class[YASP_MAX_ITEM_CLASS_LENGTH];

	for (int i = 0; i < snapshot.Length; i++)
	{
		snapshot.GetKey(i, key, sizeof(key));

		ArrayList list;
		shop.GetValue(key, list);

		for (int j = 0; j < list.Length; j++)
		{
			list.GetString(j, class, sizeof(class));

			ICI_AddClassToArray(class);
		}
	}

	delete snapshot;
}

public void ICI_AddClassToArray(char class[YASP_MAX_ITEM_CLASS_LENGTH])
{
	ga_sItemClassId.PushString(class);
}

// class -> id
public int ICI_GetIdOfClass(char class[YASP_MAX_ITEM_CLASS_LENGTH])
{
	int id = ga_sItemClassId.FindString(class);

	return id;
}

// id -> class
public void ICI_GetClassOfId(int id, char[] buffer, int size)
{
	if (size < 1) return;
	
	ga_sItemClassId.GetString(id, buffer, size);
}

// =============== [ gsm_aPlayerInventory ]
public void Inventory_CreateList(int client)
{
	if (!IsClientValid(client)) return;

	char str_client[2];
	IntToString(client, str_client, sizeof(str_client));

	gsm_aPlayerInventory.SetValue(str_client, new ArrayList(), true);
	gsm_aPlayerEquipped.SetValue(str_client, new ArrayList(), true);
}

public void Inventory_AddItem(int client, int itemid)
{
	if (!IsClientValid(client)) return;

	char str_client[2];
	IntToString(client, str_client, sizeof(str_client));

	ArrayList inv;
	gsm_aPlayerInventory.GetValue(str_client, inv);

	if (inv.FindValue(itemid) != -1) return;

	inv.Push(itemid);

	gsm_aPlayerInventory.SetValue(str_client, inv, true);
}

public void Inventory_RemoveItem(int client, int itemid)
{
	if (!IsClientValid(client)) return;

	char str_client[2];
	IntToString(client, str_client, sizeof(str_client));
	
	ArrayList inv;
	gsm_aPlayerInventory.GetValue(str_client, inv);

	int index = inv.FindValue(itemid);

	if (index == -1) return;

	inv.Erase(index);
	
	gsm_aPlayerInventory.SetValue(str_client, inv, true);
}

public bool Inventory_HasItem(int client, int itemid)
{
	if (!IsClientValid(client)) return false;

	char str_client[2];
	IntToString(client, str_client, sizeof(str_client));
	
	ArrayList inv;
	gsm_aPlayerInventory.GetValue(str_client, inv);

	return inv.FindValue(itemid) != -1;
}

public ArrayList Inventory_GetInventory(int client)
{	
	if (!IsClientValid(client)) return null;

	char str_client[2];
	IntToString(client, str_client, sizeof(str_client));
	
	ArrayList inv;
	gsm_aPlayerInventory.GetValue(str_client, inv);

	return inv;
}

// =============== [ gsm_aPlayerEquipped ]

/**
 * Equips an item for client
 * 
 * @param client	Client id
 * @param itemid	Item id
 * 
 * @return true if already equipped, false otherwise
 */
public bool Inventory_EquipItem(int client, int itemid)
{
	if (!IsClientValid(client)) return false;

	char str_client[2];
	IntToString(client, str_client, sizeof(str_client));
	
	ArrayList inv;
	gsm_aPlayerEquipped.GetValue(str_client, inv);

	if (inv.FindValue(itemid) != -1) return true; // if already equipped

	inv.Push(itemid);
	
	gsm_aPlayerInventory.SetValue(str_client, inv, true);

	return false;
}

/**
 * Dequips an item for client
 * 
 * @param client	Client id
 * @param itemid	Item id
 * 
 * @return true if already dequipped, false otherwise
 */
public bool Inventory_DequipItem(int client, int itemid)
{
	if (!IsClientValid(client)) return false;

	char str_client[2];
	IntToString(client, str_client, sizeof(str_client));
	
	ArrayList inv;
	gsm_aPlayerEquipped.GetValue(str_client, inv);

	if (inv.FindValue(itemid) != -1) return true; // if already dequipped

	inv.Erase(itemid);
	
	gsm_aPlayerInventory.SetValue(str_client, inv, true);

	return false;
}

public ArrayList Inventory_GetEquipped(int client)
{
	if (!IsClientValid(client)) return null;

	char str_client[2];
	IntToString(client, str_client, sizeof(str_client));
	
	ArrayList inv;
	gsm_aPlayerEquipped.GetValue(str_client, inv);

	return inv;
}

// ==================== [ GETTERS ] ==================== //
public ArrayList ICI_GetClassIdArray()
{
	return ga_sItemClassId;
}

public StringMap Inventory_GetHashMap()
{
	return gsm_aPlayerInventory;
}

public bool GetClientInventoryLoaded(int client)
{
	return ga_bPlayerInvLoaded[client];
}

// ==================== [ SETTERS ] ==================== //
public void SetClientInventoryLoaded(int client, bool loaded)
{
	ga_bPlayerInvLoaded[client] = loaded;
}