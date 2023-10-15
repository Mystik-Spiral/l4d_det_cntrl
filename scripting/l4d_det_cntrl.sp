/*
*	Detonation Control (l4d_det_cntrl) by Mystik Spiral
*
*	Control gascan/molotov detonation based on customizable proximity
*
*	Features:  
*
*	If a gascan or molotov detonation location is within a defined proximity
*	of self/incapped/other survivor, prevent detonation, otherwise treat
*	normally.  This is very helpful if you have plugins that allow bots to
*	throw molotovs.  If a bot/player/griefer makes a bad molotov throw or
*	shoots a gascan that would burn self/incapped/other survivor in the
*	defined proximity, this plugin will prevent detonation.
*
*	For gascans: Shooting the gascan when it is too close will not cause a
*	fire, though you will see shot decals on the undetonated gascan.
*	Move the gascan out of proximity and it will behave normally.
*
*	For molotovs: Once a thrown molotov hits the ground, if it is too close,
*	the molotov will skip across the ground like it does when hitting a wall.
*	The undetonated molotov can be picked back up and thrown again.
*	Throw the molotov out of proximity and it will behave normally.
*
*
*	Options:
*
*	Separate proximity values for gascan and molotov
*	Separate proximity values for vertical and vector distance
*	Separate proximity values for self, incapped, and other
*	Separately enable/disable gascan and molotov protection
*	Separately display/surpress gascan and molotov chat messages
*	Language translations: English, French, Spanish, Russian, Chinese
*
*
*	Notes:
*
*	Vertical proximity is checked first.  If no survivor is in vertical
*	proximity, then detonation will happen as normal and the vector
*	proximity check is skipped.
*
*	Vertical refers to the distance in height only (above/below).
*	Vector refers to the distance in three-dimensional space.
*	Distance is measured to the survivors eye position.
*
*
*	Requirements:
*	
*	Left 4 DHooks Direct (left4dhooks.smx) v1.138 or higher
*	https://forums.alliedmods.net/showthread.php?p=2684862
*
*
*	Github:
*
*	Want to contribute code enhancements?
*	Create a pull request using this GitHub repository:
*	https://github.com/Mystik-Spiral/l4d_det_cntrl
*
*
*
*	Discussion:
*
*	Discuss this plugin at AlliedModders - Detonation Control
*	https://forums.alliedmods.net/showthread.php?t=344220
*
*
*	Credits:
*
*	Silvers (SilverShot): Game type/mode detection/enable/disable template,
*	left4dhooks plugin, examples, fixes, and general community help.
*/

// ====================================================================================================
// Plugin Info Defines
// ====================================================================================================
#define PLUGIN_NAME             "[L4D & L4D2] Detonation Control"
#define PLUGIN_AUTHOR           "Mystik Spiral"
#define PLUGIN_DESCRIPTION      "Prevent gascan/molotov detonation in defined proximity"
#define PLUGIN_VERSION          "1.0"
#define PLUGIN_URL              "https://forums.alliedmods.net/showthread.php?t=344220"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Additional Defines
// ====================================================================================================
#define CVAR_FLAGS                  FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION   FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY
#define TRANSLATION_FILENAME        "l4d_det_cntrl.phrases"
#define MAXENTITIES                 2048
#define SURV_TEAM                   2

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvarMPGameMode, g_hCvarModesOn, g_hCvarModesOff, g_hCvarModesTog, g_hCvarAllow;
ConVar g_hCvarGascanEnable, g_hCvarMolotovEnable, g_hCvarGascanChat, g_hCvarMolotovChat;
ConVar g_hCvarGasVertSelfProx, g_hCvarGasVertIncapProx, g_hCvarGasVertOtherProx;
ConVar g_hCvarGasVecSelfProx, g_hCvarGasVecIncapProx, g_hCvarGasVecOtherProx;
ConVar g_hCvarMolVertSelfProx, g_hCvarMolVertIncapProx, g_hCvarMolVertOtherProx;
ConVar g_hCvarMolVecSelfProx, g_hCvarMolVecIncapProx, g_hCvarMolVecOtherProx;

