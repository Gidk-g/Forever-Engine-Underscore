function loadAnimations()
{
    addByPrefix('firstDeath', "BF dies", 24, false);
    addByPrefix('deathLoop', "BF Dead Loop", 24, true);
    addByPrefix('deathConfirm', "BF Dead confirm", 24, false);

    if (isPlayer)
        set('flipX', true);
    else
        set('flipX', false);

    setOffsets(5, 510);
}
