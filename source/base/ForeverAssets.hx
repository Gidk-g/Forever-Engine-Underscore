package base;

import base.ChartParser.SwagSection;
import base.Conductor;
import dependency.FNFSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.*;
import funkin.Strumline.UIStaticArrow;
import funkin.Timings;
import funkin.ui.menu.*;
import states.PlayState;

using StringTools;

/**
	Forever Assets is a class that manages the different asset types, basically a compilation of switch statements that are
	easy to edit for your own needs. Most of these are just static functions that return information
**/
class ForeverAssets
{
	//
	public static function generateCombo(asset:String, number:String, allSicks:Bool, group:FlxTypedGroup<FNFSprite>, assetModifier:String = 'base', changeableSkin:String = 'default',
		baseLibrary:String, negative:Bool, createdColor:FlxColor, scoreInt:Int):FNFSprite
	{
		var width = 100;
		var height = 140;
		if (assetModifier == 'pixel')
		{
			width = 10;
			height = 12;
		}

		/*
		var combo = group.recycle(FNFSprite, function()
		{
			var comboNum:FNFSprite = new FNFSprite();
			comboNum.loadGraphic(Paths.image(ForeverTools.returnSkinAsset(asset, assetModifier, changeableSkin, baseLibrary)), true, width, height);
			comboNum.animation.add('combo', [(Std.parseInt(number) != null ? Std.parseInt(number) + 1 : 0) + (!allSicks ? 0 : 11)], 0, false);
			//
			return comboNum;
		});
		*/

		var combo:FNFSprite = new FNFSprite();
		combo.loadGraphic(Paths.image(ForeverTools.returnSkinAsset(asset, assetModifier, changeableSkin, baseLibrary)), true, width, height);
		combo.animation.add('combo', [(Std.parseInt(number) != null ? Std.parseInt(number) + 1 : 0) + (!allSicks ? 0 : 11)], 0, false);

		combo.alpha = 1;
		combo.zDepth = -Conductor.songPosition;
		combo.screenCenter();
		combo.x += (43 * scoreInt) + 20;
		combo.y += 60;

		combo.color = FlxColor.WHITE;
		if (negative)
			combo.color = createdColor;

		if (assetModifier == 'pixel')
		{
			combo.antialiasing = false;
			combo.setGraphicSize(Std.int(combo.frameWidth * PlayState.daPixelZoom));
		}
		else
		{
			combo.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
			combo.setGraphicSize(Std.int(combo.frameWidth * 0.5));
		}
		combo.updateHitbox();
		combo.acceleration.y = FlxG.random.int(100, 200);
		combo.velocity.y = -FlxG.random.int(140, 160);
		combo.velocity.x = FlxG.random.float(-5, 5);

		combo.animation.play('combo');

		return combo;
	}

