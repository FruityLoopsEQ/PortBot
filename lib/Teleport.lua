local mq = require("mq")
local Logger = require("PortBot.lib.Logger")
local Report = require("PortBot.lib.Report")

---@class Teleport
---@field destination Destination
---@field blockSpell boolean
---@field casting boolean
---@field cancel boolean
Teleport = {}
Teleport.__index = Teleport

---@param destination Destination
---@param blockSpell boolean
function Teleport.new(destination, blockSpell)
    local instance = setmetatable({}, Teleport)

    instance.destination = destination
    instance.blockSpell = blockSpell

    instance.casting = false
    instance.cancel = false

    return instance
end

function Teleport.castStatus()
    local status = mq.parse("${Cast.Status}")

    if status == "I" then
        return "IDLE"
    elseif status == "M" then
        return "MEMORIZE"
    elseif status == "C" then
        return "CASTING"
    end
end

function Teleport.isCasting()
    return Teleport.castStatus() == "CASTING"
end

function Teleport.isMemorizing()
    return Teleport.castStatus() == "MEMORIZE"
end

function Teleport.timeRemainingSeconds()
    local timingResult = mq.parse("${Cast.Timing}")
    local timeRemainingMS = tonumber(timingResult)

    Logger.Debug("Time remaining %sms", timeRemainingMS)

    return timeRemainingMS / 1000
end

function Teleport:cast()
    self.casting = true

    local spell = self.destination.spell

    if not spell:isAA() and not spell:isReady() and not self.cancel then
        Report("Loading %s", spell.name)
        spell:memorize()
    end

    while not spell:isReady() and not self.cancel do
        mq.delay("500ms")
    end

    if self.cancel then
        return
    end


    if self.blockSpell then
        spell:block()
    end

    Report("Casting %s", spell.name)

    spell:cast()
    mq.delay("500ms")

    while Teleport.isCasting() and not self.cancel do
        local secondsRemaining = Teleport.timeRemainingSeconds()

        if secondsRemaining < 7 and secondsRemaining > 0 then
            Report("%.0f", secondsRemaining)
        end

        mq.delay("1s")
    end

    if self.blockSpell then
        spell:unblock()
    end
end

function Teleport:stop()
    self.cancel = true

    Report("Canceling port to %s", self.destination.name)

    if Teleport.isCasting() then
        mq.cmd("/interrupt")

        mq.delay("1s", function()
          return not Teleport.isCasting()
        end)
    end
end

return Teleport
