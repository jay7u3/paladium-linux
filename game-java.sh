#!/usr/bin/env bash
# Wrapper Java du jeu Paladium sous Linux.
#  - ré-injecte les natives LWJGL Linux (le launcher nettoie le dossier natives)
#  - remplace Apollon par une version corrigée (le bouton Boutique ne crashe plus)
#  - PLAFONNE la RAM du jeu pour éviter l'OOM killer (machine 7 Go) :
#      le launcher passe -Xmx4096M -Xms2048M, ce qui sature la RAM système et
#      fait tuer le jeu par le noyau (« Out of memory: Killed process java »)
#      quelques secondes après la connexion au serveur. On réécrit donc -Xmx/-Xms.
#  - sort le jeu du cgroup snap.code (terminal VSCode) via systemd-run, ce qui
#      remet oom_score_adj à 0 : le jeu n'est plus la cible prioritaire de l'OOM.
#  - lance le vrai Java 8
PALA="$HOME/Desktop/Paladium"

# RAM max du jeu en Mo (surchargable : PALADIUM_MAX_RAM=3072 ./launch-paladium.sh)
#
# 2560 plutôt que 3072 : sur cette machine 7 Go, un heap de 3072 donne ~3,7 Go
# résident. Comme il ne reste que ~3,9 Go dispo (swap déjà saturé), au moment du
# join le chargement du monde fait pager le tas sur le disque → le thread client
# gèle → io.netty.handler.timeout.ReadTimeoutException (déconnexion ~20 s après le
# login, puis impossible de se reconnecter). 2560 (~3,2 Go résident) laisse de la
# marge et tient en RAM. Repasse à 3072 (PALADIUM_MAX_RAM=3072) seulement après
# avoir fermé Discord/Firefox/onglets ; descends à 2048 si ça lague encore.
MAX_RAM="${PALADIUM_MAX_RAM:-2560}"
MIN_RAM="${PALADIUM_MIN_RAM:-512}"

for d in "$HOME/paladium/natives"/*/; do
    [ -d "$d" ] && cp -f "$PALA/linux-natives"/*.so "$d" 2>/dev/null
done
[ -f "$PALA/patches/Apollon-9.1.0.pala" ] && cp -f "$PALA/patches/Apollon-9.1.0.pala" "$HOME/paladium/mods/Apollon-9.1.0.pala" 2>/dev/null

# Réécrit les arguments mémoire imposés par le launcher.
args=()
for a in "$@"; do
    case "$a" in
        -Xmx*) args+=("-Xmx${MAX_RAM}M") ;;
        -Xms*) args+=("-Xms${MIN_RAM}M") ;;
        *)     args+=("$a") ;;
    esac
done

JAVA="$HOME/paladium-games/runtime/bin/java"
echo "[game-java] heap plafonné : -Xms${MIN_RAM}M -Xmx${MAX_RAM}M (RAM système : $(free -m | awk '/^Mem:/{print $2"Mo, libre "$7"Mo dispo"}'))" >&2

# --- GPU : rendre sur le GPU dédié NVIDIA (offload PRIME) plutôt que l'iGPU AMD ---
# Par défaut Linux rend sur l'iGPU AMD Vega, qui pioche sa VRAM dans la RAM système
# (déjà saturée sur cette machine 7 Go). La GTX 1650 a 4 Go de VRAM DÉDIÉE : y
# basculer le rendu = bien plus de FPS ET de la RAM système rendue au jeu (moins
# d'OOM). Désactivable avec PALADIUM_GPU=igpu ./launch-paladium.sh
if [ "${PALADIUM_GPU:-nvidia}" = "nvidia" ] && command -v nvidia-smi >/dev/null 2>&1; then
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only   # idem pour un éventuel backend Vulkan
    echo "[game-java] rendu GPU : NVIDIA GTX 1650 (offload PRIME) — VRAM dédiée, RAM préservée" >&2
fi

# Lance le jeu dans un scope systemd --user dédié → hors du cgroup snap.code,
# donc oom_score_adj=0 (le jeu n'est plus tué en priorité par le noyau).
if command -v systemd-run >/dev/null 2>&1 && systemd-run --user --scope true >/dev/null 2>&1; then
    exec systemd-run --user --scope --quiet -- "$JAVA" "${args[@]}"
fi
exec "$JAVA" "${args[@]}"
