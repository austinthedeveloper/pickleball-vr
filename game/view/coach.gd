## The coach companion (ADR-023): a web page a coach opens on a phone on
## the same Wi-Fi, served by the game itself. Nothing to install.
##
## - HTTP on PORT serves `coach/index.html` (and nothing else).
## - A WebSocket on PORT + 1 carries JSON both ways: the game sends the
##   state (a few times a second) and each of your shots; the coach sends
##   settings and START / PAUSE / RESUME / RESTART / MENU.
## - A coach must first send the CODE the headset shows: until then a
##   socket gets nothing and can do nothing.
##
## Only while COACH MODE is on (Settings.coach). Display and menu side
## only: commands reach the game through main, as a menu press would.
class_name Coach
extends Node

const PORT := 8094
const PAGE := "res://coach/index.html"
const MAX_REQUEST := 8192
const HTTP_TIMEOUT := 3.0            ## a request that doesn't arrive whole, dropped

signal command(msg: Dictionary)      ## an authorised coach's message

var code := ""                       ## the four digits the headset shows
var port := PORT
var _http := TCPServer.new()
var _ws := TCPServer.new()
var _requests: Array = []            ## [StreamPeerTCP, bytes so far, seconds waited]
var _peers: Array = []               ## [WebSocketPeer, authorised]
var _page := PackedByteArray()


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	code = "%04d" % rng.randi_range(0, 9999)
	_page = FileAccess.get_file_as_bytes(PAGE)
	var e1 := _http.listen(port)
	var e2 := _ws.listen(port + 1)
	if e1 != OK or e2 != OK:
		push_warning("coach: can't listen on %d/%d (%d, %d)" % [port, port + 1, e1, e2])
	else:
		print("coach: http://%s:%d  code %s" % [(addresses() + ["localhost"])[0], port, code])


func _exit_tree() -> void:
	for p in _peers:
		(p[0] as WebSocketPeer).close()
	_http.stop()
	_ws.stop()


## Is it serving?
func listening() -> bool:
	return _http.is_listening() and _ws.is_listening()


## Coaches connected and past the code.
func coaches() -> int:
	return _peers.filter(func(p: Array) -> bool: return p[1]).size()


## Where a phone on the same network finds it.
static func addresses() -> Array[String]:
	var out: Array[String] = []
	for a in IP.get_local_addresses():
		if a.begins_with("192.168.") or a.begins_with("10.") or a.begins_with("172."):
			out.append(a)
	return out


func _process(delta: float) -> void:
	_serve_pages(delta)
	_serve_sockets()


func _serve_pages(delta: float) -> void:
	while _http.is_connection_available():
		_requests.append([_http.take_connection(), PackedByteArray(), 0.0])
	for r in _requests.duplicate():
		var c: StreamPeerTCP = r[0]
		c.poll()
		var n := c.get_available_bytes()
		if n > 0:
			var got := c.get_partial_data(n)
			if got[0] == OK:
				r[1] = (r[1] as PackedByteArray) + (got[1] as PackedByteArray)
		r[2] += delta
		var text := (r[1] as PackedByteArray).get_string_from_utf8()
		if text.contains("\r\n\r\n") or (r[1] as PackedByteArray).size() > MAX_REQUEST or r[2] > HTTP_TIMEOUT \
				or c.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			if c.get_status() == StreamPeerTCP.STATUS_CONNECTED and text.contains("\r\n\r\n"):
				c.put_data(_respond(text.get_slice("\r\n", 0)))
			c.disconnect_from_host()
			_requests.erase(r)


## The reply to a request line: the page for GET /, else 404.
func _respond(line: String) -> PackedByteArray:
	var parts := line.split(" ")
	var path := parts[1] if parts.size() > 1 else ""
	if parts[0] == "GET" and (path == "/" or path.begins_with("/?") or path == "/index.html"):
		var head := "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\n" % _page.size() \
			+ "Cache-Control: no-store\r\nConnection: close\r\n\r\n"
		return head.to_utf8_buffer() + _page
	var body := "not found".to_utf8_buffer()
	return ("HTTP/1.1 404 Not Found\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % body.size()).to_utf8_buffer() + body


func _serve_sockets() -> void:
	while _ws.is_connection_available():
		var p := WebSocketPeer.new()
		if p.accept_stream(_ws.take_connection()) == OK:
			_peers.append([p, false])
	for e in _peers.duplicate():
		var p: WebSocketPeer = e[0]
		p.poll()
		var st := p.get_ready_state()
		if st == WebSocketPeer.STATE_CLOSED:
			_peers.erase(e)
			continue
		while st == WebSocketPeer.STATE_OPEN and p.get_available_packet_count() > 0:
			var msg: Variant = JSON.parse_string(p.get_packet().get_string_from_utf8())
			if not msg is Dictionary:
				continue
			if not e[1]:
				if String(msg.get("type", "")) == "hello" and String(msg.get("code", "")) == code:
					e[1] = true
					_send(p, {"type": "welcome"})
				else:
					_send(p, {"type": "bad_code"})
				continue
			command.emit(msg)


## To every authorised coach.
func broadcast(msg: Dictionary) -> void:
	for e in _peers:
		if e[1]:
			_send(e[0], msg)


func _send(p: WebSocketPeer, msg: Dictionary) -> void:
	if p.get_ready_state() == WebSocketPeer.STATE_OPEN:
		p.send_text(JSON.stringify(msg))
