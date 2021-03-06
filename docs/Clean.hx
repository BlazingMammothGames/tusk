import sys.FileSystem;

class Clean {
	public static function run() {
		var files:Array<String> = [
			"all.js", "haxe.xml", "js.xml"
		];
		trace("Cleaning files: " + files);
		for(file in files) {
			try {
				FileSystem.deleteFile(file);
			}
			catch(exc:String) {
				trace(exc);
			}
		}
	}
}