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
  },
  quotesPromote = {
    "A surprise promotion appears.",
    "Climbing the ladder, one whisper at a time.",
    "Leadership saw potential. Bold call.",
    "Promoted for services to raid snacks.",
    "Their resume now says 'trusted'.",
    "Another step closer to guild politics.",
    "Grats on the new permissions.",
    "Promoted. Expectations increased.",
    "Someone found the promote button.",
    "Rank up achieved. Try not to abuse it."
  },
  quotesDemote = {
    "Gravity works on guild ranks too.",
    "Demoted to fewer responsibilities.",
    "Performance review was... brief.",
    "That rank did not survive the patch.",
    "Permissions have left the party.",
    "A tactical repositioning on the ladder.",
    "Demoted, but still in the raid.",
    "Promotion speedrun: any% failed.",
    "The guild has spoken.",
    "Back to proving grounds."
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
  if type(GLS_DB.quotesPromote) ~= "table" or table.getn(GLS_DB.quotesPromote) == 0 then
    GLS_DB.quotesPromote = {}
    for i=1, table.getn(defaults.quotesPromote) do GLS_DB.quotesPromote[i] = defaults.quotesPromote[i] end
  end
  if type(GLS_DB.quotesDemote) ~= "table" or table.getn(GLS_DB.quotesDemote) == 0 then
    GLS_DB.quotesDemote = {}
    for i=1, table.getn(defaults.quotesDemote) do GLS_DB.quotesDemote[i] = defaults.quotesDemote[i] end
  end
end

local function pickQuote(quoteType)
  local q
  if quoteType == "kick" then
    q = GLS_DB.quotesKick
  elseif quoteType == "promote" then
    q = GLS_DB.quotesPromote
  elseif quoteType == "demote" then
    q = GLS_DB.quotesDemote
  else
    q = GLS_DB.quotesLeave
  end
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

local function shouldPostForRank(rankIndex, quoteType)
  local minIndex = GLS_DB.rankMinIndex
  if not minIndex or minIndex < 0 then
    return true
  end
  if rankIndex == nil then
    if quoteType == "promote" or quoteType == "demote" then
      return true
    end
    return false
  end
  return rankIndex >= minIndex
end

local function postSnark(name, quoteType, rankIndex, bypassThrottle)
  if not GLS_DB.enabled then return end
  if not shouldPostForRank(rankIndex, quoteType) then
    if GLS_DB.debug then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[GLS Debug]|r rank filter blocked: "..tostring(name).." (type="..tostring(quoteType)..", rankIndex="..tostring(rankIndex)..")")
    end
    return
  end

  local ignoreThrottle = bypassThrottle or quoteType == "promote" or quoteType == "demote"
  if not ignoreThrottle and throttled() then
    if GLS_DB.debug then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[GLS Debug]|r throttled: "..tostring(name).." (type="..tostring(quoteType)..")")
    end
    return
  end

  local quote = pickQuote(quoteType)
  if not quote then
    if GLS_DB.debug then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[GLS Debug]|r no quote available for type="..tostring(quoteType))
    end
    return
  end

  local color = GLS_DB.color or "ff9900"
  local msg
  if GLS_DB.prefixName and name and name ~= "" then
    msg = "|cff" .. color .. name .. ": " .. quote .. "|r"
  else
    msg = "|cff" .. color .. quote .. "|r"
  end

  if GLS_DB.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[GLS Debug]|r sending "..tostring(quoteType).." snark to "..tostring(GLS_DB.channel or "GUILD"))
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
local testCycleTypes = {"leave", "kick", "promote", "demote"}
local testCycleLabels = {
  leave = "Leave",
  kick = "Kick",
  promote = "Promote",
  demote = "Demote"
}
local testCycleIndex = 1

local function currentTestType()
  return testCycleTypes[testCycleIndex] or "leave"
end

local function advanceTestType()
  testCycleIndex = testCycleIndex + 1
  if testCycleIndex > table.getn(testCycleTypes) then
    testCycleIndex = 1
  end
end

local function setTestTypeByName(mode)
  mode = string.lower(mode or "")
  if mode == "promotion" then mode = "promote" end
  if mode == "demotion" then mode = "demote" end

  for i=1, table.getn(testCycleTypes) do
    if testCycleTypes[i] == mode then
      testCycleIndex = i
      return true
    end
  end
  return false
end

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

local function quotesToText(quotes)
  if type(quotes) ~= "table" then return "" end

  local lines = {}
  for i=1, table.getn(quotes) do
    local q = quotes[i]
    if type(q) == "string" and q ~= "" then
      table.insert(lines, q)
    elseif q ~= nil then
      table.insert(lines, tostring(q))
    end
  end

  return table.concat(lines, "\n")
end

local function textToQuotes(text)
  local out = {}
  text = text or ""

  if string.gmatch then
    for line in string.gmatch(text, "[^\r\n]+") do
      line = string.gsub(line, "^%s+", "")
      line = string.gsub(line, "%s+$", "")
      if line ~= "" then
        table.insert(out, line)
      end
    end
  else
    local gfind = rawget(string, "gfind")
    if gfind then
      for line in gfind(text, "[^\r\n]+") do
        line = string.gsub(line, "^%s+", "")
        line = string.gsub(line, "%s+$", "")
        if line ~= "" then
          table.insert(out, line)
        end
      end
    end
  end

  return out
end

local function applyQuotesFromEditor(quoteType)
  local editor
  if quoteType == "kick" then
    editor = optionsControls.kickQuotesEdit
  elseif quoteType == "promote" then
    editor = optionsControls.promoteQuotesEdit
  elseif quoteType == "demote" then
    editor = optionsControls.demoteQuotesEdit
  else
    editor = optionsControls.leaveQuotesEdit
  end
  if not editor then return end

  local parsed = textToQuotes(editor:GetText())
  if table.getn(parsed) < 1 then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff6666At least one quote is required.|r")
    return
  end

  if quoteType == "kick" then
    GLS_DB.quotesKick = parsed
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffSaved kick quotes:|r " .. table.getn(parsed))
  elseif quoteType == "promote" then
    GLS_DB.quotesPromote = parsed
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffSaved promotion quotes:|r " .. table.getn(parsed))
  elseif quoteType == "demote" then
    GLS_DB.quotesDemote = parsed
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffSaved demotion quotes:|r " .. table.getn(parsed))
  else
    GLS_DB.quotesLeave = parsed
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffSaved leave quotes:|r " .. table.getn(parsed))
  end
end

local function setupQuoteEditorScrolling(scrollFrame, editBox)
  local scrollBar = nil
  if scrollFrame and scrollFrame.GetName then
    local n = scrollFrame:GetName()
    if n and n ~= "" then
      scrollBar = _G[n .. "ScrollBar"]
    end
  end

  local syncingScroll = false

  local function setScroll(value)
    local maxScroll = editBox:GetHeight() - scrollFrame:GetHeight()
    if maxScroll < 0 then maxScroll = 0 end

    if value < 0 then value = 0 end
    if value > maxScroll then value = maxScroll end

    if syncingScroll then return end
    syncingScroll = true
    scrollFrame:SetVerticalScroll(value)
    if scrollBar then
      scrollBar:SetValue(value)
    end
    syncingScroll = false
  end

  local function updateScrollMetrics()
    local minHeight = scrollFrame:GetHeight()
    local contentHeight
    if editBox.GetStringHeight then
      contentHeight = editBox:GetStringHeight() + 28
    else
      local text = editBox:GetText() or ""
      local lines = 1
      if string.gmatch then
        for _ in string.gmatch(text, "\n") do
          lines = lines + 1
        end
      else
        local gfind = rawget(string, "gfind")
        if gfind then
          for _ in gfind(text, "\n") do
            lines = lines + 1
          end
        end
      end
      contentHeight = (lines * 16) + 28
    end
    if contentHeight < minHeight then
      contentHeight = minHeight
    end
    editBox:SetHeight(contentHeight)

    local maxScroll = contentHeight - minHeight
    if maxScroll < 0 then maxScroll = 0 end

    local current = scrollFrame:GetVerticalScroll()
    if current > maxScroll then
      current = maxScroll
      scrollFrame:SetVerticalScroll(current)
    end

    if scrollBar then
      scrollBar:SetMinMaxValues(0, maxScroll)
      scrollBar:SetValue(current)
    end
  end

  editBox.GLS_UpdateScrollMetrics = updateScrollMetrics

  editBox:SetScript("OnTextChanged", function()
    updateScrollMetrics()
  end)

  editBox:SetScript("OnCursorChanged", nil)

  scrollFrame:SetScript("OnVerticalScroll", function()
    if syncingScroll then return end
    if scrollBar then
      syncingScroll = true
      scrollBar:SetValue(arg1)
      syncingScroll = false
    end
  end)

  if scrollBar then
    scrollBar:SetScript("OnValueChanged", function()
      setScroll(arg1 or 0)
    end)
  end

  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function()
    local step = 20
    local current = scrollFrame:GetVerticalScroll()
    local delta = arg1 or 0
    if delta > 0 then
      current = current - step
    else
      current = current + step
    end
    setScroll(current)
  end)

  updateScrollMetrics()
