package base;

import base.ChartParser.Song;
import base.ChartParser.SwagSection;
import base.ChartParser.SwagSong;
import flixel.FlxG;
import flixel.system.FlxSound;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import states.PlayState;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/*
	Stuff like this is why this is a mod engine and not a rewrite.
	I'm not going to pretend to know what any of this does and I don't really have the motivation to
	go through it and rewrite it if I think it works just fine, but there are other aspects that I wanted to
	change about the game entirely which I wanted to rewrite so that's why I made this.

	I'll take a look later if it's important for anything. Otherwise, I don't think this code needs to be edited
	for things like other mods and such, maybe for base engine functions. who knows? we'll see.

	Told myself I wasn't gonna bother with this cus I was lazy but now I actually have to and I hate myself for not doing it earlier!
 */
typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor
{
	public static var bpm:Float = 100;

	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds

	public static var songPosition:Float;
	public static var lastSongPos:Float;
	public static var offset:Float = 0;

	public static var songMusic:FlxSound;
	public static var songVocals:FlxSound;

	public static var vocalArray:Array<FlxSound> = [];

	/*
		public static var safeFrames:Int = 10;
		public static var safeZoneOffset:Float = (safeFrames / 60) * 1000;
	 */
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		// trace("new BPM map BUDDY " + bpmChangeMap);
	}

	public static function changeBPM(newBpm:Float, measure:Float = 4 / 4)
	{
		bpm = newBpm;

		crochet = ((60 / bpm) * 1000);
		stepCrochet = (crochet / 4) * measure;
	}

	public static function bindMusic()
	{
		var songData = PlayState.SONG;

		songMusic = new FlxSound();
		songVocals = new FlxSound();

		songMusic.loadEmbedded(Paths.songSounds(songData.song, 'Inst'), false, true);

		if (songData.needsVoices)
			songVocals.loadEmbedded(Paths.songSounds(songData.song, 'Voices'), false, true);

		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(songVocals);
		vocalArray.push(songVocals);
	}

	public static function startMusic(completeFunc:Dynamic)
	{
		songMusic.play();
		songVocals.play();

		songMusic.onComplete = completeFunc;

		resyncVocals();
	}

	public static function pauseMusic()
	{
		songMusic.time = Math.max(songMusic.time, 0);
		songMusic.time = Math.min(songMusic.time, songMusic.length);
		
		songMusic.pause();
		for (vocals in vocalArray)
		{
			if (vocals != null)
			{
				vocals.pause();
			}
		}
	}

	public static function stopMusic()
	{
		for (vocals in vocalArray)
		{
			if (vocals != null)
				vocals.stop();
		}
		//songMusic.stop();
	}

	public static function killMusic()
	{
		for (vocals in vocalArray)
		{
			if (vocals != null)
				ForeverTools.killMusic([songMusic, vocals]);
		}
	}

	public static function resyncVocals():Void
	{
		PlayState.contents.callFunc('resyncVocals', null);

		#if DEBUG_TRACES trace('resyncing vocal time ${songVocals.time}'); #end
		songVocals.pause();

		songMusic.play();
		songPosition = songMusic.time;
		if (songVocals != null && songPosition <= songVocals.length)
		{
			songVocals.time = songPosition;
		}
		songVocals.play();
		#if DEBUG_TRACES trace('new vocal time ${songPosition}'); #end
	}

	public static function resyncBySteps()
	{
		if (Math.abs(songMusic.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (PlayState.SONG.needsVoices && Math.abs(songVocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}
	}
}
