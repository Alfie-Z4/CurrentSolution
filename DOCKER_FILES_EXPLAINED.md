# Docker Files Explained - What You Need to Know

## ✅ You Have Everything You Need - Don't Delete Anything!

Your codebase has multiple Docker files, and **this is correct**. Here's what they all do and why you need them.

---

## 📁 Docker Files in Your Project

### **Main Docker Compose Files** (Choose ONE based on your deployment)

#### 1. `docker-compose-central.yml` ⭐ **USE THIS ON WINDOWS SERVER**
**What it does:** Runs all services EXCEPT current-sensing
**Services:** MQTT, InfluxDB, Telegraf, Grafana, Analysis, Graph UI
**When to use:** On your Windows server (central location)
**Command:**
```powershell
docker-compose -f docker-compose-central.yml up -d
```

#### 2. `docker-compose-pi.yml` ⭐ **USE THIS ON EACH RASPBERRY PI**
**What it does:** Runs ONLY current-sensing service
**Services:** Current sensing (measurement)
**When to use:** On each Raspberry Pi device
**Command:**
```bash
docker-compose -f docker-compose-pi.yml up -d
```

#### 3. `docker-compose.yml` (Original - Keep for Reference)
**What it does:** Runs EVERYTHING on one machine (all-in-one)
**Services:** Current-sensing + MQTT + InfluxDB + Telegraf + Grafana + Analysis + Graph
**When to use:** Testing on a single computer, or as reference
**Command:**
```powershell
docker-compose up -d
```

---

### **Service-Specific Files** (Don't Touch - Used by Main Compose Files)

Each service folder has its own files that define how to build/run that service:

#### `analysis/app.yml`
- Defines the Analysis service container
- Referenced by main docker-compose files

#### `current_sensing/app.yml` + `current_sensing/Dockerfile`
- Defines how to build the current sensing container
- Includes Python dependencies and sensor code

#### `dashboards/app.yml`
- Defines Grafana container configuration
- Mounts dashboard and datasource configs

#### `graph/app.yml` + `graph/Dockerfile`
- Defines the Graph UI service (web interface)
- Optional service for visualization

#### `mqtt_broker/app.yml`
- Defines MQTT broker (Mosquitto) container
- Uses official Eclipse Mosquitto image

#### `timeseries_datastorage/app.yml`
- Defines TWO services:
  - `db` (InfluxDB)
  - `telegraf` (data pipeline)

---

## 🎯 How Docker Compose Works

The main docker-compose files **reference** the service-specific app.yml files using the `extends` keyword.

**Example from docker-compose-central.yml:**
```yaml
services:
    mqtt_broker:
        extends:
            file: mqtt_broker/app.yml  # ← Uses this file
            service: app
```

This means:
- The main compose file orchestrates everything
- Each service folder contains its specific configuration
- **You need ALL the files** - they work together

---

## ❌ **DO NOT DELETE ANY DOCKER FILES**

### Why You Need All Three docker-compose Files:

1. **`docker-compose-central.yml`** - For your Windows server deployment
2. **`docker-compose-pi.yml`** - For your Raspberry Pi deployment
3. **`docker-compose.yml`** - For testing/reference/single-machine setup

### Why You Need All Service Folders:

Even though Raspberry Pis only run `current-sensing`, you still need ALL folders on the Windows server because:
- `docker-compose-central.yml` references: analysis, mqtt_broker, timeseries_datastorage, dashboards, graph
- Each of these needs its own `app.yml` and `Dockerfile`

---

## 📦 What to Copy Where

### **On Windows Server:**
✅ **Copy ENTIRE project folder**
```
C:\PowerMonitoring\
  ├── analysis/              ← Need this
  ├── current_sensing/       ← Don't need to run, but files must exist
  ├── dashboards/            ← Need this
  ├── graph/                 ← Need this
  ├── mqtt_broker/           ← Need this
  ├── timeseries_datastorage/ ← Need this
  ├── docker-compose-central.yml ← This is what you run!
  ├── deploy-central-server.ps1
  └── (all other files)
```

### **On Each Raspberry Pi:**
✅ **Copy ENTIRE project folder**
```
/home/pi/PowerMonitoring/
  ├── current_sensing/       ← Need this
  ├── analysis/              ← Files must exist (even if not used)
  ├── dashboards/            ← Files must exist
  ├── mqtt_broker/           ← Files must exist
  ├── (etc...)
  ├── docker-compose-pi.yml  ← This is what you run!
  └── deploy-pi.sh
```

