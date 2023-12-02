/*
**
**
**---------------------------------------------------------------------------
** Copyright 1999 Martin Colberg
** Copyright 1999-2016 Randy Heit
** Copyright 2005-2016 Christoph Oelckers
** All rights reserved.
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions
** are met:
**
** 1. Redistributions of source code must retain the above copyright
**    notice, this list of conditions and the following disclaimer.
** 2. Redistributions in binary form must reproduce the above copyright
**    notice, this list of conditions and the following disclaimer in the
**    documentation and/or other materials provided with the distribution.
** 3. The name of the author may not be used to endorse or promote products
**    derived from this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
** IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
** OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
** IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
** INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
** NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
** THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**---------------------------------------------------------------------------
**
*/
/********************************
* B_Think.c                     *
* Description:                  *
* Functions for the different   *
* states that the bot           *
* uses. These functions are     *
* the main AI                   *
*                               *
*********************************/

#include "doomdef.h"
#include "doomstat.h"
#include "p_local.h"
#include "b_bot.h"
#include "g_game.h"
#include "d_net.h"
#include "d_event.h"
#include "d_player.h"
#include "actorinlines.h"

//static FRandom pr_botmove ("BotMove");

//This function is called each tic for each bot,
//so this is what the bot does.
void DBot::Think ()
{
	/*
	ticcmd_t *cmd = &netcmds[player - players][((gametic + 1)/ticdup)%BACKUPTICS];

	memset (cmd, 0, sizeof(*cmd));

	if (enemy && enemy->health <= 0)
		enemy = nullptr;

	if (player->mo->health > 0) //Still alive
	{
		if (teamplay || !deathmatch)
			mate = Choose_Mate ();

		AActor *actor = player->mo;
		DAngle oldyaw = actor->Angles.Yaw;
		DAngle oldpitch = actor->Angles.Pitch;

		Set_enemy ();
		ThinkForMove (cmd);
		TurnToAng ();

		cmd->ucmd.yaw = (short)((actor->Angles.Yaw - oldyaw).Degrees() * (65536 / 360.f)) / ticdup;
		cmd->ucmd.pitch = (short)((oldpitch - actor->Angles.Pitch).Degrees() * (65536 / 360.f));
		if (cmd->ucmd.pitch == -32768)
			cmd->ucmd.pitch = -32767;
		cmd->ucmd.pitch /= ticdup;
		actor->Angles.Yaw = oldyaw + DAngle::fromDeg(cmd->ucmd.yaw * ticdup * (360 / 65536.f));
		actor->Angles.Pitch = oldpitch - DAngle::fromDeg(cmd->ucmd.pitch * ticdup * (360 / 65536.f));
	}

	if (t_active)	t_active--;
	if (t_strafe)	t_strafe--;
	if (t_react)	t_react--;
	if (t_fight)	t_fight--;
	if (t_rocket)	t_rocket--;
	if (t_roam)		t_roam--;

	//Respawn ticker
	if (t_respawn)
	{
		t_respawn--;
	}
	else if (player->mo->health <= 0)
	{ // Time to respawn
		cmd->ucmd.buttons |= BT_USE;
	}
	*/
}