# Moon Landing Tutorial and Progression System - Integration Guide

## Overview

This guide explains how to integrate the tutorial and progression systems into the moon landing scene (`moon_landing.tscn`).

## New Components Created

### 1. Tutorial System (`scripts/gameplay/moon_tutorial_manager.gd`)

**Purpose**: Guides players through the landing process step-by-step.

**Tutorial Steps**:
1. **Welcome** - Introduction to lunar descent
2. **Thrust Forward** - Learn W key for forward movement
3. **Altitude Control** - Learn SPACE key for vertical thrust
4. **Speed Control** - Maintain safe landing speed (<5 m/s)
5. **Gentle Landing** - Touch down on the moon
6. **Exit Spacecraft** - Press SPACE to switch to walking mode
7. **First Jump** - Experience lunar gravity

**Features**:
- Auto-detects player actions and advances tutorial
- Skippable with ESC key
- Saves progress to prevent repetition
- Visual feedback through TutorialPrompt UI

### 2. Progression System (`scripts/gameplay/moon_progression_tracker.gd`)

**Purpose**: Tracks achievements, missions, and high scores.

**Achievements** (12 total):
- **First Steps** - Complete first landing (100 pts)
- **Smooth Operator** - Land under 2 m/s (200 pts)
- **Perfection** - Land under 1 m/s in target zone (500 pts)
- **Lunar Explorer** - Travel 100m from landing (150 pts)
- **Long Distance Walker** - Travel 500m (300 pts)
- **Lunar Marathon** - Travel 1000m (1000 pts)
- **Jumper** - Jump 10 times (100 pts)
- **High Jumper** - Jump 20 times (200 pts)
- **Lunar Olympian** - Jump 50 times (500 pts)
- **Fuel Efficient** - Land with 50% fuel (300 pts)
- **Speedrunner** - Land in under 60s (400 pts)
- **Veteran Pilot** - Complete 5 landings (600 pts)

**Missions** (6 total):
1. **First Landing** (Tutorial) - Complete tutorial
2. **Precision Landing** - Land in target zone
3. **Quick Descent** - Land quickly
4. **Fuel Conservation** - Land with fuel remaining
5. **Lunar Survey** - Explore marked locations
6. **Lunar Olympics** - Jump challenges

**Scoring**:
- Base score: 1000 per landing
- Speed bonus: Up to 500 for perfect landing
- Time bonus: Up to 200 for quick landing
- Distance bonus: 1 point per 10m explored
- Jump bonus: 10 points per jump

### 3. UI Components

#### `TutorialPrompt` (`scripts/ui/tutorial_prompt.gd`)
- Floating panel with tutorial instructions
- Shows title, instruction text, and hints
- Slide-in animations and shake effects
- Skip button
- Progress bar for tutorial completion

#### `AchievementNotification` (`scripts/ui/achievement_notification.gd`)
- Slides in from right side
- Shows achievement name, description, and points
- Gold/achievement themed styling
- Auto-dismisses after 3 seconds
- Queues multiple achievements

#### `MoonHUDEnhanced` (`scripts/ui/moon_hud_enhanced.gd`)
- Integrates tutorial, progression, and basic HUD
- Color-coded altitude and speed indicators
- Real-time score and objective tracking
- Achievement notification queue
- Mission progress display

## Integration Steps

### Step 1: Add Scripts to Scene

In `moon_landing.tscn`, add these nodes:

```gdscript
# Add as child of root
MoonTutorialManager (moon_tutorial_manager.gd)
MoonProgressionTracker (moon_progression_tracker.gd)

# Replace or enhance existing MoonHUD
MoonHUDEnhanced (moon_hud_enhanced.gd)

# Add as children of MoonHUDEnhanced
  ├─ TutorialPrompt (tutorial_prompt.gd)
  └─ AchievementNotification (achievement_notification.gd)
```

### Step 2: Update MoonLandingInitializer

Modify `scripts/gameplay/moon_landing_initializer.gd`:

