import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[QA Terrain] {msg}")

def execute(payload):
    try:
        requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=1)
    except:
        pass

def test_terrain():
    log("Starting Terrain Test...")
    
    # 1. Create Terrain Object
    execute({ "action": "create", "type": "empty", "name": "TerrainChunk_01", "position": [0,0,0], "scale": [1,1,1] })
    # 2. Add Component (starts generation)
    execute({ "action": "add_component", "type": "Procedural.ProceduralTerrain", "name": "TerrainChunk_01" })

    # Wait for Initialize
    time.sleep(1.0)
    
    log("Test Complete. Check logs for '[Procedural] Terrain Generated'.")

if __name__ == "__main__":
    test_terrain()
