home:
{
  pkgs ? import <nixpkgs> { },
}:

let
  luarocks = pkgs.luajitPackages;
  mkRock = import <my/utils/luarocks.nix>;
  parseURL =
    url:
    let
      m = builtins.match "https://www\\.github\\.com/([^/]+)/([^/]+)" url;
    in
    {
      owner = builtins.elemAt m 0;
      repo = builtins.elemAt m 1;
    };
  mkFromSpec =
    name: spec:
    let
      parsed = parseURL spec.url;
      prePhase = if spec ? prePhase then spec.prePhase else "";
    in
    mkRock {
      inherit pkgs name;
      inherit (parsed) owner repo;
      version = builtins.substring 0 7 spec.rev;
      commit = spec.rev;
      hash = spec.hash;
      prePhase = prePhase;
    };
  rawSpecs = {
    busted = {
      date = "2026-08-25T16:36:10+02:00";
      deepClone = false;
      fetchLFS = false;
      fetchSubmodules = false;
      fetchTags = false;
      hash = "sha256-sYP4XyiQIVo5hqQMZvIzZ1p2JvRRbRmqEkT7bkf4mdw=";
      leaveDotGit = false;
      path = "/nix/store/wnrnhyjhcn9vm0r630hawxjlbjz8lv18-busted";
      rev = "22f8089f461a563fb9553ab56f926c6805850833";
      rootDir = "";
      sha256 = "1p4rz13nxys42am1jvaiyhk7cnk76gr6c354hqwml8ch51gzi0xi";
      url = "https://www.github.com/lunarmodules/busted";
    };
    inspect = {
      date = "2026-01-05T17:28:00+01:00";
      deepClone = false;
      fetchLFS = false;
      fetchSubmodules = false;
      fetchTags = false;
      hash = "sha256-2+voC5OcNuuaSZu0KNK64vtHHxDWr1slejF0ToVeDCI=";
      leaveDotGit = false;
      path = "/nix/store/3svqwk8pxz0f0d4x9gyvcybn3ycxxc7v-inspect.lua";
      rev = "a8ca3120dfec48801036eaeff9335ab7a096dd24";
      rootDir = "";
      sha256 = "08hcbs2lwx1ig8jmpbyn20glgyz2pb92id4v96dfndlwjc5yisyv";
      url = "https://www.github.com/kikito/inspect.lua";
    };
    ldoc = {
      date = "2026-09-04T00:26:29+02:00";
      deepClone = false;
      fetchLFS = false;
      fetchSubmodules = false;
      fetchTags = false;
      hash = "sha256-y2rVfZNuBI04tfAUZvrBgtDbFDlHvoSz7UdiLQ47x/k=";
      leaveDotGit = false;
      path = "/nix/store/wjmh9d0yv42pyfhgqpdsyqj77q40wgk3-ldoc";
      rev = "e1dff24e1c519c96bbf95647c9aeac2dfb3b9ae0";
      rootDir = "";
      sha256 = "1yf77c72sqj7xnrq9gj774adpl42q7x6c57hnlw8s13fjdyxasnb";
      url = "https://www.github.com/lunarmodules/ldoc";
    };
    lpath = {
      date = "2023-06-08T15:19:43+08:00";
      deepClone = false;
      fetchLFS = false;
      fetchSubmodules = false;
      fetchTags = false;
      hash = "sha256-d1xV0j2vcyyC3+xfp2RWsJs4ChDmAX6feBbY8KdFjYU=";
      leaveDotGit = false;
      path = "/nix/store/f44a6kpc456p42fvalxs3fg3di721x2j-lpath";
      rev = "cdc573e8bf3fabe67e67a41651de1b2da93f306c";
      rootDir = "";
      sha256 = "11cd8nkz1n0ng2gpw0g62053i6xharjafpzcvy12qwxg7p95ap3p";
      url = "https://www.github.com/starwing/lpath";
    };
    lua-cjson = {
      date = "2024-04-15T16:59:28+10:00";
      deepClone = false;
      fetchLFS = false;
      fetchSubmodules = false;
      fetchTags = false;
      hash = "sha256-cxwhLNOnvBGh9yrIPoj6e/UjxsDi4kCzrTgy6DHZH4A=";
      leaveDotGit = false;
      path = "/nix/store/hca8bnj7hplfsc5pkl4i8xc4cip28j4p-lua-cjson";
      rev = "718f27293a981fb5e9e662e9aec0b7cf78317da6";
      rootDir = "";
      sha256 = "100zv4qyhciqmnrl1qp2q3327xbvza43xj1ayyhi3g57scn2273k";
      url = "https://www.github.com/mpx/lua-cjson";
    };
    luacheck = {
      date = "2026-07-31T12:38:41+02:00";
      deepClone = false;
      fetchLFS = false;
      fetchSubmodules = false;
      fetchTags = false;
      hash = "sha256-/i7hl4DgjKHNotpECDfzkt7cr7XpSjyE1XprA1phtpg=";
      leaveDotGit = false;
      path = "/nix/store/jrynq9skkm8715nz9ajknj774grii3qj-luacheck";
      rev = "2f764bdcabe8b7c19deadf0e9bb2adc19df1a4c5";
      rootDir = "";
      sha256 = "165nc5d06svssn23qjp9nnpxrpljycvhhi6slb6s3370h2by2bpy";
      url = "https://www.github.com/lunarmodules/luacheck";
    };
    luafilesystem = {
      date = "2026-09-03T19:07:15+02:00";
      deepClone = false;
      fetchLFS = false;
      fetchSubmodules = false;
      fetchTags = false;
      hash = "sha256-zI8upqgPE0xD5bRacSeyJkhKoyfyBAgT368g5+6y7vU=";
      leaveDotGit = false;
      path = "/nix/store/s9idkh7pj5qvxlr047h4064dvaxs0nx5-luafilesystem";
      rev = "146ab458e821cd7617892099fe8e6e399b46185c";
      rootDir = "";
      sha256 = "1xgfnbpff85gvw9hh17j4yillj16n8kp2nmlwm1lq4qgm2k2x3yc";
      url = "https://www.github.com/lunarmodules/luafilesystem";
    };
    luasystem = {
      date = "2026-10-04T12:05:23+02:00";
      deepClone = false;
      fetchLFS = false;
      fetchSubmodules = false;
      fetchTags = false;
      hash = "sha256-CrPMFFR0gw46mDLMl14gi8UBdj7lKu+88YLGUki0sZc=";
      leaveDotGit = false;
      path = "/nix/store/n2qmmd78mz1583568disr14v9gwy48cp-luasystem";
      rev = "5730c14d2e8abf373d77a3bec7c119ce9548dfc2";
      rootDir = "";
      sha256 = "15xini455il2y6yfyap57rv03icb41g9gk1jk0x0x0vlahacrcqa";
      url = "https://www.github.com/lunarmodules/luasystem";
      prePhase = "export RT_DIR=${pkgs.glibc}";
    };
    luautf8 = {
      date = "2026-08-26T19:44:37+08:00";
      deepClone = false;
      fetchLFS = false;
      fetchSubmodules = false;
      fetchTags = false;
      hash = "sha256-vWKI4CrTB82tK1RiO9rkXLkSHdWEAinl/qOqdbc1iv4=";
      leaveDotGit = false;
      path = "/nix/store/4dqpb7kkzasmnski49bzsihh4z3dca5a-luautf8";
      rev = "a47b1433473a2509d77ad28f59a976716d187927";
      rootDir = "";
      sha256 = "1zla6nvpbam3zvjjj0l4slfi5fawwkd3nqjl5fnws1yk5bh8hqmx";
      url = "https://www.github.com/starwing/luautf8";
    };
    luv = {
      date = "2026-09-30T19:40:45-07:00";
      deepClone = false;
      fetchLFS = false;
      fetchSubmodules = false;
      fetchTags = false;
      hash = "sha256-CdG9zMDgSCgh+v4BNxao2IhpP0ZnNodQMc42hF+OU08=";
      leaveDotGit = false;
      path = "/nix/store/pxghgjk4b6rjmjw8q7sw7ng84v75dfjh-luv";
      rev = "26e62e49b0230891ece45a78cc1f63c074e60020";
      rootDir = "";
      sha256 = "0kskirgq8dnf6588fdk78qznk26qm0b3f0gyz8hjhj70q36bvl89";
      url = "https://www.github.com/luvit/luv";
    };
    penlight = {
      date = "2026-09-03T19:16:00+02:00";
      deepClone = false;
      fetchLFS = false;
      fetchSubmodules = false;
      fetchTags = false;
      hash = "sha256-9hY8Arbv7lpG8NfBwT+k6tl3oGaamjR8aMvXpJjKfmM=";
      leaveDotGit = false;
      path = "/nix/store/kjw1zsr3jj9ay62v0fgrlgxk7m09fggj-penlight";
      rev = "dfa483dddc0d751be1047667f4580dd90319169c";
      rootDir = "";
      sha256 = "0qvyraca9mybd1y396lscsh7gngalhzw3hfpy135mvpgnq13q5pn";
      url = "https://www.github.com/lunarmodules/penlight";
    };
  };
in
(builtins.mapAttrs mkFromSpec rawSpecs)
++ (with luarocks; [
  lpeg
  lpeg_patterns
  ansicolors
  plenary-nvim
  sqlite
  luaposix
])
