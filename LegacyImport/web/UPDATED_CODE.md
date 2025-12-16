# Complete Updated scene_manager.html Code

## Instructions
Replace the contents of `C:/godot/web/scene_manager.html` with the code below.

---

## Changes Summary

### HTML Changes:
1. Added "Reload Scene" button in header next to Refresh button
2. Added modal overlay HTML at bottom of body
3. Updated action buttons column to include Validate and Info buttons
4. Added button group div wrapper for better flex layout

### CSS Changes:
1. Added `.reload-btn` styles (orange gradient)
2. Added `.validate-btn` styles (purple gradient)
3. Added `.info-btn` styles (blue gradient)
4. Added `.header-actions` flex container
5. Added `.action-buttons` flex container
6. Added modal styles (`.modal-overlay`, `.modal`, `.modal-header`, `.modal-close`, etc.)
7. Added validation status styles (`.validation-status`, `.validation-details`, etc.)
8. Added `.toast.warning` style
9. Updated responsive breakpoints for new buttons

### JavaScript Changes:
1. Added `showModal()`, `closeModal()`, `closeModalOnBackdrop()` functions
2. Added `reloadCurrentScene()` function
3. Added `validateScene()` function
4. Added `displayValidationResults()` function
5. Added `showSceneInfo()` function
6. Added `escapeHtml()` utility function
7. Updated `refreshCurrentScene()` to disable button during load
8. Updated `renderSceneList()` to include Validate and Info buttons
9. Added ESC key event listener for modal closing

---

## Key Code Sections to Add/Modify

### 1. Add to CSS (after `.refresh-btn:active`)

```css
.refresh-btn:disabled {
    background: #555;
    cursor: not-allowed;
    transform: none;
    box-shadow: none;
    opacity: 0.5;
}

.header-actions {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
}

.reload-btn {
    background: linear-gradient(135deg, #ff8800 0%, #ffaa00 100%);
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 1em;
    font-weight: 600;
    transition: all 0.3s ease;
    box-shadow: 0 4px 12px rgba(255, 136, 0, 0.3);
}

.reload-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(255, 136, 0, 0.4);
}

.reload-btn:active {
    transform: translateY(0);
}

.reload-btn:disabled {
    background: #555;
    cursor: not-allowed;
    transform: none;
    box-shadow: none;
    opacity: 0.5;
}
```

### 2. Add to CSS (after `.load-btn:disabled`)

```css
.action-buttons {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
}

.validate-btn {
    background: linear-gradient(135deg, #6600cc 0%, #8800ff 100%);
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.9em;
    font-weight: 600;
    transition: all 0.3s ease;
    box-shadow: 0 2px 8px rgba(136, 0, 255, 0.3);
}

.validate-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(136, 0, 255, 0.4);
}

.validate-btn:active {
    transform: translateY(0);
}

.validate-btn:disabled {
    background: #555;
    cursor: not-allowed;
    transform: none;
    box-shadow: none;
}

.info-btn {
    background: linear-gradient(135deg, #0088cc 0%, #00aaff 100%);
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.9em;
    font-weight: 600;
    transition: all 0.3s ease;
    box-shadow: 0 2px 8px rgba(0, 136, 204, 0.3);
}

.info-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 136, 204, 0.4);
}

.info-btn:active {
    transform: translateY(0);
}

.info-btn:disabled {
    background: #555;
    cursor: not-allowed;
    transform: none;
    box-shadow: none;
}
```

### 3. Add to CSS (after `.toast.info`)

```css
.toast.warning {
    background: linear-gradient(135deg, #ff8800 0%, #ffaa00 100%);
}
```

### 4. Add to CSS (before `@media` section)

