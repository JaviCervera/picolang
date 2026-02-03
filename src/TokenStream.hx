package;

class TokenStream {
	var tokens:Array<Token>;
	var pos:Int;

	public function new(tokens:Array<Token>) {
		this.tokens = tokens;
		this.pos = 0;
	}

	public function getTokens():Array<Token> {
		return tokens;
	}

	public function getPos():Int {
		return pos;
	}

	public function nextToken():Token {
		skipEols();
		var tok:Token = tokens[pos];
		pos++;
		return tok;
	}

	public function peek(offset:Int = 0):Token {
		var prevPos:Int = pos;
		skip(offset);
		var tok:Token = nextToken();
		pos = prevPos;
		return tok;
	}

	public function goBack():Void {
		pos--;
		while (pos > 0 && tokens[pos].type == TokenType.TOK_EOL) {
			pos--;
		}
	}

	public function hasNext():Bool {
		var prevPos:Int = pos;
		skipEols();
		var hasNext:Bool = pos < tokens.length;
		pos = prevPos;
		return hasNext;
	}

	public function seek(pos:Int):Void {
		this.pos = pos;
	}

	public function skip(count:Int):Void {
		for (i in 0...count) {
			nextToken();
		}
	}

	public function skipEols():Bool {
		var skipped:Bool = false;
		while (pos < tokens.length && tokens[pos].type == TokenType.TOK_EOL) {
			pos++;
			skipped = true;
		}
		return skipped;
	}
}
