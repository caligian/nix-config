home:
{ pkgs, env }:
let
  myEnv = env;
  utils = import <my/utils.nix> { inherit home pkgs; };
  path = utils.path;
  str = utils.str;
  dir = path.dir;
  pkgsFiles = utils.keep (path.ls dir.nixPkgs) (file: !(str.detect file [ ".*base.nix$" ]));
  buildInputs = utils.apply pkgsFiles (
    file:
    import file home {
      env = myEnv;
      pkgs = pkgs;
    }
  );
in
buildInputs
