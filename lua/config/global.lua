local wezterm = require("wezterm")

local global = {}
local os_name = wezterm.target_triple
local hostname = wezterm.hostname()

---@type table
local human_rights_infos = {
  ["Azusa"] = true,
  ["Wakamo"] = true,
  ["Izuna"] = true,
}

-- NOTE: wezterm cannot get sysinfo
---@return boolean
local check_human_rights = function()
  return human_rights_infos[hostname] or false
end

---@type boolean
local is_human_rights = check_human_rights()

global.check_human_rights = check_human_rights
global.hostname = hostname
global.is_intel_mac = os_name == "x86_64-apple-darwin"
-- Apple Silicon
global.is_m_mac = os_name == "aarch64-apple-darwin"
global.is_linux = os_name == "x86_64-unknown-linux-gnu"
global.is_windows = os_name == "x86_64-pc-windows-msvc"
global.is_wsl = wezterm.running_under_wsl()
global.is_azusa = hostname == "Azusa"
global.is_human_rights = is_human_rights
global.is_home = hostname == "Wakamo"
global.home = wezterm.home_dir
global.config_dir = wezterm.config_dir
global.config_file = wezterm.config_file
global.version = wezterm.version
global.exec_dir = wezterm.executable_dir
global.path_sep = global.is_windows and "\\" or "/"
global.SPACE_1 = " "
global.SPACE_3 = "   "

-- NOTE: Runtime toggles for screen sharing, flipped from config/share_mode.lua.
-- State lives in wezterm.GLOBAL so it survives config reloads. These are
-- functions, not booleans, because the command palette handlers run outside of
-- config evaluation and must read the current value each time.
---@return boolean
global.is_opaque = function()
  return wezterm.GLOBAL.opaque_mode == true
end

---@return boolean
global.is_kabegami_disabled = function()
  return wezterm.GLOBAL.kabegami_disabled == true
end

return global
