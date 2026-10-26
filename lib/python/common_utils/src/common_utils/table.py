import copy
import re
from math import ceil
from typing import Any, Callable, Generator, Iterator, Literal, TypeVar, overload

from pyfzf import FzfPrompt
from .error import utils as errors
from .is_a import (
    Module,
    Namespace,
    inherits,
    is_container,
    is_dict,
    is_error,
    is_list,
    is_map,
    is_pattern,
    is_seq,
    is_tuple,
    isa,
    module,
    namespaces,
)
from .result import E, Err, Ok, Result, T, is_err, is_ok

raise_error = errors.throw
error_msg = errors.get_msg
container = is_container
sequence = is_seq
deepcopy = copy.deepcopy
copy = copy.copy


Pattern = TypeVar("Pattern", re.Pattern, str, bytes)
Container = TypeVar("Container", list, tuple, dict, Namespace)
Mapping = TypeVar("Mapping", Namespace, dict)
Sequence = TypeVar("Sequence", list, tuple)
ContainerType = type[Container]
SequenceType = type[Sequence]
MappingType = type[Sequence]
Value = T | E

ReducerWithIndex = Callable[[Any, Any, Any], Any]
ReducerWithoutIndex = Callable[[Any, Any], Any]
Reducer = ReducerWithIndex | ReducerWithoutIndex

TransformerWithIndex = Callable[[Any, Any], Any]
TransformerWithoutIndex = Callable[[Any], Any]
Transformer = TransformerWithIndex | TransformerWithoutIndex

FilterWithIndex = Callable[[Any, Any], bool]
FilterWithoutIndex = Callable[[Any], bool]
Filter = FilterWithIndex | FilterWithoutIndex

fassocContainer = TypeVar("fassocContainer", list, dict, Namespace)
fassocIndex = TypeVar("fassocIndex", str, int, bytes, re.Pattern, float)
fassocError = TypeVar("fassocError", KeyError, IndexError, TypeError, ValueError)
fassocIndexList = list[fassocIndex]

grepPattern = Pattern | Callable[[Any], bool]
grepContainer = tuple | list[T] | dict[Any, T] | Namespace[T]
grepReturn = (
    tuple
    | list[T | None]
    | list[bool]
    | dict[Any, bool]
    | dict[Any, T | None]
    | Namespace[T | None]
)


def strip(
    s: str | bytes,
    lhs: bool = True,
    rhs: bool = True,
) -> str:
    s = re.sub(r"^\s+", "", s) if lhs else s
    s = re.sub(r"^\s+", "", s) if rhs else s
    return s


def chomp(
    s: str | bytes | tuple | list[str | bytes],
    lhs: bool = True,
    rhs: bool = True,
) -> str | list[str] | tuple:
    if s:
        return strip(s, lhs=True, rhs=True)
    elif is_list(s):
        return [strip(str(x)) for x in s]
    else:
        return tuple(strip(x) for x in s)


def lstrip(s: str | bytes) -> str:
    return strip(s, lhs=True)


def rstrip(s: str | bytes) -> str:
    return strip(s, rhs=True)


def get_default(
    default: Any | None = None,
    default_factory: Callable[[], Any | None] | None = None,
    x: Any | None = None,
) -> Any | None:
    if x is not None:
        return x
    elif default_factory:
        return default_factory()
    else:
        return default


