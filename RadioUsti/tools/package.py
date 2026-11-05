#!/usr/bin/env python3
"""Build -> validate -> package RadioUsti.mcaddon (plus separate .mcpack files) into dist/."""
import os
import subprocess
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DIST = os.path.join(ROOT, "dist")
SKIP = {"README.txt", ".DS_Store"}


def zip_dir(zf, folder, prefix):
    for dp, dn, fn in os.walk(folder):
        dn.sort()
        for f in sorted(fn):
            if f in SKIP:
                continue
            full = os.path.join(dp, f)
            arc = os.path.join(prefix, os.path.relpath(full, folder)).replace(os.sep, "/")
            zi = zipfile.ZipInfo(arc, date_time=(2026, 1, 1, 0, 0, 0))
            zi.compress_type = zipfile.ZIP_DEFLATED
            with open(full, "rb") as fh:
                zf.writestr(zi, fh.read())


def main():
    if "--no-build" not in sys.argv:
        subprocess.run([sys.executable, os.path.join(HERE, "build.py")], check=True)
    r = subprocess.run([sys.executable, os.path.join(HERE, "validate.py")])
    if r.returncode != 0:
        sys.exit("validation failed - not packaging")
    os.makedirs(DIST, exist_ok=True)
    bp, rp = os.path.join(ROOT, "RadioUsti_BP"), os.path.join(ROOT, "RadioUsti_RP")
    out = os.path.join(DIST, "RadioUsti.mcaddon")
    with zipfile.ZipFile(out, "w") as zf:
        zip_dir(zf, bp, "RadioUsti_BP")
        zip_dir(zf, rp, "RadioUsti_RP")
    for folder, name in ((bp, "RadioUsti_BP.mcpack"), (rp, "RadioUsti_RP.mcpack")):
        with zipfile.ZipFile(os.path.join(DIST, name), "w") as zf:
            zip_dir(zf, folder, "")
    # integrity check
    for f in ("RadioUsti.mcaddon", "RadioUsti_BP.mcpack", "RadioUsti_RP.mcpack"):
        with zipfile.ZipFile(os.path.join(DIST, f)) as zf:
            bad = zf.testzip()
            if bad:
                sys.exit(f"corrupt entry {bad} in {f}")
            names = zf.namelist()
            if not any(n.endswith("manifest.json") for n in names):
                sys.exit(f"{f}: no manifest.json")
            print(f"{f}: {len(names)} files, {os.path.getsize(os.path.join(DIST, f)) // 1024} KiB, OK")


if __name__ == "__main__":
    main()
