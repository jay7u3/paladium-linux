#!/usr/bin/env python3
"""
Construit launcher-linux-patched.jar à partir du launcher.jar officiel en
appliquant les correctifs nécessaires pour faire tourner Paladium sous Linux.

Correctifs (patchs bytecode ciblés) :
  1. CommonRoute.handleGetOS       -> répond "windows" à l'UI web (débloque l'install).
  2. RamWindows.getFreeMemory      -> retourne la RAM totale (débloque le curseur RAM).
  3. DistributionModel.isCompatible -> true  (télécharge TOUS les fichiers, y compris
  4. DistributionFile.isCompatible  -> true   les bibliothèques/Forge absentes sous Linux).
  5. GameDistribution.getJava      -> chemin du Java 8 Linux fourni (le jeu n'a pas de
                                      Java sous Linux ; on injecte celui du runtime).
"""
import sys, os, zipfile, struct

JAVA_PATH = os.environ.get("PALA_GAME_JAVA",
                           os.path.expanduser("~/paladium-games/game-java.sh"))

# --- patchs simples (remplacement de séquence d'octets, longueur identique) ---
SIMPLE = {
    "fr/paladium/router/route/common/CommonRoute.class": [
        (bytes([0xB2,0x00,0x18,0xA6,0x00,0x08,0x12,0x19,0xA7,0x00,0x05,0x12,0x15]),
         bytes([0xB2,0x00,0x18,0xA6,0x00,0x08,0x12,0x15,0xA7,0x00,0x05,0x12,0x15])),
    ],
    "fr/paladium/core/utils/memory/RamWindows.class": [
        (bytes([0xB8,0x00,0x02,0xC0,0x00,0x03,0x4C,0x2B,0xB9,0x00,0x05,0x01,0x00,0xAD]),
         bytes([0xB8,0x00,0x02,0xC0,0x00,0x03,0x4C,0x2B,0xB9,0x00,0x04,0x01,0x00,0xAD])),
    ],
    # isCompatible: flip final `iconst_0; ireturn` -> `iconst_1; ireturn` (return true)
    "fr/paladium/core/distribution/dto/DistributionModel.class": [
        (bytes([0x84,0x04,0x01,0xA7,0xFF,0xE1,0x03,0xAC]),
         bytes([0x84,0x04,0x01,0xA7,0xFF,0xE1,0x04,0xAC])),
    ],
    "fr/paladium/core/distribution/dto/DistributionFile.class": [
        (bytes([0x84,0x04,0x01,0xA7,0xFF,0xE1,0x03,0xAC]),
         bytes([0x84,0x04,0x01,0xA7,0xFF,0xE1,0x04,0xAC])),
    ],
}

def apply_simple(name, data):
    data = bytearray(data)
    for old, new in SIMPLE[name]:
        c = data.count(old)
        if c == 1:
            i = data.find(old); data[i:i+len(old)] = new; print(f"[patch] OK  {name}")
        elif c == 0 and data.count(new) == 1:
            print(f"[patch] deja applique {name}")
        else:
            sys.exit(f"[patch] motif introuvable/ambigu dans {name} (n={c})")
    return bytes(data)

# --- patch getJava : chirurgie du pool de constantes ---
CP_SIZES = {3:4,4:4,5:8,6:8,7:2,8:2,9:4,10:4,11:4,12:4,15:3,16:2,17:4,18:4,19:2,20:2}

def parse_cp_end(d):
    count = struct.unpack(">H", d[8:10])[0]
    off = 10; i = 1
    while i < count:
        tag = d[off]
        if tag == 1:
            ln = struct.unpack(">H", d[off+1:off+3])[0]; off += 3 + ln
        else:
            off += 1 + CP_SIZES[tag]
        i += 2 if tag in (5, 6) else 1
    return count, off

def patch_getjava(data):
    d = bytearray(data)
    count, cp_end = parse_cp_end(d)
    utf8_idx = count
    str_idx  = count + 1
    pb = JAVA_PATH.encode("utf-8")
    new_entries = bytes([1]) + struct.pack(">H", len(pb)) + pb + bytes([8]) + struct.pack(">H", utf8_idx)
    d[8:10] = struct.pack(">H", count + 2)
    d = d[:cp_end] + new_entries + d[cp_end:]
    old = bytes([0x2A,0xB4,0x00,0x56,0xB0])           # aload_0; getfield #86; areturn
    new = bytes([0x00,0x13]) + struct.pack(">H", str_idx) + bytes([0xB0])  # nop; ldc_w str; areturn
    if d.count(old) != 1:
        sys.exit(f"[patch] getJava: motif introuvable/ambigu (n={d.count(old)})")
    i = d.find(old); d[i:i+5] = new
    print(f"[patch] OK  GameDistribution.getJava -> {JAVA_PATH}")
    return bytes(d)

def main():
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/paladium-games/launcher.jar")
    dst = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser("~/paladium-games/launcher-linux-patched.jar")
    if not os.path.exists(src):
        sys.exit(f"introuvable: {src}")
    GETJAVA = "fr/paladium/core/distribution/GameDistribution.class"
    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename in SIMPLE:
                data = apply_simple(item.filename, data)
            elif item.filename == GETJAVA:
                data = patch_getjava(data)
            zout.writestr(item, data)
    print(f"[ok] jar patche : {dst}")

if __name__ == "__main__":
    main()
