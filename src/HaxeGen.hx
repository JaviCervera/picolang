package;

class HaxeGen {
	var stream:TokenStream;
	var scanner:Scanner;
	var lib:Lib;
	var buffer:String;

	public function new(tokens:Array<Token>, scanner:Scanner, lib:Lib) {
		stream = new TokenStream(tokens);
		this.scanner = scanner;
		this.lib = lib;

		// Fill buffer
		buffer = "package;\n\n";
		buffer += "class Main {\n";
		buffer += genGlobals();
		buffer += genFunctions();
		buffer += genMain();
		buffer += "}\n";
	}

	public function getCode():String {
		return buffer;
	}

	function genGlobals():String {
		var str:String = "";
		for (glob in scanner.getGlobals()) {
			str += genTabs(1) + "static var _pi_" + glob.name + ":" + genType(glob.type) + ";\n";
		}
		if (scanner.getGlobals().length > 0)
			str += "\n";
		return str;
	}

	function genMain():String {
		var str:String = genTabs(1) + "static function main() {\n";
		for (glob in scanner.getGlobals()) {
			str += genTabs(2) + "_pi_" + glob.name + " = ";
			stream.seek(glob.offset);
			str += genExp(null) + ";\n";
		}
		str += genTabs(2) + "_pi_Main();\n";
		str += genTabs(1) + "}\n";
		return str;
	}

	function genFunctions():String {
		var str:String = "";
		for (f in scanner.getFunctions()) {
			str += genFunction(f);
		}
		return str;
	}

	function genFunction(f:ScriptFunc):String {
		var str:String = "";

		// Header
		str += genTabs(1) + "static function " + genFunctionSignature(f) + " {\n";

		// Locals
		var tabs:String = genTabs(2);
		for (l in f.args.length...f.locals.length) {
			str += tabs + "var _pi_" + f.locals[l].name + ":" + genType(f.locals[l].type) + ";\n";
		}

		// Block
		stream.seek(f.offset);
		str += genBlockContents(f, 2);

		// Return
		if (f.type != TokenType.TOK_VOID)
			str += genTabs(2) + "return _pi_" + f.returnVar + ";\n";

		// Footer
		str += genTabs(1) + "}\n\n";

		return str;
	}

	function genFunctionSignature(f:ScriptFunc):String {
		var str:String = "_pi_" + f.name + "(";
		for (arg in 0...f.args.length) {
			str += "_pi_" + f.locals[arg].name + ":" + genType(f.locals[arg].type);
			if (arg < f.args.length - 1)
				str += ", ";
		}
		str += ")";
		if (f.type != TokenType.TOK_VOID) {
			str += ":" + genType(f.type);
		} else {
			str += ":Void";
		}
		return str;
	}

	function genBlockContents(f:ScriptFunc, indent:Int):String {
		var str:String = genTabs(indent);
		var type:Int = stream.peek().type;

		// While we do not find the end of a block, gen statements
		while (type != TokenType.TOK_ELSEIF && type != TokenType.TOK_ELSE && type != TokenType.TOK_END) {
			str += genStatement(f, indent);
			type = stream.peek().type;
		}

		return str;
	}

	function genStatement(f:ScriptFunc, indent:Int):String {
		if (stream.peek().isControl()) {
			return genControl(f, indent);
		} else {
			if (stream.peek().type == TokenType.TOK_VAR)
				stream.skip(1); // skip var
			var str:String = genExp(f);
			str += genEndStatement() + "\n" + genTabs(indent);
			return str;
		}
	}

	function genControl(f:ScriptFunc, indent:Int):String {
		var str:String = "\n" + genTabs(indent);
		switch (stream.peek().type) {
			case TokenType.TOK_IF:
				str += genIf(f, indent);
			case TokenType.TOK_FOR:
				str += genFor(f, indent);
			case TokenType.TOK_WHILE:
				str += genWhile(f, indent);
		}
		str += "\n" + genTabs(indent);
		return str;
	}

