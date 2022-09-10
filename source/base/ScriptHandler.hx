package base;

import base.*;
import dependency.FNFSprite;
import flixel.*;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.*;
import flixel.system.*;
import flixel.tweens.*;
import flixel.util.*;
import funkin.*;
import lime.app.Application;
import openfl.display.GraphicsShader;
import openfl.filters.ShaderFilter;
import states.PlayState;
import sys.io.File;

class ScriptHandler extends SScript
{
	public function new(file:String, ?preset:Bool = true)
	{
		super(file, preset);
		traces = false;
	}

	override public function preset():Void
	{
		super.preset();

		set('FlxG', FlxG);
		set('FlxBasic', FlxBasic);
		set('FlxObject', FlxObject);
		set('FlxCamera', FlxCamera);
		set('FlxSprite', FlxSprite);
		set('FlxTimer', FlxTimer);
		set('FlxTween', FlxTween);
		set('FlxEase', FlxEase);
		set('FlxMath', FlxMath);
		set('FlxSound', FlxSound);
		set('FlxGroup', FlxGroup);
		set('FlxTypedGroup', FlxTypedGroup);
		set('FlxSpriteGroup', FlxSpriteGroup);
		set('FlxSort', FlxSort);

		set('Note', Note);
		set('Strumline', Strumline);
		set('Conductor', Conductor);
		set('ForeverAssets', ForeverAssets);
		set('ForeverTools', ForeverTools);
	}
}

