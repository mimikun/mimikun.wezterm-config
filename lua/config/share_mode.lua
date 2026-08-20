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
local kabegami_mode = require("config.kabegami_mode")

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

-- ref: https://wezterm.org/config/lua/window-events/augment-command-palette.html
wezterm.on("augment-command-palette", function()
  return {
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
    -- The wallpaper mode entries are registered from here rather than from
    -- config/kabegami_mode.lua because a second augment-command-palette
    -- handler would be a guess about whether WezTerm merges what they return.
    -- One handler, one place.
    {
      brief = "Wallpaper: random mode (draw a new image)",
      icon = "md_shuffle_variant",
      action = kabegami_mode.shuffle,
    },
    {
      brief = "Wallpaper: fixed mode (keep the current image)",
      icon = "md_pin",
      action = kabegami_mode.fix,
    },
  }
end)

-- Returns a table with the toggle actions
return M
