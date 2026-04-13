#!/usr/bin/env bash
source "$(dirname "$0")/lib_log.sh"

AGENT="gemini --yolo -m gemini-3.1-flash-lite-preview -p"
DATASET="/home/rona/.gemini/tmp/fleet/dataset"
RESULTS_FILE="suite_results.log"
export LOG_LEVEL=1

usage() { echo "Usage: ${0##*/} [-l|--loglevel 0|1|2]"; exit 1; }

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -l|--loglevel) export LOG_LEVEL="$2"; shift ;;
        *) break ;;
    esac
    shift
done

info "Suite started (LogLevel: $LOG_LEVEL)"
run_bench() {
    local name="$1"; local script="$2"; local extra="$3"
    info "Starting: $name"
    # Propagate LOG_LEVEL and AGENT
    LOG_LEVEL=$LOG_LEVEL ./$script --agent "$AGENT" --dataset "$DATASET" $extra >> "$RESULTS_FILE" 2>&1
}

run_bench "GEMINI CONTROL" "hit_rate_bench.sh" ""
run_bench "GEMINI SKILL" "hit_rate_bench.sh" "--use-skill"
run_bench "GEMINI CHAOS" "chaos_monkey_bench.sh" "--use-skill"
info "Done."