end

local function updateOptionsUI()
  if not optionsFrame then return end

  if optionsControls.enabled then
    optionsControls.enabled:SetChecked(GLS_DB.enabled and true or false)
  end
  if optionsControls.prefix then
    optionsControls.prefix:SetChecked(GLS_DB.prefixName and true or false)
  end
  if optionsControls.debug then
    optionsControls.debug:SetChecked(GLS_DB.debug and true or false)
  end
  if optionsControls.channelButton then
    optionsControls.channelButton:SetText("Channel: " .. tostring(GLS_DB.channel or "GUILD"))
  end

  if optionsControls.rankEdit then
    local rankMin = tonumber(GLS_DB.rankMinIndex)
    if rankMin and rankMin >= 0 then
      rankMin = math.floor(rankMin)
      GLS_DB.rankMinIndex = rankMin
      optionsControls.rankEdit:SetText(tostring(rankMin))
    else
      GLS_DB.rankMinIndex = -1
      optionsControls.rankEdit:SetText("all")
    end
  end

  local colorHex = GLS_DB.color
  if type(colorHex) ~= "string" or string.len(colorHex) ~= 6 then
    colorHex = "ff9900"
  end

  if optionsControls.colorButton then
    optionsControls.colorButton:SetText(string.format("Pick Color: #%s", colorHex))
  end
  if optionsControls.testModeButton then
    optionsControls.testModeButton:SetText("Mode: " .. (testCycleLabels[currentTestType()] or "Leave"))
  end
  if optionsControls.leaveQuotesEdit then
    optionsControls.leaveQuotesEdit:SetText(quotesToText(GLS_DB.quotesLeave))
    if optionsControls.leaveQuotesEdit.GLS_UpdateScrollMetrics then
      optionsControls.leaveQuotesEdit.GLS_UpdateScrollMetrics()
    end
  end
  if optionsControls.kickQuotesEdit then
    optionsControls.kickQuotesEdit:SetText(quotesToText(GLS_DB.quotesKick))
    if optionsControls.kickQuotesEdit.GLS_UpdateScrollMetrics then
      optionsControls.kickQuotesEdit.GLS_UpdateScrollMetrics()
    end
  end
  if optionsControls.promoteQuotesEdit then
    optionsControls.promoteQuotesEdit:SetText(quotesToText(GLS_DB.quotesPromote))
    if optionsControls.promoteQuotesEdit.GLS_UpdateScrollMetrics then
      optionsControls.promoteQuotesEdit.GLS_UpdateScrollMetrics()
    end
  end
  if optionsControls.demoteQuotesEdit then
    optionsControls.demoteQuotesEdit:SetText(quotesToText(GLS_DB.quotesDemote))
    if optionsControls.demoteQuotesEdit.GLS_UpdateScrollMetrics then
      optionsControls.demoteQuotesEdit.GLS_UpdateScrollMetrics()
    end
  end
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
  frame:SetWidth(700)
  frame:SetHeight(640)
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

  local closeBtn = CreateFrame("Button", "GLS_OptionsCloseButton", frame, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

  local enabled = CreateFrame("CheckButton", "GLS_EnabledCheck", frame, "UICheckButtonTemplate")
  enabled:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -56)
  enabled:SetScript("OnClick", function()
    GLS_DB.enabled = enabled:GetChecked() and true or false
  end)
  local enabledText = _G["GLS_EnabledCheckText"] or (enabled.GetName and _G[(enabled:GetName() or "") .. "Text"])
  if enabledText then
    enabledText:SetText("Enabled")
  end
  optionsControls.enabled = enabled

  local prefix = CreateFrame("CheckButton", "GLS_PrefixCheck", frame, "UICheckButtonTemplate")
  prefix:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 0, -8)
  prefix:SetScript("OnClick", function()
    GLS_DB.prefixName = prefix:GetChecked() and true or false
  end)
  local prefixText = _G["GLS_PrefixCheckText"] or (prefix.GetName and _G[(prefix:GetName() or "") .. "Text"])
  if prefixText then
    prefixText:SetText("Prefix player name")
  end
  optionsControls.prefix = prefix

  local debug = CreateFrame("CheckButton", "GLS_DebugCheck", frame, "UICheckButtonTemplate")
  debug:SetPoint("TOPLEFT", frame, "TOPLEFT", 245, -56)
  debug:SetScript("OnClick", function()
    GLS_DB.debug = debug:GetChecked() and true or false
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark debug mode =|r " .. tostring(GLS_DB.debug))
    if GLS_DB.debug then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[GLS Debug]|r Debug logging enabled for CHAT_MSG_SYSTEM.")
    end
  end)
  local debugText = _G["GLS_DebugCheckText"] or (debug.GetName and _G[(debug:GetName() or "") .. "Text"])
  if debugText then
    debugText:SetText("Debug mode")
  end
  optionsControls.debug = debug

  local channelButton = CreateFrame("Button", "GLS_ChannelButton", frame, "UIPanelButtonTemplate")
  channelButton:SetWidth(190)
  channelButton:SetHeight(22)
  channelButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 468, -56)
  channelButton:SetScript("OnClick", function()
    GLS_DB.channel = nextChannel(GLS_DB.channel)
    channelButton:SetText("Channel: " .. GLS_DB.channel)
  end)
  optionsControls.channelButton = channelButton

  local rankLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  rankLabel:SetPoint("TOPLEFT", debug, "BOTTOMLEFT", 4, -12)
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

  local rankApply = CreateFrame("Button", "GLS_RankApplyButton", frame, "UIPanelButtonTemplate")
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
  colorLabel:SetPoint("TOPLEFT", channelButton, "BOTTOMLEFT", 0, -14)
  colorLabel:SetText("Message color")

  local colorButton = CreateFrame("Button", "GLS_ColorButton", frame, "UIPanelButtonTemplate")
  colorButton:SetWidth(170)
  colorButton:SetHeight(22)
  colorButton:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 0, -6)
  colorButton:SetScript("OnClick", openColorPicker)
  optionsControls.colorButton = colorButton

  local leaveLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  leaveLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -210)
  leaveLabel:SetText("Leave quotes (one per line)")

  local leaveSaveBtn = CreateFrame("Button", "GLS_LeaveSaveButton", frame, "UIPanelButtonTemplate")
  leaveSaveBtn:SetWidth(80)
  leaveSaveBtn:SetHeight(20)
  leaveSaveBtn:SetPoint("LEFT", leaveLabel, "RIGHT", 8, 0)
  leaveSaveBtn:SetText("Save")
  leaveSaveBtn:SetScript("OnClick", function() applyQuotesFromEditor("leave") end)

  local leaveScroll = CreateFrame("ScrollFrame", "GLS_LeaveQuotesScroll", frame, "UIPanelScrollFrameTemplate")
  leaveScroll:SetWidth(300)
  leaveScroll:SetHeight(150)
  leaveScroll:SetPoint("TOPLEFT", leaveLabel, "BOTTOMLEFT", 0, -8)

  local leaveEdit = CreateFrame("EditBox", nil, leaveScroll)
  leaveEdit:SetWidth(278)
  leaveEdit:SetHeight(150)
  leaveEdit:SetAutoFocus(false)
  leaveEdit:SetMultiLine(true)
  leaveEdit:SetFontObject(ChatFontNormal)
  leaveEdit:SetJustifyH("LEFT")
  leaveEdit:SetJustifyV("TOP")
  leaveEdit:SetTextInsets(4, 4, 4, 6)
  leaveEdit:SetPoint("TOPLEFT", leaveScroll, "TOPLEFT", 0, 0)
  leaveEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  leaveScroll:SetScrollChild(leaveEdit)
  setupQuoteEditorScrolling(leaveScroll, leaveEdit)
  optionsControls.leaveQuotesEdit = leaveEdit

  local kickLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  kickLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 360, -210)
  kickLabel:SetText("Kick quotes (one per line)")

  local kickSaveBtn = CreateFrame("Button", "GLS_KickSaveButton", frame, "UIPanelButtonTemplate")
  kickSaveBtn:SetWidth(80)
  kickSaveBtn:SetHeight(20)
  kickSaveBtn:SetPoint("LEFT", kickLabel, "RIGHT", 8, 0)
  kickSaveBtn:SetText("Save")
  kickSaveBtn:SetScript("OnClick", function() applyQuotesFromEditor("kick") end)

  local kickScroll = CreateFrame("ScrollFrame", "GLS_KickQuotesScroll", frame, "UIPanelScrollFrameTemplate")
  kickScroll:SetWidth(300)
  kickScroll:SetHeight(150)
  kickScroll:SetPoint("TOPLEFT", kickLabel, "BOTTOMLEFT", 0, -8)

  local kickEdit = CreateFrame("EditBox", nil, kickScroll)
  kickEdit:SetWidth(278)
  kickEdit:SetHeight(150)
  kickEdit:SetAutoFocus(false)
  kickEdit:SetMultiLine(true)
  kickEdit:SetFontObject(ChatFontNormal)
  kickEdit:SetJustifyH("LEFT")
  kickEdit:SetJustifyV("TOP")
  kickEdit:SetTextInsets(4, 4, 4, 6)
  kickEdit:SetPoint("TOPLEFT", kickScroll, "TOPLEFT", 0, 0)
  kickEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  kickScroll:SetScrollChild(kickEdit)
  setupQuoteEditorScrolling(kickScroll, kickEdit)
  optionsControls.kickQuotesEdit = kickEdit

  local promoteLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  promoteLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -410)
  promoteLabel:SetText("Promotion quotes (one per line)")

  local promoteSaveBtn = CreateFrame("Button", "GLS_PromoteSaveButton", frame, "UIPanelButtonTemplate")
  promoteSaveBtn:SetWidth(80)
  promoteSaveBtn:SetHeight(20)
  promoteSaveBtn:SetPoint("LEFT", promoteLabel, "RIGHT", 8, 0)
  promoteSaveBtn:SetText("Save")
  promoteSaveBtn:SetScript("OnClick", function() applyQuotesFromEditor("promote") end)

  local promoteScroll = CreateFrame("ScrollFrame", "GLS_PromoteQuotesScroll", frame, "UIPanelScrollFrameTemplate")
  promoteScroll:SetWidth(300)
  promoteScroll:SetHeight(150)
  promoteScroll:SetPoint("TOPLEFT", promoteLabel, "BOTTOMLEFT", 0, -8)

  local promoteEdit = CreateFrame("EditBox", nil, promoteScroll)
  promoteEdit:SetWidth(278)
  promoteEdit:SetHeight(150)
  promoteEdit:SetAutoFocus(false)
  promoteEdit:SetMultiLine(true)
  promoteEdit:SetFontObject(ChatFontNormal)
  promoteEdit:SetJustifyH("LEFT")
  promoteEdit:SetJustifyV("TOP")
  promoteEdit:SetTextInsets(4, 4, 4, 6)
  promoteEdit:SetPoint("TOPLEFT", promoteScroll, "TOPLEFT", 0, 0)
  promoteEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  promoteScroll:SetScrollChild(promoteEdit)
  setupQuoteEditorScrolling(promoteScroll, promoteEdit)
  optionsControls.promoteQuotesEdit = promoteEdit

  local demoteLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  demoteLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 360, -410)
  demoteLabel:SetText("Demotion quotes (one per line)")

  local demoteSaveBtn = CreateFrame("Button", "GLS_DemoteSaveButton", frame, "UIPanelButtonTemplate")
  demoteSaveBtn:SetWidth(80)
  demoteSaveBtn:SetHeight(20)
  demoteSaveBtn:SetPoint("LEFT", demoteLabel, "RIGHT", 8, 0)
  demoteSaveBtn:SetText("Save")
  demoteSaveBtn:SetScript("OnClick", function() applyQuotesFromEditor("demote") end)

  local demoteScroll = CreateFrame("ScrollFrame", "GLS_DemoteQuotesScroll", frame, "UIPanelScrollFrameTemplate")
  demoteScroll:SetWidth(300)
  demoteScroll:SetHeight(150)
  demoteScroll:SetPoint("TOPLEFT", demoteLabel, "BOTTOMLEFT", 0, -8)

  local demoteEdit = CreateFrame("EditBox", nil, demoteScroll)
  demoteEdit:SetWidth(278)
  demoteEdit:SetHeight(150)
  demoteEdit:SetAutoFocus(false)
  demoteEdit:SetMultiLine(true)
  demoteEdit:SetFontObject(ChatFontNormal)
  demoteEdit:SetJustifyH("LEFT")
  demoteEdit:SetJustifyV("TOP")
  demoteEdit:SetTextInsets(4, 4, 4, 6)
  demoteEdit:SetPoint("TOPLEFT", demoteScroll, "TOPLEFT", 0, 0)
  demoteEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  demoteScroll:SetScrollChild(demoteEdit)
  setupQuoteEditorScrolling(demoteScroll, demoteEdit)
  optionsControls.demoteQuotesEdit = demoteEdit

  local testBtn = CreateFrame("Button", "GLS_TestButton", frame, "UIPanelButtonTemplate")
  testBtn:SetWidth(120)
  testBtn:SetHeight(22)
  testBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 22)
  testBtn:SetText("Send Test")
  testBtn:SetScript("OnClick", function()
    local quoteType = currentTestType()
    postSnark(UnitName("player") or "Someone", quoteType, 99, true)
  end)
  optionsControls.testSendButton = testBtn

  local cycleBtn = CreateFrame("Button", "GLS_TestCycleButton", frame, "UIPanelButtonTemplate")
  cycleBtn:SetWidth(130)
  cycleBtn:SetHeight(22)
  cycleBtn:SetPoint("LEFT", testBtn, "RIGHT", 8, 0)
  cycleBtn:SetText("Mode: " .. (testCycleLabels[currentTestType()] or "Leave"))
  cycleBtn:SetScript("OnClick", function()
    advanceTestType()
    cycleBtn:SetText("Mode: " .. (testCycleLabels[currentTestType()] or "Leave"))
  end)
  optionsControls.testModeButton = cycleBtn

  local closeBottomBtn = CreateFrame("Button", "GLS_CloseBottomButton", frame, "UIPanelButtonTemplate")
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