// ====================================================================================================
// Handles
// ====================================================================================================
Handle g_hGascanChatSpam[MAXPLAYERS + 1], g_hMolotovChatSpam[MAXPLAYERS + 1];
Handle g_hSpawnMolotov[MAXENTITIES + 1];

// ====================================================================================================
// Global Variables
// ====================================================================================================
int g_iMap, g_iPlayerSpawn, g_iRoundStart, g_iCurrentMode;
bool g_bCvarAllow, g_bMapStarted, g_bL4D2; //g_bLateLoad
bool g_bCvarGascanEnable, g_bCvarMolotovEnable, g_bCvarGascanChat, g_bCvarMolotovChat;
bool g_bGascanChatSpam[MAXPLAYERS + 1], g_bMolotovChatSpam[MAXPLAYERS + 1];
float g_fCvarGasVertSelfProx, g_fCvarGasVertIncapProx, g_fCvarGasVertOtherProx;
float g_fCvarGasVecSelfProx, g_fCvarGasVecIncapProx, g_fCvarGasVecOtherProx;
float g_fCvarMolVertSelfProx, g_fCvarMolVertIncapProx, g_fCvarMolVertOtherProx;
float g_fCvarMolVecSelfProx, g_fCvarMolVecIncapProx, g_fCvarMolVecOtherProx;

// ====================================================================================================
// Plugin Load
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2)
	{
		g_bL4D2 = true;
		//g_bLateLoad = late;
		return APLRes_Success;
	}
	if ( test == Engine_Left4Dead )
	{
		g_bL4D2 = false;
		//g_bLateLoad = late;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
	return APLRes_SilentFailure;
}

