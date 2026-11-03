#!/usr/bin/env pwsh
# CycleCare — Quick run script
# Usage: .\run.ps1 [debug|release|test|analyze|build]

param([string]$Command = "debug")

$env:JAVA_HOME = "D:\tools\java17"
$env:PATH = "D:\tools\java17\bin;D:\tools\supabase-cli;C:\Users\lekhan hr\AppData\Local\Pub\Cache\bin;D:\flutter\bin;" + $env:PATH
$env:GRADLE_USER_HOME = "D:\gradle-home"
$env:ANDROID_HOME = "D:\tools\android-sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME

# D:\flutter, not D:\flutter-sdk\flutter. The latter is an abandoned 3.24.5
# checkout whose Dart 3.5.4 cannot resolve this pubspec (sdk: >=3.10.0) and
# rejects language features the code already uses, so pointing here produced
# phantom compile errors in code that analyzes clean. android/local.properties
# agrees: flutter.sdk=D:\flutter.
$flutter = "D:\flutter\bin\flutter.bat"

# A wrong SDK path fails as a confusing analyzer error pages later, so say so here.
if (-not (Test-Path $flutter)) {
    Write-Error "Flutter not found at $flutter. Update run.ps1 and android/local.properties together."
    exit 1
}

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
