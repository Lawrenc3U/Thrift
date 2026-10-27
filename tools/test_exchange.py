#!/usr/bin/env python3
"""Execute the real exchange invariants through interruption and replay cases."""
from pathlib import Path
import os
import shutil
import subprocess

ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/"src/shared/ExchangeRules.luau").read_text(encoding="utf-8")
source=source.rsplit("return ExchangeRules",1)[0]
suite=r'''
local function item(id) return {Uid=id,DefId="lamps_1",Rarity=2,Condition=4,Variance=1,Inspected=true} end
local function side(id,delta,outgoing,incoming) return {UserId=id,CashDelta=delta,Outgoing=outgoing,Incoming=incoming} end
local a={Cash=500,Inventory={item("a")},Collection={}}
local b={Cash=100,Inventory={item("b")},Collection={}}
local tx={Id="tx-1",Sides={side(1,-75,{"a"},{item("b")}),side(2,75,{"b"},{item("a")})},Acks={}}
a.Exchange={Pending="tx-1"}; b.Exchange={Pending="tx-1"}
assert(ExchangeRules.apply(a,tx,tx.Sides[1],100)); assert(a.Cash==425 and a.Inventory[1].Uid=="b")
assert(ExchangeRules.apply(b,tx,tx.Sides[2],100)); assert(b.Cash==175 and b.Inventory[1].Uid=="a")
local cash,count=a.Cash,#a.Inventory
assert(ExchangeRules.apply(a,tx,tx.Sides[1],100)); assert(a.Cash==cash and #a.Inventory==count)
local bad={Cash=0,Inventory={},Collection={},Exchange={Pending="tx-2"}}
local badTx={Id="tx-2",Sides={side(3,-1,{}, {})},Acks={}}
assert(not ExchangeRules.apply(bad,badTx,badTx.Sides[1],100)); assert(bad.Cash==0)
local full={Cash=20,Inventory={},Collection={},Exchange={Pending="tx-3"}}
for i=1,100 do table.insert(full.Inventory,item("f"..i)) end
local fullTx={Id="tx-3",Sides={side(4,0,{}, {item("extra")})},Acks={}}
assert(not ExchangeRules.apply(full,fullTx,fullTx.Sides[1],100)); assert(#full.Inventory==100)
tx.Acks["1"]=true; assert(not ExchangeRules.allAcknowledged(tx)); tx.Acks["2"]=true; assert(ExchangeRules.allAcknowledged(tx))
print("PASS durable exchange conservation, capacity, insufficient cash and idempotent replay")
'''
target=ROOT/".exchange-tests.generated.luau"
configured=os.environ.get("LUAU")
candidates=[configured,shutil.which("luau"),shutil.which("luau.exe"),str(ROOT/"tools"/"bin"/("luau.exe" if os.name=="nt" else "luau")),"/workspace/tooling/luau/luau"]
luau=next((candidate for candidate in candidates if candidate and Path(candidate).is_file()),None)
if not luau:
    print("SKIP Luau exchange tests: Luau CLI is not installed. Roblox Studio testing is still required.")
    raise SystemExit(0)
try:
    target.write_text(source+"\n"+suite,encoding="utf-8")
    subprocess.run([luau,str(target)],check=True,cwd=ROOT)
finally: target.unlink(missing_ok=True)
