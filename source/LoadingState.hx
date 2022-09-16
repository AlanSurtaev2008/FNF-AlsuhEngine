package;

import flixel.FlxG;
import haxe.io.Path;
import lime.app.Future;
import flixel.FlxState;
import flixel.FlxSprite;
import lime.app.Promise;
import flash.media.Sound;
import flixel.math.FlxMath;
import openfl.utils.Assets;
import flixel.util.FlxTimer;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;

using StringTools;

class LoadingState extends TransitionableState
{
	var targetShit:Float = 0;

	var callbacks:MultiCallback;

	var funkay:FlxSprite;
	var loadBar:FlxSprite;
	
	var target:FlxState;
	var stopMusic:Bool = false;
	var directory:String;

	function new(target:FlxState, stopMusic:Bool, directory:String):Void
	{
		super();

		this.target = target;
		this.stopMusic = stopMusic;
		this.directory = directory;
	}
	
	public override function create():Void
	{
		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, 0xFFCAFF4D);
		add(bg);

		funkay = new FlxSprite();
		funkay.loadGraphic(Paths.getImage('bg/funkay'));
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		funkay.antialiasing = OptionData.globalAntialiasing;
		funkay.scrollFactor.set();
		funkay.screenCenter();
		add(funkay);

		loadBar = new FlxSprite(0, FlxG.height - 20);
		loadBar.makeGraphic(FlxG.width, 10, 0xFFFF16D2);
		loadBar.antialiasing = OptionData.globalAntialiasing;
		loadBar.screenCenter(X);
		loadBar.scale.x = 0.00001;
		add(loadBar);

		if (Transition.nextCamera != null) {
			Transition.nextCamera = null;
		}

		FlxG.camera.fade(FlxG.camera.bgColor, 0.5, true, function()
		{
			initSongsManifest().onComplete(function(lib)
			{
				callbacks = new MultiCallback(onLoad);
	
				var introComplete = callbacks.add('introComplete');
	
				if (PlayState.SONG != null) {
					checkLoadSong(getSongPath());
				}

				checkLibrary('shared');
	
				if (directory != null && directory.length > 0 && directory != 'shared') {
					checkLibrary(directory);
				}
	
				new FlxTimer().start(1.5, function(_) introComplete());
			});
		});
	}

	private static var cachedFiles:Map<String, Bool> = #if (haxe >= "4.0.0") new Map() #else new Map<String, Bool>() #end;

	function checkLoadSong(path:String):Void
	{
		if (#if MODS_ALLOWED !cachedFiles.exists(path) #else !Assets.cache.hasSound(path) #end)
		{
			var callback = callbacks.add("song:" + path);

			#if MODS_ALLOWED
			Sound.loadFromFile(path).onComplete(function(sound:Sound)
			{
				trace('loaded path: ' + path);
				cachedFiles.set(path, true);

				callback();

				sound;

				if (PlayState.SONG != null && PlayState.SONG.needsVoices) {
					checkLoadSong(getVocalPath());
				}
			}).onError(function(error:Dynamic)
			{
				trace('path not found: ' + path);

				callback();
			});
			#else
			Assets.loadSound(path).onComplete(function(sound:Sound)
			{
				trace('loaded path: ' + path);
				cachedFiles.set(path, true);

				callback();

				sound;

				if (PlayState.SONG != null && PlayState.SONG.needsVoices) {
					checkLoadSong(getVocalPath());
				}
			}).onError(function(error:Dynamic)
			{
				trace('path not found: ' + path);

				callback();
			});
			#end
		}
	}

	function checkLibrary(library:String):Void
	{
		trace(Assets.hasLibrary(library));

		if (Assets.getLibrary(library) == null)
		{
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw "Missing library: " + library;
			
			var callback = callbacks.add("library:" + library);

			Assets.loadLibrary(library).onComplete(function(library:AssetLibrary)
			{
				callback();
			});
		}
	}
	
	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var wacky:Float = FlxG.width * 0.88;

		funkay.setGraphicSize(Std.int(wacky + 0.9 * (funkay.width - wacky)));
		funkay.updateHitbox();

		if (controls.ACCEPT)
		{
			funkay.setGraphicSize(Std.int(funkay.width + 60));
			funkay.updateHitbox();

			#if debug
			if (callbacks != null) trace('fired: ' + callbacks.getFired() + " unfired:" + callbacks.getUnfired());
			#end
		}

		if (callbacks != null)
		{
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
			loadBar.scale.x += 0.5 * (targetShit - loadBar.scale.x);
		}
	}
	
	function onLoad():Void
	{
		if (stopMusic && FlxG.sound.music != null) {
			FlxG.sound.music.stop();
		}

		FreeplayMenuState.destroyFreeplayVocals();

		FlxG.switchState(target);
	}

	static function getSongPath():String
	{
		return Paths.getInst(PlayState.SONG.songID, CoolUtil.getDifficultySuffix(PlayState.lastDifficulty), true);
	}

	static function getVocalPath():String
	{
		return Paths.getVoices(PlayState.SONG.songID, CoolUtil.getDifficultySuffix(PlayState.lastDifficulty), true);
	}

	public static function loadAndSwitchState(target:FlxState, stopMusic:Bool = false):Void
	{
		FlxG.switchState(getNextState(target, stopMusic));
	}
	
	static function getNextState(target:FlxState, stopMusic:Bool = false):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;

		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);

		var loaded:Bool = false;

		if (OptionData.loadingScreen)
		{
			if (PlayState.SONG != null) {
				loaded = isSoundLoaded(getSongPath()) && (!PlayState.SONG.needsVoices || isSoundLoaded(getVocalPath())) && isLibraryLoaded("shared") && isLibraryLoaded(directory);
			}

			if (!loaded) {
				return new LoadingState(target, stopMusic, directory);
			}

			if (stopMusic && FlxG.sound.music != null) {
				FlxG.sound.music.stop();
			}

			FreeplayMenuState.destroyFreeplayVocals();
		}
		
		return target;
	}

	static function isSoundLoaded(path:String):Bool
	{
		return #if MODS_ALLOWED cachedFiles.exists(path) #else Assets.cache.hasSound(path) #end;
	}
	
	static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}

	public override function destroy():Void
	{
		super.destroy();
		
		callbacks = null;
	}
	
	static function initSongsManifest():Future<AssetLibrary>
	{
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = LimeAssets.getLibrary(id);

		if (library != null)
		{
			return Future.withValue(library);
		}

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
			promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;
	
	var unfired = new Map<String, Void->Void>();
	var fired = new Array<String>();
	
	public function new(callback:Void->Void, logId:String = null):Void
	{
		this.callback = callback;
		this.logId = logId;
	}
	
	public function add(id = "untitled"):Void->Void
	{
		id = '$length:$id';

		length++;
		numRemaining++;

		var func:Void->Void = null;

		func = function()
		{
			if (unfired.exists(id))
			{
				unfired.remove(id);
				fired.push(id);
				numRemaining--;
				
				if (logId != null)
					log('fired $id, $numRemaining remaining');
				
				if (numRemaining == 0)
				{
					if (logId != null)
						log('all callbacks fired');

					callback();
				}
			}
			else
				log('already fired $id');
		}

		unfired[id] = func;

		return func;
	}
	
	inline function log(msg):Void
	{
		if (logId != null)
			trace('$logId: $msg');
	}
	
	public function getFired() return fired.copy();
	public function getUnfired() return [for (id in unfired.keys()) id];
}