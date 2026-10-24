{ pkgs, ... }:
[
  (pkgs.perl.withPackages (
    ps: with ps; [
      Moose
      MooseXGetopt
      MooseXTypes
      MooseXTypesPathTiny
      NamespaceAutoclean
      CarpAssert
      PathTiny
      FileTouch
      FileUtil
      FileSlurp
      JSONXS
      ConfigAny
      ConfigTiny
      YAMLLibYAML
      PLS
      ArchiveTar
      GetoptLongDescriptive
    ]
  ))
]
