class_name Weapon extends Sprite2D



##### EXPORT VARIABLE #####

@export_group("Weapon Stats")
@export var fire_rate: float = float(0.3)
@export var reload_time: float = float(1)
@export_subgroup("Reload Misc")
@export var allow_instant_reload_interruption: bool = false
@export var reload_individual_bullets: bool = false
@export var individual_bullet_reload_cost: int = int(1)
@export var next_reload_cancel_delay: float = float(0.25)
@export_subgroup("")
@export var initial_accuracy: float = float(1) :
	get:
		return initial_accuracy
	set(value):
		initial_accuracy = clamp(value, 0, 1)
@export var magazine_size: int = int(30)
@export var reserve_ammo: int = int(90)
@export_group("Projectile Options")
@export var projectile_count: int = int(1)
@export var projectile_cost_override: int = int(0)
@export var projectile_even_spread: bool = false


@export_group("Firemode Options")
@export_subgroup("Full Auto Options")
@export var is_full_auto: bool = true

@export_subgroup("Burst Options")
@export var is_burst_fire: bool = false
@export var burst_amount: int = int(1)
@export var burst_fire_rate: float = float(0.1)

@export_subgroup("Charge Options")
@export var is_charge_fire: bool = false
@export var charge_time_seconds: float = float(1)
@export var minimum_charge: float = float(0)


@export_group("Misc")
@export var allow_queued_firing: bool = true
@export var time_left_to_queue: float = float(0.2) :
	get:
		return time_left_to_queue
	set(value):
		time_left_to_queue = clamp(float(value), float(0), float(fire_rate))


@export_category("Resources")
@export var physics_projectile: PackedScene



##### CLASS VARIABLES #####


var burst_timer: Timer
var fire_rate_timer: Timer
var reload_timer: Timer
var reload_individual_timer: Timer
var is_bursting: bool = false
var is_reloading: bool = false
var cancel_next_individual: bool = false

var can_fire: bool = true 
var is_fire_queued: bool = false
var charge_full_autod_previously: bool = false

var current_charge: float = float(0) :
	get:
		return current_charge
	set(value):
		current_charge = clamp(float(value), float(0), float(1))

var magazine_count: int :
	get:
		return magazine_count
	set(value):
		magazine_count = clamp(value, 0, 9223372036854775807)



##### FUNCTIONS #####

func _ready():
	burst_timer = initialize_general_timer()

	fire_rate_timer = initialize_general_timer()
	fire_rate_timer.timeout.connect(_attempt_queue_fire)

	reload_timer = initialize_general_timer()
	reload_timer.timeout.connect(_reload_timer_finished)

	reload_individual_timer = initialize_general_timer()
	reload_individual_timer.timeout.connect(_reload_individual_timer_finished)

	magazine_count = magazine_size 



func _process(delta):
	# Called first to determine if the player wants to shoot if during a reload
	check_attempt_reload()

	if is_charge_fire == true:
		check_attempt_charge_fire(delta)

	else:
		if is_full_auto == true:
			check_attempt_full_fire()
		else:
			check_attempt_single_fire()


func check_attempt_reload():
	if Input.is_action_just_pressed("reload"):
		if reload_individual_bullets == true:
			if is_reloading == false:
				if determine_can_reload() == true:
					start_reload(reload_individual_timer)
			else:
				var elapsed_time = reload_individual_timer.wait_time - reload_individual_timer.time_left

				if elapsed_time > next_reload_cancel_delay:
					print('cancelling next reload')
					cancel_next_individual = true
		else:
			if determine_can_reload() == true:
				start_reload(reload_timer)

	elif (Input.is_action_just_pressed("primary_action") and allow_instant_reload_interruption == true and determine_can_fire(true) == true):
		if is_reloading == true:
			if reload_individual_bullets == true:
				cancel_reload(reload_individual_timer)
			else:
				cancel_reload(reload_timer)


func check_attempt_full_fire():
	if Input.is_action_pressed("primary_action"):
		try_fire()


