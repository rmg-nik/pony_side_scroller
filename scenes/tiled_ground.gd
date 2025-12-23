extends Node2D

# AI Used

# --- Налаштування ---
@export var segment_templates: Array[StaticBody2D]
@export var player: Node2D

# Скільки ДОДАТКОВИХ блоків генерувати праворуч після заповнення екрану
@export var extra_buffer_blocks: int = 3

# Відстань позаду гравця, після якої сегменти видаляються
@export var delete_distance: float = 500.0

# --- Внутрішні змінні ---
var current_spawn_x: float = 0.0
var active_segments: Array[Node2D] = []

func _ready():
	prepare()

func prepare():	
	if segment_templates.is_empty() or not player:
		push_error("Не призначено шаблони або гравця!")
		set_process(false)
		return
	
	# Ховаємо шаблони
	for template in segment_templates:
		template.visible = false
		template.process_mode = Node.PROCESS_MODE_DISABLED
	
	clear()
	# Початкова точка генерації (від позиції генератора або 0)
	current_spawn_x = global_position.x
	
	# --- ЗМІНА 1: Генерація на ширину екрану + буфер ---
	var viewport_width = get_viewport_rect().size.x
	# Цільова координата: позиція гравця + ширина екрану
	# (Ми генеруємо підлогу, поки 'хвіст' генерації не вийде за правий край екрану)
	var screen_right_edge = player.global_position.x + viewport_width
	
	# 1. Заповнюємо весь екран
	while current_spawn_x < screen_right_edge:
		spawn_segment()
		
	# 2. Додаємо +3 блоки (або скільки вказано в extra_buffer_blocks) про запас
	for i in range(extra_buffer_blocks):
		spawn_segment()

func clear():
	while !active_segments.is_empty():
		var first_segment = active_segments.front()
		
		# Перевіряємо, чи вийшов перший сегмент за межу видалення
		if first_segment.global_position.x < player.global_position.x - delete_distance:
			# Видаляємо зі списку і зі сцени
			active_segments.pop_front()
			first_segment.queue_free()
		else:
			# Якщо найстаріший сегмент ще "нормальний", то новіші тим паче.
			# Перериваємо цикл, щоб не перевіряти зайве.
			break	

func _process(_delta):
	if not get_parent().game_running:
		return
	# --- Логіка додавання (без змін) ---
	var viewport_width = get_viewport_rect().size.x
	var view_right_edge = player.global_position.x + viewport_width
	
	if !active_segments.is_empty():
		var last_segment = active_segments.back()
		# Якщо правий край генерації наближається до екрану, додаємо ще
		if last_segment.global_position.x < view_right_edge + (viewport_width * 0.5):
			spawn_segment()
	
	# --- ЗМІНА 2: Видалення в циклі (для швидкого руху) ---
	# Використовуємо while, щоб видалити ВСІ застарілі блоки за один кадр
	clear()

func spawn_segment():
	var template = segment_templates.pick_random()
	var new_segment = template.duplicate()
	
	add_child(new_segment)
	new_segment.visible = true
	new_segment.process_mode = Node.PROCESS_MODE_INHERIT
	
	var segment_width = _get_segment_width(new_segment)
	
	# Встановлюємо позицію (враховуючи, що origin по центру)
	new_segment.global_position = Vector2(current_spawn_x + segment_width / 2, template.global_position.y)
	
	# Зсуваємо курсор вправо на ширину цього блоку
	current_spawn_x += segment_width
	
	active_segments.append(new_segment)

func _get_segment_width(segment: Node2D) -> float:
	var sprite = segment.get_node_or_null("Sprite2D")
	
	if sprite and sprite.texture:
		var base_width = 0.0
		
		# 1. Перевіряємо, чи увімкнено Region (вирізка з атласу)
		if sprite.region_enabled:
			# Якщо так, беремо ширину прямокутника region_rect
			base_width = sprite.region_rect.size.x
		else:
			# Якщо ні, беремо повну ширину текстури
			base_width = sprite.texture.get_width()
			
		# 2. Множимо на scale, щоб врахувати розтягування в редакторі
		return base_width * sprite.scale.x
	
	# Фоллбек на CollisionShape, якщо спрайта немає
	var collision = segment.get_node_or_null("CollisionShape2D")
	if collision and collision.shape:
		return collision.shape.get_rect().size.x
		
	return 100.0
