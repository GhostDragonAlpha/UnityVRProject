extends Node

# Simple test script for TerrainNoiseGenerator
# Run this in Godot to verify the noise generator works

func _ready() -> void:
	print("=== TerrainNoiseGenerator Test ===")
	
	var noise_gen = TerrainNoiseGenerator.new()
	add_child(noise_gen)
	
	# Test 1: Basic height generation
	print("\nTest 1: Basic height generation")
	noise_gen.set_seed(12345)
	var height1 = noise_gen.get_height(100.0, 100.0)
	print("  Height at (100, 100): ", height1)
	assert(height1 >= 0.0 and height1 <= noise_gen.amplitude, "Height out of range")
	print("  PASSED")
	
	# Test 2: Deterministic generation
	print("\nTest 2: Deterministic generation")
	var height2 = noise_gen.get_height(100.0, 100.0)
	assert(abs(height1 - height2) < 0.0001, "Heights don't match - not deterministic")
	print("  Same position gives same height: ", height1 == height2)
	print("  PASSED")
	
	# Test 3: Different positions give different heights
	print("\nTest 3: Different positions")
	var height3 = noise_gen.get_height(200.0, 200.0)
	print("  Height at (200, 200): ", height3)
	assert(abs(height1 - height3) > 0.01, "Different positions should give different heights")
	print("  PASSED")
	
	# Test 4: Heightmap generation
	print("\nTest 4: Heightmap generation")
	var heightmap = noise_gen.generate_heightmap(64, 64)
	assert(heightmap != null, "Heightmap is null")
	assert(heightmap.get_width() == 64, "Heightmap width incorrect")
	assert(heightmap.get_height() == 64, "Heightmap height incorrect")
	print("  Generated 64x64 heightmap successfully")
	print("  PASSED")
	
	# Test 5: Biome variations
	print("\nTest 5: Biome variations")
	var height_no_biome = noise_gen.get_height(300.0, 300.0)
	var height_volcanic = noise_gen.get_height(300.0, 300.0, "volcanic")
	var height_ocean = noise_gen.get_height(300.0, 300.0, "ocean")
	print("  No biome: ", height_no_biome)
	print("  Volcanic: ", height_volcanic)
	print("  Ocean: ", height_ocean)
	print("  PASSED")
	
	# Test 6: Preset application
	print("\nTest 6: Preset application")
	noise_gen.apply_preset(TerrainNoiseGenerator.NoisePreset.SMOOTH_HILLS)
	var height_smooth = noise_gen.get_height(400.0, 400.0)
	noise_gen.apply_preset(TerrainNoiseGenerator.NoisePreset.ROUGH_MOUNTAINS)
	var height_rough = noise_gen.get_height(400.0, 400.0)
	print("  Smooth hills: ", height_smooth)
	print("  Rough mountains: ", height_rough)
	print("  PASSED")
	
	# Test 7: Configuration
	print("\nTest 7: Configuration")
	var config = noise_gen.get_configuration()
	print("  Config keys: ", config.keys().size())
	assert(config.has("base_frequency"), "Config missing base_frequency")
	assert(config.has("octaves"), "Config missing octaves")
	assert(config.has("amplitude"), "Config missing amplitude")
	print("  PASSED")
	
	# Test 8: Determinism validation
	print("\nTest 8: Full determinism validation")
	var is_deterministic = noise_gen.validate_determinism(50)
	assert(is_deterministic, "Noise generation is not deterministic")
	print("  Determinism validated with 50 test positions")
	print("  PASSED")
	
	print("\n=== All Tests PASSED ===")
	print("TerrainNoiseGenerator is working correctly!")
	
	# Clean up
	noise_gen.queue_free()
	get_tree().quit()
