## The tests' stand-in for pickleball-relay: one room, as the relay frames
## it. The first to dial is the host (room BXKM); each one after is a guest,
## numbered from 0 as they come. The host's frames go to the guest their
## first byte names (255: all of them).
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
				ws.send_text(JSON.stringify({"op": "welcome", "you": i - 1, "ver": ""}))
				(peers[0][0] as WebSocketPeer).send_text(JSON.stringify({"op": "joined", "guest": i - 1, "ver": ""}))
		while ws.get_available_packet_count() > 0:
			var b := ws.get_packet()
			if ws.was_string_packet() or peers.size() < 2:
				continue
			if i == 0:
				for g in range(1, peers.size()):
					if b[0] == 255 or b[0] == g - 1:
						(peers[g][0] as WebSocketPeer).send(b.slice(1))
			else:
				var out := PackedByteArray([i - 1])
				out.append_array(b)
				(peers[0][0] as WebSocketPeer).send(out)

func stop() -> void:
	for p in peers:
		(p[0] as WebSocketPeer).close()
	server.stop()
