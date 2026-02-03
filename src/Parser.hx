package;

class Parser {
	static inline var EXP_NORMAL:Int = 0;
	static inline var EXP_CONDITIONAL:Int = 1;

	var stream:TokenStream;
	var scanner:Scanner;
	var lib:Lib;
	var err:String;
	var errToken:Token;

	public function new(tokens:Array<Token>, lib:Lib) {
		stream = new TokenStream(tokens);
		scanner = new Scanner(tokens);
		this.lib = lib;
		err = "";
		errToken = new Token();

		// Scan
		scanner.scanDefs();

		// Parse
		while (stream.hasNext() && err == "") {
			// Global
			if (stream.peek().type == TokenType.TOK_VAR) {
				parseVarDecl();
			}
			// Function
			else if (stream.peek().type == TokenType.TOK_FUNCTION) {
				parseFunction();
			}
			// Unexpected token
			else {
				err = "Unexpected element";
				errToken = new Token(TokenType.TOK_EOF, stream.peek().data, stream.peek().file, stream.peek().line);
			}
		}
	}

	public function getErr():String {
		if (err == "") {
			return "";
		} else {
			return err + " on file '" + errToken.file + "' at line " + errToken.line + ", element '" + errToken.data + "'";
		}
	}

	public function getScanner():Scanner {
		return scanner;
	}

	// function id $args [colon type] $block end
	function parseFunction():Void {
		// function
		stream.skip(1);

		// id
		var nameToken:Token = parseId();
		var func:ScriptFunc = scanner.func(nameToken.data);

		// Scan for params and locals
		scanner.scanLocals(stream.getPos());

		// $args
		parseArgs();
		if (err != "")
			return;

		// colon type
		var hasType:Bool = false;
		if (stream.peek().type == TokenType.TOK_COLON) {
			hasType = true;
			stream.skip(1); // colon
			if (!stream.peek().isType()) {
				err = "Expected type";
				errToken = stream.nextToken();
				return;
			}
			stream.skip(1); // type
		}

		// $block
		var offset:Int = stream.getPos();
		parseBlock(func);
		if (err != "")
			return;

		// end
		parseEnd();
		if (err != "")
			return;

		// Parse return var
		if (hasType) {
			var returnTok:Token = stream.nextToken();
			if (returnTok.type != TokenType.TOK_ID) {
				err = "Expected return variable";
				errToken = returnTok;
				return;
			}
			if (!scanner.isVar(returnTok.data)) {
				err = "Return value must be a variable";
				errToken = returnTok;
				return;
			}
			if (!TokenUtils.areCompatible(scanner.getVar(returnTok.data).type, func.type)) {
				err = "Incompatible type in return variable";
				errToken = returnTok;
			}
			func.returnVar = returnTok.data;
		}

		// Set function offset and locals
		func.offset = offset;
		func.locals = scanner.getLocals().copy();
	}

	// openparen [id colon type *[comma id colon type]] closeparen
	function parseArgs():Void {
		// openparen
		if (stream.peek().type != TokenType.TOK_OPENPAREN) {
			err = "Expected '('";
			errToken = stream.nextToken();
			return;
		}
		stream.skip(1);

		// [id colon type *[comma id colon type]]
		while (stream.peek().type == TokenType.TOK_ID) {
			// id
			var nameToken:Token = parseId();
			if (err != "")
				return;

			// colon
			if (stream.peek().type != TokenType.TOK_COLON) {
				err = "Expected ':'";
				errToken = stream.nextToken();
				return;
			}
			stream.skip(1); // colon

			// type
			if (!stream.peek().isType()) {
				err = "Expected type";
				errToken = stream.nextToken();
				return;
			}
			stream.skip(1); // type

			// comma
			if (stream.peek().type == TokenType.TOK_COMMA)
				stream.skip(1);
		}

		// closeparen
		if (stream.peek().type != TokenType.TOK_CLOSEPAREN) {
			err = "Expected ')'";
			errToken = stream.nextToken();
			return;
		}
		stream.skip(1);
	}

	// *[$statement]
	function parseBlock(f:ScriptFunc):Void {
		// While we do not find the end of a block, parse statements
		var type:Int = stream.peek().type;
		while (err == "" && type != TokenType.TOK_ELSEIF && type != TokenType.TOK_ELSE && type != TokenType.TOK_END && type != TokenType.TOK_EOF) {
			parseStatement(f);
			if (stream.hasNext())
				type = stream.peek().type;
		}
	}

