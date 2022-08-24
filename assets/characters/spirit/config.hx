function loadAnimations()
{
	addByPrefix('idle', "idle spirit instance", 24, false);
	addByPrefix('singUP', "up spirit instance", 24, false);
	addByPrefix('singRIGHT', "right spirit instance", 24, false);
	addByPrefix('singLEFT', "left spirit instance", 24, false);
	addByPrefix('singDOWN', "down spirit instance", 24, false);

	addOffset('idle', -220, -280);
	addOffset('singUP', -220, -240);
	addOffset('singRIGHT', -220, -280);
	addOffset('singLEFT', -200, -280);
	addOffset('singDOWN', -200, -220);

	setGraphicSize(get('width') * 6);
	set('antialiasing', false);

	playAnim('idle');

	setOffsets(-200, 710);
	setCamOffsets(100, 50);
	setBarColor([255, 60, 110]);
}
