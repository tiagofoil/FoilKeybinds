# Publishing checklist

Steps only Tiago can do. Nothing here has been done yet.

1. Create the public GitHub repo, then `git remote add origin <url>` and `git push -u origin main`.
2. Create the CurseForge project "Foil Keybinds" (World of Warcraft, addon). Note its numeric Project ID.
3. Create the Wago Addons project "Foil Keybinds". Note its Wago ID (the short id in the project URL/settings).
4. Create API keys and add them as GitHub repo secrets (Settings, Secrets and variables, Actions):
   - `CF_API_KEY`: from https://legacy.curseforge.com/account/api-tokens
   - `WAGO_API_TOKEN`: from https://addons.wago.io/account/apikeys
   - `GITHUB_TOKEN` is provided by Actions; no setup needed.
5. Add these lines to `FoilKeybinds/FoilKeybinds.toc`, with the real IDs:

       ## X-Curse-Project-ID: 123456
       ## X-Wago-ID: abcdEF12

   Also bump `## Version:` (or replace it with `## Version: @project-version@` so the packager fills it from the tag).
6. Push a tag: `git tag v1.0.0 && git push origin v1.0.0`. The Release workflow runs the tests, then packages and uploads to CurseForge, Wago and GitHub Releases.

Tip: a tag like `v1.0.0-beta1` is uploaded as a beta, useful for a first dry run.