	// $local | $control | ($expression endst)
	function parseStatement(f:ScriptFunc):Void {
		if (stream.peek().type == TokenType.TOK_VAR) {
			parseVarDecl();
		} else if (stream.peek().isControl()) {
			parseControl(f);
		} else {
			parseExp(EXP_NORMAL);
			if (err != "")
				return;
			parseEndStatement();
		}
	}

	// var id colon type assign $block endst
	function parseVarDecl():Void {
		// var
		stream.skip(1);

		// id
		parseId();
		if (err != "")
			return;

		// colon
		if (stream.peek().type != TokenType.TOK_COLON) {
			err = "Expected ':'";
			errToken = stream.nextToken();
			return;
		}
		stream.skip(1);

		// type
		var typeToken:Token = stream.nextToken();
		if (!typeToken.isType()) {
			err = "Expected type";
			errToken = typeToken;
			return;
		}

		// assign
		if (stream.peek().type != TokenType.TOK_ASSIGN) {
			err = "Expected '='";
			errToken = stream.nextToken();
			return;
		}
		stream.skip(1);

		// $exp
		var expToken:Token = stream.peek();
		var type:Int = parseExp(EXP_NORMAL);
		if (err != "")
			return;

		// Check type compatibility
		if (!TokenUtils.areCompatible(type, typeToken.type)) {
			err = "Incompatible types";
			errToken = expToken;
			return;
		}

		// endst
		parseEndStatement();
	}

	// $if | $for | $while
	function parseControl(f:ScriptFunc):Void {
		var type:Int = stream.peek().type;
		switch (type) {
			case TokenType.TOK_IF:
				parseIf(f);
			case TokenType.TOK_FOR:
				parseFor(f);
			case TokenType.TOK_WHILE:
				parseWhile(f);
		}
	}

	// if $exp $block *[elif $exp $block] [else $block] end
	function parseIf(f:ScriptFunc):Void {
		// if
		stream.skip(1);

		// $exp
		parseExp(EXP_CONDITIONAL);
		if (err != "")
			return;

		// $block
		parseBlock(f);
		if (err != "")
			return;

		// *[elif $exp $block]
		while (stream.peek().type == TokenType.TOK_ELSEIF) {
			// elif
			stream.skip(1);

			// $exp
			parseExp(EXP_CONDITIONAL);
			if (err != "")
				return;

			// $block
			parseBlock(f);
			if (err != "")
				return;
		}

		// [else $block]
		if (stream.peek().type == TokenType.TOK_ELSE) {
			// else
			stream.skip(1);

			// $block
			parseBlock(f);
			if (err != "")
				return;
		}

		// end
		parseEnd();
	}

	// for id assign $expression comma $expression [comma $expression] $block end
	function parseFor(f:ScriptFunc):Void {
		// for
		stream.skip(1);

		// id
		if (stream.peek().type != TokenType.TOK_ID) {
			err = "Expected variable";
			errToken = stream.nextToken();
			return;
		}
		stream.skip(1); // id

		// assign
		if (stream.peek().type != TokenType.TOK_ASSIGN) {
			err = "Expected '='";
			errToken = stream.nextToken();
			return;
		}
		stream.skip(1); // =

		// $expression
		parseExp(EXP_CONDITIONAL);
		if (err != "")
			return;

		// comma
		if (stream.peek().type != TokenType.TOK_COMMA) {
			err = "Expected ','";
			errToken = stream.nextToken();
			return;
		}
		stream.skip(1); // ,

		// $expression
		parseExp(EXP_CONDITIONAL);
		if (err != "")
			return;

		// [comma $expression]
		if (stream.peek().type == TokenType.TOK_COMMA) {
			// comma
			stream.skip(1);

			// $expression
			parseExp(EXP_CONDITIONAL);
			if (err != "")
				return;
		}

		// $block
		parseBlock(f);
		if (err != "")
			return;

		// end
		parseEnd();
	}

	// while $expression $block end
	function parseWhile(f:ScriptFunc):Void {
		// while
		stream.skip(1);

		// $expression
		parseExp(EXP_CONDITIONAL);
		if (err != "")
			return;

		// $block
		parseBlock(f);
		if (err != "")
			return;

		// end
		parseEnd();
	}

