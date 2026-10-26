import termcolor
from termcolor import cprint
from pprint import pprint, pp
from .is_a import module


def msg(*s: str, color: str = "blue", **kwargs) -> None:
    assert color in termcolor.COLORS
    cprint(*s, color=color, **kwargs)


def error(*s: str, color: str = "red", **kwargs) -> None:
    cprint(*s, color=color, **kwargs)


def msg_ok(*s: str, color: str = "green", **kwargs) -> None:
    cprint(*s, color=color, **kwargs)


def msg_info(*s: str, color: str = "blue", **kwargs) -> None:
    cprint(*s, color=color, **kwargs)


def msg_warn(*s: str, color: str = "yellow", **kwargs) -> None:
    cprint(*s, color=color, **kwargs)


def get_colors() -> dict[str, int]:
    return termcolor.COLORS


def get_color(s: str) -> int | None:
    return termcolor.COLORS.get(s)


@module
class utils:
    print = staticmethod(msg)
    ok = staticmethod(msg_ok)
    info = staticmethod(msg_ok)
    warn = staticmethod(msg_warn)
    error = staticmethod(error)
    get_colors = staticmethod(get_colors)
    get_color = staticmethod(get_color)
    pp = staticmethod(pp)
    pprint = staticmethod(pprint)
    cprint = staticmethod(cprint)


__all__ = [
    "utils",
    "pprint",
    "pp",
    "cprint",
    "msg_ok",
    "msg_warn",
    "msg_info",
    "msg",
]
