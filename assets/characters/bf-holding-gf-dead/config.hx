function loadAnimations()
{
    addByPrefix('firstDeath', "BF Dies with GF", 24, false);
    addByPrefix('deathLoop', "BF Dead with GF Loop", 24, true);
    addByPrefix('deathConfirm', "RETRY confirm holding gf", 24, false);

    addOffset('firstDeath', 37, 14);
    addOffset('deathLoop', 37, -3);
    addOffset('deathConfirm', 37, 28);
    if (isPlayer)
        set('flipX', true);
    else
        set('flipX', false);
}