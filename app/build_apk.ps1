# Swachh Railways - APK Build Script
# Workaround for AGP 8.x / Gradle 8.14 Windows file locking bug in verifyReleaseResources

Write-Host "=== Swachh Railways APK Builder ===" -ForegroundColor Cyan

# Kill lingering Java processes
Write-Host "Stopping Gradle daemons..." -ForegroundColor Yellow
Get-Process -Name "java" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Clear locked intermediates from previous run
Write-Host "Clearing build intermediates..." -ForegroundColor Yellow
Get-ChildItem -Path "build" -Directory -Recurse -Filter "verified_library_resources" -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Run Gradle directly, skipping the broken verifyReleaseResources tasks
Write-Host "Building release APK..." -ForegroundColor Green
Set-Location android
.\gradlew assembleRelease -x verifyReleaseResources --no-daemon
Set-Location ..

if ($LASTEXITCODE -eq 0) {
    $apk = "build\app\outputs\flutter-apk\app-release.apk"
    $size = [math]::Round((Get-Item $apk).Length / 1MB, 2)
    Write-Host ""
    Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "APK: $((Resolve-Path $apk).Path)" -ForegroundColor Cyan
    Write-Host "Size: ${size} MB" -ForegroundColor Cyan
} else {
    Write-Host "BUILD FAILED. Check output above." -ForegroundColor Red
}