	// $assignexp | $orexp
	function parseExp(type:Int):Int {
		if (type == EXP_NORMAL) {
			return parseAssignExp(type);
		} else {
			return parseOrExp(type);
		}
	}

	// $orexp [assign $assignexp]
	function parseAssignExp(type_:Int):Int {
		// $orexp
		var type:Int = parseOrExp(type_);
		if (err != "")
			return TokenType.TOK_VOID;

		// assign
		if (stream.peek().type == TokenType.TOK_ASSIGN) {
			var token:Token = stream.nextToken();

			// $assignexp
			var type2:Int = parseAssignExp(type_);
			if (err != "")
				return TokenType.TOK_VOID;

			// Check type compatibility
			if (!TokenUtils.areCompatible(type, type2)) {
				err = "Incompatible types";
				errToken = token;
				return TokenType.TOK_VOID;
			}

			type = TokenUtils.balanceTypes(type, type2);
		}

		return type;
	}

	// $andexp *[or $andexp]
	function parseOrExp(type_:Int):Int {
		// $andexp
		var type:Int = parseAndExp(type_);
		if (err != "")
			return TokenType.TOK_VOID;

		// *[or $andexp]
		while (stream.peek().type == TokenType.TOK_OR) {
			if (!TokenUtils.areCompatible(type, TokenType.TOK_INT)) {
				err = "Cannot use in boolean expression";
				errToken = stream.nextToken();
				return TokenType.TOK_VOID;
			}

			// or
			var orToken:Token = stream.nextToken();

			// $andexp
			var type2:Int = parseAndExp(type_);
			if (err != "")
				return TokenType.TOK_VOID;

			// Check type compatibility
			if (!TokenUtils.areCompatible(type, type2)) {
				err = "Incompatible types";
				errToken = orToken;
				return TokenType.TOK_VOID;
			}

			type = TokenUtils.balanceTypes(type, type2);
		}

		return type;
	}

	// $equalexp *[and $equalexp]
	function parseAndExp(type_:Int):Int {
		// $equalexp
		var type:Int = parseEqualExp(type_);
		if (err != "")
			return TokenType.TOK_VOID;

		// *[and $equalexp]
		while (stream.peek().type == TokenType.TOK_AND) {
			if (!TokenUtils.areCompatible(type, TokenType.TOK_INT)) {
				err = "Cannot use in boolean expression";
				errToken = stream.nextToken();
				return TokenType.TOK_VOID;
			}

			// and
			var andToken:Token = stream.nextToken();

			// $equalexp
			var type2:Int = parseEqualExp(type_);
			if (err != "")
				return TokenType.TOK_VOID;

			// Check type compatibility
			if (!TokenUtils.areCompatible(type, type2)) {
				err = "Incompatible types";
				errToken = andToken;
				return TokenType.TOK_VOID;
			}

			type = TokenUtils.balanceTypes(type, type2);
		}

		return type;
	}

	// $relexp *[equal | notequal $relexp]
	function parseEqualExp(type_:Int):Int {
		// $relexp
		var type:Int = parseRelExp(type_);
		if (err != "")
			return TokenType.TOK_VOID;

		// *[equal | notequal $relexp]
		while (stream.peek().type == TokenType.TOK_EQUAL || stream.peek().type == TokenType.TOK_NOTEQUAL) {
			// equal | notequal
			var token:Token = stream.nextToken();

			// $relexp
			var type2:Int = parseRelExp(type_);
			if (err != "")
				return TokenType.TOK_VOID;

			// Check type compatibility
			if (!TokenUtils.areCompatible(type, type2)) {
				err = "Incompatible types";
				errToken = token;
				return TokenType.TOK_VOID;
			}

			type = TokenType.TOK_INT;
		}

		return type;
	}

