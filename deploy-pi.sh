#!/bin/bash
# Bash Script for Raspberry Pi Deployment
# Power Monitoring - Raspberry Pi Setup

echo "=========================================="
echo "Power Monitoring - Raspberry Pi Setup"
echo "=========================================="
echo ""

# Get Pi machine name from argument or prompt
if [ -z "$1" ]; then
    echo "Enter machine name for this Pi (e.g., Pi_1, Pi_2, etc.):"
    read -r MACHINE_NAME
else
    MACHINE_NAME=$1
fi

# Get central server IP from argument or prompt
if [ -z "$2" ]; then
    echo "Enter central server IP address:"
    read -r SERVER_IP
else
    SERVER_IP=$2
fi

echo ""
echo "Configuration:"
echo "  Machine Name: $MACHINE_NAME"
echo "  Server IP: $SERVER_IP"
echo ""
echo "Is this correct? (y/n)"
read -r CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Setup cancelled"
    exit 0
fi

# Find the config file to use
CONFIG_FILE="current_sensing/config/user_config.toml"

# Check if user_config.toml exists, if not use pm_b_3pu_mock.toml as template
if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    echo "Creating user_config.toml from template..."
    cp current_sensing/config/pm_b_3pu_mock.toml "$CONFIG_FILE"
fi

echo ""
echo "Updating configuration file..."

# Backup original config
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Update MQTT broker IP
sed -i "s/broker = \".*\"/broker = \"$SERVER_IP\"/" "$CONFIG_FILE"

# Update machine name
sed -i "s/machine = \".*\"/machine = \"$MACHINE_NAME\"/" "$CONFIG_FILE"

echo "✅ Configuration updated"

# Stop any existing containers
echo ""
echo "Stopping any existing containers..."
docker-compose -f docker-compose-pi.yml down 2>/dev/null

# Build image
echo ""
echo "Building Docker image..."
docker-compose -f docker-compose-pi.yml build

# Start service
echo ""
echo "Starting current sensing service..."
docker-compose -f docker-compose-pi.yml up -d

# Wait and check status
sleep 5

echo ""
echo "=========================================="
echo "Service Status:"
echo "=========================================="
docker-compose -f docker-compose-pi.yml ps

echo ""
echo "Checking connection to MQTT broker..."
sleep 3
docker-compose -f docker-compose-pi.yml logs --tail=20 current-sensing

echo ""
echo "=========================================="
echo "✅ Raspberry Pi Setup Complete!"
echo "=========================================="
echo ""
echo "Machine Name: $MACHINE_NAME"
echo "Connecting to: $SERVER_IP:1883"
echo ""
echo "To view logs: docker-compose -f docker-compose-pi.yml logs -f"
echo "To stop:      docker-compose -f docker-compose-pi.yml down"
echo ""
