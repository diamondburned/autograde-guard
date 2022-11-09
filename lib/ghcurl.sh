#!/usr/bin/env bash

. lib/bool.sh
. lib/log.sh

command -v gh &> /dev/null || {
	log "Missing gh. Did you run nix-shell?"
	exit 1
}

ghcurl() {
	GITHUB_TOKEN="$GUARD_GITHUB_TOKEN" gh api "$@"
}
