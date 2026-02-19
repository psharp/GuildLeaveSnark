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
  minimapAngle = 225,    -- minimap button position angle
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

local function postSnark(name, quoteType, rankIndex, bypassThrottle)
  if not GLS_DB.enabled then return end
  if not shouldPostForRank(rankIndex) then
    if GLS_DB.debug then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[GLS Debug]|r rank filter blocked: "..tostring(name).." (rankIndex="..tostring(rankIndex)..")")
    end
    return
  end
  if not bypassThrottle and throttled() then return end

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

local channels = {"GUILD", "SAY", "PARTY", "RAID"}

local function nextChannel(current)
  for i=1, table.getn(channels) do
    if channels[i] == current then
      if i >= table.getn(channels) then
        return channels[1]
      end
      return channels[i + 1]
    end
  end
  return "GUILD"
end

local optionsFrame
local optionsControls = {}
local minimapButton

local function hexToRGB(hex)
  hex = string.lower(hex or "ff9900")
  if string.len(hex) ~= 6 then
    hex = "ff9900"
  end

  local r = tonumber(string.sub(hex, 1, 2), 16) or 255
  local g = tonumber(string.sub(hex, 3, 4), 16) or 153
  local b = tonumber(string.sub(hex, 5, 6), 16) or 0
  return r / 255, g / 255, b / 255
end

local function rgbToHex(r, g, b)
  local rr = math.floor((r or 1) * 255 + 0.5)
  local gg = math.floor((g or 0.6) * 255 + 0.5)
  local bb = math.floor((b or 0) * 255 + 0.5)

  if rr < 0 then rr = 0 elseif rr > 255 then rr = 255 end
  if gg < 0 then gg = 0 elseif gg > 255 then gg = 255 end
  if bb < 0 then bb = 0 elseif bb > 255 then bb = 255 end

  return string.format("%02x%02x%02x", rr, gg, bb)
end

local function updateOptionsUI()
  if not optionsFrame then return end

  optionsControls.enabled:SetChecked(GLS_DB.enabled)
  optionsControls.prefix:SetChecked(GLS_DB.prefixName)
  optionsControls.debug:SetChecked(GLS_DB.debug)
  optionsControls.channelButton:SetText("Channel: " .. (GLS_DB.channel or "GUILD"))

  if GLS_DB.rankMinIndex and GLS_DB.rankMinIndex >= 0 then
    optionsControls.rankEdit:SetText(tostring(GLS_DB.rankMinIndex))
  else
    optionsControls.rankEdit:SetText("all")
  end

  optionsControls.colorButton:SetText("Pick Color: #" .. (GLS_DB.color or "ff9900"))
end

local function applyRankFilterFromEdit()
  local v = string.lower(optionsControls.rankEdit:GetText() or "")
  if v == "" or v == "all" then
    GLS_DB.rankMinIndex = -1
    optionsControls.rankEdit:SetText("all")
    return
  end

  local n = tonumber(v)
  if n and n >= 0 then
    GLS_DB.rankMinIndex = math.floor(n)
    optionsControls.rankEdit:SetText(tostring(GLS_DB.rankMinIndex))
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Invalid rank filter. Use all or a number >= 0.|r")
    if GLS_DB.rankMinIndex and GLS_DB.rankMinIndex >= 0 then
      optionsControls.rankEdit:SetText(tostring(GLS_DB.rankMinIndex))
    else
      optionsControls.rankEdit:SetText("all")
    end
  end
end

local function openColorPicker()
  local oldHex = GLS_DB.color or "ff9900"
  local r, g, b = hexToRGB(oldHex)

  local function applyPickerColor()
    local pr, pg, pb = ColorPickerFrame:GetColorRGB()
    GLS_DB.color = rgbToHex(pr, pg, pb)
    updateOptionsUI()
  end

  ColorPickerFrame.hasOpacity = false
  ColorPickerFrame.opacityFunc = nil
  ColorPickerFrame.func = applyPickerColor
  ColorPickerFrame.cancelFunc = function()
    GLS_DB.color = oldHex
    updateOptionsUI()
  end
  ColorPickerFrame:SetColorRGB(r, g, b)
  ColorPickerFrame:Show()
