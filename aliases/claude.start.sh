#!/usr/bin/env bash
set -euo pipefail

# claude.start.sh — Start the claude-code MCP server, health-check it, then
#                    launch the Claude Code CLI (dev mode via Bun).
#
# Usage:
#  claude.start.sh [--foreground] [CLAUDE_CODE_DIR] [-- CLI_ARGS...]
#
# Everything after a bare "--" is forwarded to the Claude CLI.
#
# Environment variables:
#  CLAUDE_CODE_DIR  - path to the claude-code repo (optional). Default tries common paths.
#  CLAUDE_CURL_URL  - URL to curl once server is ready. Default: http://localhost:3000/health
#  CLAUDE_LOG       - where to write server log when started in background. Default: /tmp/claude-server.log
#  CLAUDE_NO_CLI    - set to 1 to skip launching the CLI after the health check.
#
# By default the script starts the MCP server in the background, waits up to
# 30 seconds for the health endpoint to respond, then launches the interactive
# Claude Code CLI. Use --foreground as first arg to run the MCP server in the
# foreground instead.

DEFAULT_DIRS=(
  "${CLAUDE_CODE_DIR:-}"
  "/c/Users/Computer/dev/claude-code-bootstrap/claude-code"
  "$HOME/dev/claude-code-bootstrap/claude-code"
  "$(pwd)/../dev/claude-code-bootstrap/claude-code"
)

FOREGROUND=0
if [ "${1:-}" = "--foreground" ]; then
  FOREGROUND=1
  shift || true
fi

# Parse optional positional dir and "--" separator for CLI args
ARG_DIR=""
CLI_ARGS=()
if [ "${1:-}" = "--" ]; then
  # No dir given, just CLI args
  shift || true
  CLI_ARGS=("$@")
elif [ -n "${1:-}" ]; then
  ARG_DIR="$1"
  shift || true
  if [ "${1:-}" = "--" ]; then
    shift || true
    CLI_ARGS=("$@")
  fi
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
  # last resort: look for a nearby folder named claude-code
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

start_cmd=""
# Prefer a built HTTP entrypoint if present
if [ -f "dist/src/http.js" ]; then
  start_cmd="node dist/src/http.js"
elif [ -f "src/index.ts" ]; then
  # dev entrypoint
  start_cmd="npx tsx src/index.ts"
elif grep -q "start:http" package.json 2>/dev/null; then
  start_cmd="npm run start:http"
else
  start_cmd="npm run dev"
fi

if [ "$FOREGROUND" -eq 1 ]; then
  echo "Running claude MCP server in foreground: $start_cmd"
  # run in foreground and in parallel wait for the health endpoint
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

# ── Launch the Claude Code CLI ──────────────────────────────────────
if [ "${CLAUDE_NO_CLI:-0}" = "1" ]; then
  echo "CLAUDE_NO_CLI=1 — skipping CLI launch."
  echo "To stop the background server: kill $SERVER_PID"
  exit 0
fi

cd "$CLAUDE_DIR"

# Use bun dev runner (works without a production build)
if command -v bun >/dev/null 2>&1 && [ -f "scripts/dev.ts" ]; then
  echo "Launching Claude Code CLI via: bun scripts/dev.ts ${CLI_ARGS[*]:-}"
  exec bun scripts/dev.ts "${CLI_ARGS[@]}"
else
  echo "bun not found or scripts/dev.ts missing — cannot launch CLI." >&2
  echo "Install bun (https://bun.sh) or run from the claude-code directory manually." >&2
  echo "To stop the background server: kill $SERVER_PID"
  exit 1
fi
