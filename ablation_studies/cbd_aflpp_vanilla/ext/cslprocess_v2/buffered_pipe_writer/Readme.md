# Passage d'un fichier contenant plusieurs lignes au travers d'un tube (bash)

Salut à tous, je jette une bouteille à la mer, au cas où quelqu'un ait rencontré le même problème que moi.

J'ai un fichier qui a le contenu suivant (`commands`) :
```
USER secret
LIST
LIST
```

Je le passe au programme que je veux tester de la manière suivante :
```
./mon_programme < commands
```

Le problème est `./mon_programme` lit l'entrée standard de la manière suivante (Analysé avec `strace`) :
```
read(0, "USER secret\nLIST \nLIST\n", 128) = 23
```

Ce qu'il se passe concrètement, c'est que la commande `USER secret` produit un `exec()`. La fin (`LIST \nLIST\n`) n'est donc pas consommée par mon programme suite à l'appel à `exec()`.
Mon programme lit en boucle sur `stdin` tant que l'entrée n'est pas vide.

Ce que je voudrais donc, c'est un moyen de consommer `commands` tel que à chaque saut de ligne, le tube soit refermé, et que le programme continue jusqu'à ce qu'il arrive à un nouveau `read(0, ...)`.
J'aurais donc une suite d'appels systèmes ressemblant à ceci :
```
read(0, "USER secret\n", ...)
...
read(0, "LIST \n", ...)
...
read(0, "LIST\n", ...)
...
read(0, "", ...) = 0
```