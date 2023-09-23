extends TileMap

var room_width: int
var room_height: int

var stack: Array[Vector2i] = []

@onready var ui: CanvasLayer = get_node("UI")

@onready var generate_button: Button = get_node("UI/HBoxContainer/CreateWorldButton")
@onready var speed_button: Button = get_node("UI/HBoxContainer/SpeedButton")
@onready var screenshot_button: Button = get_node("UI/HBoxContainer/ScreenshotButton")

@onready var sea_slider: HSlider = get_node("UI/PanelContainer/Probabilities/VBoxContainer2/SeaSlider")
@onready var coast_slider: HSlider = get_node("UI/PanelContainer/Probabilities/VBoxContainer2/CoastSlider")
@onready var land_slider: HSlider = get_node("UI/PanelContainer/Probabilities/VBoxContainer2/LandSlider")
@onready var mountain_slider: HSlider = get_node("UI/PanelContainer/Probabilities/VBoxContainer2/MountainSlider")

enum {
	SEA, 
	COAST, 
	LAND, 
	MOUNTAIN
}

enum {
	INSTANT,
	SLOW, 
	MEDIUM, 
	FAST
}

var distributions = {
	SEA: [SEA, COAST], 
	COAST: [SEA, COAST, LAND],
	LAND: [COAST, LAND, MOUNTAIN], 
	MOUNTAIN: [LAND, MOUNTAIN]
}

var probabilities = {
	SEA: 1, 
	COAST: 1, 
	LAND: 1, 
	MOUNTAIN: 1
}

signal world_filled

var speed: int = SLOW: set = set_speed
var timer_speed = 0.1
var image: Image = null

func _ready():
	room_width = ProjectSettings.get("display/window/size/viewport_width")/16
	room_height = ProjectSettings.get("display/window/size/viewport_height")/16

func get_valid_tiles(xx: int, yy: int)->Array: 
	var tiles = [SEA, COAST, LAND, MOUNTAIN]
	var atlas_coord: int = -1
	var valid_tiles = []
	for tile in tiles: 
		if xx > 0: 
			atlas_coord = get_cell_atlas_coords(0, Vector2i(xx - 1, yy)).x
			if atlas_coord != -1: 
				if tile not in distributions[atlas_coord]: 
					continue
		if xx < room_width - 1: 
			atlas_coord = get_cell_atlas_coords(0, Vector2i(xx + 1, yy)).x
			if atlas_coord != -1: 
				if tile not in distributions[atlas_coord]: 
					continue
		if yy > 0: 
			atlas_coord = get_cell_atlas_coords(0, Vector2i(xx, yy - 1)).x
			if atlas_coord != -1: 
				if tile not in distributions[atlas_coord]: 
					continue
		if yy < room_height - 1: 
			atlas_coord = get_cell_atlas_coords(0, Vector2i(xx, yy + 1)).x
			if atlas_coord != -1: 
				if tile not in distributions[atlas_coord]: 
					continue
		valid_tiles.append(tile)
	return valid_tiles
	
func get_lowest_entropy_tile(tiles_to_check: Array[Vector2i]): 
	var lowest_entropy_tile = Vector2i(-1, -1)
	var lowest_entropy = INF
	
	for tile in tiles_to_check: 
		if get_cell_atlas_coords(0, tile).x != -1: 
			continue
		var valid_tiles = get_valid_tiles(tile.x, tile.y)
		if valid_tiles.size() < lowest_entropy: 
			lowest_entropy = valid_tiles.size()
			lowest_entropy_tile = tile
	return lowest_entropy_tile
	
func get_empty_neighbors(tile: Vector2i): 
	var neighbors = []
	var atlas_coord = -1
	if tile.x > 0: 
		atlas_coord = get_cell_atlas_coords(0, tile + Vector2i(-1, 0))
		if atlas_coord.x == -1: 
			neighbors.append(tile + Vector2i(-1, 0))
	if tile.x < room_width - 1: 
		atlas_coord = get_cell_atlas_coords(0, tile + Vector2i(1, 0))
		if atlas_coord.x == -1: 
			neighbors.append(tile + Vector2i(1, 0))
	if tile.y > 0: 
		atlas_coord = get_cell_atlas_coords(0, tile + Vector2i(0, -1))
		if atlas_coord.y == -1: 
			neighbors.append(tile + Vector2i(0, -1))
	if tile.y < room_height - 1: 
		atlas_coord = get_cell_atlas_coords(0, tile + Vector2i(0, 1))
		if atlas_coord.y == -1: 
			neighbors.append(tile + Vector2i(0, 1))
	return neighbors
	
func get_probability_distribution(tiles: Array): 
	var probability_distribution = []
	for tile in tiles: 
		for i in range(probabilities[tile]): 
			probability_distribution.append(tile)
			
	return probability_distribution

func fill_world(): 
	
	var tiles_to_check: Array[Vector2i] = []
	var xx = randi() % room_width
	var yy = randi() % room_height
	
	while xx != -1 and yy != -1: 
		var valid_tiles = get_valid_tiles(xx, yy)
		if valid_tiles.size() <= 0: 
			clean()
			tiles_to_check = []
			xx = randi() % room_width
			yy = randi() % room_height
			continue
		
		set_cell(0, Vector2i(xx, yy), 0, Vector2i(get_probability_distribution(valid_tiles).pick_random(), 0))
		
		var neighbors = get_empty_neighbors(Vector2i(xx, yy))
		tiles_to_check.append_array(neighbors)
		
		var next_tile = get_lowest_entropy_tile(tiles_to_check)
		tiles_to_check.erase(next_tile)
		
		xx = next_tile.x
		yy = next_tile.y
		if speed != INSTANT: 
			await  get_tree().create_timer(timer_speed).timeout

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
	screenshot_button.disabled = false

func _on_speed_button_pressed():
	self.speed += 1

func _on_exit_button_pressed():
	get_tree().change_scene_to_file("res://Menus/start_menu.tscn")

func _on_sea_slider_drag_ended(value_changed):
	if value_changed: 
		probabilities[SEA] = wrapi(sea_slider.value, 1, 11)


func _on_coast_slider_drag_ended(value_changed):
	if value_changed: 
		probabilities[COAST] = wrapi(coast_slider.value, 1, 11)


func _on_land_slider_drag_ended(value_changed):
	if value_changed: 
		probabilities[LAND] = wrapi(land_slider.value, 1, 11)
		
func _on_mountain_slider_drag_ended(value_changed):
	if value_changed: 
		probabilities[MOUNTAIN] = wrapi(mountain_slider.value, 1, 11)


func _on_screenshot_button_pressed():
	ui.hide()
	var os_name = OS.get_name()
	var viewport: Viewport = get_viewport()
	var path: String = "wfc_"+str(Time.get_unix_time_from_system()) + ".png"
	await get_tree().create_timer(1).timeout
	image = viewport.get_texture().get_image()
	
	if os_name == "Web": 
		var buffer: PackedByteArray = image.save_png_to_buffer() 
		JavaScriptBridge.download_buffer(buffer, path, "image/png")
	else: 
		print("FIle")
		print(image.save_png("user://"+path))
	ui.show()

func _on_create_world_button_pressed():
	generate_button.disabled = true
	screenshot_button.disabled = true
	clean()
	fill_world()
