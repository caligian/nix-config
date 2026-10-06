# ~/.user/nix/myUtils.nix
home:
{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  inherit (builtins)
    removeAttrs
    attrNames
    attrValues
    foldl'
    concatStringsSep
    elem
    length
    head
    tail
    genList
    readDir
    pathExists
    isPath
    isString
    isAttrs
    isInt
    isFloat
    isBool
    isNull
    toString
    fromJSON
    toJSON
    readFile
    writeFile
    trace
    throw
    splitString
    hasAttr
    getAttr
    elemAt
    replaceStrings
    listToAttrs
    baseNameOf
    dirOf
    concatLists
    toFile
    ;

  inherit (lib)
    flatten
    unique
    mergeAttrs
    recursiveUpdate
    mapAttrs
    filterAttrs
    # optional
    # optionals
    removePrefix
    removeSuffix
    toLower
    toUpper
    # escapeShellArg
    isList
    isDerivation
    makeLibraryPath
    ;

  inherit (pkgs)
    writeText
    # writeShellScript
    # runCommand
    fetchurl
    fetchTarball
    fetchFromGitHub
    fetchgit
    ;
  dictUtils = {
    keys = attrNames;
    values = attrValues;
    merge = mergeAttrs;
    update = recursiveUpdate;
    filter = dict: fn: filterAttrs fn dict;
    map = dict: fn: mapAttrs fn dict;
    has = attrs: key: hasAttr key attrs;
    get = attrs: key: getAttr key attrs;
    rm = removeAttrs;
  };
  git =
    {
      pkgs,
      name,
      version,
      owner,
      repo,
      commit,
      desc ? "",
      license ? pkgs.lib.licenses.mit,
      nativeBuildInputs ? [ ],
      buildInputs ? [ ],
      propagatedBuildInputs ? [ ],
      prePhase ? "",
      buildPhase ? "",
      installPhase ? "",
      postPhase ? "",
      meta ? { },
    }:

    let
      src = pkgs.fetchFromGitHub {
        inherit owner repo;
        rev = commit;
        hash = "";
      };
    in
    pkgs.stdenv.mkDerivation {
      pname = name;
      inherit version src;

      nativeBuildInputs = nativeBuildInputs;
      buildInputs = buildInputs;
      propagatedBuildInputs = propagatedBuildInputs;
      preConfigure = prePhase;
      buildPhase = buildPhase;
      installPhase = installPhase;
      postInstall = postPhase;

      meta = {
        description = desc;
        inherit license;
        maintainers = [ ];
      }
      // meta;
    };
  toList =
    x: force:
    let
      force = if isNull force then false else true;
    in
    if force || !(isList x) then [ x ] else x;
  listUtils = {
    apply = xs: fn: builtins.map fn xs;
    keep = xs: fn: builtins.filter fn xs;
    reduce =
      xs: acc: fn:
      foldl' fn acc xs;
    len = length;
    car = head;
    cdr = tail;
    contains = elem;
    range = genList;
    flatten = flatten;
    unique = unique;
    head = head;
    tail = tail;
    concat = concatLists;
    join = concatStringsSep;
    nth = elemAt;
    toDict = listToAttrs;
  };
  strUtils = rec {
    strmatch =
      str: patterns:
      if (length patterns) == 0 then
        null
      else
        let
          pattern = elemAt patterns 0;
          rest = tail patterns;
          res = builtins.match pattern str;
        in
        if isNull res then strmatch str rest else res;
    strdetect = str: patterns: !(isNull (strmatch str patterns));
    split = str: sep: splitString sep str;
    lower = str: toLower str;
    upper = str: toUpper str;
    hasPrefix = str: prefix: lib.hasPrefix prefix str;
    hasSuffix = str: suffix: lib.hasSuffix suffix str;
    rmPrefix = str: prefix: removePrefix prefix str;
    rmSuffix = str: suffix: removeSuffix suffix str;
    replace =
      str: from: to:
      replaceStrings [ from ] [ to ] str;
    gsub =
      str: from: to:
      replaceStrings [ from ] [ to ] str;
    match = str: patterns: strmatch str patterns;
    detect = str: patterns: strdetect str patterns;
  };
  toUtils = {
    str = toString;
    string = toString;
    dict = listToAttrs;
  };
  isUtils = {
    int = isInt;
    float = isFloat;
    string = isString;
    str = isString;
    number = x: (isInt x) || (isString x);
    num = x: (isInt x) || (isString x);
    dict = isAttrs;
    null = isNull;
    bool = isBool;
    path = isPath;
    derivation = isDerivation;
    drv = isDerivation;
  };
  pathType =
    p:
    let
      dir = dirOf p;
      base = baseNameOf p;
      entries = if pathExists dir then readDir dir else { };
    in
    if hasAttr base entries then entries.${base} else null;
  pathUtils = {
    exists = pathExists;
    basename = baseNameOf;
    dirname = dirOf;
    ls = p: if pathExists p then map (file: p + "/" + file) (attrNames (readDir p)) else null;
    libraryPath = makeLibraryPath;
    type = pathType;
    isFile = p: pathType p == "regular";
    isDir = p: pathType p == "directory";
    dir = userDirs;
  };
  userRootDir = "${home}/.user";
  homeLibDir = "${home}/lib";
  userDirs = {
    root = userRootDir;
    nix = "${userRootDir}/nix";
    nixPkgs = "${userRootDir}/nix/pkgs";
    bin = "${userRootDir}/bin";
    include = "${userRootDir}/include";
    lib = "${userRootDir}/lib";
    config = "${userRootDir}/config";
    lock = "${userRootDir}/lock";
    apiKeys = "${userRootDir}/api-keys";
    nvim = "${userRootDir}/nvim";
    kitty = "${userRootDir}/kitty";
    home = {
      lib = {
        root = homeLibDir;
        perl = "${homeLibDir}/perl";
        python = "${homeLibDir}/python";
        luajit = "${homeLibDir}/luajit";
      };
      games = "${home}/Games";
      repos = "${home}/Repos";
      music = "${home}/Music";
      downloads = "${home}/Downloads";
      projects = "${home}/Projects";
      work = "${home}/Work";
      scripts = "${home}/Scripts";
      personal = "${home}/Personal";
      pictures = "${home}/Pictures";
      config = "${home}/.config";
      local = "${home}/.local";
      localState = "${home}/.local/state";
      localBin = "${home}/.local/bin";
      bin = "${home}/bin";
    };
  };
  ftUtils = import <my/utils/ft.nix> { inherit pkgs; };
  mkNixPath = name: "${userDirs.nix}/${name}.nix";
  mkBinPath = name: "${userDirs.bin}/${name}";
  mkIncludePath = name: "${userDirs.include}/${name}";
  mkPath = p: "${userRootDir}/${p}";
  lockMkPath = name: "${userDirs.lock}/${name}";
  lockUtils = {
    mkPath = lockMkPath;
    exists = name: pathExists (lockMkPath name);
    read =
      name:
      let
        p = lockMkPath name;
      in
      if pathUtils.isFile p then readFile p else null;
  };
  mkAPIKeyPath = name: "${userDirs.apiKeys}/${name}.txt";
  apiKeyUtils = {
    mkPath = mkAPIKeyPath;
    exists = name: pathUtils.isFile (mkAPIKeyPath name);
    read =
      name:
      let
        p = mkAPIKeyPath name;
      in
      if pathUtils.isFile p then readFile p else null;
  };
  userUtils = {
    rootDir = userRootDir;
    mkNixPath = mkNixPath;
    mkBinPath = mkBinPath;
    mkIncludePath = mkIncludePath;
    mkPath = mkPath;
    source =
      name:
      let
        p = mkIncludePath name;
      in
      if pathExists p then readFile p else null;
    sourceBin =
      name:
      let
        p = mkBinPath name;
      in
      if pathExists p then readFile p else null;
    dir = userDirs;
    lock = lockUtils;
    apiKeys = apiKeyUtils;
  };
  fileUtils = {
    write = toFile;
    writeText = writeText;
    read = readFile;
  };
  jsonUtils = {
    read = p: fromJSON (readFile p);
    write = data: p: writeFile p (toJSON data);
    load = fromJSON;
    dump = toJSON;
  };
in
{
  neovim = {
    mkPlugin =
      {
        plugins ? [ ],
        rocks ? [ ],
        pkgs ? [ ],
        init ? "",
      }:
      pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
        plugins = plugins;
        extraLuaPackages = rocks;
        extraPackages = pkgs;
        luaRcContent = init;
      };
  };
  git = git;
  ft = ftUtils;
  ls = pathUtils.ls;
  dirname = pathUtils.dirname;
  basename = pathUtils.basename;
  isFile = pathUtils.isFile;
  isDir = pathUtils.isDir;
  isPath = pathUtils.exists;
  filetype = pathUtils.type;
  mkLibraryPath = makeLibraryPath;
  car = listUtils.car;
  cdr = listUtils.cdr;
  reduce = listUtils.reduce;
  len = listUtils.length;
  nth = listUtils.nth;
  join = listUtils.join;
  keep = listUtils.keep;
  apply = listUtils.apply;
  unique = listUtils.unique;
  concat = listUtils.concat;
  toList = toList;
  toDict = listUtils.toDict;
  keys = dictUtils.keys;
  values = dictUtils.values;
  merge = dictUtils.merge;
  update = dictUtils.update;
  has = dictUtils.has;
  get = dictUtils.get;
  dict = dictUtils;
  list = listUtils;
  str = strUtils;
  to = toUtils;
  file = fileUtils;
  path = pathUtils;
  is = isUtils;
  json = jsonUtils;
  log = msg: value: trace "${msg}: ${toString value}" value;
  inspect = value: trace (toJSON value) value;
  die = throw;
  user = userUtils;
  type =
    x:
    if isNull x then
      "null"
    else if isList x then
      "list"
    else if isBool x then
      "bool"
    else if isInt x then
      "int"
    else if isFloat x then
      "float"
    else if isString x then
      "string"
    else if isPath x then
      "path"
    else if isAttrs x then
      "attrs"
    else
      "unknown";
}
