package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.effects.FlxFlicker;

using StringTools;

class CreditsMenuState extends MusicBeatState
{
	private static var curSelected:Int = -1;

	var creditsArray:Array<Credit> =
	[
		new Credit('Alush Engine by'),
		new Credit('AlanSurtaev2008',			true,		'assrj',			'Main Programmer of Akayo Engine and General Director of Afford-Set', 			'',																						0xFF6300AF),
		new Credit('Psych Engine Team'),
		new Credit('Shadow Mario',				true,		'shadowmario',		'Main Programmer of Psych Engine',												'https://twitter.com/Shadow_Mario_',													0xFF444444),
		new Credit('RiverOaken',				true,		'riveroaken',		'Main Artist/Animator of Psych Engine',											'https://twitter.com/RiverOaken',														0xFFB42F71),
		new Credit('shubs',						true,		'shubs',			'Additional Programmer of Psych Engine and Main Programmer of Forever Engine',	'https://twitter.com/yoshubs',															0xFF5E99DF),
		new Credit('Former Psych Engine Members'),
		new Credit('bb-panzu',					true,		'bb-panzu',			'Ex-Programmer of Psych Engine',												'https://twitter.com/bbsub3',															0xFF3E813A),
		new Credit('Psych Engine Contributors'),
		new Credit('iFlicky',					true,		'iflicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',						'https://twitter.com/flicky_i',															0xFF9E29CF),
		new Credit('SqirraRNG',					true,		'gedehari',			'Chart Editor\'s Sound Waveform base',											'https://twitter.com/gedehari',															0xFFE1843A),
		new Credit('PolybiusProxy',				true,		'polybiusproxy',	".MP4 Video Loader Extension (hxCodec)",									'https://twitter.com/polybiusproxy',													0xFFDCD294),
		new Credit('Keoiki',					true,		'keoiki',			'Note Splash Animations',														'https://twitter.com/Keoiki_',															0xFFFFFFFF),
		new Credit('Smokey',					true,		'smokey',			'Spritemap Texture Support',													'https://twitter.com/Smokey_5_',														0xFF483D92),
		new Credit('Kade Engine by'),
		new Credit('KadeDev',					true,		'kade',				'Main Programmer of Kade Engine',												'https://twitter.com/kade0912',															0xFF64A250),
		new Credit('Kade Engine Contributors'),
		new Credit('puyoxyz',					true,		'puyo',				'Additional Programmer of Kade Engine',											'https://twitter.com/puyoxyz',															0xFF4A2916),
		new Credit('Spel0',						true,		'spel0',			'Additional Programmer of Kade Engine',											'https://www.reddit.com/user/Spel0/',													0xFFE5E5E5),
		new Credit('Special thanks'),
		new Credit('AngelDTF',					true,		'angeldtf',			"For Week 7's (Newgrounds exclusive preview) Source Code Leak",					'',																						0xFF909090),
		new Credit("Funkin' Crew"),
		new Credit('ninjamuffin99',				true,		'ninjamuffin99',	"Programmer of Friday Night Funkin'",											'https://twitter.com/ninja_muffin99',													0xFFCF2D2D),
		new Credit('PhantomArcade',				true,		'phantomarcade',	"Animator of Friday Night Funkin'",												'https://twitter.com/PhantomArcade3K',													0xFFFADC45),
		new Credit('evilsk8r',					true,		'evilsk8r',			"Artist of Friday Night Funkin'",												'https://twitter.com/evilsk8r',															0xFF5ABD4B),
		new Credit('kawaisprite',				true,		'kawaisprite',		"Composer of Friday Night Funkin'",												'https://twitter.com/kawaisprite',														0xFF378FC7)
	];
	var curCredit:Credit;

	var bg:FlxSprite;

	var grpCredits:FlxTypedGroup<Alphabet>;
	var grpIcons:FlxTypedGroup<AttachedSprite>;

	private var descBox:FlxSprite;
	private var descText:FlxText;

