package options;

import options.OptionsMenuState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;

using StringTools;

class ComboSubState extends MusicBeatSubState
{
	public var camHUD:FlxCamera;

	var rating:FlxSprite;
	var comboNums:FlxSpriteGroup;

	var isPause:Bool = false;

	public function new(?isPause:Bool = false):Void
	{
		super();

		this.isPause = isPause;
	}

	override function create():Void
	{
		super.create();

		#if desktop
		DiscordClient.changePresence("In the Options Menu - Combo Position", null);
		#end

		FlxG.mouse.visible = true;

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
		}

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD);
		
		camera = camHUD;

		rating = new FlxSprite();
		rating.loadGraphic(Paths.image('ratings/sick', 'shared'));
		rating.screenCenter();
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		rating.antialiasing = OptionData.globalAntialiasing;
		add(rating);

		comboNums = new FlxSpriteGroup();
		comboNums.cameras = [camHUD];
		add(comboNums);

		var seperatedScore:Array<Int> = [];

		for (i in 0...3)
		{
			seperatedScore.push(FlxG.random.int(0, 9));
		}

		var daLoop:Int = 0;

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite(43 * daLoop);
			numScore.loadGraphic(Paths.image('numbers/num' + i, 'shared'));
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			numScore.antialiasing = OptionData.globalAntialiasing;
			numScore.cameras = [camHUD];
			comboNums.add(numScore);

			daLoop++;
		}

		if (isPause) cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		repositionCombo();
	}

	override function destroy():Void
	{
		super.destroy();

		camera = null;
		FlxG.cameras.remove(camHUD);
		camHUD.destroy();
	}

	var holdingObjectType:Null<Bool> = null;

	var startMousePos:FlxPoint = new FlxPoint();
	var startComboOffset:FlxPoint = new FlxPoint();

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var addNum:Int = 1;

		if (FlxG.keys.pressed.SHIFT) addNum = 10;

		var controlArray:Array<Bool> =
		[
			FlxG.keys.justPressed.LEFT,
			FlxG.keys.justPressed.RIGHT,
			FlxG.keys.justPressed.UP,
			FlxG.keys.justPressed.DOWN,
		
			FlxG.keys.justPressed.A,
			FlxG.keys.justPressed.D,
			FlxG.keys.justPressed.W,
			FlxG.keys.justPressed.S
		];

		if (controlArray.contains(true))
		{
			for (i in 0...controlArray.length)
			{
				if (controlArray[i])
				{
					switch (i)
					{
						case 0:
							OptionData.comboOffset[0] -= addNum;
						case 1:
							OptionData.comboOffset[0] += addNum;
						case 2:
							OptionData.comboOffset[1] += addNum;
						case 3:
							OptionData.comboOffset[1] -= addNum;
						case 4:
							OptionData.comboOffset[2] -= addNum;
						case 5:
							OptionData.comboOffset[2] += addNum;
						case 6:
							OptionData.comboOffset[3] += addNum;
						case 7:
							OptionData.comboOffset[3] -= addNum;
					}
				}
			}

			repositionCombo();
		}

		if (FlxG.mouse.justPressed)
		{
			holdingObjectType = null;
			FlxG.mouse.getScreenPosition(camHUD, startMousePos);

			if (startMousePos.x - comboNums.x >= 0 && startMousePos.x - comboNums.x <= comboNums.width && startMousePos.y - comboNums.y >= 0 && startMousePos.y - comboNums.y <= comboNums.height)
			{
				holdingObjectType = true;

				startComboOffset.x = OptionData.comboOffset[2];
				startComboOffset.y = OptionData.comboOffset[3];
			}
			else if (startMousePos.x - rating.x >= 0 && startMousePos.x - rating.x <= rating.width && startMousePos.y - rating.y >= 0 && startMousePos.y - rating.y <= rating.height)
			{
				holdingObjectType = false;

				startComboOffset.x = OptionData.comboOffset[0];
				startComboOffset.y = OptionData.comboOffset[1];
			}
		}

		if (FlxG.mouse.justReleased)
		{
			holdingObjectType = null;
		}

		if (holdingObjectType != null)
		{
			if (FlxG.mouse.justMoved)
			{
				var mousePos:FlxPoint = FlxG.mouse.getScreenPosition(camHUD);
				var addNum:Int = holdingObjectType ? 2 : 0;

				OptionData.comboOffset[addNum + 0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
				OptionData.comboOffset[addNum + 1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);

				repositionCombo();
			}
		}

		if (controls.RESET)
		{
			for (i in 0...OptionData.comboOffset.length)
			{
				OptionData.comboOffset[i] = 0;
			}

			repositionCombo();
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			
			OptionData.savePrefs();

			FlxG.mouse.visible = false;

			if (isPause) {
				PlayState.isNextSubState = true;
			}
			
			FlxG.state.closeSubState();
			FlxG.state.openSubState(new PreferencesSubState(isPause));
		}
	}

	function repositionCombo():Void
	{
		rating.screenCenter();
		rating.x = FlxG.width * 0.55 - 135 + OptionData.comboOffset[0];
		rating.y -= 60 + OptionData.comboOffset[1];

		comboNums.screenCenter();
		comboNums.x = FlxG.width * 0.55 - 175 + OptionData.comboOffset[2];
		comboNums.y += 80 - OptionData.comboOffset[3];
	}
}