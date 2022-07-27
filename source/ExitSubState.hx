package;

import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class ExitSubState extends MusicBeatSubState
{
	override function create():Void
	{
		super.create();

		#if sys
		var blackBG:FlxSprite = new FlxSprite(0, 0);
		blackBG.makeGraphic(FlxG.width * 4, FlxG.height * 4, 0xFF000000);
		blackBG.alpha = 0.6;
		blackBG.screenCenter();
		add(blackBG);

		var rebindBG:FlxSprite = new FlxSprite(0, 100);
		rebindBG.makeGraphic(Std.int(FlxG.width * 0.85), 520, 0xFFFAFD6D);
		rebindBG.screenCenter(X);
		add(rebindBG);

		var rebindText:Alphabet = new Alphabet(0, 185, "Press any key to exit", true, false);
		rebindText.screenCenter(X);
		add(rebindText);

		var rebindText2:Alphabet = new Alphabet(0, 500, "Escape to cancel", true, false);
		rebindText2.screenCenter(X);
		add(rebindText2);
		#end
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if sys
		var keyPressed:Int = FlxG.keys.firstJustPressed();

		if (keyPressed > -1)
		{
			if (keyPressed != 27) {
				Sys.exit(0);
			} else {
				close();
			}
		}
		#end
	}
}