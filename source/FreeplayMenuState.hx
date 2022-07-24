package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;

using StringTools;

class FreeplayMenuState extends MusicBeatState
{
	private static var curSelected:Int = -1;
	private static var curDifficultyString:String = '';

	private var curDifficulty:Int = -1;

	private var songsArray:Array<SongMetaData> = [];
	private var curSong:SongMetaData;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpIcons:FlxTypedGroup<HealthIcon>;

	var bg:FlxSprite;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;

	override function create():Void
	{
		super.create();

		#if desktop
		DiscordClient.changePresence("In the Freeplay Menu", null); // Updating Discord Rich Presence
		#end

		if (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		WeekData.reloadWeekFiles(false);

		for (i in 0...WeekData.weeksList.length)
		{
			if (WeekData.weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j].songID);
				leChars.push(leWeek.songs[j].character);
			}

			WeekData.setDirectoryFromWeek(leWeek);

			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song.color;

				if (colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}

				var songItem:SongMetaData = new SongMetaData(song.songID, song.songName, song.character, FlxColor.fromRGB(colors[0], colors[1], colors[2]));
				songItem.difficulties = song.difficulties;
				songItem.defaultDifficulty = song.defaultDifficulty;
				songItem.weekID = leWeek.weekID;
				songItem.weekName = leWeek.weekID;
				songsArray.push(songItem);
			}
		}

		bg = new FlxSprite();
		bg.loadGraphic(Paths.image('bg/menuDesat'));
		bg.color = 0xFFFFFFFF;
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		grpIcons = new FlxTypedGroup<HealthIcon>();
		add(grpIcons);

		for (i in 0...songsArray.length)
		{
			var leSong:SongMetaData = songsArray[i];

			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, leSong.songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			if (songText.width > 980)
			{
				var textScale:Float = 980 / songText.width;
				songText.scale.x = textScale;

				for (letter in songText.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
			}

			Paths.currentModDirectory = songsArray[i].folder;

			var icon:HealthIcon = new HealthIcon(leSong.songCharacter);
			icon.sprTracker = songText;
			icon.ID = i;
			grpIcons.add(icon);

			if (curSelected < 0) curSelected = i;
		}

		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		add(scoreText);

		scoreBG = new FlxSprite(scoreText.x - 6, 0);
		scoreBG.makeGraphic(1, 66, 0xFF000000);
		scoreBG.antialiasing = false;
		scoreBG.alpha = 0.6;
		insert(members.indexOf(scoreText), scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		#if PRELOAD_ALL
		var leText:String = "Press RESET to Reset your Score and Accuracy | Press SPACE to listen to the Song.";
		#else
		var leText:String = "Press RESET to Reset your Score and Accuracy.";
		#end

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height);
		textBG.makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, 18);
		text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		FlxTween.tween(textBG, {y: FlxG.height - 26}, 2, {ease: FlxEase.circOut});
		FlxTween.tween(text, {y: FlxG.height - 26 + 4}, 2, {ease: FlxEase.circOut});

		if (curDifficultyString == '')
		{
			curDifficultyString = songsArray[curSelected].defaultDifficulty;
		}

		curDifficulty = songsArray[curSelected].difficulties[1].indexOf(curDifficultyString);

		changeSelection();
		changeDifficulty();
	}

	public function addSong(song:SongMetaData):Void
	{
		songsArray.push(song);
	}

	public static var vocals:FlxSound = null;
	var instPlaying:Int = -1;

	public static function destroyFreeplayVocals():Void
	{
		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}

		vocals = null;
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	var lerpAccuracy:Float = 0;
	var intendedAccuracy:Float = 0;

	var holdTime:Float = 0;
	var holdTimeHos:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		bg.color = FlxColor.interpolate(bg.color, curSong.color, CoolUtil.boundTo(elapsed * 2.45, 0, 1));

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpAccuracy = FlxMath.lerp(lerpAccuracy, intendedAccuracy, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
		{
			lerpScore = intendedScore;
		}

		if (Math.abs(lerpAccuracy - intendedAccuracy) <= 0.01)
		{
			lerpAccuracy = intendedAccuracy;
		}

		var ratingSplit:Array<String> = Std.string(CoolUtil.truncateFloat(lerpAccuracy * 100, 2)).split('.');

		if (ratingSplit.length < 2) // No decimals, add an empty space
		{
			ratingSplit.push('');
		}
		
		while (ratingSplit[1].length < 2) // Less than 2 decimals in it, add decimals then
		{
			ratingSplit[1] += '0';
		}

		scoreText.text = "PERSONAL BEST:" + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

		if (songsArray.length > 1)
		{
			if (controls.UI_UP_P)
			{
				changeSelection(-shiftMult, true);

				holdTime = 0;
			}

			if (controls.UI_DOWN_P)
			{
				changeSelection(shiftMult, true);

				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult), true);
				}
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);

				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			}
		}

		if (curSong.difficulties[1].length > 1)
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

		if (FlxG.keys.justPressed.SPACE)
		{
			if (instPlaying != curSelected)
			{
				#if PRELOAD_ALL
				destroyFreeplayVocals();

				FlxG.sound.music.volume = 0;
				Paths.currentModDirectory = curSong.folder;

				var diffic:String = CoolUtil.getDifficultySuffix(curDifficultyString, curSong.difficulties);

				PlayState.SONG = Song.loadFromJson(curSong.songID + diffic, curSong.songID);

				if (PlayState.SONG.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.songID));
				else
					vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.songID), 0.7);

				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;

				instPlaying = curSelected;
				#end
			}
		}
		else if (controls.ACCEPT)
		{
			var diffic:String = CoolUtil.getDifficultySuffix(curDifficultyString, curSong.difficulties);

			PlayState.SONG = Song.loadFromJson(curSong.songID + diffic, curSong.songID);
			PlayState.gameMode = 'freeplay';
			PlayState.difficulties = curSong.difficulties.copy();
			PlayState.storyDifficulty = curDifficultyString;
			PlayState.lastDifficulty = curDifficultyString;
			PlayState.storyWeek = curSong.weekID;
			PlayState.storyWeekName = curSong.weekName;
			PlayState.seenCutscene = false;

			#if PRELOAD_ALL
			FlxG.sound.music.volume = 0;
			destroyFreeplayVocals();
			#end

			LoadingState.loadAndSwitchState(new PlayState(), true);
		}
		else if (controls.RESET)
		{
			persistentUpdate = false;

			openSubState(new ResetScoreSubState('freeplay', curSong.songName, curSong.songID, CoolUtil.getDifficultyName(curDifficultyString,
				curSong.difficulties), curDifficultyString, curSong.songCharacter));
		}
	}

	override function closeSubState():Void
	{
		super.closeSubState();

		persistentUpdate = true;

		#if !switch
		intendedScore = Highscore.getScore(CoolUtil.formatSong(curSong.songID, curDifficultyString));
		intendedAccuracy = Highscore.getAccuracy(CoolUtil.formatSong(curSong.songID, curDifficultyString));
		#end
	}

	function changeSelection(change:Int = 0, ?playSound:Bool = true):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = songsArray.length - 1;
		if (curSelected >= songsArray.length)
			curSelected = 0;

		curSong = songsArray[curSelected];

		var bullShit:Int = 0;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}

		for (icon in grpIcons)
		{
			icon.alpha = 0.6;

			if (icon.ID == curSelected)
			{
				icon.alpha = 1;
			}
		}

		Paths.currentModDirectory = curSong.folder;

		#if !switch
		intendedScore = Highscore.getScore(CoolUtil.formatSong(curSong.songID, curDifficultyString));
		intendedAccuracy = Highscore.getAccuracy(CoolUtil.formatSong(curSong.songID, curDifficultyString));
		#end

		if (playSound)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
		}

		changeDifficulty();
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = curSong.difficulties[1].length - 1;
		if (curDifficulty >= curSong.difficulties[1].length)
			curDifficulty = 0;

		curDifficultyString = curSong.difficulties[1][curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(CoolUtil.formatSong(curSong.songID, curDifficultyString));
		intendedAccuracy = Highscore.getAccuracy(CoolUtil.formatSong(curSong.songID, curDifficultyString));
		#end

		diffText.text = '< ' + CoolUtil.getDifficultyName(curDifficultyString, curSong.difficulties).toUpperCase() + ' >';
	}

	function positionHighscore():Void
	{
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - scoreBG.scale.x / 2;

		diffText.x = scoreBG.x + scoreBG.width / 2;
		diffText.x -= diffText.width / 2;
	}
}

class SongMetaData
{
	public var songID:String = '';
	public var songName:String = '';

	public var songCharacter:String = '';

	public var weekID:String = '';
	public var weekName:String = '';
	public var color:FlxColor = 0xFFFFFFFF;

	public var defaultDifficulty:String = 'normal';
	public var difficulties:Array<Array<String>> = [
		['Easy',	'Normal',	'Hard'],
		['easy',	'normal',	'hard'],
		['-easy',	'',			'hard']
	];

	public var folder:String = "";

	public function new(songID:String = '', songName:String = '', songCharacter:String = '',color:FlxColor = 0xFFFFFFFF):Void
	{
		this.songID = songID;
		this.songName = songName;
		this.songCharacter = songCharacter;
		this.color = color;

		this.folder = Paths.currentModDirectory;
		if (this.folder == null) this.folder = '';
	}
}