#!/usr/bin/env bash

# Source the boilerplate components
source "$(dirname "$0")/lib_log.sh"

# Default configuration
AGENT="gemini --yolo -m gemini-3.1-flash-lite-preview -p"
DATASET="/home/rona/.gemini/tmp/fleet/dataset"
RESULTS_FILE="suite_results.log"

run_bench() {
    local name="$1"; local script="$2"; local extra="$3"
    info "Starting: $name"
    echo -e "\n--- $name ---" >> "$RESULTS_FILE"
    ./"$script" --agent "$AGENT" --dataset "$DATASET" $extra >> "$RESULTS_FILE" 2>&1
    notice "Finished: $name"
}

main() {
    info "Benchmark suite initialized."
    echo "=== Benchmark Suite Started: $(date) ===" > "$RESULTS_FILE"
    
    run_bench "GEMINI CONTROL" "hit_rate_bench.sh" ""
    run_bench "GEMINI SKILL" "hit_rate_bench.sh" "--use-skill"
    run_bench "GEMINI CHAOS" "chaos_monkey_bench.sh" "--use-skill"
    
    info "All benchmarks finished."
}

# Execute main
main "$@"
