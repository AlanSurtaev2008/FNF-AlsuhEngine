package editors;

import Song;
import Section;
import StageData;
import FunkinLua;
import PhillyGlow;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxSort;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import openfl.events.KeyboardEvent;
import flixel.input.keyboard.FlxKey;

using StringTools;

class EditorPlayState extends MusicBeatState
{
	var generatedMusic:Bool = false;
	var vocals:FlxSound;

	var timerToStart:Float = 0;
	var startOffset:Float = 0;
	var startPos:Float = 0;
	var combo:Int = 0;

	public function new(startPos:Float):Void
	{
		super();

		this.startPos = startPos;

		Conductor.songPosition = startPos - startOffset;

		startOffset = Conductor.crochet;
		timerToStart = startOffset;
	}

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	public var strumLine:FlxSprite;

	public var cpuStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	var scoreTxt:FlxText;
	var stepTxt:FlxText;
	var beatTxt:FlxText;

	var songHits:Int = 0;
	var songMisses:Int = 0;

	private var keysArray:Array<Dynamic>;

	override function create():Void
	{
		super.create();

		keysArray = [
			OptionData.copyKey(OptionData.keyBinds.get('note_left')),
			OptionData.copyKey(OptionData.keyBinds.get('note_down')),
			OptionData.copyKey(OptionData.keyBinds.get('note_up')),
			OptionData.copyKey(OptionData.keyBinds.get('note_right'))
		];

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.image('bg/menuDesat'));
		bg.scrollFactor.set();
		bg.color = FlxColor.fromHSB(FlxG.random.int(0, 359), FlxG.random.float(0, 0.8), FlxG.random.float(0.3, 1));
		add(bg);

		strumLine = new FlxSprite(OptionData.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, OptionData.downScroll ? FlxG.height - 150 : 50);
		strumLine.makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();
		strumLine.alpha = 0;
		strumLine.visible = false;
		add(strumLine);

		cpuStrums = new FlxTypedGroup<StrumNote>();
		add(cpuStrums);

		playerStrums = new FlxTypedGroup<StrumNote>();
		add(playerStrums);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		splash.alpha = 0.0;
		grpNoteSplashes.add(splash);

		if (!OptionData.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		generateStaticArrows(0);
		generateStaticArrows(1);

		if (PlayState.SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.songID));
		else
			vocals = new FlxSound();

		generateSong(PlayState.SONG);

		scoreTxt = new FlxText(0, FlxG.height - 50, FlxG.width, "Hits: 0 | Misses: 0", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = OptionData.scoreText;
		add(scoreTxt);
		
		beatTxt = new FlxText(10, 610, FlxG.width, "Beat: 0", 20);
		beatTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		beatTxt.scrollFactor.set();
		beatTxt.borderSize = 1.25;
		add(beatTxt);

		stepTxt = new FlxText(10, 640, FlxG.width, "Step: 0", 20);
		stepTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		stepTxt.scrollFactor.set();
		stepTxt.borderSize = 1.25;
		add(stepTxt);

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Go Back to Chart Editor', 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);

		notes.forEachAlive(function(note:Note) 
		{
			if (OptionData.cpuStrumsType != 'Disabled' || note.mustPress)
			{
				note.copyAlpha = false;
				note.alpha = note.multAlpha;

				if (OptionData.middleScroll && !note.mustPress)
				{
					note.alpha *= 0.35;
				}
			}
		});
	}

