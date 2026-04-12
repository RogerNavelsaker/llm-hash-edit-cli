#!/usr/bin/env bash
# run_hit_rate_bench.sh
# Requires an external dataset directory with tests (e.g. rust projects with a prompt.txt and a failing test).
# Usage: ./hit_rate_bench.sh --agent "gemini --yolo" --dataset ./dataset [--use-skill]

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

if [ ! -d "$DATASET" ]; then
    echo "Dataset directory $DATASET not found! Please create a dataset with test cases to run."
    exit 1
fi

SUCCESS=0
TOTAL=0

echo "Starting Hit Rate Benchmark with agent: $AGENT"
echo "Skill Enabled: $USE_SKILL"

for test_dir in "$DATASET"/*; do
  if [ -d "$test_dir" ]; then
    WORKSPACE="/tmp/llm_bench_workspace_$(basename "$test_dir")"
    rm -rf "$WORKSPACE"
    cp -r "$test_dir" "$WORKSPACE"
    cd "$WORKSPACE" || exit
    
    PROMPT=$(cat prompt.txt)
    if [ "$USE_SKILL" = true ]; then
      PROMPT="CRITICAL: You MUST use the llm-hash-edit CLI to edit files.\n$PROMPT"
    fi
    
    echo "Running test $(basename "$test_dir")..."
    # Pipe prompt or pass as arg depending on agent
    $AGENT "$PROMPT" > /dev/null 2>&1
    
    if cargo test --quiet > /dev/null 2>&1; then
      echo "  -> SUCCESS"
      ((SUCCESS++))
    else
      echo "  -> FAILED"
    fi
    ((TOTAL++))
  fi
done

if [ $TOTAL -gt 0 ]; then
    echo "Hit Rate: $SUCCESS / $TOTAL ($((SUCCESS * 100 / TOTAL))%)"
else
    echo "No tests found in dataset."
fi