local function normalizePlayerName(name)
  if not name then return nil end
  name = tostring(name)

  name = string.gsub(name, "|c%x%x%x%x%x%x%x%x", "")
  name = string.gsub(name, "|r", "")

  local _, _, linked = string.find(name, "|H.-|h%[?([^%]|]+)%]?|h")
  if linked and linked ~= "" then
    name = linked
  end

  local _, _, bracketed = string.find(name, "^%[(.+)%]$")
  if bracketed and bracketed ~= "" then
    name = bracketed
  end

  name = string.gsub(name, "%-.*$", "")
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%s+$", "")
  if name == "" then return nil end
  return name
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

  b.background = b:CreateTexture(nil, "BACKGROUND")
  b.background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  b.background:SetWidth(20)
  b.background:SetHeight(20)
  b.background:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.background:SetVertexColor(0, 0, 0, 0.9)

  b.icon = b:CreateTexture(nil, "OVERLAY")
  b.icon:SetTexture("Interface\\Icons\\Ability_Racial_Cannibalize")
  b.icon:SetWidth(17)
  b.icon:SetHeight(17)
  b.icon:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)

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
-- Returns: name, type ("leave", "kick", "promote", "demote")
local function parseLeftGuild(systemMsg)
  if not systemMsg then return nil, nil end
  -- Voluntary leave: "Name has left the guild."
  local _, _, n = string.find(systemMsg, "^(.+) has left the guild%.$")
  if n then return n, "leave" end
  -- Some clients/servers omit the period:
  _, _, n = string.find(systemMsg, "^(.+) has left the guild$")
  if n then return n, "leave" end
  -- Guild kick variants:
  -- "Name has been kicked out of the guild by KickerName"
  -- "Name has been kicked from the guild by KickerName"
  -- "Name was kicked from the guild by KickerName"
  local kickPatterns = {
    "^(.+) has been kicked out of the guild by .+%.$",
    "^(.+) has been kicked out of the guild by .+$",
    "^(.+) has been kicked from the guild by .+%.$",
    "^(.+) has been kicked from the guild by .+$",
    "^(.+) was kicked from the guild by .+%.$",
    "^(.+) was kicked from the guild by .+$",
    "^(.+) has been removed from the guild by .+%.$",
    "^(.+) has been removed from the guild by .+$",
    "^(.+) has been kicked out of the guild%.$",
    "^(.+) has been kicked out of the guild$",
    "^(.+) has been kicked from the guild%.$",
    "^(.+) has been kicked from the guild$",
    "^(.+) has been removed from the guild%.$",
    "^(.+) has been removed from the guild$"
  }

  for i=1, table.getn(kickPatterns) do
    _, _, n = string.find(systemMsg, kickPatterns[i])
    if n then return n, "kick" end
  end

  -- "You have kicked Name out of the guild."
  -- "You have kicked Name from the guild."
  _, _, n = string.find(systemMsg, "^You have kicked (.+) out of the guild%.$")
  if n then return n, "kick" end
  _, _, n = string.find(systemMsg, "^You have kicked (.+) out of the guild$")
  if n then return n, "kick" end
  _, _, n = string.find(systemMsg, "^You have kicked (.+) from the guild%.$")
  if n then return n, "kick" end
  _, _, n = string.find(systemMsg, "^You have kicked (.+) from the guild$")
  if n then return n, "kick" end

  -- "You have removed Name from the guild."
  _, _, n = string.find(systemMsg, "^You have removed (.+) from the guild%.$")
  if n then return n, "kick" end
  _, _, n = string.find(systemMsg, "^You have removed (.+) from the guild$")
  if n then return n, "kick" end

  -- Promotion variants
  -- "Actor has promoted Target to Rank"
  _, _, n = string.find(systemMsg, "^.+ has promoted (.+) to .+%.$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^.+ has promoted (.+) to .+$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^(.+) has been promoted to .+%.$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^(.+) has been promoted to .+$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^(.+) has been promoted%.$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^(.+) has been promoted$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^(.+) was promoted to .+%.$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^(.+) was promoted to .+$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^(.+) was promoted%.$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^(.+) was promoted$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^You have promoted (.+) to .+%.$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^You have promoted (.+) to .+$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^You have promoted (.+)%.$")
  if n then return n, "promote" end
  _, _, n = string.find(systemMsg, "^You have promoted (.+)$")
  if n then return n, "promote" end

  -- Demotion variants
  -- "Actor has demoted Target to Rank"
  _, _, n = string.find(systemMsg, "^.+ has demoted (.+) to .+%.$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^.+ has demoted (.+) to .+$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^(.+) has been demoted to .+%.$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^(.+) has been demoted to .+$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^(.+) has been demoted%.$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^(.+) has been demoted$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^(.+) was demoted to .+%.$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^(.+) was demoted to .+$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^(.+) was demoted%.$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^(.+) was demoted$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^You have demoted (.+) to .+%.$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^You have demoted (.+) to .+$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^You have demoted (.+)%.$")
  if n then return n, "demote" end
  _, _, n = string.find(systemMsg, "^You have demoted (.+)$")
  if n then return n, "demote" end

  return nil, nil
