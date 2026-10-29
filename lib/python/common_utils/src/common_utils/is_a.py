from __future__ import annotations

import collections.abc as abc
import inspect
import re
import types
from collections import defaultdict
from collections.abc import Iterable, Mapping, MutableMapping
from copy import copy
from dataclasses import Field, dataclass
from dataclasses import field as make_field
from functools import partial
from typing import (
    Any,
    Callable,
    Generator,
    Generic,
    Iterator,
    Literal,
    Sequence,
    Set,
    TypeVar,
    overload,
)

T = TypeVar("T")
R = TypeVar("R")
DefaultFactory = Callable[[], Any]
Mapper = Callable[[T], R]
NamespaceKey = str
NamespaceKeys = list[NamespaceKey]


class Namespace[T](MutableMapping):
    __match_args__ = ("data",)

    @staticmethod
    def assert_is_identifier(key: str) -> None:
        if not re.search("^[a-zA-Z][a-zA-Z0-9_]*$", key):
            raise KeyError(
                f"Expected an identifier (^[a-zA-Z][a-zA-Z0-9_]*$), got {key}"
            )

    @classmethod
    def with_slots(cls, slots: list[str]) -> Namespace:
        cls.__slots__ = tuple(slots)
        return cls

    def __init__(
        self,
        data: dict[str, Any] | None = None,
        **attributes,
    ) -> None:
        if data and len(attributes) > 0:
            raise ValueError("Cannot pass both **attributes and data=")

        it = data.items() if data else attributes.items()
        self.__attributes__: dict[str, bool] = {}

        for key, value in it:
            Namespace.assert_is_identifier(key)
            setattr(self, key, value)

    def __str__(self) -> str:
        s = str(self.__dict__)
        s = f"<Namespace>{s}"
        return s

    def __contains__(self, key: str) -> bool:
        return key in self.__attributes__

    def __getitem__(self, key: str) -> Any:
        if key not in self:
            raise KeyError(key)
        return getattr(self, key)

    def __setitem__(self, key: str, value: Any) -> None:
        setattr(self, key, value)

    def __setattr__(self, key: str, value: Any | None) -> None:
        Namespace.assert_is_identifier(key)
        setattr(self, key, value)
        self.__attributes__[key] = True
        self[key] = value

    def __iter__(self) -> Iterator[str]:
        yield from self.__attributes__

    def __len__(self) -> int:
        return len(self.__attributes__)


class ModuleMeta(type):
    def __call__(cls, *_args, **_kwargs):
        raise TypeError(
            "Attempting to call Module class",
            dict(cls=cls, args=_args, kwargs=_kwargs),
        )

    def __getitem__(cls, key: str) -> Any:
        return cls.__dict__[key]

    def __setitem__(cls, key: str, value: Any) -> None:
        setattr(cls, key, value)

    def __iter__(self) -> Iterator[str]:
        return iter(x for x in self.__dict__.keys() if not x.startswith("__"))

    def __contains__(self, key: str) -> bool:
        return key in iter(self)


class Module(metaclass=ModuleMeta):
    def __new__(cls, *args, **kwargs):
        raise TypeError(
            f"{cls.__name__} is a static module and cannot be instantiated."
        )


Container = Namespace | dict | list | tuple


def defined(x: Any | None) -> bool:
    return x is not None


def undefined(x: Any) -> bool:
    return x is None


def is_in(x: Any, tbl: Container, invert: bool = False) -> bool:
    if invert:
        return x not in tbl
    else:
        return x in tbl


def not_in(x: Any, tbl: Container) -> bool:
    return x not in tbl


def is_range(x: Any) -> bool:
    return isinstance(x, range)


def literal(x: Any) -> Callable[[], Any]:
    fn = lambda: x
    fn.__literal__ = True
    return fn


def is_literal(x: Any) -> bool:
    if not callable(x):
        return False
    else:
        return hasattr(x, "__literal__") and x.__literal__


def inherits(x: Any, *ys: type, invert: bool = False) -> bool:
    ok = False
    if isinstance(x, type):
        ok = issubclass(x, ys)
    else:
        ok = isinstance(x, ys)

    if invert:
        return not ok
    else:
        return ok


def type_name(x: Any) -> str:
    if x is None:
        return "None"
    elif isinstance(x, type):
        return x.__name__
    else:
        return type_name(x)


def isa(x: Any, *ys: type, invert: bool = False) -> Any:
    ok = inherits(x, *ys, invert=True)
    if not ok:
        x_type = type(x)
        context = dict(expected=ys, got=x_type, value=x, invert=invert)
        raise TypeError(ys, context)

    return x


