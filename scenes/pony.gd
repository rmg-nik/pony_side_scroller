extends CharacterBody2D

const JUMP_VELOCITY = -450.0
var is_stumbled: bool

func prepare():
	is_stumbled = false
	
func stumble():
	is_stumbled = true
	$AnimatedSprite2D.play("stumble")
	velocity.x += 80

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if is_stumbled:
		if velocity.x > 0:
			velocity.x -= 50 * delta
		else:
			velocity.x = 0
	else:
		if is_on_floor():
			if not get_parent().game_running:
				$AnimatedSprite2D.play("idle")
			else:
				if Input.is_anything_pressed():
					velocity.y = JUMP_VELOCITY
					$JumpSound.play()					
					$AnimatedSprite2D.play("jump")
					$AnimatedSprite2D.set_frame_and_progress(0, 0  )
				else:
					$AnimatedSprite2D.play("run")
			
	
	move_and_slide()
