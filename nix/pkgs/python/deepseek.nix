home:
{ lib, pkgs, ... }:
let
  pypi = pkgs.python313Packages;
  buildPkg = pypi.buildPythonPackage;
  fetchPkg = pypi.fetchPypi;
  deps = [ pypi.requests ];
  pname = "deepseek";
  version = "1.0.0";
  deepseek = buildPkg {
    format = "wheel";
    build-system = [ pypi.setuptools ];
    pname = pname;
    version = version;
    src = pkgs.fetchFromGithub {
      owner = "deepseek-ai";
      repo = "deepseek";
    };
    propagatedBuildInputs = deps;
    nativeBuildInputs = [
      pypi.setuptools
      pypi.wheel
    ];
    meta = {
      description = "Deepseek python library";
      homepage = "https://pypi.org/project/deepseek";
      licenses = lib.licenses.apache2;
    };
  };
in
deepseek
