# A lancer sur le PC de l'hote (toi) : synchronise ce depot avec l'instance CurseForge.
# - Ecrit modpack.json (versions + liens de telechargement CurseForge des mods)
# - Copie config/ et kubejs/ depuis l'instance (copie miroir : ce qui a ete supprime dans l'instance l'est aussi ici)
# Les .jar ne sont plus stockes dans le depot : setup.ps1 les telecharge directement depuis CurseForge.
#
# Utilisation : clic droit > "Executer avec PowerShell", ou :
#   powershell -ExecutionPolicy Bypass -File export.ps1 [-Instance "C:\...\Instances\MonInstance"]

param(
    [string]$Instance = "$env:USERPROFILE\curseforge\minecraft\Instances\MyDATAPACK"
)

$ErrorActionPreference = 'Stop'
Remove-TypeData System.Array -ErrorAction SilentlyContinue   # evite un bug JSON de PowerShell 5.1
$repo = $PSScriptRoot
$manifestPath = Join-Path $Instance 'minecraftinstance.json'

if (-not (Test-Path $manifestPath)) {
    throw "Instance introuvable : $manifestPath"
}

Write-Host "Lecture de $manifestPath ..."
$inst = Get-Content $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json

$mods = @()
$missing = @()
foreach ($addon in $inst.installedAddons) {
    $f = $addon.installedFile
    $file = $f.fileNameOnDisk
    if ($file -like '*.disabled') { continue }   # mod desactive dans CurseForge
    if (-not $f.downloadUrl) { $missing += $addon.name; continue }
    $sha1 = ($f.hashes | Where-Object { $_.type -eq 1 } | Select-Object -First 1).value
    $mods += [ordered]@{
        name = $addon.name
        file = $file
        url  = $f.downloadUrl
        size = [int64]$f.fileLength
        sha1 = $sha1
    }
}

# Jars presents dans le dossier mods mais inconnus de CurseForge (ajoutes a la main) : impossible a telecharger
$known = $mods | ForEach-Object { $_.file }
$manual = Get-ChildItem (Join-Path $Instance 'mods') -Filter *.jar | Where-Object { $known -notcontains $_.Name }
if ($manual -or $missing) {
    Write-Warning "Ces mods ne peuvent pas etre telecharges depuis CurseForge et ne seront PAS installes chez tes amis :"
    $manual | ForEach-Object { Write-Warning "  $($_.Name)" }
    $missing | ForEach-Object { Write-Warning "  $_" }
}

$pack = [ordered]@{
    minecraft = $inst.gameVersion
    neoforge  = $inst.baseModLoader.forgeVersion
    generated = (Get-Date).ToString('yyyy-MM-dd HH:mm')
    mods      = @($mods | Sort-Object { $_.file })
}
$json = $pack | ConvertTo-Json -Depth 5
[IO.File]::WriteAllText((Join-Path $repo 'modpack.json'), $json, (New-Object Text.UTF8Encoding $false))
Write-Host "modpack.json : $($mods.Count) mods, Minecraft $($pack.minecraft), NeoForge $($pack.neoforge)"

foreach ($dir in 'config', 'kubejs') {
    $src = Join-Path $Instance $dir
    $dst = Join-Path $repo $dir
    if (-not (Test-Path $src)) { Write-Warning "Pas de dossier $dir dans l'instance"; continue }
    Write-Host "Copie miroir de $dir ..."
    # jei\world = favoris / historique de recherche JEI propres a chaque joueur
    robocopy $src $dst /MIR /NFL /NDL /NJH /NJS /NP /XD (Join-Path $src 'jei\world') | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy a echoue pour $dir (code $LASTEXITCODE)" }
}

Write-Host ""
Write-Host "Termine. Verifie avec 'git status', puis commit + push sur la branche main."
Write-Host "Tes amis n'ont plus qu'a relancer setup.bat pour se mettre a jour."
