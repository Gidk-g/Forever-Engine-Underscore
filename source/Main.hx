package;

import base.debug.Overlay;
import dependency.Discord;
import dependency.FNFTransition;
import dependency.FNFUIState;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import funkin.PlayerSettings;
import haxe.CallStack.StackItem;
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.UncaughtErrorEvent;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

// Here we actually import the states and metadata, and just the metadata.
// It's nice to have modularity so that we don't have ALL elements loaded at the same time.
// at least that's how I think it works. I could be stupid!
class Main extends Sprite
{
	// class action variables
	public static var mainClassState:Class<FlxState> = Init; // Determine the main class state of the game
	public static var foreverVersion:String = '0.3.1';
	public static var underscoreVersion:String = '0.2.2 BETA';
	public static var commitHash:String;
	public static var showCommitHash:Bool = true;

	static var infoCounter:Overlay; // initialize the heads up display that shows information before creating it.

	// heres gameweeks set up!

	/**
		Small bit of documentation here, gameweeks are what control everything in my engine
		this system will eventually be overhauled in favor of using actual week folders within the 
		assets.
		Enough of that, here's how it works
		[ [songs to use], [characters in songs], [color of week], name of week, week image file, shown from story mode ]
	**/
	public static var gameWeeks:Array<Dynamic> = [
		[
			['Tutorial'],
			['gf'],
			[FlxColor.fromRGB(129, 100, 223)],
			'Funky Beginnings',
			'week0',
			true
		],
		[
			['Bopeebo', 'Fresh', 'Dadbattle'],
			['dad', 'dad', 'dad'],
			[FlxColor.fromRGB(129, 100, 223)],
			'vs. DADDY DEAREST',
			'week1',
			true
		],
		[
			['Spookeez', 'South', 'Monster'],
			['spooky', 'spooky', 'monster'],
			[FlxColor.fromRGB(30, 45, 60)],
			'Spooky Month',
			'week2',
			true
		],
		[
			['Pico', 'Philly-Nice', 'Blammed'],
			['pico'],
			[FlxColor.fromRGB(111, 19, 60)],
			'vs. Pico',
			'week3',
			true
		],
		[
			['Satin-Panties', 'High', 'Milf'],
			['mom'],
			[FlxColor.fromRGB(203, 113, 170)],
			'MOMMY MUST MURDER',
			'week4',
			true
		],
		[
			['Cocoa', 'Eggnog', 'Winter-Horrorland'],
			['parents-christmas', 'parents-christmas', 'monster-christmas'],
			[FlxColor.fromRGB(141, 165, 206)],
			'RED SNOW',
			'week5',
			true
		],
		[
			['Senpai', 'Roses', 'Thorns'],
			['senpai', 'senpai', 'spirit'],
			[FlxColor.fromRGB(206, 106, 169)],
			"hating simulator ft. moawling",
			'week6',
			true
		],
		[
			['Ugh', 'Guns', 'Stress'],
			['tankman', 'tankman', 'tankman'],
			[FlxColor.fromRGB(246, 182, 4)],
			"Tankman",
			'week7',
			true
		],
	];

	// calls a function to set the game up
	public function new()
	{
		super();

		/**
			ok so, haxe html5 CANNOT do 120 fps. it just cannot.
			so here i just set the framerate to 60 if its complied in html5.
			reason why we dont just keep it because the game will act as if its 120 fps, and cause
			note studders and shit its weird.
		**/

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		FlxTransitionableState.skipNextTransIn = true;

		// here we set up the base game
		addChild(new FlxGame(0, 0, mainClassState, 1, #if (html5 || neko) 60 #else 120 #end, #if (html5 || neko) 60 #else 120 #end, true)); // and create it afterwards

		// default game FPS settings, I'll probably comment over them later.
		// addChild(new FPS(10, 3, 0xFFFFFF));

		// begin the discord rich presence
		#if DISCORD_RPC
		Discord.initializeRPC();
		Discord.changePresence('');
		#end

		// test initialising the player settings
		PlayerSettings.init();

		infoCounter = new Overlay(0, 0);
		changeInfoAlpha(1);
		addChild(infoCounter);
	}

	public static function framerateAdjust(input:Float)
	{
		return input * (60 / FlxG.drawFramerate);
	}

	/*  This is used to switch "rooms," to put it basically. Imagine you are in the main menu, and press the freeplay button.
		That would change the game's main class to freeplay, as it is the active class at the moment.
	 */
	public static var lastState:FlxState;

	public static function switchState(curState:FlxState, target:FlxState)
	{
		// Custom made Trans in
		mainClassState = Type.getClass(target);
		if (!FlxTransitionableState.skipNextTransIn)
		{
			curState.openSubState(new FNFTransition(0.35, false));
			FNFTransition.finishCallback = function()
			{
				FlxG.switchState(target);
			};
			return #if DEBUG_TRACES trace('changed state') #end;
		}
		FlxTransitionableState.skipNextTransIn = false;
		// load the state
		FlxG.switchState(target);
	}

	public static function updateFramerate(newFramerate:Int)
	{
		// flixel will literally throw errors at me if I dont separate the orders
		if (newFramerate > FlxG.updateFramerate)
		{
			FlxG.updateFramerate = newFramerate;
			FlxG.drawFramerate = newFramerate;
		}
		else
		{
			FlxG.drawFramerate = newFramerate;
			FlxG.updateFramerate = newFramerate;
		}
	}

	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = StringTools.replace(dateNow, " ", "_");
		dateNow = StringTools.replace(dateNow, ":", "'");

		path = "crash/" + "FE_" + dateNow + ".txt";

		errMsg = "Friday Night Funkin' v" + Lib.application.meta["version"] + "\n";
		errMsg += "Forever Engine Underscore v" + Main.underscoreVersion + (showCommitHash ? ' (${commitHash})' : '') + "\n";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case CFunction:
					errMsg += 'a C function\n';
				case Module(m):
					errMsg += 'module ' + m + '\n';
				case FilePos(s, file, line, column):
					errMsg += file + ' (line ' + line + ')\n';
				case Method(cname, meth):
					errMsg += cname == null ? "<unknown>" : cname + '.' + meth + '\n';
				case LocalFunction(n):
					errMsg += 'local function ' + n + '\n';
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: "
			+ e.error
			+
			"\nPlease report this error to the GitHub page: https://github.com/BeastlyGhost/Forever-Engine-Underscore\non the \"master\" branch\n\n>Crash Handler written by: sqirra-rng\n\n";

		try // to make the game to not crash if it can't save the crash file
		{
			if (!Assets.exists("crash"))
				FileSystem.createDirectory("crash");

			File.saveContent(path, errMsg + "\n");
		}

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		Discord.shutdownRPC();
		Sys.exit(1);
	}

	public static function changeInfoAlpha(value:Float)
	{
		infoCounter.alpha = value;
	}

	public static function getGitCommitHash()
	{
		var process = new sys.io.Process('git', ['rev-parse', 'HEAD']);

		// read the output of the process
		var commitHash:String = process.stdout.readLine();
		var trimmedCommitHash:String = commitHash.substr(0, 7);

		// Generates a string expression
		return trimmedCommitHash;
	}
}
