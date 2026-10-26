import subprocess

from subprocess import (
    CompletedProcess,
    CalledProcessError,
    Popen,
    run,
    check_output,
)
from collections import namedtuple
from typing import Literal, Callable, Any, overload
from dataclasses import dataclass

from .table import strip
from .result import Result, Ok, Err
from .error import utils as errors
from .is_a import module, field


StrOutput = str | bytes
ListStrOutput = list[StrOutput]

ProcessOutput: tuple[
    CompletedProcess,
    StrOutput | ListStrOutput,
    StrOutput | ListStrOutput,
] = namedtuple(
    "ProcessOutput",
    ("process", "stdout", "stderr"),
    defaults=(None, None, None),
)
ProcessError = CalledProcessError | FileNotFoundError


@overload
def system(
    cmd: ListStrOutput | StrOutput,
    capture: Literal[True] = True,
    splitlines: Literal[True] = False,
    pcall: bool = False,
    chomp: bool = True,
    no_stdout: Literal[False] = False,
    no_stderr: Literal[False] = False,
    **kwargs,
) -> Result[StrOutput, ProcessError]: ...


@overload
def system(
    cmd: list[str | bytes] | str | bytes,
    capture: Literal[True] = True,
    splitlines: Literal[True] = True,
    pcall: bool = False,
    chomp: bool = True,
    no_stdout: Literal[False] = False,
    no_stderr: Literal[False] = False,
    **kwargs,
) -> Result[ListStrOutput, ProcessError]: ...


@overload
def system(
    cmd: list[str | bytes] | str | bytes,
    capture: bool = True,
    splitlines: bool = True,
    pcall: bool = False,
    chomp: bool = True,
    no_stdout: Literal[True] = False,
    no_stderr: Literal[True] = False,
    **kwargs,
) -> Result[bool, ProcessError]: ...


def system(
    cmd: list[str | bytes] | str | bytes,
    capture: bool = True,
    splitlines: bool = False,
    pcall: bool = False,
    chomp: bool = True,
    no_stdout: bool = False,
    no_stderr: bool = False,
    stdout_only: bool = False,
    stderr_only: bool = False,
    **kwargs,
) -> (
    Result[ProcessOutput | bool, ProcessError]
    | Result[StrOutput | ListStrOutput, ProcessError]
):
    kwargs = kwargs.copy()
    kwargs["check"] = True
    kwargs["capture_output"] = capture

    if type(cmd) is str:
        kwargs["shell"] = True

    if no_stdout:
        kwargs["stdout"] = subprocess.DEVNULL

    if no_stderr:
        kwargs["stderr"] = subprocess.DEVNULL

    try:
        process = subprocess.run(cmd, **kwargs)
        if capture:
            stdout = process.stdout.decode() if not no_stdout else None
            stderr = process.stderr.decode() if not no_stderr else None

            if stdout:
                stdout = strip(stdout, lhs=False) if chomp else stdout
                stdout = splitlines and stdout.split("\n") or stdout

                if stdout_only:
                    return Ok(stdout)

            if stderr:
                stderr = strip(stderr, lhs=False) if chomp else stderr
                stderr = splitlines and stderr.split("\n") or stderr

                if stderr_only:
                    return Ok(stderr)

            return Ok(ProcessOutput(process, stdout, stderr))
        else:
            return Ok(ProcessOutput(True))
    except ProcessError as error:
        if pcall:
            return Err(error, dict(cmd=cmd, kwargs=kwargs))
        else:
            errors.throw(error, dict(cmd=cmd, kwargs=kwargs))


def systemlist(
    cmd: list[str] | str,
    pcall: bool = False,
    chomp: bool = True,
    **kwargs,
) -> Result[list[str], ProcessError]:
    return system(
        cmd,
        capture=True,
        splitlines=True,
        chomp=chomp,
        pcall=pcall,
        **kwargs,
    )


DEVNULL = subprocess.DEVNULL
STDOUT = subprocess.STDOUT
PIPE = subprocess.PIPE


@module
class utils:
    DEVNULL = DEVNULL
    STDOUT = STDOUT
    PIPE = PIPE
    CalledProcessError = CalledProcessError
    CompletedProcess = CompletedProcess
    FileNotFoundError = FileNotFoundError
    ProcessError = ProcessError
    system = staticmethod(system)
    systemlist = staticmethod(systemlist)
    popen = staticmethod(Popen)
    new = staticmethod(Popen)


__all__ = ["utils", "system", "systemlist"]
