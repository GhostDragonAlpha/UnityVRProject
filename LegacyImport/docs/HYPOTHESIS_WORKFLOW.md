# Hypothesis-Driven Delegation Workflow

## The Core Philosophy
"The Master Agent defines the Truth (The Test). The Sub-Agent makes it Reality (The Fix)."

This workflow addresses the "Context Loss" problem in agentic coding. Instead of relying on sub-agents to understand the entire project history, we rely on **executable verification code** (Hypothesis Tests) as the absolute source of truth for the task at hand.

## The Workflow Loop

### 1. The Hypothesis (Master Agent)
**Role**: Director & Verifier
**Action**:
1.  Analyzes the user request.
2.  Writes a **Failing Test** (The Hypothesis) that asserts the desired behavior.
    *   This can be a Python `unittest`/`hypothesis` script, a Godot `RuntimeVerifier` check, or a `verify_holistic_state.py` layer.
3.  Verifies that the test **FAILS** (Red State).
4.  Generates a specific prompt for the Sub-Agent, including:
    *   The Failing Test Code (or path to it).
    *   The specific file(s) to modify.
    *   The constraint: "Make this test pass."

### 2. The Experiment (Sub-Agent)
**Role**: Technician & Fixer
**Action**:
1.  Receives the Failing Test and the target code.
2.  Modifies the target code to satisfy the test conditions.
3.  Runs the test locally to verify the fix.
4.  **DOES NOT** need to know the full project history, only the constraints defined by the test.

### 3. The Verification (Master Agent)
**Role**: Auditor
**Action**:
1.  Receives control back from the Sub-Agent.
2.  Runs the **Same Test** (The Hypothesis) again.
3.  **Pass (Green State)**: The task is complete. Proceed to next task.
4.  **Fail (Red State)**: The Sub-Agent failed.
    *   Analyze the failure output.
    *   Refine the instructions or the test itself.
    *   Delegate again (Loop back to Step 2).

## Tools of the Trade

### Logic Verification (Python/Hypothesis)
Use for: Algorithms, Procedural Generation, Math, Data Structures.
*   **Tool**: `pytest` + `hypothesis`
*   **Location**: `tests/property/`
*   **Example**: "Verify that the procedural planet generator always produces coordinates within the solar system bounds."

### State Verification (Godot/Runtime)
Use for: Scene Tree, Node Existence, Signal Connections, Physics.
*   **Tool**: `verify_holistic_state.py` (The Ratchet)
*   **Location**: `tests/verify_holistic_state.py`
*   **Example**: "Verify that the 'MoonLandingPolish' script creates a 'Starfield' node."

### Configuration Verification (Static)
Use for: Project Settings, File Existence, Export Presets.
*   **Tool**: `static_verifier.gd`
*   **Location**: `scripts/core/static_verifier.gd`
*   **Example**: "Verify that the main scene is set to 'vr_main.tscn'."
