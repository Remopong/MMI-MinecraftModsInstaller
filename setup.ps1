# Installe / met a jour le modpack du serveur. Lance via setup.bat.
# A chaque lancement :
#   - recupere la derniere version du pack sur GitHub (modpack.json, config, kubejs)
#   - installe NeoForge si besoin (Java est trouve ou telecharge automatiquement)
#   - telecharge uniquement les mods nouveaux ou modifies, supprime les anciens
#   - cree/actualise le profil "MMI" dans le launcher Minecraft (RAM reglee automatiquement)
# Le modpack est installe dans un dossier a part : ton .minecraft normal n'est pas touche.

param(
    [switch]$Local,                                   # utiliser les fichiers a cote du script au lieu de GitHub
    [string]$Repo   = 'Remopong/MMI-MinecraftModsInstaller',
    [string]$Branch = 'main'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest est tres lent avec la barre de progression
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Remove-TypeData System.Array -ErrorAction SilentlyContinue   # evite un bug JSON de PowerShell 5.1

$mcDir     = Join-Path $env:APPDATA '.minecraft'
$gameDir   = Join-Path $mcDir 'modpacks\MMI'
$profiles  = Join-Path $mcDir 'launcher_profiles.json'
$work      = Join-Path $env:TEMP 'mmi-setup'
$curl      = Join-Path $env:SystemRoot 'System32\curl.exe'

function Step($text) { Write-Host ""; Write-Host "== $text" -ForegroundColor Cyan }

function Download($url, $out) {
    if (Test-Path $curl) {
        & $curl -fsSL --retry 3 -o $out $url
        if ($LASTEXITCODE -ne 0) { throw "Echec du telechargement : $url" }
    } else {
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
    }
}

function Find-Java {
    $candidates = @(
        "$mcDir\runtime\java-runtime-delta\windows-x64\java-runtime-delta\bin\java.exe",
        "$env:LOCALAPPDATA\Packages\Microsoft.4297127D64EC6_8wekyb3d8bbwe\LocalCache\Local\runtime\java-runtime-delta\windows-x64\java-runtime-delta\bin\java.exe",
        "$work\jre\bin\java.exe"
    )
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }

    $sys = Get-Command java -ErrorAction SilentlyContinue
    if ($sys) {
        $ver = (& cmd /c "`"$($sys.Source)`" -version 2>&1") -join ' '
        if ($ver -match 'version "(\d+)' -and [int]$Matches[1] -ge 21) { return $sys.Source }
    }

    # Aucun Java 21 : on telecharge un Java portable (pas d'installation, pas de redemarrage)
    Write-Host "- Telechargement d'un Java 21 temporaire..."
    $zip = "$work\jre.zip"
    Download 'https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jre/hotspot/normal/eclipse' $zip
    $tmp = "$work\jre-extract"
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Expand-Archive $zip $tmp
    $inner = Get-ChildItem $tmp -Directory | Select-Object -First 1
    if (Test-Path "$work\jre") { Remove-Item "$work\jre" -Recurse -Force }
    Move-Item $inner.FullName "$work\jre"
    return "$work\jre\bin\java.exe"
}

try {
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "   Installation / mise a jour du modpack MMI" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green

    # 1. Launcher ----------------------------------------------------------
    Step "1. Verification du launcher Minecraft"
    if (-not (Test-Path $profiles)) {
        throw "Launcher Minecraft introuvable ($profiles). Installe le launcher officiel et lance-le une fois."
    }
    if (Get-Process -Name 'MinecraftLauncher', 'Minecraft' -ErrorAction SilentlyContinue) {
        throw "Ferme le launcher Minecraft avant de lancer setup.bat, puis relance-le."
    }
    New-Item -ItemType Directory -Force $work, $gameDir | Out-Null

    # 2. Recuperation du pack ------------------------------------------------
    Step "2. Recuperation de la derniere version du pack"
    $src = $PSScriptRoot
    if (-not $Local) {
        try {
            $zip = "$work\pack.zip"
            Download "https://codeload.github.com/$Repo/zip/refs/heads/$Branch" $zip
            $extract = "$work\pack"
            if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
            Expand-Archive $zip $extract
            $src = (Get-ChildItem $extract -Directory | Select-Object -First 1).FullName
            Write-Host "- Pack telecharge depuis GitHub ($Branch)."
        } catch {
            Write-Warning "GitHub inaccessible, utilisation des fichiers locaux. ($_)"
            $src = $PSScriptRoot
        }
    }
    $pack = Get-Content (Join-Path $src 'modpack.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $versionId = "neoforge-$($pack.neoforge)"
    Write-Host "- Minecraft $($pack.minecraft), NeoForge $($pack.neoforge), $($pack.mods.Count) mods (pack du $($pack.generated))"

    # 3. NeoForge ------------------------------------------------------------
    Step "3. NeoForge $($pack.neoforge)"
    if (Test-Path "$mcDir\versions\$versionId\$versionId.json") {
        Write-Host "- Deja installe."
    } else {
        $java = Find-Java
        Write-Host "- Java : $java"
        $installer = "$work\neoforge-$($pack.neoforge)-installer.jar"
        Download "https://maven.neoforged.net/releases/net/neoforged/neoforge/$($pack.neoforge)/neoforge-$($pack.neoforge)-installer.jar" $installer
        Write-Host "- Installation (peut prendre une minute)..."
        Push-Location $work
        & $java -jar $installer --installClient $mcDir | Out-Null
        $code = $LASTEXITCODE
        Pop-Location
        if ($code -ne 0) { throw "L'installation de NeoForge a echoue (code $code)." }
        Write-Host "- NeoForge installe."
    }

    # 4. Mods ----------------------------------------------------------------
    Step "4. Mods"
    $modsDir = Join-Path $gameDir 'mods'
    New-Item -ItemType Directory -Force $modsDir | Out-Null
    $stateFile = Join-Path $modsDir '.mmi-installed.txt'
    $wanted = @($pack.mods | ForEach-Object { $_.file })

    # Supprime uniquement les mods que CE script avait installes et qui ne sont plus dans le pack.
    # Les mods ajoutes a la main (shaders, minimap...) sont conserves.
    if (Test-Path $stateFile) {
        foreach ($old in Get-Content $stateFile) {
            if ($old -and $wanted -notcontains $old -and (Test-Path -LiteralPath "$modsDir\$old")) {
                Remove-Item -LiteralPath "$modsDir\$old" -Force
                Write-Host "- Supprime : $old" -ForegroundColor DarkYellow
            }
        }
    }

    $i = 0; $downloaded = 0
    foreach ($m in $pack.mods) {
        $i++
        $target = Join-Path $modsDir $m.file
        if ((Test-Path -LiteralPath $target) -and (Get-Item -LiteralPath $target).Length -eq $m.size) { continue }
        Write-Host ("- [{0}/{1}] {2}" -f $i, $pack.mods.Count, $m.file)
        $part = "$target.part"
        Download $m.url $part
        if ($m.sha1 -and (Get-FileHash -LiteralPath $part -Algorithm SHA1).Hash -ne $m.sha1.ToUpper()) {
            Remove-Item -LiteralPath $part -Force
            throw "Fichier corrompu : $($m.file). Relance setup.bat."
        }
        Move-Item -LiteralPath $part $target -Force
        $downloaded++
    }
    [IO.File]::WriteAllLines($stateFile, [string[]]$wanted)
    Write-Host "- $downloaded mod(s) telecharge(s), $($pack.mods.Count - $downloaded) deja a jour."

    # 5. Config + KubeJS -----------------------------------------------------
    Step "5. Configs et KubeJS"
    $cfgSrc = Join-Path $src 'config'
    $cfgDst = Join-Path $gameDir 'config'
    if (Test-Path $cfgSrc) {
        foreach ($f in Get-ChildItem $cfgSrc -Recurse -File) {
            $rel = $f.FullName.Substring($cfgSrc.Length + 1)
            $dst = Join-Path $cfgDst $rel
            # Les configs "client" (affichage, HUD...) ne sont copiees qu'a la 1re installation
            # pour ne pas ecraser les reglages perso de chacun.
            if ($rel -match 'client' -and (Test-Path -LiteralPath $dst)) { continue }
            New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
            Copy-Item -LiteralPath $f.FullName $dst -Force
        }
        Write-Host "- Configs copiees."
    }
    $kjsSrc = Join-Path $src 'kubejs'
    if (Test-Path $kjsSrc) {
        robocopy $kjsSrc (Join-Path $gameDir 'kubejs') /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "Copie de kubejs echouee (code $LASTEXITCODE)." }
        Write-Host "- KubeJS synchronise."
    }

    # Reprend les options du jeu (touches, son, video) depuis le .minecraft normal a la 1re installation
    if (-not (Test-Path "$gameDir\options.txt") -and (Test-Path "$mcDir\options.txt")) {
        Copy-Item "$mcDir\options.txt" "$gameDir\options.txt"
    }

    # 6. Profil launcher -----------------------------------------------------
    Step "6. Profil du launcher"
    $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $alloc = if ($ramGB -ge 30) { 10 } elseif ($ramGB -ge 15) { 6 } elseif ($ramGB -ge 7) { 4 } else { 2 }
    $jvm = "-Xms${alloc}G -Xmx${alloc}G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 " +
           "-XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 " +
           "-XX:G1ReservePercent=20 -XX:MaxTenuringThreshold=1"
    if ($alloc -ge 4) { $jvm += " -XX:G1HeapRegionSize=8M" }

    Copy-Item $profiles "$profiles.mmi-backup" -Force
    $lp = Get-Content $profiles -Raw -Encoding UTF8 | ConvertFrom-Json
    $now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    $existing = $lp.profiles.PSObject.Properties['mmi']
    if ($existing) {
        # Profil deja la : on met juste a jour la version (on garde la RAM si le joueur l'a changee)
        $existing.Value.lastVersionId = $versionId
        $existing.Value.gameDir = $gameDir
        Write-Host "- Profil 'MMI' mis a jour."
    } else {
        $newProfile = [pscustomobject]@{
            name          = 'MMI - Serveur'
            type          = 'custom'
            icon          = 'Furnace'
            lastVersionId = $versionId
            gameDir       = $gameDir
            javaArgs      = $jvm
            created       = $now
            lastUsed      = $now
        }
        $lp.profiles | Add-Member -NotePropertyName 'mmi' -NotePropertyValue $newProfile
        Write-Host "- Profil 'MMI - Serveur' cree avec ${alloc} Go de RAM (PC : ${ramGB} Go)."
    }
    [IO.File]::WriteAllText($profiles, ($lp | ConvertTo-Json -Depth 32), (New-Object Text.UTF8Encoding $false))

    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "  Termine ! Ouvre le launcher Minecraft, choisis" -ForegroundColor Green
    Write-Host "  le profil 'MMI - Serveur' et clique sur JOUER." -ForegroundColor Green
    Write-Host "  Pour mettre a jour plus tard : relance setup.bat" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "[ERREUR] $_" -ForegroundColor Red
    exit 1
}
