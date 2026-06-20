# Mission : Faire fonctionner Paladium Launcher sur Ubuntu 24.04.4 LTS

Tu es un expert Linux, Java, Wine, reverse engineering léger et compatibilité applicative.

## Contexte

Je souhaite jouer à Paladium sur la configuration suivante :

```text
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=24.04
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="Ubuntu 24.04.4 LTS"

PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
UBUNTU_CODENAME=noble
```

Le dossier `launcher/` contient :

* les exécutables Windows du launcher Paladium
* les exécutables macOS du launcher Paladium

Il n'existe pas d'exécutable Linux officiel.

## Objectif

Trouver une méthode fonctionnelle permettant de lancer Paladium sous Ubuntu 24.04.

Tu dois privilégier les solutions réellement testables plutôt que les hypothèses.

## Méthodologie obligatoire

### 1. Analyse du dossier launcher

Inspecter complètement :

* structure des fichiers
* exécutables présents
* bibliothèques embarquées
* présence d'Electron
* présence de Java
* présence de Node.js
* présence de Chromium
* présence de JNI
* présence de DLL
* présence de fichiers `.jar`
* présence de ressources natives

Utiliser notamment :

```bash
file
ldd
strings
readelf
objdump
tree
```

### 2. Identifier la technologie du launcher

Déterminer précisément si le launcher est :

* Electron
* Java Swing
* JavaFX
* Qt
* .NET
* C++
* autre

Fournir les preuves trouvées.

### 3. Recherche de solutions Linux natives

Avant d'utiliser Wine, vérifier si :

* le launcher est un wrapper Electron pouvant être lancé directement
* le launcher contient du Java multiplateforme
* les binaires macOS ou Windows embarquent des ressources compatibles Linux
* il est possible de reconstruire un lancement Linux à partir des fichiers existants

### 4. Étudier Wine

Si une solution native n'existe pas :

* installer Wine adapté à Ubuntu 24.04
* vérifier la compatibilité
* exécuter le launcher
* collecter les erreurs

Utiliser :

```bash
wine
wine64
WINEDEBUG
winetricks
```

### 5. Vérifier les protections anti-triche

Déterminer si Paladium utilise :

* Easy Anti Cheat
* BattlEye
* Vanguard
* système propriétaire
* pilote noyau
* service Windows obligatoire

Identifier précisément ce qui empêcherait un fonctionnement sous Linux.

### 6. Analyse réseau et Java

Si le launcher démarre :

* identifier la version Java utilisée
* identifier les arguments JVM
* déterminer comment le jeu est lancé
* vérifier si le client Minecraft lui-même peut fonctionner sous Linux

### 7. Recherche web

Effectuer des recherches récentes sur :

* Paladium Linux
* Paladium Ubuntu
* Paladium Wine
* Paladium Launcher Linux
* retours d'expérience d'utilisateurs Linux

Ne pas se limiter à une seule source.

### 8. Documentation

Créer un rapport détaillé contenant :

1. Résumé de l'analyse
2. Architecture du launcher
3. Blocages identifiés
4. Solutions testées
5. Résultats obtenus
6. Procédure complète pour reproduire
7. Niveau de confiance de chaque solution

## Contraintes

* Ne jamais conclure qu'une solution est impossible sans preuve.
* Toujours tester avant d'affirmer.
* Montrer les commandes exactes utilisées.
* Sauvegarder les logs pertinents.
* Privilégier une solution Linux native si elle existe.
* Utiliser Wine uniquement en dernier recours.

## Critère de réussite

Le travail est terminé uniquement lorsqu'une des situations suivantes est atteinte :

1. Paladium fonctionne sous Ubuntu.
2. Une cause technique précise et démontrée empêche son fonctionnement.
3. Une procédure reproductible permettant le lancement a été obtenue.

```
```
