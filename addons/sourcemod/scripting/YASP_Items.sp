#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

#include <yasp>

// ==================== [ GLOBAL VARIABLES ] ==================== //

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
    YASP_ITEMTYPE type;
}