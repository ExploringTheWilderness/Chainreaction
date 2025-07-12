extends Control

@onready var board_container: Control = $BoardContainer
@onready var status_label: Label = $StatusLabel
@onready var done_button: Button = $DoneButton

var grid_size
var horizontal_walls = []
var vertical_walls = []
var wall_sprites = []

func _ready():
	grid_size = GameSettings.grid_size
	
	# Подключаем сигнал кнопки
	done_button.pressed.connect(_on_done_button_pressed)
	
	# Инициализируем стены
	horizontal_walls = Array()
	for i in range(grid_size - 1):
		horizontal_walls.append(Array())
		for j in range(grid_size):
			horizontal_walls[i].append(false)
	
	vertical_walls = Array()
	for i in range(grid_size):
		vertical_walls.append(Array())
		for j in range(grid_size - 1):
			vertical_walls[i].append(false)
	
	create_visual_board()
	status_label.text = "Переключайте стены, касаясь линий"

func create_visual_board():
	var cell_size = min(board_container.size.x / grid_size, board_container.size.y / grid_size)
	
	# Создаем ячейки
	for i in range(grid_size):
		for j in range(grid_size):
			var cell_sprite = ColorRect.new()
			cell_sprite.size = Vector2(cell_size, cell_size)
			cell_sprite.position = Vector2(j * cell_size, i * cell_size)
			cell_sprite.color = Color.WHITE
			cell_sprite.border_width = 2
			cell_sprite.border_color = Color.BLACK
			board_container.add_child(cell_sprite)
	
	# Создаем стены
	create_wall_sprites(cell_size)

func create_wall_sprites(cell_size: float):
	wall_sprites = Array()
	
	# Горизонтальные стены
	for i in range(grid_size - 1):
		wall_sprites.append(Array())
		for j in range(grid_size):
			var wall = ColorRect.new()
			wall.size = Vector2(cell_size, 3)
			wall.position = Vector2(j * cell_size, (i + 1) * cell_size - 1.5)
			wall.color = Color.GRAY
			board_container.add_child(wall)
			wall_sprites[i].append(wall)
	
	# Вертикальные стены
	for i in range(grid_size):
		for j in range(grid_size - 1):
			var wall = ColorRect.new()
			wall.size = Vector2(3, cell_size)
			wall.position = Vector2((j + 1) * cell_size - 1.5, i * cell_size)
			wall.color = Color.GRAY
			board_container.add_child(wall)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_click(event.position)

func handle_click(pos: Vector2):
	var local_pos = board_container.to_local(pos)
	var cell_size = min(board_container.size.x / grid_size, board_container.size.y / grid_size)
	var threshold = 20
	
	# Проверяем горизонтальные стены
	for i in range(grid_size - 1):
		for j in range(grid_size):
			var wall_y = (i + 1) * cell_size
			var wall_x1 = j * cell_size
			var wall_x2 = (j + 1) * cell_size
			
			if abs(local_pos.y - wall_y) < threshold and wall_x1 - threshold < local_pos.x and local_pos.x < wall_x2 + threshold:
				toggle_horizontal_wall(i, j)
				return
	
	# Проверяем вертикальные стены
	for i in range(grid_size):
		for j in range(grid_size - 1):
			var wall_x = (j + 1) * cell_size
			var wall_y1 = i * cell_size
			var wall_y2 = (i + 1) * cell_size
			
			if abs(local_pos.x - wall_x) < threshold and wall_y1 - threshold < local_pos.y and local_pos.y < wall_y2 + threshold:
				toggle_vertical_wall(i, j)
				return

func toggle_horizontal_wall(row: int, col: int):
	horizontal_walls[row][col] = not horizontal_walls[row][col]
	update_wall_visual(row, col, "horizontal")

func toggle_vertical_wall(row: int, col: int):
	vertical_walls[row][col] = not vertical_walls[row][col]
	update_wall_visual(row, col, "vertical")

func update_wall_visual(row: int, col: int, wall_type: String):
	var cell_size = min(board_container.size.x / grid_size, board_container.size.y / grid_size)
	
	if wall_type == "horizontal":
		var wall = wall_sprites[row][col]
		if horizontal_walls[row][col]:
			wall.color = Color.RED
		else:
			wall.color = Color.GRAY
	elif wall_type == "vertical":
		# Находим вертикальную стену в дочерних элементах
		var wall_x = (col + 1) * cell_size
		var wall_y = row * cell_size
		
		for child in board_container.get_children():
			if child is ColorRect and child.size.x == 3 and child.size.y == cell_size:
				if abs(child.position.x - (wall_x - 1.5)) < 1 and abs(child.position.y - wall_y) < 1:
					if vertical_walls[row][col]:
						child.color = Color.RED
					else:
						child.color = Color.GRAY
					break

func _on_done_button_pressed():
	# Сохраняем стены в настройки
	GameSettings.horizontal_walls = horizontal_walls
	GameSettings.vertical_walls = vertical_walls
	
	# Переходим к игре
	get_tree().change_scene_to_file("res://scenes/game_board.tscn") 