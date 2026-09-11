extends Node2D

## Punto 15: el minijuego final se da por terminado solo, sin que el
## jugador haga nada. Instancia el nivel real y observa time_left,
## hugged_count y minigame_over a lo largo de todo time_limit (ticks
## reales, sin tocar ningún input), para ver si el conteo de abrazos sube
## solo (NPCs deambulando que caminan hacia Luke quieto) y si eso alcanza
## a completar el objetivo antes de que se agote el reloj.

const LEVEL := preload("res://scenes/levels/final_screen.tscn")

var level: HugMinigame
var last_hugged := -1
var last_second_printed := -1

func _ready() -> void:
	level = LEVEL.instantiate()
	add_child(level)
	print("total_people=", level.total_people, " time_limit=", level.time_limit)

func _process(_delta: float) -> void:
	var sec := int(level.time_limit - level.time_left)
	if sec != last_second_printed or level.hugged_count != last_hugged:
		last_second_printed = sec
		last_hugged = level.hugged_count
		print("t=%.1f hugged=%d/%d over=%s" % [level.time_limit - level.time_left, level.hugged_count, level.total_people, level.minigame_over])
	if level.minigame_over or level.time_left <= 0.0:
		print("RESULTADO: minigame_over=%s time_left=%.2f hugged=%d/%d (sin ningun input del jugador)" % [
			level.minigame_over, level.time_left, level.hugged_count, level.total_people])
		get_tree().quit()
