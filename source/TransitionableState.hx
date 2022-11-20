package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxColor;

using StringTools;

class TransitionableState extends FlxState
{
	private var controls(get, never):Controls;

	inline function get_controls():Controls {
		return PlayerSettings.player1.controls;
	}

	public override function create():Void
	{
		super.create();

		if (!Transition.skipNextTransOut)
		{
			onTransOut();

			Transition.finishCallback = onTransOutFinished;
			openSubState(new Transition(0.7, true));
		}

		Transition.skipNextTransOut = false;
	}

	var array:Array<FlxColor> = [
		FlxColor.fromRGB(148, 0, 211),
		FlxColor.fromRGB(75, 0, 130),
		FlxColor.fromRGB(0, 0, 255),
		FlxColor.fromRGB(0, 255, 0),
		FlxColor.fromRGB(255, 255, 0),
		FlxColor.fromRGB(255, 127, 0),
		FlxColor.fromRGB(255, 0 , 0)
	];

	public static var currentColor:Int = 0;
	public static var currentColor2:Int = 0;

	var skippedFrames:Int = 0;
	var skippedFrames2:Int = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if !mobile
		if (OptionData.rainFPS && skippedFrames >= 6)
		{
			if (currentColor >= array.length) {
				currentColor = 0;
			}

			Main.fpsCounter.textColor = array[currentColor];

			currentColor++;
			skippedFrames = 0;
		}
		else {
			skippedFrames++;
		}

		if (OptionData.rainMemory && skippedFrames >= 6)
		{
			if (currentColor2 >= array.length) {
				currentColor2 = 0;
			}

			Main.memoryCounter.textColor = array[currentColor2];

			currentColor2++;
			skippedFrames2 = 0;
		}
		else {
			skippedFrames2++;
		}
		#end
	}

	public function onTransIn():Void
	{
		// override per subclass
	}

	public function onTransInFinished():Void
	{
		// override per subclass
	}

	public function onTransOut():Void
	{
		// override per subclass
	}

	public function onTransOutFinished():Void
	{
		// override per subclass
	}

	var exiting:Bool = false;

	public override function switchTo(nextState:FlxState):Bool
	{
		if (!Transition.skipNextTransIn)
		{
			onTransIn();

			if (!exiting)
			{
				openSubState(new Transition(0.6, false));

				if (nextState == FlxG.state)
				{
					Transition.finishCallback = function():Void
					{
						onTransInFinished();

						exiting = true;
						FlxG.switchState(nextState);
					};
				}
				else
				{
					Transition.finishCallback = function():Void
					{
						onTransInFinished();

						exiting = true;
						FlxG.switchState(nextState);
					};
				}
			}

			return exiting;
		}
		else {
			Transition.skipNextTransIn = false;
		}

		return true;
	}
}