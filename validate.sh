#!/usr/bin/env bash
set -e # safe mode

. config.sh
. lib/ghcurl.sh
. lib/validate.sh

main() {
	ghRepos=$(ghcurl "/orgs/$ORG_NAME/repos")
	IFS=$'\n' repoNames=( $(jq -r '.[].name' <<< "$ghRepos") )

	# Cache outputs.
	mkdir -p output/validate/

	for repo in "${repoNames[@]}"; do
		if validate::repoIsTampered "$repo"; then
			local extraMessage=""

			if [[ "${validate_last_commit}" == null ]]; then
				extraMessage="no .github folder"
			else
				printf -v extraMessage \
					"commit %s by %s" \
					"${validate_last_commit_hash}" \
					"${validate_last_committer_name} <${validate_last_cmm}>"
			fi

			echo "$repo is tampered ($extraMessage)."
			echo "$repo" >> output/validate/tampered.txt
		fi
	done
}

main "$@"
