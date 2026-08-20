-- Applies the wallpaper. Which image that is -- and whether there is one at
-- all -- is decided in config/kabegami_mode.lua.
local global = require("config.global")
local mode = require("config.kabegami_mode")

local function kabegami(config)
  if not global.is_human_rights or global.is_kabegami_disabled() then
    return
  end

  local image = mode.current_image()
  if image == nil then
    return
  end

  config.window_background_image = image
  config.window_background_image_hsb = {
    hue = 1.0,
    saturation = 1.0,
    brightness = 0.07,
  }
end

return kabegami
