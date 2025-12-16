# Godot Debug Connection - Usage Examples

This directory contains example scripts demonstrating how to use the Godot Debug Connection system from an AI assistant or external tool.

## Prerequisites

1. **Python 3.8+** installed
2. **Godot 4.x** with the Debug Connection addon enabled
3. **GDA services** running (see [DEPLOYMENT_GUIDE.md](../addons/godot_debug_connection/DEPLOYMENT_GUIDE.md))

## Installation

Install required Python packages:

```bash
pip install requests
```

## Examples

### 1. Python AI Client (`python_ai_client.py`)

A complete client library for AI assistants to interact with Godot.

**Features:**

- Connection management
- Debug commands (breakpoints, stepping, evaluation)
- LSP requests (completion, definition, references)
- Code editing and hot-reload

**Usage:**

```bash
python python_ai_client.py
```

**Example Code:**

```python
from python_ai_client import GodotAIClient

client = GodotAIClient()
client.connect()

# Set a breakpoint
client.set_breakpoint("res://player.gd", 10)

# Get code completions
client.get_completion("file:///path/to/file.gd", 5, 10)

# Apply an edit
client.apply_edit("file:///path/to/file.gd", 5, 0, 10, "new_code")

client.disconnect()
```

### 2. Debug Session Example (`debug_session_example.py`)

Demonstrates a complete debugging workflow.

**Features:**

- Setting multiple breakpoints
- Launching debug session
- Inspecting stack trace and variables
- Evaluating expressions
- Stepping through code
- Continuing execution

**Usage:**

```bash
python debug_session_example.py
```

**Workflow:**

1. Connect to Godot services
2. Set breakpoints in multiple files
3. Launch debug session
4. Wait for breakpoint hit
5. Inspect execution state
6. Evaluate expressions
7. Step through code
8. Continue execution
9. Disconnect

### 3. Code Editing Example (`code_editing_example.py`)

Demonstrates programmatic code editing through LSP.

**Features:**

- Opening documents in language server
- Getting code intelligence (completions, definitions, references, hover)
- Applying text edits
- Inserting and deleting text
- Hot-reloading changes

**Usage:**

```bash
python code_editing_example.py
```

**Workflow:**

1. Connect to Godot services
2. Open a document
3. Get code intelligence
4. Apply various edits
5. Save and hot-reload
6. Disconnect

## Quick Start

### Step 1: Start Godot with GDA Services

```bash
# Windows
godot.exe --path "C:\path\to\project" --debug-server tcp://127.0.0.1:6006 --lsp-server tcp://127.0.0.1:6005

# macOS/Linux
godot --path "/path/to/project" --debug-server tcp://127.0.0.1:6006 --lsp-server tcp://127.0.0.1:6005
```

### Step 2: Verify Services are Running

```bash
curl http://127.0.0.1:8080/status
```

Expected response should show `overall_ready: false` initially.

### Step 3: Run an Example

```bash
python python_ai_client.py
```

## Common Use Cases

### Setting Breakpoints

```python
import requests

response = requests.post("http://127.0.0.1:8080/debug/setBreakpoints", json={
    "source": {"path": "res://player.gd"},
    "breakpoints": [{"line": 10}, {"line": 25}]
})
print(response.json())
```

### Getting Code Completions

```python
import requests

response = requests.post("http://127.0.0.1:8080/lsp/completion", json={
    "textDocument": {"uri": "file:///path/to/file.gd"},
    "position": {"line": 10, "character": 5}
})
completions = response.json()
for item in completions.get("response", {}).get("items", []):
    print(item["label"])
```

### Applying Code Edits

```python
import requests

response = requests.post("http://127.0.0.1:8080/edit/applyChanges", json={
    "edit": {
        "changes": {
            "file:///path/to/file.gd": [
                {
                    "range": {
                        "start": {"line": 5, "character": 0},
                        "end": {"line": 5, "character": 10}
                    },
                    "newText": "new_code"
                }
            ]
        }
    },
    "label": "AI-assisted edit"
})
print(response.json())
```

### Evaluating Expressions

```python
import requests

response = requests.post("http://127.0.0.1:8080/debug/evaluate", json={
    "expression": "player.health",
    "frameId": 0,
    "context": "watch"
})
result = response.json()
print(f"Value: {result['response']['result']}")
```

## Customization

### Changing Server URL

All examples use `http://127.0.0.1:8080` by default. To use a different URL:

```python
client = GodotAIClient(base_url="http://localhost:8081")
```

### Adjusting Timeouts

Modify the connection timeout in examples:

```python
# In connect_and_wait()
for i in range(30):  # Increase from 15 to 30
    time.sleep(1)
    # ...
```

### Adding Error Handling

Wrap API calls in try-except blocks:

```python
try:
    response = requests.post(url, json=data, timeout=10)
    response.raise_for_status()
    return response.json()
except requests.Timeout:
    print("Request timed out")
except requests.RequestException as e:
    print(f"Request failed: {e}")
```

## Troubleshooting

### Connection Fails

**Problem:** Cannot connect to services

