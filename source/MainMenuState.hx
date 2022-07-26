package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

class MainMenuState extends MusicBeatState
{
	private static var curSelected:Int = 0;

	var menuItems:Array<String> = ['story_mode', 'freeplay', #if !switch 'donate', 'options' #end];
	var grpMenuItems:FlxTypedGroup<FlxSprite>;

	var magenta:FlxSprite;

	var camFollowPos:FlxObject;
	var camFollow:FlxPoint;

	public static var engineVersion:String = '1.1.2h';
	public static var gameVersion:String = '0.2.8';

	override function create():Void
	{
		super.create();

		#if desktop
		DiscordClient.changePresence("In the Menus", null); // Updating Discord Rich Presence
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(-80);
		bg.loadGraphic(Paths.image('bg/menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = OptionData.globalAntialiasing;
		add(bg);

		camFollow = new FlxPoint(0, 0);

		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollowPos);

		magenta = new FlxSprite(-80);
		magenta.loadGraphic(Paths.image('bg/menuDesat'));
		magenta.scrollFactor.x = 0;
		magenta.scrollFactor.y = 0.18;
		magenta.setGraphicSize(Std.int(magenta.width * 1.2));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = OptionData.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		grpMenuItems = new FlxTypedGroup<FlxSprite>();
		add(grpMenuItems);

		for (i in 0...menuItems.length)
		{
			var menuItem:FlxSprite = new FlxSprite(0, 60 + (i * 160));
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + menuItems[i]);
			menuItem.animation.addByPrefix('idle', menuItems[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', menuItems[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = OptionData.globalAntialiasing;
			grpMenuItems.add(menuItem);
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var text:String = 'v ' + gameVersion + (OptionData.watermarks ? ' - FNF | v ' + engineVersion + ' - Alsuh Engine' : '');

		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, text, 12);
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.scrollFactor.set();
		add(versionShit);

		changeSelection();
	}

	var selectedSomethin:Bool = false;
	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 4.0, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
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

			if (controls.ACCEPT)
			{
				if (menuItems[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					if (OptionData.flashingLights) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					selectedSomethin = true;

					grpMenuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							new FlxTimer().start(1, function(tmr:FlxTimer)
							{
								FlxTween.tween(spr, {alpha: 0}, 0.4, {
									ease: FlxEase.quadOut,
									onComplete: function(twn:FlxTween)
									{
										spr.kill();
									}
								});
							});
						}
						else
						{
							if (OptionData.flashingLights)
							{
								FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
								{
									new FlxTimer().start(0.4, function(tmr:FlxTimer)
									{
										goToState(menuItems[curSelected]);
									});
								});
							}
							else
							{
								new FlxTimer().start(1.4, function(tmr:FlxTimer)
								{
									goToState(menuItems[curSelected]);
								});
							}
						}
					});

					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
			}

			#if desktop
			if (FlxG.keys.justPressed.SEVEN)
			{
				selectedSomethin = true;

				MusicBeatState.switchState(new editors.EditorsMenuState());
			}
			#end
		}

		grpMenuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	function goToState(daChoice:String):Void
	{
		switch (daChoice)
		{
			case 'story_mode':
				MusicBeatState.switchState(new StoryMenuState());
			case 'freeplay':
				MusicBeatState.switchState(new FreeplayMenuState());
			case 'options':
				LoadingState.loadAndSwitchState(new options.OptionsMenuState());
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		grpMenuItems.forEach(function(spr:FlxSprite)
		{
			if (spr.animation.curAnim != null && spr.animation.curAnim.name == 'selected') {
				spr.y += 20;
			}

			spr.animation.play('idle');

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				spr.y -= 20;

				camFollow.set(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
			}

			spr.updateHitbox();
		});
	}
}