// ====================================================================================================
// Verify Left4DHooks v1.138 or higher
// ====================================================================================================
public void OnAllPluginsLoaded()
{
	char sL4DH_ver[8];
	float fL4DH_ver;
	GetConVarString(FindConVar("left4dhooks_version"), sL4DH_ver, sizeof(sL4DH_ver));
	fL4DH_ver = StringToFloat(sL4DH_ver);
	if (fL4DH_ver < 1.138)
	{
		SetFailState("Missing required left4dhooks version 1.138 or higher");
	}
}

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public void OnPluginStart()
{
	LoadPluginTranslations();
	
	g_hCvarModesOn =			CreateConVar("l4d_detctl_modes_on",					"",		"Game mode names on, comma separated, no spaces. (Empty = all).", CVAR_FLAGS);
	g_hCvarModesOff =			CreateConVar("l4d_detctl_modes_off",				"",		"Game mode names off, comma separated, no spaces. (Empty = none).", CVAR_FLAGS);
	g_hCvarModesTog =			CreateConVar("l4d_detctl_modes_tog",				"0",	"Game type bitflags on, add #s together. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge", CVAR_FLAGS);
	g_hCvarAllow =				CreateConVar("l4d_detctl_enabled",					"1",	"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarGascanEnable =		CreateConVar("l4d_detctl_gascan_enable",			"1",	"Block gascan detonation if any survivor would be burned", CVAR_FLAGS);
	g_hCvarMolotovEnable =		CreateConVar("l4d_detctl_molotov_enable",			"1",	"Block molotov detonation if any survivor would be burned", CVAR_FLAGS);
	g_hCvarGascanChat =			CreateConVar("l4d_detctl_gascan_chat_msgs",			"1",	"Display gascan chat messages", CVAR_FLAGS);
	g_hCvarMolotovChat =		CreateConVar("l4d_detctl_molotov_chat_msgs",		"1",	"Display molotov chat messages", CVAR_FLAGS);
	g_hCvarGasVertSelfProx =	CreateConVar("l4d_detctl_gascan_vert_self_prox",	"100",	"Gascan vertical self proximity", CVAR_FLAGS);
	g_hCvarGasVertIncapProx =	CreateConVar("l4d_detctl_gascan_vert_incap_prox",	"160",	"Gascan vertical incap proximity", CVAR_FLAGS);
	g_hCvarGasVertOtherProx =	CreateConVar("l4d_detctl_gascan_vert_other_prox",	"150",	"Gascan vertical other proximity", CVAR_FLAGS);
	g_hCvarGasVecSelfProx =		CreateConVar("l4d_detctl_gascan_vec_self_prox",		"120",	"Gascan vector self proximity", CVAR_FLAGS);
	g_hCvarGasVecIncapProx =	CreateConVar("l4d_detctl_gascan_vec_incap_prox",	"275",	"Gascan vector incap proximity", CVAR_FLAGS);
	g_hCvarGasVecOtherProx =	CreateConVar("l4d_detctl_gascan_vec_other_prox",	"170",	"Gascan vector other proximity", CVAR_FLAGS);
	g_hCvarMolVertSelfProx =	CreateConVar("l4d_detctl_molotov_vert_self_prox",	"100",	"Molotov vertical self proximity", CVAR_FLAGS);
	g_hCvarMolVertIncapProx =	CreateConVar("l4d_detctl_molotov_vert_incap_prox",	"160",	"Molotov vertical incap proximity", CVAR_FLAGS);
	g_hCvarMolVertOtherProx =	CreateConVar("l4d_detctl_molotov_vert_other_prox",	"150",	"Molotov vertical other proximity", CVAR_FLAGS);
	g_hCvarMolVecSelfProx =		CreateConVar("l4d_detctl_molotov_vec_self_prox",	"120",	"Molotov vector self proximity", CVAR_FLAGS);
	g_hCvarMolVecIncapProx =	CreateConVar("l4d_detctl_molotov_vec_incap_prox",	"275",	"Molotov vector incap proximity", CVAR_FLAGS);
	g_hCvarMolVecOtherProx =	CreateConVar("l4d_detctl_molotov_vec_other_prox",	"170",	"Molotov vector other proximity", CVAR_FLAGS);
	
	CreateConVar("l4d_detctl_version", PLUGIN_VERSION, "Detonation Control plugin version.", CVAR_FLAGS_PLUGIN_VERSION);
	AutoExecConfig(true, "l4d_det_cntrl");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOn.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarGascanEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMolotovEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGascanChat.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMolotovChat.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGasVertSelfProx.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGasVertIncapProx.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGasVertOtherProx.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGasVecSelfProx.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGasVecIncapProx.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGasVecOtherProx.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMolVertSelfProx.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMolVertIncapProx.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMolVertOtherProx.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMolVecSelfProx.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMolVecIncapProx.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMolVecOtherProx.AddChangeHook(ConVarChanged_Cvars);
}

/****************************************************************************************************/

public void OnPluginEnd()
{
	ResetPlugin();
}

/****************************************************************************************************/

public void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
    {
    	LoadTranslations(TRANSLATION_FILENAME);
    }
    else
    {
    	if (g_bL4D2)
    	{
    		SetFailState("Missing required translation file \"<left4dead2>\\%s\", please download.", path, TRANSLATION_FILENAME);
    	}
    	else
    	{
    		SetFailState("Missing required translation file \"<left4dead>\\%s\", please download.", path, TRANSLATION_FILENAME);
    	}
    }
}

/****************************************************************************************************/

public void OnMapStart()
{
	g_bMapStarted = true;
}

/****************************************************************************************************/

public void OnMapEnd()
{
	g_iMap = 1;
	g_bMapStarted = false;
	ResetPlugin();
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
	IsAllowed();
}

/****************************************************************************************************/

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

/****************************************************************************************************/

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

/****************************************************************************************************/

