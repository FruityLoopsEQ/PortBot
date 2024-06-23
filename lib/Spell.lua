local mq = require("mq")
local Logger = require("PortBot.lib.Logger")

---@class Spell
---@field id integer
---@field name string
local Spell = {}
Spell.__index = Spell

---@param id integer
---@param name string
function Spell.new(id, name)
    local spell = {}
    setmetatable(spell, Spell)

    spell.id = id
    spell.name = name

    return spell
end

---@param spellName string
function Spell.build(spellName)
    local mqSpell = mq.TLO.Spell(spellName)

    local id = mqSpell.ID()
    local name = mqSpell.Name()

    local spell = Spell.new(id, name)

    return spell
end

function Spell:cast()
    Logger.Debug("Casting '%s'", self.name)
    mq.cmdf('/casting "%s"', self.name)
end

function Spell:block()
    Logger.Debug("Blocking spell '%s'", self.name)
    mq.cmdf("/blockspell add me %s", self.id)
end

function Spell:unblock()
    Logger.Debug("Unblocking spell '%s'", self.name)
    mq.cmdf("/blockspell remove me %s", self.id)
end

function Spell:memorize()
    Logger.Debug("Memorizing %s", self.name)
    mq.cmdf('/memorize "%s"', self.name)
end

---@return boolean
function Spell:isLearned()
    local spell = mq.TLO.Me.Spell(self.name)

    return spell() ~= nil
end

---@return boolean
function Spell:isReady()
  local castStatus = mq.parse(string.format("${Cast.Ready[%s]}", self.name))

  return castStatus == "TRUE"
end

---@return boolean
function Spell:isAA()
    local mqAA = mq.TLO.AltAbility(self.name)

    return mqAA.AARankRequired() ~= nil
end


return Spell
