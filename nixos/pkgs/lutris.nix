{ pkgs, ... }:
[
  (pkgs.lutris.override {
    extraLibraries = pkgs: with pkgs; [ libgudev ];
    extraPkgs =
      pkgs: with pkgs; [
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav
        libtheora
        libxml2
        openssl_1_1
        libwebp
        libvdpau
        speex
        libdrm
      ];
  })
]
