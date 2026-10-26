#!/usr/bin/env python

import re
import os
import shlex
import sys
import io
import shutil

from typing import Callable, Self, Any
from functools import partial
from argparse import ArgumentParser
from termcolor import cprint
from collections import defaultdict

from .table import keys, values
from .result import (
    rsafe,
    Ok,
    Err,
    rpcall,
    utils as result,
    is_err,
    is_ok,
    is_result,
    rthread,
)
from .is_a import is_a, module, Namespace, modules, struct
from .error import utils as errors

Value = str | bytes | int | float | bool
ValueList = list[Value]
ProcessedOk = Ok[Value | ValueList]
ProcessedErr = Err[ValueError]
Processor = Callable[[str, Value | ValueList], Value | ValueList | None]
ProcessorSpec = str | Processor | tuple[str | Processor, dict[str, Any]]
WrappedProcessor = Callable[[Value | ValueList], Value | ValueList | None]
ParsedArgs = Ok[tuple[Namespace[Value | ValueList], list[Value]]]
PathPattern = re.Pattern | str | bytes
PathPatternList = list[PathPattern]
KeywordSpec = tuple[tuple[str, str] | str, Namespace[Any]]


@module
class PROCESSOR:
    @staticmethod
    def is_choice(x: str, choices: list[str] | None = None) -> str:
        if not is_a.list(choices):
            raise ValueError(f"Expected choices as list, got {type(choices)}")
        elif x not in choices:
            raise ValueError(f"Expected any of {(', ').join(choices)}, got {x}")
        else:
            return x

    @staticmethod
    def is_float(
        x: float,
        start: float | None = None,
        end: float | None = None,
    ) -> float:
        if start and end:
            if x > end or x < start:
                raise ValueError(f"{x} is not between {start} and {end}")
            else:
                return x
        elif start and x < start:
            raise ValueError(f"{x} is not greater than {start}")
        elif end and x > end:
            raise ValueError(f"{x} is not smaller than {end}")
        else:
            return x

    @staticmethod
    def is_int(x: int, start: int | None = None, end: int | None = None) -> int:
        if start and end:
            if x > end or x < start:
                raise ValueError(f"{x} is not between {start} and {end}")
            else:
                return x
        elif start and x < start:
            raise ValueError(f"{x} is not greater than {start}")
        elif end and x > end:
            raise ValueError(f"{x} is not smaller than {end}")
        else:
            return x

    @staticmethod
    def is_path(x: str | bytes) -> str | bytes:
        if not os.path.exists(x):
            raise ValueError(f"{x} is not a valid path")
        else:
            return x

    @staticmethod
    def is_file(x: str | bytes) -> str | bytes:
        if not os.path.isfile(x):
            raise ValueError(f"{x} is not a valid file")
        else:
            return x

    @staticmethod
    def is_dir(x: str | bytes) -> str | bytes:
        if not os.path.isdir(x):
            raise ValueError(f"{x} is not a valid directory")
        else:
            return x

    @staticmethod
    def ls_dir(
        x: str | bytes,
        patterns: PathPattern | PathPatternList | None = None,
    ) -> list[str | bytes]:
        PROCESSOR.is_dir(x)

        res = [os.path.realpath(v) for v in os.listdir(x)]
        if patterns:

            def test(path: str | bytes) -> bool:
                for p in patterns:
                    if re.search(x, path, flags=re.I):
                        return True
                return False

            res = list(filter(test, res))

        return res

    @staticmethod
    def readlines(
        x: str,
        chomp: bool = False,
        **kwargs,
    ) -> list[str] | list[bytes]:
        PROCESSOR.is_file(x)
        with open(x, **kwargs) as fh:
            lines = fh.readlines()
            if chomp:
                return [x.strip() for x in lines]
            else:
                return lines

    @staticmethod
    def read(x: str, chomp: bool = False, **kwargs) -> str | bytes:
        PROCESSOR.is_file(x)
        with open(x, **kwargs) as fh:
            text = fh.read()
            if chomp:
                return text.strip()
            else:
                return text

    @staticmethod
    def cp(src: str, dst: str | None = None, makedirs: bool = False) -> bool:
        if not dst:
            raise ValueError(
                f"No destination file/directory provided for {src}"
            )

        dst_dir = os.path.dirname(dst)
        if not os.path.isdir(dst_dir):
            if makedirs:
                os.makedirs(dst_dir, exist_ok=True)
            else:
                raise ValueError(
                    f"Destionation directory {dst_dir} does not exist"
                )

        shutil.copy(src, dst)
        return True

    @staticmethod
    def rename(
        src: str,
        dst: str | None = None,
        makedirs: bool = False,
    ) -> bool:
        if not dst:
            raise ValueError("No destination file/directory provided for {src}")

        dst_dir = os.path.dirname(dst)
        if not os.path.isdir(dst_dir):
            if makedirs:
                os.makedirs(dst_dir, exist_ok=True)
            else:
                raise ValueError(
                    f"Destionation directory {dst_dir} does not exist"
                )

        os.rename(src, dst)
        return True

    @staticmethod
    def rm(
        path: str,
        recursive: bool = False,
    ) -> bool:
        dir = os.path.dirname(path)
        if not os.path.exists(dir):
            raise ValueError(f"Nonexistent path: {path}")

        shutil.rmtree(path)
        return True


