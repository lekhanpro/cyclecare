$ErrorActionPreference = 'Stop'
$url = 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip'
$zip = 'D:\flutter-sdk\flutter.zip'
if (-not (Test-Path 'D:\flutter-sdk\flutter\bin\flutter.bat')) {
    Write-Host "Downloading Flutter SDK..."
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    Write-Host "Extracting..."
    Expand-Archive -Path $zip -DestinationPath 'D:\flutter-sdk' -Force
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Write-Host "Install complete"
} else {
    Write-Host "Flutter already installed"
}
& 'D:\flutter-sdk\flutter\bin\flutter.bat' --version
