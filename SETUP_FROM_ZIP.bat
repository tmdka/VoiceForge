@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "ARCHIVE=%CD%\VoiceForge-Kokoro-Studio.zip"
set "STAGE=%TEMP%\VoiceForge-Setup-%RANDOM%-%RANDOM%"
set "SOURCE="

 echo.
echo ============================================
echo   VoiceForge setup
echo ============================================
echo.

if not exist "%ARCHIVE%" (
  echo [ERROR] Source archive not found:
  echo         %ARCHIVE%
  goto :fail
)

where powershell.exe >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Windows PowerShell is required for extraction.
  goto :fail
)

where python.exe >nul 2>nul
if not errorlevel 1 set "PY=python.exe"
if not defined PY (
  where py.exe >nul 2>nul
  if not errorlevel 1 set "PY=py.exe -3"
)
if not defined PY (
  echo [ERROR] Python 3 was not found.
  echo Install Python 3.8 or newer and enable "Add python.exe to PATH".
  goto :fail
)

for /f "tokens=2" %%V in ('%PY% -c "import sys; print(sys.version_info.major)" 2^>nul') do set "PY_MAJOR=%%V"
%PY% -c "import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)" >nul 2>nul
if errorlevel 1 (
  echo [ERROR] VoiceForge requires Python 3.8 or newer.
  %PY% --version
  goto :fail
)

if exist "%STAGE%" rmdir /s /q "%STAGE%"
mkdir "%STAGE%" >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Could not create temporary setup folder:
  echo         %STAGE%
  goto :fail
)

echo [1/4] Extracting source package...
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; Expand-Archive -LiteralPath $env:ARCHIVE -DestinationPath $env:STAGE -Force"
if errorlevel 1 (
  echo [ERROR] Archive extraction failed.
  goto :cleanup_fail
)

if exist "%STAGE%\VoiceForge\server.py" (
  set "SOURCE=%STAGE%\VoiceForge"
) else if exist "%STAGE%\server.py" (
  set "SOURCE=%STAGE%"
) else (
  echo [ERROR] The archive does not contain server.py in a supported layout.
  goto :cleanup_fail
)

if not exist "%SOURCE%\web\index.html" (
  echo [ERROR] The archive is incomplete: web\index.html is missing.
  goto :cleanup_fail
)
if not exist "%SOURCE%\START_VOICEFORGE.bat" (
  echo [ERROR] The archive is incomplete: START_VOICEFORGE.bat is missing.
  goto :cleanup_fail
)

echo [2/4] Installing application files...
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; $src=$env:SOURCE; $dst=(Get-Location).Path; Get-ChildItem -LiteralPath $src -Force | ForEach-Object { if ($_.Name -notin @('README.md')) { Copy-Item -LiteralPath $_.FullName -Destination $dst -Recurse -Force } }"
if errorlevel 1 (
  echo [ERROR] Could not copy the application files.
  goto :cleanup_fail
)

if exist "%CD%\tools\START_VOICEFORGE.bat" (
  copy /y "%CD%\tools\START_VOICEFORGE.bat" "%CD%\START_VOICEFORGE.bat" >nul
  if errorlevel 1 (
    echo [ERROR] Could not install the corrected launcher.
    goto :cleanup_fail
  )
)

echo [3/4] Validating Python source...
%PY% -m py_compile "%CD%\server.py"
if errorlevel 1 (
  echo [ERROR] server.py failed Python syntax validation.
  goto :cleanup_fail
)

if not exist "%CD%\server.py" goto :validation_fail
if not exist "%CD%\web\index.html" goto :validation_fail
if not exist "%CD%\START_VOICEFORGE.bat" goto :validation_fail

echo [4/4] Cleaning temporary files...
rmdir /s /q "%STAGE%" >nul 2>nul

echo.
echo [SUCCESS] VoiceForge is installed and validated.
echo Run START_VOICEFORGE.bat to launch the studio.
echo.
pause
exit /b 0

:validation_fail
echo [ERROR] Setup validation failed because one or more required files are missing.

:cleanup_fail
if exist "%STAGE%" rmdir /s /q "%STAGE%" >nul 2>nul

:fail
echo.
echo Setup did not complete. No successful installation was reported.
echo.
pause
exit /b 1
