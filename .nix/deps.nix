{ pkgs }:

with pkgs; [
	bash
	curl
	coreutils
	jq
	moreutils # for parallel
	gomplate
	taplo-cli
]
