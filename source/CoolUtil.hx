package;

import flixel.FlxG;
import lime.utils.Assets;
import flixel.math.FlxMath;

using StringTools;

class CoolUtil
{
	public static function getDifficultyName(diff:String, ?difficulties:Array<Array<String>> = null):String
	{
		if (difficulties == null)
		{
			difficulties = PlayState.difficulties;
		}

		return difficulties[0][difficulties[1].indexOf(diff.toLowerCase())];
	}

	public static function getDifficultyID(diff:String, ?isPrefix:Bool = false, ?difficulties:Array<Array<String>> = null):String
	{
		if (difficulties == null)
		{
			difficulties = PlayState.difficulties;
		}

		return difficulties[1][difficulties[isPrefix ? 2 : 0].indexOf(diff.toLowerCase())];
	}

	public static function getDifficultySuffix(diff:String, ?difficulties:Array<Array<String>> = null):String
	{
		if (difficulties == null)
		{
			difficulties = PlayState.difficulties;
		}

		return difficulties[2][difficulties[1].indexOf(diff.toLowerCase())];
	}

	public static function formatSong(song:String, diff:String):String
	{
		return song + '-' + diff;
	}

	public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	public static function truncateFloat(number:Float, precision:Int):Float
	{
		var num:Float = number;

		if (Math.isNaN(num)) num = 0;

		num = num * Math.pow(10, precision);
		num = Math.round(num) / Math.pow(10, precision);

		return num;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
		{
			return Math.floor(value);
		}

		var tempMult:Float = 1;

		for (i in 0...decimals)
		{
			tempMult *= 10;
		}

		var newValue:Float = Math.floor(value * tempMult);

		return newValue / tempMult;
	}

	public static function GCD(a, b)
	{
		return b == 0 ? FlxMath.absInt(a) : GCD(b, a % b);
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];

		for (i in min...max)
		{
			dumbArray.push(i);
		}

		return dumbArray;
	}

	public static function browserLoad(site:String):Void
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function precacheImage(image:String, ?library:String = null):Void
	{
		Paths.image(image, library);
	}

	public static function precacheSound(sound:String, ?library:String = null):Void
	{
		Paths.sound(sound, library);
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void
	{
		Paths.music(sound, library);
	}
}
