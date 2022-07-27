package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;

using StringTools;

class GameplayChangersSubState extends MusicBeatSubState
{
	private static var curSelected:Int = 0;

	var optionsArray:Array<GameplayOption> = [];
	var curOption:GameplayOption;
	var defaultValue:GameplayOption = new GameplayOption('Reset to Default Values');

	var isPause:Bool = false;

	public function new(?isPause:Bool = false):Void
	{
		super();

		this.isPause = isPause;
	}

	var grpOptions:FlxTypedGroup<Alphabet>;
	var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	var grpTexts:FlxTypedGroup<AttachedText>;

	function getOptions():Void
	{
		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrollType', 'string', 'multiplicative', ["multiplicative", "constant"]);
		goption.onChange = onChangeScrollSpeed;
		optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollSpeed', 'float', 1);
		option.scrollSpeed = 1.5;
		option.minValue = 0.5;
		option.changeValue = 0.1;

		if (goption.getValue() != "constant")
		{
			option.displayFormat = '%vX';
			option.maxValue = 3;
		}
		else
		{
			option.displayFormat = "%v";
			option.maxValue = 6;
		}

		option.onChange = onChangeScrollSpeed;
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthGain', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthLoss', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Instakill on Miss', 'instaKill', 'bool', false);
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Botplay', 'botPlay', 'bool', false);
		option.onChange = onChangeBotplay;
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Practice Mode', 'practiceMode', 'bool', false);
		option.onChange = onChangePractice;
		optionsArray.push(option);

		defaultValue.type = 'amogus';
		optionsArray.push(defaultValue);
	}

	public function getOptionByName(name:String)
	{
		for (i in optionsArray)
		{
			var opt:GameplayOption = i;

			if (opt.name == name) {
				return opt;
			}
		}

		return null;
	}

	var practiceText:FlxText;

	override function create():Void
	{
		super.create();

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
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

			var chartingText:FlxText = new FlxText(20, 20 + 96, 0, "CHARTING MODE", 32);
			chartingText.scrollFactor.set();
			chartingText.setFormat(Paths.font('vcr.ttf'), 32);
			chartingText.x = FlxG.width - (chartingText.width + 20);
			chartingText.updateHitbox();
			chartingText.visible = PlayState.chartingMode;
			add(chartingText);
	
			practiceText = new FlxText(20, 15 + (PlayState.chartingMode ? 128 : 96) + (PlayStateChangeables.practiceMode ? 5 : 0), 0, 'PRACTICE MODE', 32);
			practiceText.scrollFactor.set();
			practiceText.setFormat(Paths.font('vcr.ttf'), 32);
			practiceText.x = FlxG.width - (practiceText.width + 20);
			practiceText.updateHitbox();
			practiceText.alpha = PlayStateChangeables.practiceMode ? 1 : 0;
			add(practiceText);
		}

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		getOptions();

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(0, 70 * i, optionsArray[i].name, true, false, 0.05, 0.8);
			optionText.isMenuItem = true;
			optionText.x += 300;
			optionText.xAdd = 120;
			optionText.targetY = i;
			grpOptions.add(optionText);

			switch (optionsArray[i].type)
			{
				case 'bool':
				{
					var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
					checkbox.sprTracker = optionText;
					checkbox.offsetY = -60;
					checkbox.ID = i;
					checkboxGroup.add(checkbox);
					optionText.xAdd += 80;
				}
				case 'int' | 'float' | 'percent' | 'string':
				{
					var valueText:AttachedText = new AttachedText('' + optionsArray[i].getValue(), optionText.width + 80, true, 0.8);
					valueText.sprTracker = optionText;
					valueText.copyAlpha = true;
					valueText.ID = i;
					grpTexts.add(valueText);
					optionsArray[i].setChild(valueText);
				}
			}