def not_isa(x: Any, *ys: type) -> Any:
    return isa(x, *ys, invert=True)


def is_type(x: Any) -> bool:
    return inherits(x, type)


def is_instance(x: Any) -> bool:
    return not is_type(x)


def is_subclass(x: type, *y: type) -> bool:
    return issubclass(x, y)


def is_instancemethod(x: Any, name: str):
    attr = getattr(x, name, None)
    return isinstance(attr, types.MethodType) and attr.__self__ is x


is_imethod = is_instancemethod


def is_classmethod(x: Any, name: str):
    attr = getattr(x, name, None)
    return isinstance(attr, classmethod)


is_cmethod = is_classmethod


def is_staticmethod(x: Any, name: str):
    attr = getattr(x, name, None)
    return isinstance(attr, staticmethod)


is_smethod = is_staticmethod


def is_field(x: Any) -> bool:
    return isinstance(x, Field)


def is_method(x: Any, name: str) -> bool:
    attr = getattr(x, name, None)
    return (
        True
        if (
            callable(attr)
            and not is_classmethod(x, name)
            and not is_staticmethod(x, name)
            and not is_instancemethod(x, name)
        )
        else False
    )


def is_int(x: Any) -> bool:
    return inherits(x, int)


def is_float(x: Any) -> bool:
    return inherits(x, float)


def is_number(x: Any) -> bool:
    return inherits(x, (int, float))


def is_str(x: Any) -> bool:
    return inherits(x, str)


def is_bytes(x: Any) -> bool:
    return inherits(x, bytes)


def is_str_like(x: Any) -> bool:
    return inherits(x, str, bytes)


def is_classvar(x: Any, name: str) -> bool:
    if type(x) is type:
        raise ValueError(f"obj: Expected instance, not a class: {x}")
    elif name in x.__dict__:
        return False

    cls = x.__class__
    if not hasattr(cls, name):
        return False
    elif is_classmethod(x, name):
        return False
    elif is_staticmethod(x, name):
        return False

    return True


def is_var(x: Any, name: str, is_local: bool = False) -> bool:
    if is_local:
        return name in x.__dict__
    elif is_classmethod(x, name):
        return False
    elif is_staticmethod(x, name):
        return False
    elif is_instancemethod(x, name):
        return False
    elif not is_classvar(x, name):
        return False
    else:
        return True


def is_generator(x: Any) -> bool:
    return isinstance(x, Generator)


is_gen = is_generator


def is_dict(x: Any) -> bool:
    return isinstance(x, dict)


def is_list(x: Any) -> bool:
    return isinstance(x, list)


def is_tuple(x: Any) -> bool:
    return isinstance(x, tuple)


def is_sequence(x: Any) -> bool:
    return isinstance(x, (list, tuple))


def is_container(x: Any) -> bool:
    return isinstance(x, (Namespace, list, tuple, dict))


def is_bool(x: Any) -> bool:
    return isinstance(x, bool)


def is_true(x: Any) -> bool:
    return True if x else False


def is_false(x: Any) -> bool:
    return False if x else True


def is_na(x: Any, valid: tuple = tuple()) -> bool:
    if x is None:
        return True
    elif x in valid:
        return True
    else:
        return False


def is_class(cls: Any) -> bool:
    return type(cls) is type


def is_mapping(x: Any) -> bool:
    return is_namespace(x) or is_dict(x)


def is_namespace(x: Any) -> bool:
    return isinstance(x, Namespace)


def is_module(x: Any) -> bool:
    return isinstance(x, type) and issubclass(x, Module)


def is_regex(x: Any) -> bool:
    return isinstance(x, re.Pattern)


def is_pattern(x: Any) -> bool:
    return isinstance(x, (re.Pattern, str, bytes))


def is_error(x: Any) -> bool:
    return inherits(x, Exception, BaseException)


def assert_is_container(x: Any) -> Container:
    isa(x, Namespace, dict, tuple, list)
    return x


def assert_is_sequence(x: Any) -> Container:
    isa(x, str, bytes, tuple, list)
    return x


def keys(x: Container) -> list:
    assert_is_container(x)
    if inherits(x, Namespace):
        return iter(x)
    elif inherits(x, list, tuple):
        return list(range(len(x)))
    else:
        return list(x.keys())


def values(x: Container) -> list:
    assert_is_container(x)
    if inherits(x, Namespace):
        return [x[k] for k in iter(x)]
    elif inherits(x, list, tuple):
        return x
    else:
        return list(x.values())


