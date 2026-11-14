# Settings panel: how popular addons do it (2026-11-13)

Short survey before building the Foil Keybinds settings. Code read from GitHub raw files and from
addons installed on this WoW Forever client (real code that runs on the same API).

## Two families

| Approach | Who | How |
|---|---|---|
| Ace3 AceConfig | Bartender4, OmniCC, BigWigs, Plater, WeakAuras (partly) | Options as a declarative table, `AceConfig-3.0:RegisterOptionsTable`, `AceConfigDialog:Open` for a standalone window and `AddToBlizOptions` for the game list. Profiles come free from `AceDBOptions-3.0`. |
| Own framework window | Details! (DetailsFramework `BuildMenu`), ElvUI, EllesmereUI | A themed window that matches the addon. The game's AddOns list holds only a small canvas page with an "Open" button. |
| Native Blizzard Settings | Small modern addons (CozyFire, Shortest Path Forever, ForeverCore) | `Settings.RegisterVerticalLayoutCategory` + `RegisterAddOnSetting` / `RegisterProxySetting` + `CreateCheckbox`, `CreateSliderInitializer`, `CreateDropdownInitializer`. |

## Findings

- Bartender4 opens AceConfigDialog from `/bt` and refuses in combat; profiles are the AceDBOptions table.
  OmniCC puts themes, rules and profiles in tabs and has a separate preview dialog for live feedback.
- Details! builds every option with its own framework (`BuildMenuVolatile` with slider, switch and
  dropdown templates), so the look matches the meter.
- EllesmereUI (the owner's UI) registers `Settings.RegisterCanvasLayoutCategory(panel, "EllesmereUI")`
  where the panel is only a button that hides `SettingsPanel` and opens its own window on the next frame.
- Native vertical layout on this client: sliders use `Settings.CreateSliderOptions(min, max, step)` and
  `SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, fn)` for the value text ("100%");
  dropdowns use `Settings.CreateControlTextContainer()`; buttons use `CreateSettingsButtonInitializer`.
  Live preview is `setting:SetValueChangedCallback(fn)`.
- **WoW Forever caveat:** Shortest Path Forever notes that `Settings.OpenToCategory` and
  `C_SettingsUtil.OpenSettingsPanel` refuse a direct call from addon code (cjber/forever-core#333);
  ForeverCore wraps the opener in `securecallfunction` and wraps the vertical layout builders in
  `CreateSecureDelegate` to avoid taint from the gamepad navigation (cjber/tweaks-forever#446).
- Addon compartment toggle: LibDBIcon (shipped by CozyFire and Questie here) calls
  `AddonCompartmentFrame:RegisterAddon(data)` to show and removes the entry from
  `AddonCompartmentFrame.registeredAddons` plus `UpdateDisplay()` to hide. A TOC `AddonCompartmentFunc`
  entry cannot be toggled.
- Common option sets: scale, font size, opacity, lock, show minimap/compartment button, reset to
  defaults, profiles. Slider rows show the value next to the bar; reset is a button at the bottom.

## Decision for Foil Keybinds

The spec forbids external libraries, so no Ace3. The native vertical layout would need the Forever
secure opener and delegate workarounds to open it from inside the addon, and it hides the main window
behind `SettingsPanel` (no live preview of the window scale). So: one themed content frame built with
`Theme.lua`, shown in our own movable window (gear button, `/fkb config`) and re-parented into a themed
canvas registered with `Settings.RegisterCanvasLayoutCategory` + `Settings.RegisterAddOnCategory` for the
Options > AddOns list. Same pattern as EllesmereUI, but the controls are on the canvas too. No call to
`Settings.OpenToCategory` is needed. Compartment entry registered at runtime so it can be toggled.
Profiles are out of scope (settings are account-wide, layouts are per character already).

## Sources

- Bartender4 options: https://raw.githubusercontent.com/Nevcairiel/Bartender4/master/Options/Options.lua
- OmniCC config: https://raw.githubusercontent.com/tullamods/OmniCC/main/OmniCC_Config/options.lua
- OmniCC preview: https://raw.githubusercontent.com/tullamods/OmniCC/main/OmniCC_Config/preview.lua
- Details! options: https://raw.githubusercontent.com/Tercioo/Details-Damage-Meter/master/frames/window_options2.lua
- Installed on this client (Interface\AddOns): EllesmereUI/EllesmereUI.lua (canvas launcher),
  CozyFire/Options.lua (vertical layout, proxy settings, slider formatter),
  ShortestPathForever/UI/Settings.lua (sliders, dropdowns, buttons, Forever opener note),
  ForeverCore/Core/OpenSettings.lua and ForeverCore/UI/ForeverFamily.lua (secure opener and delegates),
  Auctionator/Source/Config/Mixins/PanelConfig.lua (canvas with OnCommit/OnDefault/OnRefresh),
  CozyFire/Libs/LibDBIcon-1.0 (compartment register/remove).
- Blizzard Settings API reference: https://warcraft.wiki.gg/wiki/Settings_API
