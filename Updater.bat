@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: LooteerV3 - Cloud Updater
:: Downloads item catalog + your personal loot config.
:: Runs as a background loop (60-second interval).
:: ============================================================

set BASE_URL=http://192.168.10.91:8002
set DATA_DIR=%~dp0data

:: ── Generate or load profile key ─────────────────────────────────────────────
if not exist "%DATA_DIR%\profile.key" (
    echo Generating new profile key...
    powershell -NoProfile -Command "[System.Guid]::NewGuid().ToString()" > "%DATA_DIR%\profile.key"
)
set /p PROFILE_KEY=<"%DATA_DIR%\profile.key"
:: Trim whitespace/newlines
for /f "tokens=* delims= " %%a in ("!PROFILE_KEY!") do set PROFILE_KEY=%%a

echo.
echo === LooteerV3 Updater ===
echo Profile Key : !PROFILE_KEY!
echo Config URL  : %BASE_URL%/config/!PROFILE_KEY!
echo.
echo Open the Config URL in your browser to configure your loot settings.
echo.

:: ── Register profile with server ─────────────────────────────────────────────
echo Registering with server...
curl -s -X POST "%BASE_URL%/api/config/register" ^
     -H "Content-Type: application/json" ^
     -d "{\"key\":\"!PROFILE_KEY!\",\"label\":\"%COMPUTERNAME%\"}" > nul
if %errorlevel% neq 0 (
    echo WARNING: Could not reach server. Will retry on next cycle.
)

echo Starting sync loop ^(Ctrl+C to stop^)...
echo.

:: ── Sync loop ────────────────────────────────────────────────────────────────
:loop
echo [%TIME%] Syncing...

curl -s -f -o "%DATA_DIR%\items.lua" "%BASE_URL%/d4/items.lua"
if %errorlevel% equ 0 (
    echo   [OK] items.lua
) else (
    echo   [FAIL] items.lua - server may be offline
)

curl -s -f -o "%DATA_DIR%\config.lua" "%BASE_URL%/api/config/!PROFILE_KEY!/config.lua"
if %errorlevel% equ 0 (
    echo   [OK] config.lua
) else (
    echo   [FAIL] config.lua
)

echo   Next sync in 60 seconds...
timeout /t 60 /nobreak > nul
goto loop

endlocal
