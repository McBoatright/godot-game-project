extends Node
class_name RiverManager

# River configuration
const RIVER_SIZE = 6  # 6 spell orbs in the river (3 player, 3 opponent)
const RUN_DURATION = 10.0  # 10 seconds per river run (for testing)
const NUM_RUNS = 5  # 5 different run patterns before looping

# River run patterns [tier1, tier2] for each run
const RUN_PATTERNS = [
	[2, 2],      # Run 1: 2-mana (Fireball)
	[3, 3],      # Run 2: 3-mana (Shield)
	[2, 3],      # Run 3: 2-3 mana (Both)
	[2, 3],      # Run 4: 2-3 mana (Both)
	[2, 3]       # Run 5: 2-3 mana (Both)
]

# River state
var river_orbs: Array = []  # Array of 6 spell orbs (or null if picked)
var visual_orbs: Array = []  # Array of spawned orb nodes in the world
var current_run: int = 0  # Current run number (0-4)
var run_timer: Timer
var time_remaining: float = RUN_DURATION

# Fixed river runs - each run has its spells set at match start
var fixed_river_runs: Array = [[], [], [], [], []]  # 5 runs, each with 6 orb slots

# Orb spawning
var world_node = null  # Reference to world scene for spawning orbs

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
	# Connect to deck refresh signal
	if deck_manager:
		deck_manager.deck_refreshed.connect(_on_deck_refreshed)
	print("DeckManager connected to River")

func set_world_node(world):
	world_node = world
	print("World node connected to River for orb spawning")

func initialize_fixed_runs():
	# Initialize all 5 river runs with their fixed spells at match start
	# This ensures spells stay consistent across the entire match
	
	if not deck_manager:
		print("ERROR: DeckManager not set!")
		return
	
	print("=== INITIALIZING FIXED RIVER RUNS ===")
	
	for run_number in range(NUM_RUNS):
		var pattern = RUN_PATTERNS[run_number]
		var tier1 = pattern[0]
		var tier2 = pattern[1]
		
		# Get spells for this run's tiers
		var run_spells = []
		for tier in range(tier1, tier2 + 1):
			var tier_spells = deck_manager.get_spells_by_tier(tier)
			for spell in tier_spells:
				run_spells.append(spell)
		
		print("Run ", run_number + 1, ": Found ", run_spells.size(), " spells (tiers ", tier1, "-", tier2, ")")
		
		# Assign spells to 6 orb slots (3 player, 3 opponent)
		# Even indices = player, odd indices = opponent
		for i in range(RIVER_SIZE):
			var is_player_orb = (i % 2 == 0)
			
			if run_spells.size() > 0:
				# Use modulo to cycle through available spells if we have fewer than 6
				var spell_index = i % run_spells.size()
				var spell = run_spells[spell_index]
				fixed_river_runs[run_number].append({
					"spell": spell,
					"is_player": is_player_orb,
					"picked": false
				})
				print("  Orb ", i, ": ", spell.spell_name, " (", "PLAYER" if is_player_orb else "OPPONENT", ")")
			else:
				# No spells available at all
				fixed_river_runs[run_number].append(null)
				print("  Orb ", i, ": EMPTY (no spells available)")
	
	print("=== RIVER RUNS INITIALIZED ===")

func start_river_run(run_number: int = 0):
	if run_number < 0 or run_number >= NUM_RUNS:
		run_number = 0
	
	current_run = run_number
	time_remaining = RUN_DURATION
	
	print("Starting river run ", run_number + 1, "/", NUM_RUNS)
	load_river_from_fixed_run(run_number)
	
	print("River run started - Run ", run_number + 1, "/", NUM_RUNS, " (", RUN_DURATION, " seconds)")
	run_timer.start()

func load_river_from_fixed_run(run_number: int):
	# Load the fixed river run (with current picked state)
	river_orbs.clear()
	
	if fixed_river_runs[run_number].is_empty():
		print("ERROR: Fixed run ", run_number, " is empty!")
		return
	
	# Copy the fixed run's orbs (preserving picked state)
	for orb_data in fixed_river_runs[run_number]:
		river_orbs.append(orb_data)
	
	river_refreshed.emit(run_number)
	print("River loaded from fixed run ", run_number + 1)
	print_river_state()
	
	# Spawn visual orbs in the world
	spawn_visual_orbs()

func spawn_visual_orbs():
	# Clear any existing visual orbs
	clear_visual_orbs()
	
	if not world_node:
		print("WARNING: World node not set, can't spawn visual orbs")
		return
	
	print("DEBUG: Spawning visual orbs, world_node exists")
	
	# Spawn orbs in center of map
	var spawn_center = Vector2(320, 130)  # Shifted right from 280 to 320
	print("DEBUG: Spawning orbs at map center: ", spawn_center)
	
	# Spawn pattern: Horizontal row in center of map
	var spacing = 80.0  # Space between orbs (increased from 60)
	var start_x = spawn_center.x - (RIVER_SIZE * spacing / 2)
	
	for i in range(river_orbs.size()):
		var orb_data = river_orbs[i]
		if not orb_data or orb_data.picked:
			print("DEBUG: Skipping orb ", i, " - null or picked")
			continue
		
		print("DEBUG: Creating orb ", i, " - ", orb_data.spell.spell_name)
		
		# Calculate position in row - use orb index i to keep empty spaces for picked orbs
		var spawn_pos = Vector2(start_x + (i * spacing), spawn_center.y)
		
		print("DEBUG: Orb ", i, " spawn position: ", spawn_pos)
		
		# Create visual orb (load scene dynamically)
		var orb_scene = load("res://scenes/spell_orb.tscn")
		if not orb_scene:
			print("ERROR: Could not load orb scene!")
			continue
		var orb_instance = orb_scene.instantiate()
		orb_instance.position = spawn_pos
		orb_instance.setup(orb_data.spell, orb_data.is_player, i)
		
		# Add to world with y_sort enabled
		world_node.add_child(orb_instance)
		orb_instance.z_index = 10  # Render above ground
		visual_orbs.append(orb_instance)
		print("DEBUG: Orb ", i, " added to world at z_index 10")
	
	print("Spawned ", visual_orbs.size(), " visual orbs in the world")

func clear_visual_orbs():
	for orb in visual_orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	visual_orbs.clear()

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

func _on_deck_refreshed():
	# When deck refreshes, reset all picked states in fixed river runs
	print("=== RIVER: Deck refreshed, resetting all orb picked states ===")
	for run in fixed_river_runs:
		for orb_data in run:
			if orb_data:
				orb_data.picked = false
	
	# Don't reload current run - wait for next river run cycle to show refreshed orbs
	print("  -> Orbs will reappear on next river run cycle")
