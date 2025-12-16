# get_node_or_null() Error Fix Summary

## Problem
RefCounted classes (HTTP API routers) were calling `get_node_or_null()` directly, which is a method only available on Node instances. This caused the error:
```
Function 'get_node_or_null()' not found in base self
```

## Root Cause
The router classes extend `RefCounted` via godottpd's `http_router.gd` base class. Since they are not part of the scene tree, they cannot call node methods directly. Additionally, they were using relative node paths (e.g., `"WebhookManager"`) instead of absolute autoload paths (e.g., `"/root/WebhookManager"`).

## Solution
Replaced all incorrect `get_node_or_null()` calls with the proper pattern:

### Before (Incorrect):
```gdscript
var webhook_manager = get_node_or_null("WebhookManager")
```

### After (Correct):
```gdscript
var tree = Engine.get_main_loop() as SceneTree
if not tree:
    response.send(500, JSON.stringify({
        "error": "Internal Server Error",
        "message": "Scene tree not available"
    }))
    return true
var webhook_manager = tree.root.get_node_or_null("/root/WebhookManager")
```

## Files Fixed
Total: 7 files, 13 occurrences

1. **C:/godot/scripts/http_api/batch_operations_router.gd**
   - Line 341: WebhookManager (in `_trigger_scene_webhook`)
   - Line 355: WebhookManager (in `_trigger_rate_limit_webhook`)

2. **C:/godot/scripts/http_api/job_detail_router.gd**
   - Line 34: JobQueue (in GET handler)
   - Line 76: JobQueue (in DELETE handler)

3. **C:/godot/scripts/http_api/job_router.gd**
   - Line 54: JobQueue (in POST handler)
   - Line 94: JobQueue (in GET handler)

4. **C:/godot/scripts/http_api/scene_router_with_audit.gd**
   - Line 39: AuditHelper (in `_get_audit_helper`)

5. **C:/godot/scripts/http_api/webhook_deliveries_router.gd**
   - Line 40: WebhookManager (in GET handler)

6. **C:/godot/scripts/http_api/webhook_detail_router.gd**
   - Line 38: WebhookManager (in GET handler)
   - Line 94: WebhookManager (in PUT handler)
   - Line 139: WebhookManager (in DELETE handler)

7. **C:/godot/scripts/http_api/webhook_router.gd**
   - Line 54: WebhookManager (in POST handler)
   - Line 91: WebhookManager (in GET handler)

## Key Changes
All relative node names were changed to absolute autoload paths:
- `"WebhookManager"` → `"/root/WebhookManager"`
- `"JobQueue"` → `"/root/JobQueue"`
- `"AuditHelper"` → `"/root/AuditHelper"`

## Verification
All fixes confirmed via:
```bash
grep -n 'get_node_or_null("/root/' scripts/http_api/*.gd
```

Result: 13 matches across 7 files, all correct.

## Next Steps
1. Restart Godot to reload the fixed files
2. Check for any compilation errors in the Godot editor
3. Test the affected routers:
   - POST /batch (batch operations)
   - GET/POST /jobs, GET/DELETE /jobs/:id (job queue)
   - POST /scene (with audit logging)
   - GET/POST /webhooks, GET/PUT/DELETE /webhooks/:id
   - GET /webhooks/:id/deliveries

## Prevention
When creating new RefCounted-based classes that need to access autoloads:
1. Always get the SceneTree first: `Engine.get_main_loop() as SceneTree`
2. Check if tree is valid before accessing nodes
3. Use absolute paths for autoloads: `/root/AutoloadName`
4. Handle the case where the autoload might not exist

## Related Files
- Fix script: `C:/godot/fix_get_node_errors.py`
- This summary: `C:/godot/GET_NODE_FIX_SUMMARY.md`
