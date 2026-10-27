# Publish Thrift Flip

The code and upload files are prepared. Roblox must create the final asset IDs under the account or group that owns the experience.

## Upload files

In Creator Dashboard, set the experience icon to `assets/marketing/experience-icon.png`. Add these thumbnails in order:

1. `assets/marketing/thumbnail-find-rare-treasures.png`
2. `assets/marketing/thumbnail-restore-display-sell.png`
3. `assets/marketing/thumbnail-key-art.png`

Upload every WAV in `assets/audio` through the experience's Asset Manager. Copy each resulting numeric ID into the matching key in `src/shared/AssetConfig.luau`. All thirteen WAV files are original, generated project audio. Do not copy the catalog page ID or an audio preview URL.

IDs such as `12345678901` in examples are placeholders, not Roblox assets. Every configured value must be the numeric ID copied from the matching uploaded **Audio** asset.

After entering the IDs, run:

```sh
python3 tools/release_check.py --require-uploaded-assets
python3 tools/build.py
```

On Windows, the release check automatically finds `luau.exe` and `luau-compile.exe` on `PATH`. If the optional Luau CLI is not installed, it skips the command-line unit tests with a clear warning and still validates the assets and generated place. Roblox Studio testing remains required either way.

Create the three game passes and one developer product listed in `docs/MONETIZATION.md`, then replace their `Id = 0` values in `src/shared/LiveConfig.luau`. Until then, Store shows reviewable previews and never opens a purchase prompt.

Open `dist/ThriftFlip.rbxlx` in the current Roblox Studio and publish it to a private test experience. Set the server size to eight players.

## Optional Epic Silver Fountain

Roblox does not allow a published server to fetch third-party model `145268350` through `InsertService`. To use the exact model without authorization errors, insert **Epic Silver Fountain** by MichaelFawkes once through the authenticated Studio Toolbox. Select the inserted root model and run this in the Studio Command Bar:

```lua
local selected = game:GetService("Selection"):Get()[1]
assert(selected and selected:IsA("Model"), "Select the inserted fountain model first")
for _, child in ipairs(selected:GetDescendants()) do
    if child:IsA("LuaSourceContainer") then child:Destroy() end
end
local folder = game:GetService("ServerStorage"):WaitForChild("CatalogAssets")
local old = folder:FindFirstChild("EpicSilverFountain")
if old then old:Destroy() end
selected.Name = "EpicSilverFountain"
selected.Parent = folder
```

Save or publish the place after running the command. The town automatically fits this model to the plaza. If it is absent, the bundled fountain is used without making a blocked network request.

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
