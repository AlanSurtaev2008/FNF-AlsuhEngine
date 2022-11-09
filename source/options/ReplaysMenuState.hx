package options;

#if desktop
import Discord.DiscordClient;
#end

import flixel.FlxG;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import flixel.FlxSprite;
import flixel.group.FlxGroup;

using StringTools;

class ReplaysMenuState extends TransitionableState
{
	var curSelected:Int = 0;

	var replaysArray:Array<String> = [];
	var actualNames:Array<String> = [];

	var grpReplays:FlxTypedGroup<Alphabet>;

	public override function create():Void
	{
		super.create();

		persistentUpdate = true;

		#if desktop
		DiscordClient.changePresence("In the Replays Menu", null); // Updating Discord Rich Presence
		#end

		if (FlxG.sound.music.playing == false || FlxG.sound.music.volume == 0) {
			FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
		}

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.getImage('bg/menuBGBlue'));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = OptionData.globalAntialiasing;
		add(bg);

		#if sys
		replaysArray = FileSystem.readDirectory(Sys.getCwd() + "\\assets\\replays\\");
		#end
		replaysArray.sort(Reflect.compare);

		if (replaysArray.length >= 1)
		{
			for (i in 0...replaysArray.length)
			{
				var string:String = replaysArray[i];
				actualNames[i] = string;
		
				var rep:Replay = Replay.loadReplay(string);
				replaysArray[i] = rep.replay.songName + ' - ' + CoolUtil.getDifficultyName(rep.replay.songDiff) + ' ' + rep.replay.timestamp;
			}
		}
		else {
			replaysArray.push('No replays...');
		}

		grpReplays = new FlxTypedGroup<Alphabet>();
		add(grpReplays);

		for (i in 0...replaysArray.length)
		{
			var replayText:Alphabet = new Alphabet(0, (100 * i) + 210, replaysArray[i], false);
			replayText.isMenuItem = true;
			replayText.targetY = i;
			replayText.startPosition.y = -70;
			grpReplays.add(replayText);
		}

		changeSelection();
	}

	var holdTime:Float = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new OptionsMenuState());
		}

		if (controls.UI_DOWN || controls.UI_UP)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.getSound('scrollMenu'));
				changeSelection(-1);

				holdTime = 0;
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.getSound('scrollMenu'));
				changeSelection(1);

				holdTime = 0;
			}

			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
			{
				changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
				FlxG.sound.play(Paths.getSound('scrollMenu'));
			}
		}

		if (controls.ACCEPT || FlxG.mouse.justPressed)
		{
			if (replaysArray[curSelected] != "No replays...")
			{
				persistentUpdate = false;

				PlayState.rep = Replay.loadReplay(actualNames[curSelected]);

				var diffic:String = CoolUtil.getDifficultySuffix(PlayState.rep.replay.songDiff, false, PlayState.rep.replay.difficulties);

				PlayState.SONG = Song.loadFromJson(PlayState.rep.replay.songID  + diffic, PlayState.rep.replay.songID);
				PlayState.gameMode = 'replay';
				PlayState.isStoryMode = false;
				PlayState.difficulties = PlayState.rep.replay.difficulties;
				PlayState.lastDifficulty = PlayState.rep.replay.songDiff;
				PlayState.storyDifficulty = PlayState.rep.replay.songDiff;
				PlayState.storyWeek = PlayState.rep.replay.weekID;
				PlayState.storyWeekName = PlayState.rep.replay.weekName;

				if (!OptionData.loadingScreen) {
					FreeplayMenuState.destroyFreeplayVocals();
				}

				LoadingState.loadAndSwitchState(new PlayState(), true);
			}
			else {
				FlxG.sound.play(Paths.getSound('cancelMenu'));
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = replaysArray.length - 1;
		if (curSelected >= replaysArray.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpReplays.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
	}
}