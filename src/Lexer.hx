package;

class Lexer {
	var buffer:String;
	var offset:Int;
	var file:String;
	var line:Int;
	var symbols:Array<String>;
	var err:String;
	var errToken:Token;
	var tokens:Array<Token>;
	var typeMap:Map<String, Int>;

	public function new(buffer:String, filename:String) {
		tokens = [];
		err = "";
		errToken = new Token();

		if (buffer == "")
			return;

		// Init vars
		this.buffer = StringTools.replace(buffer, "\r\n", "\n");
		this.buffer = StringTools.replace(this.buffer, "\r", "\n");
		this.offset = 0;
		this.file = filename;
		this.line = 1;

		// Fill types map
		typeMap = new Map<String, Int>();
		typeMap.set("not", TokenType.TOK_NOT);
		typeMap.set("and", TokenType.TOK_AND);
		typeMap.set("or", TokenType.TOK_OR);
		typeMap.set("=", TokenType.TOK_EQUAL);
		typeMap.set("<>", TokenType.TOK_NOTEQUAL);
		typeMap.set(">", TokenType.TOK_GREATER);
		typeMap.set("<", TokenType.TOK_LESSER);
		typeMap.set(">=", TokenType.TOK_GEQUAL);
		typeMap.set("<=", TokenType.TOK_LEQUAL);
		typeMap.set("+", TokenType.TOK_PLUS);
		typeMap.set("-", TokenType.TOK_MINUS);
		typeMap.set("*", TokenType.TOK_MUL);
		typeMap.set("/", TokenType.TOK_DIV);
		typeMap.set("%", TokenType.TOK_MOD);
		typeMap.set(":=", TokenType.TOK_ASSIGN);
		typeMap.set(",", TokenType.TOK_COMMA);
		typeMap.set(":", TokenType.TOK_COLON);
		typeMap.set(";", TokenType.TOK_SEMICOLON);
		typeMap.set("(", TokenType.TOK_OPENPAREN);
		typeMap.set(")", TokenType.TOK_CLOSEPAREN);
		typeMap.set("end", TokenType.TOK_END);
		typeMap.set("if", TokenType.TOK_IF);
		typeMap.set("elseif", TokenType.TOK_ELSEIF);
		typeMap.set("else", TokenType.TOK_ELSE);
		typeMap.set("for", TokenType.TOK_FOR);
		typeMap.set("while", TokenType.TOK_WHILE);
		typeMap.set("var", TokenType.TOK_VAR);
		typeMap.set("function", TokenType.TOK_FUNCTION);
		typeMap.set("Int", TokenType.TOK_INT);
		typeMap.set("Float", TokenType.TOK_FLOAT);
		typeMap.set("String", TokenType.TOK_STRING);
		typeMap.set("Ref", TokenType.TOK_REF);

		// Fill symbols table (multichar ones must appear first)
		symbols = [
			":=", "<>", ">=", "<=", ">", "<", "+", "-", "*", "/", "%", "=", ",", ":", ";", "(", ")"
		];

		// Parse all tokens
		var finish:Bool = false;
		while (!finish) {
			var tok:Token = nextToken();
			if (tok.type == TokenType.TOK_EOF) {
				errToken = tok;
				finish = true;
			} else if (tok.type != TokenType.TOK_EOL || (tokens.length > 0 && !tokens[tokens.length - 1].isStatementEnd())) {
				tokens.push(tok);
			}
		}
	}

	public function getTokens():Array<Token> {
		return tokens;
	}

	public function getErr():String {
		if (err == "") {
			return "";
		} else if (errToken.data != "") {
			return err + " on file '" + errToken.file + "' at line " + errToken.line + ", element '" + errToken.data + "'";
		} else {
			return err + " on file '" + errToken.file + "' at line " + errToken.line;
		}
	}

	public function getErrToken():Token {
		return errToken;
	}

