/*
	Ready Timer
	by muddy
	
	Adds HUD text counting the time a team has been ready in tournament mode.
	For 6s/Highlander so teams can keep track of the 15 minute time for a forfeit.
*/

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required;
#pragma semicolon 1;

#define VERSION "1.0"

int redReady, bluReady;
int redMin = 0, redSec = 0, bluMin = 0, bluSec = 0;
ConVar redTeamName, bluTeamName;

public Plugin myinfo =  {
	name = "Ready Timer",
	author = "muddy",
	description = "HUD timer when a team readies up for tournament mode",
	version = VERSION,
	url = ""
}

public void OnPluginStart() {
	HookEvent("tournament_stateupdate", teamStateChange);
	HookEvent("teamplay_round_start", roundStart);
	redTeamName = FindConVar("mp_tournament_redteamname");
	bluTeamName = FindConVar("mp_tournament_blueteamname");
	//AddCommandListener(joinTeam, "jointeam");
	HookEvent("player_team", changeTeam);
}

public void OnMapStart() {
	redReady = false;
	bluReady = false;
	bluSec = 0;
	bluMin = 0;
	redSec = 0;
	redMin = 0;
}

void teamStateChange(Event event, const char[] name, bool dontBroadcast) {
	//int ply = GetClientOfUserId(GetEventInt(event, "userid"));
	int ply = GetEventInt(event, "userid");
	TFTeam readyTeam = TF2_GetClientTeam(ply);
	int ready = GetEventInt(event, "readystate");
	bool nameChange = GetEventBool(event, "namechange");
	
	//changing name and rupping fires two separate events, so just ignore any events dealing with team name
	if(nameChange) { return; }
	
	if(readyTeam == TFTeam_Red) {
		redReady = ready;
		if(ready == 0) { redSec = 0; redMin = 0; }
	} else { //spectators cannot change ready state so anything else should be blu
		bluReady = ready;
		if(ready == 0) { bluSec = 0; bluMin = 0; }
	}
	
	if(bluReady != redReady) { CreateTimer(1.0, updateHudTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE); }
}

void roundStart(Event event, const char[] name, bool dontBroadcast) {
	redSec = 0;
	redMin = 0;
	bluSec = 0;
	bluMin = 0;
}

/*
	in tournament mode, if a player changes between red and blu, their
	original team unreadies without sending an event. if a player joins
	spec or joins FROM spec, then the ready state doesn't change.
	
	therefore, we have to manually reset the timer when a player
	changes from red to blu or vice versa.
*/
void changeTeam(Event event, const char[] name, bool dontBroadcast) {
	TFTeam oldTeam = view_as<TFTeam>(GetEventInt(event, "oldteam"));
	TFTeam newTeam = view_as<TFTeam>(GetEventInt(event, "team"));
	
	if(oldTeam == TFTeam_Red && newTeam == TFTeam_Blue) {
		redReady = 0;
		redSec = 0;
		redMin = 0;
	} else if(oldTeam == TFTeam_Blue && newTeam == TFTeam_Red) {
		bluReady = 0;
		bluSec = 0;
		bluMin = 0;
	}
}

Action updateHudTimer(Handle timer) {
	//advance teams' timers before canceling the timer so the enemy can't fuck with it by rupping and cancelling
	if(redReady) {
		redSec += 1;
		if(redSec == 60) {
			redSec = 0;
			redMin += 1;
		}
	}
	if(bluReady) {
		bluSec += 1;
		if(bluSec == 60) {
			bluSec = 0;
			bluMin += 1;
		}
	}
	
	//if neither team, or both teams, are ready, cancel this timer
	if(bluReady == redReady) {
		return Plugin_Stop;
	}
	
	char teamName[32]; //6 is max you can enter manually, but some plugins offer extended team names
	
	if(redReady) {
		GetConVarString(redTeamName, teamName, sizeof(teamName));
		
		if(redSec < 10) { PrintCenterTextAll("%s has been ready for %i:0%i", teamName, redMin, redSec); }
		else { PrintCenterTextAll("%s has been ready for %i:%i", teamName, redMin, redSec); }
		
	} else if (bluReady) {
		GetConVarString(bluTeamName, teamName, sizeof(teamName));
		
		if(bluSec < 10) { PrintCenterTextAll("%s has been ready for %i:0%i", teamName, bluMin, bluSec); }
		else { PrintCenterTextAll("%s has been ready for %i:%i", teamName, bluMin, bluSec); }
		
	}
	
	return Plugin_Continue;
}