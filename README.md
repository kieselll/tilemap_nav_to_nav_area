# Godot 4 TileMap Navigation Example

A small beginner-friendly example showing how to generate a `NavigationRegion2D` from `TileMapLayer` navigation polygons.

The script:

- reads navigation polygons from ground tiles
- reads navigation polygons from wall tiles
- merges touching shapes
- subtracts walls from ground
- writes the result into a `NavigationRegion2D`

## Godot Version

Godot `4.6`

## Main Files

- [node_2d.tscn](https://github.com/kieselll/tilemap_nav_to_nav_area/blob/main/node_2d.tscn)
- [node_2d.gd](https://github.com/kieselll/tilemap_nav_to_nav_area/blob/main/node_2d.gd)

## How To Use

1. Open the project in Godot.
2. Open [node_2d.tscn](https://github.com/kieselll/tilemap_nav_to_nav_area/blob/main/node_2d.tscn).
3. Select the root `Node2D`.
4. Click `Bake Navmesh` in the Inspector.

## Note

If the `Bake Navmesh` button stops working after script edits, reload the project once. The editor sometimes loses the callable until a reload.
