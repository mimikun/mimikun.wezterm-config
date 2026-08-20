-- The command palette's extra entries, gathered in one place.
-- ref: https://wezterm.org/config/lua/window-events/augment-command-palette.html
--
-- One augment-command-palette handler, registered here, so that the question of
-- what WezTerm does with the return values of two handlers never has to be
-- answered. Feature modules expose a `palette_entries` table and stay unaware
-- of the palette; this module knows nothing about what the entries do. Before
-- this, the wallpaper entries were registered from share_mode.lua, which had
-- nothing to do with sharing a screen.
--
-- Required for its side effect, like utils/log.lua: it registers an event
-- handler rather than returning a function(config).
local wezterm = require("wezterm")

local sources = {
  require("config.share_mode"),
  require("config.kabegami.mode"),
}

wezterm.on("augment-command-palette", function()
  local entries = {}
  for _, source in ipairs(sources) do
    for _, entry in ipairs(source.palette_entries or {}) do
      table.insert(entries, entry)
    end
  end
  return entries
end)

return {}
