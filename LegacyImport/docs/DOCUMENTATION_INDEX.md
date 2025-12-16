# SpaceTime VR - Complete Documentation Index

**Version:** 2.5.0
**Last Updated:** 2025-12-02
**Status:** Production-Ready

This is the master index for all SpaceTime VR documentation. Use this as your starting point to find any information about the project.

## Quick Navigation

| I need to... | Go to... |
|--------------|----------|
| Get started as a new developer | [Getting Started](development/GETTING_STARTED.md) |
| Look up API endpoints | [API Reference](api/API_REFERENCE.md) |
| Deploy to production | [Deployment Runbook](operations/RUNBOOKS.md#deployment-procedures) |
| Understand game systems | [Game Systems Architecture](architecture/GAME_SYSTEMS.md) |
| Find a command quickly | [Quick Reference](QUICK_REFERENCE.md) |
| Troubleshoot an issue | [Troubleshooting Guide](#troubleshooting) |
| Learn the development workflow | [Development Workflow](current/guides/DEVELOPMENT_WORKFLOW.md) |

---

## Documentation Categories

### 1. Getting Started

**For new developers and team members:**

- **[Getting Started Guide](development/GETTING_STARTED.md)**
  - Prerequisites and installation
  - First run instructions
  - Development workflow
  - Troubleshooting

- **[Quick Reference](QUICK_REFERENCE.md)**
  - Essential commands
  - Common patterns
  - Quick solutions

- **[Project Overview](README.md)**
  - What is SpaceTime VR
  - Key features
  - Technology stack

### 2. API Documentation

**Complete API reference for all interfaces:**

- **[API Reference (MASTER)](api/API_REFERENCE.md)** ⭐ **NEW**
  - HTTP REST API (complete)
  - WebSocket Telemetry API
  - Multiplayer RPC Interface
  - Database Schema
  - Redis Cache Structure
  - Authentication
  - Error Handling

- **[HTTP API Master Index](current/api/HTTP_API_MASTER_INDEX.md)**
  - Endpoint catalog
  - Request/response formats
  - Authentication

- **[HTTP API Usage Guide](current/api/HTTP_API_USAGE_GUIDE.md)**
  - Usage patterns
  - Best practices
  - Examples

- **Specialized API Docs:**
  - [Terrain API Reference](current/api/TERRAIN_API_REFERENCE.md)
  - [VR Teleportation API](current/api/VR_TELEPORTATION_HTTP_API.md)
  - [Health Endpoint Examples](current/api/HEALTH_ENDPOINT_EXAMPLES.md)
  - [Scene Validation API](SCENE_VALIDATION_API.md)
  - [Scene Reload Endpoint](current/api/SCENE_RELOAD_ENDPOINT.md)

### 3. System Architecture

**Understanding how SpaceTime VR works:**

- **[Game Systems Architecture](architecture/GAME_SYSTEMS.md)** ⭐ **NEW**
  - Voxel Terrain System
  - Server Meshing
  - Authority Transfer Protocol
  - Persistence and Save System
  - Creature AI
  - Taming and Breeding
  - Base Building System
  - Power Grid System
  - Resource Management
  - Crafting System

- **[Full Project Overview](current/guides/FULL_PROJECT_OVERVIEW.md)**
  - System overview
  - Component interactions
  - Data flow

- **[Remote Access Architecture](current/guides/REMOTE_ACCESS_ARCHITECTURE.md)**
  - Remote control design
  - API architecture

- **[Smart Server](current/guides/SMART_SERVER_FINAL.md)**
  - Server abstraction layer
  - Lifecycle management

- **[System Integration](SYSTEM_INTEGRATION.md)**
  - Component integration
  - Service communication

### 4. Operations & Deployment

**For DevOps, SRE, and production operations:**

- **[Operational Runbooks (MASTER)](operations/RUNBOOKS.md)** ⭐ **NEW**
  - Deployment Procedures
  - Scaling (Horizontal & Vertical)
  - Rollback Procedures
  - Database Operations (Backup & Restore)
  - Monitoring and Alerting
  - Incident Response
  - Maintenance Windows
  - Disaster Recovery

- **[Rollback Procedures](ROLLBACK_PROCEDURES.md)**
  - Quick rollback guide
  - Emergency procedures
  - Verification steps

- **[CI/CD Guide](CI_CD_GUIDE.md)**
  - Pipeline configuration
  - Automated deployments
  - Workflow triggers

- **[CI/CD Pipeline Summary](CI_CD_PIPELINE_SUMMARY.md)**
  - Pipeline overview
  - Stage descriptions

- **[Monitoring & Observability](MONITORING.md)**
  - Metrics collection
  - Alert configuration
  - Dashboard setup

- **[Monitoring Implementation Report](MONITORING_IMPLEMENTATION_REPORT.md)**
  - Monitoring setup details
  - Grafana dashboards

- **[Performance Optimization](PERFORMANCE_OPTIMIZATION.md)**
  - Optimization strategies
  - Profiling techniques

- **Deployment Guides:**
  - [Deployment Guide](current/guides/DEPLOYMENT_GUIDE.md)
  - [Docker Deployment v2.5](current/guides/DOCKER_DEPLOYMENT_V2.5.md)
  - [Godot Server Setup](current/guides/GODOT_SERVER_SETUP.md)
  - [Headless Mode Guide](current/guides/HEADLESS_MODE_GUIDE.md)

### 5. Security

**Security documentation and best practices:**

- **[Security Audit](current/security/SECURITY_AUDIT.md)**
  - Security review findings
  - Recommendations
  - Implementation status

- **[API Token Guide](current/security/API_TOKEN_GUIDE.md)**
  - Token management
  - Best practices
  - Rotation procedures

- **[Quick Start v2.5 Security](current/security/QUICK_START_V2.5_SECURITY.md)**
  - Security features
  - Configuration guide

- **[Security Examples](current/security/SECURITY_CURL_EXAMPLES.md)**
  - Secure API usage
  - Authentication examples

- **Security Implementation:**
  - [TLS Setup](TLS_SETUP.md)
  - [TLS Implementation Report](TLS_IMPLEMENTATION_REPORT.md)
  - [Token Management](TOKEN_MANAGEMENT.md)
  - [Token System Architecture](TOKEN_SYSTEM_ARCHITECTURE.md)
  - [Token Rotation Implementation](TOKEN_ROTATION_IMPLEMENTATION_REPORT.md)

### 6. Testing

**Comprehensive testing documentation:**

- **[Testing Guide](TESTING_GUIDE.md)**
  - Testing strategy
  - Test types
  - Running tests

- **[Testing Guide (Current)](current/testing/TESTING_GUIDE.md)**
  - Updated testing docs
  - Test suites

- **[Quick Reference Testing](current/testing/QUICK_REFERENCE_TESTING.md)**
  - Quick test commands
  - Common patterns

- **[Test Commands](current/testing/TEST_COMMANDS.md)**
  - Command reference
  - Examples

- **Test Suites:**
  - [Movement Test Features](current/testing/MOVEMENT_TEST_FEATURES.md)
  - [Movement Test README](current/testing/MOVEMENT_TEST_README.md)
  - [Spacecraft Test Index](current/testing/SPACECRAFT_TEST_INDEX.md)
  - [Performance Benchmarks](current/testing/PERFORMANCE_BENCHMARKS.md)

- **User Testing:**
  - [User Testing Guide](current/testing/USER_TESTING_GUIDE.md)
  - [User Testing Ready](current/testing/USER_TESTING_READY.md)

### 7. Development Guides

**Developer resources and guides:**

- **[Getting Started](development/GETTING_STARTED.md)** ⭐ **NEW**
  - Complete onboarding guide
  - Installation instructions
  - First steps

- **[Development Workflow](current/guides/DEVELOPMENT_WORKFLOW.md)**
  - Daily workflow
  - Best practices
  - Development cycle

- **[Contributing Guide](CONTRIBUTING.md)**
  - How to contribute
  - Code style
  - Pull request process

- **[GdUnit4 Setup](current/guides/GDUNIT4_SETUP.md)**
  - Testing framework setup
  - Writing tests

- **[Quick Start Guide](current/guides/QUICK_START.md)**
  - Fast track setup
  - Common tasks

### 8. Feature Documentation

**Documentation for specific game features:**

#### Planetary Survival
- [Planetary Survival Quick Start](current/guides/QUICK_START_PLANETARY_SURVIVAL.md)
- [Life Support System](current/guides/LIFE_SUPPORT_SYSTEM.md)
- [Base Building Quick Reference](current/guides/BASE_BUILDING_QUICK_REF.md)

#### Player Systems
- [Inventory Quick Start](current/guides/INVENTORY_QUICKSTART.md)
- [Inventory UI System](current/guides/INVENTORY_UI_SYSTEM.md)
- [Jetpack VFX](current/guides/JETPACK_VFX.md)
- [Spacecraft Quick Reference](current/guides/SPACECRAFT_QUICK_REFERENCE.md)

#### AI & Creatures
- [Creature AI Quick Start](current/guides/CREATURE_AI_QUICKSTART.md)
- [Creature AI System](current/guides/CREATURE_AI_SYSTEM.md)

#### Power & Infrastructure
- [Power Grid HUD](current/guides/POWER_GRID_HUD.md)

#### VR Systems
- [VR Setup Guide](current/guides/VR_SETUP_GUIDE.md)
- [VR Teleportation](current/guides/VR_TELEPORTATION.md)
- [VR Tracking Reference](current/guides/VR_TRACKING_QUICK_REFERENCE.md)
- [VR Optimization](VR_OPTIMIZATION.md)

#### Scene Management
- [Scene Loader Quick Start](current/guides/SCENE_LOADER_QUICK_START.md)
- [Scene Validation API](SCENE_VALIDATION_API.md)

#### Monitoring & Health
- [Health Dashboard](current/guides/HEALTH_DASHBOARD.md)
- [Player Monitor Usage](current/guides/PLAYER_MONITOR_USAGE.md)
- [Player Monitor Flow](current/guides/PLAYER_MONITOR_FLOW.md)
- [Player Monitor Quick Start](current/guides/QUICK_START_PLAYER_MONITOR.md)
- [Telemetry Guide](current/guides/TELEMETRY_GUIDE.md)

#### Tutorial & Assets
- [Tutorial Assets](current/guides/TUTORIAL_ASSETS.md)
- [Video Tutorial Script](current/guides/VIDEO_TUTORIAL_SCRIPT.md)

### 9. Reports & Status

**Project reports and status documents:**

- **Implementation Reports:**
  - [Persistence Implementation](PERSISTENCE_IMPLEMENTATION_REPORT.md)
  - [Property Tests Implementation](PROPERTY_TESTS_IMPLEMENTATION_REPORT.md)
  - [Admin Dashboard Delivery](ADMIN_DASHBOARD_DELIVERY.md)
  - [Integration Guide](INTEGRATION_GUIDE.md)

- **Completion Reports:**
  - [Task 47 Completion Summary](TASK_47_COMPLETION_SUMMARY.md)
  - [Task 45 Monitoring/Observability Complete](TASK_45_MONITORING_OBSERVABILITY_COMPLETE.md)
  - [Task 35 Completion Summary](TASK_35_COMPLETION_SUMMARY.md)
  - [Task 35 Conflict Resolution](TASK_35_CONFLICT_RESOLUTION_REPORT.md)

- **Status Documents:**
  - [Go-Live Checklist](GO_LIVE_CHECKLIST.md)
  - [Known Issues](KNOWN_ISSUES.md)
  - [Release Notes](RELEASE_NOTES.md)
  - [Final Validation Report](FINAL_VALIDATION_REPORT.md)

### 10. Release Information

**Release notes and version history:**

- **[Release Notes](RELEASE_NOTES.md)**
  - Version history
  - Feature additions
  - Bug fixes
  - Breaking changes

- **[Known Issues](KNOWN_ISSUES.md)**
  - Current known issues
  - Workarounds
  - Fix status

- **[Conflict Resolution Quick Reference](CONFLICT_RESOLUTION_QUICK_REFERENCE.md)**
  - Merge conflict resolution
  - Common conflicts

---

## Documentation by Role

### For New Developers
1. [Getting Started](development/GETTING_STARTED.md)
2. [Quick Reference](QUICK_REFERENCE.md)
3. [Development Workflow](current/guides/DEVELOPMENT_WORKFLOW.md)
4. [Contributing Guide](CONTRIBUTING.md)

### For API Developers
1. [API Reference](api/API_REFERENCE.md)
2. [HTTP API Usage Guide](current/api/HTTP_API_USAGE_GUIDE.md)
3. [Authentication Guide](current/security/API_TOKEN_GUIDE.md)
4. Examples in `examples/` directory

### For System Architects
1. [Game Systems Architecture](architecture/GAME_SYSTEMS.md)
2. [Full Project Overview](current/guides/FULL_PROJECT_OVERVIEW.md)
3. [System Integration](SYSTEM_INTEGRATION.md)
4. [Server Meshing Documentation](architecture/GAME_SYSTEMS.md#server-meshing)

### For DevOps/SRE
1. [Operational Runbooks](operations/RUNBOOKS.md)
2. [Deployment Guide](current/guides/DEPLOYMENT_GUIDE.md)
3. [Monitoring Guide](MONITORING.md)
4. [Rollback Procedures](ROLLBACK_PROCEDURES.md)
5. [CI/CD Guide](CI_CD_GUIDE.md)

### For QA/Testers
1. [Testing Guide](TESTING_GUIDE.md)
2. [User Testing Guide](current/testing/USER_TESTING_GUIDE.md)
3. [Test Commands](current/testing/TEST_COMMANDS.md)
4. [Performance Benchmarks](current/testing/PERFORMANCE_BENCHMARKS.md)

### For Security Team
1. [Security Audit](current/security/SECURITY_AUDIT.md)
2. [Token Management](TOKEN_MANAGEMENT.md)
3. [TLS Setup](TLS_SETUP.md)
4. [Security Examples](current/security/SECURITY_CURL_EXAMPLES.md)

### For Project Managers
1. [Project Overview](README.md)
2. [Go-Live Checklist](GO_LIVE_CHECKLIST.md)
3. [Known Issues](KNOWN_ISSUES.md)
4. [Release Notes](RELEASE_NOTES.md)

---

## Troubleshooting

### Common Issues

| Issue | Quick Fix | Documentation |
|-------|-----------|---------------|
| Godot won't start | `taskkill /F /IM godot.exe` | [Getting Started](development/GETTING_STARTED.md#troubleshooting) |
| API not responding | Try port 8083, restart server | [Quick Reference](QUICK_REFERENCE.md#common-issues) |
| VR not working | Check SteamVR, verify OpenXR | [VR Setup Guide](current/guides/VR_SETUP_GUIDE.md) |
| Tests failing | Clear cache, update dependencies | [Testing Guide](TESTING_GUIDE.md) |
| Deployment failed | Check logs, rollback if needed | [Rollback Procedures](ROLLBACK_PROCEDURES.md) |

### Getting Help

**Documentation Search:**
Use Ctrl+F in your browser to search this index, or use GitHub's search feature to search all documentation.

**Support Channels:**
- **Discord:** [Join Server](https://discord.gg/spacetime)
- **GitHub Issues:** [Report Bug](https://github.com/your-org/spacetime-vr/issues)
- **Email:** support@spacetime.example.com

**Internal Resources:**
- Check `CLAUDE.md` for project-specific instructions
- Review `README.md` for project overview
- Consult `QUICK_REFERENCE.md` for commands

---

## Documentation Standards

### File Naming
- ALL_CAPS_WITH_UNDERSCORES.md for root-level docs
- lowercase_with_underscores.md for subdirectory docs
- Use descriptive names

### Structure
- Start with title and metadata
- Include table of contents for long docs
- Use clear headings and subheadings
- Provide code examples
- Link to related documentation

### Maintenance
- Update "Last Updated" date when editing
- Keep version number current
- Remove outdated information
- Archive superseded docs to `history/archive/`

---

## Historical Documentation

Looking for old reports, completed tasks, or archived documents?

### Location: `history/` Directory

- **[Checkpoints](history/checkpoints/)** - 30 development checkpoints
- **[Tasks](history/tasks/)** - 87 completed task reports
- **[Summaries](history/summaries/)** - 52 session summaries and reports
- **[Archive](history/archive/)** - Archived implementation notes

---

## External Resources

### Godot Engine
- [Godot Documentation](https://docs.godotengine.org/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [Godot VR](https://docs.godotengine.org/en/stable/tutorials/vr/index.html)

### Technologies
- [OpenXR Specification](https://www.khronos.org/openxr/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

### Python Libraries
- [Requests Documentation](https://requests.readthedocs.io/)
- [Pytest Documentation](https://docs.pytest.org/)
- [Hypothesis Documentation](https://hypothesis.readthedocs.io/)

---

## Contributing to Documentation

**Want to improve the docs?**

1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Follow documentation standards above
3. Submit a pull request
4. Update this index if adding new docs

**Documentation PRs are always welcome!**

---

## Documentation Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.5.0 | 2025-12-02 | Added comprehensive API reference, operational runbooks, game systems architecture, and developer guides |
| 2.4.0 | 2025-12-01 | Added security documentation, CI/CD guides |
| 2.3.0 | 2025-11-30 | Reorganized documentation structure |
| 2.2.0 | 2025-11-29 | Added testing guides and feature docs |
| 2.1.0 | 2025-11-28 | Initial documentation framework |

---

## Quick Links (Most Common)

**Top 10 most-accessed documents:**

1. [API Reference](api/API_REFERENCE.md)
2. [Quick Reference](QUICK_REFERENCE.md)
3. [Getting Started](development/GETTING_STARTED.md)
4. [Operational Runbooks](operations/RUNBOOKS.md)
5. [Game Systems Architecture](architecture/GAME_SYSTEMS.md)
6. [Development Workflow](current/guides/DEVELOPMENT_WORKFLOW.md)
7. [Testing Guide](TESTING_GUIDE.md)
8. [Deployment Guide](current/guides/DEPLOYMENT_GUIDE.md)
9. [Rollback Procedures](ROLLBACK_PROCEDURES.md)
10. [Monitoring Guide](MONITORING.md)

---

**Last Updated:** 2025-12-02
**Version:** 2.5.0
**Status:** Production-Ready

**Welcome to SpaceTime VR! Happy developing!**
