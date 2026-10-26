#!/usr/bin/env python3
"""Run the checks available without Roblox Studio or creator credentials."""
from __future__ import annotations

from pathlib import Path
import argparse
import re
import struct
import subprocess
import sys
import wave
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
IMAGES = {
    "experience-icon.png": (512, 512),
    "thumbnail-find-rare-treasures.png": (1920, 1080),
    "thumbnail-restore-display-sell.png": (1920, 1080),
    "thumbnail-key-art.png": (1920, 1080),
}
AUDIO_KEYS = {"click", "reveal", "restore", "sale", "reward", "place", "auction", "error", "scrub", "polish", "shop", "town", "auction_music"}


def run(*command: str) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, check=True)


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError(f"not a valid PNG: {path}")
    return struct.unpack(">II", header[16:24])


def check_upload_pack() -> None:
    marketing = ROOT / "assets" / "marketing"
    for name, expected in IMAGES.items():
        path = marketing / name
        actual = png_size(path)
        assert actual == expected, f"{name}: expected {expected}, found {actual}"
        assert path.stat().st_size < 8 * 1024 * 1024, f"{name} exceeds 8 MiB"
        print(f"PASS image {name}: {actual[0]}x{actual[1]}, {path.stat().st_size / 1024:.0f} KiB")

    found = set()
    for path in sorted((ROOT / "assets" / "audio").glob("*.wav")):
        with wave.open(str(path), "rb") as sound:
            assert sound.getnchannels() == 1, f"{path.name} must be mono"
            assert sound.getsampwidth() == 2, f"{path.name} must be 16-bit PCM"
            assert sound.getframerate() == 22050, f"{path.name} must be 22050 Hz"
            duration = sound.getnframes() / sound.getframerate()
            assert 0 < duration < 60, f"{path.name} has invalid duration"
        found.add(path.stem)
        print(f"PASS audio {path.name}: {duration:.2f}s")
    assert found == AUDIO_KEYS, f"audio mismatch: missing={AUDIO_KEYS - found}, extra={found - AUDIO_KEYS}"


def unconfigured_assets() -> list[str]:
    source = (ROOT / "src" / "shared" / "AssetConfig.luau").read_text()
    audio_block = re.search(r"\bAudio\s*=\s*\{(.*?)\}", source, re.DOTALL)
    assert audio_block, "AssetConfig.Audio table is missing"
    values = {name: int(value) for name, value in re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(\d+)\b", audio_block.group(1))}
    assert set(values) == AUDIO_KEYS, f"AssetConfig audio mismatch: missing={AUDIO_KEYS - set(values)}, extra={set(values) - AUDIO_KEYS}"
    return sorted(name for name, value in values.items() if value == 0)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-uploaded-assets", action="store_true", help="fail while creator-owned Roblox asset IDs remain zero")
    args = parser.parse_args()

    run(sys.executable, "tools/test.py")
    run(sys.executable, "tools/test_exchange.py")
    run(sys.executable, "tools/export_models.py")
    run(sys.executable, "tools/build.py")
    check_upload_pack()

    place = ROOT / "dist" / "ThriftFlip.rbxlx"
    root = ET.parse(place).getroot()
    scripts = root.findall('.//ProtectedString[@name="Source"]')
    assert len(scripts) == 21, f"expected 21 embedded scripts, found {len(scripts)}"
    print(f"PASS place XML: {len(scripts)} embedded scripts, {place.stat().st_size / 1024:.0f} KiB")

    missing = unconfigured_assets()
    if missing:
        print("UPLOAD REQUIRED creator-owned IDs:", ", ".join(missing))
        if args.require_uploaded_assets:
            return 2
    else:
        print("PASS creator-owned asset IDs are configured")
    print("OFFLINE RELEASE CHECK PASSED")
    print("Roblox Studio, multiplayer, DataStore, device, and performance checks still require Roblox tools.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
