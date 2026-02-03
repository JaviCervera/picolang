package;

class TokenUtils {
	public static function areCompatible(type1:Int, type2:Int):Bool {
		if (type1 == type2 && type1 != TokenType.TOK_VOID) {
			return true;
		} else if (type1 == TokenType.TOK_INT && type2 == TokenType.TOK_FLOAT) {
			return true;
		} else if (type1 == TokenType.TOK_FLOAT && type2 == TokenType.TOK_INT) {
			return true;
		}
		return false;
	}

	public static function balanceTypes(type1:Int, type2:Int):Int {
		if (type1 == type2) {
			return type1;
		} else if (type1 == TokenType.TOK_INT && type2 == TokenType.TOK_FLOAT) {
			return TokenType.TOK_FLOAT;
		} else if (type1 == TokenType.TOK_FLOAT && type2 == TokenType.TOK_INT) {
			return TokenType.TOK_FLOAT;
		}
		return TokenType.TOK_VOID;
	}
}
