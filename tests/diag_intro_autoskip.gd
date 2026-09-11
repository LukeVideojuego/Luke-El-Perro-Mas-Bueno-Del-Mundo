extends Node

## Punto 2 (segunda ronda): si el jugador no toca nada durante la
## cinemática de introducción, el juego arrancaba el Nivel 1 de una sola
## vez (saltando los paneles 2 y 3) apenas vencía el timeout de 10s del
## panel 1. Verifica, sin tocar ningún input, que los 3 paneles se
## muestran EN ORDEN (uno cada ~10s) antes de que finished se emita.

const INTRO := preload("res://scenes/cinematics/intro_cinematic.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

var intro: Node
var seen_panel2 := false
var seen_panel3 := false
var got_finished := false
var t := 0.0
var last_panel := 1

func _ready() -> void:
	intro = INTRO.instantiate()
	add_child(intro)
	intro.finished.connect(func(): got_finished = true)

func _process(delta: float) -> void:
	t += delta
	var p: int = intro.get_current_panel()
	if p != last_panel:
		print("t=%.1f panel cambio %d -> %d" % [t, last_panel, p])
		last_panel = p
	if p == 2:
		seen_panel2 = true
	if p == 3:
		seen_panel3 = true
	if got_finished or t >= 33.0:
		_check(seen_panel2, "panel 2 se muestra sin tocar nada (no salta directo)")
		_check(seen_panel3, "panel 3 se muestra sin tocar nada")
		_check(got_finished, "recien termina (finished) despues de pasar por los 3 paneles, no antes")
		print("RESULTADO: ", fail_count, " fallos (t=%.1f)" % t)
		get_tree().quit()
