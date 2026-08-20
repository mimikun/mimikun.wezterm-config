-- How the window background renders. What that background *is* -- which image,
-- or none -- is decided in config/kabegami.lua and config/kabegami_mode.lua.
--
-- Opacity and the image's hue/saturation/brightness live together because they
-- are the same kind of knob: both adjust how readable text stays on top of
-- whatever is behind it. Keeping them apart had spread window_background_* over
-- three files.
--
-- Applied unconditionally. Opacity matters on every host, and setting
-- window_background_image_hsb without an image is inert, so this module does
-- not need to know whether there is a wallpaper.
local global = require("config.global")

local function background(config)
  -- Flipped by the screen-share toggle in config/share_mode.lua; read through
  -- the accessor so a reload picks up the current value. Do not "simplify"
  -- this back to a constant.
  config.window_background_opacity = global.is_opaque() and 1.0 or 0.93

  -- Dark enough that terminal text stays legible over the wallpaper.
  config.window_background_image_hsb = {
    hue = 1.0,
    saturation = 1.0,
    brightness = 0.07,
  }
end

return background
