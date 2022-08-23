function loadAnimations()
{
    if (song == 'roses')
    {
        addByPrefix('idle', 'Angry Senpai Idle', 24, false);
        addByPrefix('singUP', 'Angry Senpai UP NOTE', 24, false);
        addByPrefix('singLEFT', 'Angry Senpai LEFT NOTE', 24, false);
        addByPrefix('singRIGHT', 'Angry Senpai RIGHT NOTE', 24, false);
        addByPrefix('singDOWN', 'Angry Senpai DOWN NOTE', 24, false);

        addOffset('idle', 110, 280);
        addOffset('singUP', 115, 282);
        addOffset('singRIGHT', 110, 280);
        addOffset('singLEFT', 150, 280);
        addOffset('singDOWN', 124, 280);
    }
    else
    {
        addByPrefix('idle', 'Senpai Idle', 24, false);
        addByPrefix('singUP', 'SENPAI UP NOTE', 24, false);
        addByPrefix('singLEFT', 'SENPAI LEFT NOTE', 24, false);
        addByPrefix('singRIGHT', 'SENPAI RIGHT NOTE', 24, false);
        addByPrefix('singDOWN', 'SENPAI DOWN NOTE', 24, false);

        addOffset('idle', 110, 280);
        addOffset('singUP', 115, 282);
        addOffset('singRIGHT', 110, 280);
        addOffset('singLEFT', 150, 280);
        addOffset('singDOWN', 124, 280);
    }

    setGraphicSize(get('width') * 6);
    set('antialiasing', false);

    playAnim('idle');

    setOffsets(-30, 950);
    setCamOffsets(-230, -590);
    setBarColor([255,170,111]);
    quickDancer(true);
}