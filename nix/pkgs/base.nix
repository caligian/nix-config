home:
{
  pkgs ? import <nixpkgs> { },
  env ? { },
}:
let
  myEnv = env;
  utils = import <my/utils.nix> home { inherit pkgs; };
  path = utils.path;
  str = utils.str;
  dir = path.dir;
  isValidFile = (file: !(str.detect file [ ".*base.nix$" ]));
  pkgsFiles = utils.keep (path.ls dir.nixPkgs) isValidFile;
  loadPkgs =
    file:
    import file home {
      env = myEnv;
      pkgs = pkgs;
    };
  buildInputs = utils.apply pkgsFiles loadPkgs;
in
buildInputs
