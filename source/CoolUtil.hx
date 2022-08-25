package;

import flixel.FlxG;
import flixel.math.FlxMath;
import openfl.utils.Assets;
import flixel.util.FlxColor;
import flixel.system.FlxSound;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import flixel.input.keyboard.FlxKey;
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

	public static function quantize(f:Float, snap:Float):Float
	{
		return (Math.fround(f * snap) / snap);
	}

	public static function formatSong(song:String, diff:String):String
	{
		return Paths.formatToSongPath(song + '-' + diff);
	}

	public static function getKeyName(key:FlxKey):String
	{
		return switch (key)
		{
			case BACKSPACE: "BckSpc";
			case CONTROL: "Ctrl";
			case ALT: "Alt";
			case CAPSLOCK: "Caps";
			case PAGEUP: "PgUp";
			case PAGEDOWN: "PgDown";
			case ZERO: "0";
			case ONE: "1";
			case TWO: "2";
			case THREE: "3";
			case FOUR: "4";
			case FIVE: "5";
			case SIX: "6";
			case SEVEN: "7";
			case EIGHT: "8";
			case NINE: "9";
			case NUMPADZERO: "#0";
			case NUMPADONE: "#1";
			case NUMPADTWO: "#2";
			case NUMPADTHREE: "#3";
			case NUMPADFOUR: "#4";
			case NUMPADFIVE: "#5";
			case NUMPADSIX: "#6";
			case NUMPADSEVEN: "#7";
			case NUMPADEIGHT: "#8";
			case NUMPADNINE: "#9";
			case NUMPADMULTIPLY: "#*";
			case NUMPADPLUS: "#+";
			case NUMPADMINUS: "#-";
			case NUMPADPERIOD: "#.";
			case SEMICOLON: ";";
			case COMMA: ",";
			case PERIOD: ".";
			case GRAVEACCENT: "`";
			case LBRACKET: "[";
			case RBRACKET: "]";
			case QUOTE: "'";
			case PRINTSCREEN: "PrtScrn";
			case NONE: '---';
			default:
			{
				var label:String = '' + key;
				if (label.toLowerCase() == 'null') '---';

				'' + label.charAt(0).toUpperCase() + label.substr(1).toLowerCase();
			}
		}
	}

	public static function smoothColorChange(from:FlxColor, to:FlxColor, speed:Float = 0.045):FlxColor
	{
		var lerpVal:Float = CoolUtil.boundTo(speed, 0, 1);

		return FlxColor.fromRGBFloat(
			FlxMath.lerp(from.redFloat, to.redFloat, lerpVal),
			FlxMath.lerp(from.greenFloat, to.greenFloat, lerpVal),
			FlxMath.lerp(from.blueFloat, to.blueFloat, lerpVal)
		);
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