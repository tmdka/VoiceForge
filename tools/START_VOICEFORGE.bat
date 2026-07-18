@echo off
setlocal EnableExtensions
cd /d "%~dp0"

title VoiceForge
set "PY="

where python.exe >nul 2>nul
if not errorlevel 1 set "PY=python.exe"
if not defined PY (
  where py.exe >nul 2>nul
  if not errorlevel 1 set "PY=py.exe -3"
)

if not defined PY (
  echo.
  echo [ERROR] Python 3 was not found on this PC.
  echo Install Python 3.8 or newer and enable "Add python.exe to PATH".
  echo.
  pause
  exit /b 1
)

%PY% -c "import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)" >nul 2>nul
if errorlevel 1 (
  echo.
  echo [ERROR] VoiceForge requires Python 3.8 or newer.
  %PY% --version
  echo.
  pause
  exit /b 1
)

if not exist "server.py" (
  echo.
  echo [ERROR] server.py is missing from:
  echo         %CD%
  echo Run SETUP_FROM_ZIP.bat first.
  echo.
  pause
  exit /b 1
)

if not exist "web\index.html" (
  echo.
  echo [ERROR] web\index.html is missing.
  echo Run SETUP_FROM_ZIP.bat again.
  echo.
  pause
  exit /b 1
)

%PY% -m py_compile "server.py"
if errorlevel 1 (
  echo.
  echo [ERROR] server.py contains a Python syntax error.
  echo.
  pause
  exit /b 1
)

set "VOICEFORGE_URL=http://127.0.0.1:8765"
for /f "usebackq delims=" %%P in (`%PY% -c "import json,os; p='config.json'; c=json.load(open(p,encoding='utf-8')) if os.path.exists(p) else {}; print(c.get('port',8765))" 2^>nul`) do set "VOICEFORGE_PORT=%%P"
if not defined VOICEFORGE_PORT set "VOICEFORGE_PORT=8765"
set "VOICEFORGE_URL=http://127.0.0.1:%VOICEFORGE_PORT%"

rem Wait until the server is actually reachable before opening the browser.
start "VoiceForge browser helper" /min powershell.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -Command ^
  "$u='%VOICEFORGE_URL%/api/health'; for($i=0;$i -lt 80;$i++){try{Invoke-WebRequest -UseBasicParsing -TimeoutSec 1 $u ^| Out-Null; Start-Process '%VOICEFORGE_URL%'; exit 0}catch{Start-Sleep -Milliseconds 250}}"

echo.
echo Starting VoiceForge at %VOICEFORGE_URL%
echo Keep this window open while using the studio.
echo Press Ctrl+C to stop the server.
echo.

%PY% "server.py"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
  echo.
  echo [ERROR] VoiceForge stopped with exit code %RC%.
  echo Review the messages above, especially missing model paths or port conflicts.
  echo.
  pause
)

exit /b %RC%
