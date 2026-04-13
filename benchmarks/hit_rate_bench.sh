#!/usr/bin/env bash
source "$(dirname "$0")/../bash-boilerplate/lib/log.sh"
: "${LOG_LEVEL:=1}"

AGENT="gemini --yolo -m gemini-3.1-flash-lite-preview -p"
DATASET="./dataset"
USE_SKILL=false

usage() { echo "Usage: ${0##*/} [--agent AGENT] [--dataset PATH] [--use-skill] [-v|--verbose]"; }

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --agent) AGENT="$2"; shift ;;
        --dataset) DATASET="$2"; shift ;;
        --use-skill) USE_SKILL=true ;;
        -v|--verbose) export TRACE=1; set -o xtrace ;;
        *) usage; exit 1 ;;
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
    [[ "$USE_SKILL" == "true" ]] && PROMPT="CRITICAL: Use llm-hash-edit CLI.\n$PROMPT"
    
    debug "Command: $AGENT -p '$PROMPT' -o json"
    $AGENT -p "$PROMPT" -o json > session.json 2>&1 || warning "Agent execution returned non-zero"
    
    ms=0; tokens=0; turns=0; success=0
    if jq -e . session.json >/dev/null 2>&1; then
        ms=$(jq -r '.duration_ms // 0' session.json)
        tokens=$(jq -r '.usage.total_token_count // 0' session.json)
        turns=$(jq -r '.turns | length // 0' session.json)
        debug "Telemetry: ms=$ms, tokens=$tokens, turns=$turns"
    else
        error "Agent output is not valid JSON. Check session.json for errors."
    fi
    
    if cargo test --quiet > /dev/null 2>&1; then 
        success=1
        notice "Test $test_name: PASSED"
    else 
        warning "Test $test_name: FAILED"
    fi
    print_telemetry "$ms" "$tokens" "$turns" "$success"
done
