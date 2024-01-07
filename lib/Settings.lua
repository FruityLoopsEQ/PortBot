local mq = require("mq")
local Logger = require("PortBot.lib.Logger")
local IniFile = require("PortBot.lib.IniFile")

CONFIG_FILE_PATH = mq.configDir .. "/PortBot.ini"

local Defaults = {
 blockTeleport = true,
 acceptGroupInvite = true
}

---@class Settings
---@field blockTeleport boolean
---@field acceptGroupInvite boolean
Settings = {
  __tostring = function(settings)
    local blockTeleport = settings.blockTeleport
    local acceptGroupInvite = settings.acceptGroupInvite

    local template = "Settings: blockTeleport=%s, acceptGroupInvite=%s"

    return string.format(template, blockTeleport, acceptGroupInvite)
  end
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
  Logger.Info("Getting settings")

  local settings = nil

  local section = IniFile.getSection(CONFIG_FILE_PATH, "Settings")

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

  return settings
end


---@param settings Settings
function Settings.write(settings)
  Logger.Debug("Writing %s", settings)

  IniFile.write(CONFIG_FILE_PATH, "Settings", "BlockTeleport", settings.blockTeleport)
  IniFile.write(CONFIG_FILE_PATH, "Settings", "AcceptGroupInvite", settings.acceptGroupInvite)
end


return Settings
