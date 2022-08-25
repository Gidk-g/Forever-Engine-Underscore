@echo off
color 0a
title FNF: Forever Engine - Building Game (RELEASE MODE)
cd ..
cd ..
echo BUILDING...
lime build windows -release
echo.
echo DONE.
pause
pwd
explorer.exe export\release\windows\bin