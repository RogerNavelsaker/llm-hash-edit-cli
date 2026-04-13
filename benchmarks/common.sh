#!/usr/bin/env bash
source "$(dirname "$0")/../../bash-boilerplate/core.sh"

print_telemetry() {
    local ms=$1; local tokens=$2; local turns=$3; local success=$4
    local status="FAILED"
    [[ "$success" == "1" ]] && status="SUCCESS"
    info "  [TELEMETRY] Status: $status | Time: $((ms/1000))s | Tokens: $tokens | Turns: $turns"
}
