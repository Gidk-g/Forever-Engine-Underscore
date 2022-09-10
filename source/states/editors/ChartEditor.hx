package states.editors;

import base.ChartParser.Section;
import base.ChartParser.Song;
import base.ChartParser.SwagSection;
import base.ChartParser.SwagSong;
import base.Conductor;
import base.ForeverAssets;
import base.ForeverTools;
import base.MusicBeat.MusicBeatState;
import dependency.AbsoluteText.EventText;
import dependency.Discord;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.shapes.FlxShapeBox;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import funkin.Note;
import funkin.Strumline.UIStaticArrow;
import haxe.Json;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import meta.subState.charting.*;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import states.menus.FreeplayState;

using StringTools;

#if sys
import sys.thread.Thread;
#end

/**
	As the name implies, this is the class where all of the charting state stuff happens, so when you press 7 the game
	state switches to this one, where you get to chart songs and such. I'm planning on overhauling this entirely in the future
	and making it both more practical and more user friendly.
**/
class ChartEditor extends MusicBeatState
{
	var _song:SwagSong;

	var _file:FileReference;

	var songMusic:FlxSound;
	var vocals:FlxSound;
	private var keysTotal = 8;

	var strumLine:FlxSprite;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var strumLineCam:FlxObject;

	public static var songPosition:Float = 0;
	public static var curSong:SwagSong;

	public static var gridSize:Int = 50;

	public var curSection:Null<Int> = 0;

	/**
	 * CURRENT / LAST PLACED NOTE;
	**/
	var curSelectedNote:Array<Dynamic>;

	var curNoteType:Int = 0;
	var tempBpm:Float = 0;

	private var dummyArrow:FlxSprite;
	private var curRenderedNotes:FlxTypedGroup<Note>;
	private var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	private var curRenderedSections:FlxTypedGroup<FlxBasic>;
	private var curRenderedTexts:FlxTypedGroup<EventText>;

	private var arrowGroup:FlxTypedSpriteGroup<UIStaticArrow>;

	override public function create()
	{
		super.create();

		generateBackground();

		Main.changeInfoParams(0.6);

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
			_song = Song.loadSong('test', 'test');
		
		#if DISCORD_RPC
		Discord.changePresence('CHART EDITOR',
			'Charting: '
			+ _song.song
			+ ' [${CoolUtil.difficultyFromNumber(PlayState.storyDifficulty)}] - by '
			+ _song.author, null, null, null, true);
		#end

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		tempBpm = _song.bpm;

		generateGrid();

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedSections = new FlxTypedGroup<FlxBasic>();
		curRenderedTexts = new FlxTypedGroup<EventText>();

		generateNotes();

		add(curRenderedSections);
		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedTexts);

		strumLineCam = new FlxObject(0, 0);
		strumLineCam.screenCenter(X);

