I was the owner of Team Vipers for nearly 5 years. Vipers was a TF2 gaming community that shut down in January 2015. 

This repository contains some of the custom SourceMod plugins I built over the years.

It should be noted that these aren't guaranteed to work any longer. I haven't utilized them since the shut down. I've made notes below of known shortcomings. It's entirely possible that
updating the SourceMod gamedata will fix most issues (except for the Sidewinder one).


 - **abuse**: Trolls get annoyed when they can't cheat. Before banning them from the servers, the admins liked to ruin their fun a little bit by dropping at little admin abuse on them. This
 was accomplished by `sm_aboose @me`. This grants the admin running the command Power Play, homing rockets and a Valve rocket launcher. Combing this with some teleport commands was a great way 
 to troll the troll. **No longer functions due to broken Sidewinder extension**
 
 - **Facestab**: The complaint in TF2 is that you could get a facestab if you were a spy. The common response was "lag". Not on our crit server. Players complained that the spy was under powered when
 they didn't get a facestab in an all crit environment. This plugin guarantees that all spy stabs count as a backstab. 
 
 - **Reflectiles**: On our crit server, the poor pyro was not a common class to play. Instead, we had soldiers. Lots of them. To even this out a bit, we gave the pyro a buff. If the pyro
 reflected a projectile (rocket, arrow, flare, sentry rocket, etc), the projectile started tracking a player on the opposing team. A little bit of peer pressure quickly whittled down the number
 of soldiers lobbing rockets across an open battlefield. 

 - **RTD**: This fork of the [RTD](https://forums.alliedmods.net/showthread.php?p=666222) plugin built by LinuxLover, aka pheadxdll, was created when the author left Vipers and began to focus
 on their successful Randomizer community. The original plugin was updated some time after we forked it. This is running off of the 0.3 branch. I have not looked at code for the 0.4 branch
 and am not sure if the two could be merged. **Homing projectiles do not work.** It depended on a modified version of [Sidewinder](https://forums.alliedmods.net/showpost.php?p=843232&postcount=88?p=843232&postcount=88). This finally broke in an unrepairable way in mid-2014. 
  
