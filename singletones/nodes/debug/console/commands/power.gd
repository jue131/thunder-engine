extends Command

static func register() -> Command:
	return new().set_name("power").add_param("character", TYPE_STRING).add_param("state", TYPE_STRING).set_description("Set current player power state. Only built-in states for now")

func execute(args:Array) -> Command.ExecuteResult:
	var character: String = args[0]
	var suit = load("res://engine/objects/players/prefabs/suits/%s/%s_%s_suit.tscn" % [character, args[1], character])
	if !suit:
		return Command.ExecuteResult.new(
			"""Try one of these: 
			For \"character\": mario.
			For \"power\": beetroot, super, fireball, green_lui, small"""
		)
	
	var pl: Player = Thunder._current_player
	pl.change_suit(suit.instantiate())
	return Command.ExecuteResult.new("Success")

