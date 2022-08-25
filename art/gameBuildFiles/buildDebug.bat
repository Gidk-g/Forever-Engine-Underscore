@echo off
color 0a
title FNF: Forever Engine - Building Game (DEBUG MODE)
cd ..
cd ..
echo BUILDING...
lime build windows -debug
echo.
echo DONE.
pause
pwd
explorer.exe export\debug\windows\bin