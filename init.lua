local mq = require("mq")
local Logger = require("PortBot.lib.Logger")
local Report = require("PortBot.lib.Report")
local Teleport = require("PortBot.lib.Teleport")
local Settings = require("PortBot.lib.Settings")
local Destinations = require("PortBot.lib.Destinations")

Logger.prefix = "PortBot"
Logger.loglevel = "info"

Settings.configFilePath = mq.configDir .. "/PortBot.ini"
Destinations.configFilePath = mq.configDir .. "/PortBot.ini"

Report.addChannel("/g")
Report.addChannel("/bc")

VERSION="1.0.0"

local function inGame() return mq.TLO.MacroQuest.GameState() == "INGAME" end

local function start()
    Logger.Info("Starting Version: %s", VERSION)

    local settings = Settings.load()
    local destinations = Destinations.load()

    Logger.Info("Block Teleport=%s", settings.blockTeleport)

    local currentTeleport = nil

    local function stopTeleport()
        Logger.Debug("Received stop teleport")

        if currentTeleport then
            currentTeleport:stop()
        end

        currentTeleport = nil
    end

    destinations:register(function(destination)
        stopTeleport()

        Report("Destination set to %s", destination.name)
        Report("Say 'cancel' in group tell to cancel portal")

        currentTeleport = Teleport.new(destination, settings.blockTeleport)

        currentTeleport:cast()

        currentTeleport = nil
    end)

    mq.event("stop", "#1# tells #*#, 'stop'", stopTeleport)
    mq.event("cancel", "#1# tells #*#, 'cancel'", stopTeleport)

    mq.event("groupInvite", "#1# invites you to join a group.", function(_, inviterName)
        if settings.acceptGroupInvite then
            Logger.Info("Group invite from %s", inviterName)

            mq.cmdf("/target %s", inviterName)
            mq.delay("1s", function()
              return mq.TLO.Target.CleanName() == inviterName
            end)

            mq.cmd("/invite")
        end
    end)

    local function printHelp()
        mq.cmd("/g Port destinations")
        mq.cmd("/g - - -")

        for _, destination in ipairs(destinations.members) do
            if destination:anyAliases() then
                local aliases = table.concat(destination.aliases, ", ")
                mq.cmdf("/g %s (%s)", destination.name, aliases)
            else
                mq.cmdf("/g %s", destination.name)
            end
        end
    end

    mq.event("port", "#1# tells #*#, 'port'", printHelp)
    mq.event("help", "#1# tells #*#, 'help'", printHelp)

    mq.bind("/portbot", function(cmd, status)
        if cmd == "block" and status then
            if status == "on" or status == "true" or status == "1" then
                settings.blockTeleport = true
            else
                settings.blockTeleport = false
            end

            Logger.Info("Block is set to %s", settings.blockTeleport)
            Settings.write(settings)
        end
    end)

    while true do
        if inGame() then
            mq.doevents()
            mq.delay("500ms")
        end
    end
end

start()
