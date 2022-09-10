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
	public var noteType:String;

	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	// only useful for charting stuffs
	public var rawNoteData:Int;

	// offsets
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var lowPriority:Bool = false;
	public var hitboxLength:Float = 1;

	public var useCustomSpeed:Bool = Init.trueSettings.get('Use Custom Note Speed');

	// not set initially
	public var noteQuant:Int = -1;
	public var noteVisualOffset:Float = 0;
	public var noteSpeed:Float = 0;
	public var noteDirection:Float = 0;

	public var parentNote:Note;
	public var childrenNotes:Array<Note> = [];

	// it has come to this.
	public var endHoldOffset:Float = Math.NEGATIVE_INFINITY;

	public var noteHealth:Float = 0.023;

	public var hitSounds:Bool = true;
	public var canHurt:Bool = false;
	public var gfNote:Bool = false;
	public var updateAccuracy:Bool = true;

	public var hitsoundSuffix = '';

	static var pixelNoteID:Array<Int> = [4, 5, 6, 7];

	public var globalScript:NoteScript;

	public static var contents:Note;

	public function new(strumTime:Float, noteData:Int, noteAlt:Float, ?prevNote:Note, ?sustainNote:Bool = false)
	{
		super(x, y);

		contents = this;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		switch (noteType)
		{
			case 'Hey!': // hey notes
				updateAccuracy = true;
				hitSounds = true;
				canHurt = false;
				gfNote = false;
			case 'Mine': // mines
				noteHealth -= 0.065;
				updateAccuracy = true;
				hitSounds = false;
				canHurt = true;
				lowPriority = true;
				gfNote = false;
			case 'GF Note': // gf notes
				updateAccuracy = true;
				gfNote = true;
			case 'No Animation': // no animation notes
				updateAccuracy = true;
				hitSounds = false;
				canHurt = false;
				gfNote = false;
			default: // anything else
				hitSounds = true;
				updateAccuracy = true;
				canHurt = false;
				gfNote = false;
				lowPriority = false;
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

			hitSounds = false;
		}
		
		else if (!isSustainNote)
			parentNote = null;
	}
	
	static function getNoteDir(?id:Int)
		return UIStaticArrow.getArrowFromNumber(id);

	static function getNoteColor(?id:Int)
		return UIStaticArrow.getColorFromNumber(id);

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			if (strumTime > Conductor.songPosition - (Timings.msThreshold * hitboxLength)
				&& strumTime < Conductor.songPosition + (Timings.msThreshold * hitboxLength))
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
	public static function returnDefaultNote(assetModifier, strumTime, noteData, noteAlt, ?isSustainNote:Bool = false, ?prevNote:Note, ?noteType:String):Note
	{
		var newNote:Note = new Note(strumTime, noteData, noteAlt, prevNote, isSustainNote);
		newNote.noteType = noteType;
		
		// frames originally go here
		switch (assetModifier)
		{
			case 'pixel':
				if (isSustainNote)
				{
					switch (noteType)
					{
						case 'Mine':
							newNote.kill();
						default: // pixel holds default
							reloadPrefixes('arrowEnds', 'noteskins/notes', true, assetModifier, newNote);
					}
				}
				else
				{
					switch (noteType)
					{
						case 'Mine': // pixel mines;
							newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('mines', assetModifier, '', 'noteskins/mines')), true, 17, 17);
							newNote.animation.add(getNoteColor(noteData) + 'Scroll', [0, 1, 2, 3, 4, 5, 6, 7], 12);

						default: // pixel notes default
							reloadPrefixes('arrows-pixels', 'noteskins/notes', true, assetModifier, newNote);
					}
				}
				newNote.antialiasing = false;
				newNote.setGraphicSize(Std.int(newNote.width * PlayState.daPixelZoom));
				newNote.updateHitbox();

			default: // base game arrows for no reason whatsoever
				switch (noteType)
				{
					case 'Mine': // mines
						newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('mines', assetModifier, '', 'noteskins/mines')), true, 133, 128);
						newNote.animation.add(getNoteColor(noteData) + 'Scroll', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

						if (isSustainNote)
							newNote.kill();

						newNote.setGraphicSize(Std.int(newNote.width * 0.8));
						newNote.updateHitbox();
						newNote.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
					default: // anything else
						reloadPrefixes("NOTE_assets", 'noteskins/notes', true, assetModifier, newNote);
				}
		}
		//
		if (!isSustainNote)
			newNote.animation.play(UIStaticArrow.getColorFromNumber(noteData) + 'Scroll');

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
			}
		}

		return newNote;
	}

	public static function returnQuantNote(assetModifier, strumTime, noteData, noteAlt, ?isSustainNote:Bool = false, ?prevNote:Note = null, ?noteType:String):Note
	{
		var newNote:Note = new Note(strumTime, noteData, noteAlt, prevNote, isSustainNote);
		newNote.noteType = noteType;

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
						case 'Mine': // pixel mines
							if (assetModifier == 'pixel')
							{
								newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('mines', assetModifier, '', 'noteskins/mines')), true, 17, 17);
								newNote.animation.add(getNoteDir(noteData) + 'Scroll', [0, 1, 2, 3, 4, 5, 6, 7], 12);
							}
							else
							{
								newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('mines', assetModifier, '', 'noteskins/mines')), true, 133, 128);
								newNote.animation.add(getNoteDir(noteData) + 'Scroll', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 12);
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
						case 'Mine':
							newNote.kill();
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
				if (noteType == 'No Animation')
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
					newNote.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
				}
		}

		if (!isSustainNote)
			newNote.animation.play(UIStaticArrow.getArrowFromNumber(noteData) + 'Scroll');

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
			}
		}

		return newNote;
	}

	/**
	 * [reloads default note prefixes, useful for notetypes that use those same animation prefixes and such]
	 * @param texture [the texture we should use for your notes];
	 * @param texturePath [the directory that the texture is located in];
	 * @param changeable [whether the noteskin option should affect `this` note];
	 * @param assetModifier [the note's current asset modifier, usually just grabs from `returnDefaultNote` rather than specifying one];
	 * @param newNote [specifies the current note];
	 */
	static function reloadPrefixes(texture:String, texturePath:String, changeable:Bool = true, assetModifier:String, newNote:Note)
	{
		if (assetModifier != 'pixel')
		{
			newNote.frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset(texture, assetModifier, (changeable ? Init.trueSettings.get("Note Skin") : ''), texturePath));

			newNote.animation.addByPrefix(getNoteColor(newNote.noteData) + 'Scroll', getNoteColor(newNote.noteData) + '0');
			newNote.animation.addByPrefix(getNoteColor(newNote.noteData) + 'holdend', getNoteColor(newNote.noteData) + ' hold end');
			newNote.animation.addByPrefix(getNoteColor(newNote.noteData) + 'hold', getNoteColor(newNote.noteData) + ' hold piece');

			newNote.animation.addByPrefix('purpleholdend', 'pruple end hold'); // PA god dammit.

			newNote.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
			newNote.setGraphicSize(Std.int(newNote.width * 0.7));
			newNote.updateHitbox();
		}
		else
		{
			if (newNote.isSustainNote)
			{
				newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset(texture, assetModifier, (changeable ? Init.trueSettings.get("Note Skin") : ''), texturePath)), true, 7, 6);
				newNote.animation.add(getNoteColor(newNote.noteData) + 'holdend', [pixelNoteID[newNote.noteData]]);
				newNote.animation.add(getNoteColor(newNote.noteData) + 'hold', [pixelNoteID[newNote.noteData] - 4]);
			}
			else
			{
				newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset(texture, assetModifier, (changeable ? Init.trueSettings.get("Note Skin") : ''), texturePath)), true, 17, 17);
				newNote.animation.add(getNoteColor(newNote.noteData) + 'Scroll', [pixelNoteID[newNote.noteData]], 12);
			}
		}
	}

	// will be later replacing this function in favor of an actual scripted notetype system;

	/**
	* Custom Note Functions (for when you hit a note), this should execute in PlayState;
	**/
	public function goodNoteHit(newNote:Note, ?ratingTiming:String)
	{
		var hitsound = Init.trueSettings.get('Hitsound Type');
		switch (newNote.noteType)
		{
			case 'Mine':
				PlayState.contents.decreaseCombo(true);
				PlayState.health -= noteHealth;
			default:
				if (newNote.hitSounds)
				{
					if (Init.trueSettings.get('Hitsound Volume') > 0 && newNote.canBeHit)
						FlxG.sound.play(Paths.sound('hitsounds/$hitsound/hit$hitsoundSuffix'), Init.trueSettings.get('Hitsound Volume'));
				}
		}
	}

	/**
	 * [Specify what to do when a note is missed];
	 */
	public function noteMissActions(?coolNote:Note)
	{
		switch (coolNote.noteType)
		{
			default:
				// do nothing;
		}
	}
}
