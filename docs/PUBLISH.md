# Publish Thrift Flip

The code and upload files are prepared. Roblox must create the final asset IDs under the account or group that owns the experience.

## Upload files

In Creator Dashboard, set the experience icon to `assets/marketing/experience-icon.png`. Add these thumbnails in order:

1. `assets/marketing/thumbnail-find-rare-treasures.png`
2. `assets/marketing/thumbnail-restore-display-sell.png`
3. `assets/marketing/thumbnail-key-art.png`

Upload every WAV in `assets/audio` through the experience's Asset Manager. Copy each resulting numeric ID into the matching key in `src/shared/AssetConfig.luau`. All thirteen WAV files are original, generated project audio. Do not copy the catalog page ID or an audio preview URL.

After entering the IDs, run:

```sh
python3 tools/release_check.py --require-uploaded-assets
python3 tools/build.py
```

Create the three game passes and one developer product listed in `docs/MONETIZATION.md`, then replace their `Id = 0` values in `src/shared/LiveConfig.luau`. Until then, Store shows reviewable previews and never opens a purchase prompt.

Open `dist/ThriftFlip.rbxlx` in the current Roblox Studio and publish it to a private test experience. Set the server size to eight players.

## Required Roblox checks

- Finish the complete tutorial with mouse and touch emulation: find, inspect, restore, display, and sell.
- Confirm the search animation completes and the real server-awarded item appears in the rarity reveal.
- Check every travel button, ProximityPrompt, modal, safe area, and scrolling panel at phone, tablet, and desktop sizes.
- Start a local server with at least two clients. Confirm separate shop ownership, visits, offers, trading, auctions, and auction settlement.
- In a separate test experience, enable Studio API access and set `Config.StudioPracticeMode` to `false`. Verify leave/rejoin persistence and overlapping-server session locks. Restore the setting afterward.
- Test an eight-player server and a low-end mobile device. Record join time, client memory, server memory, and frame rate in the MicroProfiler and Developer Console.
- Check the Output window for red errors and failed asset loads. Test all uploaded audio while signed in as a normal player.
- Complete a private playtest before changing the experience visibility to Public.

The automated release check cannot replace these Roblox engine and account checks.
