local mq = require("mq")
local Logger = require("PortBot.lib.Logger")

---@class Spell
---@field ID integer
---@field name string
Spell = {}
Spell.__index = Spell

---@param ID integer
---@param name string
function Spell:new(ID, name)
    local spell = {}
    setmetatable(spell, Spell)

    spell.ID = ID
    spell.name = name

    return spell
end

function Spell:build(spellName)
    local mqSpell = mq.TLO.Spell(spellName)

    local ID = mqSpell.ID()
    local name = mqSpell.Name()

    local spell = Spell:new(ID, name)

    return spell
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
