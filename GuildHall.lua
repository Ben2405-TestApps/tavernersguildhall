local ADDON, ns = ...
local Core = _G.TavernersCore
if not Core then return end

local DB = Core.Database:Register("TavernersGuildHallDB", {version=2, minimised=false, noticeboard={}, bank={}, pvp={battlegrounds=0,wins=0,losses=0,honour=0}, goals={}}, 2)
local Hall = {db=DB}
Core:RegisterModule("GuildHall", Hall)

local frame, body, rows = nil, nil, {}
local cursorY = -6
local function AddLine(text, template)
  local fs = body:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
  fs:SetPoint("TOPLEFT", 12, cursorY)
  fs:SetWidth(650); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true)
  fs:SetText(text)
  local height = math.max(18, fs:GetStringHeight() or 18)
  cursorY = cursorY - height - 7
  rows[#rows+1] = fs
end
local function Clear()
  for _, row in ipairs(rows) do row:Hide(); row:SetParent(nil) end
  rows = {}
  cursorY = -6
end
local function CountQuests(module)
  if not module then return nil end
  if module.GetActiveCount then return module:GetActiveCount() end
  if module.active then return #module.active end
  return nil
end
function Hall:Refresh()
  if not body then return end
  Clear()
  local p = Core.Identity:GetPlayer()
  local level = UnitLevel and UnitLevel("player") or "?"
  local faction = UnitFactionGroup and UnitFactionGroup("player") or "Unknown"
  AddLine("|cffffd27aTHE TAVERNERS GUILD HALL|r", "GameFontNormalLarge")
  AddLine((p.name or "Unknown") .. "-" .. (p.realm or "Unknown") .. "  •  " .. tostring(p.class or "Unknown") .. "  •  Level " .. tostring(level) .. "  •  " .. faction, "GameFontNormal")
  AddLine(" ")
  local modules = Core.modules or {}
  local q = modules.QuestCompanion
  local g = modules.GearGuide
  local d = modules.DungeonTool
  local c = modules.CraftingDirectory or _G.TCD
  local a = modules.AmmoGuard
  local function status(name, mod, detail)
    AddLine((mod and "|cff55dd77●|r " or "|cffcc7770○|r ") .. name .. (detail and ("  —  " .. detail) or (mod and "  —  Ready" or "  —  Not loaded")))
  end
  status("Quest Companion", q, q and (q.GetDashboardSummary and q:GetDashboardSummary() or (tostring(CountQuests(q) or 0) .. " active quests")) or nil)
  status("Gear Guide", g, g and (g.GetDashboardSummary and g:GetDashboardSummary() or "Profile and equipped gear") or nil)
  status("Dungeon Tool", d, d and (d.GetDashboardSummary and d:GetDashboardSummary() or "Dungeon journal and maps") or nil)
  status("Crafting Directory", c, c and "Guild crafters and recipes" or nil)
  status("Ammo Guard", a, a and "Ammunition monitoring" or nil)
  AddLine(" ")
  AddLine("|cffffd27aQUICK ACTIONS|r", "GameFontNormal")
  AddLine("/tquest  —  Quest and leveling companion")
  AddLine("/tgear  —  Gear guide")
  AddLine("/tdungeon  —  Dungeon journal")
  AddLine("/tcd  —  Crafting directory (when installed)")
  AddLine("/tammoguard  —  Ammo Guard (when installed)")
  AddLine(" ")
  local roster = Core.Guild:RefreshRoster()
  local online, total = 0, 0
  for name, isOnline in pairs(roster or {}) do
    if not name:find("%-") then total = total + 1; if isOnline then online = online + 1 end end
  end
  AddLine("|cffffd27aGUILD ROSTER|r", "GameFontNormal")
  AddLine(IsInGuild and IsInGuild() and (online .. " online roster entries • " .. total .. " listed") or "Not currently in a guild.")
  if c and c.DB and c.DB.profiles then
    local profileCount, recipeCount, professions = 0, 0, {}
    for _, profile in pairs(c.DB.profiles) do
      profileCount = profileCount + 1
      for profession, detail in pairs(profile.professions or {}) do
        professions[profession] = true
        if type(detail) == "table" then recipeCount = recipeCount + #(detail.recipes or {}) end
      end
      for _ in pairs(profile.recipes or {}) do recipeCount = recipeCount + 1 end
    end
    local names = {}
    for profession in pairs(professions) do names[#names+1] = profession end
    table.sort(names)
    local shown = {}
    for i=1,math.min(6,#names) do shown[#shown+1] = names[i] end
    AddLine("|cffffd27aCRAFTING DIRECTORY|r", "GameFontNormal")
    AddLine(profileCount .. " crafter profiles stored • " .. #names .. " profession types recorded")
    if #shown > 0 then AddLine("Professions: " .. table.concat(shown, ", ") .. (#names > #shown and " …" or "")) end
    AddLine("Recipe records are held locally and grow as members scan and share their professions.")
  else
    AddLine("|cffffd27aCRAFTING DIRECTORY|r", "GameFontNormal")
    AddLine("Install/load Crafting Directory to see stored crafter profiles here.")
  end
  AddLine(" ")
  AddLine("|cffd9c49aYour Guild Hall is a local dashboard. Roster and crafting figures reflect data available to this client; guild-wide sharing depends on members using the relevant sync features.|r", "GameFontHighlightSmall")
  body:SetHeight(math.max(300, -cursorY + 30))
end
local function OpenModule(name)
  local module = (Core.modules or {})[name]
  if name == "CraftingDirectory" and _G.TCD and _G.TCD.ToggleUI then _G.TCD:ToggleUI(); return end
  if module and module.UI and module.UI.Toggle then module.UI:Toggle()
  elseif module and module.UI and module.UI.ToggleUI then module.UI:ToggleUI()
  else Core.Notifications:Print(name .. " is not loaded.") end
end
local function Build()
  if frame then return end
  frame = CreateFrame("Frame", "TavernersGuildHallFrame", UIParent)
  frame:SetSize(720, 570); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  if frame.SetBackdrop then
    frame:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",edgeFile="Interface/Tooltips/UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    frame:SetBackdropColor(.07,.05,.035,.97)
  end
  local title=frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  title:SetPoint("TOPLEFT",18,-16); title:SetText("|cffffd27aThe Taverners|r — Guild Hall")
  local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-4,-4)
    local actions={{"Quests","QuestCompanion"},{"Gear","GearGuide"},{"Dungeons","DungeonTool"},{"Crafting","CraftingDirectory"},{"Ammo","AmmoGuard"}}
  local x=18
  for _,action in ipairs(actions) do
    local label, moduleName = action[1], action[2]
    local b=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
    b:SetSize(118,24); b:SetPoint("TOPLEFT",x,-48); b:SetText(label)
    b:SetScript("OnClick",function() OpenModule(moduleName) end)
    x=x+124
  end
  local scroll=CreateFrame("ScrollFrame","TavernersGuildHallScroll",frame,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",18,-82); scroll:SetPoint("BOTTOMRIGHT",-36,18)
  body=CreateFrame("Frame",nil,scroll); body:SetSize(660,400); scroll:SetScrollChild(body)
end
function Hall:Toggle()
  Build()
  if frame:IsShown() then frame:Hide() else frame:Show(); self:Refresh() end
end
SLASH_TAVERNERSGUILDHALL1="/tgh"; SLASH_TAVERNERSGUILDHALL2="/guildhall"
SlashCmdList=SlashCmdList or {}
SlashCmdList.TAVERNERSGUILDHALL=function(msg) local value=tostring(msg or ""); if value:lower()=="refresh" then Hall:Refresh() elseif value=="" then Hall:Toggle() else HandleGuildCommand(value) end end
local ev=CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("GUILD_ROSTER_UPDATE")
ev:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_LOGIN" then
    Build(); Hall:Refresh()
  elseif event=="GUILD_ROSTER_UPDATE" then
    Core.Guild:RefreshRoster()
  end
end)


-- Guild services stored locally for now. Guild-wide sharing will use the
-- Core communication layer after protocol and moderation testing.
local function EnsureLists()
  DB.noticeboard = DB.noticeboard or {}
  DB.bank = DB.bank or {}
  DB.goals = DB.goals or {}
  DB.events = DB.events or {}
  DB.groups = DB.groups or {}
  DB.pvp = DB.pvp or {}
  DB.pvp.battlegrounds = tonumber(DB.pvp.battlegrounds) or 0
  DB.pvp.wins = tonumber(DB.pvp.wins) or 0
  DB.pvp.losses = tonumber(DB.pvp.losses) or 0
  DB.pvp.honour = tonumber(DB.pvp.honour) or 0
end
EnsureLists()

-- Guild-wide data replication. This is peer-to-peer addon messaging, not a
-- server database: online Taverners clients exchange records and keep local
-- SavedVariables copies. Offline clients catch up when they next log in.
local SYNC_PREFIX = "TAVGH2"
local syncPeers, syncCounter = {}, 0
local function Encode(value)
  return tostring(value or ""):gsub("([^%w%-%_%.~])", function(ch)
    return string.format("%%%02X", string.byte(ch))
  end)
end
local function Decode(value)
  return tostring(value or ""):gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex,16))
  end)