func check_attempt_single_fire():
	if Input.is_action_just_pressed("primary_action"):
		try_fire()


func check_attempt_charge_fire(delta):
	if Input.is_action_pressed("primary_action"):
		current_charge += float((1 * delta) / charge_time_seconds)

		if current_charge == 1 and is_full_auto == true:
			try_fire()
			current_charge = 0
			charge_full_autod_previously = true
	
	elif Input.is_action_just_released("primary_action"):
		if current_charge >= minimum_charge and charge_full_autod_previously == false:
			try_fire()
		elif charge_full_autod_previously == true:
			charge_full_autod_previously = false
		
		current_charge = 0


func _attempt_queue_fire():
	if is_fire_queued == true:
		try_fire()
		is_fire_queued = false


func try_fire():
	can_fire = determine_can_fire()

	if can_fire == true:
		fire_rate_timer.start(fire_rate)

		if is_burst_fire == true:
			burst_fire()
		else:
			regular_fire()
		
	elif can_fire == false and allow_queued_firing == true:
		if Input.is_action_just_pressed("primary_action") and fire_rate_timer.time_left <= time_left_to_queue:
			is_fire_queued = true


func burst_fire():
	is_bursting = true

	for n in (burst_amount):
		shoot()
		burst_timer.start(burst_fire_rate)
		await burst_timer.timeout

	is_bursting = false


func regular_fire():
	shoot()


func shoot():
	var spread_increment = (PI * (1 - initial_accuracy)) / projectile_count
	var initial_rotation

	initial_rotation = get_global_rotation()

	# Subtracts half of the entire width of the spread from the initial_rotation to determine
	#	the starting point for the spread, and then rotates down with each subsequent projectile.
	# (This process is just super smash n64 fox up + b move lmao)
	var rotation_param = initial_rotation - ((PI * (1 - initial_accuracy)) / 2)

	# Not sure why but the rotation_param needs to be adjusted by half of a spread increment to
	#	align properly, otherwise it shoots too far counter clockwise. Probably some basic math
	#	I'm overlooking at the time of coding
	rotation_param += spread_increment / 2

	var projectile_charge = float(1)

	if is_charge_fire == true:
		projectile_charge = current_charge

	for n in projectile_count:
		if projectile_even_spread == true:
			fire_projectile(physics_projectile, $BulletInstancePoint.get_global_position(), rotation_param, projectile_charge)
			rotation_param += spread_increment
		else:
			fire_projectile(physics_projectile, $BulletInstancePoint.get_global_position(), apply_accuracy(get_global_rotation(), initial_accuracy), projectile_charge)

	if projectile_cost_override >= 0:
		deduct_ammo(projectile_cost_override)

	print("fire", magazine_count, "/", magazine_size)


func fire_projectile(projectile_scene: PackedScene, projectile_start_point: Vector2, projectile_rotation: float, projectile_charge: float = float(1)):
	var projectile_instance = projectile_scene.instantiate()
	projectile_instance.position = projectile_start_point
	projectile_instance.rotation = projectile_rotation
	projectile_instance.charge = projectile_charge
	connect_projectile(projectile_instance)
	get_tree().get_root().add_child(projectile_instance)

	projectile_instance.apply_impulse(Vector2(projectile_instance.projectile_speed, 0).rotated(projectile_instance.rotation), Vector2())

	if projectile_cost_override <= 0:
		deduct_ammo(projectile_instance.ammo_per_shot)
	
	return projectile_instance
		

func determine_can_fire(except_reloading: bool = false) -> bool:
	if(is_reloading == true and except_reloading == false):
		return false

	elif(is_bursting == true):
		return false

	elif(magazine_count == 0):
		return false
		
	elif(fire_rate_timer.time_left > 0):
		return false
	
	return true


func determine_can_reload() -> bool:
	if reserve_ammo > 0 and magazine_count < magazine_size and is_reloading == false:
		return true
	
	return false

