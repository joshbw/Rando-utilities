@if (@X)==(@Y) @end /* JScript comment
@echo off
setlocal
if "%~1"=="" (
    echo Usage: math.cmd "expression" [/notation:auto^|infix^|prefix]
    echo.
    echo Solves arithmetic equations with correct order of operations ^(PEMDAS^).
    echo Supports standard ^(infix^) and Hungarian/Polish ^(prefix^) notation.
    echo.
    echo Examples:
    echo   math.cmd "2 + 3 * 4"           = 14
    echo   math.cmd "(2 + 3) * 4"         = 20
    echo   math.cmd "2 ^^ 3 + 1"          = 9
    echo   math.cmd "* + 2 3 4"           = 20  ^(prefix auto-detected^)
    echo   math.cmd "+ 2 * 3 4" /notation:prefix = 14
    exit /b 1
)
set "EXPR=%~1"
set "NOTATION=Auto"
if /i "%~2"=="/notation:infix" set "NOTATION=Infix"
if /i "%~2"=="/notation:prefix" set "NOTATION=Prefix"
if /i "%~2"=="/notation:auto" set "NOTATION=Auto"
cscript //nologo //e:jscript "%~f0" "%EXPR%" "%NOTATION%"
exit /b %errorlevel%
*/

// ── math.cmd – arithmetic evaluator (JScript engine) ────────────────────────
// Supports: + - * / ^ % ( )
// Notations: Infix (standard), Prefix (Hungarian/Polish), Auto-detect

