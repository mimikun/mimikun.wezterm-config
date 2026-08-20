-- Screen share mode: toggles that make the terminal readable for other people.
-- ref: https://github.com/wezterm/wezterm/issues/5240
--
-- NOTE: The usual toggle idiom is window:set_config_overrides(), but it cannot
-- turn the wallpaper off. Assigning nil to a Lua table key is the same as the
-- key being absent, so it only drops the override and restores the value from
-- the config file -- there is no way to unset window_background_image once the
-- config file has set it. So both toggles flip a flag in wezterm.GLOBAL and
-- reload the config instead; GLOBAL survives config reloads by design.
local wezterm = require("wezterm")

local M = {}

---@param key string key in wezterm.GLOBAL to flip
---@return unknown action a wezterm action_callback
local function toggle(key)
  return wezterm.action_callback(function()
    wezterm.GLOBAL[key] = not wezterm.GLOBAL[key]
    wezterm.reload_configuration()
  end)
end

M.toggle_opacity = toggle("opaque_mode")
M.toggle_kabegami = toggle("kabegami_disabled")

-- Turn both off only when both are already on, so starting a screen share is
-- always a single keystroke no matter which individual toggle was flipped.
M.toggle_all = wezterm.action_callback(function()
  local enable = not (wezterm.GLOBAL.opaque_mode and wezterm.GLOBAL.kabegami_disabled)
  wezterm.GLOBAL.opaque_mode = enable
  wezterm.GLOBAL.kabegami_disabled = enable
  wezterm.reload_configuration()
end)

--- Entries for the command palette. Registered by config/palette.lua, which
--- owns the single augment-command-palette handler.
M.palette_entries = {
  {
    brief = "Toggle screen share mode (opaque + no wallpaper)",
    icon = "md_monitor_share",
    action = M.toggle_all,
  },
  {
    brief = "Toggle window background opacity",
    icon = "md_circle_opacity",
    action = M.toggle_opacity,
  },
  {
    brief = "Toggle wallpaper (kabegami)",
    icon = "md_image_off",
    action = M.toggle_kabegami,
  },
}

-- Returns a table with the toggle actions
return M
