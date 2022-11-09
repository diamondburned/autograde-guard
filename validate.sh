#!/usr/bin/env bash
set -e # safe mode

. lib/config.sh
. lib/ghcurl.sh
. lib/validate.sh

main() {
	orgName=$(config::get ".organizationName")
	jsonOutputs=()

	# Cache outputs.
	mkdir -p output/validate/
	:> output/validate/tampered.txt
	:> output/validate/tampered.json

	while :; do
		local path
		local page=0

		printf -v path "/orgs/%s/repos?per_page=100&page=%d" "$orgName" "$page"
		ghRepos=$(ghcurl "$path")

		IFS=$'\n' repoNames=( $(jq -r '.[].name' <<< "$ghRepos") )
		for repo in "${repoNames[@]}"; do
			validateRepo "$repo"
		done

		if (( ${#repoNames_[@]} < 100 )); then
			break
		fi
	done

	# Join all our objects into a single JSON array.
	printf "%s\n" "${jsonOutputs[@]}" | jq -s . > output/validate/tampered.json
}

validateRepo() {
	local repo="$1"

	if ! validate::includeRepo "$repo"; then
		return
	fi

	local j
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

		echo "$repo is tampered ($extraMessage)."
		echo "$repo" >> output/validate/tampered.txt

		j=$(json::obj \
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
			last_author_avatar_url,omitempty "$validate_last_author_avatar_url")
	else
		j=$(json::obj \
			repo "$repo" \
			org "$orgName" \
			url "https://github.com/$orgName/$repo" \
			tampered false)
	fi
	jsonOutputs+=( "$j" )
}

main "$@"
