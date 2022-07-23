package;

import flixel.FlxG;

class Highscore
{
	private static var weekScores:Map<String, Int> = #if (haxe >= "4.0.0") new Map() #else new Map<String, Int>() #end;
	private static var songScores:Map<String, Int> = #if (haxe >= "4.0.0") new Map() #else new Map<String, Int>() #end;
	private static var songAccuracy:Map<String, Float> #if (haxe >= "4.0.0") = new Map() #else new Map<String, Float>() #end;

	public static function resetSong(song:String):Void
	{
		setScore(song, 0);
		setAccuracy(song, 0);
	}

	public static function resetWeek(week:String):Void
	{
		setWeekScore(week, 0);
	}

	public static function saveWeekScore(week:String, score:Int = 0):Void
	{
		if (weekScores.exists(week) == true)
		{
			if (weekScores.get(week) < score)
			{
				setWeekScore(week, score);
			}
		}
		else
		{
			setWeekScore(week, score);
		}
	}

	public static function getWeekScore(week:String):Int
	{
		if (weekScores.exists(week) == false)
		{
			weekScores.set(week, 0);
		}

		return weekScores.get(week);
	}

	public static function setWeekScore(week:String, score:Int = 0):Void
	{
		weekScores.set(week, score);

		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	public static function saveScore(daSong:String, score:Int = 0):Void
	{
		if (songScores.exists(daSong) == true)
		{
			if (songScores.get(daSong) < score)
			{
				setScore(daSong, score);
			}
		}
		else
		{
			setScore(daSong, score);
		}
	}

	public static function getScore(daSong:String):Int
	{
		if (songScores.exists(daSong) == false)
		{
			songScores.set(daSong, 0);
		}

		return songScores.get(daSong);
	}

	private static function setScore(daSong:String, score:Int = 0):Void
	{
		songScores.set(daSong, score);

		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	public static function saveAccuracy(daSong:String, accuracy:Float):Void
	{
		if (accuracy >= 0) setAccuracy(daSong, accuracy);
	}

	public static function getAccuracy(daSong:String):Float 
	{
		if (songAccuracy.exists(daSong) == false)
		{
			songAccuracy.set(daSong, 0);
		}

		return songAccuracy.get(daSong);
	}

	private static function setAccuracy(daSong:String, accuracy:Float):Void
	{
		songAccuracy.set(daSong, accuracy);

		FlxG.save.data.songAccuracy = songAccuracy;
		FlxG.save.flush();
	}

	public static function load():Void 
	{
		if (FlxG.save.data.weekScores != null){
			weekScores = FlxG.save.data.weekScores;
		}
		if (FlxG.save.data.songScores != null) {
			songScores = FlxG.save.data.songScores;
		}
		if (FlxG.save.data.songAccuracy != null) {
			songAccuracy = FlxG.save.data.songAccuracy;
		}
	}
}