extends Node

var player
func _ready():
	player = get_parent().get_parent()
	print(player)
	assert(player is KinematicBody2D)
	_apply_effect(player)

func _tween_effect():
	var tween = get_tree().create_tween()
	tween.tween_property(player.get_node("SpritesAnimacao"), "self_modulate", Color(0xFF7777FF), 0)
	tween.tween_property(player.get_node("SpritesAnimacao"), "self_modulate", Color(0xFFFFFFFF), $DebuffTimer.get_wait_time())

func _apply_effect(player_data):
	_tween_effect()
	player_data.spd_scaling -= 2
	player_data.emit_signal("spd_scaling_changed")
	$DebuffTimer.start()

func _remove_effect(player_data):
	print("player spd is gone")
	player_data.player_debuffs.erase(self)
	player_data.spd_scaling += 2
	player_data.emit_signal("spd_scaling_changed")
	self.queue_free()

func _on_DebuffTimer_timeout():
	_remove_effect(player)
