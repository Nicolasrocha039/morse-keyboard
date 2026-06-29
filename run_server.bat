@echo off
title Morse Keyboard WebSocket Server
echo Iniciando o servidor Morse Keyboard...
echo.
echo Abra no navegador: http://localhost:8766
echo.
start "" http://localhost:8766
"%~dp0python\python.exe" -u "%~dp0websocket_server.py"
