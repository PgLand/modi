@echo off
chcp 65001 >nul
title BRVM Gestion - Serveur local
cd /d "%~dp0"

if not exist "icons\icon-192.png" (
    echo Generation des icones PWA...
    powershell -ExecutionPolicy Bypass -File "%~dp0generer-icones.ps1"
    echo.
)

echo.
echo  ========================================
echo   BRVM Gestion Unifiee - Serveur local
echo  ========================================
echo.
echo  Sur telephone (meme WiFi), ouvrez Chrome et allez sur :
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    echo    http://%%a:8080/portefeuille.html
    goto :ip_done
)
:ip_done
echo.
echo  Puis appuyez sur « Ajouter a l'ecran d'accueil » dans l'app.
echo.
echo  Appuyez sur Ctrl+C pour arreter le serveur.
echo  ========================================
echo.

start "" cmd /c "ping 127.0.0.1 -n 3 >nul && start http://localhost:8080/portefeuille.html"

where py >nul 2>&1
if %errorlevel%==0 (
    py -m http.server 8080
    goto :fin
)

where python >nul 2>&1
if %errorlevel%==0 (
    python -m http.server 8080
    goto :fin
)

echo ERREUR : Python n'est pas installe.
echo Installez Python depuis https://python.org puis relancez ce fichier.
pause

:fin
