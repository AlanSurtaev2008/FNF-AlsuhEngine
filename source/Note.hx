package;

import flixel.FlxG;
import flixel.FlxSprite;
import shaders.ColorSwap;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.display.BitmapData;

using StringTools;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var spawned:Bool = false;
	public var noRating:Bool = false;
	public var parent:Note;

	public var blockHit:Bool = false; // only works for player

	public var tail:Array<Note> = []; // for sustains lol
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var noHealth:Bool = false;

	public var colorSwap:ColorSwap;
	public var inEditor:Bool = false;
	private var earlyHitMult:Float = 0.5;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	// Lua shit
	public var quickNoteSplash:Bool = false;
	public var noteSplashHitByOpponent:Bool = false;
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;

	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var isCustomNoteSplash:Bool = false;
	public var noteSplashHueCustom:Float = 0;
	public var noteSplashSatCustom:Float = 0;
	public var noteSplashBrtCustom:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;

	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var copyX:Bool = true;
	public var copyY:Bool = true;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealthSick:Float = 0.025;
	public var hitHealthSickSus:Float = 0.0125;
	public var hitHealthGood:Float = 0.020;
	public var hitHealthGoodSus:Float = 0.010;
	public var hitHealthBad:Float = 0.010;
	public var hitHealthBadSus:Float = 0.005;
	public var hitHealthShit:Float = 0;
	public var hitHealthShitSus:Float = 0;

	public var missHealth:Float = 0.0475;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;

	public var lowPriority:Bool = false;

	public var texture(default, set):String = null;

	public var hitsoundDisabled:Bool = false;

	private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;

		return value;
	}

	public function resizeByRatio(ratio:Float):Void // haha funny twitter shit
	{
		if (isSustainNote && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	public var hitCausesMiss:Bool = false;

	private function set_texture(value:String):String
	{
		if (texture != value) {
			reloadNote('', value);
		}

		texture = value;

		return value;
	}

	private function set_noteType(value:String):String
	{
		noteSplashTexture = PlayState.SONG.splashSkin;

		if (noteData > -1)
		{
			colorSwap.hue = OptionData.arrowHSV[noteData % 4][0] / 360;
			colorSwap.saturation = OptionData.arrowHSV[noteData % 4][1] / 100;
			colorSwap.brightness = OptionData.arrowHSV[noteData % 4][2] / 100;
		}

		if (noteData > -1 && noteType != value)
		{
			switch (value)
			{
				case 'Hurt Note':
				{
					ignoreNote = mustPress;
					reloadNote('HURT');

					noteSplashTexture = 'HURTNOTE_splashes';

					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;

					lowPriority = true;

					if (isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}

					hitCausesMiss = true;
				}
				case 'Alt Animation':
				{
					animSuffix = '-alt';
				}
				case 'No Animation':
				{
					noAnimation = true;
					noMissAnimation = true;
				}
				case 'GF Sing':
				{
					gfNote = true;
				}
			}

			noteType = value;
		}

		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?isSustainNote:Bool = false, ?inEditor:Bool = false, ?mustPress:Bool = false):Void
	{
		super();

		if (prevNote == null) {
			prevNote = this;
		}

		this.prevNote = prevNote;
		this.isSustainNote = isSustainNote;
		this.inEditor = inEditor;
		this.mustPress = mustPress;

		x += (OptionData.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;

		y -= 2000;

		this.strumTime = strumTime;

		if (!inEditor) this.strumTime += OptionData.noteOffset;

		this.noteData = noteData;

		if (noteData > -1)
		{
			texture = '';

			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			x += swagWidth * (noteData % 4);

			if (!isSustainNote) // Doing this 'if' check to fix the warnings on Senpai songs
			{
				var animToPlay:String = '';

				switch (noteData % 4)
				{
					case 0:
						animToPlay = 'purple';
					case 1:
						animToPlay = 'blue';
					case 2:
						animToPlay = 'green';
					case 3:
						animToPlay = 'red';
				}

				animation.play(animToPlay + 'Scroll');
			}
		}

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;

			hitsoundDisabled = true;

			if (OptionData.downScroll == true) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			switch (noteData)
			{
				case 0:
					animation.play('purpleholdend');
				case 1:
					animation.play('blueholdend');
				case 2:
					animation.play('greenholdend');
				case 3:
					animation.play('redholdend');
			}

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage) {
				offsetX += 30;
			}

			if (prevNote.isSustainNote)
			{
				switch (prevNote.noteData)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05 * PlayState.SONG.speed;

				if (PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
				}

				prevNote.updateHitbox();
			}

			if (PlayState.isPixelStage) {
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
		}
		else if (!isSustainNote)
		{
			earlyHitMult = 1;
		}

		x += offsetX;
	}

	public var originalHeightForCalcs:Float = 6;

	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = ''):Void
	{
		if (prefix == null) prefix = '';
		if (texture == null) texture = '';
		if (suffix == null) suffix = '';
		
		var skin:String = texture;

		if (texture.length < 1)
		{
			skin = mustPress ? PlayState.SONG.arrowSkin : PlayState.SONG.arrowSkin2;
	
			if (skin == null || skin.length < 1)
			{
				skin = 'NOTE_assets';
			}
		}

		var animName:String = null;

		if (animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length - 1] = prefix + arraySkin[arraySkin.length - 1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');

		if (PlayState.isPixelStage)
		{
			if (isSustainNote)
			{
				loadGraphic(Paths.getImage('notes/pixel/' + blahblah + 'ENDS'));

				width = width / 4;
				height = height / 2;

				originalHeightForCalcs = height;

				loadGraphic(Paths.getImage('notes/pixel/' + blahblah + 'ENDS'), true, Math.floor(width), Math.floor(height));
			}
			else
			{
				loadGraphic(Paths.getImage('notes/pixel/' + blahblah));

				width = width / 4;
				height = height / 5;

				loadGraphic(Paths.getImage('notes/pixel/' + blahblah), true, Math.floor(width), Math.floor(height));
			}

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;
		}
		else
		{
			frames = Paths.getSparrowAtlas('notes/' + blahblah);

			loadNoteAnims();

			antialiasing = OptionData.globalAntialiasing;
		}

		if (isSustainNote) {
			scale.y = lastScaleY;
		}

		updateHitbox();

		if (animName != null)
		{
			animation.play(animName, true);
		}

		if (inEditor)
		{
			setGraphicSize(editors.ChartingState.GRID_SIZE, editors.ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	function loadNoteAnims():Void
	{
		animation.addByPrefix('greenScroll', 'green0');
		animation.addByPrefix('redScroll', 'red0');
		animation.addByPrefix('blueScroll', 'blue0');
		animation.addByPrefix('purpleScroll', 'purple0');

		if (isSustainNote)
		{
			animation.addByPrefix('purpleholdend', 'pruple end hold');
			animation.addByPrefix('greenholdend', 'green hold end');
			animation.addByPrefix('redholdend', 'red hold end');
			animation.addByPrefix('blueholdend', 'blue hold end');

			animation.addByPrefix('purplehold', 'purple hold piece');
			animation.addByPrefix('greenhold', 'green hold piece');
			animation.addByPrefix('redhold', 'red hold piece');
			animation.addByPrefix('bluehold', 'blue hold piece');
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims():Void
	{
		if (isSustainNote)
		{
			animation.add('purpleholdend', [PURP_NOTE + 4]);
			animation.add('greenholdend', [GREEN_NOTE + 4]);
			animation.add('redholdend', [RED_NOTE + 4]);
			animation.add('blueholdend', [BLUE_NOTE + 4]);

			animation.add('purplehold', [PURP_NOTE]);
			animation.add('greenhold', [GREEN_NOTE]);
			animation.add('redhold', [RED_NOTE]);
			animation.add('bluehold', [BLUE_NOTE]);
		}
		else
		{
			animation.add('greenScroll', [GREEN_NOTE + 4]);
			animation.add('redScroll', [RED_NOTE + 4]);
			animation.add('blueScroll', [BLUE_NOTE + 4]);
			animation.add('purpleScroll', [PURP_NOTE + 4]);
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (noteData > -1)
		{
			colorSwap.hue = OptionData.arrowHSV[noteData % 4][0] / 360;
			colorSwap.saturation = OptionData.arrowHSV[noteData % 4][1] / 100;
			colorSwap.brightness = OptionData.arrowHSV[noteData % 4][2] / 100;

			noteSplashHue = colorSwap.hue;
			noteSplashSat = colorSwap.saturation;
			noteSplashBrt = colorSwap.brightness;
		}

		if (mustPress)
		{
			if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
			{
				canBeHit = false;
			}

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
			{
				wasGoodHit = true;
			}
		}

		if (tooLate)
		{
			if (alpha > 0.3) {
				alpha = 0.3;
			}
		}
	}
}