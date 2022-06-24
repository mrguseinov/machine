import shutil
import time
from pathlib import Path

import utils

# ------------------------------------------------------------------------------------ #

print("\nWe need to ask for the password beforehand to prettify the script output.")
utils.run("sudo echo")
print()

# ------------------------------------------------------------------------------------ #

print("Updating packages list...", end="")
utils.run("sudo apt-get update")
print(" Done.")

# ------------------------------------------------------------------------------------ #

number_of_updates = len(utils.popen("apt list --upgradable").stdout.readlines()) - 1
title = f"Updating {number_of_updates} package(s)..."
total_lines = int(number_of_updates * 7.5)
utils.show_progress(title, utils.popen("sudo apt-get upgrade -y"), total_lines)

# ------------------------------------------------------------------------------------ #

answer = utils.get_ascii_input("Do you want to change the hostname? [y/N]: ")
if utils.is_answer_positive(answer):
    new_hostname = utils.get_ascii_input("Enter your new hostname: ")
    print("Changing hostname...", end="")
    utils.change_hostname(new_hostname)
    print(" Done.")
    print("You need to reboot the machine to see the changes.")

# ------------------------------------------------------------------------------------ #

answer = utils.get_ascii_input("Do you want to change the time zone? [y/N]: ")
if utils.is_answer_positive(answer):
    print("Trying to detect your time zone...", end="")
    timezone = utils.detect_timezone()
    if timezone is None:
        print(" Failed.")
        timezone = utils.read_timezone_from_console()
    else:
        print(" Done.")
        answer = utils.get_ascii_input(f"Is your time zone '{timezone}'? [y/N]: ")
        if not utils.is_answer_positive(answer):
            timezone = utils.read_timezone_from_console()

    print("Changing the time zone...", end="")
    if timezone is None:
        print(" Failed.")
    else:
        utils.set_timezone(timezone)
        print(" Done.")

# ------------------------------------------------------------------------------------ #

print("Installing dotfiles and SSH config in home directory...", end="")
shutil.copytree("machine/ubuntu/dotfiles", Path.home(), dirs_exist_ok=True)
shutil.copytree("machine/ubuntu/ssh", f"{Path.home()}/.ssh", dirs_exist_ok=True)
utils.run("cat .bashrc_partial >> .bashrc && rm .bashrc_partial", shell=True)
print(" Done.")

# ------------------------------------------------------------------------------------ #

title = "Installing pip3 (python package manager)..."
utils.show_progress(title, utils.popen("sudo apt-get install python3-pip -y"), 307)

# ------------------------------------------------------------------------------------ #

print("Installing virtualenv (python environments manager)...", end="")
utils.run("pip3 install virtualenv")
print(" Done.")

# ------------------------------------------------------------------------------------ #

print("Installing black (python formatter)...", end="")
utils.run("pip3 install black")
print(" Done.")

# ------------------------------------------------------------------------------------ #

print("Adding 'projects' and 'sandbox' folders...", end="")
utils.run("mkdir projects")
utils.run("mkdir sandbox")
utils.run("touch sandbox/app.py")
utils.run(f"{Path.home()}/.local/bin/virtualenv sandbox/.venv")
utils.run("sandbox/.venv/bin/python -m pip install black")
print(" Done.")

# ------------------------------------------------------------------------------------ #

print("Cleaning up after provisioning...", end="")
shutil.rmtree("machine")
utils.run("chmod 700 ~/.ssh/", shell=True)
utils.run("chmod 600 ~/.ssh/*", shell=True)
utils.run("chmod 644 ~/.gitconfig", shell=True)
utils.run("sudo apt-get autoremove -y")
print(" Done.")

# ------------------------------------------------------------------------------------ #

answer = utils.get_ascii_input("Do you want to reboot the machine right now? [y/N]: ")
if utils.is_answer_positive(answer):
    try:
        print("\nThe reboot will be initiated in 5 seconds.")
        print("If you want to cancel it, press 'Ctrl+C'.")
        print("Thank you for choosing my script. Bye!\n")
        time.sleep(5)
        utils.run("sudo reboot")
    except KeyboardInterrupt:
        print("\rReboot aborted.")
else:
    print("\nThank you for choosing my script. Bye!\n")
