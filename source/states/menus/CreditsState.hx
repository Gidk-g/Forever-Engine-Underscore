package states.menus;

import base.MusicBeat.MusicBeatState;
import dependency.AbsoluteSprite;
import dependency.Discord;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.Alphabet;
import haxe.Json;

typedef CreditsUserDef =
{
	name:String,
	iconData:Array<Dynamic>,
	textData:Array<String>,
	colors:Array<Int>,
	urlData:Array<Array<String>>,
	?sectionName:String
}

typedef CreditsPrefDef =
{
	?menuBG:Null<String>,
	?menuBGColor:Null<Array<Int>>,
	?tweenColor:Null<Bool>,
	users:Array<CreditsUserDef>
}

class CreditsState extends MusicBeatState
{
	static var curSelection = -1;
	var curSocial = -1;

	var alphabetGroup:FlxTypedGroup<Alphabet>;
	var infoText:FlxText;

	var menuBG:FlxSprite = new FlxSprite();
	var menuColorTween:FlxTween;

	var userData:CreditsUserDef;
	var credData:CreditsPrefDef;

	var titleText:Alphabet;

	var iconArray:Array<AbsoluteSprite> = [];

	public static var repositionNumbers:Bool = false;

	override function create()
	{
		super.create();

		repositionNumbers = true;

		credData = Json.parse(Paths.getTextFromFile('credits.json'));

		#if DISCORD_RPC
		Discord.changePresence('READING THE CREDITS', 'Credits Menu');
		#end

		if (credData.menuBG != null && credData.menuBG.length > 0)
			menuBG.loadGraphic(Paths.image(credData.menuBG));
		else
			menuBG.loadGraphic(Paths.image('menus/base/menuDesat'));

		menuBG.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
		menuBG.screenCenter();
		add(menuBG);

		var finalColor:FlxColor = FlxColor.fromRGB(credData.menuBGColor[0], credData.menuBGColor[1], credData.menuBGColor[2]);
		if (!credData.tweenColor)
			menuBG.color = finalColor;

		alphabetGroup = new FlxTypedGroup<Alphabet>();
		add(alphabetGroup);

		for (i in 0...credData.users.length)
		{
			var personName:Alphabet = new Alphabet(0, (70 * i) + 30, credData.users[i].name, false, false);
			personName.isMenuItem = true;
			personName.disableX = true;
			personName.targetY = i;
			alphabetGroup.add(personName);

			var iconGraphic = 'credits/' + credData.users[i].iconData[0];
			var icon:AbsoluteSprite = new AbsoluteSprite(iconGraphic, personName, credData.users[i].iconData[1], credData.users[i].iconData[2]);

			if (credData.users[i].iconData[3] != null)
				icon.setGraphicSize(Std.int(icon.width * credData.users[i].iconData[3]));

			if (credData.users[i].iconData.length <= 1 || credData.users[i].iconData == null)
				icon.visible = false;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			if (curSelection == -1)
				curSelection = i;
		}

		if (curSocial == -1)
			curSocial = 0;

		titleText = new Alphabet(50, 40, credData.users[curSelection].sectionName, true, false, 0.6);
		titleText.alpha = 0.4;
		add(titleText);

		infoText = new FlxText(5, FlxG.height - 24, 0, "", 32);
		infoText.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.textField.background = true;
		infoText.textField.backgroundColor = FlxColor.BLACK;
		add(infoText);

		updateSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		infoText.screenCenter(X);

		// CONTROLS //

		var controlArray:Array<Bool> = [controls.UI_UP, controls.UI_DOWN, controls.UI_UP_P, controls.UI_DOWN_P, FlxG.mouse.wheel == 1, FlxG.mouse.wheel == -1];
		if ((controlArray.contains(true)))
		{
			for (i in 0...controlArray.length)
			{
				if (controlArray[i] == true)
				{
					if (i > 1)
					{
						if (i == 2 || i == 4)
							curSelection--;
						else if (i == 3 || i == 5)
							curSelection++;

						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
					if (curSelection < 0)
						curSelection = credData.users.length - 1;
					else if (curSelection >= credData.users.length)
						curSelection = 0;

					updateSelection();
				}
			}
		}

		if (controls.UI_LEFT_P)
			changeSocial(-1);

		if (controls.UI_RIGHT_P)
			changeSocial(1);

		if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxFlicker.flicker(alphabetGroup.members[curSelection], 0.5, 0.06 * 2, true, false, function(flick:FlxFlicker)
			{
				if (credData.users[curSelection].urlData[curSocial][1] != null)
					CoolUtil.browserLoad(credData.users[curSelection].urlData[curSocial][1]);
			});
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			Main.switchState(this, new MainMenuState());
			Paths.clearUnusedMemory();
		}

		updateInfoText();
	}

	function updateSelection()
	{
		var bullShit:Int = 0;
		for (item in alphabetGroup.members)
		{
			item.targetY = bullShit - curSelection;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}

		if (credData.users[curSelection].sectionName.length > 1 && titleText != null)
			titleText.changeText(credData.users[curSelection].sectionName);

		if (credData.tweenColor)
		{
			var color:FlxColor = FlxColor.fromRGB(credData.users[curSelection].colors[0], credData.users[curSelection].colors[1],
				credData.users[curSelection].colors[2]);

			if (menuColorTween != null)
				menuColorTween.cancel();

			if (color != menuBG.color)
			{
				menuColorTween = FlxTween.color(menuBG, 0.35, menuBG.color, color, {
					onComplete: function(tween:FlxTween) menuColorTween = null
				});
			}
		}

		// reset social;
		curSocial = 0;
	}

	public function updateInfoText()
	{
		var textData = credData.users[curSelection].textData;
		var fullText:String = '';

		// description
		if (textData[0] != null && textData[0].length >= 1)
			fullText += textData[0];

		// quotes
		if (textData[1] != null && textData[1].length >= 1)
			fullText += ' - "' + textData[1] + '"';

		if (credData.users[curSelection].urlData[curSocial][0] != null)
			fullText += ' • Visit: <' + credData.users[curSelection].urlData[curSocial][0] + '>';

		infoText.text = fullText;
	}

	public function changeSocial(huh:Int = 0) // HUH???
	{
		if (credData.users[curSelection].urlData[curSocial][0] == null)
			return;

		// prevent loud scroll sounds
		if (huh >= -1)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSocial += huh;
		if (curSocial < 0)
			curSocial = credData.users[curSelection].urlData[0].length - 1;
		if (curSocial >= credData.users[curSelection].urlData.length)
			curSocial = 0;

		// iconSocial.updateAnim(credData.users[curSelection].urlData[curSocial][0]);
	}
}