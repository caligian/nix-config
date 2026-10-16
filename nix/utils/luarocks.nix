{
  pkgs ? import <nixpkgs> { },
  name,
  owner,
  repo,
  version,
  commit,
  desc ? "",
  packages ? [ ],
  prePhase ? "",
  buildPhase ? "",
  postPhase ? "",
  buildTools ? [ ],
  hash ? "",
}:

let
  luaPkgs = pkgs.luajitPackages;
in
luaPkgs.buildLuarocksPackage {
  pname = name;
  version = version;
  src = pkgs.fetchFromGitHub {
    owner = owner;
    repo = repo;
    rev = commit;
    hash = hash;
  };
  nativeBuildInputs = buildTools;
  propagatedBuildInputs = packages;
  preConfigure = prePhase;
  buildPhase = buildPhase;
  postInstall = postPhase;
  meta = {
    description = desc;
    license = pkgs.lib.licenses.mit;
  };
}
