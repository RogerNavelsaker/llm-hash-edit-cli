#!/usr/bin/env bash
source "$(dirname "$0")/lib_log.sh"

AGENT="gemini --yolo -m gemini-3.1-flash-lite-preview -p"
DATASET="./dataset"
USE_SKILL=false

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --agent) AGENT="$2"; shift ;;
        --dataset) DATASET="$2"; shift ;;
        --use-skill) USE_SKILL=true ;;
    esac
    shift
done

for test_dir in "$DATASET"/*; do
    [ -d "$test_dir" ] || continue
    test_name=$(basename "$test_dir")
    info "Running test: $test_name"
    
    WORKSPACE="/tmp/llm_bench_workspace_$test_name"
    rm -rf "$WORKSPACE" && cp -r "$test_dir" "$WORKSPACE" && cd "$WORKSPACE"
    
    PROMPT=$(cat prompt.txt)
    [[ "$USE_SKILL" == "true" ]] && PROMPT="CRITICAL: You MUST use the llm-hash-edit CLI.\n$PROMPT"
    
    debug "Executing agent command: $AGENT -p '$PROMPT' -o json"
    $AGENT -p "$PROMPT" -o json > session.json 2>&1 || true
    
    ms=0; tokens=0; turns=0; success=0
    if jq -e . session.json >/dev/null 2>&1; then
        ms=$(jq -r '.duration_ms // 0' session.json)
        tokens=$(jq -r '.usage.total_token_count // 0' session.json)
        turns=$(jq -r '.turns | length // 0' session.json)
    fi
    
    if cargo test --quiet > /dev/null 2>&1; then success=1; fi
    print_telemetry "$ms" "$tokens" "$turns" "$success"
done
