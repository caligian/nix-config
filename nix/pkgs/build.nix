home:
opts@{ ... }:
(with opts.pkgs; [
  gcc
  gnumake
  cmake
  pkg-config
  binutils
  coreutils
  libgcc
])
