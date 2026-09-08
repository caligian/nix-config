# ~/.user/nix/myUtils.nix
{ 
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
  home
}:

let
  inherit (builtins) 
    attrNames attrValues foldl' map filter 
    concatStringsSep elem length head tail genList
    readDir pathExists isPath isString isAttrs isInt isFloat isBool isNull
    toString fromJSON toJSON readFile writeFile trace throw splitString hasAttr getAttr elemAt 
    replaceStrings
    listToAttrs baseNameOf dirOf concatLists toFile getEnv;
  
  inherit (lib)
    flatten unique mergeAttrs recursiveUpdate
    mapAttrs filterAttrs optional optionals
    hasPrefix hasSuffix removePrefix removeSuffix
    toLower toUpper escapeShellArg isList isDerivation
    makeLibraryPath;

  inherit (pkgs)
    writeText writeShellScript runCommand
    fetchurl fetchTarball fetchFromGitHub fetchgit;
  
  utils = rec {
    mkLibraryPath = makeLibraryPath;
    getEnv = name: builtins.getEnv name;
    attrs = {
      keys = attrNames;
      values = attrValues;
      merge = mergeAttrs;
      update = recursiveUpdate;
      filter = filterAttrs;
      map = mapAttrs;
      has = attr: key: hasAttr attr key;
      get = attr: key: getAttr attr key;
    };
    list = {
      map = map;
      filter = filter;
      reduce = foldl';
      len = length;
      first = head;
      rest = tail;
      contains = elem;
      range = genList;
      flatten = flatten;
      unique = unique;
      head = head;
      tail = tail;
      concat = concatLists;
      join = concatStringsSep;
      nth = elemAt;
    };
    str = {
      split = splitString;
      lower = toLower;
      upper = toUpper;
      hasPrefix = hasPrefix;
      hasSuffix = hasSuffix;
      rmPrefix = removePrefix;
      rmSuffix = removeSuffix;
      replace = replaceStrings;
    };
    as = {
      str = toString;
      attrs = listToAttrs;
    };
    file = {
      write = toFile;
      writeText = writeText;
      read = readFile;
    };
    path = {
      exists = pathExists;
      basename = baseNameOf;
      dirname = dirOf;
      ls = path: attrNames (readDir path);
      libraryPath = makeLibraryPath;
      isFile = path:
        let 
          dir = readDir (dirOf path);
          base = baseNameOf path; 
        in 
          dir ? base && dir.${base} == "regular";
      isDir = path:
        let 
          dir = readDir (dirOf path);
          base = baseNameOf path;
        in 
          dir ? base && dir.${base} == "directory";
    };
    is = {
      int = isInt;
      float = isFloat;
      string = isString;
      attrs = isAttrs;
      null = isNull;
      bool = isBool;
      path = isPath;
      derivation = isDerivation;
    };
    json = {
      read = path: fromJSON (readFile path);
      write = data: path: writeFile path (toJSON data);
      load = fromJSON;
      dump = toJSON;
    };
    shell = {
      writeScript = writeShellScript;
      run = runCommand;
    };
    fetch = {
      url = fetchurl;
      tar = fetchTarball;
      tarball = fetchTarball;
      github = url: rev: specs: 
        let
            required = splitString "/" url; 
            requiredLen = length required;
            owner = elemAt required (requiredLen - 2);
            repoFull = elemAt required (requiredLen - 1);
            repo = replaceStrings [".git"] [""] repoFull;
            mainArgs = { owner = owner; repo = repo; rev = rev; };
            args = mainArgs // (removeAttrs specs ["rev"]);

        in
          fetchFromGitHub args;
      git = url: rev: specs: 
        let 
          allSpecs = {url = url; rev = rev; } // specs;
        in
          fetchgit allSpecs;
    };
    log = msg: value: trace "${msg}: ${toString value}" value;
    inspect = value: trace (toJSON value) value;
    die = throw;
    type = x:
      if isNull x then "null"
      else if isList x then "list"
      else if isBool x then "bool"
      else if isInt x then "int"
      else if isFloat x then "float"
      else if isString x then "string"
      else if isPath x then "path"
      else if isAttrs x then "attrs"
      else "unknown";
    user = {
      dir = "${home}/.user";
      nixDir = "${user.dir}/nix";
      scriptsDir = "${user.dir}/scripts";
      mkNixPath = name: "${user.nixDir}/${name}.nix";
      mkPath = name: "${user.dir}/${name}";
      exists = name: pathExists (user.mkPath name);
      import = name: args: import (user.mkNixPath name) args;
      lock = {
        mkPath = name: "${home}/.user/lock/${name}";
        exists = name: pathExists (user.lock.mkPath name);
      };
    };
    nvim = rec {
      mkPlugin = name: repo: specs: 
        let
          urlSplit = splitString "/" repo;
          username = elemAt urlSplit 0;
          repoUrl = elemAt urlSplit 1;
          getValue = key: default:
            if hasAttr specs key then
              let 
                value = getAttr specs key;
              in 
                if value != null then value
                else default
            else
              default;
          hash = getValue "rev" "";
          dependencies = getValue "deps" [];
        in
          pkgs.vimUtils.buildVimPlugin {
            pname = name;
            dependencies = dependencies;
            version = hash;
            src = fetchFromGitHub {
              owner = username;
              repo = repoUrl;
              rev = hash;
            };
          };
      mkPlugins = specs: (
        # Example use:
        ## mkPlugins [
        ##   ["telescope" "nvim-telescope/telescope.nvim" { rev = "..."; sha256 = "..."; deps = [<vimPlugin> ...]}]
        ##   [...]
        ## ]
        let 
          process = spec: 
            let
              name = elemAt spec 0;
              repo = elemAt spec 1;
              recipe = elemAt spec 2;
            in 
              mkPlugin name repo recipe;
        in 
          map process specs
      );
    };
  };
in
  utils
