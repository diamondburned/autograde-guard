{ pkgs ? import <nixpkgs> {} }:

let deps = import ./.nix/deps.nix { inherit pkgs; };
	ghcurl = pkgs.writeShellScriptBin "ghcurl" (builtins.readFile ./ghcurl.sh);

in pkgs.mkShell {
	buildInputs = deps ++ [
		ghcurl
	];
}
