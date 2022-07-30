package;

import haxe.Json;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import Song;
import Note;
import Section;
import StageData;
import FunkinLua;
import PhillyGlow;
import DialogueBoxPsych;
import shaders.WiggleEffect;

#if !flash
import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxRuntimeShader;
#end

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.ui.FlxBar;
import lime.utils.Assets;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxSort;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import flixel.util.FlxCollision;
import flixel.util.FlxStringUtil;
import openfl.filters.ShaderFilter;
import flixel.group.FlxSpriteGroup;
import openfl.events.KeyboardEvent;
import animateatlas.AtlasFrameMaker;
import flixel.input.keyboard.FlxKey;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.atlas.FlxAtlas;
import openfl.utils.Assets as OpenFlAssets;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState;

	public var luaArray:Array<FunkinLua> = [];
	public var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	public var variables:Map<String, Dynamic> = #if (haxe >= "4.0.0") new Map() #else new Map<String, Dynamic>() #end;

	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();

	public var spawnTime:Float = 2000;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
	
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}

		songSpeed = value;
		noteKillOffset = 350 / songSpeed;

		return value;
	}

	public static var STRUM_X:Float = 42;
	public static var STRUM_X_MIDDLESCROLL:Float = -278;

	public static var SONG:SwagSong;
	public static var curStage:String = '';
	public static var rep:Replay;
	public static var daPixelZoom:Float = 6;
	public static var isPixelStage:Bool = false;
	public static var isNextSubState:Bool = false;
	public static var gameMode:String = 'story';
	public static var storyWeek:String = 'tutorial';
	public static var storyWeekName:String = 'Tutorial';
	public static var storyPlaylist:Array<String> = [];
	public static var chartingMode:Bool = false;
	public static var difficulties:Array<Array<String>> =
	[
		['Easy',	'Normal',	'Hard'],
		['easy',	'normal',	'hard'],
		['-easy',	'',			'-hard']
	];
	public static var storyDifficulty:String = 'normal';
	public static var lastDifficulty:String = 'normal';
	public static var seenCutscene:Bool = false;
	public static var usedPractice:Bool = false;
	public static var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public static var debugKeysChart:Array<FlxKey>;
	public static var debugKeysCharacter:Array<FlxKey>;

	private var iconsZooming:Bool = false;

	public var boyfriendGroup:FlxSpriteGroup;
	public var boyfriend:Boyfriend;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	
	public var boyfriendMap:Map<String, Boyfriend> = #if (haxe >= "4.0.0") new Map() #else new Map<String, Boyfriend>() #end;
	public var boyfriendCameraOffset:Array<Float> = null;

	public var iconP1:HealthIcon;

	public function loadBF(name:String):Void
	{
		boyfriend = new Boyfriend(0, 0, name);
		startCharacterPos(boyfriend, boyfriendGroup);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.character);
	}

	public var dadGroup:FlxSpriteGroup;
	public var dad:Character;

	public var DAD_X:Float = 770;
	public var DAD_Y:Float = 100;
	
	public var dadMap:Map<String, Character> = #if (haxe >= "4.0.0") new Map() #else new Map<String, Character>() #end;
	public var opponentCameraOffset:Array<Float> = null;

	public var iconP2:HealthIcon;

	public function loadDad(name:String):Void
	{
		dad = new Character(0, 0, name);
		startCharacterPos(dad, dadGroup, true);
		dadGroup.add(dad);
		startCharacterLua(dad.character);
	}

	public var gfGroup:FlxSpriteGroup;
	public var gf:Character;

	public var noneGF:FlxSprite;
	public var gfDisabled:Bool = false;

	public var gfSpeed:Int = 1;

	public var GF_X:Float = 770;
	public var GF_Y:Float = 100;
	
	public var gfMap:Map<String, Character> = #if (haxe >= "4.0.0") new Map() #else new Map<String, Character>() #end;
	public var girlfriendCameraOffset:Array<Float> = null;

	public function loadGF(name:String):Void
	{
		if (!gfDisabled)
		{
			gf = new Character(0, 0, name);
			startCharacterPos(gf, gfGroup);
			gfGroup.add(gf);
			startCharacterLua(gf.character);
		}
		else
		{
			noneGF = new FlxSprite(0, 0);
			noneGF.makeGraphic(699, 655);
			noneGF.visible = false;
			gfGroup.add(noneGF);
		}

		if (gf.character == 'pico-speaker' && tankmanRun != null)
		{
			if (!OptionData.lowQuality)
			{
				var firstTank:TankmenBG = new TankmenBG(20, 500, true);
				firstTank.resetShit(20, 600, true);
				firstTank.strumTime = 10;
				tankmanRun.add(firstTank);

				for (i in 0...TankmenBG.animationNotes.length)
				{
					if (FlxG.random.bool(16))
					{
						var tankBih = tankmanRun.recycle(TankmenBG);
						tankBih.strumTime = TankmenBG.animationNotes[i][0];
						tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
						tankmanRun.add(tankBih);
					}
				}
			}
		}
	}

	public function startCharacterPos(char:Character, group:FlxSpriteGroup, ?gfCheck:Bool = false):Void
	{
		if (gfCheck && char.character.startsWith('gf')) // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
		{
			group.setPosition(GF_X, GF_Y);

			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;

			gf.visible = false;
		}

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
			{
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);

					startCharacterPos(newBoyfriend, boyfriendGroup);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.character);
				}
			}
			case 1:
			{
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);

					startCharacterPos(newDad, dadGroup, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.character);
				}
			}
			case 2:
			{
				if (!gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);

					startCharacterPos(newGf, gfGroup);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.character);
				}
			}
		}
	}

	public function addBehindGF(obj:FlxObject):Void
	{
		insert(members.indexOf(gfGroup), obj);
	}

	public function addBehindBF(obj:FlxObject):Void
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}

	public function addBehindDad(obj:FlxObject):Void
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function reloadHealthBarColors():Void
	{
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
		healthBar.updateBar();
	}

	public var defaultCamZoom:Float = 1.05;

	public var dadbattleBlack:BGSprite;
	public var dadbattleLight:BGSprite;
	public var dadbattleSmokes:FlxSpriteGroup;

	public var halloweenBG:BGSprite;
	public var halloweenWhite:BGSprite;

	public var curLight:Int = 0;
	public var curLightEvent:Int = 0;

	public var phillyLightsColors:Array<FlxColor> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
	public var phillyWindow:BGSprite;
	public var phillyStreet:BGSprite;
	public var phillyTrain:BGSprite;
	public var blammedLightsBlack:FlxSprite;
	public var phillyWindowEvent:BGSprite;
	public var trainSound:FlxSound;
	public var phillyGlowGradient:PhillyGlowGradient;
	public var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;

	public var limoKillingState:Int = 0;
	public var limo:BGSprite;
	public var limoMetalPole:BGSprite;
	public var limoLight:BGSprite;
	public var limoCorpse:BGSprite;
	public var limoCorpseTwo:BGSprite;
	public var bgLimo:BGSprite;
	public var grpLimoParticles:FlxTypedGroup<BGSprite>;
	public var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	public var fastCar:BGSprite;

	public var upperBoppers:BGSprite;
	public var bottomBoppers:BGSprite;
	public var santa:BGSprite;
	public var heyTimer:Float;

	public var bgGirls:BackgroundGirls;
	public var bgGhouls:BGSprite;

	public var tankWatchtower:BGSprite;
	public var tankGround:BGSprite;
	public var tankmanRun:FlxTypedGroup<TankmenBG>;
	public var foregroundSprites:FlxTypedGroup<BGSprite>;

	public function loadStage(stage:String):Void
	{
		var stageData:StageFile = StageData.getStageFile(stage);

		if (stageData == null) // Stage couldn't be found, create a dummy stage for preventing a crash
		{
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];

		gfDisabled = stageData.hide_girlfriend;

		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];

		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null) {
			cameraSpeed = stageData.camera_speed;
		}

		boyfriendCameraOffset = stageData.camera_boyfriend;

		if (boyfriendCameraOffset == null) { // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];
		}

		opponentCameraOffset = stageData.camera_opponent;

		if (opponentCameraOffset == null) {
			opponentCameraOffset = [0, 0];
		}

		girlfriendCameraOffset = stageData.camera_girlfriend;

		if (girlfriendCameraOffset == null) {
			girlfriendCameraOffset = [0, 0];
		}

		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);

		switch (stage)
		{
			case 'stage': // Week 1
			{
				var bg:BGSprite = new BGSprite('stage/stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stage/stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if (!OptionData.lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage/stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);

					var stageLight:BGSprite = new BGSprite('stage/stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stage/stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

				add(gfGroup);
				add(dadGroup);
				add(boyfriendGroup);

				dadbattleSmokes = new FlxSpriteGroup();
				add(dadbattleSmokes);
			}
			case 'spooky': // Week 2
			{
				if (!OptionData.lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}

				add(halloweenBG);

				add(gfGroup);
				add(dadGroup);
				add(boyfriendGroup);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;
				add(halloweenWhite);

				CoolUtil.precacheSound('thunder_1');
				CoolUtil.precacheSound('thunder_2');
			}
			case 'philly': // Week 3
			{
				var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
				add(bg);

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				phillyWindow.alpha = 0;
				add(phillyWindow);

				var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
				add(streetBehind);

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				CoolUtil.precacheSound('train_passes');

				trainSound = new FlxSound();
				trainSound.loadEmbedded(Paths.getSound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

				add(gfGroup);
				add(dadGroup);
				add(boyfriendGroup);
			}
			case 'limo':
			{
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if (!OptionData.lowQuality)
				{
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);

					resetLimoKill();

					CoolUtil.precacheSound('dancerdeath');
				}

				limoKillingState = 0;

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				add(fastCar);

				resetFastCar();

				add(gfGroup);

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
				add(limo);

				add(dadGroup);
				add(boyfriendGroup);
			}
			case 'mall':
			{
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if (!OptionData.lowQuality)
				{
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				if (!OptionData.lowQuality)
				{
					bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
					bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
					bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
					bottomBoppers.updateHitbox();
					add(bottomBoppers);	
				}

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);

				add(gfGroup);
				add(dadGroup);
				add(boyfriendGroup);

				CoolUtil.precacheSound('Lights_Shut_off');
			}
			case 'mallEvil':
			{
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

				add(gfGroup);
				add(dadGroup);
				add(boyfriendGroup);
			}
			case 'school':
			{
				GameOverSubState.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubState.loopSoundName = 'gameOver-pixel';
				GameOverSubState.endSoundName = 'gameOverEnd-pixel';
				GameOverSubState.characterName = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				bgSky.antialiasing = false;
				add(bgSky);

				var repositionShit = -200;
				var widShit = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgSky.updateHitbox();

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				bgSchool.antialiasing = false;
				bgSchool.setGraphicSize(widShit);
				bgSchool.updateHitbox();
				add(bgSchool);

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				bgStreet.antialiasing = false;
				bgStreet.setGraphicSize(widShit);
				bgStreet.updateHitbox();
				add(bgStreet);

				if (!OptionData.lowQuality)
				{
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					fgTrees.antialiasing = false;
					add(fgTrees);
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				bgTrees.antialiasing = false;
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
				bgTrees.updateHitbox();
				add(bgTrees);

				if (!OptionData.lowQuality)
				{
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					treeLeaves.antialiasing = false;
					add(treeLeaves);

					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);
					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

				bgSchool.setGraphicSize(widShit);

				add(gfGroup);
				add(dadGroup);
				add(boyfriendGroup);
			}
			case 'schoolEvil':
			{
				GameOverSubState.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubState.loopSoundName = 'gameOver-pixel';
				GameOverSubState.endSoundName = 'gameOverEnd-pixel';
				GameOverSubState.characterName = 'bf-pixel-dead';

				if (!OptionData.lowQuality)
				{
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', 400, 200, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				}
				else
				{
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', 400, 200, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

				add(gfGroup);
				add(dadGroup);
				add(boyfriendGroup);
			}
			case 'tank':
			{
				if (SONG.songID == 'stress') {
					GameOverSubState.characterName = 'bf-holding-gf-dead';
				}

				var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
				add(sky);

				if (!OptionData.lowQuality)
				{
					var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if (!OptionData.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);

					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);

				moveTank();

				add(gfGroup);
				add(dadGroup);
				add(boyfriendGroup);

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				add(foregroundSprites);

				foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
				if (!OptionData.lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
				if (!OptionData.lowQuality) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
				if (!OptionData.lowQuality) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
			}
			default:
			{
				add(gfGroup);
				add(dadGroup);
				add(boyfriendGroup);
			}
		}
	}

	public var songLength:Float = 0;

	#if desktop
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	public var inCutscene:Bool = false;

	public var vocals:FlxSound;

	public var generatedMusic:Bool = false;
	public var startingSong:Bool = false;
	public var updateTime:Bool = false;

	public var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	public var cameraSpeed:Float = 1;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	public var camFollowPos:FlxObject;
	public var camFollow:FlxPoint;

	private static var prevCamFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];
	private var saveNotes:Array<Float> = [];

	public var combo:Int = 0;

	public static var deathCounter:Int = 0;
	public var songAccuracy:Float = 0;
	public var totalNotesHit:Float = 0;
	public var totalPlayed:Int = 0;
	public var ratingString:String = 'N/A';
	public var comboRank:String = '';
	public var health:Float = 1;
	public var songMisses:Int = 0;
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public static var campaignScore:Int = 0;

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	public static var ratingStuff:Array<Dynamic> =
	[
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	public var isCameraOnForcedPos:Bool = false;

	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	public var keysArray:Array<Dynamic>;

	public var songPositionBar:Float = 0;

	override function create():Void
	{
		Paths.clearStoredMemory();

		super.create();

		instance = this; // for lua and stuff

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}

		keysArray = [
			OptionData.copyKey(OptionData.keyBinds.get('note_left')),
			OptionData.copyKey(OptionData.keyBinds.get('note_down')),
			OptionData.copyKey(OptionData.keyBinds.get('note_up')),
			OptionData.copyKey(OptionData.keyBinds.get('note_right'))
		];

		debugKeysChart = OptionData.copyKey(OptionData.keyBinds.get('debug_1'));
		debugKeysCharacter = OptionData.copyKey(OptionData.keyBinds.get('debug_2'));

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
		{
			SONG = Song.loadFromJson('tutorial', 'tutorial');
		}

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		GameOverSubState.resetVariables();

		switch (SONG.songID)
		{
			case 'senpai' | 'roses' | 'thorns':
				dialogue = CoolUtil.coolTextFile(Paths.getTxt(SONG.songID + '/' + SONG.songID + 'Dialogue'));
		}

		Conductor.songPosition = -5000;

		curStage = SONG.stage;

		if (SONG.stage == null || SONG.stage.length < 1)
		{
			switch (SONG.songID)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					curStage = 'tank';
				default:
					curStage = 'stage';
			}
		}
		
		SONG.stage = curStage;

		loadStage(curStage);

		generateSong(SONG);

		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');

			if (FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');

				if (FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}

			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');

			if (OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}

		for (event in eventPushedMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');

			if (FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');

				if (FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_events/' + event + '.lua');

			if (OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		#end

		noteTypeMap.clear();
		noteTypeMap = null;

		eventPushedMap.clear();
		eventPushedMap = null;

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);

		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));

		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) {
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		}

		for (mod in Paths.getGlobalMods()) {
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		}
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';

		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);

			if (FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		
		if (doPush)
		{
			luaArray.push(new FunkinLua(luaFile));
		}
		#end

		var gfVersion:String = SONG.gfVersion;
	
		if (gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				case 'tank':
					gfVersion = 'gf-tankmen';
				default:
					gfVersion = 'gf';
			}

			switch (SONG.songID)
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}

			SONG.gfVersion = gfVersion; // Fix for the Chart Editor
		}

		loadGF(gfVersion);
		loadDad(SONG.player2);
		loadBF(SONG.player1);

		if (!OptionData.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		loadHUD();

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.cameras = [camHUD];

		startingSong = true;
		updateTime = true;

		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + SONG.songID + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + SONG.songID + '/'));

		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) {
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + SONG.songID + '/'));
		}

		for (mod in Paths.getGlobalMods()) {
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + SONG.songID + '/' ));// using push instead of insert because these should run after everything else
		}
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		#if desktop
		storyDifficultyText = CoolUtil.getDifficultyName(lastDifficulty, difficulties) + (lastDifficulty != storyDifficulty ? ' (' + CoolUtil.getDifficultyName(storyDifficulty, difficulties) + ')' : '');
		iconRPC = dad.char_name;

		switch (gameMode) // String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		{
			case 'story':
				detailsText = 'Story Mode: ' + storyWeekName;
			case 'freeplay':
				detailsText = 'Freeplay';
			case 'replay':
				detailsText = 'Replay';
		}

		detailsPausedText = "Paused - " + detailsText; // String for when the game is paused

		DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconRPC); // Updating Discord Rich Presence.
		#end

		if (gameMode == 'replay')
		{
			PlayStateChangeables.botPlay = true;

			botplayTxt.visible = PlayStateChangeables.botPlay;

			PlayStateChangeables.scrollSpeed = rep.replay.noteSpeed;
			OptionData.downScroll = rep.replay.isDownscroll;

			songSpeedType = PlayStateChangeables.scrollType;

			switch (songSpeedType)
			{
				case "multiplicative":
					songSpeed = SONG.speed * PlayStateChangeables.scrollSpeed;
				case "constant":
					songSpeed = PlayStateChangeables.scrollSpeed;
			}
		}

		switch (gameMode)
		{
			case 'story':
			{
				if (!seenCutscene)
				{
					switch (SONG.songID)
					{
						case 'winter-horrorland':
						{
							camHUD.visible = false;
							inCutscene = true;

							snapCamFollowToPos(400, -2050);

							var blackScreen:FlxSprite = new FlxSprite();
							blackScreen.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
							blackScreen.scrollFactor.set();
							add(blackScreen);

							FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
								ease: FlxEase.linear,
								onComplete: function(twn:FlxTween) {
									remove(blackScreen);
								}
							});

							FlxG.sound.play(Paths.getSound('Lights_Turn_On'));

							FlxG.camera.focusOn(camFollow);
							FlxG.camera.zoom = 1.5;
		
							new FlxTimer().start(0.8, function(tmr:FlxTimer)
							{
								camHUD.visible = true;

								FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween)
									{
										startCountdown();
									}
								});
							});
						}
						case 'senpai':
						{
							schoolIntro(doof);
						}
						case 'roses':
						{
							FlxG.sound.play(Paths.getSound('ANGRY'));

							schoolIntro(doof);
						}
						case 'thorns':
						{
							schoolIntro(doof);
						}
						case 'ugh' | 'guns' | 'stress':
						{
							tankIntro();
						}
						default:
						{
							startCountdown();
						}
					}

					seenCutscene = true;
				}
				else
				{
					startCountdown();
				}
			}
			default:
			{
				startCountdown();
			}
		}

		if (gameMode != 'replay')
		{
			rep = new Replay("na");
		}

		Conductor.safeZoneOffset = (OptionData.safeFrames / 60) * 1000;

		callOnLuas('onCreatePost', []);

		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		if (OptionData.pauseMusic != 'None') {
			CoolUtil.precacheMusic(Paths.formatToSongPath(OptionData.pauseMusic));
		}

		CustomFadeTransition.nextCamera = camOther;
	}

	public function startVideo(name:String, type:String = 'mp4'):Void
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.getVideo(name);

		#if sys
		if (!FileSystem.exists(filepath))
		#else
		if (!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();

			return;
		}

		var video:VideoHandler = new VideoHandler();
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();

		return;
		#end
	}

	public function startAndEnd():Void
	{
		if (endingSong)
			endSong();
		else
			startCountdown();
	}

	public var strumLine:FlxSprite;

	public var cpuStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;

	public var scoreTxt:FlxText;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var songPosBG:AttachedSprite;
	public var songPosBar:FlxBar;
	public var songPosName:FlxText;

	public var grpRatings:FlxTypedGroup<FlxSprite>;
	public var grpNumbers:FlxTypedGroup<FlxSprite>;

	var ratingTweensArray:Array<FlxTween> = [];
	var numbersTweensArray:Array<FlxTween> = [];

	public function loadHUD():Void
	{
		camFollow = new FlxPoint(0, 0);
		camFollowPos = new FlxObject(0, 0, 1, 1);

		if (prevCamFollowPos != null && prevCamFollow != null)
		{
			camFollowPos = prevCamFollowPos;
			camFollow = prevCamFollow;

			prevCamFollowPos = null;
			prevCamFollow = null;
		}
		else
		{
			if (gf != null)
			{
				snapCamFollowToPos(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
			}
			else
			{
				snapCamFollowToPos(noneGF.getGraphicMidpoint().x, noneGF.getGraphicMidpoint().y);
			}
		}

		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;

		strumLine = new FlxSprite(OptionData.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, OptionData.downScroll ? FlxG.height - 150 : 50);
		strumLine.makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();
		strumLine.alpha = 0;
		strumLine.visible = false;
		add(strumLine);

		grpRatings = new FlxTypedGroup<FlxSprite>();
		grpRatings.cameras = OptionData.ratingOnCamera ? [camHUD] : null;
		add(grpRatings);

		grpNumbers = new FlxTypedGroup<FlxSprite>();
		grpNumbers.cameras = OptionData.numbersOnCamera ? [camHUD] : null;
		add(grpNumbers);

		cpuStrums = new FlxTypedGroup<StrumNote>();
		cpuStrums.cameras = [camHUD];
		add(cpuStrums);

		playerStrums = new FlxTypedGroup<StrumNote>();
		playerStrums.cameras = [camHUD];
		add(playerStrums);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteSplashes.cameras = [camHUD];
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		splash.alpha = 0.0;
		grpNoteSplashes.add(splash);

		healthBarBG = new AttachedSprite('ui/healthBar');
		healthBarBG.y = OptionData.downScroll ? 0.11 * FlxG.height : FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		healthBarBG.cameras = [camHUD];
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		reloadHealthBarColors();
		healthBarBG.sprTracker = healthBar;
		healthBar.alpha = OptionData.healthBarAlpha;
		healthBar.cameras = [camHUD];
		add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.alpha = OptionData.healthBarAlpha;
		iconP1.cameras = [camHUD];
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.alpha = OptionData.healthBarAlpha;
		iconP2.cameras = [camHUD];
		add(iconP2);

		notes = new FlxTypedGroup<Note>();
		notes.cameras = [camHUD];
		add(notes);

		scoreTxt = new FlxText(0, healthBarBG.y + 50, FlxG.width, "", 16);
		scoreTxt.setFormat(Paths.getFont("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.cameras = [camHUD];
		scoreTxt.text = calculateScoreText(deathCounter, songAccuracy, ratingString, comboRank, Math.round(health * 50), songMisses, songScore);
		scoreTxt.visible = OptionData.scoreText;
		add(scoreTxt);

		songPosBG = new AttachedSprite('ui/healthBar');
		songPosBG.y = 10;
		songPosBG.screenCenter(X);
		songPosBG.scrollFactor.set();
		songPosBG.xAdd = -4;
		songPosBG.yAdd = -4;
		if (OptionData.downScroll) songPosBG.y = FlxG.height - 30;
		songPosBG.visible = (OptionData.songPositionType != 'Disabled');
		songPosBG.cameras = [camHUD];
		songPosBG.alpha = 0;
		add(songPosBG);

		songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), this,
			'songPositionBar', 0, 1);
		songPosBar.scrollFactor.set();
		songPosBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		songPosBar.cameras = [camHUD];
		songPosBar.visible = (OptionData.songPositionType != 'Disabled');
		songPosBar.alpha = 0;
		add(songPosBar);

		songPosBG.sprTracker = songPosBar;

		songPosName = new FlxText(0, songPosBG.y, FlxG.width, "", 20);
		songPosName.setFormat(Paths.getFont("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songPosName.scrollFactor.set();
		songPosName.borderSize = 1.25;
		songPosName.cameras = [camHUD];
		songPosName.visible = (OptionData.songPositionType != 'Disabled');
		songPosName.text = SONG.songName + " - " + CoolUtil.getDifficultyName(lastDifficulty, difficulties);
		songPosName.alpha = 0;
		add(songPosName);

		botplayTxt = new FlxText(400, OptionData.downScroll ? songPosBG.y - 85 : songPosBG.y + 75, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.getFont("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = PlayStateChangeables.botPlay;
		botplayTxt.alpha = 0;
		botplayTxt.cameras = [camHUD];
		add(botplayTxt);

		callOnLuas('onLoadHUD', []);
	}

	public function snapCamFollowToPos(x:Float, y:Float):Void
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	var dialogueCount:Int = 0;

	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void // You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	{
		if (dialogueFile.dialogue.length > 0) // TO DO: Make this more flexible, maybe?
		{
			inCutscene = true;

			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');

			var doof:DialogueBoxPsych = new DialogueBoxPsych(dialogueFile, song);
			doof.scrollFactor.set();

			if (endingSong) {
				doof.finishThing = endSong;
			} else {
				doof.finishThing = startCountdown;
			}

			doof.nextDialogueThing = startNextDialogue;
			doof.skipDialogueThing = skipDialogue;
			doof.cameras = [camHUD];
			add(doof);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');

			if (endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	public function startNextDialogue():Void
	{
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue():Void
	{
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	public function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += senpaiEvil.width / 5;

		if (SONG.songID == 'roses' || SONG.songID == 'thorns')
		{
			remove(black);

			if (SONG.songID == 'thorns')
			{
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (SONG.songID == 'thorns')
					{
						senpaiEvil.alpha = 0;
						add(senpaiEvil);

						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;

							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');

								FlxG.sound.play(Paths.getSound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);

									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
									}, true);
								});

								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
				{
					startCountdown();
				}

				remove(black);
			}
		});
	}

	public function tankIntro():Void
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = SONG.songID;
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = OptionData.globalAntialiasing;
		addBehindDad(tankman);

		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = OptionData.globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);

		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = OptionData.globalAntialiasing;
		cutsceneHandler.push(gfDance);

		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = OptionData.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);

		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = OptionData.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);

		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = OptionData.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);

			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			cameraMovement(true);

			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;

			boyfriend.animation.finishCallback = null;

			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);

		switch(songName)
		{
			case 'ugh':
			{
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';

				CoolUtil.precacheSound('wellWellWell');
				CoolUtil.precacheSound('killYou');
				CoolUtil.precacheSound('bfBeep');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.getSound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				cutsceneHandler.timer(0.1, function()
				{
					wellWellWell.play(true);
				});

				cutsceneHandler.timer(3, function()
				{
					camFollow.x += 750;
					camFollow.y += 100;
				});

				cutsceneHandler.timer(4.5, function()
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.getSound('bfBeep'));
				});

				cutsceneHandler.timer(6, function()
				{
					camFollow.x -= 750;
					camFollow.y -= 100;

					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.getSound('killYou'));
				});
			}
			case 'guns':
			{
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
	
				tankman.x += 40;
				tankman.y += 10;
		
				CoolUtil.precacheSound('tankSong2');

				var tightBars:FlxSound = new FlxSound();
				tightBars.loadEmbedded(Paths.getSound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function()
				{
					tightBars.play(true);

					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				};

				cutsceneHandler.timer(4, function()
				{
					gf.playAnim('sad', true);

					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});
			}
			case 'stress':
			{
				cutsceneHandler.endTime = 35.5;

				tankman.x -= 54;
				tankman.y -= 14;

				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;

				camFollow.set(dad.x + 400, dad.y + 170);

				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
	
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.y += 100;
				});
	
				CoolUtil.precacheSound('stressCutscene');

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (!OptionData.lowQuality)
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);

				if (!OptionData.lowQuality)
				{
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				picoCutscene.alpha = 0.00001;
				addBehindGF(picoCutscene);

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound();
				cutsceneSnd.loadEmbedded(Paths.getSound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;

				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;

					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);

					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;

					if (calledTimes > 1)
					{
						foregroundSprites.forEach(function(spr:BGSprite)
						{
							spr.y -= 100;
						});
					}
				}

				cutsceneHandler.onStart = function()
				{
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function()
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String)
					{
						if (name == 'dieBitch') //Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if (name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};

							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, function()
				{
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function()
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function()
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function()
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;

					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, function()
				{
					zoomBack();
				});
			}
		}
	}

	public var skipCountdown:Bool = false;

	public var startTimer:FlxTimer = new FlxTimer();
	public var startedCountdown:Bool = false;

	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;

		canPause = true;
		canReset = true;

		var ret:Dynamic = callOnLuas('onStartCountdown', []);

		if (ret != FunkinLua.Function_Stop)
		{
			generateStaticArrows(0);
			generateStaticArrows(1);

			for (i in 0...playerStrums.length)
			{
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}

			for (i in 0...cpuStrums.length)
			{
				setOnLuas('defaultOpponentStrumX' + i, cpuStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, cpuStrums.members[i].y);
			}

			startedCountdown = true;

			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;

			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0)
			{
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);

				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);

				return;
			}

			startTimer.start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}

				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}

				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}

				var antialias:Bool = isPixelStage ? false : OptionData.globalAntialiasing;
				var altSuffix:String = isPixelStage ? '-pixel' : '';

				switch (swagCounter)
				{
					case 0:
					{
						FlxG.sound.play(Paths.getSound('intro3' + altSuffix), 0.6);
					}
					case 1:
					{
						var ready:FlxSprite = new FlxSprite();
						ready.loadGraphic(Paths.getImage('countdown/ready' + altSuffix));
						ready.setGraphicSize(Std.int(ready.width * 0.75));
						ready.scrollFactor.set();

						if (isPixelStage) {
							ready.setGraphicSize(Std.int(ready.width * daPixelZoom));
						}

						ready.updateHitbox();
						ready.screenCenter();
						ready.antialiasing = antialias;
						ready.cameras = [camHUD];
						add(ready);

						FlxTween.tween(ready, {alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(ready);
								ready.destroy();
							}
						});

						FlxG.sound.play(Paths.getSound('intro2' + altSuffix), 0.6);
					}
					case 2:
					{
						var set:FlxSprite = new FlxSprite();
						set.loadGraphic(Paths.getImage('countdown/set' + altSuffix));
						set.setGraphicSize(Std.int(set.width * 0.75));
						set.scrollFactor.set();

						if (isPixelStage) {
							set.setGraphicSize(Std.int(set.width * daPixelZoom));
						}

						set.updateHitbox();
						set.screenCenter();
						set.antialiasing = antialias;
						set.cameras = [camHUD];
						add(set);

						FlxTween.tween(set, {alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(set);
								set.destroy();
							}
						});

						FlxG.sound.play(Paths.getSound('intro1' + altSuffix), 0.6);
					}
					case 3:
					{
						var go:FlxSprite = new FlxSprite();
						go.loadGraphic(Paths.getImage('countdown/go' + altSuffix));
						go.setGraphicSize(Std.int(go.width * 0.75));
						go.scrollFactor.set();

						if (isPixelStage) {
							go.setGraphicSize(Std.int(go.width * daPixelZoom));
						}

						go.updateHitbox();
						go.screenCenter();
						go.antialiasing = antialias;
						go.cameras = [camHUD];
						add(go);

						FlxTween.tween(go, {alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(go);
								go.destroy();
							}
						});

						FlxG.sound.play(Paths.getSound('introGo' + altSuffix), 0.6);
					}
					case 4:
					{
						// da nothing here dumbass lol
					}
				}

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

				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
			}, 5);
		}
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	public function startSong():Void
	{
		startingSong = false;
		iconsZooming = true;

		previousFrameTime = FlxG.game.ticks;

		if (startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}

		startOnTime = 0;

		FlxG.sound.playMusic(Paths.getInst(SONG.songID), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();

		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		FlxTween.tween(songPosBG, {alpha: 1}, 0.4);
		FlxTween.tween(songPosBar, {alpha: 1}, 0.4);
		FlxTween.tween(songPosName, {alpha: 1}, 0.4);

		songLength = FlxG.sound.music.length; // Song duration in a float, useful for the time left feature

		#if desktop		
		DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconRPC, true, songLength); // Updating Discord Rich Presence (with Time Left)
		#end

		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;

		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];

			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}

			--i;
		}

		i = notes.length - 1;

		while (i >= 0)
		{
			var daNote:Note = notes.members[i];

			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}

			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if (time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
		}

		vocals.play();

		Conductor.songPosition = time;
		songTime = time;
	}

	private function generateSong(songData:SwagSong):Void
	{
		Conductor.changeBPM(songData.bpm);

		songSpeedType = PlayStateChangeables.scrollType;

		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = songData.speed * PlayStateChangeables.scrollSpeed;
			case "constant":
				songSpeed = PlayStateChangeables.scrollSpeed;
		}

		if (songData.needsVoices) {
			vocals = new FlxSound().loadEmbedded(Paths.getVoices(songData.songID));
		} else {
			vocals = new FlxSound();
		}

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.getInst(songData.songID)));

		var noteData:Array<SwagSection> = songData.notes;

		var file:String = Paths.getJson(songData.songID + '/events');

		#if sys
		if (FileSystem.exists(Paths.modsJson(songData.songID + '/events')) || FileSystem.exists(file))
		#else
		if (OpenFlAssets.exists(file))
		#end
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songData.songID).events;

			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];

					var subEvent:EventNote = {
						strumTime: newEventNote[0] + OptionData.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};

					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);

					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
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
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
				swagNote.noteType = (!Std.isOfType(songNotes[3], String) ? editors.ChartingState.noteTypeList[songNotes[3]] : songNotes[3]);
				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if (OptionData.middleScroll)
						{
							sustainNote.x += 310;
		
							if (daNoteData > 1) // Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (OptionData.middleScroll)
				{
					swagNote.x += 310;

					if (daNoteData > 1) // Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if (!noteTypeMap.exists(swagNote.noteType))
				{
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
		}

		for (event in songData.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];

				var subEvent:EventNote = {
					strumTime: newEventNote[0] + OptionData.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};

				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);

				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		unspawnNotes.sort(sortByShit);

		if (eventNotes.length > 1) { // No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}

		checkEventNote();

		generatedMusic = true;
	}

	public function eventPushed(event:EventNote):Void
	{
		switch (event.event)
		{
			case 'Change Character':
			{
				var charType:Int = 0;

				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
					{
						charType = 2;
					}
					case 'dad' | 'opponent' | '0':
					{
						charType = 1;
					}
					default:
					{
						charType = Std.parseInt(event.value1);
						if (Math.isNaN(charType)) charType = 0;
					}
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
			}
			case 'Dadbattle Spotlight':
			{
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('stage/spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;
				add(dadbattleLight);

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleSmokes);

				var smoke:BGSprite = new BGSprite('stage/smoke', -1350, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);

				var smoke:BGSprite = new BGSprite('stage/smoke', 1750, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);
			}
			case 'Philly Glow':
			{
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5);
				blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

				phillyGlowGradient = new PhillyGlowGradient(-400, 225); // This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				phillyGlowGradient.intendedAlpha = OptionData.flashingLights ? 1 : 0.7;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);

				CoolUtil.precacheImage('philly/particle');

				phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
			}
		}

		if (!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	public function eventNoteEarlyTrigger(event:EventNote):Float
	{
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);

		if (returnedValue != 0) {
			return returnedValue;
		}

		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}

		return 0;
	}

	public function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private var staticArrowsTweens:Array<FlxTween> = [];

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var targetAlpha:Float = 1;

			if (player == 0)
			{
				if (OptionData.cpuStrumsType == 'Disabled') {
					targetAlpha = 0;
				} else if (OptionData.middleScroll) {
					targetAlpha = 0.35;
				}
			}

			var babyArrow:StrumNote = new StrumNote(OptionData.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);

			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			babyArrow.downScroll = OptionData.downScroll;

			var tween = FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			staticArrowsTweens.push(tween);

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
				{
					playerStrums.add(babyArrow);
				}
			}

			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState):Void
	{
		super.openSubState(SubState);

		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
			{
				startTimer.active = false;
			}

			if (finishTimer != null && !finishTimer.finished)
			{
				finishTimer.active = false;
			}

			for (tween in staticArrowsTweens)
			{
				tween.active = false;
			}
			
			var chars:Array<Character> = [boyfriend, gf, dad];

			for (char in chars)
			{
				if (char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}

			if (songSpeedTween != null) {
				songSpeedTween.active = false;
			}

			for (timer in modchartTimers) {
				timer.active = false;
			}

			for (tween in ratingTweensArray) {
				tween.active = false;
			}

			for (tween in numbersTweensArray) {
				tween.active = false;
			}
		}
	}

	override function closeSubState():Void
	{
		super.closeSubState();

		if (isNextSubState)
		{
			isNextSubState = false;
		}
		else if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
			{
				startTimer.active = true;
			}

			if (songSpeedTween != null) {
				songSpeedTween.active = true;
			}

			if (finishTimer != null && !finishTimer.finished)
			{
				finishTimer.active = true;
			}

			var chars:Array<Character> = [boyfriend, gf, dad];

			for (char in chars)
			{
				if (char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}

			for (tween in staticArrowsTweens) {
				tween.active = true;
			}

			for (timer in modchartTimers) {
				timer.active = true;
			}

			for (timer in modchartTimers) {
				timer.active = true;
			}

			for (tween in ratingTweensArray) {
				tween.active = true;
			}

			for (tween in numbersTweensArray) {
				if (tween.active) tween.active = true;
			}

			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconRPC, true, songLength - Conductor.songPosition - OptionData.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconRPC);
			}
			#end
		}
	}

	override function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconRPC, true, songLength - Conductor.songPosition - OptionData.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconRPC);
			}
		}
		#end

		super.onFocus();
	}
	
	override function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.songName + " - " + storyDifficultyText, iconRPC);
		}
		#end

		super.onFocusLost();
	}

	public function resyncVocals():Void
	{
		if (finishTimer != null) return;
		
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;

		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private function calculateScoreText(deaths:Int, accuracy:Float, rating:String, comboRank:String, health:Float, misses:Int, score:Int):String
	{
		return 'DEATHS: ' + deaths + ' | ACCURACY: ' + CoolUtil.truncateFloat(accuracy * 100, 2) + '% | RATING: ' + rating +
			(rating != 'N/A' ? ' (' + comboRank + ')' : '') + ' | HEALTH: ' + health + '% | COMBO BREAKS: ' + misses + ' | SCORE: ' + score;
	}

	public function recalculateRating():Void
	{
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);

		if (ret != FunkinLua.Function_Stop)
		{
			if (totalPlayed < 1)
			{
				ratingString = 'N/A';
			}
			else
			{
				songAccuracy = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

				if (songAccuracy >= 1)
				{
					ratingString = ratingStuff[ratingStuff.length - 1][0];
				}
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (songAccuracy < ratingStuff[i][1])
						{
							ratingString = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			comboRank = "";

			if (sicks > 0)
				comboRank = 'SFC';
			if (goods > 0)
				comboRank = 'GFC';
			if (bads > 0 || shits > 0)
				comboRank = 'FC';
			if (songMisses > 0 && songMisses < 10)
				comboRank = 'SDCB';
			else if (songMisses >= 10)
				comboRank = 'Clear';
		}

		setOnLuas('accuracy', songAccuracy);
		setOnLuas('ratingName', ratingString);
		setOnLuas('ratingFC', comboRank);
	}

	public var paused:Bool = false;

	public var canPause:Bool = false;
	public var canReset:Bool = false;

	var limoSpeed:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		callOnLuas('onUpdate', [elapsed]);

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		switch (curStage)
		{
			case 'philly':
			{
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}

				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				if (phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length-1;

					while (i > 0)
					{
						var particle:PhillyGlowParticle = phillyGlowParticles.members[i];

						if (particle.alpha < 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}

						--i;
					}
				}
			}
			case 'limo':
			{
				if (!OptionData.lowQuality)
				{
					grpLimoParticles.forEach(function(spr:BGSprite)
					{
						if (spr.animation.curAnim.finished)
						{
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch (limoKillingState)
					{
						case 1:
						{
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;

							for (i in 0...dancers.length)
							{
								if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130)
								{
									switch (i)
									{
										case 0 | 3:
										{
											if (i == 0) FlxG.sound.play(Paths.getSound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';

											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										}
										case 1:
										{
											limoCorpse.visible = true;
										}
										case 2:
										{
											limoCorpseTwo.visible = true;
										}
									}

									dancers[i].x += FlxG.width * 2;
								}
							}

							if (limoMetalPole.x > FlxG.width * 2)
							{
								resetLimoKill();

								limoSpeed = 800;
								limoKillingState = 2;
							}
						}
						case 2:
						{
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;

							if (bgLimo.x > FlxG.width * 1.5)
							{
								limoSpeed = 3000;
								limoKillingState = 3;
							}
						}
						case 3:
						{
							limoSpeed -= 2000 * elapsed;
							if (limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;

							if (bgLimo.x < -275)
							{
								limoKillingState = 4;
								limoSpeed = 800;
							}
						}
						case 4:
						{
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));

							if (Math.round(bgLimo.x) == -150)
							{
								bgLimo.x = -150;
								limoKillingState = 0;
							}
						}
					}

					if (limoKillingState > 2)
					{
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;

						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			}
			case 'mall':
			{
				if (heyTimer > 0)
				{
					heyTimer -= elapsed;

					if (heyTimer <= 0)
					{
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
			}
			case 'schoolEvil':
			{
				if (!OptionData.lowQuality && bgGhouls != null && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			}
			case 'tank':
			{
				moveTank(elapsed);
			}
		}

		if (botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause && !OptionData.controllerMode)
		{
			var ret:Dynamic = callOnLuas('onPause', [], false);

			if (ret != FunkinLua.Function_Stop) {
				openPauseMenu();
			}
		}

		if (controls.RESET && !OptionData.noReset && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
		}

		doDeathCheck();

		if (health < 0 && PlayStateChangeables.practiceMode) {
			health = 0;
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene && gameMode != 'replay')
		{
			openChartEditor();
		}

		#if MODS_ALLOWED
		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene)
		{
			openCharacterEditor();
		}
		#end

		scoreTxt.text = calculateScoreText(deathCounter, songAccuracy, ratingString, comboRank, Math.round(health * 50), songMisses, songScore);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health > 2) {
			health = 2;
		}

		if (healthBar.percent < 20)
		{
			iconP1.animation.curAnim.curFrame = 1;
	
			if (iconP2.animation.curAnim.numFrames == 3) {
				iconP2.animation.curAnim.curFrame = 2;
			}
		}
		else if (healthBar.percent > 80)
		{
			iconP2.animation.curAnim.curFrame = 1;
	
			if (iconP1.animation.curAnim.numFrames == 3) {
				iconP1.animation.curAnim.curFrame = 2;
			}
		}
		else
		{
			iconP1.animation.curAnim.curFrame = 0;
			iconP2.animation.curAnim.curFrame = 0;
		}


		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;

				if (Conductor.songPosition >= 0)
				{
					startSong();
				}
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}

				if (updateTime)
				{
					var curTime:Float = Conductor.songPosition - OptionData.noteOffset;
					if (curTime < 0) curTime = 0;

					songPositionBar = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if (OptionData.songPositionType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if (secondsTotal < 0) secondsTotal = 0;
	
					songPosName.text = SONG.songName + " - " + CoolUtil.getDifficultyName(lastDifficulty, difficulties);

					if (OptionData.songPositionType != 'Song Name') songPosName.text += ' (' + FlxStringUtil.formatTime(secondsTotal, false) + ')';
				}
			}
		}

		if (SONG.notes[curSection] != null && !startingSong && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection();
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;

			if (songSpeed < 1) time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;

			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = daNote.mustPress ? playerStrums : cpuStrums;

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;
	
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
	
				var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
				var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;

				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll)
				{
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
				}
				else
				{
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
				}

				var angleDir = strumDirection * Math.PI / 180;
	
				if (daNote.copyAngle) {
					daNote.angle = strumDirection - 90 + strumAngle;
				}

				if (daNote.copyAlpha) {
					daNote.alpha = strumAlpha;
				}

				if (daNote.copyX) {
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
				}

				if (daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					if (strumScroll && daNote.isSustainNote) // Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					{
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
			
							if (PlayState.isPixelStage) {
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							} else {
								daNote.y -= 19;
							}
						}
		
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				noteMovement(daNote, strumGroup, strumY + Note.swagWidth / 2, strumScroll);

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) {
					opponentNoteHit(daNote);
				}

				if (!daNote.blockHit && daNote.mustPress && PlayStateChangeables.botPlay && daNote.canBeHit)
				{
					if (daNote.isSustainNote)
					{
						if (daNote.canBeHit && !daNote.ignoreNote) {
							goodNoteHit(daNote);
						}
					}
					else if ((daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) && !daNote.ignoreNote)
					{
						goodNoteHit(daNote);
					}
				}

				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					if (daNote.mustPress && !PlayStateChangeables.botPlay && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
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

		checkEventNote();

		if (!inCutscene && !startingSong && !endingSong)
		{
			if (!PlayStateChangeables.botPlay) {
				keyShit();
			} else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
		}

		#if debug
		if (!startingSong && !endingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}

			if (FlxG.keys.justPressed.TWO) //Go 10 seconds into the future :O
			{
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);

		setOnLuas('PlayStateChangeables.botPlay', PlayStateChangeables.botPlay);

		callOnLuas('onUpdatePost', [elapsed]);
	}

	private function noteMovement(daNote:Note, strumGroup:FlxTypedGroup<StrumNote>, center:Float, strumScroll:Bool):Void
	{
		if (strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
			(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
		{
			if (strumScroll)
			{
				if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
				{
					var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
					swagRect.height = (center - daNote.y) / daNote.scale.y;
					swagRect.y = daNote.frameHeight - swagRect.height;

					daNote.clipRect = swagRect;
				}
			}
			else
			{
				if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
				{
					var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
					swagRect.y = (center - daNote.y) / daNote.scale.y;
					swagRect.height -= swagRect.y;

					daNote.clipRect = swagRect;
				}
			}
		}
	}

	public function openPauseMenu():Void
	{
		persistentUpdate = false;
		persistentDraw = true;

		paused = true;

		openSubState(new PauseSubState(false));
	
		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.songName + " - " + storyDifficultyText, iconRPC);
		#end
	}

	public var isDead:Bool = false;

	public function doDeathCheck(?skipHealthCheck:Bool = false):Bool
	{
		if (((skipHealthCheck && PlayStateChangeables.instaKill) || health <= 0) && !PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay)
		{
			var ret:Dynamic = callOnLuas('onGameOver', [], false);

			if (ret != FunkinLua.Function_Stop)
			{
				isDead = true;

				deathCounter++;

				boyfriend.stunned = true;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				for (tween in modchartTweens) {
					tween.active = true;
				}

				for (timer in modchartTimers) {
					timer.active = true;
				}

				FlxG.sound.music.stop();
				vocals.stop();

				openSubState(new GameOverSubState(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1]));
				
				#if desktop
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.songName + " - " + storyDifficultyText, iconRPC);
				#end

				return true;
			}
		}

		return false;
	}

	public function openChartEditor():Void
	{
		chartingMode = true;

		persistentUpdate = false;
		paused = true;

		cancelMusicFadeTween();

		MusicBeatState.switchState(new editors.ChartingState());

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public function openCharacterEditor():Void
	{
		persistentUpdate = false;
		paused = true;

		cancelMusicFadeTween();

		CustomFadeTransition.nextCamera = camOther;
		MusicBeatState.switchState(new editors.CharacterEditorState(SONG.player2, true));
	}

	public function checkEventNote():Void
	{
		while (eventNotes.length > 0) 
		{
			var leStrumTime:Float = eventNotes[0].strumTime;

			if (Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';

			if (eventNotes[0].value1 != null) {
				value1 = eventNotes[0].value1;
			}

			var value2:String = '';

			if (eventNotes[0].value2 != null) {
				value2 = eventNotes[0].value2;
			}

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String):Bool
	{
		return Reflect.getProperty(controls, key);
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String):Void
	{
		switch (eventName)
		{
			case 'Dadbattle Spotlight':
			{
				var val:Null<Int> = Std.parseInt(value1);
				if (val == null) val = 0;

				switch (Std.parseInt(value1))
				{
					case 1, 2, 3:
					{
						if (val == 1)
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;

							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if (val > 2) who = boyfriend;

						dadbattleLight.alpha = 0;

						new FlxTimer().start(0.12, function(tmr:FlxTimer)
						{
							dadbattleLight.alpha = 0.375;
						});

						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);
					}
					default:
					{
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;

						defaultCamZoom -= 0.12;

						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {
							onComplete: function(twn:FlxTween)
							{
								dadbattleSmokes.visible = false;
							}
						});
					}
				}
			}
			case 'Hey!':
			{
				var value:Int = 2;

				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
					case 'bfgf' | 'bfandgf' | 'bfxgf' | 'bf and gf' | 'bf x gf' | 'bf-and-gf' | 'bf-x-gf' | '2':
						value = 2;
				}

				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0) time = 0.6;

				switch (value)
				{
					case 0:
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = time;
					}
					case 1:
					{
						if (dad.character.startsWith('gf'))
						{
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = time;
						}
						else if (gf != null)
						{
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = time;
						}
	
						if (curStage == 'mall')
						{
							bottomBoppers.animation.play('hey', true);
							heyTimer = time;
						}
					}
					case 2:
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = time;

						if (dad.character.startsWith('gf'))
						{
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = time;
						}
						else if (gf != null)
						{
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = time;
						}
	
						if (curStage == 'mall')
						{
							bottomBoppers.animation.play('hey', true);
							heyTimer = time;
						}
					}
				}
			}
			case 'Set GF Speed':
			{
				var value:Int = Std.parseInt(value1);

				if (Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;
			}
			case 'Philly Glow':
			{
				var lightId:Int = Std.parseInt(value1);
				if (Math.isNaN(lightId)) lightId = 0;

				var doFlash:Void->Void = function() 
				{
					var color:FlxColor = FlxColor.WHITE;
					if (!OptionData.flashingLights) color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15, null, true);
				};

				var chars:Array<Character> = [boyfriend, gf, dad];

				switch (lightId)
				{
					case 0:
					{
						if (phillyGlowGradient.visible)
						{
							doFlash();

							if (OptionData.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;

							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
	
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}

							phillyStreet.color = FlxColor.WHITE;
						}
					}
					case 1: // turn on
					{
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if (!phillyGlowGradient.visible)
						{
							doFlash();

							if (OptionData.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if (OptionData.flashingLights)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;

							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;

						if (!OptionData.flashingLights)
							charColor.saturation *= 0.5;
						else
							charColor.saturation *= 0.75;

						for (who in chars)
						{
							who.color = charColor;
						}

						phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle)
						{
							particle.color = color;
						});

						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;
					}
					case 2: // spawn particles
					{
						if (!OptionData.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];

							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlowParticle = new PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}

						phillyGlowGradient.bop();
					}
				}
			}
			case 'Kill Henchmen':
			{
				killHenchmen();
			}
			case 'Add Camera Zoom':
			{
				if (OptionData.camZooms && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);

					if (Math.isNaN(camZoom)) camZoom = 0.015;
					if (Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}
			}
			case 'Trigger BG Ghouls':
			{
				if (curStage == 'schoolEvil' && !OptionData.lowQuality)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}
			}
			case 'Play Animation':
			{
				var char:Character = dad;

				switch (value2.toLowerCase().trim()) 
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
					{
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2)) val2 = 0;

						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
					}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}
			}
			case 'Camera Follow Pos':
			{
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);

				if (Math.isNaN(val1)) val1 = 0;
				if (Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;

				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}
			}
			case 'Alt Idle Animation':
			{
				var char:Character = dad;

				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend':
					{
						char = gf;
					}
					case 'boyfriend' | 'bf':
					{
						char = boyfriend;
					}
					default:
					{
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val)) val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
					}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}
			}
			case 'Screen Shake':
			{
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];

				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;

					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration)) duration = 0;
					if (Math.isNaN(intensity)) intensity = 0;

					if (duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}
			}
			case 'Change Character':
			{
				var charType:Int = 0;

				switch (value1)
				{
					case 'gf' | 'girlfriend':
					{
						charType = 2;
					}
					case 'dad' | 'opponent':
					{
						charType = 1;
					}
					default:
					{
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
					}
				}

				switch (charType)
				{
					case 0:
					{
						if (boyfriend.character != value2)
						{
							if (!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}

						setOnLuas('boyfriendName', boyfriend.character);
					}
					case 1:
					{
						if (dad.character != value2)
						{
							if (!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.character.startsWith('gf');

							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);

							if (!dad.character.startsWith('gf'))
							{
								if (wasGf && gf != null)
								{
									gf.visible = true;
								}
							}
							else if (gf != null)
							{
								gf.visible = false;
							}

							dad.alpha = lastAlpha;

							iconP2.changeIcon(dad.healthIcon);
						}

						setOnLuas('dadName', dad.character);
					}
					case 2:
					{
						if (gf != null)
						{
							if (gf.character != value2)
							{
								if (!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}

							setOnLuas('gfName', gf.character);
						}
					}
				}

				reloadHealthBarColors();
			}
			case 'BG Freaks Expression':
			{
				if (bgGirls != null) bgGirls.swapDanceType();
			}
			case 'Change Scroll Speed':
			{
				if (songSpeedType == "constant") return;
		
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
	
				if (Math.isNaN(val1)) val1 = 1;
				if (Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * PlayStateChangeables.scrollSpeed * val1;

				if (val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function(twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
			}
			case 'Set Property':
			{
				var killMe:Array<String> = value1.split('.');

				if (killMe.length > 1) {
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				} else {
					FunkinLua.setVarInArray(this, value1, value2);
				}
			}
		}

		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	var cameraTwn:FlxTween;

	public function moveCameraSection():Void
	{
		if (SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);

			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];

			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);

			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			cameraMovement(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			cameraMovement(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	public function cameraMovement(isDad:Bool):Void
	{
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);

			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];

			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (SONG.songID == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	public function tweenCamIn():Void
	{
		if (SONG.songID == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			});
		}
	}

	private function onSongComplete():Void
	{
		finishSong(false);
	}

	public var endingSong:Bool = false;
	public var finishTimer:FlxTimer = null;

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;

		FlxG.sound.music.pause();
		FlxG.sound.music.volume = 0;

		vocals.pause();
		vocals.volume = 0;

		if (OptionData.noteOffset <= 0 || ignoreNoteOffset)
		{
			finishCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(OptionData.noteOffset / 1000, function(tmr:FlxTimer)
			{
				finishCallback();
			});
		}
	}

	public var transitioning = false;

	public function endSong():Void
	{
		inCutscene = false;

		if (gameMode != 'replay')
		{
			rep.saveReplay(saveNotes);
		}

		endingSong = true;
		updateTime = false;
		camZooming = false;
		iconsZooming = false;

		songPosBG.visible = false;
		songPosBar.visible = false;
		songPosName.visible = false;

		canPause = false;
		canReset = false;

		seenCutscene = false;
		deathCounter = 0;

		var ret:Dynamic = callOnLuas('onEndSong', [], false);

		if (ret != FunkinLua.Function_Stop && !transitioning)
		{
			var difficultySuffix:String = difficulties[2][difficulties[1].indexOf(storyDifficulty)];

			if (!usedPractice && gameMode != 'replay')
			{
				#if !switch
				Highscore.saveScore(SONG.songID + '-' + storyDifficulty, songScore);
				Highscore.saveAccuracy(SONG.songID + '-' + storyDifficulty, (Math.isNaN(songAccuracy) ? 0 : songAccuracy));
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			switch (gameMode)
			{
				case 'story':
				{
					if (!usedPractice) {
						campaignScore += songScore;
					}

					storyPlaylist.remove(storyPlaylist[0]);
		
					if (storyPlaylist.length <= 0)
					{
						cancelMusicFadeTween();

						CustomFadeTransition.nextCamera = camOther;

						if (FlxTransitionableState.skipNextTransIn) {
							CustomFadeTransition.nextCamera = null;
						}

						if (!usedPractice)
						{
							Highscore.saveWeekScore(storyWeek + '-' + storyDifficulty, campaignScore);

							WeekData.weekCompleted.set(storyWeek, true);
		
							FlxG.save.data.weekCompleted = WeekData.weekCompleted;
							FlxG.save.flush();
						}

						usedPractice = false;

						WeekData.loadTheFirstEnabledMod();
						MusicBeatState.switchState(new StoryMenuState());
					}
					else
					{
						FlxTransitionableState.skipNextTransIn = true;

						usedPractice = PlayStateChangeables.botPlay ? true : false;

						switch (SONG.songID)
						{
							case 'eggnog':
							{
								var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom, -FlxG.height * FlxG.camera.zoom);
								blackShit.makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
								blackShit.scrollFactor.set();
								add(blackShit);

								FlxG.sound.play(Paths.getSound('Lights_Shut_off'), 1, false, null, true, function()
								{
									nextSong(difficultySuffix);
								});

								camHUD.visible = false;
							}
							default:
							{
								prevCamFollow = camFollow;
								prevCamFollowPos = camFollowPos;

								nextSong(difficultySuffix);
							}
						}
					}
				}
				case 'freeplay':
				{
					cancelMusicFadeTween();

					CustomFadeTransition.nextCamera = camOther;

					if (FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}

					usedPractice = false;

					WeekData.loadTheFirstEnabledMod();
					MusicBeatState.switchState(new FreeplayMenuState());
				}
				case 'replay':
				{
					cancelMusicFadeTween();

					CustomFadeTransition.nextCamera = camOther;

					if (FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}

					if (FlxG.save.data.botPlay != null)
					{
						PlayStateChangeables.botPlay = FlxG.save.data.botPlay;
					}

					if (FlxG.save.data.scrollSpeed != null)
					{
						PlayStateChangeables.scrollSpeed = FlxG.save.data.scrollSpeed;
					}

					if (FlxG.save.data.downScroll != null)
					{
						OptionData.downScroll = FlxG.save.data.downScroll;
					}
					else
					{
						OptionData.downScroll = false;
					}

					WeekData.loadTheFirstEnabledMod();
					MusicBeatState.switchState(new options.ReplaysState());
				}
				default:
				{
					cancelMusicFadeTween();

					CustomFadeTransition.nextCamera = camOther;

					if (FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}

					usedPractice = false;

					WeekData.loadTheFirstEnabledMod();
					MusicBeatState.switchState(new MainMenuState());
				}
			}

			transitioning = true;
		}
	}

	public function nextSong(difficultySuffix:String):Void
	{
		cancelMusicFadeTween();

		SONG = Song.loadFromJson(storyPlaylist[0].toLowerCase() + difficultySuffix, storyPlaylist[0].toLowerCase());
		LoadingState.loadAndSwitchState(new PlayState(), true, true);
	}

	public function KillNotes():Void
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];

			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}

		unspawnNotes = [];
		eventNotes = [];
	}

	private function popUpScore(daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition + OptionData.ratingOffset);
		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();

		if (OptionData.ratingOnCamera && OptionData.numbersOnCamera) {
			coolText.x = FlxG.width * 0.55;
		} else {
			coolText.x = FlxG.width * 0.35;
		}

		vocals.volume = 1;

		var score:Int = 0;
		var daRating:String = Conductor.judgeNote(daNote, noteDiff);

		switch (daRating)
		{
			case 'sick':
			{
				if (!daNote.noteSplashDisabled) {
					spawnNoteSplashOnNote(daNote);
				}

				if (!PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay)
				{
					sicks++;
					totalNotesHit += 1;
				}

				score = 350;
			}
			case 'good':
			{
				if (!PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay)
				{
					goods++;
					totalNotesHit += 0.75;
				}

				score = 200;
			}
			case 'bad':
			{
				if (!PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay)
				{
					bads++;
					totalNotesHit += 0.5;
				}

				score = 100;
			}
			case 'shit':
			{
				if (!PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay)
				{
					shits++;
					totalNotesHit += 0;
				}

				score = 50;
			}
		}

		if (!PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay)
		{
			songScore += score;

			songHits++;
			totalPlayed++;
		}

		var rating:FlxSprite = new FlxSprite();
		rating.loadGraphic(Paths.getImage('ratings/' + daRating + (isPixelStage ? '-pixel' : '')));
		rating.screenCenter();

		if (OptionData.ratingOnCamera) {
			rating.x = coolText.x - 125;
		} else {
			rating.x = coolText.x - 40;
		}

		var iCanSayShit:Bool = (daRating == 'shit' && !OptionData.naughtyness);

		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.setGraphicSize(Std.int(rating.width * (isPixelStage ? daPixelZoom * 0.7 : 0.7)));
		rating.antialiasing = isPixelStage ? false : OptionData.globalAntialiasing;

		rating.visible = iCanSayShit ? false : OptionData.showRatings;

		if (OptionData.ratingOnCamera)
		{
			rating.x += OptionData.comboOffset[0];
			rating.y -= OptionData.comboOffset[1];
		}

		rating.updateHitbox();
		grpRatings.add(rating);

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite();
			numScore.loadGraphic(Paths.getImage('numbers/num' + Std.int(i) + (isPixelStage ? '-pixel' : '')));
			numScore.screenCenter();
			
			if (OptionData.numbersOnCamera)
			{
				numScore.x = coolText.x + (43 * daLoop) - 175;
			}
			else
			{
				numScore.x = coolText.x + (43 * daLoop) - 90;
			}

			numScore.y += 80;
			numScore.antialiasing = isPixelStage ? false : OptionData.globalAntialiasing;
			numScore.setGraphicSize(Std.int(numScore.width * (isPixelStage ? daPixelZoom : 0.5)));
			numScore.updateHitbox();
			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = OptionData.showNumbers;

			if (OptionData.numbersOnCamera)
			{
				numScore.x += OptionData.comboOffset[2];
				numScore.y -= OptionData.comboOffset[3];
			}

			if (combo >= 10) {
				grpNumbers.add(numScore);
			}

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.kill();
					grpNumbers.remove(numScore, true);
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

				rating.kill();
				grpRatings.remove(rating, true);
				rating.destroy();
			}
		});

		if (!PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay) {
			recalculateRating();
		}
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (!PlayStateChangeables.botPlay && !startingSong && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || OptionData.controllerMode))
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !OptionData.ghostTapping;

				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];

				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && daNote.noteData == key && !daNote.blockHit)
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
					callOnLuas('onGhostTap', [key]);

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

			callOnLuas('onKeyPress', [key]);
		}
	}

	public function sortHitNotes(a:Note, b:Note):Int
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

		if (!startingSong && !PlayStateChangeables.botPlay && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];

			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}

			callOnLuas('onKeyRelease', [key]);
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

		if (!startingSong && startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && holdingArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote);
				}
			});

			if (boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
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

	public function noteMissPress(direction:Int = 1):Void
	{
		FlxG.sound.play(Paths.getSoundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		if (!boyfriend.stunned)
		{
			health -= 0.05 * PlayStateChangeables.healthLoss;

			combo = 0;

			if (!PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay)
			{
				if (!endingSong) {
					songMisses++;
				}

				totalPlayed++;
				songScore -= 10;
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}

			if (boyfriend.hasMissAnimations) {
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}

			if (PlayStateChangeables.instaKill)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}
		}

		if (!PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay) {
			recalculateRating();
		}

		callOnLuas('noteMissPress', [direction]);
	}

	public function noteMiss(daNote:Note):Void
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

		health -= daNote.missHealth * PlayStateChangeables.healthLoss; // For testing purposes

		if (!PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay)
		{
			songScore -= 10;
			songMisses++;
			totalPlayed++;
		}

		if (PlayStateChangeables.instaKill)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		if (!PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay) {
			recalculateRating();
		}

		var char:Character = boyfriend;

		if (daNote.gfNote) {
			char = gf;
		}

		if (char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			var animToPlay:String = singAnimations[daNote.noteData] + 'miss' + daNote.animSuffix;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	public function opponentNoteHit(daNote:Note):Void
	{
		if (SONG.songID != 'tutorial') {
			camZooming = true;
		}

		if (daNote.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!daNote.noAnimation)
		{
			var altAnim:String = daNote.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + altAnim;

			if (daNote.gfNote) {
				char = gf;
			}

			if (char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (OptionData.cpuStrumsType == 'Lighting Up')
		{
			var time:Float = 0.15;

			if (daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) {
				time += 0.15;
			}
	
			StrumPlayAnim(true, Std.int(Math.abs(daNote.noteData)), time);
		}

		if (SONG.needsVoices) {
			vocals.volume = 1;
		}

		daNote.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(daNote), Math.abs(daNote.noteData), daNote.noteType, daNote.isSustainNote]);

		if (!daNote.isSustainNote)
		{
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
	}

	public function defaultGiverHealth(note:Note):Void
	{
		if (!note.ignoreNote)
		{
			if (!note.noRating)
			{
				if (!note.isSustainNote)
				{
					combo += 1;
					popUpScore(note);

					if (combo > 9999) combo = 9999;
				}
				else
				{
					totalNotesHit += 0.075;
				}
			}
		}
	
		if (!note.noHealth)
		{
			health += note.hitHealth * PlayStateChangeables.healthGain;
		}

		callOnLuas('onHit', []);
	}

	public function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (PlayStateChangeables.botPlay && (note.ignoreNote || note.hitCausesMiss)) return;

			if (OptionData.hitsoundVolume > 0 && OptionData.hitsoundType != '' && !note.hitsoundDisabled)
			{
				if (OptionData.hitsoundType == 'Kade') {
					FlxG.sound.play(Paths.getSound('SNAP'), OptionData.hitsoundVolume);
				} else if (OptionData.hitsoundType == 'Psych') {
					FlxG.sound.play(Paths.getSound('hitsound'), OptionData.hitsoundVolume);
				}
			}	

			if (!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if (note.gfNote)
				{
					if (gf != null)
					{
						gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					boyfriend.playAnim(animToPlay + note.animSuffix, true);
					boyfriend.holdTimer = 0;
				}

				if (note.noteType == 'Hey!')
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if (gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if (note.hitCausesMiss)
			{
				noteMiss(note);

				if (!note.noteSplashDisabled && !note.isSustainNote)
				{
					spawnNoteSplashOnNote(note);
				}

				if (!note.noMissAnimation)
				{
					switch (note.noteType)
					{
						case 'Hurt Note': // Hurt note
						{
							if (boyfriend.animation.getByName('hurt') != null)
							{
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
						}
					}
				}

				note.wasGoodHit = true;

				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}

				var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
				var leData:Int = Math.round(Math.abs(note.noteData));
				var leType:String = note.noteType;

				callOnLuas('onHitCauses', [notes.members.indexOf(note), leData, leType, isSus]);

				return;
			}
			else
			{
				defaultGiverHealth(note);
			}

			if (PlayStateChangeables.botPlay)
			{
				var time:Float = 0.15;

				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}

				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			}
			else
			{
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID) {
						spr.playAnim('confirm', true);
					}
				});
			}

			if (gameMode != 'replay' && note.mustPress) {
				saveNotes.push(CoolUtil.truncateFloat(note.strumTime, 2));
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;

			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}

		if (!PlayStateChangeables.practiceMode && !PlayStateChangeables.botPlay) {
			recalculateRating();
		}
	}

	public function spawnNoteSplashOnNote(note:Note)
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
		var skin:String = SONG.splashSkin != null && SONG.splashSkin.length > 0 ? SONG.splashSkin : 'noteSplashes';

		var hue:Float = OptionData.arrowHSV[data % 4][0] / 360;
		var sat:Float = OptionData.arrowHSV[data % 4][1] / 100;
		var brt:Float = OptionData.arrowHSV[data % 4][2] / 100;

		if (note != null)
		{
			skin = note.noteSplashTexture;

			if (note.isCustomNoteSplash)
			{
				hue = note.noteSplashHueCustom;
				sat = note.noteSplashSatCustom;
				brt = note.noteSplashBrtCustom;
			}
			else
			{
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	public function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.getSoundRandom('thunder_', 1, 2));
		if (!OptionData.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if (gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if (OptionData.camZooms)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if (!camZooming) // Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
			{
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if (OptionData.flashingLights)
		{
			halloweenWhite.alpha = 0.4;

			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	public function trainStart():Void
	{
		trainMoving = true;

		if (!trainSound.playing) {
			trainSound.play(true);
		}
	}

	var startedMoving:Bool = false;

	public function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;

			if (gf != null) {
				gf.playAnim('hairBlow');
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars--;

				if (trainCars <= 0)
				{
					trainFinishing = true;
				}
			}

			if (phillyTrain.x < -4000 && trainFinishing)
			{
				trainReset();
			}
		}
	}

	public function trainReset():Void
	{
		if (gf != null) {
			gf.playAnim('hairFall');
		}

		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;

		trainCars = 8;

		trainFinishing = false;
		startedMoving = false;
	}

	var fastCarCanDrive:Bool = true;

	public function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	public function killHenchmen():Void
	{
		if (!OptionData.lowQuality && curStage == 'limo')
		{
			if (limoKillingState < 1)
			{
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;
			}
		}
	}

	public function fastCarDrive():Void
	{
		FlxG.sound.play(Paths.getSoundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;

		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	public function resetLimoKill():Void
	{
		if (curStage == 'limo')
		{
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	public function moveTank(?elapsed:Float = 0):Void
	{
		if (!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	var lastStepHit:Int = -1;

	override function stepHit():Void
	{
		super.stepHit();

		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		if (curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;

		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	override function sectionHit():Void
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && OptionData.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);

				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}

			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
	}

	var lastBeatHit:Int = -1;

	override function beatHit():Void
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
		{
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, OptionData.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (OptionData.iconZooms && iconsZooming)
		{
			iconP1.scale.set(1.2, 1.2);
			iconP1.updateHitbox();

			iconP2.scale.set(1.2, 1.2);
			iconP2.updateHitbox();	
		}

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}

		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}

		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}

		switch (curStage)
		{
			case 'spooky':
			{
				if (FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
				{
					lightningStrikeShit();
				}
			}
			case 'philly':
			{
				if (!trainMoving) {
					trainCooldown++;
				}

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);

					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
			}
			case 'limo':
			{
				grpLimoDancers.forEach(function(dancer:BackgroundDancer)
				{
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
				{
					fastCarDrive();
				}
			}
			case 'mall':
			{
				upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);
			}
			case 'school':
			{
				bgGirls.dance();
			}
			case 'tank':
			{
				if (!OptionData.lowQuality) tankWatchtower.dance();

				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
			}
		}

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); // DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	public function StrumPlayAnim(isDad:Bool, id:Int, time:Float):Void
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

	public function addTextToDebug(text:String, color:FlxColor):Void
	{
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += 20;
		});

		if (luaDebugGroup.members.length > 34)
		{
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}

		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		if (modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag)) return modchartTexts.get(tag);

		return null;
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;

		#if LUA_ALLOWED
		if (exclusions == null) exclusions = [];

		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName)) {
				continue;
			}

			var ret:Dynamic = script.call(event, args);

			if (ret == FunkinLua.Function_StopLua && !ignoreStops) {
				break;
			}

			var bool:Bool = ret == FunkinLua.Function_Continue;

			if (!bool) {
				returnVal = cast ret;
			}
		}
		#end

		return returnVal;
	}

	public static function cancelMusicFadeTween():Void
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
		}

		FlxG.sound.music.fadeTween = null;
	}

	override function destroy():Void
	{
		super.destroy();

		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}

		luaArray = [];

		if (!OptionData.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		#if hscript
		FunkinLua.haxeInterp = null;
		#end
	}

	public function setOnLuas(variable:String, arg:Dynamic):Void
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!OptionData.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!OptionData.shaders) return false;

		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

	public function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';

		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);

			if (FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);

		if (Assets.exists(luaFile)) {
			doPush = true;
		}
		#end

		if (doPush)
		{
			for (script in luaArray)
			{
				if (script.scriptName == luaFile) return;
			}

			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}
}