extends TileMap

var room_width: int
var room_height: int

var stack: Array[Vector2i] = []

@onready var generate_button: Button = get_node("UI/HBoxContainer/GenerateButton")
@onready var speed_button: Button = get_node("UI/HBoxContainer/SpeedButton")

enum {
	WATER, 
	SAND, 
	GRASS, 
	TREE
}

enum {
	INSTANT, 
	SLOW, 
	MEDIUM, 
	FAST
}

signal world_filled

var speed: int = 0: set = set_speed
var timer_speed = 0

func _ready():
	room_width = ProjectSettings.get("display/window/size/viewport_width")/16
	room_height = ProjectSettings.get("display/window/size/viewport_height")/16
	fill_world()
	
func get_empty_neighbors(xx: int, yy: int): 
	var neighbors = []
	if xx > 0 and get_cell_source_id(0, Vector2i(xx - 1, yy)) == -1: 
		neighbors.append(Vector2i(xx - 1, yy))
	if xx < room_width - 1 and get_cell_source_id(0, Vector2i(xx + 1, yy)) == -1: 
		neighbors.append(Vector2i(xx + 1, yy) )
	if yy > 0 and get_cell_source_id(0, Vector2i(xx, yy - 1)) == -1: 
		neighbors.append(Vector2i(xx, yy - 1))
	if yy < room_height - 1 and get_cell_source_id(0, Vector2i(xx, yy + 1)) == -1: 
		neighbors.append(Vector2i(xx, yy + 1))
	if xx > 0 and yy > 0 and get_cell_source_id(0, Vector2i(xx - 1, yy - 1)) == -1: 
		neighbors.append(Vector2i(xx - 1, yy - 1))
	if xx > 0 and yy < room_height - 1 and get_cell_source_id(0, Vector2i(xx - 1, yy + 1)) == -1: 
		neighbors.append(Vector2i(xx - 1, yy + 1))
	if xx < room_width - 1 and yy > 0 and get_cell_source_id(0, Vector2i(xx + 1, yy - 1)) == - 1: 
		neighbors.append(Vector2i(xx + 1, yy - 1))
	if xx < room_width - 1 and yy < room_height - 1 and get_cell_source_id(0, Vector2i(xx + 1, yy + 1)) == -1: 
		neighbors.append(Vector2i(xx + 1, yy + 1))
		
	return neighbors
	
func get_full_neighbors(xx: int, yy: int): 
	var neighbors = []
	if xx > 0 and get_cell_source_id(0, Vector2i(xx - 1, yy)) != -1: 
		neighbors.append(Vector2i(xx - 1, yy))
	if xx < room_width - 1 and get_cell_source_id(0, Vector2i(xx + 1, yy)) != -1: 
		neighbors.append(Vector2i(xx + 1, yy) )
	if yy > 0 and get_cell_source_id(0, Vector2i(xx, yy - 1)) != -1: 
		neighbors.append(Vector2i(xx, yy - 1))
	if yy < room_height - 1 and get_cell_source_id(0, Vector2i(xx, yy + 1)) != -1: 
		neighbors.append(Vector2i(xx, yy + 1))
	if xx > 0 and yy > 0 and get_cell_source_id(0, Vector2i(xx - 1, yy - 1)) != -1: 
		neighbors.append(Vector2i(xx - 1, yy - 1))
	if xx > 0 and yy < room_height - 1 and get_cell_source_id(0, Vector2i(xx - 1, yy + 1)) != -1: 
		neighbors.append(Vector2i(xx - 1, yy + 1))
	if xx < room_width - 1 and yy > 0 and get_cell_source_id(0, Vector2i(xx + 1, yy - 1)) != - 1: 
		neighbors.append(Vector2i(xx + 1, yy - 1))
	if xx < room_width - 1 and yy < room_height - 1 and get_cell_source_id(0, Vector2i(xx + 1, yy + 1)) != -1: 
		neighbors.append(Vector2i(xx + 1, yy + 1))
	return neighbors
	
func valid_area(cell: Vector2i): 
	var options = [WATER, SAND, GRASS, TREE]
	var neighbors = get_full_neighbors(cell.x, cell.y)
	for n in neighbors: 
		var tile = get_cell_atlas_coords(0, n).x
		match tile: 
			WATER: 
				options.erase(GRASS)
				options.erase(TREE)
			SAND: 
				options.erase(TREE)
			GRASS: 
				options.erase(WATER)
			TREE: 
				options.erase(WATER)
				options.erase(SAND)
	if WATER in options: 
		for i in range(3): 
			options.append(WATER)
	if GRASS in options: 
		for i in range(4): 
			options.append(GRASS)
	if SAND in options: 
		options.append(SAND)
	return options

func fill_world(): 
	var xx = int(room_width / 2)
	var yy = int(room_height / 2)
	set_cell(0, Vector2i(xx, yy), 0, Vector2i(randi_range(WATER, TREE), 0))
	for n in get_empty_neighbors(xx, yy): 
		stack.append(n)
	while  stack.size() > 0: 
		var front: Vector2i = stack.pop_front()
		if get_cell_source_id(0, front) != -1: 
			continue
		var options = valid_area(front)
		if options.size() > 0: 
			set_cell(0, front, 0, Vector2i(options.pick_random(), 0))
			for n in get_empty_neighbors(front.x, front.y): 
				if n not in stack: 
					stack.append(n)
			if speed != INSTANT: 
				await get_tree().create_timer(timer_speed).timeout
	emit_signal("world_filled")
		
func clean(): 
	for i in range(room_width):
		for j in range(room_height): 
			set_cell(0, Vector2i(i, j))

func set_speed(value): 
	speed = wrapi(value, INSTANT, FAST + 1)
	match speed: 
		INSTANT: 
			speed_button.text = "Speed: Instant"
			timer_speed = 0
		SLOW: 
			speed_button.text = "Speed: Slow"
			timer_speed = 0.1
		MEDIUM: 
			speed_button.text = "Speed: Medium"
			timer_speed = 0.05
		FAST: 
			speed_button.text = "Speed: Fast"
			timer_speed = 0.001

func _on_world_filled():
	generate_button.disabled = false

func _on_speed_button_pressed():
	self.speed += 1

func _on_generate_button_pressed():
	generate_button.disabled = true
	clean()
	fill_world()


func _on_exit_button_pressed():
	get_tree().change_scene_to_file("res://Menus/start_menu.tscn")
