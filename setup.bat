@echo off
title Installation du Modpack, Java 21 et NeoForge
echo ===================================================
echo   Installation du Modpack, Java 21 et NeoForge
echo ===================================================
echo.

:: Definition des chemins
set "MC_DIR=%appdata%\.minecraft"
set "MODS_DIR=%MC_DIR%\mods"
set "CONFIG_DIR=%MC_DIR%\config"
set "EMOTES_DIR=%MC_DIR%\emotes"
set "KUBEJS_DIR=%MC_DIR%\kubejs"
set "SCRIPT_DIR=%~dp0"

echo 1. Verification de l'installation de Minecraft...
if not exist "%MC_DIR%" (
    echo [Erreur] Le dossier Minecraft est introuvable. As-tu lance le jeu au moins une fois ?
    pause
    exit /b
)

echo.
echo 2. Verification de Java 21...
set "NEEDS_JAVA=0"
where java >nul 2>&1
if %ERRORLEVEL% neq 0 (
    set NEEDS_JAVA=1
) else (
    :: Verifie si la version de Java commence par "21"
    java -version 2>&1 | findstr /i "version \"21" >nul
    if %ERRORLEVEL% neq 0 (
        echo [Info] Une ancienne version de Java a ete detectee.
        set NEEDS_JAVA=1
    )
)

if "%NEEDS_JAVA%"=="1" (
    echo [Info] Java 21 est requis mais n'est pas installe ou pas a jour.
    echo - Telechargement de Java 21 (Eclipse Temurin JRE) en cours...
    curl -L -o "%TEMP%\java21_installer.msi" "https://api.adoptium.net/v3/installer/latest/21/ga/windows/x64/jre/hotspot/normal/eclipse"
    
    echo - Lancement de l'installation... (Une fenetre d'autorisation peut s'ouvrir)
    msiexec /i "%TEMP%\java21_installer.msi" /passive /norestart
    
    echo.
    echo ==========================================================
    echo [ACTION REQUISE] Java 21 vient d'etre installe !
    echo Pour que l'ordinateur le detecte, tu dois FERMER cette
    echo fenetre et DOUBLE-CLIQUER a nouveau sur "setup.bat".
    echo ==========================================================
    pause
    exit /b
) else (
    echo - Java 21 est bien installe et detecte !
)

echo.
echo 3. Installation de NeoForge...
if exist "%SCRIPT_DIR%neoforge-installer.jar" (
    echo - Installation de la version client de NeoForge...
    java -jar "%SCRIPT_DIR%neoforge-installer.jar" --installClient >nul
    if %ERRORLEVEL% equ 0 (
        echo - NeoForge installe avec succes dans le launcher !
    ) else (
        echo [Erreur] L'installation de NeoForge a echoue.
    )
) else (
    echo [Info] Fichier 'neoforge-installer.jar' introuvable. On passe cette etape.
)

echo.
echo 4. Nettoyage et preparation des dossiers...
if not exist "%MODS_DIR%" mkdir "%MODS_DIR%"
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"
if not exist "%EMOTES_DIR%" mkdir "%EMOTES_DIR%"
if not exist "%KUBEJS_DIR%" mkdir "%KUBEJS_DIR%"
del /Q "%MODS_DIR%\*.jar" 2>nul

echo.
echo 5. Copie des fichiers du serveur...
if exist "%SCRIPT_DIR%mods" (
    echo - Copie des mods en cours...
    xcopy "%SCRIPT_DIR%mods\*" "%MODS_DIR%\" /Y /S /E /Q >nul
)
if exist "%SCRIPT_DIR%config" (
    echo - Copie des configurations en cours...
    xcopy "%SCRIPT_DIR%config\*" "%CONFIG_DIR%\" /Y /S /E /Q >nul
)
if exist "%SCRIPT_DIR%emotes" (
    echo - Copie du dossier emotes en cours...
    xcopy "%SCRIPT_DIR%emotes\*" "%EMOTES_DIR%\" /Y /S /E /Q >nul
)
if exist "%SCRIPT_DIR%kubejs" (
    echo - Copie du dossier kubejs en cours...
    xcopy "%SCRIPT_DIR%kubejs\*" "%KUBEJS_DIR%\" /Y /S /E /Q >nul
)

echo.
echo ===================================================
echo   Installation terminee !
echo   Lance le launcher Minecraft, choisis le profil 
echo   NeoForge et rejoins le serveur.
echo ===================================================
echo.
pause
