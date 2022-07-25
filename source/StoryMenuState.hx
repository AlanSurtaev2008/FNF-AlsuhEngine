package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	private static var curSelected:Int = -1;
	private static var curDifficultyString:String = '';

	private var curDifficulty:Int = -1;

	private var weeksArray:Array<WeekData> = [];
	private var curWeek:WeekData;

	var bgYellow:FlxSprite;
	var bgSprite:FlxSprite;

	var grpWeeks:FlxTypedGroup<MenuItem>;
	var grpLocks:FlxTypedGroup<FlxSprite>;

	var txtTracklist:FlxText;
	var txtWeekTitle:FlxText;
	var scoreText:FlxText;

	var sprDifficulty:FlxSprite;

	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	override function create():Void
	{
		super.create();

		WeekData.reloadWeekFiles(true);

		#if desktop
		DiscordClient.changePresence("In the Story Menu", null); // Updating Discord Rich Presence
		#end

		persistentUpdate = persistentDraw = true;

		if (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		Conductor.changeBPM(102);

		grpWeeks = new FlxTypedGroup<MenuItem>();
		add(grpWeeks);

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		var blackBarThingie:FlxSprite = new FlxSprite();
		blackBarThingie.makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		bgYellow = new FlxSprite(0, 56);
		bgYellow.makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		add(bgYellow);

		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = OptionData.globalAntialiasing;
		add(bgSprite);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		add(grpWeekCharacters);

		var num:Int = 0;

		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = WeekData.weekIsLocked(WeekData.weeksList[i]);

			if (!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				weeksArray.push(weekFile);

				WeekData.setDirectoryFromWeek(weekFile);
	
				var leWeek:WeekData = weeksArray[i];

				var weekThing:MenuItem = new MenuItem(0, bgYellow.y + 396, leWeek.itemFile);
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.targetY = num;
				weekThing.screenCenter(X);
				weekThing.antialiasing = OptionData.globalAntialiasing;
				grpWeeks.add(weekThing);

				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
					lock.frames = Paths.getSparrowAtlas('storymenu/campaign_menu_UI_assets');
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = i;
					lock.antialiasing = OptionData.globalAntialiasing;
					grpLocks.add(lock);
				}

				num++;
			}

			if (curSelected < 0) curSelected = i;
		}

		WeekData.setDirectoryFromWeek(weeksArray[0]);

		var charArray:Array<String> = weeksArray[0].weekCharacters;

		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		leftArrow = new FlxSprite(grpWeeks.members[0].x + grpWeeks.members[0].width + 10, grpWeeks.members[0].y + 10);
		leftArrow.frames = Paths.getSparrowAtlas('storymenu/campaign_menu_UI_assets');
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.antialiasing = OptionData.globalAntialiasing;
		add(leftArrow);
		
		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = OptionData.globalAntialiasing;
		add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.frames = Paths.getSparrowAtlas('storymenu/campaign_menu_UI_assets');
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.antialiasing = OptionData.globalAntialiasing;
		add(rightArrow);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgYellow.y + 425);
		tracksSprite.loadGraphic(Paths.image('storymenu/Menu_Tracks'));
		tracksSprite.antialiasing = OptionData.globalAntialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, '', 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.font('vcr.ttf');
		txtTracklist.color = 0xFFE55777;
		add(txtTracklist);

		scoreText = new FlxText(10, 10, 0, '', 36);
		scoreText.setFormat(Paths.font('vcr.ttf'), 32);
		add(scoreText);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, '', 32);
		txtWeekTitle.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;
		add(txtWeekTitle);

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height);
		textBG.makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, "Press RESET to Reset your Score.", 18);
		text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		FlxTween.tween(textBG, {y: FlxG.height - 26}, 2, {ease: FlxEase.circOut});
		FlxTween.tween(text, {y: FlxG.height - 26 + 4}, 2, {ease: FlxEase.circOut});

		if (curDifficultyString == '')
		{
			curDifficultyString = weeksArray[curSelected].defaultDifficulty;
		}

		curDifficulty = weeksArray[curSelected].difficulties[1].indexOf(curDifficultyString);

		changeSelection();
		changeDifficulty();
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	var selectedWeek:Bool = false;

	var holdTime:Float = 0;
	var holdTimeHos:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.sound.music != null)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
		if (Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

		scoreText.text = 'WEEK SCORE:' + lerpScore;

		var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

		if (!selectedWeek)
		{
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}

			if (weeksArray.length > 1)
			{
				if (controls.UI_UP_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeSelection(-shiftMult);

					holdTime = 0;
				}

				if (controls.UI_DOWN_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeSelection(shiftMult);

					holdTime = 0;
				}
	
				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
	
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
	
				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);

					changeSelection(-shiftMult * FlxG.mouse.wheel);
				}
			}

			if (curWeek.difficulties[1].length > 1)
			{
				if (controls.UI_LEFT_P)
				{
					changeDifficulty(-1);

					holdTimeHos = 0;
				}

				if (controls.UI_RIGHT_P)
				{
					changeDifficulty(1);

					holdTimeHos = 0;
				}
	
				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var checkLastHold:Int = Math.floor((holdTimeHos - 0.5) * 10);
					holdTimeHos += elapsed;
					var checkNewHold:Int = Math.floor((holdTimeHos - 0.5) * 10);
	
					if (holdTimeHos > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeDifficulty((checkNewHold - checkLastHold) * (controls.UI_LEFT ? -1 : 1));
					}
				}
			}

			if (controls.RESET)
			{
				persistentUpdate = false;

				openSubState(new ResetScoreSubState('story', curWeek.weekName, curWeek.weekID, CoolUtil.getDifficultyName(curDifficultyString,
					curWeek.difficulties), curDifficultyString));
			}
			else if (controls.ACCEPT && !WeekData.weekIsLocked(curWeek.weekID))
			{
				selectedWeek = true;

				for (i in 0...grpWeekCharacters.length)
				{
					var char:MenuCharacter = grpWeekCharacters.members[i];

					if (char.character != '' && char.hasConfirmAnimation)
					{
						char.hey();
					}
				}

				grpWeeks.members[curSelected].isFlashing = true;

				var diffic:String = CoolUtil.getDifficultySuffix(curDifficultyString, curWeek.difficulties);

				PlayState.SONG = Song.loadFromJson(curWeek.songs[0].songID + diffic, curWeek.songs[0].songID);
				PlayState.gameMode = 'story';

				var songArray:Array<String> = [];

				for (i in 0...curWeek.songs.length)
				{
					songArray.push(curWeek.songs[i].songID);
				}

				PlayState.storyPlaylist = songArray;
				PlayState.storyDifficulty = curDifficultyString;
				PlayState.lastDifficulty = curDifficultyString;
				PlayState.storyWeek = curWeek.weekID;
				PlayState.storyWeekName = curWeek.weekName;
				PlayState.difficulties = curWeek.difficulties;
				PlayState.campaignScore = 0;
				PlayState.seenCutscene = false;

				FlxG.sound.play(Paths.sound('confirmMenu'));
				
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					LoadingState.loadAndSwitchState(new PlayState(), true);
					FreeplayMenuState.destroyFreeplayVocals();
				});
			}
		}
	}

	override function closeSubState():Void
	{
		super.closeSubState();

		persistentUpdate = true;

		#if !switch
		intendedScore = Highscore.getWeekScore(CoolUtil.formatSong(curWeek.weekID, curDifficultyString));
		#end
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = weeksArray.length - 1;
		if (curSelected >= weeksArray.length)
			curSelected = 0;

		curWeek = weeksArray[curSelected];

		WeekData.setDirectoryFromWeek(curWeek);

		var bullShit:Int = 0;

		for (item in grpWeeks.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}

		#if !switch
		intendedScore = Highscore.getWeekScore(CoolUtil.formatSong(curWeek.weekID, curDifficultyString));
		#end

		updateText();
		changeDifficulty();
	}

	var tweenDifficulty:FlxTween;

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = curWeek.difficulties[1].length - 1;
		if (curDifficulty >= curWeek.difficulties[1].length)
			curDifficulty = 0;

		WeekData.setDirectoryFromWeek(curWeek);

		var newDifficulty:String = curWeek.difficulties[1][curDifficulty];

		if (curDifficultyString != newDifficulty)
		{
			sprDifficulty.loadGraphic(Paths.image('storymenu/menudifficulties/' + newDifficulty));
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 2;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - 15;

			if (tweenDifficulty != null) tweenDifficulty.cancel();

			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07, {
				onComplete: function(twn:FlxTween)
				{
					tweenDifficulty = null;
				}
			});
		}
		else
		{
			sprDifficulty.loadGraphic(Paths.image('storymenu/menudifficulties/' + newDifficulty));
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 2;
			sprDifficulty.y = leftArrow.y + 15;
		}

		curDifficultyString = newDifficulty;

		#if !switch
		intendedScore = Highscore.getWeekScore(CoolUtil.formatSong(curWeek.weekID, curDifficultyString));
		#end
	}

	function updateText():Void
	{
		for (i in 0...grpWeekCharacters.length)
		{
			grpWeekCharacters.members[i].changeCharacter(curWeek.weekCharacters[i]);
		}

		var leName:String = curWeek.storyName;

		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		txtTracklist.text = '';

		var stringThing:Array<String> = [];

		for (i in 0...curWeek.songs.length)
		{
			stringThing.push(curWeek.songs[i].songName);
		}

		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		bgSprite.visible = true;

		var assetName:String = curWeek.weekBackground;

		if (assetName == null || assetName.length < 1)
		{
			bgSprite.visible = false;
		}
		else
		{
			bgSprite.loadGraphic(Paths.image('storymenu/menubackgrounds/menu_' + assetName));
		}
	}

	override function beatHit():Void
	{
		super.beatHit();

		for (i in 0...grpWeekCharacters.length)
		{
			var leChar:MenuCharacter = grpWeekCharacters.members[i];

			if (leChar.isDanced && !leChar.heyed)
			{
				leChar.dance();
			}
			else
			{
				if (curBeat % 2 == 0 && !leChar.heyed)
				{
					leChar.dance();
				}
			}
		}
	}
}