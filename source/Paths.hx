package;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end

import haxe.Json;
import flixel.FlxG;
import lime.utils.Assets;
import flash.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import haxe.format.JsonParser;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets as OpenFlAssets;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class Paths
{
	public static var SOUND_EXT:String = #if web 'mp3' #else 'ogg' #end;

	public static var VIDEO_EXT:String = 'mp4';
	public static var WEBM_EXT:String = 'webm';

	public static var currentModDirectory:String = null;

	#if MODS_ALLOWED
	public static var ignoreModFolders:Array<String> =
	[
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];
	#end

	public static function excludeAsset(key:String):Void
	{
		if (!dumpExclusions.contains(key)) dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> =
	[
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
	];

	public static function clearUnusedMemory():Void
	{
		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedAssets.get(key);

				@:privateAccess
				if (obj != null)
				{
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);

					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}

		System.gc();
	}

	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(?cleanUnused:Bool = false):Void
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);

			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);

				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		localTrackedAssets = [];

		openfl.Assets.cache.clear("songs");
	}

	public static var currentLevel:String;

	public static function setCurrentLevel(name:String):Void
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null):String
	{
		if (library != null)
		{
			return getLibraryPath(file, library);
		}

		if (currentLevel != null)
		{
			var levelPath:String = '';

			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(file, currentLevel);

				if (OpenFlAssets.exists(levelPath, type))
				{
					return levelPath;
				}
			}

			levelPath = getLibraryPathForce(file, "shared");

			if (OpenFlAssets.exists(levelPath, type))
			{
				return levelPath;
			}
		}

		return getPreloadPath(file);
	}

	public static function getLibraryPath(file:String, library = "preload"):String
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	public static function getLibraryPathForce(file:String, library:String):String
	{
		return '$library:assets/$library/$file';
	}

	public static function getPreloadPath(file:String = ''):String
	{
		return 'assets/$file';
	}

	public static function file(file:String, type:AssetType = TEXT, ?library:String):String
	{
		return getPath(file, type, library);
	}

	public static function txt(key:String, ?library:String):String
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	public static function xml(key:String, ?library:String):String
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	public static function json(key:String, ?library:String):String
	{
		return getPath('data/$key.json', TEXT, library);
	}

	public static function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	public static function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	public static function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);

		return file;
	}

	public static function voices(song:String):Any
	{
		var voices = returnSound('songs', song.toLowerCase() + '/Voices');

		return voices;
	}

	public static function inst(song:String):Any
	{
		var inst = returnSound('songs', song.toLowerCase() + '/Inst');

		return inst;
	}

	public static function image(key:String, ?library:String):FlxGraphic
	{
		var returnAsset:FlxGraphic = returnGraphic(key, library);
		return returnAsset;
	}

	public static function video(key:String, ?library:Null<String> = null):String
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);

		if (FileSystem.exists(file)) {
			return file;
		}
		#end

		if (fileExists('videos/$key.$VIDEO_EXT', BINARY, false, library) && library != null)
		{
			return 'assets/' + library + '/videos/$key.$VIDEO_EXT';
		}

		return 'assets/videos/$key.$VIDEO_EXT';
	}

	public static function webm(key:String, ?library:Null<String> = null):String
	{
		#if MODS_ALLOWED
		var file:String = modsWebm(key);

		if (FileSystem.exists(file)) {
			return file;
		}
		#end

		if (fileExists('videos/$key.$WEBM_EXT', BINARY, false, library) && library != null)
		{
			return 'assets/' + library + '/videos/$key.$WEBM_EXT';
		}

		return 'assets/videos/$key.$WEBM_EXT';
	}

	public static function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key))) {}
		return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getPreloadPath(key))) {
			return File.getContent(getPreloadPath(key));
		}

		if (currentLevel != null)
		{
			var levelPath:String = '';

			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(key, currentLevel);

				if (FileSystem.exists(levelPath)) {
					return File.getContent(levelPath);
				}
			}

			levelPath = getLibraryPathForce(key, 'shared');

			if (FileSystem.exists(levelPath)) {
				return File.getContent(levelPath);
			}
		}
		#end

		return Assets.getText(getPath(key, TEXT));
	}

	public static function font(key:String):String
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);

		if (FileSystem.exists(file)) {
			return file;
		}
		#end

		return 'assets/fonts/$key';
	}

	public static function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var xmlExists:Bool = false;

		if (FileSystem.exists(modsXml(key))) {
			xmlExists = true;
		}

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)), (xmlExists ? File.getContent(modsXml(key)) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}

	public static function getPackerAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var txtExists:Bool = false;

		if (FileSystem.exists(modsTxt(key))) {
			txtExists = true;
		}

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)), (txtExists ? File.getContent(modsTxt(key)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	public static function returnGraphic(key:String, ?library:String):Any
	{
		#if MODS_ALLOWED
		var modKey:String = modsImages(key);

		if (FileSystem.exists(modKey))
		{
			if (!currentTrackedAssets.exists(modKey))
			{
				var newBitmap:BitmapData = BitmapData.fromFile(modKey);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, modKey);

				newGraphic.persist = true;
				currentTrackedAssets.set(modKey, newGraphic);
			}

			localTrackedAssets.push(modKey);

			return currentTrackedAssets.get(modKey);
		}
		#end

		var path:String = getPath('images/$key.png', IMAGE, library);

		if (OpenFlAssets.exists(path, IMAGE))
		{
			if (!currentTrackedAssets.exists(path))
			{
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = true;

				currentTrackedAssets.set(path, newGraphic);
			}

			localTrackedAssets.push(path);

			return currentTrackedAssets.get(path);
		}

		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function returnSound(path:String, key:String, ?library:String):Sound
	{
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);

		if (FileSystem.exists(file))
		{
			if (!currentTrackedSounds.exists(file))
			{
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}

			localTrackedAssets.push(key);

			return currentTrackedSounds.get(file);
		}
		#end

		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);

		if (!currentTrackedSounds.exists(gottenPath))
		#if MODS_ALLOWED
		{
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
		}
		#else
		{
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound((path == 'songs' ? 'songs:' : '') + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
		}
		#end

		localTrackedAssets.push(gottenPath);

		return currentTrackedSounds.get(gottenPath);
	}

	public static function formatToSongPath(path:String):String
	{
		return path.toLowerCase().replace(' ', '-');
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String):Bool
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(mods(currentModDirectory + '/' + key)) || FileSystem.exists(mods(key)))
		{
			return true;
		}
		#end
		
		if (OpenFlAssets.exists(Paths.getPath(key, type)))
		{
			return true;
		}

		return false;
	}

	#if MODS_ALLOWED
	public static function mods(key:String = ''):String
	{
		return 'mods/' + key;
	}

	public static function modsFont(key:String):String
	{
		return modFolders('fonts/' + key);
	}

	public static function modsJson(key:String):String
	{
		return modFolders('data/' + key + '.json');
	}

	public static function modsVideo(key:String):String
	{
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	public static function modsWebm(key:String):String
	{
		return modFolders('videos/' + key + '.' + WEBM_EXT);
	}

	public static function modsSounds(path:String, key:String):String
	{
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}

	public static function modsImages(key:String):String
	{
		return modFolders('images/' + key + '.png');
	}

	public static function modsXml(key:String):String
	{
		return modFolders('images/' + key + '.xml');
	}

	public static function modsTxt(key:String):String 
	{
		return modFolders('images/' + key + '.txt');
	}

	public static function modFolders(key:String):String
	{
		if (currentModDirectory != null && currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(currentModDirectory + '/' + key);

			if (FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		return 'mods/' + key;
	}
	#end
}