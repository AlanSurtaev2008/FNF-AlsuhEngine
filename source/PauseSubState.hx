package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import options.OptionsMenuState.OptionsSubState;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

class PauseSubState extends MusicBeatSubState
{
	static var playingPause:Bool = false;
	static var goToOptions:Bool = false;

	var curSelected:Int = 0;

	var menuItems:Array<String> = [];

	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Toggle Practice Mode', 'Toggle Botplay', 'Options', 'Exit to menu'];
	var difficultyChoices:Array<String> = [];

	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var pauseMusic:FlxSound;

	var practiceText:FlxText;

	var fromOptions:Bool = false;

	public function new(?fromOptions:Bool = false):Void
	{
		super();

		this.fromOptions = fromOptions;
	}

	override function create():Void
	{
		super.create();

		menuItems = menuItemsOG;

		if (PlayState.difficulties[1].length < 2 || PlayState.gameMode == 'replay')
		{
			menuItemsOG.remove('Change Difficulty');

			if (PlayState.gameMode == 'replay')
			{
				menuItemsOG.remove('Toggle Practice Mode');
				menuItemsOG.remove('Toggle Botplay');
			}
		}

		for (i in 0...PlayState.difficulties[1].length)
		{
			difficultyChoices.push(CoolUtil.getDifficultyName(PlayState.difficulties[1][i]));
		}

		difficultyChoices.push('BACK');

		if (FlxG.sound.music.playing && FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
		}

		for (i in FlxG.sound.list)
		{
			if (i.playing && i.ID != 9000) {
				i.pause();
			}
		}

		goToOptions = false;

		if (!playingPause)
		{
			playingPause = true;
	
			pauseMusic = new FlxSound();

			if (OptionData.pauseMusic != 'None') {
				pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(OptionData.pauseMusic)), true, true);
			}

			pauseMusic.volume = 0;
			pauseMusic.ID = 9000;
			pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
			FlxG.sound.list.add(pauseMusic);
		}
		else
		{
			for (i in FlxG.sound.list)
			{
				if (i.ID == 9000) // jankiest static variable
					pauseMusic = i;
			}
		}

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, '', 32);
		levelInfo.text += PlayState.SONG.songName;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font('vcr.ttf'), 32);
		levelInfo.updateHitbox();
		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, '', 32);
		levelDifficulty.text += CoolUtil.getDifficultyName(PlayState.lastDifficulty, PlayState.difficulties).toUpperCase();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, '', 32);
		blueballedTxt.text = 'Blue balled: ' + PlayState.deathCounter;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);
		add(blueballedTxt);

		practiceText = new FlxText(20, 15 + 96, 0, 'PRACTICE MODE', 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.alpha = 0;
		add(practiceText);

		if (fromOptions)
		{
			bg.alpha = 0.6;

			levelInfo.y += 5;
			levelDifficulty.y += 5;
			blueballedTxt.y += 5;

			if (PlayState.practiceMode) {
				practiceText.alpha = 1;
				practiceText.y += 5;
			}
		}
		else
		{
			levelInfo.alpha = 0;
			levelDifficulty.alpha = 0;
			blueballedTxt.alpha = 0;

			FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

			FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
			FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

			if (PlayState.practiceMode)
			{
				FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});
			}
		}

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		regenMenu();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	private function regenMenu():Void
	{
		while (grpMenuShit.members.length > 0)
		{
			grpMenuShit.remove(grpMenuShit.members[0], true);
		}

		for (i in 0...menuItems.length)
		{
			var menuItem:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			menuItem.isMenuItem = true;
			menuItem.targetY = i;
			grpMenuShit.add(menuItem);
		}

		curSelected = 0;

		changeSelection();
	}

	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (pauseMusic != null && pauseMusic.volume < 0.5) {
			pauseMusic.volume += 0.01 * elapsed;
		}

		if (menuItems.length > 1)
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
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
				}
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);

				changeSelection(-1 * FlxG.mouse.wheel);
			}
		}

		if (controls.ACCEPT && !OptionData.controllerMode)
		{
			var daSelected:String = menuItems[curSelected];

			if (menuItems == difficultyChoices)
			{
				if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
				{
					var difficulty:String = CoolUtil.getDifficultySuffix(daSelected, true, PlayState.difficulties.copy());

					PlayState.SONG = Song.loadFromJson(PlayState.SONG.songID + difficulty, PlayState.SONG.songID);
					PlayState.lastDifficulty = CoolUtil.getDifficultyID(daSelected);
					PlayState.usedPractice = true;

					FlxG.sound.music.volume = 0;
					MusicBeatState.resetState();

					return;
				}
				else
				{
					menuItems = menuItemsOG;
					regenMenu();
				}
			}

			switch (daSelected)
			{
				case 'Resume':
				{
					close();
				}
				case 'Restart Song':
				{
					restartSong();
				}
				case 'Change Difficulty':
				{
					menuItems = difficultyChoices;
					regenMenu();
				}
				case 'Toggle Practice Mode':
				{
					PlayState.practiceMode = !PlayState.practiceMode;
					PlayState.usedPractice = PlayState.practiceMode;

					if (PlayState.practiceMode)
					{
						FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut});
					}
					else
					{
						FlxTween.tween(practiceText, {alpha: 0, y: practiceText.y - 5}, 0.4, {ease: FlxEase.quartInOut});
					}
				}
				case 'Toggle Botplay':
				{
					PlayState.botPlay = !PlayState.botPlay;
					PlayState.usedPractice = PlayState.botPlay;

					PlayState.instance.botplayTxt.visible = PlayState.botPlay;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				}
				case 'Options':
				{
					goToOptions = true;

					PlayState.isNextSubState = true;

					FlxG.state.closeSubState();
					FlxG.state.openSubState(new OptionsSubState());
				}
				case 'Exit to menu':
				{
					PlayState.cancelMusicFadeTween();

					FlxG.sound.music.volume = 0;

					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					PlayState.botPlay = false;
					PlayState.practiceMode = false;
					PlayState.usedPractice = false;

					switch (PlayState.gameMode)
					{
						case 'story':
							MusicBeatState.switchState(new StoryMenuState());
						case 'freeplay':
							MusicBeatState.switchState(new FreeplayMenuState());
						case 'replay':
							MusicBeatState.switchState(new options.ReplaysState());
						default:
							MusicBeatState.switchState(new MainMenuState());
					}
				}
			}
		}
	}

	public static function restartSong(noTrans:Bool = false):Void
	{
		PlayState.instance.paused = true; // For lua

		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if (noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			MusicBeatState.resetState();
		}
	}

	override function destroy():Void
	{
		super.destroy();

		if (!goToOptions)
		{
			pauseMusic.destroy();
			playingPause = false;
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
	}
}