@overload
def make_container(
    x_type: list[Any],
    size: int | None = None,
    index: None = None,
    values: None = None,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> list[Any]: ...


@overload
def make_container(
    x_type: tuple,
    size: int | None = None,
    index: None = None,
    values: None = None,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> tuple: ...


@overload
def make_container(
    x_type: type[Namespace],
    size: None = None,
    index: list[str] | None = None,
    values: list[Any] | None = None,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> Namespace: ...


@overload
def make_container(
    x_type: type[dict],
    size: int | None = None,
    index: list[Any] | None = None,
    values: list[Any] | None = None,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> dict: ...


@overload
def make_mapping(
    x_type: type[Namespace],
    size: None = None,
    index: list[str] | None = None,
    values: list[Any] | None = None,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> Namespace: ...


@overload
def make_mapping(
    x_type: type[dict],
    size: int | None = None,
    index: list[Any] | None = None,
    values: list[Any] | None = None,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> dict: ...


@overload
def make_sequence(
    x_type: list[Any],
    size: int | None = None,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> list[Any]: ...


@overload
def make_sequence(
    x_type: tuple,
    size: int | None = None,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> tuple: ...


def make_sequence(
    x_type: type[list | tuple],
    size: int | None = None,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> list[Any] | tuple:
    def get_default() -> Any | None:
        if default_factory:
            return default_factory()
        else:
            return default

    if size is None:
        return x_type()
    else:
        return x_type([get_default() for _ in range(size)])


def make_mapping(
    x_type: MappingType,
    size: int | None = None,
    index: list | None = None,
    values: list[Any] | None = None,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> dict | Namespace[str, Any]:
    def get_default() -> Any | None:
        if default_factory:
            return default_factory()
        else:
            return default

    if not size and not index:
        return x_type()
    elif size and (index or values):
        raise ValueError("Cannot use size= with either values= or index=")
    elif size:
        if issubclass(x_type, Namespace):
            raise ValueError("Cannot use size with x_type=Namespace")

        return make_mapping(
            x_type,
            size=None,
            index=list(range(size)),
            values=None,
            default=default,
            default_factory=default_factory,
        )
    elif values is None:
        return make_mapping(
            x_type,
            size=None,
            index=index,
            values=[get_default() for _ in range(len(index))],
        )
    elif index is None:
        return make_mapping(
            x_type,
            size=None,
            index=list(range(len(values))),
            values=values,
        )
    elif issubclass(x_type, Namespace):
        return Namespace(data=dict(zip(index, values)))
    elif len(index) != len(values):
        raise ValueError("index= and values= must have the same length")
    else:
        return dict(zip(index, values))


def make_container(
    x_type: ContainerType,
    size: int | None = None,
    index: list[Any] | None = None,
    values: list[Any] | None = None,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> Container:
    if issubclass(x_type, (list, tuple)):
        if values or index:
            raise ValueError("Cannot use values= or index= with tuple | list")

        return make_sequence(
            x_type,
            size=size,
            default=default,
            default_factory=default_factory,
        )

    return make_mapping(
        x_type,
        size=size,
        index=index,
        values=values,
        default=default,
        default_factory=default_factory,
    )


def keys(xs: Container) -> list[int | str]:
    if is_seq(xs):
        return list(range(len(xs)))
    elif is_dict(xs):
        return list(xs.keys())
    else:
        return namespaces.keys(xs)


def items(xs: Container) -> list[tuple[int | str, Any]]:
    if is_seq(xs):
        return list(enumerate(xs))
    elif is_dict(xs):
        return list(xs.items())
    else:
        return namespaces.items(xs)


def values(xs: Container) -> list[Any]:
    if is_seq(xs):
        return xs
    elif is_dict(xs):
        return list(xs.values())
    else:
        return namespaces.values(xs)


def enumeratex(xs: Container) -> Generator:
    yield from items(xs)


def default_reducer_with_index(key: Any, acc: Any, value: Any) -> Any:
    return acc


def default_reducer(acc: Any, value: Any) -> Any:
    return acc


def default_cond(v: Any) -> bool:
    if v:
        return True
    else:
        return False


def default_cond_with_index(key: Any, value: Any) -> bool:
    return default_cond(value)


def default_filter(v: Any) -> bool:
    return default_cond(v)


def default_filter_with_index(key: Any, value: Any) -> bool:
    return default_cond(value)


def default_mapper(v: Any) -> Any:
    return v


def default_mapper_with_index(key: Any, value: Any) -> Any:
    return value


def check_value(v, pcall: bool = False) -> bool:
    if is_error(v):
        if not pcall:
            raise v
        else:
            return False
    else:
        return True


@overload
def reduce(
    tbl: Container,
    init: Any,
    fn: ReducerWithoutIndex,
    index: Literal[False] = False,
    pcall: bool = True,
) -> Any: ...


@overload
def reduce(
    tbl: Container,
    init: Any,
    fn: ReducerWithIndex,
    index: Literal[True] = False,
    pcall: bool = True,
) -> Any: ...


def reduce(
    tbl: Container,
    init: Any,
    fn: Reducer,
    index: bool = False,
    pcall: bool = True,
) -> Any:
    if fn is None:
        if index:
            fn = default_reducer_with_index
        else:
            fn = default_reducer

    res: Any = init
    for k, v in enumeratex(tbl):
        if not check_value(v, pcall=pcall):
            continue
        elif index:
            res = fn(k, res, v)
        else:
            res = fn(res, v)

    return res


def some(x: Container, cond: Callable[[Any], bool] | None = None) -> bool:
    cond = default_cond if cond is None else cond
    for value in values(x):
        if cond(value):
            return True

    return False


def all(x: Container, cond: Callable[[Any], bool] | None = None) -> bool:
    cond = default_cond if cond is None else cond
    for value in values(x):
        if not cond(value):
            return False

    return True


@overload
def foreach(
    tbl: Container,
    apply: Transformer | None = None,
    keep: Filter | None = None,
    exclude: Filter | None = None,
    until: Filter | None = None,
    when: Filter | None = None,
    pcall: bool = False,
    index: bool = False,
    cast: Literal[False] = False,
) -> list[Any] | list[tuple[Any, Any]]: ...


@overload
def foreach(
    tbl: T,
    apply: Transformer | None = None,
    keep: Filter | None = None,
    exclude: Filter | None = None,
    until: Filter | None = None,
    when: Filter | None = None,
    pcall: bool = False,
    index: bool = False,
    cast: Literal[True] = False,
) -> T: ...


def foreach(
    tbl: Container,
    apply: Transformer | None = None,
    keep: Filter | None = None,
    exclude: Filter | None = None,
    until: Filter | None = None,
    when: Filter | None = None,
    pcall: bool = False,
    index: bool = False,
    cast: bool = False,
) -> Container:
    if index:
        apply = default_mapper_with_index if not apply else apply
        keep = default_filter_with_index if not keep else keep
        exclude = default_filter_with_index if not exclude else exclude
        until = default_filter_with_index if not until else until
        when = default_filter_with_index if not when else when
    else:
        apply = default_mapper if not apply else apply
        keep = default_filter if not keep else keep
        exclude = default_filter if not exclude else exclude
        until = default_filter if not until else until
        when = default_filter if not when else when

    def append(
        res: Container,
        k: str | int | None = None,
        v: Any | None = None,
    ) -> None:
        if inherits(res, dict, Namespace):
            res[k] = v
        elif k is not None:
            res.append((k, v))
        else:
            res.append(v)

    res: dict | Namespace | list
    if isinstance(tbl, (dict, Namespace)):
        res = type(tbl)()
    else:
        res = []

    for k, v in enumeratex(tbl):
        if not check_value(v, pcall=pcall):
            continue

        if index:
            if until(k, v):
                break
            elif (when(k, v) and keep(k, v)) and not exclude(k, v):
                append(res, k=k, v=apply(k, v))
        else:
            if until(v):
                break
            elif (when(v) and keep(v)) and not exclude(v):
                append(res, v=apply(v))

    if cast:
        return type(tbl)(res)
    else:
        return res


def each(
    tbl: Container,
    apply: Transformer | None = None,
    keep: Filter | None = None,
    exclude: Filter | None = None,
    until: Filter | None = None,
    when: Filter | None = None,
    pcall: bool = False,
    index: bool = False,
) -> None:
    if index:
        apply = default_mapper_with_index if not apply else apply
        keep = default_filter_with_index if not keep else keep
        exclude = default_filter_with_index if not exclude else exclude
        until = default_filter_with_index if not until else until
        when = default_filter_with_index if not when else when
    else:
        apply = default_mapper if not apply else apply
        keep = default_filter if not keep else keep
        exclude = default_filter if not exclude else exclude
        until = default_filter if not until else until
        when = default_filter if not when else when

    for k, v in enumeratex(tbl):
        if not check_value(
            v,
            pcall=pcall,
        ):
            continue

        if index:
            if until(k, v):
                break
            elif (when(k, v) and keep(k, v)) and not exclude(k, v):
                apply(k, v)
        else:
            if until(v):
                break
            elif (when(v) and keep(v)) and not exclude(v):
                apply(v)


def keep(
    tbl: Container,
    f: Filter,
    exclude: Filter | None = None,
    index: bool = False,
    pcall: bool = False,
) -> Container:
    return foreach(
        tbl,
        keep=f,
        exclude=exclude,
        index=index,
        pcall=pcall,
    )


def exclude(
    tbl: Container,
    f: Filter,
    keep: Filter | None = None,
    index: bool = False,
    pcall: bool = False,
) -> Container:
    return foreach(
        tbl,
        exclude=f,
        keep=keep,
        index=index,
        pcall=pcall,
    )


def apply(
    tbl: Container,
    f: Transformer,
    index: bool = False,
    pcall: bool = False,
) -> Container:
    return foreach(
        tbl,
        apply=f,
        index=index,
        pcall=pcall,
    )


def assoc(
    d: Container,
    ks: Any,
    value: Any = None,
    set: bool = False,
) -> Ok[Any] | Err[KeyError | IndexError]:
    ks = [ks] if not sequence(ks) else ks
    v = d

    for i, k in enumerate(ks[:-1]):
        try:
            v = v[k]
        except Exception as error:
            return Err(
                error,
                dict(obj=d, ks=ks, k=k, index=i),
            )

    k = ks[-1]
    try:
        if set:
            v[k] = value
            return Ok(d)
        else:
            return Ok(v[k])
    except Exception as error:
        metadata = dict(obj=d, ks=ks, level=v, k=ks[-1], index=len(ks) - 1)
        return Err(error, metadata)


def fassoc(
    d: fassocContainer,
    ks: fassocIndex | fassocIndexList,
    value: Any,
    use: fassocContainer = dict,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> Ok[fassocContainer] | Err[fassocError]:
    """Be careful while using this with lists. It will automatically add elements to fill the element key"""
    use_cls = use if use is not None else dict
    ks = [ks] if inherits(ks, str, bytes, int) else ks

    def get_default() -> Any:
        if default_factory:
            return default_factory()
        else:
            return default

    def set_mapping_value(
        x: dict | Namespace,
        k: fassocIndex,
        v: Any,
    ) -> dict[str | int, Any]:
        x[k] = v
        return x

    def set_list_value(
        x: list,
        k: int,
        v: Any,
    ) -> list:
        x_len = len(x)
        if k >= x_len:
            for i in range((k - x_len) + 1):
                x.append(get_default())

        x[k] = v
        return x

    def set_value(
        x: fassocContainer,
        k: fassocIndex,
        v: Any,
    ) -> fassocContainer:
        if not inherits(x, list, dict, Namespace):
            msg = f"Mutable datatype such as list, dict or Namespace expected, got {type(x)}"
            metadata = dict(x=x, k=k, v=v, ks=ks, d=d)
            return Err(ValueError(msg), metadata)
        elif inherits(x, list):
            try:
                return Ok(set_list_value(x, k, v))
            except IndexError as error:
                return Err(error, dict(d=d, ks=ks, x=x, k=k, v=v))
        else:
            return Ok(set_mapping_value(x, k, v))

    def index_into(
        x: fassocContainer,
        k: fassocIndex,
        use: fassocContainer,
    ) -> Ok[fassocContainer] | Err[IndexError]:
        try:
            inside = x[k]
            if container(inside):
                return Ok(inside)
            else:
                return set_value(x, k, use())
        except (IndexError, KeyError, TypeError):
            return set_value(x, k, use())

    tbl = d
    for k in ks[:-1]:
        inner = index_into(tbl, k, use_cls)
        if is_err(inner):
            return inner
        else:
            tbl = inner.unwrap()

    last_key = ks[-1]
    res = index_into(tbl, last_key, use_cls)

    if is_err(res):
        return res
    else:
        set_value(tbl, last_key, value)
        return Ok(d)


def get(
    xs: Container,
    key: int | str | list[int | str],
    pcall: bool = True,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> Any:
    v = assoc(xs, key).unwrap(pcall=pcall)

    if not is_error(v):
        return v
    elif default_factory:
        return default_factory()
    else:
        return default


def get_keys(
    xs: Container,
    *ks: int | str | list[int | str],
    pcall: bool = True,
    index: bool = False,
    default: Any | None = None,
    default_factory: Callable[[], Any] | None = None,
) -> list[Any] | list[tuple[Any, Any]]:
    res = [None for _ in range(len(ks))]
    for i, k in enumerate(ks):
        v = get(
            xs,
            k,
            pcall=pcall,
        )
        if index:
            res[i] = (k, v)
        else:
            res[i] = v

    return res


def has(xs: Container, key: Any) -> bool:
    return is_ok(assoc(xs, key))


def has_keys(
    xs: Container,
    *ks: Any,
    index: bool = False,
) -> list[tuple[Any, bool]] | list[bool]:
    res = []

    for k in ks:
        match assoc(xs, k):
            case Ok():
                if index:
                    res.append((k, True))
                else:
                    res.append(True)
            case Err():
                if index:
                    res.append((k, False))
                else:
                    res.append(False)

    return res


def set_keys(
    xs: Container,
    *keys_and_values: tuple[Any, Any],
    pcall: bool = False,
) -> Container | Exception:
    if len(keys_and_values) == 0:
        return xs

    for k, v in keys_and_values:
        match assoc(xs, k, value=v, set=True):
            case Ok():
                continue
            case Err(error):
                if not pcall:
                    raise error
                else:
                    return error

    return xs


def as_list(xs: Any, force: bool = False) -> list:
    if force:
        return [xs]
    elif sequence(xs):
        return list(xs)
    else:
        return [xs]


def flatten(xs: list | tuple, maxdepth: int = -1) -> list | tuple:
    result = []

    def vector(lst: list | tuple, current_depth: int = 0) -> list:
        nonlocal result
        if current_depth != -1 and current_depth == maxdepth:
            result.append(lst)
            return

        for i, x in enumerate(lst):
            if sequence(x):
                vector(x, current_depth + 1)
            else:
                result.append(x)

    vector(xs, 0)
    if isinstance(xs, tuple):
        return tuple(result)
    else:
        return result


def paste0(*s: str | list[str]) -> str:
    return ("").join(flatten(s))


def paste(*s: str | list[str], collapse: str = " ") -> str:
    return (collapse).join(flatten(s))


def cat(*seqs: list[Any] | tuple) -> list[Any]:
    res = []

    for x in seqs:
        res.extend(list(x))

    return res


def merge(
    dst: dict | Namespace,
    *mappings: dict | Namespace,
    overwrite: bool = True,
) -> dict | Namespace:
    if len(mappings) == 0:
        return dst

    for d in mappings:
        for k, v in items(d):
            if overwrite or (k not in dst):
                dst[k] = v

    return dst


def lmerge(
    dst: dict | Namespace,
    *mappings: dict | Namespace,
) -> dict | Namespace:
    return merge(dst, *mappings, overwrite=False)


def push(
    xs: Sequence,
    *elements: Any,
    index: int | None = None,
) -> Sequence:
    cls = type(xs)
    xs = list(xs)
    xs_len = len(xs)

    if index is None:
        index = xs_len
    elif index < 0:
        index = max(0, xs_len + index)

    if index == xs_len - 1:
        for e in elements:
            xs.append(e)
    else:
        for e in elements[::-1]:
            xs.insert(index, e)

    return cls(xs)


def reverse(xs: dict | tuple | list | str) -> tuple | list | str:
    if isinstance(xs, dict):
        ks = keys(xs)
        res = {}

        for k in ks[::-1]:
            res[k] = xs[k]

        return res
    else:
        return xs[::-1]


def unpush(xs: Sequence, *elements: Any) -> Sequence:
    return push(xs, *elements, index=0)


def extend(
    xs: Sequence,
    *elements: Any,
    index: int | None = None,
    cast: bool = False,
) -> list | tuple:
    cls = type(xs)
    xs = list(xs)
    xs_len = len(xs)
    index = xs_len - 1 if index is None else index
    index = xs_len + index if index < 0 else index

    if index >= xs_len - 1:
        for e in elements:
            if sequence(e):
                xs.extend(list(e))
            else:
                xs.append(e)
    else:
        for e in elements[::-1]:
            if sequence(e):
                xs = push(xs, *e, index=index)
            else:
                xs.insert(index, e)

    if cast:
        return cls(xs)
    else:
        return xs


def lextend(
    xs: Sequence,
    *elements: Any,
    cast: bool = False,
) -> list | tuple:
    cls = type(xs)
    xs = list(xs)

    for e in elements[::-1]:
        if sequence(e):
            xs = unpush(xs, *e)
        else:
            xs.insert(0, e)

    if cast:
        return cls(xs)
    else:
        return xs


def identity(element: Any) -> Any:
    return element


def pop(
    xs: Container,
    index: int | str = -1,
    default: Any | None = None,
    default_factory: Callable | None = None,
    pcall: bool = False,
) -> Ok[Any] | Err[KeyError | IndexError]:
    ys: list
    if isinstance(xs, tuple):
        ys = list(xs)
    else:
        ys = xs

    metadata = dict(x=xs, index=index)
    if isinstance(ys, dict) and isinstance(index, int):
        try:
            index = list(ys.keys())[index]
        except (IndexError, KeyError) as error:
            if default_factory:
                return Ok(default_factory(), metadata)
            elif default is not None:
                return Ok(default, metadata)
            elif pcall:
                return Err(error, metadata)
            else:
                raise_error(error, msg=error_msg(error), args=metadata)

    try:
        return Ok(ys.pop(index), metadata)
    except (IndexError, KeyError) as error:
        if default_factory:
            return Ok(default_factory(), metadata)
        elif default is not None:
            return Ok(default, metadata)
        elif pcall:
            return Err(error, metadata)
        else:
            raise_error(error, msg=error_msg(error), args=metadata)


def shift(
    xs: Container,
    default: Any | None = None,
    default_factory: Callable | None = None,
    pcall: bool = False,
) -> Ok[Any] | Err[KeyError | IndexError]:
    return pop(
        xs,
        index=0,
        default=default,
        default_factory=default_factory,
        pcall=pcall,
    )


def popn(
    xs: Container,
    n: int = 1,
    index: int | str = -1,
    reverse: bool = False,
    pcall: bool = False,
    default_factory: Callable | None = None,
    default: Any | None = None,
) -> Ok[list[Any]] | Err[KeyError | IndexError]:
    res = []
    for i in range(n):
        match pop(
            xs,
            index=index,
            default=default,
            default_factory=default_factory,
            pcall=pcall,
        ):
            case Ok(value):
                res.append(value)
            case Err() as err:
                if not pcall:
                    raise_error(
                        err.value,
                        msg=error_msg(err.value),
                        args=err.metadata,
                    )
                else:
                    return err

    metadata = dict(x=xs, index=index, n=n)
    if reverse:
        return Ok(res[::-1], metadata)
    else:
        return Ok(res, metadata)


def shiftn(
    xs: list | tuple | dict,
    n: int = 1,
    index: int = -1,
    reverse: bool = False,
    pcall: bool = False,
    default: Callable | None = None,
) -> Ok[list[Any]] | Err[IndexError | KeyError | ValueError]:
    return popn(
        xs,
        n,
        index=0,
        reverse=reverse,
        pcall=pcall,
        default=default,
    )


def and_grep(
    s: str,
    *pattern: str | re.Pattern,
    flags=re.I,
) -> bool:
    for pat in pattern:
        if not re.search(pat, s, flags=flags):
            return False

    return True


def or_grep(
    s: str,
    *pattern: str | re.Pattern,
    flags=re.I,
) -> str | re.Pattern | None:
    for pat in pattern:
        if re.search(pat, s, flags=flags):
            return pat


def strfind(
    s: str,
    pattern: re.Pattern | str,
    flags=re.I,
    start: int = 0,
) -> tuple[int, int] | None:
    s_required = s[start:]
    if m := re.search(pattern, s_required, flags=flags):
        span = m.span(0)
        return (span[0] + start, span[1] + start)


def split(
    s: str,
    pattern: Pattern | str,
    **kwargs: str | int,
) -> list[str]:
    return re.split(pattern, s, **kwargs)


def splitlines(
    s: str,
    pattern: str | Pattern = r"\n",
    **kwargs,
) -> list[str]:
    return split(s, pattern, **kwargs)


def strmatch(
    s: str,
    *pattern: str | Pattern,
    **kwargs,
) -> re.Match | None:
    for pat in flatten(pattern, -1):
        if m := re.search(pat, s, **kwargs):
            return m


def grep_check_value(
    key: Any,
    x: Any,
    *patterns: grepPattern,
    pcall: bool = False,
    index: bool = False,
    match_index: bool = False,
    invert: bool = False,
) -> bool:
    if inherits(x, Exception):
        if pcall:
            return False
        else:
            raise x

    x = key if match_index else x
    x = str(x)

    for pattern in patterns:
        if is_pattern(pattern):
            ok = re.search(x, pattern, flags=re.I)
            ok = not ok if invert else ok

            if ok:
                return True
        elif callable(pattern):
            ok = pattern(key, x) if index else pattern(x)
            ok = not ok if invert else ok

            if ok:
                return True
        else:
            raise ValueError(
                f"pattern: Expected callable or str | bytes | re.Pattern, got {type(pattern)}"
            )

    return False


def grep(
    x: grepContainer,
    *patterns: grepPattern,
    value: bool = False,
    invert: bool = False,
    pcall: bool = False,
    index: bool = False,
    match_index: bool = False,
) -> grepReturn:
    is_tup = is_tuple(x)
    res = type(x)() if not is_tup else []

    for k, v in enumeratex(x):
        if grep_check_value(
            k,
            v,
            *patterns,
            pcall=pcall,
            index=index,
            match_index=match_index,
            invert=invert,
        ):
            if is_list(res):
                if value:
                    res.append(v)
                else:
                    res.append(True)
            elif value:
                res[k] = v
            else:
                res[k] = True

    if is_tup:
        return tuple(res)
    else:
        return res


def grepv(
    x: grepContainer,
    *pattern: str | Pattern,
    **kwargs,
) -> grepReturn:
    return grep(x, *pattern, invert=True, **kwargs)


def cut(
    x: Container,
    start: int = 0,
    end: int = None,
    step: int = 1,
    include_end: bool = False,
) -> Container:
    x_len = len(x)
    end = x_len if end is None else end
    end = (x_len + end) if end < 0 else end
    start = (x_len + start) if start < 0 else start
    end = end + 1 if include_end else end

    if (start < 0 or end < 0) or (start > end or start > x_len) or (end > x_len):
        raise IndexError(dict(start=start, end=end))

    if is_seq(x):
        return x[start:end:step]
    else:
        ks = tuple(keys(x))
        res = type(x)()

        for k in ks[start:end:step]:
            res[k] = x[k]

        return res


def chunk(x: Container, chunk_size: int) -> list[Container]:
    if is_map(x):
        ks = tuple(keys(x))
        chunked = chunk(ks, chunk_size=chunk_size)
        return [dict(zip(ks, [x[k] for k in ks])) for ks in chunked]

    res = []
    for i in range(0, len(x), chunk_size):
        res.append(x[i : i + chunk_size])

    return res


def partition(
    x: Sequence,
    n: int | Callable[[Any], bool] | Callable[[int, Any], bool],
) -> list[list[Any]] | tuple[list[Any], list[Any]]:
    if callable(n):
        res = ([], [])
        for i, elem in enumerate(x):
            if not n(elem):
                res[1].append(elem)
            else:
                res[0].append(elem)
        return res
    else:
        res = []
        x_len = len(x)

        for i in range(0, x_len, ceil(x_len / n)):
            res.append(x[i : i + n])

        return res


def car(x: Container) -> Any | None:
    if is_map(x):
        try:
            return x[tuple(keys(x))[0]]
        except (IndexError, KeyError):
            return

    try:
        return x[0]
    except IndexError:
        return


def cdr(x: Container) -> Sequence:
    return cut(x, start=1)


def butlast(x: Container) -> Any:
    is_dict = isinstance(x, dict)
    if len(x) < 1:
        if is_dict:
            return {}
        elif isinstance(x, tuple):
            return tuple()
        else:
            return []

    return cut(x, end=-1)


def head(x: Container, n: int = 1) -> Sequence:
    assert n >= 0
    if len(x) <= n:
        return x

    return [x[i] for i in range(n)]


def tail(x: Sequence, n: int = 1) -> Sequence:
    assert n >= 0

    x_len = len(x)
    if x_len <= n:
        return x

    return [x[i] for i in range(x_len - n, x_len)]


def seq(start: int, end: int, step: int = 1) -> list[int]:
    return [x for x in range(start, end, step)]


def startswith(s: str, pattern: str | Pattern, **kwargs) -> re.Match | None:
    return re.match(pattern, s, **kwargs)


def endswith(s: str, pattern: str | Pattern, **kwargs) -> re.Match | None:
    return re.search(pattern + "$", s, **kwargs)


def is_int(s: str, strip_whitespace: bool = False) -> bool:
    if strip_whitespace:
        s = re.sub(r"\s+", "", s)

    return grep(s, "^[0-9]+$") is not None


def as_int(s: str, strip_whitespace: bool = False) -> int | None:
    if is_int(s, strip_whitespace=strip_whitespace):
        s = re.sub(r"\s+", "", s)
        try:
            return int(s)
        except Exception:
            return


def is_float(s: str, strip_whitespace: bool = False) -> bool:
    if strip_whitespace:
        s = re.sub(r"^\s+", "", s)
    return grep(s, "^[0-9]+[.][0-9]+$") is not None


def as_float(s: str, strip_whitespace: bool = False) -> float | None:
    if strip_whitespace:
        s = re.sub(r"\s+", "", s)

    try:
        return float(s)
    except Exception:
        return


def sed(
    s: str,
    *patterns_and_replacements: tuple[str, str],
    **kwargs,
) -> str:
    for pattern, repl in patterns_and_replacements:
        s = re.sub(pattern, repl, s, **kwargs)

    return s


def fzf(
    tbl: dict[str, Any] | list | tuple,
    lalign: bool = True,
    ralign: bool = False,
    center: bool = False,
    bin: str | None = None,
    skip_index: bool = False,
) -> list:
    lookup = dict()
    _tbl = {}
    longest = 0
    display = []
    index = keys(tbl)
    _dict = isinstance(tbl, dict)

    if not skip_index:
        for k in index:
            k = str(k)
            k_len = len(k)

            if longest < k_len:
                longest = k_len

    for k in index:
        v = tbl[k]
        if not skip_index:
            if ralign:
                k = f"{str(k):>{longest}} | {str(v)}"
            elif lalign:
                k = f"{str(k):<{longest}} | {str(v)}"
            else:
                k = f"{str(k):^{longest}} | {str(v)}"

            lookup[k] = v
            display.append(k)
        elif _dict:
            str_k = str(k)
            lookup[str_k] = k
            display.append(str_k)
        else:
            v = str(v)
            lookup[v] = k
            display.append(v)

    _fzf = FzfPrompt(executable_path=bin)
    choice = _fzf.prompt(display, fzf_options="--multi")

    return [tbl[lookup[k]] for k in choice]


def printf(s: str, *args, **kwargs) -> None:
    return s.format(*args, **kwargs)


def sprintf(s: str, *args, **kwargs) -> str:
    return s.format(*args, **kwargs)


def is_empty(x: str | bytes | list | tuple | dict | Namespace | Module) -> bool:
    return len(x) == 0


def is_not_empty(
    x: str | bytes | list | tuple | dict | Namespace | Module,
) -> bool:
    return len(x) > 0


def process_value(
    key: str | int | bytes | None = None,
    value: Any | None = None,
    pcall: bool = False,
) -> bool:
    if is_error(value):
        if pcall:
            return False
        else:
            raise value
    else:
        return True


def lapply(
    x: list | tuple,
    f: Transformer,
    index: bool = False,
    pcall: bool = False,
) -> list | tuple:
    res = []
    for i, elem in enumerate(x):
        if process_value(i, elem, pcall=pcall):
            if index:
                res.append(f(i, elem))
            else:
                res.append(f(elem))

    return type(x)(res)


def mapply(
    x: dict | Namespace,
    f: Transformer,
    index: bool = False,
    pcall: bool = False,
) -> dict | Namespace:
    res = type(x)()
    for k, v in items(x):
        if process_value(k, v, pcall=pcall):
            if index:
                res[k] = f(k, v)
            else:
                res[k] = f(v)

    return res


filtermap = keep
is_blank = is_empty
is_not_blank = is_not_empty


__all__ = [
    "and_grep",
    "as_float",
    "as_int",
    "as_list",
    "assoc",
    "butlast",
    "car",
    "cat",
    "cdr",
    "chomp",
    "chunk",
    "container",
    "copy",
    "cut",
    "deepcopy",
    "each",
    "endswith",
    "extend",
    "fassoc",
    "filtermap",
    "flatten",
    "foreach",
    "fzf",
    "get",
    "get_keys",
    "grep",
    "grepv",
    "has",
    "has_keys",
    "head",
    "is_blank",
    "is_empty",
    "is_not_blank",
    "items",
    "keys",
    "lapply",
    "lextend",
    "lmerge",
    "lstrip",
    "make_container",
    "make_mapping",
    "make_sequence",
    "mapply",
    "merge",
    "or_grep",
    "partition",
    "paste",
    "paste0",
    "pop",
    "popn",
    "printf",
    "push",
    "reverse",
    "rstrip",
    "seq",
    "sequence",
    "set_keys",
    "shift",
    "shiftn",
    "split",
    "splitlines",
    "sprintf",
    "startswith",
    "strfind",
    "strip",
    "strmatch",
    "tail",
    "unpush",
    "values",
]
