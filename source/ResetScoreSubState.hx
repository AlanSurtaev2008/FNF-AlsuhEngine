package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

using StringTools;

class ResetScoreSubState extends MusicBeatSubState
{
	static var onYes:Bool = false;

	var bg:FlxSprite;
	var alphabetArray:Array<Alphabet> = [];
	var icon:HealthIcon;
	var yesText:Alphabet;
	var noText:Alphabet;

	var mode:String;
	var difficulty:String;
	var songID:String;

	public function new(mode:String, songName:String, songID:String, difficultyName:String, difficulty:String, ?character:Null<String> = null):Void
	{
		this.mode = mode;
		this.songID = songID;
		this.difficulty = difficulty;

		super();

		var name:String = songName;
		name += ' (' + difficultyName + ')?';

		bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var tooLong:Float = (name.length > 18) ? 0.8 : 1; // Fucking Winter Horrorland

		var text:Alphabet = new Alphabet(0, 180, "Reset the score of", true);
		text.screenCenter(X);
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);

		var text:Alphabet = new Alphabet(0, text.y + 90, name, true, false, 0.05, tooLong);
		text.screenCenter(X);

		if (mode == 'freeplay')
		{
			text.x += 60 * tooLong;
		}

		alphabetArray.push(text);
		text.alpha = 0;
		add(text);

		if (mode == 'freeplay' && character != null)
		{
			icon = new HealthIcon(character);
			icon.setGraphicSize(Std.int(icon.width * tooLong));
			icon.updateHitbox();
			icon.setPosition(text.x - icon.width + (10 * tooLong), text.y - 30);
			icon.alpha = 0;
			add(icon);
		}

		yesText = new Alphabet(0, text.y + 150, 'Yes', true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		add(yesText);

		noText = new Alphabet(0, text.y + 150, 'No', true);
		noText.screenCenter(X);
		noText.x += 200;
		add(noText);

		updateOptions();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		bg.alpha += elapsed * 1.5;
		if (bg.alpha > 0.6) bg.alpha = 0.6;

		for (i in 0...alphabetArray.length)
		{
			var spr = alphabetArray[i];
			spr.alpha += elapsed * 2.5;
		}

		if (mode == 'freeplay') icon.alpha += elapsed * 2.5;

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			FlxG.sound.play(Paths.getSound('scrollMenu'), 1);
			onYes = !onYes;
			updateOptions();
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.getSound('cancelMenu'), 1);
			close();
		}
		else if (controls.ACCEPT)
		{
			if (onYes)
			{
				if (mode == 'freeplay')
				{
					Highscore.resetSong(CoolUtil.formatSong(songID, difficulty));
				}
				else
				{
					Highscore.resetWeek(CoolUtil.formatSong(songID, difficulty));
				}
			}

			FlxG.sound.play(Paths.getSound('cancelMenu'), 1);
			close();
		}
	}

	function updateOptions():Void
	{
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);

		if (mode == 'freeplay') icon.animation.curAnim.curFrame = confirmInt;
	}
}