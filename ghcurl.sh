#!/usr/bin/env bash
if [[ ! $GUARD_GITHUB_TOKEN ]]; then
	echo '$GUARD_GITHUB_TOKEN is not set'
	exit 1
fi

curl \
	-H "Authorization: Bearer $GUARD_GITHUB_TOKEN" \
	-H "Accept: application/vnd.github.v3+json" \
	-s \
	"${@:1}" "https://api.github.com$1"
