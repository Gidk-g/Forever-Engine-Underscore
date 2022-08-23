package states;

import base.*;
import base.MusicBeat.MusicBeatState;
import dependency.Discord;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.Alphabet;
import lime.app.Application;
import openfl.Assets;
import states.menus.*;

using StringTools;

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;

	var credGroup:FlxGroup;
	var textGroup:FlxGroup;
	var credTextShit:Alphabet;

	var curWacky:Array<String> = [];

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var wackyImage:FlxSprite;

	override public function create():Void
	{
		controls.setKeyboardScheme(None, false);
		curWacky = FlxG.random.getObject(getIntroTextShit());
		super.create();

		startIntro();
	}

	var titleText:FlxSprite;
	var gameLogo:FlxSprite;
	var gfDance:FlxSprite;
	var backdrop:FlxSprite;
	var blackScreen:FlxSprite;
	var ngSpr:FlxSprite;

	var danceLeft:Bool = false;
	var initLogowidth:Float = 0;
	var newLogoScale:Float = 0;

	function startIntro()
	{
		if (!initialized)
		{
			#if DISCORD_RPC
			Discord.changePresence('TITLE SCREEN', 'Main Menu');
			#end

			/*
				var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
				diamond.persist = true;
				diamond.destroyOnNoUse = false;

				FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.32, new FlxPoint(0, -1),
					{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
				FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.32, new FlxPoint(0, 1),
					{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
			 */

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;

			ForeverTools.resetMenuMusic(true);
		}

		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		// bg.antialiasing = true;
		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();
		add(bg);

		// cool bg
		backdrop = new FlxBackdrop(Paths.image('menus/base/title/grid'), 1, 1, true, true, 1, 1);
		backdrop.velocity.set(300, 0);
		backdrop.screenCenter(X);
		backdrop.alpha = (32 / 255);
		add(backdrop);

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('menus/base/title/gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = true;
		add(gfDance);

		gameLogo = new FlxSprite(0, 50);
		gameLogo.loadGraphic(Paths.image('menus/base/title/logo'));
		gameLogo.antialiasing = true;
		initLogowidth = gameLogo.width;
		newLogoScale = gameLogo.scale.x;
		add(gameLogo);

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('menus/base/title/titleEnter');
		var animFrames:Array<FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}

		if (animFrames.length > 0)
		{
			newTitle = true;

			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', !Init.trueSettings.get('Disable Flashing Lights') ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else
		{
			newTitle = false;

			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.antialiasing = true;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		credGroup = new FlxGroup();
		textGroup = new FlxGroup();

		add(credGroup);

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('menus/base/title/newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = true;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;

		ForeverTools.checkUpdates();

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var swagGoodArray:Array<Array<String>> = [['no idea what psych engine is', 'vine boom sfx']];
		if (Assets.exists(Paths.txt('introText')))
		{
			var fullText:String = Assets.getText(Paths.txt('introText'));
			var firstArray:Array<String> = fullText.split('\n');

			for (i in firstArray)
				swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		gameLogo.scale.x = FlxMath.lerp(newLogoScale, gameLogo.scale.x, 0.95);
		gameLogo.scale.y = FlxMath.lerp(newLogoScale, gameLogo.scale.y, 0.95);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (newTitle)
		{
			titleTimer += CoolUtil.boundTo(elapsed, 0, 1);
			if (titleTimer > 2)
				titleTimer -= 2;
		}

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;
		}

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;

				timer = FlxEase.quadInOut(timer);

				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}

			if (FlxG.keys.justPressed.ESCAPE && !pressedEnter)
			{
				FlxG.sound.music.fadeOut(0.5);
				FlxG.camera.fade(FlxColor.BLACK, 0.5, false, false);
				var close:FlxTimer = new FlxTimer().start(0.9, function(tmr:FlxTimer)
				{
					Sys.exit(0);
				});
			}

			if (pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				titleText.animation.play('press');

				if (!Init.trueSettings.get('Disable Flashing Lights'))
					FlxG.camera.flash(FlxColor.WHITE, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;

				gameLogo.setGraphicSize(Std.int(initLogowidth * 1.15));

				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					if (ForeverTools.mustUpdate)
					{
						Main.switchState(this, new UpdateState());
					}
					else
					{
						Main.switchState(this, new MainMenuState());
					}
				});
			}
		}

		// hi game, please stop crashing its kinda annoyin, thanks!
		if (pressedEnter && !skippedIntro && initialized)
			skipIntro();

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200;
			credGroup.add(money);
			textGroup.add(money);
		}
	}

	function addMoreText(text:String)
	{
		var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	var reverser = 1;

	override function beatHit()
	{
		super.beatHit();

		if (gameLogo != null && !transitioning)
		{
			gameLogo.scale.set(1.05, 1.05);
			FlxTween.tween(gameLogo, {'scale.x': 0.90, 'scale.y': 0.90}, 0.5, {ease: FlxEase.bounceIn});
		}

		if (gfDance != null)
		{
			danceLeft = !danceLeft;
			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		switch (curBeat)
		{
			case 16:
				skipIntro();
		}
		//trace('Beat: ' + curBeat);
	}

	override function stepHit()
	{
		super.stepHit();
		//trace('Step: ' + curStep);

		switch (curStep)
		{
			case 4:
				createCoolText(['Yoshubs', 'Neolixn', 'Gedehari', 'Tsuraran', 'FlopDoodle', '']);
			case 12:
				addMoreText('PRESENT');
			case 16:
				deleteCoolText();
			case 20:
				createCoolText(['Not associated', 'with']);
			case 28:
				addMoreText('newgrounds');
				ngSpr.visible = true;
			case 32:
				deleteCoolText();
				ngSpr.visible = false;
			case 36:
				createCoolText([curWacky[0]]);
			case 44:
				addMoreText(curWacky[1]);
				if (curWacky[1] == 'vine boom sfx')
					FlxG.sound.play(Paths.sound('psych'));
			case 48:
				deleteCoolText();
			case 52:
				addMoreText("Friday Night Funkin'");
			case 56:
				addMoreText('Forever Engine');
			case 60:
				addMoreText('Underscore');
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(ngSpr);

			FlxG.camera.flash(FlxColor.WHITE, 2.5);
			remove(credGroup);
			skippedIntro = true;
		}
	}
}
