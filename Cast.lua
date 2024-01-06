local mq = require("mq")
local Logger = require("PortBot.Logger")
local Spell = require("PortBot.Spell")
local Report = require("PortBot.Report")

---@alias ProgressHandler fun(remainingSeconds: integer): any
---@class Cast
---@field spell Spell
---@field casting boolean
---@field cancel boolean
---@field onCastProgressHandlers ProgressHandler[]
Cast = {}
Cast.__index = Cast

---@param spell Spell
function Cast.new(spell)
    local instance = setmetatable({}, Cast)

    instance.spell = spell
    instance.casting = false
    instance.cancel = false
    instance.onCastProgressHandlers = {}

    return instance
end

---@param spell Spell
function Cast.build(spell)
    local cast = Cast.new(spell)

    return cast
end

function Cast.result()
    return mq.parse("${Cast.Result}")
end

function Cast.castStatus()
    local status = mq.parse("${Cast.Status}")

    if status == "I" then
        return "IDLE"
    elseif status == "M" then
        return "MEMORIZE"
    elseif status == "C" then
        return "CASTING"
    end
end

function Cast.isCasting()
    return Cast.castStatus() == "CASTING"
end

function Cast.isMemorizing()
    return Cast.castStatus() == "MEMORIZE"
end

function Cast.timeRemainingSeconds() 
    local timingResult = mq.parse("${Cast.Timing}")
    local timeRemainingMS = tonumber(timingResult)

    Logger.Debug("Time remaining %sms", timeRemainingMS)

    return timeRemainingMS / 1000
end


function Cast:start()
    Report("Destination set to %s", self.spell:destination())
    Report("Say 'cancel' in group tell to cancel portal")

    self.casting = true

    if self.cancel then
        return Report.result
    end

    if not self.spell:isReady() and not self.cancel then
        Report("Loading %s", self.spell.name)
        self.spell:memorize()
    end

    if self.cancel then
        return Report.result
    end

    while not self.spell:isReady() and not self.cancel do
        mq.delay("500ms")
    end

    if self.cancel then
        return Report.result
    end

    Report("Portal to %s incoming", self.spell:destination())

    self.spell:cast()
    mq.delay("500ms")

    while Cast.isCasting() and not self.cancel do
        local secondsRemaining = math.ceil(Cast.timeRemainingSeconds())

        if secondsRemaining < 6 and secondsRemaining > 0 then
            Report("%s", secondsRemaining)
        end

        for _, handler in ipairs(self.onCastProgressHandlers) do
            handler(secondsRemaining)
        end

        mq.delay("1s")
    end

    if self.cancel then
        return Report.result
    end

    return Report.result
end

---@param handler ProgressHandler
function Cast:registerOnCastProgress(handler)
    table.insert(self.onCastProgressHandlers, handler)
end

function Cast:stop()
    Logger.Debug("Stop cast of ", self.spell.name)

    if self.casting then
        Report("Canceling port to %s", self.spell:destination())
        self.cancel = true
        mq.cmd("/interrupt")
        mq.delay("1s")
    end
end

return Cast