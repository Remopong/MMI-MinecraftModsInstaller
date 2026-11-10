# A lancer sur le PC de l'hote (toi) : synchronise ce depot avec l'instance CurseForge.
# - Ecrit modpack.json (versions + liens de telechargement CurseForge des mods)
# - Copie config/ et kubejs/ depuis l'instance (copie miroir : ce qui a ete supprime dans l'instance l'est aussi ici)
# Les .jar ne sont pas stockes dans le depot : setup.ps1 les telecharge directement depuis CurseForge.
#
# Utilisation :
#   publish.bat                       -> synchronise + commit + push (un double-clic)
#   export.ps1                        -> synchronise seulement (pour verifier avant de publier)
#   export.ps1 -Push                  -> synchronise + commit + push si quelque chose a change
#   -Instance "C:\...\Instances\X"    -> si l'instance n'est pas MyDATAPACK

param(
    [string]$Instance = "$env:USERPROFILE\curseforge\minecraft\Instances\MyDATAPACK",
    [switch]$Push
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Remove-TypeData System.Array -ErrorAction SilentlyContinue   # evite un bug JSON de PowerShell 5.1
$repo = $PSScriptRoot
$manifestPath = Join-Path $Instance 'minecraftinstance.json'

function Log($text, [switch]$Warn) {
    if ($Warn) { Write-Warning $text } else { Write-Host $text }
}

function Git([string]$arguments) {
    # cmd /c fusionne stderr dans stdout : git ecrit sa progression sur stderr
    $out = cmd /c "git -C `"$repo`" $arguments 2>&1"
    if ($LASTEXITCODE -ne 0) { throw "git $arguments a echoue : $($out -join ' ')" }
    return $out
}

try {
    if (-not (Test-Path $manifestPath)) { throw "Instance introuvable : $manifestPath" }

    Log "Lecture de $manifestPath ..."
    $inst = Get-Content $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json

    # 1. Mods suivis par CurseForge (avec lien de telechargement direct)
    $mods = @()
    foreach ($addon in $inst.installedAddons) {
        $f = $addon.installedFile
        $file = $f.fileNameOnDisk
        if ($file -like '*.disabled') { continue }   # mod desactive dans CurseForge
        if (-not $f.downloadUrl) { continue }        # auteur qui bloque le telechargement hors CurseForge : traite plus bas
        $sha1 = ($f.hashes | Where-Object { $_.type -eq 1 } | Select-Object -First 1).value
        $mods += [ordered]@{
            name = $addon.name
            file = $file
            url  = $f.downloadUrl
            size = [int64]$f.fileLength
            sha1 = $sha1
        }
    }

    # Coherence entre la liste CurseForge et le dossier mods
    $modsDir = Join-Path $Instance 'mods'
    $known = @($mods | ForEach-Object { $_.file })
    $onDisk = @(Get-ChildItem $modsDir -Filter *.jar | ForEach-Object { $_.Name })
    $manual = @($onDisk | Where-Object { $known -notcontains $_ })
    $notYetOnDisk = @($known | Where-Object { $onDisk -notcontains $_ })

    if ($notYetOnDisk.Count -gt 0) {
        # CurseForge est probablement en train de telecharger / mettre a jour : on ne publie pas un etat a moitie fini
        $msg = "Mods listes par CurseForge mais absents du dossier mods : $($notYetOnDisk -join ', ')"
        if ($Push) { throw "$msg. CurseForge est peut-etre en cours de mise a jour, reessaie plus tard." }
        Log $msg -Warn
    }

    # 2. Mods hors CurseForge (Modrinth, ajoutes a la main...) : on cherche le fichier exact sur Modrinth
    #    grace a son empreinte SHA1. Introuvable -> le .jar est inclus dans le depot (dossier extra-mods).
    $extraDir = Join-Path $repo 'extra-mods'
    $bundled = @()
    if ($manual.Count -gt 0) {
        $byHash = @{}
        foreach ($name in $manual) {
            $item = Get-Item -LiteralPath (Join-Path $modsDir $name)
            $byHash[(Get-FileHash -LiteralPath $item.FullName -Algorithm SHA1).Hash.ToLower()] = $item
        }
        try {
            $body = @{ hashes = @($byHash.Keys); algorithm = 'sha1' } | ConvertTo-Json
            $resp = Invoke-RestMethod -Method Post -Uri 'https://api.modrinth.com/v2/version_files' -Body $body `
                -ContentType 'application/json' -UserAgent 'MMI-MinecraftModsInstaller'
        } catch {
            throw "Modrinth inaccessible, reessaie plus tard. ($_)"
        }
        foreach ($h in @($byHash.Keys)) {
            $item = $byHash[$h]
            $ver = $resp.PSObject.Properties[$h]
            $mf = if ($ver) { $ver.Value.files | Where-Object { $_.hashes.sha1 -eq $h } | Select-Object -First 1 }
            $entry = [ordered]@{ name = $item.BaseName; file = $item.Name }
            if ($mf) {
                $entry.url = $mf.url
                Log "Modrinth : $($item.Name)"
            } else {
                if ($item.Length -gt 95MB) {
                    throw "$($item.Name) n'est ni sur CurseForge ni sur Modrinth et fait plus de 95 Mo : GitHub ne peut pas le stocker."
                }
                $entry.path = "extra-mods/$($item.Name)"
                $bundled += $item
                Log "Inclus dans le depot (ni CurseForge ni Modrinth) : $($item.Name)" -Warn
            }
            $entry.size = [int64]$item.Length
            $entry.sha1 = $h
            $mods += $entry
        }
    }

    # extra-mods ne contient que les jars actuellement necessaires
    if ($bundled.Count -gt 0) { New-Item -ItemType Directory -Force $extraDir | Out-Null }
    if (Test-Path $extraDir) {
        $keep = @($bundled | ForEach-Object { $_.Name })
        Get-ChildItem $extraDir -File | Where-Object { $keep -notcontains $_.Name } | Remove-Item -Force
        foreach ($b in $bundled) {
            $dst = Join-Path $extraDir $b.Name
            if (-not (Test-Path -LiteralPath $dst) -or (Get-Item -LiteralPath $dst).Length -ne $b.Length) {
                Copy-Item -LiteralPath $b.FullName $dst -Force
            }
        }
        if ($bundled.Count -eq 0) { Remove-Item $extraDir -Force -Recurse }
    }

    # La date "generated" ne change que si la liste de mods / versions change (evite des commits inutiles)
    $packPath = Join-Path $repo 'modpack.json'
    $sortedMods = @($mods | Sort-Object { $_.file })
    $generated = (Get-Date).ToString('yyyy-MM-dd HH:mm')
    if (Test-Path $packPath) {
        $old = Get-Content $packPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $same = ($old.minecraft -eq $inst.gameVersion) -and ($old.neoforge -eq $inst.baseModLoader.forgeVersion) -and
                (($old.mods | ConvertTo-Json -Depth 5 -Compress) -eq ($sortedMods | ConvertTo-Json -Depth 5 -Compress))
        if ($same) { $generated = $old.generated }
    }
    $pack = [ordered]@{
        minecraft = $inst.gameVersion
        neoforge  = $inst.baseModLoader.forgeVersion
        generated = $generated
        mods      = $sortedMods
    }
    [IO.File]::WriteAllText($packPath, ($pack | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding $false))
    Log "modpack.json : $($mods.Count) mods, Minecraft $($pack.minecraft), NeoForge $($pack.neoforge)"

    foreach ($dir in 'config', 'kubejs') {
        $src = Join-Path $Instance $dir
        $dst = Join-Path $repo $dir
        if (-not (Test-Path $src)) { Log "Pas de dossier $dir dans l'instance" -Warn; continue }
        # jei\world = favoris / historique de recherche JEI propres a chaque joueur
        robocopy $src $dst /MIR /NFL /NDL /NJH /NJS /NP /XD (Join-Path $src 'jei\world') | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "robocopy a echoue pour $dir (code $LASTEXITCODE)" }
    }
    Log "config/ et kubejs/ synchronises."

    if (-not $Push) {
        Write-Host ""
        Write-Host "Termine. Pour publier : publish.bat (ou commit + push sur main)."
        exit 0
    }

    $branch = (Git 'rev-parse --abbrev-ref HEAD') -join ''
    if ($branch -ne 'main') { throw "Le depot est sur la branche '$branch', pas 'main'. Rien n'a ete publie." }

    Git 'add -A' | Out-Null
    $changes = @(Git 'diff --cached --name-only')
    if ($changes.Count -eq 0) { Log "Aucun changement, rien a publier."; exit 0 }

    Git "commit -q -m `"Sync instance $(Get-Date -Format 'yyyy-MM-dd HH:mm') ($($changes.Count) fichiers)`"" | Out-Null
    Git 'pull -q --rebase origin main' | Out-Null
    Git 'push -q origin main' | Out-Null
    Log "Publie sur GitHub : $($changes.Count) fichier(s) modifie(s). Tes amis n'ont plus qu'a relancer setup.bat."
}
catch {
    Log "ERREUR : $_" -Warn
    exit 1
}
