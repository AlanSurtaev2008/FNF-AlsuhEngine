package;

import flixel.util.FlxColor;
import flixel.addons.ui.FlxUISubState;

using StringTools;

class MusicBeatUISubState extends FlxUISubState
{
	private var stepsToDo:Int = 0;

	private var curStep(default, null):Int = 0;
	private var curBeat(default, null):Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	private var controls(get, never):Controls;

	inline function get_controls():Controls
	{
		return PlayerSettings.player1.controls;
	}

	public override function create():Void
	{
		super.create();
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

		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
		{
			stepHit();
		}

		if (OptionData.rainFPS && skippedFrames >= 6)
		{
			if (currentColor >= array.length) {
				currentColor = 0;
			}

			Main.fpsCounter.textColor = array[currentColor];

			currentColor++;
			skippedFrames = 0;
		}
		else
		{
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
		else
		{
			skippedFrames2++;
		}
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - OptionData.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0) {
			beatHit();
		}
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}
}
