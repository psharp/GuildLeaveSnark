-- GuildLeaveSnark - Turtle/Vanilla compatible

local ADDON = "GuildLeaveSnark"
local f = CreateFrame("Frame")

-- SavedVariables
GLS_DB = GLS_DB or {}

local defaults = {
  enabled = true,
  channel = "GUILD",     -- "GUILD", "SAY", "PARTY", "RAID"
  prefixName = true,     -- "Name: quote" vs just quote
  throttleSeconds = 10,  -- prevent spam during mass changes
  debug = false,         -- print system messages for debugging
  quotes = {
    "Another one returns to the wild.",
    "Press F. Or dont.",
    "BRB: permanently.",
    "They have chosen... poorly.",
    "And there was much rejoicing. yay.",
    "Real life crit again.",
    "Gone like a ninja.",
    "One less roll rival.",
    "New guild, same wipes.",
    "They will be missed. Maybe.",
    "Aggroed by real life.",
    "At least no bank heist.",
    "May repairs be costly.",
    "They left before loot.",
    "Somewhere, a murloc claps.",
    "Off to chase greener parses.",
    "The guild is calmer now.",
    "Farewell, random citizen.",
    "Promoted to ex-member.",
    "Bold move. Good luck.",
    "Gone but soon forgotten.",
    "Less drama. More DPS.",
    "This is why we wipe.",
    "They rage-ported out.",
    "Try not to pull extra.",
    "They chose peace.",
    "We wish them well. We do not.",
    "Thank you. Next.",
    "Another one bites dust.",
    "They left mid-buff. Classic."
  }
}

local function initDB()
  if type(GLS_DB) ~= "table" then GLS_DB = {} end
  for k, v in pairs(defaults) do
    if GLS_DB[k] == nil then
      -- shallow copy table defaults
      if type(v) == "table" then
        GLS_DB[k] = {}
        for i=1, table.getn(v) do GLS_DB[k][i] = v[i] end
      else
        GLS_DB[k] = v
      end
    end
  end
  if type(GLS_DB.quotes) ~= "table" or table.getn(GLS_DB.quotes) == 0 then
    GLS_DB.quotes = {}
    for i=1, table.getn(defaults.quotes) do GLS_DB.quotes[i] = defaults.quotes[i] end
  end
end

local function pickQuote()
  local q = GLS_DB.quotes
  local n = table.getn(q)
  if n < 1 then return nil end
  return q[math.random(1, n)]
end

local lastFire = 0
local function throttled()
  local now = GetTime()
  if now - lastFire < (GLS_DB.throttleSeconds or 0) then
    return true
  end
  lastFire = now
  return false
end

local function postSnark(name)
  if not GLS_DB.enabled then return end
  if throttled() then return end

  local quote = pickQuote()
  if not quote then return end

  local msg
  if GLS_DB.prefixName and name and name ~= "" then
    msg = name .. ": " .. quote
  else
    msg = quote
  end

  SendChatMessage(msg, GLS_DB.channel or "GUILD")
end

-- Approach A: parse system message (English clients)
local function parseLeftGuild(systemMsg)
  if not systemMsg then return nil end
  -- Voluntary leave: "Name has left the guild."
  local _, _, n = string.find(systemMsg, "^(.+) has left the guild%.$")
  if n then return n end
  -- Some clients/servers omit the period:
  _, _, n = string.find(systemMsg, "^(.+) has left the guild$")
  if n then return n end
  -- Guild kick: "Name has been kicked out of the guild by KickerName"
  _, _, n = string.find(systemMsg, "^(.+) has been kicked out of the guild by .+$")
  if n then return n end
  return nil
end

-- Approach B: roster diff fallback
local roster = {}
local function scanRoster()
  local t = {}
  if IsInGuild() then
    GuildRoster()
    local count = GetNumGuildMembers(true)
    for i=1, count do
      local name = GetGuildRosterInfo(i)
      if name then
        -- Strip realm if present
        name = string.gsub(name, "%-.*$", "")
        t[name] = true
      end
    end
  end
  roster = t
end

