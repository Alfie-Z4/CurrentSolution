# ============================================================================
# Power Monitoring - Windows Native Installation Script
# ============================================================================
# This script installs all components natively on Windows Server 2016
# No Docker required - everything runs as Windows services
# ============================================================================

param(
    [string]$InfluxToken = "",
    [string]$ServerIP = ""
)

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " Power Monitoring - Windows Native Setup" -ForegroundColor Cyan
Write-Host " Company: DataImage" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Get server IP if not provided
if ([string]::IsNullOrEmpty($ServerIP)) {
    $ServerIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*"} | Select-Object -First 1).IPAddress
    Write-Host "Detected Server IP: $ServerIP" -ForegroundColor Green
}

# Create directories
Write-Host "`n[1/10] Creating directories..." -ForegroundColor Yellow
$directories = @(
    "C:\PowerMonitoring",
    "C:\PowerMonitoring\Data\InfluxDB",
    "C:\PowerMonitoring\Data\Mosquitto",
    "C:\PowerMonitoring\Data\Grafana",
    "C:\PowerMonitoring\Logs",
    "C:\Scripts",
    "C:\Tools"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Gray
    }
}

# Enable TLS 1.2 for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ============================================================================
# Install Mosquitto MQTT Broker
# ============================================================================
Write-Host "`n[2/10] Installing Mosquitto MQTT Broker..." -ForegroundColor Yellow

