# MMI - Installateur du modpack

Installe et met a jour automatiquement les mods, configs et scripts KubeJS du serveur
(Minecraft 1.21.1 + NeoForge) dans le launcher Minecraft officiel.

## Pour les joueurs

**Avant de commencer :** installe le launcher Minecraft officiel et lance-le une fois (connecte a ton compte), puis **ferme-le**.

1. Sur GitHub, clique sur le bouton vert **Code** puis **Download ZIP**.
2. Extrais le ZIP (n'importe ou, par exemple sur le bureau). Ne lance pas le script depuis le ZIP.
3. Double-clique sur **setup.bat** et laisse faire.
4. Ouvre le launcher, choisis le profil **MMI - Serveur** et clique sur **JOUER**.

**Mettre a jour :** quand le serveur change de mods, ferme le launcher et relance simplement `setup.bat`.
Le script recupere tout seul la derniere version sur GitHub et ne telecharge que ce qui a change.

Ce que le script fait pour toi :
- installe la bonne version de NeoForge (Java est trouve ou telecharge automatiquement, aucun redemarrage) ;
- telecharge les mods directement depuis CurseForge et verifie qu'ils ne sont pas corrompus ;
- installe le modpack dans un dossier separe (`%appdata%\.minecraft\modpacks\MMI`) : ton Minecraft normal n'est pas touche ;
- cree le profil **MMI - Serveur** avec la RAM reglee selon ton PC (10 Go si 32 Go+, 6 Go si 16 Go, 4 Go si 8 Go, 2 Go sinon).

Tu peux ajouter tes propres mods client (minimap, shaders...) dans `%appdata%\.minecraft\modpacks\MMI\mods` :
le script ne les supprimera pas. Pour changer la RAM : launcher > Configurations > MMI - Serveur > Modifier > Plus d'options.

## Pour l'hote (mise a jour du pack)

1. Modifie ton instance CurseForge comme d'habitude (ajout/maj/suppression de mods, configs, KubeJS).
2. Lance `export.ps1` (clic droit > Executer avec PowerShell). Il met a jour `modpack.json`, `config/` et `kubejs/`
   a partir de l'instance (`-Instance "chemin"` si ce n'est pas `MyDATAPACK`).
3. Commit et push sur la branche **main**.

Les fichiers .jar ne sont pas stockes dans le depot : `modpack.json` contient leurs liens CurseForge.
