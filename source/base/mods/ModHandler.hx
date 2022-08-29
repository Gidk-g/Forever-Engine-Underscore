package base.mods;

#if MOD_HANDLER
import polymod.*;
import polymod.Polymod.ModMetadata;
import polymod.Polymod.PolymodError;
import polymod.backends.OpenFLBackend;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules;

class ModHandler
{
	static final API_VER = '0.1.0';
	static final MOD_DIR = 'mods';

	public static var modsMetaData:Array<String> = [];

	public static function loadModHandler():Void
	{
		#if MOD_HANDLER
		trace('Initializing Polymod...');
		getMods();
		loadMods(modsMetaData);
		#else
		trace("Polymod is not supported on your Platform!")
		#end
	}

	#if MOD_HANDLER
	public static function loadMods(folders:Array<String>):Void
	{
		trace(folders);
		trace('Attempting to Load ${folders.length} mods...');
		var loadedModlist = Polymod.init({
			/**
			 * root directory of all mods
			 * Required if you are on desktop and using the SysFileSystem (may be optional on some file systems)
			 */
			modRoot: MOD_DIR,

			/**
			 * directory names of one or more mods, relative to modRoot
			 */
			dirs: folders,

			/**
			 * the Haxe framework you're using (OpenFL, HEAPS, Kha, NME, etc..).
			 * If not provided, Polymod will attempt to determine this automatically.
			 */
			framework: OPENFL,

			/**
			 * any specific settings for your particular Framework
			 */
			frameworkParams: {
				/**
				 * if you're using Lime/OpenFL AND you're using custom or non-default asset libraries, then you must provide a key=>value store mapping the name of each asset library to a path prefix in your mod structure
				 */
				assetLibraryPaths: [
					"default" => "assets",
					"characters" => "characters",
					"songs" => "songs",
					"shaders" => "shaders",
					"fonts" => "fonts",
					"stages" => "stages",
					"videos" => "videos",
				]
			},

			/**
			 * semantic version of your game's Modding API (will generate errors & warnings)
			 */
			apiVersion: API_VER,

			/**
			 * callback for any errors generated during mod initialization
			 */
			errorCallback: onError,

			/**
			 * parsing rules for various data formats
			 */
			parseRules: getParseRules(),

			/**
			 * list of filenames to ignore in mods
			 */
			ignoredFiles: Polymod.getDefaultIgnoreList(),

			/**
			 * your own custom backend for handling assets
			 */
			customBackend: ModBackend
		});

		trace(loadedModlist);
		trace('Loading Successful, ${loadedModlist.length} / ${folders.length} new mods.');

		for (mod in loadedModlist)
			trace('Name: ${mod.title}, [${mod.id}]');

		var fileList = Polymod.listModFiles("IMAGE");
		trace('Installed mods added / replaced ${fileList.length} images');
		for (item in fileList)
			trace(' * [$item]');

		var fileList = Polymod.listModFiles("TEXT");
		trace('Installed mods added / replaced ${fileList.length} text files');
		for (item in fileList)
			trace(' * [$item]');

		var fileList = Polymod.listModFiles("MUSIC");
		trace('Installed mods added / replaced ${fileList.length} songs');
		for (item in fileList)
			trace(' * [$item]');

		var fileList = Polymod.listModFiles("SOUNDS");
		trace('Installed mods added / replaced ${fileList.length} sounds');
		for (item in fileList)
			trace(' * [$item]');
	}

	public static function getMods():Array<ModMetadata>
	{
		var daList:Array<ModMetadata> = [];

		trace('Searching for Mods...');

		for (i in Polymod.scan(MOD_DIR, '*.*.*', onError))
		{
			modsMetaData.push(i.id);
			daList.push(i);
		}

		trace('Found ${daList.length} new mods.');

		return daList;
	}

	public static function getParseRules():ParseRules
	{
		var output = ParseRules.getDefault();
		output.addType("txt", TextFileFormat.LINES);
		return output;
	}

	static function onError(error:PolymodError):Void
	{
		switch (error.severity)
		{
			case NOTICE:
				trace(error.message, null);
			case WARNING:
				trace(error.message, null);
			case ERROR:
				trace(error.message, null);
		}
	}
	#end
}

class ModBackend extends OpenFLBackend
{
	public function new()
	{
		super();
		trace('Initialized custom asset loader backend.');
	}

	public override function clearCache()
	{
		super.clearCache();
		trace('Custom asset cache has been cleared.');
	}

	public override function exists(exist:String):Bool
	{
		trace('Call to ModBackend: exists($exist)');
		return super.exists(exist);
	}

	public override function getBytes(byte:String):lime.utils.Bytes
	{
		trace('Call to ModBackend: getBytes($byte)');
		return super.getBytes(byte);
	}

	public override function getText(txt:String):String
	{
		trace('Call to ModBackend: getText($txt)');
		return super.getText(txt);
	}

	public override function list(type:PolymodAssetType = null):Array<String>
	{
		trace('Listing assets in custom asset cache ($type).');
		return super.list(type);
	}
}
#end
