Préparation :

Si vous n'avez pas de profil existant sur la version 1.21.1, vous pouvez le créer via le Launcher Minecraft dans l'onglet Configuration en haut.
Sélectionnez ensuite "Nouvelle Configuration", insérez un nom de profil, puis dans VERSION, sélectionnez "release 1.21.1".
Cliquez ensuite sur Installer en bas à droite.
Lancez ensuite le jeu en ayant sélectionné la version 1.21.1 dans le menu à gauche du bouton JOUER.
Une fois dans le menu principal du jeu, fermez-le.

Sur GITHUB :

Cliquez sur le bouton vert "Code" puis sur "Download ZIP".

Sur votre PC :

Extrayez absolument le dossier sur votre bureau (ne lancez pas le script directement depuis le ZIP).
Double-cliquez sur setup.bat.
Laissez le script faire : s'il installe Java, il vous demandera de fermer et de relancer setup.bat une deuxième fois.
Ouvrez le launcher Minecraft, vérifiez que le profil NeoForge est sélectionné.
Entrez dans le menu Configuration en haut, cliquez sur les "..." en face de la version "Neoforge 21.1.229" et cliquez sur Modifier.
Cliquez ensuite sur "PLUS D'OPTIONS" et effacez TOUS les "ARGUMENTS JVM".
Une fois le champ vide, copiez-collez ces arguments :

"-Xms10G -Xmx10G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:MaxTenuringThreshold=1"

/!\ ATTENTION /!\

-Xms10G -Xmx10G sont en rapport avec la RAM de votre ordinateur, remplacez le 10 dans les cas suivants :

Un ordinateur avec 32+ Go de RAM : valeur de 10

Un ordinateur avec 16 Go de RAM : valeur de 6

Un ordinateur avec 8 Go de RAM : valeur de 4

Un ordinateur avec 4 Go de RAM : valeur de 2


Si vous avez moins de 4 ou 8 Go de RAM, veuillez supprimer "-XX:G1HeapRegionSize=8M" de la liste des arguments.
Si votre jeu met beaucoup de temps à se lancer, supprimez -XX:+AlwaysPreTouch de la liste des arguments, si aucune différence n'est constatée ou si cela aggrave le problème, remettez-le.

Enregistrez tout et lancez le jeu.

GL HF !
