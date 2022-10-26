#!/usr/bin/env bash
set -e

. lib/config.sh
. lib/ghcurl.sh
. lib/validate.sh

main() {
	[[ ! -f output/validate/tampered.txt ]] && ./validate.sh

	IFS=$'\n' tamperedRepos=( $(< output/validate/tampered.txt) )
	for repo in "${repoNames[@]}"; do
		rollback_repo "$repo"
	done
}

# rollback_repo(repo)
#
# rollback_repo rolls back the state of .github to the last known good state. It
# does this by making a new commit under its own user, signed by the PAT user.
#
# Methodology
#
# GitHub-only solution:
#
#    1. find the last working commit
#    2. get the tree with that commit sha
#    3. filter all our files that are within .github from the tree
#    4. make a new tree the latest commit for the base tree and the filtered
#       tree included in .tree
#    5. make a new commit with the new tree and the latest commit as parent,
#       don't forget to set the right author
#
# Things to consider:
#
#    - Do we support SSH keys? We can't do that w/ this method.
#    - Do we sign ourselves? GitHub should be doing that for us.
#
# Pros:
#
#    - No Git needed
#    - No fiddling with PATs (this is probably a HUGE one)
#    - No filesystem access needed
#
# Cons:
#
#    - Probably very slow (API-based)
#    - Requires a lot of API calls
#    - GitHub-specific
#
rollback_repo() {
	local repo="$1"
	local work=$(mktemp -d "tmp.rollback.XXXXXXXXX")

	git clone -o "$work" --depth 1 "https://github.com/${ORG_NAME}/${repo}.git"
	cd "$work"

	git fetch


}


main "$@"
