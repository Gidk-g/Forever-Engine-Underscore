package base;

import Paths.ChartType;
import funkin.EventNote;
import funkin.Note;
import funkin.Strumline;
import haxe.Json;
import openfl.utils.Assets;
import states.PlayState;
import sys.io.File;

using StringTools;

/**
	This is the ChartParser class. it loads in charts, but also exports charts, the chart parameters are based on the type of chart, 
	say the base game type loads the base game's charts, the forever chart type loads a custom forever structure chart with custom features,
	and so on. This class will handle both saving and loading of charts with useful features and scripts that will make things much easier
	to handle and load, as well as much more modular!
**/
/**
 * Song Information, such as name, notes, events, bpm, etc;
**/
typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Array<Dynamic>>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var noteSkin:String;
	var splashSkin:String;
	var author:String;
	var assetModifier:String;
	var validScore:Bool;
	var ?offset:Int;
	var ?color:Array<Int>;
}

/**
 * Song Meta Information, such as author, asset modifier, offset, song color, etc;
**/
typedef SwagMeta =
{
	var author:String;
	var assetModifier:String;
	var ?offset:Int;
	var ?color:Array<Int>;
}

/**
 * Song Section Information;
**/
typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

class ChartParser
{
	public static var songType:ChartType = UNDERSCORE;

