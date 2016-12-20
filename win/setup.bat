@echo off
@REM 管理者権限チェック
NET SESSION > NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Please run as administrator.
    pause
    EXIT /B 1
)
@REM Powershellを権限を緩めて実行
powershell -ExecutionPolicy Unrestricted %~dpn0.ps1
