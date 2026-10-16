{
  pkgs,
  name,
  version,
  commit,
  owner,
  repo,
  desc ? "",
  license ? pkgs.lib.licenses.mit,
  python ? pkgs.python313,
  packages ? [ ],
  buildTools ? [ ],
  prePhase ? "",
  buildPhase ? "",
  postPhase ? "",
  format ? "pyproject",
}:

let
  pyPkgs = python.pkgs;
in
pyPkgs.buildPythonPackage {
  pname = name;
  version = version;
  format = format;
  src = pkgs.fetchFromGitHub {
    inherit owner repo;
    rev = commit;
    hash = "";
  };
  pyproject = true;
  build-system = buildTools;
  nativeBuildInputs = buildTools;
  propagatedBuildInputs = packages;
  preConfigure = prePhase;
  buildPhase = buildPhase;
  postInstall = postPhase;
  doCheck = false;
  meta = {
    description = desc;
    inherit license;
    maintainers = [ ];
  };
}
