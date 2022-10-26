{ pkgs ? import <nixpkgs> {} }:

let deps = import ./.nix/deps.nix { inherit pkgs; };
	ghcurl = pkgs.writeShellScriptBin "ghcurl" ''
		cd ${./.}
		. lib/ghcurl.sh

		ghcurl "$@"
	'';

in pkgs.mkShell {
	buildInputs = deps ++ [
		ghcurl
	];
}
