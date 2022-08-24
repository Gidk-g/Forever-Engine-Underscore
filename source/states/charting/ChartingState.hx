package states.charting;

import base.*;
import base.ChartParser.Song;
import base.ChartParser.SwagSong;
import base.Conductor;
import base.MusicBeat.MusicBeatState;
import dependency.*;
import dependency.BaseButton.CoolAssButton;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import funkin.*;
import funkin.Strumline.UIStaticArrow;
import funkin.ui.*;
import haxe.Json;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.ColorTransform;
import openfl.net.FileReference;
import states.charting.data.*;
import states.menus.FreeplayState;
import states.substates.charting.*;

using StringTools;

/**
	As the name implies, this is the class where all of the charting state stuff happens, so when you press 7 the game
	state switches to this one, where you get to chart songs and such. I'm planning on overhauling this entirely in the future
	and making it both more practical and more user friendly.
**/
class ChartingState extends MusicBeatState
{
	public var _song:SwagSong;

	var _file:FileReference;

	var songMusic:FlxSound;
	var vocals:FlxSound;
	var keysTotal = 8;

	var strumLine:FlxSprite;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var strumLineCam:FlxObject;

	public var currentSection:Null<Int> = 0;

	var curSelectedNote:Note;
	var curSelectedSustain:Dynamic;

	public static var songPosition:Float = 0;
	public static var curSong:SwagSong;

	var baseGrid:FlxSprite;

	public static var gridSize:Int = 50;

	var mouseIndicator:FlxSprite;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedEvents:FlxTypedGroup<EventNote>;
	var curRenderedSections:FlxTypedGroup<FlxBasic>;

	var arrowGroup:FlxTypedSpriteGroup<UIStaticArrow>;

	var buttonTextGroup:FlxTypedGroup<AbsoluteText>;
	var buttonGroup:FlxTypedGroup<CoolAssButton>;
	var gridGroup:FlxTypedGroup<FlxObject>;

	var buttonArray:Array<Array<Dynamic>> = [];

	var bfIcon:HealthIcon;
	var dadIcon:HealthIcon;

	// UI/default/forever/chart editor/quant
	var quantL:FlxSprite;
	var quantR:FlxSprite;

	// event name - desciption
	var eventArray:Array<Array<String>> = [
		["", ""],
		[
			"Hey!",
			"Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"
		],
		[
			"Set GF Speed",
			"Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"
		],
		[
			"Change Character",
			"Sets the current Character to a new one\nValue 1: Character to change (dad, bf, gf)\nValue 2: New character's name"
		],
		[
			"Change Scroll Speed",
			"Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."
		],
		[
			"Play Animation",
			"Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"
		]
	];
	var eventTxt:FlxText;
	var currentSelectedEvent:String;

	static final snapList:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	static final snapColors:Array<FlxColor> = [
		FlxColor.RED, FlxColor.BLUE, FlxColor.PURPLE, FlxColor.YELLOW, FlxColor.GRAY, FlxColor.PINK, FlxColor.ORANGE, FlxColor.CYAN, FlxColor.GREEN,
		FlxColor.LIME, FlxColor.MAGENTA
	];

	static var curSnap:Int = 8;
	static var curSpeed = 1;

	override public function create()
	{
		super.create();

		generateBackground();

		Main.changeInfoAlpha(0.4);

		if (PlayState.SONG != null)
		{
			if (PlayState.SONG.events == null)
				PlayState.SONG.events = [];

			_song = PlayState.SONG;
		}
		else
		{
			_song = Song.loadSong('test', 'test');

			if (_song.events == null)
				_song.events = [];
		}

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		#if DISCORD_RPC
		Discord.changePresence('CHART EDITOR',
			'Charting: '
			+ _song.song
			+ ' [${CoolUtil.difficultyFromNumber(PlayState.storyDifficulty)}] - by '
			+ _song.author, true);
		#end

		gridGroup = new FlxTypedGroup<FlxObject>();
		add(gridGroup);

		buttonGroup = new FlxTypedGroup<CoolAssButton>();
		add(buttonGroup);

		buttonTextGroup = new FlxTypedGroup<AbsoluteText>();
		add(buttonTextGroup);

		generateButtons();
		// generateGrid();

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedEvents = new FlxTypedGroup<EventNote>();
		curRenderedSections = new FlxTypedGroup<FlxBasic>();

		// generateNotes();
		recreateGrid();

		add(curRenderedSections);
		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedEvents);

