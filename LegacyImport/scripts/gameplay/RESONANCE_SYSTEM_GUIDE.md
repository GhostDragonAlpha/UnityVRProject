# ResonanceSystem Guide

## Overview

The ResonanceSystem implements a resonance-based interaction mechanic where players can manipulate objects through harmonic frequency matching. This system is based on wave interference principles and allows for both constructive and destructive interference effects.

## Requirements Implemented

This implementation satisfies all requirements from Requirement 20:

- **20.1**: Scan objects to determine their base harmonic frequency
- **20.2**: Emit matching frequency for constructive interference (amplification)
- **20.3**: Emit inverted frequency for destructive interference (cancellation)
- **20.4**: Calculate wave amplitude changes as sum of wave amplitudes
- **20.5**: Remove cancelled objects from scene using queue_free()

## Core Concepts

### Frequency

Each object in the scene has a base harmonic frequency between 100 Hz and 1000 Hz. This frequency is deterministically calculated based on:

- Object name
- Object position
- Object type/class
- Object mass (for RigidBody3D objects)

### Amplitude

Objects start with an amplitude of 1.0. The amplitude represents the "strength" or "presence" of the object in the scene:

- **Amplitude > 1.0**: Object is amplified (constructive interference)
- **Amplitude = 1.0**: Object is at normal state
- **Amplitude < 1.0**: Object is weakened (destructive interference)
- **Amplitude ≤ 0.1**: Object is cancelled and removed from scene

### Interference

When a frequency is emitted, it interferes with tracked objects:

- **Constructive Interference**: Matching frequency increases amplitude
- **Destructive Interference**: Inverted frequency decreases amplitude

The strength of interference depends on how well the emitted frequency matches the object's frequency.

## API Reference

### Signals

```gdscript
signal object_scanned(object: Node3D, frequency: float)
```

Emitted when an object is scanned. Provides the object and its determined frequency.

```gdscript
signal interference_applied(object: Node3D, interference_type: String, amplitude_change: float)
```

Emitted when interference is applied to an object. `interference_type` is either "constructive" or "destructive".

```gdscript
signal object_cancelled(object: Node3D)
```

Emitted when an object is cancelled through destructive interference.

### Methods

#### scan_object(object: Node3D) -> float

Scans an object to determine its base harmonic frequency and begins tracking it.

**Parameters:**

- `object`: The Node3D object to scan

**Returns:** The object's frequency in Hz (100-1000)

**Example:**

```gdscript
var frequency = resonance_system.scan_object(target_object)
print("Object frequency: %.2f Hz" % frequency)
```

#### emit_matching_frequency(target_frequency: float) -> void

Emits a matching frequency for constructive interference. This will amplify objects with similar frequencies.

**Parameters:**

- `target_frequency`: The frequency to emit (100-1000 Hz)

**Example:**

```gdscript
# Amplify an object
var freq = resonance_system.get_object_frequency(target)
resonance_system.emit_matching_frequency(freq)
```

#### emit_inverted_frequency(target_frequency: float) -> void

Emits an inverted frequency for destructive interference. This will weaken and eventually cancel objects with similar frequencies.

**Parameters:**

- `target_frequency`: The frequency to invert and emit (100-1000 Hz)

**Example:**

```gdscript
# Cancel an object
var freq = resonance_system.get_object_frequency(target)
resonance_system.emit_inverted_frequency(freq)
```

#### stop_emission() -> void

Stops emitting any frequency. Objects will maintain their current amplitudes.

**Example:**

```gdscript
resonance_system.stop_emission()
```

#### get_object_amplitude(object: Node3D) -> float

Gets the current amplitude of a tracked object.

**Parameters:**

- `object`: The tracked object

**Returns:** The object's current amplitude (0.0+)

**Example:**

```gdscript
var amplitude = resonance_system.get_object_amplitude(target)
print("Amplitude: %.3f" % amplitude)
```

#### get_object_frequency(object: Node3D) -> float

Gets the frequency of a tracked object.

**Parameters:**

- `object`: The tracked object

**Returns:** The object's frequency in Hz

**Example:**

```gdscript
var freq = resonance_system.get_object_frequency(target)
```

#### untrack_object(object: Node3D) -> void

Stops tracking an object without cancelling it.

**Parameters:**

- `object`: The object to stop tracking

**Example:**

```gdscript
resonance_system.untrack_object(target)
```

#### get_tracked_objects() -> Array[Node3D]

Gets all currently tracked objects.

**Returns:** Array of tracked Node3D objects

**Example:**

```gdscript
var tracked = resonance_system.get_tracked_objects()
print("Tracking %d objects" % tracked.size())
```

#### clear_tracked_objects() -> void

Clears all tracked objects without cancelling them.

