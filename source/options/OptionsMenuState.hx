package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.effects.FlxFlicker;

using StringTools;

class OptionsMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;

	private var options:Array<String> = ['Preferences', 'Controls', 'Note Colors', #if sys 'Replays', #end 'Credits', 'Exit'];
	private var grpOptions:FlxTypedGroup<Alphabet>;

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	function openSelectedSubstate(label:String):Void
	{
		switch (label)
		{
			case 'Preferences':
			{
				openSubState(new PreferencesSubState(false));
			}
			case 'Controls':
			{
				openSubState(new ControlsSubState(false));
			}
			case 'Note Colors':
			{
				openSubState(new NotesSubState(false));
			}
			#if sys
			case 'Replays':
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new ReplaysState());
			}
			#end
			case 'Credits':
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new CreditsMenuState());
			}
			case 'Exit':
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}
	}

	override function create():Void
	{
		super.create();

		if (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		OptionData.savePrefs();

		#if desktop
		DiscordClient.changePresence("In the Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.image('bg/menuDesat'));
		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = OptionData.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true, false);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			optionText.ID = i;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true, false);
		add(selectorLeft);

		selectorRight = new Alphabet(0, 0, '<', true, false);
		add(selectorRight);

		changeSelection();
	}

	override function closeSubState():Void
	{
		super.closeSubState();

		flickering = false;
		OptionData.savePrefs();
	}

	var flickering:Bool = false;
	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			OptionData.savePrefs();

			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (!flickering)
		{
			if (options.length > 1)
			{
				if (controls.UI_UP_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeSelection(-1);

					holdTime = 0;
				}

				if (controls.UI_DOWN_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeSelection(1);

					holdTime = 0;
				}

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
					}
				}

				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);

					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if (controls.ACCEPT)
			{
				if (OptionData.flashingLights)
				{
					flickering = true;

					FlxFlicker.flicker(selectorLeft, 1, 0.04, true);
					FlxFlicker.flicker(selectorRight, 1, 0.04, true);
	
					FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.04, true, false, function(flick:FlxFlicker)
					{
						openSelectedSubstate(options[curSelected]);
					});
	
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
				else
				{
					openSelectedSubstate(options[curSelected]);
				}
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		for (item in grpOptions.members)
		{
			item.alpha = 0.6;

			if (item.ID == curSelected)
			{
				item.alpha = 1;

				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;

				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}

class OptionsSubState extends MusicBeatSubState
{
	private static var curSelected:Int = -1;

	private var options:Array<String> = ['Preferences', 'Controls', 'Note Colors', 'Exit'];
	private var grpOptions:FlxTypedGroup<Alphabet>;

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	function openSelectedSubstate(label:String):Void
	{
		switch (label)
		{
			case 'Preferences':
			{
				PlayState.isNextSubState = true;

				FlxG.state.closeSubState();
				FlxG.state.openSubState(new PreferencesSubState(true));
			}
			case 'Controls':
			{
				PlayState.isNextSubState = true;

				FlxG.state.closeSubState();
				FlxG.state.openSubState(new ControlsSubState(true));
			}
			case 'Note Colors':
			{
				PlayState.isNextSubState = true;

				FlxG.state.closeSubState();
				FlxG.state.openSubState(new NotesSubState(true));
			}
			case 'Exit':
			{
				OptionsMenuState.curSelected = curSelected;
				
				OptionData.savePrefs();

				FlxG.sound.play(Paths.sound('cancelMenu'));

				PlayState.isNextSubState = true;
	
				FlxG.state.closeSubState();
				FlxG.state.openSubState(new PauseSubState(true));
	
				curSelected = -1;
			}
		}
	}

	override function create():Void
	{
		super.create();

		OptionData.savePrefs();

		#if desktop
		DiscordClient.changePresence("In the Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 20, 0, '', 32);
		levelInfo.text += PlayState.SONG.songName;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font('vcr.ttf'), 32);
		levelInfo.updateHitbox();
		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 20 + 32, 0, '', 32);
		levelDifficulty.text += CoolUtil.getDifficultyName(PlayState.lastDifficulty, PlayState.difficulties).toUpperCase();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 20 + 64, 0, '', 32);
		blueballedTxt.text = 'Blue balled: ' + PlayState.deathCounter;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);
		add(blueballedTxt);

		var chartingText:FlxText = new FlxText(20, 20 + 96, 0, "CHARTING MODE", 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.font('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.updateHitbox();
		chartingText.visible = PlayState.chartingMode;
		add(chartingText);

		var practiceText:FlxText = new FlxText(20, 20 + (PlayState.chartingMode ? 128 : 96), 0, 'PRACTICE MODE', 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.alpha = PlayStateChangeables.practiceMode ? 1 : 0;
		add(practiceText);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		if (curSelected < 0) curSelected = OptionsMenuState.curSelected;

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true, false);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			optionText.ID = i;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true, false);
		add(selectorLeft);

		selectorRight = new Alphabet(0, 0, '<', true, false);
		add(selectorRight);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		changeSelection();
	}

	var flickering:Bool = false;
	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			OptionsMenuState.curSelected = curSelected;

			OptionData.savePrefs();

			FlxG.sound.play(Paths.sound('cancelMenu'));

			PlayState.isNextSubState = true;

			FlxG.state.closeSubState();
			FlxG.state.openSubState(new PauseSubState(true));

			curSelected = -1;
		}

		if (!flickering)
		{
			if (options.length > 1)
			{
				if (controls.UI_UP_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeSelection(-1);

					holdTime = 0;
				}

				if (controls.UI_DOWN_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeSelection(1);

					holdTime = 0;
				}

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
					}
				}

				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);

					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if (controls.ACCEPT)
			{
				if (OptionData.flashingLights)
				{
					flickering = true;

					FlxFlicker.flicker(selectorLeft, 1, 0.04, true);
					FlxFlicker.flicker(selectorRight, 1, 0.04, true);
	
					FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.04, true, false, function(flick:FlxFlicker)
					{
						openSelectedSubstate(options[curSelected]);
					});
	
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
				else
				{
					openSelectedSubstate(options[curSelected]);
				}
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		for (item in grpOptions.members)
		{
			item.alpha = 0.6;

			if (item.ID == curSelected)
			{
				item.alpha = 1;

				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;

				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}