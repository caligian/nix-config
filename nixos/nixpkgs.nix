{
  ...
}:
{
  nixpkgs.config = {
    permittedInsecurePackages = [
      "electron-41.10.7"
      "openssl-1.1.1w"
    ];
    rocmSupport = true;
    allowUnfree = true;
    # overlays = [
    #   (final: prev: {
    #     neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (old: rec {
    #       version = "0.11.1";
    #       src = final.fetchFromGitHub {
    #         owner = "neovim";
    #         repo = "neovim";
    #         tag = "v${version}";
    #         hash = "sha256-kJvKyNjpqIKa5aBi62jHTCb1KxQ4YgYtBh/aNYZSeO8=";
    #       };
    #     });
    #   })
    # ];
  };
}
