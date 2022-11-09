{ pkgs }:

with pkgs; [
	bash
	curl
	coreutils
	gh
	jq
	moreutils # for parallel
	gomplate
	taplo-cli
]
