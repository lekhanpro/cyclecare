# Detached runner: execute a command, tee everything to a log, mark completion.
# Needed because the agent shell caps foreground commands at well under a second.
param(
  [Parameter(Mandatory = $true)][string]$Log,
  [Parameter(Mandatory = $true)][string]$Cmd
)
$ErrorActionPreference = 'Continue'
$env:Path = "D:\flutter\bin;" + $env:Path
$env:TEMP = "D:\tmp"; $env:TMP = "D:\tmp"
New-Item -ItemType Directory -Force -Path "D:\tmp" | Out-Null
Set-Location "D:\cyclecare"

"=== $(Get-Date -Format o) :: $Cmd ===" | Set-Content $Log
Invoke-Expression $Cmd *>> $Log
"=== EXIT=$LASTEXITCODE DONE ===" | Add-Content $Log
