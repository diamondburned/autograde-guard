#!/usr/bin/env bash

. lib/bool.sh

ghcurl() {
	if [[ ! $GUARD_GITHUB_TOKEN ]]; then
		echo '$GUARD_GITHUB_TOKEN is not set'
		exit $FALSE
	fi
	
	curl \
		-H "Authorization: Bearer $GUARD_GITHUB_TOKEN" \
		-H "Accept: application/vnd.github.v3+json" \
		-s \
		"${@:1}" "https://api.github.com$1"
}
