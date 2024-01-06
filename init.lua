local mq = require("mq")
local Logger = require("PortBot.Logger")
local PortHandler = require("PortBot.PortHandler")
local Report = require("PortBot.Report")
local Cast = require("PortBot.Cast")

Logger.prefix = "PortBot"
Logger.loglevel = "info"

Report.addChannel("/g")
Report.addChannel("/bc")

BLOCK_PORTS=false

VERSION="0.0.1"

local function in_game() return mq.TLO.MacroQuest.GameState() == "INGAME" end

local currentCast = nil
local function stopCasting()
    if currentCast ~= nil then
        currentCast:stop()
    end

    currentCast = nil
end

--- @param spell Spell
local function castSpell(spell)
    stopCasting()

    currentCast = Cast.build(spell)

    if BLOCK_PORTS then
        spell:block()
    end

    currentCast:start()

    if BLOCK_PORTS then
        spell:unblock()
    end
    currentCast = nil
end

--- @param portSpells table<string, string[]>
--- @return PortHandler[]
local function registerSpellHandlers(portSpells)
    Logger.Debug("Registering handlers")
    local handlers = {}

    for spellName, aliases in pairs(portSpells) do
        local handler = PortHandler:build(spellName)

        Logger.Debug("Register %s", spellName)

        for _,alias in ipairs(aliases) do
            Logger.Debug("  -> %s", alias)
            handler:register(alias, castSpell)
        end

        table.insert(handlers, handler)
    end

    local sort = function(a, b)
        return a:destination():lower() < b:destination():lower()
    end
    table.sort(handlers, sort)
    return handlers
end

local function handleGroupInvite(_, inviterName)
    Logger.Info("Group invite from %s", inviterName)

    mq.cmdf("/target %s", inviterName)
    mq.delay("250ms")
    mq.cmd("/invite")
end

local spells = {
    -- Antonica
    ["Circle of Lavastorm"] = { "lavastorm" },
    ["Circle of Feerrott"] = { "feerrott", "fear" },
    ["Circle of Misty"] = { "misty" },
    ["Circle of Ro"] = { "sro", "ro" },
    ["Circle of Commons"] = { "commons", "wc" },
    ["Circle of Surefall Glade"] = { "surefall", "sfg" },
    ["Circle of Karana"] = { "karana", "wk" },
    --  Faydwer
    ["Circle of Steamfont"] = { "steamfont", "sfm" },
    ["Circle of Butcher"] = { "butcher", "butcherblock", "bb" },
    -- Odus
    ["Circle of Stonebrunt"] = { "stonebrunt" },
    ["Circle of Toxxulia"] = { "tox" },
    -- Kunark
    ["Wind of the North"] = { "skyfire" },
    ["Wind of the South"] = { "emerald", "ej" },
    ["Circle of the Combines"] = { "dreadlands", "dl" },
    -- Velious
    ["Circle of Cobalt Scar"] = { "cobalt scar", "cs" },
    ["Circle of Wakening Lands"] = { "wakening lands", "wakening", "wl" },
    ["Circle of Great Divide"] = { "great divide", "divide", "gd" },
    ["Circle of Iceclad"] = { "iceclad" },
    -- Luclin
    ["Circle of the Nexus"] = { "nexus" },
    ["Circle of Dawnshroud"] = { "dawnshroud" },
    ["Circle of Twilight"] = { "twilight" },
    ["Circle of Grimling"] = { "grimling" },
    -- Planes of Power
    ["Circle of Knowledge"] = { "knowledge", "pok" },
    -- Taelosia
    ["Circle of Barindu"] = { "barindu", "bar" },
    ["Circle of Natimbi"] = { "natimbi", "nat" },
}

-- Ramzee creates a mystic portal.
-- Jibb discorporates in a portal of wind.
--- @param handlers PortHandler[]
local function printPortHandlers(handlers)
    mq.cmd("/g Port destinations")
    mq.cmd("/g - - -")

    for _, handler in ipairs(handlers) do
        local matches = table.concat(handler.matches, ", ")
        mq.cmdf("/g %s (%s)", handler:destination(), matches)
    end
end

local function start()
    Logger.Info("Starting Version: %s", VERSION)

    local handlers = registerSpellHandlers(spells)

    mq.event("groupInvite", "#1# invites you to join a group.", handleGroupInvite)

    local function handlePortHelp(_, senderName)
        Logger.Debug("Help requested by %s", senderName)

        printPortHandlers(handlers)
    end

    mq.event("port", "#1# tells #*#, 'port'", handlePortHelp)
    mq.event("help", "#1# tells #*#, 'help'", handlePortHelp)
    mq.event("stop", "#1# tells #*#, 'stop'", stopCasting)
    mq.event("cancel", "#1# tells #*#, 'cancel'", stopCasting)

    local last_time = os.time()

    while true do
        if in_game() and os.difftime(os.time(), last_time) >= 1 then
            mq.doevents()
        end
    end
end

start()
