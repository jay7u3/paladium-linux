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
| [game-java.sh](game-java.sh) | Wrapper Java du jeu : natives LWJGL Linux, plafond RAM (anti-OOM), **rendu sur le GPU NVIDIA dédié**. |
| [certs-fix/](certs-fix/) | Certificats CA publics manquants (GTS Root R4 / WE1) ré-injectés dans le keystore pour réparer l'authentification. |

## Prérequis

```bash
sudo apt install default-jre python3
```

Plus le launcher officiel **`Paladium Games Launcher.jar`** (téléchargé depuis le
site Paladium) placé dans `Launcher/`. Le reste (runtime Java 8, `launcher.jar`,
mods, natives) est récupéré automatiquement au premier lancement.

## Utilisation

```bash
./launch-paladium.sh
```

Premier lancement : installation + correctif certificats + redémarrage auto.
Lancements suivants : direct.

## Réglages utiles

**GPU** — le rendu est forcé sur la **NVIDIA GTX 1650** (offload PRIME) au lieu
de l'iGPU AMD. Pour revenir à l'iGPU :

```bash
PALADIUM_GPU=igpu ./launch-paladium.sh
```

**RAM** — le heap du jeu est plafonné pour éviter l'OOM killer (machine 7 Go).
Ajustable :

```bash
PALADIUM_MAX_RAM=3072 ./launch-paladium.sh   # plus de RAM si tu as fermé d'autres apps
PALADIUM_MAX_RAM=2048 ./launch-paladium.sh   # moins si ça lague encore
```
