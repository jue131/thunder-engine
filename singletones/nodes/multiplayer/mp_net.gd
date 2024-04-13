extends Node
# Generic class for rpc with return value
#class DoubleRpc extends Node:
	#signal done  # TODO: add an optional timer to force signal after timeout.
	#var status
	#var response
	#
	## Override this method to provide real server logic
	#func server_process(request):
		#response = {}
		#return Status.new()
	#
	#@rpc("any_peer", "reliable")
	#func _send(request):
		#status = server_process(request)
		#var caller_id = multiplayer.get_remote_sender_id()
		#_reply.rpc_id(caller_id, status, response)
		#
	#@rpc("any_peer", "reliable")
	#func _reply(status, response):
		#self.status = status
		#self.response = response
		#done.emit()
		#
	#func run(peer_id, request):
		#_send.rpc_id(peer_id, request)
#
## A rpc implementation
#class FetchName extends DoubleRpc:
	#func server_process(request):
		#var name = "test name for " + request.user_id
		## get name from server data
		#response = {name = name}
		#return Status.new()
## This node must be added to the tree before usable
#var fetch_name_rpc := FetchName.new()
#
## Fetches name from server and wait for the return
#func fetch_name_and_wait():
	#fetch_name_rpc.run(1, {user_id = 123})
	#await fetch_name_rpc.done
	#return fetch_name_rpc.response.get("name")
