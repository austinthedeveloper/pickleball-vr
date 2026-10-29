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
##
## ANYWHERE (ADR-026): the headset also opens a room on the relay (the
## port kit's design/RELAY.md) and sends it this page, so a coach can open
## it from anywhere at RELAY/c/ROOM. The relay's guests are coaches like
## the Wi-Fi's: the same JSON, the same code, inside binary frames.
class_name Coach
extends Node

const PORT := 8094
const PAGE := "res://coach/index.html"
const MAX_REQUEST := 8192
const HTTP_TIMEOUT := 3.0            ## a request that doesn't arrive whole, dropped
const INBOUND := 1 << 20             ## a coach's biggest message, bytes: 8 s of voice, base64

const RELAY := "wss://pb94-relay.wonderfulground-3bc64e4e.eastus.azurecontainerapps.io"
const RELAY_GAME := "pb94-vr-coach"
const RELAY_RETRY := [2.0, 5.0, 10.0, 30.0]   ## seconds before each try again
const RELAY_KEEP := 60.0             ## a word to the relay this often, so a quiet room stays open

signal command(msg: Dictionary)      ## an authorised coach's message
signal room_changed                  ## ANYWHERE's room opened, or closed

var code := ""                       ## the four digits the headset shows
var port := PORT
var _http := TCPServer.new()
var _ws := TCPServer.new()
var _requests: Array = []            ## [StreamPeerTCP, bytes so far, seconds waited]
var _peers: Array = []               ## [WebSocketPeer, authorised]
var _page := PackedByteArray()
var relay := ""                      ## ANYWHERE: the relay's address, or "" for Wi-Fi only
var room := ""                       ## the relay's room code, once it's open
var _relay: WebSocketPeer
var _guests := {}                    ## the relay's guest number -> authorised
var _relay_wait := 0.0               ## seconds until the next try
var _relay_tries := 0
var _relay_keep := 0.0


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
	if _relay:
		_relay.close()
	for p in _peers:
		(p[0] as WebSocketPeer).close()
	_http.stop()
	_ws.stop()


## Is it serving?
func listening() -> bool:
	return _http.is_listening() and _ws.is_listening()


## Coaches connected and past the code.
func coaches() -> int:
	return _peers.filter(func(p: Array) -> bool: return p[1]).size() \
		+ _guests.values().filter(func(a: bool) -> bool: return a).size()


## ANYWHERE on or off: a room on the relay at `url`, or none.
func set_relay(url: String) -> void:
	if url == relay:
		return
	relay = url
	_relay_close()
	_relay_tries = 0
	_relay_wait = 0.0


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
	_serve_relay(delta)


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
		p.inbound_buffer_size = INBOUND     # a voice clip or a photo in one message (ADR-025)
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
			e[1] = _receive(p.get_packet(), e[1], func(m: Dictionary) -> void: _send(p, m))


## A coach's message, from the Wi-Fi or the relay: the code first, then
## commands. Returns whether that coach is authorised now.
func _receive(bytes: PackedByteArray, authorised: bool, reply: Callable) -> bool:
	var msg: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not msg is Dictionary:
		return authorised
	if not authorised:
		if String(msg.get("type", "")) == "hello" and String(msg.get("code", "")) == code:
			reply.call({"type": "welcome"})
			return true
		reply.call({"type": "bad_code"})
		return false
	command.emit(msg)
	return true


func _serve_relay(delta: float) -> void:
	if relay == "":
		return
	if _relay == null:
		_relay_wait -= delta
		if _relay_wait <= 0.0:
			_relay_open()
		return
	_relay.poll()
	var st := _relay.get_ready_state()
	if st == WebSocketPeer.STATE_CLOSED:
		push_warning("coach: the relay closed (%d %s)" % [_relay.get_close_code(), _relay.get_close_reason()])
		_relay_close()
		_relay_wait = RELAY_RETRY[mini(_relay_tries, RELAY_RETRY.size() - 1)]
		_relay_tries += 1
		return
	if st != WebSocketPeer.STATE_OPEN:
		return
	_relay_keep += delta
	if _relay_keep >= RELAY_KEEP and room != "":
		_relay_keep = 0.0
		_relay.send_text(JSON.stringify({"op": "keep"}))
	while _relay.get_available_packet_count() > 0:
		var bytes := _relay.get_packet()
		if _relay.was_string_packet():
			_relay_control(JSON.parse_string(bytes.get_string_from_utf8()))
		elif bytes.size() > 1 and _guests.has(bytes[0]):
			var g: int = bytes[0]
			_guests[g] = _receive(bytes.slice(1), _guests[g], func(m: Dictionary) -> void: _send_guest(g, m))


## The relay's own messages: the room, and coaches coming and going.
func _relay_control(msg: Variant) -> void:
	if not msg is Dictionary:
		return
	match String(msg.get("op", "")):
		"room":
			room = String(msg.get("code", ""))
			_relay_tries = 0
			_relay.send_text(JSON.stringify({"op": "page", "html": _page.get_string_from_utf8()}))
			print("coach: anywhere at %s/c/%s" % [relay.replace("wss://", "https://"), room])
			room_changed.emit()
		"joined":
			# The room is the key (ADR-026): a coach who found it needs no code.
			var g := int(msg.get("guest", 0))
			_guests[g] = true
			_send_guest(g, {"type": "welcome"})
		"left":
			_guests.erase(int(msg.get("guest", 0)))


func _relay_open() -> void:
	_relay = WebSocketPeer.new()
	_relay.inbound_buffer_size = INBOUND + 1024
	_relay.outbound_buffer_size = maxi(1 << 18, _page.size() * 2)
	var ver := String(ProjectSettings.get_setting("application/config/version", ""))
	var err := _relay.connect_to_url("%s/v1/host?game=%s&ver=%s" % [relay, RELAY_GAME, ver.uri_encode()])
	if err != OK:
		push_warning("coach: can't reach the relay (%d)" % err)
		_relay = null
		_relay_wait = RELAY_RETRY[mini(_relay_tries, RELAY_RETRY.size() - 1)]
		_relay_tries += 1


func _relay_close() -> void:
	if _relay:
		_relay.close()
	_relay = null
	_guests.clear()
	_relay_keep = 0.0
	if room != "":
		room = ""
		room_changed.emit()


## To every authorised coach.
func broadcast(msg: Dictionary) -> void:
	for e in _peers:
		if e[1]:
			_send(e[0], msg)
	for g in _guests:
		if _guests[g]:
			_send_guest(g, msg)


## To one of the relay's coaches: its number, then the JSON.
func _send_guest(g: int, msg: Dictionary) -> void:
	if _relay and _relay.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var out := PackedByteArray([g])
		out.append_array(JSON.stringify(msg, "", false).to_utf8_buffer())
		_relay.send(out)


func _send(p: WebSocketPeer, msg: Dictionary) -> void:
	if p.get_ready_state() == WebSocketPeer.STATE_OPEN:
		p.send_text(JSON.stringify(msg, "", false))   # in order: the PRANKS buttons keep theirs