	// $addexp *[lesser | lequal | greater | gequal $addexp]
	function parseRelExp(type_:Int):Int {
		// $addexp
		var type:Int = parseAddExp(type_);
		if (err != "")
			return TokenType.TOK_VOID;

		// *[lesser | lequal | greater | gequal $addexp]
		var tokType:Int = stream.peek().type;
		while (tokType == TokenType.TOK_LESSER || tokType == TokenType.TOK_LEQUAL || tokType == TokenType.TOK_GREATER || tokType == TokenType.TOK_GEQUAL) {
			// lesser | lequal | greater | gequal
			var token:Token = stream.nextToken();

			// $addexp
			var type2:Int = parseAddExp(type_);
			if (err != "")
				return TokenType.TOK_VOID;

			// Check type compatibility
			if (!TokenUtils.areCompatible(type, type2)) {
				err = "Incompatible types";
				errToken = token;
				return TokenType.TOK_VOID;
			}

			type = TokenType.TOK_INT;

			tokType = stream.peek().type;
		}

		return type;
	}

	// $mulexp *[plus | minus $mulexp]
	function parseAddExp(type_:Int):Int {
		// $mulexp
		var type:Int = parseMulExp(type_);
		if (err != "")
			return TokenType.TOK_VOID;

		// *[plus | minus $mulexp]
		while (stream.peek().type == TokenType.TOK_PLUS || stream.peek().type == TokenType.TOK_MINUS) {
			// plus | minus
			var token:Token = stream.nextToken();

			// $mulexp
			var type2:Int = parseMulExp(type_);
			if (err != "")
				return TokenType.TOK_VOID;

			// Check type compatibility
			if (!TokenUtils.areCompatible(type, type2)) {
				err = "Incompatible types";
				errToken = token;
				return TokenType.TOK_VOID;
			}

			type = TokenUtils.balanceTypes(type, type2);
		}

		return type;
	}

	// $unaryexp *[mul | div | mod $unaryexp]
	function parseMulExp(type_:Int):Int {
		// $unaryexp
		var type:Int = parseUnaryExp(type_);
		if (err != "")
			return TokenType.TOK_VOID;

		// *[mul | div | mod $unaryexp]
		while (stream.peek().type == TokenType.TOK_MUL
			|| stream.peek().type == TokenType.TOK_DIV
			|| stream.peek().type == TokenType.TOK_MOD) {
			// mul | div | mod
			var token:Token = stream.nextToken();

			// $unaryexp
			var type2:Int = parseUnaryExp(type_);
			if (err != "")
				return TokenType.TOK_VOID;

			// Check type compatibility
			if (!TokenUtils.areCompatible(type, type2)) {
				err = "Incompatible types";
				errToken = token;
				return TokenType.TOK_VOID;
			}

			type = TokenUtils.balanceTypes(type, type2);
		}

		return type;
	}

	// [not | minus] $groupexp
	function parseUnaryExp(type_:Int):Int {
		// not | minus
		var token:Token = null;
		var hasUnary:Bool = false;
		if (stream.peek().type == TokenType.TOK_NOT || stream.peek().type == TokenType.TOK_MINUS) {
			token = stream.nextToken();
			hasUnary = true;
		}

		// $groupexp
		var type:Int = parseGroupExp(type_);
		if (hasUnary && type != TokenType.TOK_INT && type != TokenType.TOK_FLOAT) {
			err = "Incompatible types";
			errToken = token;
			return TokenType.TOK_VOID;
		}
		return type;
	}

	// (openparen $expression closeparen) | $atomicexp
	function parseGroupExp(type_:Int):Int {
		// (openparen $expression closeparen)
		if (stream.peek().type == TokenType.TOK_OPENPAREN) {
			// openparen
			stream.skip(1);

			// $expression
			var type:Int = parseExp(type_);
			if (err != "")
				return TokenType.TOK_VOID;

			// closeparen
			var closeparenToken:Token = stream.nextToken();
			if (closeparenToken.type != TokenType.TOK_CLOSEPAREN) {
				err = "Expected ')'";
				errToken = closeparenToken;
				return TokenType.TOK_VOID;
			}

			return type;
		}
		// $atomicexp
		else {
			return parseAtomicExp(type_);
		}
	}

