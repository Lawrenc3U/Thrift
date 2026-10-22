# Thrift Flip commerce setup

The game ships with a working cosmetic storefront, receipt processing, permanent ownership, and purchase restoration. Roblox purchases remain hidden until creator-owned IDs are configured in `src/shared/LiveConfig.luau`.

## Recommended launch catalog

Create these in Creator Dashboard, then add their numeric IDs to `LiveConfig.Passes` or `LiveConfig.Products`:

| Offer | Type | Suggested price | Permanent reward |
| --- | --- | ---: | --- |
| Rose Cottage | Game pass | R$49 | Cute shop theme |
| Neon Tomorrow | Game pass | R$79 | Futuristic shop theme |
| Curator Pack | Game pass | R$99 | Antique theme and Curator title |
| Seasonal Window Set | Developer product | R$29 | A named seasonal decoration |

Every paid offer must describe the exact cosmetic reward. Do not sell random finds, restoration scores, cash, inventory capacity, or auction advantages. Those offers weaken the collection loop and create refund and trust problems.

## Conversion path

The in-game **STORE** quick action opens the cosmetic boutique. Players also encounter themes and decorations while upgrading their shop, so the paid catalog extends an activity they already understand. Configure a small launch catalog first, review purchase completion and retention analytics, then add seasonal visual sets only when the existing catalog converts.

Before launch, upload creator-owned icons and audio, configure the IDs, purchase every offer in a private test experience, rejoin, and verify permanent ownership and duplicate receipt handling.