```css
/* Modal Styles */
.modal-overlay {
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.7);
    z-index: 2000;
    align-items: center;
    justify-content: center;
}

.modal-overlay.active {
    display: flex;
}

.modal {
    background: #2a2a3e;
    padding: 30px;
    border-radius: 12px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
    max-width: 600px;
    width: 90%;
    max-height: 80vh;
    overflow-y: auto;
    border: 2px solid #3a3a5a;
}

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}

.modal-header h3 {
    color: #00d4ff;
    font-size: 1.5em;
}

.modal-close {
    background: none;
    border: none;
    color: #a0a0b0;
    font-size: 1.5em;
    cursor: pointer;
    padding: 0;
    width: 30px;
    height: 30px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 4px;
    transition: all 0.3s ease;
}

.modal-close:hover {
    background: #3a3a5a;
    color: #ffffff;
}

.modal-content {
    color: #e0e0e0;
}

.validation-status {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 15px;
    border-radius: 8px;
    margin-bottom: 20px;
    font-weight: 600;
}

.validation-status.valid {
    background: rgba(0, 255, 136, 0.1);
    border: 2px solid #00ff88;
    color: #00ff88;
}

.validation-status.invalid {
    background: rgba(255, 68, 68, 0.1);
    border: 2px solid #ff4444;
    color: #ff4444;
}

.validation-status.warning {
    background: rgba(255, 170, 0, 0.1);
    border: 2px solid #ffaa00;
    color: #ffaa00;
}

.validation-details {
    display: grid;
    gap: 15px;
}

.validation-item {
    background: #1e1e2e;
    padding: 15px;
    border-radius: 8px;
    border-left: 4px solid #3a3a5a;
}

.validation-item-header {
    font-weight: 600;
    margin-bottom: 8px;
    color: #00d4ff;
}

.validation-item-content {
    color: #a0a0b0;
    font-size: 0.95em;
    line-height: 1.5;
}

.validation-list {
    list-style: none;
    padding-left: 0;
}

.validation-list li {
    padding: 5px 0;
    border-bottom: 1px solid #3a3a5a;
}

.validation-list li:last-child {
    border-bottom: none;
}
```

### 5. Update HTML header section

Replace:
```html
<div class="current-scene-header">
    <h2>Current Scene</h2>
    <button class="refresh-btn" onclick="refreshCurrentScene()">Refresh</button>
</div>
```

With:
```html
<div class="current-scene-header">
    <h2>Current Scene</h2>
    <div class="header-actions">
        <button class="refresh-btn" onclick="refreshCurrentScene()" id="refresh-btn">🔄 Refresh</button>
        <button class="reload-btn" onclick="reloadCurrentScene()" id="reload-btn">♻️ Reload Scene</button>
    </div>
</div>
```

### 6. Add modal HTML before closing `</body>` tag

```html
<!-- Validation Modal -->
<div class="modal-overlay" id="modal-overlay" onclick="closeModalOnBackdrop(event)">
    <div class="modal" onclick="event.stopPropagation()">
        <div class="modal-header">
            <h3>Scene Validation</h3>
            <button class="modal-close" onclick="closeModal()">×</button>
        </div>
        <div class="modal-content" id="modal-content">
            <!-- Populated by JavaScript -->
        </div>
    </div>
</div>
```

### 7. Add JavaScript functions (after `showLoading()`)

```javascript
// Modal functions
function showModal(content) {
    document.getElementById('modal-content').innerHTML = content;
    document.getElementById('modal-overlay').classList.add('active');
}

function closeModal() {
    document.getElementById('modal-overlay').classList.remove('active');
}

function closeModalOnBackdrop(event) {
    if (event.target.id === 'modal-overlay') {
        closeModal();
    }
}
```

### 8. Add JavaScript functions (after `updateLastUpdateTime()`)

