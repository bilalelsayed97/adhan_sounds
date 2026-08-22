#!/usr/bin/env python3
"""Generates manifest.json (schema v2) from the android/ and ios/ part trees.

Titles, ids and types come from scripts/legacy_catalog.json. Every sound must
have the same number of sequentially numbered parts on both platforms; the
script fails loudly otherwise so the URL template can never drift from disk.
"""
import json, os, sys, datetime, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE_URL = "https://raw.githubusercontent.com/bilalelsayed97/adhan_sounds/main/"
TEMPLATES = {"android": "android/{fileName}/{fileName}_{n}.mp3",
             "ios": "ios/{fileName}/{fileName}_{n}.caf"}

def parts_on_disk(platform, name):
    ext = "mp3" if platform == "android" else "caf"
    d = os.path.join(ROOT, platform, name)
    if not os.path.isdir(d):
        return None
    pat = re.compile(rf"^{re.escape(name)}_(\d+)\.{ext}$")
    nums, total = [], 0
    for f in os.listdir(d):
        m = pat.match(f)
        if m:
            nums.append(int(m.group(1)))
            total += os.path.getsize(os.path.join(d, f))
    nums.sort()
    if nums != list(range(1, len(nums) + 1)):
        sys.exit(f"{platform}/{name}: non-sequential parts {nums}")
    return len(nums), total

def preview_path(name):
    for rel in (f"{name}.mp3", f"notifications/{name}.mp3"):
        if os.path.isfile(os.path.join(ROOT, rel)):
            return rel
    sys.exit(f"{name}: no full-length preview mp3 found")

with open(os.path.join(ROOT, "scripts", "legacy_catalog.json")) as fh:
    legacy = json.load(fh)["results"]

sounds, errors = [], []
for e in legacy:
    name = e["fileName"]
    a, i = parts_on_disk("android", name), parts_on_disk("ios", name)
    if a is None or i is None:
        errors.append(f"{name}: missing {'android' if a is None else 'ios'} parts"); continue
    if a[0] != i[0]:
        errors.append(f"{name}: android has {a[0]} parts, ios has {i[0]}"); continue
    prev = preview_path(name)
    sounds.append({
        "id": e["id"], "fileName": name,
        "titleAr": e["titleAr"], "titleEn": e["titleEn"],
        "type": e["type"], "parts": a[0], "rev": 1,
        "preview": {"url": prev, "bytes": os.path.getsize(os.path.join(ROOT, prev))},
        "android": {"bytes": a[1]}, "ios": {"bytes": i[1]},
    })
if errors:
    sys.exit("\n".join(errors))

manifest = {"schemaVersion": 2,
            "generatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
            "baseUrl": BASE_URL, "partTemplates": TEMPLATES, "sounds": sounds}
with open(os.path.join(ROOT, "manifest.json"), "w", encoding="utf-8") as fh:
    json.dump(manifest, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
print(f"wrote manifest.json with {len(sounds)} sounds")
