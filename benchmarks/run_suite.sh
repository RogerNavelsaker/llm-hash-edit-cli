#!/usr/bin/env bash

# ==============================================================================
# Benchmarking Suite Runner
# Inspired by: https://github.com/ralish/bash-script-template
# ==============================================================================

# Enable strict mode
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

# Default settings
AGENT="gemini --yolo -m gemini-3.1-flash-lite-preview -p"
DATASET="/home/rona/.gemini/tmp/fleet/dataset"
RESULTS_FILE="suite_results.log"

usage() {
    echo "Usage: $0 [options]"
    echo "  -a, --agent AGENT      Set the agent command"
    echo "  -d, --dataset PATH     Set the dataset path"
    echo "  -o, --output FILE      Set the output log file"
    echo "  -v, --verbose          Enable trace output"
    echo "  -h, --help             Show this help"
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -a|--agent) AGENT="$2"; shift ;;
        -d|--dataset) DATASET="$2"; shift ;;
        -o|--output) RESULTS_FILE="$2"; shift ;;
        -v|--verbose) export TRACE=1; set -o xtrace ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

echo "=== Benchmark Suite Started: $(date) ===" | tee "$RESULTS_FILE"
echo "Agent: $AGENT" | tee -a "$RESULTS_FILE"

run_bench() {
    local name=$1
    local script=$2
    local extra=$3
    echo -e "\n--- $name ---" | tee -a "$RESULTS_FILE"
    ./$script --agent "$AGENT" --dataset "$DATASET" $extra >> "$RESULTS_FILE" 2>&1
}

# Run the three suites
run_bench "GEMINI CONTROL" "hit_rate_bench.sh" ""
run_bench "GEMINI SKILL" "hit_rate_bench.sh" "--use-skill"
run_bench "GEMINI CHAOS" "chaos_monkey_bench.sh" "--use-skill"

echo -e "\n=== Suite Finished: $(date) ===" | tee -a "$RESULTS_FILE"