```gdscript
@export var tutorial_manager: MoonTutorialManager = null
@export var progression_tracker: MoonProgressionTracker = null
@export var moon_hud_enhanced: MoonHUDEnhanced = null

func find_scene_nodes() -> void:
	# ... existing code ...

	if not tutorial_manager:
		tutorial_manager = get_node_or_null("../MoonTutorialManager")
	if not progression_tracker:
		progression_tracker = get_node_or_null("../MoonProgressionTracker")
	if not moon_hud_enhanced:
		moon_hud_enhanced = get_node_or_null("../UI/MoonHUDEnhanced")

func initialize_tutorial_and_progression() -> void:
	"""Initialize tutorial and progression systems."""
	# Initialize tutorial manager
	if tutorial_manager:
		tutorial_manager.initialize(
			landing_detector,
			spacecraft,
			moon_hud_enhanced,
			transition_system,
			moon_hud_enhanced.tutorial_prompt if moon_hud_enhanced else null
		)
		print("[MoonLandingInitializer] Tutorial manager initialized")

	# Initialize progression tracker
	if progression_tracker:
		progression_tracker.initialize(
			landing_detector,
			spacecraft,
			transition_system
		)
		progression_tracker.start_landing_session()
		print("[MoonLandingInitializer] Progression tracker initialized")

	# Initialize enhanced HUD
	if moon_hud_enhanced:
		var walking_controller = transition_system.get_walking_controller() if transition_system else null
		moon_hud_enhanced.initialize(
			landing_detector,
			walking_controller,
			tutorial_manager,
			progression_tracker
		)
		print("[MoonLandingInitializer] Enhanced HUD initialized")

func _ready() -> void:
	# ... existing code ...
	initialize_moon()
	initialize_spacecraft()
	initialize_landing_detector()
	initialize_tutorial_and_progression()  # Add this
	apply_lunar_gravity()
```

### Step 3: Create UI Layout

If building UI in the Godot editor, use this structure:

```
CanvasLayer (MoonHUDEnhanced)
├─ StatusLabel (Label) - Top-left
│   └─ Text: "Status: IN FLIGHT"
├─ AltitudeLabel (Label) - Below status
│   └─ Text: "Altitude: High"
├─ VelocityLabel (Label) - Below altitude
│   └─ Text: "Speed: 0.0 m/s"
├─ LandingPrompt (Label) - Center
│   └─ Text: "Press [SPACE] to Exit Spacecraft"
├─ ScoreLabel (Label) - Top-right
│   └─ Text: "Score: 0"
├─ MissionLabel (Label) - Below score
│   └─ Text: "Mission: First Landing"
├─ ObjectivesLabel (Label) - Right side
│   └─ Text: "OBJECTIVES:\n[ ] Land successfully\n..."
├─ ProgressBar (ProgressBar) - Bottom center
│   └─ Shows tutorial/achievement progress
├─ TutorialPrompt (TutorialPrompt) - Top-left overlay
└─ AchievementNotification (AchievementNotification) - Right side
```

### Step 4: Connect Signals

The systems auto-connect most signals. Verify these connections:

**Landing Detector → Tutorial Manager**:
- `landing_detected` → Tutorial advances to "exit spacecraft" step
- `walking_mode_requested` → Tutorial advances to "first jump" step

**Landing Detector → Progression Tracker**:
- `landing_detected` → Records successful landing, calculates score
- Triggers achievement checks

**Tutorial Manager → HUD**:
- `tutorial_step_completed` → Updates tutorial progress bar
- `tutorial_sequence_completed` → Hides tutorial UI

**Progression Tracker → HUD**:
- `achievement_unlocked` → Shows achievement notification
- `mission_completed` → Shows mission complete notification
- `new_high_score` → Shows high score notification

### Step 5: Test the Integration

1. **Start the moon_landing scene**
2. **Verify tutorial appears** - "Welcome to Lunar Descent!" message
3. **Follow tutorial steps**:
   - Press W → Advances to altitude control
   - Press SPACE → Advances to speed control
   - Maintain speed < 5 m/s → Advances to landing
   - Land successfully → Advances to exit spacecraft
   - Press SPACE to exit → Advances to jump
   - Jump once → Tutorial completes
4. **Verify achievements unlock**:
   - "First Steps" should unlock on landing
   - "Smooth Operator" if speed < 2 m/s
   - "Perfection" if speed < 1 m/s
5. **Verify progression tracking**:
   - Score increases
   - Distance tracked when walking
   - Jump count increases
   - New missions unlock

## Configuration Options

### Tutorial Manager

```gdscript
# Skip tutorial automatically (for testing)
tutorial_manager.skip_tutorial = true

# Reset tutorial progress
tutorial_manager.reset_tutorial()

# Check if tutorial is active
if tutorial_manager.is_tutorial_active():
	print("Tutorial running")
```

### Progression Tracker

```gdscript
# Get statistics
var stats = progression_tracker.statistics
print("Total jumps: ", stats["total_jumps"])
print("Max distance: ", stats["max_distance_traveled"])

# Get unlocked achievements
var achievements = progression_tracker.get_unlocked_achievements()
for achievement in achievements:
	print(achievement["name"])

# Reset all progression
progression_tracker.reset_progression()

# Complete a specific mission
progression_tracker.complete_mission(
	progression_tracker.Mission.TUTORIAL_LANDING
)
```

