#!/usr/bin/env bash
# chaos_monkey_bench.sh

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
TOTAL_MS=0
TOTAL_TOKENS=0
TOTAL_TURNS=0

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
    
    # Launch the agent in the background with -o json
    $AGENT -p "$PROMPT" -o json > session.json 2>&1 &
    AGENT_PID=$!
    
    # Chaos Monkey: Wait for initial read then mutate
    sleep 4
    TARGET_FILE=$(find . -name "*.rs" -o -name "*.ts" -o -name "*.py" -o -name "*.js" | head -n 1)
    if [ -n "$TARGET_FILE" ] && ps -p $AGENT_PID > /dev/null; then
        echo "  🐵 Chaos Monkey: Injecting shifting comment into $TARGET_FILE!"
        sed -i '1i // CHAOS MONKEY CONCURRENT MUTATION: SHIFTING ALL LINES BY 1' "$TARGET_FILE"
    fi
    
    wait $AGENT_PID
    
    # Parse telemetry
    if [ -f session.json ]; then
        MS=$(jq -r '.duration_ms // 0' session.json)
        TOKENS=$(jq -r '.usage.total_token_count // 0' session.json)
        TURNS=$(jq -r '.turns | length // 0' session.json)
        
        TOTAL_MS=$((TOTAL_MS + MS))
        TOTAL_TOKENS=$((TOTAL_TOKENS + TOKENS))
        TOTAL_TURNS=$((TOTAL_TURNS + TURNS))
    fi
    
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
    echo "------------------------------------------------"
    echo "Chaos Monkey Results:"
    echo "Hit Rate: $SUCCESS / $TOTAL ($((SUCCESS * 100 / TOTAL))%)"
    echo "Avg Time: $((TOTAL_MS / TOTAL / 1000))s ($((TOTAL_MS / TOTAL))ms)"
    echo "Avg Tokens: $((TOTAL_TOKENS / TOTAL))"
    echo "Avg Turns: $((TOTAL_TURNS / TOTAL))"
    echo "------------------------------------------------"
else
    echo "No tests found in dataset."
fi