$mosquittoInstaller = "C:\Temp\mosquitto-installer.exe"
if (-not (Test-Path "C:\Program Files\mosquitto\mosquitto.exe")) {
    try {
        Write-Host "  Downloading Mosquitto..." -ForegroundColor Gray
        $url = "https://mosquitto.org/files/binary/win64/mosquitto-2.0.18-install-windows-x64.exe"
        Invoke-WebRequest -Uri $url -OutFile $mosquittoInstaller -UseBasicParsing
        
        Write-Host "  Installing Mosquitto..." -ForegroundColor Gray
        Start-Process $mosquittoInstaller -ArgumentList "/S" -Wait
        
        Write-Host "  Mosquitto installed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install Mosquitto: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  Mosquitto already installed" -ForegroundColor Green
}

# Configure Mosquitto
$mosquittoConf = @"
# Mosquitto Configuration for Power Monitoring
listener 1883 0.0.0.0
allow_anonymous true
persistence true
persistence_location C:/PowerMonitoring/Data/Mosquitto/
log_dest file C:/PowerMonitoring/Logs/mosquitto.log
log_type all
"@

Set-Content -Path "C:\Program Files\mosquitto\mosquitto.conf" -Value $mosquittoConf -Force
Write-Host "  Configured Mosquitto" -ForegroundColor Gray

# Start Mosquitto service
try {
    Restart-Service mosquitto -ErrorAction Stop
    Set-Service mosquitto -StartupType Automatic
    Write-Host "  Mosquitto service started" -ForegroundColor Green
} catch {
    Write-Host "  Warning: Could not start Mosquitto service: $_" -ForegroundColor Yellow
}

# ============================================================================
# Install InfluxDB
# ============================================================================
Write-Host "`n[3/10] Installing InfluxDB..." -ForegroundColor Yellow

if (-not (Test-Path "C:\PowerMonitoring\InfluxDB\influxd.exe")) {
    try {
        Write-Host "  Downloading InfluxDB..." -ForegroundColor Gray
        $url = "https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.4-windows-amd64.zip"
        $zipFile = "C:\Temp\influxdb.zip"
        Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing
        
        Write-Host "  Extracting InfluxDB..." -ForegroundColor Gray
        Expand-Archive -Path $zipFile -DestinationPath "C:\PowerMonitoring\InfluxDB" -Force
        
        # Move files from nested directory if needed
        $influxDir = Get-ChildItem "C:\PowerMonitoring\InfluxDB" -Directory | Select-Object -First 1
        if ($influxDir) {
            Get-ChildItem $influxDir.FullName | Move-Item -Destination "C:\PowerMonitoring\InfluxDB" -Force
            Remove-Item $influxDir.FullName -Force
        }
        
        Write-Host "  InfluxDB extracted successfully!" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install InfluxDB: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  InfluxDB already installed" -ForegroundColor Green
}

# ============================================================================
# Install NSSM (Service Wrapper)
# ============================================================================
Write-Host "`n[4/10] Installing NSSM (Service Manager)..." -ForegroundColor Yellow

if (-not (Test-Path "C:\Tools\nssm.exe")) {
    try {
        Write-Host "  Downloading NSSM..." -ForegroundColor Gray
        $url = "https://nssm.cc/release/nssm-2.24.zip"
        $zipFile = "C:\Temp\nssm.zip"
        Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing
        
        Expand-Archive -Path $zipFile -DestinationPath "C:\Tools" -Force
        Copy-Item "C:\Tools\nssm-2.24\win64\nssm.exe" "C:\Tools\nssm.exe" -Force
        
        Write-Host "  NSSM installed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install NSSM: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  NSSM already installed" -ForegroundColor Green
}

# Create InfluxDB service
Write-Host "  Creating InfluxDB service..." -ForegroundColor Gray
$nssmPath = "C:\Tools\nssm.exe"

# Remove service if exists
& $nssmPath stop InfluxDB 2>$null
& $nssmPath remove InfluxDB confirm 2>$null

# Install service
& $nssmPath install InfluxDB "C:\PowerMonitoring\InfluxDB\influxd.exe"
& $nssmPath set InfluxDB AppDirectory "C:\PowerMonitoring\InfluxDB"
& $nssmPath set InfluxDB AppStdout "C:\PowerMonitoring\Logs\influxdb-stdout.log"
& $nssmPath set InfluxDB AppStderr "C:\PowerMonitoring\Logs\influxdb-stderr.log"
& $nssmPath set InfluxDB Start SERVICE_AUTO_START

Start-Service InfluxDB
Write-Host "  InfluxDB service started" -ForegroundColor Green

# Wait for InfluxDB to start
Write-Host "  Waiting for InfluxDB to start (10 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# ============================================================================
# Install Grafana
# ============================================================================
Write-Host "`n[5/10] Installing Grafana..." -ForegroundColor Yellow

if (-not (Get-Service Grafana -ErrorAction SilentlyContinue)) {
    try {
        Write-Host "  Downloading Grafana..." -ForegroundColor Gray
        $url = "https://dl.grafana.com/enterprise/release/grafana-enterprise-10.2.3.windows-amd64.msi"
        $msiFile = "C:\Temp\grafana.msi"
        Invoke-WebRequest -Uri $url -OutFile $msiFile -UseBasicParsing
        
        Write-Host "  Installing Grafana..." -ForegroundColor Gray
        Start-Process msiexec.exe -ArgumentList "/i `"$msiFile`" /quiet /norestart" -Wait
        
        Write-Host "  Grafana installed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install Grafana: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  Grafana already installed" -ForegroundColor Green
}

# Start Grafana
try {
    Start-Service Grafana -ErrorAction Stop
    Set-Service Grafana -StartupType Automatic
    Write-Host "  Grafana service started" -ForegroundColor Green
} catch {
    Write-Host "  Warning: Could not start Grafana service: $_" -ForegroundColor Yellow
}

# ============================================================================
# Install Python
# ============================================================================
Write-Host "`n[6/10] Installing Python..." -ForegroundColor Yellow

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    try {
        Write-Host "  Downloading Python 3.11..." -ForegroundColor Gray
        $url = "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe"
        $pythonInstaller = "C:\Temp\python-installer.exe"
        Invoke-WebRequest -Uri $url -OutFile $pythonInstaller -UseBasicParsing
        
        Write-Host "  Installing Python..." -ForegroundColor Gray
        Start-Process $pythonInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Host "  Python installed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install Python: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  Python already installed" -ForegroundColor Green
    python --version
}

# ============================================================================
# Install Python Dependencies
# ============================================================================
Write-Host "`n[7/10] Installing Python packages..." -ForegroundColor Yellow

try {
    python -m pip install --upgrade pip --quiet
    python -m pip install influxdb-client paho-mqtt --quiet
    Write-Host "  Python packages installed" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to install Python packages: $_" -ForegroundColor Red
}

# ============================================================================
# Configure Firewall
# ============================================================================
Write-Host "`n[8/10] Configuring Windows Firewall..." -ForegroundColor Yellow

$firewallRules = @(
    @{Name="PowerMon-MQTT"; Port=1883; Description="MQTT Broker"},
    @{Name="PowerMon-InfluxDB"; Port=8086; Description="InfluxDB"},
    @{Name="PowerMon-Grafana"; Port=3000; Description="Grafana"}
)

foreach ($rule in $firewallRules) {
    try {
        Remove-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName $rule.Name `
                           -Direction Inbound `
                           -Protocol TCP `
                           -LocalPort $rule.Port `
                           -Action Allow `
                           -Description $rule.Description | Out-Null
        Write-Host "  Opened port $($rule.Port) ($($rule.Description))" -ForegroundColor Gray
    } catch {
        Write-Host "  Warning: Could not configure firewall for port $($rule.Port)" -ForegroundColor Yellow
    }
}

# ============================================================================
# Setup MQTT Bridge Service
# ============================================================================
Write-Host "`n[9/10] Setting up MQTT-to-InfluxDB bridge..." -ForegroundColor Yellow

# Copy bridge script
Copy-Item ".\windows-native\mqtt-to-influxdb-bridge.py" "C:\PowerMonitoring\mqtt-to-influxdb-bridge.py" -Force

Write-Host ""
Write-Host "  InfluxDB is running at: http://localhost:8086" -ForegroundColor Cyan
Write-Host "  Please complete InfluxDB setup in your browser:" -ForegroundColor Yellow
Write-Host "    1. Go to http://localhost:8086" -ForegroundColor Gray
Write-Host "    2. Username: admin" -ForegroundColor Gray
Write-Host "    3. Password: DataImage2025!" -ForegroundColor Gray
Write-Host "    4. Organization: DataImage" -ForegroundColor Gray
Write-Host "    5. Bucket: power_monitoring" -ForegroundColor Gray
Write-Host "    6. Copy the API token shown" -ForegroundColor Gray
Write-Host ""

if ([string]::IsNullOrEmpty($InfluxToken)) {
    $InfluxToken = Read-Host "  Paste your InfluxDB API token here"
}

# Set environment variable for bridge
[System.Environment]::SetEnvironmentVariable("INFLUX_TOKEN", $InfluxToken, "Machine")
[System.Environment]::SetEnvironmentVariable("INFLUX_ORG", "DataImage", "Machine")
[System.Environment]::SetEnvironmentVariable("INFLUX_BUCKET", "power_monitoring", "Machine")

# Create bridge service
& $nssmPath stop MQTT-Bridge 2>$null
& $nssmPath remove MQTT-Bridge confirm 2>$null

$pythonExe = (Get-Command python).Source
& $nssmPath install MQTT-Bridge $pythonExe "C:\PowerMonitoring\mqtt-to-influxdb-bridge.py"
& $nssmPath set MQTT-Bridge AppDirectory "C:\PowerMonitoring"
& $nssmPath set MQTT-Bridge AppStdout "C:\PowerMonitoring\Logs\mqtt-bridge-stdout.log"
& $nssmPath set MQTT-Bridge AppStderr "C:\PowerMonitoring\Logs\mqtt-bridge-stderr.log"
& $nssmPath set MQTT-Bridge Start SERVICE_AUTO_START

Start-Service MQTT-Bridge
Write-Host "  MQTT Bridge service started" -ForegroundColor Green

# ============================================================================
# Summary
# ============================================================================
Write-Host "`n[10/10] Installation Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services Running:" -ForegroundColor Yellow
Write-Host "  [✓] Mosquitto MQTT Broker    - Port 1883" -ForegroundColor Green
Write-Host "  [✓] InfluxDB Database         - Port 8086" -ForegroundColor Green
Write-Host "  [✓] Grafana Dashboard         - Port 3000" -ForegroundColor Green
Write-Host "  [✓] MQTT-InfluxDB Bridge      - Running" -ForegroundColor Green
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  Grafana:  http://$ServerIP:3000" -ForegroundColor Cyan
Write-Host "            Username: admin, Password: admin" -ForegroundColor Gray
Write-Host ""
Write-Host "  InfluxDB: http://$ServerIP:8086" -ForegroundColor Cyan
Write-Host "            Username: admin, Password: DataImage2025!" -ForegroundColor Gray
Write-Host ""
Write-Host "Raspberry Pi Configuration:" -ForegroundColor Yellow
Write-Host "  Update current_sensing/config/user_config.toml on each Pi:" -ForegroundColor Gray
Write-Host "    [mqtt]" -ForegroundColor Gray
Write-Host "        broker = `"$ServerIP`"" -ForegroundColor Cyan
Write-Host "        port = 1883" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Configure Grafana datasource (see WINDOWS_NATIVE_GUIDE.md)" -ForegroundColor Gray
Write-Host "  2. Import dashboard" -ForegroundColor Gray
Write-Host "  3. Configure Raspberry Pis with server IP: $ServerIP" -ForegroundColor Gray
Write-Host "  4. Start current sensing on Pis" -ForegroundColor Gray
Write-Host ""
Write-Host "Logs Location: C:\PowerMonitoring\Logs\" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
