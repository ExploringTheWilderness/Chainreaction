extends Control

@onready var board_container: Control = $BoardContainer
@onready var status_label: Label = $StatusLabel
@onready var restart_button: Button = $RestartButton

var grid_size
var num_players
var current_player = 1
var total_moves = 0
var is_processing_explosions = false
var game_over = false

# Игровое поле
var board = []
var horizontal_walls = []
var vertical_walls = []

# Визуальные элементы
var cell_widgets = []

# Класс для визуализации клетки
class CellWidget extends Control:
	var i := 0
	var j := 0
	var cell_size := 0.0
	var cell_ref = null
	func _draw():
		# Рисуем рамку
		draw_rect(Rect2(Vector2.ZERO, Vector2(cell_size, cell_size)), Color.BLACK, false, 2)
		if cell_ref == null:
			return
		# Рисуем кружки по directions
		var offset = cell_size / 4
		var small_r = cell_size / 10
		var big_r = small_r * 1.5
		var center = Vector2(cell_size/2, cell_size/2)
		for dr in cell_ref.directions:
			var pos = center
			if dr == "up":
				pos += Vector2(0, -offset)
			elif dr == "down":
				pos += Vector2(0, offset)
			elif dr == "left":
				pos += Vector2(-offset, 0)
			elif dr == "right":
				pos += Vector2(offset, 0)
			var is_occupied = dr in cell_ref.occupied_slots
			if is_occupied:
				var p = cell_ref.player
				if p > 0:
					draw_circle(pos, big_r, GameSettings.player_colors[p-1])
				else:
					draw_circle(pos, big_r, Color(0.5,0.5,0.5))
			else:
				draw_circle(pos, small_r, Color(0.5,0.5,0.5))

func _ready():
	grid_size = GameSettings.grid_size
	num_players = GameSettings.num_players
	restart_button.pressed.connect(_on_restart_button_pressed)
	if GameSettings.use_custom_board and GameSettings.horizontal_walls.size() > 0:
		horizontal_walls = GameSettings.horizontal_walls
		vertical_walls = GameSettings.vertical_walls
	else:
		horizontal_walls = []
		for i in range(grid_size - 1):
			horizontal_walls.append([])
			for j in range(grid_size):
				horizontal_walls[i].append(false)
		vertical_walls = []
		for i in range(grid_size):
			vertical_walls.append([])
			for j in range(grid_size - 1):
				vertical_walls[i].append(false)
	create_board()
	create_visual_board()
	start_game()

func create_board():
	board = []
	for i in range(grid_size):
		board.append([])
		for j in range(grid_size):
			board[i].append(Cell.new())
			update_cell_directions(i, j)

func update_cell_directions(row, col):
	var cell = board[row][col]
	cell.directions.clear()
	if row > 0 and not horizontal_walls[row - 1][col]:
		cell.directions.append("up")
	if row < grid_size - 1 and not horizontal_walls[row][col]:
		cell.directions.append("down")
	if col > 0 and not vertical_walls[row][col - 1]:
		cell.directions.append("left")
	if col < grid_size - 1 and not vertical_walls[row][col]:
		cell.directions.append("right")

func create_visual_board():
	await get_tree().process_frame
	var cell_size = min(board_container.size.x / grid_size, board_container.size.y / grid_size)
	cell_widgets = []
	board_container.get_children().map(func(c): c.queue_free())
	for i in range(grid_size):
		cell_widgets.append([])
		for j in range(grid_size):
			var cell_widget = CellWidget.new()
			cell_widget.i = i
			cell_widget.j = j
			cell_widget.cell_size = cell_size
			cell_widget.cell_ref = board[i][j]
			cell_widget.position = Vector2(j * cell_size, i * cell_size)
			cell_widget.size = Vector2(cell_size, cell_size)
			board_container.add_child(cell_widget)
			cell_widgets[i].append(cell_widget)

func update_visual_board():
	for i in range(grid_size):
		for j in range(grid_size):
			cell_widgets[i][j].queue_redraw()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_click(event.position)

func handle_click(pos: Vector2):
	if is_processing_explosions or game_over:
		return
	var local_pos = pos - board_container.global_position
	var cell_size = min(board_container.size.x / grid_size, board_container.size.y / grid_size)
	var col = int(local_pos.x / cell_size)
	var row = int(local_pos.y / cell_size)
	if row < 0 or row >= grid_size or col < 0 or col >= grid_size:
		return
	var cell = board[row][col]
	if cell.player != -1 and cell.player != current_player:
		return
	is_processing_explosions = true
	var best_direction = find_best_slot(row, col, local_pos, cell_size)
	if best_direction != "":
		await place_chip(row, col, best_direction)
		is_processing_explosions = false

