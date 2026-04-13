#!/usr/bin/env bash
set -o errexit; set -o pipefail; set -o nounset
[[ "${TRACE-0}" == "1" ]] && set -o xtrace

readonly RED='\033[0;31m'; readonly GREEN='\033[0;32m'; readonly YELLOW='\033[0;33m'; readonly BLUE='\033[0;34m'; readonly NC='\033[0m'

log() { echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1" >&2; }
info() { log "${GREEN}[INFO]${NC} $1"; }
debug() { log "${BLUE}[DEBUG]${NC} $1"; }
notice() { log "${BLUE}[NOTICE]${NC} $1"; }
warning() { log "${YELLOW}[WARN]${NC} $1"; }
error() { log "${RED}[ERROR]${NC} $1"; exit 1; }

print_telemetry() {
    local ms=$1; local tokens=$2; local turns=$3; local success=$4
    local status="${RED}FAILED${NC}"
    [[ "$success" == "1" ]] && status="${GREEN}SUCCESS${NC}"
    log "  [TELEMETRY] Status: $status | Time: $((ms/1000))s | Tokens: $tokens | Turns: $turns"
}
