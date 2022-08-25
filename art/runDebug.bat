@echo off
color 0a
title FNF: Forever Engine - Running Game (DEBUG MODE)
cd ..
echo BUILDING...
lime build windows -debug
echo.
echo DONE.
pause
pwd
explorer.exe export\release\windows\bin