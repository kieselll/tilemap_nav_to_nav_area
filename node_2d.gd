@tool
extends Node2D

@export_tool_button("Bake Navmesh", "NavigationPolygon") var gen_mesh = generate_navmesh

const TILESET_NAVIGATION_LAYER := 0

@onready var layer_ground: TileMapLayer = $TileMapLayer
@onready var layer_walls: TileMapLayer = $TileMapLayer2
@onready var navreg: NavigationRegion2D = $NavigationRegion2D

func generate_navmesh() -> void:
	if not is_instance_valid(layer_ground) or not is_instance_valid(layer_walls) or not is_instance_valid(navreg):
		push_error("Missing TileMapLayer or NavigationRegion2D reference.")
		return

	layer_ground.update_internals()
	layer_walls.update_internals()

	var ground_navigation_map := layer_ground.get_navigation_map()
	var wall_navigation_map := layer_walls.get_navigation_map()

	if ground_navigation_map != wall_navigation_map:
		push_warning("Ground and wall TileMapLayers do not share the same navigation map.")

	var ground_outlines := _merge_touching_polygons(_collect_layer_navigation_outlines(layer_ground))
	var wall_outlines := _merge_touching_polygons(_collect_layer_navigation_outlines(layer_walls))

	if ground_outlines.is_empty():
		push_error("Ground TileMapLayer has no navigation outlines to bake.")
		return

	var final_outlines := _subtract_wall_outlines(ground_outlines, wall_outlines)
	var navigation_polygon := _create_navigation_polygon()

	if final_outlines.is_empty():
		push_error("Wall subtraction removed all navigation area.")
		return

	for outline: PackedVector2Array in _sort_outlines_for_navigation(final_outlines):
		if outline.size() >= 3:
			navigation_polygon.add_outline(outline)

	navigation_polygon.make_polygons_from_outlines()
	navreg.navigation_polygon = navigation_polygon

func _create_navigation_polygon() -> NavigationPolygon:
	var navigation_polygon := NavigationPolygon.new()
	var existing_navigation_polygon := navreg.navigation_polygon

	if existing_navigation_polygon != null:
		navigation_polygon.agent_radius = existing_navigation_polygon.agent_radius
		navigation_polygon.border_size = existing_navigation_polygon.border_size
		navigation_polygon.baking_rect = existing_navigation_polygon.baking_rect
		navigation_polygon.baking_rect_offset = existing_navigation_polygon.baking_rect_offset

	navigation_polygon.sample_partition_type = NavigationPolygon.SAMPLE_PARTITION_CONVEX_PARTITION

	return navigation_polygon

func _collect_layer_navigation_outlines(layer: TileMapLayer) -> Array[PackedVector2Array]:
	var outlines: Array[PackedVector2Array] = []
	var layer_to_region_transform := navreg.get_global_transform().affine_inverse() * layer.get_global_transform()

	for cell: Vector2i in layer.get_used_cells():
		var tile_data := layer.get_cell_tile_data(cell)

		if tile_data == null:
			continue

		var tile_navigation_polygon := tile_data.get_navigation_polygon(
			TILESET_NAVIGATION_LAYER,
			layer.is_cell_flipped_h(cell),
			layer.is_cell_flipped_v(cell),
			layer.is_cell_transposed(cell)
		)

		if tile_navigation_polygon == null:
			continue

		var cell_origin := layer.map_to_local(cell)

		for outline_index in tile_navigation_polygon.get_outline_count():
			var outline := tile_navigation_polygon.get_outline(outline_index)
			var transformed_outline := PackedVector2Array()

			for point: Vector2 in outline:
				transformed_outline.append(layer_to_region_transform * (point + cell_origin))

			if transformed_outline.size() >= 3:
				outlines.append(transformed_outline)

	return outlines

func _merge_touching_polygons(polygons: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var merged_polygons := polygons.duplicate()
	var changed := true

	while changed:
		changed = false

		for i in range(merged_polygons.size()):
			var did_merge := false

			for j in range(i + 1, merged_polygons.size()):
				var merged := Geometry2D.merge_polygons(merged_polygons[i], merged_polygons[j])

				if merged.size() == 1:
					merged_polygons[i] = merged[0]
					merged_polygons.remove_at(j)
					changed = true
					did_merge = true
					break

			if did_merge:
				break

	return merged_polygons

func _subtract_wall_outlines(
	ground_outlines: Array[PackedVector2Array],
	wall_outlines: Array[PackedVector2Array]
) -> Array[PackedVector2Array]:
	var remaining_outlines := ground_outlines.duplicate()

	for wall_outline: PackedVector2Array in wall_outlines:
		var next_outlines: Array[PackedVector2Array] = []

		for ground_outline: PackedVector2Array in remaining_outlines:
			next_outlines.append_array(Geometry2D.clip_polygons(ground_outline, wall_outline))

		remaining_outlines = next_outlines

	return remaining_outlines

func _sort_outlines_for_navigation(outlines: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var sorted_outlines := outlines.duplicate()
	sorted_outlines.sort_custom(func(a: PackedVector2Array, b: PackedVector2Array) -> bool:
		return abs(_signed_polygon_area(a)) > abs(_signed_polygon_area(b))
	)
	return sorted_outlines

func _signed_polygon_area(outline: PackedVector2Array) -> float:
	var area := 0.0

	for i in range(outline.size()):
		var current := outline[i]
		var next := outline[(i + 1) % outline.size()]
		area += current.x * next.y - next.x * current.y

	return area * 0.5
