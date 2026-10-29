extends SceneTree
## Private review harness: stage declared exports, then serve that directory only.
## godot --headless --path . --script tools/view_finish_preview.gd -- stage
## godot --headless --path . --script tools/view_finish_preview.gd -- serve
const OUT := "res://build/view-finish-review"
const CONFIG := "res://art/view-finish-v1/review.json"
var listener := TCPServer.new()
var clients: Array = []
var serving := false

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or args[0] not in ["stage", "serve"]:
		printerr("usage: view_finish_preview.gd -- stage|serve")
		quit(2)
		return
	if args[0] == "stage":
		quit(_stage())
	else:
		var err := listener.listen(8984, "127.0.0.1")
		if err != OK:
			printerr("preview: listen failed ", err)
			quit(1)
			return
		serving = true
		print("view-finish-preview: http://127.0.0.1:8984 (staged exports only)")

func _stage() -> int:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not data is Dictionary:
		printerr("preview: invalid config")
		return 1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var manifest := {"title": data.title, "revision": data.revision, "round": data.round, "notice": data.get("notice", ""), "frames": [], "downloads": []}
	for frame: Dictionary in data.frames:
		var source: String = frame.source
		var name: String = frame.file
		if not _safe_name(name) or not FileAccess.file_exists(source):
			printerr("preview: missing or unsafe frame ", source)
			return 1
		var destination := OUT.path_join(name)
		var err := DirAccess.copy_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(destination))
		if err != OK:
			printerr("preview: copy failed ", source)
			return 1
		var row := frame.duplicate()
		row.erase("source")
		row.sha256 = FileAccess.get_sha256(destination)
		manifest.frames.append(row)
	for item: Dictionary in data.get("downloads", []):
		var source: String=item.source
		var name: String=item.file
		if not _safe_name(name) or name.get_extension()!="zip" or not FileAccess.file_exists(source):
			printerr("preview: missing or unsafe download ",source);return 1
		var destination:=OUT.path_join(name)
		# Download names include their build commit. Keep an existing verified archive intact
		# while refreshing image rounds, including any transfer already in progress.
		if FileAccess.file_exists(destination) and FileAccess.get_sha256(destination)!=FileAccess.get_sha256(source):
			printerr("preview: immutable download name has different bytes ",name);return 1
		if not FileAccess.file_exists(destination) and DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(destination))!=OK:
			printerr("preview: download copy failed ",source);return 1
		var row:=item.duplicate();row.erase("source")
		row.sha256=FileAccess.get_sha256(destination)
		var archive:=FileAccess.open(destination,FileAccess.READ)
		row.bytes=archive.get_length()
		manifest.downloads.append(row)
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	var html := FileAccess.get_file_as_string("res://art/view-finish-v1/review.html")
	file = FileAccess.open(OUT.path_join("index.html"), FileAccess.WRITE)
	file.store_string(html)
	file.close()
	print("view-finish-preview: staged %d declared frames (%s)" % [manifest.frames.size(), data.round])
	return 0

func _safe_name(name: String) -> bool:
	if name.is_empty() or name.get_file() != name or name.begins_with("."):
		return false
	var expression := RegEx.new()
	expression.compile("^[a-zA-Z0-9_-]+\\.(png|json|html|webp|zip)$")
	return expression.search(name) != null

func _process(_dt: float) -> bool:
	if not serving:
		return false
	while listener.is_connection_available():
		clients.append({"socket": listener.take_connection(), "request": PackedByteArray(), "age": 0.0})
	for i in range(clients.size() - 1, -1, -1):
		var client: Dictionary = clients[i]
		var socket: StreamPeerTCP = client.socket
		socket.poll()
		client.age += _dt
		var available := socket.get_available_bytes()
		if available > 0:
			var packet := socket.get_data(available)
			if packet[0] == OK:
				client.request.append_array(packet[1])
		if client.request.size() > 8192 or client.age > 5.0:
			socket.disconnect_from_host()
			clients.remove_at(i)
			continue
		if client.request.get_string_from_utf8().contains("\r\n\r\n"):
			_respond(socket, client.request.get_string_from_utf8())
			clients.remove_at(i)
		elif socket.get_status() == StreamPeerTCP.STATUS_NONE:
			clients.remove_at(i)
	return false

func _respond(socket: StreamPeerTCP, request: String) -> void:
	var parts := request.get_slice("\r\n", 0).split(" ")
	var status := "404 Not Found"
	var mime := "text/plain; charset=utf-8"
	var body := "Not found\n".to_utf8_buffer()
	var body_size:=body.size()
	var method := parts[0] if parts.size() >= 2 else ""
	if method in ["GET", "HEAD"]:
		var name := parts[1].get_slice("?", 0).trim_prefix("/")
		if name.is_empty():
			name = "index.html"
		# Only filenames explicitly present in the staged manifest are accessible.
		var allowed := ["index.html", "manifest.json"]
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT.path_join("manifest.json")))
		if manifest is Dictionary:
			for frame: Dictionary in manifest.get("frames", []):
				allowed.append(str(frame.file))
			for item: Dictionary in manifest.get("downloads", []):
				allowed.append(str(item.file))
		if _safe_name(name) and name in allowed:
			var path := OUT.path_join(name)
			if FileAccess.file_exists(path):
				var file:=FileAccess.open(path,FileAccess.READ)
				body_size=file.get_length()
				if method=="GET":body=file.get_buffer(body_size)
				status = "200 OK"
				mime = {"png": "image/png", "webp": "image/webp", "json": "application/json", "html": "text/html; charset=utf-8", "zip": "application/zip"}.get(name.get_extension(), mime)
	else:
		status = "405 Method Not Allowed"
		body = "Method not allowed\n".to_utf8_buffer()
		body_size=body.size()
	var headers := "HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nConnection: close\r\n\r\n" % [status, mime, body_size]
	socket.put_data(headers.to_utf8_buffer())
	if method != "HEAD":
		socket.put_data(body)
	socket.disconnect_from_host()
