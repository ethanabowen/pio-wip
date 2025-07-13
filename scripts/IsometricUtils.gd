extends Node
class_name IsometricUtils

# Isometric tile dimensions
const TILE_WIDTH: int = 64
const TILE_HEIGHT: int = 32

# Convert world coordinates to isometric coordinates
static func world_to_iso(world_pos: Vector2) -> Vector2:
	var iso_x = (world_pos.x - world_pos.y) * (TILE_WIDTH / 2.0)
	var iso_y = (world_pos.x + world_pos.y) * (TILE_HEIGHT / 2.0)
	return Vector2(iso_x, iso_y)

# Convert isometric coordinates to world coordinates
static func iso_to_world(iso_pos: Vector2) -> Vector2:
	var world_x = (iso_pos.x / (TILE_WIDTH / 2.0) + iso_pos.y / (TILE_HEIGHT / 2.0)) / 2.0
	var world_y = (iso_pos.y / (TILE_HEIGHT / 2.0) - iso_pos.x / (TILE_WIDTH / 2.0)) / 2.0
	return Vector2(world_x, world_y)

# Convert world coordinates to tile coordinates
static func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(floor(world_pos.x), floor(world_pos.y))

# Convert tile coordinates to world coordinates
static func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x, tile_pos.y)

# Convert screen position to world position
static func screen_to_world(screen_pos: Vector2, camera: Camera2D) -> Vector2:
	var world_pos = camera.get_global_transform().affine_inverse() * screen_pos
	return iso_to_world(world_pos)

# Convert world position to screen position
static func world_to_screen(world_pos: Vector2, camera: Camera2D) -> Vector2:
	var iso_pos = world_to_iso(world_pos)
	return camera.get_global_transform() * iso_pos

# Get the depth sorting order for isometric sprites
static func get_iso_depth(world_pos: Vector2) -> float:
	# Objects further down and to the right should be drawn on top
	return world_pos.x + world_pos.y

# Convert tile coordinates to isometric screen position
static func tile_to_iso_screen(tile_pos: Vector2i) -> Vector2:
	var world_pos = tile_to_world(tile_pos)
	return world_to_iso(world_pos)

# Get neighboring tile positions
static func get_tile_neighbors(tile_pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions = [
		Vector2i(1, 0),   # East
		Vector2i(0, 1),   # South
		Vector2i(-1, 0),  # West
		Vector2i(0, -1),  # North
		Vector2i(1, 1),   # Southeast
		Vector2i(-1, -1), # Northwest
		Vector2i(1, -1),  # Northeast
		Vector2i(-1, 1)   # Southwest
	]
	
	for direction in directions:
		neighbors.append(tile_pos + direction)
	
	return neighbors

# Calculate distance between two tiles
static func tile_distance(tile_a: Vector2i, tile_b: Vector2i) -> float:
	var diff = tile_a - tile_b
	return sqrt(diff.x * diff.x + diff.y * diff.y)

# Check if a tile position is valid (within bounds)
static func is_tile_valid(tile_pos: Vector2i, map_size: Vector2i) -> bool:
	return tile_pos.x >= 0 and tile_pos.x < map_size.x and tile_pos.y >= 0 and tile_pos.y < map_size.y

# Get tile position from mouse position
static func get_tile_from_mouse(mouse_pos: Vector2, camera: Camera2D) -> Vector2i:
	var world_pos = screen_to_world(mouse_pos, camera)
	return world_to_tile(world_pos)

# Lerp between two world positions in isometric space
static func lerp_iso(from: Vector2, to: Vector2, weight: float) -> Vector2:
	return from.lerp(to, weight)

# Create a diamond shape for tile selection
static func create_tile_diamond(tile_pos: Vector2i) -> PackedVector2Array:
	var iso_pos = tile_to_iso_screen(tile_pos)
	var points = PackedVector2Array()
	
	# Diamond shape points
	points.append(iso_pos + Vector2(0, -TILE_HEIGHT/2))  # Top
	points.append(iso_pos + Vector2(TILE_WIDTH/2, 0))    # Right
	points.append(iso_pos + Vector2(0, TILE_HEIGHT/2))   # Bottom
	points.append(iso_pos + Vector2(-TILE_WIDTH/2, 0))   # Left
	
	return points