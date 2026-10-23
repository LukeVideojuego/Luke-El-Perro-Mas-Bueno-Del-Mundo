extends Node2D

## A2: confirma con un jefe real (no solo lectura de constantes, y con vida
## suficiente para no morir a mitad de la prueba) que:
##  1. Un golpe cuerpo a cuerpo quita 1 de vida.
##  2. Un huesito quita 1 de vida (ThrownBone.DAMAGE).
##  3. Un ladrido de onda quita exactamente 3 de vida (BarkWave.DAMAGE),
##     el TRIPLE del huesito -- la relación real se verifica contra
##     ThrownBone.DAMAGE, no contra un "3" hardcodeado en el ladrido.

const BossScene := preload("res://scenes/enemies/thief_boss.tscn")
const BarkWaveScene := preload("res://scenes/objects/bark_wave.tscn")
const ThrownBoneScript := preload("res://scripts/world/thrown_bone.gd")
const BarkWaveScript := preload("res://scripts/world/bark_wave.gd")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _spawn_boss() -> Node2D:
	var boss: Node2D = BossScene.instantiate()
	boss.position = Vector2(0, 0)
	add_child(boss)
	return boss

func _ready() -> void:
	# 1: valores "de fabrica" (constantes), antes de tocar ningun enemigo.
	_check(ThrownBoneScript.DAMAGE == 1, "huesito (ThrownBone.DAMAGE) = 1 (es %d)" % ThrownBoneScript.DAMAGE)
	_check(BarkWaveScript.DAMAGE == 3, "ladrido (BarkWave.DAMAGE) = 3 (es %d)" % BarkWaveScript.DAMAGE)
	_check(BarkWaveScript.DAMAGE == 3 * ThrownBoneScript.DAMAGE,
		"ladrido es EXACTAMENTE el triple del huesito (%d == 3 x %d)" % [BarkWaveScript.DAMAGE, ThrownBoneScript.DAMAGE])

	# 2: golpe cuerpo a cuerpo real (amount por defecto = 1, igual que Luke).
	var boss1 := _spawn_boss()
	var health_before: int = boss1.health
	boss1.receive_attack(self)
	_check(boss1.health == health_before - 1, "golpe cuerpo a cuerpo real quita 1 de vida (%d -> %d)" % [health_before, boss1.health])
	boss1.queue_free()
	await get_tree().physics_frame

	# 3: huesito real (mismo DAMAGE que usa thrown_bone.gd de verdad).
	var boss2 := _spawn_boss()
	health_before = boss2.health
	boss2.receive_attack(self, ThrownBoneScript.DAMAGE)
	_check(boss2.health == health_before - 1, "huesito real quita 1 de vida (%d -> %d)" % [health_before, boss2.health])
	boss2.queue_free()
	await get_tree().physics_frame

	# 4: ladrido real (bark_wave.tscn instanciado y lanzado, como lo tira
	#    Luke) contra la hurtbox real del jefe -- confirma el daño EN EL
	#    CAMINO REAL del proyectil, no solo llamando receive_attack a mano.
	var boss3 := _spawn_boss()
	await get_tree().physics_frame
	health_before = boss3.health
	var wave: Area2D = BarkWaveScene.instantiate()
	add_child(wave)
	wave.launch(Vector2(-60, 0), 1.0, self)
	for i in range(20):
		await get_tree().physics_frame
	_check(boss3.health == health_before - 3,
		"ladrido real (bark_wave.tscn) quita exactamente 3 de vida (%d -> %d)" % [health_before, boss3.health])
	boss3.queue_free()

	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()
