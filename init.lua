local mq = require("mq")
local Logger = require("PortBot.lib.Logger")
local Report = require("PortBot.lib.Report")
local Teleport = require("PortBot.lib.Teleport")
local Settings = require("PortBot.lib.Settings")
local Destinations = require("PortBot.lib.Destinations")

Logger.prefix = "PortBot"
Logger.loglevel = "info"

Settings.configFilePath = mq.configDir .. "/PortBot.ini"

Report.addChannel("/g")
Report.addChannel("/bc")

VERSION = "2.0.0"

local function inGame() return mq.TLO.MacroQuest.GameState() == "INGAME" end

local function printHelp()
  mq.cmd("/g Port destinations")
  mq.cmd("/g - - -")

  for _, destination in ipairs(Destinations) do
    if destination:hasSpell() then
      if destination.aliases then
        local aliases = table.concat(destination.aliases, ", ")
        mq.cmdf("/g %s (%s)", destination.zoneName, aliases)
      else
        mq.cmdf("/g %s", destination.zoneName)
      end
    end
  end
end

local function start()
  Logger.Info("Starting Version: %s", VERSION)

  local settings = Settings.load()

  Logger.Info("Block Teleport=%s", settings.blockTeleport)

  local currentTeleport = nil

  local function stopTeleport()
    Logger.Debug("Received stop teleport")

    if currentTeleport then
      currentTeleport:stop()
    end

    currentTeleport = nil
  end

  local function onMatch(destination)
    stopTeleport()

    currentTeleport = Teleport.new(destination, settings.blockTeleport)
    Report("Destination set to %s", destination.zoneName)

    if destination:hasSpell() then
      Report("Say 'cancel' in group tell to cancel portal")
      Report("- - -")

      currentTeleport:cast()
      currentTeleport = nil
    else
      for _, spell in ipairs(destination.spells) do
        Report("Missing Spell: %s", spell.name)
      end

      stopTeleport()
    end
  end

  for _, destination in ipairs(Destinations) do
    destination:register(onMatch)
  end

  mq.event("stop", "#1# tells the group, 'stop'", stopTeleport)
  mq.event("cancel", "#1# tells the group, 'cancel'", stopTeleport)

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

  mq.event("port", "#1# tells the group, 'port'", printHelp)
  mq.event("help", "#1# tells the group, 'help'", printHelp)

  mq.bind("/portbot", function(cmd, status)
    if cmd == "block" and status then
      if status == "on" or status == "true" or status == "1" then
        settings.blockTeleport = true
      else
        settings.blockTeleport = false
      end

      Logger.Info("Block is set to %s", settings.blockTeleport)
      Settings.write(settings)
    else
      printHelp()
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
