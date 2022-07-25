package;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import haxe.Json;
import lime.utils.Assets;
import Section.SwagSection;
import haxe.format.JsonParser;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var songID:String;
	var songName:String;

	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;

	var needsVoices:Bool;

	var bpm:Float;
	var speed:Float;

	var player1:String;
	var player2:String;
	var player3:String;
	var gfVersion:String;
	var stage:String;

	var arrowSkin:String;
	var splashSkin:String;
}

class Song
{
	public static function onLoadJson(songJson:Dynamic):Void
	{
		if (songJson.songID == null)
		{
			songJson.songID = StringTools.replace(' ', '-', songJson.song.toLowerCase());
		}

		if (songJson.songName == null)
		{
			songJson.songName = StringTools.replace('-', ' ', songJson.song);
		}

		if (songJson.gfVersion == null) // from Psych Chars
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if (songJson.events == null) // from Psych Chars
		{
			songJson.events = [];

			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;

				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];

					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);

						len = notes.length;
					}
					else
					{
						i++;
					}
				}
			}
		}
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson:String = null;

		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(folder + '/' + jsonInput);

		if (FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end
		if (rawJson == null)
		{
			#if sys
			rawJson = File.getContent(Paths.json(folder + '/' + jsonInput)).trim();
			#else
			rawJson = Assets.getText(Paths.json(folder + '/' + jsonInput)).trim();
			#end
		}

		while (!rawJson.endsWith('}'))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		var songJson:SwagSong = parseJSONshit(rawJson);

		if (jsonInput != 'events') {
			StageData.loadDirectory(songJson);
		}

		onLoadJson(songJson);

		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		return cast Json.parse(rawJson).song;
	}
}
