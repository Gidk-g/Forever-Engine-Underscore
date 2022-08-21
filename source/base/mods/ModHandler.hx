package base.mods;

#if MOD_HANDLER
import polymod.Polymod;
import polymod.backends.OpenFLBackend;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules.LinesParseFormat;
import polymod.format.ParseRules.TextFileFormat;
#end

class ModHandler
{
    static final API_VER = "0.1.0";
    static final MOD_DIR = "mods";

    public static function loadModHandler()
    {
        #if MOD_HANDLER
        trace('Initializing Polymod...');
		loadMods(getMods());
        #else
        trace("Polymod is not supported on your Platform!")
        #end
    }

    #if MOD_HANDLER
    public static function loadMods(folders:Array<String>)
    {
        trace('Attempting to Load ${folders.length} mods...');
        var loadedModlist = polymod.Polymod.init({
            modRoot: MOD_DIR,
            dirs: folders,
            framework: CUSTOM,
            apiVersion: API_VER,
			errorCallback: onError,
			frameworkParams: buildFrameworkParams(),
			customBackend: ModBackend,
			ignoredFiles: Polymod.getDefaultIgnoreList(),
			parseRules: parseRules(),
        });

		trace('Loading Successful, ${loadedModlist.length} / ${folders.length} new mods.');

        for (mod in loadedModlist)
            trace('Name: ${mod.title}, [${mod.id}]');

        var fileList = Polymod.listModFiles("IMAGE");
		trace('Installed mods replaced ${fileList.length} images');
		for (item in fileList)
			trace(' * [$item]');

		var fileList = Polymod.listModFiles("TEXT");
		trace('Installed mods replaced ${fileList.length} text files');
		for (item in fileList)
			trace(' * [$item]');

		var fileList = Polymod.listModFiles("MUSIC");
		trace('Installed mods replaced ${fileList.length} songs');
		for (item in fileList)
			trace(' * [$item]');

		var fileList = Polymod.listModFiles("SOUNDS");
		trace('Installed mods replaced ${fileList.length} sounds');
		for (item in fileList)
			trace(' * [$item]');
    }

    static function getMods():Array<String>
    {
        trace('Searching for Mods...');
        var modMeta = Polymod.scan(MOD_DIR);
        trace('Found ${modMeta.length} new mods.');
        var modNames = [for (i in modMeta) i.id];
        return modNames;
    }

    public static function parseRules():polymod.format.ParseRules
    {
		var output = polymod.format.ParseRules.getDefault();
		output.addType("txt", TextFileFormat.LINES);
		return output;
    }

	static inline function buildFrameworkParams():polymod.FrameworkParams
	{
		return
        {
			assetLibraryPaths: [
				"default" => "./assets",
				"characters" => "./characters",
				"fonts" => "./fonts",
				"images" => "./images",
				"music" => "./music",
				"scripts" => "./scripts",
				"shaders" => "./shaders",
				"songs" => "./songs",
				"sounds" => "./sounds",
				"stages" => "./stages",
				"videos" => "./videos",
				"weeks" => "./weeks",
			]
		}
	}

    static function onError(error:PolymodError):Void
	{
		switch (error.code)
		{
			default:
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
	}
    #end
}

#if MOD_HANDLER
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