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


class Namespace[T](MutableMapping):
    def __init__(
        self,
        data: dict[str, Any] | None = None,
        **attributes,
    ) -> None:
        self.__attributes__: list[str] = list(attributes.keys())
        if data:
            if len(attributes) > 0:
                raise ValueError("Cannot pass both **attributes and data=")
            attributes = data

        for key, value in attributes.items():
            self[key] = value

    def __str__(self) -> str:
        s = str(self.__dict__)
        s = f"<Namespace>{s}"
        return s

    def __contains__(self, key: str) -> None:
        return hasattr(self, key)

    def __delitem__(self, key: str) -> None:
        if hasattr(self, key):
            delattr(self, key)
            del self.__dict__[key]

    def __getitem__(self, key: int | str | tuple | list[str]) -> Any | None:
        def get(key) -> Any | None:
            try:
                if is_int(key):
                    return getattr(self, self.__attributes__[key])
                else:
                    return getattr(self, key)
            except (IndexError, KeyError) as error:
                raise KeyError(error.args[0])

        if is_seq(key):
            res = []
            for k in key:
                if is_seq(k):
                    res.append([self.__getitem__(k) for k in key])
                else:
                    res.append(self.__getitem__(k))

            return res
        else:
            return get(key)

    def __setitem__(self, key: str, value: Any) -> None:
        setattr(self, key, value)

    def __setattr__(self, key: str, value: Any | None) -> None:
        if not re.match("[a-zA-Z_][a-zA-Z0-9_]*", key, flags=re.I):
            raise KeyError(
                f"Keys can only have alphanumeric characters and underscores, got {key}"
            )
        if not hasattr(self, "__attributes__"):
            super().__setattr__("__attributes__", [key])
        elif key not in self.__attributes__:
            self.__attributes__.append(key)

        super().__setattr__(key, value)

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


def defined(x: Any | None) -> bool:
    return x is not None


def undefined(x: Any) -> bool:
    return x is None


def is_in(x: Any, tbl: dict | Namespace | tuple | list[Any] | Module) -> bool:
    return x in tbl


def is_not_in(x: Any, tbl: dict | Namespace | tuple | list[Any] | Module) -> bool:
    return x not in tbl


def is_range(x: Any) -> bool:
    return isinstance(x, range)


def literal(x: Any) -> Callable[[], Any]:
    return lambda *_args, **_kwargs: x


def inherits(x: Any, *ys: type, cls: bool = False) -> bool:
    if cls:
        return issubclass(x, ys)
    else:
        return isinstance(x, ys)


def cinherits(x: Any, *ys: type) -> bool:
    return inherits(x, *ys, cls=True)


def is_type(x: Any) -> bool:
    return type(x) is type


def is_instance(x: Any) -> bool:
    return not is_type(x)


def is_subclass(x: type, *y: type) -> bool:
    return issubclass(x, y)


def is_instance_method(x: Any, name: str):
    attr = getattr(x, name, None)
    return isinstance(attr, types.MethodType) and attr.__self__ is x


def is_class_method(x: Any, name: str):
    attr = getattr(x, name, None)
    return isinstance(attr, classmethod)


def is_static_method(x: Any, name: str):
    attr = getattr(x, name, None)
    return isinstance(attr, staticmethod)


def is_field(x: Any) -> bool:
    return isinstance(x, Field)


