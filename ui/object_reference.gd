extends RefCounted
## Host presentation identity. A survey source is never a navigation index.
static func valid(reference: Dictionary) -> bool:
	return reference.get("kind") in ["catalogue", "body", "survey"] and reference.get("id") is String and not reference.id.is_empty()
static func from_inspection(id: String) -> Dictionary:
	return {"kind": "body", "id": id.trim_prefix("body:")} if id.begins_with("body:") else {"kind": "catalogue", "id": id}
