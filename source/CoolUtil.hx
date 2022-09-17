package;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;

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
		if (difficulties == null) {
			difficulties = PlayState.difficulties;
		}

		return difficulties[0][difficulties[isSuffix ? 2 : 1].indexOf(diff)];
	}

	public static function getDifficultyID(diff:String, ?isSuffix:Bool = false, ?difficulties:Array<Array<String>> = null):String
	{
		if (difficulties == null) {
			difficulties = PlayState.difficulties;
		}

		return difficulties[1][difficulties[isSuffix ? 2 : 0].indexOf(diff)];
	}

	public static function getDifficultySuffix(diff:String, ?isName:Bool = false, ?difficulties:Array<Array<String>> = null):String
	{
		if (difficulties == null) {
			difficulties = PlayState.difficulties;
		}

		return difficulties[2][difficulties[isName ? 0 : 1].indexOf(diff)];
	}

	public static function quantize(f:Float, snap:Float):Float
	{
		return (Math.fround(f * snap) / snap);
	}

	public static function formatSong(song:String, diff:String):String
	{
		return (song + '-' + diff).toLowerCase();
	}

	public static function getKeyName(key:FlxKey):String
	{
		switch (key)
		{
			case BACKSPACE: return "BckSpc";
			case CONTROL: return "Ctrl";
			case ALT: return "Alt";
			case CAPSLOCK: return "Caps";
			case PAGEUP: return "PgUp";
			case PAGEDOWN: return "PgDown";
			case ZERO: return "0";
			case ONE: return "1";
			case TWO: return "2";
			case THREE: return "3";
			case FOUR: return "4";
			case FIVE: return "5";
			case SIX: return "6";
			case SEVEN: return "7";
			case EIGHT: return "8";
			case NINE: return "9";
			case NUMPADZERO: return "#0";
			case NUMPADONE: return "#1";
			case NUMPADTWO: return "#2";
			case NUMPADTHREE: return "#3";
			case NUMPADFOUR: return "#4";
			case NUMPADFIVE: return "#5";
			case NUMPADSIX: return "#6";
			case NUMPADSEVEN: return "#7";
			case NUMPADEIGHT: return "#8";
			case NUMPADNINE: return "#9";
			case NUMPADMULTIPLY: return "#*";
			case NUMPADPLUS: return "#+";
			case NUMPADMINUS: return "#-";
			case NUMPADPERIOD: return "#.";
			case SEMICOLON: return ";";
			case COMMA: return ",";
			case PERIOD: return ".";
			case GRAVEACCENT: return "`";
			case LBRACKET: return "[";
			case RBRACKET: return "]";
			case QUOTE: return "'";
			case PRINTSCREEN: return "PrtScrn";
			case NONE: return '---';
			default:
			{
				var label:String = '' + key;

				if (label.toLowerCase() == 'null') {
					return '---';
				}
		
				return '' + label.charAt(0).toUpperCase() + label.substr(1).toLowerCase();
			} 
		}
	}

	@:deprecated("`CoolUtil.interpolateColor()` is deprecated, use 'FlxTween.color()' instead")
	public static function interpolateColor(from:FlxColor, to:FlxColor, speed:Float = 0.045, multiplier:Float = 54.5):FlxColor
	{
		return FlxColor.interpolate(from, to, boundTo(FlxG.elapsed * (speed * multiplier), 0, 1));
	}

	public static function coolLerp(a:Float, b:Float, ratio:Float, multiplier:Float = 54.5, ?integerShitKillMeLoopWhatEver:Null<Float> = null):Float
	{
		if (integerShitKillMeLoopWhatEver != null) {
			return FlxMath.lerp(a, b, boundTo(integerShitKillMeLoopWhatEver - (FlxG.elapsed * (ratio * multiplier)), 0, 1));
		}

		return FlxMath.lerp(a, b, boundTo(FlxG.elapsed * (ratio * multiplier), 0, 1));
	}

	public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	@:deprecated("`CoolUtil.truncateFloat()` is deprecated, use `CoolUtil.floorDecimal()` or 'FlxMath.roundDecimal()' instead")
	public static function truncateFloat(number:Float, precision:Int):Float
	{
		var num:Float = number;

		if (Math.isNaN(num)) num = 0;

		num = num * Math.pow(10, precision);
		num = Math.round(num) / Math.pow(10, precision);

		return num;
	}

	public static function floorDecimal(number:Float, precision:Int = 0):Float
	{
		if (Math.isNaN(number)) number = 0;

		if (precision < 1) {
			return Math.floor(number);
		}

		var tempMult:Float = 1;

		for (i in 0...precision) {
			tempMult *= 10;
		}

		return Math.floor(number * tempMult) / tempMult;
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];

		#if sys
		if (FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if (Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length) {
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length) {
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];

		for (i in min...max) {
			dumbArray.push(i);
		}

		return dumbArray;
	}

	public static function browserLoad(site:String):Void
	{
		if (site.contains('dQw4w9WgXcQ'))
		{
			trace('lololololololol');
			trace("you've been rick rolled lol");
			trace("NEVER");
			trace("GONNA");
			trace("GIVE");
			trace("YOU");
			trace("UP");
			trace("NEVER");
			trace("GONNA");
			trace("LET");
			trace("YOU");
			trace("DOWN");
		}

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