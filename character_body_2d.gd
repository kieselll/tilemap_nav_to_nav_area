extends CharacterBody2D

func _physics_process(delta: float) -> void:
	velocity.y += 500 * delta
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_A and event.is_pressed():
			velocity.x = -1000
		if event.keycode == KEY_D and event.is_pressed():
			velocity.x = 1000
		if (event.keycode == KEY_D or event.keycode == KEY_A) and not event.is_pressed():
			velocity.x = 0
		if event.keycode == KEY_SPACE and event.is_pressed() and is_on_floor():
			velocity.y = -500
