Thrift Flip: Game Plan
A Roblox restore-and-resell shop game. Version 1.0 plan, October 2026.
1. Vision
One-line pitch: Buy junk, restore it, display it in your shop, and sell it for profit. Turn $5 junk into $5,000 antiques.
What makes it different: Most shop games on Roblox are tycoons or roleplay. Thrift Flip combines the surprise of mystery-box finds, the satisfaction of restoring things, and the style appeal of decorating a shop. Players see value grow in front of them, then show it off.
Design pillars
1. Surprise: every item has hidden condition and rarity. Opening a find should feel like a small jackpot.
2. Satisfaction: restoring should feel good in seconds (clean, polish, repaint) with clear before and after.
3. Style: the shop is the player's identity. Decor, themes and displays matter more than raw numbers.
4. Social: visit shops, bid at auctions, trade, and rate each other.
Audience: Roblox players aged roughly 9 to 15, mobile-first, who like collecting, decorating and simple minigames. Design for phones first, then PC and tablet.
2. Core gameplay loop (3 to 5 minutes)
1. Find: visit a sourcing spot (dumpster run, estate sale, auction) and pick up mystery items.
2. Inspect: reveal the item's category, condition and hidden rarity.
3. Restore: play a short minigame that raises condition and value.
4. Display: place the item in the shop on a shelf, table or wall.
5. Sell: NPC customers walk in, browse, haggle and buy. Other players can buy too.
6. Reinvest: spend cash on a bigger shop, better tools and decor, which unlocks better finds.
First 60 seconds (tutorial): the player finds one item, restores it with a guided 10-second minigame, places it on a shelf, and sells it to a friendly NPC for a visible profit. No text walls. One big arrow and one big button at a time.
3. Systems
3.1 Items and rarity
• Categories (launch): lamps, radios, clocks, chairs, toys, mirrors, cameras, vases. About 10 base items per category (80 total).
• Condition: Wrecked, Poor, Fair, Good, Mint. Restoring moves condition up.
• Rarity: Common, Uncommon, Rare, Epic, Legendary. Rarity is hidden until inspected and sets the value range.
• Value formula (server side): base value x rarity multiplier x condition multiplier x small random variance x active demand modifier.
• Style tags: each item has a style (Retro, Cozy, Futuristic, Antique, Cute). Matching styles in a shop gives a display bonus.
3.2 Restoration minigames
Each takes 8 to 20 seconds and works with one thumb on mobile.
• Scrub: swipe back and forth to clear grime. Fast and relaxing.
• Polish: trace a path without leaving it. Rewards accuracy.
• Rewire: connect matching colors. Used for electronics.
• Repaint: pick colors and fill areas. Creative, affects style tag and value.
• Assemble: drag pieces into place. Used for broken items.
Result quality (Okay, Good, Perfect) changes the condition gain. Upgraded tools make minigames easier or give small bonuses. Never make a minigame a hard gate; failure just gives a smaller gain.
3.3 Shop and customers
• Shop layout: the player places items on shelves, tables and wall slots. Displays have capacity limits that upgrades raise.
• NPC customers: 6 to 8 personality types. Each prefers certain styles and budgets. Some haggle; the player chooses to accept, counter or decline. A good haggle is a quick two-button choice, not a long dialogue.
• Reputation: serving customers well and decorating well raises shop reputation, which brings more and better customers.
• Shop tiers: Corner Stall, Small Shop, Boutique, Department Store. Each is a bigger interior with more slots and a new look.
3.4 Sourcing locations
• Dumpster runs: free, low rarity, quick. Good for beginners.
• Estate sales: paid mystery lots with better odds.
• Auction house: live bidding events with up to 8 players. A single rare lot appears and players bid against each other. The most exciting multiplayer moment in the game.
• Daily deliveries: one free lot per day to bring players back.
3.5 Multiplayer features
• Shared town: a street of eight shops with up to 8 players per server. Players walk between shops, browse, and chat.
• Player market: list restored items for sale to other players. Price caps and a listing fee reduce abuse.
• Trading: confirmed two-sided trades with a cool-down. This launches after the core game is stable.
• Shop ratings: visitors can leave a star rating once per day.
• Weekly contest: best shop in a theme (for example Cozy Cabin), judged by player votes, with cosmetic prizes.
3.6 Progression and goals
• Levels: shop level unlocks new item categories, sourcing spots and decor.
• Collection book: a catalog of every item and rarity found. Completion gives rewards and a reason to keep playing.
• Daily and weekly quests: for example "Restore 3 lamps", "Sell something for 500".
• Titles and trophies: earned from contests and milestones, shown on the player's sign.
3.7 Events
• Estate Sale Weekend: boosted rare drops for a limited time.
• Designer Showcase: a themed contest with a limited cosmetic prize.
• Seasonal events: holiday decor and limited collectibles.
4. How the world looks
4.1 Art direction
Bright, warm and cozy, stylized in a chunky Roblox-friendly look with soft rounded shapes, a little visible wear, and thick readable silhouettes. Think vintage market meets pastel toy shop. Not realistic, not gloomy.
Palette
• Base: cream, warm wood, soft teal and dusty rose.
• Accents: mustard yellow and coral for highlights and UI.
• Rarity colors: gray, green, blue, purple, gold. These are used consistently everywhere (glow, borders, UI).
Lighting: warm golden afternoon light outside and soft lamp light inside, with gentle shadows. Rare items have a subtle glow so they pop on a shelf.
4.2 The town: Thrift Street
A charming cobblestone street with a central square and shops along both sides.
• Town square: fountain, notice board (quests and contests), bench seating, and a market stall area for player-to-player listings.
• Player shops: each shop has a unique storefront color and a sign showing the owner's name, level and rating. Awnings and window displays show the owner's best items.
• Auction house: a grand brick building with a stage and a curtain. Seats for bidders, a spotlight on the lot, and a big gavel animation.
• Estate sale lot: a front yard filled with boxes and furniture, with a friendly seller NPC.
• Dumpster alley: a slightly messy but still colorful back street with bins, crates and neon signs.
• Edges: hills, trees, rooftops and a skyline backdrop so the world feels complete rather than boxed in.
4.3 The shop interior
• A compact room with a front counter, a shelf wall, a center display table, and a back workbench for restoring.
• Workbench: a tidy desk with a lamp, tool rack and a clear spot to place the item. This is where minigames happen, with the camera pulling in slightly.
• Display slots: glowing outlines show where items can go. Placing an item makes a satisfying little pop and sparkle.
• Upgrade look: each tier changes the walls, floor, lighting and room size, so progression is visible.
• Decor: rugs, plants, posters, neon signs, curtains, and themed sets.
4.4 Characters
• Players use their own Roblox avatars. Optional cosmetics include aprons, hats, glasses and name tags.
• NPC customers are simple, expressive and varied: an older collector, a hipster, a kid with pocket money, a decorator, a dealer. Each has a short idle and happy animation.
4.5 UI style
• Rounded panels, large buttons, bold readable text, and a consistent rarity color system.
• Mobile layout: thumb-reachable controls on the bottom corners, minimal clutter, and no tiny text.
• Feedback on every action: number pop-ups, sparkles, short sounds, and a gentle screen shake on big finds.
4.6 Audio
• Relaxed, upbeat background music in the shop and a livelier track in the auction house.
• Satisfying sounds for scrubbing, polishing, placing, selling (a cash register chime) and rare reveals (a rising sparkle).
5. Quality bar
The game should feel polished even if it is small. Targets:
Visual quality
• A consistent art style across every asset. Two ugly assets hurt more than ten missing ones.
• Every item has a clear silhouette and readable at thumbnail size.
• Rarity effects are obvious but not noisy.
• Custom icons, a real game logo and clean thumbnails (not default or stock).
Gameplay quality
• Every action gets instant feedback (visual, sound and number).
• No minigame takes more than 20 seconds, and each is playable in one hand.
• No dead time: the player always has an obvious next action.
Performance
• Stable 60 FPS on mid-range phones in the shop, and at least 30 FPS in the busiest town scenes.
• Initial load under about 15 seconds on a typical connection; keep the part count modest and use streaming for the town.
• Keep memory usage reasonable for low-end devices.
Reliability
• All money, items and trades are validated on the server. The client only requests actions.
• DataStore saves use retries, session locking and a backup plan so progress is never lost.
• Anti-exploit checks for duplication, teleport abuse and fake sales.
Accessibility and safety
• Readable text sizes and color-blind-friendly rarity (use icons or shapes as well as color).
• Chat uses Roblox's standard filtering; trading and market limits protect younger players.
• No pay-to-win: purchases are cosmetic or convenience only.
Playtest goals (launch targets, not guarantees)
• At least 70% of new testers complete the tutorial.
• Day-1 return rate of around 25% or better in early tests; improve from there.
• Average first session of roughly 10 minutes or more.
6. Technical plan
• Engine: Roblox Studio, Luau.
• Structure: server scripts own game state; clients handle UI and effects. Use RemoteEvents with strict validation.
• Modules: ItemService (generation and values), ShopService (displays, customers, sales), MinigameService, MarketService, AuctionService, DataService (DataStoreService with retries), QuestService, MonetizationService.
• Data saved per player: cash, level, inventory, shop layout, collection book progress, owned cosmetics, and settings.
• World: the Thrift Street town built with modular pieces (reusing the BuildWorld approach), plus a separate per-player shop interior instance.
• Tags and attributes: CollectionService tags for interactables so scripts stay clean.
• Analytics: log funnel steps (tutorial, first sale, first restore, shop upgrade), session length and spending, so decisions come from data.
7. Monetization
Type
Examples
Game passes
VIP Auction Access, Auto-Cleaner tools, Extra Display Slots, Double Reputation
Developer products
Instant Restore, Reveal Rarity, Cash Boost, Extra Daily Lot
Cosmetics
Shop themes, storefront signs, display cases, mannequins, avatar aprons and hats
Limited drops
Weekly estate sale with a rare cosmetic or collectible
Rules: cosmetics are the primary sale, nothing locks core progression behind Robux, and prices stay low and clear. Sell by showing, not by nagging: preview items in the shop before buying.
8. Roadmap
Phase 0: Prototype (weeks 1 to 2)
• One shop, 10 items, two minigames, NPC customers, and basic save.
• Goal: prove the loop is fun with friends.
Phase 1: Vertical slice (weeks 3 to 6)
• 40 items, all five minigames, shop tiers 1 and 2, dumpster runs and estate sales, UI polish, tutorial.
• Goal: a small but polished experience you could show publicly.
Phase 2: Multiplayer (weeks 7 to 10)
• The shared Thrift Street town, shop visiting and ratings, auction house, player market.
• Goal: players interact and have reasons to return.
Phase 3: Monetization and polish (weeks 11 to 12)
• Game passes, products, cosmetics, daily quests, collection book, audio pass, icon and thumbnail set.
• Goal: launch-ready.
Phase 4: Soft launch and tuning (weeks 13 to 16)
• Release to a small audience, watch retention and drop-off, fix the biggest problems, and tune the economy.
Phase 5: Live ops (ongoing)
• Weekly estate sale, monthly contest, seasonal events, new item categories every few weeks, and trading once the economy is stable.
Timelines assume one dedicated developer with some help on art. A small team (programmer, builder, artist) could cut this by about a third.
9. Team and tools
• Programmer: Luau, DataStores, UI.
• Builder or 3D artist: town, shop interiors, props (Blender or Studio).
• UI and 2D artist: icons, logo, thumbnails (the icon work already done can be reused for style reference).
• Sound: licensed or original audio; check Roblox's audio rules.
• Playtesters: at least 10 to 20 real players before launch.
10. Launch plan
• Create a strong icon and 3 to 5 thumbnails that show a dramatic before and after restore.
• Write a short clear description and use the right genre tags.
• Share short clips (restoring an item, a rare reveal, an auction) on social platforms.
• Run a launch-week event with a limited cosmetic to encourage first-day play.
• Gather feedback in a community space and fix issues quickly.
11. Risks and mitigations
Risk
Mitigation
Most Roblox games earn very little
Treat it as a bet; ship a small polished version first and measure
Core loop gets repetitive
Variety in minigames, auctions, events, and collection goals
Economy inflation
Server-side values, sinks (upgrades, fees), and regular tuning
Trading scams and exploits
Launch trading late, with limits, confirmation and logs
Scope creep
Hold the roadmap; add features only after retention is proven
Weak first impression
Spend extra time on the tutorial, thumbnail and first minute
12. Success metrics
• Tutorial completion rate
• Day-1 and Day-7 retention
• Average session length
• Sales per session and cash flow (to spot inflation)
• Conversion rate on cosmetic purchases
• Auction and market participation
13. Asset checklist
Environment: street pieces, shop exteriors (6 colors), shop interiors (4 tiers), auction house, estate sale lot, dumpster alley, trees, lamps, benches, signs.
Items: 80 base items in 8 categories, each with Wrecked to Mint variants (a dirt or damage overlay can do most of the work).
Tools and workbench: brushes, cloths, polish, screwdrivers, paint cans, a lamp, a tool rack.
Effects: sparkles, dust clouds, rarity glows, cash pop-ups, confetti, gavel hit.
UI: panels, buttons, inventory grid, rarity borders, minigame frames, auction bid panel, market listing UI, quest list, collection book, settings, shop upgrade menu.
Characters: 6 to 8 NPC customers, a tutorial guide NPC, an auctioneer, and a seller.
Audio: music (shop, town, auction), tool sounds, UI sounds, cash register, rare reveal, crowd cheer.
Marketing: game icon, logo, 3 to 5 thumbnails, pass and product icons.
14. What to do next
1. Build the prototype: one shop, 10 items, two minigames.
2. Test it with 5 to 10 players and watch where they get confused or bored.
3. Only after that, expand to the full vertical slice.
