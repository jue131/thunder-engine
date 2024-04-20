extends Control

@onready var connect_panel: Panel = $Connect
@onready var connect_name: LineEdit = $Connect/Name
@onready var ip_address: LineEdit = $Connect/IPAddress
@onready var error_label: Label = $Connect/ErrorLabel
@onready var btn_host: Button = $Connect/Host
@onready var btn_join: Button = $Connect/Join

@onready var players: Panel = $Players
@onready var start: Button = $Players/Start
@onready var list: ItemList = $Players/List
@onready var port_forward: Label = $Players/PortForward

@onready var error_dialog: AcceptDialog = $ErrorDialog
@onready var timer: Timer = $Connect/Timer

func _ready():
	# Called every time the node is added to the scene.
	Multiplayer.connection_failed.connect(_on_connection_failed)
	Multiplayer.connection_succeeded.connect(_on_connection_success)
	Multiplayer.player_list_changed.connect(refresh_lobby)
	Multiplayer.game_ended.connect(_on_game_ended)
	Multiplayer.game_error.connect(_on_game_error)
	port_forward.text = port_forward.text % [Multiplayer.DEFAULT_PORT]


func _on_host_pressed():
	var err = name_check(connect_name.text)
	if err: return
	
	var player_name = connect_name.text
	var ok = Multiplayer.host_game(player_name)
	if !ok: return

	connect_panel.hide()
	players.show()
	error_label.text = ""

	#if ok:
	#	Multiplayer.begin_game()
	refresh_lobby()


func _on_join_pressed():
	var err = name_check(connect_name.text)
	if err: return

	var ip = ip_address.text
	if !ip.is_valid_ip_address():
		error_label.text = "Invalid IP address!"
		return

	error_label.text = ""
	btn_host.disabled = true
	btn_join.disabled = true

	var player_name = connect_name.text
	timer.start()
	timer.timeout.connect(_on_connection_failed)
	Multiplayer.join_game(ip, player_name)


func name_check(new_name: String) -> bool:
	if new_name == "" || "%" in new_name:
		error_label.text = "Invalid name!"
		return true
	return false


func _on_connection_success():
	connect_panel.hide()
	timer.stop()
	players.show()


func _on_connection_failed():
	btn_host.disabled = false
	btn_join.disabled = false
	error_label.set_text("Connection failed.")


func _on_game_ended():
	show()
	connect_panel.show()
	players.hide()
	btn_host.disabled = false
	btn_join.disabled = false


func _on_game_error(errtxt):
	error_dialog.dialog_text = errtxt
	error_dialog.popup_centered()
	btn_host.disabled = false
	btn_join.disabled = false


func refresh_lobby():
	var player_list = Multiplayer.get_player_list()
	player_list.sort()
	list.clear()
	list.add_item(Multiplayer.player_name + " (You)")
	for p in player_list:
		list.add_item(p)

	start.disabled = !multiplayer.is_server()


func _on_start_pressed():
	Multiplayer.begin_game()


func _on_find_public_ip_pressed():
	OS.shell_open("https://icanhazip.com/")
