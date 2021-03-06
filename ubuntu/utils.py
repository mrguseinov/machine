from __future__ import annotations

import shlex
import subprocess
import sys


def change_hostname(new_hostname: str):
    old_hostname = run("cat /etc/hostname").stdout.strip()
    run(f"sudo sed -i 's/{old_hostname}/{new_hostname}/g' /etc/hosts")
    run(f"sudo sed -i 's/{old_hostname}/{new_hostname}/g' /etc/hostname")


def get_ascii_input(message: str) -> str:
    while True:
        try:
            return input(message).encode("ascii").decode()
        except (UnicodeEncodeError, UnicodeDecodeError):
            print("Use only english keyboard layout (ascii characters).")


def is_answer_positive(answer: str) -> bool:
    return answer.lower() in ["y", "yes", "yeah", "yep"]


def popen(command: str) -> subprocess.Popen[str]:
    """Run `command` in a new process (non-blocking)."""
    sys.stdout.flush()
    return subprocess.Popen(
        shlex.split(command),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


def run(command: str, shell: bool = False) -> subprocess.CompletedProcess[str]:
    """Run `command` and wait for it to complete."""
    sys.stdout.flush()
    return subprocess.run(
        command if shell else shlex.split(command),
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        shell=shell,
        check=True,
        text=True,
    )


def show_progress(title: str, process: subprocess.Popen[str], total_lines: int) -> None:
    """`total_lines` is an approximate number of stdout lines from the `process`."""
    title = "\r" + title
    print(title, end="")

    if total_lines > 0 and process.stdout:
        for line_number, _ in enumerate(process.stdout):
            percent = min(int(line_number / total_lines * 100), 100)
            print(f"{title} {percent}%", end="")

    if process.wait():
        sys.exit("\n" + process.stderr.read().strip())

    print(f"{title} Done.")