func find_best_slot(row, col, local_pos, cell_size):
	var cell = board[row][col]
	var cell_center = Vector2(col * cell_size + cell_size / 2, row * cell_size + cell_size / 2)
	var min_distance = INF
	var best_direction = ""
	for direction in cell.directions:
		if direction in cell.occupied_slots:
			continue
		var slot_pos = cell_center
		var offset = cell_size / 4
		if direction == "up":
			slot_pos += Vector2(0, -offset)
		elif direction == "down":
			slot_pos += Vector2(0, offset)
		elif direction == "left":
			slot_pos += Vector2(-offset, 0)
		elif direction == "right":
			slot_pos += Vector2(offset, 0)
		var distance = local_pos.distance_to(slot_pos)
		if distance < min_distance:
			min_distance = distance
			best_direction = direction
	if min_distance < cell_size / 6:
		return best_direction
	return ""

func place_chip(row, col, direction):
	var cell = board[row][col]
	cell.add_chip(direction, current_player)
	total_moves += 1
	update_visual_board()
	if cell.is_full():
		await get_tree().create_timer(0.5).timeout
		process_explosions()
	else:
		await get_tree().create_timer(0.2).timeout
		next_player()

func process_explosions():
	if check_game_over():
		game_over = true
		update_status()
		is_processing_explosions = false
		return
	var full_cells = []
	for i in range(grid_size):
		for j in range(grid_size):
			if board[i][j].is_full():
				full_cells.append(Vector2i(i, j))
	if full_cells.is_empty():
		await get_tree().create_timer(0.2).timeout
		is_processing_explosions = false
		next_player()
		return
	var explosions = []
	for cell_pos in full_cells:
		var cell = board[cell_pos.x][cell_pos.y]
		var chips = cell.clear()
		for chip in chips:
			var direction = chip.direction
			var player_id = chip.player
			var new_pos = cell_pos + GameSettings.directions[direction]
			if new_pos.x >= 0 and new_pos.x < grid_size and new_pos.y >= 0 and new_pos.y < grid_size:
				explosions.append({
					"from_pos": cell_pos,
					"to_pos": new_pos,
					"direction": direction,
					"opposite": GameSettings.opposites[direction],
					"player": player_id
				})
	animate_explosions(explosions)

func animate_explosions(explosions):
	if explosions.is_empty():
		await get_tree().create_timer(0.5).timeout
		process_explosions()
		return
	var animation_data = {"completed": 0, "total": explosions.size()}
	for explosion in explosions:
		var chip_sprite = ColorRect.new()
		chip_sprite.size = Vector2(20, 20)
		chip_sprite.color = GameSettings.player_colors[explosion.player - 1]
		var from_pos = get_slot_position(Vector2(explosion.from_pos.y * 50 + 25, explosion.from_pos.x * 50 + 25), explosion.direction, 50)
		var to_pos = get_slot_position(Vector2(explosion.to_pos.y * 50 + 25, explosion.to_pos.x * 50 + 25), explosion.opposite, 50)
		chip_sprite.position = from_pos - Vector2(10, 10)
		board_container.add_child(chip_sprite)
		var tween = create_tween()
		tween.tween_property(chip_sprite, "position", to_pos - Vector2(10, 10), 0.5)
		tween.tween_callback(func():
			board[explosion.to_pos.x][explosion.to_pos.y].add_chip(explosion.opposite, explosion.player)
			chip_sprite.queue_free()
			animation_data.completed += 1
			if animation_data.completed >= animation_data.total:
				update_visual_board()
				await get_tree().create_timer(0.5).timeout
				process_explosions()
		)

func get_slot_position(center, direction, cell_size):
	var offset = cell_size / 4
	match direction:
		"up":
			return center + Vector2(0, -offset)
		"down":
			return center + Vector2(0, offset)
		"left":
			return center + Vector2(-offset, 0)
		"right":
			return center + Vector2(offset, 0)
		_:
			return center

func next_player():
	current_player = (current_player % num_players) + 1
	var counts = count_chips()
	while counts.get(current_player, 0) == 0 and has_empty_cells():
		current_player = (current_player % num_players) + 1
	update_status()

func count_chips():
	var counts = {}
	for i in range(grid_size):
		for j in range(grid_size):
			var cell = board[i][j]
			if cell.player > 0:
				counts[cell.player] = counts.get(cell.player, 0) + cell.occupied_slots.size()
	return counts

func has_empty_cells():
	for i in range(grid_size):
		for j in range(grid_size):
			if board[i][j].player == -1:
				return true
	return false

func check_game_over():
	if total_moves < num_players:
		return false
	var counts = count_chips()
	var remaining_players = 0
	for player_id in range(1, num_players + 1):
		if counts.get(player_id, 0) > 0:
			remaining_players += 1
	return remaining_players <= 1

func get_winner():
	var counts = count_chips()
	var max_chips = 0
	var winner = -1
	for player_id in range(1, num_players + 1):
		var chips = counts.get(player_id, 0)
		if chips > max_chips:
			max_chips = chips
			winner = player_id
	return winner

func update_status():
	if game_over:
		var winner = get_winner()
		if winner > 0:
			status_label.text = "Игрок %d победил!" % winner
		else:
			status_label.text = "Ничья!"
		restart_button.visible = true
	else:
		status_label.text = "Ход игрока %d" % current_player

func _on_restart_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn") 

func start_game():
	current_player = 1
	total_moves = 0
	is_processing_explosions = false
	game_over = false
	update_status() 
