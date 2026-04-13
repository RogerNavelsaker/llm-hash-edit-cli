#!/usr/bin/env bash
set -o errexit; set -o pipefail; set -o nounset

# LOG_LEVEL: 0=Error, 1=Info/Notice/Warning, 2=Debug
: "${LOG_LEVEL:=1}"

readonly RED='\033[0;31m'; readonly GREEN='\033[0;32m'; readonly YELLOW='\033[0;33m'; readonly BLUE='\033[0;34m'; readonly NC='\033[0m'

log() { echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1" >&2; }
error()   { log "${RED}[ERROR]${NC} $1"; exit 1; }
warning() { [[ "$LOG_LEVEL" -ge 1 ]] && log "${YELLOW}[WARN]${NC} $1"; }
notice()  { [[ "$LOG_LEVEL" -ge 1 ]] && log "${BLUE}[NOTICE]${NC} $1"; }
info()    { [[ "$LOG_LEVEL" -ge 1 ]] && log "${GREEN}[INFO]${NC} $1"; }
debug()   { [[ "$LOG_LEVEL" -ge 2 ]] && log "${BLUE}[DEBUG]${NC} $1"; }

print_telemetry() {
    local ms=$1; local tokens=$2; local turns=$3; local success=$4
    local status="${RED}FAILED${NC}"
    [[ "$success" == "1" ]] && status="${GREEN}SUCCESS${NC}"
    log "  [TELEMETRY] Status: $status | Time: $((ms/1000))s | Tokens: $tokens | Turns: $turns"
}
