================================================================================
                            SpaceTime VR
                         Production Release
================================================================================

Version: 1.0
Build Date: See BUILD_INFO.txt
Platform: Windows Desktop (x86_64)
Engine: Godot 4.5.1-stable

================================================================================
QUICK START
================================================================================

1. Extract all files to a directory of your choice
2. Double-click SpaceTime.exe to launch
3. The application will start and load the default scene

================================================================================
SYSTEM REQUIREMENTS
================================================================================

Minimum Requirements:
  - OS: Windows 10/11 (64-bit)
  - CPU: Intel Core i5 or AMD Ryzen 5 (quad-core)
  - RAM: 8 GB
  - GPU: NVIDIA GTX 1060 / AMD RX 580 (4 GB VRAM)
  - DirectX: Version 11
  - Storage: 500 MB available space
  - Network: Broadband Internet connection (for HTTP API features)

Recommended Requirements (VR):
  - OS: Windows 10/11 (64-bit)
  - CPU: Intel Core i7 or AMD Ryzen 7 (hexa-core+)
  - RAM: 16 GB
  - GPU: NVIDIA RTX 2060 / AMD RX 5700 XT (6 GB VRAM)
  - VR Headset: Any OpenXR-compatible headset (Quest, Vive, Index, etc.)
  - Storage: 1 GB available space

================================================================================
VR SETUP
================================================================================

SpaceTime VR supports OpenXR-compatible VR headsets:

1. Install your VR headset's runtime software:
   - Meta Quest: Oculus PC software
   - HTC Vive: SteamVR
   - Valve Index: SteamVR
   - Windows Mixed Reality: Windows MR Portal

2. Connect and configure your VR headset

3. Ensure the VR runtime is active before launching SpaceTime VR

4. Launch SpaceTime.exe - VR mode will activate automatically if a headset
   is detected

Desktop Mode:
  - If no VR headset is detected, the application will run in desktop mode
  - You can still explore the environment using keyboard and mouse

================================================================================
CONTROLS
================================================================================

Desktop Mode:
  - WASD: Move camera
  - Mouse: Look around
  - Space: Jump / Fly up
  - Ctrl: Crouch / Fly down
  - Shift: Sprint
  - ESC: Menu

VR Mode:
  - Head movement: Look around
  - Controller triggers: Interact
  - Controller thumbsticks: Locomotion
  - Controller buttons: Menu (varies by headset)

================================================================================
HTTP API ACCESS
================================================================================

SpaceTime VR includes a built-in HTTP API for monitoring and control:

Default Port: 8080

Example endpoints:
  - http://127.0.0.1:8080/status         - System status
  - http://127.0.0.1:8080/state/scene    - Current scene info
  - http://127.0.0.1:8080/state/player   - Player state

To test the API:
  1. Launch SpaceTime.exe
  2. Wait 10-15 seconds for full initialization
  3. Open a web browser or use curl:
     curl http://127.0.0.1:8080/status

WebSocket Telemetry:
  - Port 8081
  - Real-time performance metrics
  - Connect with WebSocket client to: ws://127.0.0.1:8081

Note: The HTTP API is designed for development and monitoring. For production
deployments, consider security implications and firewall configuration.

================================================================================
ENVIRONMENT VARIABLES
================================================================================

Optional environment variables for configuration:

SPACETIME_DEBUG=1
  - Enables verbose debug logging to console
  - Useful for troubleshooting

SPACETIME_LOG_LEVEL=INFO|DEBUG|WARNING|ERROR
  - Sets the logging verbosity level
  - Default: INFO

SPACETIME_HTTP_API_PORT=8080
  - Changes the HTTP API port
  - Default: 8080

SPACETIME_TELEMETRY_PORT=8081
  - Changes the WebSocket telemetry port
  - Default: 8081

Example (Windows):
  set SPACETIME_DEBUG=1
  SpaceTime.exe

Example (PowerShell):
  $env:SPACETIME_DEBUG=1
  .\SpaceTime.exe

================================================================================
FILE INTEGRITY VERIFICATION
================================================================================

SHA256 checksums are provided for all files:

To verify file integrity:

Windows (PowerShell):
  Get-FileHash SpaceTime.exe -Algorithm SHA256
  # Compare output with SpaceTime.exe.sha256

Windows (Command Prompt):
  certutil -hashfile SpaceTime.exe SHA256
  # Compare output with SpaceTime.exe.sha256

Linux/Mac:
  sha256sum -c SpaceTime.exe.sha256

This ensures the files have not been corrupted or tampered with during
download or transfer.

================================================================================
TROUBLESHOOTING
================================================================================

Application won't start:
  - Ensure you have extracted all files (both .exe and .pck)
  - Install Visual C++ Redistributable (x64) if prompted
  - Update graphics drivers to latest version
  - Check Windows Event Viewer for error details

Low performance / stuttering:
  - Update graphics drivers
  - Close background applications
  - Lower quality settings in-game (if available)
  - For VR: Ensure headset refresh rate matches app (90 FPS target)

VR not working:
  - Verify VR runtime is installed and active
  - Ensure headset is connected before launching
  - Check headset firmware is up to date
  - Try restarting VR runtime software

HTTP API not responding:
  - Wait 15 seconds after launch for full initialization
  - Check if port 8080 is blocked by firewall
  - Verify no other application is using port 8080
  - Check console output for errors

Black screen or rendering issues:
  - Update graphics drivers
  - Verify DirectX 11 is installed
  - Check Windows Update for system updates
  - Try running as Administrator

================================================================================
KNOWN ISSUES
================================================================================

- VR comfort features (vignette, snap turns) are always enabled
- Some procedural generation features may cause brief stutters
- HTTP API authentication is basic (not recommended for public networks)
- Telemetry WebSocket has no rate limiting (may impact performance)

For latest updates and bug fixes, check for newer versions.

================================================================================
SUPPORT & CONTACT
================================================================================

For technical support, bug reports, or feature requests:

  - Issue Tracker: [URL to issue tracker]
  - Documentation: See docs/ folder or [URL to online docs]
  - Community: [URL to community forums/Discord]
  - Email: [Support email]

Please include the following information when reporting issues:
  - Windows version
  - Hardware specifications (CPU, GPU, RAM)
  - Build version (see BUILD_INFO.txt)
  - Steps to reproduce the issue
  - Screenshots or error messages

================================================================================
LICENSE & CREDITS
================================================================================

SpaceTime VR
Copyright (C) 2025

Built with Godot Engine 4.5.1-stable
https://godotengine.org

OpenXR VR support
https://www.khronos.org/openxr/

Third-party libraries and assets:
  - godottpd: HTTP server library
  - gdUnit4: Testing framework
  - Voxel plugin: Procedural terrain generation

See LICENSE.txt for full license information.

================================================================================
CHANGELOG
================================================================================

Version 1.0 (2025-12-04):
  - Initial production release
  - VR support via OpenXR
  - HTTP REST API for monitoring and control
  - WebSocket telemetry streaming
  - Procedural universe generation
  - Space physics simulation
  - Resonance gameplay mechanics

See CHANGELOG.md for complete version history.

================================================================================

Thank you for using SpaceTime VR!

================================================================================
