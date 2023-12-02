
class CajunBodyNode : Actor
{
	Default
	{
		+NOSECTOR
		+NOGRAVITY
		+INVISIBLE
	}
}

class CajunTrace : Actor
{
	Default
	{
		Speed 12;
		Radius 6;
		Height 8;
		+NOBLOCKMAP
		+DROPOFF
		+MISSILE
		+NOGRAVITY
		+NOTELEPORT
	}
}

struct BotInfoData native
{
	native int		MoveCombatDist;
	native int		flags;
	native Actor	projectileType;
}

struct BotSkillData native
{
	native int aiming;
	native int perfection;
	native int reaction;   //How fast the bot will fire after seeing the player.
	native int isp;        //Instincts of Self Preservation. Personality
}

// TODO: do we need this?
enum dirtype_t
{
	DI_EAST,
	DI_NORTHEAST,
	DI_NORTH,
	DI_NORTHWEST,
	DI_WEST,
	DI_SOUTHWEST,
	DI_SOUTH,
	DI_SOUTHEAST,
	DI_NODIR,
	NUMDIRS
}

class Bot native
{
	native PlayerInfo player;

	native static BotInfoData GetBotInfo(Actor weap);
	native BotSkillData GetBotSkill();

	virtual native void BotThink();
}

// [Kizoky] Ported ZCajun AI
class ZSCajunBot : Bot
{
	// ---------- [Kizoky] These were the original pointers in C++
	Actor dest;
	Actor prev;
	Actor enemy;
	Actor missile;
	Actor mate;
	Actor last_mate;
	// ----------

	const BIF_BOT_REACTION_SKILL_THING = 1;
	const BIF_BOT_EXPLOSIVE = 2;
	const BIF_BOT_BFG = 4;

	Actor botself;
	PlayerInfo botplayer;

	bool allround;

	bool IsLeader(Actor Whom)
	{
		// [Kizoky] Search through Bot thinkers...
		ThinkerIterator it = ThinkerIterator.Create("Bot");
		Bot zbot;
		while ( zbot = Bot(it.Next()) )
		{
			let zsbot = ZSCajunBot(zbot);
			if (!zsbot)
				continue;

			if (!zsbot.mate)
				continue;

			if (zsbot.mate == Whom)
				return true;
		}

		return false;
	}

	// TODO: Is this even exported to ZScript?
	bool IsTeammate(Actor Whom)
	{
		if (!Whom)
		{
			return false;
		}
		else if (!deathmatch && player && Whom.player)
		{
			// [Kizoky] many thanks for Boondorl
			return !(player.mo.bFRIENDLY ^ Whom.bFRIENDLY);
		}
		/*
		else if (teamplay)
		{
			int myTeam = GetTeam();
			int otherTeam = other->GetTeam();

			return (myTeam != TEAM_NONE && myTeam == otherTeam);
		}
		*/
		return false;
	}

	Actor Choose_Mate()
	{
		double closest_dist, test;
		Actor target = null;

		// [Kizoky] don't iterate through Players if in Deathmatch
		if (deathmatch)
			return target;

		// is mate alive?
		if (mate)
		{
			if (mate.health <= 0)
				mate = null;
			else
				last_mate = mate;
		}
		if (mate) // Still is..
			return mate;

		// Check old_mates status.
		if (last_mate)
			if (last_mate.health <= 0)
				last_mate = null;

		target = null;
		closest_dist = 9999;

		// Check for player friends
		for (uint count = 0; count < MAXPLAYERS; count++)
		{
			let plr = Players[count].mo;
			if (!plr)
				continue;

			// [Kizoky] bots shouldn't target themselves
			if (plr == botself)
				continue;

			// [Kizoky] bots shouldn't follow other bots
			if (plr.player.Bot)
				continue;

			if (IsTeammate(plr) && 
				plr.health > 0 && 
				(botself.health / 2) <= plr.health && 
				!IsLeader(plr)) //taken?
			{
				if (botself.CheckSight(plr, SF_IGNOREVISIBILITY))
				{
					test = plr.Distance2D(botself);

					if (test < closest_dist)
					{
						closest_dist = test;
						target = plr;
					}
				}
			}
		}

		return target;
	}

