extends Node
## Negative control for `make lint-precision`: nothing here may be flagged.

func clean(beta: float, one_minus_beta: float, beta_x: float, b_x: float, bx: float) -> float:
	var a := one_minus_beta
	var b := 21.0 - beta_x
	var c := 2.1 - beta_x
	var e := 21.0 - b
	var g := 1.0 - b_x
	var h := 1.0 - bx
	var label := "1 - beta" # a label string, not a computation
	var other := '1.0-beta'
	return a + b + c + e + g + h + 1.0 - 0.5 + label.length() + other.length()
