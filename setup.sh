#!/bin/bash
# Quick Pi setup script

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo systemctl enable docker

# Clone project
cd ~
git clone https://github.com/Alfie-Z4/CurrentSolution.git

echo "Setup complete! Please:"
echo "1. Reboot: sudo reboot"
echo "2. Edit config: nano ~/CurrentSolution/current_sensing/config/user_config.toml"
echo "3. Edit MQTT: nano ~/CurrentSolution/current_sensing/config/pm_b_3pb_bc_robotics.toml"
echo "4. Start: cd ~/CurrentSolution && docker compose -f docker-compose-pi.yml up -d"