		// epic strum line
		strumLine = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width / 2), 2);
		add(strumLine);
		strumLine.screenCenter(X);

		// cursor
		dummyArrow = new FlxSprite().makeGraphic(gridSize, gridSize);
		dummyArrow.alpha = 0.6;
		add(dummyArrow);

		// and now the epic note thingies
		arrowGroup = new FlxTypedSpriteGroup<UIStaticArrow>(0, 0);
		for (i in 0...keysTotal)
		{
			var typeReal:Int = i;
			if (typeReal > 3)
				typeReal -= 4;

			var assetType = 'base';
			assetType = (_song.assetModifier == 'base' ? 'chart editor' : _song.assetModifier);

			var newArrow:UIStaticArrow = ForeverAssets.generateUIArrows(((FlxG.width / 2) - ((keysTotal / 2) * gridSize)) + ((i - 1) * gridSize), assetType == 'pixel' ? -55 : -75,
				typeReal, assetType);

			newArrow.ID = i;
			newArrow.setGraphicSize(gridSize);
			newArrow.updateHitbox();
			newArrow.alpha = 0.9;
			if (_song.assetModifier == 'pixel')
				newArrow.antialiasing = false;
			else
				newArrow.antialiasing = !Init.trueSettings.get('Disable Antialiasing');

			// lol silly idiot
			newArrow.playAnim('static');

			arrowGroup.add(newArrow);
		}
		add(arrowGroup);
		arrowGroup.x -= 1;

		// code from the playstate so I can separate the camera and hud
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		FlxG.camera.follow(strumLineCam);

		generateText();

		FlxG.mouse.useSystemCursor = true; // Use system cursor because it's prettier
		FlxG.mouse.visible = true; // Hide mouse on start
	}

	var hitSoundsPlayed:Array<Note> = [];

	override public function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		if (FlxG.keys.justPressed.SPACE)
		{
			if (songMusic.playing)
			{
				songMusic.pause();
				vocals.pause();
				// playButtonAnimation('pause');
			}
			else
			{
				vocals.play();
				songMusic.play();

				// reset note tick sounds
				hitSoundsPlayed = [];

				// playButtonAnimation('play');
			}
		}

		if (!FlxG.keys.pressed.SHIFT)
		{
			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				songMusic.pause();
				vocals.pause();

				var daTime:Float = 700 * FlxG.elapsed;

				if (FlxG.keys.pressed.W)
				{
					songMusic.time -= daTime;
				}
				else
					songMusic.time += daTime;

				vocals.time = songMusic.time;
			}
		}
		else
		{
			if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
			{
				songMusic.pause();
				vocals.pause();

				var daTime:Float = Conductor.stepCrochet * 2;

				if (FlxG.keys.justPressed.W)
				{
					songMusic.time -= daTime;
				}
				else
					songMusic.time += daTime;

				vocals.time = songMusic.time;
			}
		}

		var scrollSpeed:Float = 0.75;
		if (FlxG.mouse.wheel != 0)
		{
			songMusic.pause();
			vocals.pause();

			songMusic.time = Math.max(songMusic.time - (FlxG.mouse.wheel * Conductor.stepCrochet * scrollSpeed), 0);
			songMusic.time = Math.min(songMusic.time, songMusic.length);
			vocals.time = songMusic.time;
		}

		// strumline camera stuffs!
		Conductor.songPosition = songMusic.time;

		strumLine.y = getYfromStrum(Conductor.songPosition);
		strumLineCam.y = strumLine.y + (FlxG.height / 3);
		arrowGroup.y = strumLine.y;

		coolGradient.y = strumLineCam.y - (FlxG.height / 2);
		coolGrid.y = strumLineCam.y - (FlxG.height / 2);

		_song.bpm = tempBpm;

		if (songMusic.playing)
		{
			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
			{
				songMusic.pitch += 0.1;
				vocals.pitch += 0.1;
			}

			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.X)
			{
				songMusic.pitch -= 0.1;
				vocals.pitch -= 0.1;
			}

			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C)
			{
				songMusic.pitch = 1;
				vocals.pitch = 1;
			}

			if (songMusic.pitch >= 6)
			{
				songMusic.pitch = 6;
				vocals.pitch = 6;
			}

			if (songMusic.pitch <= 0.1)
			{
				songMusic.pitch = 0.1;
				vocals.pitch = 0.1;
			}
		}

		// there's probably a better way to do this;
		bpmTxt.text = Std.string('BEAT: ' + FlxMath.roundDecimal(decBeat, 2)
			+ '\nSTEP: ' + FlxMath.roundDecimal(decStep, 2)
			+ '\nTIME: ' + Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(songMusic.length / 1000, 2))
			+ '\nBPM: ' + _song.bpm
			+ '\n\nRate: ' + songMusic.pitch);

		super.update(elapsed);

		curRenderedNotes.forEachAlive(function(epicNote:Note)
		{
			var songCrochet = (Math.floor(Conductor.songPosition / Conductor.stepCrochet));

			// do epic note calls for strum stuffs
			if (songCrochet == Math.floor(epicNote.strumTime / Conductor.stepCrochet) && songMusic.playing)
			{
				var data:Null<Int> = epicNote.noteData;

				if (data > -1 && epicNote.mustPress != _song.notes[curSection].mustHitSection)
					data += 4;

				arrowGroup.members[data].playAnim('confirm', true);
				arrowGroup.members[data].resetAnim = (epicNote.sustainLength / 1000) + 0.2;

				if (!hitSoundsPlayed.contains(epicNote))
				{
					FlxG.sound.play(Paths.sound('hitsounds/${Init.trueSettings.get('Hitsound Type').toLowerCase()}/hit'));
					hitSoundsPlayed.push(epicNote);
				}
			}
		});

		if (FlxG.mouse.x > (fullGrid.x)
			&& FlxG.mouse.x < (fullGrid.x + fullGrid.width)
			&& FlxG.mouse.y > 0
			&& FlxG.mouse.y < (getYfromStrum(songMusic.length)))
		{
			var fakeMouseX = FlxG.mouse.x - fullGrid.x;
			dummyArrow.x = (Math.floor((fakeMouseX) / gridSize) * gridSize) + fullGrid.x;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridSize) * gridSize;

			// moved this in here for the sake of not dying
			if (FlxG.mouse.justPressed)
			{
				if (!FlxG.mouse.overlaps(curRenderedNotes))
				{
					// add note funny
					var noteStrum = getStrumTime(dummyArrow.y);

					var notesSection = Math.floor(noteStrum / (Conductor.stepCrochet * 16));
					var noteData = adjustSide(Math.floor((dummyArrow.x - fullGrid.x) / gridSize), _song.notes[notesSection].mustHitSection);
					var noteType = Std.string(curNoteType);
					var noteSus = 0; // ninja you will NOT get away with this

					// noteCleanup(notesSection, noteStrum, noteData);
					// _song.notes[notesSection].sectionNotes.push([noteStrum, noteData, noteSus]);

					if (noteData > -1)
						generateChartNote(noteData, noteStrum, noteSus, 0, noteType, notesSection, true);
					/*
					else
						generateChartEvent(noteStrum, eValue1, eValue2, eName, true);
					*/
					autosaveSong();
					// updateSelection(_song.notes[notesSection].sectionNotes[_song.notes[notesSection].sectionNotes.length - 1], notesSection, true);
					// isPlacing = true;
				}
				else
				{
					curRenderedNotes.forEachAlive(function(note:Note)
					{
						if (FlxG.mouse.overlaps(note))
						{
							if (FlxG.keys.pressed.CONTROL)
							{
								// selectNote(note);
							}
							else
							{
								note.kill();
								curRenderedNotes.remove(note);
								note.destroy();
							}
						}
					});
				}
			}
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
		{
			autosaveSong();
			saveLevel();
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.R)
		{
			loadAutosave();
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			autosaveSong();
			songPosition = songMusic.time;
			PlayState.SONG = _song;
			FlxG.mouse.visible = false;

			ForeverTools.killMusic([songMusic, vocals]);

			Paths.clearUnusedMemory();
			Main.changeInfoParams(1);

			Main.switchState(this, new PlayState());
		}

		if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.ESCAPE)
		{
			autosaveSong();
			FlxG.mouse.visible = false;
			ForeverTools.killMusic([songMusic, vocals]);

			Paths.clearUnusedMemory();
			Main.changeInfoParams(1);

			CoolUtil.difficulties = CoolUtil.baseDifficulties;

			Main.switchState(this, new FreeplayState());
		}
	}

	override public function stepHit()
	{
		// call all rendered notes lol
		curRenderedNotes.forEach(function(epicNote:Note)
		{
			if ((epicNote.y > (strumLineCam.y - (FlxG.height / 2) - epicNote.height))
				|| (epicNote.y < (strumLineCam.y + (FlxG.height / 2))))
			{
				epicNote.alive = true;
				epicNote.visible = true;
			}
			else
			{
				epicNote.alive = false;
				epicNote.visible = false;
			}
		});

		super.stepHit();
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, 0, (songMusic.length / Conductor.stepCrochet) * gridSize, 0, songMusic.length);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, songMusic.length, 0, (songMusic.length / Conductor.stepCrochet) * gridSize);
	}

	function getSectionBeats(?section:Null<Int> = null)
	{
		if (section == null)
			section = curSection;
		var val:Null<Float> = null;

		if (_song.notes[section] != null)
			val = _song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	var fullGrid:FlxTiledSprite;

	function generateGrid()
	{
		// create new sprite
		var base:FlxSprite = FlxGridOverlay.create(gridSize, gridSize, gridSize * 2, gridSize * 2, true, FlxColor.WHITE, FlxColor.BLACK);
		fullGrid = new FlxTiledSprite(null, gridSize * keysTotal, gridSize);
		// base graphic change data
		var newAlpha = (26 / 255);
		base.graphic.bitmap.colorTransform(base.graphic.bitmap.rect, new ColorTransform(1, 1, 1, newAlpha));
		fullGrid.loadGraphic(base.graphic);
		fullGrid.screenCenter(X);

		// fullgrid height
		fullGrid.height = (songMusic.length / Conductor.stepCrochet) * gridSize;
		add(fullGrid);
	}

	public var sectionLineGraphic:FlxGraphic;
	public var sectionCameraGraphic:FlxGraphic;
	public var sectionStepGraphic:FlxGraphic;

	private function regenerateSection(section:Int, placement:Float)
	{
		// this will be used to regenerate a box that shows what section the camera is focused on

		// oh and section information lol
		var sectionLine:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (keysTotal / 2)) - (extraSize / 2), placement);
		sectionLine.frames = sectionLineGraphic.imageFrame;
		sectionLine.alpha = (88 / 255);

		// section camera
		var sectionExtend:Float = 0;
		if (_song.notes[section].mustHitSection)
			sectionExtend = (gridSize * (keysTotal / 2));

		var sectionCamera:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (keysTotal / 2)) + (sectionExtend), placement);
		sectionCamera.frames = sectionCameraGraphic.imageFrame;
		sectionCamera.alpha = (88 / 255);
		//curRenderedSections.add(sectionCamera);

		// set up section numbers
		for (i in 0...2)
		{
			var sectionNumber:FlxText = new FlxText(0, sectionLine.y - 12, 0, Std.string(section), 20);
			// set the x of the section number
			sectionNumber.x = sectionLine.x - sectionNumber.width - 5;
			if (i == 1)
				sectionNumber.x = sectionLine.x + sectionLine.width + 5;

			sectionNumber.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE);
			sectionNumber.antialiasing = false;
			sectionNumber.alpha = sectionLine.alpha;
			curRenderedSections.add(sectionNumber);
		}

		for (i in 1...Std.int(getSectionBeats() * 4 / 4))
		{
			// create a smaller section stepper
			var sectionStep:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (keysTotal / 2)) - (extraSize / 2), placement + (i * (gridSize * 4)));
			sectionStep.frames = sectionStepGraphic.imageFrame;
			sectionStep.alpha = sectionLine.alpha;
			curRenderedSections.add(sectionStep);
		}

		curRenderedSections.add(sectionLine);
	}

	var sectionsMax = 0;

	function generateNotes()
	{
		// GENERATING THE GRID NOTES!
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedTexts.clear();

		// sectionsMax = 1;
		generateSection();
		for (section in 0..._song.notes.length)
		{
			sectionsMax = section;
			curSection = section;
			regenerateSection(section, 16 * gridSize * section);
			setNewBPM(section);
			for (i in _song.notes[section].sectionNotes)
			{
				// note stuffs
				var daNoteAlt = 0;
				if (i.length > 2)
					daNoteAlt = i[3];
				var daNoteType = i[3];
				generateChartNote(i[1], i[0], i[2], daNoteAlt, daNoteType, section, false);
			}
		}
		// lolll
		// sectionsMax--;
	}

	var extraSize = 6;

	function generateSection()
	{
		// pregenerate assets so it doesnt destroy your ram later
		sectionLineGraphic = FlxG.bitmap.create(gridSize * keysTotal + extraSize, 2, FlxColor.WHITE);
		sectionCameraGraphic = FlxG.bitmap.create(Std.int(gridSize * (keysTotal / 2)), 16 * gridSize, FlxColor.fromRGB(43, 116, 219));
		sectionStepGraphic = FlxG.bitmap.create(gridSize * keysTotal + extraSize, 1, FlxColor.WHITE);
	}

	function loadSong(daSong:String):Void
	{
		if (songMusic != null)
			songMusic.stop();

		if (vocals != null)
			vocals.stop();

		songMusic = new FlxSound();
		vocals = new FlxSound();
		
		songMusic.loadEmbedded(Paths.songSounds(daSong, 'Inst'), false, true);
		if (_song.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.songSounds(daSong, 'Voices'), false, true);

		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocals);

		songMusic.play();
		vocals.play();

		if (curSong == _song)
			songMusic.time = songPosition * songMusic.pitch;
		curSong = _song;
		songPosition = 0;

		pauseMusic();

		songMusic.onComplete = function()
		{
			ForeverTools.killMusic([songMusic, vocals]);
			loadSong(daSong);
		};
	}

	private function generateChartNote(daNoteInfo, daStrumTime, daSus, daNoteAlt, daNoteType, noteSection, pushNote:Bool)
	{
		var note:Note = ForeverAssets.generateArrow(_song.assetModifier, daStrumTime, daNoteInfo % 4, 0, false, null, daNoteType);
		// I love how there's 3 different engines that use this exact same variable name lmao
		note.rawNoteData = daNoteInfo;
		note.sustainLength = daSus;
		note.setGraphicSize(gridSize, gridSize);
		note.updateHitbox();

		note.screenCenter(X);
		note.x -= ((gridSize * (keysTotal / 2)) - (gridSize / 2));
		note.x += Math.floor(adjustSide(daNoteInfo, _song.notes[noteSection].mustHitSection) * gridSize);

		note.y = Math.floor(getYfromStrum(daStrumTime));

		if (pushNote)
			_song.notes[noteSection].sectionNotes.push([daStrumTime, daNoteInfo % 8, daSus, '']);

		curRenderedNotes.add(note);

		generateSustain(daStrumTime, daNoteInfo, daSus, daNoteAlt, daNoteType, note);

		// attach a text to their respective notetype;
		if (daNoteType != 'default')
		{
			var noteTypeNum:EventText = new EventText(0, 0, 100, Std.string(daNoteType), 24);
			noteTypeNum.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noteTypeNum.xAdd = -26;
			noteTypeNum.yAdd = 10;
			noteTypeNum.borderSize = 1;
			curRenderedTexts.add(noteTypeNum);
			noteTypeNum.tracker = note;
		}

		note.mustPress = !_song.notes[curSection].mustHitSection;
		if (daNoteInfo > 3)
			note.mustPress = !note.mustPress;
	}

	private function generateSustain(daStrumTime:Float = 0, daNoteInfo:Int = 0, daSus:Float = 0, daNoteAlt:Float = 0, daNoteType:String = 'default', prevNote:Note)
	{
		if (daSus > 0 && prevNote != null)
		{
			var constSize = Std.int(gridSize / 2 - 2);

			var sustainVis:Note = ForeverAssets.generateArrow(_song.assetModifier, daStrumTime + Conductor.stepCrochet, daNoteInfo % 4, daNoteAlt, true, prevNote, daNoteType);
			sustainVis.setGraphicSize(constSize, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, gridSize * constSize)));
			sustainVis.updateHitbox();
			sustainVis.x = prevNote.x + constSize;
			sustainVis.y = prevNote.y + (gridSize / 2);
			sustainVis.rawNoteData = daNoteInfo;
			curRenderedSustains.add(sustainVis);

			if (prevNote != null && prevNote.isSustainNote)
			{
				var sustainEnd:Note = ForeverAssets.generateArrow(_song.assetModifier, daStrumTime + Conductor.stepCrochet, daNoteInfo % 4, daNoteAlt, true, sustainVis, daNoteType);
				sustainEnd.setGraphicSize(constSize, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, gridSize * constSize)));
				sustainEnd.updateHitbox();
				sustainEnd.x = sustainVis.x - 15;
				sustainEnd.y = sustainVis.y + (sustainVis.height) + (gridSize / 2);
				sustainEnd.rawNoteData = daNoteInfo;
				curRenderedSustains.add(sustainEnd);
			}
		}
	}

	var coolGrid:FlxBackdrop;
	var coolGradient:FlxSprite;

	private function generateBackground()
	{
		coolGrid = new FlxBackdrop(null, 1, 1, true, true, 1, 1);
		coolGrid.loadGraphic(Paths.image('UI/forever/base/chart editor/grid'));
		coolGrid.alpha = (32 / 255);
		add(coolGrid);

		// gradient
		coolGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			FlxColor.gradient(FlxColor.fromRGB(188, 158, 255, 200), FlxColor.fromRGB(80, 12, 108, 255), 16));
		coolGradient.alpha = (32 / 255);
		add(coolGradient);
	}

	var songTxt:FlxText;
	var helpTxt:FlxText;
	var prefTxt:FlxText;
	var bpmTxt:FlxText;

	private function generateText()
	{
		songTxt = new FlxText(0, 20, 0, "", 16);
		songTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		songTxt.scrollFactor.set();
		add(songTxt);

		songTxt.text = _song.song.toUpperCase()
			+ ' <${CoolUtil.difficultyFromNumber(PlayState.storyDifficulty)}> '
			+ 'BY '
			+ _song.author.toUpperCase()
			+ '\n';

		bpmTxt = new FlxText(0, FlxG.height - 120, 0, "BEAT: 0.00\nSTEP: 0.00\nTIME: 0.00 / 0.00\nBPM: 0\n\nRate: 0", 16);
		bpmTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		/*helpTxt = new FlxText(0, 0, 0, "", 16);
		helpTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		helpTxt.scrollFactor.set();
		add(helpTxt);

		prefTxt = new FlxText(0, 0, 0, "", 16);
		prefTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		prefTxt.scrollFactor.set();
		add(prefTxt);

		helpTxt.text = 'PRESS BACKSPACE FOR HELP';
		prefTxt.text = 'PRESS ENTER FOR PREFERENCES';

		helpTxt.setPosition(FlxG.width - (helpTxt.width + 5), FlxG.height - 55);
		prefTxt.setPosition(FlxG.width - (prefTxt.width + 5), FlxG.height - 30);*/
	}

	function adjustSide(noteData:Int, sectionTemp:Bool)
	{
		return (sectionTemp ? ((noteData + 4) % 8) : noteData);
	}

	function setNewBPM(section:Int)
	{
		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (songMusic.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((songMusic.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function autosaveSong():Void
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && data.length > 0)
		{
			FlxG.save.data.autosave = data;
		}
		FlxG.save.flush();
	}

	function loadAutosave():Void
	{
		try
		{
			PlayState.SONG = Song.parseSong(FlxG.save.data.autosave, null);
			FlxG.resetState();
		}
		catch (e)
		{
			return;
		}
	}

	// save things
	function saveLevel()
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	function pauseMusic()
	{
		songMusic.time = Math.max(songMusic.time, 0);
		songMusic.time = Math.min(songMusic.time, songMusic.length);

		resyncVocals();
		songMusic.pause();
		vocals.pause();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		songMusic.play();
		Conductor.songPosition = songMusic.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}
}