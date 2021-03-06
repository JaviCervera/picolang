#include "generator.h"

using namespace std;
using namespace swan;

string Generator::GenProgram(const vector<string>& functions, const vector<string>& program, const Definitions& _) const {
    const string headerStr =
        "function _bool(a) if a ~= false and a ~= nil and a ~= 0 then return true else return false end end\n"
        "function _and(a, b) if _bool(a) and _bool(b) then return 1 else return 0 end end\n"
        "function _or(a, b) if _bool(a) or _bool(b) then return 1 else return 0 end end\n"
        "function _not(a) if _bool(a) then return 0 else return 1 end end\n"
        "_args = {}\n"
        "function pico.AddIntArg(v) _args[#_args+1] = v end\n"
        "function pico.AddFloatArg(v) _args[#_args+1] = v end\n"
        "function pico.AddStringArg(v) _args[#_args+1] = v end\n"
        "function pico.Call(f) local ret = pico[f](table.unpack(_args)) _args = {} return ret end\n"
        "function pico.CallInt(f) return Int(pico.CallFloat(f)) end\n"
        "function pico.CallFloat(f) return tonumber(pico.Call(f)) end\n"
        "function pico.CallString(f) return tostring(pico.Call(f)) end\n"
        "function pico.Callable(f) return type(pico[f]) == \"function\" end\n";
    string functionsStr;
    for (size_t i = 0; i < functions.size(); ++i) {
        functionsStr += functions[i] + "\n";
    }
    string programStr;
    for (size_t i = 0; i < program.size(); ++i) {
        programStr += program[i];
    }
    return headerStr + functionsStr + programStr + "\n";
}

string Generator::GenFunctionDef(const Function& func, const string& block) const {
    return GenFunctionHeader(func) + block + "end\n";
}

string Generator::GenStatement(const string& exp) const {
    return exp + "\n";
}

string Generator::GenIf(const string& exp, const string& block, const string& elseifs, const string& else_, const string& end) const {
    return "if _bool(" + exp + ") then\n" + block + elseifs + else_ + end;
}

string Generator::GenElseIf(const string& exp, const string& block) const {
    return "elseif _bool(" + exp + ") then\n" + block;
}

string Generator::GenElse(const string& block) const {
    return "else\n" + block;
}

string Generator::GenEnd() const {
    return "end\n";
}

string Generator::GenFor(const Var& _, const string& assignment, const string& to, const string& step, const string& block, const string& end) const {
    const string fixedAssignment = (assignment.find("local ", 0) == 0)
        ? assignment.substr(6)
        : assignment;
    return "for " + fixedAssignment + ", " + to + (block != "" ? (", " + step) : "") + " do\n" + block + end;
}

string Generator::GenWhile(const string& exp, const string& block, const string& end) const {
    return "while _bool(" + exp + ") do\n" + block + end;
}

string Generator::GenReturn(int funcType, const string& exp) const {
    return "return " + exp + "\n";
}

string Generator::GenVarDef(const Var& var, int expType, const string& exp, bool isGlobal) const {
    return (!isGlobal ? "local " : "") + GenAssignment(var, expType, exp);
}

string Generator::GenAssignment(const Var& var, int expType, const string& exp) const {
    return GenVarId(var.name) + " = " + exp;
}

string Generator::GenBinaryExp(int expType, const Token& token, const string& left, const string& right) const {
    const string op =
        (token.type == TOK_OR) ? " or " :
        (token.type == TOK_AND) ? " and " :
        (token.type == TOK_EQUAL) ? " == " :
        (token.type == TOK_NOTEQUAL) ? " ~= " :
        (token.type == TOK_LESSER) ? " < " :
        (token.type == TOK_LEQUAL) ? " <= " :
        (token.type == TOK_GREATER) ? " > " :
        (token.type == TOK_GREATER) ? " >= " :
        (token.type == TOK_PLUS && expType != TYPE_STRING) ? "+" :
        (token.type == TOK_PLUS && expType == TYPE_STRING) ? ".." :
        (token.type == TOK_MINUS) ? "-" :
        (token.type == TOK_MUL) ? "*" :
        (token.type == TOK_DIV) ? "/" :
        "%";
    return
        (token.type == TOK_OR) ? ("_or(" + left + ", " + right + ")") : 
        (token.type == TOK_AND) ? ("_and(" + left + ", " + right + ")") :
        (left + op + right);
}

string Generator::GenUnaryExp(const Token& token, const string& exp) const {
    if (token.type == TOK_NOT) return ("_not(" + exp + ")") ;
    else return "-" + exp;
}

string Generator::GenGroupExp(const string& exp) const {
    return "(" + exp + ")";
}

string Generator::GenFunctionCall(const Function& func, const string& args) const {
    return GenFuncId(func.name) + args;
}

string Generator::GenArgs(const Function& func, const vector<Expression>& args) const {
    string result;
    for (size_t i = 0; i < args.size(); ++i) {
        result += args[i].code;
        if (i < args.size() - 1) result += ", ";
    }
    return "(" + result + ")";
}

string Generator::GenVar(const Var& var) const {
    return GenVarId(var.name);
}

string Generator::GenLiteral(const Token& token) const {
    switch (token.type) {
    case TOK_INTLITERAL:
    case TOK_REALLITERAL:
        return token.data;
    case TOK_STRINGLITERAL:
        return "\"" + token.data + "\"";
#ifdef ENABLE_REF
    case TOK_NULLLITERAL:
        return "nil";
#endif
    default:
        return "<unknown>";
    }
}

string Generator::GenIndent(int level) const {
    const string space = "    ";
    string indent;
    for (int i = 0; i < level; ++i) {
        indent += space;
    }
    return indent;
}

string Generator::GenFunctionHeader(const Function& func) {
    return "function " + GenFuncId(func.name) + GenParams(func) + "\n";
}

string Generator::GenParams(const Function& func) {
    string params;
    for (size_t i = 0; i < func.params.size(); ++i) {
        params += GenVarId(func.params[i].name);
        if (i < func.params.size() - 1) params += ", ";
    }
    return "(" + params + ")";
}

string Generator::GenFuncId(const string& id) {
    return "pico." + id;
}

string Generator::GenVarId(const string& id) {
    return "__pico__" + id;
}
