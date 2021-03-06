///THIS IS A CUSTOM INCLUDE BY REVAN

/*
By Revan
www.wcs-lagerhaus.de
Version : 1.0
*/
//constants:
#define MAX_BEAM_SCROLLSPEED 100

//PushClientToVector is deprecated use PushEntToVector instead
#define PushClientToVector PushEntToVector

stock PushEntToVector( edict, Float:pos1[3], Float:power )
{
	new Float:pos2[3], Float:main_origin[3], Float:velo1[3], Float:velo2[3];
	GetEntPropVector(edict, Prop_Send, "m_vecOrigin", pos2);

	main_origin[0] = pos1[0] - pos2[0], main_origin[1] = pos1[1] - pos2[1], main_origin[2] = pos1[2] - pos2[2];
	velo1[0] += 0, velo1[1] += 0, velo1[2] += 300;
	
	velo2[0] = main_origin[0] * ( 100 * power );
	velo2[1] = main_origin[1] * ( 100 * power );
	velo2[2] = main_origin[2] * ( 100 * power );

	TeleportEntity( edict, NULL_VECTOR, NULL_VECTOR, velo1 );
	TeleportEntity( edict, NULL_VECTOR, NULL_VECTOR, velo2 );
}

stock CreateParticles(const client,bool:parentent,Float:fLifetime,Float:fAng[3],Float:BaseSpread,Float:StartSize,Float:EndSize,Float:Twist,String:material[],String:renderclr[],String:SpreadSpeed[],String:JetLength[],String:Speed[],String:Rate[]){
	new particle = CreateEntityByName("env_smokestack");
	if(IsValidEdict(particle) && IsClientInGame(client))
	{
		decl String:Name[32], Float:fPos[3];
		Format(Name, sizeof(Name), "W3S_particles_%i", client);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		fPos[2] += 50.0;
		// Set Key Values
		DispatchKeyValueVector(particle, "Origin", fPos);
		DispatchKeyValueVector(particle, "Angles", fAng);
		DispatchKeyValueFloat(particle, "BaseSpread", BaseSpread);
		DispatchKeyValueFloat(particle, "StartSize", StartSize);
		DispatchKeyValueFloat(particle, "EndSize", EndSize);
		DispatchKeyValueFloat(particle, "Twist", Twist);
		
		DispatchKeyValue(particle, "Name", Name);
		DispatchKeyValue(particle, "SmokeMaterial", material);
		DispatchKeyValue(particle, "RenderColor", renderclr);
		DispatchKeyValue(particle, "SpreadSpeed", SpreadSpeed);
		DispatchKeyValue(particle, "RenderAmt", "255");
		DispatchKeyValue(particle, "JetLength", JetLength);
		DispatchKeyValue(particle, "RenderMode", "0");
		DispatchKeyValue(particle, "Initial", "0");
		DispatchKeyValue(particle, "Speed", Speed);
		DispatchKeyValue(particle, "Rate", Rate);
		DispatchSpawn(particle);
		
		// Set Entity Inputs
		if(parentent)
		{
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", client, particle, 0);
		}
		AcceptEntityInput(particle, "TurnOn");
		CreateTimer(fLifetime, INCTimer_RemoveEntity, particle);
		return particle;
	}
	else
	{
		LogError("Failed to create entity env_smokestack!");
	}
	return -1;
}

