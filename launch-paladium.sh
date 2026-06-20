#!/usr/bin/env bash
# Lance Paladium sous Linux en exécutant DIRECTEMENT le launcher patché.
#
# Pourquoi pas le bootstrap officiel ?
#   Le bootstrap exécute `runtime/bin/java -jar launcher.jar` (le launcher
#   OFFICIEL). Sous Linux celui-ci se comporte mal : getOS=linux bloque l'UI web,
#   getJava ne renvoie aucun Java (le jeu n'a pas de JRE Linux), isCompatible=false
#   n'autorise pas le téléchargement des libs/Forge -> « [Launcher] Crashed », et
#   surtout le jeu n'est PAS lançable. C'est exactement le symptôme observé quand on
#   passe par le bootstrap.
#
#   La solution qui fonctionne : `launcher-linux-patched.jar`, généré par
#   build-patched-launcher.py, qui :
#     - répond "windows" à l'UI (débloque l'installation/les boutons),
#     - débloque le curseur RAM,
#     - force isCompatible=true (télécharge TOUTES les libs/Forge),
#     - injecte game-java.sh comme Java du jeu (wrapper : natives Linux + RAM cap).
#   Ce script régénère ce jar puis le lance directement avec le runtime Java 8.
#
# CORRECTIF AUTHENTIFICATION (TLS) :
#   Le launcher utilise un magasin de confiance perso (keystore.jks) qui n'épingle
#   pas la chaîne du serveur d'auth (launcher.cef.paladium.games -> WE1 -> GTS Root
#   R4). Sous Linux le magasin système ne comble pas le manque -> « Impossible de
#   vérifier votre compte ». On ré-injecte les certificats manquants (idempotent).
set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
BOOTSTRAP_JAR="$ROOT/Launcher/Paladium Games Launcher.jar"
BUILD_PATCH="$ROOT/build-patched-launcher.py"
GAME_JAVA_SRC="$ROOT/game-java.sh"
CERTS_DIR="$ROOT/certs-fix"

INSTALL_DIR="$HOME/paladium-games"
LAUNCHER_JAR="$INSTALL_DIR/launcher.jar"                  # officiel (téléchargé par le bootstrap)
PATCHED_JAR="$INSTALL_DIR/launcher-linux-patched.jar"     # version qui fonctionne sous Linux
RUNTIME_JAVA="$INSTALL_DIR/runtime/bin/java"              # JRE 8 fourni par le bootstrap
GAME_JAVA_DST="$INSTALL_DIR/game-java.sh"
KEYSTORE="$INSTALL_DIR/keystore.jks"
KEYSTORE_PW='01pG^{QV(*6j'   # mot de passe codé en dur dans le launcher (CertificateUtil)

command -v java       >/dev/null 2>&1 || { echo "Java introuvable : sudo apt install default-jre" >&2; exit 1; }
command -v python3    >/dev/null 2>&1 || { echo "python3 introuvable : sudo apt install python3"  >&2; exit 1; }

KEYTOOL="$(command -v keytool || true)"
[ -x "$INSTALL_DIR/runtime/bin/keytool" ] && KEYTOOL="$INSTALL_DIR/runtime/bin/keytool"

