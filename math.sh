#!/usr/bin/env bash
set -euo pipefail

# â”€â”€ math.sh â€“ arithmetic evaluator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# Supports: + - * / ^ % ( )
# Notations: Infix (standard), Prefix (Hungarian/Polish), Auto-detect
# Uses awk for floating-point arithmetic.

usage() {
    cat <<'EOF'
Usage: math.sh "expression" [--notation auto|infix|prefix]

Solves arithmetic equations with correct order of operations (PEMDAS).
Supports standard (infix) and Hungarian/Polish (prefix) notation.

Examples:
  math.sh "2 + 3 * 4"                     = 14
  math.sh "(2 + 3) * 4"                   = 20
  math.sh "2 ^ 3 + 1"                     = 9
  math.sh "* + 2 3 4"                      = 20  (prefix auto-detected)
  math.sh "+ 2 * 3 4" --notation prefix    = 14
EOF
    exit 1
}

# â”€â”€ Globals â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

TOKEN_TYPES=()
TOKEN_VALUES=()
TOKEN_COUNT=0
POS=0

# â”€â”€ Arithmetic helper (float-safe via awk) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

calc() {
    awk "BEGIN { printf \"%.15g\", $1 }"
}

# â”€â”€ Tokenizer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

tokenize() {
    local text="$1"
    local i=0
    local len=${#text}
    TOKEN_TYPES=()
    TOKEN_VALUES=()
    TOKEN_COUNT=0

    while (( i < len )); do
        local c="${text:$i:1}"

        # Skip whitespace
        if [[ "$c" =~ [[:space:]] ]]; then
            i=$(( i + 1 ))
            continue
        fi

        # Numbers
        if [[ "$c" =~ [0-9] ]] || { [[ "$c" == "." ]] && (( i + 1 < len )) && [[ "${text:$((i+1)):1}" =~ [0-9] ]]; }; then
            local start=$i
            local dot_seen=0
            while (( i < len )); do
                local ch="${text:$i:1}"
                if [[ "$ch" =~ [0-9] ]]; then
                    i=$(( i + 1 ))
                elif [[ "$ch" == "." ]] && (( dot_seen == 0 )); then
                    dot_seen=1
                    i=$(( i + 1 ))
                else
                    break
                fi
            done
            TOKEN_TYPES+=("Number")
            TOKEN_VALUES+=("${text:$start:$((i - start))}")
            TOKEN_COUNT=$(( TOKEN_COUNT + 1 ))
            continue
        fi

        # Operators
        case "$c" in
            +|-|\*|/|^|%)
                TOKEN_TYPES+=("Operator")
                TOKEN_VALUES+=("$c")
                TOKEN_COUNT=$(( TOKEN_COUNT + 1 ))
                i=$(( i + 1 ))
                continue
                ;;
        esac

        # Parentheses
        if [[ "$c" == "(" ]]; then
            TOKEN_TYPES+=("LParen")
            TOKEN_VALUES+=("(")
            TOKEN_COUNT=$(( TOKEN_COUNT + 1 ))
            i=$(( i + 1 ))
            continue
        fi
        if [[ "$c" == ")" ]]; then
            TOKEN_TYPES+=("RParen")
            TOKEN_VALUES+=(")")
            TOKEN_COUNT=$(( TOKEN_COUNT + 1 ))
            i=$(( i + 1 ))
            continue
        fi

        echo "Error: Unexpected character '$c' at position $i." >&2
        exit 1
    done
}

# â”€â”€ Prefix (Hungarian/Polish) evaluator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

eval_prefix() {
    if (( POS >= TOKEN_COUNT )); then
        echo "Error: Unexpected end of expression (prefix)." >&2
        exit 1
    fi

    local ttype="${TOKEN_TYPES[$POS]}"
    local tval="${TOKEN_VALUES[$POS]}"

    if [[ "$ttype" == "Number" ]]; then
        POS=$(( POS + 1 ))
        RESULT="$tval"
        return
    fi

    if [[ "$ttype" == "Operator" ]]; then
        local op="$tval"
        POS=$(( POS + 1 ))

        eval_prefix
        local left="$RESULT"

        eval_prefix
        local right="$RESULT"

        case "$op" in
            +) RESULT=$(calc "$left + $right") ;;
            -) RESULT=$(calc "$left - $right") ;;
            \*) RESULT=$(calc "$left * $right") ;;
            /)
                if [[ $(calc "$right == 0") == "1" ]]; then
                    echo "Error: Division by zero." >&2; exit 1
                fi
                RESULT=$(calc "$left / $right")
                ;;
            ^) RESULT=$(calc "$left ^ $right") ;;
            %)
                if [[ $(calc "$right == 0") == "1" ]]; then
                    echo "Error: Modulo by zero." >&2; exit 1
                fi
                RESULT=$(calc "$left % $right")
                ;;
        esac
        return
    fi

    echo "Error: Unexpected token '$tval' in prefix expression." >&2
    exit 1
}

# â”€â”€ Infix recursive-descent parser (PEMDAS) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#
# Expression â†’ Term   (('+' | '-') Term)*
# Term       â†’ Power  (('*' | '/' | '%') Power)*
# Power      â†’ Unary  ('^' Power)?          (right-associative)
# Unary      â†’ ('+' | '-') Unary | Atom
# Atom       â†’ NUMBER | '(' Expression ')'

peek_type() {
    if (( POS < TOKEN_COUNT )); then
        echo "${TOKEN_TYPES[$POS]}"
    else
        echo ""
    fi
}

