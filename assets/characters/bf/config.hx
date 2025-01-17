function loadAnimations()
{
	addByPrefix('idle', 'BF idle dance', 24, false);
	addByPrefix('singUP', 'BF NOTE UP0', 24, false);
	addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
	addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
	addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
	addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
	addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
	addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
	addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
	addByPrefix('hey', 'BF HEY', 24, false);
	addByPrefix('scared', 'BF idle shaking', 24);

	addOffset('hey', -3);

	playAnim('idle');

	set('antialiasing', true);

	setBarColor([49, 176, 209]);
	setCamOffsets(0, -50);
	if (isPlayer)
	{
		setOffsets(0, 430);
		set('flipX', false);
	}
	else
	{
		setOffsets(-135, 770);
		set('flipX', true);
		flipLeftRight();
	}
}