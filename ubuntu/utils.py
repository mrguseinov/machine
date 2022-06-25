import shlex
import subprocess
import time
import traceback

import requests


def detect_timezone() -> str | None:
    try:
        return requests.get("https://ipinfo.io/json").json()["timezone"]
    except Exception as e:
        print_traceback(e)
        return None


def print_title(title: str, *, sleep: bool = True) -> None:
    hyphens = "-" * 80
    title = f" {title.upper()} "
    print("\n" + hyphens)
    print(f"{title:#^80}")
    print(hyphens + "\n")
    if sleep:
        time.sleep(1)


def print_traceback(e: Exception) -> None:
    print("".join(traceback.format_exception(e.__class__, e, e.__traceback__)).strip())


def run_command(command: str, *, shell: bool = False) -> None:
    subprocess.run(command if shell else shlex.split(command), check=True, shell=shell)