	private function generateSong(songData:SwagSong):Void
	{
		Conductor.changeBPM(songData.bpm);

		FlxG.sound.playMusic(Paths.inst(songData.song), 0, false);
		FlxG.sound.music.pause();
		FlxG.sound.music.onComplete = endSong;
		vocals.pause();
		vocals.volume = 0;

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection> = songData.notes;

		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;

				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);
				swagNote.noteType = (!Std.isOfType(songNotes[3], String) ? editors.ChartingState.noteTypeList[songNotes[3]] : songNotes[3]);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
			}
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var targetAlpha:Float = 1;

			if (player < 1)
			{
				if (OptionData.cpuStrumsType == 'Disabled')
					targetAlpha = 0;
				else if (OptionData.middleScroll)
					targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(OptionData.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, strumLine.y, i, player);
			babyArrow.alpha = targetAlpha;

			switch (player)
			{
				case 0:
				{
					if (OptionData.middleScroll)
					{
						babyArrow.x += 310;
	
						if (i > 1) { // Up and Right
							babyArrow.x += FlxG.width / 2 + 25;
						}
					}

					cpuStrums.add(babyArrow);
				}
				case 1:
					playerStrums.add(babyArrow);
			}

			babyArrow.postAddedToGroup();
		}
	}

	var startingSong:Bool = true;

	function startSong():Void
	{
		startingSong = false;

		FlxG.sound.music.time = startPos;
		FlxG.sound.music.play();
		FlxG.sound.music.volume = 1;
		vocals.volume = 1;
		vocals.time = startPos;
		vocals.play();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.music.pause();
			vocals.pause();

			LoadingState.loadAndSwitchState(new ChartingState());
		}

		if (startingSong)
		{
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;

			if (timerToStart < 0) {
				startSong();
			}
		}
		else
		{
			Conductor.songPosition += elapsed * 1000;
		}

		var roundedSpeed:Float = FlxMath.roundDecimal(PlayState.SONG.speed, 2);

		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if (roundedSpeed < 1) time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;

			notes.forEachAlive(function(daNote:Note)
			{
				var strumX:Float = 0;
				var strumY:Float = 0;

				var strumAngle:Float = 0;
				var strumAlpha:Float = 0;
		
				if (daNote.mustPress)
				{
					strumX = playerStrums.members[daNote.noteData].x;
					strumY = playerStrums.members[daNote.noteData].y;

					strumAngle = playerStrums.members[daNote.noteData].angle;
					strumAlpha = playerStrums.members[daNote.noteData].alpha;
				}
				else
				{
					strumX = cpuStrums.members[daNote.noteData].x;
					strumY = cpuStrums.members[daNote.noteData].y;

					strumAngle = cpuStrums.members[daNote.noteData].angle;
					strumAlpha = cpuStrums.members[daNote.noteData].alpha;
				}

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;

				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				var center:Float = strumY + Note.swagWidth / 2;

				if (daNote.copyX) {
					daNote.x = strumX;
				}

				if (daNote.copyAngle) {
					daNote.angle = strumAngle;
				}

				if (daNote.copyAlpha) {
					daNote.alpha = strumAlpha;
				}
	
				if (daNote.copyY) {
					noteMovement(daNote, center, strumY, roundedSpeed, fakeCrochet);
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) {
					opponentNoteHit(daNote);
				}

				if (OptionData.downScroll ? daNote.y > FlxG.height : daNote.y < -daNote.height)
				{
					if (daNote.mustPress && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		scoreTxt.text = 'Hits: ' + songHits + ' | Combo Breaks: ' + songMisses;
		beatTxt.text = 'Beat: ' + curBeat;
		stepTxt.text = 'Step: ' + curStep;
	}

	private function noteMovement(daNote:Note, center:Float, strumY:Float, roundedSpeed:Float, fakeCrochet:Float):Void
	{
		if (OptionData.downScroll)
		{
			daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

			if (daNote.isSustainNote)
			{
				if (daNote.animation.curAnim.name.endsWith('end'))
				{
					daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
					daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;

					if (PlayState.isPixelStage) {
						daNote.y += 8;
					} else {
						daNote.y -= 19;
					}
				}

				daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
				daNote.y += 27.5 * ((PlayState.SONG.bpm / 100) - 1) * (roundedSpeed - 1);

				if (daNote.mustPress || !daNote.ignoreNote)
				{
					if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center && (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
						swagRect.height = (center - daNote.y) / daNote.scale.y;
						swagRect.y = daNote.frameHeight - swagRect.height;

						daNote.clipRect = swagRect;
					}
				}
			}
		}
		else
		{
			daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

			if (daNote.mustPress || !daNote.ignoreNote)
			{
				if (daNote.isSustainNote && daNote.y + daNote.offset.y * daNote.scale.y <= center && (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
					swagRect.y = (center - daNote.y) / daNote.scale.y;
					swagRect.height -= swagRect.y;

					daNote.clipRect = swagRect;
				}
			}
		}
	}

	private function popUpScore(daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition);
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;

		var score:Int = 0;

		var daRating:String = Conductor.judgeNote(daNote, noteDiff);

		var rating:FlxSprite = new FlxSprite();
		rating.loadGraphic(Paths.image('ratings/' + daRating + (PlayState.isPixelStage ? '-pixel' : '')));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.setGraphicSize(Std.int(rating.width * (PlayState.isPixelStage ? PlayState.daPixelZoom * 0.7 : 0.7)));
		rating.antialiasing = PlayState.isPixelStage ? false : OptionData.globalAntialiasing;
		rating.x += OptionData.comboOffset[0];
		rating.y -= OptionData.comboOffset[1];
		rating.visible = OptionData.showRatings;
		rating.updateHitbox();
		add(rating);

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite();
			numScore.loadGraphic(Paths.image('numbers/num' + Std.int(i) + (PlayState.isPixelStage ? '-pixel' : '')));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;
			numScore.antialiasing = PlayState.isPixelStage ? false : OptionData.globalAntialiasing;
			numScore.setGraphicSize(Std.int(numScore.width * (PlayState.isPixelStage ? PlayState.daPixelZoom : 0.5)));
			numScore.updateHitbox();
			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.x += OptionData.comboOffset[2];
			numScore.y -= OptionData.comboOffset[3];
			numScore.visible = OptionData.showNumbers;

			if (combo >= 10) {
				add(numScore);
			}

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}

		coolText.text = Std.string(seperatedScore);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001,
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				rating.destroy();
			}
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || OptionData.controllerMode))
		{
			if (generatedMusic)
			{
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !OptionData.ghostTapping;

				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];

				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && daNote.noteData == key)
					{
						sortedNotesList.push(daNote);
					}
				});

				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0)
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) 
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							}
							else
							{
								notesStopped = true;
							}
						}

						if (!notesStopped) // eee jack detection before was not super good
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else
				{
					if (canMiss) {
						noteMissPress(key);
					}
				}

				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];

			if (spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];

			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		}
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}

		return -1;
	}

	private function keyShit():Void
	{
		var holdingArray:Array<Bool> = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];

		if (OptionData.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];

			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i]) {
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
					}
				}
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && holdingArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					goodNoteHit(daNote);
				}
			});
		}

		if (OptionData.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];

			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i]) {
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
					}
				}
			}
		}
	}

	private function endSong():Void
	{
		LoadingState.loadAndSwitchState(new editors.ChartingState());
	}

	function noteMissPress(direction:Int = 1):Void
	{
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		combo = 0;
		songMisses++;

		vocals.volume = 0;
	}

	function noteMiss(daNote:Note):Void
	{
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 10)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		if (!daNote.ignoreNote)
		{
			songMisses++;
			vocals.volume = 0;
		}
	}

	function opponentNoteHit(daNote:Note):Void
	{
		if (PlayState.SONG.needsVoices) {
			vocals.volume = 1;
		}

		var time:Float = 0.15;

		if (daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}

		StrumPlayAnim(true, Std.int(Math.abs(daNote.noteData)), time);

		daNote.hitByOpponent = true;

		daNote.kill();
		notes.remove(daNote, true);
		daNote.destroy();
	}

	function defaultGiverHealth(note:Note):Void
	{
		if (!note.ignoreNote && !note.isSustainNote)
		{
			popUpScore(note);
			songHits++;
			combo++;
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (note.hitCausesMiss)
			{
				noteMiss(note);

				if (!note.noteSplashDisabled && !note.isSustainNote)
				{
					spawnNoteSplashOnNote(note);
				}

				note.wasGoodHit = true;

				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}

				return;
			}
			else
			{
				defaultGiverHealth(note);
			}

			playerStrums.forEach(function(spr:StrumNote)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.playAnim('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note)
	{
		if (OptionData.noteSplashes && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];

			if (strum != null)
			{
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null):Void
	{
		var skin:String = PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0 ? PlayState.SONG.splashSkin : 'noteSplashes';

		var hue:Float = OptionData.arrowHSV[data % 4][0] / 360;
		var sat:Float = OptionData.arrowHSV[data % 4][1] / 100;
		var brt:Float = OptionData.arrowHSV[data % 4][2] / 100;

		if (note != null)
		{
			skin = note.noteSplashTexture;

			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float):Void
	{
		var spr:StrumNote = null;

		if (isDad) {
			spr = cpuStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	override function stepHit():Void
	{
		super.stepHit();

		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}
	}

	override function beatHit():Void
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, OptionData.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();

		Conductor.songPosition = FlxG.sound.music.time;

		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	override function destroy():Void
	{
		super.destroy();

		FlxG.sound.music.stop();

		vocals.stop();
		vocals.destroy();

		if (!OptionData.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
	}
}