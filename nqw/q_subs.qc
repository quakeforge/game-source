/*

in nightmare mode, all attack_finished times become 0
some monsters refire twice automatically

*/

void(float normal) SUB_AttackFinished =
{
	self.cnt = 0;		// refire count for nightmare
	if (skill != 3)
		self.attack_finished = time + normal;
};

float (entity targ) visible;

void (void() thinkst) SUB_CheckRefire =
{
	if (skill != 3)
		return;
	if (self.cnt == 1)
		return;
	if (!visible (self.enemy))
		return;
	self.cnt = 1;
	self.think = thinkst;
};
