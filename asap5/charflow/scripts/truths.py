"""Safe boolean expression evaluator and unate detection.

Replaces the original truths.py which used eval()/exec() — security risk.
Uses operator module for safe evaluation of logic expressions.
"""
import itertools
import operator
import re


def safe_eval_bool(expr, variables):
    """Evaluate a boolean expression safely using only known operators.

    Supports: &, |, ^, !, ~, and, or, not, parentheses.
    Variables are looked up in the 'variables' dict.

    Returns bool.
    """
    # Normalize operators
    expr = expr.replace('!', ' not ').replace('~', ' not ')
    expr = expr.replace('&', ' and ').replace('|', ' or ')
    expr = expr.replace('^', ' xor ')

    tokens = _tokenize(expr)
    result = _parse_expr(tokens, variables)
    return bool(result)


def _tokenize(expr):
    """Split expression into tokens."""
    return [t for t in re.findall(r'[()]|not|and|or|xor|\w+', expr) if t]


def _parse_expr(tokens, variables):
    """Recursive descent parser for boolean expressions."""
    pos = [0]

    def peek():
        return tokens[pos[0]] if pos[0] < len(tokens) else None

    def consume():
        t = tokens[pos[0]]
        pos[0] += 1
        return t

    def parse_or():
        left = parse_xor()
        while peek() == 'or':
            consume()
            right = parse_xor()
            left = left or right
        return left

    def parse_xor():
        left = parse_and()
        while peek() == 'xor':
            consume()
            right = parse_and()
            left = operator.xor(bool(left), bool(right))
        return left

    def parse_and():
        left = parse_not()
        while peek() == 'and':
            consume()
            right = parse_not()
            left = left and right
        return left

    def parse_not():
        if peek() == 'not':
            consume()
            return not parse_not()
        return parse_atom()

    def parse_atom():
        t = peek()
        if t == '(':
            consume()
            result = parse_or()
            if peek() == ')':
                consume()
            return result
        consume()
        if t in variables:
            return bool(variables[t])
        raise ValueError(f'Unknown variable: {t}')

    return parse_or()


def detect_unate(func_expr, input_pins, active_pin):
    """Detect whether active_pin is positive or negative unate.

    Returns (is_positive_unate: bool, static_pin_values: dict).
    static_pin_values maps non-active input pins to the logic values
    that enable the active_pin's timing path.
    """
    other_pins = [p for p in input_pins if p != active_pin]

    # Try all combinations of other pins to find one where
    # toggling active_pin changes the output
    for combo in itertools.product([False, True], repeat=len(other_pins)):
        pin_vals = dict(zip(other_pins, combo))

        # Evaluate with active_pin=0 and active_pin=1
        pin_vals[active_pin] = False
        out_low = safe_eval_bool(func_expr, pin_vals)

        pin_vals[active_pin] = True
        out_high = safe_eval_bool(func_expr, pin_vals)

        if out_low != out_high:
            # Found a sensitizing condition
            static_values = {p: int(v) for p, v in zip(other_pins, combo)}
            is_positive = (out_high == True and out_low == False)
            return is_positive, static_values

    raise ValueError(
        f'Cannot find sensitizing condition for {active_pin} in {func_expr}'
    )
