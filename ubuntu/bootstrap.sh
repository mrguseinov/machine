# Exit on any (not really) error, undefined variable or command pipe failure.
set -euo pipefail

# ---------------------------------------------------------------------------------- #

source $(dirname "$0")/functions.sh

if [ $(whoami) == "root" ]; then
    read -p "The script will run for the 'root' user. Continue? [y/N]: " -e answer
    if $(is_decision_positive "$answer"); then
        echo ""
    else
        echo "Do not run the script with 'sudo' or logged in as the 'root'."
        exit
    fi
else
    echo ""
    echo "We need to ask for the password beforehand to prettify the script output."
    echo "We also need to enter the sudo session before starting background upgrade."
    sudo echo ""
fi

cd ~

# ---------------------------------------------------------------------------------- #

echo -ne "Updating packages list..."
sudo apt update > /dev/null 2>&1
echo " Done."

# ---------------------------------------------------------------------------------- #

echo -ne "Updating packages...\r"

num_updates=$(count_available_updates)
num_lines_start=$(count_file_lines /var/log/apt/term.log)

start_upgrade_async

while true; do
    if $(is_upgrade_done); then break; fi

    num_lines_current=$(count_file_lines /var/log/apt/term.log)
    current_package_id=$(echo "($num_lines_current - $num_lines_start) / 4 + 1" | bc)

    if (( $current_package_id > $num_updates )); then
        echo -ne "Updating packages... $num_updates/$num_updates\r"
    else
        echo -ne "Updating packages... $current_package_id/$num_updates\r"
    fi

    sleep 0.5
done

echo "Updating packages... Done.          "

# ---------------------------------------------------------------------------------- #

echo -ne "Changing timezone to Moscow..."
sudo timedatectl set-timezone Europe/Moscow
echo " Done."

# ---------------------------------------------------------------------------------- #

read -p "Do you want to change the hostname? [y/N]: " -e answer
if $(is_decision_positive "$answer"); then
    read -p "Enter your new hostname: " -e new_hostname
    echo -ne "Changing hostname..."
    old_hostname=$(cat /etc/hostname)
    sudo sed -i "s/$old_hostname/$new_hostname/g" /etc/hosts
    sudo sed -i "s/$old_hostname/$new_hostname/g" /etc/hostname
    echo " Done."
    echo "You need to reboot the machine to see the changes."
fi

# ---------------------------------------------------------------------------------- #

echo -ne "Installing dotfiles and SSH config in home directory..."
ubuntu_path="machine/ubuntu"
cp -r "$ubuntu_path"/dotfiles/. ~
cat .bashrc_partial >> .bashrc && rm .bashrc_partial
mkdir -p ~/.ssh/ && cp -r "$ubuntu_path"/ssh/. ~/.ssh/
echo " Done."

# ---------------------------------------------------------------------------------- #

echo -ne "Installing python3.8..."
sudo apt install python3.8 -y > /dev/null 2>&1
echo " Done."

# ---------------------------------------------------------------------------------- #

echo -ne "Installing pip3 (python package manager)..."
sudo apt install python3-pip -y > /dev/null 2>&1
echo " Done."

# ---------------------------------------------------------------------------------- #

echo -ne "Installing virtualenv (python environments manager)..."
pip3 install virtualenv -q --no-warn-script-location
source ~/.profile
echo " Done."

# ---------------------------------------------------------------------------------- #

echo -ne "Installing black (python formatter)..."
pip3 install black -q
echo " Done."

# ---------------------------------------------------------------------------------- #

echo -ne "Adding 'projects' and 'sandbox' folders..."
mkdir projects
mkdir sandbox
touch sandbox/app.py
virtualenv sandbox/venv -q
source sandbox/venv/bin/activate
pip install --upgrade pip -q
pip install black -q
deactivate
echo " Done."

# ---------------------------------------------------------------------------------- #

echo -ne "Cleaning up after provision..."
rm -rf machine/
chmod 700 ~/.ssh/
chmod 600 ~/.ssh/*
chmod 644 ~/.gitconfig
sudo apt autoremove -y > /dev/null 2>&1
echo " Done."

# ---------------------------------------------------------------------------------- #

if [ -f /var/run/reboot-required ]; then
    read -p "Do you want to reboot the machine right now? [y/N]: " -e answer
    if $(is_decision_positive "$answer"); then
        echo ""
        echo "The reboot will be initiated in 5 seconds."
        echo "Thank you for choosing my script. Bye!"
        echo ""
        sleep 5
        sudo reboot
    fi
fi

# ---------------------------------------------------------------------------------- #

echo ""
echo "Thank you for choosing my script. Bye!"
echo ""
