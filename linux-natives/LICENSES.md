# Licences des natives Linux

Ces bibliothèques natives **ne sont pas du code Paladium** : ce sont des
bibliothèques open-source standard, redistribuées ici conformément à leurs
licences. Elles sont fournies telles quelles (non modifiées), uniquement
renommées pour que le loader du jeu les trouve (`lwjgl` → `lwjgl_pala`).

| Fichier(s) | Projet | Licence | Source officielle |
|---|---|---|---|
| `liblwjgl_pala.so`, `liblwjgl_pala64.so` | LWJGL 2.x | BSD-3-Clause | https://github.com/LWJGL/lwjgl |
| `libjinput-linux.so`, `libjinput-linux64.so` | JInput | BSD-2-Clause | https://github.com/jinput/jinput |
| `libopenal.so`, `libopenal64.so` | OpenAL Soft | LGPL-2.1 | https://github.com/kcat/openal-soft |

## LWJGL — BSD-3-Clause

```
Copyright (c) 2002-2009 Lightweight Java Game Library Project
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
* Neither the name of 'Light Weight Java Game Library' nor the names of its
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED. IN NO EVENT SHALL THE
COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## JInput — BSD-2-Clause

```
Copyright (c) 2002-2008 The Jinput Project. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED.
```

## OpenAL Soft — LGPL-2.1

OpenAL Soft est distribué sous **GNU Lesser General Public License v2.1**.
Les fichiers `libopenal*.so` sont la bibliothèque partagée **non modifiée**.
Texte complet de la licence : https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt

La LGPL autorise la redistribution de la bibliothèque partagée non modifiée à
condition de conserver cette notice et de pouvoir y relier d'autres programmes.
