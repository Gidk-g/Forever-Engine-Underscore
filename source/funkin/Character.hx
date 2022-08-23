package funkin;

/**
	The character class initialises any and all characters that exist within gameplay. For now, the character class will
	stay the same as it was in the original source of the game. I'll most likely make some changes afterwards though!
**/
import base.*;
import base.ChartParser.Song;
import base.ChartParser.SwagSection;
import base.ChartParser.SwagSong;
import dependency.FNFSprite;
import flixel.FlxG;
import flixel.addons.util.FlxSimplex;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxSort;
import funkin.background.TankmenBG;
import funkin.ui.HealthIcon;
import haxe.Json;
import openfl.Assets;
import openfl.utils.Assets as OpenFlAssets;
import states.PlayState;
import states.substates.GameOverSubstate;
import sys.FileSystem;
import sys.io.File;

using StringTools;

enum CharacterType
{
	SPARROW;
	PACKER;
	HASH;
}

typedef PsychEngineChar =
{
	var animations:Array<PsychAnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Float>;
}

typedef PsychAnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FNFSprite
{
	public var character:String;

	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;

	public var adjustPos:Bool = true;

	public var icon:String;

	public var barColor:Array<Float> = [];
	public var animationNotes:Array<Dynamic> = [];
	public var idlePos:Array<Float> = [0, 0];

	public var offsets:Array<Float> = [0, 0];
	public var camOffsets:Array<Float> = [0, 0];
	public var scales:Array<Float> = [0, 0];

	public var debugMode:Bool = false;
	public var isPlayer:Bool = false;
	public var quickDancer:Bool = false;

	public var scriptArray:Array<ScriptHandler> = [];

	public var idleSuffix:String = '';

	public var stunned:Bool = false;

	public var bopSpeed:Int = 2;

	// FOR PSYCH COMPATIBILITY
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;
	public var specialAnim:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var heyTimer:Float = 0;

	public function new(?x:Float = 0, ?y:Float = 0, ?isPlayer:Bool = false, ?character:String = 'bf')
	{
		super(x, y);
		this.isPlayer = isPlayer;

		setCharacter(x, y, character);
	}

	public function setCharacter(x:Float, y:Float, character:String):Character
	{
		this.character = character;
		curCharacter = character;

		switch (curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
		}

		var psychChar = FileSystem.exists(Paths.getPreloadPath('characters/$character/' + character + '.json'));

		switch (curCharacter)
		{
			// hardcoded (example, in case you want to hardcode characters)
			/*
				case 'bf-og':
					frames = Paths.getSparrowAtlas('characters/base/BOYFRIEND');
					animation.addByPrefix('idle', 'BF idle dance', 24, false);
					animation.addByPrefix('singUP', 'BF NOTE UP0', 24, false);
					animation.addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
					animation.addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
					animation.addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
					animation.addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
					animation.addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
					animation.addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
					animation.addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
					animation.addByPrefix('hey', 'BF HEY', 24, false);
					animation.addByPrefix('scared', 'BF idle shaking', 24);
					animation.addByPrefix('firstDeath', "BF dies", 24, false);
					animation.addByPrefix('deathLoop', "BF Dead Loop", 24, true);
					animation.addByPrefix('deathConfirm', "BF Dead confirm", 24, false);
					playAnim('idle');
					flipX = true;
			 */
			default:
				if (psychChar)
					generatePsychChar(character);
				else
					generateBaseChar(character);
		}

		recalcDance();
		dance();

		return this;
	}

	override function update(elapsed:Float)
	{
		/**
		 * Special Animations Code.
		 * @author: Shadow_Mario_
		**/

		if (!debugMode && animation.curAnim != null)
		{
			if (heyTimer > 0)
			{
				heyTimer -= elapsed;
				if (heyTimer <= 0)
				{
					if (specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			}
			else if (specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			if (!isPlayer)
			{
				if (animation.curAnim != null && animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * 0.0011 * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}
			else if (isPlayer && !skipDance && !specialAnim)
			{
				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}
				else
					holdTimer = 0;

				if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode)
				{
					playAnim('idle', true, false, 10);
				}

				if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished)
				{
					playAnim('deathLoop');
				}
			}

			if (animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}

			switch (curCharacter)
			{
				case 'pico-speaker':
					if (animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
					{
						var noteData:Int = 1;
						if (animationNotes[0][1] > 2)
							noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
					if (animation.curAnim.finished)
						playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			}

			var curCharSimplified:String = simplifyCharacter();

			if (animation.curAnim != null)
				switch (curCharSimplified)
				{
					case 'gf':
						if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
							playAnim('danceRight');
						if ((animation.curAnim.name.startsWith('sad')) && (animation.curAnim.finished))
							playAnim('danceLeft');
				}

			if (animation.curAnim != null && animation.curAnim.finished && animation.curAnim.name == 'idle')
			{
				if (animation.getByName('idlePost') != null)
					animation.play('idlePost', true, false, 0);
			}
		}

		super.update(elapsed);
	}

	var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(?forced:Bool = false)
	{
		if (!debugMode && !skipDance && !specialAnim && animation.curAnim != null)
		{
			var curCharSimplified:String = simplifyCharacter();
			switch (curCharSimplified)
			{
				case 'gf':
					if ((!animation.curAnim.name.startsWith('hair')) && (!animation.curAnim.name.startsWith('sad')))
					{
						danced = !danced;

						if (!danced)
							playAnim('danceLeft$idleSuffix', forced);
						else
							playAnim('danceRight$idleSuffix', forced);
					}
				default:
					// Left/right dancing, think Skid & Pump
					if (animation.getByName('danceLeft$idleSuffix') != null
						&& animation.getByName('danceRight$idleSuffix') != null || danceIdle)
					{
						danced = !danced;
						if (danced)
							playAnim('danceRight$idleSuffix', forced);
						else
							playAnim('danceLeft$idleSuffix', forced);
					}
					else
						playAnim('idle$idleSuffix', forced);
			}
		}
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		if (animation.getByName(AnimName) != null)
			super.playAnim(AnimName, Force, Reversed, Frame);

		if (curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	public function simplifyCharacter():String
	{
		var base = curCharacter;

		if (base.contains('-'))
			base = base.substring(0, base.indexOf('-'));

		return base;
	}

	function loadMappedAnims()
	{
		var sections:Array<SwagSection> = Song.loadSong('picospeaker', PlayState.SONG.song.toLowerCase()).notes;
		for (section in sections)
		{
			for (note in section.sectionNotes)
			{
				animationNotes.push(note);
			}
		}
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private var settingCharacterUp:Bool = true;

	/**
	* for Psych Engine Characters;
	* @author Shadow_Mario_
	**/
	public function recalcDance()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if (settingCharacterUp)
		{
			bopSpeed = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = bopSpeed;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			bopSpeed = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	function generateBaseChar(char:String = 'bf')
	{
		var path:String = Paths.getPreloadPath('characters/$char/config.hx');
		var scripts:Array<String> = [path];

		#if MOD_HANDLER
		scripts.insert(0, Paths.getModPath('characters/$char', 'config', 'hxs'));
		#end

		var pushedScripts:Array<String> = [];

		for (i in scripts)
		{
			if (FileSystem.exists(i) && !pushedScripts.contains(i))
			{
				var script:ScriptHandler = new ScriptHandler(i);

				if (script.interp == null)
				{
					trace("Something terrible occured! Skipping.");
					continue;
				}

				scriptArray.push(script);
				pushedScripts.push(i);
			}
		}

		var spriteType = "sparrow";

		#if MOD_HANDLER
		var modTxtToFind:String = Paths.getModPath('characters/$char', char, 'txt');
		var txtToFind:String = Paths.getPath('characters/$char/$char.txt', TEXT);

		if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
		#else
		if (Assets.exists(Paths.getPath('characters/$char/$char.txt', TEXT)))
		#end
		{
			spriteType = "packer";
		}
		switch (spriteType)
		{
			case "packer":
				frames = Paths.getPackerAtlas(char, 'characters/$char');
			case "sparrow":
				frames = Paths.getSparrowAtlas(char, 'characters/$char');
			case "sparrow-hash":
				frames = Paths.getSparrowHashAtlas(char, 'characters/$char');
		}

		// trace(interp, script);
		setVar('addByPrefix', function(name:String, prefix:String, ?frames:Int = 24, ?loop:Bool = false)
		{
			animation.addByPrefix(name, prefix, frames, loop);
		});

		setVar('addByIndices', function(name:String, prefix:String, indices:Array<Int>, ?frames:Int = 24, ?loop:Bool = false)
		{
			animation.addByIndices(name, prefix, indices, "", frames, loop);
		});

		setVar('addOffset', function(?name:String = "idle", ?x:Float = 0, ?y:Float = 0)
		{
			addOffset(name, x, y);
			if (name == 'idle')
				idlePos = [x, y];
		});

		setVar('set', function(name:String, value:Dynamic)
		{
			Reflect.setProperty(this, name, value);
		});

		setVar('setSingDuration', function(amount:Int)
		{
			singDuration = amount;
		});

		setVar('setOffsets', function(?x:Float = 0, ?y:Float = 0)
		{
			offsets = [x, y];
		});

		setVar('setCamOffsets', function(?x:Float = 0, ?y:Float = 0)
		{
			camOffsets = [x, y];
		});

		setVar('setScale', function(?x:Float = 1, ?y:Float = 1)
		{
			scales = [x, y];
			scale.set(scales[0], scales[1]);
		});

		setVar('setIcon', function(swag:String = 'face') icon = swag);

		setVar('quickDancer', function(quick:Bool = false)
		{
			quickDancer = quick;
		});

		setVar('setBarColor', function(rgb:Array<Float>)
		{
			if (barColor != null)
				barColor = rgb;
			else
				barColor = [161, 161, 161];
			return true;
		});

		setVar('setDeathChar',
			function(char:String = 'bf-dead', lossSfx:String = 'fnf_loss_sfx', song:String = 'gameOver', confirmSound:String = 'gameOverEnd', bpm:Int)
			{
				GameOverSubstate.character = char;
				GameOverSubstate.deathSound = lossSfx;
				GameOverSubstate.deathMusic = song;
				GameOverSubstate.deathConfirm = confirmSound;
				GameOverSubstate.deathBPM = bpm;
			});

		setVar('get', function(variable:String)
		{
			return Reflect.getProperty(this, variable);
		});

		setVar('setGraphicSize', function(width:Int = 0, height:Int = 0)
		{
			setGraphicSize(width, height);
			updateHitbox();
		});

		setVar('playAnim', function(name:String, ?force:Bool = false, ?reversed:Bool = false, ?frames:Int = 0)
		{
			playAnim(name, force, reversed, frames);
		});

		setVar('isPlayer', isPlayer);
		setVar('curStage', PlayState.curStage);
		setVar('song', PlayState.SONG.song.toLowerCase());

		callFunc('loadAnimations', null);

		if (isPlayer) // fuck you ninjamuffin lmao
		{
			flipX = !!flipX;
		}

		if (icon == null)
			icon = char;

		if (adjustPos)
		{
			x += offsets[0];
			#if DEBUG_TRACES trace('character ${curCharacter} scale ${scale.y}'); #end
			y += (offsets[1] - (frameHeight * scale.y));
		}

		if (animation.getByName('danceLeft') != null)
			playAnim('danceLeft');
		else
			playAnim('idle');
	}

	public function callFunc(key:String, value:Dynamic)
	{
		for (i in scriptArray)
		{
			if (i.exists(key))
				i.get(key)(value);
		}

		return key;
	}

	public function setVar(key:String, value:Dynamic):Bool
	{
		for (i in scriptArray)
			i.set(key, value);

		return true;
	}

	public var psychAnimationsArray:Array<PsychAnimArray> = [];

	function generatePsychChar(char:String = 'bf')
	{
		/**
		 * @author Shadow_Mario_
		 */
		var path = Paths.getPreloadPath('characters/$char/' + character + '.json');

		#if MOD_HANDLER
		var rawJson = File.getContent(path);
		#else
		var rawJson = Assets.getText(path);
		#end

		var json:PsychEngineChar = cast Json.parse(rawJson);
		var spriteType = "sparrow";

		#if MOD_HANDLER
		var modTxtToFind:String = Paths.getModPath('characters/$char', json.image, 'txt');
		var txtToFind:String = Paths.getPath('characters/$char/${json.image}.txt', TEXT);

		if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
		#else
		if (Assets.exists(Paths.getPath('characters/$char/${json.image}.txt', TEXT)))
		#end
		{
			spriteType = "packer";
		}

		switch (spriteType)
		{
			case "packer":
				frames = Paths.getPackerAtlas(json.image.replace('characters/', ''), 'characters/$char');
			case "sparrow":
				frames = Paths.getSparrowAtlas(json.image.replace('characters/', ''), 'characters/$char');
			case "sparrow-hash":
				frames = Paths.getSparrowHashAtlas(json.image.replace('characters/', ''), 'characters/$char');
		}

		psychAnimationsArray = json.animations;
		for (anim in psychAnimationsArray)
		{
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; // Bruh
			var animIndices:Array<Int> = anim.indices;
			if (animIndices != null && animIndices.length > 0)
				animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
			else
				animation.addByPrefix(animAnim, animName, animFps, animLoop);

			if (anim.offsets != null && anim.offsets.length > 1)
				addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
		}
		flipX = json.flip_x;
		antialiasing = !json.no_antialiasing;
		offsets = json.position;

		if (isPlayer) // fuck you ninjamuffin lmao
		{
			flipX = !flipX;
		}

		// icon = json.healthicon;
		barColor = json.healthbar_colors;
		singDuration = json.sing_duration;
		scale.set(json.scale, json.scale);
		updateHitbox();

		if (animation.getByName('danceLeft') != null)
			playAnim('danceLeft');
		else
			playAnim('idle');
	}
}