	void Set_Enemy()
	{
		Actor oldenemy;

		if (enemy
			&& enemy.health > 0
			&& botself.CheckSight (enemy))
		{
			oldenemy = enemy;
		}
		else
		{
			oldenemy = NULL;
		}

		// [RH] Don't even bother looking for a different enemy if this is not deathmatch
		// and we already have an existing enemy.
		if (deathmatch || !enemy)
		{
			allround = !!enemy;
			enemy = Find_Enemy();
			if (!enemy)
				enemy = oldenemy; //Try go for last (it will be NULL if there wasn't anyone)
		}
		//Verify that that enemy is really something alive that bot can kill.
		if (enemy && ((enemy.health < 0 || !(enemy.bSHOOTABLE)) || botself.IsFriend(enemy)))
			enemy = nullptr;
	}

	//MAKEME: Make this a smart decision
	Actor Find_Enemy()
	{
		int count;
		double closest_dist, temp; //To target.
		Actor target;
		double vangle;
	
		if (!deathmatch)
		{ // [RH] Take advantage of the Heretic/Hexen code to be a little smarter
			return botself.RoughMonsterSearch (20);
		}
		
		return target;

		//Note: It's hard to ambush a bot who is not alone
		//if (allround || mate)
		//	vangle = DAngle::fromDeg(360.);
		//else
		//	vangle = DAngle::fromDeg(ENEMY_SCAN_FOV);
		//allround = false;
		//
		//target = NULL;
		//closest_dist = FLT_MAX;
		//
		//for (count = 0; count < MAXPLAYERS; count++)
		//{
		//	player_t *client = &players[count];
		//	if (playeringame[count]
		//		&& !player->mo->IsTeammate (client->mo)
		//		&& client->mo->health > 0
		//		&& player->mo != client->mo)
		//	{
		//		if (Check_LOS (client->mo, vangle)) //Here's a strange one, when bot is standing still, the P_CheckSight within Check_LOS almost always returns false. tought it should be the same checksight as below but.. (below works) something must be fuckin wierd screded up. 
		//		//if(P_CheckSight(player->mo, players[count].mo))
		//		{
		//			temp = client->mo->Distance2D(player->mo);
		//
		//			//Too dark?
		//			if (temp > DARK_DIST &&
		//				client->mo->Sector->lightlevel < WHATS_DARK /*&&
		//				player->Powers & PW_INFRARED*/)
		//				continue;
		//
		//			if (temp < closest_dist)
		//			{
		//				closest_dist = temp;
		//				target = client->mo;
		//			}
		//		}
		//	}
		//}
	}

	//doesnt check LOS, checks visibility with a set view angle.
	//B_Checksight checks LOS (straight line)
	//----------------------------------------------------------------------
	//Check if mo1 has free line to mo2
	//and if mo2 is within mo1 viewangle (vangle) given with normal degrees.
	//if these conditions are true, the function returns true.
	//GOOD TO KNOW is that the player's view angle
	//in doom is 90 degrees infront.
	bool Check_LOS (Actor to, double vangle)
	{
		if (!botself.CheckSight (to, SF_SEEPASTBLOCKEVERYTHING))
			return false; // out of sight
		if (vangle >= BAM(360.))
			return true;
		if (vangle == 0)
			return false; //Looker seems to be blind.
	
		// player.mo.Angles.Yaw
		return player.mo.AbsAngle(player.mo.AngleTo(to), player.mo.angle) <= (vangle/2);
	}

	// [Kizoky] Ported FCajunMaster::SetBodyAt
	Actor body1;
	Actor body2;
	void SetBodyAt(Vector3 pos, int hostnum)
	{
		if (hostnum == 1)
		{
			if (body1)
			{
				body1.SetOrigin(pos, false);
			}
			else
			{
				body1 = player.mo.Spawn("CajunBodyNode", pos, NO_REPLACE);
			}
		}
		else if (hostnum == 2)
		{
			if (body2)
			{
				body2.SetOrigin (pos, false);
			}
			else
			{
				body2 = player.mo.Spawn("CajunBodyNode", pos, NO_REPLACE);
			}
		}
	}

