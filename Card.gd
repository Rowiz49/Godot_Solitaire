extends Node2D

signal warn_parent(card_clicked,left) #This warns and enables selection based on z_index, connected to Card_Master
signal rightclicked(card_clicked) #This triggers the autoplacement, connected to Board
onready var sprite = $AnimatedSprite
onready var tween = $Tween
var old_pos : Vector2 #when coming back
var destination : Vector2 #where to go
var sprite_n := 0
var suit_value := ""
var card_number : int
var card_color_red : bool
var dragging := false
var moving := false
var time : float #In order to get a constant lerp
onready var board_node := get_tree().get_root().get_node("Board")
onready var parent := self.get_parent()
onready var click_area := $Card_Hitbox

func _to_string() -> String: #For debugging
	return suit_value+"/"+str(card_number)

func create(suit,number) -> void: #Init card
	suit_value = suit
	card_number = number
	card_color_red = true if suit == "D" or suit == "H" else false #The suit is either red(true) or black(false)
	match suit: #Transform card_number into sprite_n
		"C":
			sprite_n = card_number
		"D":
			sprite_n = card_number + 13
		"H":
			sprite_n = card_number + 26
		"S":
			sprite_n = card_number + 39

func _ready() -> void:#The card connects and cannot register input
# warning-ignore:return_value_discarded
	self.connect("warn_parent",get_parent(),"_On_parent_warned")
# warning-ignore:return_value_discarded
	self.connect("rightclicked",get_parent().get_parent(),"_On_card_rightclicked")
	click_area.input_pickable = false

func flip_card() -> void: #Flip card and make it clickable
	tween.interpolate_property(sprite,"scale",Vector2(2,2),Vector2(0,2),0.3,Tween.TRANS_QUAD,Tween.EASE_IN)
	tween.start()
	sprite.frame = sprite_n if !click_area.input_pickable else 0
	tween.interpolate_property(sprite,"scale",Vector2(0,2),Vector2(2,2),0.3,Tween.TRANS_QUAD,Tween.EASE_OUT)
	tween.start()
	click_area.input_pickable = !click_area.input_pickable

func move_card(ldestination,row) -> Vector2:
	#Moves card to a row, in a vector2 destination, offset based on the row
	#Returns the new position in order to use set_old_pos()
	destination = ldestination+Vector2(0,30*row.size())
	time = 0
	moving = true
	return destination

func _physics_process(delta) -> void:
	if moving: #Go back if the dragging was not correct
		time += delta
		global_position = lerp(global_position,destination,time/(200*delta))
		if global_position.round() == destination.round(): #You need to round in order to avoid decimal error
			moving = false
	elif dragging: #Go to mouse position if dragging
		global_position = lerp(global_position,get_global_mouse_position(),25*delta)

func _On_card_selected(left) -> void: #Drag and put card on top
	if left: #Drag if left click
		dragging = true
		if board_node.z_global > z_index:
			board_node.z_global += 1
			z_index = board_node.z_global
	else: #Autoplace if right click
		emit_signal("rightclicked",self)

func set_old_pos(new_pos) -> void:
	#Register the position in order to be able to go back
	old_pos = new_pos
	
func go_back():
	time = 0
	destination = old_pos
	moving = true

func _on_Card_Hitbox_input_event(_viewport, _event, _shape_idx) -> void:#If clicked
	if Input.is_action_just_pressed("right-click"):
		emit_signal("warn_parent",self,false)
	elif Input.is_action_just_pressed("click"):
		emit_signal("warn_parent",self,true)
	if Input.is_action_just_released("click"):
		dragging = false
