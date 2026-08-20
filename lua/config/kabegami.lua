-- Wallpaper modes. Fixed keeps one image; random draws from ~/.kabegami/random.
--
-- The two modes are not invented here: i3 already draws the same line for the
-- same directory, with `setwallpaper <file>` and `setrandom ~/.kabegami/random`,
-- so this reuses that split rather than adding a third way to describe it.
--
-- The single source of truth is ~/.kabegami/mode, one line:
--
--   random                          -- draw from random/ on every start
--   random/azusa_by_namatume.png    -- keep this one
--   azusa_02.jpg                    -- anything else under ~/.kabegami/
--
-- A file rather than wezterm.GLOBAL, because GLOBAL does not survive a
-- restart. Paths in it are relative to ~/.kabegami/ and always written with
-- forward slashes, so the same file means the same thing read from Windows
-- (where WezTerm runs) and from WSL (where a future editor plugin would write
-- it). Editing the line by hand is a supported way to choose.
--
-- The images cannot be redistributed, so they are placed by hand on each
-- machine and are simply absent on some of them -- the WSL side of this host
-- has none at all. Every path is therefore optional: with nothing to show,
-- no wallpaper is set, instead of pointing window_background_image at a file
-- that is not there. The hand-written table that used to live here had already
-- drifted that way, declaring butasan_nesoberi.png and azusa_by_sentariba.png,
-- neither of which exists (the second is azusa-sentariba.png, with a hyphen,
-- in the parent directory). Globbing the directory cannot drift.
local wezterm = require("wezterm")
local global = require("config.global")

local M = {}

local sep = global.path_sep
local kabegami_dir = table.concat({ global.home, ".kabegami" }, sep)
local random_dir = table.concat({ kabegami_dir, "random" }, sep)
local state_path = table.concat({ kabegami_dir, "mode" }, sep)

--- What ~/.kabegami/mode says when it is missing, empty or unreadable, which
--- is every machine that has never been switched.
M.default_state = "random/azusa_by_namatume.png"

M.RANDOM = "random"

-- wezterm.glob is case-sensitive, and the collection holds both .jpg and .JPG.
local image_patterns = { "*.png", "*.PNG", "*.jpg", "*.JPG", "*.jpeg", "*.JPEG", "*.webp" }

---@param path string
---@return boolean
local function exists(path)
  return #wezterm.glob(path) > 0
end

---@param rel string forward-slash path under ~/.kabegami/
---@return string absolute path with this platform's separator
local function absolute(rel)
  return kabegami_dir .. sep .. (rel:gsub("/", sep))
end

