## The tests' stand-in for pickleball-relay: one room, as the relay frames
## it. The first to dial is the host (room BXKM), the second the guest
## (number 0).
class_name StandInRelay
extends RefCounted

var server := TCPServer.new()
var peers: Array = []            ## [WebSocketPeer, greeted]

func _init(port: int) -> void:
	server.listen(port, "127.0.0.1")

func pump() -> void:
	while server.is_connection_available():
		var ws := WebSocketPeer.new()
		ws.inbound_buffer_size = 1 << 20
		ws.outbound_buffer_size = 1 << 20
		ws.accept_stream(server.take_connection())
		peers.append([ws, false])
	for i in peers.size():
		var ws: WebSocketPeer = peers[i][0]
		ws.poll()
		if ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
			continue
		if not peers[i][1]:
			peers[i][1] = true
			if i == 0:
				ws.send_text(JSON.stringify({"op": "room", "code": "BXKM"}))
			else:
				ws.send_text(JSON.stringify({"op": "welcome", "you": 0, "ver": ""}))
				(peers[0][0] as WebSocketPeer).send_text(JSON.stringify({"op": "joined", "guest": 0, "ver": ""}))
		while ws.get_available_packet_count() > 0:
			var b := ws.get_packet()
			if ws.was_string_packet() or peers.size() < 2:
				continue
			if i == 0:
				(peers[1][0] as WebSocketPeer).send(b.slice(1))
			else:
				var out := PackedByteArray([0])
				out.append_array(b)
				(peers[0][0] as WebSocketPeer).send(out)

func stop() -> void:
	for p in peers:
		(p[0] as WebSocketPeer).close()
	server.stop()
