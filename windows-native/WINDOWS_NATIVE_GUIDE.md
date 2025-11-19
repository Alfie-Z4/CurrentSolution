# Power Monitoring - Windows Native Installation Guide

## Overview

This guide explains how to install and run the Power Monitoring solution natively on Windows Server 2016 **without Docker**.

All components run as Windows services and start automatically on system boot.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Windows Server 2016                                     │
│                                                         │
│ ┌─────────────────────────────────────────────────┐   │
│ │ Mosquitto MQTT Broker (Windows Service)        │   │
│ │ Port: 1883                                      │   │
│ │ Receives data from Raspberry Pis                │   │
│ └─────────────────────────────────────────────────┘   │
│                                                         │
│ ┌─────────────────────────────────────────────────┐   │
│ │ MQTT-to-InfluxDB Bridge (Python Service)       │   │
│ │ Subscribes to MQTT topics                       │   │
│ │ Writes data to InfluxDB                         │   │
│ └─────────────────────────────────────────────────┘   │
│                                                         │
│ ┌─────────────────────────────────────────────────┐   │
│ │ InfluxDB 2.x (Windows Service)                  │   │
│ │ Port: 8086                                      │   │
│ │ Stores time-series data                         │   │
│ └─────────────────────────────────────────────────┘   │
│                                                         │
│ ┌─────────────────────────────────────────────────┐   │
│ │ Grafana (Windows Service)                       │   │
│ │ Port: 3000                                      │   │
│ │ Visualization dashboards                        │   │
│ └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
           ↑
           │ MQTT Messages (Port 1883)
           │
┌──────────┴──────────────────────────────────────┐
│ Raspberry Pis (Still use Docker)                │
│ - Run current_sensing container                 │
│ - Send MQTT messages to Windows Server          │
└──────────────────────────────────────────────────┘
```

---

## Prerequisites

- Windows Server 2016 (or newer)
- Administrator access
- Internet connection for downloads
- PowerShell 5.1+
- At least 4GB RAM, 20GB free disk space

---

## Quick Installation

### Step 1: Download the Repository

```powershell
# Navigate to C drive
cd C:\

# Clone repository (or copy manually)
git clone https://github.com/Alfie-Z4/CurrentSolution.git PowerMonitoring

cd PowerMonitoring
```

### Step 2: Run Installation Script

```powershell
# Open PowerShell as Administrator
# Run the installation script
.\windows-native\setup-windows-native.ps1
```

**The script will:**
1. Create necessary directories
2. Download and install Mosquitto MQTT Broker
3. Download and install InfluxDB
4. Download and install Grafana
5. Install Python and dependencies
6. Configure Windows Firewall
7. Create Windows services for all components
8. Start all services

**Total time: ~15-20 minutes** (mostly download time)

### Step 3: Complete InfluxDB Setup

After the script finishes:

1. Open browser: `http://localhost:8086`
2. Complete initial setup:
   - **Username:** `admin`
   - **Password:** `DataImage2025!`
   - **Organization:** `DataImage`
   - **Bucket:** `power_monitoring`
3. **IMPORTANT:** Copy the API token shown
4. Paste it when the script asks for it

### Step 4: Configure Grafana

1. Open browser: `http://localhost:3000`
2. Login:
   - **Username:** `admin`
   - **Password:** `admin`
   - Change password when prompted
3. Add InfluxDB datasource:
   - Click ⚙️ (Settings) → **Data Sources**
   - Click **Add data source**
   - Select **InfluxDB**
   - Configure:
     - **Query Language:** `Flux`
     - **URL:** `http://localhost:8086`
     - **Organization:** `DataImage`
     - **Token:** (paste your InfluxDB token)
     - **Default Bucket:** `power_monitoring`
   - Click **Save & Test**
4. Import dashboard:
   - Click **+** → **Import**
   - Upload `dashboards/config/dashboards/Power Monitoring/production_dashboard.json`
   - Select InfluxDB datasource
   - Click **Import**

---

## Raspberry Pi Configuration

### On Each Raspberry Pi:

#### Step 1: Update MQTT Broker Address

```bash
# SSH to your Raspberry Pi
ssh pi@your-pi-ip

# Navigate to project
cd PowerMonitoring

# Edit configuration
nano current_sensing/config/user_config.toml
```

#### Step 2: Change MQTT Broker to Windows Server IP

```toml
[mqtt]
    broker = "192.168.1.XXX"  # ← Replace with your Windows Server IP
    port = 1883
    topic_prefix = ""

[machine]
    machine = "Pi_1"  # ← Unique name for each Pi (Pi_1, Pi_2, etc.)
```

Save: `Ctrl + X`, `Y`, `Enter`

#### Step 3: Restart Current Sensing Service

```bash
# Restart the service
docker-compose -f docker-compose-pi.yml restart

# Check logs
docker-compose -f docker-compose-pi.yml logs -f
```

