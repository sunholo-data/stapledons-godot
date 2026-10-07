extends Node
## Negative control for `make lint-precision`: nothing here may be flagged.

func clean(beta: float, one_minus_beta: float, beta_x: float) -> float:
	var a := one_minus_beta
	var b := 21.0 - beta_x
	var c := 2.1 - beta_x
	var label := "1 - beta" # a label string, not a computation
	var other := '1.0-beta'
	return a + b + c + 1.0 - 0.5 + label.length() + other.length()
