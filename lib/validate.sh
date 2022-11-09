#!/usr/bin/env bash

. lib/json.sh
. lib/bool.sh
. lib/config.sh
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
	if ! validate::includeRepo "$repo"; then
		return $FALSE
	fi

	local orgName=$(config::get ".organizationName")

	# Get all the commits that changes the .github folder.
	local ghCommits=$(ghcurl "/repos/${orgName}/${repo}/commits?path=.github")

	# Get the latest commit in the .github folder.
	validate_last_commit_json=$(jq '.[0]' <<< "$ghCommits")
	if [[ "$validate_last_commit_json" == "null" ]]; then
		validate_last_commit=
	else
		validate_last_commit=$(jq -r '.' <<< "$validate_last_commit_json")
	fi
	local j=$validate_last_commit

	# Get the commit hash, committer name and whether they're verified.
	validate_last_commit_hash=$(json::get "$j" .sha)
	validate_last_commit_hash=${validate_last_commit_hash:0:7}
	validate_last_author_id=$(json::get "$j" .author.id)
	validate_last_author_name=$(json::get "$j" .author.login)
	validate_last_author_avatar_url=$(json::get "$j" .author.avatar_url)
	validate_last_committer_name=$(json::get "$j" .commit.committer.name)
	validate_last_committer_email=$(json::get "$j" .commit.committer.email)
	validate_last_commit_is_verified=$(json::get "$j" .commit.verification.verified)

	if [[ "$validate_last_commit" != null ]]; then
		if validate::userIsTrusted "$validate_last_committer_name" && [[ "$validate_last_commit_is_verified" == "true" ]]; then
			return $FALSE
		fi
	fi

	return $TRUE
}

# validate::userIsTrusted($1: user) -> bool
validate::userIsTrusted() {
	config::array_into __trusted_users ".validate.trustedUsers"
	local user
	for user in "${__trusted_users[@]}"; do
		if [[ "$1" == $user ]]; then
			return $TRUE
		fi
	done
	return $FALSE
}

config::array_into __validate_included_repos ".validate.includedRepos"
config::array_into __validate_excluded_repos ".validate.excludedRepos"

# validate::includeRepo($1: repo) -> bool
validate::includeRepo() {
	if (( ${#__validate_included_repos[@]} > 0 )); then
		if ! validate::repoIsIncluded "$1"; then
			return $FALSE
		fi
	fi

	if (( ${#__validate_excluded_repos[@]} == 0 )); then
		if validate::repoIsExcluded "$1"; then
			return $FALSE
		fi
	fi

	return $TRUE
}

validate::repoIsExcluded() {
	local repo
	for repo in "${__validate_excluded_repos[@]}"; do
		if [[ "$1" == $repo ]]; then
			return $TRUE
		fi
	done

	return $FALSE
}

validate::repoIsIncluded() {
	local repo
	for repo in "${__validate_included_repos[@]}"; do
		if [[ "$1" == $repo ]]; then
			return $TRUE
		fi
	done

	return $FALSE
}
