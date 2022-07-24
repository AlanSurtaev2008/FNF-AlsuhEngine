package options;

import options.OptionsMenuState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.effects.FlxFlicker;
import flixel.input.keyboard.FlxKey;

using StringTools;

class ControlsSubState extends MusicBeatSubState
{
	private static var curSelected:Int = -1;
	private static var curAlt:Bool = false;

	private static var defaultKey:String = 'Reset to Default Keys';
	private var bindLength:Int = 0;

	var optionShit:Array<Dynamic> =
	[
		['NOTES'],
		['Left', 'note_left'],
		['Down', 'note_down'],
		['Up', 'note_up'],
		['Right', 'note_right'],
		[''],
		['UI'],
		['Left', 'ui_left'],
		['Down', 'ui_down'],
		['Up', 'ui_up'],
		['Right', 'ui_right'],
		[''],
		['Reset', 'reset'],
		['Accept', 'accept'],
		['Back', 'back'],
		['Pause', 'pause']
	];

	private var grpOptions:FlxTypedGroup<Alphabet>;

	private var grpInputs:FlxTypedGroup<AttachedText>;
	private var grpInputsAlt:FlxTypedGroup<AttachedText>;

	var isPause:Bool = false;

	public function new(?isPause:Bool = false):Void
	{
		super();

		this.isPause = isPause;
	}

	override function create():Void
	{
		super.create();

		var bg:FlxSprite = new FlxSprite();

		if (isPause)
		{
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			bg.alpha = 0.6;
			bg.scrollFactor.set();
		}
		else
		{
			bg.loadGraphic(Paths.image('bg/menuDesat'));
			bg.color = 0xFFea71fd;
			bg.updateHitbox();
			bg.screenCenter();
			bg.antialiasing = OptionData.globalAntialiasing;
		}

		add(bg);

		if (isPause)
		{
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
	
			var practiceText:FlxText = new FlxText(20, 20 + 96, 0, 'PRACTICE MODE', 32);
			practiceText.scrollFactor.set();
			practiceText.setFormat(Paths.font('vcr.ttf'), 32);
			practiceText.x = FlxG.width - (practiceText.width + 20);
			practiceText.updateHitbox();
			practiceText.visible = PlayState.practiceMode;
			add(practiceText);
		}

		optionShit.push(['']);
		optionShit.push([defaultKey]);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpInputs = new FlxTypedGroup<AttachedText>();
		add(grpInputs);

		grpInputsAlt = new FlxTypedGroup<AttachedText>();
		add(grpInputsAlt);

		for (i in 0...optionShit.length)
		{
			var isCentered:Bool = unselectableCheck(i, true);

			var optionText:Alphabet = new Alphabet(0, (10 * i), optionShit[i][0], true, false);
			optionText.isMenuItem = true;
	
			if (isCentered)
			{
				optionText.screenCenter(X);
				optionText.forceX = optionText.x;
				optionText.yAdd = -55;
			}
			else
			{
				optionText.forceX = 200;
			}

			optionText.yMult = 60;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (!isCentered)
			{
				addBindTexts(optionText, i);
				bindLength++;

				if (curSelected < 0) curSelected = i;
			}
		}

		if (isPause) cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		changeSelection();
	}

	var flickering:Bool = false;
	var rebindingKey:Bool = false;

	var nextAccept:Int = 5;
	var bindingTime:Float = 0;

