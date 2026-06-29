@echo off
title Morse Keyboard - Liberar Firewall
echo Verificando privilegios de administrador...
NET SESSION >nul 2>&1
if %errorLevel% == 0 (
    goto :admin
) else (
    echo Solicitando privilegios... Clique em "Sim" se aparecer a tela do Windows.
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

:admin
echo ====================================================
echo Liberando as portas 8765 e 8766 no Firewall...
echo ====================================================
netsh advfirewall firewall add rule name="Morse Keyboard Server" dir=in action=allow protocol=TCP localport=8765,8766 >nul 2>&1
echo.
echo Portas liberadas com sucesso! 
echo Agora o celular podera se conectar ao servidor.
echo.
echo Pode fechar esta janela e tentar novamente no celular.
pause
