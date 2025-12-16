# Quick Fix Guide: Enable DAP/LSP Connections
**Time Required:** 5 minutes
**Difficulty:** Easy (1 line change)

## The Fix in 30 Seconds

**Problem:** DAP/LSP ports not listening
**Cause:** `CREATE_NO_WINDOW` flag
**Solution:** Remove the flag

## Step-by-Step Instructions

### 1. Edit the File (2 minutes)

Open `C:/godot/godot_editor_server.py` in your editor.

Find **line 91** (in the `start()` method):
```python
creationflags=subprocess.CREATE_NO_WINDOW
```

**Delete that line entirely.**

Before:
```python
self.process = subprocess.Popen(
    cmd,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    creationflags=subprocess.CREATE_NO_WINDOW  # ← DELETE THIS LINE
)
```

After:
```python
self.process = subprocess.Popen(
    cmd,
    stdout=subprocess.DEVNULL,  # Also change PIPE to DEVNULL
    stderr=subprocess.DEVNULL   # Also change PIPE to DEVNULL
)
```

**Save the file.**

### 2. Test the Fix (3 minutes)

```bash
# Kill existing Godot
taskkill /IM Godot*.exe /F

# Start the server
python godot_editor_server.py

# Wait 15 seconds for startup
# You should see Godot editor window open

# In another terminal, check ports
netstat -an | findstr ":6006 :6005 :8080"
```

**Expected output:**
```
TCP    127.0.0.1:6005         0.0.0.0:0              LISTENING
TCP    127.0.0.1:6006         0.0.0.0:0              LISTENING
TCP    127.0.0.1:8080         0.0.0.0:0              LISTENING
```

**All three ports should show LISTENING.** ✅

### 3. Verify It Works

Test DAP connection:
```bash
python -c "import socket; s=socket.socket(); s.connect(('127.0.0.1',6006)); print('DAP OK'); s.close()"
```

Test LSP connection:
```bash
python -c "import socket; s=socket.socket(); s.connect(('127.0.0.1',6005)); print('LSP OK'); s.close()"
```

**Expected output:**
```
DAP OK
LSP OK
```

## Done! 🎉

Your DAP and LSP servers are now working.

## Troubleshooting

### Port still not listening?

1. **Check Godot window opened:**
   - Look for Godot in taskbar
   - If no window, the fix didn't apply correctly

2. **Wait longer:**
   - Some systems need 20-30 seconds for full initialization
   - Check ports again after waiting

3. **Check Godot version:**
   ```bash
   "C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe" --version
   ```
   - Must be 4.0 or higher for DAP/LSP support

4. **Try manual launch first:**
   ```bash
   "C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe" --path "C:/godot" --dap-port 6006 --lsp-port 6005 --editor
   ```
   - If manual launch doesn't work, it's not a subprocess issue

### Window annoyance?

If the visible window bothers you:

**Option 1: Minimize it**
Just click minimize. Server keeps working.

**Option 2: Move to virtual desktop**
Windows 10/11: Win+Ctrl+D creates new desktop, move window there.

**Option 3: Use console executable**
See `GODOT_LAUNCH_INVESTIGATION_REPORT.md` for details.

## What Changed?

Before: Window hidden → Editor incomplete → DAP/LSP fail ❌
After:  Window visible → Editor complete → DAP/LSP work ✅

## Files for Reference

- **This guide:** `QUICK_FIX_GUIDE.md`
- **Full details:** `DAP_LSP_FIX_SUMMARY.md`
- **Investigation:** `GODOT_LAUNCH_INVESTIGATION_REPORT.md`
- **Comparison:** `LAUNCH_METHOD_COMPARISON.md`
- **Fixed version:** `godot_editor_server_fixed.py` (reference)

## Next Steps

After confirming the fix works:

1. ✅ Update documentation
2. ✅ Test with actual DAP/LSP clients
3. ✅ Run integration tests
4. ✅ Update related scripts if needed

---

**That's it! Enjoy your working DAP/LSP connections.** 🚀
