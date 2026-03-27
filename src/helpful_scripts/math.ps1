<#
.SYNOPSIS
    Solves arithmetic equations with correct order of operations.
.DESCRIPTION
    Evaluates arithmetic expressions supporting:
    - Standard (infix) notation:  2 + 3 * 4
    - Hungarian/Polish (prefix) notation:  + 2 * 3 4
    - Parentheses for grouping:  (2 + 3) * 4
    - Operators: + - * / ^ % (add, subtract, multiply, divide, exponent, modulo)
    - Mathematically correct order of operations (PEMDAS)
.PARAMETER Expression
    The arithmetic expression to evaluate. Quote the expression to prevent
    shell interpretation of special characters like * and parentheses.
.PARAMETER Notation
    The notation style: Auto (default), Infix (standard), or Prefix (Hungarian/Polish).
    Auto mode detects the notation by attempting a prefix parse first.
.EXAMPLE
    .\math.ps1 "2 + 3 * 4"
    14
.EXAMPLE
    .\math.ps1 "(2 + 3) * 4"
    20
.EXAMPLE
    .\math.ps1 "2 ^ 3 + 1"
    9
.EXAMPLE
    .\math.ps1 "* + 2 3 4"
    20
.EXAMPLE
    .\math.ps1 -Notation Prefix "+ 2 * 3 4"
    14
#>

param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Expression,

    [ValidateSet('Auto', 'Infix', 'Prefix')]
    [string]$Notation = 'Auto'
)

Set-StrictMode -Version Latest

# ── Tokenizer ────────────────────────────────────────────────────────────────

function ConvertTo-Tokens
{
    param([string]$Text)

    $tokens = [System.Collections.Generic.List[object]]::new()
    $i = 0
    $Text = $Text.Trim()

    while ($i -lt $Text.Length)
    {
        $c = $Text[$i]

        if ([char]::IsWhiteSpace($c))
        {
            $i++
            continue
        }

        # Numbers: digits and decimals
        if ([char]::IsDigit($c) -or ($c -eq '.' -and ($i + 1) -lt $Text.Length -and [char]::IsDigit($Text[$i + 1])))
        {
            $start = $i
            $dotSeen = $false
            while ($i -lt $Text.Length -and ([char]::IsDigit($Text[$i]) -or ($Text[$i] -eq '.' -and -not $dotSeen)))
            {
                if ($Text[$i] -eq '.') { $dotSeen = $true }
                $i++
            }
            $tokens.Add(@{ Type = 'Number'; Value = [double]$Text.Substring($start, $i - $start) })
            continue
        }

        if ($c -in '+', '-', '*', '/', '^', '%')
        {
            $tokens.Add(@{ Type = 'Operator'; Value = [string]$c })
            $i++
            continue
        }

        if ($c -eq '(')
        {
            $tokens.Add(@{ Type = 'LParen'; Value = '(' })
            $i++
            continue
        }

        if ($c -eq ')')
        {
            $tokens.Add(@{ Type = 'RParen'; Value = ')' })
            $i++
            continue
        }

        throw "Unexpected character '$c' at position $i."
    }

    return $tokens
}

# ── Prefix / Hungarian / Polish notation evaluator ───────────────────────────

function Resolve-PrefixExpression
{
    param(
        [System.Collections.Generic.List[object]]$Tokens,
        [ref]$Position
    )

    if ($Position.Value -ge $Tokens.Count)
    {
        throw "Unexpected end of expression (prefix)."
    }

    $token = $Tokens[$Position.Value]

    if ($token.Type -eq 'Number')
    {
        $Position.Value++
        return $token.Value
    }

    if ($token.Type -eq 'Operator')
    {
        $op = $token.Value
        $Position.Value++

        $left  = Resolve-PrefixExpression -Tokens $Tokens -Position $Position
        $right = Resolve-PrefixExpression -Tokens $Tokens -Position $Position

        switch ($op)
        {
            '+' { return $left + $right }
            '-' { return $left - $right }
            '*' { return $left * $right }
            '/' {
                if ($right -eq 0) { throw "Division by zero." }
                return $left / $right
            }
            '^' { return [Math]::Pow($left, $right) }
            '%' {
                if ($right -eq 0) { throw "Modulo by zero." }
                return $left % $right
            }
        }
    }

    throw "Unexpected token '$($token.Value)' in prefix expression."
}

# ── Infix notation recursive-descent parser ──────────────────────────────────
#
# Grammar (implements PEMDAS):
#   Expression → Term   (('+' | '-') Term)*
#   Term       → Power  (('*' | '/' | '%') Power)*
#   Power      → Unary  ('^' Power)?                  # right-associative
#   Unary      → ('+' | '-') Unary | Atom
#   Atom       → NUMBER | '(' Expression ')'

