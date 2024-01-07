---@class Destination
---@field name string
---@field spell string
---@field aliases string[]
Destination = {}
Destination.__index = Destination

---@param name string
---@param spell string
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

return Destination
