function beatHit(curBeat)
{
    if (curBeat % 8 == 7)
	{
		boyfriend.playAnim('hey', true);
        boyfriend.specialAnim = true;
        boyfriend.heyTimer = 0.6;
	}
}