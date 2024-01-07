local mq = require("mq")

---@class IniFile
---@field mqIniFile userdata
IniFile = {}
IniFile.__index = IniFile

---@param mqIniFile userdata
---@return IniFile
function IniFile.new(mqIniFile)
  local iniFile = {}
  setmetatable(iniFile, IniFile)

  iniFile.mqIniFile = mqIniFile

  return iniFile
end

---@param filePath string
---@param section string
---@param key string
---@param value string | boolean | number
function IniFile.write(filePath, section, key, value)
  mq.cmdf('/ini "%s" "%s" "%s" "%s"', filePath, section, key, value)
end

function IniFile.exists(filePath)
  return mq.TLO.Ini.File(filePath).Exists()
end

function IniFile.get(filePath)
  local mqIniFile = mq.TLO.Ini.File(filePath)

  assert(mqIniFile.Exists(), string.format("Ini file not found at %s", filePath))

  return IniFile.new(mqIniFile)
end

---@param filePath string
---@param sectionName string
function IniFile.getSection(filePath, sectionName)
  if not IniFile.exists(filePath) then
    return nil
  end

  local iniFile = IniFile.get(filePath)

  return iniFile:section(sectionName)
end

---@param name string
---@return table | nil
function IniFile:section(name)
  local mqSection = self.mqIniFile.Section(name)

  if not mqSection.Exists() then
    return nil
  end

  local section = {}

  local keyCount = mqSection.Key.Count()

  Logger.Debug("Reading Section - name=%s", name)

  for i=1,keyCount do
    local key = mqSection.Key.KeyAtIndex(i)()
    local value = mqSection.Key(key).Value()

    Logger.Debug("%s - %s=%s", name, key, value)

    if value == "true" then
      value = true
    elseif value == "false" then
      value = false
    elseif tonumber(value) then
      value = tonumber(value)
    end

    section[key] = value
  end

  return section
end

return IniFile
