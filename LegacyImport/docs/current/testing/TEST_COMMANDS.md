# Scene Validation - Test Commands

## Prerequisites
Ensure Godot is running with HTTP API on port 8080.

## Quick Test Commands

### Test 1: Validate Existing Scene (Should Pass)
```bash
curl -X PUT http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

Expected Output:
```json
{
  "valid": true,
  "errors": [],
  "warnings": [],
  "scene_info": {
    "node_count": <number>,
    "root_type": "<type>",
    "root_name": "<name>"
  }
}
```

---

### Test 2: Validate Non-Existent Scene (Should Fail)
```bash
curl -X PUT http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://does_not_exist.tscn"}'
```

Expected Output:
```json
{
  "valid": false,
  "errors": ["Scene file not found: res://does_not_exist.tscn"],
  "warnings": [],
  "scene_info": {}
}
```

---

### Test 3: Invalid Path Format (Should Fail)
```bash
curl -X PUT http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "invalid_path.tscn"}'
```

Expected Output:
```json
{
  "valid": false,
  "errors": ["Scene path must start with 'res://'"],
  "warnings": [],
  "scene_info": {}
}
```

---

### Test 4: Run Automated Test Suite
```bash
# Python (recommended)
python test_scene_validation.py

# Bash
./test_scene_validation.sh
```

---

### Test 5: Use Example Client
```bash
# Validate single scene
python examples/scene_validation_client.py res://vr_main.tscn

# Batch validation
python examples/scene_validation_client.py --batch
```

---

## One-Line Test
Copy and paste this to test immediately:
```bash
curl -X PUT http://127.0.0.1:8080/scene -H "Content-Type: application/json" -d '{"scene_path": "res://vr_main.tscn"}' | python -m json.tool
```

## PowerShell (Windows)
```powershell
Invoke-RestMethod -Method Put -Uri "http://127.0.0.1:8080/scene" -ContentType "application/json" -Body '{"scene_path": "res://vr_main.tscn"}' | ConvertTo-Json
```

## Python One-Liner
```python
python -c "import requests; print(requests.put('http://127.0.0.1:8080/scene', json={'scene_path': 'res://vr_main.tscn'}).json())"
```
