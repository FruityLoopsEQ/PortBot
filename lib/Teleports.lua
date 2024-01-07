local Logger = require("PortBot.lib.Logger")
local IniFile = require("PortBot.lib.IniFile")
local Destination = require("PortBot.lib.Destination")

local function splitString(inputstr, sep)
   if sep == nil then
      sep = "%s"
   end

   local t={}

   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
   end

   return t
end

---@class Teleports
---@field configFilePath string
---@field destinations Destination[]
Teleports = {
  configFilePath = ""
}
Teleports.__index = Teleports

---@return Teleports
function Teleports.new()
  local teleports = {}
  setmetatable(teleports, Teleports)

  teleports.destinations = {}

  return teleports
end

function Teleports.load()
  local configFilePath = Teleports.configFilePath

  Logger.Info("Loading teleports")
  local teleports = Teleports.new()

  local section = IniFile.getSection(configFilePath, "Teleports")

  assert(section, string.format("Couldn't find [Teleports] section in %s", configFilePath))

  for key, value in pairs(section) do
    local name = key
    local valueParts = splitString(value, "|")

    local spell = valueParts[1]
    local aliasParts = valueParts[2]
    local aliases = {}

    if aliasParts then
      aliases = splitString(aliasParts, ",")
    end

    local destination = Destination.new(name, spell, aliases)

    table.insert(teleports.destinations, destination)
  end

  Logger.Debug("Teleports loaded")
  return teleports
end

return Teleports
