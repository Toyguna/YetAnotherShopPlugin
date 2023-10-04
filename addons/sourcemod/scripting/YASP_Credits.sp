#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

#include <yasp>

// ==================== [ CREDITS ] ==================== //

public Action Credits_OnPlay(Handle timer)
{
	ConVar cv_onplay = FindConVar("yasp_points_onplay");
	ConVar cv_prefix = FindConVar("yasp_chat_prefix");

	char prefix[YASP_MAX_PREFIX_LENGTH];
	cv_prefix.GetString(prefix, sizeof(prefix));

	int amount = cv_onplay.IntValue;

	for (int i = 0; i < MaxClients; i++)
	{
		if (!IsClientValid(i)) continue;
		if (IsFakeClient(i)) continue;

		YASP_AddClientCredits(i, amount);

		if (!IsClientInGame(i)) continue;
		PrintToChat(i, "%s %T", prefix, "Credits_OnPlay", LANG_SERVER, amount);
	}

	return Plugin_Continue;
}

public void Credits_OnKill(int killer, int victim)
{
	ConVar cv_onkill = FindConVar("yasp_points_onkill");
	int amount = cv_onkill.IntValue;

	ConVar cv_prefix = FindConVar("yasp_chat_prefix");
	char prefix[YASP_MAX_PREFIX_LENGTH];
	cv_prefix.GetString(prefix, sizeof(prefix));

	char victim_name[MAX_NAME_LENGTH];
	GetClientName(victim, victim_name, sizeof(victim_name));

	YASP_AddClientCredits(killer, amount);
	PrintToChat(killer, "%s %T", prefix, "Credits_OnKill", LANG_SERVER, amount, victim_name);
}

public void Credits_OnUber(int medic)
{
	ConVar cv_onuber = FindConVar("yasp_points_onuber");
	int amount = cv_onuber.IntValue;

	ConVar cv_prefix = FindConVar("yasp_chat_prefix");
	char prefix[YASP_MAX_PREFIX_LENGTH];
	cv_prefix.GetString(prefix, sizeof(prefix));

	YASP_AddClientCredits(medic, amount);
	PrintToChat(medic, "%s %T", prefix, "Credits_OnUber", LANG_SERVER, amount);
}

public void Credits_OnAssist(int client)
{
	if (!IsClientValid(client)) return;

	ConVar cv_onuber = FindConVar("yasp_points_onassist");
	int amount = cv_onuber.IntValue;

	ConVar cv_prefix = FindConVar("yasp_chat_prefix");
	char prefix[YASP_MAX_PREFIX_LENGTH];
	cv_prefix.GetString(prefix, sizeof(prefix));

	YASP_AddClientCredits(client, amount);
	PrintToChat(client, "%s %T", prefix, "Credits_OnAssist", LANG_SERVER, amount);
}

public void Credits_OnCap(int client)
{
	ConVar cv_onuber = FindConVar("yasp_points_oncap");
	int amount = cv_onuber.IntValue;

	ConVar cv_prefix = FindConVar("yasp_chat_prefix");
	char prefix[YASP_MAX_PREFIX_LENGTH];
	cv_prefix.GetString(prefix, sizeof(prefix));

	YASP_AddClientCredits(client, amount);
	PrintToChat(client, "%s %T", prefix, "Credits_OnCap", LANG_SERVER, amount);
}

public void Credits_OnDestroySapper(int client)
{
	ConVar cv_onuber = FindConVar("yasp_points_ondestroysapper");
	int amount = cv_onuber.IntValue;

	ConVar cv_prefix = FindConVar("yasp_chat_prefix");
	char prefix[YASP_MAX_PREFIX_LENGTH];
	cv_prefix.GetString(prefix, sizeof(prefix));

	YASP_AddClientCredits(client, amount);
	PrintToChat(client, "%s %T", prefix, "Credits_OnDestroySapper", LANG_SERVER, amount);
}

public void Credits_OnDestroyBuilding(int client)
{
	ConVar cv_onuber = FindConVar("yasp_points_ondestroybuilding");
	int amount = cv_onuber.IntValue;

	ConVar cv_prefix = FindConVar("yasp_chat_prefix");
	char prefix[YASP_MAX_PREFIX_LENGTH];
	cv_prefix.GetString(prefix, sizeof(prefix));

	YASP_AddClientCredits(client, amount);
	PrintToChat(client, "%s %T", prefix, "Credits_OnDestroyBuilding", LANG_SERVER, amount);
}