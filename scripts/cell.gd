class_name Cell
extends RefCounted

var player: int = -1  # -1 означает отсутствие игрока
var directions: Array[String] = []
var occupied_slots: Array[String] = []
var pending_chips: Array[Dictionary] = []

func _init():
	pass

func add_chip(direction: String, player_id: int) -> bool:
	# Проверяем, есть ли свободный слот
	if direction in directions and direction not in occupied_slots:
		occupied_slots.append(direction)
		if player == -1 or player == player_id:
			player = player_id
		return true
	else:
		# Добавляем в очередь ожидания
		pending_chips.append({
			"direction": direction,
			"player": player_id
		})
		return false

func is_full() -> bool:
	return occupied_slots.size() >= directions.size()

func clear() -> Array[Dictionary]:
	# Возвращаем все фишки для взрыва
	var chips = []
	for slot in occupied_slots:
		chips.append({
			"direction": slot,
			"player": player
		})
	
	# Очищаем ячейку
	occupied_slots.clear()
	player = -1
	
	# Обрабатываем ожидающие фишки
	for pending in pending_chips:
		add_chip(pending.direction, pending.player)
	
	pending_chips.clear()
	
	return chips

func get_available_slots() -> Array[String]:
	var available = []
	for direction in directions:
		if direction not in occupied_slots:
			available.append(direction)
	return available 