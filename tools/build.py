#!/usr/bin/env python3
"""Build a Roblox XML place using only Python's standard library."""
from pathlib import Path
import argparse
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

def build(output: Path) -> tuple[int, int]:
    root = ET.Element('roblox', {'version': '4'})
    ET.SubElement(root, 'External').text = 'null'
    ET.SubElement(root, 'External').text = 'nil'
    count = 0
    def item(parent, cls, name):
        nonlocal count
        count += 1
        obj = ET.SubElement(parent, 'Item', {'class': cls, 'referent': f'RBX{count}'})
        props = ET.SubElement(obj, 'Properties')
        ET.SubElement(props, 'string', {'name': 'Name'}).text = name
        return obj, props
    workspace, props = item(root, 'Workspace', 'Workspace')
    ET.SubElement(props, 'bool', {'name': 'StreamingEnabled'}).text = 'true'
    ET.SubElement(props, 'float', {'name': 'Gravity'}).text = '196.2'
    item(root, 'Lighting', 'Lighting')
    item(root, 'SoundService', 'SoundService')
    storage, _ = item(root, 'ReplicatedStorage', 'ReplicatedStorage')
    shared, _ = item(storage, 'Folder', 'Shared')
    scripts, _ = item(root, 'ServerScriptService', 'ServerScriptService')
    server, _ = item(scripts, 'Folder', 'Server')
    starter, _ = item(root, 'StarterPlayer', 'StarterPlayer')
    player_scripts, _ = item(starter, 'StarterPlayerScripts', 'StarterPlayerScripts')
    client, _ = item(player_scripts, 'Folder', 'Client')
    script_count = 0
    for folder, target in [('shared', shared), ('server', server), ('client', client)]:
        for path in sorted((ROOT / 'src' / folder).glob('*.luau')):
            suffix = '.server' if path.stem.endswith('.server') else '.client' if path.stem.endswith('.client') else ''
            cls = {'': 'ModuleScript', '.server': 'Script', '.client': 'LocalScript'}[suffix]
            name = path.stem.removesuffix(suffix) if suffix else path.stem
            _, props = item(target, cls, name)
            ET.SubElement(props, 'ProtectedString', {'name': 'Source'}).text = path.read_text()
            script_count += 1
    ET.indent(root)
    output.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(root).write(output, encoding='utf-8', xml_declaration=True)
    # Round-trip every script to catch escaping or accidental omission.
    sources = ET.parse(output).findall('.//ProtectedString[@name="Source"]')
    assert len(sources) == script_count
    expected = sorted(p.read_text() for p in (ROOT / 'src').rglob('*.luau'))
    assert sorted(s.text for s in sources) == expected
    return count, script_count

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=ROOT / 'dist' / 'ThriftFlip.rbxlx')
    args = parser.parse_args()
    objects, scripts = build(args.output)
    print(f'Built {args.output}: {objects} instances, {scripts} scripts (source round-trip verified)')
