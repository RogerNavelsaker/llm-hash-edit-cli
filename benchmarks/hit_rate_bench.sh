#!/usr/bin/env bash
AGENT="gemini --yolo"
DATASET="./dataset"
USE_SKILL=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --agent) AGENT="$2"; shift ;;
        --dataset) DATASET="$2"; shift ;;
        --use-skill) USE_SKILL=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

SUCCESS=0
TOTAL=0
TOTAL_MS=0
TOTAL_TOKENS=0
TOTAL_TURNS=0

for test_dir in "$DATASET"/*; do
  if [ -d "$test_dir" ]; then
    WORKSPACE="/tmp/llm_bench_workspace_$(basename "$test_dir")"
    rm -rf "$WORKSPACE" && cp -r "$test_dir" "$WORKSPACE" && cd "$WORKSPACE"
    
    PROMPT=$(cat prompt.txt)
    if [ "$USE_SKILL" = true ]; then PROMPT="CRITICAL: You MUST use the llm-hash-edit CLI.\n$PROMPT"; fi
    
    $AGENT -p "$PROMPT" -o json > session.json 2>&1
    
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

if [ $TOTAL -gt 0 ]; then
    echo "Hit Rate: $SUCCESS / $TOTAL, Avg Time: $((TOTAL_MS / TOTAL / 1000))s, Avg Tokens: $((TOTAL_TOKENS / TOTAL)), Avg Turns: $((TOTAL_TURNS / TOTAL))"
fi
