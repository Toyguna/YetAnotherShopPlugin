#if defined _yasp_included
 #endinput
#endif
#define _yasp_included

// ==================== [ CONSTANTS ] ==================== //

#define YASP_MAX_SHOP_CATEGORY_LENGTH 128

#define YASP_MAX_ITEM_CLASS_LENGTH 128
#define YASP_MAX_ITEM_NAME_LENGTH 128
#define YASP_MAX_ITEM_TYPE_LENGTH 16

#define YASP_STEAMAUTH_2 20

#define YASP_MAX_COMMAND_LENGTH 32
#define YASP_MAX_PREFIX_LENGTH 64

// ==================== [ NATIVES ] ==================== //

/*
 * Returns number of credits of given client.
 * -1 if client is invalid.
 * 
 * @param client    Client Index
 * @return  client's credits
 */
native int YASP_GetClientCredits(int client);

/*
 * Sets number of credits of client.
 * 
 * @param client    Client Index
 * @param amount    Credit amount
 */
native void YASP_SetClientCredits(int client, int amount);

/*
 * Adds number of credits of client.
 * 
 * @param client    Client Index
 * @param amount    Credit amount
 */
native void YASP_AddClientCredits(int client, int amount);

/*
 * Save data of client.
 * 
 * @param client    Client Index
 */
native void YASP_SaveClientData(int client);

/*
 * Load data of client.
 * 
 * @param client    Client Index
 */
native void YASP_LoadClientData(int client);


/*
 * Save data of all clients.
 */
native void YASP_SaveAllClientData();

/*
 * Converts string type to YASP_ITEMTYPE enum 
 *
 * @param string String to convert
 * @param size Size of string
 * @return  Enum, YASP_UNKNOWN is returned if operation fails.
*/
native YASP_ITEMTYPE YASP_GetEnumFromTypeStr(char[] string, int size);


/*
 * Converts YASP_ITEMTYPE enum to string type
 *
 * @param type  Enum to convert
 * @param string Buffer to store string
 * @param size Size of buffer
 * @return  1 if operation is successful, otherwise -1
*/
native int YASP_GetTypeStrFromEnum(YASP_ITEMTYPE type, char[] buffer, int size);