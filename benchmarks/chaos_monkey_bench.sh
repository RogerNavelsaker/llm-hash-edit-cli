#!/usr/bin/env bash
source "$(dirname "$0")/lib_log.sh"
: "${LOG_LEVEL:=1}"

AGENT="gemini --yolo -m gemini-3.1-flash-lite-preview -p"
DATASET="./dataset"
USE_SKILL=true

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --agent) AGENT="$2"; shift ;;
        --dataset) DATASET="$2"; shift ;;
        -v|--verbose) export TRACE=1; set -o xtrace ;;
        *) break ;;
    esac
    shift
done

for test_dir in "$DATASET"/*; do
    [ -d "$test_dir" ] || continue
    test_name=$(basename "$test_dir")
    info "Running Chaos Monkey test: $test_name"
    
    WORKSPACE="/tmp/llm_bench_workspace_$test_name"
    rm -rf "$WORKSPACE" && cp -r "$test_dir" "$WORKSPACE" && cd "$WORKSPACE"
    
    PROMPT="CRITICAL: Use llm-hash-edit CLI.\n$(cat prompt.txt)"
    $AGENT -p "$PROMPT" -o json > session.json 2>&1 &
    AGENT_PID=$!
    
    sleep 4
    TARGET=$(find . -name "*.rs" | head -n 1)
    if [ -n "$TARGET" ]; then
        info "Chaos Monkey: Injecting mutation into $TARGET"
        sed -i '1i // CHAOS MONKEY' "$TARGET"
    fi
    
    wait $AGENT_PID
    
    ms=0; tokens=0; turns=0; success=0
    if jq -e . session.json >/dev/null 2>&1; then
        ms=$(jq -r '.duration_ms // 0' session.json)
        tokens=$(jq -r '.usage.total_token_count // 0' session.json)
        turns=$(jq -r '.turns | length // 0' session.json)
    fi
    
    if cargo test --quiet > /dev/null 2>&1; then 
        success=1
        notice "Test $test_name: PASSED (Recovered)"
    else 
        warning "Test $test_name: FAILED (Lost update)"
    fi
    print_telemetry "$ms" "$tokens" "$turns" "$success"
done
