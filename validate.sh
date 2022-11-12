#!/usr/bin/env bash
set -e # safe mode

. lib/log.sh
. lib/config.sh
. lib/ghcurl.sh
. lib/validate.sh

orgName=$(config::get ".organizationName")

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
	repoPage=1
	jsonOutputs=""

	# Cache outputs.
	mkdir -p output/validate/

	# Try and read our pushed at times.
	# We'll be searching oldTampered a lot, so we put it into an assoc.
	# array so we don't have to do O(n) searches on every single loop.
	declare -A oldTampered
	declare -A lastFetched

	if [[ -f output/validate/last_fetched.json && -f output/validate/tampered.json ]]; then
		lastFetchedJSON=$(< output/validate/last_fetched.json)
		oldTamperedJSON=$(< output/validate/tampered.json)

		while read -d $'\n' -r result; do
			name=$(json::get "$result" ".repo")
			oldTampered["$name"]="$result"
		done < <(jq -rc ".[]" output/validate/tampered.json)

		while read -d $'\n' -r result; do
			name=$(json::get "$result" ".key")
			time=$(json::get "$result" ".value")
			lastFetched["$name"]="$time"
		done < <(jq -rc "to_entries | .[]" output/validate/last_fetched.json)
	fi

	while :; do
		printf -v path "/orgs/%s/repos?per_page=100&page=%d" "$orgName" "$repoPage"
		ghRepos=$(ghcurl "$path")

		filteredNames=()
		numRepos=0

		while read -d $'\n' -r repo; do
			name=$(json::get "$repo" ".name")
			pushedAt=$(json::get "$repo" ".pushed_at")
			numRepos=$[numRepos + 1]

			if ! validate::includeRepo "$name"; then
				log::trace "$name is skipped."
				continue
			fi

			lastPushedAt="${lastFetched["$name"]}"
			lastResult="${oldTampered[$name]}"

			if [[ "$lastResult" != "" && "$lastPushedAt" == "$pushedAt" ]]; then
				log::trace "$name is unchanged, using its cache"
				jsonOutputs+="$lastResult"
			else
				filteredNames+=( "$name" )
				lastFetched["$name"]="$pushedAt"
			fi
		done < <(jq -rc '.[] | {name, pushed_at}' <<< "$ghRepos")

		# Run our workers in parallel and collect the output.
		output=$(parallel -j10 ./validate.sh -- "${filteredNames[@]}")
		jsonOutputs+="$output"$'\n'

		if (( numRepos < 100 )); then
			break
		else
			repoPage=$[ repoPage + 1 ]
		fi
	done

	# Save tampered.json.
	jq -s . <<< "$jsonOutputs" > output/validate/tampered.json

	# Save last_fetched.json.
	for repo in "${!lastFetched[@]}"; do
		json::obj \
			key "$repo" \
			value "${lastFetched[$repo]}"
	done | jq -s 'from_entries' > output/validate/last_fetched.json
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
			last_commit_is_verified,omitempty "$validate_last_commit_is_verified" \
			last_author_id,omitempty "$validate_last_author_id" \
			last_author_name,omitempty "$validate_last_author_name" \
			last_author_avatar_url,omitempty "$validate_last_author_avatar_url"
	else
		log::trace "$repo is not tampered."

		json::obj \
			repo "$repo" \
			org "$orgName" \
			url "https://github.com/$orgName/$repo" \
			tampered false
	fi
}

main "$@"
