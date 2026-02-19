-- GuildLeaveSnark - Turtle/Vanilla compatible

local ADDON = "GuildLeaveSnark"
local f = CreateFrame("Frame")

-- SavedVariables
GLS_DB = GLS_DB or {}

local defaults = {
  enabled = true,
  channel = "GUILD",     -- "GUILD", "SAY", "PARTY", "RAID"
  prefixName = true,     -- "Name: quote" vs just quote
  rankMinIndex = -1,     -- -1 = all ranks, otherwise only rankIndex >= this value
  throttleSeconds = 10,  -- prevent spam during mass changes
  debug = false,         -- print system messages for debugging
  color = "ff9900",      -- hex color (default: orange)
  quotesLeave = {
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
    "May repairs be costly.",
    "They left before loot.",
    "Somewhere, a murloc claps.",
    "Off to chase greener parses.",
    "The guild is calmer now.",
    "Farewell, random citizen.",
    "Bold move. Good luck.",
    "Gone but soon forgotten.",
    "Less drama. More DPS.",
    "They chose peace.",
    "We wish them well. We do not.",
    "Thank you. Next.",
    "Another one bites dust.",
    "They left mid-buff. Classic."
  },
  quotesKick = {
    "Promoted to ex-member.",
    "This is why we wipe.",
    "They rage-ported out.",
    "Try not to pull extra.",
    "At least no bank heist.",
    "The trash took itself out.",
    "Justice has been served.",
    "One less repair bill to carry.",
    "They found out about consequences.",
    "Performance review: Failed.",
    "Uninstalled from the roster.",
    "The ban hammer has spoken.",
    "They were asked to leave. Forcefully.",
    "No refunds on guild tabards.",
    "Turns out actions have consequences."
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
  
  -- Migrate old "quotes" to "quotesLeave" if needed
  if type(GLS_DB.quotes) == "table" and table.getn(GLS_DB.quotes) > 0 then
    GLS_DB.quotesLeave = GLS_DB.quotes
    GLS_DB.quotes = nil
  end
  
  if type(GLS_DB.quotesLeave) ~= "table" or table.getn(GLS_DB.quotesLeave) == 0 then
    GLS_DB.quotesLeave = {}
    for i=1, table.getn(defaults.quotesLeave) do GLS_DB.quotesLeave[i] = defaults.quotesLeave[i] end
  end
  if type(GLS_DB.quotesKick) ~= "table" or table.getn(GLS_DB.quotesKick) == 0 then
    GLS_DB.quotesKick = {}
    for i=1, table.getn(defaults.quotesKick) do GLS_DB.quotesKick[i] = defaults.quotesKick[i] end
  end
end

local function pickQuote(quoteType)
  local q = quoteType == "kick" and GLS_DB.quotesKick or GLS_DB.quotesLeave
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

local function shouldPostForRank(rankIndex)
  local minIndex = GLS_DB.rankMinIndex
  if not minIndex or minIndex < 0 then
    return true
  end
  if rankIndex == nil then
    return false
  end
  return rankIndex >= minIndex
end

local function postSnark(name, quoteType, rankIndex)
  if not GLS_DB.enabled then return end
  if not shouldPostForRank(rankIndex) then
    if GLS_DB.debug then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[GLS Debug]|r rank filter blocked: "..tostring(name).." (rankIndex="..tostring(rankIndex)..")")
    end
    return
  end
  if throttled() then return end

  local quote = pickQuote(quoteType)
  if not quote then return end

  local color = GLS_DB.color or "ff9900"
  local msg
  if GLS_DB.prefixName and name and name ~= "" then
    msg = "|cff" .. color .. name .. ": " .. quote .. "|r"
  else
    msg = "|cff" .. color .. quote .. "|r"
  end

  SendChatMessage(msg, GLS_DB.channel or "GUILD")
end

-- Approach A: parse system message (English clients)
-- Returns: name, type ("leave" or "kick")
local function parseLeftGuild(systemMsg)
  if not systemMsg then return nil, nil end
  -- Voluntary leave: "Name has left the guild."
  local _, _, n = string.find(systemMsg, "^(.+) has left the guild%.$")
  if n then return n, "leave" end
  -- Some clients/servers omit the period:
  _, _, n = string.find(systemMsg, "^(.+) has left the guild$")
  if n then return n, "leave" end
  -- Guild kick: "Name has been kicked out of the guild by KickerName"
  _, _, n = string.find(systemMsg, "^(.+) has been kicked out of the guild by .+$")
  if n then return n, "kick" end
  return nil, nil
end

-- Approach B: roster diff fallback
local roster = {}
local function scanRoster()
  local t = {}
  if IsInGuild() then
    GuildRoster()
    local count = GetNumGuildMembers(true)
    for i=1, count do
      local name, _, rankIndex = GetGuildRosterInfo(i)
      if name then
        -- Strip realm if present
        name = string.gsub(name, "%-.*$", "")
        t[name] = rankIndex
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
  for name,rankIndex in pairs(old) do
    if not new[name] then
      postSnark(name, "leave", rankIndex)
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
    
    local name, quoteType = parseLeftGuild(arg1)
    if name then
      postSnark(name, quoteType)
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
    DEFAULT_CHAT_FRAME:AddMessage("/gls color <hex>  (e.g., ff9900 for orange)")
    DEFAULT_CHAT_FRAME:AddMessage("/gls rank all|<index>  (0=GM, bigger number=lower rank)")
    DEFAULT_CHAT_FRAME:AddMessage("/gls debug on|off  (show system messages)")
    DEFAULT_CHAT_FRAME:AddMessage('/gls addleave <quote>  (add leave quote)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls addkick <quote>  (add kick quote)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls removeleave <num>  (remove by number)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls removekick <num>  (remove by number)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls list  (show all quotes)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls clear  (restore default quotes)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls test <name>  (test with fake leave)')
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

  if cmd == "color" then
    local hex = rest or ""
    hex = string.gsub(hex, "^#", "")  -- strip leading # if present
    if string.len(hex) == 6 and string.find(hex, "^%x%x%x%x%x%x$") then
      GLS_DB.color = string.lower(hex)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark color set to|r |cff"..GLS_DB.color..GLS_DB.color.."|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Invalid hex color. Use 6 digits (e.g., ff9900 for orange)|r")
    end
    return
  end

  if cmd == "rank" then
    rest = string.lower(rest or "")
    if rest == "" then
      if GLS_DB.rankMinIndex and GLS_DB.rankMinIndex >= 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark rank filter:|r rankIndex >= "..GLS_DB.rankMinIndex.." (0=GM, larger=lower rank)")
      else
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark rank filter:|r all ranks")
      end
      return
    end

    if rest == "all" then
      GLS_DB.rankMinIndex = -1
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark rank filter:|r all ranks")
      return
    end

    local n = tonumber(rest)
    if n and n >= 0 then
      GLS_DB.rankMinIndex = math.floor(n)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark rank filter set:|r rankIndex >= "..GLS_DB.rankMinIndex.." (0=GM, larger=lower rank)")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls rank all|<index>  (0=GM, larger number=lower rank)|r")
    end
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
      table.insert(GLS_DB.quotesLeave, rest)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffAdded leave quote (#"..table.getn(GLS_DB.quotesLeave)..")|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls add <quote text>|r")
    end
    return
  end

  if cmd == "list" then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark Leave Quotes ("..table.getn(GLS_DB.quotesLeave).."):|r")
    for i=1, table.getn(GLS_DB.quotesLeave) do
      DEFAULT_CHAT_FRAME:AddMessage(i..": "..GLS_DB.quotesLeave[i])
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark Kick Quotes ("..table.getn(GLS_DB.quotesKick).."):|r")
    for i=1, table.getn(GLS_DB.quotesKick) do
      DEFAULT_CHAT_FRAME:AddMessage(i..": "..GLS_DB.quotesKick[i])
    end
    return
  end

  if cmd == "test" then
    local name = rest ~= "" and rest or "Someone"
    postSnark(name, "leave", 99)
    return
  end

  DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Unknown command. /gls help|r")
end