@module
class utils:
    @staticmethod
    def get_name(*option: str) -> str:
        match len(option):
            case 1:
                o = option[0]
                o = o.replace("-", "_")
                o = re.sub(r"^_+", "", o)
                return o
            case 0:
                raise ValueError("No option name provided")
            case x if x > 0:
                lens = list(map(len, option))
                max_ind = lens.index(max(lens))
                return utils.get_name(option[max_ind])

    @staticmethod
    def make_processor(
        option: str,
        f: Processor | str,
        **kwargs,
    ) -> WrappedProcessor:
        option = utils.get_name(*option)
        f = PROCESSOR[f] if is_a.str(f) else f

        def function(value: Value | ValueList) -> Value | ValueList | None:
            nonlocal option
            nonlocal f

            res: ProcessedOk | ProcessedErr
            f = PROCESSOR[f] if is_a.str(f) else f
            f = partial(f, **kwargs)

            if is_a.list(value):
                res = rpcall(lambda vs: list(map(f, vs)), value)
            else:
                res = rpcall(f, value)

            if is_err(res):
                msg = res.get_message()
                option = option.replace("_", "-")
                option = f"--{option}" if len(option) > 1 else f"-{option}"
                msg = f"{option}: {msg}"

                return Err(ValueError(msg))
            else:
                if res.value is None:
                    return Ok(value, res.metadata)
                else:
                    return res

        return function

    @staticmethod
    def make_processors(option: str, *fs: ProcessorSpec) -> WrappedProcessor:
        def mkprocessor(f: ProcessorSpec) -> WrappedProcessor:
            match f:
                case (use, dict(kwargs)):
                    use = PROCESSOR[use] if is_a.str(use) else use
                    use = partial(use, **kwargs)
                    return utils.make_processor(option, use)
                case str(use):
                    return utils.make_processor(option, PROCESSOR[use])
                case use if callable(use):
                    return utils.make_processor(option, use)
                case use:
                    msg = f"Expected type ProcessorSpec, got {use}"
                    raise ValueError(msg, dict(f=use, option=option))

        def function(value: Value | ValueList) -> Value | ValueList | None:
            if is_result(value):
                value = value.unwrap()

            processors = list(map(mkprocessor, fs))
            return rthread(value, *processors)

        return function


