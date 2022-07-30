package;

import flixel.FlxG;
import flixel.math.FlxMath;
import openfl.utils.Assets;
import flixel.system.FlxSound;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;

#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

using StringTools;

class CoolUtil
{
	public static function getDifficultyName(diff:String, isSuffix:Bool = false, ?difficulties:Array<Array<String>> = null):String
	{
		if (difficulties == null)
		{
			difficulties = PlayState.difficulties;
		}

		return difficulties[0][difficulties[isSuffix ? 2 : 1].indexOf(diff)];
	}

	public static function getDifficultyID(diff:String, ?isSuffix:Bool = false, ?difficulties:Array<Array<String>> = null):String
	{
		if (difficulties == null)
		{
			difficulties = PlayState.difficulties;
		}

		return difficulties[1][difficulties[isSuffix ? 2 : 0].indexOf(diff)];
	}

	public static function getDifficultySuffix(diff:String, ?isName:Bool = false, ?difficulties:Array<Array<String>> = null):String
	{
		if (difficulties == null)
		{
			difficulties = PlayState.difficulties;
		}

		return difficulties[2][difficulties[isName ? 0 : 1].indexOf(diff)];
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
		var daList:Array<String> = [];

		#if sys
		if (FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if (Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

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
		Paths.getImage(image, library);
	}

	public static function precacheSound(sound:String, ?library:String = null):Void
	{
		Paths.getSound(sound, library);
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void
	{
		Paths.getMusic(sound, library);
	}
}
