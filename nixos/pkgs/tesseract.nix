{ pkgs, ... }:
let
  tesseract = pkgs.tesseract.override {
    enableLanguages = [
      "eng"
      "mar"
      "hin"
      "osd"
    ];
  };
in
[
  tesseract
  (pkgs.ocrmypdf.override { tesseract = tesseract; })
]
