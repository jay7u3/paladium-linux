# Rapport — Paladium Games Launcher sous Ubuntu 24.04

## 1. Résumé

Paladium **fonctionne nativement sous Linux**, sans Wine. Le launcher Windows
(`.exe`) est inutile : le fichier **`Paladium Games Launcher.jar`** est un
*bootstrap* Java multiplateforme qui télécharge et lance la vraie application.

Deux choses étaient nécessaires :
1. Lancer le bootstrap `.jar` avec un Java système (Java 21 présent → OK).
2. **Corriger un bug TLS spécifique à Linux** qui empêchait la connexion au compte
   (« Impossible de vérifier votre compte Paladium Games »).

État final : launcher lancé, écran de connexion affiché, authentification réparée.

## 2. Architecture du launcher

| Élément | Détail |
|--------|--------|
| `Paladium Games Launcher.exe` | Wrapper Windows (PE32). **Inutile sous Linux.** |
| `Paladium Games Launcher.jar` | Bootstrap Java Swing (Eclipse jar-in-jar). Classe `fr.paladium.Bootstrap`. |
| Manifeste de distribution | `https://download.paladium-pvp.fr/games/bootstrap.json` |
| Runtime téléchargé | JRE **1.8.0_202** Linux x64 (`java-linux.zip`) — requis par JCEF |
| Application | `launcher-1.38.jar` (≈9 Mo, identique sur Win/Mac/Linux) |
| Interface | **JCEF** (Java Chromium Embedded Framework) — UI web dans Chromium |
| Install dir | `~/paladium-games/` (`runtime/`, `launcher.jar`, `keystore.jks`, `internal/`) |

Le bootstrap détecte l'OS (`DistributionOS.LINUX`), télécharge le bon runtime,
rend les binaires exécutables (`setExecutable`), puis exécute
`~/paladium-games/runtime/bin/java -jar ~/paladium-games/launcher.jar`.
Le manifeste contient bien une entrée **LINUX** → support Linux officiel côté serveur.

## 3. Blocage identifié (authentification)

Au clic sur *Connexion* puis login Microsoft, le launcher appelle son serveur
d'auth `https://launcher.cef.paladium.games/api/auth/start`. Échec :

```
PaladiumAuthenticator.authenticate → javax.net.ssl.SSLHandshakeException:
PKIX path building failed: unable to find valid certification path
→ [ERROR] Impossible de vérifier votre compte Paladium Games.
```

**Cause racine.** Le launcher (`CustomHttpClient` + `CertificateUtil`) n'utilise
PAS le magasin de confiance du système : il construit son propre `SSLContext` à
partir d'un magasin **`keystore.jks`** rempli de certificats *épinglés* (15 certs
embarqués dans `launcher.jar` sous `/certs/`).

La chaîne réelle du serveur d'auth est :

```
launcher.cef.paladium.games → GTS WE1 → GTS Root R4 → GlobalSign Root CA
```

Or les certs épinglés contiennent `gts-root-r1` mais **ni GTS Root R4, ni WE1**.
Aucun point d'ancrage ne correspond → échec.

Pourquoi seulement sous Linux ? Le launcher complète son magasin via
`findSystemCerts()`. Sous Windows/macOS, cela récupère la racine manquante depuis
le magasin du système d'exploitation. Sous Linux, `findSystemCerts()` ne trouve
rien d'utile, donc le jeu de certificats épinglés (incomplet) est seul utilisé.

## 4. Correctif appliqué

Ajout des deux certificats manquants (**GTS Root R4** et l'intermédiaire **WE1**)
dans le magasin `~/paladium-games/keystore.jks`
(mot de passe codé en dur dans le launcher : `01pG^{QV(*6j`).

PEM sauvegardés dans `certs-fix/`. Le script `launch-paladium.sh` les ré-injecte
automatiquement à chaque lancement (idempotent), pour survivre à une éventuelle
régénération du magasin.

## 5. Résultats (vérifiés)

Test TLS avec le **JRE 8 du launcher** et le magasin `keystore.jks` corrigé
(réplique exacte de la logique `CustomHttpClient`) :

| Hôte | Avant | Après |
|------|-------|-------|
| `launcher.cef.paladium.games` (auth) | SSLHandshakeException | **HTTP 403 (handshake OK)** |
| `api.minecraftservices.com` | — | HTTP 401 (OK) |
| `sessionserver.mojang.com` | — | HTTP 403 (OK) |
| `dns.google` (DoH) | — | HTTP 200 (OK) |
| `cloudflare-dns.com` (DoH) | échec | échec (non bloquant : dns.google + DNS système prennent le relais) |

L'erreur 403/401 = la négociation TLS réussit (le serveur répond), donc le PKIX
est résolu. C'était exactement l'appel qui échouait.

Le launcher démarre, l'UI Chromium s'affiche, l'écran de connexion est présent.
La connexion complète (login Microsoft réel) nécessite les identifiants de
l'utilisateur, mais l'appel d'auth qui bloquait est désormais fonctionnel.

## 6. Procédure de reproduction

Prérequis : un JRE système (Ubuntu 24.04 : `sudo apt install default-jre`).

```bash
cd ~/Desktop/Paladium
./launch-paladium.sh
```

Premier lancement uniquement : `keystore.jks` est créé par le launcher ; le script
attend son apparition, injecte les certificats, puis redémarre le launcher une fois.
Les lancements suivants sont directs.

Correctif manuel équivalent (si besoin) :

```bash
KS=~/paladium-games/keystore.jks
keytool -importcert -noprompt -alias fix-gts-root-r4 -file certs-fix/gts-root-r4.pem -keystore "$KS" -storepass '01pG^{QV(*6j'
keytool -importcert -noprompt -alias fix-gts-we1     -file certs-fix/gts-we1.pem     -keystore "$KS" -storepass '01pG^{QV(*6j'
```

## 7. Anti-triche

Le **launcher** n'embarque aucun anti-triche kernel (pas d'EAC/BattlEye/Vanguard
dans les binaires). C'est un client Minecraft moddé : l'authentification passe par
Microsoft/Mojang puis par l'API Paladium. Rien n'empêche techniquement le
fonctionnement sous Linux au niveau du launcher.

## 8. Niveau de confiance

| Élément | Confiance |
|--------|-----------|
| Lancement natif Linux du launcher | **Élevée** — testé, UI affichée |
| Cause racine de l'erreur d'auth | **Élevée** — décompilation + reproduction |
| Correctif TLS | **Élevée** — l'appel qui échouait renvoie maintenant HTTP 403 |
| Connexion + lancement du jeu de bout en bout | **Moyenne** — non testé (nécessite identifiants Microsoft) |
