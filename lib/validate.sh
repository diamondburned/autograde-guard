#!/usr/bin/env bash

. lib/env.sh
. lib/json.sh
. lib/bool.sh
. lib/config.sh
. lib/ghcurl.sh

__validate_orgName=$(config::get ".organizationName")
config::array_into __trusted_users ".validate.trustedUsers"
config::array_into __validate_included_repos ".validate.includedRepos"
config::array_into __validate_excluded_repos ".validate.excludedRepos"

# validate::repoIsTampered($1: repo) -> bool
#
# repoIsTampered returns true (0) if the given repository within the defined
# organization in config.sh is tampered with.
validate::repoIsTampered() {
	# Clear all of our environment variables so we don't have any
	# lingering variables from previous runs.
	env::clear_prefix validate_last
	env::clear_prefix validate_good

	local repo="$1"
	local path=""
	local page=1
	local foundGoodCommit=$FALSE

	# Always start with this being true, we'll set it to false if we find
	# a good last commit.
	validate_last_commit_is_tampered=$TRUE

	# Get all the commits that changes the .github folder.
	while (( foundGoodCommit == FALSE )); do
		printf -v path \
			"/repos/%s/%s/commits?path=.github&page=%d&per_page=100" \
			"$__validate_orgName" "$repo" "$page"
		local ghCommits=$(ghcurl "$path")
	
		if (( page == 1 )); then
			# Get the latest commit in the .github folder.
			local j=$(json::get "$ghCommits" '.[0]')
			validate_last_commit="$j"
			validate_last_commit_hash=$(json::get "$j" .sha)
			validate_last_author_id=$(json::get "$j" .author.id)
			validate_last_author_name=$(json::get "$j" .author.login)
			validate_last_author_avatar_url=$(json::get "$j" .author.avatar_url)
			validate_last_committer_name=$(json::get "$j" .commit.committer.name)
			validate_last_committer_email=$(json::get "$j" .commit.committer.email)
			validate_last_commit_is_verified=$(json::getb "$j" .commit.verification.verified)

			if validate::commitIsValid "$j"; then
				validate_last_commit_is_tampered=$FALSE
				validate_good_commit="$validate_last_commit"
				validate_good_commit_hash="$validate_last_commit_hash"
				validate_good_author_id="$validate_last_author_id"
				validate_good_author_name="$validate_last_author_name"
				validate_good_author_avatar_url="$validate_last_author_avatar_url"
				validate_good_committer_name="$validate_last_committer_name"
				validate_good_committer_email="$validate_last_committer_email"
				validate_good_commit_is_verified="$validate_last_commit_is_verified"
				break
			fi
		fi

		local count=0
		while read -d $'\n' -r j; do
			count=$[ count + 1 ]

			if ! validate::commitIsValid "$j"; then
				continue
			fi

			validate_good_commit="$j"
			validate_good_commit_hash=$(json::get "$j" .sha)
			validate_good_author_id=$(json::get "$j" .author.id)
			validate_good_author_name=$(json::get "$j" .author.login)
			validate_good_author_avatar_url=$(json::get "$j" .author.avatar_url)
			validate_good_committer_name=$(json::get "$j" .commit.committer.name)
			validate_good_committer_email=$(json::get "$j" .commit.committer.email)
			validate_good_commit_is_verified=$(json::getb "$j" .commit.verification.verified)

			foundGoodCommit=$TRUE
			break
		done < <(json::get "$ghCommits" '.[]')

		if (( count < 100 )); then
			break
		fi

		page=$[page + 1]
	done

	return $validate_last_commit_is_tampered
}

# validate::commitIsValid($1: commit) -> bool
validate::commitIsValid() {
	local committerName="$(json::get "$1" .commit.committer.name)"
	local commitIsVerified="$(json::getb "$1" .commit.verification.verified)"
	local authorID="$(json::get "$1" .author.id)"
	local authorName="$(json::get "$1" .author.login)"

	# Allow signed Git commits with the right author.
	if validate::userIsTrusted "$committerName" && [[ "$commitIsVerified" == true ]]; then
		return $TRUE
	fi

	# Allow GitHub users. We trust GitHub to report this correctly.
	if [[ "$authorID" != "" ]] && validate::userIsTrusted "$authorName"; then
		return $TRUE
	fi

	return $FALSE
}

# validate::userIsTrusted($1: user) -> bool
validate::userIsTrusted() {
	local user
	for user in "${__trusted_users[@]}"; do
		if validate::match "$1" "$user"; then
			return $TRUE
		fi
	done
	return $FALSE
}

# validate::includeRepo($1: repo) -> bool
validate::includeRepo() {
	if (( ${#__validate_included_repos[@]} > 0 )); then
		if ! validate::repoIsIncluded "$1"; then
			return $FALSE
		fi
	fi

	if (( ${#__validate_excluded_repos[@]} > 0 )); then
		if validate::repoIsExcluded "$1"; then
			return $FALSE
		fi
	fi

	return $TRUE
}

validate::repoIsExcluded() {
	local repo
	for repo in "${__validate_excluded_repos[@]}"; do
		if validate::match "$1" "$repo"; then
			return $TRUE
		fi
	done

	return $FALSE
}

validate::repoIsIncluded() {
	local repo
	for repo in "${__validate_included_repos[@]}"; do
		if validate::match "$1" "$repo"; then
			return $TRUE
		fi
	done

	return $FALSE
}

# validate::match($1: str, $2: matcher)
validate::match() {
	if [[ $2 == "/"*"/" ]]; then
		local m="${2%*/}" # Trim the trailing slashes.
		local m="${m#/*}"
		[[ "$1" =~ $m ]]
		return
	else
		[[ "$1" == "$2" ]]
		return
	fi
}
