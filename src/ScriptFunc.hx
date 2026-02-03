package;

class ScriptFunc {
	public var name:String;
	public var type:Int;
	public var args:Array<Int>;
	public var locals:Array<ScriptVar>;
	public var offset:Int;
	public var returnVar:String;

	public function new(name:String, type:Int, args:Array<Int>) {
		this.name = name;
		this.type = type;
		this.args = args;
		this.locals = [];
		this.offset = 0;
		this.returnVar = "";
	}

	public function getLocal(name:String):ScriptVar {
		for (l in locals) {
			if (l.name == name)
				return l;
		}
		return null;
	}
}
