package;

#if desktop
import Discord.DiscordClient;
#end

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.effects.FlxFlicker;

using StringTools;

class CreditsMenuState extends TransitionableState
{
	private static var curSelected:Int = -1;

	var creditsArray:Array<Array<String>> = [];
	var curCredit:Array<String>;

	var bg:FlxSprite;

	var grpCredits:FlxTypedGroup<Alphabet>;
	var grpIcons:FlxTypedGroup<AttachedSprite>;

	private var descBox:FlxSprite;
	private var descText:FlxText;

	public override function create():Void
	{
		super.create();

		#if desktop
		DiscordClient.changePresence("In the Credits Menu", null); // Updating Discord Rich Presence
		#end

		#if MODS_ALLOWED
		var path:String = 'modsList.txt';

		if (FileSystem.exists(path))
		{
			var leMods:Array<String> = CoolUtil.coolTextFile(path);
		
			for (i in 0...leMods.length)
			{
				if (leMods.length > 1 && leMods[0].length > 0)
				{
					var modSplit:Array<String> = leMods[i].split('|');
				
					if (!Paths.ignoreModFolders.contains(modSplit[0].toLowerCase()) && !modsAdded.contains(modSplit[0]))
					{
						if (modSplit[1] == '1')
							pushModCreditsToList(modSplit[0]);
						else
							modsAdded.push(modSplit[0]);
					}
				}
			}
		}

		var arrayOfFolders:Array<String> = Paths.getModDirectories();
		arrayOfFolders.push('');

		for (folder in arrayOfFolders) {
			pushModCreditsToList(folder);
		}
		#end

		var pisspoop:Array<Array<String>> =
		[
			['Alsuh Engine by'],
			['AlanSurtaev2008',		'assrj',			'Main Programmer of Alsuh Engine and General Director of Afford-Set', 		'',										'6300AF'],
			[''],
			['Psych Engine Team'],
			['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',											'https://twitter.com/Shadow_Mario_',	'444444'],
			['RiverOaken',			'river',			'Main Artist/Animator of Psych Engine',										'https://twitter.com/RiverOaken',		'B42F71'],
			['shubs',				'shubs',			'Additional Programmer of Psych Engine',									'https://twitter.com/yoshubs',			'5E99DF'],
			[''],
			['Former Psych Engine Members'],
			['bb-panzu',			'bb',				'Ex-Programmer of Psych Engine',											'https://twitter.com/bbsub3',			'3E813A'],
			[''],
			['Psych Engine Contributors'],
			['iFlicky',				'flicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',					'https://twitter.com/flicky_i',			'9E29CF'],
			['SqirraRNG',			'sqirra',			'Crash Handler and Base code for\nChart Editor\'s Waveform',				'https://twitter.com/gedehari',			'E1843A'],
			['PolybiusProxy',		'proxy',			'.MP4 Video Loader Library (hxCodec)',										'https://twitter.com/polybiusproxy',	'DCD294'],
			['KadeDev',				'kade',				'Fixed some cool stuff on Chart Editor\nand other PRs',						'https://twitter.com/kade0912',			'64A250'],
			['Keoiki',				'keoiki',			'Note Splash Animations',													'https://twitter.com/Keoiki_',			'D2D2D2'],
			['Nebula the Zorua',	'nebula',			'LUA JIT Fork and some Lua reworks',										'https://twitter.com/Nebula_Zorua',		'7D40B2'],
			['Smokey',				'smokey',			'Sprite Atlas Support',														'https://twitter.com/Smokey_5_',		'483D92'],
			[''],
			['Special Thanks'],
			['AngelDTF',			'angeldtf',			"For Week 7's (Newgrounds exclusive preview) Source Code Leak",				'',										'909090'],
			['GWeb',				'gweb',				"For .WEBM Extension",														'https://twitter.com/GWebDevFNF',		'639BFF'],
			[''],
			["Funkin' Crew"],
			['ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",										'https://twitter.com/ninja_muffin99',	'CF2D2D'],
			['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",											'https://twitter.com/PhantomArcade3K',	'FADC45'],
			['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",											'https://twitter.com/evilsk8r',			'5ABD4B'],
			['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",											'https://twitter.com/kawaisprite',		'378FC7']
		];

		for (i in pisspoop) {
			creditsArray.push(i);
		}

		bg = new FlxSprite();
		bg.loadGraphic(Paths.getImage('bg/menuDesat'));
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
			var leCredit:Array<String> = creditsArray[i];
			var isCentered:Bool = unselectableCheck(i);

			var creditText:Alphabet = new Alphabet(0, 70 * i, leCredit[0], isCentered);
			creditText.isMenuItem = true;
			creditText.startPosition.y = -70;
			creditText.screenCenter(X);
			creditText.changeX = false;
			creditText.targetY = i;
			grpCredits.add(creditText);

			if (!isCentered)
			{
				if (leCredit[5] != null) {
					Paths.currentModDirectory = leCredit[5];
				}

				creditText.x = -70;
				creditText.startPosition.x = -70;

				if (leCredit[1] != '')
				{
					var icon:AttachedSprite = new AttachedSprite('credits/' + leCredit[1]);
					icon.xAdd = creditText.width + 10;
					icon.sprTracker = creditText;
					icon.copyVisible = true;
					icon.ID = i;
					grpIcons.add(icon);
				}

				Paths.currentModDirectory = '';

				if (curSelected < 0) curSelected = i;
			}
		}

		descBox = new FlxSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.getFont("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		changeSelection();
	}

	var flickering:Bool = false;
	var nextAccept:Int = 5;
	var holdTime:Float = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		bg.color = CoolUtil.interpolateColor(bg.color, getCurrentBGColor(), 0.045);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new options.OptionsMenuState());
		}

		if (!flickering)
		{
			if (creditsArray.length > 1)
			{
				var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
	
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}
	
				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
	
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
	
				if (FlxG.mouse.wheel != 0)
				{
					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if (controls.ACCEPT && nextAccept <= 0 && (curCredit[3] == null || curCredit[3].length > 4))
			{
				if (OptionData.flashingLights)
				{
					flickering = true;

					FlxFlicker.flicker(grpCredits.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker)
					{
						flickering = false;
						CoolUtil.browserLoad(curCredit[3]);
					});

					FlxG.sound.play(Paths.getSound('confirmMenu'));
				}
				else
				{
					CoolUtil.browserLoad(curCredit[3]);
				}
			}
		}

		for (item in grpCredits.members)
		{
			if (!item.bold)
			{
				if (item.targetY == 0)
				{
					var lastX:Float = item.x;
				
					item.screenCenter(X);
					item.x = CoolUtil.coolLerp(lastX, item.x - 70, 0.2);
				}
				else
				{
					item.x = CoolUtil.coolLerp(item.x, 200 + -40 * Math.abs(item.targetY), 0.2);
				}
			}
		}

		if (nextAccept > 0) {
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

			if (!unselectableCheck(bullShit - 1))
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

		descText.text = curCredit[2];
		descText.screenCenter(Y);
		descText.y += 270;

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		descBox.visible = curCredit[2] != '';

		FlxG.sound.play(Paths.getSound('scrollMenu'));
	}

	#if MODS_ALLOWED
	private var modsAdded:Array<String> = [];

	function pushModCreditsToList(folder:String)
	{
		if (modsAdded.contains(folder)) return;

		var creditsFile:String = null;

		if (folder != null && folder.trim().length > 0)
			creditsFile = Paths.mods(folder + '/data/credits.txt');
		else
			creditsFile = Paths.mods('data/credits.txt');

		if (FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');

			for (i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if (arr.length >= 5) arr.push(folder);
				creditsArray.push(arr);
			}
	
			creditsArray.push(['']);
		}

		modsAdded.push(folder);
	}
	#end

	function getCurrentBGColor():Int
	{
		var bgColor:String = creditsArray[curSelected][4];

		if (!bgColor.startsWith('0x')) {
			bgColor = '0xFF' + bgColor;
		}

		return Std.parseInt(bgColor);
	}

	private function unselectableCheck(num:Int):Bool
	{
		return creditsArray[num].length <= 1;
	}
}