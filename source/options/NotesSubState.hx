package options;

import options.OptionsMenuState;

import shaders.ColorSwap;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.effects.FlxFlicker;

using StringTools;

class NotesSubState extends MusicBeatSubState
{
	private static var curSelected:Int = 0;
	private static var typeSelected:Int = 0;

	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderArray:Array<ColorSwap> = [];

	var curValue:Float = 0;

	var blackBG:FlxSprite;
	var hsbText:Alphabet;

	var posX:Int = 230;

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
			practiceText.visible = PlayStateChangeables.practiceMode;
			add(practiceText);
		}
		
		blackBG = new FlxSprite(posX - 25).makeGraphic(870, 200, FlxColor.BLACK);
		blackBG.alpha = 0.4;
		add(blackBG);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);

		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		for (i in 0...OptionData.arrowHSV.length)
		{
			var yPos:Float = (165 * i) + 35;

			for (j in 0...3)
			{
				var optionText:Alphabet = new Alphabet(0, yPos + 60, Std.string(OptionData.arrowHSV[i][j]), true);
				optionText.x = posX + (225 * j) + 250;
				grpNumbers.add(optionText);
			}

			var note:FlxSprite = new FlxSprite(posX, yPos);
			note.frames = Paths.getSparrowAtlas('notes/NOTE_assets', 'shared');

			var animations:Array<String> = ['purple0', 'blue0', 'green0', 'red0'];
			note.animation.addByPrefix('idle', animations[i]);
			note.animation.play('idle');
			note.antialiasing = OptionData.globalAntialiasing;
			grpNotes.add(note);

			var newShader:ColorSwap = new ColorSwap();
			note.shader = newShader.shader;
			newShader.hue = OptionData.arrowHSV[i][0] / 360;
			newShader.saturation = OptionData.arrowHSV[i][1] / 100;
			newShader.brightness = OptionData.arrowHSV[i][2] / 100;
			shaderArray.push(newShader);
		}

		hsbText = new Alphabet(0, 0, "Hue    Saturation  Brightness", false, false, 0, 0.65);
		hsbText.x = posX + 240;
		add(hsbText);

		if (isPause) cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		changeSelection();
	}

	var nextAccept:Int = 5;

	var holdTime:Float = 0;
	var holdTimeType:Float = 0;

	var holdTimeValue:Float = 0;

	var flickering:Bool = false;
	var changingNote:Bool = false;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!flickering)
		{
			if (changingNote)
			{
				if (controls.BACK || controls.ACCEPT)
				{
					changingNote = false;
					changeSelection();
				}

				if (holdTimeValue < 0.5)
				{
					if (controls.UI_LEFT_P)
					{
						updateValue(-1);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
					else if (controls.UI_RIGHT_P)
					{
						updateValue(1);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
					else if (controls.RESET)
					{
						resetValue(curSelected, typeSelected);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}

					if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
					{
						holdTimeValue = 0;
					}
					else if (controls.UI_LEFT || controls.UI_RIGHT)
					{
						holdTimeValue += elapsed;
					}
				}
				else
				{
					var add:Float = 90;
		
					switch (typeSelected)
					{
						case 1 | 2: add = 50;
					}
			
					if (controls.UI_LEFT)
					{
						updateValue(elapsed * -add);
					}
					else if (controls.UI_RIGHT)
					{
						updateValue(elapsed * add);
					}
				
					if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						holdTimeValue = 0;
					}
				}
			}
			else
			{
				if (OptionData.arrowHSV.length > 1)
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
						changeSelection(-1 * FlxG.mouse.wheel);
					}
				}

				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));

					changeType(-1);
					holdTime = 0;
				}

				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));

					changeType(1);
					holdTime = 0;
				}

				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						changeType((checkNewHold - checkLastHold) * (controls.UI_LEFT ? -1 : 1));
					}
				}

				if (controls.RESET)
				{
					for (i in 0...3) {
						resetValue(curSelected, i);
					}

					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
		
				if (controls.ACCEPT && nextAccept <= 0)
				{
					if (OptionData.flashingLights)
					{
						flickering = true;

						FlxFlicker.flicker(grpNotes.members[curSelected], 1, 0.06, true);

						FlxFlicker.flicker(grpNumbers.members[(curSelected * 3) + typeSelected], 1, 0.06, true, false, function(flick:FlxFlicker)
						{
							selectType();
						});

						FlxG.sound.play(Paths.sound('confirmMenu'));
					}
					else
					{
						selectType();
					}
				}

				if (controls.BACK)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
	
					if (isPause)
					{
						OptionData.savePrefs();
	
						PlayState.isNextSubState = true;
	
						FlxG.state.closeSubState();
						FlxG.state.openSubState(new OptionsSubState());
					}
					else
					{
						close();
					}
				}
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function selectType():Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));

		flickering = false;
		changingNote = true;
		holdTimeValue = 0;

		for (i in 0...grpNumbers.length)
		{
			var item = grpNumbers.members[i];
			item.alpha = 0;

			if ((curSelected * 3) + typeSelected == i)
			{
				item.alpha = 1;
			}
		}

		for (i in 0...grpNotes.length)
		{
			var item = grpNotes.members[i];
			item.alpha = 0;

			if (curSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = OptionData.arrowHSV.length - 1;
		if (curSelected >= OptionData.arrowHSV.length)
			curSelected = 0;

		curValue = OptionData.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length)
		{
			var item = grpNumbers.members[i];
			item.alpha = 0.6;

			if ((curSelected * 3) + typeSelected == i)
			{
				item.alpha = 1;
			}
		}

		for (i in 0...grpNotes.length)
		{
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(0.75, 0.75);
	
			if (curSelected == i)
			{
				item.alpha = 1;
				item.scale.set(1, 1);
		
				hsbText.y = item.y - 70;
				blackBG.y = item.y - 20;
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0):Void
	{
		typeSelected += change;

		if (typeSelected < 0)
			typeSelected = 2;
		if (typeSelected > 2)
			typeSelected = 0;

		curValue = OptionData.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length)
		{
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
	
			if ((curSelected * 3) + typeSelected == i)
			{
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int):Void
	{
		curValue = 0;

		OptionData.arrowHSV[selected][type] = 0;

		switch (type)
		{
			case 0: shaderArray[selected].hue = 0;
			case 1: shaderArray[selected].saturation = 0;
			case 2: shaderArray[selected].brightness = 0;
		}

		var item = grpNumbers.members[(selected * 3) + type];
		item.changeText('0');
		item.offset.x = (40 * (item.lettersArray.length - 1)) / 2;
	}

	function updateValue(change:Float = 0):Void
	{
		curValue += change;

		var roundedValue:Int = Math.round(curValue);
		var max:Float = 180;

		switch (typeSelected)
		{
			case 1 | 2: max = 100;
		}

		if (roundedValue < -max) {
			curValue = -max;
		} else if (roundedValue > max) {
			curValue = max;
		}

		roundedValue = Math.round(curValue);

		OptionData.arrowHSV[curSelected][typeSelected] = roundedValue;

		switch (typeSelected)
		{
			case 0: shaderArray[curSelected].hue = roundedValue / 360;
			case 1: shaderArray[curSelected].saturation = roundedValue / 100;
			case 2: shaderArray[curSelected].brightness = roundedValue / 100;
		}

		var item = grpNumbers.members[(curSelected * 3) + typeSelected];
		item.changeText(Std.string(roundedValue));
		item.offset.x = (40 * (item.lettersArray.length - 1)) / 2;

		if (roundedValue < 0) item.offset.x += 10;
	}
}