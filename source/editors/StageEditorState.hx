package editors;

import haxe.Json;

#if desktop
import Discord.DiscordClient;
#end

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import openfl.events.Event;
import flixel.util.FlxColor;
import lime.system.Clipboard;
import flixel.group.FlxGroup;
import flixel.addons.ui.FlxUI;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;
import flixel.graphics.FlxGraphic;
import animateatlas.AtlasFrameMaker;
import flixel.addons.ui.FlxUITabMenu;
import flixel.animation.FlxAnimation;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;

using StringTools;

/**
 * Alan is here, we need your pull request with stage editor for StageSpriteData.hx.
 */
class StageEditorState extends MusicBeatUIState
{
	var txt:FlxText;

	override function create():Void
	{
		super.create();

		FlxG.mouse.visible = true;

		txt = new FlxText(0, 0, FlxG.width, "Alan is here, we need your pull request\nwith stage editor for StageSpriteData.hx.\n\nPress ENTER to Github Page, ESCAPE to exit.", 32);
		txt.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
		txt.scrollFactor.set();
		txt.screenCenter();
		txt.borderSize = 2.4;
		add(txt);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER) {
			CoolUtil.browserLoad('https://github.com/AlanSurtaev2008/FNF-AlsuhEngine');
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.music.volume = 0;
			FlxG.mouse.visible = false;

			FlxG.switchState(new MasterEditorMenu());
		}
	}
}