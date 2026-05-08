@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: LooteerV3 - Cloud Updater
::
:: Default mode (no args)  : background loop, syncs every 60s.
:: Oneshot mode             : Updater.bat oneshot
::                            single fetch then exit. Used by the
::                            "Reload Catalog" button in the V3 GUI
::                            so users don't have to leave a console
::                            window open all session.
::
:: Each successful sync writes data/last_sync.lua with the current
:: epoch so the V3 GUI header can show "synced Nm ago".
:: ============================================================

set BASE_URL=https://looter.d4data.live
set DATA_DIR=%~dp0data
set MODE=%~1

:: -- Generate or load profile key --
if not exist "%DATA_DIR%\profile.key" (
    echo Generating new profile key...
    powershell -NoProfile -Command "[System.Guid]::NewGuid().ToString()" > "%DATA_DIR%\profile.key"
)
set /p PROFILE_KEY=<"%DATA_DIR%\profile.key"
:: Trim whitespace/newlines
for /f "tokens=* delims= " %%a in ("!PROFILE_KEY!") do set PROFILE_KEY=%%a

:: -- Register profile with server (idempotent) --
curl -s -X POST "%BASE_URL%/api/config/register" ^
     -H "Content-Type: application/json" ^
     -d "{\"key\":\"!PROFILE_KEY!\",\"label\":\"%COMPUTERNAME%\"}" > nul

:: -- Single sync (both modes do at least one) --
call :sync_once

if /i "%MODE%"=="oneshot" (
    :: Lua-triggered reload - exit silently after the single sync.
    exit /b 0
)

:: -- Banner (loop mode only) --
echo.
echo === LooteerV3 Updater ===
echo Profile Key : !PROFILE_KEY!
echo Config URL  : %BASE_URL%/config/!PROFILE_KEY!
echo.
echo Open the Config URL in your browser to configure your loot settings.
echo Starting sync loop ^(Ctrl+C to stop^)...
echo.

:: -- Sync loop --
:loop
echo   Next sync in 60 seconds...
timeout /t 60 /nobreak > nul
echo [%TIME%] Syncing...
call :sync_once
goto loop

:: -- Sub: do a single curl pair + write last_sync.lua --
:sync_once
curl -s -f -o "%DATA_DIR%\items.lua" "%BASE_URL%/d4/items.lua"
set ITEMS_OK=%errorlevel%
if %ITEMS_OK% equ 0 (
    if /i not "%MODE%"=="oneshot" echo   [OK] items.lua
) else (
    if /i not "%MODE%"=="oneshot" echo   [FAIL] items.lua - server may be offline
)

curl -s -f -o "%DATA_DIR%\config.lua" "%BASE_URL%/api/config/!PROFILE_KEY!/config.lua"
if %errorlevel% equ 0 (
    if /i not "%MODE%"=="oneshot" echo   [OK] config.lua
) else (
    if /i not "%MODE%"=="oneshot" echo   [FAIL] config.lua
)

:: Stamp the sync time as a Lua module so gui.lua can require() it.
:: Only stamp on successful items.lua fetch; a failed fetch shouldn't
:: pretend the catalog is fresh.
if %ITEMS_OK% equ 0 (
    powershell -NoProfile -Command "$e = [int64]([datetime]::UtcNow - [datetime]'1970-01-01').TotalSeconds; Set-Content -Path '%DATA_DIR%\last_sync.lua' -Value (\"return \" + $e) -Encoding ASCII"
)
exit /b 0

endlocal
