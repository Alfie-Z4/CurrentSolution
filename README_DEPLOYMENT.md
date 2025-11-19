# Power Monitoring System - Production Deployment

## 🚀 Quick Start

### Windows Server Setup (One Command!)

```powershell
cd C:\PowerMonitoring
.\deploy-central-server.ps1
```

### Raspberry Pi Setup (One Command!)

```bash
cd /home/pi/PowerMonitoring
./deploy-pi.sh Pi_1 YOUR_SERVER_IP
```

---

## 📚 Documentation

Choose the guide for your setup:

### **Windows Server Deployment** ⭐ **START HERE**
👉 **[WINDOWS_SETUP_GUIDE.md](WINDOWS_SETUP_GUIDE.md)** - Complete guide for Windows Server + Raspberry Pis

### Alternative/Additional Guides
- **[QUICK_START.md](QUICK_START.md)** - Original quick reference
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Detailed Linux deployment guide

---

## 📋 What You Need

### Central Server (Windows)
- Windows Server 2019/2022 or Windows 10/11 Pro
- Docker Desktop installed
- Ports 1883, 3000 open
- Static IP recommended

### Each Raspberry Pi
- Raspberry Pi 3/4/5
- Docker installed
- Current sensors connected
- Network access to server

---

## 🏗️ Architecture

```
Windows Server (All Services)
    ↓ MQTT (1883)
    ↓ Grafana (3000)
    ↑
Pi_1, Pi_2, Pi_3, Pi_4, Pi_5
(Current Sensing Only)
```

---

## ✅ Pre-Configured Features

All changes have been applied to your code:

- ✅ **Fixed datasource UIDs** - No more "datasource not found" errors
- ✅ **Auto-discovery dashboards** - Machines appear automatically
- ✅ **Windows PowerShell scripts** - One-command deployment
- ✅ **Production-ready dashboard** - Clean, professional interface
- ✅ **Stable configuration** - Works with export/import

---

## 🎯 Setup Summary

### On Windows Server:

1. Install Docker Desktop
2. Configure firewall (ports 1883, 3000)
3. Run: `.\deploy-central-server.ps1`
4. Note the IP address shown
5. Access Grafana: `http://SERVER-IP:3000`

### On Each Raspberry Pi:

1. Install Docker
2. Copy project files
3. Edit config: Set server IP and unique machine name
4. Run: `./deploy-pi.sh Pi_X SERVER_IP`
5. Verify logs show "Connected!"

### In Grafana:

1. Login: admin / admin (change password)
2. Open dashboard: "Power Monitoring - Production"
3. Select machine from dropdown
4. View real-time current and power data

---

## 📁 Key Files

### Configuration Files (Updated):
- `dashboards/config/provisioning/datasources/influxdb.yml` - InfluxDB datasource with stable UID
- `dashboards/config/provisioning/datasources/analysis.yml` - Analysis datasource with stable UID
- `dashboards/config/dashboards/Power Monitoring/production_dashboard.json` - New production dashboard

### Deployment Files (New):
- `deploy-central-server.ps1` - Windows server deployment script
- `deploy-pi.sh` - Raspberry Pi deployment script
- `docker-compose-central.yml` - Central server services
- `docker-compose-pi.yml` - Pi current sensing service

### Documentation (New):
- `WINDOWS_SETUP_GUIDE.md` - **Complete Windows setup guide** ⭐
- `PI_CONFIG_TEMPLATE.toml` - Configuration template for Pis

---

## 🔧 Common Commands

### Windows Server

```powershell
# Start services
.\deploy-central-server.ps1

# Check status
docker-compose -f docker-compose-central.yml ps

# View logs
docker-compose -f docker-compose-central.yml logs -f

# Stop services
docker-compose -f docker-compose-central.yml down
```

### Raspberry Pi

```bash
# Deploy (prompts for machine name and server IP)
./deploy-pi.sh

# Or with arguments
./deploy-pi.sh Pi_1 192.168.1.100

# View logs
docker-compose -f docker-compose-pi.yml logs -f

# Stop
docker-compose -f docker-compose-pi.yml down
```

---

## 🌐 Access URLs

After deployment, access:

- **Grafana Dashboard:** `http://YOUR-SERVER-IP:3000`
- **Graph UI:** `http://YOUR-SERVER-IP:80`
- **InfluxDB:** `http://YOUR-SERVER-IP:8086`

---

## 🆘 Troubleshooting

### No data in Grafana?

1. Check Pi logs: `docker-compose -f docker-compose-pi.yml logs -f`
2. Verify MQTT messages on server: `docker exec -it mqtt_broker mosquitto_sub -t "power_monitoring/#" -v`
3. Check time range in Grafana (top right)

### Pi can't connect?

1. Check firewall on Windows: Port 1883 must be open
2. Ping server from Pi: `ping YOUR-SERVER-IP`
3. Verify server IP in Pi config is correct

### Full troubleshooting guide in [WINDOWS_SETUP_GUIDE.md](WINDOWS_SETUP_GUIDE.md)

---

## 📊 What's New (Production Ready)

### Changes Applied:

1. **Datasource UIDs Fixed**
   - InfluxDB: `powermon-influxdb`
   - Analysis: `powermon-analysis`
   - No more broken references on export/import

2. **Auto-Discovery Dashboard**
   - Machine dropdown auto-populates from InfluxDB
   - No manual configuration needed
   - Add new Pi → automatically appears

3. **Windows Deployment**
   - PowerShell script for server setup
   - Automatic firewall detection
   - IP address auto-detection
   - One-command deployment

4. **Clean Documentation**
   - Windows-specific guide with screenshots descriptions
   - Step-by-step PowerShell commands
   - Troubleshooting for Windows environment

---

## 🎉 You're Ready to Deploy!

Follow **[WINDOWS_SETUP_GUIDE.md](WINDOWS_SETUP_GUIDE.md)** for complete step-by-step instructions.

The system is now production-ready with all fixes applied!
