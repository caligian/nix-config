from __future__ import annotations

from typing import Any
from typing import Optional as opt


def new(
    name: str,
    msg: opt[str] = None,
    metadata: opt[dict] = None,
) -> Exception:
    mt = {} if not metadata else metadata
    return type(name, (Exception,), mt)


def throw(
    cls: type[Exception],
    msg: opt[str] = None,
    metadata: opt[dict[str, Any]] = None,
) -> None:
    assert type(cls) is type
    assert "Error" in cls.__name__
    raise cls(msg, metadata)


def is_error_type(cls: any) -> bool:
    return (type(cls) is type) and ("Error" in cls.__name__)


def is_error(cls: any) -> bool:
    return (type(cls) is not type) and isinstance(cls, Exception)


def get_msg(self: Exception) -> opt[str]:
    if len(self.args) > 0:
        return self.args[0]


def get_args(self: Exception) -> opt[str]:
    return self.args


def set_msg(self: Exception, msg: str) -> None:
    self.args = (msg, *self.args[1:])


def set_metadata(self: Exception, msg: opt[str] = None, **metadata) -> None:
    current = self.args[1] if len(self.args) >= 2 else None
    current = current.copy() if current is not None else {}
    current.update(metadata)
    self.args = (msg, current)


class Error(Exception):
    def __init__(self, msg: str = "", metadata: dict[str, Any] = {}) -> None:
        self.msg = msg
        self.metadata = metadata
        super().__init__(self, msg, metadata)

    def __getitem__(self, key: str) -> Any:
        return self.metadata[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.metadata[key] = value

    def throw(
        self,
        msg: opt[str] = None,
        metadata: opt[dict[str, Any]] = None,
    ) -> None:
        mt = self.metadata
        if mt and metadata:
            mt = mt.copy()
            mt.update(metadata)

        if msg:
            raise type(self)(msg, mt)
        else:
            raise type(self)(self.msg, mt)

    def throw_unless(
        self,
        ok: bool,
        msg: opt[str] = None,
        metadata: opt[dict[str, Any]] = None,
    ) -> None:
        if not ok:
            self.throw(self, msg=msg, metadata=metadata)


err_new = new
err_msg = get_msg
err_args = get_args
err_set_msg = set_msg
err_set_metadata = set_metadata

__all__ = [
    "Error",
    "throw",
    "err_new",
    "err_msg",
    "err_args",
    "err_set_msg",
    "err_set_metadata",
]
