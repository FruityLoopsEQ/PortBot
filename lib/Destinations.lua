local mq = require("mq")
local Logger = require("PortBot.lib.Logger")
local Spell = require("PortBot.lib.Spell")

---@class Destination
---@field zoneName string
---@field spells Spell[]
---@field aliases string[] | nil
local Destination = {}
Destination.__index = Destination

---@param zoneName string
---@param spells Spell[]
---@param aliases string[] | nil
---@return Destination
function Destination.new(zoneName, spells, aliases)
  local destination = {}
  setmetatable(destination, Destination)

  destination.zoneName = zoneName
  destination.spells = spells
  destination.aliases = aliases

  return destination
end

---@return Spell | nil
function Destination:getSpell()
  for _, spell in ipairs(self.spells) do
    if spell:isLearned() then
      return spell
    end
  end
end

---@return boolean
function Destination:hasSpell()
  return self:getSpell() ~= nil
end

---@param callback fun(destination: Destination): any
function Destination:register(callback)
  local eventTemplate = "destination-%s"
  local matchTemplate = "#1# tells the group, '%s'"

  Logger.Debug("Registering destination(%s)", self.zoneName)

  local onEvent = function()
    Logger.Info("Handling destination %s", self.zoneName)
    callback(self)
  end

  mq.event(eventTemplate:format(self.zoneName), matchTemplate:format(self.zoneName), onEvent)

  local aliases = self.aliases or {}
  for _, alias in ipairs(aliases) do
    mq.event(eventTemplate:format(alias), matchTemplate:format(alias), onEvent)
  end
end

----@type Destination[]
local Destinations = {}

---@param zoneName string
---@param spellNames string[]
---@param aliases string[] | nil
local function addDestination(zoneName, spellNames, aliases)
  local spells = {}

  for _, spellName in ipairs(spellNames) do
    local spell = Spell.build(spellName)
    table.insert(spells, spell)
  end

  local destination = Destination.new(zoneName, spells, aliases)

  table.insert(Destinations, destination)

  return destination
end

-- Antonica
addDestination("Lavastorm", { "Circle of Lavastorm" })
addDestination("Feerrott", { "Circle of Feerrott" }, { "fear" })
addDestination("Misty", { "Circle of Misty" })
addDestination("South Ro", { "Circle of Ro" }, { "sro", "ro" })
addDestination("West Commonlands", { "Circle of Commons" }, { "commons", "wc" })
addDestination("Surefall Glade", { "Circle of Surefall Glade" }, { "surefall", "sfg" })
addDestination("North Karana", { "Circle of Karana" }, { "karana", "nk" })
addDestination("East Karana", { "Succor: East" }, { "east karana", "ek" })

-- Faydwer
addDestination("Steamfont", { "Circle of Steamfont" })
addDestination("Butcherblock", { "Circle of Butcher" }, { "butcher", "bb" })

-- Odus
addDestination("Stonebrunt", { "Circle of Stonebrunt" })
addDestination("Toxxulia", { "Circle of Toxxulia" }, { "tox" })

-- Kunark
addDestination("Skyfire", { "Wind of the North" })
addDestination("Emerald Jungle", { "Wind of the South" }, { "emerald", "ej" })
addDestination("Dreadlands", { "Circle of the Combines" }, { "dl" })

-- Velious
addDestination("Cobalt Scar", { "Circle of Cobalt Scar" })
addDestination("Wakening Lands", { "Circle of Wakening Lands" }, { "wakening" })
addDestination("Great Divide", { "Circle of Great Divide" }, { "gd" })
addDestination("Iceclad", { "Circle of Iceclad" })

-- Luclin
addDestination("Nexus", { "Circle of the Nexus" })
addDestination("Dawnshroud", { "Circle of Dawnshroud" })
addDestination("Twilight", { "Circle of Twilight" })
addDestination("Grimling", { "Circle of Grimling" })

-- Planes of Power
addDestination("Plane of Knowledge", { "Circle of Knowledge" }, { "knowledge", "pok" })

-- Taelosia (GoD)
addDestination("Barindu", { "Circle of Barindu" })
addDestination("Natimbi", { "Circle of Natimbi" })

-- Evac
addDestination("Evac", { "Exodus", "Succor", "Lesser Succor" })

return Destinations
