# adhan_sounds

Audio catalog for the Quran Kareem app. Served raw via
`https://raw.githubusercontent.com/bilalelsayed97/adhan_sounds/main/`.

## Layout

| Path | Purpose |
|---|---|
| `<name>.mp3`, `notifications/<name>.mp3` | Full-length previews streamed by the app |
| `android/<name>/<name>_N.mp3` | Split parts (≤29 s) downloaded on Android |
| `ios/<name>/<name>_N.caf` | Same parts as mono IMA4 CAF (≤22.05 kHz) for iOS notifications |
| `manifest.json` | Schema v2 catalog consumed by the app (generated, commit it) |

## Manifest v2

```json
{ "schemaVersion": 2, "baseUrl": "...", 
  "partTemplates": { "android": "android/{fileName}/{fileName}_{n}.mp3", "ios": "ios/{fileName}/{fileName}_{n}.caf" },
  "sounds": [ { "id", "fileName", "titleAr", "titleEn", "type", "parts", "rev",
                "preview": { "url", "bytes" }, "android": { "bytes" }, "ios": { "bytes" } } ] }
```

`fileName` is the canonical key. Bump `rev` when a sound's parts are re-encoded so
clients mark downloaded copies stale. Part URLs = `baseUrl + template` with
`{fileName}`/`{n}` substituted.

## Adding a sound

1. Drop the full mp3 at the root (adhan) or `notifications/` (short sounds).
2. Split into ≤29 s parts: `android/<name>/<name>_N.mp3` and `ios/<name>/<name>_N.caf`.
3. Add the entry (id, titles, type) to `scripts/legacy_catalog.json`.
4. `scripts/reencode_ima4.sh` then `scripts/build_manifest.py`; commit `manifest.json`.

`scripts/normalize_layout.sh` is the one-off migration that moved
`notifications/{android,ios}` into the unified trees.