	//-------------------------------------
	//Bot_Dofire()
	//-------------------------------------
	//The bot will check if it's time to fire
	//and do so if that is the case.
	int t_react;
	bool first_shot;
	Const WHATS_DARK = 50; //light value thats classed as dark.
	bool increase;
	void Dofire ()
	{
		bool no_fire; //used to prevent bot from pumping rockets into nearby walls.
		int aiming_penalty=0; //For shooting at shading target, if screen is red, MAKEME: When screen red.
		int aiming_value; //The final aiming value.
		double Dist;
		double an;
		double m;
		double fm;
	
		if (!enemy || !(enemy.bSHOOTABLE) || enemy.health <= 0)
			return;
	
		if (botplayer.ReadyWeapon == NULL)
			return;
	
		if (botplayer.damagecount > GetBotSkill().isp)
		{
			first_shot = true;
			return;
		}
	
		//Reaction skill thing.
		if (first_shot &&
			!(GetBotInfo(botplayer.ReadyWeapon).flags & BIF_BOT_REACTION_SKILL_THING))
		{
			t_react = (100-GetBotSkill().reaction+1)/((random[pr_botdofire]()%3)+3);
		}
		first_shot = false;
		if (t_react)
			return;
	
		//MAKEME: Decrease the rocket suicides even more.
	
		no_fire = true;
		//Distance to enemy.
		Dist = botself.Distance2D(enemy/*, botself.Vel.X - enemy.Vel.X, botself.Vel.Y - enemy.Vel.Y*/);
	
		//FIRE EACH TYPE OF WEAPON DIFFERENT: Here should all the different weapons go.
		if (GetBotInfo(botplayer.ReadyWeapon).MoveCombatDist == 0)
		{
			//*4 is for atmosphere,  the chainsaws sounding and all..
			no_fire = (Dist > DEFMELEERANGE*4);
		}
		else if (GetBotInfo(botplayer.ReadyWeapon).flags & BIF_BOT_BFG)
		{
			//MAKEME: This should be smarter.
			if ((random[pr_botdofire]()%200)<=GetBotSkill().reaction)
				if(Check_LOS(enemy, BAM(SHOOTFOV)))
					no_fire = false;
		}
		else if (GetBotInfo(botplayer.ReadyWeapon).projectileType != NULL)
		{
			if (GetBotInfo(botplayer.ReadyWeapon).flags & BIF_BOT_EXPLOSIVE)
			{
				//Special rules for RL
				/*
				an = FireRox (enemy, cmd);
				if(an != 0)
				{
					botself.Angle = an;
					//have to be somewhat precise. to avoid suicide.
					if (absangle(an, player.mo.angle) < BAM(12.))
					{
						t_rocket = 9;
						no_fire = false;
					}
				}
				*/
			}
			// prediction aiming
			Dist = botself.Distance2D(enemy);
			let proj = GetBotInfo(botplayer.ReadyWeapon).projectileType;
			int projspeed = GetDefaultByType(proj.GetClass()).Speed;
			fm = Dist / projspeed;

			SetBodyAt(enemy.pos + enemy.Vel.XY * fm * 2, 1);
			player.mo.Angle = botself.AngleTo(body1);

			if (Check_LOS (enemy, BAM(SHOOTFOV)))
				no_fire = false;
		}
		else
		{
			//Other weapons, mostly instant hit stuff.
			player.mo.Angle = botself.AngleTo(enemy);
			aiming_penalty = 0;
			if (enemy.bSHADOW)
				aiming_penalty += (random[pr_botdofire]()%25)+10;
			if (enemy.cursector.GetLightLevel()<WHATS_DARK/* && !(player->powers & PW_INFRARED)*/)
				aiming_penalty += random[pr_botdofire]()%40;//Dark
			if (botplayer.damagecount)
				aiming_penalty += botplayer.damagecount; //Blood in face makes it hard to aim
			aiming_value = GetBotSkill().aiming - aiming_penalty;
			if (aiming_value <= 0)
				aiming_value = 1;
			m = BAM(((SHOOTFOV/2)-(aiming_value*SHOOTFOV/200))); //Higher skill is more accurate
			if (m <= 0)
				m = BAM(1.); //Prevents lock.
	
			if (m != 0) // [Kizoky] nullAngle
			{
				if (increase)
					botself.Angle += m;
				else
					botself.Angle -= m;
			}
	
			if (player.mo.AbsAngle(player.mo.Angle, player.cmd.yaw) < BAM(4.))
			{
				increase = !increase;
			}
	
			if (Check_LOS (enemy, BAM(SHOOTFOV/2)))
				no_fire = false;
		}
		if (!no_fire) //If going to fire weapon
		{
			player.cmd.buttons |= BT_ATTACK;
		}
		//Prevents bot from jerking, when firing automatic things with low skill.
	}

