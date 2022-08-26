package states.menus;

import base.MusicBeat.MusicBeatState;
import base.mods.ModHandler;
import dependency.AbsoluteSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.Alphabet;
import polymod.Polymod;
import haxe.Json;

/**
	* people have been asking and stuff so here it is
	* this is gonna be slooow to finish though, as I already need to finish the offset and chart editors
	* but here it is, I will need a lot of help, but here it is!

	* quick reminder, i'm not a very good programmer, but I will try my very best -gabi
	* no, I have NO ideas for this.
**/
class ModsMenuState extends MusicBeatState
{
	private static var curSelection:Int = -1;

	var bg:FlxSprite;
	var fg:FlxSprite;
	var infoText:FlxText;

	var grpMenuMods:FlxTypedGroup<Alphabet>;

	var icons:Array<AbsoluteSprite> = [];
	var modList:Array<ModMetadata> = [];

	var isEnabled = true;

	override function create()
	{
		super.create();

		// refresh mods
		ModHandler.loadModHandler();

		// get current modlist
		modList = ModHandler.getMods();

		bg = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
		bg.color = 0xCE64DF;
		add(bg);

		fg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		fg.alpha = 0;
		fg.scrollFactor.set();
		add(fg);

		infoText = new FlxText(5, FlxG.height - 24, 0, "", 32);
		infoText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.textField.background = true;
		infoText.textField.backgroundColor = FlxColor.BLACK;
		add(infoText);

		grpMenuMods = new FlxTypedGroup<Alphabet>();
		add(grpMenuMods);

		for (i in 0...modList.length)
		{
			var alphabet:Alphabet = new Alphabet(0, 70 * i, modList[i].title, true);
			alphabet.isMenuItem = true;
			alphabet.screenCenter(X);
			alphabet.targetY = i;
			alphabet.disableX = true;
			grpMenuMods.add(alphabet);

			if (curSelection == -1)
				curSelection = i;
		}

		FlxTween.tween(fg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		updateSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		infoText.text = modList[curSelection].description;
		infoText.screenCenter(X);

		if (controls.BACK)
			Main.switchState(this, new MainMenuState());
		//else (controls.ACCEPT)
			//CoolUtil.browserLoad(modList[curSelection].homepage);

		if (controls.UI_UP_P)
			updateSelection(-1);
		else if (controls.UI_DOWN_P)
			updateSelection(1);
	}

	function updateSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelection += change;

		if (curSelection < 0)
			curSelection = modList.length - 1;
		if (curSelection >= modList.length)
			curSelection = 0;

		var bullShit:Int = 0;
		for (item in grpMenuMods.members)
		{
			item.targetY = bullShit - curSelection;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				if (isEnabled)
					item.alpha = 1;
				else
					item.alpha = 0.6;
			}
		}
	}
}
