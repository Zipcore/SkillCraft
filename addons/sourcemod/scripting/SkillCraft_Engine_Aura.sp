#pragma dynamic 30000

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

public Plugin:myinfo = 
{
	name = "SkillCraft - Engine - Aura",
	author = "SkillCraft Team",
	description = "Aura Engine for SkillCraft"
};

new bool:AuraOrigin[MAXPLAYERSCUSTOM][MAXAURAS];

new Float:AuraDistance[MAXPLAYERSCUSTOM][MAXAURAS];

new HasAura[MAXPLAYERSCUSTOM][MAXAURAS]; //int, we just count up

new String:AuraShort[MAXAURAS][32];
new bool:AuraTrackOtherTeam[MAXAURAS];
new AuraCount=0;

new Handle:g_Forward;

new Float:lastCalcAuraTime;

public OnPluginStart()
{
	CreateTimer(0.5,CalcAura,_,TIMER_REPEAT);
}
public bool:Init_SC_NativesForwards()
{
	
	//Backwards compatible old format / easy buff compatible
	CreateNative("SC_RegisterAura",Native_SC_RegisterAura);//for skills
	CreateNative("SC_SetAuraFromPlayer",Native_SC_SetAuraFromPlayer);

	// New format allows greater flexiblity with distances
	CreateNative("SC_RegisterChangingDistanceAura",Native_SC_RegisterChangingDistanceAura);//for races
	CreateNative("SC_SetPlayerAura",Native_SC_SetPlayerAura);

	// Both systems use this:
	CreateNative("SC_RemovePlayerAura",Native_SC_RemovePlayerAura);
	CreateNative("SC_HasAura",Native_SC_HasAura);
	
	g_Forward=CreateGlobalForward("On_SC_PlayerAuraStateChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
	return true;
}

public Native_SC_RegisterAura(Handle:plugin,numParams)
{
	new String:taurashort[32];
	GetNativeString(1,taurashort,32);
	
	for(new aura=1; aura <= AuraCount; aura++)
	{
		if(StrEqual(taurashort, AuraShort[aura], false))
		{
			return aura; //already registered
		}
	}
	if(AuraCount + 1 < MAXAURAS)
	{
		AuraCount++;
		strcopy(AuraShort[AuraCount], 32, taurashort);
		
		for(new client=1;client<=MaxClients;client++)
		{
			AuraDistance[client][AuraCount] = Float:GetNativeCell(2);
		}
		
		AuraTrackOtherTeam[AuraCount] = bool:GetNativeCell(3);
		
		//War3_LogInfo("Registered aura \"%s\" with a distance of \"%f\". TrackOtherTeam: %i", AuraShort[AuraCount], AuraDistance[1][AuraCount], AuraTrackOtherTeam[AuraCount]);
		return AuraCount;
	}
	else
	{
		ThrowError("CANNOT REGISTER ANY MORE AURAS");
	}
	
	return -1;
}
public Native_SC_SetAuraFromPlayer(Handle:plugin,numParams)
{
	new aura=GetNativeCell(1);
	new client=GetNativeCell(2);
	AuraOrigin[client][aura]=bool:GetNativeCell(3);
}



public Native_SC_RegisterChangingDistanceAura(Handle:plugin,numParams)
{
	new String:taurashort[32];
	GetNativeString(1,taurashort,32);
	
	for(new aura=1; aura <= AuraCount; aura++)
	{
		if(StrEqual(taurashort, AuraShort[aura], false))
		{
			// Change values of aura, since its already registered
			AuraTrackOtherTeam[aura] = bool:GetNativeCell(2);
			//War3_LogInfo("Changed - Registered aura \"%s\" TrackOtherTeam: %i", AuraShort[aura], AuraTrackOtherTeam[aura]);
			return aura; //already registered
		}
	}
	if(AuraCount + 1 < MAXAURAS)
	{
		AuraCount++;
		strcopy(AuraShort[AuraCount], 32, taurashort);
		
		AuraTrackOtherTeam[AuraCount] = bool:GetNativeCell(2);
		
		//War3_LogInfo("Registered aura \"%s\" TrackOtherTeam: %i", AuraShort[AuraCount], AuraTrackOtherTeam[AuraCount]);
		return AuraCount;
	}
	else
	{
		ThrowError("CANNOT REGISTER ANY MORE AURAS");
	}
	
	return -1;
}
public Native_SC_SetPlayerAura(Handle:plugin,numParams)
{
	new aura=GetNativeCell(1);
	new client=GetNativeCell(2);
	AuraDistance[client][aura]=Float:GetNativeCell(3);
	AuraOrigin[client][aura]=true;
}
public Native_SC_RemovePlayerAura(Handle:plugin,numParams)
{
	new aura=GetNativeCell(1);
	new client=GetNativeCell(2);
	AuraDistance[client][aura]=0.0;
	AuraOrigin[client][aura]=false;
}
public Native_SC_HasAura(Handle:plugin,numParams)
{
	new aura=GetNativeCell(1);
	new client=GetNativeCell(2);

	return ValidPlayer(client,true)&&HasAura[client][aura];
}
public On_SC_Event(SC_EVENT:event,client){
	if(event==ClearPlayerVariables){
		InternalClearPlayerVars(client);
	}
}
InternalClearPlayerVars(client){
	for(new aura=1;aura<=AuraCount;aura++)
	{
		AuraOrigin[client][aura]=false;
		AuraDistance[client][aura]=0.0;
	}
}
//re calculate auras when one of these things happen, however a 0.1 delay minimum (like 32 players spawn at round start, we dont calculate 32 times)
public On_SC_EventSpawn(){ ShouldCalcAura();}
public On_SC_EventDeath(){ ShouldCalcAura();}
ShouldCalcAura(){
	if(GetEngineTime()>lastCalcAuraTime+0.1){
		CalcAura(INVALID_HANDLE);
	}
}
public Action:CalcAura(Handle:t)
{
	lastCalcAuraTime=GetEngineTime();
	//store old aura count
	decl OldHasAura[MAXPLAYERSCUSTOM][MAXAURAS];
	for(new client=1;client<=MaxClients;client++)
	{
		for(new aura=1;aura<=AuraCount;aura++){
			OldHasAura[client][aura]=HasAura[client][aura];
			HasAura[client][aura]=0; //clear bool aura
		}
	}
	
	
	//	new Float:Distances[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];
	decl Float:vec1[3];
	decl Float:vec2[3];
	decl teamtarget;
	decl teamclient;
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			for(new target=client;target<=MaxClients;target++) //client can be target
			{
				if(ValidPlayer(target,true))
				{
					teamtarget=GetClientTeam(target);
					teamclient=GetClientTeam(client);
					GetClientAbsOrigin(client,vec1);
					GetClientAbsOrigin(target,vec2);
					new Float:dis=GetVectorDistance(vec1,vec2);
					//DP("aura %d  %f",client,dis);
					for(new aura=1;aura<=AuraCount;aura++){
						//boolean magic!!!!!!!! De Morgan wuz here   (And El Diablo improved it! 9/3/2013)

						//client originating an aura
						if(AuraOrigin[client][aura] && dis<AuraDistance[client][aura]){ 
							//DP("aura origin %d",client);
							if( (!AuraTrackOtherTeam[aura])==(teamclient==teamtarget)) 
							// || (AuraTrackOtherTeam[aura]&&teamclient!=teamtarget)
							
							{
								//DP("aura target on %d",target);
								HasAura[target][aura]++;
							}
						}
						//target originating an aura
						if(AuraOrigin[target][aura] &&target!=client && dis<AuraDistance[target][aura]){  //skip if client is target, which we already did up top
							if( (!AuraTrackOtherTeam[aura])==(teamclient==teamtarget)   ) 
								//|| (AuraTrackOtherTeam[aura]&&teamclient!=teamtarget)
							
							{
								HasAura[client][aura]++;
							}
						}
					}
				}
			}
		}	
	}
	for(new client=1;client<=MaxClients;client++)
	{
		for(new aura=1;aura<=AuraCount;aura++)
		{
			if(HasAura[client][aura]>1){ //overlapped from different people
				HasAura[client][aura]=1;
			}
			//stat changed?
			if(  (OldHasAura[client][aura]!=HasAura[client][aura])	)
			{
				//DP("NEW AURA %d %d %d",aura,client,HasAuraLevel[client][aura]);
				Call_StartForward(g_Forward);
				Call_PushCell(client);
				Call_PushCell(aura);
				Call_PushCell(HasAura[client][aura]);
				Call_Finish(dummy);
			}
		}
	}
	SC_CreateEvent(OnAuraCalculationFinished,0);
	
}