	public static function generateRating(newRating:String, perfect:Bool, lateHit:Bool, group:FlxTypedGroup<FNFSprite>, assetModifier:String = 'base', changeableSkin:String = 'default',
			baseLibrary:String):FNFSprite
	{
		/*
		var rating = group.recycle(FNFSprite, function()
		{
			var judge:FNFSprite = new FNFSprite();
			judge.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('judgements', assetModifier, changeableSkin, baseLibrary)), true,
				assetModifier == 'pixel' ? 72 : 500, assetModifier == 'pixel' ? 32 : 163);

			judge.animation.add(newRating, [
				Std.int((Timings.judgementsMap.get(newRating)[0] * 2) + (perfect ? 0 : 2) + (lateHit ? 1 : 0))
			], (assetModifier == 'pixel' ? 12 : 24), false);
			//
			return judge;
		});
		*/

		var rating:FNFSprite = new FNFSprite();
		rating.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('judgements', assetModifier, changeableSkin, baseLibrary)), true,
			assetModifier == 'pixel' ? 72 : 500, assetModifier == 'pixel' ? 32 : 163);

		rating.animation.add(newRating, [
			Std.int((Timings.judgementsMap.get(newRating)[0] * 2) + (perfect ? 0 : 2) + (lateHit ? 1 : 0))
		], (assetModifier == 'pixel' ? 12 : 24), false);

		rating.alpha = 1;
		rating.zDepth = -Conductor.songPosition;

		if (assetModifier == 'pixel')
		{
			rating.antialiasing = false;
			rating.setGraphicSize(Std.int(rating.frameWidth * PlayState.daPixelZoom * 0.7));
		}
		else
		{
			rating.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
			rating.setGraphicSize(Std.int(rating.frameWidth * 0.7));
		}

		rating.screenCenter();
		rating.x = (FlxG.width * 0.55) - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y = -FlxG.random.int(140, 175);
		rating.velocity.x = -FlxG.random.int(0, 10);

		rating.animation.play(newRating);

		return rating;
	}

	public static function generateNoteSplashes(asset:String, parentGroup:FlxTypedGroup<NoteSplash>, assetModifier:String = 'base', changeableSkin:String = 'default', baseLibrary:String,
			noteData:Int):NoteSplash
	{
		//
		var tempSplash:NoteSplash = parentGroup.recycle(NoteSplash);
		tempSplash.noteData = noteData;

		switch (assetModifier)
		{
			case 'pixel':
				asset = 'splash-pixel';

				tempSplash.loadGraphic(Paths.image(ForeverTools.returnSkinAsset(asset, assetModifier, changeableSkin, baseLibrary)), true, 34, 34);
				tempSplash.animation.add('anim1', [noteData, 4 + noteData, 8 + noteData, 12 + noteData], 24, false);
				tempSplash.animation.add('anim2', [16 + noteData, 20 + noteData, 24 + noteData, 28 + noteData], 24, false);
				tempSplash.animation.play('anim1');
				tempSplash.addOffset('anim1', -120, -90);
				tempSplash.addOffset('anim2', -120, -90);
				tempSplash.setGraphicSize(Std.int(tempSplash.width * PlayState.daPixelZoom));

			default:
				asset = 'noteSplashes';

				tempSplash.loadGraphic(Paths.image(ForeverTools.returnSkinAsset(asset, assetModifier, changeableSkin, baseLibrary)), true, 210, 210);
				tempSplash.animation.add('anim1', [
					(noteData * 2 + 1),
					8 + (noteData * 2 + 1),
					16 + (noteData * 2 + 1),
					24 + (noteData * 2 + 1),
					32 + (noteData * 2 + 1)
				], 24, false);
				tempSplash.animation.add('anim2', [
					(noteData * 2),
					8 + (noteData * 2),
					16 + (noteData * 2),
					24 + (noteData * 2),
					32 + (noteData * 2)
				], 24, false);
				tempSplash.animation.play('anim1');
				tempSplash.addOffset('anim1', -20, -10);
				tempSplash.addOffset('anim2', -20, -10);
		}
		
		parentGroup.sort(FNFSprite.depthSorting, FlxSort.DESCENDING);

		return tempSplash;
	}

	public static function generateUIArrows(x:Float, y:Float, ?staticArrowType:Int = 0, assetModifier:String):UIStaticArrow
	{
		var newStaticArrow:UIStaticArrow = new UIStaticArrow(x, y, staticArrowType);
		switch (assetModifier)
		{
			case 'pixel':
				// look man you know me I fucking hate repeating code
				// not even just a cleanliness thing it's just so annoying to tweak if something goes wrong like
				// genuinely more programmers should make their code more modular
				var framesArgument:String = "arrows-pixels";
				newStaticArrow.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('$framesArgument', assetModifier, Init.trueSettings.get("Note Skin"),
					'noteskins/notes')), true,
					17, 17);
				newStaticArrow.animation.add('static', [staticArrowType]);
				newStaticArrow.animation.add('pressed', [4 + staticArrowType, 8 + staticArrowType], 12, false);
				newStaticArrow.animation.add('confirm', [12 + staticArrowType, 16 + staticArrowType], 24, false);

				newStaticArrow.setGraphicSize(Std.int(newStaticArrow.width * PlayState.daPixelZoom));
				newStaticArrow.updateHitbox();
				newStaticArrow.antialiasing = false;

				newStaticArrow.addOffset('static', -67, -50);
				newStaticArrow.addOffset('pressed', -67, -50);
				newStaticArrow.addOffset('confirm', -67, -50);

			case 'chart editor':
				newStaticArrow.loadGraphic(Paths.image('UI/forever/base/chart editor/note_array'), true, 157, 156);
				newStaticArrow.animation.add('static', [staticArrowType]);
				newStaticArrow.animation.add('pressed', [16 + staticArrowType], 12, false);
				newStaticArrow.animation.add('confirm', [4 + staticArrowType, 8 + staticArrowType, 16 + staticArrowType], 24, false);

				newStaticArrow.addOffset('static');
				newStaticArrow.addOffset('pressed');
				newStaticArrow.addOffset('confirm');

			default:
				// probably gonna revise this and make it possible to add other arrow types but for now it's just pixel and normal
				var stringSect:String = '';
				// call arrow type I think
				stringSect = UIStaticArrow.getArrowFromNumber(staticArrowType);

				var framesArgument:String = "NOTE_assets";

				newStaticArrow.frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset('$framesArgument', assetModifier,
					Init.trueSettings.get("Note Skin"), 'noteskins/notes'));

				newStaticArrow.animation.addByPrefix('static', 'arrow' + stringSect.toUpperCase());
				newStaticArrow.animation.addByPrefix('pressed', stringSect + ' press', 24, false);
				newStaticArrow.animation.addByPrefix('confirm', stringSect + ' confirm', 24, false);

				newStaticArrow.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
				newStaticArrow.setGraphicSize(Std.int(newStaticArrow.width * 0.7));

				// set little offsets per note!
				// so these had a little problem honestly and they make me wanna off(set) myself so the middle notes basically
				// have slightly different offsets than the side notes (which have the same offset)

				var offsetMiddleX = 0;
				var offsetMiddleY = 0;
				if (staticArrowType > 0 && staticArrowType < 3)
				{
					offsetMiddleX = 2;
					offsetMiddleY = 2;
					if (staticArrowType == 1)
					{
						offsetMiddleX -= 1;
						offsetMiddleY += 2;
					}
				}

				newStaticArrow.addOffset('static');
				newStaticArrow.addOffset('pressed', -2, -2);
				newStaticArrow.addOffset('confirm', 36 + offsetMiddleX, 36 + offsetMiddleY);
		}

		return newStaticArrow;
	}

	/**
		Notes!
	**/
	public static function generateArrow(assetModifier, strumTime, noteData, noteAlt, ?isSustainNote:Bool = false, ?prevNote:Note = null,
			?noteType:String):Note
	{
		var newNote:Note;
		newNote = Note.returnDefaultNote(assetModifier, strumTime, noteData, noteAlt, isSustainNote, prevNote, noteType);

		// hold note shit
		if (isSustainNote && prevNote != null)
		{
			// set note offset
			if (prevNote.isSustainNote)
				newNote.noteVisualOffset = prevNote.noteVisualOffset;
			else // calculate a new visual offset based on that note's width and newnote's width
				newNote.noteVisualOffset = ((prevNote.width / 2) - (newNote.width / 2));
		}

		return newNote;
	}

	/**
		Checkmarks!
	**/
	public static function generateCheckmark(x:Float, y:Float, asset:String, assetModifier:String = 'base', changeableSkin:String = 'default',
			baseLibrary:String)
	{
		var newCheckmark:Checkmark = new Checkmark(x, y);
		newCheckmark.frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset(asset, assetModifier, changeableSkin, baseLibrary));
		newCheckmark.antialiasing = !Init.trueSettings.get('Disable Antialiasing');

		newCheckmark.animation.addByPrefix('false finished', 'uncheckFinished');
		newCheckmark.animation.addByPrefix('false', 'uncheck', 12, false);
		newCheckmark.animation.addByPrefix('true finished', 'checkFinished');
		newCheckmark.animation.addByPrefix('true', 'check', 12, false);
		newCheckmark.setGraphicSize(Std.int(newCheckmark.width * 0.7));
		newCheckmark.updateHitbox();
		newCheckmark.addOffset('false', 45, 5);
		newCheckmark.addOffset('true', 45, 5);
		newCheckmark.addOffset('true finished', 45, 5);
		newCheckmark.addOffset('false finished', 45, 5);
		return newCheckmark;
	}
}
