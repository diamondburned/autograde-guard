#!/usr/bin/env bash
set -e # safe mode

. lib/log.sh
. lib/config.sh
. lib/ghcurl.sh
. lib/validate.sh

main() {
	if (( $# == 0 )); then
		validateAll
		return
	fi

	for repo in "$@"; do
		validateRepo "$repo"
	done
}

validateAll() {
	orgName=$(config::get ".organizationName")
	repoPage=1
	jsonOutputs=""

	# Cache outputs.
	mkdir -p output/validate/
	:> output/validate/tampered.json

	while :; do
		local path
		printf -v path "/orgs/%s/repos?per_page=100&page=%d" "$orgName" "$repoPage"

		ghRepos=$(ghcurl "$path")

		IFS=$'\n' repoNames=( $(jq -r '.[].name' <<< "$ghRepos") )
		filteredNames=()
		for repo in "${repoNames[@]}"; do
			if validate::includeRepo "$repo"; then
				filteredNames+=( "$repo" )
			else
				log "$repo is skipped."
			fi
		done

		output=$(parallel -j4 ./validate.sh -- "${filteredNames[@]}")
		jsonOutputs+="$output"$'\n'

		if (( ${#repoNames[@]} < 100 )); then
			break
		else
			repoPage=$[ repoPage + 1 ]
		fi
	done

	# Join all our objects into a single JSON array.
	jq -s . > output/validate/tampered.json <<< "$jsonOutputs"
}

validateRepo() {
	local repo="$1"
	if validate::repoIsTampered "$repo"; then
		local extraMessage=""
		if [[ "${validate_last_commit}" ]]; then
			printf -v extraMessage \
				"commit %s by %s" \
				"${validate_last_commit_hash}" \
				"${validate_last_committer_name} <${validate_last_committer_email}>"
		else
			extraMessage="no .github folder"
		fi

		log "$repo is tampered ($extraMessage)."

		json::obj \
			repo "$repo" \
			org "$orgName" \
			url "https://github.com/$orgName/$repo" \
			tampered true \
			last_commit "$validate_last_commit_hash" \
			last_committer_name,omitempty "$validate_last_committer_name" \
			last_committer_email,omitempty "$validate_last_committer_email" \
			last_commit_is_verified "$validate_last_commit_is_verified" \
			last_author_id,omitempty "$validate_last_author_id" \
			last_author_name,omitempty "$validate_last_author_name" \
			last_author_avatar_url,omitempty "$validate_last_author_avatar_url"
	else
		json::obj \
			repo "$repo" \
			org "$orgName" \
			url "https://github.com/$orgName/$repo" \
			tampered false
	fi
}

main "$@"
