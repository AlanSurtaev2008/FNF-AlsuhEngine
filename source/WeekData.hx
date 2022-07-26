package;

#if MODS_ALLOWED
import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
#end

import haxe.Json;
import lime.utils.Assets;
import haxe.format.JsonParser;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

typedef WeekFile =
{
	var weekID:String;
	var weekName:String;

	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;

	var songs:Array<SongLabel>;

	var difficulties:Array<Array<String>>;
	var defaultDifficulty:String;

	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var itemFile:String;

	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
}

typedef SongLabel =
{
	var songID:String;
	var songName:String;

	var character:String;
	var color:Array<Int>;

	var difficulties:Array<Array<String>>;
	var defaultDifficulty:String;
}

class WeekData
{
	public static var weeksList:Array<String> = [];

	public static var weeksLoaded:Map<String, WeekData> = #if (haxe >= "4.0.0") new Map() #else new Map<String, WeekData>() #end;
	public static var weekCompleted:Map<String, Bool> = #if (haxe >= "4.0.0") new Map() #else new Map<String, Bool>() #end;

	public var folder:String = '';

	public var weekID:String;
	public var weekName:String;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var songs:Array<SongLabel>;
	public var difficulties:Array<Array<String>>;
	public var defaultDifficulty:String;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var itemFile:String;
	public var storyName:String;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;

	public function new(weekFile:WeekFile):Void
	{
		weekID = weekFile.weekID;
		weekName = weekFile.weekName;
		startUnlocked = weekFile.startUnlocked;
		hiddenUntilUnlocked = weekFile.hiddenUntilUnlocked;
		songs = weekFile.songs;
		difficulties = weekFile.difficulties;
		defaultDifficulty = weekFile.defaultDifficulty;
		weekCharacters = weekFile.weekCharacters;
		weekBackground = weekFile.weekBackground;
		weekBefore = weekFile.weekBefore;
		itemFile = weekFile.itemFile;
		storyName = weekFile.storyName;
		hideStoryMode = weekFile.hideStoryMode;
		hideFreeplay = weekFile.hideFreeplay;
	}

	public static function createWeekFile():WeekFile
	{
		return {
			songs: [
				{
					songID: 'bopeebo',
					songName: 'Bopeebo',
					character: 'dad',
					color: [146, 113, 253],
					difficulties: [
						['Easy',	'Normal',	'Hard'],
						['easy',	'normal',	'hard'],
						['-easy',	'',			'-hard']
					],
					defaultDifficulty: 'normal',
				},
				{
					songID: 'fresh',
					songName: 'Fresh',
					character: 'dad',
					color: [146, 113, 253],
					difficulties: [
						['Easy',	'Normal',	'Hard'],
						['easy',	'normal',	'hard'],
						['-easy',	'',			'-hard']
					],
					defaultDifficulty: 'normal',
				},
				{
					songID: 'dad-battle',
					songName: 'Dad Battle',
					character: 'dad',
					color: [146, 113, 253],
					difficulties: [
						['Easy',	'Normal',	'Hard'],
						['easy',	'normal',	'hard'],
						['-easy',	'',			'-hard']
					],
					defaultDifficulty: 'normal',
				}
			],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			itemFile: 'week1',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			weekID: 'custom-week',
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: [
				['Easy',	'Normal',	'Hard'],
				['easy',	'normal',	'hard'],
				['-easy',	'',			'-hard']
			],
			defaultDifficulty: 'normal'
		};
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false):Void
	{
		weeksList = [];

		weeksLoaded.clear();

		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getPreloadPath()];
		var originalLength:Int = directories.length;

		if (FileSystem.exists(Paths.mods()))
		{
			for (folder in FileSystem.readDirectory(Paths.mods()))
			{
				var path = Path.join([Paths.mods(), folder]);

				if (sys.FileSystem.isDirectory(path) && !Paths.ignoreModFolders.contains(folder))
				{
					directories.push(path + '/');
				}
			}
		}
		#else
		var directories:Array<String> = [Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		#end

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('weeks/weekList.txt'));

		for (i in 0...sexList.length)
		{
			for (j in 0...directories.length)
			{
				var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';

				if (!weeksLoaded.exists(sexList[i]))
				{
					var week:WeekFile = getWeekFile(fileToCheck);

					if (week != null)
					{
						var weekFile:WeekData = new WeekData(week);

						#if MODS_ALLOWED
						if (j >= originalLength)
						{
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length-1);
						}
						#end

						if (weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay)))
						{
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length)
		{
			var directory:String = directories[i] + 'weeks/';

			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = Path.join([directory, file]);

					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var weekToCheck:String = file.substr(0, file.length - 5);

						if (!weeksLoaded.exists(weekToCheck))
						{
							var week:WeekFile = getWeekFile(path);

							if (week != null)
							{
								var weekFile:WeekData = new WeekData(week);

								if (i >= originalLength)
								{
									weekFile.folder = directories[i].substring(Paths.mods().length, directories[i].length-1);
								}

								if ((isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay)) 
								{
									weeksLoaded.set(weekToCheck, weekFile);
									weeksList.push(weekToCheck);
								}
							}
						}
					}
				}
			}
		}
		#end
	}

	public static function getWeekFile(path:String):WeekFile
	{
		var rawJson:String = null;

		#if MODS_ALLOWED
		if (FileSystem.exists(path))
		{
			rawJson = File.getContent(path);
		}
		#else
		if (OpenFlAssets.exists(path))
		{
			rawJson = Assets.getText(path);
		}
		#end

		if (rawJson != null && rawJson.length > 0)
		{
			return cast Json.parse(rawJson);
		}

		return null;
	}

	public static function weekIsLocked(name:String):Bool
	{
		return (!weeksLoaded.get(name).startUnlocked && weeksLoaded.get(name).weekBefore.length > 0 &&
			(!weekCompleted.exists(weeksLoaded.get(name).weekBefore) || !weekCompleted.get(weeksLoaded.get(name).weekBefore)));
	}

	public static function setDirectoryFromWeek(?data:WeekData = null):Void
	{
		Paths.currentModDirectory = '';

		if (data != null && data.folder != null && data.folder.length > 0)
		{
			Paths.currentModDirectory = data.folder;
		}
	}
}