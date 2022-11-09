{ pkgs ? import <nixpkgs> {} }:

let deps = import ./.nix/deps.nix {
		inherit pkgs;
	};

	ghcurl = pkgs.writeShellScriptBin "ghcurl" ''
		cd ${./.}
		. lib/ghcurl.sh

		ghcurl "$@"
	'';

in pkgs.mkShell {
	buildInputs = deps ++ (with pkgs; [
		ghcurl
		nodejs
	]);

	shellHook = ''
		PATH="$PATH:$PWD/node_modules/.bin"
	'';

	NO_COLOR = "1";
	GUARD_TRACE = "1";
}
