{
  pkgs,
  name,
  version,
  commit,
  owner,
  repo,
  buildTools,
  desc ? "",
  license ? pkgs.lib.licenses.mit,
  packages ? [ ],
  buildInputs ? [ ],
  prePhase ? "",
  buildPhase ? "",
  postPhase ? "",
}:

let
  rPkgs = pkgs.rPackages;
in
rPkgs.buildRPackage {
  pname = name;
  version = version;
  src = pkgs.fetchFromGitHub {
    inherit owner repo;
    rev = commit;
    hash = "";
  };
  nativeBuildInputs = buildTools;
  propagatedBuildInputs = packages;
  buildInputs = buildInputs;
  preConfigure = prePhase;
  buildPhase = buildPhase;
  postInstall = postPhase;
  meta = {
    description = desc;
    inherit license;
    maintainers = [ ];
  };
}
