import os
import re
import sys

from typing import Callable, Self, Any, Generator, Sequence, Literal
from termcolor import cprint
from functools import partial
from dataclasses import dataclass

# from prompt_toolkit import prompt
from prompt_toolkit import print_formatted_text as print
from prompt_toolkit import PromptSession
from prompt_toolkit.history import FileHistory
from prompt_toolkit.completion import NestedCompleter, WordCompleter
from prompt_toolkit.validation import Validator, ValidationError
from prompt_toolkit.styles import Style

from .is_a import (
    module,
    namespace,
    is_a,
    field,
    namespaces,
    inherits,
)
from .error import utils as errors
from .table import table
from .result import (
    Result,
    Ok,
    Err,
    rpcall,
    rsafe,
    is_err,
    is_ok,
)

WordCompleterFun = Callable[[], Generator]
ValidatorFun = Callable[[str], ValidationError | str | None]
Completer = WordCompleterFun | NestedCompleter | WordCompleter
Pattern = str | bytes | re.Pattern
PatternList = list[Pattern]

DEFAULT_HISTORY_FILE = os.path.join(
    os.getenv("HOME"),
    ".local",
    "state",
    "python_input_history.txt",
)


def make_validator(
    *fs: ValidatorFun,
    error_message: str,
    move_cursor_to_end: bool = True,
    **kwargs,
) -> Validator:
    def inner(value: str) -> Literal[True]:
        curpos = len(value) if move_cursor_to_end else 0

        for f in fs:
            try:
                ok = f(value, **kwargs)
                if is_a.str(ok):
                    error_msg = ok
                    raise ValidationError(curpos, error_msg)
                elif isinstance(ok, ValidationError):
                    raise ok
                elif isinstance(ok, Exception):
                    raise ValidationError(curpos, (ok))
                elif not ok:
                    raise ValidationError(curpos, error_message)
            except ValidationError as error:
                raise error
            except Exception as error:
                raise ValidationError(curpos, errors.get_msg(error))

        return True

    inner.DEFINITION = fs
    return Validator.from_callable(inner)


def as_validator(
    error_message: str,
    move_cursor_to_end: bool = True,
    **kwargs,
) -> Callable[[ValidatorFun], Validator]:
    def inner(f: ValidatorFun) -> Validator:
        return make_validator(
            f,
            error_message=error_message,
            move_cursor_to_end=move_cursor_to_end,
        )

    return inner


def make_completer(
    f: list[str] | WordCompleterFun,
    ignore_case: bool = True,
    match_middle: bool = False,
    **kwargs,
) -> WordCompleter:
    def use() -> list[str]:
        if is_a.list(f):
            return f
        else:
            try:
                return f(**kwargs)
            except Exception:
                return []

    return WordCompleter(
        use,
        ignore_case=ignore_case,
        match_middle=match_middle,
    )


def as_completer(
    ignore_case: bool = True,
    match_middle: bool = False,
    **kwargs,
) -> Callable[[WordCompleterFun], WordCompleter]:
    def decorator(f: list[str] | WordCompleterFun) -> WordCompleter:
        return make_completer(
            f,
            ignore_case=ignore_case,
            match_middle=match_middle,
            **kwargs,
        )

    return decorator


def make_dir_completer(
    x: str,
    pattern: Pattern | PatternList,
    ignore_case: bool = True,
    match_middle: bool = False,
) -> WordCompleter:
    pattern = [pattern] if not is_a.list(pattern) else pattern

    def function() -> list[str]:
        nonlocal x
        if not os.path.isdir(x):
            return []

        x = os.path.realpath(x)
        res = []

        for f in os.listdir(x):
            f = os.path.join(x, f)
            for p in pattern:
                if re.search(p, f, flags=re.I):
                    res.append(f)

        return res

    return WordCompleter(
        function,
        ignore_case=ignore_case,
        match_middle=match_middle,
    )


def merge_completers(
    **completers: NestedCompleter | WordCompleter,
) -> NestedCompleter:
    return NestedCompleter(completers)


def make_prompt_history(
    filename: str = DEFAULT_HISTORY_FILE,
) -> FileHistory | None:
    dir = os.path.dirname(filename)
    if not os.path.isdir(dir):
        os.makedirs(dir, exist_ok=True)
    return FileHistory(filename)


@module
class VALIDATOR:
    new = make_validator

    @as_validator("Input must be empty")
    @staticmethod
    def is_empty(x: str) -> bool:
        return len(x) == 0

    @as_validator("Input cannot be empty")
    @staticmethod
    def is_not_empty(x: str) -> bool:
        return len(x) > 0

    @as_validator("Input is not a decimal")
    @staticmethod
    def is_float(x: str) -> bool:
        try:
            _ = float(x)
            return True
        except ValueError:
            return False

    @as_validator("Input is not an integer")
    @staticmethod
    def is_int(x: str) -> bool:
        try:
            _ = int(x)
            return True
        except ValueError:
            return False

    @as_validator("Input is not a decimal")
    @staticmethod
    def is_float_list(x: str) -> bool:
        try:
            for elem in table.split(x, r"\s+"):
                _ = float(elem)
            return True
        except ValueError:
            return False

    @as_validator("Input is not an integer")
    @staticmethod
    def is_int_list(x: str) -> bool:
        try:
            for elem in table.split(x, r"\s+"):
                _ = int(elem)
            return True
        except ValueError:
            return False

    @as_validator("Not a valid path")
    @staticmethod
    def is_path(x: str) -> bool:
        return os.path.exists(x)

    @as_validator("Not a valid filename")
    @staticmethod
    def is_file(x: str) -> bool:
        return os.path.isfile(x)

    @as_validator("Not a valid directory")
    @staticmethod
    def is_dir(x: str) -> bool:
        return os.path.isdir(x)


