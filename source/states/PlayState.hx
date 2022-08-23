package states;

import Paths.ChartType;
import base.*;
import base.ChartParser.Song;
import base.ChartParser.SwagSong;
import base.MusicBeat.MusicBeatState;
import dependency.*;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.OverlayShader;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.*;
import funkin.Strumline.UIStaticArrow;
import funkin.ui.*;
import lime.app.Application;
import openfl.display.BlendMode;
import openfl.display.BlendModeEffect;
import openfl.display.GraphicsShader;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import states.charting.*;
import states.menus.*;
import states.substates.*;

using StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if VIDEO_PLUGIN
import vlc.MP4Handler;
#end


class PlayState extends MusicBeatState
{
	public static var startTimer:FlxTimer;

	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 2;
	public static var contents:PlayState;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;

	public static var dadOpponent:Character;
	public static var gf:Character;
	public static var boyfriend:Character;

	public static var assetModifier:String = 'base';
	public static var changeableSkin:String = 'default';
	public static var changeableSound:String = 'default';

	public static var GraphicMap:Map<String, FNFSprite> = new Map<String, FNFSprite>();
	public static var ShaderMap:Map<String, GraphicsShader> = new Map<String, GraphicsShader>();

	public var events:FlxTypedGroup<EventNote> = new FlxTypedGroup<EventNote>();
	public var unspawnEvents:Array<EventNote> = [];

	public var notes:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	public var unspawnNotes:Array<Note> = [];
	
	var ratingArray:Array<String> = [];
	var allSicks:Bool = true;

	// if you ever wanna add more keys
	var numberOfKeys:Int = 4;

	// get it cus release
	// I'm funny just trust me
	var curSection:Int = 0;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	// Discord RPC variables
	public static var songDetails:String = "";
	public static var detailsSub:String = "";
	public static var detailsPausedText:String = "";

	static var prevCamFollow:FlxObject;

	var curSong:String = "";
	var gfSpeed:Int = 1;

	public static var health:Float = 1; // mario
	public static var combo:Int = 0;

	public static var misses:Int = 0;
	public static var ghostMisses:Int = 0;

	public static var deaths:Int = 0;

	public var generatedMusic:Bool = false;
	public var endingSong:Bool = false;

	public var startingSong:Bool = false;
	public var paused:Bool = false;

	var startedCountdown:Bool = false;
	var inCutscene:Bool = false;

	var canPause:Bool = true;

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	public var scriptArray:Array<ScriptHandler> = [];

	// cameras
	public static var camHUD:FlxCamera;
	public static var camGame:FlxCamera;
	public static var camAlt:FlxCamera;
	public static var dialogueHUD:FlxCamera;

	public var camDisplaceX:Float = 0;
	public var camDisplaceY:Float = 0; // might not use depending on result

	public static var cameraSpeed:Float = 1;
	public static var defaultCamZoom:Float = 1.05;
	public static var forceZoom:Array<Float>;

	public static var songScore:Int = 0;
	public static var rank:String = 'N/A';

	var storyDifficultyText:String = "";

	public static var iconRPC:String = "";
	public static var songLength:Float = 0;

	var stageBuild:Stage;

	public static var uiHUD:ClassHUD;
	public static var daPixelZoom:Float = 6;

	// strumlines
	public var dadStrums:Strumline;
	public var bfStrums:Strumline;

	public static var strumLines:FlxTypedGroup<Strumline>;
	public static var strumHUD:FlxCamera;

	var allUIs:Array<FlxCamera> = [];

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo objects in an array
	public static var lastCombo:Array<FlxSprite>;

	public static var preventScoring:Bool = false;
	public static var chartingMode:Bool = false;
	public static var practiceMode:Bool = false;
	public static var scriptDebugMode:Bool = false;

	public static var prevCharter:Int = 0;

	var precacheList:Map<String, String> = new Map<String, String>();

	var canMiss:Bool = true;

	// at the beginning of the playstate
	override public function create()
	{
		super.create();

		// for scripts
		contents = this;

		// reset any values and variables that are static
		songScore = 0;
		rank = 'N/A';
		combo = 0;
		health = 1;
		misses = 0;
		ghostMisses = 0;
		// sets up the combo object array
		lastCombo = [];

		defaultCamZoom = 1.05;
		cameraSpeed = 1;
		forceZoom = [0, 0, 0, 0];

		Timings.callAccuracy();

		assetModifier = 'base';
		changeableSkin = 'default';
		changeableSound = 'default';

		// stop any existing music tracks playing
		Conductor.stopMusic();
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// create the game camera
		camGame = new FlxCamera();

		// create the hud camera (separate so the hud stays on screen)
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		// create an alternative camera, will be used for stuff later
		camAlt = new FlxCamera();
		camAlt.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camAlt, false);

		allUIs.push(camHUD);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		// default song
		if (SONG == null)
			SONG = Song.loadSong('test', 'test');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		setupScripts();

		callFunc('create', null);

		// cache shit
		displayRating('sick', 'early', true);
		popUpCombo(true);

		GameOverSubstate.resetGameOver();

		// set up a class for the stage type in here afterwards
		curStage = "";

		// call the song's stage if it exists
		if (SONG.stage != null)
			curStage = SONG.stage;
		else
			curStage = 'unknown';

		if (Init.trueSettings.get('Stage Opacity') > 0)
		{
			stageBuild = new Stage(PlayState.curStage);
			add(stageBuild);
		}

		var setSpeed = Init.trueSettings.get('Scroll Speed');
		if (Init.trueSettings.get('Use Set Scroll Speed'))
			SONG.speed = setSpeed;

		// set up characters here too
		switch (ChartParser.songType)
		{
			case UNDERSCORE | PSYCH:
				gf = new Character(300, 100, false, SONG.gfVersion);

			case FNF_LEGACY:
				gf = new Character(300, 100, false, stageBuild.returnGFtype(curStage));

			default:
				// blah
		}
		gf.adjustPos = false;
		gf.scrollFactor.set(0.95, 0.95);
		gf.dance(true);

		dadOpponent = new Character(100, 100, false, SONG.player2);
		dadOpponent.dance(true);

		boyfriend = new Character(770, 450, true, SONG.player1);
		boyfriend.dance(true);

