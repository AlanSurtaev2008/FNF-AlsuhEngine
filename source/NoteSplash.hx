package;

import flixel.FlxG;
import flixel.FlxSprite;
import shaders.ColorSwap;

class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = null;

	private var idleAnim:String;
	private var textureLoaded:String = null;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0):Void
	{
		super(x, y);

		var skin:String = 'noteSplashes';
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		loadAnims(skin);
		
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		setupNoteSplash(x, y, note);

		antialiasing = OptionData.globalAntialiasing;
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0):Void
	{
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		alpha = 0.6;

		if (texture == null)
		{
			texture = 'noteSplashes';
			if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
		}

		if (textureLoaded != texture)
		{
			loadAnims(texture);
		}

		colorSwap.hue = hueColor;
		colorSwap.saturation = satColor;
		colorSwap.brightness = brtColor;

		offset.set(10, 10);

		var animNum:Int = FlxG.random.int(1, 2);
		animation.play('note' + note + '-' + animNum, true);
		animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
	}

	function loadAnims(skin:String):Void
	{
		frames = Paths.getSparrowAtlas('notes/' + skin);

		animation.addByPrefix("note0-1", "note impact 1 purple", 24, false);
		animation.addByPrefix("note1-1", "note impact 1 blue", 24, false);
		animation.addByPrefix("note2-1", "note impact 1 green", 24, false);
		animation.addByPrefix("note3-1", "note impact 1 red", 24, false);

		animation.addByPrefix("note0-2", "note impact 2 purple", 24, false);
		animation.addByPrefix("note1-2", "note impact 2 blue", 24, false);
		animation.addByPrefix("note2-2", "note impact 2 green", 24, false);
		animation.addByPrefix("note3-2", "note impact 2 red", 24, false);
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (animation.curAnim.finished) kill();
	}
}