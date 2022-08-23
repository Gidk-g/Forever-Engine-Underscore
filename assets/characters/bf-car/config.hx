function loadAnimations()
{
    addByPrefix('idle', 'BF idle dance', 24, false);
    addByPrefix('singUP', 'BF NOTE UP0', 24, false);
    addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
    addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
    addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
    addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
    addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
    addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
    addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);

    addOffset('idle', -5, 30);
    addOffset('idleHair', -5, 30);
    addOffset('singUP', -29, 57);
    addOffset('singDOWN', -10, -20);
    addOffset('singLEFT', 12, 24);
    addOffset('singRIGHT', -38, 23);

    addOffset('singUPmiss', -29, 57);
    addOffset('singDOWNmiss', -11, 11);
    addOffset('singLEFTmiss', 12, 54);
    addOffset('singRIGHTmiss', -30, 51);

    playAnim('idle');

    setBarColor([49,176,209]);
    setOffsets(80, 410);
    if (isPlayer)
        set('flipX', false);
    else
        set('flipX', true);
}