end

-- Approach B: roster diff fallback
local roster = {}
local knownRanks = {}
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
        knownRanks[name] = rankIndex
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
      name = normalizePlayerName(name)
      if not name then return end

      if quoteType == "promote" or quoteType == "demote" then
        scanRoster()
      end

      local rankIndex = roster[name]
      if rankIndex == nil then
        rankIndex = knownRanks[name]
      end
      postSnark(name, quoteType, rankIndex)
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
    DEFAULT_CHAT_FRAME:AddMessage('/gls addpromotion <quote>  (add promotion quote)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls adddemotion <quote>  (add demotion quote)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls removeleave <num>  (remove by number)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls removekick <num>  (remove by number)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls removepromotion <num>  (remove by number)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls removedemotion <num>  (remove by number)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls list  (show all quotes)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls clear  (restore default quotes)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls add <quote>  (alias for addleave)')
    DEFAULT_CHAT_FRAME:AddMessage('/gls testmode [leave|kick|promote|demote]')
    DEFAULT_CHAT_FRAME:AddMessage('/gls test <name>  (send quick leave test)')
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

  if cmd == "testmode" then
    local mode = string.lower(rest or "")
    if mode == "" then
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark test mode:|r " .. (testCycleLabels[currentTestType()] or "Leave"))
      return
    end

    if setTestTypeByName(mode) then
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark test mode set to|r " .. (testCycleLabels[currentTestType()] or "Leave"))
      updateOptionsUI()
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls testmode leave|kick|promote|demote|r")
    end
    return
  end

  if cmd == "add" or cmd == "addleave" then
    if rest and rest ~= "" then
      table.insert(GLS_DB.quotesLeave, rest)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffAdded leave quote (#"..table.getn(GLS_DB.quotesLeave)..")|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls addleave <quote text>|r")
    end
    return
  end

  if cmd == "addkick" then
    if rest and rest ~= "" then
      table.insert(GLS_DB.quotesKick, rest)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffAdded kick quote (#"..table.getn(GLS_DB.quotesKick)..")|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls addkick <quote text>|r")
    end
    return
  end

  if cmd == "addpromotion" then
    if rest and rest ~= "" then
      table.insert(GLS_DB.quotesPromote, rest)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffAdded promotion quote (#"..table.getn(GLS_DB.quotesPromote)..")|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls addpromotion <quote text>|r")
    end
    return
  end

  if cmd == "adddemotion" then
    if rest and rest ~= "" then
      table.insert(GLS_DB.quotesDemote, rest)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffAdded demotion quote (#"..table.getn(GLS_DB.quotesDemote)..")|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls adddemotion <quote text>|r")
    end
    return
  end

  if cmd == "removeleave" then
    local n = tonumber(rest)
    if n and n >= 1 and n <= table.getn(GLS_DB.quotesLeave) then
      table.remove(GLS_DB.quotesLeave, n)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRemoved leave quote #"..n.."|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls removeleave <number>|r")
    end
    return
  end

  if cmd == "removekick" then
    local n = tonumber(rest)
    if n and n >= 1 and n <= table.getn(GLS_DB.quotesKick) then
      table.remove(GLS_DB.quotesKick, n)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRemoved kick quote #"..n.."|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls removekick <number>|r")
    end
    return
  end

  if cmd == "removepromotion" then
    local n = tonumber(rest)
    if n and n >= 1 and n <= table.getn(GLS_DB.quotesPromote) then
      table.remove(GLS_DB.quotesPromote, n)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRemoved promotion quote #"..n.."|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls removepromotion <number>|r")
    end
    return
  end

  if cmd == "removedemotion" then
    local n = tonumber(rest)
    if n and n >= 1 and n <= table.getn(GLS_DB.quotesDemote) then
      table.remove(GLS_DB.quotesDemote, n)
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRemoved demotion quote #"..n.."|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Usage: /gls removedemotion <number>|r")
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
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark Promotion Quotes ("..table.getn(GLS_DB.quotesPromote).."):|r")
    for i=1, table.getn(GLS_DB.quotesPromote) do
      DEFAULT_CHAT_FRAME:AddMessage(i..": "..GLS_DB.quotesPromote[i])
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark Demotion Quotes ("..table.getn(GLS_DB.quotesDemote).."):|r")
    for i=1, table.getn(GLS_DB.quotesDemote) do
      DEFAULT_CHAT_FRAME:AddMessage(i..": "..GLS_DB.quotesDemote[i])
    end
    return
  end

  if cmd == "clear" then
    GLS_DB.quotesLeave = {}
    for i=1, table.getn(defaults.quotesLeave) do GLS_DB.quotesLeave[i] = defaults.quotesLeave[i] end
    GLS_DB.quotesKick = {}
    for i=1, table.getn(defaults.quotesKick) do GLS_DB.quotesKick[i] = defaults.quotesKick[i] end
    GLS_DB.quotesPromote = {}
    for i=1, table.getn(defaults.quotesPromote) do GLS_DB.quotesPromote[i] = defaults.quotesPromote[i] end
    GLS_DB.quotesDemote = {}
    for i=1, table.getn(defaults.quotesDemote) do GLS_DB.quotesDemote[i] = defaults.quotesDemote[i] end
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffGuildLeaveSnark quotes reset to defaults.|r")
    updateOptionsUI()
    return
  end

  if cmd == "test" then
    local name = rest ~= "" and rest or "Someone"
    postSnark(name, "leave", 99, true)
    return
  end

  DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Unknown command. /gls help|r")
end
