local mq = require("mq")
local Logger = require("PortBot.lib.Logger")

---@class Spell
---@field ID integer
---@field name string
---@field description string
Spell = {}
Spell.__index = Spell

---@param ID integer
---@param name string
---@param description string
function Spell:new(ID, name, description)
    local spell = {}
    setmetatable(spell, Spell)

    spell.ID = ID
    spell.name = name
    spell.description = description

    return spell
end

function Spell:build(spellName)
    local mqSpell = mq.TLO.Spell(spellName)

    local ID = mqSpell.ID()
    local name = mqSpell.Name()
    local description = mqSpell.Description()

    local spell = Spell:new(ID, name, description)

    return spell
end

function Spell:destination()
    local target = self.description:match("Opens a mystical portal that transports your group to (.*)")
    target = target or self.description:match("Opens a mystic portal that teleports your group to (.*)")

    local zone = target:match("the (.*).")
    zone = zone or target:match("(.*).")

    return zone
end

function Spell:cast()
    Logger.Debug("Casting '%s'", self.name)
    mq.cmdf('/cast "%s"', self.name)
    mq.delay("500ms")
end

function Spell:block()
    Logger.Debug("Blocking spell '%s'", self.name)
    mq.cmdf("/blockspell add me %s", self.ID)
end

function Spell:unblock()
    Logger.Debug("Unblocking spell '%s'", self.name)
    mq.cmdf("/blockspell remove me %s", self.ID)
end

function Spell:memorize()
    Logger.Debug("Memorizing %s", self.name)
    mq.cmdf('/memorize "%s"', self.name)
end

function Spell:isReady()
    return mq.parse(string.format("${Cast.Ready[%s]}", self.name)) == "TRUE"
end


return Spell