end

local function createOptionsUI()
  if optionsFrame then return end

  local frame = CreateFrame("Frame", "GLS_OptionsFrame", UIParent)
  frame:SetWidth(360)
  frame:SetHeight(290)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    local target = self or this
    if target then
      target:StartMoving()
    end
  end)
  frame:SetScript("OnDragStop", function(self)
    local target = self or this
    if target then
      target:StopMovingOrSizing()
    end
  end)
  frame:Hide()

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -16)
  title:SetText("GuildLeaveSnark")

  local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  subtitle:SetPoint("TOP", title, "BOTTOM", 0, -6)
  subtitle:SetText("Options")

  local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

  local enabled = CreateFrame("CheckButton", "GLS_EnabledCheck", frame, "UICheckButtonTemplate")
  enabled:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -52)
  enabled:SetScript("OnClick", function()
    GLS_DB.enabled = enabled:GetChecked() and true or false
  end)
  _G[enabled:GetName() .. "Text"]:SetText("Enabled")
  optionsControls.enabled = enabled

  local prefix = CreateFrame("CheckButton", "GLS_PrefixCheck", frame, "UICheckButtonTemplate")
  prefix:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 0, -8)
  prefix:SetScript("OnClick", function()
    GLS_DB.prefixName = prefix:GetChecked() and true or false
  end)
  _G[prefix:GetName() .. "Text"]:SetText("Prefix player name")
  optionsControls.prefix = prefix

  local debug = CreateFrame("CheckButton", "GLS_DebugCheck", frame, "UICheckButtonTemplate")
  debug:SetPoint("TOPLEFT", prefix, "BOTTOMLEFT", 0, -8)
  debug:SetScript("OnClick", function()
    GLS_DB.debug = debug:GetChecked() and true or false
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark debug mode =|r " .. tostring(GLS_DB.debug))
    if GLS_DB.debug then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[GLS Debug]|r Debug logging enabled for CHAT_MSG_SYSTEM.")
    end
  end)
  _G[debug:GetName() .. "Text"]:SetText("Debug mode")
  optionsControls.debug = debug

  local channelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  channelButton:SetWidth(165)
  channelButton:SetHeight(22)
  channelButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -26, -56)
  channelButton:SetScript("OnClick", function()
    GLS_DB.channel = nextChannel(GLS_DB.channel)
    channelButton:SetText("Channel: " .. GLS_DB.channel)
  end)
  optionsControls.channelButton = channelButton

  local rankLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  rankLabel:SetPoint("TOPLEFT", channelButton, "BOTTOMLEFT", 0, -18)
  rankLabel:SetText("Rank filter")

  local rankEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  rankEdit:SetWidth(90)
  rankEdit:SetHeight(20)
  rankEdit:SetAutoFocus(false)
  rankEdit:SetPoint("TOPLEFT", rankLabel, "BOTTOMLEFT", 0, -6)
  rankEdit:SetScript("OnEnterPressed", function(self)
    applyRankFilterFromEdit()
    self:ClearFocus()
  end)
  optionsControls.rankEdit = rankEdit

  local rankApply = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  rankApply:SetWidth(60)
  rankApply:SetHeight(22)
  rankApply:SetPoint("LEFT", rankEdit, "RIGHT", 8, 0)
  rankApply:SetText("Set")
  rankApply:SetScript("OnClick", applyRankFilterFromEdit)

  local rankHelp = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  rankHelp:SetWidth(170)
  rankHelp:SetJustifyH("LEFT")
  rankHelp:SetPoint("TOPLEFT", rankEdit, "BOTTOMLEFT", 0, -4)
  rankHelp:SetText("all or index (0=GM)")

  local colorLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  colorLabel:SetPoint("TOPLEFT", rankHelp, "BOTTOMLEFT", 0, -10)
  colorLabel:SetText("Message color")

  local colorButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  colorButton:SetWidth(170)
  colorButton:SetHeight(22)
  colorButton:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 0, -6)
  colorButton:SetScript("OnClick", openColorPicker)
  optionsControls.colorButton = colorButton

  local testBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  testBtn:SetWidth(120)
  testBtn:SetHeight(22)
  testBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 22)
  testBtn:SetText("Send Test")
  testBtn:SetScript("OnClick", function() postSnark(UnitName("player") or "Someone", "leave", 99, true) end)

  local closeBottomBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  closeBottomBtn:SetWidth(90)
  closeBottomBtn:SetHeight(22)
  closeBottomBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 22)
  closeBottomBtn:SetText("Close")
  closeBottomBtn:SetScript("OnClick", function() frame:Hide() end)

  optionsFrame = frame