**Solutions:**

1. Verify Godot is running with GDA services
2. Check port 8080 is not blocked by firewall
3. Ensure HttpApiServer is running
4. Check Godot console for errors

### Breakpoints Not Hit

**Problem:** Breakpoints set but execution doesn't pause

**Solutions:**

1. Ensure debug session is launched first
2. Verify file paths are correct (use `res://` prefix)
3. Check line numbers are valid (1-based)
4. Run the game in Godot to trigger breakpoints

### LSP Requests Fail

**Problem:** Code intelligence requests return empty results

**Solutions:**

1. Open the document first with `didOpen`
2. Use correct file URI format (`file:///absolute/path`)
3. Wait for LSP initialization to complete
4. Check language server is connected

### Edits Not Applied

**Problem:** Text edits fail or don't take effect

**Solutions:**

1. Verify file URI is correct
2. Check range coordinates are valid (0-based)
3. Ensure language server is connected
4. Call hot-reload after edits

## Advanced Usage

### Batch Operations

Apply multiple edits efficiently:

```python
# Multiple edits in one request
edits = [
    {
        "range": {"start": {"line": 5, "character": 0}, "end": {"line": 5, "character": 10}},
        "newText": "new_code_1"
    },
    {
        "range": {"start": {"line": 10, "character": 0}, "end": {"line": 10, "character": 15}},
        "newText": "new_code_2"
    }
]
client.apply_edit(file_path, edits, "Batch refactor")
```

### Async Operations

Use async/await for concurrent requests:

```python
import asyncio
import aiohttp

async def get_completions_async(session, uri, line, char):
    async with session.post(
        "http://127.0.0.1:8080/lsp/completion",
        json={"textDocument": {"uri": uri}, "position": {"line": line, "character": char}}
    ) as response:
        return await response.json()

async def main():
    async with aiohttp.ClientSession() as session:
        tasks = [
            get_completions_async(session, "file:///file1.gd", 5, 10),
            get_completions_async(session, "file:///file2.gd", 10, 5)
        ]
        results = await asyncio.gather(*tasks)
        print(results)

asyncio.run(main())
```

### Event Listening

Monitor for DAP events (requires WebSocket support - future enhancement):

```python
# Future: WebSocket connection for real-time events
import websocket

def on_message(ws, message):
    event = json.loads(message)
    if event.get("type") == "event":
        print(f"Event: {event.get('event')}")

ws = websocket.WebSocketApp(
    "ws://127.0.0.1:8081/events",
    on_message=on_message
)
ws.run_forever()
```

## Integration with AI Assistants

### OpenAI Function Calling

Define functions for AI to call:

```python
functions = [
    {
        "name": "set_breakpoint",
        "description": "Set a breakpoint in a GDScript file",
        "parameters": {
            "type": "object",
            "properties": {
                "file_path": {"type": "string", "description": "Path to file (e.g., res://player.gd)"},
                "line": {"type": "integer", "description": "Line number (1-based)"}
            },
            "required": ["file_path", "line"]
        }
    },
    # ... more functions
]

# Use with OpenAI API
response = openai.ChatCompletion.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Set a breakpoint at line 10 in player.gd"}],
    functions=functions,
    function_call="auto"
)
```

### LangChain Tools

Create LangChain tools:

```python
from langchain.tools import Tool

def set_breakpoint_tool(input_str):
    # Parse input
    file_path, line = input_str.split(",")
    client = GodotAIClient()
    client.connect()
    result = client.set_breakpoint(file_path.strip(), int(line.strip()))
    client.disconnect()
    return str(result)

tools = [
    Tool(
        name="SetBreakpoint",
        func=set_breakpoint_tool,
        description="Set a breakpoint in a GDScript file. Input: 'file_path, line_number'"
    )
]
```

## Best Practices

1. **Always connect before operations**: Check `client.connected` before sending commands
2. **Handle errors gracefully**: Wrap API calls in try-except blocks
3. **Use proper file URIs**: Convert paths to `file:///` URIs for LSP
4. **Wait for initialization**: Allow time for services to connect
5. **Clean up resources**: Always call `disconnect()` when done
6. **Batch operations**: Combine multiple edits into single requests
7. **Monitor status**: Check connection status regularly
8. **Log operations**: Keep logs for debugging

## See Also

- [API Reference](../addons/godot_debug_connection/API_REFERENCE.md) - Complete API documentation
- [HTTP API](../addons/godot_debug_connection/HTTP_API.md) - HTTP endpoint reference
- [Deployment Guide](../addons/godot_debug_connection/DEPLOYMENT_GUIDE.md) - Setup instructions
- [DAP Commands](../addons/godot_debug_connection/DAP_COMMANDS.md) - Debug adapter commands
- [LSP Methods](../addons/godot_debug_connection/LSP_METHODS.md) - Language server methods

## Contributing

To add new examples:

1. Create a new Python file in this directory
2. Follow the existing example structure
3. Include comprehensive comments
4. Add error handling
5. Update this README with the new example

## License

[Add your license here]
