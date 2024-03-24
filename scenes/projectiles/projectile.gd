class_name Projectile extends Node2D

signal enemy_hit(position: Vector2, enemy: Node, projectile)
signal enemy_exit(position: Vector2, enemy: Node, projectile)
signal wall_hit(position: Vector2, wall: Node, projectile)
signal wall_exit(position: Vector2, wall: Node, projectile)

@export_group("Projectile Stats")
@export var damage: float = float(1)
@export var projectile_speed: float = float(550)
@export var ammo_per_shot: int = int(1)
@export var is_enemy_piercing: bool = false
@export var is_wall_piercing: bool = false
@export var play_effect_on_enemy: bool = false
@export var play_effect_on_wall: bool = false
@export var is_charged_type: bool = false
@export_subgroup("Charged Curves")
@export var charged_size_curve: Curve
@export var charged_damage_curve: Curve
@export var charged_speed_curve: Curve

@export_category("Animation")
@export var impact_animator: PackedScene
@export var animation_name: String = "default"
@export var rotate_animation_with_bullet: bool = true

@export_category("Audio")
@export var impact_sound: AudioStream
@export var sound_volume : float = 0.0
@export var sound_attenuation: float = float(1)

var charge: float = float(1):
	get:
		return charge
	set(value):
		charge = clamp(float(value), float(0), float(1))

var impact_effect: ImpactEffect = ImpactEffect.new()

func _enter_tree():
	if is_charged_type == true:
		apply_charge_mods(charge)

func apply_charge_mods(charge_to_apply):
	if charged_size_curve != null:
		var charged_size = charged_size_curve.sample(charge_to_apply)

		for child in get_children():
			child.scale = child.scale * charged_size

	if charged_damage_curve != null:
		damage = charged_damage_curve.sample(charge_to_apply)

	if charged_speed_curve != null:
		projectile_speed = charged_speed_curve.sample(charge_to_apply)

func determine_projectile_interaction(parent, body: Node, bullet_global_position: Vector2, bullet_global_rotation: float):
	if body.is_in_group("Enemy"):
		on_enemy_hit(parent, body, bullet_global_position, bullet_global_rotation)
	
	elif body.is_in_group("Wall"):
		on_wall_hit(parent, body, bullet_global_position, bullet_global_rotation)

func on_hit_effect(parent, hit_position, hit_rotation):
	if(impact_animator != null):
		impact_effect.play_animation(parent, impact_animator, animation_name, hit_position, hit_rotation)

	if(impact_sound != null):
		impact_effect.play_sound(parent, impact_sound, hit_position, sound_volume, sound_attenuation)

# parent variable is included to allow instantiating animations and sounds under
#	a preferred node. Gives more control over both if desired
func on_enemy_hit(parent, enemy: Node, hit_position: Vector2, hit_rotation: float):
	if play_effect_on_enemy == true:
		on_hit_effect(parent, hit_position, hit_rotation)
	enemy_hit.emit(hit_position, enemy, self)

func on_wall_hit(parent, enemy: Node, hit_position: Vector2, hit_rotation: float):
	if play_effect_on_wall == true:
		on_hit_effect(parent, hit_position, hit_rotation)
		
	wall_hit.emit(hit_position, enemy, self)
