#!/usr/bin/env bash
TRUSTED_USERS=( diamondburned )
ORG_NAME="diamondburned-testorg"

set -e # safe mode

main() {
	ghRepos=$(ghcurl "/orgs/$ORG_NAME/repos")
	IFS=$'\n' repoNames=(
		$(jq -r '.[].name | select(. != "autograder")' <<< "$ghRepos")
	)

	for repo in "${repoNames[@]}"; do
		# Get all the commits that changes the .github folder.
		ghCommits=$(ghcurl "/repos/$ORG_NAME/${repo}/commits?path=.github")
		# Get the latest commit in the .github folder.
		lastCommit=$(jq -r '.[0]' <<< "$ghCommits")
		# Get the commit hash, committer name and whether they're verified.
		lastCommitHash=$(jq -r '.sha' <<< "$lastCommit")
		lastCommitHash=${lastCommitHash:0:7}
		lastCommitterName=$(jq -r '.commit.committer.name' <<< "$lastCommit")
		lastCommitIsVerified=$(jq -r '.commit.verification.verified' <<< "$lastCommit")

		if [[ "$lastCommitterName" == "GitHub" && "$lastCommitIsVerified" == "true" ]]; then
			continue
		fi

		extraMessage=""
		if [[ "$lastCommit" == null ]]; then
			extraMessage="no .github folder"
		else
			printf -v extraMessage \
				"commit %s by %s" \
				"$lastCommitHash" "$lastCommitterName"
		fi

		echo "$repo is tampered with ($extraMessage)"
	done
}

isTrusted() {
	for user in "${TRUSTED_USERS[@]}"; do
		if [[ "$user" == "$1" ]]; then
			return 0
		fi
	done
	return 1
}

alias ghcurl="./ghcurl.sh"
main "$@"
