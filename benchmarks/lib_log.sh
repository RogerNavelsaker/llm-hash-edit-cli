#!/usr/bin/env bash

# Standardized logging and boilerplate
set -o errexit
set -o pipefail
set -o nounset
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log() { echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1" >&2; }
info() { log "${GREEN}[INFO]${NC} $1"; }
debug() { [[ "${TRACE-0}" == "1" ]] && log "${BLUE}[DEBUG]${NC} $1"; }
notice() { log "${BLUE}[NOTICE]${NC} $1"; }
warning() { log "${YELLOW}[WARN]${NC} $1"; }
error() { log "${RED}[ERROR]${NC} $1"; exit 1; }
critical() { log "${RED}[CRITICAL]${NC} $1"; exit 1; }
