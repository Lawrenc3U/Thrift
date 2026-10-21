# Release status and required Studio checks

The user's target is the full game in `game-design.md`. This build implements much of the core, progression, and same-server social gameplay, but **does not fulfill the full production plan yet**. Automated passes do not replace playtesting.

## Required before calling this playable or ready to release

- Open the generated place in current Roblox Studio. Resolve engine/API errors, character spawning, camera, UI scrolling/safe areas, prompts, and streaming behavior. No Studio session has run in this cloud environment.
- Complete the tutorial without developer intervention, on desktop and mobile emulation. Walk to the workbench in the shop with your name. Restoration takes 8–20 seconds; basic gains are granted even for poor performance. Inventory items cannot be displayed while actively being restored.
- Confirm all five interactions with touch and mouse: scrub swipe, polish sequence, wire pairs, repaint palette, assembly piece selection. Test cancellation, death/respawn, UI closure, distance, timeout, duplicated input, and high latency.
- Test two to sixteen clients: different shop ownership, visitors cannot mutate another shop, customer offers, expired offers, occupied displays, cash reservation while bidding, disconnecting leading bidders, capacity at auction settlement, and anti-sniping.
- Validate real persistence in a dedicated published test experience. Restart servers, simulate failed saves, attempt concurrent joins, test lock expiry, and verify backups through Roblox tools. Backups are a manual recovery aid, not an automatic restoration system. Roblox may terminate a process before a final save; progress since the last successful save can still be lost.
- Profile 16-player town load, memory, streaming, and client FPS on real mid-range and low-end phones. The 60/30 FPS and 15-second load goals have not been measured.
- Run at least 10–20 playtests and tune tutorial completion, economy, retention, pacing, accessibility, and exploitation risks with measured data.

## Work still needed for the full design

| Area | Current implementation | Remaining production work |
| --- | --- | --- |
| World/art | Procedural shared street and 16 modular open shops | Custom authored town buildings, a proper auction interior, varied sourcing props, distinct 80-item silhouettes, thumbnails, icon, logo, animation polish |
| Shop tiers | Four slot capacities, signs and architectural details | Increasing room sizes and separate per-player interior instances |
| Restoration | Five functioning grid-based interaction implementations | Bespoke item-centered visual minigames, polish path tolerance, richer one-thumb assembly and accessibility options |
| Customers | Eight personalities, budgets/preferences, animated approach/exit, haggling | Rigged NPC art, walk cycles, actual route/pathfinding and browse choices |
| Market and trading | Explicitly unavailable in UI | Durable idempotent transfer journal, cross-profile crash recovery, escrow, confirmations, cooldowns, caps, fees and exploit testing; config flags do not enable nonexistent handlers |
| Showcase | Weekly server-local entries/votes; title for an online winner at rollover | Persistent global entries and votes, moderation, offline rewards, real theme scheduling and ranked results |
| Events | Daily style demand and estate-sale weekend rarity promotion | Scheduled seasonal content, limited cosmetics and event UI |
| Monetization | Empty cosmetic-pass configuration and purchase-completion hook | Returning-player entitlement reconciliation, actual creator-owned passes, previews and entitlement tests; no developer products or receipts are implemented |
| Audio | No audio assets | Licensed original shop/town/auction music, action sounds, settings and device checks |
| Analytics | Best-effort custom events for several core actions | Complete funnel IDs/steps, session duration, commerce instrumentation, dashboards and measured targets |
| Data | Session-locked version-1 profiles and backup copies | Migration framework, operator recovery tooling, fault-injection in live infrastructure, monitoring and load tests |
| Decorations | Fixed-location rugs/plants/poster/sign/curtains/trophy plus themes | Free-placement editor, rotation, collision checks, more themed sets |

The showcase is intentionally described as local. Do not present it as a persistent global weekly contest. Player market and trading are intentionally unavailable rather than claiming safe transfers before their transaction system exists. Paid gameplay advantages from the draft plan are omitted to honor its no-pay-to-win pillar.

## Studio smoke-test record

Not run. Fill in Roblox Studio version, desktop/mobile device, player count, persistence mode, actual result, and reproduction steps for each failure. Never replace an unrun result with a check mark based on cloud compilation.
