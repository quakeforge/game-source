/*
POX - This file contains a function taken from norse_movetogaol
The ONLY thing I used is norse_waterlevel. All bot movement is
controlled by movetogoal and coffe_move

The Paroxysm progs.dat is bloated due to the new weapons, I couldn't add the
entire norse_movetogoal even if I wanted to (which I don't ;) - I have
enough trouble debugging 50 lines of movement code never mind 2500!)

The Following is the original header from botmove.qc, obviously, not
all of it is relevent anymore.
*/


/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=*\
||	    norse_movetogoal and related move functions		 ||
||		     by Roscoe A. Sincero			 ||
||		e-mail: legion@keg.zymurgy.org			 ||
||								 ||
||		     Copyright(c) 1997				 ||
||								 ||
||		     Date: June 27, 1997 (v0.30)		 ||
||		     Date: July 03, 1997 (v0.31)		 ||
||		     Date: July 13, 1997 (v0.31.1)		 ||
||		     Date: July 21, 1997 (v0.32.0)		 ||
||								 ||
||								 ||
||     Permissions:  You are allowed to use these functions	 ||
||		     provided that the original author,		 ||
||		     Roscoe A. Sincero gets credit for coding	 ||
||		     the functions and that your work is	 ||
||		     is publically available to anyone and it	 ||
||		     is *FREE*.					 ||
\*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=*/

/*

   If you wish to add this code or portions of it in a commercial
   product, you will need to contact me _AND_ the individuals mentioned
   in my credits below.

   Norse_movetogoal package v0.32 by Roscoe A. Sincero

   Additional credits: Cameron Newham for Eliminatorbot v1.4.  If it wasn't
   for his bot, I would never had tried to create my own movetogoal
   function.  I had major problems in combining his bot with roambot
   and at the time I couldn't figure out why the bot would simply stop
   for no reason.  So I played around with the FL_ONGROUND flag.  From
   this, I formed the basis for the movetogoal function.  For the curious,
   it turns out that my problems were with those nested if-else block
   statements and had nothing to do with FL_ONGROUND.  The jumping code
   and swimming code used in the eliminatorbot formed the basis for the
   now complicated swim code and jump code.

   Jonathan E. Wright for Cujo v1.4.  I used the FINDLEDGE function and
   used ideas taken from various other functions related to finding gaps
   in the floor.
*/

float (entity me) norse_waterlevel =
{

   local float pc;
   if (me == world)
      return 0;

/*
   I originally took the waterlevel code from Jonathan E. Wright's
   CUJO_Waterlevel function of Cujo v1.4.  It has proven to be unreliable
   and more importantly, it is no longer compatible with the move code.
   So I made my own.

   The variable .watertype2 is used instead of .watertype.  The variable
   .watertype can be modified by the Quake engine itself.  Moreover, it
   is also used to produce the unwanted splashing sounds.  To remove the
   splashing sounds, .watertype is permanently set to zero.  .watertype2
   is used instead.

*/

   me.watertype = 0;   

   // check at eye level
   pc = pointcontents (me.origin + me.view_ofs);

   if (pc == CONTENT_WATER || pc == CONTENT_SLIME || pc == CONTENT_LAVA)
   {
      me.watertype2 = pc;
      me.waterlevel = 3;
      return 3;	  // liquid is at eye/head level, above mouth/nose
   }

   // check at waist level
   pc = pointcontents (me.origin + '0 0 6');

   if (pc == CONTENT_WATER || pc == CONTENT_SLIME || pc == CONTENT_LAVA)
   {
      me.watertype2 = pc;
      me.waterlevel = 2;
      return 2;	  
   }

   // check at feet level
   pc = pointcontents (me.origin - '0 0 20');

   if (pc == CONTENT_WATER || pc == CONTENT_SLIME || pc == CONTENT_LAVA)
   {
      me.watertype2 = pc;
      me.waterlevel = 1;
      return 1;	  // liquid covers legs
   }

   pc = pointcontents (me.origin - '0 0 24');
   if (pc == CONTENT_LAVA || pc == CONTENT_SLIME || pc == CONTENT_WATER)
   {
      me.watertype2 = pc;
      me.waterlevel = 1;
      return 1;
   }


   me.watertype2 = 0;
   me.waterlevel = 0;
   return 0;   // water, if any, is not significant


};
