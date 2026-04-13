#!/usr/bin/env bash
source "$(dirname "$0")/lib_log.sh"

# If user provided -v, set TRACE for subshells
if [[ "${1:-}" == "-v" ]] || [[ "${1:-}" == "--verbose" ]]; then
    export TRACE=1
    set -o xtrace
fi

AGENT="gemini --yolo -m gemini-3.1-flash-lite-preview -p"
DATASET="/home/rona/.gemini/tmp/fleet/dataset"
RESULTS_FILE="suite_results.log"

info "Starting suite..."

run_bench() {
    local name="$1"; local script="$2"; local extra="$3"
    info "Starting: $name"
    # Pass TRACE if it's set
    local trace_arg=""
    [[ "${TRACE-0}" == "1" ]] && trace_arg="-v"
    
    ./"$script" --agent "$AGENT" --dataset "$DATASET" $extra $trace_arg
}

run_bench "GEMINI CONTROL" "hit_rate_bench.sh" ""
run_bench "GEMINI SKILL" "hit_rate_bench.sh" "--use-skill"
run_bench "GEMINI CHAOS" "chaos_monkey_bench.sh" "--use-skill"

info "All benchmarks done."