end

local function toggleOptionsUI()
  if not optionsFrame then
    createOptionsUI()
  end

  if optionsFrame:IsShown() then
    optionsFrame:Hide()
  else
    updateOptionsUI()
    optionsFrame:Show()
  end
end

local function updateMinimapButtonPosition()
  if not minimapButton then return end
  local angle = (GLS_DB.minimapAngle or 225) * (math.pi / 180)
  local radius = 80
  minimapButton:ClearAllPoints()
  minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function getAngleDegrees(dx, dy)
  local atan2fn = math.atan2 or atan2
  if atan2fn then
    return math.deg(atan2fn(dy, dx))
  end

  if dx == 0 then
    if dy > 0 then return 90 end
    if dy < 0 then return -90 end
    return 0
  end

  local a = math.deg(math.atan(dy / dx))
  if dx < 0 then
    a = a + 180
  end
  return a
end

local function createMinimapButton()
  if minimapButton then return end

  local b = CreateFrame("Button", "GLS_MinimapButton", Minimap)
  b:SetWidth(32)
  b:SetHeight(32)
  b:SetFrameStrata("MEDIUM")
  b:SetMovable(true)
  b:EnableMouse(true)
  b:RegisterForDrag("LeftButton")

  b.icon = b:CreateTexture(nil, "OVERLAY")
  b.icon:SetTexture("Interface\\Icons\\Ability_Racial_Cannibalize")
  b.icon:SetWidth(20)
  b.icon:SetHeight(20)
  b.icon:SetPoint("CENTER", b, "CENTER", 0, 1)
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  b.border = b:CreateTexture(nil, "OVERLAY")
  b.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  b.border:SetWidth(54)
  b.border:SetHeight(54)
  b.border:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)

  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  b:SetScript("OnClick", function()
    toggleOptionsUI()
  end)

  b:SetScript("OnEnter", function()
    GameTooltip:SetOwner(b, "ANCHOR_LEFT")
    GameTooltip:SetText("GuildLeaveSnark")
    GameTooltip:AddLine("Left-click: Toggle options", 1, 1, 1)
    GameTooltip:AddLine("Drag: Move minimap button", 1, 1, 1)
    GameTooltip:Show()
  end)

  b:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  local dragging = false

  b:SetScript("OnDragStart", function()
    dragging = true
  end)

  b:SetScript("OnDragStop", function()
    dragging = false
  end)

  b:SetScript("OnUpdate", function()
    if dragging then
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      cx = cx / scale
      cy = cy / scale
      GLS_DB.minimapAngle = getAngleDegrees(cx - mx, cy - my)
      updateMinimapButtonPosition()
    end
  end)

  minimapButton = b
  updateMinimapButtonPosition()
  b:Show()
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
    createOptionsUI()
    createMinimapButton()
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
      postSnark(name, quoteType, roster[name])
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
    DEFAULT_CHAT_FRAME:AddMessage("/gls ui  (toggle options window)")
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

  if cmd == "ui" then
    toggleOptionsUI()
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
    postSnark(name, "leave", 99, true)
    return
  end

  DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Unknown command. /gls help|r")
end
