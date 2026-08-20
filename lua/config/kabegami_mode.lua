-- Wallpaper modes. Fixed keeps one image; random draws from ~/.kabegami/random.
--
-- The two modes are not invented here: i3 already draws the same line for the
-- same directory, with `setwallpaper <file>` and `setrandom ~/.kabegami/random`,
-- so this reuses that split rather than adding a third way to describe it.
--
-- The images cannot be redistributed, so they are placed by hand on each
-- machine and are simply absent on some of them -- the WSL side of this host
-- has none at all. Every path is therefore optional: with nothing to show,
-- no wallpaper is set, instead of pointing window_background_image at a file
-- that is not there. The old hand-written table had already drifted that way,
-- declaring butasan_nesoberi.png and azusa_by_sentariba.png, neither of which
-- exists (the second is azusa-sentariba.png, with a hyphen, in the parent
-- directory). Globbing the directory cannot drift.
--
-- State lives in wezterm.GLOBAL, which survives config reloads but not a
-- restart -- the same reason config/share_mode.lua uses it. The fixed image
-- declared below is what a restart falls back to.
local wezterm = require("wezterm")
local global = require("config.global")

local M = {}

local kabegami_dir = table.concat({ global.home, ".kabegami" }, global.path_sep)
local random_dir = table.concat({ kabegami_dir, "random" }, global.path_sep)

--- The image fixed mode starts from. Editing this line is how that choice is
--- made; living in the config file is also what carries it across restarts.
M.fixed_image = table.concat({ random_dir, "azusa_by_namatume.png" }, global.path_sep)

-- wezterm.glob is case-sensitive, and the collection holds both .jpg and .JPG.
local image_patterns = { "*.png", "*.PNG", "*.jpg", "*.JPG", "*.jpeg", "*.JPEG", "*.webp" }

---@param path string
---@return boolean
local function exists(path)
  return #wezterm.glob(path) > 0
end

---@return string[] absolute paths of every image directly under random/
local function random_candidates()
  local found = {}
  for _, pattern in ipairs(image_patterns) do
    for _, path in ipairs(wezterm.glob(random_dir .. global.path_sep .. pattern)) do
      table.insert(found, path)
    end
  end
  table.sort(found)
  return found
end

--- Public so that the "it actually changes" behaviour can be asserted without
--- a running GUI; see AGENTS.md on verifying computed values.
---@return string|nil a different image from the one on screen, or nil if none
function M.next_image()
  local files = random_candidates()
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
  if wezterm.GLOBAL.kabegami_mode == "random" then
    if wezterm.GLOBAL.kabegami_image == nil then
      wezterm.GLOBAL.kabegami_image = M.next_image()
    end
    local image = wezterm.GLOBAL.kabegami_image
    return image ~= nil and exists(image) and image or nil
  end

  local image = wezterm.GLOBAL.kabegami_pinned or M.fixed_image
  return exists(image) and image or nil
end

--- Switch to random mode and draw a new image. Pressing this again redraws.
M.shuffle = wezterm.action_callback(function()
  wezterm.GLOBAL.kabegami_mode = "random"
  wezterm.GLOBAL.kabegami_image = M.next_image()
  wezterm.reload_configuration()
end)

--- Switch to fixed mode, keeping whatever is on screen right now. Shuffle until
--- an image is worth keeping, then press this to stop it changing.
M.fix = wezterm.action_callback(function()
  wezterm.GLOBAL.kabegami_pinned = M.current_image()
  wezterm.GLOBAL.kabegami_mode = "fixed"
  wezterm.reload_configuration()
end)

return M
