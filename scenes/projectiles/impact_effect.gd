class_name ImpactEffect extends Node2D

# Creates a new AudioStreamPlayer2D at a given location to play a sound (One Shot)
func play_sound(parent, sound: AudioStream, sound_position: Vector2, sound_volume: float, sound_attenuation: float):
	var audio_stream_player = AudioStreamPlayer2D.new()
	parent.add_child(audio_stream_player)
	
	audio_stream_player.stream = sound
	audio_stream_player.position = sound_position
	audio_stream_player.volume_db = sound_volume
	audio_stream_player.attenuation = sound_attenuation
	audio_stream_player.play()

	await(audio_stream_player.finished)
	audio_stream_player.queue_free()

# Instantiates a given scene with a AnimatedSprite2D node to play an animation at a given position (One Shot)
func play_animation(parent, impact_animator: PackedScene, animation_name: String, animation_position: Vector2, animation_rotation):
	var impact_instance = impact_animator.instantiate()
	parent.add_child(impact_instance)

	impact_instance.position = animation_position
	impact_instance.rotation = animation_rotation
	impact_instance.play(animation_name)

	await(impact_instance.animation_finished)
	impact_instance.queue_free()

