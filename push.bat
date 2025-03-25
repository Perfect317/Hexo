@echo off
setlocal enabledelayedexpansion

:: 确保脚本从当前脚本所在目录执行
cd /d %~dp0


set "bat_dir=%CD%\bat"

if not exist "%bat_dir%" (
    echo The "bat" folder does not exist in the current directory.
    exit /b
)

set "scripts=hexo_clean.bat hexo_update.bat push.bat"

for %%S in (%scripts%) do (
    set "script_path=%bat_dir%\%%S"
    if exist "!script_path!" (
        echo Running %%S...
        call "!script_path!"
    ) else (
        echo %%S not found in "bat" folder.
    )
)

endlocal

pause