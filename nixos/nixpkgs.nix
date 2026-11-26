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
  };
}