			updateTextFrom(optionsArray[i]);
		}

		if (isPause) cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		changeSelection();
		reloadCheckboxes();
	}

	var flickering:Bool = false;

	var nextAccept:Int = 5;

	var holdTime:Float = 0;
	var holdTimeValue:Float = 0;

	var holdValue:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			PlayStateChangeables.saveChangeables();

			if (isPause)
			{
				PlayState.isNextSubState = true;

				FlxG.state.closeSubState();
				FlxG.state.openSubState(new PauseSubState(true));
			}
			else
			{
				close();
			}

			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (!flickering)
		{
			if (optionsArray.length > 1)
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

			if (controls.ACCEPT && nextAccept <= 0)
			{
				if (curOption == defaultValue)
				{
					if (OptionData.flashingLights)
					{
						flickering = true;

						FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker)
						{
							reset();
							FlxG.sound.play(Paths.sound('cancelMenu'));
						});
					}
					else
					{
						reset();

						FlxG.sound.play(Paths.sound('cancelMenu'));
						reloadCheckboxes();
					}

					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
				else
				{
					if (curOption.type == 'bool' && !curOption.isPause)
					{
						if (OptionData.flashingLights)
						{
							flickering = true;

							FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker)
							{
								changeBool(curOption);
							});

							FlxG.sound.play(Paths.sound('confirmMenu'));
						}
						else
						{
							changeBool(curOption);
						}
					}
					else if (curOption.type == 'menu')
					{
						if (OptionData.flashingLights)
						{
							flickering = true;

							FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker)
							{
								flickering = false;
								curOption.change();
							});

							FlxG.sound.play(Paths.sound('confirmMenu'));
						}
						else
						{
							curOption.change();
						}
					}
				}
			}

			if ((controls.UI_LEFT || controls.UI_RIGHT) && curOption.type != 'bool' && curOption.type != 'menu' && curOption != defaultValue && !curOption.isPause)
			{
				var pressed:Bool = (controls.UI_LEFT_P || controls.UI_RIGHT_P);

				if (holdTimeValue > 0.5 || pressed) 
				{
					if (pressed)
					{
						var add:Dynamic = null;

						if (curOption.type != 'string')
						{
							add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
						}

						switch (curOption.type)
						{
							case 'int' | 'float' | 'percent':
							{
								holdValue = curOption.getValue() + add;

								if (holdValue < curOption.minValue)
									holdValue = curOption.minValue;
								else if (holdValue > curOption.maxValue)
									holdValue = curOption.maxValue;

								switch (curOption.type)
								{
									case 'int':
									{
										holdValue = Math.round(holdValue);
										curOption.setValue(holdValue);
									}
									case 'float' | 'percent':
									{
										holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
										curOption.setValue(holdValue);
									}
								}
							}
							case 'string':
							{
								var num:Int = curOption.curOption; // lol

								if (controls.UI_LEFT_P)
									--num;
								else
									num++;

								if (num < 0)
									num = curOption.options.length - 1;
								else if (num >= curOption.options.length)
									num = 0;

								curOption.curOption = num;
								curOption.setValue(curOption.options[num]); // lol
							}
						}

						updateTextFrom(curOption);

						curOption.change();
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
					else if (curOption.type != 'string')
					{
						holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);

						if (holdValue < curOption.minValue) 
							holdValue = curOption.minValue;
						else if (holdValue > curOption.maxValue)
							holdValue = curOption.maxValue;

						switch (curOption.type)
						{
							case 'int':
							{
								curOption.setValue(Math.round(holdValue));
							}
							case 'float' | 'percent':
							{
								curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
							}
						}

						updateTextFrom(curOption);
						curOption.change();
					}
				}

				if (curOption.type != 'string')
				{
					holdTimeValue += elapsed;
				}
			}
			else if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
			{
				clearHold();
			}

			if (controls.RESET)
			{
				curOption.resetToDefault();
				curOption.change();

				FlxG.sound.play(Paths.sound('scrollMenu'));

				updateTextFrom(curOption);
				reloadCheckboxes();
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function onChangeScrollSpeed():Void
	{
		if (isPause)
		{
			PlayState.instance.songSpeedType = PlayStateChangeables.scrollType;

			switch (PlayState.instance.songSpeedType)
			{
				case "multiplicative":
					PlayState.instance.songSpeed = PlayState.SONG.speed * PlayStateChangeables.scrollSpeed;
				case "constant":
					PlayState.instance.songSpeed = PlayStateChangeables.scrollSpeed;
			}
		}
	}

	function onChangeBotplay():Void
	{
		if (isPause)
		{
			PlayState.instance.botplayTxt.visible = PlayStateChangeables.botPlay;
			PlayState.instance.botplayTxt.alpha = 1;
			PlayState.instance.botplaySine = 0;
		}

		PlayState.usedPractice = PlayStateChangeables.botPlay;
	}

	function onChangePractice():Void
	{
		PlayState.usedPractice = PlayStateChangeables.practiceMode;

		if (isPause)
		{
			if (PlayStateChangeables.practiceMode)
			{
				FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut});
			}
			else
			{
				FlxTween.tween(practiceText, {alpha: 0, y: practiceText.y - 5}, 0.4, {ease: FlxEase.quartInOut});
			}
		}
	}

	function changeBool(option:GameplayOption):Void
	{
		flickering = false;

		FlxG.sound.play(Paths.sound('scrollMenu'));

		option.setValue((option.getValue() == true) ? false : true);
		option.change();

		reloadCheckboxes();
	}

	function reset():Void
	{
		flickering = false;

		for (i in 0...optionsArray.length)
		{
			var leOption:GameplayOption = optionsArray[i];
			leOption.setValue(leOption.defaultValue);
	
			if (leOption.type != 'bool')
			{
				if (leOption.type == 'string')
				{
					leOption.curOption = leOption.options.indexOf(leOption.getValue());
				}

				updateTextFrom(leOption);
			}

			if (leOption.name == 'Scroll Speed')
			{
				leOption.displayFormat = "%vX";
				leOption.maxValue = 3;
	
				if (leOption.getValue() > 3)
				{
					leOption.setValue(3);
				}
		
				updateTextFrom(leOption);
			}
	
			leOption.change();
		}

		reloadCheckboxes();
	}

	function updateTextFrom(option:GameplayOption):Void
	{
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();

		if (option.type == 'percent') val *= 100;

		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold():Void
	{
		if (holdTimeValue > 0.5) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		holdTimeValue = 0;
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) 
			{
				item.alpha = 1;
			}
		}

		for (checkbox in checkboxGroup)
		{
			checkbox.alpha = 0.6;
	
			if (checkbox.ID == curSelected)
			{
				checkbox.alpha = 1;
			}
		}

		for (text in grpTexts)
		{
			text.alpha = 0.6;
	
			if (text.ID == curSelected)
			{
				text.alpha = 1;
			}
		}

		curOption = optionsArray[curSelected]; //shorter lol

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes():Void
	{
		for (checkbox in checkboxGroup)
		{
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}
}