def items(x: Container) -> list[tuple[Any, Any]]:
    assert_is_container(x)
    if inherits(x, Namespace, list, tuple):
        return list(zip(keys(x), values(x)))
    else:
        return list(x.items())


def as_regex(
    x: re.Pattern | bytes | str,
    flags: re.RegexFlag | None = None,
    ignore_case: bool = False,
    multiline: bool = False,
    fixed: bool = False,
) -> re.Pattern:
    if isinstance(x, re.Pattern):
        return x
    elif fixed:
        return re.escape(x)

    if ignore_case:
        flags += re.I

    if multiline:
        flags += re.M

    return re.compile(x, flags=flags)


class field(Module):
    @staticmethod
    def new(*args, **kwargs) -> Field:
        return make_field(*args, **kwargs)

    @staticmethod
    def bool(default: bool | None = None, **kwargs) -> Field:
        if default is not None:
            return make_field(default=default, **kwargs)
        else:
            return make_field(default=False, **kwargs)

    @staticmethod
    def boolean(default: bool | None = None, **kwargs) -> Field:
        return field.bool(default, **kwargs)

    @staticmethod
    def true(**kwargs) -> Field:
        return field.bool(True, **kwargs)

    @staticmethod
    def false(**kwargs) -> Field:
        return field.bool(False, **kwargs)

    @staticmethod
    def na(**kwargs) -> Field:
        return make_field(default=None, **kwargs)

    @staticmethod
    def list(
        n: int | None = None,
        default: list[Any] | None = None,
        default_factory: Callable[[], Any | None] | None = None,
        **kwargs,
    ) -> Field:
        if n:
            if not default_factory:
                raise ValueError("default_factory= is missing")
            default = [default_factory() for _ in range(n)]
        elif default is None:
            default = []
        return make_field(default_factory=lambda: copy(default), **kwargs)

    @staticmethod
    def tuple(
        n: int | None = None,
        default: tuple | None = None,
        default_factory: Callable[[], Any | None] | None = None,
        **kwargs,
    ) -> Field:
        if n:
            if not default_factory:
                raise ValueError("default_factory= is missing")
            default = (default_factory() for _ in range(n))
        elif default is None:
            default = tuple()
        return make_field(default_factory=lambda: copy(default), **kwargs)

    @staticmethod
    def int(default: int, **kwargs) -> Field:
        return make_field(default=default, **kwargs)

    @staticmethod
    def str(default: str, **kwargs) -> Field:
        return make_field(default=default, **kwargs)

    @staticmethod
    def bytes(default: bytes, **kwargs) -> Field:
        return make_field(default=default, **kwargs)

    @staticmethod
    def float(default: float, **kwargs) -> Field:
        return make_field(default=default, **kwargs)

    @staticmethod
    def dict(
        default: dict | None = None,
        default_factory: Callable[[], Any | None] | None = None,
        **kwargs,
    ) -> Field:
        if default_factory:
            f = lambda: defaultdict(default_factory)
            return make_field(default_factory=f, **kwargs)
        elif default:
            return make_field(default_factory=lambda: copy(default))
        else:
            return make_field(default_factory=lambda: {}, **kwargs)

    @staticmethod
    def Namespace(default: Namespace | None = None, **kwargs) -> Field:
        default = Namespace() if default is None else default
        return make_field(default_factory=lambda: copy(default), **kwargs)

    @staticmethod
    def defaultdict(
        default: Any | None = None,
        default_factory: Callable[[], Any | None] | None = None,
        **kwargs,
    ) -> Field:
        if default_factory:
            return field.dict(default_factory=default)
        else:
            return field.dict(default_factory=lambda: default)


abc.Mapping.register(Namespace)


__all__ = [
    "Module",
    "Namespace",
    "dataclass",
    "defined",
    "field",
    "inherits",
    "is_bool",
    "is_bytes",
    "is_class",
    "is_classmethod",
    "is_classvar",
    "is_cmethod",
    "is_container",
    "is_dict",
    "is_error",
    "is_false",
    "is_field",
    "is_float",
    "is_gen",
    "is_generator",
    "is_imethod",
    "is_instance",
    "is_instancemethod",
    "is_int",
    "is_list",
    "is_mapping",
    "is_method",
    "is_module",
    "is_na",
    "is_namespace",
    "is_number",
    "is_pattern",
    "is_range",
    "is_regex",
    "is_sequence",
    "is_staticmethod",
    "is_str",
    "is_str_like",
    "is_subclass",
    "is_true",
    "is_tuple",
    "is_type",
    "is_var",
    "isa",
    "literal",
    "undefined",
]
