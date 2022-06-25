import utils

utils.print_title("updating packages list", sleep=False)
utils.run_command("sudo apt update")

utils.print_title("updating packages themselves")
utils.run_command("sudo apt upgrade -y")

utils.print_title("installing pip (python package manager)")
utils.run_command("sudo apt install python3-pip -y")

utils.print_title("installing virtualenv (python environments manager)")
utils.run_command("pip install virtualenv --no-warn-script-location")

utils.print_title("installing black (python formatter)")
utils.run_command("pip install black --no-warn-script-location")

utils.print_title("changing the time zone", sleep=False)
timezone = utils.detect_timezone()
if timezone is not None:
    utils.run_command(f"sudo timedatectl set-timezone {timezone}")
    print(f"Changed the time zone to '{timezone}'.")

utils.print_title("installing dotfiles and ssh config")
utils.run_command("cp -r machine/ubuntu/dotfiles/. ~", shell=True)
utils.run_command("cp -r machine/ubuntu/ssh/. ~/.ssh/", shell=True)
utils.run_command("cat .bashrc_partial >> .bashrc && rm .bashrc_partial", shell=True)
print("Done.")

utils.print_title("adding 'projects' and 'sandbox' folders")
utils.run_command("mkdir projects")
utils.run_command("mkdir sandbox")
utils.run_command("touch sandbox/app.py")
print("Done.")

utils.print_title("performing the final steps")
utils.run_command("chmod 700 ~/.ssh/", shell=True)
utils.run_command("chmod 600 ~/.ssh/*", shell=True)
utils.run_command("chmod 644 ~/.gitconfig", shell=True)
utils.run_command("sudo apt autoremove -y")
utils.run_command("rm -rf machine/")

utils.print_title("rebooting the machine", sleep=False)
print("Thank you for choosing my script. Bye!\n")
utils.run_command("sudo reboot")
