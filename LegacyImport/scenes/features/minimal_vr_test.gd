extends Node3D
## Minimal VR Test Scene
## Simple scene to verify VR is working with visible geometry

func _ready() -> void:
	print("[MinimalVRTest] Scene ready")

	# Initialize OpenXR
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		print("[MinimalVRTest] Found OpenXR interface")

		if xr_interface.initialize():
			print("[MinimalVRTest] OpenXR initialized successfully")

			# CRITICAL: Mark viewport for XR rendering
			get_viewport().use_xr = true
			print("[MinimalVRTest] Viewport marked for XR rendering")

			# Activate XR camera
			$XROrigin3D/XRCamera3D.current = true
			print("[MinimalVRTest] XR Camera activated")

			print("[MinimalVRTest] VR READY - You should see a red cube 2 meters in front of you")
		else:
			print("[MinimalVRTest] ERROR: OpenXR initialization failed")
	else:
		print("[MinimalVRTest] ERROR: OpenXR interface not found")
