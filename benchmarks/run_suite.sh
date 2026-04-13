#!/usr/bin/env bash

# ==============================================================================
# Benchmarking Suite Runner
# ==============================================================================

### Global Environment Settings
set -o errexit
set -o pipefail
set -o nounset

# Default settings
AGENT="gemini --yolo -m gemini-3.1-flash-lite-preview -p"
DATASET="/home/rona/.gemini/tmp/fleet/dataset"
RESULTS_FILE="suite_results.log"

usage() {
    echo "Usage: ${0##*/} [options]"
    echo "  -a, --agent AGENT      Set the agent command"
    echo "  -d, --dataset PATH     Set the dataset path"
    echo "  -o, --output FILE      Set the output log file"
    echo "  -v, --verbose          Enable trace output"
    echo "  -h, --help             Show this help"
}

### Parse Arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -a|--agent) AGENT="$2"; shift ;;
        -d|--dataset) DATASET="$2"; shift ;;
        -o|--output) RESULTS_FILE="$2"; shift ;;
        -v|--verbose) set -o xtrace ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "Unknown option: $1" >&2; usage; exit 1 ;;
        *) break ;;
    esac
    shift
done

echo "=== Benchmark Suite Started: $(date) ===" | tee "$RESULTS_FILE"
echo "Agent: $AGENT" >> "$RESULTS_FILE"

run_bench() {
    local name=$1
    local script=$2
    local extra=$3
    echo -e "\n--- $name ---" | tee -a "$RESULTS_FILE"
    ./"$script" --agent "$AGENT" --dataset "$DATASET" $extra >> "$RESULTS_FILE" 2>&1
}

# Execution
run_bench "GEMINI CONTROL" "hit_rate_bench.sh" ""
run_bench "GEMINI SKILL" "hit_rate_bench.sh" "--use-skill"
run_bench "GEMINI CHAOS" "chaos_monkey_bench.sh" "--use-skill"

echo -e "\n=== Suite Finished: $(date) ===" | tee -a "$RESULTS_FILE"
