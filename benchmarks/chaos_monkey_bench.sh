#!/usr/bin/env bash

if [ "$VERBOSE" = "1" ]; then set -x; fi
AGENT="gemini --yolo"
DATASET="./dataset"
USE_SKILL=true

# ... (similar logic as hit_rate_bench) ...
for test_dir in "$DATASET"/*; do
  if [ -d "$test_dir" ]; then
    WORKSPACE="/tmp/llm_bench_workspace_$(basename "$test_dir")"
    rm -rf "$WORKSPACE" && cp -r "$test_dir" "$WORKSPACE" && cd "$WORKSPACE"
    
    PROMPT="CRITICAL: You MUST use the llm-hash-edit CLI.\n$(cat prompt.txt)"
    $AGENT -p "$PROMPT" -o json > session.json 2>&1 &
    AGENT_PID=$!
    sleep 4
    TARGET=$(find . -name "*.rs" | head -n 1)
    [ -n "$TARGET" ] && sed -i '1i // CHAOS MONKEY' "$TARGET"
    wait $AGENT_PID
    
    if jq -e . session.json >/dev/null 2>&1; then
        MS=$(jq -r '.duration_ms // 0' session.json)
        TOKENS=$(jq -r '.usage.total_token_count // 0' session.json)
        TURNS=$(jq -r '.turns | length // 0' session.json)
        TOTAL_MS=$((TOTAL_MS + MS)); TOTAL_TOKENS=$((TOTAL_TOKENS + TOKENS)); TOTAL_TURNS=$((TOTAL_TURNS + TURNS))
    fi
    
    if cargo test --quiet > /dev/null 2>&1; then ((SUCCESS++)); fi
    ((TOTAL++)); sleep 10
  fi
done
# ... (summarize) ...
