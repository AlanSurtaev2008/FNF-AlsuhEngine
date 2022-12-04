package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;

import Controls;

using StringTools;

class OptionData
{
	public static var fullScreen:Bool = false;
	public static var lowQuality:Bool = false;
	public static var globalAntialiasing:Bool = true;
	public static var shaders:Bool = true;
	public static var framerate:Int = 60;

	public static var ghostTapping:Bool = true;
	public static var controllerMode:Bool = false;
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrumsType:String = 'Glow';
	public static var hitsoundType:String = 'Kade';
	public static var hitsoundVolume:Float = 0;
	public static var noReset:Bool = false;
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var shitWindow:Int = 160;
	public static var comboStacking:Bool = true;
	public static var safeFrames:Float = 10;
	public static var noteOffset:Int = 0;

	public static var camZooms:Bool = true;
	public static var camShakes:Bool = true;

	public static var cutscenesInType:String = 'Story';
	public static var skipCutscenes:Bool = true;

	public static var iconZooms:Bool = true;
	public static var sustainsType:String = 'New';
	public static var noteSplashes:Bool = true;
	public static var danceOffset:Int = 2;
	public static var songPositionType:String = 'Time Left and Elapsed';
	public static var scoreText:Bool = true;
	public static var naughtyness:Bool = true;

	public static var showRatings:Bool = true;
	public static var showNumbers:Bool = true;

	public static var healthBarAlpha:Float = 1;
	public static var pauseMusic:String = 'Tea Time';
	public static var fpsCounter:Bool = false;
	public static var rainFPS:Bool = false;
	public static var memoryCounter:Bool = false;
	public static var rainMemory:Bool = false;
	public static var checkForUpdates:Bool = true;
	public static var autoPause:Bool = false;
	public static var watermarks:Bool = true;
	public static var loadingScreen:Bool = #if NO_PRELOAD_ALL true #else false #end;
	public static var flashingLights:Bool = true;

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];

	private static var ignoredFields:Array<String> = ['keyBinds', 'defaultKeys'];

	public static function savePrefs():Void
	{
		FlxG.save.bind('alsuh-engine', 'afford-set');

		var fieldsArray:Array<String> = Reflect.fields(OptionData);

		for (i in 0...ignoredFields.length)
		{
			var ignoredField:String = ignoredFields[i];

			if (fieldsArray.contains(ignoredField)) {
				fieldsArray.remove(ignoredField);
			}
		}

		for (i in 0...fieldsArray.length)
		{
			var field:String = fieldsArray[i];

			Reflect.setField(FlxG.save.data, field, Reflect.field(OptionData, field));
			FlxG.save.flush();
		}

		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
		FlxG.save.flush();
	}

	public static function loadPrefs():Void
	{
		FlxG.save.bind('alsuh-engine', 'afford-set');

		var fieldsArray:Array<String> = Reflect.fields(OptionData);

		for (i in 0...ignoredFields.length)
		{
			var ignoredField:String = ignoredFields[i];

			if (fieldsArray.contains(ignoredField)) {
				fieldsArray.remove(ignoredField);
			}
		}

		for (i in 0...fieldsArray.length)
		{
			var field:String = fieldsArray[i];
			var valueFromSave:Dynamic = Reflect.field(OptionData, field);

			if (valueFromSave != null) {
				Reflect.setField(OptionData, field, valueFromSave);
			}

			switch (field)
			{
				case 'fullScreen':
				{
					FlxG.fullscreen = fullScreen;
				}
				case 'framerate':
				{
					if (framerate > FlxG.drawFramerate)
					{
						FlxG.updateFramerate = framerate;
						FlxG.drawFramerate = framerate;
					}
					else
					{
						FlxG.drawFramerate = framerate;
						FlxG.updateFramerate = framerate;
					}
				}
				case 'fpsCounter':
				{
					if (Main.fpsCounter != null) {
						Main.fpsCounter.visible = fpsCounter;
					}
				}
				case 'memoryCounter':
				{
					if (Main.memoryCounter != null) {
						Main.memoryCounter.visible = memoryCounter;
					}
				}
				case 'autoPause':
				{
					FlxG.autoPause = autoPause;
				}
			}
		}

		if (FlxG.save.data.volume != null) {
			FlxG.sound.volume = FlxG.save.data.volume;
		}

		if (FlxG.save.data.mute != null) {
			FlxG.sound.muted = FlxG.save.data.mute;
		}
	}

	public static var keyBinds:Map<String, Array<FlxKey>> =
	[
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],
		
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],

		'reset'			=> [R, NONE],
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		
		'volume_mute'	=> [ZERO, NONE],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN, NONE],
		'debug_2'		=> [EIGHT, NONE]
	];

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys():Void
	{
		defaultKeys = keyBinds.copy();
	}

	public static function saveCtrls():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', 'afford-set');
		save.data.keyBinds = keyBinds;
		save.flush();
	}

	public static function loadCtrls():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', 'afford-set');

		if (save != null && save.data.keyBinds != null)
		{
			var loadedControls:Map<String, Array<FlxKey>> = save.data.keyBinds;

			for (control => keys in loadedControls)
			{
				keyBinds.set(control, keys);
			}
		}

		reloadControls();
	}

	public static function reloadControls():Void
	{
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));

		PlayState.debugKeysChart = OptionData.copyKey(OptionData.keyBinds.get('debug_1'));
		PlayState.debugKeysCharacter = OptionData.copyKey(OptionData.keyBinds.get('debug_2'));

		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();

		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}

			i++;
			len = copiedArray.length;
		}

		return copiedArray;
	}
}