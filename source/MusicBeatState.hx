package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxColor;
import Conductor.BPMChangeEvent;
import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
	{
		return PlayerSettings.player1.controls;
	}

	override function create():Void
	{
		super.create();

		if (!FlxTransitionableState.skipNextTransOut)
		{
			openSubState(new CustomFadeTransition(0.7, true));
		}

		FlxTransitionableState.skipNextTransOut = false;
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

	override function update(elapsed:Float):Void
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
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
			{
				lastChange = Conductor.bpmChangeMap[i];
			}
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public static function switchState(nextState:FlxState):Void
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;

		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(0.6, false));

			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.resetState();
				};
			}
			else
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.switchState(nextState);
				};
			}

			return;
		}

		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState():Void
	{
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;

		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
		{
			beatHit();
		}
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}
}