	// intliteral | floatliteral | stringliteral | $call | id
	function parseAtomicExp(type:Int):Int {
		var token:Token = stream.nextToken();
		switch (token.type) {
			case TokenType.TOK_INTLITERAL:
				return TokenType.TOK_INT;
			case TokenType.TOK_FLOATLITERAL:
				return TokenType.TOK_FLOAT;
			case TokenType.TOK_STRINGLITERAL:
				return TokenType.TOK_STRING;
			case TokenType.TOK_ID:
				// $call
				if (stream.peek().type == TokenType.TOK_OPENPAREN) {
					stream.goBack(); // Move before function name
					return parseCall(type);
				}
				// var
				else {
					if (!scanner.isVar(token.data)) {
						if (scanner.func(token.data) != null) {
							err = "Expected '(' in function call";
						} else {
							err = "Variable has not been declared";
						}
						errToken = token;
						return TokenType.TOK_VOID;
					}
					return scanner.getVar(token.data).type;
				}
			default:
				err = "Unexpected element";
				errToken = token;
		}
		return TokenType.TOK_VOID;
	}

	// id $params
	function parseCall(type:Int):Int {
		// id
		var funcToken:Token = stream.nextToken();
		var libFunc:LibFunc = lib.func(funcToken.data);
		var scriptFunc:ScriptFunc = scanner.func(funcToken.data);
		if (libFunc == null && scriptFunc == null) {
			err = "Unknown function";
			errToken = funcToken;
			return TokenType.TOK_VOID;
		}
		var funcType:Int;
		var argTypes:Array<Int>;
		if (libFunc != null) {
			funcType = libFunc.type;
			argTypes = libFunc.args;
		} else {
			funcType = scriptFunc.type;
			argTypes = scriptFunc.args;
		}

		// $params
		var numParams:Int = parseParams(type, argTypes);
		if (err != "")
			return TokenType.TOK_VOID;
		if (argTypes.length != numParams) {
			err = "Function call does not match number of arguments";
			errToken = funcToken;
			return TokenType.TOK_VOID;
		}

		return funcType;
	}

	// openparen [$exp *[comma $exp]] closeparen
	function parseParams(type_:Int, argTypes:Array<Int>):Int {
		var numArgs:Int = 0;

		// openparen
		if (stream.peek().type != TokenType.TOK_OPENPAREN) {
			err = "Expected '('";
			errToken = stream.nextToken();
			return numArgs;
		}
		stream.skip(1);

		// [$exp *[comma $exp]]
		if (stream.peek().type != TokenType.TOK_CLOSEPAREN) {
			// $exp
			var token:Token = stream.peek();
			var type:Int = parseExp(type_);
			if (err != "")
				return numArgs;

			// Check argument type
			if (!TokenUtils.areCompatible(type, argTypes[numArgs])) {
				err = "Incompatible types";
				errToken = token;
				return TokenType.TOK_VOID;
			}
			numArgs++;

			// *[comma $exp]
			while (stream.peek().type == TokenType.TOK_COMMA) {
				// comma
				stream.skip(1);

				// $exp
				var token:Token = stream.peek();
				var type:Int = parseExp(type_);
				if (err != "")
					return numArgs;

				// Check argument type
				if (!TokenUtils.areCompatible(type, argTypes[numArgs])) {
					err = "Incompatible types";
					errToken = token;
					return TokenType.TOK_VOID;
				}
				numArgs++;
			}
		}

		// closeparen
		if (stream.peek().type != TokenType.TOK_CLOSEPAREN) {
			err = "Expected ')'";
			errToken = stream.nextToken();
			return numArgs;
		}
		stream.skip(1);

		return numArgs;
	}

	function parseId():Token {
		var nameToken:Token = stream.nextToken();
		if (nameToken.type != TokenType.TOK_ID) {
			err = "Expected identifier";
		}
		// Check if identifier has been defined as a library function
		else if (lib.func(nameToken.data) != null) {
			err = "Identifier cannot have the same name as a library function";
		}
		// Check if identifier has been defined multiple times
		else if (scanner.numDefs(nameToken.data) > 1) {
			err = "Identifier defined multiple times";
		}

		// Set error token if an error was found
		if (err != "")
			errToken = nameToken;

		return nameToken;
	}

	function parseEndStatement():Void {
		var hasEol:Bool = stream.skipEols();
		if (!hasEol) {
			var token:Token = stream.nextToken();
			if (token.type != TokenType.TOK_SEMICOLON) {
				err = "Expected semicolon or new line";
				errToken = token;
			}
		}
	}

	function parseEnd():Void {
		var endToken:Token = stream.nextToken();
		if (endToken.type != TokenType.TOK_END) {
			err = "Expected 'end'";
			errToken = endToken;
		}
	}
}
