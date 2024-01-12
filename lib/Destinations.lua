local mq = require("mq")
local Logger = require("PortBot.lib.Logger")
local IniFile = require("PortBot.lib.IniFile")
local Spell = require("PortBot.lib.Spell")

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

---@class Destination
---@field name string
---@field spell Spell
---@field aliases string[]
local Destination = {}
Destination.__index = Destination

---@param name string
---@param spell Spell
---@param aliases string[] | nil
---@return Destination
function Destination.new(name, spell, aliases)
  aliases = aliases or {}

  local destination = {}
  setmetatable(destination, Destination)

  destination.name = name
  destination.spell = spell
  destination.aliases = aliases

  return destination
end

---@param callback fun(destination: Destination): any
function Destination:register(callback)
  local eventTemplate = "destination-%s"
  local matchTemplate = "#1# tells the group, '%s'"

  Logger.Debug("Registering destination(%s)", self.name)

  local onEvent = function()
    Logger.Info("Handling destination %s", self.name)
    callback(self)
  end

  mq.event(eventTemplate:format(self.name), matchTemplate:format(self.name), onEvent)

  for _, alias in ipairs(self.aliases) do
    mq.event(eventTemplate:format(alias), matchTemplate:format(alias), onEvent)
  end
end

function Destination:anyAliases()
  return next(self.aliases)
end

---@param name string
---@param value string
---@return Destination
function Destination.parse(name, value)
    local valueParts = splitString(value, "|")

    local spellName = valueParts[1]
    local aliasParts = valueParts[2]
    local aliases = {}

    if aliasParts then
      aliases = splitString(aliasParts, ",")
    end

    local spell = Spell.build(spellName)
    return Destination.new(name, spell, aliases)
end

---@class Destinations
---@field configFilePath string
---@field members Destination[]
local Destinations = {
  configFilePath = ""
}
Destinations.__index = Destinations

---@return Destinations
function Destinations.new()
  local destinations = {}
  setmetatable(destinations, Destinations)

  destinations.members = {}

  return destinations
end

---@return Destinations
function Destinations.load()
  local configFilePath = Destinations.configFilePath

  Logger.Info("Loading destinations")
  local destinations = Destinations.new()

  local section = IniFile.getSection(configFilePath, "Destinations")

  assert(section, string.format("Couldn't find [Destinations] section in %s", configFilePath))

  for name, value in pairs(section) do
    local destination = Destination.parse(name, value)

    table.insert(destinations.members, destination)
  end

  Logger.Debug("Destinations loaded")
  return destinations
end

---@param callback fun(destination: Destination): any
function Destinations:register(callback)
  for _, destination in ipairs(self.members) do
    destination:register(callback)
  end
end

return Destinations
