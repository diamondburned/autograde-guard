let commit = "ac20a8605b0f79be2d65d995cd347251cd5b984b"; # nixos-22.05
	src = builtins.fetchTarball {
		src = "https://github.com/NixOS/nixpkgs/archive/refs/${commit}.tar.gz";
		sha256 = "87428fc522803d31065e7bce3cf03fe475096631e5e07bbd7a0fde60c4cf25c7";
	};
	pkgs = import src {};

in import ./deps.nix {
	inherit pkgs;
}
