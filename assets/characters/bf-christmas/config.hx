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

    addOffset('idle', -5, 0);
    addOffset('hey', 7, 4);
    addOffset('singUP', -29, 27);
    addOffset('singDOWN', -10, -50);
    addOffset('singLEFT', 12, -6);
    addOffset('singRIGHT', -38, -7);

    addOffset('singUPmiss', -29, 27);
    addOffset('singDOWNmiss', -11, -19);
    addOffset('singLEFTmiss', 12, 24);
    addOffset('singRIGHTmiss', -30, 21);

    playAnim('idle');

    setBarColor([49,176,209]);
    setOffsets(0, 430);
    if (isPlayer)
        set('flipX', false);
    else
        set('flipX', true);
}