class OptionParser:
    utils = utils
    PROCESSOR = PROCESSOR

    def __init__(self, prog: str, usage: str | None = None) -> None:
        self.prog = prog
        self.usage = usage
        self.parser: ArgumentParser | None = None
        self.processor: dict[str, list[Processor]] = defaultdict(lambda: [])
        self.positional_processor: list[Processor] = []
        self.keyword_spec: Namespace[KeywordSpec] = Namespace()
        self.setup_done: bool = False

    def assert_setup_done(self) -> None:
        if not self.setup_done:
            raise AssertionError(".setup() is not run yet")

    def setup(self, **kwargs) -> None:
        self.parser = ArgumentParser(prog=self.prog, usage=self.usage, **kwargs)
        self.setup_done = True

    def on(
        self,
        option: str | tuple[str, str],
        *processors: ProcessorSpec,
        **kwargs,
    ) -> Self:
        self.assert_setup_done()

        option = [option] if is_a.str(option) else option
        name = utils.get_name(*option)
        self.parser.add_argument(*option, **kwargs)
        self.keyword_spec[name] = (option, Namespace(kwargs))
        self.attach(*processors, option=option)

        return self

    def attach(
        self,
        *processors: str | Processor | tuple[Processor | dict[str, Any]],
        option: str | tuple[str, str] | None = None,
        name: str | None = None,
    ) -> Self:
        self.assert_setup_done()

        option = "POSITIONAL" if option is None else option
        option = [option] if is_a.str(option) else option
        processor = utils.make_processors(option, *processors)

        if option == "POSITIONAL":
            self.positional_processor.append(processor)
        else:
            name = name if name is not None else utils.get_name(*option)
            self.processor[name].append(processor)

        return self

    def attach1(
        self,
        processor: str | Processor,
        option: str | tuple[str, str] | None = None,
        name: str | None = None,
        **kwargs,
    ) -> Self:
        self.assert_setup_done()

        option = "POSITIONAL" if option is None else option
        option = [option] if is_a.str(option) else option
        processor = utils.make_processor(option, processor, **kwargs)

        if option == "POSITIONAL":
            self.positional_processor.append(processor)
        else:
            name = name if name is not None else utils.get_name(*option)
            self.processor[name].append(processor)

        return self

    def process(
        self,
        parsed_keyword: dict[str, Any],
        parsed_positional: list[str],
    ) -> ParsedArgs | Err[ValueError]:
        self.assert_setup_done()

        positional = parsed_positional
        positional = rthread(positional, *self.positional_processor)

        if is_err(positional):
            return positional
        else:
            positional = positional.unwrap()

        keyword = parsed_keyword.copy()
        for option, processors in self.processor.items():
            if not is_a.seq(processors):
                processors = [processors]

            kvalues = keyword[option]
            if (
                kvalues is not None
                or type(kvalues) is list
                and len(kvalues) > 0
            ):
                kvalues = rthread(kvalues, *processors)
                if is_err(kvalues):
                    return kvalues
                else:
                    keyword[option] = kvalues.unwrap()

        return Ok((Namespace(keyword), positional))

    def parse_args(
        self,
        args: list[str] | str | None = None,
        exit_on_error: bool = False,
        exit_on_help: bool = False,
    ) -> ParsedArgs | Err[ValueError]:
        self.assert_setup_done()

        args = sys.argv[1:] if is_a.na(args) else args
        args = shlex.split(args) if is_a.str(args) else args
        parser = self.parser

        if "-h" in args or "--help" in args:
            with io.StringIO() as fh:
                parser.print_help(file=fh)
                if exit_on_help:
                    print(fh.getvalue())
                    sys.exit(0)
                else:
                    return Ok((Namespace({"help": fh.getvalue()}), []))

        try:
            keyword, positional = parser.parse_known_args(args)
            res = self.process(keyword.__dict__, positional)

            if is_err(res):
                if exit_on_error:
                    print(errors.get_msg(res.value))
                    sys.exit(1)
                else:
                    return res
            else:
                return res
        except Exception as e:
            if exit_on_error:
                print(errors.get_msg(e))
                sys.exit(1)
            else:
                return Err(e)


# def validate_input(*xs: str) -> Result:
#     ok = False not in list(map(os.path.exists, xs))
#     if ok:
#         return Ok(xs)
#     else:
#         return Err(FileNotFoundError(xs), dict(files=xs))
#
#
# parser = OptionParser("test-something")
# parser.setup()
# parser.on(["-i", "--input"], PROCESSOR.readlines, nargs="+")
# keyword = parser.parse_args()
# print(keyword[0])
# [keyword, positional] = parser.parse_args(
#     ["-i", os.getenv("HOME") + "/.bashrc"]
# ).unwrap()
# keyword
# keyword.input
# positional
# parser.keyword_specs.input
# print(mod)

__all__ = ["OptionParser"]
