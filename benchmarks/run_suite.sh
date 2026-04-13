#!/usr/bin/env bash
# Centralized Benchmark Suite Runner
# Edit the variables below to change models or datasets globally

AGENT="gemini --yolo -m gemini-3.1-flash-lite-preview -p"
DATASET="/home/rona/.gemini/tmp/fleet/dataset"
RESULTS_FILE="suite_results.log"

echo "=== Benchmark Suite Started: $(date) ===" > "$RESULTS_FILE"
echo "Agent: $AGENT" >> "$RESULTS_FILE"
echo "---------------------------------------" >> "$RESULTS_FILE"

run_bench() {
    local name=$1
    local script=$2
    local extra=$3
    echo "--- $name ---" | tee -a "$RESULTS_FILE"
    ./$script --agent "$AGENT" --dataset "$DATASET" $extra >> "$RESULTS_FILE" 2>&1
}

# Run the three suites
run_bench "GEMINI CONTROL" "hit_rate_bench.sh" ""
run_bench "GEMINI SKILL" "hit_rate_bench.sh" "--use-skill"
run_bench "GEMINI CHAOS" "chaos_monkey_bench.sh" "--use-skill"

echo "---------------------------------------" >> "$RESULTS_FILE"
echo "=== Suite Finished: $(date) ===" >> "$RESULTS_FILE"

cat "$RESULTS_FILE"
