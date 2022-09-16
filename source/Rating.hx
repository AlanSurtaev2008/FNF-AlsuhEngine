package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;

using StringTools;

class Rating extends FlxSprite
{
	public var rating:String = 'sick';

	public function new(rating:String, suffix:String, coolText:FlxText):Void
	{
		super();

		this.rating = rating;

		loadGraphic(Paths.getImage('ratings/' + rating + suffix));

		screenCenter();

		x = coolText.x - 125;
		y -= 60;

		acceleration.y = 550;

		velocity.x -= FlxG.random.int(0, 10);
		velocity.y -= FlxG.random.int(140, 175);

		setGraphicSize(Std.int(width * (suffix.contains('pixel') ? PlayState.daPixelZoom * 0.7 : 0.7)));

		antialiasing = suffix.contains('pixel') ? false : OptionData.globalAntialiasing;

		goToVisible();

		x += OptionData.comboOffset[0];
		y -= OptionData.comboOffset[1];

		updateHitbox();
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		goToVisible();
	}

	public function goToVisible():Void
	{
		var iCanSayShit:Bool = (rating == 'shit' && !OptionData.naughtyness);
		visible = iCanSayShit ? false : OptionData.showRatings;
	}
}