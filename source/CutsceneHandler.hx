package;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import flixel.group.FlxSpriteGroup;
import animateatlas.AtlasFrameMaker;
import flixel.graphics.atlas.FlxAtlas;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class CutsceneHandler extends FlxBasic
{
	public var timedEvents:Array<Dynamic> = [];

	public var finishCallback:Void->Void = null;
	public var finishCallback2:Void->Void = null;

	public var onStart:Void->Void = null;
	public var endTime:Float = 0;
	public var objects:Array<FlxSprite> = [];
	public var music:String = null;

	public function new():Void
	{
		super();

		timer(0, function()
		{
			if (music != null)
			{
				FlxG.sound.playMusic(Paths.music(music), 0, false);
				FlxG.sound.music.fadeIn();
			}

			if (onStart != null) onStart();
		});

		PlayState.instance.add(this);
	}

	private var cutsceneTime:Float = 0;
	private var firstFrame:Bool = false;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.state != PlayState.instance || !firstFrame)
		{
			firstFrame = true;
			return;
		}

		cutsceneTime += elapsed;

		if (endTime <= cutsceneTime)
		{
			finishCallback();
			if (finishCallback2 != null) finishCallback2();

			for (spr in objects)
			{
				spr.kill();
				PlayState.instance.remove(spr);
				spr.destroy();
			}
			
			kill();
			destroy();

			PlayState.instance.remove(this);
		}
		
		while (timedEvents.length > 0 && timedEvents[0][0] <= cutsceneTime)
		{
			timedEvents[0][1]();
			timedEvents.splice(0, 1);
		}
	}

	public function push(spr:FlxSprite):Void
	{
		objects.push(spr);
	}

	public function timer(time:Float, func:Void->Void):Void
	{
		timedEvents.push([time, func]);
		timedEvents.sort(sortByTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}
}