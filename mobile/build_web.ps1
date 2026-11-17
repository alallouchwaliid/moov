# Recompile la version web (PWA iPhone) de MOOV et la place dans ../webapp,
# d'où Django la sert sur /app/.
# Usage (dans le dossier mobile) :  powershell -ExecutionPolicy Bypass -File build_web.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

flutter build web --release --base-href /app/
if (Test-Path ..\webapp) { Remove-Item ..\webapp -Recurse -Force }
Copy-Item build\web ..\webapp -Recurse
# Fichiers de débogage inutiles en production
Get-ChildItem ..\webapp -Recurse -Filter *.symbols | Remove-Item -Force
Remove-Item ..\webapp\.last_build_id -ErrorAction SilentlyContinue

Write-Host "`nVersion web prête dans webapp/. Ensuite : git add -A ; git commit ; git push" -ForegroundColor Green
Write-Host "puis sur PythonAnywhere : cd ~/moov && git pull, et bouton Reload (onglet Web)." -ForegroundColor Green