end
local function SplitPacket(message)
  local fields = {}
  for field in (tostring(message or "") .. "|"):gmatch("(.-)|") do
    fields[#fields+1] = field
  end
  return fields
end
local function RecordList(kind)
  if kind=="notice" then return DB.noticeboard end
  if kind=="bank" then return DB.bank end
  if kind=="goal" then return DB.goals end
  if kind=="event" then return DB.events end
  if kind=="group" then return DB.groups end
  if kind=="pvp" then DB.pvpLog=DB.pvpLog or {}; return DB.pvpLog end
end
local function NextRecordID()
  syncCounter=syncCounter+1
  return tostring(UnitName("player") or "Unknown")..":"..tostring(Core.Util:Now())..":"..tostring(syncCounter)
end
local function FindRecord(list,id)
  for _,record in ipairs(list or {}) do if record.id==id then return record end end
end
local function PackRecord(kind,record,operation)
  local values={}
  if kind=="notice" then values={record.text}
  elseif kind=="bank" then values={record.item,record.quantity,record.action}
  elseif kind=="goal" then values={record.text,record.done and "1" or "0"}
  elseif kind=="event" then values={record.date,record.time,record.title}
  elseif kind=="group" then values={record.role,record.dungeon,record.filled and "1" or "0"}
  elseif kind=="pvp" then values={record.result,record.honour or 0}
  else return nil end
  local parts={"1",operation or "PUT",kind,Encode(record.id),tostring(record.created or record.updated or 0),Encode(record.author)}
  for _,value in ipairs(values) do parts[#parts+1]=Encode(value) end
  local packet=table.concat(parts,"|")
  if #packet>240 then return nil end
  return packet
end
local function SendRecord(kind,record,channel,target,operation)
  local packet=PackRecord(kind,record,operation)
  if packet then Core.Comm:Send(SYNC_PREFIX,packet,channel or "GUILD",target)
  else Core.Notifications:Print("A guild record was too long to synchronise.") end
end
local function PublishRecord(kind,record)
  local list=RecordList(kind)
  if not list then return false end
  record.id=record.id or NextRecordID()
  record.created=record.created or Core.Util:Now()
  record.author=record.author or UnitName("player")
  list[#list+1]=record
  SendRecord(kind,record,"GUILD")
  if Hall.Refresh then Hall:Refresh() end
  return true
end
local function MergePacket(fields,sender)
  local kind=fields[3]
  local list=RecordList(kind)
  if not list then return false end
  local id=Decode(fields[4])
  if id=="" then return false end
  local existing=FindRecord(list,id)
  if existing and fields[2]~="UPD" then return false end
  local record={id=id,created=tonumber(fields[5]) or Core.Util:Now(),author=Decode(fields[6])}
  if kind=="notice" then record.text=Decode(fields[7])
  elseif kind=="bank" then record.item=Decode(fields[7]); record.quantity=tonumber(fields[8]) or 0; record.action=Decode(fields[9]); record.owner=record.author
  elseif kind=="goal" then record.text=Decode(fields[7]); record.done=fields[8]=="1"
  elseif kind=="event" then record.date=Decode(fields[7]); record.time=Decode(fields[8]); record.title=Decode(fields[9])
  elseif kind=="group" then record.role=Decode(fields[7]); record.dungeon=Decode(fields[8]); record.filled=fields[9]=="1"; record.author=record.author
  elseif kind=="pvp" then
    record.result=Decode(fields[7]); record.honour=tonumber(fields[8]) or 0
    DB.pvp=DB.pvp or {battlegrounds=0,wins=0,losses=0,honour=0}
    if record.result=="win" or record.result=="loss" then
      DB.pvp.battlegrounds=(tonumber(DB.pvp.battlegrounds) or 0)+1
      if record.result=="win" then DB.pvp.wins=(tonumber(DB.pvp.wins) or 0)+1
      else DB.pvp.losses=(tonumber(DB.pvp.losses) or 0)+1 end
    end
    DB.pvp.honour=(tonumber(DB.pvp.honour) or 0)+record.honour
  end
  if #tostring(record.text or record.title or record.item or record.dungeon or "")>100 then return false end
  if existing then
    for key,value in pairs(record) do existing[key]=value end
  else
    list[#list+1]=record
    if #list>250 then table.remove(list,1) end
  end
  if Hall.Refresh then Hall:Refresh() end
  return true
end
local function SendSnapshot(target)
  local kinds={"notice","bank","goal","event","group","pvp"}
  for _,kind in ipairs(kinds) do
    local list=RecordList(kind)
    for _,record in ipairs(list or {}) do SendRecord(kind,record,"WHISPER",target) end
  end
end
local function GuildSender(sender)
  if not sender or sender=="" or not IsInGuild or not IsInGuild() then return false end
  Core.Guild:RefreshRoster()
  return Core.Guild:IsOnline(sender)
end
Core.Comm:Register(SYNC_PREFIX,function(message,channel,sender)
  if channel~="GUILD" and channel~="WHISPER" then return end
  if not GuildSender(sender) then return end
  local fields=SplitPacket(message)
  if fields[1]~="1" then return end
  if fields[2]=="HELLO" then
    local count=0
    for _,kind in ipairs({"notice","bank","goal","event","group","pvp"}) do count=count+#(RecordList(kind) or {}) end
    Core.Comm:Send(SYNC_PREFIX,"1|PRES|"..tostring(count),"WHISPER",sender)
  elseif fields[2]=="PRES" then
    syncPeers[sender]={count=tonumber(fields[3]) or 0}
  elseif fields[2]=="SYNCREQ" then
    SendSnapshot(sender)
  elseif fields[2]=="PUT" or fields[2]=="UPD" then
    MergePacket(fields,sender)
  end
end)
local function BeginGuildSync()
  if not IsInGuild or not IsInGuild() then return end
  syncPeers={}
  Core.Guild:RefreshRoster()
  Core.Comm:Send(SYNC_PREFIX,"1|HELLO","GUILD")
  if C_Timer and C_Timer.After then
    C_Timer.After(3,function()
      local peers={}
      for name in pairs(syncPeers) do peers[#peers+1]=name end
      table.sort(peers)
      for index,name in ipairs(peers) do
        C_Timer.After((index-1)*0.8,function()
          Core.Comm:Send(SYNC_PREFIX,"1|SYNCREQ","WHISPER",name)
        end)
      end
      if #peers>0 then Core.Notifications:Print("Guild Hall synchronising with "..#peers.." online Taverners member(s).")
      else Core.Notifications:Print("No other online Taverners addon users found; your local Guild Hall is ready.") end
    end)
  end
end

local previousRefresh = Hall.Refresh
function Hall:Refresh()
  previousRefresh(self)
  if not body then return end
  EnsureLists()
  AddLine(" ")
  AddLine("|cffffd27aTAVERNERS GUILD SERVICES|r", "GameFontNormal")
  AddLine("NOTICEBOARD", "GameFontNormal")
  local shown = 0
  for i=#DB.noticeboard, math.max(1,#DB.noticeboard-4), -1 do
    local post = DB.noticeboard[i]
    if post then
      AddLine((post.done and "|cff777777[Done]|r " or "|cffffd27a[Open]|r ") .. tostring(post.text))
      shown = shown + 1
    end
  end
  if shown == 0 then AddLine("No notices yet. Add one with /tgh note add <message>.") end

  AddLine(" ")
  AddLine("GUILD BANK LEDGER", "GameFontNormal")
  local entries = #DB.bank
  AddLine(entries .. " locally recorded material / contribution entries.")
  for i=math.max(1,entries-2),entries do
    local item = DB.bank[i]
    if item then AddLine(tostring(item.action) .. " " .. tostring(item.quantity) .. " x " .. tostring(item.item) .. " — " .. tostring(item.owner)) end
  end
  AddLine("Record with /tgh bank add <item> <quantity> [deposit/withdrawal].")

  AddLine(" ")
  AddLine("PVP TRACKER", "GameFontNormal")
  AddLine("Battlegrounds: " .. tostring(DB.pvp.battlegrounds or 0) ..
    " • Wins: " .. tostring(DB.pvp.wins or 0) ..
    " • Losses: " .. tostring(DB.pvp.losses or 0) ..
    " • Honour recorded: " .. tostring(DB.pvp.honour or 0))
  AddLine("Use /tgh pvp win, /tgh pvp loss, or /tgh pvp honour <amount>.")

  AddLine(" ")
  AddLine("ADVENTURE JOURNAL", "GameFontNormal")
  local active = 0
  for _, goal in ipairs(DB.goals) do
    if not goal.done then active = active + 1; AddLine("• " .. tostring(goal.text)) end
  end
  AddLine(active .. " active goals. Add with /tgh goal add <goal>; finish with /tgh goal done <number>.")

  AddLine(" ")
  AddLine("GUILD EVENT CALENDAR", "GameFontNormal")
  local eventCount=0
  for i=1,#DB.events do
    local event=DB.events[i]
    if event and not event.cancelled then
      eventCount=eventCount+1
      AddLine(tostring(event.date or "Date TBC").." "..tostring(event.time or "").." — "..tostring(event.title))
    end
  end
  if eventCount==0 then AddLine("No events scheduled. Use /tgh event add <date> <time> <title>.") end

  AddLine(" ")
  AddLine("GROUP FINDER BOARD", "GameFontNormal")
  local groupCount=0
  for i=#DB.groups,math.max(1,#DB.groups-4),-1 do
    local request=DB.groups[i]
    if request and not request.filled then
      groupCount=groupCount+1
      AddLine(tostring(request.dungeon).." — looking for "..tostring(request.role).." ("..tostring(request.author)..")")
    end
  end
  if groupCount==0 then AddLine("No local group requests. Use /tgh group add <role> <dungeon>.") end
  body:SetHeight(math.max(300, -cursorY + 30))
end

local function AddGuildNotice(text)
  if not text or text == "" then return false end
  PublishRecord("notice",{text=Core.Util:SafeText(text),done=false})
  while #DB.noticeboard > 30 do table.remove(DB.noticeboard,1) end
  return true
end
local function AddBankEntry(item, quantity, action)
  if not item or item == "" then return false end
  quantity = tonumber(quantity)
  if not quantity or quantity <= 0 then return false end
  PublishRecord("bank",{item=Core.Util:SafeText(item),quantity=math.floor(quantity),action=(action=="withdrawal" and "Withdrawal" or "Deposit"),owner=UnitName("player")})
  while #DB.bank > 100 do table.remove(DB.bank,1) end
  return true
end
local function AddGoal(text)
  if not text or text == "" then return false end
  PublishRecord("goal",{text=Core.Util:SafeText(text),done=false})
  return true
end
local function MarkGoalDone(index)
  local goal = DB.goals[tonumber(index) or 0]
  if not goal then return false end
  goal.done = true
  goal.completed = Core.Util:Now()
  SendRecord("goal",goal,"GUILD",nil,"UPD")
  Hall:Refresh()
  return true
end

local function HandleGuildCommand(msg)
  local command, rest = tostring(msg or ""):match("^(%S+)%s*(.-)$")
  command = (command or ""):lower()
  if command == "note" then
    local action, text = (rest or ""):match("^(%S+)%s*(.-)$")
    if action == "add" and AddGuildNotice(text) then Core.Notifications:Print("Notice shared with online Taverners members.")
    else Core.Notifications:Print("Usage: /tgh note add <message>") end
  elseif command == "bank" then
    local action, tail = (rest or ""):match("^(%S+)%s*(.-)$")
    if action == "add" then
      local item, quantity, direction = (tail or ""):match("^(.-)%s+(%d+)%s*(%S*)$")
      if AddBankEntry(item, quantity, direction) then Core.Notifications:Print("Contribution shared with online Taverners members.")
      else Core.Notifications:Print("Usage: /tgh bank add <item> <quantity> [deposit/withdrawal]") end
    else Core.Notifications:Print("Usage: /tgh bank add <item> <quantity> [deposit/withdrawal]") end
  elseif command == "goal" then
    local action, text = (rest or ""):match("^(%S+)%s*(.-)$")
    if action == "add" and AddGoal(text) then Core.Notifications:Print("Adventure goal added.")
    elseif action == "done" and MarkGoalDone(text) then Core.Notifications:Print("Adventure goal completed.")
    else Core.Notifications:Print("Usage: /tgh goal add <goal> OR /tgh goal done <number>") end
  elseif command == "event" then
    local action, tail = (rest or ""):match("^(%S+)%s*(.-)$")
    if action=="add" then
      local date, timeValue, title = (tail or ""):match("^(%S+)%s+(%S+)%s+(.+)$")
      if date and timeValue and title then
        PublishRecord("event",{date=Core.Util:SafeText(date),time=Core.Util:SafeText(timeValue),title=Core.Util:SafeText(title)})
        Core.Notifications:Print("Guild event shared with online Taverners members.")
      else Core.Notifications:Print("Usage: /tgh event add <date> <time> <title>") end
    else Core.Notifications:Print("Usage: /tgh event add <date> <time> <title>") end
  elseif command == "group" then
    local action, tail = (rest or ""):match("^(%S+)%s*(.-)$")
    if action=="add" then
      local role, dungeon = (tail or ""):match("^(%S+)%s+(.+)$")
      if role and dungeon then
        PublishRecord("group",{role=Core.Util:SafeText(role),dungeon=Core.Util:SafeText(dungeon),filled=false})
        Core.Notifications:Print("Group request shared with online Taverners members.")
      else Core.Notifications:Print("Usage: /tgh group add <role> <dungeon>") end
    else Core.Notifications:Print("Usage: /tgh group add <role> <dungeon>") end
  elseif command == "pvp" then
    local action, amount = (rest or ""):match("^(%S+)%s*(.-)$")
    if action == "win" or action=="loss" then
      DB.pvp.battlegrounds=DB.pvp.battlegrounds+1
      if action=="win" then DB.pvp.wins=DB.pvp.wins+1 else DB.pvp.losses=DB.pvp.losses+1 end
      PublishRecord("pvp",{result=action,honour=0})
    elseif action == "honour" and tonumber(amount) and tonumber(amount)>0 then
      DB.pvp.honour=DB.pvp.honour+math.floor(tonumber(amount))
      PublishRecord("pvp",{result="honour",honour=math.floor(tonumber(amount))})
    else Core.Notifications:Print("Usage: /tgh pvp win | loss | honour <amount>"); return end
    Core.Notifications:Print("PvP record updated.")
  else
    Core.Notifications:Print("Guild Hall: /tgh | note add | bank add | goal add/done | event add | group add | pvp win/loss/honour")
  end
  Hall:Refresh()
end

-- Rebind after local command handlers have been declared (Lua lexical scope).
SlashCmdList.TAVERNERSGUILDHALL=function(msg)
  local value=tostring(msg or "")
  if value:lower()=="refresh" then Hall:Refresh()
  elseif value=="" then Hall:Toggle()
  else HandleGuildCommand(value) end
end

-- This frame is declared after BeginGuildSync so the callback closes over
-- the local function (not a nil global) when PLAYER_LOGIN fires.
local syncEventFrame=CreateFrame("Frame")
syncEventFrame:RegisterEvent("PLAYER_LOGIN")
syncEventFrame:SetScript("OnEvent",function()
  if C_Timer and C_Timer.After then C_Timer.After(5,BeginGuildSync) else BeginGuildSync() end
end)
