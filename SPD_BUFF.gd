extends Node

signal speed_buff_activated
signal speed_buff_depleted

var player
func _ready():
	player = get_parent().get_parent()
	print(player)
	_apply_effect_speed_positive(player)
	
func _apply_effect_speed_positive(player_data):
	player_data.spd_scaling += 2
	player_data.emit_signal("spd_scaling_changed")
	$BuffTimer.start()
#		get_node("%Tween").interpolate_property(get_node("%Player/SpritesAnimacao"), "self_modulate", Color(0xBBFF8CFF), Color(0xFFFFFFFF), btimer.get_wait_time())
#		get_node("%Tween").start()

func _remove_effect(player_data):
	print("player spd is gone")
	player_data.player_buffs.erase(self)
	player_data.spd_scaling -= 2
	player_data.emit_signal("spd_scaling_changed")
	self.queue_free()

func _on_BuffTimer_timeout():
	_remove_effect(player)
