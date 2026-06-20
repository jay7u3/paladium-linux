# Paladium sous Linux 🐧

Faire tourner **Paladium** (Minecraft moddé) nativement sous Linux — testé sur
Ubuntu 24.04. Aucun Wine : le launcher officiel est un bootstrap Java
multiplateforme, il suffit de le débloquer.

Ce dépôt ne contient **que les scripts et la documentation** du correctif. Les
binaires Paladium (launcher, mods, natives) sont propriétaires : ils ne sont pas
redistribués ici et sont téléchargés/installés à la première exécution.

> 📄 Détails techniques complets (analyse, cause racine, preuves) :
> [docs/RAPPORT.md](docs/RAPPORT.md). Brief d'origine : [docs/MISSION.md](docs/MISSION.md).

## Ce que font les scripts

| Fichier | Rôle |
|---------|------|
| [launch-paladium.sh](launch-paladium.sh) | Point d'entrée. Installe le runtime, régénère le launcher patché, corrige les certificats TLS, lance le jeu. |
| [build-patched-launcher.py](build-patched-launcher.py) | Patche le `launcher.jar` officiel (bytecode) pour débloquer l'install Linux, le curseur RAM et injecter le Java du jeu. |
| [game-java.sh](game-java.sh) | Wrapper Java du jeu : natives LWJGL Linux, plafond RAM (anti-OOM). |
| [certs-fix/](certs-fix/) | Certificats CA publics manquants (GTS Root R4 / WE1) ré-injectés dans le keystore pour réparer l'authentification. |

## Prérequis

```bash
sudo apt install default-jre python3
```

Plus le launcher officiel **`Paladium Games Launcher.jar`** (téléchargé depuis le
site Paladium) placé dans `Launcher/`. Le runtime Java 8, `launcher.jar`, les mods
et les natives Windows sont récupérés automatiquement au premier lancement.

Les natives Linux (`linux-natives/`) sont **incluses dans le dépôt** : ce sont
des bibliothèques open-source (LWJGL/JInput en BSD, OpenAL Soft en LGPL),
redistribuables — voir [linux-natives/LICENSES.md](linux-natives/LICENSES.md).

⚠️ **À fournir soi-même** (propriétaires Paladium, non redistribués) :

- `Launcher/Paladium Games Launcher.jar` — le bootstrap officiel (obligatoire).
- `patches/Apollon-9.1.0.pala` — version corrigée du mod Boutique (optionnel ;
  sans lui le jeu se lance, seul le bouton Boutique plante).

`launch-paladium.sh` doit être lancé **depuis la racine du dépôt** (là où se
trouvent ces dossiers) : le chemin est résolu automatiquement, peu importe le nom
du dossier cloné.

## Utilisation

```bash
./launch-paladium.sh
```

Premier lancement : installation + correctif certificats + redémarrage auto.
Lancements suivants : direct.

## Réglages utiles

**RAM** — le heap du jeu est plafonné pour éviter l'OOM killer sur les machines
à faible mémoire. Ajustable :

```bash
PALADIUM_MAX_RAM=3072 ./launch-paladium.sh   # plus de RAM si tu as fermé d'autres apps
PALADIUM_MAX_RAM=2048 ./launch-paladium.sh   # moins si ça lague encore
```
