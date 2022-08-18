package base;

import flixel.util.FlxColor;
import haxe.Json;
import states.menus.StoryMenuState;
import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef WeekDataDef =
{
	var songs:Array<String>; // array of songs, song colors, song character icons, and week name [refer to the gameWeeks variable];
	var icons:Array<String>; // character icons that will show up on freeplay (e.g: dad, spooky, tankman);
	var colors:Array<Float>; // colors for your week on freeplay
	var name:Null<String>; // image graphic for the week (e.g: "week1");
}

typedef WeekStoryDataDef =
{
	var characters:Null<Array<String>>; // characters that will show up on the story menu (e.g: dad, bf, gf);
	var weekImage:Null<String>; // the week's image file;
	var before:Null<String>; // week before this one;
	var unlocked:Null<Bool>; // whether the week starts off unlocked or not;
}

class WeekParser
{
	public static var storyData:WeekStoryDataDef;
	public static var weekData:WeekDataDef;

	public static var songArray:Array<String> = [];
	public static var iconArray:Array<String> = [];
	public static var colorArray:Array<Float> = [];

	public static var weekArray:Array<Dynamic> = [];

	public static function loadWeeks(push:Bool = true)
	{
		parseJson();

		if (push && parseJson()) // if we can add custom weeks, and parsing was successful;
			pushWeeks(push);
	}

	public static function loadStoryData(push:Bool = true)
	{
		if (push)
		{
			if (storyData.characters == null)
				StoryMenuState.weekCharacters.push(['', 'bf', 'gf']);
			else
				StoryMenuState.weekCharacters.push(storyData.characters);

			if (storyData.unlocked == null)
				StoryMenuState.weekUnlocked.push(true);
			else
				StoryMenuState.weekUnlocked.push(storyData.unlocked);

			if (storyData.weekImage == null)
				storyData.weekImage = 'week1';
		}
	}

	public static function parseJson():Bool
	{
		var dataFolders = [];
		dataFolders.push(Paths.getPreloadPath('weeks/'));

		var pushedWeeks:Array<String> = [];

		for (folders in dataFolders)
		{
			if (FileSystem.exists(folders))
			{
				for (file in FileSystem.readDirectory(folders))
				{
					// quick file check to prevent crashes with non-json files;
					if (file.endsWith('.json'))
					{
						weekData = Json.parse(Paths.getTextFromFile('weeks/$file'));
						storyData = Json.parse(Paths.getTextFromFile('weeks/$file'));
					}
					return true;
				}
			}
		}

		return false;
	}

	public static function pushWeeks(push:Bool = false)
	{
		// janky ass add week data things;
		for (song in 0...weekData.songs.length)
			songArray.push(weekData.songs[song]);

		for (icon in 0...weekData.icons.length)
			iconArray.push(weekData.icons[icon]);

		colorArray.push(FlxColor.fromRGB(weekData.colors[0], weekData.colors[1], weekData.colors[2]));

		weekArray.push(songArray);
		weekArray.push(iconArray);
		weekArray.push(colorArray);
		weekArray.push(weekData.name);

		Main.gameWeeks.push(weekArray);
		trace(Main.gameWeeks);
		loadStoryData(push);
	}
}