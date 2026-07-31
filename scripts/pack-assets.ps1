#Requires -Version 5.1
<#
.SYNOPSIS
    Empacota assets na máquina remota e baixa para Assets/

.EXAMPLE
    .\scripts\pack-assets.ps1
    .\scripts\pack-assets.ps1 -Host 192.168.86.248 -User rice -Password rice
#>
param(
    [string]$RemoteHost = "192.168.86.248",
    [string]$User = "rice",
    [string]$Password = "rice"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$AssetsDir = Join-Path $RepoRoot "Assets"
$PackScript = Join-Path $RepoRoot "scripts\pack-assets.sh"
$Sshpass = "C:\Users\Craig\AppData\Local\Microsoft\WinGet\Packages\xhcoding.sshpass-win32_Microsoft.Winget.Source_8wekyb3d8bbwe\sshpass.exe"

if (-not (Test-Path $Sshpass)) {
    Write-Error "sshpass não encontrado. Instale via: winget install xhcoding.sshpass-win32"
}

$env:SSHPASS = $Password
$packContent = [IO.File]::ReadAllText($PackScript).Replace("`r`n", "`n")
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($packContent))

Write-Host "→ Empacotando na máquina ${User}@${RemoteHost}..."
$vendorContent = [IO.File]::ReadAllText((Join-Path $RepoRoot "scripts\vendor-assets.sh")).Replace("`r`n", "`n")
$vendorB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($vendorContent))
$iconsInclude = Join-Path $RepoRoot "config\icons.include"
$iconsIncludeB64 = ""
if (Test-Path $iconsInclude) {
    $iconsIncludeContent = [IO.File]::ReadAllText($iconsInclude).Replace("`r`n", "`n")
    $iconsIncludeB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($iconsIncludeContent))
}
$remoteCmd = @"
echo '$b64' | base64 -d > /tmp/pack-assets.sh
echo '$vendorB64' | base64 -d > /tmp/vendor-assets.sh
mkdir -p /tmp/config
$(if ($iconsIncludeB64) { "echo '$iconsIncludeB64' | base64 -d > /tmp/config/icons.include" })
chmod +x /tmp/pack-assets.sh /tmp/vendor-assets.sh
rm -rf /tmp/gtk-assets && mkdir -p /tmp/gtk-assets
REPO_ROOT=/tmp ASSETS_DIR=/tmp/gtk-assets bash /tmp/pack-assets.sh
"@
& $Sshpass -p $Password ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL "${User}@${RemoteHost}" $remoteCmd

Write-Host "→ Baixando assets para $AssetsDir..."
New-Item -ItemType Directory -Force -Path $AssetsDir | Out-Null
$env:SSHPASS = $Password
foreach ($file in @("themes.zip", "icons.zip", "cursors.zip", "Manhattan.zip", "MacTahoe.tar.xz")) {
    Write-Host "  $file..."
    & $Sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL `
        "${User}@${RemoteHost}:/tmp/gtk-assets/$file" $AssetsDir 2>$null
    if (-not $?) {
        # vendor files may already exist locally
        if ($file -in @("Manhattan.zip", "MacTahoe.tar.xz") -and (Test-Path (Join-Path $AssetsDir $file))) {
            Write-Host "    (mantido local)"
        }
    }
}

Write-Host "Pronto."
Get-ChildItem $AssetsDir\*.zip | Format-Table Name, @{N='Size';E={"{0:N1} MB" -f ($_.Length/1MB)}}