func damage_enemy(enemy, damage) -> void:
	enemy.take_damage(damage)


func apply_accuracy(initial_rotation, accuracy: float) -> float:
	var rad_offset = PI * (1 - accuracy) 
	return randf_range(initial_rotation - rad_offset, initial_rotation + rad_offset)


func deduct_ammo(projectile_cost, projectiles_fired: int = int(1)):
	magazine_count -= projectile_cost * projectiles_fired


func start_reload(timer: Timer):
	print('reload started')
	timer.start(reload_time)
	is_reloading = true

func cancel_reload(timer: Timer):
	print('reload interrupted')
	timer.stop()
	is_reloading = false

func _reload_timer_finished():
	reload()
	is_reloading = false

	print("reloaded", magazine_count, "/", magazine_size)
	print("reserve ammo", reserve_ammo)


func reload() -> void:
	var amount_to_reload = magazine_size - magazine_count

	if(amount_to_reload > reserve_ammo):
		magazine_count += reserve_ammo
		reserve_ammo -= reserve_ammo 

	else:
		magazine_count += amount_to_reload
		reserve_ammo -= amount_to_reload


func _reload_individual_timer_finished():
	reload_individual(individual_bullet_reload_cost)
	is_reloading = false

	print("reloaded", magazine_count, "/", magazine_size)
	print("reserve ammo", reserve_ammo)

	reload_individual_try_next()


func reload_individual(amount_to_reload):
	var mag_space_left = magazine_size - magazine_count

	if amount_to_reload > reserve_ammo:
		amount_to_reload = reserve_ammo

	if mag_space_left < amount_to_reload:
		amount_to_reload = mag_space_left

	magazine_count += amount_to_reload
	reserve_ammo -= amount_to_reload


func reload_individual_try_next():
	if magazine_size - magazine_count > 0 and cancel_next_individual == false:
		start_reload(reload_individual_timer)

	# cancel_next_individual is always reset when the next bullet is loaded
	cancel_next_individual = false


func initialize_general_timer() -> Timer:
	var timer = Timer.new()
	add_child.call_deferred(timer)
	timer.one_shot = true
	timer.autostart = false
	return timer


func add_multiple_children(parent, children: Array, call_deferred: bool = true) -> void:
	for child in children:
		if call_deferred == true:
			parent.add_child.call_deferred(child)
		else:
			parent.add_child(child)


func connect_projectile(projectile_list):
	for projectile in [projectile_list]:
		projectile.enemy_hit.connect(_on_enemy_hit)
		projectile.enemy_exit.connect(_on_enemy_exit)
		projectile.wall_hit.connect(_on_wall_hit)
		projectile.wall_exit.connect(_on_wall_exit)




### EXTERNAL SIGNAL CONNECTIONS ###

func _on_enemy_hit(hit_position: Vector2, enemy: Node, projectile):
	damage_enemy(enemy, projectile.damage)

	if projectile.is_enemy_piercing == false:
		projectile.queue_free()
	elif projectile.is_enemy_piercing == true:
		projectile.collider.add_collision_exception_with(enemy)
		projectile.collider.linear_velocity = Vector2(projectile.projectile_speed, 0).rotated(projectile.get_global_rotation())


func _on_enemy_exit(hit_position: Vector2, enemy: Node, projectile):
	if projectile.is_enemy_piercing == true:
		projectile.collider.remove_collision_exception_with(enemy)


func _on_wall_hit(hit_position: Vector2, wall: Node, projectile):
	if projectile.is_wall_piercing == false:
		projectile.queue_free()
	elif projectile.is_wall_piercing == true:
		projectile.collider.add_collision_exception_with(wall)
		projectile.collider.linear_velocity = Vector2(projectile.projectile_speed, 0).rotated(projectile.get_global_rotation())
	
	
func _on_wall_exit(hit_position: Vector2, wall: Node, projectile):
	if projectile.is_wall_piercing == true:
		projectile.collider.remove_collision_exception_with(wall)


