package;

import sys.io.File;
import sys.FileSystem;

class Pico {
	static function main():Void {
		// Check arguments
		if (Sys.args().length < 1) {
			Sys.println("Usage:");
			Sys.println("  pico <filename.pi>");
			Sys.exit(-1);
		}

		final fileArg:String = Sys.args()[Sys.args().length - 1].split("~q").join("");
		final modPath:String = "..";

		// Get script file(s)
		var scriptFiles:Array<String>;
		if (!FileSystem.exists(fileArg)) {
			Sys.println("Error: File '" + fileArg + "' does not exist");
			Sys.exit(-1);
		}

		if (FileSystem.isDirectory(fileArg)) {
			// Directory
			scriptFiles = [];
			var files:Array<String> = FileSystem.readDirectory(fileArg);
			for (file in files) {
				var ext = extractExt(file).toLowerCase();
				if (ext == "pi") {
					scriptFiles.push(fileArg + "/" + file);
				}
			}
		} else {
			// Single file
			scriptFiles = [fileArg];
		}

		// Generate library from funcs files
		var lib:Lib = genLibFromModulesDir(modPath);
		if (lib == null) {
			Sys.exit(-1);
		}

		// Lexical analysis of all files
		var lexerTokens:Array<Token> = [];
		for (scriptFile in scriptFiles) {
			var source:String;
			try {
				source = File.getContent(scriptFile);
			} catch (e:Dynamic) {
				Sys.println("Error: Could not read file '" + scriptFile + "'");
				Sys.exit(-1);
				return;
			}

			var lexer:Lexer = new Lexer(source, scriptFile);
			if (lexer.getErr() != "") {
				Sys.println(lexer.getErr());
				Sys.exit(-1);
			}

			for (token in lexer.getTokens()) {
				lexerTokens.push(token);
			}
		}

		// Parse syntax
		var parser:Parser = new Parser(lexerTokens, lib);
		if (parser.getErr() != "") {
			Sys.println(parser.getErr());
			Sys.exit(-1);
		}

		// Make sure there is a Main function
		if (parser.getScanner().func("Main") == null) {
			Sys.println("'Main' function not found.");
			Sys.exit(-1);
		}

		// Generate output
		final gen = new HaxeGen(lexerTokens, parser.getScanner(), lib);
		final code = gen.getCode();
		final ext = ".hx";

		var outfile:String = stripExt(fileArg);
		if (FileSystem.isDirectory(fileArg)) {
			outfile = fileArg + "/main";
		}

		try {
			Sys.println(code);
			// File.saveContent(outfile + ext, code);
		} catch (e:Dynamic) {
			Sys.println("Error: Could not write output file '" + outfile + ext + "'");
			Sys.exit(-1);
		}

		Sys.exit(0);
	}

	static function genLibFromModulesDir(path:String):Lib {
		var lib:Lib = new Lib();

		// Parse modules folder
		var funcsFiles:Array<String> = parseModulesFolder(path);
		if (funcsFiles.length == 0) {
			Sys.println("Error: Could not find 'core.defs' file");
			return null;
		}

		for (funcsFile in funcsFiles) {
			var appDir:String = extractDir(Sys.executablePath());
			var dir = appDir + "/";
			if (path != "") {
				dir += path + "/";
			}
			var err:String = parseFuncsFile(dir + funcsFile, lib);
			if (err != "") {
				Sys.println("Error parsing module '" + funcsFile + "': " + err);
				return null;
			}
		}

		return lib;
	}

