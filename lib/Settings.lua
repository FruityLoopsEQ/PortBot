local Logger = require("PortBot.lib.Logger")
local IniFile = require("PortBot.lib.IniFile")

local Defaults = {
 blockTeleport = true,
 acceptGroupInvite = true
}

---@class Settings
---@field blockTeleport boolean
---@field acceptGroupInvite boolean
---@field configFilePath string
local Settings = {
  configFilePath = ""
}
Settings.__index = Settings

---@param blockTeleport boolean
---@param acceptGroupInvite boolean
---@return Settings
function Settings.new(blockTeleport, acceptGroupInvite)
  local settings = {}
  setmetatable(settings, Settings)

  settings.blockTeleport = blockTeleport
  settings.acceptGroupInvite = acceptGroupInvite

  return settings
end

--- @return Settings
function Settings.load()
  Logger.Info("Loading settings")

  local settings = nil

  local section = IniFile.getSection(Settings.configFilePath, "Settings")

  if not section then
    settings = Settings.new(Defaults.blockTeleport, Defaults.acceptGroupInvite)
  else
    local blockTeleport = section.BlockTeleport
    local acceptGroupInvite = section.AcceptGroupInvite

    if blockTeleport == nil then
      blockTeleport = Defaults.blockTeleport
    end

    if acceptGroupInvite == nil then
      acceptGroupInvite = Defaults.acceptGroupInvite
    end

    settings = Settings.new(blockTeleport, acceptGroupInvite)
  end

  Settings.write(settings)

  Logger.Debug("Settings loaded")
  return settings
end


---@param settings Settings
function Settings.write(settings)
  Logger.Debug("Writing settings")

  IniFile.write(Settings.configFilePath, "Settings", "BlockTeleport", settings.blockTeleport)
  IniFile.write(Settings.configFilePath, "Settings", "AcceptGroupInvite", settings.acceptGroupInvite)
end


return Settings
