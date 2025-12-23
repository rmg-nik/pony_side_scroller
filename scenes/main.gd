extends Node

@export var obstacles_templates: Array[Area2D]
var obstacles : Array[Node2D]
var prizes : Array[Node2D]
var cherry_scene = preload("res://scenes/cherry.tscn")

const PLAYER_START_POS := Vector2i(128, 520)
const CAM_START_POS := Vector2i(576, 324)
const PRIZE_SCORE := 1000
var score: int = 0
var high_score: int
var speed: float
const START_SPEED: float = 2.0
const SPEED_MULTIPLIER: float = 0.25
const MAX_SPEED: float = 7.0
var screen_size: Vector2i
var game_running: bool
var elapsed: float
var block_input: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if obstacles_templates.is_empty():
		push_error("There are no obtacles in obstacles_templates")
	
	for template in obstacles_templates:
		template.visible = false
		template.process_mode = Node.PROCESS_MODE_DISABLED
		
	screen_size = get_viewport().get_visible_rect().size
	$HUD.get_node("StartLabel").show()

func new_game():	
	block_input = false
	high_score = max(score, high_score)
	score = 0
	elapsed = 0
	game_running = false
	speed = START_SPEED
	$Pony.position = PLAYER_START_POS
	$Pony.velocity = Vector2i(0, 0)
	$Pony.prepare()
	$Camera2D.position = CAM_START_POS
	$HUD.get_node("StartLabel").show()
	$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(high_score)
	$BackgroundMusic.play()
	for obstacle in obstacles:
		obstacle.process_mode = Node.PROCESS_MODE_DISABLED
		obstacle.queue_free()
	obstacles.clear()
	for prize in prizes:
		prize.queue_free()
	prizes.clear()
	update_score()
	#simple hack...
	if high_score > 0:
		$TiledGround.prepare()

func game_over():
	game_running = false
	$Pony.stumble()
	$HUD.get_node("StartLabel").text = "RESTART"
	$HUD.get_node("StartLabel").show()
	block_input = true
	$BackgroundMusic.stop()
	$GameOverSound.play()
	await $GameOverSound.finished
	block_input = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	elapsed += delta
	if game_running:
		speed += delta * SPEED_MULTIPLIER
		speed = min(speed, MAX_SPEED)
		$Pony.position.x += speed
		#$Pony.get_node("AnimatedSprite2D").speed_scale = speed / START_SPEED
		$Camera2D.position.x += speed
		score += int(elapsed)
		update_score()
		generate_obstacle()
		generate_prize()
	else:
		if block_input:
			return
		if Input.is_anything_pressed():
			new_game()
			await get_tree().create_timer(0.1).timeout
			game_running = true
			elapsed = 0
			$HUD.get_node("StartLabel").hide()
		else:
			var value = 1.0
			var elapsed_int: int = int(elapsed)
			if elapsed - elapsed_int < 0.5:
				value = 0.8
			var label: Label
			label = $HUD.get_node("StartLabel")
			label.set("theme_override_colors/font_color", Color(value, value, value))	

func generate_obstacle():
	if obstacles_templates.is_empty():
		print("There are no obtacles in obstacles_templates")
		return
		
	if obstacles.is_empty() or obstacles.back().position.x - $Camera2D.position.x < 0 + randi_range(50, 250):
		var ref = obstacles_templates.pick_random()
		var obstacle
		obstacle = ref.duplicate()		
		var obstacle_x: int = $Camera2D.position.x + screen_size.x + 100
		var obstacle_y : int = obstacle.position.y
		obstacle.position = Vector2i(obstacle_x, obstacle_y)
		obstacle.visible = true
		obstacle.process_mode = Node.PROCESS_MODE_INHERIT
		obstacle.body_entered.connect(hit_obstacle)
		add_child(obstacle)
		obstacles.append(obstacle)

func generate_prize():
	if prizes.is_empty() or prizes.back().position.x - $Camera2D.position.x < 0 + randi_range(200, 400):
		var prize  = cherry_scene.instantiate()
		var x: int = $Camera2D.position.x + screen_size.x + randi_range(300, 600)
		var y : int = $Cherry.position.y
		prize.position = Vector2i(x, y)
		prize.visible = true
		prize.process_mode = Node.PROCESS_MODE_INHERIT
		prize.body_entered.connect(hit_prize)
		add_child(prize)
		prizes.append(prize)
		
func hit_obstacle(body):
	if body.name == "Pony":
		game_over()

func hit_prize(body):
	if body.name == "Pony":
		$PrizePickup.play()
		score += PRIZE_SCORE
		print("PRIZE!!!")
		update_score()

func remove_prize(prize):
	prizes.erase(prize)
	
func remove_passed_obstacles():
	while !obstacles.is_empty():
		var first = obstacles.front()
		if first.position.x > $Camera2D.position.x:
			break
		obstacles.pop_front()
		first.queue_free()
		
func update_score() -> void:
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score)
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(high_score)