		var camPos:FlxPoint = new FlxPoint(gf.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

		if (Init.trueSettings.get('Stage Opacity') > 0)
		{
			stageBuild.repositionPlayers(curStage, boyfriend, dadOpponent, gf);
			stageBuild.dadPosition(curStage, boyfriend, dadOpponent, gf, camPos);
		}

		changeableSkin = Init.trueSettings.get("UI Skin");
		changeableSound = Init.trueSettings.get("Hitsound Type");

		if (ChartParser.songType == UNDERSCORE)
			assetModifier = SONG.assetModifier;

		if ((curStage.startsWith("school")) && (ChartParser.songType == FNF_LEGACY))
			assetModifier = 'pixel';

		// add characters
		if (Init.trueSettings.get('Stage Opacity') > 0)
		{
			if (stageBuild.spawnGirlfriend)
				add(gf);

			add(stageBuild.layers);

			add(dadOpponent);
			add(boyfriend);
			add(stageBuild.foreground);
		}

		// force them to dance
		dadOpponent.dance();
		gf.dance();
		boyfriend.dance();

		// set song position before beginning
		Conductor.songPosition = -(Conductor.crochet * 4);

		// EVERYTHING SHOULD GO UNDER THIS, IF YOU PLAN ON SPAWNING SOMETHING LATER ADD IT TO STAGEBUILD OR FOREGROUND
		// darken everything but the arrows and ui via a flxsprite
		var darknessBG:FlxSprite = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		darknessBG.alpha = (100 - Init.trueSettings.get('Stage Opacity')) / 100;
		darknessBG.scrollFactor.set(0, 0);
		add(darknessBG);

		// strum setup
		strumLines = new FlxTypedGroup<Strumline>();

		// generate the song
		generateSong(SONG.song);

		// set the camera position to the center of the stage
		camPos.set(gf.x + (gf.frameWidth / 2), gf.y + (gf.frameHeight / 2));

		// create the game camera
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);
		// check if the camera was following someone previously
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);
		add(camFollowPos);

		// actually set the camera up
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		startingSong = true;
		startedCountdown = true;

		// initialize ui elements
		var bfPlacement = FlxG.width / 2 + (!Init.trueSettings.get('Centered Notefield') ? FlxG.width / 4 : 0);
		var dadPlacement = (FlxG.width / 2) - FlxG.width / 4;

		var strumVertPos = (Init.trueSettings.get('Downscroll') ? FlxG.height - 200 : 0);

		dadStrums = new Strumline(dadPlacement, strumVertPos, this, dadOpponent, false, true, false, 4);
		bfStrums = new Strumline(bfPlacement, strumVertPos, this, boyfriend, true, false, true, 4);

		dadStrums.visible = !Init.trueSettings.get('Centered Notefield');

		strumLines.add(dadStrums);
		strumLines.add(bfStrums);

		// generate a new strum camera
		strumHUD = new FlxCamera();
		strumHUD.bgColor.alpha = 0;
		strumHUD.cameras = [camHUD];
		allUIs.push(strumHUD);

		FlxG.cameras.add(strumHUD, false);

		// set this strumline's camera to the designated camera
		strumLines.cameras = [strumHUD];

		add(strumLines);

		uiHUD = new ClassHUD();
		add(uiHUD);
		uiHUD.cameras = [camHUD];
		//

		// create a hud over the hud camera for dialogue
		dialogueHUD = new FlxCamera();
		dialogueHUD.bgColor.alpha = 0;
		FlxG.cameras.add(dialogueHUD, false);

		//
		keysArray = [
			copyKey(Init.gameControls.get('LEFT')[0]),
			copyKey(Init.gameControls.get('DOWN')[0]),
			copyKey(Init.gameControls.get('UP')[0]),
			copyKey(Init.gameControls.get('RIGHT')[0])
		];

		for (key => type in precacheList)
		{
			// trace('Key $key is type $type');
			switch (type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
				case 'sparrow':
					Paths.getSparrowAtlas(key);
				case 'packer':
					Paths.getPackerAtlas(key);
			}
		}
		Paths.clearUnusedMemory();

		// call the funny intro cutscene depending on the song
		if (!skipCutscenes())
			songIntroCutscene();
		else
			startCountdown();

		if (Init.trueSettings.get('Hitsound Volume') > 0)
			precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');
		precacheList.set('breakfast', 'music');
		precacheList.set('UI/default/alphabet', 'image');

		callFunc('postCreate', null);
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}

	var keysArray:Array<Dynamic>;

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if ((key >= 0)
			&& !bfStrums.autoplay
			&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || Init.trueSettings.get('Controller Mode'))
			&& (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate)))
		{
			if (generatedMusic)
			{
				var previousTime:Float = Conductor.songPosition;
				Conductor.songPosition = Conductor.songMusic.time;
				// improved this a little bit, maybe its a lil
				var possibleNoteList:Array<Note> = [];
				var pressedNotes:Array<Note> = [];

				var coolNote:Note;

				bfStrums.allNotes.forEachAlive(function(daNote:Note)
				{
					if ((daNote.noteData == key) && daNote.canBeHit && !daNote.isSustainNote && !daNote.tooLate && !daNote.wasGoodHit)
						possibleNoteList.push(daNote);
				});

				possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				// if there is a list of notes that exists for that control
				if (possibleNoteList.length > 0)
				{
					var eligable = true;
					var firstNote = true;
					// loop through the possible notes
					for (coolNote in possibleNoteList)
					{
						for (noteDouble in pressedNotes)
						{
							if (Math.abs(noteDouble.strumTime - coolNote.strumTime) < 10)
								firstNote = false;
							else
								eligable = false;
						}

						var gfSec = (SONG.notes[Math.floor(curStep / 16)] != null) && (SONG.notes[Math.floor(curStep / 16)].gfSection);

						if (eligable)
						{
							goodNoteHit(coolNote, (coolNote.gfNote || gfSec ? gf : boyfriend), bfStrums, firstNote); // then hit the note
							pressedNotes.push(coolNote);
						}
						// end of this little check
					}
					//
				}
				else
				{ // else just call bad notes
					ghostMisses++;
					if (!Init.trueSettings.get('Ghost Tapping') && canMiss)
						missNoteCheck(true, key, boyfriend, true);
				}

				Conductor.songPosition = previousTime;
			}

			if (bfStrums.receptors.members[key] != null && bfStrums.receptors.members[key].animation.curAnim.name != 'confirm')
				bfStrums.receptors.members[key].playAnim('pressed');
		}
	}

	public function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate))
		{
			// receptor reset
			if (key >= 0 && bfStrums.receptors.members[key] != null)
				bfStrums.receptors.members[key].playAnim('static');
		}
	}

	function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
						return i;
				}
			}
		}
		return -1;
	}

	override public function destroy()
	{
		callFunc('destroy', null);

		if (!Init.trueSettings.get('Controller Mode'))
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		GraphicMap.clear();
		ShaderMap.clear();

		super.destroy();
	}

	var staticDisplace:Int = 0;

	var lastSection:Int = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		callFunc('update', elapsed);

		if (Init.trueSettings.get('Stage Opacity') > 0)
			stageBuild.stageUpdateConstant(elapsed, boyfriend, gf, dadOpponent);

		if (health > 2)
			health = 2;

		// dialogue checks
		if (dialogueBox != null && dialogueBox.alive)
		{
			// wheee the shift closes the dialogue
			if (FlxG.keys.justPressed.SHIFT)
				dialogueBox.closeDialog();

			// the change I made was just so that it would only take accept inputs
			if (controls.ACCEPT && dialogueBox.textStarted)
			{
				var sound = 'cancelMenu';

				if (dialogueBox.portraitData.confirmSound != null)
					sound = dialogueBox.portraitData.confirmSound;
				
				FlxG.sound.play(Paths.sound(sound));
				dialogueBox.curPage += 1;

				if (dialogueBox.curPage == dialogueBox.dialogueData.dialogue.length)
					dialogueBox.closeDialog();
				else
					dialogueBox.updateDialog();

				// for custom fonts
				if (dialogueBox.boxData.textType == 'custom')
				{
					dialogueBox.alphabetText.finishedLine = false;
					dialogueBox.handSelect.visible = false;
				}
			}
		}

		if (!inCutscene)
		{
			// pause the game if the game is allowed to pause and enter is pressed
			if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
			{
				pauseGame();
			}

			// make sure you're not cheating lol
			if (!isStoryMode)
			{
				// charting state (more on that later)
				if (FlxG.keys.justPressed.SEVEN)
				{
					Conductor.stopMusic();
					chartingMode = true;
					preventScoring = true;
					if (FlxG.keys.pressed.SHIFT)
					{
						prevCharter = 1;
						Main.switchState(this, new ChartingState());
					}
					else
					{
						prevCharter = 0;
						Main.switchState(this, new OriginalChartingState());
					}
				}
				if (FlxG.keys.justPressed.EIGHT)
				{
					var holdingShift = FlxG.keys.pressed.SHIFT;
					var holdingAlt = FlxG.keys.pressed.ALT;

					Conductor.stopMusic();
					Main.switchState(this, new CharacterDebug(holdingShift ? SONG.player1 : holdingAlt ? SONG.gfVersion : SONG.player2, PlayState.curStage));
				}

				if (FlxG.keys.justPressed.FIVE)
				{
					preventScoring = true;
					FlxG.sound.play(Paths.sound('scrollMenu'));
					practiceMode = !practiceMode;
				}

				if (FlxG.keys.justPressed.SIX)
				{
					preventScoring = true;
					FlxG.sound.play(Paths.sound('scrollMenu'));
					bfStrums.autoplay = !bfStrums.autoplay;
					uiHUD.autoplayMark.visible = bfStrums.autoplay;
					uiHUD.autoplayMark.alpha = 1;
					uiHUD.autoplaySine = 0;
				}
			}

			if (startingSong)
			{
				if (startedCountdown)
				{
					Conductor.songPosition += elapsed * 1000;
					if (Conductor.songPosition >= 0)
						startSong();
				}
			}
			else
			{
				Conductor.songPosition += elapsed * 1000;
				if (!paused)
				{
					songTime += FlxG.game.ticks - previousFrameTime;
					previousFrameTime = FlxG.game.ticks;

					// Interpolation type beat
					if (Conductor.lastSongPos != Conductor.songPosition)
					{
						songTime = (songTime + Conductor.songPosition) / 2;
						Conductor.lastSongPos = Conductor.songPosition;
					}
				}
			}

			if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
			{
				var curSection = Std.int(curStep / 16);
				if (curSection != lastSection)
				{
					// section reset stuff
					var lastMustHit:Bool = PlayState.SONG.notes[lastSection].mustHitSection;
					if (PlayState.SONG.notes[curSection].mustHitSection != lastMustHit)
					{
						camDisplaceX = 0;
						camDisplaceY = 0;
					}
					lastSection = Std.int(curStep / 16);
				}

				var mustHit = PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection;
				var gfSection = PlayState.SONG.notes[Std.int(curStep / 16)].gfSection;

				if (!mustHit && !gfSection)
				{
					var char = dadOpponent;

					var getCenterX = char.getMidpoint().x + 100;
					var getCenterY = char.getMidpoint().y - 100;

					camFollow.setPosition(getCenterX + camDisplaceX + char.camOffsets[0], getCenterY + camDisplaceY + char.camOffsets[1]);

					if (char.curCharacter == 'mom')
						Conductor.songVocals.volume = 1;
				}
				else if (mustHit && !gfSection)
				{
					var char = boyfriend;

					var getCenterX = char.getMidpoint().x - 100;
					var getCenterY = char.getMidpoint().y - 100;
					switch (curStage)
					{
						case 'limo':
							getCenterX = char.getMidpoint().x - 300;
						case 'mall':
							getCenterY = char.getMidpoint().y - 200;
						case 'school':
							getCenterX = char.getMidpoint().x - 200;
							getCenterY = char.getMidpoint().y - 200;
						case 'schoolEvil':
							getCenterX = char.getMidpoint().x - 200;
							getCenterY = char.getMidpoint().y - 200;
					}

					camFollow.setPosition(getCenterX + camDisplaceX - char.camOffsets[0], getCenterY + camDisplaceY + char.camOffsets[1]);
				}
				else if (gfSection && !mustHit || gfSection && mustHit)
				{
					var char = gf;

					var getCenterX = char.getMidpoint().x + 100;
					var getCenterY = char.getMidpoint().y - 100;

					camFollow.setPosition(getCenterX + camDisplaceX + char.camOffsets[0], getCenterY + camDisplaceY + char.camOffsets[1]);
				}
			}

			var lerpVal = (elapsed * 2.4) * cameraSpeed;
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

			var easeLerp = 0.95;
			// camera stuffs
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom + forceZoom[0], FlxG.camera.zoom, easeLerp);
			for (hud in allUIs)
				hud.zoom = FlxMath.lerp(1 + forceZoom[1], hud.zoom, easeLerp);

			// not even forcezoom anymore but still
			FlxG.camera.angle = FlxMath.lerp(0 + forceZoom[2], FlxG.camera.angle, easeLerp);
			for (hud in allUIs)
				hud.angle = FlxMath.lerp(0 + forceZoom[3], hud.angle, easeLerp);

			// Controls

			// RESET = Quick Game Over Screen
			if (controls.RESET && !startingSong && !isStoryMode)
			{
				health = 0;
			}
			doGameOverCheck();

			// spawn in the notes from the array
			if ((unspawnNotes[0] != null) && ((unspawnNotes[0].strumTime - Conductor.songPosition) < 3500))
			{
				var dunceNote:Note = unspawnNotes[0];
				// push note to its correct strumline
				strumLines.members[Math.floor((dunceNote.noteData + (dunceNote.mustPress ? 4 : 0)) / numberOfKeys)].push(dunceNote);
				notes.add(dunceNote);
				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}

			if (unspawnEvents[0] != null && unspawnEvents[0].strumTime - Conductor.songPosition < 3500)
			{
				var dunceEvent:EventNote = unspawnEvents[0];
				dunceEvent.visible = false;
				events.add(dunceEvent);
				unspawnEvents.splice(unspawnEvents.indexOf(dunceEvent), 1);
			}

			noteCalls();

			if (Init.trueSettings.get('Controller Mode'))
				controllerInput();
		}

		if (FlxG.keys.justPressed.TWO && !isStoryMode && !startingSong && !endingSong && scriptDebugMode)
		{ // Go 10 seconds into the future, @author Shadow_Mario_
			if (Conductor.songPosition + 10000 < Conductor.songMusic.length)
			{
				canMiss = false;
				preventScoring = true;
				Conductor.songMusic.pause();
				Conductor.songVocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.strumTime - 500 < Conductor.songPosition)
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.alive = false;
						daNote.destroy();
					}
				});

				Conductor.songMusic.time = Conductor.songPosition;
				Conductor.songVocals.time = Conductor.songPosition;

				Conductor.songMusic.play();
				Conductor.songVocals.play();

				new FlxTimer().start(0.6, function(timer:FlxTimer)
				{
					canMiss = true;
				});
			}
		}

		callFunc('postUpdate', null);
	}

	// maybe theres a better place to put this, idk -saw
	function controllerInput()
	{
		var justPressArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
		var justReleaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];

		if (justPressArray.contains(true))
		{
			for (i in 0...justPressArray.length)
			{
				if (justPressArray[i])
					onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
			}
		}

		if (justReleaseArray.contains(true))
		{
			for (i in 0...justReleaseArray.length)
			{
				if (justReleaseArray[i])
					onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
			}
		}
	}

	function noteCalls()
	{
		// reset strums
		for (strumline in strumLines)
		{
			// handle strumline stuffs
			for (uiNote in strumline.receptors)
			{
				if (strumline.autoplay)
					strumCallsAuto(uiNote);
			}

			if (strumline.splashNotes != null)
				for (i in 0...strumline.splashNotes.length)
				{
					strumline.splashNotes.members[i].x = strumline.receptors.members[i].x - 48;
					strumline.splashNotes.members[i].y = strumline.receptors.members[i].y + (UIStaticArrow.swagWidth / 6) - 56;
				}
		}

		// if the song is generated
		if (generatedMusic && startedCountdown)
		{
			for (strumline in strumLines)
			{
				// set the notes x and y
				var downscrollMultiplier = 1;
				if (Init.trueSettings.get('Downscroll'))
					downscrollMultiplier = -1;

				strumline.allNotes.forEachAlive(function(daNote:Note)
				{
					var roundedSpeed = FlxMath.roundDecimal(daNote.noteSpeed, 2);
					var receptorPosY:Float = strumline.receptors.members[Math.floor(daNote.noteData)].y + UIStaticArrow.swagWidth / 6;
					var psuedoY:Float = (downscrollMultiplier * -((Conductor.songPosition - daNote.strumTime) * (0.45 * roundedSpeed)));
					var psuedoX = 25 + daNote.noteVisualOffset;

					daNote.y = receptorPosY
						+ (Math.cos(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoY)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoX);
					// painful math equation
					daNote.x = strumline.receptors.members[Math.floor(daNote.noteData)].x
						+ (Math.cos(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoX)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoY);

					// also set note rotation
					daNote.angle = -daNote.noteDirection;

					// shitty note hack I hate it so much
					var center:Float = receptorPosY + UIStaticArrow.swagWidth / 2;
					if (daNote.isSustainNote)
					{
						daNote.y -= ((daNote.height / 2) * downscrollMultiplier);
						if ((daNote.animation.curAnim.name.endsWith('holdend') || daNote.animation.curAnim.name.endsWith('rollend'))
							&& (daNote.prevNote != null))
						{
							daNote.y -= ((daNote.prevNote.height / 2) * downscrollMultiplier);
							if (Init.trueSettings.get('Downscroll'))
							{
								daNote.y += (daNote.height * 2);
								if (daNote.endHoldOffset == Math.NEGATIVE_INFINITY)
								{
									// set the end hold offset yeah I hate that I fix this like this
									daNote.endHoldOffset = (daNote.prevNote.y - (daNote.y + daNote.height));
									// trace(daNote.endHoldOffset);
								}
								else
									daNote.y += daNote.endHoldOffset;
							}
							else // this system is funny like that
								daNote.y += ((daNote.height / 2) * downscrollMultiplier);
						}

						if (Init.trueSettings.get('Downscroll'))
						{
							daNote.flipY = true;
							if ((daNote.parentNote != null && daNote.parentNote.wasGoodHit)
								&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if ((daNote.parentNote != null && daNote.parentNote.wasGoodHit)
								&& daNote.y + daNote.offset.y * daNote.scale.y <= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;
								daNote.clipRect = swagRect;
							}
						}
					}

					// hell breaks loose here, we're using nested scripts!
					mainControls(daNote, strumline.character, strumline, strumline.autoplay);

					// check where the note is and make sure it is either active or inactive
					if (daNote.y > FlxG.height)
					{
						daNote.active = false;
						daNote.visible = false;
					}
					else
					{
						daNote.visible = true;
						daNote.active = true;
					}

					if (!daNote.tooLate && daNote.strumTime < Conductor.songPosition - (Timings.msThreshold) && !daNote.wasGoodHit)
					{
						if ((!daNote.tooLate) && (daNote.mustPress) && (!daNote.badNote))
						{
							if (!daNote.isSustainNote)
							{
								daNote.tooLate = true;
								for (note in daNote.childrenNotes)
									note.tooLate = true;

								Conductor.songVocals.volume = 0;
								if (canMiss)
									missNoteCheck((Init.trueSettings.get('Ghost Tapping')) ? true : false, daNote.noteData, boyfriend, true);
								// ambiguous name
								Timings.updateAccuracy(0);
							}
							else if (daNote.isSustainNote)
							{
								if (daNote.parentNote != null)
								{
									var parentNote = daNote.parentNote;
									if (!parentNote.tooLate)
									{
										var breakFromLate:Bool = false;
										for (note in parentNote.childrenNotes)
										{
											// trace('hold amount ${parentNote.childrenNotes.length}, note is late?' + note.tooLate + ', ' + breakFromLate);
										}

										if (!breakFromLate)
										{
											if (canMiss)
												missNoteCheck((Init.trueSettings.get('Ghost Tapping')) ? true : false, daNote.noteData, boyfriend, true);
											for (note in parentNote.childrenNotes)
												note.tooLate = true;
										}
										//
									}
								}
							}
						}
					}

					// if the note is off screen (above)
					if ((((!Init.trueSettings.get('Downscroll')) && (daNote.y < -daNote.height))
						|| ((Init.trueSettings.get('Downscroll')) && (daNote.y > (FlxG.height + daNote.height))))
						&& (daNote.tooLate || daNote.wasGoodHit))
						destroyNote(strumline, daNote);
				});

				// unoptimised asf camera control based on strums
				strumCameraRoll(strumline.receptors, (strumline == bfStrums));

				searchUnspawnEvents();
			}
		}

		// reset bf's animation
		var holdControls:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		if ((boyfriend != null && boyfriend.animation != null)
			&& (boyfriend.holdTimer > Conductor.stepCrochet * (4 / 1000) && (!holdControls.contains(true) || bfStrums.autoplay)))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}
	}

	/**
	 * a function to switch characters during songs!
	 * @param `newCharacter` [your character of choice to switch to, ex: `bf-psych`];
	 * @param `targetCharacter` [should be either `boyfriend`, `dadOpponent`, or `girlfriend`];
	 * @param `x` [the X position for the New Character];
	 * @param `y` [the Y position for the New Character];
	**/
	public function changeCharacter(newCharacter:String, targetCharacter:String, x:Float, y:Float)
	{
		var charType:Int = 0;
		switch (targetCharacter)
		{
			case 'dad' | 'opponent' | 'dadOpponent':
				charType = 1;
			case 'gf' | 'girlfriend' | 'player3':
				charType = 2;
			case 'boyfriend' | 'bf' | 'player':
				charType = Std.parseInt(targetCharacter);
				if (Math.isNaN(charType))
					charType = 0;
			default:
				charType = Std.parseInt(targetCharacter);
				if (Math.isNaN(charType))
					charType = 0;
		}

		switch (charType)
		{
			case 0:
				boyfriend.setCharacter(x, y, newCharacter);
				uiHUD.iconP1.updateIcon(newCharacter, true);
				uiHUD.updateBar();
			case 1:
				dadOpponent.setCharacter(x, y, newCharacter);
				uiHUD.iconP2.updateIcon(newCharacter, false);
				uiHUD.updateBar();
			case 2:
				gf.setCharacter(x, y, newCharacter);
		}
	}

	function destroyNote(strumline:Strumline, daNote:Note)
	{
		daNote.active = false;
		daNote.exists = false;

		var chosenGroup = (daNote.isSustainNote ? strumline.holdsGroup : strumline.notesGroup);
		// note damage here I guess
		daNote.kill();
		if (strumline.allNotes.members.contains(daNote))
			strumline.allNotes.remove(daNote, true);
		if (chosenGroup.members.contains(daNote))
			chosenGroup.remove(daNote, true);
		daNote.destroy();
	}

	public function searchUnspawnEvents()
	{
		while (unspawnEvents.length > 0)
		{
			var strumTime:Float = unspawnEvents[0].strumTime;
			if (Conductor.songPosition < strumTime)
			{
				break;
			}

			var value1:String = '';
			if (unspawnEvents[0].val1 != null)
				value1 = unspawnEvents[0].val1;

			var value2:String = '';
			if (unspawnEvents[0].val1 != null)
				value2 = unspawnEvents[0].val1;

			eventNoteHit(unspawnEvents[0].eventName, value1, value2);
			unspawnEvents.shift();
		}
	}

	function eventNoteHit(name:String, val1:String, val2:String, ?eventNote:EventNote)
	{
		if (!eventNote.shouldExecute)
			return;

		switch (eventNote.eventName)
		{
			case 'Change Character':
				var ogPosition:Array<Float> = [770, 450];
				switch (eventNote.val2)
				{
					case 'dad' | 'opponent' | 'dadOpponent':
						ogPosition = [100, 100];
					case 'gf' | 'player3' | 'girlfriend':
						ogPosition = [300, 100];
					case 'bf' | 'player' | 'boyfriend':
						ogPosition = [770, 450];
				}
				changeCharacter(eventNote.val1, eventNote.val2, ogPosition[0], ogPosition[1]);

			case 'Set GF Speed':
				var speed:Int = Std.parseInt(eventNote.val1);
				if (Math.isNaN(speed) || speed < 1)
					speed = 1;
				gfSpeed = speed;

			case 'Hey!':
				var who:Int = -1;
				switch (eventNote.val1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | 'player':
						who = 0;
					case 'gf' | 'girlfriend' | 'player3':
						who = 1;
				}

				var tmr:Float = Std.parseFloat(eventNote.val2);
				if (Math.isNaN(tmr) || tmr <= 0)
					tmr = 0.6;

				if (who != 0)
				{
					if (dadOpponent.curCharacter.startsWith('gf'))
					{
						dadOpponent.playAnim('cheer', true);
						dadOpponent.specialAnim = true;
						dadOpponent.heyTimer = tmr;
					}
					else if (gf != null)
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = tmr;
					}
				}
				if (who != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = tmr;
				}

			case 'Play Animation':
				var char:Character = dadOpponent;
				switch (eventNote.val2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(eventNote.val2);
						if (Math.isNaN(val2))
							val2 = 0;

						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(eventNote.val1, true);
					char.specialAnim = true;
				}
		}
	}

	function goodNoteHit(coolNote:Note, character:Character, characterStrums:Strumline, ?canDisplayJudgement:Bool = true)
	{
		if (!coolNote.wasGoodHit)
		{
			callFunc('goodNoteHit', coolNote);

			coolNote.wasGoodHit = true;
			Conductor.songVocals.volume = 1;

			coolNote.goodNoteHit(coolNote);

			characterPlayAnimation(coolNote, character);

			if (characterStrums.receptors.members[coolNote.noteData] != null)
				characterStrums.receptors.members[coolNote.noteData].playAnim('confirm', true);

			// special thanks to sam, they gave me the original system which kinda inspired my idea for this new one
			if (canDisplayJudgement)
			{
				// get the note ms timing
				var noteDiff:Float = Math.abs(coolNote.strumTime - Conductor.songPosition);
				// get the timing
				if (coolNote.strumTime < Conductor.songPosition)
					ratingTiming = "late";
				else
					ratingTiming = "early";

				// loop through all avaliable judgements
				var foundRating:String = 'miss';
				var lowestThreshold:Float = Math.POSITIVE_INFINITY;
				for (myRating in Timings.judgementsMap.keys())
				{
					var myThreshold:Float = Timings.judgementsMap.get(myRating)[1];
					if (noteDiff <= myThreshold && (myThreshold < lowestThreshold))
					{
						foundRating = myRating;
						lowestThreshold = myThreshold;
					}
				}

				if (!coolNote.badNote)
				{
					if (!coolNote.isSustainNote)
					{
						increaseCombo(foundRating, coolNote.noteData, character);
						popUpScore(foundRating, ratingTiming, characterStrums, coolNote);

						if (coolNote.childrenNotes.length > 0)
							Timings.notesHit++;

						healthCall(Timings.judgementsMap.get(foundRating)[3]);
					}
					else
					{
						// call updated accuracy stuffs
						if (coolNote.parentNote != null)
						{
							Timings.updateAccuracy(100, true, coolNote.parentNote.childrenNotes.length);
							healthCall(100 / coolNote.parentNote.childrenNotes.length);
						}
					}
				}
			}

			if (!coolNote.isSustainNote)
				destroyNote(characterStrums, coolNote);
		}
	}

	public function missNoteCheck(?includeAnimation:Bool = false, direction:Int = 0, character:Character, popMiss:Bool = false, lockMiss:Bool = false)
	{
		callFunc('missNoteCheck', null);

		if (includeAnimation)
		{
			var stringDirection:String = UIStaticArrow.getArrowFromNumber(direction);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			character.playAnim('sing' + stringDirection.toUpperCase() + 'miss', lockMiss);
		}
		decreaseCombo(popMiss);
	}

	public function characterPlayAnimation(coolNote:Note, character:Character)
	{
		// alright so we determine which animation needs to play
		// get alt strings and stuffs
		var stringArrow:String = '';
		var altString:String = '';

		var baseString = 'sing' + UIStaticArrow.getArrowFromNumber(coolNote.noteData).toUpperCase();

		// I tried doing xor and it didnt work lollll
		if (coolNote.noteAlt > 0)
			altString = '-alt';

		if (((SONG.notes[Math.floor(curStep / 16)] != null) && (SONG.notes[Math.floor(curStep / 16)].altAnim))
			&& (character.animOffsets.exists(baseString + '-alt')))
		{
			if (altString != '-alt')
				altString = '-alt';
			else
				altString = '';
		}

		if (coolNote.fullString != null)
			stringArrow = coolNote.fullString;
		altString = coolNote.altString;

		switch (coolNote.noteType)
		{
			case 3:
				character.specialAnim = true;
				character.heyTimer = 0.6;
			case 4:
				stringArrow = '';
				altString = '';
			case 5:
				if (character.curCharacter == 'bf-psych')
					stringArrow = 'hurt';
				else
					stringArrow = baseString + 'miss';
				character.specialAnim = true;
				character.heyTimer = 0.6;

			default:
				stringArrow = baseString + altString;
		}

		character.playAnim(stringArrow, true);
		character.holdTimer = 0;
	}

	function strumCallsAuto(cStrum:UIStaticArrow, ?callType:Int = 1, ?daNote:Note):Void
	{
		switch (callType)
		{
			case 1:
				// end the animation if the calltype is 1 and it is done
				if ((cStrum.animation.finished) && (cStrum.canFinishAnimation))
					cStrum.playAnim('static');
			default:
				// check if it is the correct strum
				if (daNote.noteData == cStrum.ID)
				{
					// if (cStrum.animation.curAnim.name != 'confirm')
					cStrum.playAnim('confirm'); // play the correct strum's confirmation animation (haha rhymes)

					// stuff for sustain notes
					if ((daNote.isSustainNote) && (!daNote.animation.curAnim.name.endsWith('holdend')))
						cStrum.canFinishAnimation = false; // basically, make it so the animation can't be finished if there's a sustain note below
					else
						cStrum.canFinishAnimation = true;
				}
		}
	}

	function mainControls(daNote:Note, char:Character, strumline:Strumline, autoplay:Bool):Void
	{
		var notesPressedAutoplay = [];

		// here I'll set up the autoplay functions
		if (autoplay)
		{
			// check if the note was a good hit
			if (daNote.strumTime <= Conductor.songPosition && !daNote.badNote)
			{
				// kill the note, then remove it from the array
				var canDisplayJudgement = false;
				if (strumline.displayJudgements)
				{
					canDisplayJudgement = true;
					for (noteDouble in notesPressedAutoplay)
					{
						if (noteDouble.noteData == daNote.noteData)
						{
							canDisplayJudgement = false;
						}
					}
					notesPressedAutoplay.push(daNote);
				}

				var curSection = Std.int(curStep / 16);

				var gfSec = (SONG.notes[Math.floor(curStep / 16)] != null) && (SONG.notes[Math.floor(curStep / 16)].gfSection);

				if (daNote.gfNote || gfSec)
					char = gf;

				goodNoteHit(daNote, char, strumline, canDisplayJudgement);
			}
			//
		}

		var holdControls:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		if (!autoplay)
		{
			// check if anything is held
			if (holdControls.contains(true))
			{
				// check notes that are alive
				strumline.allNotes.forEachAlive(function(coolNote:Note)
				{
					if ((coolNote.parentNote != null && coolNote.parentNote.wasGoodHit)
						&& coolNote.canBeHit
						&& coolNote.mustPress
						&& !coolNote.tooLate
						&& coolNote.isSustainNote
						&& holdControls[coolNote.noteData])
						goodNoteHit(coolNote, char, strumline);
				});
			}
		}
	}

	function strumCameraRoll(cStrum:FlxTypedSpriteGroup<UIStaticArrow>, mustHit:Bool)
	{
		if (!Init.trueSettings.get('No Camera Note Movement'))
		{
			var camDisplaceExtend:Float = 15;
			if (PlayState.SONG.notes[Std.int(curStep / 16)] != null)
			{
				if ((PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && mustHit)
					|| (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && !mustHit))
				{
					camDisplaceX = 0;
					if (cStrum.members[0].animation.curAnim.name == 'confirm')
						camDisplaceX -= camDisplaceExtend;
					if (cStrum.members[3].animation.curAnim.name == 'confirm')
						camDisplaceX += camDisplaceExtend;

					camDisplaceY = 0;
					if (cStrum.members[1].animation.curAnim.name == 'confirm')
						camDisplaceY += camDisplaceExtend;
					if (cStrum.members[2].animation.curAnim.name == 'confirm')
						camDisplaceY -= camDisplaceExtend;
				}
			}
		}
		//
	}

	public function pauseGame()
	{
		callFunc('pauseGame', null);

		// pause discord rpc
		updateRPC(true);

		// pause game
		paused = true;

		// update drawing stuffs
		persistentUpdate = false;
		persistentDraw = true;

		// stop all tweens and timers
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
		{
			if (!tmr.finished)
				tmr.active = false;
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween)
		{
			if (!twn.finished)
				twn.active = false;
		});

		// open pause substate
		openSubState(new PauseSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
	}

	override public function onFocus():Void
	{
		if (!paused)
			updateRPC(false);
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (canPause && !paused && !inCutscene && !bfStrums.autoplay && !Init.trueSettings.get('Auto Pause'))
			pauseGame();
		super.onFocusLost();
	}

	public static function updateRPC(pausedRPC:Bool)
	{
		#if DISCORD_RPC
		var displayRPC:String = (pausedRPC) ? detailsPausedText : songDetails;

		if (health > 0)
		{
			if (Conductor.songPosition > 0 && !pausedRPC)
				Discord.changePresence(displayRPC, detailsSub, iconRPC, true, songLength - Conductor.songPosition);
			else
				Discord.changePresence(displayRPC, detailsSub, iconRPC);
		}
		#end
	}

	var animationsPlay:Array<Note> = [];

	var ratingTiming:String = "";

	function popUpScore(baseRating:String, timing:String, strumline:Strumline, coolNote:Note)
	{
		// set up the rating
		var score:Int = 50;

		// create the note splash if you hit a sick
		if (baseRating == "sick")
			createSplash(coolNote, strumline);
		else
			// if it isn't a sick, and you had a sick combo, then it becomes not sick :(
			if (allSicks)
				allSicks = false;

		displayRating(baseRating, timing);
		Timings.updateAccuracy(Timings.judgementsMap.get(baseRating)[3]);
		score = Std.int(Timings.judgementsMap.get(baseRating)[2]);

		if (!practiceMode)
			songScore += score;

		popUpCombo();
	}

	public function createSplash(coolNote:Note, strumline:Strumline)
	{
		// play animation in existing notesplashes
		var noteSplashRandom:String = (Std.string((FlxG.random.int(0, 1) + 1)));
		if (strumline.splashNotes != null)
			strumline.splashNotes.members[coolNote.noteData].playAnim('anim' + noteSplashRandom, true);
	}

	var createdColor = FlxColor.fromRGB(204, 66, 66);

	function popUpCombo(?cache:Bool = false)
	{
		var comboString:String = Std.string(combo);
		var negative = false;
		if ((comboString.startsWith('-')) || (combo == 0))
			negative = true;
		var stringArray:Array<String> = comboString.split("");
		// deletes all combo sprites prior to initalizing new ones
		if (lastCombo != null)
		{
			while (lastCombo.length > 0)
			{
				lastCombo[0].kill();
				lastCombo.remove(lastCombo[0]);
			}
		}

		for (scoreInt in 0...stringArray.length)
		{
			// numScore.loadGraphic(Paths.image('UI/' + pixelModifier + 'num' + stringArray[scoreInt]));
			var numScore = ForeverAssets.generateCombo('combo', stringArray[scoreInt], (!negative ? allSicks : false), assetModifier, changeableSkin, 'UI',
				negative, createdColor, scoreInt);
			add(numScore);
			setVar('numScore', numScore);
			// hardcoded lmao
			if (!Init.trueSettings.get('Simply Judgements'))
			{
				add(numScore);
				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						numScore.kill();
					},
					startDelay: Conductor.crochet * 0.002
				});
			}
			else
			{
				add(numScore);
				// centers combo
				numScore.y += 10;
				numScore.x -= 95;
				numScore.x -= ((comboString.length - 1) * 22);
				lastCombo.push(numScore);
				FlxTween.tween(numScore, {y: numScore.y + 20}, 0.1, {type: FlxTweenType.BACKWARD, ease: FlxEase.circOut});
				/*FlxTween.tween(numScore, {"scale.x": 0, "scale.y": 0}, 0.1, {
					onComplete: function(tween:FlxTween)
					{
						rating.kill();
					},
					startDelay: Conductor.crochet * 0.00125
				});*/
			}
			// hardcoded lmao
			if (Init.trueSettings.get('Fixed Judgements'))
			{
				if (!cache)
					numScore.cameras = [camHUD];
				numScore.y += 50;
			}
			numScore.x += 100;
		}
	}

	public function decreaseCombo(?popMiss:Bool = false)
	{
		if (combo > 5 && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');

		if (combo > 0)
			combo = 0; // bitch lmao
		else
			combo--;

		// misses
		if (!practiceMode)
			songScore -= 10;

		if (!endingSong)
			misses++;

		// display negative combo
		if (popMiss)
		{
			// doesnt matter miss ratings dont have timings
			displayRating("miss", 'late');
			healthCall(Timings.judgementsMap.get("miss")[3]);
		}

		popUpCombo();

		// gotta do it manually here lol
		Timings.updateFCDisplay();
	}

	function increaseCombo(?baseRating:String, ?direction = 0, ?character:Character)
	{
		// trolled this can actually decrease your combo if you get a bad/shit/miss
		if (baseRating != null)
		{
			if (Timings.judgementsMap.get(baseRating)[3] > 0)
			{
				if (combo < 0)
					combo = 0;
				combo += 1;
			}
			else if (canMiss)
				missNoteCheck(true, direction, character, false, true);
		}
	}

	public function displayRating(daRating:String, timing:String, ?cache:Bool = false)
	{
		/* so you might be asking
			"oh but if the rating isn't sick why not just reset it"
			because miss judgements can pop, and they dont mess with your sick combo
		 */
		var rating = ForeverAssets.generateRating('$daRating', (daRating == 'sick' ? allSicks : false), timing, assetModifier, changeableSkin, 'UI');
		add(rating);
		setVar('rating', rating);

		if (!Init.trueSettings.get('Simply Judgements'))
		{
			add(rating);

			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					rating.kill();
				},
				startDelay: Conductor.crochet * 0.00125
			});
		}
		else
		{
			if (lastRating != null)
			{
				lastRating.kill();
			}
			add(rating);
			lastRating = rating;
			FlxTween.tween(rating, {y: rating.y + 20}, 0.2, {type: FlxTweenType.BACKWARD, ease: FlxEase.circOut});
			FlxTween.tween(rating, {"scale.x": 0, "scale.y": 0}, 0.1, {
				onComplete: function(tween:FlxTween)
				{
					rating.kill();
				},
				startDelay: Conductor.crochet * 0.00125
			});
		}
		// */

		if (!cache)
		{
			if (Init.trueSettings.get('Fixed Judgements'))
			{
				// bound to camera
				rating.cameras = [camHUD];
				rating.screenCenter();
			}

			// return the actual rating to the array of judgements
			Timings.gottenJudgements.set(daRating, Timings.gottenJudgements.get(daRating) + 1);

			// set new smallest rating
			if (Timings.smallestRating != daRating)
			{
				if (Timings.judgementsMap.get(Timings.smallestRating)[0] < Timings.judgementsMap.get(daRating)[0])
					Timings.smallestRating = daRating;
			}
		}
	}

	function healthCall(?ratingMultiplier:Float = 0)
	{
		// health += 0.012;
		var healthBase:Float = 0.06;
		health += (healthBase * (ratingMultiplier / 100));
	}

	function startSong():Void
	{
		callFunc('startSong', null);

		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		// FlxTween.tween(uiHUD.centerMark, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		if (!paused)
		{
			Conductor.startMusic(endSong.bind());

			#if DISCORD_RPC
			// Song duration in a float, useful for the time left feature
			songLength = Conductor.songMusic.length;

			// Updating Discord Rich Presence (with Time Left)
			updateRPC(false);
			#end
		}
	}

	function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		songDetails = CoolUtil.dashToSpace(SONG.song) + ' [' + CoolUtil.difficultyFromNumber(storyDifficulty) + '] - by ' + SONG.author;

		detailsPausedText = "Paused - " + songDetails;
		detailsSub = "";

		updateRPC(false);

		curSong = songData.song;

		// call song
		Conductor.bindMusic();

		// generate the chart and sort through notes
		unspawnNotes = ChartParser.loadChart(SONG, ChartParser.songType);
		unspawnEvents = ChartParser.loadEvents(SONG, ChartParser.songType);

		unspawnNotes.sort(sortByShit);

		if (unspawnEvents.length > 1)
		{
			unspawnEvents.sort(sortByEvent);
		}
		searchUnspawnEvents();
		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function sortByEvent(event1:EventNote, event2:EventNote):Int
		return FlxSort.byValues(FlxSort.ASCENDING, event1.strumTime, event2.strumTime);

	override function stepHit()
	{
		super.stepHit();

		Conductor.resyncBySteps();

		callFunc('stepHit', curStep);
	}

	public var characterArray:Array<Character> = [];
	function charactersDance(curBeat:Int)
	{
		if (curBeat % Math.round(gfSpeed * gf.bopSpeed) == 0
			&& gf.animation.curAnim != null
			&& !gf.animation.curAnim.name.startsWith('sing')
			&& gf.animation.curAnim.name.startsWith("idle")
			|| gf.animation.curAnim.name.startsWith("dance")
			&& !gf.stunned)
			gf.dance();

		if (curBeat % boyfriend.bopSpeed == 0
			&& boyfriend.animation.curAnim != null
			&& !boyfriend.animation.curAnim.name.startsWith('sing')
			&& boyfriend.animation.curAnim.name.startsWith("idle")
			|| boyfriend.animation.curAnim.name.startsWith("dance")
			|| boyfriend.quickDancer
			&& !boyfriend.stunned)
			boyfriend.dance();

		if (curBeat % boyfriend.bopSpeed == 0
			&& dadOpponent.animation.curAnim != null
			&& !dadOpponent.animation.curAnim.name.startsWith('sing')
			&& dadOpponent.animation.curAnim.name.startsWith("idle")
			|| dadOpponent.animation.curAnim.name.startsWith("dance")
			|| dadOpponent.quickDancer
			&& !dadOpponent.stunned)
			dadOpponent.dance();

		for (char in characterArray)
		{
			if (!char.animation.curAnim.name.startsWith('sing')
				&& char.animation.curAnim.name.startsWith("idle")
				|| char.animation.curAnim.name.startsWith("dance")
				&& curBeat % dadOpponent.bopSpeed == 0
				|| char.quickDancer)
				char.dance();
		}
	}

	public var isDead:Bool = false;

	function doGameOverCheck()
	{
		callFunc('doGameOverCheck', null);

		if (!practiceMode && health <= 0 && !isDead)
		{
			paused = true;
			// startTimer.active = false;
			persistentUpdate = false;
			persistentDraw = false;

			Conductor.stopMusic();

			deaths += 1;

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			FlxG.sound.play(Paths.sound(GameOverSubstate.deathSound));

			#if DISCORD_RPC
			Discord.changePresence("Game Over - " + songDetails, detailsSub, iconRPC);
			#end
			isDead = true;
			return true;
		}
		return false;
	}

	override function beatHit()
	{
		super.beatHit();

		if ((FlxG.camera.zoom < 1.35 && curBeat % 4 == 0) && (!Init.trueSettings.get('Reduced Movements')))
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.05;
			strumHUD.zoom += 0.05;
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
			}
		}

		uiHUD.beatHit();

		charactersDance(curBeat);

		// stage stuffs
		if (Init.trueSettings.get('Stage Opacity') > 0)
			stageBuild.stageUpdate(curBeat, boyfriend, gf, dadOpponent);

		callFunc('beatHit', curBeat);
	}

	//
	//
	/// substate stuffs
	//
	//

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			Conductor.pauseMusic();
		}

		// trace('open substate');
		super.openSubState(SubState);
		// trace('open substate end ');
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (Conductor.songMusic != null && !startingSong)
				Conductor.resyncVocals();

			// if ((startTimer != null) && (!startTimer.finished))
			//	startTimer.active = true;
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
			{
				if (!tmr.finished)
					tmr.active = true;
			});

			FlxTween.globalManager.forEach(function(twn:FlxTween)
			{
				if (!twn.finished)
					twn.active = true;
			});
			paused = false;

			///*
			updateRPC(false);
			// */
		}

		Paths.clearUnusedMemory();

		callFunc('closeSubState', null);

		super.closeSubState();
	}

	/*
		Extra functions and stuffs
	 */
	/// song end function at the end of the playstate lmao ironic I guess
	var endSongEvent:Bool = false;

	function endSong():Void
	{
		callFunc('endSong', null);

		if (!canMiss)
			health = 0;

		// set ranking
		rank = Timings.returnScoreRating().toUpperCase();

		canPause = false;
		endingSong = true;

		Conductor.songMusic.volume = 0;
		Conductor.songVocals.volume = 0;

		deaths = 0;

		if (SONG.validScore && !preventScoring)
		{
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);
			Highscore.saveRank(SONG.song, rank, storyDifficulty);
		}

		if (chartingMode)
			Main.switchState(this, (prevCharter == 1 ? new ChartingState() : new OriginalChartingState()));
		else if (!isStoryMode)
			Main.switchState(this, new FreeplayState());
		else
		{
			// set the campaign's score higher
			campaignScore += songScore;
			campaignMisses += misses;

			// remove a song from the story playlist
			storyPlaylist.remove(storyPlaylist[0]);

			// check if there aren't any songs left
			if ((storyPlaylist.length <= 0) && (!endSongEvent))
			{
				// play menu music
				ForeverTools.resetMenuMusic();

				// set up transitions
				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				// change to the menu state
				Main.switchState(this, new StoryMenuState());

				// save the week's score if the score is valid
				if (SONG.validScore && !preventScoring)
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);

				// flush the save
				FlxG.save.flush();
			}
			else
				songEndSpecificActions();
		}
		//
	}

	function songEndSpecificActions()
	{
		switch (SONG.song.toLowerCase())
		{
			case 'eggnog':
				// make the lights go out
				var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
					-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
				blackShit.scrollFactor.set();
				add(blackShit);
				camHUD.visible = false;

				// oooo spooky
				FlxG.sound.play(Paths.sound('Lights_Shut_off'));

				// call the song end
				new FlxTimer().start(Conductor.crochet / 1000, function(timer:FlxTimer)
				{
					callDefaultSongEnd();
				}, 1);

			default:
				callDefaultSongEnd();
		}
	}

	function callDefaultSongEnd()
	{
		var difficulty:String = '-' + CoolUtil.difficultyFromNumber(storyDifficulty).toLowerCase();
		difficulty = difficulty.replace('-normal', '');

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		PlayState.SONG = Song.loadSong(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
		Conductor.killMusic();

		// deliberately did not use the main.switchstate as to not unload the assets
		FlxG.switchState(new PlayState());
	}

	public function playVideo(name:String)
	{
		#if VIDEO_PLUGIN
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:MP4Handler = new MP4Handler();
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if (endingSong)
			endSong();
		else
			callTextbox();
	}

	var dialogueBox:DialogueBox;

	public function songIntroCutscene()
	{
		callFunc('songIntroCutscene', null);
		switch (curSong.toLowerCase())
		{
			case "winter-horrorland":
				inCutscene = true;
				var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				add(blackScreen);
				blackScreen.scrollFactor.set();
				camHUD.visible = false;

				new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					remove(blackScreen);
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					camFollow.y = -2050;
					camFollow.x += 200;
					FlxG.camera.focusOn(camFollow.getPosition());
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				});
			case 'roses':
				// the same just play angery noise LOL
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
				callTextbox();
			case 'thorns':
				inCutscene = true;
				for (hud in allUIs)
					hud.visible = false;

				var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
				red.scrollFactor.set();

				var senpaiEvil:FlxSprite = new FlxSprite();
				senpaiEvil.frames = Paths.getSparrowAtlas('cutscene/senpai/senpaiCrazy');
				senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
				senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
				senpaiEvil.scrollFactor.set();
				senpaiEvil.updateHitbox();
				senpaiEvil.screenCenter();

				add(red);
				add(senpaiEvil);
				senpaiEvil.alpha = 0;
				new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
				{
					senpaiEvil.alpha += 0.15;
					if (senpaiEvil.alpha < 1)
						swagTimer.reset();
					else
					{
						senpaiEvil.animation.play('idle');
						FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
						{
							remove(senpaiEvil);
							remove(red);
							FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
							{
								for (hud in allUIs)
									hud.visible = true;
								callTextbox();
							}, true);
						});
						new FlxTimer().start(3.2, function(deadTime:FlxTimer)
						{
							FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
						});
					}
				});

			default:
				callTextbox();
		}
	}

	function callTextbox()
	{
		var dialogPath = Paths.json(SONG.song.toLowerCase() + '/dialogue');
		if (sys.FileSystem.exists(dialogPath))
		{
			startedCountdown = false;

			dialogueBox = DialogueBox.createDialogue(sys.io.File.getContent(dialogPath));
			dialogueBox.cameras = [dialogueHUD];
			dialogueBox.whenDaFinish = startCountdown;

			add(dialogueBox);
		}
		else
			startCountdown();
	}

	public static function skipCutscenes():Bool
	{
		// pretty messy but an if statement is messier
		if (Init.trueSettings.get('Skip Text') != null && Std.isOfType(Init.trueSettings.get('Skip Text'), String))
		{
			switch (cast(Init.trueSettings.get('Skip Text'), String))
			{
				case 'never':
					return false;
				case 'freeplay only':
					if (!isStoryMode)
						return true;
					else
						return false;
				default:
					return true;
			}
		}
		return false;
	}

	public static var swagCounter:Int = 0;

	function startCountdown():Void
	{
		inCutscene = false;
		Conductor.songPosition = -(Conductor.crochet * 5);
		swagCounter = 0;

		camHUD.visible = true;

		callFunc('startCountdown', null);

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			startedCountdown = true;

			charactersDance(curBeat);

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', [
				ForeverTools.returnSkinAsset('ready', assetModifier, changeableSkin, 'UI'),
				ForeverTools.returnSkinAsset('set', assetModifier, changeableSkin, 'UI'),
				ForeverTools.returnSkinAsset('go', assetModifier, changeableSkin, 'UI')
			]);

			var introAlts:Array<String> = introAssets.get('default');
			for (value in introAssets.keys())
			{
				if (value == PlayState.curStage)
					introAlts = introAssets.get(value);
			}

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3-' + assetModifier), 0.6);
					Conductor.songPosition = -(Conductor.crochet * 4);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (assetModifier == 'pixel')
						ready.setGraphicSize(Std.int(ready.width * PlayState.daPixelZoom));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2-' + assetModifier), 0.6);
					Conductor.songPosition = -(Conductor.crochet * 3);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();

					if (assetModifier == 'pixel')
						set.setGraphicSize(Std.int(set.width * PlayState.daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1-' + assetModifier), 0.6);
					Conductor.songPosition = -(Conductor.crochet * 2);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();

					if (assetModifier == 'pixel')
						go.setGraphicSize(Std.int(go.width * PlayState.daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo-' + assetModifier), 0.6);
					Conductor.songPosition = -(Conductor.crochet * 1);

				case 4:
					if (!Init.trueSettings.get('Controller Mode'))
					{
						FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
						FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
					}
			}

			callFunc('onCountdownTick', swagCounter);
			swagCounter += 1;
		}, 5);
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}

	public function callFunc(key:String, value:Dynamic)
	{
		for (i in scriptArray)
		{
			if (i.exists(key))
				i.get(key)(value);
		}

		if (generatedMusic)
		{
			ScriptHandler.ScriptFuncs.callBaseVars();
			callPlayStateVars();
		}

		return key;
	}

	public function setVar(key:String, value:Dynamic):Bool
	{
		for (i in scriptArray)
			i.set(key, value);

		return true;
	}

	function setupScripts()
	{
		var fools:Array<String> = [Paths.getPreloadPath('scripts/'), Paths.getPreloadPath('songs/${SONG.song.toLowerCase().replace(' ', '-')}/')];
		var pushedScripts:Array<String> = [];

		#if MOD_HANDLER
		fools.insert(0, Paths.getModPath('scripts', '', ''));
		fools.insert(0, Paths.getModPath('songs/${SONG.song.toLowerCase().replace(' ', '-')}', '', ''));
		fools.insert(0, Paths.getModPath('songs/${SONG.song.toLowerCase().replace(' ', '-')}', '', ''));
		#end

		for (fool in fools)
		{
			if (FileSystem.exists(fool))
			{
				for (file in FileSystem.readDirectory(fool))
				{
					if (file.endsWith('.hx') && !pushedScripts.contains(file))
					{
						scriptArray.push(new ScriptHandler(fool.replace('.', '') + file));
						pushedScripts.push(file);
					}
				}
			}
		}
	}

	function completeTween(id:String)
	{
		callFunc('completeTween', null);
		// add your custom actions for finishing a tween here;
	}

	function callPlayStateVars()
	{
		// PlayState values
		setVar('song', PlayState.SONG);
		setVar('currentSong', PlayState.SONG.song);
		setVar('game', PlayState.contents);
		setVar('stageBuild', stageBuild);
		setVar('cameraSpeed', cameraSpeed);
		setVar('preventScoring', preventScoring);
		setVar('chartingMode', chartingMode);
		setVar('practiceMode', practiceMode);
		setVar('autoplay', bfStrums.autoplay);
		setVar('dadStrums', dadStrums);
		setVar('bfStrums', bfStrums);
		setVar('hud', uiHUD);
		setVar('defaultCamZoom', defaultCamZoom);

		setVar('score', songScore);
		setVar('misses', misses);
		setVar('ghostMisses', ghostMisses);
		setVar('health', health);
		setVar('combo', combo);

		// Character values
		setVar('bf', boyfriend);
		setVar('gf', gf);
		setVar('dad', dadOpponent);

		setVar('boyfriend', boyfriend);
		setVar('girlfriend', gf);
		setVar('dadOpponent', dadOpponent);

		setVar('boyfriendName', boyfriend.curCharacter);
		setVar('girlfriendName', gf.curCharacter);
		setVar('dadOpponentName', dadOpponent.curCharacter);

		setVar('bfName', boyfriend.curCharacter);
		setVar('gfName', gf.curCharacter);
		setVar('dadName', dadOpponent.curCharacter);

		setVar('difficultyString', uiHUD.diffDisplay);
		setVar('songString', uiHUD.infoDisplay);
		setVar('engineString', uiHUD.engineDisplay);

		setVar('camGame', camGame);
		setVar('camAlt', camAlt);
		setVar('camHUD', camHUD);
		setVar('strumHUD', strumHUD);
		setVar('dialogueHUD', dialogueHUD);

		setVar('playVideo', function(key:String)
		{
			playVideo(key);
		});

		setVar('setProperty', function(key:String, value:Dynamic)
		{
			var dotList:Array<String> = key.split('.');

			if (dotList.length > 1)
			{
				var reflector:Dynamic = Reflect.getProperty(this, dotList[0]);

				for (i in 1...dotList.length - 1)
					reflector = Reflect.getProperty(reflector, dotList[i]);

				Reflect.setProperty(reflector, dotList[dotList.length - 1], value);
				return true;
			}

			Reflect.setProperty(this, key, value);
			return true;
		});

		setVar('getProperty', function(variable:String)
		{
			var dotList:Array<String> = variable.split('.');

			if (dotList.length > 1)
			{
				var reflector:Dynamic = Reflect.getProperty(this, dotList[0]);

				for (i in 1...dotList.length - 1)
					reflector = Reflect.getProperty(reflector, dotList[i]);

				return Reflect.getProperty(reflector, dotList[dotList.length - 1]);
			}

			return Reflect.getProperty(this, variable);
		});
	}
}
