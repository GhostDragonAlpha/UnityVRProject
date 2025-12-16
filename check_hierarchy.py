import unity_bridge
import json

def check_hierarchy():
    unity_bridge.log("Querying Scene Hierarchy...")
    # Using execute_batch logic or raw requests? execute() helper is POST.
    # Hierarchy is GET.
    # Need to add GET support to unity_bridge or just use requests here.
    
    import requests
    try:
        url = f"http://localhost:{unity_bridge.PORT}/hierarchy"
        # We need to trigger the loop in unity_bridge to make sure Unity is awake?
        # execute_batch with empty list just to focus?
        unity_bridge.execute_batch([]) 
        
        # Now GET
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            print("\n=== SCENE HIERARCHY ===")
            print(f"Total Objects: {data.get('object_count', 'N/A')}")
            print(f"Root Objects: {data.get('roots_count', 'N/A')}")
            print("--- Tree ---")
            print_tree(data.get("objects", []), 0)
            print("=======================\n")
        else:
            print(f"Error: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"Failed to query hierarchy: {e}")

def print_tree(nodes, depth):
    indent = "  " * depth
    for node in nodes:
        comps = ", ".join(node.get("components", []))
        pos = node.get("position", "unknown")
        print(f"{indent}- {node['name']} [{comps}] @ {pos}")
        if "children" in node:
            print_tree(node["children"], depth + 1)

if __name__ == "__main__":
    check_hierarchy()
