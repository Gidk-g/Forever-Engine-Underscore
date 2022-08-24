function loadAnimations()
{
	addByPrefix('firstDeath', "BF Dies pixel", 24, false);
	addByPrefix('deathLoop', "Retry Loop", 24, true);
	addByPrefix('deathConfirm', "RETRY CONFIRM", 24, false);

	addOffset('firstDeath', 0, 0);
	addOffset('deathLoop', -30, -10);
	addOffset('deathConfirm', 3, 0);

	setGraphicSize(get('width') * 6);
	set('antialiasing', false);
	if (isPlayer)
		set('flipX', true);
	else
		set('flipX', false);
}
