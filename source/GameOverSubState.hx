package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

class GameOverSubState extends MusicBeatSubState
{
	public static var instance:GameOverSubState;

	public var boyfriend:Boyfriend;

	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;

	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static function resetVariables():Void
	{
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	public override function create():Void
	{
		super.create();

		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);
	}

	public function new(x:Float, y:Float):Void
	{
		super();

		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.changeBPM(100);
		Conductor.songPosition = 0;

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		FlxG.sound.play(Paths.getSound(deathSoundName));

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
	}

	var isFollowingAlready:Bool = false;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (updateCamera)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT)
		{
			endBullshit(false);
		}

		if (controls.BACK)
		{
			endBullshit(true);
		}

		if (boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if (boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);

				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished && !playingDeathSound)
			{
				if (OptionData.naughtyness && PlayState.SONG.stage == 'tank')
				{
					playingDeathSound = true;
					coolStartDeath(0.2);
					
					var exclude:Array<Int> = [];

					FlxG.sound.play(Paths.getSound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function()
					{
						if (!isEnding)
						{
							FlxG.sound.music.fadeIn(0.2, 1, 4);
						}
					});
				}
				else
				{
					coolStartDeath(1);
				}

				boyfriend.startedDeath = true;
			}
		}

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}

		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.getMusic(loopSoundName), volume);
	}

	var isEnding:Bool = false;

	function endBullshit(toMenu:Bool = false):Void
	{
		if (!isEnding)
		{
			isEnding = true;

			boyfriend.playAnim('deathConfirm', true);

			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.getMusic(endSoundName));

			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					if (toMenu)
					{
						PlayState.deathCounter = 0;
						PlayState.seenCutscene = false;

						WeekData.loadTheFirstEnabledMod();
			
						switch (PlayState.gameMode)
						{
							case 'story':
								FlxG.switchState(new StoryMenuState());
							case 'freeplay':
								FlxG.switchState(new FreeplayMenuState());
							case 'replay':
							{
								if (FlxG.save.data.scrollSpeed != null)
								{
									PlayStateChangeables.scrollSpeed = FlxG.save.data.scrollSpeed;
								}
								else
								{
									PlayStateChangeables.scrollSpeed = 1.0;
								}
			
								if (FlxG.save.data.downScroll != null)
								{
									OptionData.downScroll = FlxG.save.data.downScroll;
								}
								else
								{
									OptionData.downScroll = false;
								}
	
								FlxG.switchState(new options.ReplaysState());
							}
							default:
								FlxG.switchState(new MainMenuState());
						}
					}
					else
					{
						FlxG.resetState();
					}
				});
			});

			if (toMenu) {
				PlayState.instance.callOnLuas('onExitFromGameOver', [true]);
			} else {
				PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
			}
		}
	}
}
