extends Node2D

## Diagnostico puntual: que esta golpeando el raycast del WoodPost.
const LEVEL := preload("res://scenes/levels/world_1_level_1.tscn")
var done := false

func _physics_process(_d: float) -> void:
	if done:
		return
	done = true
	var level := LEVEL.instantiate()
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_2d().direct_space_state
	for name in ["CheckpointOne", "CheckpointTwo", "MissionSign", "Finish"]:
		var node: Node2D = level.get_node_or_null(name)
		if node == null:
			continue
		var start: Vector2 = node.global_position + Vector2(-22.0, 24.0)
		var q := PhysicsRayQueryParameters2D.create(start, start + Vector2(0.0, 900.0))
		q.collision_mask = 1
		q.collide_with_areas = false
		var hit := space.intersect_ray(q)
		print("%-14s pos=%s  desde y=%.0f -> %s" % [
			name, node.global_position, start.y,
			"NADA" if hit.is_empty() else ("y=%.0f collider=%s (%s)" % [
				hit.position.y, hit.collider.name, hit.collider.get_class()])])
		var post: Node2D = node.get_node_or_null("WoodPost")
		if post != null:
			print("     WoodPost.measured_length = %.1f  hijos=%d" % [post.measured_length, post.get_child_count()])
	get_tree().quit()
