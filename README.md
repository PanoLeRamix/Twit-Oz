# Projet Twit-Oz – Groupe T
L'objectif de ce programme est de prédire, lors de l'écriture d'un texte, le mot suivant, à-partir des mots précédents, moyennant l'analyse d'une base de données de fichiers texte.
En l'occurrence, la base de données sont 208 fichiers contenant chacun jusqu'à 100 tweets de Donald Trump.

## Installation

* Tout d'abord, assurez-vous de disposer de tous les fichiers du projet (voir plus bas) dans un seul dossier, sur votre ordinateur.
* Une fois que cela est fait, ouvrez votre shell et positionnez-vous dans ce
dossier.
```bash
cd repositorypath
```

* Vous pouvez maintenant compiler le programme en inscrivant cette
commande dans le shell.
```bash
make 
```

## Utilisation
* Lancez le programme en écrivant ceci.
```bash
ozengine main.oza
```

* Patientez un instant. (sur un ordinateur performant, le chargement devrait durer tout au plus quelques secondes)

* Lorsque le texte affiché sur la fenêtre s'étant ouverte vous indique que le chargement est terminé, effacez ce même texte et écrivez le vôtre. 

* Finalement, appuyez sur le bouton "Predict", ou utilisez le raccourci "Ctrl.+S", et l'application vous prédira le mot le plus susceptible de suivre les deux derniers mots que vous avez écrits !

## Les différents fichiers:
* Makefile permet de compiler le programme.
 
* main.oz contient le code du programme : les quelques fonctions principales et toutes les fonctions annexes.

* tweets est un dossier qui contient tous les fichiers texte (à savoir 208) de la base de données.

* README.md donne des explications sur la globalité du projet et indique le contenu des différents fichiers (ce fichier-ci).

## Contributions
Anton Lamotte - Aurélien Larue

