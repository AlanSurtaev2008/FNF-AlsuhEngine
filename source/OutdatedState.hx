package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

class OutdatedState extends MusicBeatState
{
	public static var leftState:Bool = false;

	public static var newVersion:String = 'lol';
	public static var curChanges:String = "dk";

	public override function create():Void
	{
		super.create();

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		bg.antialiasing = OptionData.globalAntialiasing;
		bg.color = 0xFF0F0F0F;
		add(bg);

		var txt:FlxText = new FlxText(0, 0, FlxG.width, "Your used version " + MainMenuState.engineVersion + "\nof Alsuh Engine is outdated."
			+ "\nUse the latest version " + newVersion
			+ ".\n\nWhat new?\n\n" + curChanges + "\n\nPress ENTER to download latest version\nor ESCAPE to ignorite this message.", 32);
		txt.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
		txt.screenCenter();
		add(txt);
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			leftState = true;

			FlxG.switchState(new MainMenuState());
			FlxG.sound.play(Paths.getSound('cancelMenu'));
		}
		else if (controls.ACCEPT)
		{
			CoolUtil.browserLoad('https://github.com/AlanSurtaev2008/FNF-AlsuhEngine/releases/latest');
		}
	}
}