```javascript
// Reload current scene
async function reloadCurrentScene() {
    if (!currentScenePath) {
        showToast('No scene currently loaded', 'warning');
        return;
    }

    const btn = document.getElementById('reload-btn');
    btn.disabled = true;
    showLoading(true);
    showToast('Reloading current scene...', 'info');

    try {
        const response = await fetch(`${API_BASE_URL}/scene/reload`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.message || `HTTP ${response.status}`);
        }

        showToast('Scene reloaded successfully', 'success');

        // Refresh current scene display
        setTimeout(() => {
            refreshCurrentScene();
        }, 500);

    } catch (error) {
        console.error('Error reloading scene:', error);
        showToast(`Failed to reload scene: ${error.message}`, 'error');
    } finally {
        showLoading(false);
        btn.disabled = false;
    }
}

// Validate a scene
async function validateScene(scenePath, sceneName) {
    showLoading(true);
    showToast(`Validating ${sceneName}...`, 'info');

    try {
        const response = await fetch(`${API_BASE_URL}/scene`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                scene_path: scenePath
            })
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.message || `HTTP ${response.status}`);
        }

        // Display validation results in modal
        displayValidationResults(sceneName, data);

    } catch (error) {
        console.error('Error validating scene:', error);
        showToast(`Failed to validate scene: ${error.message}`, 'error');
    } finally {
        showLoading(false);
    }
}

// Display validation results in modal
function displayValidationResults(sceneName, data) {
    const isValid = data.valid === true;
    const hasWarnings = data.warnings && data.warnings.length > 0;
    const hasErrors = data.errors && data.errors.length > 0;

    let statusClass = 'valid';
    let statusIcon = '✓';
    let statusText = 'Valid';

    if (hasErrors || !isValid) {
        statusClass = 'invalid';
        statusIcon = '✗';
        statusText = 'Invalid';
    } else if (hasWarnings) {
        statusClass = 'warning';
        statusIcon = '⚠';
        statusText = 'Valid with Warnings';
    }

    let content = `
        <div class="validation-status ${statusClass}">
            <span style="font-size: 1.5em;">${statusIcon}</span>
            <span>${statusText}</span>
        </div>

        <div class="validation-details">
            <div class="validation-item">
                <div class="validation-item-header">Scene Name</div>
                <div class="validation-item-content">${sceneName}</div>
            </div>

            <div class="validation-item">
                <div class="validation-item-header">Scene Path</div>
                <div class="validation-item-content">${data.scene_path || 'Unknown'}</div>
            </div>

            <div class="validation-item">
                <div class="validation-item-header">Node Count</div>
                <div class="validation-item-content">${data.node_count !== undefined ? data.node_count : 'N/A'}</div>
            </div>
    `;

    if (hasWarnings) {
        content += `
            <div class="validation-item">
                <div class="validation-item-header">⚠ Warnings (${data.warnings.length})</div>
                <div class="validation-item-content">
                    <ul class="validation-list">
                        ${data.warnings.map(w => `<li>${w}</li>`).join('')}
                    </ul>
                </div>
            </div>
        `;
    }

    if (hasErrors) {
        content += `
            <div class="validation-item">
                <div class="validation-item-header">✗ Errors (${data.errors.length})</div>
                <div class="validation-item-content">
                    <ul class="validation-list">
                        ${data.errors.map(e => `<li>${e}</li>`).join('')}
                    </ul>
                </div>
            </div>
        `;
    }

    if (data.message) {
        content += `
            <div class="validation-item">
                <div class="validation-item-header">Additional Info</div>
                <div class="validation-item-content">${data.message}</div>
            </div>
        `;
    }

    content += `</div>`;

    showModal(content);
}

// Show scene info (quick validation)
async function showSceneInfo(scenePath, sceneName) {
    validateScene(scenePath, sceneName);
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
```

### 9. Update `refreshCurrentScene()` function

Add button disable/enable:

```javascript
async function refreshCurrentScene() {
    const btn = document.getElementById('refresh-btn');
    btn.disabled = true;

    try {
        const response = await fetch(`${API_BASE_URL}/scene`);
        // ... rest of existing code ...

        updateLastUpdateTime();
    } catch (error) {
        // ... existing error handling ...
    } finally {
        btn.disabled = false;
    }
}
```

### 10. Update `renderSceneList()` function

Replace the `<td>` with actions:

```javascript
<td>
    <div class="action-buttons">
        <button
            class="load-btn"
            onclick="loadScene('${scene.path}', '${escapeHtml(scene.name)}')"
            ${isCurrent ? 'disabled' : ''}
        >
            ${isCurrent ? '✓ Loaded' : '📂 Load'}
        </button>
        <button
            class="validate-btn"
            onclick="validateScene('${scene.path}', '${escapeHtml(scene.name)}')"
        >
            🔍 Validate
        </button>
        <button
            class="info-btn"
            onclick="showSceneInfo('${scene.path}', '${escapeHtml(scene.name)}')"
        >
            ℹ Info
        </button>
    </div>
</td>
```

### 11. Add event listener (before closing `</script>` tag)

```javascript
// Close modal on ESC key
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        closeModal();
    }
});
```

### 12. Update responsive CSS

Add to the `@media (max-width: 768px)` section:

```css
.action-buttons {
    flex-direction: column;
}
```

---

## Testing Checklist

After making all updates, verify:

- [ ] Reload button appears in header
- [ ] Reload button calls API and shows toast
- [ ] Validate button appears on each scene row
- [ ] Validate button opens modal with results
- [ ] Info button appears on each scene row
- [ ] Info button shows validation modal
- [ ] Modal shows color-coded status
- [ ] Modal displays node count
- [ ] Modal displays warnings (if any)
- [ ] Modal displays errors (if any)
- [ ] Modal closes on X button click
- [ ] Modal closes on background click
- [ ] Modal closes on ESC key
- [ ] All buttons disable during loading
- [ ] Toast notifications show for all actions
- [ ] Responsive layout works on mobile
- [ ] No JavaScript console errors

---

## Quick Test URL

Open in browser: `file:///C:/godot/web/test_features.html`

This provides standalone testing of all new API features.
