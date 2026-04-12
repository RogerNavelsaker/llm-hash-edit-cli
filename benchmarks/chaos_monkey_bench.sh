#!/usr/bin/env bash
# chaos_monkey_bench.sh
# Tests LLM agent resilience against "lost updates" and concurrent modifications.
# It injects a line-shifting mutation into the target file while the agent is running.

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
    echo "Dataset directory $DATASET not found!"
    exit 1
fi

SUCCESS=0
TOTAL=0

echo "🐵 Starting Chaos Monkey Benchmark with agent: $AGENT"
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
    
    echo "Running test $(basename "$test_dir") with concurrent mutations..."
    
    # Launch the agent in the background
    $AGENT -p "$PROMPT" > agent_output.log 2>&1 &
    AGENT_PID=$!
    
    # THE CHAOS MONKEY
    # We wait a few seconds (to allow the agent to perform its initial file read),
    # then we inject a line at the top of the target file.
    # This shifts all line numbers down by 1.
    # Standard tools will overwrite the WRONG line.
    # llm-hash-edit will throw a hash mismatch error, forcing the LLM to re-read and recover.
    sleep 4
    TARGET_FILE=$(find . -name "*.rs" -o -name "*.ts" -o -name "*.py" -o -name "*.js" | head -n 1)
    if [ -n "$TARGET_FILE" ] && ps -p $AGENT_PID > /dev/null; then
        echo "  🐵 Chaos Monkey: Injecting shifting comment into $TARGET_FILE!"
        sed -i '1i // CHAOS MONKEY CONCURRENT MUTATION: SHIFTING ALL LINES BY 1' "$TARGET_FILE"
    fi
    
    # Wait for the LLM agent to finish its turn loop
    wait $AGENT_PID
    
    # Verify if the edit was successfully applied to the correct logical location
    if cargo test --quiet > /dev/null 2>&1 || npm test --silent > /dev/null 2>&1 || pytest -q > /dev/null 2>&1; then
      echo "  -> SUCCESS (Recovered from Chaos Monkey!)"
      ((SUCCESS++))
    else
      echo "  -> FAILED (Fell victim to Chaos Monkey)"
    fi
    ((TOTAL++))
  fi
done

if [ $TOTAL -gt 0 ]; then
    echo "Chaos Monkey Hit Rate: $SUCCESS / $TOTAL ($((SUCCESS * 100 / TOTAL))%)"
else
    echo "No tests found in dataset."
fi
