package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxDestroyUtil;

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

class RatingData
{
	public var name:String = '';
	public var image:String = '';
	public var counter:String = '';

	public var hitWindow(get, default):Null<Int> = 0; //ms
	public var ratingMod:Float = 1;

	public var score:Int = 350;

	public var noteSplash:Bool = true;

	public function new(name:String):Void
	{
		this.name = name;
		this.image = name;
		this.counter = name + 's';

		if (hitWindow == null) {
			hitWindow = 0;
		}
	}

	public function get_hitWindow():Null<Int>
	{
		if (Reflect.hasField(OptionData, name + 'Window')) {
			return Reflect.field(OptionData, name + 'Window');
		}

		return 0;
	}

	public function increase(blah:Int = 1):Void
	{
		Reflect.setField(PlayState.instance, counter, Reflect.field(PlayState.instance, counter) + blah);
	}
}