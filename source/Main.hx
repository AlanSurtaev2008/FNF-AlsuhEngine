package;

#if !mobile
import counters.FPSCounter;
import counters.MemoryCounter;
#end

import openfl.Lib;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.events.Event;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;

using StringTools;

class Main extends Sprite
{
	public var game:FlxGame;

	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	#if !mobile
	public static var fpsCounter:FPSCounter;
	public static var memoryCounter:MemoryCounter;
	#end

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new():Void
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;

			zoom = Math.min(ratioX, ratioY);

			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		#if !debug
		initialState = TitleState;
		#end

		OptionData.loadDefaultKeys();

		game = new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen);
		addChild(game);

		OptionData.loadPrefs();

		#if !mobile
		fpsCounter = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsCounter);

		if (fpsCounter != null) {
			fpsCounter.visible = OptionData.fpsCounter;
		}

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		memoryCounter = new MemoryCounter(10, 3, 0xFFFFFF);
		addChild(memoryCounter);

		if (memoryCounter != null) {
			memoryCounter.visible = OptionData.memoryCounter;
		}
		#end
	}
}