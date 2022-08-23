package funkin;

import base.*;
import dependency.FNFSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import funkin.Strumline.UIStaticArrow;
import states.PlayState;

using StringTools;

class Note extends FNFSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var noteAlt:Float = 0;
	public var noteType:Int = 0;

	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	// only useful for charting stuffs
	public var chartSustain:FlxSprite = null;
	public var rawNoteData:Int;

	// not set initially
	public var noteQuant:Int = -1;
	public var noteVisualOffset:Float = 0;
	public var noteSpeed:Float = 0;
	public var noteDirection:Float = 0;

	public var parentNote:Note;
	public var childrenNotes:Array<Note> = [];

	// it has come to this.
	public var endHoldOffset:Float = Math.NEGATIVE_INFINITY;

	public var healthGain:Float = 0.023;
	public var healthLoss:Float = 0.0475;

	public var hitSounds:Bool = true;
	public var badNote:Bool = false;
	public var gfNote:Bool = false;

	public var fullString = '';
	public var altString = '';
	public var hitsoundSuffix = '';

	static var noteColorID:Array<String> = ['purple', 'blue', 'green', 'red'];
	static var directionID:Array<String> = ['left', 'down', 'up', 'right'];
	static var pixelNoteID:Array<Int> = [4, 5, 6, 7];

	public function new(strumTime:Float, noteData:Int, noteAlt:Float, ?prevNote:Note, ?sustainNote:Bool = false, ?noteType:Int = 0)
	{
		super(x, y);

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.noteType = noteType;
		isSustainNote = sustainNote;

		if (noteType == null)
			noteType = 0;

		switch (noteType)
		{
			case 1:
				altString = '-alt';
			case 2:
				fullString = 'hey';
			case 3:
				gfNote = true;
			case 5:
				healthLoss = 0.065;
				badNote = true;
			default:
				hitSounds = true;
				badNote = false;
				gfNote = false;
		}

		// oh okay I know why this exists now
		y -= 2000;

		this.strumTime = strumTime;
		this.noteData = noteData;
		this.noteAlt = noteAlt;

		// determine parent note
		if (isSustainNote && prevNote != null)
		{
			parentNote = prevNote;
			while (parentNote.parentNote != null)
				parentNote = parentNote.parentNote;
			parentNote.childrenNotes.push(this);
		}
		else if (!isSustainNote)
			parentNote = null;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			if (strumTime > Conductor.songPosition - (Timings.msThreshold) && strumTime < Conductor.songPosition + (Timings.msThreshold))
				canBeHit = true;
			else
				canBeHit = false;
		}
		else // make sure the note can't be hit if it's the dad's I guess
			canBeHit = false;

		if (tooLate || (parentNote != null && parentNote.tooLate))
			alpha = 0.3;
	}

	/**
		Note creation scripts

		these are for all your custom note needs

		at the very bottom of this file you can find the function
		for setting up custom note behavior when hit and such
	**/
	public static function returnDefaultNote(assetModifier, strumTime, noteData, noteAlt, ?isSustainNote:Bool = false, ?prevNote:Note, noteType:Int = 0):Note
	{
		var newNote:Note = new Note(strumTime, noteData, noteAlt, prevNote, isSustainNote, noteType);

		// frames originally go here
		switch (assetModifier)
		{
			case 'pixel':
				if (isSustainNote)
				{
					switch (noteType)
					{
						case 5:
							newNote.kill();
						default: // pixel holds default
							newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('arrowEnds', assetModifier, Init.trueSettings.get("Note Skin"),
								'noteskins/notes')),
								true, 7, 6);
							newNote.animation.add(noteColorID[noteData] + 'holdend', [pixelNoteID[noteData]]);
							newNote.animation.add(noteColorID[noteData] + 'hold', [pixelNoteID[noteData] - 4]);
					}
				}
				else
				{
					switch (noteType)
					{
						case 5: // pixel mines
							newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('mines', assetModifier, '', 'noteskins/mines')), true, 17, 17);
							newNote.animation.add(noteColorID[noteData] + 'Scroll', [0, 1, 2, 3, 4, 5, 6, 7]);

						default: // pixel notes default
							newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('arrows-pixels', assetModifier, Init.trueSettings.get("Note Skin"),
								'noteskins/notes')),
								true, 17, 17);
							newNote.animation.add(noteColorID[noteData] + 'Scroll', [pixelNoteID[noteData]]);
					}
				}
				newNote.antialiasing = false;
				newNote.setGraphicSize(Std.int(newNote.width * PlayState.daPixelZoom));
				newNote.updateHitbox();

			default: // base game arrows for no reason whatsoever
				switch (noteType)
				{
					case 5: // mines
						newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('mines', assetModifier, '', 'noteskins/mines')), true, 133, 128);
						newNote.animation.add(noteColorID[noteData] + 'Scroll', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

						if (isSustainNote)
							newNote.kill();

						newNote.setGraphicSize(Std.int(newNote.width * 0.8));
						newNote.updateHitbox();
						newNote.antialiasing = true;

					default: // anything else
						newNote.frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset('NOTE_assets', assetModifier, Init.trueSettings.get("Note Skin"),
							'noteskins/notes'));

						newNote.animation.addByPrefix(noteColorID[noteData] + 'Scroll', noteColorID[noteData] + '0');
						newNote.animation.addByPrefix(noteColorID[noteData] + 'holdend', noteColorID[noteData] + ' hold end');
						newNote.animation.addByPrefix(noteColorID[noteData] + 'hold', noteColorID[noteData] + ' hold piece');

						if (noteData == 0)
							newNote.animation.addByPrefix('purpleholdend', 'pruple end hold'); // uh?

						newNote.setGraphicSize(Std.int(newNote.width * 0.7));
						newNote.updateHitbox();
						newNote.antialiasing = true;
				}
		}
		//
		if (!isSustainNote)
			newNote.animation.play(UIStaticArrow.getColorFromNumber(noteData) + 'Scroll');
		// trace(prevNote);
		if (isSustainNote && prevNote != null)
		{
			newNote.noteSpeed = prevNote.noteSpeed;
			newNote.alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;

			newNote.animation.play(UIStaticArrow.getColorFromNumber(noteData) + 'holdend');

			newNote.updateHitbox();
			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(UIStaticArrow.getColorFromNumber(prevNote.noteData) + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * prevNote.noteSpeed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		}

		return newNote;
	}

	public static function returnQuantNote(assetModifier, strumTime, noteData, noteAlt, ?isSustainNote:Bool = false, ?prevNote:Note = null, noteType:Int = 0):Note
	{
		var newNote:Note = new Note(strumTime, noteData, noteAlt, prevNote, isSustainNote, noteType);

		// actually determine the quant of the note
		if (newNote.noteQuant == -1)
		{
			/*
				I have to credit like 3 different people for these LOL they were a hassle
				but its gede pixl and scarlett, thank you SO MUCH for baring with me
			 */
			final quantArray:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 192]; // different quants

			var curBPM:Float = Conductor.bpm;
			var newTime = strumTime;
			for (i in 0...Conductor.bpmChangeMap.length)
			{
				if (strumTime > Conductor.bpmChangeMap[i].songTime)
				{
					curBPM = Conductor.bpmChangeMap[i].bpm;
					newTime = strumTime - Conductor.bpmChangeMap[i].songTime;
				}
			}

			final beatTimeSeconds:Float = (60 / curBPM); // beat in seconds
			final beatTime:Float = beatTimeSeconds * 1000; // beat in milliseconds
			// assumed 4 beats per measure?
			final measureTime:Float = beatTime * 4;

			final smallestDeviation:Float = measureTime / quantArray[quantArray.length - 1];

			for (quant in 0...quantArray.length)
			{
				// please generate this ahead of time and put into array :)
				// I dont think I will im scared of those
				final quantTime = (measureTime / quantArray[quant]);
				if ((newTime #if !neko + Init.trueSettings['Offset'] #end + smallestDeviation) % quantTime < smallestDeviation * 2)
				{
					// here it is, the quant, finally!
					newNote.noteQuant = quant;
					break;
				}
			}
		}

		// note quants
		switch (assetModifier)
		{
			default:
				// inherit last quant if hold note
				if (isSustainNote && prevNote != null)
					newNote.noteQuant = prevNote.noteQuant;
				// base quant notes
				if (!isSustainNote)
				{
					switch (noteType)
					{
						case 5: // pixel mines
							if (assetModifier == 'pixel')
							{
								newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('mines', assetModifier, '', 'noteskins/mines')), true, 17, 17);
								newNote.animation.add(directionID[noteData] + 'Scroll', [0, 1, 2, 3, 4, 5, 6, 7]);
							}
							else
							{
								newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('mines', assetModifier, '', 'noteskins/mines')), true, 133, 128);
								newNote.animation.add(directionID[noteData] + 'Scroll', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
							}

						default:
							// in case you're unfamiliar with these, they're ternary operators, I just dont wanna check for pixel notes using a separate statement
							var newNoteSize:Int = (assetModifier == 'pixel') ? 17 : 157;
							newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('NOTE_quants', assetModifier, Init.trueSettings.get("Note Skin"),
								'noteskins/notes', 'quant')),
								true, newNoteSize, newNoteSize);

							newNote.animation.add('leftScroll', [0 + (newNote.noteQuant * 4)]);
							// LOL downscroll thats so funny to me
							newNote.animation.add('downScroll', [1 + (newNote.noteQuant * 4)]);
							newNote.animation.add('upScroll', [2 + (newNote.noteQuant * 4)]);
							newNote.animation.add('rightScroll', [3 + (newNote.noteQuant * 4)]);
					}
				}
				else
				{
					switch (noteType)
					{
						default:
							// quant holds
							newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('HOLD_quants', assetModifier, Init.trueSettings.get("Note Skin"),
								'noteskins/notes', 'quant')),
								true, (assetModifier == 'pixel') ? 17 : 109, (assetModifier == 'pixel') ? 6 : 52);
							newNote.animation.add('hold', [0 + (newNote.noteQuant * 4)]);
							newNote.animation.add('holdend', [1 + (newNote.noteQuant * 4)]);
							newNote.animation.add('roll', [2 + (newNote.noteQuant * 4)]);
							newNote.animation.add('rollend', [3 + (newNote.noteQuant * 4)]);
					}
				}

				var sizeThing = 0.7;
				if (noteType == 5)
					sizeThing = 0.8;

				if (assetModifier == 'pixel')
				{
					newNote.antialiasing = false;
					newNote.setGraphicSize(Std.int(newNote.width * PlayState.daPixelZoom));
					newNote.updateHitbox();
				}
				else
				{
					newNote.setGraphicSize(Std.int(newNote.width * sizeThing));
					newNote.updateHitbox();
					newNote.antialiasing = true;
				}
		}

		//
		if (!isSustainNote)
			newNote.animation.play(UIStaticArrow.getArrowFromNumber(noteData) + 'Scroll');

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
		{
			newNote.noteSpeed = prevNote.noteSpeed;
			newNote.alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;

			newNote.animation.play('holdend');
			newNote.updateHitbox();

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play('hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * (43 / 52) * 1.5 * prevNote.noteSpeed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		}

		return newNote;
	}

	/**
	* Custom Note Functions (for when you hit a note), this should execute in PlayState;
	**/
	public function goodNoteHit(newNote:Note)
	{
		var hitsound = Init.trueSettings.get('Hitsound Type');
		switch (newNote.noteType)
		{
			case 5:
				PlayState.contents.decreaseCombo(true);
				PlayState.health -= healthLoss;	
			default:
				if (newNote.hitSounds)
				{
					if (Init.trueSettings.get('Hitsound Volume') > 0 && newNote.canBeHit && !newNote.isSustainNote)
						FlxG.sound.play(Paths.sound('hitsounds/$hitsound/hit$hitsoundSuffix'), Init.trueSettings.get('Hitsound Volume'));
				}
		}
	}
}
