package editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;

using StringTools;

class EditorsMenuState extends MusicBeatState
{
	private var curSelected:Int = 0;
	private var editorsArray:Array<String> =
	[
		'Week Editor',
		'Menu Character Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Character Editor',
		'Chart Editor'
	];

	private var grpEditors:FlxTypedGroup<Alphabet>;

	override function create():Void
	{
		super.create();

		FlxG.camera.bgColor = FlxColor.BLACK;

		if (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		FlxG.mouse.visible = false;

		#if desktop
		DiscordClient.changePresence("In the Editors Menu", null); // Updating Discord Rich Presence
		#end

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.image('bg/menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpEditors = new FlxTypedGroup<Alphabet>();
		add(grpEditors);

		for (i in 0...editorsArray.length)
		{
			var editorText:Alphabet = new Alphabet(0, (70 * i) + 30, editorsArray[i], true, false);
			editorText.isMenuItem = true;
			editorText.targetY = i;
			grpEditors.add(editorText);
		}

		changeSelection();
	}

	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (editorsArray.length > 1)
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
			goToState(editorsArray[curSelected]);
			FreeplayMenuState.destroyFreeplayVocals();
		}
	}

	function goToState(label:String):Void
	{
		FlxG.sound.music.volume = 0;

		switch (label)
		{
			case 'Week Editor':
				MusicBeatState.switchState(new WeekEditorState());
			case 'Menu Character Editor':
				MusicBeatState.switchState(new MenuCharacterEditorState());
			case 'Character Editor':
				LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false), true);
			case 'Dialogue Editor':
				LoadingState.loadAndSwitchState(new DialogueEditorState(), true);
			case 'Dialogue Portrait Editor':
				LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), true);
			case 'Chart Editor':
			{
				PlayState.SONG = Song.loadFromJson('test', 'test');
				LoadingState.loadAndSwitchState(new ChartingState(), true);
			}
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = editorsArray.length - 1;
		if (curSelected >= editorsArray.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpEditors.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
}