**Example:**

```gdscript
resonance_system.clear_tracked_objects()
```

## Usage Examples

### Basic Scanning and Amplification

```gdscript
extends Node3D

var resonance_system: ResonanceSystem
var target: Node3D

func _ready():
    # Create resonance system
    resonance_system = ResonanceSystem.new()
    add_child(resonance_system)

    # Scan target
    var frequency = resonance_system.scan_object(target)

    # Amplify target
    resonance_system.emit_matching_frequency(frequency)

    # Wait 2 seconds
    await get_tree().create_timer(2.0).timeout

    # Stop emission
    resonance_system.stop_emission()

    # Check new amplitude
    var amplitude = resonance_system.get_object_amplitude(target)
    print("Final amplitude: %.3f" % amplitude)
```

### Object Cancellation

```gdscript
extends Node3D

var resonance_system: ResonanceSystem
var target: Node3D

func _ready():
    # Create resonance system
    resonance_system = ResonanceSystem.new()
    add_child(resonance_system)

    # Connect to cancellation signal
    resonance_system.object_cancelled.connect(_on_object_cancelled)

    # Scan and cancel target
    var frequency = resonance_system.scan_object(target)
    resonance_system.emit_inverted_frequency(frequency)

func _on_object_cancelled(object: Node3D):
    print("Object cancelled: %s" % object.name)
```

### Monitoring Interference

```gdscript
extends Node3D

var resonance_system: ResonanceSystem

func _ready():
    resonance_system = ResonanceSystem.new()
    add_child(resonance_system)

    # Connect to interference signal
    resonance_system.interference_applied.connect(_on_interference)

func _on_interference(object: Node3D, type: String, change: float):
    print("%s interference on %s: %+.4f" % [type, object.name, change])
```

### Scanning Multiple Objects

```gdscript
extends Node3D

var resonance_system: ResonanceSystem
var objects: Array[Node3D]

func _ready():
    resonance_system = ResonanceSystem.new()
    add_child(resonance_system)

    # Scan all objects
    for obj in objects:
        var freq = resonance_system.scan_object(obj)
        print("%s: %.2f Hz" % [obj.name, freq])

    # Get all tracked objects
    var tracked = resonance_system.get_tracked_objects()
    print("Tracking %d objects" % tracked.size())
```

## Implementation Details

### Frequency Calculation

Object frequencies are calculated deterministically using a hash-based approach:

1. Hash the object's name
2. Add position components (x, y, z) scaled by 100
3. Add the object's class name hash
4. For RigidBody3D, add mass scaled by 1000
5. Normalize the hash to the frequency range (100-1000 Hz)

This ensures the same object always has the same frequency.

### Frequency Matching

The system uses an exponential falloff function to determine how well two frequencies match:

```
match_strength = exp(-diff_ratio * 5.0)
```

Where `diff_ratio` is the frequency difference as a percentage of the average frequency.

- Perfect match (0% difference) = 1.0 strength
- Large difference = ~0.0 strength

### Amplitude Changes

Amplitude changes are calculated each frame based on:

- Frequency match strength (0.0 to 1.0)
- Interference type (constructive or destructive)
- Interference strength constant (1.0)
- Delta time

The formula is:

```
amplitude_change = ±frequency_match * INTERFERENCE_STRENGTH * delta
```

Where the sign is positive for constructive and negative for destructive interference.

### Object Cancellation

Objects are cancelled when their amplitude drops to or below the cancellation threshold (0.1). When cancelled:

1. The `object_cancelled` signal is emitted
2. The object is removed from tracking
3. `queue_free()` is called on the object

## Performance Considerations

- The system processes all tracked objects every frame when emitting
- Frequency calculations are only done once per object during scanning
- Invalid objects are automatically removed from tracking
- Consider limiting the number of simultaneously tracked objects for performance

## Integration with Other Systems

The ResonanceSystem can be integrated with:

- **Player Controller**: Allow player to scan and emit frequencies via VR controls
- **UI System**: Display object frequencies and amplitudes in HUD
- **Audio System**: Play audio feedback based on frequency and interference
- **Visual Effects**: Show visual effects when objects are amplified or cancelled
- **Mission System**: Create objectives around resonance mechanics

## Testing

See `tests/unit/test_resonance_system.gd` for unit tests covering:

- Object scanning
- Constructive interference
- Destructive interference
- Object cancellation
- Frequency matching

Run the example at `examples/resonance_example.gd` to see the system in action.

## Future Enhancements

Potential improvements:

- Multiple simultaneous frequency emissions
- Frequency harmonics (octaves, fifths, etc.)
- Resonance chains (objects affecting other objects)
- Frequency modulation effects
- Visual feedback for frequency matching
- Audio synthesis based on object frequencies
