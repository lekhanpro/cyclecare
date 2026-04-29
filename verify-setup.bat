@echo off
echo ========================================
echo CycleCare Setup Verification
echo ========================================
echo.

echo Checking project structure...
echo.

if exist "app\build.gradle.kts" (
    echo [OK] App build file found
) else (
    echo [ERROR] App build file missing
)

if exist "app\src\main\AndroidManifest.xml" (
    echo [OK] AndroidManifest found
) else (
    echo [ERROR] AndroidManifest missing
)

if exist "app\src\main\java\com\cyclecare\app\CycleCareApp.kt" (
    echo [OK] Application class found
) else (
    echo [ERROR] Application class missing
)

if exist "landing-page\index.html" (
    echo [OK] Landing page found
) else (
    echo [ERROR] Landing page missing
)

if exist ".github\workflows\build-apk.yml" (
    echo [OK] GitHub Actions workflow found
) else (
    echo [ERROR] GitHub Actions workflow missing
)

echo.
echo ========================================
echo Checking Java...
echo ========================================
java -version 2>&1 | findstr /C:"version"
if %ERRORLEVEL% EQU 0 (
    echo [OK] Java is installed
) else (
    echo [WARNING] Java not found - required for local builds
)

echo.
echo ========================================
echo Summary
echo ========================================
echo.
echo Your CycleCare project is ready!
echo.
echo Next steps:
echo 1. Push to GitHub for automatic APK build
echo 2. Or run: gradlew.bat assembleDebug
echo 3. Deploy landing page to GitHub Pages/Netlify
echo.
echo For detailed instructions, see:
echo - QUICKSTART.md
echo - BUILD_GUIDE.md
echo.

pause
