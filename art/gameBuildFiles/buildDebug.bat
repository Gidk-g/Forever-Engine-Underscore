@echo off
color 0a
title FNF: Forever Engine - Building Game (DEBUG MODE)
cd ..
cd ..
echo BUILDING...
echo IF IT CRASHES AFTER THE TITLESCREEN
echo TRY BINDING THE RESET KEYS TO ANYTHING ON A RELEASE BUILD
lime build windows -debug
echo.
echo DONE.
pause
pwd
explorer.exe export\debug\windows\bin