	// [Kizoky] defines for the movement code
	const SHOOTFOV = 60.;
	const AVOID_DIST = 45000000/65536.;
	const SIDERUN = 0x2800;
	const FORWARDRUN = 0x3200;
	const THINKDISTSQ = (50000.*50000./(65536.*65536.));


	void Pitch (Actor target)
	{
		double aim;
		double diff;

		diff = target.pos.Z - player.mo.pos.Z;
		aim = atan(diff / player.mo.Distance2D(target));
		//player.cmd.pitch = aim; /*DAngle::fromRad(aim);*/
		// [Kizoky] this seems to work just fine, although I'm not 100% sure yet
		player.mo.pitch = -aim;
		//player.mo.angle = player.mo.AngleTo(target);
	}

	bool Move ()
	{
		double tryx, tryy;
		bool try_ok;
		int good;
	
		if (player.mo.movedir >= DI_NODIR)
		{
			player.mo.movedir = DI_NODIR;	// make sure it's valid.
			return false;
		}
		
		/*
		tryx = player.mo.X() + 8*xspeed[player.mo.movedir];
		tryy = player.mo.Y() + 8*yspeed[player.mo.movedir];
	
		try_ok = Level->BotInfo.CleanAhead (player->mo, tryx, tryy, cmd);
	
		if (!try_ok) //Anything blocking that could be opened etc..
		{
			if (!spechit.Size ())
				return false;
	
			player->mo->movedir = DI_NODIR;
	
			good = 0;
			spechit_t spechit1;
			line_t *ld;
	
			while (spechit.Pop (spechit1))
			{
				ld = spechit1.line;
				bool tryit = true;
	
				if (ld->special == Door_LockedRaise && !P_CheckKeys (player->mo, ld->args[3], false))
					tryit = false;
				else if (ld->special == Generic_Door && !P_CheckKeys (player->mo, ld->args[4], false))
					tryit = false;
	
				if (tryit &&
					(P_TestActivateLine (ld, player->mo, 0, SPAC_Use) ||
					 P_TestActivateLine (ld, player->mo, 0, SPAC_Push)))
				{
					good |= ld == player->mo->BlockingLine ? 1 : 2;
				}
			}
			if (good && ((pr_botopendoor() >= 203) ^ (good & 1)))
			{
				cmd->ucmd.buttons |= BT_USE;
				cmd->ucmd.forwardmove = FORWARDRUN;
				return true;
			}
			else
				return false;
		}
		else //Move forward.
			cmd->ucmd.forwardmove = FORWARDRUN;
		*/

		return true;
	}

	void Roam()
	{
		//if (Reachable(dest))
		{ // Straight towards it.
			player.mo.Angle = player.mo.AngleTo(dest);
		}
		/*else*/ if (player.mo.movedir < 8) // turn towards movement direction if not there yet
		{
			// no point doing this with floating point angles...
			int delta = player.mo.angle - (player.mo.movedir << 29);

			if (delta > 0)
				player.mo.Angle -= 45;
			else if (delta < 0)
				player.mo.Angle += 45;
		}

		// chase towards destination.
		if (--player.mo.movecount < 0 || !Move ())
		{
			//NewChaseDir (cmd);
		}
	}

