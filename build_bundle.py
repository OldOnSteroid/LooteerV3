"""
build_bundle.py — Build and upload the plugin zip to the looter server.

Creates:
  LooteerV3/          — loot bot plugin
  AlfredTheButler/    — town/butler plugin

Uploads to: /data/plugin_bundle.zip on 192.168.10.91
"""

import os
import io
import zipfile
import paramiko

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPTS_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOOTER_DIR    = os.path.join(SCRIPTS_DIR, "LooteerV3")
ALFRED_DIR    = os.path.join(SCRIPTS_DIR, "AlfredTheButler-main")

# Files to skip
ALFRED_SKIP   = {"data/export"}
LOOTER_SKIP_FILES = {"build_bundle.py"}

# ── Server ────────────────────────────────────────────────────────────────────
HOST   = "192.168.10.91"
PORT   = 22
USER   = "root"
PASS   = "2N8s6tx!"
REMOTE = "/data/plugin_bundle.zip"


def add_dir(zf: zipfile.ZipFile, local_dir: str, zip_prefix: str, skip_prefixes=()) -> int:
    """Recursively add all files from local_dir into zip_prefix/ inside the zip."""
    count = 0
    for root, dirs, files in os.walk(local_dir):
        rel_root = os.path.relpath(root, local_dir).replace(os.sep, "/")
        if rel_root == ".":
            rel_root = ""

        # Skip unwanted subdirs
        skip = False
        for sp in skip_prefixes:
            if rel_root == sp or rel_root.startswith(sp + "/"):
                skip = True
                break
        if skip:
            continue

        for fname in files:
            if not rel_root and fname in LOOTER_SKIP_FILES:
                continue
            local_path = os.path.join(root, fname)
            arc_path = f"{zip_prefix}/{rel_root}/{fname}" if rel_root else f"{zip_prefix}/{fname}"
            arc_path = arc_path.replace("//", "/")
            zf.write(local_path, arc_path)
            print(f"  + {arc_path}")
            count += 1
    return count


def build_zip() -> bytes:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        print("Adding LooteerV3...")
        n1 = add_dir(zf, LOOTER_DIR, "LooteerV3")

        print("Adding AlfredTheButler...")
        n2 = add_dir(zf, ALFRED_DIR, "AlfredTheButler", skip_prefixes=("data/export",))

        print(f"\nTotal: {n1 + n2} files")
    return buf.getvalue()


def upload(data: bytes) -> None:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(HOST, port=PORT, username=USER, password=PASS, timeout=10)
    sftp = ssh.open_sftp()

    # Upload to /tmp on host, then docker cp into the container's /data volume
    tmp_host = "/tmp/plugin_bundle.zip"
    with sftp.open(tmp_host, "wb") as fh:
        fh.write(data)
    sftp.close()

    _, stdout, stderr = ssh.exec_command(
        f"docker cp {tmp_host} looter-d4share:/data/plugin_bundle.zip && rm {tmp_host}"
    )
    out = stdout.read().decode()
    err = stderr.read().decode()
    if out.strip():
        print(out.strip())
    if err.strip():
        print("[stderr]", err.strip())

    ssh.close()
    print(f"Uploaded {len(data):,} bytes -> looter-d4share:/data/plugin_bundle.zip")


if __name__ == "__main__":
    print("Building plugin bundle...\n")
    data = build_zip()
    print(f"\nUploading ({len(data):,} bytes)...")
    upload(data)
    print("Done. Bundle available at /download/plugin.zip")