	// hopefully this makes it easier for people to load and save chart features and such, y'know the deal lol
	public static function loadChart(songData:SwagSong, songType:ChartType = FNF_LEGACY):Array<Note>
	{
		var unspawnNotes:Array<Note> = [];
		var noteData:Array<SwagSection>;

		noteData = songData.notes;
		switch (songType)
		{
			case FNF:
			// placeholder until 0.3!
			case FNF_LEGACY:
				// load fnf style charts (PRE 0.3)
				var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

				for (section in noteData)
				{
					var coolSection:Int = Std.int(section.lengthInSteps / 4);

					for (songNotes in section.sectionNotes)
					{
						var daStrumTime:Float = #if !neko songNotes[0] - Init.trueSettings['Offset'] /* - | late, + | early*/ #else songNotes[0] #end;
						var daNoteData:Int = Std.int(songNotes[1] % 4);
						// define the note's animation (in accordance to the original game)!
						var daNoteAlt:Float = 0;

						// very stupid but I'm lazy
						if (songNotes.length > 2)
						{
							daNoteAlt = songNotes[3];
						}
						/*
							rest of this code will be mostly unmodified, I don't want to interfere with how FNF chart loading works
							I'll keep all of the extra features in forever charts, which you'll be able to convert and export to very easily using
							the in engine editor 

							I'll be doing my best to comment the work below but keep in mind I didn't originally write it
						 */

						// check the base section
						var gottaHitNote:Bool = section.mustHitSection;

						// if the note is on the other side, flip the base section of the note
						if (songNotes[1] > 3)
							gottaHitNote = !section.mustHitSection;

						// define the note that comes before (previous note)
						var oldNote:Note;
						if (unspawnNotes.length > 0)
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						else // if it exists, that is
							oldNote = null;

						// create the new note
						var swagNote:Note = ForeverAssets.generateArrow(PlayState.assetModifier, daStrumTime, daNoteData, daNoteAlt);
						// set note speed
						swagNote.noteSpeed = songData.speed;

						// set the note's length (sustain note)
						swagNote.sustainLength = songNotes[2];
						swagNote.scrollFactor.set(0, 0);
						var susLength:Float = swagNote.sustainLength; // sus amogus

						// adjust sustain length
						susLength = susLength / Conductor.stepCrochet;
						// push the note to the array we'll push later to the playstate
						unspawnNotes.push(swagNote);
						// STOP POSTING ABOUT AMONG US
						// basically said push the sustain notes to the array respectively
						for (susNote in 0...Math.floor(susLength))
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
							var sustainNote:Note = ForeverAssets.generateArrow(PlayState.assetModifier,
								daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, daNoteAlt, true, oldNote);
							sustainNote.scrollFactor.set();

							unspawnNotes.push(sustainNote);
							sustainNote.mustPress = gottaHitNote;
							/*
								This is handled in engine anyways, not necessary!
								if (sustainNote.mustPress)
									sustainNote.x += FlxG.width / 2;
							 */
						}
						// oh and set the note's must hit section
						swagNote.mustPress = gottaHitNote;
					}
					daBeats += 1;
				}

			case FOREVER:
			// placeholder

			case UNDERSCORE:
				/**
					a copy of FNF_LEGACY, except we have notetypes and events, that's all
					I don't exactly know how chart parsing works, so I'm leaving it like this for the time being
					- BeastlyGhost
				**/

				var daBeats:Int = 0;

				for (section in noteData)
				{
					var coolSection:Int = Std.int(section.lengthInSteps / 4);

					for (songNotes in section.sectionNotes)
					{
						var daStrumTime:Float = songNotes[0]#if !neko - Init.trueSettings['Offset'] #end; // - | late, + | early
						var daNoteData:Int = Std.int(songNotes[1] % 4);
						var daNoteAlt:Float = 0;
						var daNoteType:Int = 0; // define the note's type

						if (songNotes.length > 2)
						{
							daNoteType = songNotes[3];
						}
						var gottaHitNote:Bool = section.mustHitSection;
						if (songNotes[1] > 3)
							gottaHitNote = !section.mustHitSection;

						var oldNote:Note;
						if (unspawnNotes.length > 0)
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						else
							oldNote = null;

						var swagNote:Note = ForeverAssets.generateArrow(PlayState.assetModifier, daStrumTime, daNoteData, daNoteAlt, daNoteType);
						swagNote.noteSpeed = songData.speed;

						swagNote.sustainLength = songNotes[2];
						swagNote.scrollFactor.set(0, 0);

						var susLength:Float = swagNote.sustainLength;
						susLength = susLength / Conductor.stepCrochet;
						unspawnNotes.push(swagNote);

						for (susNote in 0...Math.floor(susLength))
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
							var sustainNote:Note = ForeverAssets.generateArrow(PlayState.assetModifier,
								daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, daNoteAlt, true, oldNote, daNoteType);
							sustainNote.scrollFactor.set();

							unspawnNotes.push(sustainNote);
							sustainNote.mustPress = gottaHitNote;
						}
						swagNote.mustPress = gottaHitNote;
					}
					daBeats += 1;
				}
			case PSYCH:
				// placeholder
		}

		return unspawnNotes;
	}

	public static function loadEvents(SONG:SwagSong, chartType:ChartType):Array<EventNote>
	{
		var allowedTypes:Array<ChartType> = [UNDERSCORE];
		var eventData:Array<Array<Dynamic>> = SONG.events;
		var unspawnEvents:Array<EventNote> = [];

		if (allowedTypes.contains(chartType) && eventData != null)
		{
			for (event in eventData)
			{
				var strumTime:Float = event[0];
				var val1:String = event[1];
				var val2:String = event[2];
				var onHit:String = event[3];

				var eventNote:EventNote = new EventNote(strumTime, val1, val2, onHit);
				eventNote.visible = false;

				unspawnEvents.push(eventNote);
			}
		}

		return unspawnEvents;
	}
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadSong(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = '';
		var rawMeta = '';

		try
		{
			rawJson = Assets.getText(Paths.songJson(folder.toLowerCase(), jsonInput.toLowerCase())).trim();
		}
		catch (e)
		{
			rawJson = null;
		}

		if (rawJson != null)
		{
			while (!rawJson.endsWith("}"))
				rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		try
		{
			rawMeta = Assets.getText(Paths.songJson(folder.toLowerCase(), 'meta')).trim();
		}
		catch (e)
		{
			rawMeta = null;
		}

		if (rawMeta != null)
		{
			while (!rawMeta.endsWith("}"))
				rawMeta = rawMeta.substr(0, rawMeta.length - 1);
		}

		if (rawMeta == null)
		{
			rawMeta = '{
				"author": "???",
				"assetModifier": "base",
				"offset": 0,
				"color": [255, 255, 255]
			}';
		}

		return parseSong(rawJson, rawMeta);
	}

	public static function parseSong(rawJson:String, rawMeta:String = 'meta'):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;

		var swagMeta:SwagMeta = cast Json.parse(rawMeta);

		// injecting info from the meta file if it's valid data, else get from the song data
		// please spare me I know it looks weird.
		if (swagMeta.assetModifier != null)
			swagShit.assetModifier = swagMeta.assetModifier;
		else if (swagMeta.assetModifier == null)
			swagShit.assetModifier = swagShit.assetModifier;
		else
			swagShit.assetModifier == 'base';

		if (swagMeta.author != null)
			swagShit.author = swagMeta.author;
		else if (swagMeta.author == null)
			swagShit.author = swagShit.author;
		else
			swagShit.author = '???';

		if (swagMeta.offset != null)
			swagShit.offset = swagMeta.offset;
		else if (swagMeta.offset == null)
			swagShit.offset = swagShit.offset;
		else
			swagShit.offset = 0;

		if (swagMeta.color != null)
			swagShit.color = swagMeta.color;
		else if (swagMeta.color == null)
			swagShit.color = swagShit.color;
		else
			swagShit.color = [255, 255, 255];

		return swagShit;
	}
}

class Section
{
	public var sectionNotes:Array<Dynamic> = [];

	public var lengthInSteps:Int = 16;
	public var typeOfSection:Int = 0;
	public var mustHitSection:Bool = true;

	/**
	 *	Copies the first section into the second section!
	 */
	public static var COPYCAT:Int = 0;

	public function new(lengthInSteps:Int = 16)
	{
		this.lengthInSteps = lengthInSteps;
	}
}
