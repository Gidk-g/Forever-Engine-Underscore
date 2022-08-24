package states;

import base.ForeverTools;
import base.MusicBeat.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import states.menus.MainMenuState;

class UpdateState extends MusicBeatState
{
	var bg:FlxSprite;
	var warnText:FlxText;

	override function create()
	{
		super.create();

		bg = new FlxSprite();
		bg.loadGraphic(Paths.image('menus/base/menuDesat'));
		bg.alpha = 0.4;
		bg.color = 0xFF357591;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width, "Hey, fair warning
			\nit looks like your Game Version is outdated!
			\nPress ENTER to Update\nfrom "
			+ Main.underscoreVersion
			+ ' (FE v'
			+ Main.foreverVersion
			+ ') to '
			+ ForeverTools.updateVersion
			+ '\nPress ESCAPE to ignore this message.
			\nif you wish to disable this, Uncheck "Check for Updates" on the Options Menu', 32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!FlxG.save.data.leftFlashing)
		{
			var accept:Bool = controls.ACCEPT;
			var back:Bool = controls.BACK;

			if (accept || back)
			{
				if (!back)
				{
					FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function(twn:FlxTween)
						{
							CoolUtil.browserLoad('https://github.com/BeastlyGhost/Forever-Engine-Underscore');
							Main.switchState(this, new MainMenuState());
						}
					});
				}
				else
				{
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function(twn:FlxTween)
						{
							Main.switchState(this, new MainMenuState());
						}
					});
				}
			}
		}
		else
		{
			// anti "haha u stuck here now lmao!!!"
			Main.switchState(this, new MainMenuState());
		}
	}
}
