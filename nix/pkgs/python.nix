home:
opts@{ ... }:
(with opts.pkgs; [
  python313
  (with python313Packages; [
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
  ])
])
