package;

import haxe.Json;

#if sys
import sys.io.File;
#end

import flixel.FlxG;
import lime.utils.Assets;
import openfl.events.Event;
import flixel.util.FlxColor;
import openfl.utils.Dictionary;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;

typedef KeyPress =
{
	public var time:Float;
	public var key:String;
}

typedef KeyRelease =
{
	public var time:Float;
	public var key:String;
}

typedef ReplayJSON =
{
	public var timestamp:Date;
	public var weekID:String;
	public var weekName:String;
	public var songID:String;
	public var songName:String;
	public var songDiff:String;
	public var difficulties:Array<Array<String>>;
	public var songNotes:Array<Float>;
	public var keyPresses:Array<KeyPress>;
	public var keyReleases:Array<KeyRelease>;

	public var noteSpeed:Float;
	public var isDownscroll:Bool;
}

class Replay
{
	public var path:String = "";
	public var replay:ReplayJSON;

	public function new(path:String)
	{
		this.path = path;

		replay = {
			songID: "tutorial",
			songName: "Tutorial", 
			songDiff: 'normal',
			difficulties: [
				['Easy',	'Normal',	'Hard'],
				['easy',	'normal',	'hard'],
				['-easy',	'',			'-hard']
			],
			weekID: 'tutorial',
			weekName: 'Tutorial',
			noteSpeed: 1.5,
			isDownscroll: false,
			keyPresses: [],
			songNotes: [],
			keyReleases: [],
			timestamp: Date.now()
		};
	}

	public static function loadReplay(path:String):Replay
	{
		var rep:Replay = new Replay(path);
		rep.roadFromJson();

		return rep;
	}

	public function saveReplay(noteArray:Array<Float>):Void
	{
		var json = {
			"songID": PlayState.SONG.songID,
			"songName": PlayState.SONG.songName,
			"weekID": PlayState.storyWeek,
			"weekName": PlayState.storyWeekName,
			"songDiff": PlayState.lastDifficulty,
			"difficulties": PlayState.difficulties,
			"songNotes": noteArray,
			"keyPresses": replay.keyPresses,
			"keyReleases": replay.keyReleases,
			"noteSpeed": (OptionData.scrollSpeed > 1 ? OptionData.scrollSpeed : PlayState.SONG.speed),
			"isDownscroll": OptionData.downScroll,
			"timestamp": Date.now()
		};

		var data:String = Json.stringify(json);

		#if sys
		File.saveContent("assets/replays/replay-" + PlayState.SONG.songID + '-' + PlayState.lastDifficulty + "-time-" + Date.now().getTime() + ".rep", data);
		#end
	}

	public function roadFromJson():Void
	{
		#if sys
		try
		{
			var repl:ReplayJSON = cast Json.parse(File.getContent(Sys.getCwd() + "assets\\replays\\" + path));
			replay = repl;
		}
		catch (e:Dynamic)
		{
			// noting
		}
		#end
	}
}