@module
class utils:
    "Prompt utilities to make life easy for building prompt tools"

    as_validator = staticmethod(as_validator)
    as_completer = staticmethod(as_completer)
    make_validator = staticmethod(make_validator)
    make_completer = staticmethod(make_completer)
    make_dir_completer = staticmethod(make_dir_completer)
    make_prompt_history = staticmethod(make_prompt_history)


@dataclass
class Prompt:
    utils = utils
    VALIDATOR = VALIDATOR
    history_file: str = field.str(DEFAULT_HISTORY_FILE)

    def __post_init__(self) -> None:
        self.history: FileHistory = make_prompt_history(self.history_file)
        self.session: PromptSession | None = None
        self.setup_done: bool = False
        self.completer: dict = {}
        self.validator: namespace[Validator] = table.copy(VALIDATOR)

    def assert_setup_done(self) -> None:
        if not self.setup_done:
            raise AssertionError(
                "<object>.init(*args, **kwargs) has not been run"
            )

    def setup(self, *args, **kwargs) -> None:
        if self.history:
            self.session = PromptSession(*args, history=self.history, **kwargs)
        else:
            self.session = PromptSession(*args, **kwargs)

        self.setup_done = True
        return self

    def add_validator(
        self,
        name: str,
        f: ValidatorFun,
        error_message: str | None = None,
        move_cursor_to_end: bool | None = None,
        **kwargs,
    ) -> Self:
        self.validator[name] = make_validator(
            f,
            error_message=error_message,
            move_cursor_to_end=move_cursor_to_end,
        )
        return self

    def add_completer(
        self,
        completer: list[str]
        | WordCompleterFun
        | WordCompleter
        | NestedCompleter,
        *cmd: str,
        ignore_case: bool = True,
        match_middle: bool = False,
        **kwargs,
    ) -> Self:
        cmds = self.completer
        for c in cmd[:-1]:
            if not cmds.get(c):
                cmds[c] = {}
            cmds = cmds[c]

        if inherits(completer, WordCompleter, NestedCompleter):
            cmds[cmd[-1]] = completer
        else:
            cmds[cmd[-1]] = make_completer(
                completer,
                ignore_case=ignore_case,
                match_middle=match_middle,
            )

        return self

    def has_completer(self, *cmd: str, assert_exists: bool = False) -> bool:
        ok = table.has(self.completer, cmd)
        if not ok and assert_exists:
            raise KeyError(cmd)
        else:
            return ok

    def get_completer(
        self,
        *cmd: str,
        assert_exists: bool = False,
    ) -> NestedCompleter | WordCompleter | None:
        if self.has_completer(*cmd):
            completer = table.get(self.completer, cmd)
            if is_a.dict(completer):
                return NestedCompleter(completer)
            else:
                return completer

    def get_validator(
        self,
        name: str,
        assert_exists: bool = False,
    ) -> Validator | None:
        if name not in self.validator:
            if assert_exists:
                raise KeyError(name)
        else:
            return self.validator[name]

    def input(
        self,
        prompt: str = "%",
        message: str | None = None,
        multiline: bool = False,
        validator: str
        | tuple[ValidatorFun, dict]
        | tuple[ValidatorFun, str, dict] = None,
        completer: str | None = None,
        apply: Callable[[str], any] = lambda x: x,
        default: Any | None = None,
        default_factory: Callable[[], Any] | None = None,
        **kwargs,
    ) -> str | None:
        self.assert_setup_done()

        _validator = validator
        _completer = completer

        if validator:
            match validator:
                case str(x):
                    validator = self.get_validator(x, assert_exists=True)
                case (x, dict(vkwargs)) if callable(x):
                    validator = make_validator(x, **vkwargs)
                case (x, str(error_message), dict(vkwargs)) if callable(x):
                    validator = make_validator(
                        x, error_message=error_message, **vkwargs
                    )
                case x:
                    raise ValueError(
                        f"Expected str | tuple[str, dict], got {x}"
                    )

        if completer:
            completer = self.get_completer(completer)

        if not message:
            prompt = f"{prompt} "
        else:
            prompt = f"{message} {prompt} "

        style = Style.from_dict(
            {
                "frame.border": "#ffffff",
                "multiline": "#0f52ba",
                "prompt": "#ff0000",
            }
        )

        def get_multiline_message() -> list:
            return [
                ("class:multiline", "[multiline] "),
                ("class:prompt", prompt),
            ]

        def get_message() -> list:
            return [("class:prompt", prompt)]

        def get_response() -> str:
            if multiline:
                return self.session.prompt(
                    get_multiline_message(),
                    style=style,
                    multiline=True,
                    prompt_continuation=">> ",
                    completer=completer,
                    validator=validator,
                    validate_while_typing=True,
                    **kwargs,
                )
            else:
                return self.session.prompt(
                    get_message(),
                    style=style,
                    completer=completer,
                    validator=validator,
                    validate_while_typing=True,
                    **kwargs,
                )

        try:
            response = get_response()
        except KeyboardInterrupt:
            sys.stdout.flush()
            cprint("KeyboardInterrupt", "red")
            return self.input(
                prompt=prompt,
                message=message,
                apply=apply,
                multiline=multiline,
                validator=_validator,
                completer=_completer,
                **kwargs,
            )
        except EOFError:
            sys.stdout.flush()
            return

        response = response.strip()
        if len(response) == 0:
            if default_factory:
                return default_factory()
            else:
                return default
        else:
            return apply(response)


# session: Prompt = Prompt()
# session.setup()
# session.add_completer(lambda: ["world", "siddhant", "laudu"], "hello", "world")
# session.input(
#     multiline=True, completer="hello", validator="is_not_empty", default=1
# )

__all__ = ["Prompt"]
