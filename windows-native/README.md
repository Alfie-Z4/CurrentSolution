# Windows Native Installation

This folder contains everything needed to run the Power Monitoring solution natively on Windows Server 2016 **without Docker**.

## Files in This Folder

### Installation Scripts

- **`setup-windows-native.ps1`** - Automated installation script
  - Downloads and installs all components
  - Configures Windows services
  - Sets up firewall rules
  - **Run this first!**

### Python Scripts

- **`mqtt-to-influxdb-bridge.py`** - MQTT to InfluxDB data bridge
  - Subscribes to MQTT topics from Raspberry Pis
  - Writes data to InfluxDB
  - Replaces Telegraf from Docker version
  - Runs as Windows service

### Configuration

- **`requirements.txt`** - Python package dependencies
  - influxdb-client
  - paho-mqtt

### Documentation

- **`WINDOWS_NATIVE_GUIDE.md`** - Complete installation and troubleshooting guide
  - Step-by-step installation
  - Service management
  - Troubleshooting
  - Backup/restore

## Quick Start

### Prerequisites

- Windows Server 2016 or newer
- Administrator access
- Internet connection

### Installation (5 Minutes)

```powershell
# 1. Open PowerShell as Administrator

# 2. Navigate to this directory
cd C:\PowerMonitoring\windows-native

# 3. Run installation script
.\setup-windows-native.ps1

# 4. Follow the prompts
# - Complete InfluxDB setup in browser
# - Copy API token when shown
# - Paste token when script asks

# Done! Services are running
```

## What Gets Installed

| Component | Port | Purpose |
|-----------|------|---------|
| **Mosquitto MQTT** | 1883 | Receives data from Raspberry Pis |
| **InfluxDB** | 8086 | Stores time-series data |
| **Grafana** | 3000 | Visualization dashboards |
| **MQTT Bridge** | N/A | Transfers MQTT → InfluxDB |
| **Python 3.11** | N/A | Runs bridge script |

All run as Windows services and auto-start on boot.

## Access URLs

After installation:

- **Grafana:** http://YOUR_SERVER_IP:3000
  - Username: `admin`
  - Password: `admin` (change on first login)

- **InfluxDB:** http://YOUR_SERVER_IP:8086
  - Username: `admin`
  - Password: `DataImage2025!`

## Raspberry Pi Configuration

Update each Pi's config to point to your Windows Server:

```toml
# File: current_sensing/config/user_config.toml

[mqtt]
    broker = "YOUR_WINDOWS_SERVER_IP"  # ← Change this
    port = 1883
```

Restart Pi services:
```bash
docker-compose -f docker-compose-pi.yml restart
```

## Service Management

```powershell
# Check status
Get-Service mosquitto, InfluxDB, Grafana, MQTT-Bridge

# Start all
Start-Service mosquitto, InfluxDB, Grafana, MQTT-Bridge

# Stop all
Stop-Service mosquitto, InfluxDB, Grafana, MQTT-Bridge

# Restart one
Restart-Service MQTT-Bridge
```

## View Logs

```powershell
# Bridge logs
Get-Content C:\PowerMonitoring\Logs\mqtt-bridge-stdout.log -Tail 50 -Wait

# InfluxDB logs
Get-Content C:\PowerMonitoring\Logs\influxdb-stdout.log -Tail 50

# Mosquitto logs
Get-Content C:\PowerMonitoring\Logs\mosquitto.log -Tail 50
```

## Troubleshooting

### No data in Grafana?

1. Check services are running:
   ```powershell
   Get-Service mosquitto, InfluxDB, MQTT-Bridge | Format-Table
   ```

2. Check bridge logs:
   ```powershell
   Get-Content C:\PowerMonitoring\Logs\mqtt-bridge-stdout.log -Tail 100
   ```

3. Check Pi is sending data:
   ```bash
   # On Raspberry Pi
   docker-compose -f docker-compose-pi.yml logs -f
   ```

### MQTT Connection Issues?

1. Test from Windows Server:
   ```powershell
   & "C:\Program Files\mosquitto\mosquitto_sub.exe" -h localhost -t "power_monitoring/#" -v
   ```

2. Check firewall:
   ```powershell
   Get-NetFirewallRule -DisplayName "PowerMon*"
   ```

3. Test from Pi:
   ```bash
   # On Raspberry Pi
   telnet YOUR_WINDOWS_IP 1883
   ```

## Migration to Docker (Future)

When you get an Ubuntu server, you can easily migrate:

1. Backup InfluxDB data
2. Export Grafana dashboards
3. Deploy Docker version on Ubuntu
4. Restore data
5. Update Pi configs

See `WINDOWS_NATIVE_GUIDE.md` for details.

## Support

For detailed troubleshooting, see **`WINDOWS_NATIVE_GUIDE.md`**

For code issues, check the main repository README.

## File Structure After Installation

```
C:\PowerMonitoring\
├── mqtt-to-influxdb-bridge.py  ← Bridge script (running as service)
├── Data\
│   ├── InfluxDB\               ← Time-series data storage
│   ├── Mosquitto\              ← MQTT persistence
│   └── Grafana\                ← Grafana configs
├── Logs\
│   ├── mqtt-bridge-stdout.log  ← Bridge logs
│   ├── influxdb-stdout.log     ← InfluxDB logs
│   └── mosquitto.log           ← MQTT broker logs
└── InfluxDB\
    └── influxd.exe             ← InfluxDB executable

C:\Program Files\mosquitto\     ← MQTT broker installation
C:\Program Files\GrafanaLabs\   ← Grafana installation
C:\Tools\nssm.exe               ← Service manager
```

---

**Ready to install? Run `setup-windows-native.ps1` now!**
