import unity_bridge
import time
import os
import shutil

# Local temp path (safe)
TEMP_IMG = r"C:\Users\allen\.gemini\antigravity\scratch\UnityVRProject\visual_proof.png"
# Artifact path (final destination)
ARTIFACT_IMG = r"C:\Users\allen\.gemini\antigravity\brain\ae14f8ab-d1f7-4221-8ea4-4362ce1a5809\visual_proof.png"

def capture_proof():
    unity_bridge.log("Capturing Visual Proof...")
    unity_bridge.ensure_initialized()
    
    # Send Screenshot Command
    # unity_bridge sends focus automatically now.
    unity_bridge.execute({"action": "screenshot", "filename": TEMP_IMG})
    
    # Wait for IO
    time.sleep(3)
    
    if os.path.exists(TEMP_IMG):
        unity_bridge.log(f"Screenshot captured at: {TEMP_IMG}")
        # Move to Artifacts
        shutil.copy(TEMP_IMG, ARTIFACT_IMG)
        unity_bridge.log(f"Proof moved to Artifacts: {ARTIFACT_IMG}")
    else:
        unity_bridge.log("CRITICAL: Screenshot failed to write to disk.")

if __name__ == "__main__":
    capture_proof()
