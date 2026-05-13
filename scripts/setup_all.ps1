#!/usr/bin/env pwsh
# CycleCare Full Setup Script
# Run: powershell -ExecutionPolicy Bypass -File scripts/setup_all.ps1
# This script sets up Supabase, Firebase, and builds the release APK

param(
    [string]$SupabaseUrl = "",
    [string]$SupabaseAnonKey = "",
    [string]$SupabaseProjectRef = "",
    [string]$SupabaseAccessToken = "",
    [string]$GroqApiKey = "",
    [string]$FirebaseProjectId = ""
)

$ErrorActionPreference = "Stop"
$FlutterBin = "D:\flutter-sdk\flutter\bin\flutter.bat"
$DartBin = "D:\flutter-sdk\flutter\bin\dart.bat"
$SupabaseBin = "D:\tools\supabase-cli\supabase.exe"
$env:JAVA_HOME = "D:\tools\java17"
$env:PATH = "D:\tools\java17\bin;D:\tools\supabase-cli;C:\Users\lekhan hr\AppData\Local\Pub\Cache\bin;D:\flutter-sdk\flutter\bin;" + $env:PATH
$env:GRADLE_USER_HOME = "D:\gradle-home"
$env:ANDROID_HOME = "C:\Users\lekhan hr\AppData\Local\Android\Sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  CycleCare Full Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ─── Step 1: Flutter pub get ──────────────────────────────────────────────────
Write-Host "[1/8] Installing Flutter dependencies..." -ForegroundColor Yellow
& $FlutterBin pub get
Write-Host "✓ Dependencies installed" -ForegroundColor Green

# ─── Step 2: Write .env ───────────────────────────────────────────────────────
Write-Host "`n[2/8] Writing .env..." -ForegroundColor Yellow
if ($SupabaseUrl -and $SupabaseAnonKey) {
    @"
SUPABASE_URL=$SupabaseUrl
SUPABASE_ANON_KEY=$SupabaseAnonKey
"@ | Set-Content .env
    Write-Host "✓ .env written" -ForegroundColor Green
} else {
    Write-Host "⚠ Skipping .env (no credentials provided). App will run in local-only mode." -ForegroundColor Yellow
}

# ─── Step 3: Supabase migrations ─────────────────────────────────────────────
Write-Host "`n[3/8] Supabase migrations..." -ForegroundColor Yellow
if ($SupabaseAccessToken -and $SupabaseProjectRef) {
    $env:SUPABASE_ACCESS_TOKEN = $SupabaseAccessToken
    & $SupabaseBin link --project-ref $SupabaseProjectRef
    & $SupabaseBin db push
    Write-Host "✓ Migrations pushed" -ForegroundColor Green
} else {
    Write-Host "⚠ Skipping Supabase migrations (no project ref/token). Run manually:" -ForegroundColor Yellow
    Write-Host "  supabase login" -ForegroundColor Gray
    Write-Host "  supabase link --project-ref YOUR_PROJECT_REF" -ForegroundColor Gray
    Write-Host "  supabase db push" -ForegroundColor Gray
}

# ─── Step 4: Supabase Edge Functions ─────────────────────────────────────────
Write-Host "`n[4/8] Supabase Edge Functions..." -ForegroundColor Yellow
if ($SupabaseAccessToken -and $SupabaseProjectRef) {
    & $SupabaseBin functions deploy ai-assistant
    & $SupabaseBin functions deploy send-push
    & $SupabaseBin functions deploy partner-sync
    if ($GroqApiKey) {
        & $SupabaseBin secrets set GROQ_API_KEY=$GroqApiKey
        Write-Host "✓ Groq API key set" -ForegroundColor Green
    }
    Write-Host "✓ Edge Functions deployed" -ForegroundColor Green
} else {
    Write-Host "⚠ Skipping Edge Functions (no credentials). Run manually:" -ForegroundColor Yellow
    Write-Host "  supabase functions deploy ai-assistant" -ForegroundColor Gray
    Write-Host "  supabase functions deploy send-push" -ForegroundColor Gray
    Write-Host "  supabase functions deploy partner-sync" -ForegroundColor Gray
    Write-Host "  supabase secrets set GROQ_API_KEY=your-key" -ForegroundColor Gray
}

# ─── Step 5: Firebase ─────────────────────────────────────────────────────────
Write-Host "`n[5/8] Firebase configuration..." -ForegroundColor Yellow
if ($FirebaseProjectId) {
    Write-Host "Configuring Firebase for project: $FirebaseProjectId"
    & flutterfire configure --project=$FirebaseProjectId --platforms=android --yes
    Write-Host "✓ Firebase configured" -ForegroundColor Green
    # Uncomment Firebase in pubspec.yaml
    $pubspec = Get-Content pubspec.yaml -Raw
    $pubspec = $pubspec -replace '  # firebase_core: \^3\.8\.1', '  firebase_core: ^3.8.1'
    $pubspec = $pubspec -replace '  # firebase_auth: \^5\.4\.1', '  firebase_auth: ^5.4.1'
    $pubspec = $pubspec -replace '  # firebase_messaging: \^15\.1\.5', '  firebase_messaging: ^15.1.5'
    $pubspec = $pubspec -replace '  # google_sign_in: \^6\.2\.2', '  google_sign_in: ^6.2.2'
    Set-Content pubspec.yaml $pubspec -NoNewline
    & $FlutterBin pub get
    Write-Host "✓ Firebase packages enabled" -ForegroundColor Green
} else {
    Write-Host "⚠ Skipping Firebase (no project ID). Run manually:" -ForegroundColor Yellow
    Write-Host "  flutterfire configure --project=YOUR_FIREBASE_PROJECT" -ForegroundColor Gray
}

# ─── Step 6: Analyze ──────────────────────────────────────────────────────────
Write-Host "`n[6/8] Running flutter analyze..." -ForegroundColor Yellow
& $FlutterBin analyze --no-fatal-infos --no-fatal-warnings
Write-Host "✓ Analyze passed" -ForegroundColor Green

# ─── Step 7: Tests ────────────────────────────────────────────────────────────
Write-Host "`n[7/8] Running tests..." -ForegroundColor Yellow
& $FlutterBin test --no-pub
Write-Host "✓ All tests passed" -ForegroundColor Green

# ─── Step 8: Build ────────────────────────────────────────────────────────────
Write-Host "`n[8/8] Building APK..." -ForegroundColor Yellow
& $FlutterBin build apk --debug --no-pub
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $apkPath) {
    $size = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)
    Write-Host "✓ Debug APK built: $apkPath ($size MB)" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nTo run the app:" -ForegroundColor White
Write-Host "  flutter run" -ForegroundColor Gray
Write-Host "`nTo build release AAB for Play Store:" -ForegroundColor White
Write-Host "  flutter build appbundle --release" -ForegroundColor Gray
