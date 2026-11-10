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

Modifie ton instance CurseForge comme d'habitude (ajout/maj/suppression de mods, configs, KubeJS), puis
**double-clic sur `publish.bat`** : il synchronise le depot avec l'instance et publie sur GitHub (`main`)
seulement si quelque chose a change.

Pour verifier avant de publier : lance `export.ps1` (synchronise sans publier), regarde avec `git status`, puis `publish.bat`.

Instance par defaut : `MyDATAPACK` (sinon ajoute `-Instance "chemin"`).
Les .jar ne sont pas stockes dans le depot : `modpack.json` contient leurs liens de telechargement.

**Mods hors CurseForge** (Modrinth, fichier recu d'un ami...) : mets simplement le .jar dans le dossier `mods`
de l'instance. A la publication, le script cherche le fichier exact sur Modrinth ; s'il n'y est pas, le .jar
est copie dans `extra-mods/` et publie avec le pack (95 Mo max par fichier, limite de GitHub).