	bool sleft;
	Vector3 old;
	int t_strafe;
	void ThinkForMove()
	{
		double dist;
		bool stuck;
		int r;
	
		stuck = false;
		dist = dest ? botself.Distance2D(dest) : 0;
	
		if (missile &&
			(!missile.Vel.X || !missile.Vel.Y || !Check_LOS(missile, BAM(SHOOTFOV*3/2))))
		{
			sleft = !sleft;
			missile = null; //Probably ended its travel.
		}
		
		/*
		// this has always been broken and without any reference it cannot be fixed.
		if (botself.Angles.Pitch > 0)
			botself.Angles.Pitch -= 80;
		else if (botself.Angles.Pitch <= -60)
			botself.Angles.Pitch += 80;
		*/

		//HOW TO MOVE:
		if (missile && (botself.Distance2D(missile) < AVOID_DIST)) //try avoid missile got from P_Mobj.c thinking part.
		{
			Pitch (missile);
			botself.Angle = botself.AngleTo(missile);
			player.cmd.sidemove = sleft ? -SIDERUN : SIDERUN;
			player.cmd.forwardmove = -FORWARDRUN; //Back IS best.

			if ((botself.pos - old).LengthSquared() < THINKDISTSQ
				&& t_strafe<=0)
			{
				t_strafe = 5;
				sleft = !sleft;
			}

			//If able to see enemy while avoiding missile, still fire at enemy.
			if (enemy && Check_LOS (enemy, BAM(SHOOTFOV)))
				Dofire(); //Order bot to fire current weapon
		}
		else if (enemy && player.mo.CheckSight (enemy, 0)) //Fight!
		{
			Pitch (enemy);

			if (dest && dest.bSPECIAL)
			{
				if (player.health < GetBotSkill().isp)
				{
					
					return;
				}
			}
		}

	}

	float NextAttack;
	bool toggleattack;
	override void BotThink()
	{
		if (player.mo == null || Level.IsFrozen())
		{
			return;
		}

		// TODO: don't use these
		botplayer = player; // [Kizoky] Some less confusing name for the Bot's Player info
		botself = player.mo; // [Kizoky] Access to the PlayerPawn

		if (enemy && enemy.health <= 0)
			enemy = null;

		if (botself.health > 0)
		{
			// if (teamplay)
			mate = Choose_Mate();

			double oldyaw = player.cmd.yaw;
			double oldpitch = player.cmd.pitch;

			Set_Enemy();
		}

		//Console.Printf("Overridden");
	}
}

// [Kizoky] non-ZCajun AI (test, shouldn't be in release)
class ZSBot : Bot
{
	Actor botself;
	PlayerInfo botplayer;

	//Actor target;

	int Test;
	bool sw;

	void Pitch (Actor target)
	{
		double aim;
		double diff;

		diff = target.pos.Z - player.mo.pos.Z;
		aim = atan(diff / player.mo.Distance2D(target));
		player.mo.pitch = -aim;
		player.mo.angle = player.mo.AngleTo(target);
	}

	int DeathRespawnTimer;
	bool Respawn;
	void HandleRespawn()
	{
		if (player.mo.health > 0)
			return;

		if (!Respawn)
		{
			Respawn = true;
			DeathRespawnTimer = level.time + 35 * random[zsbot_respawn](3,6);
		}
		else if (Respawn && level.time > DeathRespawnTimer)
		{
			Respawn = false;
			player.cmd.buttons |= BT_USE;
		}
	}

	override void BotThink()
	{
		if (player.mo == null || Level.IsFrozen())
		{
			return;
		}

		HandleRespawn();

		if (level.time > Test)
		{
			if (sw)
			{
				Test = level.time + 35 * 4;
				sw = false;
				Console.Printf("Rest %d", Test);
			}
			else
			{
				Test = level.time + 35 * 4;
				sw = true;
				Console.Printf("Attacking");
			}
		}

		if (sw)
		{
			player.cmd.buttons |= BT_ATTACK;

			if (!player.mo.target || (player.mo.target && player.mo.target.health <= 0))
			{
				player.mo.target = player.mo.RoughMonsterSearch (20);
			}

			if (player.mo.target)
			{
				Pitch (player.mo.target);
			}
		}
	}
}