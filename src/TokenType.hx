package;

class TokenType {
	public static inline var TOK_EOF:Int = 0;
	public static inline var TOK_EOL:Int = 1;

	// Literals
	public static inline var TOK_INTLITERAL:Int = 2;
	public static inline var TOK_FLOATLITERAL:Int = 3;
	public static inline var TOK_STRINGLITERAL:Int = 4;

	// Operators
	public static inline var TOK_NOT:Int = 10;
	public static inline var TOK_AND:Int = 11;
	public static inline var TOK_OR:Int = 12;
	public static inline var TOK_EQUAL:Int = 13;
	public static inline var TOK_NOTEQUAL:Int = 14;
	public static inline var TOK_GREATER:Int = 15;
	public static inline var TOK_LESSER:Int = 16;
	public static inline var TOK_GEQUAL:Int = 17;
	public static inline var TOK_LEQUAL:Int = 18;
	public static inline var TOK_PLUS:Int = 19;
	public static inline var TOK_MINUS:Int = 20;
	public static inline var TOK_MUL:Int = 21;
	public static inline var TOK_DIV:Int = 22;
	public static inline var TOK_MOD:Int = 23;
	public static inline var TOK_ASSIGN:Int = 24;

	// Separators
	public static inline var TOK_COMMA:Int = 30;
	public static inline var TOK_COLON:Int = 31;
	public static inline var TOK_SEMICOLON:Int = 32;
	public static inline var TOK_OPENPAREN:Int = 33;
	public static inline var TOK_CLOSEPAREN:Int = 34;
	public static inline var TOK_END:Int = 35;

	// Control statements
	public static inline var TOK_IF:Int = 40;
	public static inline var TOK_ELSEIF:Int = 41;
	public static inline var TOK_ELSE:Int = 42;
	public static inline var TOK_FOR:Int = 43;
	public static inline var TOK_WHILE:Int = 44;

	// Variable and function definitions
	public static inline var TOK_VAR:Int = 50;
	public static inline var TOK_FUNCTION:Int = 51;

	// Identifiers
	public static inline var TOK_ID:Int = 60;

	// Types
	public static inline var TOK_INT:Int = -1;
	public static inline var TOK_FLOAT:Int = -2;
	public static inline var TOK_STRING:Int = -3;
	public static inline var TOK_REF:Int = -4;
	public static inline var TOK_VOID:Int = -5; // Not a real token, but functions can be of this type
}
