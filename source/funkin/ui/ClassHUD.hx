package funkin.ui;

import base.Conductor;
import base.CoolUtil;
import base.ForeverTools;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import funkin.Timings;
import lime.app.Application;
import states.PlayState;

using StringTools;

class ClassHUD extends FlxTypedGroup<FlxBasic>
{
	// set up variables and stuff here
	var scoreBar:FlxText;
	var scoreLast:Float = -1;
	var scoreColorTween:FlxTween;

	public var traceBar:FlxText;

	// fnf mods
	var scoreDisplay:String = 'beep bop bo skdkdkdbebedeoop brrapadop';

	var cornerMark:FlxText; // engine mark at the upper right corner
	var centerMark:FlxText; // song display name and difficulty at the center

	var healthBarBG:FlxSprite;
	var healthBar:FlxBar;

	var SONG = PlayState.SONG;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	var stupidHealth:Float = 0;

	public var infoDisplay:String = CoolUtil.dashToSpace(PlayState.SONG.song);
	public var diffDisplay:String = CoolUtil.difficultyFromNumber(PlayState.storyDifficulty);
	public var engineDisplay:String = "FE UNDERSCORE v" + Main.underscoreVersion + (Main.showCommitHash ? ' (${Main.commitHash})' : '');

	public var autoplayMark:FlxText;
	public var autoplaySine:Float = 0;

	var timingsMap:Map<String, FlxText> = [];

	var barFillDir = RIGHT_TO_LEFT;

	var bfBar = FlxColor.fromRGB(PlayState.boyfriend.barColor[0], PlayState.boyfriend.barColor[1], PlayState.boyfriend.barColor[2]);
	var dadBar = FlxColor.fromRGB(PlayState.dadOpponent.barColor[0], PlayState.dadOpponent.barColor[1], PlayState.dadOpponent.barColor[2]);

