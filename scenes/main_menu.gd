extends Control

@onready var grid_size_input: LineEdit = $VBoxContainer/GridSizeInput
@onready var players_input: LineEdit = $VBoxContainer/PlayersInput
@onready var custom_board_check: CheckBox = $VBoxContainer/CustomBoardCheck
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var start_button: Button = $VBoxContainer/StartButton

func _ready():
	# Устанавливаем значения по умолчанию
	grid_size_input.text = "5"
	players_input.text = "2"
	custom_board_check.button_pressed = false
	
	# Подключаем сигнал кнопки
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
	var grid_size = grid_size_input.text.to_int()
	var num_players = players_input.text.to_int()
	var use_custom_board = custom_board_check.button_pressed
	
	# Проверяем валидность ввода
	if grid_size < 3 or grid_size > 10:
		status_label.text = "Размер сетки должен быть от 3 до 10"
		return
		
	if num_players < 2 or num_players > 8:
		status_label.text = "Количество игроков должно быть от 2 до 8"
		return
	
	# Сохраняем настройки в глобальные переменные
	GameSettings.grid_size = grid_size
	GameSettings.num_players = num_players
	GameSettings.use_custom_board = use_custom_board
	
	# Переходим к игре
	if use_custom_board:
		get_tree().change_scene_to_file("res://scenes/board_editor.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game_board.tscn")

func _on_restart_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn") 
