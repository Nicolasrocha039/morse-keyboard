$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Desinstalador do Driver Interception" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Requer privilégios de administrador
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host "Feche este terminal, abra o Powershell como Administrador e execute o script novamente." -ForegroundColor Yellow
    Pause
    exit
}

$installerPath = Join-Path $PSScriptRoot "Interception\Interception\command line installer\install-interception.exe"

if (Test-Path $installerPath) {
    Write-Host "Desinstalando o driver de Kernel..." -ForegroundColor Yellow
    Start-Process -FilePath $installerPath -ArgumentList "/uninstall" -Wait -NoNewWindow
    Write-Host ""
    Write-Host "Desinstalação concluída com sucesso!" -ForegroundColor Green
    Write-Host "O computador será reiniciado em 15 segundos..." -ForegroundColor Cyan
    Start-Sleep -Seconds 15
    Restart-Computer -Force
} else {
    Write-Host "Erro: O desinstalador não foi encontrado em: $installerPath" -ForegroundColor Red
    Pause
}
