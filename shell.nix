{ pkgs ? import <nixpkgs> {} }:

let ghcurl = pkgs.writeShellScriptBin "ghcurl" ''
	curl \
		-H "Authorization: Bearer $GUARD_GITHUB_TOKEN" \
		-H "Accept: application/vnd.github.v3+json" \
		-s \
		"''${@:1}" "https://api.github.com$1"
'';

in pkgs.mkShell {
	buildInputs = with pkgs; [
		bash
		curl
		coreutils
		jq
		ghcurl
	];
}
