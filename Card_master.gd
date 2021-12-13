extends Node2D

signal dragging_cards(card) #Let's know the Board which card is being dragged
signal select_card #Warns a card it was selected for autoplacement
var selected_cards := []
var left : bool

func _On_parent_warned(child,local_left) -> void: #Signal recieved from card click
	selected_cards.append(child)
	left = local_left

func _process(_delta) -> void: #At each frame, looks at all cards that were clicked
	find_dominance()
	selected_cards = []

func find_dominance() -> void:
	if selected_cards.size() >= 1: #Looks at all cards clicked and selects the one on top
		#Based on z_index
		#Linear maximum algorithm
		var max_z = selected_cards[0]
		for i in range(selected_cards.size()-1):
			if selected_cards[i].z_index < selected_cards[i+1].z_index:
				max_z = selected_cards[i+1]
		if left: #If dragging
			emit_signal("dragging_cards",max_z) #If dragging then warn Board
		else: #If not dragging
# warning-ignore:return_value_discarded
			self.connect("select_card",max_z,"_On_card_selected")
			emit_signal("select_card",left)
			self.disconnect("select_card",max_z,"_On_card_selected")
			#Connect and disconnect so we only warn one card that it was selected for autoplacement

func _on_Board_dragged_card(card) -> void:
	# warning-ignore:return_value_discarded
	self.connect("select_card",card,"_On_card_selected")
	emit_signal("select_card",left)
	self.disconnect("select_card",card,"_On_card_selected")
	#We let the card know it was selected for dragging
