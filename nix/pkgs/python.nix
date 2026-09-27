home:
opts@{ ... }:
(with opts.pkgs; [
  python313
  (with python313Packages; [
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
  ])
])
