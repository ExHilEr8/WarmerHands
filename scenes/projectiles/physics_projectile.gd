class_name PhysicsProjectile extends Projectile

@export_category("Misc")
@export var collider: RigidBody2D

func _ready():
	pass

func _on_body_entered(body:Node):
	var bullet_global_position = get_global_position()
	var bullet_global_rotation

	if rotate_animation_with_bullet:
		bullet_global_rotation = get_global_rotation()
	else:
		bullet_global_rotation = 0

	determine_projectile_interaction(get_tree().get_root(), body, bullet_global_position, bullet_global_rotation)

func _on_body_exited(body:Node):
	if body.is_in_group("Enemy"):
		enemy_exit.emit(get_global_position(), body, self)
	
	if body.is_in_group("EnvironmentBound"):
		wall_exit.emit(get_global_position(), body, self)
