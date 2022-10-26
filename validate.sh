#!/usr/bin/env bash
set -e # safe mode

. lib/config.sh
. lib/ghcurl.sh
. lib/validate.sh

main() {
	orgName=$(config::get ".organizationName")

	ghRepos=$(ghcurl "/orgs/$orgName/repos")
	IFS=$'\n' repoNames=( $(jq -r '.[].name' <<< "$ghRepos") )

	# Cache outputs.
	mkdir -p output/validate/
	echo > output/validate/tampered.txt
	echo > output/validate/tampered.json
	jsonOutputs=()

	for repo in "${repoNames[@]}"; do
		if validate::repoIsExcluded "$repo"; then
			continue
		fi

		local j
		if validate::repoIsTampered "$repo"; then
			local extraMessage=""

			if [[ "${validate_last_commit}" == null ]]; then
				extraMessage="no .github folder"
			else
				printf -v extraMessage \
					"commit %s by %s" \
					"${validate_last_commit_hash}" \
					"${validate_last_committer_name} <${validate_last_committer_email}>"
			fi

			echo "$repo is tampered ($extraMessage)."
			echo "$repo" >> output/validate/tampered.txt

			# Don't make nulls strings.
			jarg=--arg
			[[ "$validate_last_commit_hash" == null ]] && jarg=--argjson
			
			j=$(jq --null-input \
				--arg "repo" "$repo" \
				--arg "org" "$orgName" \
				--arg "url" "https://github.com/$orgName/$repo" \
				--argjson "tampered" "true" \
				$jarg "last_sha" "$validate_last_commit_hash" \
				$jarg "last_author_name" "$validate_last_committer_name" \
				$jarg "last_author_email" "$validate_last_committer_email" \
				--argjson "last_is_verified" "$validate_last_commit_is_verified" \
				'{$repo, $org, $url, $tampered, $last_sha, $last_author_name, $last_author_email, $last_is_verified}')
		else
			j=$(jq --null-input \
				--arg "repo" "$repo" \
				--arg "org" "$orgName" \
				--arg "url" "https://github.com/$orgName/$repo" \
				--argjson "tampered" "false" \
				'{$repo, $org, $url, $tampered}')
		fi
		jsonOutputs+=( "$j" )
	done

	# Join all our objects into a single JSON array.
	printf "%s\n" "${jsonOutputs[@]}" | jq -s . > output/validate/tampered.json
}

main "$@"