void GetCvars()
{
	g_bCvarGascanEnable = g_hCvarGascanEnable.BoolValue;
	g_bCvarMolotovEnable = g_hCvarMolotovEnable.BoolValue;
	g_bCvarGascanChat = g_hCvarGascanChat.BoolValue;
	g_bCvarMolotovChat = g_hCvarMolotovChat.BoolValue;
	g_fCvarGasVertSelfProx = g_hCvarGasVertSelfProx.FloatValue;
	g_fCvarGasVertIncapProx = g_hCvarGasVertIncapProx.FloatValue;
	g_fCvarGasVertOtherProx = g_hCvarGasVertOtherProx.FloatValue;
	g_fCvarGasVecSelfProx = g_hCvarGasVecSelfProx.FloatValue;
	g_fCvarGasVecIncapProx = g_hCvarGasVecIncapProx.FloatValue;
	g_fCvarGasVecOtherProx = g_hCvarGasVecOtherProx.FloatValue;
	g_fCvarMolVertSelfProx = g_hCvarMolVertSelfProx.FloatValue;
	g_fCvarMolVertIncapProx = g_hCvarMolVertIncapProx.FloatValue;
	g_fCvarMolVertOtherProx = g_hCvarMolVertOtherProx.FloatValue;
	g_fCvarMolVecSelfProx = g_hCvarMolVecSelfProx.FloatValue;
	g_fCvarMolVecIncapProx = g_hCvarMolVecIncapProx.FloatValue;
	g_fCvarMolVecOtherProx = g_hCvarMolVecOtherProx.FloatValue;
}

/****************************************************************************************************/

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
	}
}

/****************************************************************************************************/

bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 && iCvarModesTog != 15 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModesOn.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}
	
	return true;
}

/****************************************************************************************************/

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}

/****************************************************************************************************/

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

