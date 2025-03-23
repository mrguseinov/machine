import utils

utils.print_title("updating packages list", sleep=False)
utils.run_command("sudo apt update")

utils.print_title("updating packages themselves")
utils.run_command("sudo NEEDRESTART_MODE=a apt upgrade -y")

utils.print_title("installing uv (python package and project manager)")
commands = [
    """curl -LsSf https://astral.sh/uv/install.sh | sh""",
    """echo 'eval "$(uv generate-shell-completion bash)"' >> ~/.bashrc""",
    """echo 'eval "$(uvx --generate-shell-completion bash)"' >> ~/.bashrc""",
]
for command in commands:
    utils.run_command(command, shell=True)

utils.print_title("installing latest stable python")
utils.run_command("~/.local/bin/uv python install", shell=True)

utils.print_title("installing bat (cat clone with wings)")
utils.run_command("sudo apt install bat -y")
utils.run_command("mkdir -p ~/.local/bin", shell=True)
utils.run_command("ln -s /usr/bin/batcat ~/.local/bin/bat", shell=True)

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

utils.print_title("performing the final steps")
utils.run_command("chmod 700 ~/.ssh/", shell=True)
utils.run_command("chmod 600 ~/.ssh/*", shell=True)
utils.run_command("chmod 644 ~/.gitconfig", shell=True)
utils.run_command("sudo apt autoremove -y")
utils.run_command("rm -rf machine/")

utils.print_title("rebooting the machine", sleep=False)
print("Thank you for choosing my script. Bye!\n")
utils.run_command("sudo reboot")
