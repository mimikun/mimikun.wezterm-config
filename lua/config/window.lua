local global = require("config.global")

local function window(config)
  config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
  config.window_background_opacity = global.is_opaque() and 1.0 or 0.93
end

return window
