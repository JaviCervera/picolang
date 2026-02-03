package;

class Scanner {
	var stream:TokenStream;
	var globals:Array<ScriptVar>;
	var functions:Array<ScriptFunc>;
	var locals:Array<ScriptVar>;

	public function new(tokens:Array<Token>) {
		stream = new TokenStream(tokens);
		globals = [];
		functions = [];
		locals = [];
	}

	public function scanDefs():Void {
		// Move to the beginning of the stream
		stream.seek(0);

		// Check for global and function declarations
		var block:Int = 0;
		var token:Token = stream.nextToken();
		while (stream.hasNext()) {
			// Count blocks
			if (token.isControl() || token.type == TokenType.TOK_FUNCTION) {
				block++;
			} else if (token.type == TokenType.TOK_END) {
				block = Std.int(Math.max(block - 1, 0));
			}

			if (token.type == TokenType.TOK_VAR) {
				if (stream.peek().type == TokenType.TOK_ID && block == 0) {
					var name:String = stream.nextToken().data;
					stream.skip(1); // Skip ':'
					var type:Int = stream.nextToken().type;
					globals.push(new ScriptVar(name, type, stream.getPos() + 1));
				}
			} else if (token.type == TokenType.TOK_FUNCTION) {
				var name:String = stream.nextToken().data;

				// Parse params
				var paramTypes:Array<Int> = [];
				stream.skip(1); // Skip '('
				while (stream.hasNext() && stream.peek().type != TokenType.TOK_CLOSEPAREN) {
					if (stream.peek().type == TokenType.TOK_ID)
						stream.skip(1); // Skip name
					if (stream.peek().type == TokenType.TOK_COLON)
						stream.skip(1); // Skip colon
					if (stream.peek().isType()) {
						paramTypes.push(stream.nextToken().type);
					} else {
						paramTypes.push(TokenType.TOK_VOID);
					}
					if (stream.hasNext() && stream.peek().type == TokenType.TOK_COMMA) {
						stream.skip(1); // Skip comma
					}
				}
				if (stream.hasNext())
					stream.skip(1); // Skip ')'

				// Parse return type
				var type:Int = TokenType.TOK_VOID;
				if (stream.peek().type == TokenType.TOK_COLON) {
					stream.skip(1); // Skip ':'
					type = stream.nextToken().type;
				}
				functions.push(new ScriptFunc(name, type, paramTypes));
			}

			// Get next token
			if (stream.hasNext())
				token = stream.nextToken();
		}
	}

	public function scanLocals(pos:Int):Void {
		// Reset locals
		locals = [];

		// Seek position in stream
		stream.seek(pos);

		// Scan arguments
		if (stream.peek().type == TokenType.TOK_OPENPAREN)
			stream.skip(1); // Skip (
		while (stream.hasNext() && stream.peek().type != TokenType.TOK_CLOSEPAREN) {
			if (stream.peek().type == TokenType.TOK_ID) {
				var name:String = stream.nextToken().data;
				if (stream.peek().type == TokenType.TOK_COLON)
					stream.skip(1); // Skip colon
				if (stream.peek().isType()) {
					locals.push(new ScriptVar(name, stream.nextToken().type, -1));
				} else {
					locals.push(new ScriptVar(name, TokenType.TOK_VOID, -1));
				}
			} else {
				stream.skip(1);
			}
		}
		stream.skip(1); // )

		// Scan
		var block:Int = 1;
		while (stream.hasNext() && block > 0) {
			var token:Token = stream.nextToken();

			// Count blocks
			if (token.isControl()) {
				block++;
			} else if (token.type == TokenType.TOK_END) {
				block--;
			}

			// Scan vars
			if (token.type == TokenType.TOK_VAR && stream.peek().type == TokenType.TOK_ID) {
				var name:String = stream.nextToken().data;
				stream.skip(1); // Skip ':'
				var type:Int = stream.nextToken().type;
				locals.push(new ScriptVar(name, type, stream.getPos() + 1));
			}
		}
	}

	public function numDefs(name:String):Int {
		var count:Int = 0;
		for (f in functions) {
			if (f.name == name)
				count++;
		}
		for (g in globals) {
			if (g.name == name)
				count++;
		}
		for (l in locals) {
			if (l.name == name)
				count++;
		}
		return count;
	}

	public function getLocals():Array<ScriptVar> {
		return locals;
	}

	public function getVar(name:String):ScriptVar {
		for (l in locals) {
			if (l.name == name)
				return l;
		}
		for (g in globals) {
			if (g.name == name)
				return g;
		}
		return null;
	}

	public function func(name:String):ScriptFunc {
		for (func in functions) {
			if (func.name == name)
				return func;
		}
		return null;
	}

	public function funcId(f:ScriptFunc):Int {
		for (i in 0...functions.length) {
			if (functions[i] == f)
				return i;
		}
		return -1;
	}

	public function isVar(name:String):Bool {
		for (l in locals) {
			if (l.name == name)
				return true;
		}
		for (g in globals) {
			if (g.name == name)
				return true;
		}
		return false;
	}

	public function globalId(name:String):Int {
		for (i in 0...globals.length) {
			if (globals[i].name == name)
				return i;
		}
		return -1;
	}

	public function getGlobals():Array<ScriptVar> {
		return globals;
	}

	public function getFunctions():Array<ScriptFunc> {
		return functions;
	}
}
