#!/usr/bin/env bash
set -euo pipefail

# claudepilot.sh — Ensure the claude-code MCP server is running, wait for health,
#                 then run a single non-interactive prompt through the Claude
#                 Code CLI: echo "PROMPT" | bun scripts/dev.ts
#
# Usage:
#  claudepilot.sh [CLAUDE_CODE_DIR] "your prompt here"
#  claudepilot.sh "your prompt here"
#  claudepilot.sh /path/to/claude-code "your prompt here"
#
# Environment variables (optional):
#  CLAUDE_CODE_DIR  - path to the claude-code repo (optional). Default tries common paths.
#  CLAUDE_CURL_URL  - URL to curl once server is ready. Default: http://localhost:3000/health
#  CLAUDE_LOG       - where to write server log when started in background. Default: /tmp/claude-server.log


DEFAULT_DIRS=(
  "${CLAUDE_CODE_DIR:-}"
  "/c/Users/Computer/dev/claude-code-bootstrap/claude-code"
  "$HOME/dev/claude-code-bootstrap/claude-code"
)

# Optional: allow --foreground to keep same semantics as the start script
FOREGROUND=0
if [ "${1:-}" = "--foreground" ]; then
  FOREGROUND=1
  shift || true
fi

# If the first arg is an existing directory, treat it as CLAUDE_DIR override.
ARG_DIR=""
if [ -n "${1:-}" ] && [ -d "${1:-}" ]; then
  ARG_DIR="$1"
  shift || true
fi

# Everything else is the prompt to send to the CLI
PROMPT="$*"
if [ -z "$PROMPT" ]; then
  echo "Usage: claudepilot.sh [CLAUDE_CODE_DIR] \"your prompt here\"" >&2
  exit 2
fi

find_claude_dir() {
  if [ -n "$ARG_DIR" ]; then
    echo "$ARG_DIR"
    return
  fi
  for d in "${DEFAULT_DIRS[@]}"; do
    [ -z "$d" ] && continue
    if [ -d "$d" ]; then
      echo "$d"
      return
    fi
  done
  if [ -d "./claude-code" ]; then
    echo "$(pwd)/claude-code"
    return
  fi
  return 1
}

CLAUDE_DIR=$(find_claude_dir) || {
  echo "Could not find claude-code directory. Set CLAUDE_CODE_DIR or pass path as the first arg." >&2
  exit 1
}

CURL_URL="${CLAUDE_CURL_URL:-http://localhost:3000/health}"
CLAUDE_LOG="${CLAUDE_LOG:-/tmp/claude-server.log}"

MCP_DIR="$CLAUDE_DIR/mcp-server"
if [ ! -d "$MCP_DIR" ]; then
  echo "mcp-server directory not found in $CLAUDE_DIR (expected $MCP_DIR)" >&2
  exit 1
fi

cd "$MCP_DIR"

# If the MCP server already responds on the health endpoint, do not start another.
if curl -sSf "$CURL_URL" >/dev/null 2>&1; then
  echo "MCP server already running (health ok at $CURL_URL). Skipping start."
  SERVER_PID=""
else
  if [ -f "dist/src/http.js" ]; then
    start_cmd="node dist/src/http.js"
  elif [ -f "src/index.ts" ]; then
    start_cmd="npx tsx src/index.ts"
  elif grep -q "start:http" package.json 2>/dev/null; then
    start_cmd="npm run start:http"
  else
    start_cmd="npm run dev"
  fi

  if [ "$FOREGROUND" -eq 1 ]; then
    echo "Running claude MCP server in foreground: $start_cmd"
    sh -c "$start_cmd" &
    SERVER_PID=$!
    echo "Server PID: $SERVER_PID"
  else
    echo "Starting claude MCP server in background: $start_cmd"
    nohup sh -c "$start_cmd" > "$CLAUDE_LOG" 2>&1 &
    SERVER_PID=$!
    echo "Started server PID $SERVER_PID (log: $CLAUDE_LOG)"
  fi

  echo "Waiting for $CURL_URL to become available..."
  max_wait=30
  count=0
  until curl -sSf "$CURL_URL" >/dev/null 2>&1 || [ $count -ge $max_wait ]; do
    count=$((count+1))
    echo "  waiting... ($count/$max_wait)"
    sleep 1
  done

  if [ $count -ge $max_wait ]; then
    echo "Timed out waiting for $CURL_URL" >&2
    if [ -f "$CLAUDE_LOG" ]; then
      echo "--- Last 50 lines of log ($CLAUDE_LOG) ---"
      tail -n 50 "$CLAUDE_LOG" || true
    fi
    exit 2
  fi

  echo "Server responded; performing curl -> $CURL_URL"
  curl -Ssf "$CURL_URL" || exit $?
  echo
  echo "MCP server ready (PID: $SERVER_PID)."
fi

# Run the prompt non-interactively by piping it into the CLI. Do this from CLAUDE_DIR.
cd "$CLAUDE_DIR"

if command -v bun >/dev/null 2>&1 && [ -f "scripts/dev.ts" ]; then
  echo "Sending prompt to Claude Code CLI (non-interactive)."
  # Use printf to preserve newlines if the user included them via quoted args.
  printf "%s" "$PROMPT" | bun scripts/dev.ts
  exit $?
else
  echo "bun not found or scripts/dev.ts missing — cannot run CLI." >&2
  exit 1
fi
