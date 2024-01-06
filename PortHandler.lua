local mq = require("mq")
local Logger = require("PortBot.Logger")
local Spell = require("PortBot.Spell")

---@class PortHandler
---@field spell Spell
---@field handlerNames string[]
---@field matches string[]
PortHandler = {}
PortHandler.__index = PortHandler

---@param spell Spell
function PortHandler:new(spell)
    local portHandler = {}
    setmetatable(portHandler, PortHandler)

    portHandler.spell = spell
    portHandler.handlerNames = {}
    portHandler.matches = {}

    return portHandler
end

function PortHandler:build(spellName)
    local spell = Spell:build(spellName)

    local portHandler = PortHandler:new(spell)
    return portHandler
end

function PortHandler:destination()
    return self.spell:destination()
end

---@param matchText string
---@param callback fun(spell: Spell): nil
function PortHandler:register(matchText, callback)
    local spellName = self.spell.name
    local eventName = string.format("portHandler-%s-%s", spellName, matchText)

    Logger.Debug("Registering %s to %s", matchText, spellName)

    local callback = function (line, senderName, ...)
        Logger.Info("%s requested %s", senderName, spellName)
        callback(self.spell)
    end

    local line = string.format("#1# tells #*#, '%s'", matchText)
    Logger.Debug(line)

    table.insert(self.handlerNames, eventName)
    table.insert(self.matches, matchText)
    mq.event(eventName, line, callback)
end

return PortHandler