	// eep
	public function new()
	{
		// call the initializations and stuffs
		super();

		// le healthbar setup
		var barY = FlxG.height * 0.875;
		if (Init.trueSettings.get('Downscroll'))
			barY = 64;

		healthBarBG = new FlxSprite(0, barY);
		healthBarBG.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('healthBar', PlayState.assetModifier, PlayState.changeableSkin, 'UI')));

		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, barFillDir, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8));
		healthBar.scrollFactor.set();
		
		if (Init.trueSettings.get('Colored Health Bar'))
			healthBar.createFilledBar(dadBar, bfBar);
		else
			healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);

		// healthBar
		add(healthBar);

		iconP1 = new HealthIcon(PlayState.boyfriend.icon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(PlayState.dadOpponent.icon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		scoreBar = new FlxText(FlxG.width / 2, Math.floor(healthBarBG.y + 40), 0, scoreDisplay);
		scoreBar.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE);
		scoreBar.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		scoreBar.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
		add(scoreBar);

		cornerMark = new FlxText(0, 0, 0, engineDisplay);
		cornerMark.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE);
		cornerMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		cornerMark.setPosition(FlxG.width - (cornerMark.width + 5), 5);
		cornerMark.antialiasing = true;
		cornerMark.visible = Init.trueSettings.get('Engine Mark');
		add(cornerMark);

		centerMark = new FlxText(0, (Init.trueSettings.get('Downscroll') ? FlxG.height - 45 : 20), 0, '- $infoDisplay [$diffDisplay] -');
		centerMark.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE);
		centerMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		centerMark.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
		centerMark.screenCenter(X);
		add(centerMark);

		autoplayMark = new FlxText(-5, (Init.trueSettings.get('Downscroll') ? centerMark.y - 60 : centerMark.y + 60), FlxG.width - 800, "AUTOPLAY\n", 32);
		autoplayMark.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		autoplayMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		autoplayMark.screenCenter(X);
		autoplayMark.visible = PlayState.bfStrums.autoplay;

		// repositioning for it to not be covered by the receptors
		if (Init.trueSettings.get('Centered Receptors'))
		{
			if (Init.trueSettings.get('Downscroll'))
				autoplayMark.y = autoplayMark.y - 85;
			else
				autoplayMark.y = autoplayMark.y + 85;
		}

		add(autoplayMark);

		traceBar = new FlxText(10, 20, 0, '', 16);
		traceBar.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE);
		traceBar.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		traceBar.scrollFactor.set();
		traceBar.alpha = 0;
		add(traceBar);

		// counter
		if (Init.trueSettings.get('Counter') != 'None')
		{
			var judgementNameArray:Array<String> = [];
			for (i in Timings.judgementsMap.keys())
				judgementNameArray.insert(Timings.judgementsMap.get(i)[0], i);
			judgementNameArray.sort(sortByShit);
			for (i in 0...judgementNameArray.length)
			{
				var textAsset:FlxText = new FlxText(5
					+ (!left ? (FlxG.width - 10) : 0),
					(FlxG.height / 2)
					- (counterTextSize * (judgementNameArray.length / 2))
					+ (i * counterTextSize), 0, '', counterTextSize);
				if (!left)
					textAsset.x -= textAsset.text.length * counterTextSize;
				textAsset.setFormat(Paths.font("vcr.ttf"), counterTextSize, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				textAsset.scrollFactor.set();
				timingsMap.set(judgementNameArray[i], textAsset);
				add(textAsset);
			}
		}

		updateScoreText();
		updateBar();
	}

	var counterTextSize:Int = 18;

	function sortByShit(Obj1:String, Obj2:String):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Timings.judgementsMap.get(Obj1)[0], Timings.judgementsMap.get(Obj2)[0]);

	var left = (Init.trueSettings.get('Counter') == 'Left');

	override public function update(elapsed:Float)
	{
		// pain, this is like the 7th attempt
		healthBar.percent = (PlayState.health * 50);

		var iconLerp = 1 - Main.framerateAdjust(0.15);
		// iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.initialWidth, iconP1.width, iconLerp)));
		// iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.initialWidth, iconP2.width, iconLerp)));

		iconP1.scale.set(FlxMath.lerp(1, iconP1.scale.x, iconLerp), FlxMath.lerp(1, iconP1.scale.y, iconLerp));
		iconP2.scale.set(FlxMath.lerp(1, iconP2.scale.x, iconLerp), FlxMath.lerp(1, iconP2.scale.y, iconLerp));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		iconP1.updateAnim(healthBar.percent);
		iconP2.updateAnim(100 - healthBar.percent);

		if (autoplayMark.visible)
		{
			autoplaySine += 30 * elapsed;
			autoplayMark.alpha = 1 - Math.sin((Math.PI * autoplaySine) / 80);
		}
	}

	private final divider:String = " • ";

	public function updateScoreText()
	{
		var importSongScore = PlayState.songScore;
		var importMisses = PlayState.misses;

		var unrated = (Timings.comboDisplay == null || Timings.comboDisplay == '');

		var comboDisplay = ' [' + Timings.comboDisplay + ']';

		// testing purposes
		var displayAccuracy:Bool = Init.trueSettings.get('Display Accuracy');

		scoreBar.text = 'Score: $importSongScore';
		if (displayAccuracy)
		{
			scoreBar.text += divider + 'Accuracy: ${(Math.floor(Timings.getAccuracy() * 100) / 100)}%' + (!unrated ? comboDisplay : '');
			scoreBar.text += divider + 'Combo Breaks: $importMisses';
			scoreBar.text += divider + 'Rank: ${Timings.returnScoreRating().toUpperCase()}';
		}
		scoreBar.text += '\n';
		scoreBar.x = Math.floor((FlxG.width / 2) - (scoreBar.width / 2));

		// update counter
		if (Init.trueSettings.get('Counter') != 'None')
		{
			for (i in timingsMap.keys())
			{
				timingsMap[i].text = '${(i.charAt(0).toUpperCase() + i.substring(1, i.length))}: ${Timings.gottenJudgements.get(i)}';
				timingsMap[i].x = (5 + (!left ? (FlxG.width - 10) : 0) - (!left ? (6 * counterTextSize) : 0));
			}
		}

		// update playstate
		PlayState.detailsSub = scoreBar.text;
		PlayState.updateRPC(false);
	}

	public function updateBar()
	{
		if (Init.trueSettings.get('Colored Health Bar'))
			healthBar.createFilledBar(dadBar, bfBar);
		else
			healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		healthBar.scrollFactor.set();
		healthBar.updateBar();
	}

	public function beatHit()
	{
		if (!Init.trueSettings.get('Reduced Movements'))
		{
			iconP1.setGraphicSize(Std.int(iconP1.width + 30));
			iconP2.setGraphicSize(Std.int(iconP2.width + 30));

			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}
	}

	public function tweenScoreColor(rating:String, perfect:Bool)
	{
		if (Init.trueSettings.get('Animated Score Color'))
		{
			if(scoreColorTween != null)
				scoreColorTween.cancel();

			var rankColor = FlxColor.CYAN;

			switch (rating)
			{
				case 'good': rankColor = FlxColor.LIME;
				case 'bad': rankColor = FlxColor.ORANGE;
				case 'shit': rankColor = FlxColor.PURPLE;
				case 'miss': rankColor = FlxColor.RED;
				default: rankColor = perfect ? FlxColor.fromString('#F8D482') : FlxColor.CYAN;
			}

			scoreColorTween = FlxTween.color(scoreBar, 0.005, scoreBar.color, rankColor,
			{
				onComplete: function(twn:FlxTween)
				{
					FlxTween.color(scoreBar, 0.75, scoreBar.color, FlxColor.WHITE);
					scoreColorTween = null;
				}
			});
		}
	}
}
