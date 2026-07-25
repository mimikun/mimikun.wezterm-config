local function window(config)
  config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
  -- NOTE: Temporarily disabled. Revert this commit to restore
  --config.window_background_opacity = 0.93
end

return window
