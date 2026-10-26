from .is_a import module
import datetime

_date = datetime.date
_datetime = datetime.datetime
_time = datetime.time


def strptime(
    fmt: str,
    date_str: str,
    *args,
    use: type = datetime,
    **kwargs,
) -> str:
    fn = use.strptime
    return fn(date_str, fmt)


def strftime(
    fmt: str,
    *args,
    use: type = datetime,
    **kwargs,
) -> str:
    return use(*args, **kwargs).strftime(fmt)


@module
class utils:
    new = _date
    date = _date
    datetime = _datetime
    time = _time
    strftime = strftime
    strptime = strptime
    ftime = strftime
    ptime = strptime


__all__ = ["utils", "strftime", "strptime"]