**Look for:** `Connected!` and `pub topic:power_monitoring/Pi_1/...`

---

## Manual Installation (If Script Fails)

### 1. Install Mosquitto MQTT Broker

```powershell
# Download installer
$url = "https://mosquitto.org/files/binary/win64/mosquitto-2.0.18-install-windows-x64.exe"
Invoke-WebRequest -Uri $url -OutFile "$env:USERPROFILE\Downloads\mosquitto.exe"

# Run installer
Start-Process "$env:USERPROFILE\Downloads\mosquitto.exe" -Wait
```

**Configure Mosquitto:**

Edit `C:\Program Files\mosquitto\mosquitto.conf`:

```conf
listener 1883 0.0.0.0
allow_anonymous true
persistence true
persistence_location C:/PowerMonitoring/Data/Mosquitto/
log_dest file C:/PowerMonitoring/Logs/mosquitto.log
```

**Start service:**

```powershell
Restart-Service mosquitto
Set-Service mosquitto -StartupType Automatic
```

### 2. Install InfluxDB

```powershell
# Download InfluxDB
$url = "https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.4-windows-amd64.zip"
Invoke-WebRequest -Uri $url -OutFile "$env:USERPROFILE\Downloads\influxdb.zip"

# Extract
Expand-Archive -Path "$env:USERPROFILE\Downloads\influxdb.zip" -DestinationPath "C:\PowerMonitoring\InfluxDB"
```

**Install as service (requires NSSM):**

```powershell
# Download NSSM
$url = "https://nssm.cc/release/nssm-2.24.zip"
Invoke-WebRequest -Uri $url -OutFile "$env:USERPROFILE\Downloads\nssm.zip"
Expand-Archive -Path "$env:USERPROFILE\Downloads\nssm.zip" -DestinationPath "C:\Tools"

# Install service
& "C:\Tools\nssm-2.24\win64\nssm.exe" install InfluxDB "C:\PowerMonitoring\InfluxDB\influxd.exe"
& "C:\Tools\nssm-2.24\win64\nssm.exe" set InfluxDB AppDirectory "C:\PowerMonitoring\InfluxDB"

# Start service
Start-Service InfluxDB
```

### 3. Install Grafana

```powershell
# Download Grafana
$url = "https://dl.grafana.com/enterprise/release/grafana-enterprise-10.2.3.windows-amd64.msi"
Invoke-WebRequest -Uri $url -OutFile "$env:USERPROFILE\Downloads\grafana.msi"

# Install
Start-Process msiexec.exe -ArgumentList "/i `"$env:USERPROFILE\Downloads\grafana.msi`" /quiet" -Wait

# Start service
Start-Service Grafana
Set-Service Grafana -StartupType Automatic
```

### 4. Install Python and Dependencies

```powershell
# Download Python
$url = "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe"
Invoke-WebRequest -Uri $url -OutFile "$env:USERPROFILE\Downloads\python.exe"

# Install
Start-Process "$env:USERPROFILE\Downloads\python.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait

# Install packages
python -m pip install influxdb-client paho-mqtt
```

### 5. Setup MQTT Bridge

```powershell
# Set environment variables
[System.Environment]::SetEnvironmentVariable("INFLUX_TOKEN", "YOUR_TOKEN_HERE", "Machine")
[System.Environment]::SetEnvironmentVariable("INFLUX_ORG", "DataImage", "Machine")
[System.Environment]::SetEnvironmentVariable("INFLUX_BUCKET", "power_monitoring", "Machine")

# Copy bridge script
Copy-Item ".\windows-native\mqtt-to-influxdb-bridge.py" "C:\PowerMonitoring\mqtt-to-influxdb-bridge.py"

# Install as service
$pythonPath = (Get-Command python).Source
& "C:\Tools\nssm-2.24\win64\nssm.exe" install MQTT-Bridge $pythonPath "C:\PowerMonitoring\mqtt-to-influxdb-bridge.py"
& "C:\Tools\nssm-2.24\win64\nssm.exe" set MQTT-Bridge AppDirectory "C:\PowerMonitoring"

# Start service
Start-Service MQTT-Bridge
```

---

## Service Management

### Check Service Status

```powershell
# Check all services
Get-Service mosquitto, InfluxDB, Grafana, MQTT-Bridge | Format-Table -AutoSize
```

### Start/Stop Services

```powershell
# Start all
Start-Service mosquitto, InfluxDB, Grafana, MQTT-Bridge

# Stop all
Stop-Service mosquitto, InfluxDB, Grafana, MQTT-Bridge

# Restart individual service
Restart-Service mosquitto
```

### View Logs

```powershell
# View bridge logs
Get-Content "C:\PowerMonitoring\Logs\mqtt-bridge-stdout.log" -Tail 50 -Wait

# View InfluxDB logs
Get-Content "C:\PowerMonitoring\Logs\influxdb-stdout.log" -Tail 50 -Wait

