-- Applies the wallpaper. Which image that is -- and whether there is one at
-- all -- is decided in ./mode.lua; how it renders, in config/background.lua.
--
-- This is the module WezTerm's config loading enters through, so it keeps the
-- function(config) shape the other config modules have. Everything that is not
-- "put the image into config" lives next to it rather than in it.
local global = require("config.global")
local mode = require("config.kabegami.mode")

local function kabegami(config)
  if not global.is_human_rights or global.is_kabegami_disabled() then
    return
  end

  local image = mode.current_image()
  if image == nil then
    return
  end

  config.window_background_image = image
end

return kabegami
