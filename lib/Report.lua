local mq = require("mq")

local Report = {}

Report.channels = {}
Report.addChannel = function(channel)
    table.insert(Report.channels, channel)
end

setmetatable(Report, {
    __call = function(cls, message, ...)
        local formattedMessage = message:format(...)
        for _, channel in ipairs(cls.channels) do
            mq.cmdf("%s %s", channel, formattedMessage)
        end
    end
})

return Report
