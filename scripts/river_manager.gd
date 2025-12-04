extends Node
class_name RiverManager

# River configuration
const RIVER_SIZE = 6  # 6 spell orbs in the river (3 player, 3 opponent)
const RUN_DURATION = 30.0  # 30 seconds per river run
const NUM_RUNS = 5  # 5 different run patterns before looping

# River run patterns [tier1, tier2] for each run
const RUN_PATTERNS = [
	[1, 1],      # Run 1: Only 1-cost
	[1, 2],      # Run 2: 1-cost and 2-cost
	[2, 3],      # Run 3: 2-cost and 3-cost
	[3, 4],      # Run 4: 3-cost and 4-cost
	[1, 5]       # Run 5: Any cost (1-5)
]

# River state
var river_orbs: Array = []  # Array of 6 spell orbs (or null if picked)
var current_run: int = 0  # Current run number (0-4)
var run_timer: Timer
var time_remaining: float = RUN_DURATION

# Signals
signal river_refreshed(run_number: int)
signal orb_picked(orb_index: int, spell: Spell, is_player: bool)
signal river_run_complete(run_number: int)
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

func start_river_run(run_number: int = 0):
	if run_number < 0 or run_number >= NUM_RUNS:
		run_number = 0
	
	current_run = run_number
	time_remaining = RUN_DURATION
	populate_river(run_number)
	run_timer.start()
	print("River run started - Run ", run_number + 1, "/", NUM_RUNS, " (", RUN_DURATION, " seconds)")

func populate_river(run_number: int):
	river_orbs.clear()
	
	if not deck_manager:
		print("ERROR: DeckManager not set!")
		return
	
	# Get the tier pattern for this run
	var pattern = RUN_PATTERNS[run_number]
	var tier1 = pattern[0]
	var tier2 = pattern[1]
	
	# Get available spells for these tiers
	var available = []
	for tier in range(tier1, tier2 + 1):
		var tier_spells = deck_manager.get_spells_by_tier(tier)
		for spell in tier_spells:
			available.append(spell)
	
	if available.is_empty():
		print("No spells available for Run ", run_number + 1, " - all picked up!")
		river_refreshed.emit(run_number)
		return
	
	# Shuffle available spells
	available.shuffle()
	
	# Fill 6 orbs: 3 player (even indices), 3 opponent (odd indices)
	for i in range(RIVER_SIZE):
		var is_player_orb = (i % 2 == 0)  # 0,2,4 = player; 1,3,5 = opponent
		
		if available.size() > 0:
			var spell = available.pop_front()
			river_orbs.append({
				"spell": spell,
				"is_player": is_player_orb,
				"picked": false
			})
		else:
			# Not enough spells left
			river_orbs.append(null)
	
	river_refreshed.emit(run_number)
	print("River populated with ", river_orbs.size(), " orbs (Run ", run_number + 1, ")")
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
	
	# Remove this spell from the deck permanently (until deck refresh)
	if deck_manager:
		deck_manager.remove_spell_from_available(spell)
	
	orb_picked.emit(orb_index, spell, is_player)
	print("Orb ", orb_index, " picked: ", spell.spell_name)
	print("  -> Spell removed from deck until refresh")
	
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
	print("River run complete! Run ", current_run + 1, " finished.")
	river_run_complete.emit(current_run)
	
	# Auto-advance to next run (cycle 0-4)
	var next_run = current_run + 1
	if next_run >= NUM_RUNS:
		next_run = 0  # Loop back to run 1
	
	# Start next river run
	start_river_run(next_run)

func force_end_run():
	if run_timer and not run_timer.is_stopped():
		run_timer.stop()
		_on_river_run_timeout()
		_on_river_run_timeout()
