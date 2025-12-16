extends Node

## Debug script to print HTTP API token to file
## Run this from the Godot editor to get the current API token

func _ready():
	var SecurityConfig = load("res://scripts/http_api/security_config.gd")
	var token = SecurityConfig.get_token()

	print("============================================================")
	print("HTTP API TOKEN:")
	print(token)
	print("============================================================")
	print("Authorization: Bearer ", token)
	print("============================================================")

	# Save to file
	var file = FileAccess.open("res://jwt_token.txt", FileAccess.WRITE)
	if file:
		file.store_string(token)
		file.close()
		print("Token saved to jwt_token.txt")
	else:
		print("ERROR: Could not save token to file")

	# Quit after printing
	await get_tree().create_timer(1.0).timeout
	#get_tree().quit()
