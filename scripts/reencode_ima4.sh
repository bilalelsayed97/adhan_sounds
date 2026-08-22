#!/usr/bin/env bash
# Re-encodes every .caf under DIR (default: ios/) to mono IMA4 at <=22050 Hz so
# iOS notification sounds stay small. Files already mono+ima4 at <=22050 Hz are
# skipped; files sampled below 22050 Hz keep their rate (no upsampling).
# Asserts every output is <= 30 s (UNNotificationSound hard limit).
set -euo pipefail
DIR="${1:-$(dirname "$0")/../ios}"
TARGET_RATE=22050
before=0; after=0; converted=0; skipped=0
while IFS= read -r -d '' f; do
  fmt=$(afinfo "$f" | grep -m1 'Data format')
  ch=$(echo "$fmt" | sed -E 's/.*: *([0-9]+) ch.*/\1/')
  rate=$(echo "$fmt" | sed -E 's/.*, *([0-9]+) Hz.*/\1/')
  codec=$(echo "$fmt" | sed -E 's/.*Hz, *([a-z0-9]+).*/\1/')
  size=$(stat -f%z "$f"); before=$((before+size))
  if [[ $codec == ima4 && $ch == 1 && $rate -le $TARGET_RATE ]]; then
    skipped=$((skipped+1)); after=$((after+size))
  else
    out_rate=$TARGET_RATE; [[ $rate -lt $TARGET_RATE ]] && out_rate=$rate
    # Two steps: afconvert cannot downmix stereo IMA4 directly (error -66564),
    # so go through a mono LPCM intermediate first.
    tmp="${f%.caf}.tmp.caf"; pcm="${f%.caf}.pcm.caf"
    afconvert -f caff -d "LEI16@${out_rate}" -c 1 "$f" "$pcm"
    afconvert -f caff -d ima4 "$pcm" "$tmp"
    rm -f "$pcm"; mv "$tmp" "$f"
    after=$((after+$(stat -f%z "$f"))); converted=$((converted+1))
  fi
  dur=$(afinfo "$f" | grep -m1 'estimated duration' | sed -E 's/.*: *([0-9.]+).*/\1/')
  if (( $(echo "$dur > 30" | bc -l) )); then echo "ERROR: $f is ${dur}s (>30s)" >&2; exit 1; fi
done < <(find "$DIR" -name '*.caf' -print0)
echo "converted=$converted skipped=$skipped before=$((before/1024/1024))MB after=$((after/1024/1024))MB"