def is_method(x: Any, name: str) -> bool:
    attr = getattr(x, name, None)
    return (
        True
        if (
            callable(attr)
            and not is_class_method(x, name)
            and not is_static_method(x, name)
            and not is_instance_method(x, name)
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


def is_class_var(x: Any, name: str) -> bool:
    if type(x) is type:
        raise ValueError(f"obj: Expected instance, not a class: {x}")
    elif name in x.__dict__:
        return False

    cls = x.__class__
    if not hasattr(cls, name):
        return False
    elif is_class_method(x, name):
        return False
    elif is_static_method(x, name):
        return False

    return True


def is_var(x: Any, name: str, is_local: bool = False) -> bool:
    if is_local:
        return name in x.__dict__
    elif is_class_method(x, name):
        return False
    elif is_static_method(x, name):
        return False
    elif is_instance_method(x, name):
        return False
    elif not is_class_var(x, name):
        return False
    else:
        return True


def is_generator(x: Any) -> bool:
    return isinstance(x, Generator)


def is_dict(x: Any) -> bool:
    return isinstance(x, dict)


def is_list(x: Any) -> bool:
    return isinstance(x, list)


def is_tuple(x: Any) -> bool:
    return isinstance(x, tuple)


def is_sequence(x: Any) -> bool:
    return isinstance(x, (list, tuple))


def is_container(x: Any) -> bool:
    return isinstance(x, (list, tuple, dict))


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


def is_parent(parent: Any, child: Any, cls: bool = False) -> bool:
    return inherits(child, parent, cls=cls)


is_parent_of = is_parent


def is_class(cls: Any) -> bool:
    return type(cls) is type


def is_mapping(x: Any) -> bool:
    return is_namespace(x) or is_dict(x)


def is_namespace(x: Any) -> bool:
    return isinstance(x, Namespace)


def is_module(x: Any) -> bool:
    return isinstance(x, type) and issubclass(x, Module)


def as_module(defined_cls: type) -> type:
    if issubclass(defined_cls, Module):
        return defined_cls

    name = defined_cls.__name__
    attribs = defined_cls.__dict__
    return type(name, (Module,), dict(attribs))


def is_regex(x: Any) -> bool:
    return isinstance(x, re.Pattern)


def is_pattern(x: Any) -> bool:
    return isinstance(x, (re.Pattern, str, bytes))


def is_none(x: Any) -> None:
    return x is None


def is_not_none(x: Any) -> None:
    return x is not None


def is_error(x: Any) -> bool:
    return inherits(x, Exception, BaseException)


def is_struct(x: Any) -> bool:
    return inherits(x, Namespace) and getattr(x, "__struct__", False)


is_ns = is_namespace
container = is_container
sequence = is_sequence
is_boolean = is_bool
is_classmethod = is_class_method
is_staticmethod = is_static_method
is_callable = callable
is_imethod = is_instance_method
is_cmethod = is_class_method
is_cvar = is_class_var
is_classvar = is_class_var
is_gen = is_generator
is_attr = hasattr
is_attribute = hasattr
is_smethod = is_static_method


@as_module
class namespace:
    @staticmethod
    def keys(
        x: Namespace,
        keys: list[str] | None = None,
    ) -> list[str]:
        if keys:
            return [k for k in list(iter(x)) if k in set(keys)]
        else:
            return list(iter(x))

    @staticmethod
    def values(
        x: Namespace[T],
        keys: list[str] | None = None,
    ) -> list[T]:
        return [x[k] for k in namespace.keys(x, keys)]

    @staticmethod
    def items(
        x: Namespace[T],
        keys: list[str] | None = None,
    ) -> list[tuple[str, T]]:
        ks = namespace.keys(x, keys=keys)
        vs = namespace.values(x, keys=keys)
        return list([tuple(x) for x in zip(ks, vs)])

    @staticmethod
    def as_dict(
        x: Namespace[T],
        keys: list[str] | None = None,
    ) -> dict[str, T]:
        return dict(namespace.items(x, keys=keys))

    @staticmethod
    def as_list(
        x: Namespace[T],
        keys: list[str] | None = None,
    ) -> list[tuple[str, T]]:
        return namespace.items(x, keys=keys)


@as_module
class module:
    @staticmethod
    def keys(
        x: Module,
        keys: list[str] | None = None,
    ) -> list[str]:
        if keys:
            return [k for k in list(iter(x)) if k in set(keys)]
        else:
            return list(iter(x))

    @staticmethod
    def values(
        x: Module,
        keys: list[str] | None = None,
    ) -> list[Any]:
        return [x[k] for k in module.keys(x, keys)]

    @staticmethod
    def items(
        x: Module,
        keys: list[str] | None = None,
    ) -> list[tuple[str, Any]]:
        ks = module.keys(x, keys=keys)
        vs = module.values(x, keys=keys)
        return list([tuple(x) for x in zip(ks, vs)])

    @staticmethod
    def as_dict(
        x: Module,
        keys: list[str] | None = None,
    ) -> dict[str, Any]:
        return dict(module.items(x, keys=keys))

    @staticmethod
    def as_list(
        x: Module,
        keys: list[str] | None = None,
    ) -> list[tuple[str, Any]]:
        return module.items(x, keys=keys)

    @staticmethod
    def as_namespace(
        x: Module,
        keys: list[str] | None = None,
    ) -> Namespace[Any]:
        return Namespace(ata=module.as_dict(x, keys=keys))


def get_dunder(cls: type[T], name: str) -> Callable | None:
    dunder = getattr(cls, name, None)
    if dunder is None:
        return getattr(cls, name, None)
    else:
        return dunder


def struct(cls: type[T], **kwargs) -> type[T]:
    kwargs["slots"] = True
    kwargs["order"] = True
    fields = [k for k in cls.__dict__ if not str.startswith(k, "__")]
    mkfields = lambda self: {k: getattr(self, k) for k in fields}
    bases: list[type] = list(getattr(cls, "__mro__"))

    if Namespace in bases:
        bases.pop(bases.index(Namespace))

    try:
        bases.pop(bases.index(Namespace))
        bases.pop(bases.index(object))
    except (ValueError, IndexError):
        pass

    cls = type(cls.__name__, (Namespace, *bases), dict(cls.__dict__))
    cls = dataclass(cls, **kwargs)
    post_init = get_dunder(cls, "__post_init__")
    validate = get_dunder(cls, "__validate__")

    def new_post_init(self, **post_kwargs) -> None:
        if not hasattr(self, "__attributes__"):
            Namespace.__init__(self, data=mkfields(self))

        if validate:
            try:
                validate(self)
                if post_init:
                    post_init(self, **post_kwargs)
            except ValueError as error:
                raise error
        elif post_init:
            post_init(self, **post_kwargs)

    cls.__post_init__ = new_post_init
    cls.__struct__ = True

    return cls


@as_module
class field:
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


# @struct
# class Point:
#     x: int = field.int(-1)
#     y: int = field.int(-2)
#
#     def __validate__(self) -> None:
#         if self.x < 0:
#             raise ValueError("No x value provided")
#         elif self.y < 0:
#             raise ValueError("No y value provided")
#
#     def __post_init__(self) -> None:
#         return self
#
#
# point = Point(1, 2)
# print(is_struct(point))
# print(point[0, "x", [1, [0]]])
#
#
# abc.Mapping.register(Namespace)

is_attr = is_attr
is_attribute = is_attribute
is_bool = is_bool
is_boolean = is_boolean
is_bytes = is_bytes
is_callable = is_callable
is_class = is_class
is_class_method = is_class_method
is_class_var = is_class_var
is_classmethod = is_classmethod
is_classvar = is_classvar
is_cmethod = is_cmethod
is_container = is_container
is_cvar = is_cvar
is_dict = is_dict
is_error = is_error
is_false = is_false
is_field = is_field
is_float = is_float
is_gen = is_gen
is_generator = is_generator
is_imethod = is_imethod
is_int = is_int
is_list = is_list
is_mapping = is_mapping
is_method = is_method
is_module = is_module
is_na = is_na
is_namespace = is_namespace
is_number = is_number
is_parent = is_parent
is_pattern = is_pattern
is_range = is_range
is_regex = is_regex
is_sequence = is_sequence
is_static_method = is_static_method
is_staticmethod = is_staticmethod
is_str = is_str
is_str_like = is_str_like
is_subclass = is_subclass
is_true = is_true
is_tuple = is_tuple
is_type = is_type
is_var = is_var
literal = literal
isa = inherits
is_cmethod = is_class_method
is_smethod = is_static_method
is_seq = is_sequence


__all__ = [
    "container",
    "dataclass",
    "defined",
    "field",
    "inherits",
    "isa",
    "is_attr",
    "is_attribute",
    "is_bool",
    "is_boolean",
    "is_bytes",
    "is_callable",
    "is_class",
    "is_class_method",
    "is_class_var",
    "is_classmethod",
    "is_classvar",
    "is_cmethod",
    "is_container",
    "is_cvar",
    "is_dict",
    "is_error",
    "is_false",
    "is_field",
    "is_float",
    "is_gen",
    "is_generator",
    "is_imethod",
    "is_instance",
    "is_instance_method",
    "is_int",
    "is_list",
    "is_mapping",
    "is_method",
    "is_module",
    "is_na",
    "is_namespace",
    "is_number",
    "is_parent",
    "is_pattern",
    "is_range",
    "is_regex",
    "is_sequence",
    "is_static_method",
    "is_staticmethod",
    "is_str",
    "is_str_like",
    "is_subclass",
    "is_true",
    "is_tuple",
    "is_type",
    "is_var",
    "literal",
    "Module",
    "module",
    "as_module",
    "Namespace",
    "namespace",
    "sequence",
    "undefined",
]