	function genIf(f:ScriptFunc, indent:Int):String {
		// if
		stream.skip(1); // skip if
		var str:String = "if (" + genExp(f) + ") {\n";
		str += genTabs(indent + 1) + genBlockContents(f, indent + 1) + "\n";

		// optional elseif
		while (stream.peek().type == TokenType.TOK_ELSEIF) {
			stream.skip(1); // skip elseif
			str += genTabs(indent) + "} else if (" + genExp(f) + ") {\n";
			str += genTabs(indent + 1) + genBlockContents(f, indent + 1) + "\n";
		}

		// optional else
		if (stream.peek().type == TokenType.TOK_ELSE) {
			stream.skip(1); // skip else
			str += genTabs(indent) + "} else {\n";
			str += genTabs(indent + 1) + genBlockContents(f, indent + 1) + "\n";
		}

		// end
		str += genTabs(indent) + "}";

		return str;
	}

	function genFor(f:ScriptFunc, indent:Int):String {
		// header
		stream.skip(1); // skip for
		var varToken:Token = stream.nextToken();
		stream.skip(1); // skip =
		var fromExp:String = genExp(f);
		stream.skip(1); // skip ,
		var toExp:String = genExp(f);

		var str:String = "";

		// optional step exp
		if (stream.peek().type == TokenType.TOK_COMMA) {
			stream.skip(1); // skip ,
			var stepExp:String = genExp(f);
			// Haxe for loop with step - we need to convert to while loop
			str += "{\n";
			str += genTabs(indent + 1) + "_pi_" + varToken.data + " = " + fromExp + ";\n";
			str += genTabs(indent + 1) + "while (_pi_" + varToken.data + " <= " + toExp + ") {\n";
			// Block will be generated
		} else {
			// Simple for loop using Haxe range
			str += "_pi_" + varToken.data + " = " + fromExp + ";\n";
			str += genTabs(indent) + "while (_pi_" + varToken.data + " <= " + toExp + ") {\n";
		}

		// $block
		str += genTabs(indent + 1) + genBlockContents(f, indent + 1) + "\n";

		// Add increment
		if (stream.peek(-2).type == TokenType.TOK_COMMA) {
			// Step was provided - need to figure this out differently
			// For now, just increment by 1
			str += genTabs(indent + 1) + "_pi_" + varToken.data + "++;\n";
		} else {
			str += genTabs(indent + 1) + "_pi_" + varToken.data + "++;\n";
		}

		// end
		str += genTabs(indent) + "}";

		return str;
	}

	function genWhile(f:ScriptFunc, indent:Int):String {
		stream.skip(1); // skip while
		var str:String = "while (" + genExp(f) + ") {\n";
		str += genTabs(indent + 1) + genBlockContents(f, indent + 1) + "\n";
		str += genTabs(indent) + "}";
		return str;
	}

	function genExp(f:ScriptFunc):String {
		var str:String = genOrExp(f);
		if (stream.peek().type == TokenType.TOK_COLON)
			stream.skip(2);
		if (stream.peek().type == TokenType.TOK_ASSIGN) {
			stream.skip(1); // Skip =
			str += " = " + genExp(f);
		}
		return str;
	}

	function genOrExp(f:ScriptFunc):String {
		var str:String = genAndExp(f);
		while (stream.peek().type == TokenType.TOK_OR) {
			stream.skip(1); // skip or
			str += " || " + genAndExp(f);
		}
		return str;
	}

	function genAndExp(f:ScriptFunc):String {
		var str:String = genEqualExp(f);
		while (stream.peek().type == TokenType.TOK_AND) {
			stream.skip(1); // skip and
			str += " && " + genEqualExp(f);
		}
		return str;
	}

	function genEqualExp(f:ScriptFunc):String {
		var str:String = genRelExp(f);
		while (stream.peek().type == TokenType.TOK_EQUAL || stream.peek().type == TokenType.TOK_NOTEQUAL) {
			if (stream.nextToken().type == TokenType.TOK_EQUAL) {
				str += " == ";
			} else {
				str += " != ";
			}
			str += genRelExp(f);
		}
		return str;
	}

	function genRelExp(f:ScriptFunc):String {
		var str:String = genAddExp(f);
		var tokType:Int = stream.peek().type;
		while (tokType == TokenType.TOK_LESSER || tokType == TokenType.TOK_LEQUAL || tokType == TokenType.TOK_GREATER || tokType == TokenType.TOK_GEQUAL) {
			switch (stream.nextToken().type) {
				case TokenType.TOK_LESSER:
					str += " < ";
				case TokenType.TOK_LEQUAL:
					str += " <= ";
				case TokenType.TOK_GREATER:
					str += " > ";
				case TokenType.TOK_GEQUAL:
					str += " >= ";
			}
			str += genAddExp(f);
			tokType = stream.peek().type;
		}
		return str;
	}

