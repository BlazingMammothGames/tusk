package tusk.modules;

import tusk.debug.Log;

/**
 * Responsible for loading, unloading, and playing sounds in tusk
 */
class Sound {
	private var tusk:Tusk;

	@:allow(tusk.Tusk)
	private function new(tusk:Tusk) {
		this.tusk = tusk;
	}

	/**
	 * Loads a sound, and alerts a callback when it has loaded
	 * @param  path            the relative filename of the sound to load
	 * @param  onLoadComplete  a callback of the form `Void->Void` which takes the sound ID and is called
	 *                         when the sound has finished loading
	 */
	@:allow(tusk.modules.Assets)
    #if snow
    private function load(path:String, onLoadComplete:snow.system.audio.Sound->Void, onError:snow.system.audio.Sound->Void) {
		tusk.app.audio.create(path, path)
			.then(function(sound:snow.system.audio.Sound) {
				Log.trace("Loaded sound: " + path);
				onLoadComplete(sound);
			}, function(sound:snow.system.audio.Sound) {
				//Log.error("Failed to load sound: " + path);
				onError(sound);
			});
    }
    #else
    private function load(path:String, onLoadComplete:Dynamic->Void, onError:Dynamic->Void){}
	#end

    /**
     * Plays a loaded sound
     * @param  id the string-based ID of the sound
     */
    public function play(sound:tusk.resources.Sound) {
    	#if snow
        tusk.app.audio.play(sound.id);
        #end
    }
}