**Why copy everything?** Docker Compose may need to reference file paths, even if not building those services.

---

## 🚀 Which Command to Run

### **On Windows Server:**
```powershell
# Option 1: Use the script (recommended)
.\deploy-central-server.ps1

# Option 2: Manual command
docker-compose -f docker-compose-central.yml up -d
```

**How it knows which docker-compose file:**
- The `-f` flag tells docker-compose which file to use
- Or the script explicitly calls `docker-compose-central.yml`

### **On Raspberry Pi:**
```bash
# Option 1: Use the script (recommended)
./deploy-pi.sh Pi_1 192.168.1.100

# Option 2: Manual command
docker-compose -f docker-compose-pi.yml up -d
```

---

## 🔍 What Happens When You Run the Scripts

### `deploy-central-server.ps1` (Windows):
1. Checks Docker is running
2. Runs: `docker-compose -f docker-compose-central.yml build`
3. Runs: `docker-compose -f docker-compose-central.yml up -d`
4. This starts: MQTT, InfluxDB, Telegraf, Grafana, Analysis, Graph
5. Does NOT start: current-sensing

### `deploy-pi.sh` (Raspberry Pi):
1. Updates config file with server IP and machine name
2. Runs: `docker-compose -f docker-compose-pi.yml build`
3. Runs: `docker-compose -f docker-compose-pi.yml up -d`
4. This starts: current-sensing only
5. Does NOT start: MQTT, InfluxDB, Grafana, etc.

---

## 📊 Summary Table

| File | Use On | Starts What Services | When to Use |
|------|--------|---------------------|-------------|
| `docker-compose-central.yml` | Windows Server | MQTT, InfluxDB, Telegraf, Grafana, Analysis, Graph | **Your main deployment** |
| `docker-compose-pi.yml` | Raspberry Pi | current-sensing only | Each Pi device |
| `docker-compose.yml` | Any single machine | ALL services | Testing/reference |

---

## ✅ **Simple Answer**

### Your Questions:

**Q: Do I need the entire codebase on the server?**
✅ **YES** - Copy everything to both Windows server and Raspberry Pis

**Q: Will it know which docker to run?**
✅ **YES** - The script (`deploy-central-server.ps1`) automatically uses `docker-compose-central.yml`
- If you run manually, use: `docker-compose -f docker-compose-central.yml up -d`

**Q: Do I need to remove some files?**
❌ **NO** - Keep all files. They're all needed as references and dependencies.

---

## 🎯 Quick Deployment Summary

### On Windows Server:
```powershell
# 1. Copy entire folder to C:\PowerMonitoring
# 2. Open PowerShell in that folder
cd C:\PowerMonitoring

# 3. Run the script - it knows to use docker-compose-central.yml
.\deploy-central-server.ps1
```

### On Raspberry Pi:
```bash
# 1. Copy entire folder to /home/pi/PowerMonitoring
# 2. SSH to Pi and navigate
cd /home/pi/PowerMonitoring

# 3. Run the script - it knows to use docker-compose-pi.yml
./deploy-pi.sh Pi_1 YOUR_SERVER_IP
```

---

## 🔒 The Magic is in the Scripts

The deployment scripts **automatically use the correct docker-compose file** for each platform:

**`deploy-central-server.ps1` (line 30):**
```powershell
docker-compose -f docker-compose-central.yml build
```

**`deploy-pi.sh` (line 50):**
```bash
docker-compose -f docker-compose-pi.yml build
```

You don't have to think about it - just run the script! ✅

---

## 📖 How to Open WINDOWS_SETUP_GUIDE.md

The file exists and is readable. Try these methods:

### Method 1: Open with Notepad
```powershell
notepad WINDOWS_SETUP_GUIDE.md
```

### Method 2: Open with VS Code (if installed)
```powershell
code WINDOWS_SETUP_GUIDE.md
```

### Method 3: Open with Default Markdown Viewer
```powershell
Start-Process WINDOWS_SETUP_GUIDE.md
```

### Method 4: View in PowerShell
```powershell
Get-Content WINDOWS_SETUP_GUIDE.md | more
```

### Method 5: Open Folder and Double-Click
```powershell
explorer .
# Then double-click WINDOWS_SETUP_GUIDE.md
```

---

**Bottom Line:**
- ✅ Keep all files
- ✅ Copy entire project to both server and Pis
- ✅ Run `.\deploy-central-server.ps1` on Windows
- ✅ Run `./deploy-pi.sh` on Pis
- ✅ Scripts automatically use the correct docker-compose file

**No manual file management needed!** 🎉
