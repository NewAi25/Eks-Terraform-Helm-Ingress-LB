$ErrorActionPreference = "Stop"

function Has-Cmd {
  param([string]$Name)
  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Refresh-PathForSession {
  $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $user    = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machine;$user"
}

function Ensure-Winget {
  if (-not (Has-Cmd "winget")) {
    throw "winget is not available. Install 'App Installer' / enable winget, then rerun."
  }
  winget --version | Out-Host
}

function Install-IfMissing {
  param(
    [string]$Cmd,
    [string]$WingetId,
    [scriptblock]$VersionCmd
  )

  if (Has-Cmd $Cmd) {
    Write-Host "✅ $Cmd already installed." -ForegroundColor Green
    & $VersionCmd | Out-Host
    return
  }

  Write-Host "Installing $Cmd via winget..." -ForegroundColor Yellow
  winget install --id $WingetId -e --source winget | Out-Host

  Refresh-PathForSession

  if (-not (Has-Cmd $Cmd)) {
    throw "❌ $Cmd installed but still not found in PATH. Close & reopen PowerShell, then rerun install-prereqs.ps1."
  }

  Write-Host "✅ $Cmd installed successfully." -ForegroundColor Green
  & $VersionCmd | Out-Host
}

Write-Host "=== Pre-req installer: AWS CLI v2 + kubectl + Terraform ==="

Ensure-Winget
Refresh-PathForSession

Install-IfMissing -Cmd "aws"      -WingetId "Amazon.AWSCLI"        -VersionCmd { aws --version }
Install-IfMissing -Cmd "kubectl"  -WingetId "Kubernetes.kubectl"   -VersionCmd { kubectl version --client }
Install-IfMissing -Cmd "terraform" -WingetId "Hashicorp.Terraform" -VersionCmd { terraform version }

Write-Host "=== All prerequisites are installed and verified ✅ ===" -ForegroundColor Green
Write-Host "Next run: .\deploy.ps1"