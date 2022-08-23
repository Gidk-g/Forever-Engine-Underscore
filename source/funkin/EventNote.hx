package funkin;

import base.*;
import flixel.FlxSprite;
import states.PlayState;

class EventNote extends FlxSprite
{
	public var strumTime:Float;
	public var val1:String;
	public var val2:String;
	public var eventName:String;
	public var shouldExecute:Bool;

	public function new(strumTime:Float, val1:String, val2:String, eventName:String)
	{
		super();

		this.strumTime = strumTime;
		this.val1 = val1;
		this.val2 = val2;
		this.eventName = eventName;

		// loadGraphic(Paths.image('UI/default/base/charter/eventNote'));
		loadGraphic(Paths.image(ForeverTools.returnSkinAsset('eventNote', PlayState.assetModifier, PlayState.changeableSkin, 'UI')));
	}

	override function update(e:Float)
	{
		super.update(e);

		if (strumTime < 0)
			return;

		if (strumTime <= Conductor.songPosition)
			shouldExecute = true;
	}
}
