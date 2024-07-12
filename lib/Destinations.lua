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

---@class Collection
---@field members Destination[]
local Collection = {}
Collection.__index = Collection

---@param members Destination[] | nil
---@return Collection
function Collection.new(members)
  members = members or {}
  local destinations = {}
  setmetatable(destinations, Collection)

  destinations.members = members

  return destinations
end

---@param zoneName string
---@param spellNames string[]
---@param aliases string[] | nil
function Collection:add(zoneName, spellNames, aliases)
  local spells = {}

  for _, spellName in ipairs(spellNames) do
    local spell = Spell.build(spellName)
    table.insert(spells, spell)
  end

  local destination = Destination.new(zoneName, spells, aliases)

  table.insert(self.members, destination)

  return destination
end

---@param callback fun(destination: Destination): any
function Collection:each(callback)
  for _, destination in ipairs(self.members) do
    callback(destination)
  end
end

local Destinations = Collection.new()

-- Antonica
Destinations:add("Lavastorm", { "Circle of Lavastorm" })
Destinations:add("Feerrott", { "Circle of Feerrott" }, { "fear" })
Destinations:add("Misty", { "Circle of Misty" })
Destinations:add("South Ro", { "Circle of Ro" }, { "sro", "ro" })
Destinations:add("West Commonlands", { "Circle of Commons" }, { "commons", "wc" })
Destinations:add("Surefall Glade", { "Circle of Surefall Glade" }, { "surefall", "sfg" })
Destinations:add("North Karana", { "Circle of Karana" }, { "karana", "nk" })
Destinations:add("East Karana", { "Succor: East" }, { "east karana", "ek" })

-- Faydwer
Destinations:add("Steamfont", { "Circle of Steamfont" })
Destinations:add("Butcherblock", { "Circle of Butcher" }, { "butcher", "bb" })

-- Odus
Destinations:add("Stonebrunt", { "Circle of Stonebrunt" })
Destinations:add("Toxxulia", { "Circle of Toxxulia" }, { "tox" })

-- Kunark
Destinations:add("Skyfire", { "Wind of the North" })
Destinations:add("Emerald Jungle", { "Wind of the South" }, { "emerald", "ej" })
Destinations:add("Dreadlands", { "Circle of the Combines" }, { "dl" })

-- Velious
Destinations:add("Cobalt Scar", { "Circle of Cobalt Scar" })
Destinations:add("Wakening Lands", { "Circle of Wakening Lands" }, { "wakening" })
Destinations:add("Great Divide", { "Circle of Great Divide" }, { "gd" })
Destinations:add("Iceclad", { "Circle of Iceclad" })

-- Luclin
Destinations:add("Nexus", { "Circle of the Nexus" })
Destinations:add("Dawnshroud", { "Circle of Dawnshroud" })
Destinations:add("Twilight", { "Circle of Twilight" })
Destinations:add("Grimling", { "Circle of Grimling" })

-- Planes of Power
Destinations:add("Plane of Knowledge", { "Circle of Knowledge" }, { "knowledge", "pok" })

-- Taelosia (GoD)
Destinations:add("Barindu", { "Circle of Barindu" })
Destinations:add("Natimbi", { "Circle of Natimbi" })

-- Evac
Destinations:add("Evac", { "Exodus", "Succor", "Lesser Succor" })

return Destinations
