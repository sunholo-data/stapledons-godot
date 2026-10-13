extends Node
## Positive control for `make lint-precision`: every planted line below MUST be flagged (6 lines).
## It lives under tests/, which the lint skips, so it never fails the real tree.

func planted(beta: float, b: float) -> float:
	var a := 1.0 - beta
	var bb := 1 - beta
	var c := 1.0-beta
	var d := (1.00 -beta) * 2.0
	var e := 1.0 / sqrt(1.0 - b * b)
	var f := 1 - b
	return a + bb + c + d + e + f
