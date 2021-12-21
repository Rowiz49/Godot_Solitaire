extends Node2D

signal dragged_card(card)
signal won
onready var deck_pos = $DeckPosition
onready var card_master = $Card_master
onready var row_positions = get_tree().get_nodes_in_group("Row")
onready var suit_positions = get_tree().get_nodes_in_group("Target")
onready var Card = load("res://Card.tscn")
onready var discard_pos = $DiscardPosition

var dragged_from : Array
var dragged_from_i : int
var suit_areas := []
var current_hand := []
var card_deck := []
var card_discard := []
var rows := [[],[],[],[],[],[],[]]
var suits := [[],[],[],[]]
var z_global := 1 #Variable that keeps selected cards always on top

func generate_cards() -> void: #Create the cards
	var suits_str = ["D","S","H","C"]
	for suit in suits_str:
		for number in [1,2,3,4,5,6,7,8,9,10,11,12,13]:
			var new_card = Card.instance()
			new_card.create(suit,number)
			new_card.set_position(deck_pos.get_global_position())
			card_deck.append(new_card)
	randomize()
	card_deck.shuffle()
	for next_card in card_deck:
		card_master.add_child(next_card)

func deal_cards() -> void: #deal the cards to the rows
	var new_pos
	for row_n in range(7):
		for _i in range(row_n+1):
			rows[row_n].append(card_deck.pop_back()) #Take from deck and put in one of the rows
			z_global += 1
			rows[row_n][-1].z_index = z_global
			new_pos = rows[row_n][-1].move_card(row_positions[row_n].get_global_position(),rows[row_n])
			rows[row_n][-1].set_old_pos(new_pos)
			yield(get_tree().create_timer(0.2), "timeout")
	yield(get_tree().create_timer(0.5), "timeout")
	for row_n in range(7): # Flip 1st card of each row
			rows[row_n][-1].flip_card()

func _ready() -> void:
	for i in row_positions: #Get areas to detect click released
		suit_areas.append(i.get_child(0))
	for j in suit_positions:
		suit_areas.append(j.get_child(1))
	suit_areas.append($Outside/OutsideArea)
	for k in suit_areas: #Connect the areas
		k.connect("released",self,"_On_drag_released")

func start():
	for card in card_master.get_children():
		card.queue_free()
	suits = [[],[],[],[]]
	rows = [[],[],[],[],[],[],[]]
	card_deck = []
	card_discard = []
	for i in suit_positions:
		i.visible = true
	deck_pos.visible = true
	generate_cards()
	deal_cards()

func _On_card_rightclicked(card) -> void:
	var new_row
	var previous_row
	var index = -1
	var current_handl := []
	var new_pos : Vector2
	for row in rows:  #Check the rows to know where the card is
		index = row.find(card,0)
		if index != -1:
			previous_row = row
			break
	if previous_row == null: #Check if it's a discard
		if card in card_discard:
			previous_row = card_discard
		else:
			for suit in suits:
				if card in suit:
					previous_row = suit
					break
	if !check_suits(card,previous_row): #Check if it goes to suit
		for row in range(rows.size()):
			if card.card_number == 13 and rows[row].size() == 0: #Check if king
				new_row = row
				break
			if rows[row].size() > 0 and rows[row] != previous_row and rows[row][-1].card_number == card.card_number + 1 and rows[row][-1].card_color_red != card.card_color_red : 
				#Check if possible move
				new_row = row
				break
		if new_row != null: #If the card can move
			if previous_row != null: #If it was not on a suit
				current_handl = previous_row.slice(index,previous_row.size(),1,true)
				for n_card in current_handl: #Move card by card to new position
					rows[new_row].append(n_card)
					z_global += 1
					n_card.z_index = z_global
					new_pos = n_card.move_card(row_positions[new_row].get_global_position(),rows[new_row])
					n_card.set_old_pos(new_pos)
					previous_row.erase(n_card)
					yield(get_tree().create_timer(0.1), "timeout")
				if previous_row == card_discard and card_discard.size() > 0:
					card_discard[-1].get_child(2).set_pickable(true)
				elif previous_row.size() > 0  and !previous_row[-1].get_child(2).is_pickable():
					#flip next card on row
					previous_row[-1].flip_card()
			elif previous_row == null: #Check for the suits discards
				for suit in suits:
					if card in suit:
						rows[new_row].append(card)
						z_global += 1
						card.z_index = z_global
						new_pos = card.move_card(row_positions[new_row].get_global_position(),rows[new_row])
						card.set_old_pos(new_pos)
						suit.erase(card)
						break
	else:
		if previous_row == card_discard and card_discard.size() > 0:
			card_discard[-1].get_child(2).set_pickable(true)
	if check_win():
		emit_signal("won")