	override function create():Void
	{
		super.create();

		#if desktop
		DiscordClient.changePresence("In the Credits Menu", null); // Updating Discord Rich Presence
		#end

		bg = new FlxSprite();
		bg.loadGraphic(Paths.image('bg/menuDesat'));
		bg.color = 0xFFFFFFFF;
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.antialiasing = OptionData.globalAntialiasing;
		add(bg);

		grpCredits = new FlxTypedGroup<Alphabet>();
		add(grpCredits);

		grpIcons = new FlxTypedGroup<AttachedSprite>();
		add(grpIcons);

		for (i in 0...creditsArray.length)
		{
			var leCredit:Credit = creditsArray[i];
			var isCentered:Bool = unselectableCheck(i);

			var creditText:Alphabet = new Alphabet(0, 70 * i, leCredit.name, isCentered, false);
			creditText.isMenuItem = true;
			creditText.screenCenter(X);
			creditText.forceX = creditText.x;
			creditText.targetY = i;
			grpCredits.add(creditText);

			if (!isCentered)
			{
				creditText.yAdd = -75;

				if (leCredit.icon != '')
				{
					var icon:AttachedSprite = new AttachedSprite('credits/' + leCredit.icon);
					icon.xAdd = creditText.width + 10;
					icon.sprTracker = creditText;
					icon.copyVisible = true;
					icon.ID = i;
					grpIcons.add(icon);
				}

				if (curSelected < 0) curSelected = i;
			}
		}

		descBox = new FlxSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		changeSelection();
	}

	var flickering:Bool = false;
	var nextAccept:Int = 5;
	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		bg.color = FlxColor.interpolate(bg.color, curCredit.color, CoolUtil.boundTo(elapsed * 2.45, 0, 1));

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new OptionsMenuState());
		}

		if (!flickering)
		{
			if (creditsArray.length > 1)
			{
				if (controls.UI_UP_P)
				{
					changeSelection(-1);
					holdTime = 0;
				}
	
				if (controls.UI_DOWN_P)
				{
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
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
					}
				}
	
				if (FlxG.mouse.wheel != 0)
				{
					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if (controls.ACCEPT && nextAccept <= 0 && curCredit.link != '')
			{
				if (OptionData.flashingLights)
				{
					flickering = true;

					FlxFlicker.flicker(grpCredits.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker)
					{
						flickering = false;
						CoolUtil.browserLoad(curCredit.link);
					});

					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
				else
				{
					CoolUtil.browserLoad(curCredit.link);
				}
			}
		}

		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}
	}

	function changeSelection(change:Int = 0)
	{
		do
		{
			curSelected += change;

			if (curSelected < 0)
				curSelected = creditsArray.length - 1;
			if (curSelected >= creditsArray.length)
				curSelected = 0;
		}
		while (unselectableCheck(curSelected));

		curCredit = creditsArray[curSelected];

		var bullShit:Int = 0;

		for (item in grpCredits.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1))
			{
				item.alpha = 0.6;

				if (item.targetY == 0)
				{
					item.alpha = 1;

					for (icon in grpIcons)
					{
						icon.alpha = 0.6;

						if (icon.sprTracker == item)
						{
							icon.alpha = 1;
						}
					}
				}
			}
		}

		descText.text = curCredit.description;
		descText.screenCenter(Y);
		descText.y += 270;

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		descBox.visible = (curCredit.description != '');

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	private function unselectableCheck(num:Int):Bool
	{
		return creditsArray[num].selected == false;
	}
}

private class Credit
{
	public var name:String = '';
	public var selected:Bool = false;
	public var icon:String = '';
	public var description:String = '';
	public var link:String = '';
	public var color:FlxColor = 0xFFFFFFFF;

	public function new(name:String = '', selected:Bool = false, icon:String = '', description:String = '', link:String = '', color:FlxColor = 0xFFFFFFFF):Void
	{
		this.name = name;
		this.selected = selected;
		this.icon = icon;
		this.description = description;
		this.link = link;
		this.color = color;
	}
}