# Thrift Flip

A Roblox restore-and-resell game built in Luau. Find forgotten treasures, reveal their rarity, restore them, decorate your shop, and sell to customers in a cozy shared town.

**Status: an implemented, unplaytested development build—not a complete or launch-ready game.** The cloud environment compiles the code and runs headless server tests; it cannot run Roblox Studio. See [release status](docs/RELEASE.md) for the remaining work against the full [game plan](docs/game-design.md).

## Open the game

1. Run `python3 tools/build.py` (Python 3.10+; no packages required).
2. Open `dist/ThriftFlip.rbxlx` in Roblox Studio on Windows or macOS.
3. Click **Play**. Studio practice mode is on by default and deliberately does not save. Follow the gold tutorial marker: Dumpster Alley → Bag → Inspect → your named shop → workbench → restore → display → accept your first customer's offer in Shop.
4. Use **Test → Start** with two or more clients to exercise visits, ratings, and auctions. Configure the published experience for **16 players** in Creator Dashboard.

Optional Rojo workflow: install Rojo 7, run `rojo serve default.project.json`, and connect Studio's Rojo plugin. The Python place builder provides a dependency-free alternative; it embeds all scripts with the same hierarchy.

## Implemented systems

- 80 catalog definitions in eight categories; five rarities and conditions; procedural category models with size variants, rarity outlines, and condition tinting.
- Server-owned inventory, currency, value, demand, progression, sourcing costs/cooldowns, daily delivery, collections, and milestone rewards.
- Five restoration interactions: swipe scrub, trace polish, match rewiring pairs, paint palette/fill, and piece/outline assembly. Server validates tokens, targets, input rate, duration, ownership, and result quality.
- 16 generated shops, four capacity tiers with architectural trim upgrades, themes, six buyable decorations, display slots, and eight customer personalities with budgets, preferences, offers, counters, and sales.
- Same-server auctions with reserved cash, anti-sniping extensions, and single-profile settlement; visiting and daily ratings; daily and weekly quests; titles and a **server-local** showcase.
- Touch-compatible responsive panels, keyboard/mouse support through Roblox movement and proximity prompts, tutorial hints/markers, rarity symbols plus color, settings, and basic action feedback.
- UpdateAsync persistence with expiring session leases, retries, periodic saves, shutdown release, recovery copies, and refusal to overwrite unavailable saves. These protections are implemented and mocked in tests; live DataStore reliability still requires Studio/published-server validation.

## Development checks

Install/build Luau **0.699**, commit `994b6416f1a2d16ac06c52b4e574bad5d8749053`, outside this checkout:

```sh
git clone --branch 0.699 --depth 1 https://github.com/luau-lang/luau.git /workspace/tooling/luau
make -C /workspace/tooling/luau config=release luau luau-compile -j2
python3 tools/test.py
python3 tools/build.py
```

`tools/test.py` defaults to that cloud path. On another machine, set `LUAU` and optionally `LUAU_COMPILE` to your executable paths. It compiles every source file, then executes production economy, profile, persistence, and game-service code against service doubles. It does **not** emulate the Roblox engine or claim UI/physics/network readiness.

## Persistence and publishing

Live servers always require working Roblox DataStores. To test real persistence in Studio, publish a **separate test experience**, enable Studio API access in its security settings, and set `Config.StudioPracticeMode = false`. Do not enable Studio access to your production saves. Test leave/rejoin, two-server overlap, network failures, and shutdown. Missing data access kicks players with an explanation; it never falls back to a disposable live profile.

Publishing, pass creation, branding, licensed audio, and release configuration happen in your Roblox account. No Roblox credentials are needed for the cloud build. Cosmetic pass mappings in `Config.CosmeticPasses` are deliberately empty; no purchases are offered until valid owned IDs and entitlement testing exist. There are no paid random finds or paid progression boosts.

## Layout

| Path | Purpose |
| --- | --- |
| `src/shared` | Catalog, tuning, economy formulas, profile defaults |
| `src/server` | Session-locked saves, world generation, game rules, lifecycle |
| `src/client` | Mobile UI, local guidance, five restoration interactions |
| `tests` | Behavioral tests and Roblox service doubles |
| `tools` | Luau validation and Studio place export |
| `docs` | Original plan, playtest checklist, release gaps |

Each cloud task is already isolated. Work in this checkout; a separate Git worktree is unnecessary.