class ScriptFuncs extends PlayState
{
	public static function setBaseVars()
	{
		PlayState.contents.setVar('fnfVer', Application.current.meta.get('version'));
		PlayState.contents.setVar('foreverVer', Main.foreverVersion);
		PlayState.contents.setVar('underscoreVer', Main.underscoreVersion);

		// Timings.hx values
		PlayState.contents.setVar('comboRating', Timings.comboDisplay);
		PlayState.contents.setVar('accuracy', Timings.accuracy);
		PlayState.contents.setVar('ratingFinal', Timings.ratingFinal);
		PlayState.contents.setVar('trueAccuracy', Timings.trueAccuracy);
		PlayState.contents.setVar('formattedAccuracy', Math.floor(Timings.getAccuracy() * 100) / 100);
		PlayState.contents.setVar('formattedRanking', Timings.returnScoreRating().toUpperCase());

		PlayState.contents.setVar('Paths', Paths);
		PlayState.contents.setVar('Controls', Controls);
		PlayState.contents.setVar('PlayState', PlayState);
		PlayState.contents.setVar('Timings', Timings);

		PlayState.contents.setVar('makeSprite', function(spriteID:String, x:Int = 0, y:Int = 0, graphicCol:Dynamic)
		{
			var newSprite = new FNFSprite();
			newSprite.makeGraphic(x, y, graphicCol);
			newSprite.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
			PlayState.ScriptedGraphics.set(spriteID, newSprite);
			PlayState.contents.setVar('$spriteID', newSprite);
			PlayState.contents.add(newSprite);
		});

		PlayState.contents.setVar('loadSprite', function(spriteID:String, key:String, x:Float, y:Float)
		{
			var newSprite:FNFSprite = new FNFSprite(x, y).loadGraphic(Paths.image(key));
			newSprite.updateHitbox();
			newSprite.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
			PlayState.ScriptedGraphics.set(spriteID, newSprite);
			PlayState.contents.setVar('$spriteID', newSprite);
			PlayState.contents.add(newSprite);
		});

		PlayState.contents.setVar('loadAnimatedSprite',
			function(spriteID:String, key:String, spriteType:String, x:Float = 0, y:Float = 0, spriteAnims:Array<Dynamic>, defAnim:String)
			{
				var newSprite:FNFSprite = new FNFSprite(x, y);

				switch (spriteType)
				{
					case "packer":
						newSprite.frames = Paths.getPackerAtlas(key);
					case "sparrow":
						newSprite.frames = Paths.getSparrowAtlas(key);
					case "sparrow-hash":
						newSprite.frames = Paths.getSparrowHashAtlas(key);
				}

				for (anim in spriteAnims)
				{
					newSprite.animation.addByPrefix(anim[0], anim[1], anim[2], anim[3]);
				}
				newSprite.updateHitbox();
				newSprite.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
				newSprite.animation.play(defAnim);
				PlayState.ScriptedGraphics.set(spriteID, newSprite);
				PlayState.contents.setVar('$spriteID', newSprite);
				PlayState.contents.add(newSprite);
			});
			
		PlayState.contents.setVar('addSpriteAnimation', function(spriteID:String, newAnims:Array<Dynamic>)
		{
			var gottenSprite:FNFSprite = PlayState.ScriptedGraphics.get(spriteID);
			for (anim in newAnims)
			{
				gottenSprite.animation.addByPrefix(anim[0], anim[1], anim[2], anim[3]);
			}
		});

		PlayState.contents.setVar('addSpriteOffset', function(spriteID:String, anim:String, x:Float, y:Float)
		{
			var gottenSprite:FNFSprite = PlayState.ScriptedGraphics.get(spriteID);
			gottenSprite.addOffset(anim, x, y);
		});
		
		PlayState.contents.setVar('spritePlayAnimation', function(spriteID:String, animToPlay:String, forced:Bool = true)
		{
			var gottenSprite:FNFSprite = PlayState.ScriptedGraphics.get(spriteID);
			gottenSprite.animation.play(animToPlay, forced);
		});

		PlayState.contents.setVar('setSpriteBlend', function(spriteID:String, blendString:String)
		{
			var gottenSprite:FNFSprite = PlayState.ScriptedGraphics.get(spriteID);
			gottenSprite.blend = ForeverTools.getBlendFromString(blendString);
		});

		PlayState.contents.setVar('setSpriteScrollFactor', function(spriteID:String, x:Float, y:Float)
		{
			var gottenSprite:FNFSprite = PlayState.ScriptedGraphics.get(spriteID);
			gottenSprite.scrollFactor.set(x, y);
		});

		PlayState.contents.setVar('setSpriteSize', function(spriteID:String, newSize:Float)
		{
			var gottenSprite:FNFSprite = PlayState.ScriptedGraphics.get(spriteID);
			gottenSprite.setGraphicSize(Std.int(gottenSprite.width * newSize));
		});

		PlayState.contents.setVar('setSpriteAlpha', function(spriteID:String, newAlpha:Float)
		{
			var gottenSprite:FNFSprite = PlayState.ScriptedGraphics.get(spriteID);
			gottenSprite.alpha = newAlpha;
		});

		PlayState.contents.setVar('createCharacter', function(charID:String, key:String, x:Float, y:Float, alpha:Float, isPlayer:Bool = false)
		{
			var newChar:Character;
			newChar = new Character(x, y, isPlayer, key);
			newChar.alpha = alpha;
			newChar.dance();
			PlayState.contents.characterArray.push(newChar);
			PlayState.contents.setVar('$charID', charID);
			PlayState.contents.add(newChar);
		});

		PlayState.contents.setVar('changeCharacter', function(key:String, target:String, x:Float, y:Float)
		{
			PlayState.contents.changeCharacter(key, target, x, y);
		});

		PlayState.contents.setVar('castShader', function(shaderID:String, key:String, camera:String = 'camGame')
		{
			if (Init.trueSettings.get('Disable Shaders'))
			{
				return null;
			}
			else
			{
				if (key != null || key != '')
				{
					var shader:GraphicsShader = new GraphicsShader("", File.getContent(Paths.shader(key)));
					PlayState.ScriptedShaders.set(shaderID, shader);

					switch (camera)
					{
						case 'camhud' | 'camHUD' | 'hud' | 'ui':
							PlayState.camHUD.setFilters([new ShaderFilter(shader)]);
						case 'camgame' | 'camGame' | 'game' | 'world':
							PlayState.camGame.setFilters([new ShaderFilter(shader)]);
						case 'strumhud' | 'strumHUD' | 'strum' | 'strumlines':
							PlayState.strumHUD.setFilters([new ShaderFilter(shader)]);
					}
				}
				else
				{
					return;
				}
			}
		});

		PlayState.contents.setVar('trace', function(text:String, printOnHud:Bool = true, color:Array<Int> = null)
		{
			if (color == null)
				color = [255, 255, 255];

			trace(text);

			if (printOnHud)
			{
				PlayState.uiHUD.traceBar.text += '$text\n';
				PlayState.uiHUD.traceBar.color = FlxColor.fromRGB(color[0], color[1], color[2]);
				FlxTween.tween(PlayState.uiHUD.traceBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

				new FlxTimer().start(6, function(tmr:FlxTimer)
				{
					PlayState.uiHUD.traceBar.text = '';
					FlxTween.tween(PlayState.uiHUD.traceBar, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				});
			}
		});

		PlayState.contents.setVar('playSound', function(sound:String)
		{
			FlxG.sound.play(Paths.sound(sound));
		});

		PlayState.contents.setVar('getSetting', function(key:String)
		{
			Init.trueSettings.get(key);
		});

		PlayState.contents.setVar('setSetting', function(key:String, value:Dynamic)
		{
			Init.trueSettings.set(key, value);
		});

		PlayState.contents.setVar('getColor', function(color:String)
		{
			ForeverTools.getColorFromString(color);
		});

		PlayState.contents.setVar('doTween', function(tweenID:String, tweenProperty:String, object:Dynamic, value:Dynamic, time:Float, ease:String)
		{
			endTween(tweenID);
			var tweenType = {};
			var newTween:FlxTween = null;

			/**
			 * originally made for psych engine as a pull request
			 * https://github.com/ShadowMario/FNF-PsychEngine/pull/10433
			 * credits to Cherri#0815
			 */
			Reflect.setField(tweenType, tweenProperty, value);

			PlayState.ScriptedTweens.set(tweenID, newTween = FlxTween.tween(object, tweenType, time, {
				ease: ForeverTools.getEaseFromString(ease),
				onComplete: function(tween:FlxTween)
				{
					newTween.cancel();
					completeTween(tweenID);
					newTween = null;
				}
			}));
		});

		PlayState.contents.setVar('doStrumTween', function(tweenID:String, tweenProperty:String, strumline:String, newNote:Int, value:Dynamic, time:Float, ease:String)
		{
			endTween(tweenID);
			var tweenType = {};
			var epicNote = PlayState.bfStrums.receptors.members[newNote];
			var newTween:FlxTween = null;

			switch (strumline)
			{
				case 'dadStrums' | 'dadOpponentStrums' | 'dad' | 'opponentStrums':
					epicNote = PlayState.dadStrums.receptors.members[newNote];
				default:
					epicNote = PlayState.bfStrums.receptors.members[newNote];
			}

			/**
			 * originally made for psych engine as a pull request
			 * https://github.com/ShadowMario/FNF-PsychEngine/pull/10433
			 * credits to Cherri#0815
			 */
			Reflect.setField(tweenType, tweenProperty, value);

			PlayState.ScriptedTweens.set(tweenID, newTween = FlxTween.tween(epicNote, tweenType, time, {
				ease: ForeverTools.getEaseFromString(ease),
				onComplete: function(tween:FlxTween)
				{
					newTween.cancel();
					completeTween(tweenID);
					newTween = null;
				}
			}));
		});
	}

	public static function completeTween(tweenID:String)
	{
		PlayState.contents.callFunc('completeTween', [tweenID]);
		endTween(tweenID);
	}

	public static function endTween(tweenID:String)
	{
		if(PlayState.ScriptedTweens.exists(tweenID))
		{
			PlayState.ScriptedTweens.get(tweenID).cancel();
			PlayState.ScriptedTweens.get(tweenID).destroy();
			PlayState.ScriptedTweens.remove(tweenID);
		}
	}	
}