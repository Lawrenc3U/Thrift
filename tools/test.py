#!/usr/bin/env python3
"""Compile all source; run real modules in a Luau harness with mocked Roblox services."""
import os
import shutil
import subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def find_tool(environment_name, executable_name):
    configured = os.environ.get(environment_name)
    candidates = [
        configured,
        shutil.which(executable_name),
        shutil.which(executable_name + '.exe'),
        str(ROOT / 'tools' / 'bin' / (executable_name + ('.exe' if os.name == 'nt' else ''))),
        '/workspace/tooling/luau/' + executable_name,
    ]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return candidate
    return None

def main():
    luau = find_tool('LUAU', 'luau')
    compiler = find_tool('LUAU_COMPILE', 'luau-compile')
    if not luau or not compiler:
        print('SKIP Luau gameplay tests: Luau CLI is not installed. Roblox Studio testing is still required.')
        print('Install Luau, add luau and luau-compile to PATH, or set LUAU and LUAU_COMPILE.')
        return 0
    files = sorted((ROOT / 'src').rglob('*.luau'))
    for path in files:
        result = subprocess.run([compiler, '--null', str(path)], capture_output=True, text=True)
        if result.returncode:
            print(result.stdout, result.stderr)
            raise SystemExit(result.returncode)
    print(f'Compiled {len(files)} Luau source files', flush=True)
    bundle = (ROOT / 'tests' / 'mocks.luau').read_text(encoding='utf-8') + '\n'
    for folder, name in [('shared', 'Config'), ('shared', 'Catalog'), ('shared', 'Economy'), ('shared', 'Profile'), ('shared', 'Commerce'), ('shared', 'DecorPlacement'), ('server', 'DataService'), ('server', 'GameService')]:
        source = (ROOT / 'src' / folder / f'{name}.luau').read_text(encoding='utf-8')
        source = '\n'.join(line for line in source.splitlines() if not (
            line.startswith('local Shared = ') or line.startswith('local Config = require(')
            or line.startswith('local Catalog = require(') or line.startswith('local Economy = require(')
            or line.startswith('local Profile = require(') or line.startswith('local DecorPlacement = require(')))
        bundle += f'local {name} = (function()\n{source}\nend)()\n'
    bundle += (ROOT / 'tests' / 'game.spec.luau').read_text(encoding='utf-8')
    target = ROOT / '.luau-tests.generated.luau'
    try:
        target.write_text(bundle, encoding='utf-8')
        subprocess.run([luau, str(target)], check=True, cwd=ROOT)
    finally:
        target.unlink(missing_ok=True)

if __name__ == '__main__':
    raise SystemExit(main())
