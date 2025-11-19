# PowerShell Script for Central Server Deployment
# Power Monitoring - Windows Server Setup

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Power Monitoring - Central Server Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Get server IP address
Write-Host "Detecting server IP address..." -ForegroundColor Yellow
$ServerIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*"} | Select-Object -First 1).IPAddress

if ($ServerIP) {
    Write-Host "📡 Server IP detected: $ServerIP" -ForegroundColor Green
} else {
    Write-Host "⚠️  Could not auto-detect IP. Please enter manually:" -ForegroundColor Yellow
    $ServerIP = Read-Host "Server IP Address"
}

Write-Host ""
Write-Host "⚠️  IMPORTANT: Configure your Raspberry Pis to connect to: $ServerIP`:1883" -ForegroundColor Yellow
Write-Host ""

# Stop any existing containers
Write-Host "Stopping any existing containers..." -ForegroundColor Yellow
docker-compose -f docker-compose-central.yml down 2>$null

# Pull/build images
Write-Host ""
Write-Host "Building Docker images (this may take a few minutes)..." -ForegroundColor Yellow
docker-compose -f docker-compose-central.yml build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Start services
Write-Host ""
Write-Host "Starting all services..." -ForegroundColor Yellow
docker-compose -f docker-compose-central.yml up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start services!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Wait for services to be ready
Write-Host ""
Write-Host "Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check status
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Service Status:" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
docker-compose -f docker-compose-central.yml ps

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "✅ Central Server Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your services at:" -ForegroundColor White
Write-Host "  📊 Grafana:  http://$ServerIP`:3000" -ForegroundColor Cyan
Write-Host "       Login: admin / admin" -ForegroundColor Gray
Write-Host ""
Write-Host "  🌐 Graph UI: http://$ServerIP`:80" -ForegroundColor Cyan
Write-Host ""
Write-Host "  📈 InfluxDB: http://$ServerIP`:8086" -ForegroundColor Cyan
Write-Host ""
Write-Host "Raspberry Pis should connect to:" -ForegroundColor White
Write-Host "  🔌 MQTT Broker: $ServerIP`:1883" -ForegroundColor Yellow
Write-Host ""
Write-Host "To view logs: docker-compose -f docker-compose-central.yml logs -f" -ForegroundColor Gray
Write-Host "To stop:      docker-compose -f docker-compose-central.yml down" -ForegroundColor Gray
Write-Host ""

# Open Grafana in default browser
$openBrowser = Read-Host "Open Grafana in browser now? (y/n)"
if ($openBrowser -eq 'y' -or $openBrowser -eq 'Y') {
    Start-Process "http://$ServerIP`:3000"
}

Read-Host "Press Enter to exit"
