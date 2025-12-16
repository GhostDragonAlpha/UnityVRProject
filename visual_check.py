import unity_bridge
import time
import os

ARTIFACTS_DIR = r"C:\Users\allen\.gemini\antigravity\brain\ae14f8ab-d1f7-4221-8ea4-4362ce1a5809"

def verify_visuals():
    unity_bridge.log("Starting Visual Verification...")
    unity_bridge.ensure_initialized()
    
    # 1. Position Camera to see the Roots
    # Sun is at 0,0,0 (Scale 50).
    # Move Main Camera to 0, 50, -300 and look at 0,0,0.
    
    # Find Main Camera (Tag or Name)
    cam_name = "Main Camera"
    
    # Reset Position
    unity_bridge.execute({"action": "set_property", "name": cam_name, "type": "UnityEngine.Transform", "propertyName": "position", "value": "0,50,-300"})
    
    # Rotation (Look at 0,0,0) -> Approx needs Quaternion or just set Euler.
    # Looking forward (Z+) from -300Z is 0,0,0 rotation. Slight tilt down.
    # We must set rotation via Transform.
    # Euler (10, 0, 0) -> Pitch down 10 deg.
    unity_bridge.execute({"action": "set_property", "name": cam_name, "type": "UnityEngine.Transform", "propertyName": "eulerAngles", "value": "10,0,0"})
    
    unity_bridge.log("Camera Positioned at (0, 50, -300) looking at Sol.")
    
    # 2. Capture Screenshot
    # We save directly to the Artifacts directory so the Agent can see it via 'view_file'.
    filename = "visual_verification_01.png"
    filepath = os.path.join(ARTIFACTS_DIR, filename)
    
    unity_bridge.log(f"Requesting Screenshot: {filepath}")
    
    # Unity writes specific paths relative to Project if just filename, 
    # but we passed absolute path. ScreenCapture.CaptureScreenshot supports absolute paths.
    unity_bridge.execute({"action": "screenshot", "filename": filepath})
    
    # Wait for write (Unity Capture is frame-end, slight delay)
    time.sleep(2)
    
    if os.path.exists(filepath):
        unity_bridge.log(f"Screenshot verified on disk: {filepath}")
    else:
        unity_bridge.log("WARNING: Screenshot file not found. Check Unity errors.")

if __name__ == "__main__":
    verify_visuals()
