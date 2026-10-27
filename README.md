# Thrift Flip

A Roblox fashion thrift-and-resell game built in Luau. Hunt for catalog-inspired clothing, reveal its rarity, freshen it up, style your shop, and sell it to NPC shoppers based on your Roblox friends.

The creator upload pack is in `assets/marketing`: a 512×512 experience icon and three 1920×1080 thumbnails. Thirteen original WAV files are in `assets/audio`. Follow `docs/PUBLISH.md` to upload them and configure their creator-owned IDs.

**Status: a feature-complete development build that still needs final Roblox Studio and device QA before public release.** The cloud environment compiles the code and runs headless server tests; it cannot run Roblox Studio. See [release status](docs/RELEASE.md) for the publishing checklist.

## Open the game

1. Run `python3 tools/build.py` (Python 3.10+; no packages required).
2. Open `dist/ThriftFlip.rbxlx` in Roblox Studio on Windows or macOS.
3. Click **Play**. Studio practice mode is on by default and deliberately does not save. You start with **$500**. Follow the gold tutorial marker: Thrift Outlet → Bag → inspect the label → your named shop → workbench → freshen → display → accept your first friend's offer in Shop.
4. Use **Test → Start** with two or more clients to exercise visits, ratings, and auctions. Configure the published experience for **8 players** in Creator Dashboard to match the eight claimable shops.

Optional Rojo workflow: install Rojo 7, run `rojo serve default.project.json`, and connect Studio's Rojo plugin. The Python place builder provides a dependency-free alternative; it embeds all scripts with the same hierarchy.

## Implemented systems

- 80 catalog-inspired fashion finds across T-shirts, shirts, pants, shorts, jackets, dresses, shoes, and accessories; five rarities and conditions; Roblox catalog attribution and thumbnails; original 3D replicas; rarity effects; and an exported `.rbxmx` model pack.
- Server-owned inventory, currency, value, demand, progression, sourcing costs/cooldowns, daily delivery, collections, and milestone rewards.
- Five restoration interactions: swipe scrub, trace polish, match rewiring pairs, paint palette/fill, and piece/outline assembly. Server validates tokens, targets, input rate, duration, ownership, and result quality.
- A rebuilt cozy town matching the supplied 3D preview, with a Thrift Outlet, Fashion Flea, Donation Drop, Curated Rack, market row, Auction House, eight claimable shops, four visual tiers, movable floor decorations, and clothing displays. Shoppers use the player's friends list and avatar appearance when Roblox makes it available, with reliable fallback customers.
- Same-server auctions with reserved cash and anti-sniping; durable same-server market listings and confirmed two-sided trades; persistent weekly showcase neighborhoods; seasonal events, visiting, ratings, quests, titles, and cosmetic-only commerce hooks.
- Responsive mobile/desktop journal UI, real-time 3D item previews, filtered inventory and collection pages, market/trade review, seasonal pages, tutorial guidance, rarity symbols plus color, settings, and polished action feedback.
- UpdateAsync persistence with expiring session leases, retries, periodic saves, shutdown release, recovery copies, and refusal to overwrite unavailable saves. These protections are implemented and mocked in tests; live DataStore reliability still requires Studio/published-server validation.

## Development checks

Install/build Luau **0.699**, commit `994b6416f1a2d16ac06c52b4e574bad5d8749053`, outside this checkout:

```sh
git clone --branch 0.699 --depth 1 https://github.com/luau-lang/luau.git /workspace/tooling/luau
make -C /workspace/tooling/luau config=release luau luau-compile -j2
python3 tools/test.py
python3 tools/test_exchange.py
python3 tools/generate_audio.py
python3 tools/export_models.py
python3 tools/build.py
python3 tools/release_check.py
```

`tools/test.py` defaults to that cloud path. On another machine, set `LUAU` and optionally `LUAU_COMPILE` to your executable paths. It compiles every source file, then executes production economy, profile, persistence, and game-service code against service doubles. It does **not** emulate the Roblox engine or claim UI/physics/network readiness.

## Persistence and publishing

Live servers always require working Roblox DataStores. To test real persistence in Studio, publish a **separate test experience**, enable Studio API access in its security settings, and set `Config.StudioPracticeMode = false`. Do not enable Studio access to your production saves. Test leave/rejoin, two-server overlap, network failures, and shutdown. Missing data access kicks players with an explanation; it never falls back to a disposable live profile.

Publishing, pass creation, and release configuration happen in your Roblox account. The repository includes original generated WAV music/effects under `assets/audio`, a reusable 80-item fashion model pack under `assets/models`, and an asset-ID manifest in `src/shared/AssetConfig.luau`. Upload the WAV files through your experience's Asset Manager and paste the resulting IDs into that manifest. Cosmetic purchase configuration is deliberately empty until creator-owned IDs exist. There are no paid random finds or paid progression boosts.

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