# View Mosquitto logs
Get-Content "C:\PowerMonitoring\Logs\mosquitto.log" -Tail 50 -Wait
```

---

## Troubleshooting

### MQTT Broker Not Receiving Data

```powershell
# Check if Mosquitto is running
Get-Service mosquitto

# Check if port 1883 is open
Test-NetConnection -ComputerName localhost -Port 1883

# Check firewall
Get-NetFirewallRule -DisplayName "PowerMon-MQTT"

# Test MQTT manually
& "C:\Program Files\mosquitto\mosquitto_pub.exe" -h localhost -t "test" -m "hello"
& "C:\Program Files\mosquitto\mosquitto_sub.exe" -h localhost -t "test"
```

### InfluxDB Not Storing Data

```powershell
# Check InfluxDB service
Get-Service InfluxDB

# Check logs
Get-Content "C:\PowerMonitoring\Logs\influxdb-stderr.log" -Tail 50

# Test InfluxDB API
Invoke-WebRequest -Uri "http://localhost:8086/health"
```

### Bridge Not Working

```powershell
# Check bridge service
Get-Service MQTT-Bridge

# Check environment variables
[System.Environment]::GetEnvironmentVariable("INFLUX_TOKEN", "Machine")

# View bridge logs
Get-Content "C:\PowerMonitoring\Logs\mqtt-bridge-stdout.log" -Tail 100

# Restart bridge
Restart-Service MQTT-Bridge
```

### Raspberry Pi Can't Connect

```powershell
# Check firewall on Windows Server
Get-NetFirewallRule -DisplayName "PowerMon*"

# Test connectivity from Pi
# On Pi, run:
ping YOUR_WINDOWS_SERVER_IP
telnet YOUR_WINDOWS_SERVER_IP 1883
```

---

## Uninstallation

```powershell
# Stop and remove services
Stop-Service MQTT-Bridge, InfluxDB, Grafana, mosquitto

& "C:\Tools\nssm.exe" remove MQTT-Bridge confirm
& "C:\Tools\nssm.exe" remove InfluxDB confirm

# Uninstall Grafana
wmic product where "name like 'Grafana%'" call uninstall

# Uninstall Mosquitto
& "C:\Program Files\mosquitto\uninstall.exe" /S

# Remove directories
Remove-Item "C:\PowerMonitoring" -Recurse -Force
```

---

## Performance Tuning

### Optimize InfluxDB

Edit InfluxDB config (create if doesn't exist):
`C:\PowerMonitoring\InfluxDB\config.yml`

```yaml
storage-cache-max-memory-size: 1073741824  # 1GB
storage-cache-snapshot-memory-size: 26214400  # 25MB
```

### Optimize Mosquitto

Edit `C:\Program Files\mosquitto\mosquitto.conf`:

```conf
max_connections 100
max_queued_messages 1000
message_size_limit 1024
```

---

## Backup and Restore

### Backup InfluxDB Data

```powershell
# Stop InfluxDB
Stop-Service InfluxDB

# Backup data directory
Copy-Item "C:\PowerMonitoring\Data\InfluxDB" "C:\Backups\InfluxDB_$(Get-Date -Format 'yyyy-MM-dd')" -Recurse

# Start InfluxDB
Start-Service InfluxDB
```

### Restore InfluxDB Data

```powershell
# Stop InfluxDB
Stop-Service InfluxDB

# Restore data
Remove-Item "C:\PowerMonitoring\Data\InfluxDB\*" -Recurse -Force
Copy-Item "C:\Backups\InfluxDB_2025-11-19\*" "C:\PowerMonitoring\Data\InfluxDB" -Recurse

# Start InfluxDB
Start-Service InfluxDB
```

---

## Support

For issues, check:
1. Service status: `Get-Service mosquitto, InfluxDB, Grafana, MQTT-Bridge`
2. Logs in `C:\PowerMonitoring\Logs\`
3. Firewall rules: `Get-NetFirewallRule -DisplayName "PowerMon*"`
4. Network connectivity from Raspberry Pis

---

## Differences from Docker Version

| Feature | Docker Version | Windows Native |
|---------|---------------|----------------|
| **Installation** | `docker-compose up` | Run PowerShell script |
| **Services** | Docker containers | Windows services |
| **Updates** | `docker-compose pull` | Manual updates |
| **Logs** | `docker logs` | Files in C:\PowerMonitoring\Logs |
| **Configuration** | docker-compose.yml | Windows service configs |
| **Portability** | High (any Docker host) | Windows only |
| **Performance** | Good | Slightly better (native) |
| **Complexity** | Low | Medium |

---

## Migration to Docker (Future)

When you get Ubuntu server, migration is straightforward:

1. Export Grafana dashboards
2. Backup InfluxDB data
3. Deploy Docker version on Ubuntu
4. Import dashboards
5. Restore InfluxDB data
6. Update Raspberry Pi configs to new server IP

Estimated migration time: 30 minutes

---

**That's it! Your Windows native installation is complete.**
