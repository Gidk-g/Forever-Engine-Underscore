package;

/*
	Aw hell yeah! something I can actually work on!
 */
import base.CoolUtil;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.Character.CharacterType;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
	future chart types support (unfinished!)
	code taken from: FNF-Forever-Engine, https://github.com/Yoshubs/FNF-Forever-Engine
**/
@:enum abstract ChartType(String) to String
{
	var FNF;
	var FNF_LEGACY;
	var FOREVER;
	var UNDERSCORE;
	var PSYCH;
}

class Paths
{
	// Here we set up the paths class. This will be used to
	// Return the paths of assets and call on those assets as well.
	inline public static var SOUND_EXT = "ogg";
	inline public static var VIDEO_EXT = "mp4";

	public static var currentPack:String = '';

	// in case anything goes wrong with your mods
	public static var defaultPack:String = 'default';

	// level we're loading
	static var currentLevel:String;

	// set the current level top the condition of this function if called
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	// stealing my own code from psych engine
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedTextures:Map<String, Texture> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/music/foreverMenu.$SOUND_EXT',
		'assets/music/breakfast.$SOUND_EXT',
		'assets/images/UI/default/base/alphabet.png',
		'assets/images/UI/default/base/alphabet.xml',
	];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		var counter:Int = 0;
		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedAssets.get(key);
				if (obj != null)
				{
					var isTexture:Bool = currentTrackedTextures.exists(key);
					if (isTexture)
					{
						var texture = currentTrackedTextures.get(key);
						texture.dispose();
						texture = null;
						currentTrackedTextures.remove(key);
					}
					@:privateAccess
					if (openfl.Assets.cache.hasBitmapData(key))
					{
						openfl.Assets.cache.removeBitmapData(key);
						FlxG.bitmap._cache.remove(key);
					}
					#if DEBUG_TRACES trace('removed $key, ' + (isTexture ? 'is a texture' : 'is not a texture')); #end
					obj.destroy();
					currentTrackedAssets.remove(key);
					counter++;
				}
			}
		}
		#if DEBUG_TRACES trace('removed $counter assets'); #end
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(?cleanUnused:Bool = false)
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
	}

	public static function returnGraphic(key:String, folder:String = 'images', ?library:String, ?textureCompression:Bool)
	{
		textureCompression = Init.trueSettings.get('Hardware Caching');

		#if MOD_HANDLER
		var modPath:String = modImages(key);
		if (FileSystem.exists(modPath))
		{
			if (!currentTrackedAssets.exists(modPath))
			{
				var bitmap = BitmapData.fromFile(modPath);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, modPath);
				if (textureCompression)
				{
					var texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true, 0);
					texture.uploadFromBitmapData(bitmap);
					currentTrackedTextures.set(key, texture);
					bitmap.dispose();
					bitmap.disposeImage();
					bitmap = null;
					#if DEBUG_TRACES trace('new mod texture $key, bitmap is $bitmap'); #end
					newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, key, false);
				}
				else
				{
					newGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
					#if DEBUG_TRACES trace('new mod bitmap $key, not textured'); #end
				}
				currentTrackedAssets.set(key, newGraphic);
			}
			localTrackedAssets.push(modPath);
			return currentTrackedAssets.get(modPath);
		}
		#end
		var path = getPath('$folder/$key.png', IMAGE, library);

		if (FileSystem.exists(path))
		{
			if (!currentTrackedAssets.exists(key))
			{
				var bitmap = BitmapData.fromFile(path);
				var newGraphic:FlxGraphic;
				if (textureCompression)
				{
					var texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true, 0);
					texture.uploadFromBitmapData(bitmap);
					currentTrackedTextures.set(key, texture);
					bitmap.dispose();
					bitmap.disposeImage();
					bitmap = null;
					#if DEBUG_TRACES trace('new texture $key, bitmap is $bitmap'); #end
					newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, key, false);
				}
				else
				{
					newGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
					#if DEBUG_TRACES trace('new bitmap $key, not textured'); #end
				}
				currentTrackedAssets.set(key, newGraphic);
			}
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		#if DEBUG_TRACES trace('oh no ' + key + ' is returning null NOOOO'); #end
		return null;
	}

	static public function getTextFromFile(key:String, ignoreMods:Bool = false):String
	{
		#if MOD_HANDLER
		if (!ignoreMods && FileSystem.exists(getModPath('', key, '')))
			return File.getContent(getModPath('', key, ''));
		#end
		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			levelPath = getLibraryPathForce(key, '');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		return Assets.getText(getPath(key, TEXT));
	}

	public static function returnSound(path:String, key:String, ?library:String)
	{
		#if MOD_HANDLER
		var file:String = modSounds(path, key);
		if (FileSystem.exists(file))
		{
			if (!currentTrackedSounds.exists(file))
			{
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if (!currentTrackedSounds.exists(gottenPath))
			#if MOD_HANDLER
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
			#else
			{
				var folder:String = '';
				if (path == 'songs')
					folder = 'songs:';

				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
			}
			#end
		// currentTrackedSounds.set(gottenPath, Sound.fromFile(gottenPath));
		localTrackedAssets.push(key);
		return currentTrackedSounds.get(gottenPath);
	}

	//
	inline public static function getPath(file:String, type:AssetType, ?library:Null<String>)
	{
		/*
				Okay so, from what I understand, this loads in the current path based on the level
				we're in (if a library is not specified), say like week 1 or something, 
				then checks if the assets you're looking for are there.
				if not, it checks the shared assets folder.
			// */

		// well I'm rewriting it so that the library is the path and it looks for the file type
		// later lmao I don't really wanna rn

		if (library != null)
			return getLibraryPath(file, library);

		/*
			if (currentLevel != null)
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;

				levelPath = getLibraryPathForce(file, "shared");
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
		}*/

		var levelPath = getLibraryPathForce(file, "mods");
		if (OpenFlAssets.exists(levelPath, type))
			return levelPath;

		return getPreloadPath(file);
	}

	// files!
	// this is how I'm gonna do it, considering it's much cleaner in my opinion

	/*
		inline static public function returnFileType(fileName:String, ?library:String, fileExtension:String)
		{
			// I don't really use haxe so bare with me
			var returnFile:String = "$" + fileName + "." + fileExtension;
			return getPath()
	}//*/
	/*  
		actually I could just combine all of these main functions into one and really call it a day
		it's similar and would use one function with a switch case
		for now I'm more focused on getting this to run than anything and I'll clean out the code later as I do want to organise
		everything later 
	 */
	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library/$file';
	}

	public inline static function getPreloadPath(file:String)
	{
		var returnPath:String = 'assets/$file';
		if (!FileSystem.exists(returnPath))
			returnPath = CoolUtil.swapSpaceDash(returnPath);
		return returnPath;
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	/*inline static public function offsetTxt(key:String, ?library:String)
		{
			return getPath('images/characters/$key.txt', TEXT, library);
	}*/
	inline static public function json(key:String, ?library:String)
	{
		return getPath('songs/$key.json', TEXT, library);
	}

	inline static public function songJson(song:String, secondSong:String, ?library:String)
	{
		return getPath('songs/${song.toLowerCase()}/${secondSong.toLowerCase()}.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String):Dynamic
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Dynamic
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function songPath(path:String)
	{
		return CoolUtil.swapSpaceDash(path);
	}

	inline static public function songSounds(song:String, songFile:String)
	{
		var songKey:String = '${CoolUtil.swapSpaceDash(song.toLowerCase())}/$songFile';
		var sound = returnSound('songs', songKey);
		return sound;
	}

	inline static public function image(key:String, folder:String = 'images', ?library:String, ?textureCompression:Bool)
	{
		textureCompression = Init.trueSettings.get('Hardware Caching');
		var returnAsset:FlxGraphic = returnGraphic(key, folder, library, textureCompression);
		return returnAsset;
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(key:String, folder:String = 'images', ?library:String)
	{
		var graphic:FlxGraphic = returnGraphic(key, folder, library);
		return (FlxAtlasFrames.fromSparrow(graphic, File.getContent(file('$folder/$key.xml', library))));
	}

	inline static public function getPackerAtlas(key:String, folder:String = 'images', ?library:String)
	{
		return (FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, folder), file('$folder/$key.txt', library)));
	}

	inline static public function getSparrowHashAtlas(key:String, folder:String = 'images', ?library:String)
	{
		return FlxAtlasFrames.fromTexturePackerJson(image(key, library), file('$folder/$key.json', library));
	}

	inline static public function video(key:String)
	{
		#if MOD_HANDLER
		var file:String = modVideos(key);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function shader(key:String)
	{
		#if MOD_HANDLER
		var file:String = getModPath('shaders', key, 'frag');
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return 'assets/shaders/$key.frag';
	}

	/**
	 * MOD PATHS AND ANYTHING RELATED TO MODS
	 * something that i'm gonna work on soon! -gabi
	**/
	#if MOD_HANDLER
	inline static public function getModpack(key:String = '')
	{
		return 'mods/' + key;
	}

	inline static public function modImages(key:String)
	{
		return getModPath('images', key, 'png');
	}

	inline static public function modSounds(path:String, key:String)
	{
		return getModPath(path, key, SOUND_EXT);
	}

	inline static public function modVideos(key:String)
	{
		return getModPath('videos', key, VIDEO_EXT);
	}

	public inline static function getModPath(path:String, file:String, extension:String)
	{
		var returnPath:String = 'mods/$currentPack/$path/$file.$extension';
		if (!FileSystem.exists(returnPath))
			returnPath = CoolUtil.swapSpaceDash(returnPath);
		return returnPath;
	}

	public static function getModDirs():Array<String>
	{
		var modsList:Array<String> = [];
		var modsFolder:String = getModpack();
		if (FileSystem.exists(modsFolder))
		{
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && folder != 'default' && !modsList.contains(folder))
				{
					modsList.push(folder);
				}
			}
		}
		return modsList;
	}
	#end
}
