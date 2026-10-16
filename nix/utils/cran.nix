{
  pkgs,
  name,
  version,
  commit,
  owner,
  repo,
  desc ? "",
  license ? pkgs.lib.licenses.mit,
  packages ? [ ],
  buildInputs ? [ ],
  buildTools ? [ ],
  prePhase ? "",
  buildPhase ? "",
  postPhase ? "",
}:

let
  rPkgs = pkgs.rPackages;
in
rPkgs.buildRPackage {
  name = name;
  version = version;
  src = pkgs.fetchFromGitHub {
    inherit owner repo;
    rev = commit;
    hash = "";
  };
  propagatedBuildInputs = packages;
  buildInputs = buildInputs;
  nativeBuildInputs = buildTools;
  preConfigure = prePhase;
  buildPhase = buildPhase;
  postInstall = postPhase;
  meta = {
    description = desc;
    inherit license;
    maintainers = [ ];
  };
}
