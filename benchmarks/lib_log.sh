#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091

### Dependencies
# Expected by bash-boilerplate
readonly LOG_FILE="${LOG_FILE:-/dev/null}"
readonly LOG_LEVEL="${LOG_LEVEL:-1}"

### Colors
readonly RED='\033[0;31m'; readonly GREEN='\033[0;32m'; readonly YELLOW='\033[0;33m'; readonly BLUE='\033[0;34m'; readonly NC='\033[0m'

### Logging Helpers
log() { echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1" >&2; }
info() { [[ "$LOG_LEVEL" -ge 1 ]] && log "${GREEN}[INFO]${NC} $1"; }
debug() { [[ "$LOG_LEVEL" -ge 2 ]] && log "${BLUE}[DEBUG]${NC} $1"; }
notice() { [[ "$LOG_LEVEL" -ge 1 ]] && log "${BLUE}[NOTICE]${NC} $1"; }
warning() { [[ "$LOG_LEVEL" -ge 1 ]] && log "${YELLOW}[WARN]${NC} $1"; }
error() { log "${RED}[ERROR]${NC} $1"; exit 1; }

print_telemetry() {
    local ms=$1; local tokens=$2; local turns=$3; local success=$4
    local status="${RED}FAILED${NC}"
    [[ "$success" == "1" ]] && status="${GREEN}SUCCESS${NC}"
    log "  [TELEMETRY] Status: $status | Time: $((ms/1000))s | Tokens: $tokens | Turns: $turns"
}
