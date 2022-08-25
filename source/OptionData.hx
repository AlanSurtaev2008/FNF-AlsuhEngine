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
	public static var cpuStrumsType:String = 'Light Up';
	public static var hitsoundType:String = 'Kade';
	public static var hitsoundVolume:Float = 0;
	public static var noReset:Bool = false;
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var shitWindow:Int = 160;
	public static var safeFrames:Float = 10;
	public static var noteOffset:Int = 0;

	public static var camZooms:Bool = true;
	public static var camShakes:Bool = true;

	public static var iconZooms:Bool = true;
	public static var sustainsType:String = 'New';
	public static var noteSplashes:Bool = true;
	public static var danceOffset:Int = 2;
	public static var songPositionType:String = 'Time Left';
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
	public static var flashingLights:Bool = true;

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];

	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];

	public static function savePrefs():Void
	{
		FlxG.save.bind('alsuh-engine', 'afford-set');

		FlxG.save.data.fullScreen = fullScreen;
		FlxG.save.data.lowQuality = lowQuality;
		FlxG.save.data.globalAntialiasing = globalAntialiasing;
		FlxG.save.data.shaders = shaders;
		FlxG.save.data.framerate = framerate;

		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.controllerMode = controllerMode;
		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.cpuStrumsType = cpuStrumsType;
		FlxG.save.data.ratingOffset = ratingOffset;
		FlxG.save.data.sickWindow = sickWindow;
		FlxG.save.data.goodWindow = goodWindow;
		FlxG.save.data.badWindow = badWindow;
		FlxG.save.data.shitWindow = shitWindow;
		FlxG.save.data.safeFrames = safeFrames;
		FlxG.save.data.noteOffset = noteOffset;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.camShakes = camShakes;
		FlxG.save.data.iconZooms = iconZooms;
		FlxG.save.data.sustainsType = sustainsType;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.danceOffset = danceOffset;
		FlxG.save.data.songPositionType = songPositionType;
		FlxG.save.data.scoreText = scoreText;
		FlxG.save.data.naughtyness = naughtyness;
		FlxG.save.data.showRatings = showRatings;
		FlxG.save.data.showNumbers = showNumbers;
		FlxG.save.data.noReset = noReset;
		FlxG.save.data.healthBarAlpha = healthBarAlpha;
		FlxG.save.data.hitsoundType = hitsoundType;
		FlxG.save.data.hitsoundVolume = hitsoundVolume;
		FlxG.save.data.pauseMusic = pauseMusic;
		FlxG.save.data.checkForUpdates = checkForUpdates;
		FlxG.save.data.fpsCounter = fpsCounter;
		FlxG.save.data.rainFPS = rainFPS;
		FlxG.save.data.memoryCounter = memoryCounter;
		FlxG.save.data.rainMemory = rainMemory;
		FlxG.save.data.watermarks = watermarks;
		FlxG.save.data.autoPause = autoPause;
		FlxG.save.data.flashingLights = flashingLights;

		FlxG.save.data.arrowHSV = arrowHSV;
		FlxG.save.data.comboOffset = comboOffset;

		FlxG.save.flush();
	}

	public static function loadPrefs():Void
	{
		FlxG.save.bind('alsuh-engine', 'afford-set');

		if (FlxG.save.data.fullScreen != null) {
			fullScreen = FlxG.save.data.fullScreen;
			FlxG.fullscreen = fullScreen;
		} else {
			FlxG.fullscreen = fullScreen;
		}

		if (FlxG.save.data.lowQuality != null) {
			lowQuality = FlxG.save.data.lowQuality;
		}
		if (FlxG.save.data.globalAntialiasing != null) {
			globalAntialiasing = FlxG.save.data.globalAntialiasing;
		}
		if (FlxG.save.data.shaders != null) {
			shaders = FlxG.save.data.shaders;
		}
		if (FlxG.save.data.framerate != null) {
			framerate = FlxG.save.data.framerate;
			if (framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			} else {
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		} else {
			if (framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			} else {
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		}

		if (FlxG.save.data.ghostTapping != null) {
			ghostTapping = FlxG.save.data.ghostTapping;
		}
		if (FlxG.save.data.controllerMode != null) {
			controllerMode = FlxG.save.data.controllerMode;
		}
		if (FlxG.save.data.downScroll != null) {
			downScroll = FlxG.save.data.downScroll;
		}
		if (FlxG.save.data.middleScroll != null) {
			middleScroll = FlxG.save.data.middleScroll;
		}
		if (FlxG.save.data.cpuStrumsType != null) {
			cpuStrumsType = FlxG.save.data.cpuStrumsType;
		}
		if (FlxG.save.data.ratingOffset != null) {
			ratingOffset = FlxG.save.data.ratingOffset;
		}
		if (FlxG.save.data.sickWindow != null) {
			sickWindow = FlxG.save.data.sickWindow;
		}
		if (FlxG.save.data.goodWindow != null) {
			goodWindow = FlxG.save.data.goodWindow;
		}
		if (FlxG.save.data.badWindow != null) {
			badWindow = FlxG.save.data.badWindow;
		}
		if (FlxG.save.data.shitWindow != null) {
			shitWindow = FlxG.save.data.shitWindow;
		}
		if (FlxG.save.data.safeFrames != null) {
			safeFrames = FlxG.save.data.safeFrames;
		}
		if (FlxG.save.data.noteOffset != null) {
			noteOffset = FlxG.save.data.noteOffset;
		}

		if (FlxG.save.data.camZooms != null) {
			camZooms = FlxG.save.data.camZooms;
		}
		if (FlxG.save.data.camShakes != null) {
			camShakes = FlxG.save.data.camShakes;
		}

		if (FlxG.save.data.iconZooms != null) {
			iconZooms = FlxG.save.data.iconZooms;
		}
		if (FlxG.save.data.noteSplashes != null) {
			noteSplashes = FlxG.save.data.noteSplashes;
		}
		if (FlxG.save.data.sustainsType != null) {
			sustainsType = FlxG.save.data.sustainsType;
		}
		if (FlxG.save.data.danceOffset != null) {
			danceOffset = FlxG.save.data.danceOffset;
		}
		if (FlxG.save.data.songPositionType != null) {
			songPositionType = FlxG.save.data.songPositionType;
		}
		if (FlxG.save.data.scoreText != null) {
			scoreText = FlxG.save.data.scoreText;
		}
		if (FlxG.save.data.naughtyness != null) {
			naughtyness = FlxG.save.data.naughtyness;
		}
		if (FlxG.save.data.showRatings != null) {
			showRatings = FlxG.save.data.showRatings;
		}
		if (FlxG.save.data.showNumbers != null) {
			showNumbers = FlxG.save.data.showNumbers;
		}
		if (FlxG.save.data.noReset != null) {
			noReset = FlxG.save.data.noReset;
		}
		if (FlxG.save.data.healthBarAlpha != null) {
			healthBarAlpha = FlxG.save.data.healthBarAlpha;
		}
		if (FlxG.save.data.hitsoundType != null) {
			hitsoundType = FlxG.save.data.hitsoundType;
		}
		if (FlxG.save.data.hitsoundVolume != null) {
			hitsoundVolume = FlxG.save.data.hitsoundVolume;
		}
		if (FlxG.save.data.pauseMusic != null) {
			pauseMusic = FlxG.save.data.pauseMusic;
		}
		if (FlxG.save.data.checkForUpdates != null) {
			checkForUpdates = FlxG.save.data.checkForUpdates;
		}
		if (FlxG.save.data.controllerMode != null) {
			controllerMode = FlxG.save.data.controllerMode;
		}
		if (FlxG.save.data.fpsCounter != null) {
			fpsCounter = FlxG.save.data.fpsCounter;

			if (Main.fpsCounter != null) {
				Main.fpsCounter.visible = fpsCounter;
			}
		}
		if (FlxG.save.data.rainFPS != null) {
			rainFPS = FlxG.save.data.rainFPS;
		}
		if (FlxG.save.data.memoryCounter != null) {
			memoryCounter = FlxG.save.data.memoryCounter;

			if (Main.memoryCounter != null) {
				Main.memoryCounter.visible = memoryCounter;
			}
		}
		if (FlxG.save.data.rainMemory != null) {
			rainMemory = FlxG.save.data.rainMemory;
		}
		if (FlxG.save.data.watermarks != null) {
			watermarks = FlxG.save.data.watermarks;
		}

		if (FlxG.save.data.autoPause != null) {
			autoPause = FlxG.save.data.autoPause;
			FlxG.autoPause = autoPause;
		} else {
			FlxG.autoPause = autoPause;
		}

		if (FlxG.save.data.flashingLights != null) {
			flashingLights = FlxG.save.data.flashingLights;
		}

		if (FlxG.save.data.comboOffset != null) {
			comboOffset = FlxG.save.data.comboOffset;
		}
		if (FlxG.save.data.arrowHSV != null) {
			arrowHSV = FlxG.save.data.arrowHSV;
		}

		if (FlxG.save.data.volume != null)
		{
			FlxG.sound.volume = FlxG.save.data.volume;
		}

		if (FlxG.save.data.mute != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute;
		}
	}

	public static function field(variable:String):Dynamic
	{
		return Reflect.field(OptionData, variable);
	}

	public static function setField(variable:String, value:Dynamic):Void
	{
		Reflect.setField(OptionData, variable, value);
	}

	public static function getProperty(variable:String):Dynamic
	{
		return Reflect.getProperty(OptionData, variable);
	}

	public static function setProperty(variable:String, value:Dynamic):Void
	{
		Reflect.setProperty(OptionData, variable, value);
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

		'mods'			=> [M, NONE],

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