	var holdTime:Float = 0;
	var holdTimeHos:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK && !rebindingKey)
		{
			OptionData.saveCtrls();
			OptionData.reloadControls();

			FlxG.sound.play(Paths.sound('cancelMenu'));

			if (isPause)
			{
				PlayState.isNextSubState = true;

				FlxG.state.closeSubState();
				FlxG.state.openSubState(new OptionsSubState());
			}
			else
			{
				close();
			}
		}

		if (!flickering)
		{
			if (rebindingKey)
			{
				var keyPressed:Int = FlxG.keys.firstJustPressed();
	
				if (keyPressed > -1)
				{
					var keysArray:Array<FlxKey> = OptionData.keyBinds.get(optionShit[curSelected][1]);
					keysArray[curAlt ? 1 : 0] = keyPressed;
	
					var opposite:Int = (curAlt ? 0 : 1);
	
					if (keysArray[opposite] == keysArray[1 - opposite]) {
						keysArray[opposite] = NONE;
					}
	
					OptionData.keyBinds.set(optionShit[curSelected][1], keysArray);
	
					reloadKeys();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					rebindingKey = false;
				}
	
				bindingTime += elapsed;

				if (bindingTime > 5)
				{
					rebindingKey = false;
					bindingTime = 0;

					if (curAlt) {
						grpInputsAlt.members[getInputTextNum()].visible = true;
					} else {
						grpInputs.members[getInputTextNum()].visible = true;
					}

					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
			}
			else
			{
				if (optionShit.length > 1)
				{
					if (controls.UI_UP_P)
					{
						changeSelection(-1);
						holdTime = 0;
					}
		
					if (controls.UI_DOWN_P)
					{
						changeSelection(1);
						holdTime = 0;
					}
		
					if (controls.UI_DOWN || controls.UI_UP)
					{
						var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
						holdTime += elapsed;
						var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
		
						if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
							changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
						}
					}
		
					if (FlxG.mouse.wheel != 0) {
						changeSelection(-1 * FlxG.mouse.wheel);
					}
				}

				if ((controls.UI_LEFT_P || controls.UI_RIGHT_P) && optionShit[curSelected][0] != defaultKey)
				{
					changeAlt();
				}

				if (controls.RESET && optionShit[curSelected][0] != defaultKey)
				{
					OptionData.keyBinds.set(optionShit[curSelected][1], OptionData.defaultKeys.get(optionShit[curSelected][1]));

					reloadKeys();
					changeSelection();
				}

				if (controls.ACCEPT && nextAccept <= 0)
				{
					if (optionShit[curSelected][0] == defaultKey)
					{
						if (OptionData.flashingLights)
						{
							flickering = true;

							FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker)
							{
								reset();
							});
						}
						else
						{
							reset();
						}

						FlxG.sound.play(Paths.sound('confirmMenu'));
					}
					else if (!unselectableCheck(curSelected))
					{
						if (OptionData.flashingLights)
						{
							flickering = true;

							FlxFlicker.flicker(curAlt ? grpInputsAlt.members[getInputTextNum()] : grpInputs.members[getInputTextNum()],
								1, 0.06, false, false, function(flick:FlxFlicker)
							{
								selectInput();
							});
							
							FlxG.sound.play(Paths.sound('confirmMenu'));
						}
						else
						{
							if (curAlt) {
								grpInputsAlt.members[getInputTextNum()].visible = false;
							} else {
								grpInputs.members[getInputTextNum()].visible = false;
							}

							selectInput();
						}
					}
				}
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function reset():Void
	{
		flickering = false;

		OptionData.keyBinds = OptionData.defaultKeys.copy();

		reloadKeys();
		changeSelection();
	}

	function selectInput():Void
	{
		flickering = false;
		bindingTime = 0;
		rebindingKey = true;

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function getInputTextNum():Int
	{
		var num:Int = 0;

		for (i in 0...curSelected)
		{
			if (optionShit[i].length > 1)
			{
				num++;
			}
		}

		return num;
	}

	function changeSelection(change:Int = 0):Void
	{
		do
		{
			curSelected += change;

			if (curSelected < 0)
				curSelected = optionShit.length - 1;
			if (curSelected >= optionShit.length)
				curSelected = 0;
		}
		while (unselectableCheck(curSelected));

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = 0.6;

				if (item.targetY == 0)
				{
					item.alpha = 1;

					for (input in grpInputsAlt)
					{
						input.alpha = 0.6;

						if (input.sprTracker == item && curAlt)
						{
							input.alpha = 1;
						}
					}

					for (input in grpInputs)
					{
						input.alpha = 0.6;

						if (input.sprTracker == item && !curAlt)
						{
							input.alpha = 1;
						}
					}
				}
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeAlt():Void
	{
		curAlt = !curAlt;

		for (input in grpInputsAlt)
		{
			input.alpha = 0.6;

			if (input.sprTracker == grpOptions.members[curSelected] && curAlt)
			{
				input.alpha = 1;
			}
		}

		for (input in grpInputs)
		{
			input.alpha = 0.6;

			if (input.sprTracker == grpOptions.members[curSelected] && !curAlt)
			{
				input.alpha = 1;
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	private function unselectableCheck(num:Int, ?checkDefaultKey:Bool = false):Bool
	{
		if (optionShit[num][0] == defaultKey) 
		{
			return checkDefaultKey;
		}

		return optionShit[num].length < 2 && optionShit[num][0] != defaultKey;
	}

	private function addBindTexts(optionText:Alphabet, num:Int):Void
	{
		var keys:Array<FlxKey> = OptionData.keyBinds.get(optionShit[num][1]);

		var text1 = new AttachedText(InputFormatter.getKeyName(keys[0]), 400, -55);
		text1.setPosition(optionText.x + 400, optionText.y - 55);
		text1.sprTracker = optionText;
		grpInputs.add(text1);

		var text2 = new AttachedText(InputFormatter.getKeyName(keys[1]), 650, -55);
		text2.setPosition(optionText.x + 650, optionText.y - 55);
		text2.sprTracker = optionText;
		grpInputsAlt.add(text2);
	}

	function reloadKeys():Void
	{
		while (grpInputs.members.length > 0)
		{
			var item:AttachedText = grpInputs.members[0];

			item.kill();
			grpInputs.remove(item, true);
			item.destroy();
		}

		while (grpInputsAlt.members.length > 0)
		{
			var item:AttachedText = grpInputsAlt.members[0];

			item.kill();
			grpInputsAlt.remove(item, true);
			item.destroy();
		}

		for (i in 0...grpOptions.length)
		{
			if (!unselectableCheck(i, true))
			{
				addBindTexts(grpOptions.members[i], i);
			}
		}

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = 0.6;

				if (item.targetY == 0)
				{
					item.alpha = 1;

					for (input in grpInputsAlt)
					{
						input.alpha = 0.6;

						if (input.sprTracker == item && curAlt)
						{
							input.alpha = 1;
						}
					}

					for (input in grpInputs)
					{
						input.alpha = 0.6;

						if (input.sprTracker == item && !curAlt)
						{
							input.alpha = 1;
						}
					}
				}
			}
		}
	}
}