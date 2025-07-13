extends TileMap
class_name IsometricTileMap

# Time state management
var time_states: Dictionary = {}
var current_time_state: Dictionary = {}
var time_manager: TimeManager

# Map properties
var map_size: Vector2i = Vector2i(50, 50)
var tile_animations: Dictionary = {}

# Tile types enum
enum TileType {
	EMPTY,
	GRASS,
	STONE,
	WATER,
	SAND,
	TREE,
	ROCK,
	BUILDING
}

# Tile data structure
class TileData:
	var type: TileType
	var variant: int = 0
	var properties: Dictionary = {}
	var animation_frame: int = 0
	var time_created: float = 0.0
	
	func _init(tile_type: TileType, tile_variant: int = 0):
		type = tile_type
		variant = tile_variant

func _ready():
	# Initialize isometric tile map
	tile_set = _create_default_tileset()
	
	# Find time manager
	time_manager = get_node("/root/TimeManager")
	if time_manager:
		time_manager.register_time_object(self)
	
	# Initialize map
	_initialize_map()

func _initialize_map():
	# Create a basic map layout
	for x in range(map_size.x):
		for y in range(map_size.y):
			var tile_pos = Vector2i(x, y)
			var tile_data = TileData.new(TileType.GRASS)
			
			# Add some variation
			if randf() < 0.1:
				tile_data.type = TileType.TREE
			elif randf() < 0.05:
				tile_data.type = TileType.ROCK
			
			_set_tile_data(tile_pos, tile_data)

func _set_tile_data(tile_pos: Vector2i, tile_data: TileData):
	# Set the tile in the current state
	current_time_state[tile_pos] = tile_data
	
	# Update the visual tile
	_update_tile_visual(tile_pos, tile_data)

func _update_tile_visual(tile_pos: Vector2i, tile_data: TileData):
	# Map tile types to tileset IDs
	var source_id = 0
	var atlas_coords = Vector2i(0, 0)
	
	match tile_data.type:
		TileType.EMPTY:
			erase_cell(0, tile_pos)
			return
		TileType.GRASS:
			atlas_coords = Vector2i(0, 0)
		TileType.STONE:
			atlas_coords = Vector2i(1, 0)
		TileType.WATER:
			atlas_coords = Vector2i(2, 0)
		TileType.SAND:
			atlas_coords = Vector2i(3, 0)
		TileType.TREE:
			atlas_coords = Vector2i(0, 1)
		TileType.ROCK:
			atlas_coords = Vector2i(1, 1)
		TileType.BUILDING:
			atlas_coords = Vector2i(2, 1)
	
	# Add variant offset
	atlas_coords.x += tile_data.variant
	
	set_cell(0, tile_pos, source_id, atlas_coords)
	
	# Update z-index for proper isometric sorting
	var world_pos = IsometricUtils.tile_to_world(tile_pos)
	var depth = IsometricUtils.get_iso_depth(world_pos)
	# Note: TileMap doesn't support per-tile z-index, this would need custom rendering

func get_tile_data(tile_pos: Vector2i) -> TileData:
	if tile_pos in current_time_state:
		return current_time_state[tile_pos]
	return null

func set_tile_type(tile_pos: Vector2i, tile_type: TileType, variant: int = 0):
	if not IsometricUtils.is_tile_valid(tile_pos, map_size):
		return
	
	var tile_data = TileData.new(tile_type, variant)
	if time_manager:
		tile_data.time_created = time_manager.current_time
	
	_set_tile_data(tile_pos, tile_data)

func get_tile_type(tile_pos: Vector2i) -> TileType:
	var tile_data = get_tile_data(tile_pos)
	if tile_data:
		return tile_data.type
	return TileType.EMPTY

func is_tile_walkable(tile_pos: Vector2i) -> bool:
	var tile_type = get_tile_type(tile_pos)
	match tile_type:
		TileType.WATER, TileType.ROCK, TileType.BUILDING:
			return false
		_:
			return true

func get_tiles_in_area(center: Vector2i, radius: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var tile_pos = Vector2i(x, y)
			if IsometricUtils.is_tile_valid(tile_pos, map_size):
				if IsometricUtils.tile_distance(center, tile_pos) <= radius:
					tiles.append(tile_pos)
	
	return tiles

func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	# Simple A* pathfinding implementation
	var open_set: Array[Vector2i] = [start]
	var closed_set: Array[Vector2i] = []
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: IsometricUtils.tile_distance(start, goal)}
	
	while open_set.size() > 0:
		# Find node with lowest f_score
		var current = open_set[0]
		for node in open_set:
			if f_score.get(node, INF) < f_score.get(current, INF):
				current = node
		
		if current == goal:
			# Reconstruct path
			var path: Array[Vector2i] = []
			while current in came_from:
				path.push_front(current)
				current = came_from[current]
			return path
		
		open_set.erase(current)
		closed_set.append(current)
		
		# Check neighbors
		for neighbor in IsometricUtils.get_tile_neighbors(current):
			if not IsometricUtils.is_tile_valid(neighbor, map_size):
				continue
			if not is_tile_walkable(neighbor):
				continue
			if neighbor in closed_set:
				continue
			
			var tentative_g_score = g_score.get(current, INF) + 1
			
			if neighbor not in open_set:
				open_set.append(neighbor)
			elif tentative_g_score >= g_score.get(neighbor, INF):
				continue
			
			came_from[neighbor] = current
			g_score[neighbor] = tentative_g_score
			f_score[neighbor] = tentative_g_score + IsometricUtils.tile_distance(neighbor, goal)
	
	return []  # No path found

# Time management functions
func get_time_state() -> Dictionary:
	return current_time_state.duplicate(true)

func set_time_state(state: Dictionary):
	current_time_state = state.duplicate(true)
	
	# Update all tile visuals
	for tile_pos in current_time_state:
		var tile_data = current_time_state[tile_pos]
		_update_tile_visual(tile_pos, tile_data)

func _create_default_tileset() -> TileSet:
	# This would typically be created in the Godot editor
	# For now, return null and expect the tileset to be assigned in the editor
	return null