	function nextToken():Token {
		// Skip blank characters
		var skipResult:Token = skipBlank();
		if (skipResult != null)
			return skipResult;

		// Check end of file
		if (offset >= buffer.length) {
			return new Token(TokenType.TOK_EOF, "", file, line);
		}

		// Check numeric literal
		var negNumber:Bool = false;
		if (buffer.charAt(offset) == "-" && offset + 1 < buffer.length && isNumber(buffer.charCodeAt(offset + 1))) {
			negNumber = true;
		}

		if (negNumber || isNumber(buffer.charCodeAt(offset))) {
			var str:String = "";
			if (buffer.charAt(offset) == "-") {
				str = "-";
				offset++;
			}
			while (offset < buffer.length && isNumber(buffer.charCodeAt(offset))) {
				str += buffer.charAt(offset);
				offset++;
			}
			if (offset < buffer.length && buffer.charAt(offset) == ".") {
				// Float
				str += ".";
				offset++;
				if (offset >= buffer.length || !isNumber(buffer.charCodeAt(offset))) {
					err = "Invalid decimal number";
					return new Token(TokenType.TOK_EOF, "", file, line);
				}
				while (offset < buffer.length && isNumber(buffer.charCodeAt(offset))) {
					str += buffer.charAt(offset);
					offset++;
				}
				return new Token(TokenType.TOK_FLOATLITERAL, str, file, line);
			} else {
				// Int
				return new Token(TokenType.TOK_INTLITERAL, str, file, line);
			}
		}

		// Check symbol
		var symbol:String = checkSymbol();
		if (symbol != "") {
			offset += symbol.length;
			return new Token(getType(symbol), symbol, file, line);
		}

		// Check string
		if (buffer.charAt(offset) == '"') {
			var str:String = "";
			offset++; // Skip "
			while (offset < buffer.length - 1 && buffer.charAt(offset) != '"' && buffer.charAt(offset) != "\n") {
				str += buffer.charAt(offset);
				offset++;
			}
			if (offset >= buffer.length || buffer.charAt(offset) != '"') {
				err = "String must be closed";
				return new Token(TokenType.TOK_EOF, "", file, line);
			}
			offset++; // Skip "
			return new Token(TokenType.TOK_STRINGLITERAL, str, file, line);
		}

		// Check keyword or identifier
		if (isAlpha(buffer.charCodeAt(offset))) {
			var str:String = "";
			while (offset < buffer.length && (isAlpha(buffer.charCodeAt(offset)) || isNumber(buffer.charCodeAt(offset)))) {
				str += buffer.charAt(offset);
				offset++;
			}
			return new Token(getType(str), str, file, line);
		}

		// Not recognized
		err = "Unrecognized token";
		return new Token(TokenType.TOK_EOF, buffer.charAt(offset), file, line);
	}

	function skipBlank():Token {
		while (offset < buffer.length
			&& (buffer.charAt(offset) == " " || buffer.charAt(offset) == "\t" || buffer.charAt(offset) == "\n" || isSLComment() || isMLComment())) {
			if (isSLComment()) {
				offset += 2; // Skip //
				while (offset < buffer.length && buffer.charAt(offset) != "\n") {
					offset++;
				}
			}

			if (isMLComment()) {
				offset += 2; // Skip /*
				while (offset < buffer.length - 1 && !(buffer.charAt(offset) == "*" && buffer.charAt(offset + 1) == "/")) {
					if (buffer.charAt(offset) == "\n")
						line++;
					offset++;
				}
				if (offset + 1 >= buffer.length) {
					err = "Comment must be closed";
					return new Token(TokenType.TOK_EOF, "", file, line);
				}
				offset++; // Skip ending *
			}

			var isEol:Bool = false;
			if (offset < buffer.length && buffer.charAt(offset) == "\n") {
				isEol = true;
			}

			if (isEol)
				line++;
			if (offset < buffer.length)
				offset++;

			if (isEol) {
				return new Token(TokenType.TOK_EOL, "\n", file, line - 1);
			}
		}
		return null;
	}

	function isSLComment():Bool {
		return offset < buffer.length - 1 && buffer.charAt(offset) == "/" && buffer.charAt(offset + 1) == "/";
	}

	function isMLComment():Bool {
		return offset < buffer.length - 1 && buffer.charAt(offset) == "/" && buffer.charAt(offset + 1) == "*";
	}

	function isNumber(c:Int):Bool {
		return c >= "0".code && c <= "9".code;
	}

	function isAlpha(c:Int):Bool {
		return c == "_".code || (c >= "A".code && c <= "Z".code) || (c >= "a".code && c <= "z".code);
	}

	function checkSymbol():String {
		for (symbol in symbols) {
			if (offset + symbol.length <= buffer.length) {
				var str:String = buffer.substring(offset, offset + symbol.length);
				if (str == symbol)
					return str;
			}
		}
		return "";
	}

	function getType(symbol:String):Int {
		if (typeMap.exists(symbol)) {
			return typeMap.get(symbol);
		}
		return TokenType.TOK_ID;
	}
}
