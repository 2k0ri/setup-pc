@echo off
@REM �Ǘ��Ҍ����`�F�b�N
NET SESSION > NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Please run as administrator.
    pause
    EXIT /B 1
)
@REM Powershell���������ɂ߂Ď��s
powershell -ExecutionPolicy Unrestricted %~dpn0.ps1
