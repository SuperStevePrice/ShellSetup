#!/bin/bash
# ========================================================
# Elementary OS–like desktop installer for Ubuntu ARM64
# For M1 Mac VirtualBox VM
# ========================================================

echo "Updating base system..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common curl wget git unzip

echo "Installing minimal Ubuntu desktop..."
sudo apt install -y ubuntu-desktop-minimal

echo "Adding Elementary OS repository..."
sudo add-apt-repository -y ppa:elementary-os/stable
sudo apt update

echo "Installing Pantheon desktop and core Elementary apps..."
sudo apt install -y elementary-desktop elementary-theme elementary-icon-theme elementary-default-settings elementary-tweaks plank

echo "Installing LightDM and Pantheon greeter..."
sudo apt install -y lightdm pantheon-greeter
echo "Setting LightDM as default display manager..."
sudo dpkg-reconfigure lightdm

echo "Setting Plank dock to autostart..."
mkdir -p ~/.config/autostart
cp /usr/share/applications/plank.desktop ~/.config/autostart/

echo "Installing wallpapers and sound theme..."
sudo apt install -y elementary-wallpapers elementary-sound-theme

echo "Cleaning up Ubuntu GNOME leftovers..."
sudo apt remove -y ubuntu-session gnome-shell
sudo apt autoremove -y
sudo apt autoclean -y

echo "Installation complete! Rebooting now..."
sudo reboot

