package states.substates;

import base.Conductor;
import base.MusicBeat.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.Character;
import states.*;
import states.menus.*;

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Character;
	var camFollow:FlxObject;

	var deathSong:FlxSound;
	var tankNoise:FlxSound;

	public static var character:String = 'bf-dead';
	public static var deathMusic:String = 'gameOver';
	public static var deathSound:String = 'fnf_loss_sfx';
	public static var deathConfirm:String = 'gameOverEnd';
	public static var deathBPM:Int = 100;

	public static function resetGameOver()
	{
		character = 'bf-dead';
		deathMusic = 'gameOver';
		deathSound = 'fnf_loss_sfx';
		deathConfirm = 'gameOverEnd';
		deathBPM = 100;
	}

	override function create()
	{
		super.create();

		PlayState.contents.callFunc('gameOverBegins', null);
	}

	public function new(x:Float, y:Float)
	{
		super();

		Conductor.songPosition = 0;

		// precache song
		deathSong = new FlxSound().loadEmbedded(Paths.music(deathMusic), false, true);
		deathSong.volume = (PlayState.SONG.stage == 'military' ? 0.2 : 1);
		FlxG.sound.list.add(deathSong);

		if (PlayState.SONG.stage == 'military')
		{
			// precache tankman sound
			tankNoise = new FlxSound().loadEmbedded(Paths.sound('jeff/jeffGameover-' + FlxG.random.int(1, 25)), false, true);
			FlxG.sound.list.add(tankNoise);
		}

		bf = new Character(x, y, character);
		add(bf);

		PlayState.boyfriend.destroy();

		camFollow = new FlxObject(bf.getGraphicMidpoint().x + 20, bf.getGraphicMidpoint().y - 40, 1, 1);
		add(camFollow);

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		Conductor.changeBPM(deathBPM);
		bf.playAnim('firstDeath');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
			endBullshit();

		if (controls.BACK)
		{
			deathSong.stop();
			if (tankNoise != null && tankNoise.playing)
				tankNoise.stop();
			PlayState.deaths = 0;

			if (PlayState.isStoryMode)
				Main.switchState(this, new StoryMenuState());
			else
				Main.switchState(this, new FreeplayState());
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
			FlxG.camera.follow(camFollow, LOCKON, 0.01);

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			bf.playAnim('deathLoop');
			deathSong.play(false);
		}

		if (PlayState.SONG.stage == 'military')
		{
			if (bf.animation.curAnim.name == 'deathLoop')
			{
				tankNoise.play(false);
				tankNoise.onComplete = function()
				{
					if (!isEnding)
						deathSong.fadeIn(4, 0.2, 1);
				}
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			deathSong.stop();
			if (tankNoise != null && tankNoise.playing)
				tankNoise.stop();
			FlxG.sound.play(Paths.music(deathConfirm));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 1, false, function()
				{
					Main.switchState(this, new PlayState());
				});
			});
		}
	}
}