		// epic strum line
		strumLine = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width / 2 - 155), 2);
		add(strumLine);
		strumLine.screenCenter(X);

		// cursor
		mouseIndicator = new FlxSprite().makeGraphic(gridSize, gridSize);
		mouseIndicator.alpha = 0.6;
		add(mouseIndicator);

		// and now the epic note thingies
		arrowGroup = new FlxTypedSpriteGroup<UIStaticArrow>(0, 0);
		for (keys in 0...keysTotal)
		{
			var typeReal:Int = 0;
			typeReal = keys;
			if (typeReal > 3)
				typeReal -= 4;

			var newArrow:UIStaticArrow = ForeverAssets.generateUIArrows(((FlxG.width / 2) - ((keysTotal / 2) * gridSize - 25)) + ((keys - 1) * gridSize), -76,
				typeReal, 'chart editor');

			newArrow.ID = keys;
			newArrow.setGraphicSize(gridSize);
			newArrow.updateHitbox();
			newArrow.alpha = 0.8;
			newArrow.antialiasing = !Init.trueSettings.get('Disable Antialiasing');

			// lol silly idiot
			newArrow.playAnim('static');

			if (newArrow.animation.curAnim.name == 'confirm')
				newArrow.alpha = 1;

			arrowGroup.add(newArrow);
		}

		add(arrowGroup);
		arrowGroup.x -= 1;

		generateIcons();

		strumLineCam = new FlxObject(0, 0);
		strumLineCam.screenCenter(X);

		// code from the playstate so I can separate the camera and hud
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		FlxG.camera.follow(strumLine);

		generateText();

		FlxG.mouse.useSystemCursor = true; // Use system cursor because it's prettier
		FlxG.mouse.visible = true; // Hide mouse on start
	}

	var hitSoundsPlayed:Array<Note> = [];

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		curStep = recalculateSteps();

		if (FlxG.keys.justPressed.SPACE)
		{
			if (songMusic.playing)
			{
				songMusic.pause();
				vocals.pause();
				// CoolUtil.difficultyFromNumber(storyDifficulty)('pause');
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

		if (FlxG.keys.justPressed.E && curSelectedNote != null)
			curSelectedNote.sustainLength += Conductor.stepCrochet;
		else if (FlxG.keys.justPressed.Q && curSelectedNote != null)
			curSelectedNote.sustainLength -= Conductor.stepCrochet;

		updateText();

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

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[currentSection].lengthInSteps));
		// trace(strumLine.y);
		strumLineCam.y = strumLine.y + (FlxG.height / 3);
		arrowGroup.y = strumLine.y;

		var strumCamY = strumLineCam.y - (FlxG.height / 2);

		coolGradient.y = strumCamY;
		coolGrid.y = strumCamY;

		bfIcon.y = strumCamY;
		dadIcon.y = strumCamY;

		quantL.y = dadIcon.y + 110;
		quantR.y = dadIcon.y + 110;

		if (curBeat % 4 == 0 && curStep >= 16 * (currentSection + 1))
			changeSection(currentSection + 1, false);
		else if (strumLine.y < -15)
			changeSection(currentSection - 1, false);

		// mouse stuffs
		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(buttonGroup))
			{
				buttonGroup.forEach(function(button:CoolAssButton)
				{
					if (FlxG.mouse.overlaps(button))
					{
						button.onClick(null);
					}
				});
			}

			var currentType:Int = 0;
			if (!FlxG.mouse.overlaps(curRenderedNotes))
			{
				// add note funny
				var noteStrum = getStrumTime(mouseIndicator.y) + sectionStartTime();

				var notesSection = Math.floor(noteStrum / (Conductor.stepCrochet * 16));
				var noteData = adjustSide(Math.floor((mouseIndicator.x - baseGrid.x) / gridSize), _song.notes[notesSection].mustHitSection);
				var noteType = currentType; // define notes as the current type
				var noteSus = 0; // ninja you will NOT get away with this

				noteData--;

				if (noteData > -1)
					generateChartNote(noteData, noteStrum, noteSus, 0, noteType, notesSection);
				else
					generateEvent(noteStrum, null, null, currentSelectedEvent, true);
				autosaveSong();
			}
			else
			{
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							curSelectedNote = note;
						}
						else
						{
							note.kill();
							curRenderedNotes.remove(note, true);
							deleteNote(note);
							note.destroy();
						}
					}
				});
				curRenderedEvents.forEachAlive(function(event:EventNote)
				{
					if (FlxG.mouse.overlaps(event))
					{
						event.kill();
						curRenderedEvents.remove(event, true);
						deleteEvent(event);
						event.destroy();
					}
				});
			}

			// would be cool maybe
			if (FlxG.mouse.overlaps(quantL) || FlxG.mouse.overlaps(quantR))
			{
				changeQuant(FlxG.mouse.overlaps(quantL) ? -1 : 1);
			}
		}

		if (FlxG.mouse.x > (baseGrid.x)
			&& FlxG.mouse.x < (baseGrid.x + baseGrid.width)
			&& FlxG.mouse.y > 0
			&& FlxG.mouse.y < baseGrid.y + (gridSize * _song.notes[currentSection].lengthInSteps))
		{
			var fakeMouseX:Float = FlxG.mouse.x - baseGrid.x;

			mouseIndicator.x = (Math.floor((fakeMouseX) / gridSize) * gridSize) + baseGrid.x;

			if (FlxG.keys.pressed.SHIFT)
				mouseIndicator.y = FlxG.mouse.y;
			else
				mouseIndicator.y = Math.floor(FlxG.mouse.y / gridSize) * gridSize;
		}

		if (FlxG.keys.justPressed.ESCAPE)
			saveAndClose(FlxG.keys.pressed.SHIFT ? 'FreeplayState' : 'PlayState');

		if (FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ENTER)
		{
			pauseMusic();
			openSubState(new PreferenceSubstate(camHUD, (FlxG.keys.justPressed.ENTER) ? 'prefs' : 'help'));
		}

		if (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E)
			changeNoteSustain(FlxG.keys.justPressed.Q ? -Conductor.stepCrochet : Conductor.stepCrochet);

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
		{
			autosaveSong();
			saveLevel();
		}

		var left = FlxG.keys.justPressed.LEFT;
		var right = FlxG.keys.justPressed.RIGHT;

		if (left || right)
			changeQuant(left ? -1 : 1);

		if (FlxG.keys.anyPressed([W, S]))
		{
			if (curStep <= 0)
				return;

			songMusic.pause();
			vocals.pause();

			var daTime:Float = 700 * FlxG.elapsed * curSpeed;

			if (FlxG.keys.pressed.W)
				songMusic.time -= daTime;
			else
				songMusic.time += daTime;

			vocals.time = songMusic.time;
		}
	}

	function changeQuant(newSpd:Int)
	{
		curSpeed += newSpd;

		if (curSpeed > snapList.length - 1)
			curSpeed = 0;
		if (curSpeed < 0)
			curSpeed = snapList.length - 1;

		curSnap = snapList[curSpeed];

		quantL.color = snapColors[curSpeed];
		quantR.color = snapColors[curSpeed];
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedSustain != null)
			{
				curSelectedSustain += value;
				curSelectedSustain = Math.max(curSelectedSustain, 0);
			}
		}

		updateGrid(false);
	}

	function saveAndClose(State:String)
	{
		songPosition = songMusic.time;
		PlayState.SONG = _song;

		FlxG.mouse.visible = false;
		ForeverTools.killMusic([songMusic, vocals]);

		Main.changeInfoAlpha(1);

		Paths.clearUnusedMemory();

		if (State == 'PlayState')
			Main.switchState(this, new PlayState());
		else
			Main.switchState(this, new FreeplayState());
	}

	function deleteNote(note:Note)
	{
		var data:Null<Int> = note.noteData;

		var noteStrum = getStrumTime(mouseIndicator.y);
		var curSection = Math.floor(noteStrum / (Conductor.stepCrochet * 16));

		if (data > -1 && note.mustPress != _song.notes[curSection].mustHitSection)
			data += 4;

		if (data > -1)
		{
			for (i in _song.notes[curSection].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] == data)
				{
					FlxG.log.add('FOUND EVIL NUMBER');
					_song.notes[curSection].sectionNotes.remove(i);
					break;
				}
			}
		}
	}

	function deleteEvent(event:EventNote)
	{
		var naughtyStrum:Float = event.strumTime;

		for (i in _song.events)
		{
			if (i[0] == naughtyStrum)
			{
				_song.events.remove(i);
				event.kill();
				curRenderedEvents.remove(event, true);
				event.destroy();
				break;
			}
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

				var pain = (Math.floor(Conductor.songPosition / Conductor.stepCrochet));

				// do epic note calls for strum stuffs
				if (pain == Math.floor(epicNote.strumTime / Conductor.stepCrochet))
				{
					var data:Null<Int> = epicNote.noteData;
					if (data > -1 && epicNote.mustPress != _song.notes[currentSection].mustHitSection)
						data += 4;

					arrowGroup.members[data].playAnim('confirm', true);
					arrowGroup.members[data].resetAnim = (epicNote.sustainLength / 1000) + 0.2;

					if (!hitSoundsPlayed.contains(epicNote))
					{
						FlxG.sound.play(Paths.sound('hitsounds/${Init.trueSettings.get('Hitsound Type').toLowerCase()}/hit'));
						hitSoundsPlayed.push(epicNote);
					}
				}
			}
			else
			{
				epicNote.alive = false;
				epicNote.visible = false;
			}
		});

		super.stepHit();
	}

	function changeSection(?sec:Int = 0, ?stop:Bool = false):Void
	{
		currentSection = sec;

		if (stop)
		{
			vocals.stop();
			songMusic.stop();
		}

		Conductor.songPosition = songMusic.time;

		updateGrid(false);
	}

	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...currentSection + add)
		{
			if (_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += 4 * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, baseGrid.y, baseGrid.y + baseGrid.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, baseGrid.y, baseGrid.y + baseGrid.height);
	}

	function updateGrid(creating:Bool):Void
	{
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedEvents.clear();

		var sectionInfo:Array<Dynamic> = _song.notes[currentSection].sectionNotes;
		var eventInfo:Array<Dynamic> = _song.events;

		for (i in sectionInfo)
		{
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];
			var daNoteType:Int = i[3];

			// trace('Current note type is $daNoteType.');

			var keys = 4;

			generateChartNote(daNoteInfo, daStrumTime, daSus, 0, daNoteType, currentSection, false);
		}

		for (i in eventInfo)
		{
			var strum:Float = i[0];
			var val1:String = i[1];
			var val2:String = i[2];
			var id:String = i[3];

			generateEvent(strum, val1, val2, id, creating);
		}
	}

	var fullGrid:FlxTiledSprite;

	function recreateGrid():Void
	{
		gridGroup.clear();
		var newAlpha = (26 / 255);

		baseGrid = FlxGridOverlay.create(gridSize, gridSize, gridSize * 9, gridSize * 32, true, FlxColor.WHITE, FlxColor.BLACK);
		baseGrid.graphic.bitmap.colorTransform(baseGrid.graphic.bitmap.rect, new ColorTransform(1, 1, 1, newAlpha));
		baseGrid.screenCenter(X);
		// gridGroup.add(baseGrid);

		fullGrid = new FlxTiledSprite(null, gridSize * keysTotal, gridSize);
		fullGrid.loadGraphic(baseGrid.graphic);
		fullGrid.screenCenter(X);
		fullGrid.height = (songMusic.length / Conductor.stepCrochet) * gridSize;
		gridGroup.add(fullGrid);

		var gridBlackLine:FlxSprite = new FlxSprite(baseGrid.x + gridSize).makeGraphic(2, Std.int(baseGrid.height), FlxColor.BLACK);
		gridGroup.add(gridBlackLine);

		updateGrid(false);
	}

	public var sectionLineGraphic:FlxGraphic;
	public var sectionCameraGraphic:FlxGraphic;
	public var sectionStepGraphic:FlxGraphic;

	function regenerateSection(section:Int, placement:Float)
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
		curRenderedSections.add(sectionCamera);

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

		for (i in 1...Std.int(_song.notes[section].lengthInSteps / 4))
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

		// sectionsMax = 1;
		generateSection();
		for (section in 0..._song.notes.length)
		{
			sectionsMax = section;
			regenerateSection(section, 16 * gridSize * section);

			for (i in _song.notes[section].sectionNotes)
			{
				// note stuffs
				var daNoteAlt:Float = 0;
				if (i.length > 2)
					daNoteAlt = i[3];

				var daNoteType:Int = 0;
				if (i.length > 2)
					daNoteType = i[3];

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
			vocals.loadEmbedded(Paths.songSounds(daSong, 'Voices'), false, true);

		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocals);

		songMusic.play();
		vocals.play();

		if (curSong == _song)
			songMusic.time = songPosition;

		curSong = _song;
		songPosition = 0;

		pauseMusic();

		songMusic.onComplete = function()
		{
			ForeverTools.killMusic([songMusic, vocals]);
			loadSong(daSong);
		};
	}

	function generateChartNote(daNoteInfo, daStrumTime, daSus, daNoteAlt:Float, daNoteType:Int, noteSection, ?shouldPush:Bool = true)
	{
		// trace(daNoteInfo);

		var note:Note = ForeverAssets.generateArrow(PlayState.assetModifier, daStrumTime, daNoteInfo % 4, 0, false, null);
		note.rawNoteData = daNoteInfo;
		note.sustainLength = daSus;
		note.setGraphicSize(gridSize, gridSize);
		note.updateHitbox();
		note.screenCenter(X);
		note.x = Math.ffloor(daNoteInfo * gridSize) + gridSize;
		note.x += 418;
		note.y = Math.ffloor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[currentSection].lengthInSteps)));

		if (shouldPush)
		{
			_song.notes[noteSection].sectionNotes.push([daStrumTime, (daNoteInfo + 4) % 8, daSus, '']);
			curSelectedNote = note;
		}

		curRenderedNotes.add(note);

		if (daSus > 0)
		{
			var sustainVis:FlxSprite = new FlxSprite(note.x + (gridSize / 2 - 3),
				note.y + gridSize).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, baseGrid.height)));
			curRenderedSustains.add(sustainVis);
		}

		// generateSustain(daStrumTime, daNoteInfo, daSus, daNoteAlt, daNoteType, note);
	}

	function generateEvent(strumTime:Float, val1:String, val2:String, id:String, ?shouldPush:Bool = false):Void
	{
		var event:Array<Dynamic> = [strumTime, val1, val2, id];

		var eventNote:EventNote = new EventNote(strumTime, val1, val2, id);
		eventNote.setGraphicSize(gridSize, gridSize);
		eventNote.updateHitbox();
		eventNote.x += 370;
		eventNote.y = Math.floor(getYfromStrum((event[0] - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[currentSection].lengthInSteps)));

		if (shouldPush)
		{
			_song.events.push(event);
		}

		curRenderedEvents.add(eventNote);
	}

	function generateSustain(daStrumTime:Float = 0, daNoteInfo:Int = 0, daSus:Float = 0, daNoteAlt:Float = 0, danoteType:Int = 0, note:Note)
	{
		/*
			if (daSus > 0)
			{
				var prevNote:Note = null;
				prevNote = note;
				var constSize = Std.int(gridSize / 3);

				var sustainVis:Note = new Note(daStrumTime + (Conductor.stepCrochet * daSus) + Conductor.stepCrochet, daNoteInfo % 4, daNoteAlt, prevNote, true, daNoteType);
				sustainVis.setGraphicSize(constSize,
					Math.floor(FlxMath.remapToRange((daSus / 2) - constSize, 0, Conductor.stepCrochet * 16, 0, gridSize * gridSize)));
				sustainVis.updateHitbox();
				sustainVis.x = note.x + constSize;
				sustainVis.y = note.y + (gridSize / 2);

				var sustainEnd:Note = new Note(daStrumTime + (Conductor.stepCrochet * daSus) + Conductor.stepCrochet, daNoteInfo % 4, daNoteAlt, sustainVis, true, daNoteType);
				sustainEnd.setGraphicSize(constSize, constSize);
				sustainEnd.updateHitbox();
				sustainEnd.x = sustainVis.x;
				sustainEnd.y = note.y + (sustainVis.height) + (gridSize / 2);

				// loll for later
				sustainVis.rawNoteData = daNoteInfo;
				sustainEnd.rawNoteData = daNoteInfo;

				curRenderedSustains.add(sustainVis);
				curRenderedSustains.add(sustainEnd);
			}
		 */
	}

	///*
	var coolGrid:FlxBackdrop;
	var coolGradient:FlxSprite;

	function generateBackground()
	{
		coolGrid = new FlxBackdrop(null, 1, 1, true, true, 1, 1);
		coolGrid.loadGraphic(Paths.image('UI/forever/base/chart editor/grid'));
		coolGrid.screenCenter();
		coolGrid.alpha = (32 / 255);
		add(coolGrid);

		// gradient
		coolGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			FlxColor.gradient(FlxColor.fromRGB(188, 158, 255, 200), FlxColor.fromRGB(80, 12, 108, 255), 16));
		coolGradient.alpha = (32 / 255);
		coolGradient.screenCenter();
		add(coolGradient);
	}

	function generateButtons():Void
	{
		// x, y, text on button, text size, child (optional), size ("" (medium), "big", or "small"),
		// function that will be called when pressed (optional)

		buttonArray = [
			[FlxG.width - 240, 20, "SAVE SONG", 20, null, "", null],
			[FlxG.width - 240, 70, "RELOAD SONG", 20, null, "", null],
			[FlxG.width - 240, 120, "LOAD AUTOSAVE", 20, null, "", null],
			[FlxG.width - 240, 170, "SWAP SECTION NOTES", 20, null, "", null],
			[FlxG.width - 240, 220, "COPY SECTION NOTES", 20, null, "", null],
			[FlxG.width - 240, 270, "PASTE SECTION NOTES", 20, null, "", null]
		];

		buttonGroup.clear();
		buttonTextGroup.clear();

		var void:Void->Void = null;

		for (i in buttonArray)
		{
			if (i != null)
			{
				// trace(i);

				switch (i[2].toLowerCase())
				{
					case 'reload song':
						void = function()
						{
							loadSong(PlayState.SONG.song);
							FlxG.resetState();
						};

					case 'save song':
						void = function()
						{
							saveLevel();
						}

					case 'load autosave':
						void = function()
						{
							PlayState.SONG = Song.parseSong(FlxG.save.data.autosave);
							FlxG.resetState();
						}

					case 'swap section notes':
						void = function()
						{
							for (i in 0..._song.notes[currentSection].sectionNotes.length)
							{
								var note = _song.notes[currentSection].sectionNotes[i];

								// must press
								var keys = 4;

								// in total
								var tolKeys = 8;

								note[1] = (note[1] + keys) % tolKeys;
								_song.notes[currentSection].sectionNotes[i] = note;
								updateGrid(false);
							}
						};

					default:
						void = i[6];
				}

				var button:CoolAssButton = new CoolAssButton(i[0], i[1], i[5], null);
				button.child = i[4];
				button.clickThing = void;
				buttonGroup.add(button);

				var text:AbsoluteText = new AbsoluteText(i[2], i[3], button, 10, 10);
				text.scrollFactor.set();
				buttonTextGroup.add(text);
			}
		}
	}

	var editorTxt:FlxText;
	var songTxt:FlxText;
	var helpTxt:FlxText;
	var prefTxt:FlxText;
	var bpmTxt:FlxText;

	function generateText()
	{
		// text stuffs
		editorTxt = new FlxText(10, 20, 0, "", 16);
		editorTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		editorTxt.scrollFactor.set();
		add(editorTxt);

		songTxt = new FlxText(10, 45, 0, "", 16);
		songTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		songTxt.scrollFactor.set();
		add(songTxt);

		editorTxt.text = 'CHART EDITOR\n';
		songTxt.text = _song.song.toUpperCase()
			+ ' <${CoolUtil.difficultyFromNumber(PlayState.storyDifficulty)}> '
			+ 'BY '
			+ _song.author.toUpperCase()
			+ '\n';

		// fallback text in case the game explodes idk
		bpmTxt = new FlxText(5, FlxG.height - 30, 0, "BPM: 0", 16);
		bpmTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		helpTxt = new FlxText(0, 0, 0, "", 16);
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
		prefTxt.setPosition(FlxG.width - (prefTxt.width + 5), FlxG.height - 30);
	}

	function updateText()
	{
		bpmTxt.text = bpmTxt.text = Std.string('BEAT: ' + FlxMath.roundDecimal(decBeat, 2) + '  SNAP: ' + curSnap + '  MEASURE: ' + currentSection
			+ '  TIME: ' + FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ '  BPM: '
			+ _song.bpm;
	}

	function generateIcons()
	{
		// stupid.
		var bf:Character = new Character(0, 0, _song.player1);
		var dad:Character = new Character(0, 0, _song.player2);

		bfIcon = new HealthIcon(bf.icon);
		dadIcon = new HealthIcon(dad.icon);
		bfIcon.scrollFactor.set(1, 1);
		dadIcon.scrollFactor.set(1, 1);

		bfIcon.setGraphicSize(gridSize, gridSize);
		dadIcon.setGraphicSize(gridSize, gridSize);

		bfIcon.flipX = true;

		add(bfIcon);
		add(dadIcon);

		bfIcon.screenCenter(X);
		dadIcon.screenCenter(X);

		dadIcon.setPosition(strumLine.width / 2 + 80, 0);
		bfIcon.setPosition(strumLine.width / 2 + 590, 0);

		quantL = new FlxSprite();
		quantR = new FlxSprite();

		// load animations
		quantL.loadGraphic(Paths.image('UI/forever/base/chart editor/marker'));
		quantL.updateHitbox();
		quantL.antialiasing = !Init.trueSettings.get('Disable Antialiasing');

		// RIGHT
		quantR.loadGraphic(Paths.image('UI/forever/base/chart editor/marker'));
		quantR.updateHitbox();
		quantR.antialiasing = !Init.trueSettings.get('Disable Antialiasing');

		quantL.scrollFactor.set(1, 1);
		quantR.scrollFactor.set(1, 1);

		quantL.setGraphicSize(gridSize, gridSize);
		quantR.setGraphicSize(gridSize, gridSize);

		add(quantL);
		add(quantR);

		quantL.screenCenter(X);
		quantR.screenCenter(X);

		quantR.setPosition(strumLine.x + 10, 30);
		quantL.setPosition(strumLine.x + 490, quantR.y);

		quantL.color = snapColors[curSpeed];
		quantR.color = snapColors[curSpeed];
	}

	function adjustSide(noteData:Int, sectionTemp:Bool):Int
	{
		return (sectionTemp ? ((noteData + 4) % 8) : noteData);
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
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
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

	//

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
