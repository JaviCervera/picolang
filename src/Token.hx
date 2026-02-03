package;

class Token {
	public var type:Int;
	public var data:String;
	public var file:String;
	public var line:Int;

	public function new(?type:Int = 0, ?data:String = "", ?file:String = "", ?line:Int = 0) {
		this.type = type;
		this.data = data;
		this.file = file;
		this.line = line;
	}

	public function isControl():Bool {
		return Token.isControlStatic(type);
	}

	public function isBooleanOp():Bool {
		return Token.isBooleanOpStatic(type);
	}

	public function isRelationalOp():Bool {
		return Token.isRelationalOpStatic(type);
	}

	public function isAdditiveOp():Bool {
		return Token.isAdditiveOpStatic(type);
	}

	public function isMultiplicativeOp():Bool {
		return Token.isMultiplicativeOpStatic(type);
	}

	public function isUnaryOp():Bool {
		return Token.isUnaryOpStatic(type);
	}

	public function isType():Bool {
		return Token.isTypeStatic(type);
	}

	public function isStatementEnd():Bool {
		return Token.isStatementEndStatic(type);
	}

	public static function isControlStatic(type:Int):Bool {
		return type == TokenType.TOK_IF || type == TokenType.TOK_FOR || type == TokenType.TOK_WHILE;
	}

	public static function isBooleanOpStatic(type:Int):Bool {
		return type == TokenType.TOK_AND || type == TokenType.TOK_OR;
	}

	public static function isRelationalOpStatic(type:Int):Bool {
		return type >= TokenType.TOK_EQUAL && type <= TokenType.TOK_LEQUAL;
	}

	public static function isAdditiveOpStatic(type:Int):Bool {
		return type == TokenType.TOK_PLUS || type == TokenType.TOK_MINUS;
	}

	public static function isMultiplicativeOpStatic(type:Int):Bool {
		return type == TokenType.TOK_MUL || type == TokenType.TOK_DIV || type == TokenType.TOK_MOD;
	}

	public static function isUnaryOpStatic(type:Int):Bool {
		return type == TokenType.TOK_NOT || type == TokenType.TOK_MINUS;
	}

	public static function isTypeStatic(type:Int):Bool {
		return type <= TokenType.TOK_INT && type >= TokenType.TOK_REF;
	}

	public static function isStatementEndStatic(type:Int):Bool {
		return type == TokenType.TOK_EOL || type == TokenType.TOK_SEMICOLON;
	}
}
