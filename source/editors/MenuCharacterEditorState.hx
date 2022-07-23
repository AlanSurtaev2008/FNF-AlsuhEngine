package editors;

import haxe.Json;

#if sys
import sys.io.File;
#end

import MenuCharacter;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import openfl.events.Event;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import openfl.net.FileFilter;
import flixel.addons.ui.FlxUI;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;

using StringTools;

class MenuCharacterEditorState extends MusicBeatState
{
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var characterFile:MenuCharacterFile = null;
	var txtOffsets:FlxText;

	var defaultCharacters:Array<String> = ['dad', 'bf', 'gf'];

	override function create():Void
	{
		super.create();

		characterFile = {
			image: 'Menu_Dad',
			scale: 0.47,
			position: [125, 205],
			idle_anim: 'Dad idle dance BLACK LINE',
			idle_animAlt: '',
			confirm_anim: 'Dad idle dance BLACK LINE',
			indices: [],
			indicesAlt: [],
			isGF: false,
			flipX: false
		};

		#if desktop
		DiscordClient.changePresence("Menu Character Editor", "Editting: " + characterFile.image); // Updating Discord Rich Presence
		#end

		add(new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51));

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		add(grpWeekCharacters);

		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, defaultCharacters[char], true);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		txtOffsets = new FlxText(20, 10, 0, "[0, 0]", 32);
		txtOffsets.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txtOffsets.alpha = 0.7;
		add(txtOffsets);

		var tipText:FlxText = new FlxText(0, 540, FlxG.width,
			"Arrow Keys - Change Offset (Hold shift for 10x speed)
			\nSpace - Play \"Start Press\" animation (Boyfriend Character Type)", 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		tipText.scrollFactor.set();
		add(tipText);

		addEditorBox();

		FlxG.mouse.visible = true;

		updateCharTypeBox();
	}

	var UI_typebox:FlxUITabMenu;
	var UI_mainbox:FlxUITabMenu;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];

	function addEditorBox():Void
	{
		var tabs = [
			{name: 'Character Type', label: 'Character Type'},
		];

		UI_typebox = new FlxUITabMenu(null, tabs, true);
		UI_typebox.resize(120, 180);
		UI_typebox.x = 100;
		UI_typebox.y = FlxG.height - UI_typebox.height - 50;
		UI_typebox.scrollFactor.set();
		addTypeUI();

		add(UI_typebox);

		var tabs = [
			{name: 'Character', label: 'Character'},
		];
		UI_mainbox = new FlxUITabMenu(null, tabs, true);
		UI_mainbox.resize(275, 275);
		UI_mainbox.x = FlxG.width - UI_mainbox.width - 25;
		UI_mainbox.y = FlxG.height - UI_mainbox.height - 2.5;
		UI_mainbox.scrollFactor.set();

		addCharacterUI();

		add(UI_mainbox);

		var loadButton:FlxButton = new FlxButton(0, 480, "Load Character", function()
		{
			loadCharacter();
		});

		loadButton.screenCenter(X);
		loadButton.x -= 60;
		add(loadButton);
	
		var saveButton:FlxButton = new FlxButton(0, 480, "Save Character", function()
		{
			saveCharacter();
		});

		saveButton.screenCenter(X);
		saveButton.x += 60;
		add(saveButton);
	}

	var opponentCheckbox:FlxUICheckBox;
	var boyfriendCheckbox:FlxUICheckBox;
	var girlfriendCheckbox:FlxUICheckBox;
	var curTypeSelected:Int = 0; //0 = Dad, 1 = BF, 2 = GF

	function addTypeUI():Void
	{
		var tab_group = new FlxUI(null, UI_typebox);
		tab_group.name = "Character Type";

		opponentCheckbox = new FlxUICheckBox(10, 20, null, null, "Opponent", 100);
		opponentCheckbox.callback = function()
		{
			curTypeSelected = 0;
			updateCharTypeBox();
		};

		boyfriendCheckbox = new FlxUICheckBox(opponentCheckbox.x, opponentCheckbox.y + 40, null, null, "Boyfriend", 100);
		boyfriendCheckbox.callback = function()
		{
			curTypeSelected = 1;
			updateCharTypeBox();
		};

		girlfriendCheckbox = new FlxUICheckBox(boyfriendCheckbox.x, boyfriendCheckbox.y + 40, null, null, "Girlfriend", 100);
		girlfriendCheckbox.callback = function()
		{
			curTypeSelected = 2;
			updateCharTypeBox();
		};

		tab_group.add(opponentCheckbox);
		tab_group.add(boyfriendCheckbox);
		tab_group.add(girlfriendCheckbox);
		UI_typebox.addGroup(tab_group);
	}

	var imageInputText:FlxUIInputText;
	var idleInputText:FlxUIInputText;
	var idleAltInputText:FlxUIInputText;
	var confirmInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationAltIndicesInputText:FlxUIInputText;
	var confirmDescText:FlxText;
	var scaleStepper:FlxUINumericStepper;
	var flipXCheckbox:FlxUICheckBox;

	function addCharacterUI():Void
	{
		var tab_group = new FlxUI(null, UI_mainbox);
		tab_group.name = "Character";
		
		imageInputText = new FlxUIInputText(10, 20, 80, characterFile.image, 8);
		blockPressWhileTypingOn.push(imageInputText);

		idleInputText = new FlxUIInputText(10, imageInputText.y + 35, 100, characterFile.idle_anim, 8);
		blockPressWhileTypingOn.push(idleInputText);

		idleAltInputText = new FlxUIInputText(10, idleInputText.y + 45, 100, characterFile.idle_animAlt, 8);
		blockPressWhileTypingOn.push(idleAltInputText);

		confirmInputText = new FlxUIInputText(10, idleAltInputText.y + 35, 100, characterFile.confirm_anim, 8);
		blockPressWhileTypingOn.push(confirmInputText);

		var indicesStr:String = characterFile.indices.toString();

		animationIndicesInputText = new FlxUIInputText(10, confirmInputText.y + 35, 100,
			indicesStr.substr(1, indicesStr.length - 2), 8);
		blockPressWhileTypingOn.push(animationIndicesInputText);

		var indicesStr:String = characterFile.indicesAlt.toString();

		animationAltIndicesInputText = new FlxUIInputText(10, animationIndicesInputText.y + 35, 100,
			indicesStr.substr(1, indicesStr.length - 2), 8);
		blockPressWhileTypingOn.push(animationAltIndicesInputText);

		flipXCheckbox = new FlxUICheckBox(10, confirmInputText.y + 95, null, null, "Flip X", 100);
		flipXCheckbox.callback = function()
		{
			grpWeekCharacters.members[curTypeSelected].flipX = flipXCheckbox.checked;
			characterFile.flipX = flipXCheckbox.checked;
		};

		var reloadImageButton:FlxButton = new FlxButton(180, confirmInputText.y + 95, "Reload Char", function()
		{
			reloadSelectedCharacter();
		});
		
		scaleStepper = new FlxUINumericStepper(190, imageInputText.y, 0.05, 1, 0.1, 30, 2);

		confirmDescText = new FlxText(10, confirmInputText.y - 18, 0, 'Start Press animation on the .XML:');
		tab_group.add(new FlxText(10, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(10, idleInputText.y - 18, 0, 'Idle animation on the .XML:'));
		tab_group.add(new FlxText(10, idleAltInputText.y - 26, 0, 'Alternative idle animation on the .XML\n(you can use normal animation):'));
		tab_group.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(10, animationIndicesInputText.y - 18, 0, 'Animation Indices:'));
		tab_group.add(new FlxText(10, animationAltIndicesInputText.y - 18, 0, 'Alternative Animation Indices:'));
		tab_group.add(flipXCheckbox);
		tab_group.add(reloadImageButton);
		tab_group.add(confirmDescText);
		tab_group.add(imageInputText);
		tab_group.add(idleInputText);
		tab_group.add(idleAltInputText);
		tab_group.add(confirmInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationAltIndicesInputText);
		tab_group.add(scaleStepper);

		UI_mainbox.addGroup(tab_group);
	}

	function updateCharTypeBox():Void
	{
		opponentCheckbox.checked = false;
		boyfriendCheckbox.checked = false;
		girlfriendCheckbox.checked = false;

		switch (curTypeSelected)
		{
			case 0:
				opponentCheckbox.checked = true;
			case 1:
				boyfriendCheckbox.checked = true;
			case 2:
				girlfriendCheckbox.checked = true;
		}

		updateCharacters();
	}

	function updateCharacters():Void
	{
		for (i in 0...3)
		{
			var char:MenuCharacter = grpWeekCharacters.members[i];
			char.alpha = 0.2;
			char.character = '';
			char.changeCharacter(defaultCharacters[i]);
		}

		reloadSelectedCharacter();
	}
	
	function reloadSelectedCharacter():Void
	{
		var char:MenuCharacter = grpWeekCharacters.members[curTypeSelected];

		char.alpha = 1;
		char.frames = Paths.getSparrowAtlas('storymenu/menucharacters/' + characterFile.image);
		char.isDanced = characterFile.isGF;

		if (char.isDanced)
		{
			if (characterFile.indicesAlt != null && characterFile.indicesAlt.length > 0 && characterFile.idle_animAlt != null)
			{
				char.animation.addByIndices('danceRight', characterFile.idle_animAlt, characterFile.indicesAlt, '', false);
			}

			if (characterFile.indices != null && characterFile.indices.length > 0)
			{
				char.animation.addByIndices('danceLeft', characterFile.idle_anim, characterFile.indices, '', false);
			}
		}
		else
		{
			char.animation.addByPrefix('idle', characterFile.idle_anim, 24);
		}

		char.animation.addByPrefix('confirm', characterFile.confirm_anim, 24, false);
		char.flipX = (characterFile.flipX == true);
		char.scale.set(characterFile.scale, characterFile.scale);
		char.updateHitbox();
		char.dance();

		updateOffset();
		
		#if desktop
		DiscordClient.changePresence("Menu Character Editor", "Editting: " + characterFile.image); // Updating Discord Rich Presence
		#end
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>):Void
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == imageInputText)
			{
				characterFile.image = imageInputText.text;
			}
			else if (sender == idleInputText)
			{
				characterFile.idle_anim = idleInputText.text;
			}
			else if (sender == idleAltInputText)
			{
				characterFile.idle_animAlt = idleAltInputText.text;
			}
			else if (sender == confirmInputText)
			{
				characterFile.confirm_anim = confirmInputText.text;
			}
			else if (sender == animationIndicesInputText)
			{
				var indices:Array<Int> = [];
				var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');

				if (indicesStr.length > 1)
				{
					for (i in 0...indicesStr.length)
					{
						var index:Int = Std.parseInt(indicesStr[i]);

						if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1)
						{
							indices.push(index);
						}
					}
				}

				characterFile.indices = indices;
			}
			else if (sender == animationAltIndicesInputText)
			{
				var indices:Array<Int> = [];
				var indicesStr:Array<String> = animationAltIndicesInputText.text.trim().split(',');

				if (indicesStr.length > 1)
				{
					for (i in 0...indicesStr.length)
					{
						var index:Int = Std.parseInt(indicesStr[i]);

						if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1)
						{
							indices.push(index);
						}
					}
				}

				characterFile.indicesAlt = indices;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == scaleStepper)
			{
				characterFile.scale = scaleStepper.value;
				reloadSelectedCharacter();
			}
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var blockInput:Bool = false;

		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
	
				blockInput = true;

				if (FlxG.keys.justPressed.ENTER) inputText.hasFocus = false;

				break;
			}
		}

		if (!blockInput)
		{
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;

			if (FlxG.keys.justPressed.ESCAPE)
			{
				MusicBeatState.switchState(new EditorsMenuState());
			}

			var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 10 : 1;

			if (FlxG.keys.justPressed.LEFT)
			{
				characterFile.position[0] += shiftMult;
				updateOffset();
			}

			if (FlxG.keys.justPressed.RIGHT)
			{
				characterFile.position[0] -= shiftMult;
				updateOffset();
			}

			if (FlxG.keys.justPressed.UP)
			{
				characterFile.position[1] += shiftMult;
				updateOffset();
			}

			if (FlxG.keys.justPressed.DOWN)
			{
				characterFile.position[1] -= shiftMult;
				updateOffset();
			}

			if (FlxG.keys.justPressed.SPACE && curTypeSelected == 1)
			{
				grpWeekCharacters.members[curTypeSelected].animation.play('confirm', true);
			}
		}

		var char:MenuCharacter = grpWeekCharacters.members[1];

		if (char.animation.curAnim != null && char.animation.curAnim.name == 'confirm' && char.animation.curAnim.finished)
		{
			char.dance();
		}
	}

	function updateOffset():Void
	{
		var char:MenuCharacter = grpWeekCharacters.members[curTypeSelected];
		char.offset.set(characterFile.position[0], characterFile.position[1]);
		txtOffsets.text = '' + characterFile.position;
	}

	var _file:FileReference = null;

	function loadCharacter():Void
	{
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');

		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if (_file.__path != null) fullPath = _file.__path;

		if (fullPath != null)
		{
			var rawJson:String = File.getContent(fullPath);

			if (rawJson != null)
			{
				var loadedChar:MenuCharacterFile = cast Json.parse(rawJson);

				if (loadedChar.idle_anim != null && loadedChar.confirm_anim != null) // Make sure it's really a character
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);

					trace("Successfully loaded file: " + cutName);

					characterFile = loadedChar;

					reloadSelectedCharacter();

					imageInputText.text = characterFile.image;
					idleInputText.text = characterFile.idle_anim;
					idleAltInputText.text = characterFile.idle_animAlt;
					confirmInputText.text = characterFile.confirm_anim;
					scaleStepper.value = characterFile.scale;

					if (characterFile.indices != null && characterFile.indices.length > 0)
					{
						var indicesStr:String = characterFile.indices.toString();
						animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
					}

					if (characterFile.indicesAlt != null && characterFile.indicesAlt.length > 0)
					{
						var indicesStr:String = characterFile.indicesAlt.toString();
						animationAltIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
					}

					updateOffset();
					_file = null;

					return;
				}
			}
		}

		_file = null;

		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onLoadCancel(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		_file = null;

		trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onLoadError(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;

		trace("Problem loading file");
	}

	function saveCharacter():Void
	{
		var data:String = Json.stringify(characterFile, "\t");

		if (data.length > 0)
		{
			var splittedImage:Array<String> = imageInputText.text.trim().split('_');
			var characterName:String = splittedImage[splittedImage.length - 1].toLowerCase().replace(' ', '');

			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, characterName + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;

		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;

		FlxG.log.error("Problem saving file");
	}
}