stock CreateFire(const client,String:firesize[],String:health[],String:fireattack[],String:firetype[],String:flags[],Float:damagescale,Float:fLifetime){
	new fire = CreateEntityByName("env_fire");
	if(IsValidEdict(fire) && IsClientInGame(client))
	{
		decl String:Name[32], Float:fPos[3];
		Format(Name, sizeof(Name), "W3S_fire_%i", client);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		DispatchKeyValueFloat(fire, "damagescale", damagescale);

		DispatchKeyValue(fire, "Name", Name);
		DispatchKeyValue(fire, "health", health);
		DispatchKeyValue(fire, "fireattack", fireattack);
		DispatchKeyValue(fire, "firetype", firetype);
		DispatchKeyValue(fire, "flags", flags);
		DispatchKeyValue(fire, "firesize", firesize);
		DispatchSpawn(fire);
		ActivateEntity(fire);
		TeleportEntity(fire, fPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(fire, "StartFire");
		CreateTimer(fLifetime, INCTimer_RemoveEntity, fire);
		return fire;
	}
	else
	{
		LogError("Failed to create entity env_fire!");
	}
	return -1;
}


stock CreateTesla(const client,Float:flifetime_min,Float:flifetime_max,Float:thick_min,Float:thick_max,Float:interval_min,Float:interval_max,Float:radiustesla,String:beamcount_min[],String:beamcount_max[],String:ColorTesla[],String:sound[],String:beammodel[],bool:spark){
	new point_tesla = CreateEntityByName("point_tesla");
	if(IsValidEdict(point_tesla) && IsClientInGame(client))
	{
		decl String:Name[32], Float:fPos[3];
		Format(Name, sizeof(Name), "W3S_tesla_%i", client);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		fPos[2]+=42.0;
		DispatchKeyValueFloat(point_tesla, "lifetime_min", flifetime_min);
		DispatchKeyValueFloat(point_tesla, "lifetime_min", flifetime_max);
		DispatchKeyValueFloat(point_tesla, "thick_min", thick_min);
		DispatchKeyValueFloat(point_tesla, "thick_max", thick_max);
		DispatchKeyValueFloat(point_tesla, "interval_min", interval_min);
		DispatchKeyValueFloat(point_tesla, "interval_max", interval_max);
		DispatchKeyValueFloat(point_tesla, "m_flRadius", radiustesla);
		DispatchKeyValue(point_tesla, "m_Color", ColorTesla);

		DispatchKeyValue(point_tesla, "Name", Name);
		DispatchKeyValue(point_tesla, "beamcount_min", beamcount_min);
		DispatchKeyValue(point_tesla, "beamcount_max", beamcount_max);
		DispatchKeyValue(point_tesla, "m_SoundName", sound);
		DispatchKeyValue(point_tesla, "texture", beammodel);
		DispatchSpawn(point_tesla);
		ActivateEntity(point_tesla);
		TeleportEntity(point_tesla, fPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(point_tesla, "TurnOn");
		if(spark)
		AcceptEntityInput(point_tesla, "DoSpark");
		
		CreateTimer(flifetime_max+0.2, INCTimer_RemoveEntity, point_tesla);
		return point_tesla;
	}
	else
	{
		LogError("Failed to create entity point_tesla!");
	}
	return -1;
}

stock CreateExplosion(Float:VectorPos[3], owner, String:classname[], String:magnitude[])
{
	new g_ent = CreateEntityByName("env_explosion");
	SetEntPropEnt(g_ent, Prop_Send, "m_hOwnerEntity", owner);
	DispatchKeyValue(g_ent, "classname", classname);
	DispatchKeyValue(g_ent, "iMagnitude", magnitude);
	DispatchSpawn(g_ent);
	TeleportEntity(g_ent, VectorPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(g_ent, "Explode");
	RemoveEdict(g_ent);
}

public Action:INCTimer_RemoveEntity(Handle:timer, any:edict)
{
	if(IsValidEdict(edict))
	{
		AcceptEntityInput(edict, "Kill");
	}
}

stock SetEntityAimToClient( edict, target)
{
	new Float:spos[3],  Float:epos[3], Float:vecles[3], Float:angles[3];
	GetEntPropVector(edict, Prop_Send, "m_vecOrigin", spos);
	GetClientAbsOrigin( target, epos );
	SubtractVectors( epos, spos, vecles );
	GetVectorAngles( vecles, angles );
	angles[2] = 0.0;
	TeleportEntity( edict, NULL_VECTOR, angles, NULL_VECTOR );
}