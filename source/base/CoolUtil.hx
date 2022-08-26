package base;

import flixel.FlxCamera;
import flixel.FlxG;
import openfl.utils.Assets;
import states.PlayState;

using StringTools;

#if sys
import sys.FileSystem;
#end

class CoolUtil
{
	public static var baseDifficulties:Array<String> = ["EASY", "NORMAL", "HARD"];
	public static var difficulties:Array<String> = [];
	public static var difficultyLength = baseDifficulties.length;
	public static var customDiffLength = difficulties.length;

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	public static function difficultyFromNumber(number:Int):String
	{
		return difficulties[number];
	}

	public static function dashToSpace(string:String):String
	{
		return string.replace("-", " ");
	}

	public static function spaceToDash(string:String):String
	{
		return string.replace(" ", "-");
	}

	public static function swapSpaceDash(string:String):String
	{
		return StringTools.contains(string, '-') ? dashToSpace(string) : spaceToDash(string);
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];

		if (Assets.exists(path))
			daList = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function getOffsetsFromTxt(path:String):Array<Array<String>>
	{
		var daList:Array<String> = [];

		if (Assets.exists(path))
			daList = Assets.getText(path).trim().split('\n');

		var swagOffsets:Array<Array<String>> = [];

		for (i in daList)
			swagOffsets.push(i.split(' '));

		return swagOffsets;
	}

	public static function returnAssetsLibrary(library:String, ?subDir:String = 'assets/images'):Array<String>
	{
		var libraryArray:Array<String> = [];

		#if sys
		var unfilteredLibrary = FileSystem.readDirectory('$subDir/$library');

		for (folder in unfilteredLibrary)
			if (!folder.contains('.'))
				libraryArray.push(folder);

		#if DEBUG_TRACES trace(libraryArray); #end
		#end

		return libraryArray;
	}

	public static function getAnimsFromTxt(path:String):Array<Array<String>>
	{
		var daList:Array<String> = [];

		if (Assets.exists(path))
			daList = Assets.getText(path).trim().split('\n');

		var swagOffsets:Array<Array<String>> = [];

		for (i in daList)
			swagOffsets.push(i.split('--'));

		return swagOffsets;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
			dumbArray.push(i);

		return dumbArray;
	}

	public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}
}
