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

# --- servers.dat (NBT non compresse) : lecture des serveurs et fusion sans rien supprimer ---
function Read-ServerList([string]$path) {
    $b = [IO.File]::ReadAllBytes($path)
    $script:nbtPos = 0
    function U8  { $v = $b[$script:nbtPos]; $script:nbtPos += 1; return [int]$v }
    function U16 { $v = ([int]$b[$script:nbtPos] -shl 8) -bor [int]$b[$script:nbtPos + 1]; $script:nbtPos += 2; return $v }
    function I32 { $v = ([int64]$b[$script:nbtPos] -shl 24) -bor ([int64]$b[$script:nbtPos + 1] -shl 16) -bor ([int64]$b[$script:nbtPos + 2] -shl 8) -bor [int64]$b[$script:nbtPos + 3]; $script:nbtPos += 4; return [int64]$v }
    function Str { $n = U16; $s = [Text.Encoding]::UTF8.GetString($b, $script:nbtPos, $n); $script:nbtPos += $n; return $s }
    function Skip([int]$t) {
        switch ($t) {
            1 { $script:nbtPos += 1 } 2 { $script:nbtPos += 2 } 3 { $script:nbtPos += 4 } 4 { $script:nbtPos += 8 }
            5 { $script:nbtPos += 4 } 6 { $script:nbtPos += 8 }
            7 { $n = I32; $script:nbtPos += $n }
            8 { $n = U16; $script:nbtPos += $n }
            9 { $et = U8; $n = I32; for ($k = 0; $k -lt $n; $k++) { Skip $et } }
            10 { while ($true) { $t2 = U8; if ($t2 -eq 0) { break }; $nl = U16; $script:nbtPos += $nl; Skip $t2 } }
            11 { $n = I32; $script:nbtPos += 4 * $n }
            12 { $n = I32; $script:nbtPos += 8 * $n }
            default { throw "tag NBT inconnu ($t)" }
        }
    }
    if ((U8) -ne 10) { throw "servers.dat invalide" }
    $null = Str
    $list = @()
    while ($script:nbtPos -lt $b.Length) {
        $t = U8; if ($t -eq 0) { break }
        $name = Str
        if ($t -eq 9 -and $name -eq 'servers') {
            $et = U8; $n = I32
            if ($n -gt 0 -and $et -ne 10) { throw "liste servers inattendue" }
            for ($k = 0; $k -lt $n; $k++) {
                $start = $script:nbtPos; $ip = ''
                while ($true) {
                    $t2 = U8; if ($t2 -eq 0) { break }
                    $nm = Str
                    if ($t2 -eq 8 -and $nm -eq 'ip') { $ip = Str } else { Skip $t2 }
                }
                $raw = New-Object byte[] ($script:nbtPos - $start)
                [Array]::Copy($b, $start, $raw, 0, $raw.Length)
                $list += ,([pscustomobject]@{ ip = $ip.Trim().ToLower(); raw = $raw })
            }
        } else { Skip $t }
    }
    return ,$list
}

function Write-ServerList([string]$path, $list) {
    $ms = New-Object IO.MemoryStream
    $ms.Write([byte[]](10, 0, 0, 9, 0, 7), 0, 6)
    $name = [Text.Encoding]::ASCII.GetBytes('servers'); $ms.Write($name, 0, $name.Length)
    $n = $list.Count
    $ms.Write([byte[]](10, (($n -shr 24) -band 255), (($n -shr 16) -band 255), (($n -shr 8) -band 255), ($n -band 255)), 0, 5)
    foreach ($e in $list) { $ms.Write($e.raw, 0, $e.raw.Length) }
    $ms.WriteByte(0)
    [IO.File]::WriteAllBytes($path, $ms.ToArray())
}

function Import-Servers([string]$from, [string]$to) {
    if (-not (Test-Path -LiteralPath $from)) { return 0 }
    if (-not (Test-Path -LiteralPath $to)) {
        Copy-Item -LiteralPath $from $to
        return (Read-ServerList $to).Count
    }
    $src = Read-ServerList $from
    $dst = Read-ServerList $to
    $known = @($dst | ForEach-Object { $_.ip })
    $new = @($src | Where-Object { $_.ip -and ($known -notcontains $_.ip) })
    if ($new.Count -eq 0) { return 0 }
    Copy-Item -LiteralPath $to "$to.mmi-backup" -Force
    Write-ServerList $to (@($dst) + $new)
    return $new.Count
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
    # Le launcher du Microsoft Store / app Xbox lit son propre fichier de profils
    $profileFiles = @($profiles, (Join-Path $mcDir 'launcher_profiles_microsoft_store.json')) | Where-Object { Test-Path $_ }
    if (-not $profileFiles) {
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

    # Auto-mise a jour : si GitHub a une version plus recente de ce script, on la prend et on la lance
    $newScript = Join-Path $src 'setup.ps1'
    if ($src -ne $PSScriptRoot -and (Test-Path $newScript) -and
        (Get-FileHash $newScript).Hash -ne (Get-FileHash $PSCommandPath).Hash) {
        Write-Host "- Nouvelle version de l'installateur, mise a jour..."
        foreach ($f in 'setup.ps1', 'setup.bat') {
            try { Copy-Item (Join-Path $src $f) (Join-Path $PSScriptRoot $f) -Force } catch { }
        }
        & powershell -NoProfile -ExecutionPolicy Bypass -File $newScript -Local
        exit $LASTEXITCODE
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
        if ($m.path) {
            # mod hors CurseForge/Modrinth, fourni directement dans le pack
            Copy-Item -LiteralPath (Join-Path $src $m.path) $part -Force
        } else {
            Download $m.url $part
        }
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

    # Serveurs enregistres : on ajoute au profil MMI ceux du .minecraft normal qui manquent.
    # Rien n'est jamais supprime ; en cas de probleme on n'y touche pas et l'installation continue.
    try {
        $added = Import-Servers "$mcDir\servers.dat" "$gameDir\servers.dat"
        if ($added -gt 0) { Write-Host "- $added serveur(s) enregistre(s) importe(s) depuis ton Minecraft normal." }
    } catch {
        Write-Warning "Import des serveurs enregistres ignore ($_)"
    }

    # 6. Profil launcher -----------------------------------------------------
    Step "6. Profil du launcher"
    $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $alloc = if ($ramGB -ge 30) { 10 } elseif ($ramGB -ge 15) { 6 } elseif ($ramGB -ge 7) { 4 } else { 2 }
    $jvm = "-Xms${alloc}G -Xmx${alloc}G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 " +
           "-XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 " +
           "-XX:G1ReservePercent=20 -XX:MaxTenuringThreshold=1"
    if ($alloc -ge 4) { $jvm += " -XX:G1HeapRegionSize=8M" }

    $now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    foreach ($profiles in $profileFiles) {
    Copy-Item $profiles "$profiles.mmi-backup" -Force
    $lp = Get-Content $profiles -Raw -Encoding UTF8 | ConvertFrom-Json
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
    }

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
