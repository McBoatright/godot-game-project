extends Node
class_name RiverManager

# River configuration
const RIVER_SIZE = 6  # 6 spell orbs in the river
const RUN_DURATION = 30.0  # 30 seconds per river run
const TIERS = [1, 2, 3, 4, 5]  # Mana cost tiers

# River state
var river_orbs: Array = []  # Array of 6 spell orbs (or null if picked)
var current_tier: int = 1  # Current mana tier (1-5)
var run_timer: Timer
var time_remaining: float = RUN_DURATION

# Signals
signal river_refreshed(tier: int)
signal orb_picked(orb_index: int, spell: Spell, is_player: bool)
signal river_run_complete(tier: int)
signal timer_updated(time_left: float)

var deck_manager = null  # Reference to DeckManager

func _ready():
	setup_river_timer()
	print("River system initialized")

func setup_river_timer():
	run_timer = Timer.new()
	run_timer.name = "RiverRunTimer"
	run_timer.wait_time = RUN_DURATION
	run_timer.autostart = false
	run_timer.one_shot = true
	add_child(run_timer)
	run_timer.timeout.connect(_on_river_run_timeout)

func _process(_delta):
	if run_timer and not run_timer.is_stopped():
		time_remaining = run_timer.time_left
		timer_updated.emit(time_remaining)

func set_deck_manager(dm):
	deck_manager = dm
	print("DeckManager connected to River")

func start_river_run(tier: int = 1):
	if tier < 1 or tier > 5:
		print("Invalid tier: ", tier)
		return
	
	current_tier = tier
	time_remaining = RUN_DURATION
	populate_river(tier)
	run_timer.start()
	print("River run started - Tier ", tier, " (", RUN_DURATION, " seconds)")

func populate_river(tier: int):
	river_orbs.clear()
	
	if not deck_manager:
		print("ERROR: DeckManager not set!")
		return
	
	# Get spells of this tier
	var tier_spells = deck_manager.get_spells_by_tier(tier)
	
	if tier_spells.is_empty():
		print("No spells available for tier ", tier)
		return
	
	# Fill 6 orbs alternating player/opponent
	for i in range(RIVER_SIZE):
		var is_player_orb = (i % 2 == 0)  # Even indices = player, odd = opponent
		
		# Pick a random spell from available tier spells
		if tier_spells.size() > 0:
			var spell = tier_spells[randi() % tier_spells.size()]
			river_orbs.append({
				"spell": spell,
				"is_player": is_player_orb,
				"picked": false
			})
		else:
			river_orbs.append(null)
	
	river_refreshed.emit(tier)
	print("River populated with ", river_orbs.size(), " orbs (Tier ", tier, ")")
	print_river_state()

func print_river_state():
	print("=== RIVER STATE ===")
	for i in range(river_orbs.size()):
		var orb = river_orbs[i]
		if orb and not orb.picked:
			var orb_owner = "PLAYER" if orb.is_player else "OPPONENT"
			print("  [", i, "] ", orb_owner, ": ", orb.spell.spell_name, " (", orb.spell.mana_cost, " mana)")
		else:
			print("  [", i, "] EMPTY")
	print("==================")

func pick_orb(orb_index: int, is_player: bool) -> Spell:
	if orb_index < 0 or orb_index >= river_orbs.size():
		print("Invalid orb index: ", orb_index)
		return null
	
	var orb = river_orbs[orb_index]
	if not orb or orb.picked:
		print("Orb ", orb_index, " is empty or already picked")
		return null
	
	# Check if this orb belongs to the correct player
	if orb.is_player != is_player:
		var orb_owner = "opponent" if orb.is_player else "player"
		print("This orb belongs to the ", orb_owner, "!")
		return null
	
	# Pick the orb
	orb.picked = true
	var spell = orb.spell
	orb_picked.emit(orb_index, spell, is_player)
	print("Orb ", orb_index, " picked: ", spell.spell_name)
	
	return spell

func get_player_orbs() -> Array:
	var player_orbs = []
	for i in range(river_orbs.size()):
		var orb = river_orbs[i]
		if orb and orb.is_player and not orb.picked:
			player_orbs.append({"index": i, "spell": orb.spell})
	return player_orbs

func get_available_orb_count(is_player: bool) -> int:
	var count = 0
	for orb in river_orbs:
		if orb and orb.is_player == is_player and not orb.picked:
			count += 1
	return count

func _on_river_run_timeout():
	print("River run complete! Tier ", current_tier, " finished.")
	river_run_complete.emit(current_tier)
	
	# Auto-advance to next tier (cycle 1-5)
	var next_tier = current_tier + 1
	if next_tier > 5:
		next_tier = 1
	
	# Start next river run
	start_river_run(next_tier)

func force_end_run():
	if run_timer and not run_timer.is_stopped():
		run_timer.stop()
		_on_river_run_timeout()
