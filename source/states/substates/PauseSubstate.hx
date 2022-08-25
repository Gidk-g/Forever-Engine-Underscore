package states.substates;

import base.*;
import base.ChartParser.Song;
import base.CoolUtil;
import base.MusicBeat.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import sys.FileSystem;
import funkin.Alphabet;
import funkin.Highscore;
import states.*;
import states.menus.*;

class PauseSubstate extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;
	var pauseMusic:FlxSound;

	var menuItems:Array<String> = [];
	var gameDifficulties:Array<Array<String>> = [];
	var difficultyArray:Array<String> = [];

	var pauseItems:Array<String> = ['Resume', 'Restart Song', 'Exit to Options', 'Exit to menu'];

	public static var toOptions:Bool = false;
	public static var levelPractice:FlxText;
	private var levelError:FlxText;

	public function new(x:Float, y:Float)
	{
		super();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		// menu items set up!
		menuItems = pauseItems;

		for (i in CoolUtil.baseDifficulties)
		{
			// check for existance of difficulty files, and then push said files to the difficulty array as an entry;
			if (FileSystem.exists(Paths.songJson(CoolUtil.dashToSpace(PlayState.SONG.song), CoolUtil.dashToSpace(PlayState.SONG.song) + '-' + i))
				|| (FileSystem.exists(Paths.songJson(CoolUtil.dashToSpace(PlayState.SONG.song), CoolUtil.dashToSpace(PlayState.SONG.song))) && i == "NORMAL"))
				difficultyArray.push(i);
		}

		if (difficultyArray.length > 1) // no need to show the button if there's only a single difficulty;
		{
			menuItems.insert(2, 'Change Difficulty');
			gameDifficulties.push(difficultyArray);
			difficultyArray.push('BACK');
		}

		if (PlayState.chartingMode)
			menuItems.insert(3, 'Leave Charting Mode');

		// pause music, bg, and texts
		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += CoolUtil.dashToSpace(PlayState.SONG.song) + ' [' + CoolUtil.difficultyFromNumber(PlayState.storyDifficulty) + ']';
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font('vcr.ttf'), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelAuthor:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelAuthor.text += 'By: ' + PlayState.SONG.author;
		levelAuthor.scrollFactor.set();
		levelAuthor.setFormat(Paths.font('vcr.ttf'), 32);
		levelAuthor.updateHitbox();
		add(levelAuthor);

		var levelDeaths:FlxText = new FlxText(20, 15 + 64, 0, "", 32);
		levelDeaths.text += "Blue balled: " + PlayState.deaths;
		levelDeaths.scrollFactor.set();
		levelDeaths.setFormat(Paths.font('vcr.ttf'), 32);
		levelDeaths.updateHitbox();
		add(levelDeaths);

		levelPractice = new FlxText(20, 15 + 96, 0, "PRACTICE MODE", 32);
		levelPractice.scrollFactor.set();
		levelPractice.setFormat(Paths.font('vcr.ttf'), 32);
		levelPractice.updateHitbox();
		levelPractice.visible = PlayState.practiceMode;
		add(levelPractice);

		levelError = new FlxText(20, 15 + 102, 0, '', 32);
		levelError.scrollFactor.set();
		levelError.setFormat(Paths.font('vcr.ttf'), 32);
		levelError.updateHitbox();
		add(levelError);

		levelInfo.alpha = 0;
		levelAuthor.alpha = 0;
		levelDeaths.alpha = 0;
		levelPractice.alpha = 0;
		levelError.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelAuthor.x = FlxG.width - (levelAuthor.width + 20);
		levelDeaths.x = FlxG.width - (levelDeaths.width + 20);
		levelPractice.x = FlxG.width - (levelPractice.width + 20);
		levelError.x = FlxG.width - (levelError.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelAuthor, {alpha: 1, y: levelAuthor.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(levelDeaths, {alpha: 1, y: levelDeaths.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});
		if (PlayState.practiceMode)
			FlxTween.tween(levelPractice, {alpha: 1, y: levelPractice.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		reloadOptions();
	}

	function reloadOptions()
	{
		// kill and destroy all the existing items inside the item group;
		for (i in 0...grpMenuShit.members.length)
		{
			var existingItem = grpMenuShit.members[0];
			existingItem.kill();
			grpMenuShit.remove(existingItem, true);
			existingItem.destroy();
		}

		// generate the new menu items;
		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		curSelected = 0;
		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		if (controls.UI_UP_P)
		{
			changeSelection(-1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (controls.ACCEPT)
		{
			var daSelected:String = menuItems[curSelected];

			if (menuItems == difficultyArray && daSelected != 'BACK' && difficultyArray.contains(daSelected))
			{
				var leSongRaw = PlayState.SONG.song.toLowerCase();
				var leSong = Highscore.formatSong(PlayState.SONG.song.toLowerCase(), curSelected);

				try
				{
					PlayState.SONG = Song.loadSong(leSong, leSongRaw);
					PlayState.storyDifficulty = curSelected;
					disableCheats(true);
					Main.switchState(this, new PlayState());
				}
				catch (e)
				{
					levelError.text = "Uncaught Error: " + e;
					levelError.x = FlxG.width - (levelError.width + 20);
					levelError.alpha = 1;
					menuItems = pauseItems;
					reloadOptions();

					FlxTween.tween(levelError, {alpha: 0}, 2);
				}
				return;
			}

			switch (daSelected)
			{
				case "Resume":
					close();
				case "Restart Song":
					if (!PlayState.chartingMode)
						disableCheats(false);
					else
						disableCheats(true);
					Main.switchState(this, new PlayState());
				case "Change Difficulty":
					menuItems = difficultyArray;
					reloadOptions();
				case "Exit to Options":
					toOptions = true;
					disableCheats(true);
					Main.switchState(this, new OptionsMenuState());
				case "Exit to menu":
					Conductor.stopMusic();
					PlayState.deaths = 0;
					disableCheats(true);

					if (PlayState.isStoryMode)
						Main.switchState(this, new StoryMenuState());
					else
						Main.switchState(this, new FreeplayState());

				case 'Leave Charting Mode':
					disableCheats(true);
					PlayState.chartingMode = false;
					Main.switchState(this, new PlayState());
				case 'BACK':
					menuItems = pauseItems;
					reloadOptions();
			}
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();
		super.destroy();
	}

	public static function disableCheats(scoringToo:Bool = false)
	{
		PlayState.practiceMode = false;
		PlayState.contents.bfStrums.autoplay = false;
		PlayState.uiHUD.autoplayMark.visible = false;

		if (scoringToo)
			PlayState.preventScoring = false;

		levelPractice.visible = false;
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;
		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}
