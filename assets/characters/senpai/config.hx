function loadAnimations()
{
    if (song == 'roses')
    {
        addByPrefix('idle', 'Angry Idle', 24, false);
        addByPrefix('singUP', 'Angry Up', 24, false);
        addByPrefix('singLEFT', 'Angry Left', 24, false);
        addByPrefix('singRIGHT', 'Angry Right', 24, false);
        addByPrefix('singDOWN', 'Angry Down', 24, false);

        addOffset('idle', 110, 280);
        addOffset('singUP', 115, 282);
        addOffset('singRIGHT', 110, 280);
        addOffset('singLEFT', 150, 280);
        addOffset('singDOWN', 124, 280);
    }
    else
    {
        addByPrefix('idle', 'Idle', 24, false);
        addByPrefix('singUP', 'Up', 24, false);
        addByPrefix('singLEFT', 'Left', 24, false);
        addByPrefix('singRIGHT', 'Right', 24, false);
        addByPrefix('singDOWN', 'Down', 24, false);

		addOffset('idle', 110, 280);
		addOffset('singUP', 115, 282);
		addOffset('singRIGHT', 110, 280);
		addOffset('singLEFT', 150, 280);
		addOffset('singDOWN', 124, 280);
	}

	setGraphicSize(get('width') * 6);
	set('antialiasing', false);

	playAnim('idle');

<<<<<<< HEAD
	setOffsets(-30, 950);
	setCamOffsets(-230, -590);
	setBarColor([255, 170, 111]);
	quickDancer(true);
}
=======
    setOffsets(-30, 950);
    setCamOffsets(-230, -590);
    setBarColor([255,170,111]);
    quickDancer(false);
}
>>>>>>> 0e43137fe0587d6e2a5d0d996edb975058b35532
