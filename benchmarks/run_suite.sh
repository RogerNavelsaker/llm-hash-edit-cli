#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/common.sh"

AGENT="gemini --yolo -m gemini-3.1-flash-lite-preview -p"
DATASET="/home/rona/.gemini/tmp/fleet/dataset"
RESULTS_FILE="suite_results.log"

run_bench() {
    local script="$1"; local extra="$2"
    ./"$script" --agent "$AGENT" --dataset "$DATASET" $extra >> "$RESULTS_FILE" 2>&1
}

main() {
    info "Benchmark suite initialized."
    echo "=== Benchmark Suite Started: $(date) ===" > "$RESULTS_FILE"
    
    run_bench "hit_rate_bench.sh" ""
    run_bench "hit_rate_bench.sh" "--use-skill"
    run_bench "chaos_monkey_bench.sh" "--use-skill"
    
    info "Benchmarks finished. Results: $RESULTS_FILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
