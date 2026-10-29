{
  pkgs,
  ...
}:
(with pkgs.python313Packages; [
  pip
  jedi-language-server
  python-docx
  termcolor
  pandas
  babel
  ipython
  ipdb
  yt-dlp
  polars
  pycmus
  pyfzf
  numpy
  selenium
  scipy
  httpx
  pydantic
  pydantic-core
  typing-extensions
  websockets
  html5lib
  lxml
  beautifulsoup4
  ibis-framework
  # opencv4
  # pytesseract
  # pdfplumber
])
++ [ pkgs.python313 ]
