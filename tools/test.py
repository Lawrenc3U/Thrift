#!/usr/bin/env python3
"""Compile all source; run real modules in a Luau harness with mocked Roblox services."""
import os
import subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
LUAU = os.environ.get('LUAU', '/workspace/tooling/luau/luau')
COMPILER = os.environ.get('LUAU_COMPILE', str(Path(LUAU).with_name('luau-compile')))

def main():
    files = sorted((ROOT / 'src').rglob('*.luau'))
    for path in files:
        result = subprocess.run([COMPILER, '--null', str(path)], capture_output=True, text=True)
        if result.returncode:
            print(result.stdout, result.stderr)
            raise SystemExit(result.returncode)
    print(f'Compiled {len(files)} Luau source files', flush=True)
    bundle = (ROOT / 'tests' / 'mocks.luau').read_text() + '\n'
    for folder, name in [('shared', 'Config'), ('shared', 'Catalog'), ('shared', 'Economy'), ('shared', 'Profile'), ('shared', 'Commerce'), ('shared', 'DecorPlacement'), ('server', 'DataService'), ('server', 'GameService')]:
        source = (ROOT / 'src' / folder / f'{name}.luau').read_text()
        source = '\n'.join(line for line in source.splitlines() if not (
            line.startswith('local Shared = ') or line.startswith('local Config = require(')
            or line.startswith('local Catalog = require(') or line.startswith('local Economy = require(')
            or line.startswith('local Profile = require(') or line.startswith('local DecorPlacement = require(')))
        bundle += f'local {name} = (function()\n{source}\nend)()\n'
    bundle += (ROOT / 'tests' / 'game.spec.luau').read_text()
    target = ROOT / '.luau-tests.generated.luau'
    try:
        target.write_text(bundle)
        subprocess.run([LUAU, str(target)], check=True, cwd=ROOT)
    finally:
        target.unlink(missing_ok=True)

if __name__ == '__main__':
    main()
