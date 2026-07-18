@echo off
setlocal
cd /d "%~dp0"

set "ARCHIVE=VoiceForge-Kokoro-Studio.zip"

if not exist "%ARCHIVE%" (
  echo [VoiceForge] Missing %ARCHIVE%
  pause
  exit /b 1
)

where powershell >nul 2>nul
if errorlevel 1 (
  echo [VoiceForge] PowerShell is required to extract the source package.
  pause
  exit /b 1
)

echo [VoiceForge] Extracting source package...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; Expand-Archive -LiteralPath '%ARCHIVE%' -DestinationPath '.' -Force; $src=Join-Path (Get-Location) 'VoiceForge'; if (Test-Path $src) { Get-ChildItem -LiteralPath $src -Force | ForEach-Object { Move-Item -LiteralPath $_.FullName -Destination (Get-Location) -Force }; Remove-Item -LiteralPath $src -Force -Recurse }"

if errorlevel 1 (
  echo [VoiceForge] Extraction failed.
  pause
  exit /b 1
)

echo [VoiceForge] Source files are ready.
if exist "START_VOICEFORGE.bat" (
  echo Run START_VOICEFORGE.bat to launch the studio.
)
pause