### HUD Enhanced

```gdscript
# Manually show tutorial step
moon_hud_enhanced.show_tutorial_step(
	"Custom Step",
	"Custom instruction",
	"Custom hint"
)

# Hide tutorial
moon_hud_enhanced.hide_tutorial()

# Show custom achievement
moon_hud_enhanced.show_achievement({
	"name": "Custom Achievement",
	"description": "You did something cool!",
	"points": 1000
})
```

## File Locations

All new files are in the project:

```
C:/godot/
├── scripts/
│   ├── gameplay/
│   │   ├── moon_tutorial_manager.gd       (Tutorial system)
│   │   └── moon_progression_tracker.gd    (Progression/achievements)
│   └── ui/
│       ├── tutorial_prompt.gd             (Tutorial UI)
│       ├── achievement_notification.gd     (Achievement popup)
│       └── moon_hud_enhanced.gd           (Integrated HUD)
└── MOON_TUTORIAL_INTEGRATION.md          (This file)
```

## Save Data Locations

Systems save progress to user:// directory:

- `user://moon_tutorial_progress.cfg` - Tutorial completion state
- `user://moon_progression.json` - Achievements, missions, statistics

To reset all progress, delete these files.

## Extending the System

### Add New Tutorial Steps

In `moon_tutorial_manager.gd`, add to `TUTORIAL_MESSAGES`:

```gdscript
TutorialStep.NEW_STEP: {
	"title": "New Feature",
	"instruction": "Learn how to use this feature",
	"hint": "Helpful tip here",
	"completion": "feature_used"
}
```

Then add completion check in `_update_current_step()`.

### Add New Achievements

In `moon_progression_tracker.gd`, add to `Achievement` enum and `achievements` dictionary:

```gdscript
enum Achievement {
	# ... existing achievements ...
	NEW_ACHIEVEMENT,
}

var achievements: Dictionary = {
	# ... existing achievements ...
	Achievement.NEW_ACHIEVEMENT: {
		"name": "Achievement Name",
		"description": "Achievement description",
		"unlocked": false,
		"points": 500
	}
}
```

Then add check in appropriate method.

### Add New Missions

In `moon_progression_tracker.gd`, add to `Mission` enum and `missions` dictionary:

```gdscript
enum Mission {
	# ... existing missions ...
	NEW_MISSION,
}

var missions: Dictionary = {
	# ... existing missions ...
	Mission.NEW_MISSION: {
		"name": "Mission Name",
		"description": "Mission description",
		"completed": false,
		"objectives": ["Objective 1", "Objective 2"],
		"reward_points": 2000,
		"unlocked": false
	}
}
```

## Troubleshooting

### Tutorial doesn't start
- Check `tutorial_manager.tutorial_completed` - may need reset
- Verify `tutorial_manager.initialize()` was called
- Check console for "[MoonTutorialManager] Starting tutorial"

### Achievements not unlocking
- Check `progression_tracker.initialize()` was called
- Verify signals are connected (landing_detected, etc.)
- Check console for "[MoonProgressionTracker] Achievement unlocked"

### UI not showing
- Verify nodes exist in scene tree
- Check `visible` property on UI nodes
- Verify `initialize()` was called on HUD Enhanced

### Progress not saving
- Check user:// directory permissions
- Look for save errors in console
- Verify `_save_progression_data()` is being called

## Performance Notes

- Tutorial system: Minimal overhead, only processes when active
- Progression tracker: ~0.1ms per frame when tracking distance/jumps
- Achievement notifications: Queue system prevents spam
- Save operations: Occur only on state changes (not every frame)

## Future Enhancements

Potential improvements for the system:

1. **3D Tutorial Arrows**: Point to controls in 3D space
2. **Voice-over**: Audio instructions for tutorial steps
3. **Leaderboards**: Online high score tracking
4. **Replays**: Record and playback best landings
5. **Custom Challenges**: User-created landing challenges
6. **Medals**: Bronze/Silver/Gold ratings per mission
7. **Statistics Screen**: Detailed stats visualization
8. **Achievement Icons**: Custom textures per achievement
9. **Sound Effects**: Achievement unlock sounds
10. **Particle Effects**: Celebration particles on achievements

## Summary

The tutorial and progression system provides:

- **Onboarding**: Clear guidance for new players
- **Motivation**: Goals and rewards keep players engaged
- **Replayability**: Missions and achievements encourage multiple playthroughs
- **Feedback**: Visual and statistical feedback on performance
- **Progression**: Sense of advancement and mastery

All systems are modular and can be extended or modified without affecting core gameplay.
