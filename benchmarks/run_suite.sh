#!/usr/bin/env bash
source "$(dirname "$0")/lib_log.sh"

AGENT="gemini --yolo -m gemini-3.1-flash-lite-preview -p"
DATASET="/home/rona/.gemini/tmp/fleet/dataset"
RESULTS_FILE="suite_results.log"

usage() {
    echo "Usage: ${0##*/} [options]"
    echo "  -v, --verbose  Enable trace output"
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -v|--verbose) export TRACE=1; set -o xtrace ;;
        *) break ;;
    esac
    shift
done

info "Starting suite..."
echo "=== Start: $(date) ===" > "$RESULTS_FILE"

run_bench() {
    local name="$1"; local script="$2"; local extra="$3"
    info "Starting: $name"
    echo -e "\n--- $name ---" >> "$RESULTS_FILE"
    ./"$script" --agent "$AGENT" --dataset "$DATASET" $extra >> "$RESULTS_FILE" 2>&1
    notice "Finished: $name"
}

run_bench "GEMINI CONTROL" "hit_rate_bench.sh" ""
run_bench "GEMINI SKILL" "hit_rate_bench.sh" "--use-skill"
run_bench "GEMINI CHAOS" "chaos_monkey_bench.sh" "--use-skill"

info "All benchmarks done."
