extends CanvasLayer

signal start_game
onready var in_game := [$RestartButton]
onready var out_of_game := [$Panel,$StartButton,$CloseButton,$Signature]
var paused := false
var play_image := load("res://PNG/GUI/play.png")
var pause_image := load("res://PNG/GUI/pause.png")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for node in in_game:
		node.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_StartButton_pressed() -> void:
	get_tree().paused = false
	for node in out_of_game:
		node.visible = false
	for node in in_game:
		node.visible = true
	if paused:
		$RestartButton/TextureRect.texture = pause_image
		$RestartButton/TextureRect.rect_position.x = 8
		for node in out_of_game:
			node.visible = false
		get_tree().paused = false
		paused = false
	emit_signal("start_game")


func _on_CloseButton_pressed() -> void:
	get_tree().quit()


func _on_RestartButton_pressed() -> void:
	if paused:
		$RestartButton/TextureRect.texture = pause_image
		$RestartButton/TextureRect.rect_position.x = 8
		for node in out_of_game:
			node.visible = false
		get_tree().paused = false
		paused = false
	else:
		$RestartButton/TextureRect.texture = play_image
		$RestartButton/TextureRect.rect_position.x = 0
		$Panel/Title.text = "PAUSED"
		$StartButton/Label.text = "RESTART"
		$CloseButton/Label.text = "CLOSE GAME"
		for node in out_of_game:
			node.visible = true
		get_tree().paused = true
		paused = true


func _on_Board_won() -> void:
	$Panel/Title.text = "YOU WON!"
	$StartButton/Label.text = "RESTART"
	$CloseButton/Label.text = "CLOSE GAME"
	for node in out_of_game:
		node.visible = true
