import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[QA Audio] {msg}")

def execute(payload):
    try:
        requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=5)
    except Exception as e:
        log(f"Error: {e}")

def test_audio():
    log("Starting AudioSynthesizer Test...")

    # 1. Create Object with Synthesizer
    execute({ "action": "create", "type": "empty", "name": "SynthTester", "position": [0,0,0], "scale": [1,1,1] })
    # Add AudioSource (Required)
    execute({ "action": "add_component", "type": "UnityEngine.AudioSource", "name": "SynthTester" })
    # Add Synthesizer
    execute({ "action": "add_component", "type": "Audio.AudioSynthesizer", "name": "SynthTester" })

    # 2. Play Tone (440Hz Sine)
    log("Playing 440Hz Sine...")
    execute({ 
        "action": "set_property", 
        "name": "SynthTester", 
        "type": "Audio.AudioSynthesizer", 
        "propertyName": "frequency", 
        "value": "440" 
    })
    execute({ 
        "action": "set_property", 
        "name": "SynthTester", 
        "type": "Audio.AudioSynthesizer", 
        "propertyName": "isPlaying", 
        "value": "true" 
    })
    
    time.sleep(1.0)
    
    # 3. Frequency Sweep (880Hz)
    log("Sweeping to 880Hz...")
    execute({ 
        "action": "set_property", 
        "name": "SynthTester", 
        "type": "Audio.AudioSynthesizer", 
        "propertyName": "frequency", 
        "value": "880" 
    })
    
    time.sleep(1.0)
    
    # 4. Stop
    log("Stopping Tone...")
    execute({ 
        "action": "set_property", 
        "name": "SynthTester", 
        "type": "Audio.AudioSynthesizer", 
        "propertyName": "isPlaying", 
        "value": "false" 
    })
    
    log("Audio Test Complete. (Visual confirmation: Check Inspector 'frequency' changed).")

if __name__ == "__main__":
    test_audio()