(function () {
    var args = WScript.Arguments;
    if (args.length < 1) {
        WScript.Echo("No expression provided.");
        WScript.Quit(1);
    }

    var expression = args(0);
    var notation = args.length > 1 ? args(1) : "Auto";

    // ── Tokenizer ───────────────────────────────────────────────────────────

    function tokenize(text) {
        var tokens = [];
        var i = 0;
        text = text.replace(/^\s+/, "").replace(/\s+$/, "");

        while (i < text.length) {
            var c = text.charAt(i);

            if (/\s/.test(c)) { i++; continue; }

            if (/\d/.test(c) || (c === "." && i + 1 < text.length && /\d/.test(text.charAt(i + 1)))) {
                var start = i;
                var dotSeen = false;
                while (i < text.length && (/\d/.test(text.charAt(i)) || (text.charAt(i) === "." && !dotSeen))) {
                    if (text.charAt(i) === ".") dotSeen = true;
                    i++;
                }
                tokens.push({ type: "Number", value: parseFloat(text.substring(start, i)) });
                continue;
            }

            if ("+-*/^%".indexOf(c) >= 0) {
                tokens.push({ type: "Operator", value: c });
                i++;
                continue;
            }

            if (c === "(") { tokens.push({ type: "LParen", value: "(" }); i++; continue; }
            if (c === ")") { tokens.push({ type: "RParen", value: ")" }); i++; continue; }

            throw new Error("Unexpected character '" + c + "' at position " + i + ".");
        }
        return tokens;
    }

    // ── Prefix (Hungarian/Polish) evaluator ─────────────────────────────────

    function evalPrefix(tokens, pos) {
        if (pos.i >= tokens.length) throw new Error("Unexpected end of expression (prefix).");

        var token = tokens[pos.i];

        if (token.type === "Number") {
            pos.i++;
            return token.value;
        }

        if (token.type === "Operator") {
            var op = token.value;
            pos.i++;
            var left = evalPrefix(tokens, pos);
            var right = evalPrefix(tokens, pos);

            switch (op) {
                case "+": return left + right;
                case "-": return left - right;
                case "*": return left * right;
                case "/":
                    if (right === 0) throw new Error("Division by zero.");
                    return left / right;
                case "^": return Math.pow(left, right);
                case "%":
                    if (right === 0) throw new Error("Modulo by zero.");
                    return left % right;
            }
        }

        throw new Error("Unexpected token '" + token.value + "' in prefix expression.");
    }

    // ── Infix recursive-descent parser (PEMDAS) ────────────────────────────
    //
    // Expression → Term   (('+' | '-') Term)*
    // Term       → Power  (('*' | '/' | '%') Power)*
    // Power      → Unary  ('^' Power)?          (right-associative)
    // Unary      → ('+' | '-') Unary | Atom
    // Atom       → NUMBER | '(' Expression ')'

    var infixTokens, infixPos;

    function peek() {
        return infixPos < infixTokens.length ? infixTokens[infixPos] : null;
    }
    function advance() { infixPos++; }

    function parseExpression() {
        var result = parseTerm();
        var t = peek();
        while (t !== null && t.type === "Operator" && (t.value === "+" || t.value === "-")) {
            var op = t.value;
            advance();
            var right = parseTerm();
            result = op === "+" ? result + right : result - right;
            t = peek();
        }
        return result;
    }

    function parseTerm() {
        var result = parsePower();
        var t = peek();
        while (t !== null && t.type === "Operator" && (t.value === "*" || t.value === "/" || t.value === "%")) {
            var op = t.value;
            advance();
            var right = parsePower();
            if (op === "*") result *= right;
            else if (op === "/") {
                if (right === 0) throw new Error("Division by zero.");
                result /= right;
            } else {
                if (right === 0) throw new Error("Modulo by zero.");
                result %= right;
            }
            t = peek();
        }
        return result;
    }

    function parsePower() {
        var base = parseUnary();
        var t = peek();
        if (t !== null && t.type === "Operator" && t.value === "^") {
            advance();
            var exp = parsePower(); // right-associative
            return Math.pow(base, exp);
        }
        return base;
    }

    function parseUnary() {
        var t = peek();
        if (t !== null && t.type === "Operator" && (t.value === "+" || t.value === "-")) {
            var op = t.value;
            advance();
            var operand = parseUnary();
            return op === "-" ? -operand : operand;
        }
        return parseAtom();
    }

    function parseAtom() {
        var t = peek();
        if (t === null) throw new Error("Unexpected end of expression.");

        if (t.type === "Number") {
            advance();
            return t.value;
        }

        if (t.type === "LParen") {
            advance();
            var result = parseExpression();
            var closing = peek();
            if (closing === null || closing.type !== "RParen")
                throw new Error("Missing closing parenthesis.");
            advance();
            return result;
        }

        throw new Error("Unexpected token '" + t.value + "'.");
    }

    // ── Auto-detection ──────────────────────────────────────────────────────

    function isPrefixNotation(tokens) {
        if (tokens.length < 3 || tokens[0].type !== "Operator") return false;
        if (tokens.length === 2 && tokens[1].type === "Number") return false;
        try {
            var testPos = { i: 0 };
            evalPrefix(tokens, testPos);
            return testPos.i === tokens.length;
        } catch (e) {
            return false;
        }
    }

    // ── Main ────────────────────────────────────────────────────────────────

    try {
        var tokens = tokenize(expression);
        if (tokens.length === 0) throw new Error("Empty expression.");

        var usePrefix;
        switch (notation.toLowerCase()) {
            case "prefix": usePrefix = true; break;
            case "infix":  usePrefix = false; break;
            default:       usePrefix = isPrefixNotation(tokens); break;
        }

        var result;
        if (usePrefix) {
            var pos = { i: 0 };
            result = evalPrefix(tokens, pos);
            if (pos.i !== tokens.length)
                throw new Error("Unexpected extra tokens after prefix expression.");
        } else {
            infixTokens = tokens;
            infixPos = 0;
            result = parseExpression();
            if (infixPos !== infixTokens.length)
                throw new Error("Unexpected token '" + infixTokens[infixPos].value + "' after end of expression.");
        }

        // Format output: integers without decimals
        if (result === Math.floor(result) && Math.abs(result) <= 9007199254740991) {
            WScript.Echo(parseInt(result, 10));
        } else {
            WScript.Echo(result);
        }

    } catch (e) {
        WScript.StdErr.WriteLine("Error: " + e.message);
        WScript.Quit(1);
    }
})();
