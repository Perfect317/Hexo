@echo off
setlocal enabledelayedexpansion

:: 确保脚本从当前脚本所在目录执行
cd /d %~dp0

set "bat_dir=%CD%\bat"

if not exist "%bat_dir%" (
    echo The "bat" folder does not exist in the current directory.
    exit /b
)

:: 设置要执行的 Python 脚本文件名
set "script=replace.py"

:: 设置完整路径
set "script_path=%bat_dir%\%script%"

:: 检查脚本文件是否存在，并使用 python3 执行
if exist "%script_path%" (
    echo Running %script% with Python...
    python3 "%script_path%"
) else (
    echo %script% not found in "bat" folder.
)

hexo clean

endlocal
pause
