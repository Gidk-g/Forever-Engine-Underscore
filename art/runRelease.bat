@echo off
color 0a
title FNF: Forever Engine - Running Game (RELEASE MODE)
cd ..
echo BUILDING...
lime build windows -release
echo.
echo DONE.
pause
pwd
explorer.exe export\release\windows\bin