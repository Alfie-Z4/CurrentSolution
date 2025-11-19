# Power Monitoring - Complete Installation Guide

## Table of Contents

1. [Quick Overview](#quick-overview)
2. [Installation Steps](#installation-steps)
3. [Raspberry Pi Configuration](#raspberry-pi-configuration)
4. [Verification](#verification)
5. [Troubleshooting](#troubleshooting)
6. [Next Steps](#next-steps)

---

## Quick Overview

### What We're Installing

**On Windows Server 2016:**
- ✅ Mosquitto MQTT Broker (receives data from Pis)
- ✅ InfluxDB (stores time-series data)
- ✅ Grafana (visualization dashboards)
- ✅ Python bridge script (MQTT → InfluxDB)

**On Raspberry Pis (no changes needed):**
- Current sensing Docker container (already working)
- Just update config to point to Windows Server

### Total Time Required

- **Server installation:** 15-20 minutes (mostly automated)
- **Raspberry Pi configuration:** 5 minutes per Pi
- **Total:** ~30-45 minutes for complete setup

---

## Installation Steps

### Step 1: Prepare Windows Server

**Open PowerShell as Administrator:**

1. Press **Windows + X**
2. Select **"Windows PowerShell (Admin)"**

**Navigate to your project:**

```powershell
cd C:\Users\alfredoziccardi\~\PowerUniversitySolution
```

---

### Step 2: Run Installation Script

```powershell
.\windows-native\setup-windows-native.ps1
```

**What happens:**

The script will:
1. ✅ Create directories (C:\PowerMonitoring, C:\Logs, etc.)
2. ✅ Download Mosquitto MQTT Broker
3. ✅ Download InfluxDB
4. ✅ Download Grafana
5. ✅ Install Python 3.11
6. ✅ Install Python packages
7. ✅ Configure Windows Firewall
8. ✅ Create Windows services
9. ✅ Start all services

**This takes 15-20 minutes** (mostly download time).

---

### Step 3: Setup InfluxDB

**During installation, the script will pause and show:**

```
  InfluxDB is running at: http://localhost:8086
  Please complete InfluxDB setup in your browser:
    1. Go to http://localhost:8086
    2. Username: admin
    3. Password: DataImage2025!
    4. Organization: DataImage
    5. Bucket: power_monitoring
    6. Copy the API token shown

  Paste your InfluxDB API token here:
```

**What to do:**

1. **Open browser** and go to `http://localhost:8086`
2. **Click "Get Started"**
3. **Fill in the form:**
   - Username: `admin`
   - Password: `DataImage2025!`
   - Confirm Password: `DataImage2025!`
   - Initial Organization Name: `DataImage`
   - Initial Bucket Name: `power_monitoring`
4. **Click "Continue"**
5. **Copy the API Token** shown on the next screen
6. **Go back to PowerShell** and paste the token

---

### Step 4: Wait for Installation to Complete

The script will finish setting up services and show:

```
============================================================================
 Installation Summary
============================================================================

Services Running:
  [✓] Mosquitto MQTT Broker    - Port 1883
  [✓] InfluxDB Database         - Port 8086
  [✓] Grafana Dashboard         - Port 3000
  [✓] MQTT-InfluxDB Bridge      - Running

Access URLs:
  Grafana:  http://192.168.1.XXX:3000
            Username: admin, Password: admin

  InfluxDB: http://192.168.1.XXX:8086
            Username: admin, Password: DataImage2025!
```

**Write down your server IP!** You'll need it for Raspberry Pis.

---

### Step 5: Configure Grafana

1. **Open browser:** `http://YOUR_SERVER_IP:3000`

2. **Login:**
   - Username: `admin`
   - Password: `admin`
   - Set new password when prompted (e.g., `DataImage2025!`)

3. **Add InfluxDB Data Source:**
   - Click ⚙️ (Settings) → **Data Sources**
   - Click **Add data source**
   - Select **InfluxDB**
   - Configure:
     - **Name:** `InfluxDB`
     - **Query Language:** `Flux`
     - **URL:** `http://localhost:8086`
     - **Access:** `Server (default)`
     - **Organization:** `DataImage`
     - **Token:** (paste your InfluxDB API token)
     - **Default Bucket:** `power_monitoring`
   - Click **Save & Test**
   - Should show: ✅ **"Data source is working"**

4. **Import Dashboard:**
   - Click **+** (plus icon) → **Import**
   - Click **Upload JSON file**
   - Navigate to: `C:\Users\alfredoziccardi\~\PowerUniversitySolution\dashboards\config\dashboards\Power Monitoring\production_dashboard.json`
   - Select InfluxDB datasource
   - Click **Import**

**Dashboard is now ready!** (will be empty until Pis send data)

---

## Raspberry Pi Configuration

### For Each Raspberry Pi:

#### Step 1: SSH to Raspberry Pi

```bash
ssh pi@your-pi-ip
```

#### Step 2: Navigate to Project

```bash
cd PowerMonitoring
# or wherever you cloned the repository
```

#### Step 3: Edit Configuration

```bash
nano current_sensing/config/user_config.toml
```

#### Step 4: Update MQTT Broker

**Find this section:**
```toml
[mqtt]
    broker = "localhost"  # or whatever it is now
    port = 1883
```

**Change to:**
```toml
[mqtt]
    broker = "192.168.1.XXX"  # ← YOUR WINDOWS SERVER IP
    port = 1883
```

**Also update machine name:**
```toml
[machine]
    machine = "Pi_1"  # ← Unique name (Pi_1, Pi_2, Pi_3, etc.)
```

**Save:** Press `Ctrl + X`, then `Y`, then `Enter`

#### Step 5: Restart Current Sensing

```bash
docker-compose -f docker-compose-pi.yml restart
```

#### Step 6: Verify Connection

```bash
docker-compose -f docker-compose-pi.yml logs -f
```

**Look for:**
```
Connected!
pub topic:power_monitoring/Pi_1/...
```

Press `Ctrl + C` to exit logs.

**Repeat for all Raspberry Pis!**

---

## Verification

### Step 1: Check Services on Windows Server

```powershell
Get-Service mosquitto, InfluxDB, Grafana, MQTT-Bridge | Format-Table -AutoSize
```

**Should show all "Running":**
```
Status  Name         DisplayName
------  ----         -----------
Running mosquitto    Mosquitto Broker
Running InfluxDB     InfluxDB
Running Grafana      Grafana
Running MQTT-Bridge  MQTT-Bridge
```

### Step 2: Check MQTT Messages

```powershell
# Listen to MQTT messages
& "C:\Program Files\mosquitto\mosquitto_sub.exe" -h localhost -t "power_monitoring/#" -v
```

**You should see messages like:**
```
power_monitoring/Pi_1/L1 {"current": 5.2, "voltage": 230, ...}
power_monitoring/Pi_1/L2 {"current": 3.8, "voltage": 230, ...}
```

Press `Ctrl + C` to stop.

### Step 3: Check Data in InfluxDB

1. Open: `http://YOUR_SERVER_IP:8086`
2. Login (admin / DataImage2025!)
3. Click **Data Explorer** (left menu)
4. Select bucket: `power_monitoring`
5. Select measurement: `equipment_power_usage`
6. Click **Submit**

**Should see data points graphed!**

### Step 4: Check Grafana Dashboard

1. Open: `http://YOUR_SERVER_IP:3000`
2. Click **Dashboards** → **Power Monitoring - Production**
3. Click **Machine** dropdown at top
4. Select a Pi (e.g., Pi_1)

**Should see live data:**
- ✅ Current readings
- ✅ Power calculations
- ✅ Graphs updating
- ✅ Gauges moving

**🎉 SUCCESS! Everything is working!**

---

## Troubleshooting

### Problem: No services running

**Solution:**
```powershell
# Check Windows Firewall isn't blocking
Get-NetFirewallRule -DisplayName "PowerMon*"

# Start services manually
Start-Service mosquitto, InfluxDB, Grafana, MQTT-Bridge

# Check for errors
Get-Service mosquitto, InfluxDB, Grafana, MQTT-Bridge | Format-List
```

### Problem: Raspberry Pi can't connect

**Check from Pi:**
```bash
# Test network connectivity
ping YOUR_WINDOWS_IP

# Test MQTT port
telnet YOUR_WINDOWS_IP 1883
```

**Check on Windows Server:**
```powershell
# Test MQTT broker locally
& "C:\Program Files\mosquitto\mosquitto_pub.exe" -h localhost -t "test" -m "hello"
& "C:\Program Files\mosquitto\mosquitto_sub.exe" -h localhost -t "test"

# Check firewall
Test-NetConnection -ComputerName localhost -Port 1883
```

### Problem: Data not appearing in InfluxDB

**Check bridge logs:**
```powershell
Get-Content C:\PowerMonitoring\Logs\mqtt-bridge-stdout.log -Tail 100
```

**Check environment variable:**
```powershell
[System.Environment]::GetEnvironmentVariable("INFLUX_TOKEN", "Machine")
```

**Restart bridge:**
```powershell
Restart-Service MQTT-Bridge
```

### Problem: Grafana shows "No Data"

**Check datasource:**
1. Grafana → ⚙️ Settings → Data Sources
2. Click InfluxDB
3. Scroll down, click **Save & Test**
4. Should show green checkmark

**Check query:**
1. Dashboard → Panel → Edit
2. Check query is correct
3. Check bucket name is `power_monitoring`

### Problem: Installation script failed

**Manual installation:**

See: `windows-native\WINDOWS_NATIVE_GUIDE.md` section "Manual Installation"

---

## Next Steps

### Monitor Your System

**View logs in real-time:**
```powershell
# Bridge logs
Get-Content C:\PowerMonitoring\Logs\mqtt-bridge-stdout.log -Tail 50 -Wait

# Check what data is being stored
& "C:\Program Files\mosquitto\mosquitto_sub.exe" -h localhost -t "power_monitoring/#" -v
```

### Backup Data

**Create backup:**
```powershell
# Stop InfluxDB
Stop-Service InfluxDB

# Backup
Copy-Item "C:\PowerMonitoring\Data\InfluxDB" "C:\Backups\InfluxDB_$(Get-Date -Format 'yyyy-MM-dd')" -Recurse

# Start InfluxDB
Start-Service InfluxDB
```

### Add More Raspberry Pis

For each new Pi:
1. Update `user_config.toml` with server IP
2. Set unique machine name (Pi_4, Pi_5, etc.)
3. Restart current_sensing
4. New machine appears in Grafana dropdown automatically!

### Customize Dashboards

- Edit existing panels
- Add new visualizations
- Create alerts
- Share with team

---

## Quick Reference

### Important URLs

- **Grafana:** http://YOUR_SERVER_IP:3000 (admin / YOUR_PASSWORD)
- **InfluxDB:** http://YOUR_SERVER_IP:8086 (admin / DataImage2025!)

### Important Paths

- **Logs:** `C:\PowerMonitoring\Logs\`
- **Data:** `C:\PowerMonitoring\Data\`
- **Config:** `C:\Program Files\mosquitto\mosquitto.conf`

### Important Commands

```powershell
# Service management
Get-Service mosquitto, InfluxDB, Grafana, MQTT-Bridge
Start-Service MQTT-Bridge
Restart-Service mosquitto

# View logs
Get-Content C:\PowerMonitoring\Logs\mqtt-bridge-stdout.log -Tail 50 -Wait

# Test MQTT
& "C:\Program Files\mosquitto\mosquitto_sub.exe" -h localhost -t "power_monitoring/#"
```

---

## Support

**For detailed troubleshooting:**
- See `windows-native\WINDOWS_NATIVE_GUIDE.md`

**For code issues:**
- Check GitHub repository issues
- Review application logs in `C:\PowerMonitoring\Logs\`

**For Raspberry Pi issues:**
- Check Docker logs: `docker-compose logs -f`
- Verify config: `cat current_sensing/config/user_config.toml`

---

**🎉 Congratulations! Your Power Monitoring system is now running!**
