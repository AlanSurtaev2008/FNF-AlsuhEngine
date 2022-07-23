package;

import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;

	private var isPlayer:Bool;
	private var isOldIcon:Bool;
	private var character:String;

	public function new(char:String = 'bf', isPlayer:Bool = false):Void
	{
		super();

		this.isPlayer = this.isOldIcon = false;
		this.character = '';
		this.isPlayer = isPlayer;

		changeIcon(char);

		antialiasing = char.endsWith('-pixel') ? false : OptionData.globalAntialiasing;
		scrollFactor.set();
	}

	public function changeIcon(char:String):Void
	{
		if (char != this.character)
		{
			var name:String = 'icons/icon-' + char;

			if (Paths.fileExists('images/' + name + '.png', IMAGE))
			{
				var file:Dynamic = Paths.image(name);

				if (loadGraphic(file).width >= 450)
				{
					loadGraphic((file), true, 150, 150);
					animation.add(char, [0, 1, 2], 0, false, this.isPlayer);
				}
				else if (loadGraphic((file)).width <= 300)
				{
					loadGraphic((file), true, 150, 150);
					animation.add(char, [0, 1], 0, false, this.isPlayer);
				}

				animation.play(char);

				this.character = char;
			}
			else
			{
				changeIcon("face");
			}
		}

		antialiasing = char.endsWith('-pixel') ? false : OptionData.globalAntialiasing;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
		}
	}

	public function getCharacter():String
	{
		return character;
	}
}