#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

#include <yasp>

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
    char id[YASP_MAX_ITEM_ID_LENGTH];
    char displayname[YASP_MAX_ITEM_NAME_LENGTH];

    bool buyable;
    int price;
    YASP_ITEMTYPE type;

    int Init(
        char id[YASP_MAX_ITEM_ID_LENGTH], char displayname[YASP_MAX_ITEM_NAME_LENGTH], 
        bool buyable, int price, YASP_ITEMTYPE type
    )
    {
        this.id = id;
        this.displayname = displayname;

        this.buyable = buyable;
        this.price = price;
        this.type = type;

        return 0;
    }
}