/****************************************************************************************************/

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(g_iMap == 1 ? 5.0 : 1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

/****************************************************************************************************/

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(g_iMap == 1 ? 5.0 : 1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

/****************************************************************************************************/

public Action tmrStart(Handle timer)
{
	g_iMap = 0;
	ResetPlugin();
	return Plugin_Continue;
}

/****************************************************************************************************/

void ResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

/****************************************************************************************************/

public Action L4D2_CGasCan_EventKilled(int gascan, int &inflictor, int &attacker)
{
	//check if gascan detonation location is in burn proximity of any survivor
	//if so, prevent detonation, otherwise treat normally
	if (IsValidEdict(gascan) && attacker <= MaxClients)
	{
		if (g_bCvarGascanEnable && GasMolDetTooClose(gascan, g_fCvarGasVertSelfProx, g_fCvarGasVertIncapProx, g_fCvarGasVertOtherProx, g_fCvarGasVecSelfProx, g_fCvarGasVecIncapProx, g_fCvarGasVecOtherProx, attacker))
		{
			if (g_bCvarGascanChat && !g_bGascanChatSpam[attacker])
			{
				CPrintToChat(attacker, "{orange}[DetCtl]{lightgreen} %t", "GascanMsg");
				g_bGascanChatSpam[attacker] = true;
				g_hGascanChatSpam[attacker] = CreateTimer(11.0, GascanChatSpam, attacker);
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/****************************************************************************************************/

public Action L4D_Molotov_Detonate(int molotov, int client)
{
	//check if molotov detonation location is in burn proximity of any survivor
	//if so, prevent detonation, otherwise treat normally
	if (g_bCvarMolotovEnable && GasMolDetTooClose(molotov, g_fCvarMolVertSelfProx, g_fCvarMolVertIncapProx, g_fCvarMolVertOtherProx, g_fCvarMolVecSelfProx, g_fCvarMolVecIncapProx, g_fCvarMolVecOtherProx, client))
	{
		if (g_bCvarMolotovChat && !g_bMolotovChatSpam[client])
		{
			CPrintToChat(client, "{orange}[DetCtl]{lightgreen} %t", "MolotovMsg");
			g_bMolotovChatSpam[client] = true;
			g_hMolotovChatSpam[client] = CreateTimer(11.0, MolotovChatSpam, client);
		}
		g_hSpawnMolotov[molotov] = CreateTimer(0.1, SpawnMolotov, molotov);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/****************************************************************************************************/

public Action SpawnMolotov(Handle timer, int molotov)
{
	if (IsValidEdict(molotov))
	{
		float fMolPos[3], fMolAng[3], fMolVel[3];
		GetEntPropVector(molotov, Prop_Send, "m_vecOrigin", fMolPos);
		GetEntPropVector(molotov, Prop_Send, "m_angRotation", fMolAng);
		GetEntPropVector(molotov, Prop_Data, "m_vecVelocity", fMolVel);
		int iWepMol = CreateEntityByName("weapon_molotov");
		if (IsValidEdict(iWepMol))
		{
			DispatchSpawn(iWepMol);
			AcceptEntityInput(molotov, "kill");
			TeleportEntity(iWepMol, fMolPos, fMolAng, fMolVel);
		}
	}
	g_hSpawnMolotov[molotov] = INVALID_HANDLE;
	return Plugin_Continue;
}

/****************************************************************************************************/

public Action MolotovChatSpam(Handle timer, int client)
{
	g_bMolotovChatSpam[client] = false;
	g_hMolotovChatSpam[client] = INVALID_HANDLE;
	return Plugin_Continue;
}

/****************************************************************************************************/

public Action GascanChatSpam(Handle timer, int client)
{
	g_bGascanChatSpam[client] = false;
	g_hGascanChatSpam[client] = INVALID_HANDLE;
	return Plugin_Continue;
}

/****************************************************************************************************/

stock bool GasMolDetTooClose(int GasMol, float VertSelfProx, float VertIncapProx, float VertOtherProx, float VecSelfProx, float VecIncapProx, float VecOtherProx, int client)
{
	float fGasMolPos[3], fClientPos[3], fVectorDistance, fVerticalDistance;
	float fVectorSelfClosest = 99999.9, fVectorIncapClosest = 99999.9, fVectorOtherClosest = 99999.9;
	float fVerticalSelfClosest = 99999.9, fVerticalIncapClosest = 99999.9, fVerticalOtherClosest = 99999.9;
	//get position of gascan or molotov
	GetEntPropVector(GasMol, Prop_Send, "m_vecOrigin", fGasMolPos);
	//get position of all survivor clients
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == SURV_TEAM)
		{
			GetClientEyePosition(i, fClientPos);
			//get vector distance between current client and detonation location
			fVectorDistance = GetVectorDistance(fGasMolPos, fClientPos);
			//get vertical distance between current client and detonation location
			fVerticalDistance = FloatAbs(fClientPos[2] - fGasMolPos[2]);
			//PrintToServer("client: %i-%N, VecDist: %f, VerDist: %f", i, i, fVectorDistance, fVerticalDistance);
			//track closest self/incap/other vector/vertical distance between client and detonation location
			if (i != client)
			{
				if (fVectorDistance < fVectorOtherClosest)
				{
					fVectorOtherClosest = fVectorDistance;
				}
				if (fVerticalDistance < fVerticalOtherClosest)
				{
					fVerticalOtherClosest = fVerticalDistance;
				}
			}
			else
			{
				fVectorSelfClosest = fVectorDistance;
				fVerticalSelfClosest = fVerticalDistance;
			}
			if (IsClientIncapped(i))
			{
				if (fVectorDistance < fVectorIncapClosest)
				{
					fVectorIncapClosest = fVectorDistance;
				}
				if (fVerticalDistance < fVerticalIncapClosest)
				{
					fVerticalIncapClosest = fVerticalDistance;
				}
			}
		}
	}
	//f*Closest now holds distance from detonation location to closest self/incap/other client
	//PrintToServer("Closest Vertical: self: %f, incap: %f, other: %f", fVerticalSelfClosest, fVerticalIncapClosest, fVerticalOtherClosest);
	//PrintToServer("Closest Vector: self: %f, incap: %f, other: %f", fVectorSelfClosest, fVectorIncapClosest, fVectorOtherClosest);
	//if all closest vertical distance is not in detontation proximity return false and skip vector check
	if (fVerticalSelfClosest > VertSelfProx && fVerticalIncapClosest > VertIncapProx && fVerticalOtherClosest > VertOtherProx)
	{
		return false;
	}
	//if any closest vector distance is in detonation proximity return true, otherwise return false
	return (fVectorSelfClosest < VecSelfProx || fVectorIncapClosest < VecIncapProx || fVectorOtherClosest < VecOtherProx) ? true : false;
}

/****************************************************************************************************/

public void CPrintToChat(int client, const char[] message, any ...)
{
    static char buffer[512];
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{white}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "\x04");
    ReplaceString(buffer, sizeof(buffer), "{olive}", "\x05");

    PrintToChat(client, buffer);
}

stock bool IsClientIncapped(int client)
{
	//convert integer to boolean for return value
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}
