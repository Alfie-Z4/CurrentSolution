# Power Monitoring System - Windows Server Deployment Guide

## Complete Setup for Windows Server + Raspberry Pi Devices

This guide covers deploying the Power Monitoring system with:
- **1 Windows Server** running all backend services (MQTT, InfluxDB, Grafana, Analysis)
- **Multiple Raspberry Pi devices** measuring current and sending data

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Windows Server Setup](#windows-server-setup)
3. [Raspberry Pi Setup](#raspberry-pi-setup)
4. [Verification](#verification)
5. [Troubleshooting](#troubleshooting)
6. [Maintenance](#maintenance)

---

## Prerequisites

### Windows Server Requirements

- **Operating System:** Windows Server 2019/2022 or Windows 10/11 Pro
- **Docker Desktop for Windows** installed with WSL2 backend
- **PowerShell 5.1+** (pre-installed on Windows)
- **Network:** Static IP address recommended
- **Ports:** 1883 (MQTT), 3000 (Grafana), 8086 (InfluxDB) must be available
- **Hardware:** Minimum 4GB RAM, 20GB free disk space
- **Firewall:** Ports must be open for incoming connections

### Raspberry Pi Requirements (Each Device)

- **Hardware:** Raspberry Pi 3/4/5
- **OS:** Raspberry Pi OS (32-bit or 64-bit)
- **Docker:** Installed on each Pi
- **Sensors:** Current sensors/clamps connected via I2C
- **Network:** Access to Windows server on port 1883

---

## Windows Server Setup

### Step 1: Install Docker Desktop

1. **Download Docker Desktop:**
   - Visit: https://www.docker.com/products/docker-desktop
   - Download Docker Desktop for Windows

2. **Install Docker Desktop:**
   - Run installer
   - During installation, ensure "Use WSL 2 instead of Hyper-V" is selected
   - Restart computer when prompted

3. **Configure Docker Desktop:**
   - Open Docker Desktop
   - Go to Settings (gear icon)
   - **General:**
     - ✅ Enable "Use the WSL 2 based engine"
   - **Resources → WSL Integration:**
     - ✅ Enable integration with default WSL distro
   - Click **Apply & Restart**

4. **Verify Docker is working:**
   ```powershell
   docker --version
   docker-compose --version
   docker info
   ```

### Step 2: Configure Windows Firewall

**Open PowerShell as Administrator:**

```powershell
# Allow MQTT (for Raspberry Pis to connect)
New-NetFirewallRule -DisplayName "Power Monitoring - MQTT" -Direction Inbound -Protocol TCP -LocalPort 1883 -Action Allow

# Allow Grafana (for web browser access)
New-NetFirewallRule -DisplayName "Power Monitoring - Grafana" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow

# Allow InfluxDB (optional - for direct database access)
New-NetFirewallRule -DisplayName "Power Monitoring - InfluxDB" -Direction Inbound -Protocol TCP -LocalPort 8086 -Action Allow

# Allow Graph UI (optional)
New-NetFirewallRule -DisplayName "Power Monitoring - Graph UI" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
```

**Verify firewall rules:**
```powershell
Get-NetFirewallRule -DisplayName "Power Monitoring*" | Format-Table DisplayName, Enabled, Direction, Action
```

### Step 3: Download/Copy Project Files

**Option A: Using Git (Recommended)**

```powershell
# Install Git for Windows if not already installed
# Download from: https://git-scm.com/download/win

# Clone the repository
cd C:\
git clone https://github.com/DigitalShoestringSolutions/PowerMonitoring.git
cd PowerMonitoring
```

**Option B: Manual Copy**

1. Copy your `PowerUniversitySolution` folder to `C:\PowerMonitoring`
2. Open PowerShell and navigate:
   ```powershell
   cd C:\PowerMonitoring
   ```

### Step 4: Run the Deployment Script

```powershell
# Navigate to project directory
cd C:\PowerMonitoring

# Run the deployment script
.\deploy-central-server.ps1
```

**What the script does:**
1. ✅ Checks Docker is running
2. ✅ Detects your server's IP address
3. ✅ Stops any existing containers
4. ✅ Builds all Docker images
5. ✅ Starts all services (MQTT, InfluxDB, Telegraf, Grafana, Analysis, Graph UI)
6. ✅ Displays access URLs

**Expected Output:**
```
==========================================
✅ Central Server Setup Complete!
==========================================

Access your services at:
  📊 Grafana:  http://192.168.1.100:3000
       Login: admin / admin

  🌐 Graph UI: http://192.168.1.100:80

  📈 InfluxDB: http://192.168.1.100:8086

Raspberry Pis should connect to:
  🔌 MQTT Broker: 192.168.1.100:1883
```

**IMPORTANT:** Note the IP address shown - you'll need this for configuring Raspberry Pis!

### Step 5: Verify Services Are Running

```powershell
# Check all containers are running
docker-compose -f docker-compose-central.yml ps
```

**Expected output - all should show "Up":**
```
NAME                  STATUS
mqtt_broker           Up
timeseries-db         Up
timeseries-db-input   Up
dashboard             Up
analysis              Up
graph                 Up
```

### Step 6: Access Grafana

1. **Open your web browser**
2. **Navigate to:** `http://YOUR-SERVER-IP:3000`
   - Replace `YOUR-SERVER-IP` with the IP shown by the script
   - Example: `http://192.168.1.100:3000`

3. **Login:**
   - Username: `admin`
   - Password: `admin`

4. **Change Password:**
   - Grafana will prompt you to change the password
   - Choose a secure password and remember it!

5. **Verify Datasources:**
   - Click Configuration (gear icon) → Data Sources
   - You should see:
     - ✅ **InfluxDB** (default)
     - ✅ **Analysis Module**
   - Both should show green checkmark

6. **Open Production Dashboard:**
   - Click Dashboards (four squares icon) → Browse
   - Navigate to "Power Monitoring" folder
   - Click "Power Monitoring - Production"
   - Dashboard will be empty until Raspberry Pis start sending data

---

## Raspberry Pi Setup

### Step 1: Prepare Each Raspberry Pi

**On each Raspberry Pi, run these commands:**

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker if not already installed
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add pi user to docker group
sudo usermod -aG docker pi

# Install Docker Compose
sudo apt-get install -y docker-compose

# Enable I2C for sensors
sudo raspi-config
# Navigate to: Interface Options → I2C → Enable

# Reboot to apply changes
sudo reboot
```

### Step 2: Copy Project Files to Each Pi

**From your Windows computer, use WinSCP or command line:**

**Option A: Using WinSCP (GUI Method)**
1. Download WinSCP: https://winscp.net/
2. Connect to your Raspberry Pi
3. Copy the entire `PowerMonitoring` folder to `/home/pi/`

**Option B: Using PowerShell (Command Line)**

```powershell
# From Windows PowerShell
# Replace PI_IP_ADDRESS with your Pi's IP

# Using SCP (requires OpenSSH)
scp -r C:\PowerMonitoring pi@PI_IP_ADDRESS:/home/pi/
```

### Step 3: Configure Each Pi

**SSH into the Raspberry Pi:**

```powershell
# From Windows PowerShell
ssh pi@PI_IP_ADDRESS
```

**On the Pi, navigate to project:**

```bash
cd /home/pi/PowerMonitoring
```

**Edit configuration file:**

```bash
# Open the config file
nano current_sensing/config/user_config.toml
```

**If `user_config.toml` doesn't exist, create it:**

```bash
# Copy from template
cp current_sensing/config/pm_b_3pu_mock.toml current_sensing/config/user_config.toml

# Edit it
nano current_sensing/config/user_config.toml
```

**Make these changes:**

1. **Update MQTT broker** (find the `[mqtt]` section):
   ```toml
   [mqtt]
       broker = "192.168.1.100"  # ← YOUR WINDOWS SERVER IP
       port = 1883
   ```

2. **Update machine name** (find the `[calculation.machine_name.config]` section):
   ```toml
   [calculation.machine_name.config]
       machine = "Pi_1"  # ← Change to Pi_1, Pi_2, Pi_3, etc.
   ```

**Save and exit:**
- Press `Ctrl+X`
- Press `Y` to confirm
- Press `Enter`

### Step 4: Deploy on Each Pi

**Run the deployment script:**

```bash
# Make the script executable
chmod +x deploy-pi.sh

# Run deployment
./deploy-pi.sh Pi_1 192.168.1.100

# Replace:
#   Pi_1 → your unique machine name
#   192.168.1.100 → your Windows server IP
```

**Or run interactively (script will prompt for details):**

```bash
./deploy-pi.sh
```

**Expected Output:**
```
==========================================
✅ Raspberry Pi Setup Complete!
==========================================

Machine Name: Pi_1
Connecting to: 192.168.1.100:1883

To view logs: docker-compose -f docker-compose-pi.yml logs -f
```

### Step 5: Verify Pi is Sending Data

```bash
# Check container is running
docker-compose -f docker-compose-pi.yml ps

# View logs
docker-compose -f docker-compose-pi.yml logs -f current-sensing
```

**Look for these messages:**
```
INFO - Connecting to 192.168.1.100:1883
INFO - Connected!
INFO - pub topic:power_monitoring/Pi_1/A msg:{'timestamp':...,'current':5.2}
```

**If you see "Connected!" and "pub topic:" messages, it's working!** ✅

### Step 6: Repeat for Additional Pis

For each additional Raspberry Pi:

1. Copy project files
2. Edit `user_config.toml` with unique machine name (Pi_2, Pi_3, etc.)
3. Run `./deploy-pi.sh Pi_X SERVER_IP`
4. Verify logs show connection

---

## Verification

### 1. Check MQTT Messages on Windows Server

**On your Windows server, open PowerShell:**

```powershell
# Subscribe to MQTT broker to see all messages
docker exec -it mqtt_broker sh

# Inside the container:
mosquitto_sub -t "power_monitoring/#" -v
```

**You should see messages like:**
```
power_monitoring/Pi_1/A {"timestamp":"2025-11-19T10:30:45Z","machine":"Pi_1","phase":"A","current":5.2}
power_monitoring/Pi_2/A {"timestamp":"2025-11-19T10:30:46Z","machine":"Pi_2","phase":"A","current":3.8}
```

**Press Ctrl+C to exit, then type `exit` to leave container**

### 2. Check InfluxDB Has Data

```powershell
# Access InfluxDB web interface
Start-Process "http://localhost:8086"

# Or check via command line
docker exec -it timeseries-db influx query "from(bucket: \"power_monitoring\") |> range(start: -1h) |> limit(n: 10)"
```

### 3. Check Grafana Dashboard

1. Open Grafana: `http://YOUR-SERVER-IP:3000`
2. Go to Dashboards → Browse → Power Monitoring → "Power Monitoring - Production"
3. **Machine dropdown should show:** Pi_1, Pi_2, Pi_3, etc.
4. Select a machine
5. **You should see:**
   - Current graph with data
   - Power graph with data
   - Live gauges updating every 5 seconds

**If no data appears:**
- Check time range (top right) - set to "Last 15 minutes"
- Wait 30 seconds for auto-refresh
- Verify Pis are running (check logs)

---

## Troubleshooting

### Issue: Docker Desktop won't start

**Solution:**
1. Enable WSL 2:
   ```powershell
   wsl --install
   wsl --set-default-version 2
   ```
2. Restart computer
3. Open Docker Desktop

### Issue: "Cannot connect to Docker daemon"

**Solution:**
```powershell
# Start Docker Desktop manually
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait 30 seconds for Docker to start
Start-Sleep -Seconds 30

# Verify
docker info
```

### Issue: Raspberry Pi can't connect to server

**Check network connectivity:**

```bash
# From Raspberry Pi
ping 192.168.1.100

# Test MQTT port
telnet 192.168.1.100 1883
```

**Check Windows Firewall:**

```powershell
# On Windows server
Get-NetFirewallRule -DisplayName "Power Monitoring - MQTT" | Select-Object Enabled

# If disabled, enable it:
Set-NetFirewallRule -DisplayName "Power Monitoring - MQTT" -Enabled True
```

**Check if server is on different subnet:**
- Ensure Pi and server are on same network
- Or configure router to allow traffic between networks

### Issue: No data in Grafana

**1. Check Pi is sending data:**
```bash
# On Pi
docker-compose -f docker-compose-pi.yml logs -f current-sensing
```
Look for "pub topic:power_monitoring/..." messages

**2. Check Telegraf on server:**
```powershell
# On Windows server
docker-compose -f docker-compose-central.yml logs timeseries-db-input
```

**3. Check InfluxDB:**
```powershell
docker exec -it timeseries-db influx query "from(bucket: \"power_monitoring\") |> range(start: -1h) |> count()"
```

### Issue: Dashboard shows "No Data"

**Solution:**
1. Check time range - set to "Last 15 minutes"
2. Verify machine name matches exactly (case-sensitive)
3. Click refresh button (circular arrow icon)
4. Check browser console (F12) for errors

### Issue: Container won't start

```powershell
# View detailed logs
docker-compose -f docker-compose-central.yml logs <service-name>

# Restart specific service
docker-compose -f docker-compose-central.yml restart <service-name>

# Rebuild if needed
docker-compose -f docker-compose-central.yml up -d --build
```

---

## Maintenance

### Viewing Logs

**All services:**
```powershell
docker-compose -f docker-compose-central.yml logs -f
```

**Specific service:**
```powershell
docker-compose -f docker-compose-central.yml logs -f grafana
docker-compose -f docker-compose-central.yml logs -f mqtt_broker
docker-compose -f docker-compose-central.yml logs -f timeseries-db
```

**Stop following logs:** Press `Ctrl+C`

### Stopping Services

**Stop all services:**
```powershell
docker-compose -f docker-compose-central.yml down
```

**Stop specific service:**
```powershell
docker-compose -f docker-compose-central.yml stop grafana
```

### Restarting Services

**Restart all:**
```powershell
docker-compose -f docker-compose-central.yml restart
```

**Restart specific service:**
```powershell
docker-compose -f docker-compose-central.yml restart analysis
```

### Updating Configuration

**If you change Raspberry Pi configuration:**

```bash
# On Pi
docker-compose -f docker-compose-pi.yml down
docker-compose -f docker-compose-pi.yml up -d
```

**If you change analysis configuration (voltage/power factor):**

```powershell
# On Windows server
# Edit: analysis/config/user_config.toml
# Then:
docker-compose -f docker-compose-central.yml restart analysis
```

### Backing Up Data

**InfluxDB data:**
```powershell
# Create backup directory
New-Item -ItemType Directory -Path "C:\PowerMonitoring\backups" -Force

# Backup InfluxDB
docker exec timeseries-db influx backup C:\backups

# Copy from container to host
docker cp timeseries-db:/backups C:\PowerMonitoring\backups\influx-$(Get-Date -Format 'yyyyMMdd-HHmmss')
```

**Grafana dashboards:**
- Export through Grafana UI: Dashboard → Share → Export → Save JSON

### System Startup

**To auto-start services on Windows boot:**

1. Open Docker Desktop Settings
2. General → Start Docker Desktop when you log in ✅
3. Services will auto-start with Docker

**Or create a scheduled task:**

```powershell
# Create task to start services on boot
$action = New-ScheduledTaskAction -Execute "docker-compose" -Argument "-f C:\PowerMonitoring\docker-compose-central.yml up -d" -WorkingDirectory "C:\PowerMonitoring"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "PowerMonitoring-Startup" -Action $action -Trigger $trigger -Principal $principal
```

---

## Quick Reference Commands

### Windows Server

```powershell
# Start services
cd C:\PowerMonitoring
.\deploy-central-server.ps1

# Or manually:
docker-compose -f docker-compose-central.yml up -d

# Stop services
docker-compose -f docker-compose-central.yml down

# View logs
docker-compose -f docker-compose-central.yml logs -f

# Check status
docker-compose -f docker-compose-central.yml ps

# Restart a service
docker-compose -f docker-compose-central.yml restart analysis
```

### Raspberry Pi

```bash
# Start current sensing
cd /home/pi/PowerMonitoring
./deploy-pi.sh Pi_1 192.168.1.100

# Or manually:
docker-compose -f docker-compose-pi.yml up -d

# Stop
docker-compose -f docker-compose-pi.yml down

# View logs
docker-compose -f docker-compose-pi.yml logs -f

# Check status
docker-compose -f docker-compose-pi.yml ps
```

---

## Network Diagram

```
┌─────────────────────────────────────────────────────┐
│           WINDOWS SERVER (192.168.1.100)            │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌─────────┐          │
│  │   MQTT   │→ │ Telegraf │→ │ InfluxDB│          │
│  │  Broker  │  │          │  │         │          │
│  │ :1883    │  └──────────┘  └────┬────┘          │
│  └────▲─────┘                     │                │
│       │        ┌──────────┐       │                │
│       │        │ Analysis │←──────┘                │
│       │        │  Module  │                        │
│       │        └─────┬────┘                        │
│       │              │                              │
│       │        ┌─────▼────┐                        │
│       │        │ Grafana  │ ← Browser Access       │
│       │        │  :3000   │                        │
│       │        └──────────┘                        │
└───────┼──────────────────────────────────────────┘
        │
        │ (MQTT over LAN)
        │
   ┌────┴────┬─────────┬─────────┬─────────┐
   │         │         │         │         │
┌──▼───┐ ┌──▼───┐ ┌───▼──┐ ┌───▼──┐ ┌───▼──┐
│ Pi_1 │ │ Pi_2 │ │ Pi_3 │ │ Pi_4 │ │ Pi_5 │
│Current│ │Current│ │Current│ │Current│ │Current│
│Sensor│ │Sensor│ │Sensor│ │Sensor│ │Sensor│
└──────┘ └──────┘ └──────┘ └──────┘ └──────┘
```

---

## Summary Checklist

### ✅ Windows Server Setup:
- [ ] Docker Desktop installed and running
- [ ] Firewall rules configured (ports 1883, 3000)
- [ ] Project files in `C:\PowerMonitoring`
- [ ] Run `.\deploy-central-server.ps1`
- [ ] Note the server IP address shown
- [ ] Access Grafana at `http://SERVER-IP:3000`
- [ ] Verify all 6 containers are "Up"

### ✅ Each Raspberry Pi:
- [ ] Docker installed, I2C enabled
- [ ] Project files copied to `/home/pi/PowerMonitoring`
- [ ] Edit `current_sensing/config/user_config.toml`
  - [ ] Set `broker = "SERVER_IP"`
  - [ ] Set unique `machine = "Pi_X"`
- [ ] Run `./deploy-pi.sh Pi_X SERVER_IP`
- [ ] Verify logs show "Connected!"
- [ ] Verify logs show "pub topic:power_monitoring/..."

### ✅ Grafana Verification:
- [ ] Login successful (admin/admin, then change password)
- [ ] Datasources working (green checkmarks)
- [ ] Open "Power Monitoring - Production" dashboard
- [ ] Machine dropdown shows all Pis
- [ ] Graphs show current and power data
- [ ] Live gauges updating every 5 seconds

---

## Getting Help

If you encounter issues not covered in troubleshooting:

1. **Check Docker logs** for errors
2. **Verify network connectivity** between devices
3. **Ensure firewall rules** are active
4. **Check configuration files** for typos
5. **Review MQTT messages** to confirm data flow

**Common mistakes to avoid:**
- ❌ Using `localhost` or `127.0.0.1` for server IP (won't work from Pis)
- ❌ Forgetting to update firewall rules
- ❌ Using same machine name on multiple Pis
- ❌ Typos in server IP address
- ❌ Docker Desktop not running on Windows

---

**Your Windows Server-based Power Monitoring system is now ready! 🎉**

Access Grafana to view real-time power consumption from all your devices.
