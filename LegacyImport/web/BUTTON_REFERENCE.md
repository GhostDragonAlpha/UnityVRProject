# Quick Button Reference Card

## New Features Added to Scene Manager

### 1. Reload Scene Button (♻️ Orange)
**Location:** Header, next to Refresh button  
**API Call:** `POST /scene/reload`  
**When clicked:**
1. Disables button (prevents double-click)
2. Shows loading spinner overlay
3. Displays "Reloading current scene..." toast
4. Sends POST request to reload current scene
5. On success: Shows "Scene reloaded successfully" toast
6. Automatically refreshes scene info after 500ms
7. Re-enables button

**Error handling:** Displays error toast if reload fails

---

### 2. Validate Button (🔍 Purple)
**Location:** Each scene row in Actions column  
**API Call:** `PUT /scene` with `{scene_path: "..."}`  
**When clicked:**
1. Shows loading spinner
2. Displays "Validating {scene_name}..." toast
3. Sends PUT request to validate scene
4. Opens modal dialog with results

**Modal displays:**
- Validation status (green=valid, yellow=warnings, red=invalid)
- Scene name and path
- Node count
- List of warnings (if any)
- List of errors (if any)
- Additional info message

**Modal controls:**
- Click X button to close
- Click backdrop to close
- Press ESC key to close

---

### 3. Info Button (ℹ️ Blue)
**Location:** Each scene row in Actions column  
**API Call:** Same as Validate (`PUT /scene`)  
**When clicked:**
- Identical behavior to Validate button
- Provides quick access to validation info
- Useful for checking scene details without loading

---

## Button Behavior

### All buttons:
- Hover: Lift up slightly with enhanced shadow
- Active: Press down animation
- Disabled: Gray background, no hover effect, 50% opacity
- Loading: Cannot be clicked while operation in progress

### Current scene indicators:
- Load button shows "✓ Loaded" and is disabled for current scene
- Scene row highlighted with green background
- "Current" badge displayed next to scene name

---

## Testing Checklist

- [ ] Reload button appears in header
- [ ] Reload button is orange with ♻️ icon
- [ ] Reload calls POST /scene/reload
- [ ] Validate button appears on each row
- [ ] Validate button is purple with 🔍 icon
- [ ] Validate calls PUT /scene
- [ ] Info button appears on each row
- [ ] Info button is blue with ℹ️ icon
- [ ] Modal opens with validation results
- [ ] Modal shows colored status badge
- [ ] Modal displays node count
- [ ] Modal X button closes it
- [ ] Clicking backdrop closes modal
- [ ] ESC key closes modal
- [ ] Toast notifications appear for all actions
- [ ] Buttons disable during operations
- [ ] Loading spinner shows during async operations

---

## API Endpoints Used

| Button | Method | Endpoint | Body | Response |
|--------|--------|----------|------|----------|
| Reload | POST | `/scene/reload` | `{}` | `{success, message}` |
| Validate | PUT | `/scene` | `{scene_path}` | `{valid, node_count, warnings[], errors[], message}` |
| Info | PUT | `/scene` | `{scene_path}` | Same as Validate |

---

## File Locations

- Main dashboard: `C:/godot/web/scene_manager.html`
- Test page: `C:/godot/web/test_features.html`
- Implementation guide: `C:/godot/web/UPDATED_CODE.md`
- Change summary: `C:/godot/web/APPLIED_CHANGES.md`
- This reference: `C:/godot/web/BUTTON_REFERENCE.md`
