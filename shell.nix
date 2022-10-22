{ pkgs ? import <nixpkgs> {} }:

let ghcurl = pkgs.writeShellScriptBin "ghcurl" (builtins.readFile ./ghcurl.sh);

in pkgs.mkShell {
	buildInputs = with pkgs; [
		bash
		curl
		coreutils
		jq
		ghcurl
	];
}