class GameplayOption
{
	private var child:Alphabet;
	public var text(get, set):String;
	public var onChange:Void->Void = null; //Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var isPause:Bool = false;
	public var type(get, default):String = 'bool'; //bool, int (or integer), float (or fl), percent, string (or str)
	// Bool will use checkboxes
	// Everything else will use a text

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; //Variable from PlayStateChangeables.hx
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var name:String = 'Unknown';

	public function new(name:String, variable:String = null, type:String = 'bool', defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null):Void
	{
		this.name = name;
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case 'bool':
					defaultValue = false;
				case 'int' | 'float':
					defaultValue = 0;
				case 'percent':
					defaultValue = 1;
				case 'string':
				{
					defaultValue = '';
					if (options.length > 0) {
						defaultValue = options[0];
					}
				}
			}
		}

		if (getValue() == null) {
			setValue(defaultValue);
		}

		switch (type)
		{
			case 'string':
			{
				var num:Int = options.indexOf(getValue());

				if (num > -1) {
					curOption = num;
				}
			}	
			case 'percent':
			{
				displayFormat = '%v%';
				changeValue = 0.01;
	
				minValue = 0;
				maxValue = 1;
	
				scrollSpeed = 0.5;
				decimals = 2;
			}
		}
	}

	public function change():Void
	{
		if (onChange != null) {
			onChange();
		}
	}

	public function getValue():Dynamic
	{
		return Reflect.getProperty(PlayStateChangeables, variable);
	}

	public function setValue(value:Dynamic):Void
	{
		Reflect.setProperty(PlayStateChangeables, variable, value);
	}

	public function setChild(child:Alphabet):Void
	{
		this.child = child;
	}

	private function get_text():String
	{
		if (child != null) {
			return child.text;
		}

		return null;
	}

	private function set_text(newValue:String = ''):String
	{
		if (child != null) {
			child.changeText(newValue);
		}

		return null;
	}

	public function resetToDefault():Void
	{
		setValue(defaultValue);

		if (name == 'Scroll Speed')
		{
			displayFormat = "%vX";
			maxValue = 3;

			if (getValue() > 3)
			{
				setValue(3);
			}
		}
	}

	private function get_type()
	{
		var newValue:String = 'bool';

		switch (type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string' | 'amogus': newValue = type;
			case 'integer': newValue = 'int';
			case 'str': newValue = 'string';
			case 'fl': newValue = 'float';
		}

		type = newValue;

		return type;
	}
}