# Copilot Bash Execution Rules

## Objective
Minimize interactive approval requests by batching shell commands into a single executable script whenever possible.

## Rules

1. Batch Execution First
- Do NOT request to run multiple individual shell commands step-by-step.
- Instead, generate a single `.sh` script that contains all required commands in logical order.
- The script should be executable and self-contained.

2. Script Generation Requirements
- Always include:
  - `#!/usr/bin/env bash`
  - `set -euo pipefail`
- Add inline comments explaining each step.
- Group related operations together (inspection, cleanup, build, verification).

3. Use Scripts for:
- File inspection (ls, cat, wc, grep, etc.)
- Cleanup operations (rm, mv, overwrite fixes)
- Build/test flows
- Debugging / environment validation
- Multi-step fixes (especially when state depends on prior commands)

4. Idempotency
- Scripts should be safe to run multiple times where possible.
- Use guards like:
  - `if [ -f ... ]`
  - `mkdir -p`
  - conditional deletes

5. Logging
- Output meaningful logs using `echo` so results are easy to interpret.
- Clearly indicate:
  - start/end of script
  - major steps
  - success/failure points

6. Avoid Interactive Friction
- Do NOT pause to ask for permission for each command.
- Only request execution once per script.

7. File Placement
- Place generated scripts in:
  - `target/scripts/` (preferred)
- Place logs in:
  - `target/logs/`

8. When NOT to Batch
- Only avoid batching if:
  - A command is destructive AND requires explicit user confirmation
  - Or the user explicitly asks for step-by-step execution

## Example Pattern

Instead of:
- asking to run `cat`
- then `rm`
- then `ls`

You should generate:

'''
#!/usr/bin/env bash
set -euo pipefail

echo "Starting file repair..."

FILE="interactive-system-hierarchy-visualization/index.html"

if [ -f "$FILE" ]; then
  echo "File exists. Inspecting..."
  wc -l "$FILE"
else
  echo "File not found"
fi

echo "Removing corrupted file..."
rm -f "$FILE"

echo "Verifying deletion..."
if [ ! -f "$FILE" ]; then
  echo "SUCCESS: File deleted"
else
  echo "ERROR: File still exists"
fi

echo "Done."
'''

## Enforcement

If multiple shell commands are needed:
→ ALWAYS consolidate into a single script first.
→ NEVER default to multiple approval prompts.