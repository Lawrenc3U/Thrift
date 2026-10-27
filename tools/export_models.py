#!/usr/bin/env python3
"""Export the original 80-item primitive library as a reusable Roblox model pack."""
from pathlib import Path
import json, math, os, shutil, subprocess, tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "models"

def find_luau():
    configured = os.environ.get("LUAU")
    candidates = [
        configured,
        shutil.which("luau"),
        shutil.which("luau.exe"),
        str(ROOT / "tools" / "bin" / ("luau.exe" if os.name == "nt" else "luau")),
        "/workspace/tooling/luau/luau",
    ]
    return next((candidate for candidate in candidates if candidate and Path(candidate).is_file()), None)

DRIVER = r'''
local catalog = require("%s")
local models = require("%s")
local function join(v) return tostring(v[1])..","..tostring(v[2])..","..tostring(v[3]) end
for _, definition in ipairs(catalog.Items) do
    print("M\t"..definition.Id.."\t"..definition.Name.."\t"..definition.Category.."\t"..definition.Variant)
    local item={Condition=5,Style=definition.Style,Rarity=1}
    for _, p in ipairs(models.describe(definition,item)) do
        print("P\t"..p.Name.."\t"..p.Class.."\t"..(p.Shape or "").."\t"..join(p.Size).."\t"..join(p.Position).."\t"..join(p.Rotation).."\t"..join(p.Color).."\t"..p.Material.."\t"..p.Transparency.."\t"..p.Reflectance)
    end
end
''' % ("./src/shared/Catalog", "./src/shared/ItemModels")

def xyz(value): return [float(v) for v in value.split(",")]
def rotation(rx, ry, rz):
    cx,sx,cy,sy,cz,sz=math.cos(rx),math.sin(rx),math.cos(ry),math.sin(ry),math.cos(rz),math.sin(rz)
    return (cy*cz, sx*sy*cz-cx*sz, cx*sy*cz+sx*sz,
            cy*sz, sx*sy*sz+cx*cz, cx*sy*sz-sx*cz,
            -sy, sx*cy, cx*cy)
def prop(parent, tag, name, text): ET.SubElement(parent,tag,{"name":name}).text=str(text)
def item(parent, cls, name, ref):
    node=ET.SubElement(parent,"Item",{"class":cls,"referent":ref}); props=ET.SubElement(node,"Properties")
    prop(props,"string","Name",name); return node,props

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    luau = find_luau()
    if not luau:
        pack, manifest_path = OUT / "ThriftFlipItems.rbxmx", OUT / "manifest.json"
        assert pack.is_file() and manifest_path.is_file(), "Luau CLI is required to generate the missing model pack"
        ET.parse(pack)
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        assert len(manifest) == 80, f"expected 80 committed item models, got {len(manifest)}"
        print("SKIP model regeneration: Luau CLI is not installed; validated the committed 80-item model pack.")
        return
    with tempfile.NamedTemporaryFile("w",suffix=".luau",dir=ROOT,delete=False,encoding="utf-8") as handle:
        handle.write(DRIVER); driver=Path(handle.name)
    try: lines=subprocess.run([luau,str(driver)],check=True,capture_output=True,text=True,cwd=ROOT).stdout.splitlines()
    finally: driver.unlink(missing_ok=True)
    models=[]; current=None
    for line in lines:
        fields=line.split("\t")
        if fields[0]=="M":
            current={"id":fields[1],"name":fields[2],"category":fields[3],"variant":int(fields[4]),"parts":[]}; models.append(current)
        else:
            current["parts"].append({"name":fields[1],"class":fields[2],"shape":fields[3],"size":xyz(fields[4]),"position":xyz(fields[5]),"rotation":xyz(fields[6]),"color":xyz(fields[7]),"material":fields[8],"transparency":float(fields[9]),"reflectance":float(fields[10])})
    counts=[len(model["parts"]) for model in models]
    assert len(models)==80, f"expected 80 models, got {len(models)}"
    assert all(3 <= count <= 60 for count in counts), f"unexpected part range {min(counts)}..{max(counts)}"
    root=ET.Element("roblox",{"version":"4"}); ET.SubElement(root,"External").text="null"; ET.SubElement(root,"External").text="nil"
    serial=0
    for model in models:
        serial+=1; model_node,_=item(root,"Model",model["name"],f"RBX{serial}")
        for part in model["parts"]:
            serial+=1; node,props=item(model_node,part["class"],part["name"],f"RBX{serial}")
            prop(props,"bool","Anchored","true"); prop(props,"bool","CanCollide","false")
            size=ET.SubElement(props,"Vector3",{"name":"Size"})
            for axis,value in zip("XYZ",part["size"]): ET.SubElement(size,axis).text=str(value)
            cf=ET.SubElement(props,"CoordinateFrame",{"name":"CFrame"}); pos=part["position"]
            for axis,value in zip("XYZ",pos): ET.SubElement(cf,axis).text=str(value)
            for key,value in zip(("R00","R01","R02","R10","R11","R12","R20","R21","R22"),rotation(*part["rotation"])): ET.SubElement(cf,key).text=str(value)
            packed=(round(part["color"][0]*255)<<24)|(round(part["color"][1]*255)<<16)|(round(part["color"][2]*255)<<8)|255
            prop(props,"Color3uint8","Color3uint8",packed)
            materials={"SmoothPlastic":256,"Plastic":256,"Neon":2880,"Wood":512,"WoodPlanks":512,
                "Metal":1088,"Glass":1568,"Fabric":1312,"Marble":784,"Ceramic":512}
            prop(props,"token","Material",materials.get(part["material"],256))
            if part["class"] == "Part" and part["shape"]:
                prop(props,"token","shape",{"Ball":0,"Block":1,"Cylinder":2}.get(part["shape"],1))
            prop(props,"float","Transparency",part["transparency"]); prop(props,"float","Reflectance",part["reflectance"])
    ET.indent(root); pack=OUT/"ThriftFlipItems.rbxmx"; ET.ElementTree(root).write(pack,encoding="utf-8",xml_declaration=True)
    ET.parse(pack)
    manifest={m["id"]:{"name":m["name"],"category":m["category"],"variant":m["variant"],"parts":len(m["parts"])} for m in models}
    (OUT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print(f"Exported {len(models)} original item models ({sum(len(m['parts']) for m in models)} parts) to {pack}")

if __name__ == "__main__": main()
