class_name ComposedBinding
extends DisplayBinding
## A sentence with numbers in it: fixed copy parts and sim fields, in order. Each number is
## `format_field` of one field (formatting and nothing more; a part is never computed). It is one
## DisplayBinding, so the display audit sees one binding whose text is exactly what it produced.
## parts: Strings (copy) and [field, fmt] pairs.

var parts: Array = []


func compose(p: Array) -> ComposedBinding:
	parts = p
	for x in p:
		if x is Array:
			field = x[0]
			break
	fmt = "%s"
	return self


func update_from(view: Dictionary) -> void:
	var s := ""
	for x in parts:
		s += x if x is String else DisplayBinding.format_field(view, x[0], x[1])
	_shown = s
	text = s
