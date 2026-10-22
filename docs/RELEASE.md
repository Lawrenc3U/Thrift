# Release status and required Studio checks

The user's target is the full game in `game-design.md`. The code now implements the complete planned gameplay framework. It still requires Roblox Studio validation, creator-owned asset upload, performance profiling, and real-player tuning before a public launch. Automated passes do not replace playtesting.

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
| World/art | Authored modular town, auction interior, market, sourcing sets, 16 shops and 80 original item models | Final Studio lighting pass, optional custom Blender meshes, icon/thumbnail upload |
| Shop tiers | Four capacities with changing architecture, themes and movable floor decor | Final collision and mobile placement QA |
| Restoration | Five item-centered touch/mouse interactions with server validation | Tune tolerance and timing from device playtests |
| Customers | Eight personalities, budgets/preferences, animated arrival/exit and haggling | Optional rigged walk cycles and expanded browsing animations |
| Market and trading | Same-server listings and two-sided trades with durable journal recovery, fees, caps, review delay and confirmations | Published-server fault injection and exploit testing |
| Showcase | Persistent weekly neighborhood contests, bounded voting, offline cosmetic claims and themes | Moderation operations and live-scale monitoring |
| Events | Daily style demand and estate-sale weekend rarity promotion | Scheduled seasonal content, limited cosmetics and event UI |
| Monetization | Empty cosmetic-pass configuration and purchase-completion hook | Returning-player entitlement reconciliation, actual creator-owned passes, previews and entitlement tests; no developer products or receipts are implemented |
| Audio | Original generated shop/town/auction music and action WAVs | Upload in Asset Manager, paste owned IDs, and mix on devices |
| Analytics | Best-effort custom events for several core actions | Complete funnel IDs/steps, session duration, commerce instrumentation, dashboards and measured targets |
| Data | Session-locked version-1 profiles and backup copies | Migration framework, operator recovery tooling, fault-injection in live infrastructure, monitoring and load tests |
| Decorations | Fixed-location rugs/plants/poster/sign/curtains/trophy plus themes | Free-placement editor, rotation, collision checks, more themed sets |

The showcase uses 32 persistent weekly neighborhoods rather than one unbounded global hot key. Market listings and direct trades are same-server by design; durable journal recovery protects interrupted transfers. Paid gameplay advantages from the draft plan remain omitted to honor its no-pay-to-win pillar.

## Studio smoke-test record

Not run. Fill in Roblox Studio version, desktop/mobile device, player count, persistence mode, actual result, and reproduction steps for each failure. Never replace an unrun result with a check mark based on cloud compilation.
