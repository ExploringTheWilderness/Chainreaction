extends Node

# Глобальные настройки игры
var grid_size = 5
var num_players = 2
var use_custom_board = false

# Кастомные стены
var horizontal_walls = []
var vertical_walls = []

# Цвета игроков (до 8 игроков)
var player_colors = [
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW,
	Color.PURPLE,
	Color.ORANGE,
	Color.PINK,
	Color.CYAN
]

# Направления движения
var directions = {
	"up": Vector2i(-1, 0),
	"down": Vector2i(1, 0),
	"left": Vector2i(0, -1),
	"right": Vector2i(0, 1)
}

# Противоположные направления
var opposites = {
	"up": "down",
	"down": "up",
	"left": "right",
	"right": "left"
} 