func check_suits(card,row) -> bool:
	if row.size() > 0 and card != row[-1]:
		return false
	#returns true if the card can go in a suit, false if not
	var new_pos
	match card.suit_value: #Check the suit of the card, then if it can move
		"H":
			if card.card_number == suits[0].size() + 1:
				z_global += 1
				card.z_index = z_global
				new_pos = card.move_card(suit_positions[0].get_global_position(),[])
				card.set_old_pos(new_pos)
				suits[0].append(card)
				row.erase(card)
				if row != card_discard and row.size() > 0 and !row[-1].get_child(2).is_pickable():
					row[-1].flip_card()
				return true
		"D":
			if card.card_number == suits[1].size() + 1:
				z_global += 1
				card.z_index = z_global
				new_pos = card.move_card(suit_positions[1].get_global_position(),[])
				card.set_old_pos(new_pos)
				suits[1].append(card)
				row.erase(card)
				if row != card_discard and row.size() > 0 and !row[-1].get_child(2).is_pickable():
					row[-1].flip_card()
				return true
		"C":
			if card.card_number == suits[2].size() + 1:
				z_global += 1
				card.z_index = z_global
				new_pos = card.move_card(suit_positions[2].get_global_position(),[])
				card.set_old_pos(new_pos)
				suits[2].append(card)
				row.erase(card)
				if row != card_discard and row.size() > 0 and !row[-1].get_child(2).is_pickable():
					row[-1].flip_card()
				return true
		"S":
			if card.card_number == suits[3].size() + 1:
				z_global += 1
				card.z_index = z_global
				new_pos = card.move_card(suit_positions[3].get_global_position(),[])
				card.set_old_pos(new_pos)
				suits[3].append(card)
				row.erase(card)
				if row != card_discard and row.size() > 0 and !row[-1].get_child(2).is_pickable():
					row[-1].flip_card()
				return true
	return false

func _on_Deck_clicker_button_down() -> void: #when deck is clicked
	var new_pos
	if card_deck.size() > 0: #if there are cards in deck take the firs one and put it in discard
		var card_to_move = card_deck.pop_front()
		z_global += 1
		card_to_move.z_index = z_global 
		new_pos = card_to_move.move_card(discard_pos.get_global_position(),[])
		card_to_move.set_old_pos(new_pos)
		if card_discard.size() > 0:
			card_discard[-1].get_child(2).set_pickable(false) #Card below cannot be clicked
		card_discard.append(card_to_move)
		card_to_move.flip_card()
		yield(get_tree().create_timer(0.5),"timeout")
	else:
		for _i in range(card_discard.size()):# If the deck is void then we refill itin the same order
			var card_to_move = card_discard.pop_front()
			card_to_move.get_child(2).set_pickable(true)
			z_global += 1
			card_to_move.z_index = z_global
			new_pos = card_to_move.move_card(deck_pos.get_global_position(),[])
			card_to_move.set_old_pos(new_pos)
			card_deck.append(card_to_move)
			card_to_move.flip_card()

func check_win() -> bool: #Check if the player won
	if card_discard.size() == 0 and card_deck.size() == 0: #Check if decks are empty
		var won = true
		for row in rows:
			if row.size() != 0 and !row[0].get_child(2).is_pickable():
				won = false
				return false
		return true
	return false
		


func _on_Card_master_dragging_cards(card) -> void: # Looks where the card is dragged from and slices to create current hand
	if card in card_discard: #Search card in discard pile
		dragged_from = card_discard
		current_hand = [card]
	else:
		var index = 0
		for row in rows: #Search card amidst the rows
			if card in row: #If it is select every card beneath it
				dragged_from = row
				dragged_from_i = index
				current_hand = dragged_from.slice(dragged_from.find(card),-1)
				break
			index += 1
		if dragged_from != null: #Search card in suits
			index = 0
			for suit in suits:
				if card in suit:
					dragged_from = suit
					dragged_from_i = index
					current_hand = [card]
					break
				index += 1
	for i in current_hand:
		emit_signal("dragged_card",i)
	z_global += 1
	current_hand[0].z_index = z_global

func _On_drag_released(released_in):
	if current_hand.size() != 0:
		var movement_completed := false
		var new_row : int
		var card = current_hand[0]
		var new_pos
		#Check where it was released
		if released_in in suit_positions:
			movement_completed = check_suits(card,dragged_from)
			if dragged_from == card_discard and card_discard.size() > 0:
				card_discard[-1].get_child(2).set_pickable(true)
		elif released_in in row_positions:
			var valid := false
			new_row = row_positions.find(released_in)
			if card.card_number == 13 and rows[new_row].size() == 0: #Check if king
				valid = true
			if rows[new_row].size() > 0 and rows[new_row][-1].card_number == card.card_number + 1 and rows[new_row][-1].card_color_red != card.card_color_red : 
				#Check if possible move
				valid = true
			if valid: #If the card can move
				for n_card in current_hand: #Move card by card to new position
					rows[new_row].append(n_card)
					z_global += 1
					n_card.z_index = z_global
					new_pos = n_card.move_card(row_positions[new_row].get_global_position(),rows[new_row])
					n_card.set_old_pos(new_pos)
					dragged_from.erase(n_card)
				if dragged_from == card_discard and card_discard.size() > 0:
					card_discard[-1].get_child(2).set_pickable(true)
				elif dragged_from.size() > 0  and !dragged_from[-1].get_child(2).is_pickable():
					#flip next card on new_row 
					dragged_from[-1].flip_card()
				movement_completed = true
		if !movement_completed:
			for n_card in current_hand:
				n_card.go_back()
		current_hand[0].z_index = current_hand[0].z_index - current_hand.size()
	# warning-ignore:return_value_discarded 
		current_hand = []
		if check_win():
			emit_signal("won")