local function diffRosterAndPost()
  if not IsInGuild() then return end
  local old = roster
  scanRoster()
  local new = roster

  -- Find names that were in old but not in new
  for name,_ in pairs(old) do
    if not new[name] then
      postSnark(name)
      -- If multiple people left at once, throttle prevents spam anyway.
    end
  end
end

-- Events
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GUILD_ROSTER_UPDATE")
f:RegisterEvent("CHAT_MSG_SYSTEM")

f:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == ADDON then
    initDB()
    math.randomseed(GetTime() * 1000)
    scanRoster()
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark loaded.|r  /gls for options")
    return
  end

  if event == "PLAYER_ENTERING_WORLD" then
    scanRoster()
    return
  end

  if event == "CHAT_MSG_SYSTEM" then
    -- Debug mode: print all system messages
    if GLS_DB.debug then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[GLS Debug]|r " .. tostring(arg1))
    end
    
    local name = parseLeftGuild(arg1)
    if name then
      postSnark(name)
      -- Also update roster baseline
      scanRoster()
    end
    return
  end

  if event == "GUILD_ROSTER_UPDATE" then
    -- Just update the baseline roster; don't trigger snark
    -- (Opening social panel fires this event frequently)
    scanRoster()
    return
  end
end)

-- Slash commands
SLASH_GLS1 = "/gls"
SlashCmdList["GLS"] = function(msg)
  msg = msg or ""
  local _, _, cmd, rest = string.find(msg, "^(%S+)%s*(.*)$")
  cmd = cmd and string.lower(cmd) or ""

  if cmd == "" or cmd == "help" then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark commands:|r")
    DEFAULT_CHAT_FRAME:AddMessage("/gls on | off")
    DEFAULT_CHAT_FRAME:AddMessage("/gls channel guild|say|party|raid")
    DEFAULT_CHAT_FRAME:AddMessage("/gls prefix on|off  (Name: quote)")
    DEFAULT_CHAT_FRAME:AddMessage("/gls debug on|off  (show system messages)")
    DEFAULT_CHAT_FRAME:AddMessage('/gls add <quote text>')
    DEFAULT_CHAT_FRAME:AddMessage('/gls list')
    DEFAULT_CHAT_FRAME:AddMessage('/gls test <name>')
    return
  end

  if cmd == "on" then
    GLS_DB.enabled = true
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark enabled.|r")
    return
  end

  if cmd == "off" then
    GLS_DB.enabled = false
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark disabled.|r")
    return
  end

  if cmd == "channel" then
    local ch = string.upper(rest or "")
    if ch == "GUILD" or ch == "SAY" or ch == "PARTY" or ch == "RAID" then
      GLS_DB.channel = ch
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark channel set to|r "..ch)
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Invalid channel. Use guild|say|party|raid.|r")
    end
    return
  end

  if cmd == "prefix" then
    rest = string.lower(rest or "")
    GLS_DB.prefixName = (rest == "on" or rest == "1" or rest == "true")
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark prefixName =|r "..tostring(GLS_DB.prefixName))
    return
  end

  if cmd == "debug" then
    rest = string.lower(rest or "")
    GLS_DB.debug = (rest == "on" or rest == "1" or rest == "true")
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark debug mode =|r "..tostring(GLS_DB.debug))
    if GLS_DB.debug then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff9900All CHAT_MSG_SYSTEM messages will be printed.|r")
    end
    return
  end

  if cmd == "add" then
    if rest and rest ~= "" then
      table.insert(GLS_DB.quotes, rest)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffAdded quote (#"..table.getn(GLS_DB.quotes)..")|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls add <quote text>|r")
    end
    return
  end

  if cmd == "list" then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark quotes ("..table.getn(GLS_DB.quotes)..")|r")
    for i=1, table.getn(GLS_DB.quotes) do
      DEFAULT_CHAT_FRAME:AddMessage(i..": "..GLS_DB.quotes[i])
    end
    return
  end

  if cmd == "test" then
    local name = rest ~= "" and rest or "Someone"
    postSnark(name)
    return
  end

  DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Unknown command. /gls help|r")
end
