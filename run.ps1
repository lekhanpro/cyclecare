#!/usr/bin/env pwsh
# CycleCare — Quick run script
# Usage: .\run.ps1 [debug|release|test|analyze|build]

param([string]$Command = "debug")

$env:JAVA_HOME = "D:\tools\java17"
$env:PATH = "D:\tools\java17\bin;D:\tools\supabase-cli;C:\Users\lekhan hr\AppData\Local\Pub\Cache\bin;D:\flutter-sdk\flutter\bin;" + $env:PATH
$env:GRADLE_USER_HOME = "D:\gradle-home"
$env:ANDROID_HOME = "C:\Users\lekhan hr\AppData\Local\Android\Sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME

$flutter = "D:\flutter-sdk\flutter\bin\flutter.bat"

switch ($Command) {
    "debug"   { & $flutter run }
    "release" { & $flutter build apk --release --no-pub }
    "aab"     { & $flutter build appbundle --release --no-pub }
    "test"    { & $flutter test --no-pub }
    "analyze" { & $flutter analyze --no-fatal-infos --no-fatal-warnings }
    "build"   { & $flutter build apk --debug --no-pub }
    "clean"   { & $flutter clean; & $flutter pub get }
    default   { Write-Host "Usage: .\run.ps1 [debug|release|aab|test|analyze|build|clean]" }
}
