using haxe.io.Path;
using StringTools;

class Core {
	// Console
	public static function input(prompt:String):String {
		return Sys.stdin().readLine();
	}

	public static function print(msg:String):Void {
		Sys.println(msg);
	}

	// Dir

	public static function dirContents(path:String):Array<String> {
		return sys.FileSystem.readDirectory(path);
	}

	public static function currentDir():String {
		return Sys.getCwd();
	}

	public static function changeDir(dir:String):Void {
		Sys.setCwd(dir);
	}

	public static function fullPath(filename:String):String {
		return sys.FileSystem.absolutePath(filename);
	}

	// File

	public static function fileType(filename:String):Int {
		if (!sys.FileSystem.exists(filename)) {
			return 0;
		}
		if (sys.FileSystem.isDirectory(filename)) {
			return 2;
		}
		return 1;
	}

	public static function deleteFile(filename:String):Void {
		try {
			sys.FileSystem.deleteFile(filename);
		} catch (_) {}
	}

	// Math

	public static function asin(x:Float):Float {
		return Math.asin(x);
	}

	public static function atan(x:Float):Float {
		return Math.atan(x);
	}

	public static function atan2(y:Float, x:Float):Float {
		return Math.atan2(y, x);
	}

	public static function abs(x:Float):Float {
		return Math.abs(x);
	}

	public static function ceil(x:Float):Float {
		return Math.ceil(x);
	}

	public static function clamp(x:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(x, max));
	}

	public static function cos(x:Float):Float {
		return Math.cos(x);
	}

	public static function exp(x:Float):Float {
		return Math.exp(x);
	}

	public static function floor(x:Float):Float {
		return Math.floor(x);
	}

	public static function log(x:Float):Float {
		return Math.log(x);
	}

	public static function max(x:Float, y:Float):Float {
		return Math.max(x, y);
	}

	public static function min(x:Float, y:Float):Float {
		return Math.min(x, y);
	}

	public static function pow(x:Float, y:Float):Float {
		return Math.pow(x, y);
	}

	public static function sgn(x:Float):Float {
		return (x > 0) ? 1 : (x == 0) ? 0 : -1;
	}

	public static function sin(x:Float):Float {
		return Math.sin(x);
	}

	public static function sqrt(x:Float):Float {
		return Math.sqrt(x);
	}

	public static function tan(x:Float):Float {
		return Math.tan(x);
	}

	public static function int(num:Float):Float {
		return Std.int(num);
	}

	// String

	public static function len(str:String):Int {
		return str.length;
	}

	public static function left(str:String, count:Int):String {
		return str.substr(0, count);
	}

	public static function right(str:String, count:Int):String {
		return str.substr(str.length - count);
	}

	public static function mid(str:String, offset:Int, count:Int):String {
		return str.substr(offset, count);
	}

	public static function lower(str:String):String {
		return str.toLowerCase();
	}

	public static function upper(str:String):String {
		return str.toUpperCase();
	}

	public static function find(str:String, find:String, offset:Int):Int {
		return str.indexOf(find, offset);
	}

	public static function replace(str:String, find:String, replace:String):String {
		return str.replace(find, replace);
	}

	public static function trim(str:String):String {
		return str.trim();
	}

	public static function join(elems:Array<String>, separator:String):String {
		return elems.join(separator);
	}

	public static function split(str:String, separator:String):Array<String> {
		return str.split(separator);
	}

	public static function stripExt(filename:String):String {
		return filename.withoutExtension();
	}

	public static function stripDir(filename:String):String {
		return filename.withoutDirectory();
	}

	public static function extractExt(filename:String):String {
		return filename.extension();
	}

	public static function extractDir(filename:String):String {
		return filename.directory();
	}

	public static function codepoint(str:String, index:Int):Int {
		final code = str.charCodeAt(index);
		return (code != null) ? code : -1;
	}

	public static function chr(c:Int):String {
		return String.fromCharCode(c);
	}

	public static function str(val:Int):String {
		return Std.string(val);
	}

	public static function strF(val:Float):String {
		return Std.string(val);
	}

	public static function val(str:String):Int {
		return Std.parseInt(str);
	}

	public static function valF(str:String):Float {
		return Std.parseFloat(str);
	}

	public static function loadString(filename:String):String {
		try {
			return sys.io.File.getContent(filename);
		} catch (e) {
			return "";
		}
	}

	public static function saveString(filename:String, str:String, append:Bool):Void {
		final previous = append ? loadString(filename) : "";
		sys.io.File.saveContent(filename, previous + str);
	}
}
