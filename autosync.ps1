# Active / desactive la synchro automatique de l'instance CurseForge vers GitHub.
# Cree une tache Windows qui lance "export.ps1 -Auto" a l'ouverture de session puis toutes les X minutes.
# La tache ne publie que si quelque chose a change, et attend que le jeu soit ferme.
# Journal : sync.log dans ce dossier.
#
#   autosync.ps1                 -> active (toutes les 30 min)
#   autosync.ps1 -Minutes 10     -> active avec un autre intervalle
#   autosync.ps1 -Off            -> desactive

param(
    [int]$Minutes = 30,
    [switch]$Off
)

$ErrorActionPreference = 'Stop'
$taskName = 'MMI - Synchro modpack'

if ($Off) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Synchro automatique desactivee."
    exit 0
}

$export = Join-Path $PSScriptRoot 'export.ps1'
# conhost --headless : pas de fenetre qui clignote a chaque synchro
$action = New-ScheduledTaskAction -Execute 'conhost.exe' `
    -Argument "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$export`" -Auto" `
    -WorkingDirectory $PSScriptRoot

$atLogon = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$repeat  = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes $Minutes) -RepetitionDuration (New-TimeSpan -Days 3650)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -StartWhenAvailable -RunOnlyIfNetworkAvailable -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 15)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $atLogon, $repeat -Settings $settings `
    -Description 'Publie automatiquement l''instance CurseForge MyDATAPACK sur GitHub (MMI-MinecraftModsInstaller).' `
    -Force | Out-Null

Write-Host "Synchro automatique activee : a l'ouverture de session et toutes les $Minutes minutes."
Write-Host "Journal : $(Join-Path $PSScriptRoot 'sync.log')"
Write-Host "Pour desactiver : powershell -ExecutionPolicy Bypass -File autosync.ps1 -Off"
