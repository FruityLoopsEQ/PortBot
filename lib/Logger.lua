local mq = require("mq")

Logger = {}
Logger.loglevel = "info"
Logger.prefix = ""

local loglevels = {
    ["debug"] = { level = 1, abbreviation = "DEBUG" },
    ["info"]  = { level = 2, abbreviation = "INFO" },
    ["warn"]  = { level = 3, abbreviation = "WARN" },
    ["error"] = { level = 4, abbreviation = "ERROR" },
    ["fatal"] = { level = 5, abbreviation = "FATAL" }
}

local function Terminate()
    if mq then mq.exit() end
    os.exit()
end

local function GetCallerString()
    if Logger.loglevel:lower() ~= "debug" then
        return ''
    end

    local callString = "unknown"
    local callerInfo = debug.getinfo(4, "Sl")
    if callerInfo and callerInfo.short_src ~= nil and callerInfo.short_src ~= "=[C]" then
        callString = string.format("%s::%s", callerInfo.short_src:match("[^\\^/]*.lua$"), callerInfo.currentline)
    end

    return string.format("(%s) ", callString)
end

local function Output(paramLogLevel, message, ...)
    message = tostring(message)
    local formattedMessage = message:format(...)

    if loglevels[Logger.loglevel:lower()].level <= loglevels[paramLogLevel].level then
        print(string.format("%s%s[%s] :: %s", Logger.prefix, GetCallerString(), loglevels[paramLogLevel].abbreviation,
            formattedMessage))
    end
end

function Logger.Debug(...)
    Output("debug", ...)
end

function Logger.Info(...)
    Output("info", ...)
end

function Logger.Warn(...)
    Output("warn", ...)
end

function Logger.Error(...)
    Output("error", ...)
end

function Logger.Fatal(...)
    Output("fatal", ...)
    Terminate()
end

return Logger
