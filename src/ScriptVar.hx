package;

class ScriptVar {
	public var name:String;
	public var type:Int;
	public var offset:Int;

	public function new(name:String, type:Int, offset:Int) {
		this.name = name;
		this.type = type;
		this.offset = offset;
	}
}