inject_certs() {
    [ -f "$KEYSTORE" ] || return 0
    [ -n "$KEYTOOL" ] || return 0
    local alias file
    for file in "$CERTS_DIR"/*.pem; do
        [ -f "$file" ] || continue
        alias="fix-$(basename "$file" .pem)"
        if ! "$KEYTOOL" -list -keystore "$KEYSTORE" -storepass "$KEYSTORE_PW" -alias "$alias" >/dev/null 2>&1; then
            "$KEYTOOL" -importcert -noprompt -alias "$alias" -file "$file" \
                -keystore "$KEYSTORE" -storepass "$KEYSTORE_PW" >/dev/null 2>&1 \
                && echo "[fix-certs] ajouté : $alias"
        fi
    done
}

# ---------------------------------------------------------------------------
# 1. Installation initiale (runtime Java 8 + JCEF + launcher.jar) via le bootstrap,
#    UNIQUEMENT si ce n'est pas déjà installé. Le bootstrap télécharge tout puis
#    démarre le launcher officiel ; on l'arrête dès que les fichiers sont présents.
# ---------------------------------------------------------------------------
if [ ! -x "$RUNTIME_JAVA" ] || [ ! -f "$LAUNCHER_JAR" ]; then
    if [ ! -f "$BOOTSTRAP_JAR" ]; then
        echo "Bootstrap introuvable : $BOOTSTRAP_JAR" >&2
        echo "Place « Paladium Games Launcher.jar » (téléchargé depuis le site Paladium) dans le dossier Launcher/ — voir le README." >&2
        exit 1
    fi
    echo "[install] première installation : lancement du bootstrap pour télécharger le runtime + launcher…"
    java -jar "$BOOTSTRAP_JAR" &
    BOOT_PID=$!
    for _ in $(seq 1 120); do
        sleep 1
        [ -x "$RUNTIME_JAVA" ] && [ -f "$LAUNCHER_JAR" ] && break
    done
    sleep 3
    kill "$BOOT_PID" 2>/dev/null || true
    pkill -f "$INSTALL_DIR/runtime/bin/java"      2>/dev/null || true
    pkill -f "$INSTALL_DIR/internal/jcef_helper"  2>/dev/null || true
    sleep 2
    [ -x "$RUNTIME_JAVA" ] && [ -f "$LAUNCHER_JAR" ] || {
        echo "[install] échec : runtime ou launcher.jar manquant après le bootstrap." >&2; exit 1; }
    echo "[install] terminé."
fi

# ---------------------------------------------------------------------------
# 2. Déployer le wrapper Java du jeu (RAM cap + natives Linux + hors cgroup snap).
# ---------------------------------------------------------------------------
cp -f "$GAME_JAVA_SRC" "$GAME_JAVA_DST"
chmod +x "$GAME_JAVA_DST"

# ---------------------------------------------------------------------------
# 3. (Re)générer le launcher patché à partir du launcher.jar officiel courant
#    (suit automatiquement une éventuelle mise à jour du launcher).
# ---------------------------------------------------------------------------
echo "[patch] génération de launcher-linux-patched.jar…"
python3 "$BUILD_PATCH" "$LAUNCHER_JAR" "$PATCHED_JAR"

# ---------------------------------------------------------------------------
# 4. Correctif certificats (si le keystore existe déjà).
# ---------------------------------------------------------------------------
inject_certs

# ---------------------------------------------------------------------------
# 5. Lancer DIRECTEMENT le launcher patché avec le runtime Java 8.
#    Premier lancement : le keystore est créé par le launcher ; on attend qu'il
#    apparaisse, on injecte les certificats, puis on redémarre une fois.
# ---------------------------------------------------------------------------
run_launcher() { ( cd "$INSTALL_DIR" && exec "$RUNTIME_JAVA" -jar "$PATCHED_JAR" "$@" ); }

echo "[launch] démarrage du launcher patché Paladium…"
if [ ! -f "$KEYSTORE" ]; then
    run_launcher "$@" &
    LAUNCH_PID=$!
    for _ in $(seq 1 30); do
        sleep 1
        [ -f "$KEYSTORE" ] && break
    done
    sleep 2
    if inject_certs | grep -q 'ajouté'; then
        echo "[fix-certs] keystore corrigé au premier lancement — redémarrage du launcher."
        kill "$LAUNCH_PID" 2>/dev/null || true
        pkill -f "$INSTALL_DIR/runtime/bin/java"     2>/dev/null || true
        pkill -f "$INSTALL_DIR/internal/jcef_helper" 2>/dev/null || true
        sleep 2
        exec bash -c 'cd "$1" && exec "$2" -jar "$3"' _ "$INSTALL_DIR" "$RUNTIME_JAVA" "$PATCHED_JAR"
    fi
    wait "$LAUNCH_PID"
else
    exec bash -c 'cd "$1" && exec "$2" -jar "$3"' _ "$INSTALL_DIR" "$RUNTIME_JAVA" "$PATCHED_JAR"
fi
