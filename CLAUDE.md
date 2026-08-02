# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is mimikun's personal [WezTerm](https://wezfurlong.org/wezterm/) terminal emulator configuration, written entirely in Lua. It targets multiple machines and OSes (macOS Intel/Apple Silicon, Linux, Windows, WSL) from a single codebase, branching behavior on hostname and OS at runtime.

## Commands

Lint/format tooling is run directly (no wrapper scripts):

```bash
stylua .          # Format Lua (config in stylua.toml: 2-space indent, 120 col, double quotes)
stylua --check .  # Check formatting without writing
selene .          # Lint Lua (config in selene.toml)
typos             # Spell-check
```

Git/workflow helpers live in `Taskfile.yml` (run with [Task](https://taskfile.dev/)):

```bash
task              # List all tasks
task pab          # Create a patch-YYYYMMDD branch
task smas         # Switch to master branch
task push         # Push to origin master (MAIN_BRANCH=master)
task morning-routine  # clean-fetch → delete patch branches → pull → new patch branch
```

There is no build/test step — WezTerm loads `wezterm.lua` directly. To verify changes, reload the config inside WezTerm (or restart it) and check the debug overlay for load errors.

## Architecture

### Entry point (`wezterm.lua`)

`wezterm.lua` is the only file WezTerm loads directly. It:

1. Extends `package.path` so modules resolve from `lua/` and `lua/plugins/` (e.g. `require("config.colors")` → `lua/config/colors.lua`, `require("plugins.tabline-wez")` → `lua/plugins/tabline-wez/init.lua`).
2. Builds the `config` object via `wezterm.config_builder()`.
3. Loads every config/plugin module through a `safe_require` helper that `pcall`s the module and, if it returned a function, calls it with `config`. Failures are logged, not fatal — a broken module degrades gracefully instead of breaking the whole config.
4. Returns the mutated `config` table.

### Module convention

Almost every module under `lua/config/` and `lua/plugins/` returns a **function that takes `config` and mutates it in place** (side effects on the shared config table), rather than returning a value. `safe_require` depends on this contract. The exceptions are `lua/config/global.lua` and `lua/utils/log.lua`, which return plain tables.

### Runtime host/OS detection (`lua/config/global.lua`)

This is the central switchboard. It returns a table of booleans derived from `wezterm.target_triple` and `wezterm.hostname()`:

- OS flags: `is_intel_mac`, `is_m_mac`, `is_linux`, `is_windows`, `is_wsl`.
- Host flags: `is_azusa`, `is_home` (Wakamo), and `is_human_rights`.
- `is_human_rights` is true only for hostnames listed in the `human_rights_infos` allowlist. Machines in this list get "premium" features (currently the `kabegami` wallpaper). Note: WezTerm cannot read system info, so this is a hardcoded per-host allowlist keyed on hostname — add new machines there.
- Also exposes path helpers: `home`, `config_dir`, `path_sep` (OS-aware).

Feature gating in `wezterm.lua` reads these flags — e.g. `config.kabegami` loads only when `is_human_rights`, and `config.menu` loads only when **not** `is_azusa`.

### Feature modules (`lua/config/`)

Split by concern — `colors`, `appearance`, `window`, `fonts`, `keyboard`, `mouse`, `programs`, `menu`, `kabegami`, `share_mode`. Load order in `wezterm.lua` is intentional; keep new modules in a sensible position. `kabegami.lua` (wallpaper) selects an image from `~/.kabegami/random/` and only applies it on human-rights hosts.

`share_mode.lua` is the exception to the `function(config)` convention: it returns a plain table of toggle actions (like `utils/log.lua`) and registers an `augment-command-palette` handler as a side effect of being required, so `wezterm.lua` requires it directly rather than through `safe_require`. It backs the screen-share toggles (`LEADER-s` all, `LEADER-o` opacity, `LEADER-b` wallpaper, plus command palette entries) by flipping flags in `wezterm.GLOBAL` and calling `wezterm.reload_configuration()`. Consequently `window.lua` and `kabegami.lua` read those flags via `global.is_opaque()` / `global.is_kabegami_disabled()` instead of hardcoding — do not "simplify" the opacity back to a constant. The reload-based design is deliberate: `window:set_config_overrides()` cannot unset `window_background_image` once the config file sets it (wezterm/wezterm#5240).

### Plugins (`lua/plugins/`)

Local wrappers around remote WezTerm plugins pulled via `wezterm.plugin.require("<git url>")` (e.g. `tabline.wez`, `battery.wez`). `tabline-wez/` is split into `init` / `options` / `sections`, with `options` and `sections` themselves following the `function(config)` convention.

### Utilities (`lua/utils/log.lua`)

Debug helpers called at the end of `wezterm.lua`: `debug_log_print` (dumps host info and enables `debug_key_events`), `show_plugin_list`, plus commented-out `update_all_plugins` / `reload_config` toggles.

## Conventions

- Comments and docs in English; inline Japanese comments exist in keymap files (`keyboard.lua`) explaining specific bindings — preserve them.
- Modules commonly cite their source with a `-- ref: <url>` comment at the top. Keep these when adapting upstream code.
- `master` is the main branch; day-to-day work happens on `patch-YYYYMMDD` branches created via `task pab`.