peek_value() {
    if (( POS < TOKEN_COUNT )); then
        echo "${TOKEN_VALUES[$POS]}"
    else
        echo ""
    fi
}

parse_expression() {
    parse_term
    local result="$RESULT"

    while true; do
        local tt
        tt=$(peek_type)
        local tv
        tv=$(peek_value)
        if [[ "$tt" == "Operator" ]] && [[ "$tv" == "+" || "$tv" == "-" ]]; then
            POS=$(( POS + 1 ))
            parse_term
            if [[ "$tv" == "+" ]]; then
                result=$(calc "$result + $RESULT")
            else
                result=$(calc "$result - $RESULT")
            fi
        else
            break
        fi
    done

    RESULT="$result"
}

parse_term() {
    parse_power
    local result="$RESULT"

    while true; do
        local tt
        tt=$(peek_type)
        local tv
        tv=$(peek_value)
        if [[ "$tt" == "Operator" ]] && [[ "$tv" == "*" || "$tv" == "/" || "$tv" == "%" ]]; then
            POS=$(( POS + 1 ))
            parse_power
            case "$tv" in
                \*) result=$(calc "$result * $RESULT") ;;
                /)
                    if [[ $(calc "$RESULT == 0") == "1" ]]; then
                        echo "Error: Division by zero." >&2; exit 1
                    fi
                    result=$(calc "$result / $RESULT")
                    ;;
                %)
                    if [[ $(calc "$RESULT == 0") == "1" ]]; then
                        echo "Error: Modulo by zero." >&2; exit 1
                    fi
                    result=$(calc "$result % $RESULT")
                    ;;
            esac
        else
            break
        fi
    done

    RESULT="$result"
}

parse_power() {
    parse_unary
    local base="$RESULT"

    local tt
    tt=$(peek_type)
    local tv
    tv=$(peek_value)
    if [[ "$tt" == "Operator" ]] && [[ "$tv" == "^" ]]; then
        POS=$(( POS + 1 ))
        parse_power  # right-associative
        RESULT=$(calc "$base ^ $RESULT")
    else
        RESULT="$base"
    fi
}

parse_unary() {
    local tt
    tt=$(peek_type)
    local tv
    tv=$(peek_value)
    if [[ "$tt" == "Operator" ]] && [[ "$tv" == "+" || "$tv" == "-" ]]; then
        POS=$(( POS + 1 ))
        parse_unary
        if [[ "$tv" == "-" ]]; then
            RESULT=$(calc "- ($RESULT)")
        fi
        return
    fi
    parse_atom
}

parse_atom() {
    local tt
    tt=$(peek_type)
    local tv
    tv=$(peek_value)

    if [[ -z "$tt" ]]; then
        echo "Error: Unexpected end of expression." >&2
        exit 1
    fi

    if [[ "$tt" == "Number" ]]; then
        POS=$(( POS + 1 ))
        RESULT="$tv"
        return
    fi

    if [[ "$tt" == "LParen" ]]; then
        POS=$(( POS + 1 ))
        parse_expression

        local ct
        ct=$(peek_type)
        if [[ "$ct" != "RParen" ]]; then
            echo "Error: Missing closing parenthesis." >&2
            exit 1
        fi
        POS=$(( POS + 1 ))
        return
    fi

    echo "Error: Unexpected token '$tv'." >&2
    exit 1
}

# â”€â”€ Auto-detection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

is_prefix_notation() {
    if (( TOKEN_COUNT < 3 )) || [[ "${TOKEN_TYPES[0]}" != "Operator" ]]; then
        return 1
    fi
    if (( TOKEN_COUNT == 2 )) && [[ "${TOKEN_TYPES[1]}" == "Number" ]]; then
        return 1
    fi

    # Try a full prefix parse in a subshell
    if (
        POS=0
        eval_prefix
        (( POS == TOKEN_COUNT ))
    ) 2>/dev/null; then
        return 0
    fi
    return 1
}

# â”€â”€ Format output â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

format_result() {
    local val="$1"
    awk "BEGIN {
        v = $val + 0
        if (v == int(v) && v >= -9007199254740991 && v <= 9007199254740991)
            printf \"%d\n\", v
        else
            printf \"%.15g\n\", v
    }"
}

# â”€â”€ Main â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

if [[ $# -lt 1 ]]; then
    usage
fi

EXPRESSION="$1"
NOTATION="auto"
shift

while [[ $# -gt 0 ]]; do
    case "$1" in
        --notation)
            NOTATION="${2,,}"  # lowercase
            shift 2
            ;;
        *)
            echo "Error: Unknown option '$1'." >&2
            exit 1
            ;;
    esac
done

tokenize "$EXPRESSION"

if (( TOKEN_COUNT == 0 )); then
    echo "Error: Empty expression." >&2
    exit 1
fi

USE_PREFIX=false
case "$NOTATION" in
    prefix) USE_PREFIX=true ;;
    infix)  USE_PREFIX=false ;;
    auto)
        if is_prefix_notation; then
            USE_PREFIX=true
        fi
        ;;
    *)
        echo "Error: Unknown notation '$NOTATION'. Use auto, infix, or prefix." >&2
        exit 1
        ;;
esac

RESULT=""
POS=0

if $USE_PREFIX; then
    eval_prefix
    if (( POS != TOKEN_COUNT )); then
        echo "Error: Unexpected extra tokens after prefix expression." >&2
        exit 1
    fi
else
    parse_expression
    if (( POS != TOKEN_COUNT )); then
        echo "Error: Unexpected token '${TOKEN_VALUES[$POS]}' after end of expression." >&2
        exit 1
    fi
fi

format_result "$RESULT"
