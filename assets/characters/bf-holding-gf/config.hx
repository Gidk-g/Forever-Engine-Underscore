function loadAnimations()
{
	addByPrefix('idle', 'BF idle dance w gf', 24, false);
	addByPrefix('singUP', 'BF NOTE UP0', 24, false);
	addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
	addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
	addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
	addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
	addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
	addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
	addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);

	addOffset('idle', 0, 0);
	addOffset('bfCatch', 0, 0);
	addOffset('singUP', -29, 10);
	addOffset('singDOWN', -10, -10);
	addOffset('singLEFT', 12, 7);
	addOffset('singRIGHT', -41, 23);

	addOffset('singUPmiss', -29, 10);
	addOffset('singDOWNmiss', -10, -10);
	addOffset('singLEFTmiss', 12, 7);
	addOffset('singRIGHTmiss', -41, 23);

	playAnim('idle');

	setBarColor([49, 176, 209]);
	setOffsets(0, 340);
	setIcon('bf-holding-gf');
	if (isPlayer)
	{
		setDeathChar('bf-holding-gf-dead');
		set('flipX', false);
	}
	else
	{
		set('flipX', true);
	}
}
