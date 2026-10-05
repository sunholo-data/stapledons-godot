class_name LoreBinding
extends RefCounted
## M4.7 codex text is a LoreBinding{entry_id} (design m4-first-journey.md, display audit): the body
## the codex shows must hash-equal (sha256) the body of the vendored entry, whose numbers
## `make lore-check` vouches for. Any other text, even one character different, fails.

var entry_id := ""


func check(shown_body: String) -> bool:
	if entry_id == "":
		return false
	var want := LoreLoader.body_sha(entry_id)
	return want != "" and LoreLoader.sha256_text(shown_body) == want
