package;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

using StringTools;

class InputFormatter
{
	public static function getKeyName(key:FlxKey):String
	{
		var text:String = '---';

		switch (key)
		{
			case BACKSPACE:
				text = "BckSpc";
			case CONTROL:
				text = "Ctrl";
			case ALT:
				text = "Alt";
			case CAPSLOCK:
				text = "Caps";
			case PAGEUP:
				text = "PgUp";
			case PAGEDOWN:
				text = "PgDown";
			case ZERO:
				text = "0";
			case ONE:
				text = "1";
			case TWO:
				text = "2";
			case THREE:
				text = "3";
			case FOUR:
				text = "4";
			case FIVE:
				text = "5";
			case SIX:
				text = "6";
			case SEVEN:
				text = "7";
			case EIGHT:
				text = "8";
			case NINE:
				text = "9";
			case NUMPADZERO:
				text = "#0";
			case NUMPADONE:
				text = "#1";
			case NUMPADTWO:
				text = "#2";
			case NUMPADTHREE:
				text = "#3";
			case NUMPADFOUR:
				text = "#4";
			case NUMPADFIVE:
				text = "#5";
			case NUMPADSIX:
				text = "#6";
			case NUMPADSEVEN:
				text = "#7";
			case NUMPADEIGHT:
				text = "#8";
			case NUMPADNINE:
				text = "#9";
			case NUMPADMULTIPLY:
				text = "#*";
			case NUMPADPLUS:
				text = "#+";
			case NUMPADMINUS:
				text = "#-";
			case NUMPADPERIOD:
				text = "#.";
			case SEMICOLON:
				text = ";";
			case COMMA:
				text = ",";
			case PERIOD:
				text = ".";
			case GRAVEACCENT:
				text = "`";
			case LBRACKET:
				text = "[";
			case RBRACKET:
				text = "]";
			case QUOTE:
				text = "'";
			case PRINTSCREEN:
				text = "PrtScrn";
			case NONE:
				text = '---';
			default:
			{
				var label:String = '' + key;
				if (label.toLowerCase() == 'null') text = '---';

				text = '' + label.charAt(0).toUpperCase() + label.substr(1).toLowerCase();
			}
		}

		return text;
	}
}