package webmlmfao;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.system.FlxSound;

using StringTools;

class VideoSubState extends BaseSubState
{
	public var leSource:String = "";

	public var txt:FlxText;

	public var vidSound:FlxSound = null;

	public var doShit:Bool = false;
	public var pauseText:String = "Press P To Pause/Unpause";

	var holdTimer:Int = 0;
	var crashMoment:Int = 0;
	var itsTooLate:Bool = false;
	var skipTxt:FlxText;

	var onComplete:Void->Void;

	public function new(source:String, ?onComplete:Void->Void):Void
	{
		super();
		
		this.leSource = source;
		this.onComplete = onComplete;
	}
	
	public override function create()
	{
		super.create();

		if (FlxG.sound.music != null) {
			FlxG.sound.music.pause();
		}

		var isHTML:Bool = #if web true #else false #end;

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		txt = new FlxText(0, 0, FlxG.width,
			"If Your On HTML5\nTap Anything...\nThe Bottom Text Indicates If You\nAre Using HTML5...\n\n" +
			(isHTML ? "You Are Using HTML5!" : "You Are Not Using HTML5...\nThe Video Didnt Load!"),
			32);
		txt.setFormat(Paths.getFont("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		txt.screenCenter();
		add(txt);

		skipTxt = new FlxText(FlxG.width / 1.5, FlxG.height - 50, FlxG.width, 'hold ANY KEY to skip', 32);
		skipTxt.setFormat(Paths.getFont("vcr.ttf"), 32, FlxColor.WHITE, LEFT);

		if (GlobalVideo.isWebm)
		{
			if (Paths.fileExists('videos/$leSource.' + Paths.SOUND_EXT, SOUND) || Paths.fileExists('videos/$leSource.' + Paths.SOUND_EXT, MUSIC)) {
				vidSound = FlxG.sound.play(Paths.getWebmSound(leSource), 1, false, null, true);
			}
		}

		GlobalVideo.get().source(Paths.getWebm(leSource));
		GlobalVideo.get().clearPause();

		if (GlobalVideo.isWebm) {
			GlobalVideo.get().updatePlayer();
		}

		GlobalVideo.get().show();

		if (GlobalVideo.isWebm) {
			GlobalVideo.get().restart();
		} else {
			GlobalVideo.get().play();
		}

		doShit = true;

		add(skipTxt);

		if (!PlayState.seenCutscene) {
			PlayState.seenCutscene = true;
		}

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		GlobalVideo.get().update(elapsed);
		
		if (GlobalVideo.get().ended || GlobalVideo.get().stopped)
		{
			txt.visible = false;
			skipTxt.visible = false;

			GlobalVideo.get().hide();
			GlobalVideo.get().stop();
		}

		if (crashMoment > 0) crashMoment--;

		if (FlxG.keys.pressed.ANY && crashMoment <= 0 || itsTooLate && FlxG.keys.pressed.ANY)
		{
			holdTimer++;

			crashMoment = 16;
			itsTooLate = true;
	
			FlxG.sound.music.volume = 0;

			GlobalVideo.get().alpha();
	
			txt.visible = false;
	
			if (holdTimer > 100)
			{
				skipTxt.visible = false;
				GlobalVideo.get().stop();

				end();
			}
		}
		else if (!GlobalVideo.get().paused)
		{
			GlobalVideo.get().unalpha();

			holdTimer = 0;
			itsTooLate = false;
		}
		
		if (GlobalVideo.get().ended) {
			end();
		}

		if (GlobalVideo.get().played || GlobalVideo.get().restarted) {
			GlobalVideo.get().show();
		}

		GlobalVideo.get().restarted = false;
		GlobalVideo.get().played = false;

		GlobalVideo.get().stopped = false;
		GlobalVideo.get().ended = false;
	}

	public function end():Void
	{
		txt.text = pauseText;
		vidSound.destroy();

		close();

		if (onComplete != null) {
			onComplete();
		}
	}
}