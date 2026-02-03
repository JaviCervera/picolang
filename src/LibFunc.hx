package;

class LibFunc {
	public var name:String;
	public var nativeName:String;
	public var type:Int;
	public var args:Array<Int>;

	public function new(name:String, nativeName:String, type:Int, args:Array<Int>) {
		this.name = name;
		this.nativeName = nativeName;
		this.type = type;
		this.args = args;
	}
}