$script:infixTokens = $null
$script:infixPos    = 0

function Read-InfixToken
{
    if ($script:infixPos -ge $script:infixTokens.Count) { return $null }
    return $script:infixTokens[$script:infixPos]
}

function Step-InfixToken
{
    $script:infixPos++
}

function Resolve-InfixExpression
{
    $result = Resolve-InfixTerm

    $t = Read-InfixToken
    while ($null -ne $t -and $t.Type -eq 'Operator' -and $t.Value -in '+', '-')
    {
        $op = $t.Value
        Step-InfixToken
        $right = Resolve-InfixTerm

        if ($op -eq '+') { $result += $right }
        else             { $result -= $right }

        $t = Read-InfixToken
    }

    return $result
}

function Resolve-InfixTerm
{
    $result = Resolve-InfixPower

    $t = Read-InfixToken
    while ($null -ne $t -and $t.Type -eq 'Operator' -and $t.Value -in '*', '/', '%')
    {
        $op = $t.Value
        Step-InfixToken
        $right = Resolve-InfixPower

        switch ($op)
        {
            '*' { $result *= $right }
            '/' {
                if ($right -eq 0) { throw "Division by zero." }
                $result /= $right
            }
            '%' {
                if ($right -eq 0) { throw "Modulo by zero." }
                $result %= $right
            }
        }

        $t = Read-InfixToken
    }

    return $result
}

function Resolve-InfixPower
{
    $base = Resolve-InfixUnary

    $t = Read-InfixToken
    if ($null -ne $t -and $t.Type -eq 'Operator' -and $t.Value -eq '^')
    {
        Step-InfixToken
        $exp = Resolve-InfixPower          # right-associative
        return [Math]::Pow($base, $exp)
    }

    return $base
}

function Resolve-InfixUnary
{
    $t = Read-InfixToken
    if ($null -ne $t -and $t.Type -eq 'Operator' -and $t.Value -in '+', '-')
    {
        $op = $t.Value
        Step-InfixToken
        $operand = Resolve-InfixUnary

        if ($op -eq '-') { return -$operand }
        return $operand
    }

    return Resolve-InfixAtom
}

function Resolve-InfixAtom
{
    $t = Read-InfixToken

    if ($null -eq $t)
    {
        throw "Unexpected end of expression."
    }

    if ($t.Type -eq 'Number')
    {
        Step-InfixToken
        return $t.Value
    }

    if ($t.Type -eq 'LParen')
    {
        Step-InfixToken
        $result = Resolve-InfixExpression

        $closing = Read-InfixToken
        if ($null -eq $closing -or $closing.Type -ne 'RParen')
        {
            throw "Missing closing parenthesis."
        }
        Step-InfixToken
        return $result
    }

    throw "Unexpected token '$($t.Value)'."
}

# ── Notation auto-detection ──────────────────────────────────────────────────

function Test-PrefixNotation
{
    param([System.Collections.Generic.List[object]]$Tokens)

    if ($Tokens.Count -lt 3 -or $Tokens[0].Type -ne 'Operator') { return $false }

    # A unary usage like "-5" (op then single number) is infix, not prefix
    if ($Tokens.Count -eq 2 -and $Tokens[1].Type -eq 'Number') { return $false }

    # Try a full prefix parse; if it consumes every token it's valid prefix
    try
    {
        $testPos = [ref]0
        $null = Resolve-PrefixExpression -Tokens $Tokens -Position $testPos
        return ($testPos.Value -eq $Tokens.Count)
    }
    catch
    {
        return $false
    }
}

# ── Main ─────────────────────────────────────────────────────────────────────

$tokens = ConvertTo-Tokens -Text $Expression

if ($tokens.Count -eq 0) { throw "Empty expression." }

$usePrefix = switch ($Notation)
{
    'Prefix' { $true }
    'Infix'  { $false }
    'Auto'   { Test-PrefixNotation -Tokens $tokens }
}

if ($usePrefix)
{
    $pos = [ref]0
    $result = Resolve-PrefixExpression -Tokens $tokens -Position $pos

    if ($pos.Value -ne $tokens.Count)
    {
        throw "Unexpected extra tokens after prefix expression."
    }
}
else
{
    $script:infixTokens = $tokens
    $script:infixPos    = 0
    $result = Resolve-InfixExpression

    if ($script:infixPos -ne $script:infixTokens.Count)
    {
        $leftover = $script:infixTokens[$script:infixPos]
        throw "Unexpected token '$($leftover.Value)' after end of expression."
    }
}

# Output: whole numbers as integers, otherwise as doubles
if ($result -eq [Math]::Floor($result) -and [Math]::Abs($result) -le [long]::MaxValue)
{
    [long]$result
}
else
{
    $result
}
