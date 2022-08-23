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
	var colors:Array<Array<Float>>; // colors for your week on freeplay
	var name:Null<String>; // image graphic for the week (e.g: "week1");
	var shownOnStory:Null<Bool>; // if the week can be shown on the story mode menu;
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
		if (push)
		{
			parseJson();

			if (parseJson()) // if parsing was successful;
				pushWeeks(push);
		}
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
				storyData.weekImage = '';
		}
	}

	public static function parseJson():Bool
	{
		var dataFolders = [];
		var pushedWeeks:Array<String> = [];

		if (FileSystem.exists(Paths.getPreloadPath('weeks/')))
			dataFolders.push(Paths.getPreloadPath('weeks/'));

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

		for (color in 0...weekData.colors.length)
			colorArray.push(FlxColor.fromRGB(weekData.colors[color][0], weekData.colors[color][1], weekData.colors[color][2]));

		weekArray.push(songArray);
		weekArray.push(iconArray);
		weekArray.push(colorArray);
		weekArray.push(weekData.name);
		weekArray.push(storyData.weekImage);
		weekArray.push(weekData.shownOnStory);

		Main.gameWeeks.push(weekArray);
		#if DEBUG_TRACES trace(Main.gameWeeks); #end
		loadStoryData(push);
	}
}
