#!/usr/bin/env bash

. config.sh
. lib/util.sh
. lib/ghcurl.sh

# validate::repoIsTampered($1: repo) -> bool
#
# repoIsTampered returns true (0) if the given repository within the defined
# organization in config.sh is tampered with.
validate::repoIsTampered() {
	export validate_last_commit=""
	export validate_last_commit_hash=""
	export validate_last_committer_name=""
	export validate_last_commit_is_verified=""

	local repo="$1"
	if validate::repoIsExcluded "$repo"; then
		return $FALSE
	fi

	# Get all the commits that changes the .github folder.
	local ghCommits=$(ghcurl "/repos/$ORG_NAME/${repo}/commits?path=.github")
	# Get the latest commit in the .github folder.
	validate_last_commit=$(jq -r '.[0]' <<< "$ghCommits")
	# Get the commit hash, committer name and whether they're verified.
	validate_last_commit_hash=$(jq -r '.sha' <<< "$validate_last_commit")
	validate_last_commit_hash=${validate_last_commit_hash:0:7}
	validate_last_committer_name=$(jq -r '.commit.committer.name' <<< "$validate_last_commit")
	validate_last_commit_is_verified=$(jq -r '.commit.verification.verified' <<< "$validate_last_commit")

	if [[ "$validate_last_commit" != null ]]; then
		if validate::userIsTrusted "$validate_last_committer_name" && [[ "$validate_last_commit_is_verified" == "true" ]]; then
			return $FALSE
		fi
	fi

	return $TRUE
}

# validate::userIsTrusted($1: user) -> bool
validate::userIsTrusted() {
	local user
	for user in "${TRUSTED_USERS[@]}"; do
		if [[ "$user" == "$1" ]]; then
			return $TRUE
		fi
	done
	return $FALSE
}

# validate::repoIsExcluded($1: repo) -> bool
validate::repoIsExcluded() {
	local repo
	for repo in "${EXCLUDED_REPOS[@]}"; do
		if [[ "$repo" == "$1" ]]; then
			return $TRUE
		fi
	done
	return $FALSE
}