	// Returns array of funcs files found
	static function parseModulesFolder(path:String):Array<String> {
		var foundCoreLib:Bool = false;
		var funcsFiles:Array<String> = ["core.defs"]; // Always put core as first library

		var appDir:String = extractDir(Sys.executablePath());
		var fullPath:String = appDir + "/" + path;

		if (!FileSystem.exists(fullPath) || !FileSystem.isDirectory(fullPath)) {
			return [];
		}

		var files:Array<String> = FileSystem.readDirectory(fullPath);
		for (file in files) {
			var ext = extractExt(file).toLowerCase();
			if (ext == "defs") {
				if (file == "core.defs") {
					foundCoreLib = true;
				} else {
					funcsFiles.push(file);
				}
			}
		}

		if (!foundCoreLib) {
			return [];
		}

		return funcsFiles;
	}

	// Returns error message or empty string if success
	static function parseFuncsFile(funcsFile:String, lib:Lib):String {
		// Load file contents (with UNIX-like file endings)
		var fileContents:String;
		try {
			fileContents = File.getContent(funcsFile);
		} catch (e:Dynamic) {
			return "Could not read file";
		}

		fileContents = fileContents.split("\r\n").join("\n").split("\r").join("\n");

		// Generate lines
		var lines:Array<String> = fileContents.split("\n");

		// Process each line
		for (line in lines) {
			// Trim spaces
			line = StringTools.trim(line);

			// Ignore blank and comment lines
			if (line == "" || line.substr(0, 2) == "//") {
				continue;
			}

			// This separates the data on the left and the right of the (
			var parenSplit:Array<String> = line.split("(");
			if (parenSplit.length != 2) {
				return "Function needs one set of arguments -> " + line;
			}
			if (parenSplit[0].substr(0, 4) != "def ") {
				return "Expected function declaration -> " + line;
			}

			// Extract function name from the left of the (
			var funcName:String = StringTools.trim(parenSplit[0].split("def ").join(""));

			// Extract parameters and type
			var rightSplit:Array<String> = parenSplit[1].split(")");
			var funcType:Int = TokenType.TOK_VOID;
			if (rightSplit.length > 1 && rightSplit[1] != "") {
				var repl:String = StringTools.trim(rightSplit[1].split(":").join(""));
				funcType = getType(repl);
				if (funcType == TokenType.TOK_VOID) {
					return "Invalid function type '" + repl + "' -> " + line;
				}
			}

			// Extract parameters from the right of the (
			var params:Array<String> = rightSplit[0].split(",");
			var paramTypes:Array<Int> = [];
			if (params.length == 1 && params[0] == "") {
				paramTypes = [];
			} else {
				for (param in params) {
					var paramParts:Array<String> = param.split(":");
					if (paramParts.length < 2) {
						return "Invalid parameter format -> " + line;
					}
					paramTypes.push(getType(paramParts[1]));
				}
			}

			// Add function to lib
			lib.addFunc(funcName, funcType, paramTypes);
		}

		return "";
	}

	static function getType(type:String):Int {
		type = StringTools.trim(type);
		switch (type) {
			case "Int":
				return TokenType.TOK_INT;
			case "Float":
				return TokenType.TOK_FLOAT;
			case "String":
				return TokenType.TOK_STRING;
			case "Ref":
				return TokenType.TOK_REF;
			default:
				return TokenType.TOK_VOID;
		}
	}

	static function extractExt(path:String):String {
		var lastDot:Int = path.lastIndexOf(".");
		var lastSlash:Int = path.lastIndexOf("/");
		if (lastDot > lastSlash && lastDot != -1) {
			return path.substr(lastDot + 1);
		}
		return "";
	}

	static function stripExt(path:String):String {
		var lastDot:Int = path.lastIndexOf(".");
		var lastSlash:Int = path.lastIndexOf("/");
		if (lastDot > lastSlash && lastDot != -1) {
			return path.substr(0, lastDot);
		}
		return path;
	}

	static function extractDir(path:String):String {
		var lastSlash:Int = path.lastIndexOf("/");
		if (lastSlash == -1) {
			lastSlash = path.lastIndexOf("\\");
		}
		if (lastSlash != -1) {
			return path.substr(0, lastSlash);
		}
		return "";
	}
}
