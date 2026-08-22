#!/usr/bin/env bash
# Normalises the repo so every split sound lives under
#   android/<name>/<name>_N.mp3   and   ios/<name>/<name>_N.caf
# Moves notifications/{android,ios}/* into those trees. Loose single-part files
# (notifications/android/<name>.mp3) become <name>_1.<ext>. Full-length preview
# files at the root and in notifications/*.mp3 are left untouched.
set -euo pipefail
cd "$(dirname "$0")/.."

for platform in android ios; do
  ext=mp3; [[ $platform == ios ]] && ext=caf
  src="notifications/$platform"
  [[ -d $src ]] || continue
  for entry in "$src"/*; do
    name=$(basename "$entry")
    if [[ -d $entry ]]; then
      mkdir -p "$platform/$name"
      git mv -k "$entry"/* "$platform/$name/" 2>/dev/null || mv "$entry"/* "$platform/$name/"
      rmdir "$entry"
    elif [[ $name == *.$ext ]]; then
      base="${name%.$ext}"
      mkdir -p "$platform/$base"
      git mv -k "$entry" "$platform/$base/${base}_1.$ext" 2>/dev/null || mv "$entry" "$platform/$base/${base}_1.$ext"
    else
      echo "skip unexpected $entry" >&2
    fi
  done
  rmdir "$src" 2>/dev/null || true
done
echo "done: $(find android -name '*.mp3' | wc -l) android parts, $(find ios -name '*.caf' | wc -l) ios parts"