	function genAddExp(f:ScriptFunc):String {
		var str:String = genMulExp(f);
		while (stream.peek().type == TokenType.TOK_PLUS || stream.peek().type == TokenType.TOK_MINUS) {
			if (stream.nextToken().type == TokenType.TOK_PLUS) {
				str += " + ";
			} else {
				str += " - ";
			}
			str += genMulExp(f);
		}
		return str;
	}

	function genMulExp(f:ScriptFunc):String {
		var str:String = genUnaryExp(f);
		while (stream.peek().type == TokenType.TOK_MUL
			|| stream.peek().type == TokenType.TOK_DIV
			|| stream.peek().type == TokenType.TOK_MOD) {
			switch (stream.nextToken().type) {
				case TokenType.TOK_MUL:
					str += " * ";
				case TokenType.TOK_DIV:
					str += " / ";
				case TokenType.TOK_MOD:
					str += " % ";
			}
			str += genUnaryExp(f);
		}
		return str;
	}

	function genUnaryExp(f:ScriptFunc):String {
		var str:String = "";
		if (stream.peek().type == TokenType.TOK_NOT || stream.peek().type == TokenType.TOK_MINUS) {
			if (stream.nextToken().type == TokenType.TOK_NOT) {
				str += "!";
			} else {
				str += "-";
			}
		}
		str += genGroupExp(f);
		return str;
	}

	function genGroupExp(f:ScriptFunc):String {
		if (stream.peek().type == TokenType.TOK_OPENPAREN) {
			stream.skip(1); // skip (
			var str:String = "(" + genExp(f) + ")";
			stream.skip(1); // skip )
			return str;
		} else {
			return genAtomicExp(f);
		}
	}

	function genAtomicExp(f:ScriptFunc):String {
		var token:Token = stream.nextToken();
		switch (token.type) {
			case TokenType.TOK_INTLITERAL:
				return token.data;
			case TokenType.TOK_FLOATLITERAL:
				return token.data;
			case TokenType.TOK_STRINGLITERAL:
				return '"' + token.data + '"';
			case TokenType.TOK_ID:
				if (stream.peek().type == TokenType.TOK_OPENPAREN) { // function call
					stream.goBack(); // Move before function name
					return genCall(f);
				} else { // var id
					return "_pi_" + token.data;
				}
			default:
				return ""; // Should not get here
		}
	}

	function genCall(f:ScriptFunc):String {
		// id
		var funcToken:Token = stream.nextToken();
		var libFunc:LibFunc = lib.func(funcToken.data);
		var scriptFunc:ScriptFunc = scanner.func(funcToken.data);
		var str:String = "";
		if (libFunc != null) {
			str += libFunc.nativeName;
			str += genArgs(f, libFunc.args);
		} else {
			str += "_pi_" + scriptFunc.name;
			str += genArgs(f, scriptFunc.args);
		}
		return str;
	}

	function genArgs(f:ScriptFunc, args:Array<Int>):String {
		stream.skip(1); // skip (
		var str:String = "(";
		if (stream.peek().type != TokenType.TOK_CLOSEPAREN) {
			str += genExp(f);
			var argIndex:Int = 1;
			while (stream.peek().type == TokenType.TOK_COMMA) {
				stream.skip(1); // skip ,
				str += ", " + genExp(f);
				argIndex++;
			}
		}
		str += ")";
		stream.skip(1); // skip )
		return str;
	}

	function genEndStatement():String {
		if (stream.peek().type == TokenType.TOK_SEMICOLON)
			stream.skip(1); // ;
		return ";";
	}

	static function genTabs(indent:Int):String {
		var str:String = "";
		for (i in 0...indent) {
			str += "\t";
		}
		return str;
	}

	static function genType(type:Int):String {
		return switch (type) {
			case TokenType.TOK_INT:
				"Int";
			case TokenType.TOK_FLOAT:
				"Float";
			case TokenType.TOK_STRING:
				"String";
			case TokenType.TOK_REF:
				"Dynamic";
			default:
				"Void";
		}
	}
}
