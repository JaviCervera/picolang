package;

class Lib {
	var functions:Array<LibFunc>;

	public function new() {
		functions = [];
	}

	public function addFunc(realName:String, type:Int, args:Array<Int>):Void {
		var picoName:String = realName;
		var findPos:Int = picoName.indexOf("<");
		if (findPos != -1) {
			picoName = picoName.substring(0, findPos);
		}
		functions.push(new LibFunc(picoName, realName, type, args));
	}

	public function numFuncs():Int {
		return functions.length;
	}

	public function funcAt(index:Int):LibFunc {
		if (index >= 0 && index < functions.length) {
			return functions[index];
		}
		return null;
	}

	public function func(name:String):LibFunc {
		for (f in functions) {
			if (f.name == name)
				return f;
		}
		return null;
	}
}
