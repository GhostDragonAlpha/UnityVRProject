# VR Testing Workflow

**Last Updated:** 2025-12-09
**Purpose:** Document the workflow for testing VR scenes and diagnosing issues when scenes close unexpectedly or show gray screen

## Overview

This document provides a step-by-step workflow for debugging VR scenes in Godot. When VR scenes close unexpectedly or show gray screen in the headset, follow this systematic approach to identify and fix the root cause.

## Critical Rule: Always Check Godot Console Output

**WHEN SCENE CLOSES OR SHOWS ISSUES → IMMEDIATELY RETRIEVE CONSOLE OUTPUT**

The Godot console contains the source of truth for all runtime behavior, initialization status, and errors.

## Step-by-Step Debugging Workflow

### STEP 1: Launch VR Scene with Output Monitoring

Always launch VR scenes in background to capture console output:

```bash
cd "C:/Ignotus" && "C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "." "res://scenes/vr_main.tscn" 2>&1 &
```

**Save the bash_id returned from this command - you will need it to retrieve console output.**

### STEP 2: Retrieve Console Output When Issues Occur

**CRITICAL:** When scene closes or shows issues, IMMEDIATELY retrieve console output using the bash_id from step 1.

### STEP 3: Analyze VR Initialization Section

Look for the SUCCESS pattern (all 4 lines must be present):

```
[VRMain] Found OpenXR interface
[VRMain] OpenXR initialized successfully
[VRMain] Viewport marked for XR rendering
[VRMain] Switching to XR Camera...
```

### STEP 4: Check Physics Status

For pure VR tracking tests, verify physics is DISABLED. Look for:

```
[VRMain] Physics movement disabled - VR tracking only mode  ← CORRECT
```

If you see this instead, physics is interfering:

```
[VRMain] Initializing player in Earth Orbit...  ← WRONG - causes gray screen
```

FIX: Edit scenes/vr_main.tscn line 54: physics_movement_enabled = false

### SUCCESS CRITERIA

1. ✓ All 4 VR initialization messages present
2. ✓ Physics disabled message (for tracking tests)
3. ✓ No critical ERROR lines
4. ✓ Scene status: running
5. ✓ SteamVR showing headset tracking active
6. ✓ User can see scene in headset (not gray screen)

## Quick Reference

```bash
# Check SteamVR
python scripts/tools/check_steamvr_status.py

# Kill Godot
taskkill //F //IM Godot_v4.5.1-stable_win64_console.exe

# Wait for shutdown
ping 127.0.0.1 -n 4 >nul
```

## Key Files

- vr_main.gd:41 - Physics toggle
- scenes/vr_main.tscn:54 - physics_movement_enabled setting