---@param path string absolute
---@return string|nil forward-slash path under ~/.kabegami/, nil if outside it
local function relative(path)
  local normalised = path:gsub("\\", "/")
  local prefix = kabegami_dir:gsub("\\", "/") .. "/"
  if normalised:sub(1, #prefix) ~= prefix then
    return nil
  end
  return normalised:sub(#prefix + 1)
end

---@return string contents of ~/.kabegami/mode, or the default
function M.read_state()
  local handle = io.open(state_path, "r")
  if handle == nil then
    return M.default_state
  end
  local line = handle:read("l")
  handle:close()
  if line == nil then
    return M.default_state
  end
  line = line:match("^%s*(.-)%s*$")
  return line ~= "" and line or M.default_state
end

---@param value string
local function write_state(value)
  local handle = io.open(state_path, "w")
  if handle == nil then
    -- The directory is created by hand along with the images, so a machine
    -- without it has nothing to show anyway; failing quietly keeps the
    -- keybinding from erroring on those hosts.
    wezterm.log_info("kabegami: cannot write " .. state_path)
    return
  end
  handle:write(value .. "\n")
  handle:close()
end

---@param dir string absolute
---@return string[] absolute paths of every image directly under dir
local function images_in(dir)
  local found = {}
  for _, pattern in ipairs(image_patterns) do
    for _, path in ipairs(wezterm.glob(dir .. sep .. pattern)) do
      table.insert(found, path)
    end
  end
  table.sort(found)
  return found
end

--- Public so that the "it actually changes" behaviour can be asserted without
--- a running GUI; see CLAUDE.md on verifying computed values.
---@return string|nil a different image from the one on screen, or nil if none
function M.next_image()
  local files = images_in(random_dir)
  if #files == 0 then
    return nil
  end
  if #files == 1 then
    return files[1]
  end

  -- Seeded per call: os.time() alone repeats within the same second, and two
  -- reloads in one second is exactly the case this has to survive.
  math.randomseed(os.time() + math.floor(os.clock() * 1000000))

  -- Draw until the pick differs from what is already shown, so that pressing
  -- the key visibly changes something. Bounded, because with a pathological
  -- seed an unbounded loop would hang config evaluation.
  local current = wezterm.GLOBAL.kabegami_image
  for _ = 1, 16 do
    local candidate = files[math.random(#files)]
    if candidate ~= current then
      return candidate
    end
  end
  return files[1] == current and files[2] or files[1]
end

---@return string|nil path to show, or nil for no wallpaper at all
function M.current_image()
  if M.read_state() == M.RANDOM then
    -- Which image is a per-session detail: an unrelated reload should not
    -- reshuffle the wallpaper, so it is drawn once and kept in GLOBAL.
    if wezterm.GLOBAL.kabegami_image == nil then
      wezterm.GLOBAL.kabegami_image = M.next_image()
    end
    local image = wezterm.GLOBAL.kabegami_image
    return image ~= nil and exists(image) and image or nil
  end

  local image = absolute(M.read_state())
  return exists(image) and image or nil
end

--- Switch to random mode and draw a new image. Pressing this again redraws.
M.shuffle = wezterm.action_callback(function()
  write_state(M.RANDOM)
  wezterm.GLOBAL.kabegami_image = M.next_image()
  wezterm.reload_configuration()
end)

--- Switch to fixed mode, keeping whatever is on screen right now. Shuffle until
--- an image is worth keeping, then press this to stop it changing.
M.fix = wezterm.action_callback(function()
  local shown = M.current_image()
  write_state(shown ~= nil and relative(shown) or M.default_state)
  wezterm.reload_configuration()
end)

--- Pick from every image under ~/.kabegami/, plus random mode.
M.pick = wezterm.action_callback(function(window, pane)
  local choices = { { id = M.RANDOM, label = "random (draw from random/ each start)" } }
  for _, dir in ipairs({ kabegami_dir, random_dir }) do
    for _, path in ipairs(images_in(dir)) do
      local id = relative(path)
      if id ~= nil then
        table.insert(choices, { id = id, label = id })
      end
    end
  end

  window:perform_action(
    wezterm.action.InputSelector({
      title = "Wallpaper",
      choices = choices,
      action = wezterm.action_callback(function(_, _, id)
        if id == nil then
          return
        end
        write_state(id)
        if id == M.RANDOM then
          wezterm.GLOBAL.kabegami_image = M.next_image()
        end
        wezterm.reload_configuration()
      end),
    }),
    pane
  )
end)

--- Entries for the command palette. Registered by config/palette.lua, which
--- owns the single augment-command-palette handler.
M.palette_entries = {
  {
    brief = "Wallpaper: random mode (draw a new image)",
    icon = "md_shuffle_variant",
    action = M.shuffle,
  },
  {
    brief = "Wallpaper: fixed mode (keep the current image)",
    icon = "md_pin",
    action = M.fix,
  },
  {
    brief = "Wallpaper: pick one",
    icon = "md_image_search",
    action = M.pick,
  },
}

--- Puts the chosen image into config. Called by wezterm.lua through
--- safe_require, which accepts a table with an `apply` as well as a bare
--- function -- this module has to be both, because keyboard.lua and
--- palette.lua need the actions above.
---@param config table
function M.apply(config)
  if not global.is_human_rights or global.is_kabegami_disabled() then
    return
  end

  local image = M.current_image()
  if image == nil then
    return
  end

  config.window_background_image = image
end

return M
