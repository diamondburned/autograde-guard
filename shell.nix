{ pkgs ? import <nixpkgs> {} }:

let actionDeps = import ./.nix/action-deps.nix;

	ghcurl = pkgs.writeShellScriptBin "ghcurl" ''
		cd ${pkgs.lib.escapeShellArg (builtins.toString ./.)}
		. lib/ghcurl.sh
		ghcurl "$@"
	'';

in pkgs.mkShell {
	buildInputs = actionDeps ++ (with pkgs; [
		ghcurl
		nodejs
	]);

	shellHook = ''
		PATH="$PATH:$PWD/node_modules/.bin"
	'';

	NO_COLOR = "1";
	GUARD_TRACE = "1";
}
