# Thrift Flip commerce setup

The game ships with a working cosmetic storefront, receipt processing, permanent ownership, and purchase restoration. Roblox purchases remain hidden until creator-owned IDs are configured in `src/shared/LiveConfig.luau`.

## Launch catalog included in the game

Create these in Creator Dashboard, then add their numeric IDs to `LiveConfig.Passes` or `LiveConfig.Products`:

| Offer | Type | Suggested price | Permanent reward |
| --- | --- | ---: | --- |
| Rose Gold Boutique | Game pass | R$49 | Exclusive Rose Gold theme, curtains, plants and title |
| Neon Night Market | Game pass | R$79 | Exclusive Neon Night theme, neon sign and title |
| Curator Club | Game pass | R$129 | Exclusive gallery theme, trophy, poster and title |
| Thrift Street Supporter | Developer product | R$19 | Supporter title and Second Chances poster |

The four offers already appear as disabled previews in Studio. Create each offer under the same owner as the experience, then replace its `Id = 0` value in `src/shared/LiveConfig.luau`. Suggested prices are planning guidance; live buttons display the price returned by Roblox.

Every paid offer must describe the exact cosmetic reward. Do not sell random finds, restoration scores, cash, inventory capacity, or auction advantages. Those offers weaken the collection loop and create refund and trust problems.

## Conversion path

The in-game **STORE** quick action opens the cosmetic boutique. Players also encounter themes and decorations while upgrading their shop, so the paid catalog extends an activity they already understand. Configure a small launch catalog first, review purchase completion and retention analytics, then add seasonal visual sets only when the existing catalog converts.

Before launch, upload creator-owned icons and audio, configure the IDs, purchase every offer in a private test experience, rejoin, and verify permanent ownership and duplicate receipt handling. Run `python3 tools/release_check.py --require-uploaded-assets` after configuration.
