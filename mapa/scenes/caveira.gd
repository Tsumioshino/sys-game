extends Area2D

var timerIn = Timer.new()

var players = {}

func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		players[body.get_name()] = body
		yield(get_tree().create_timer(10), "timeout")
		if body.get_name() in players:
			body._call_win()
		


func _on_Area2D_body_exited(body):
	if body.is_in_group("player"):
		players.erase(body.get_name())
