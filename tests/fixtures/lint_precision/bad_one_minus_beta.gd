extends Node
## Positive control for `make lint-precision`: every planted line below MUST be flagged (4 lines).
## It lives under tests/, which the lint skips, so it never fails the real tree.

func planted(beta: float) -> float:
	var a := 1.0 - beta
	var b := 1 - beta
	var c := 1.0-beta
	var d := (1.00 -beta) * 2.0
	return a + b + c + d
