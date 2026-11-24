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
local ev=CreateFrame("Frame"); ev:RegisterEvent("PLAYER_LOGIN"); ev:SetScript("OnEvent",function() Build(); Hall:Refresh() end)


-- Guild services stored locally for now. Guild-wide sharing will use the
-- Core communication layer after protocol and moderation testing.
local function EnsureLists()
  DB.noticeboard = DB.noticeboard or {}
  DB.bank = DB.bank or {}
  DB.goals = DB.goals or {}
  DB.pvp = DB.pvp or {battlegrounds=0,wins=0,losses=0,honour=0}
end
EnsureLists()

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
  body:SetHeight(math.max(300, -cursorY + 30))
end

local function AddGuildNotice(text)
  if not text or text == "" then return false end
  DB.noticeboard[#DB.noticeboard+1] = {text=Core.Util:SafeText(text), created=Core.Util:Now(), done=false, author=UnitName("player")}
  while #DB.noticeboard > 30 do table.remove(DB.noticeboard,1) end
  return true
end
local function AddBankEntry(item, quantity, action)
  if not item or item == "" then return false end
  quantity = tonumber(quantity)
  if not quantity or quantity <= 0 then return false end
  DB.bank[#DB.bank+1] = {item=Core.Util:SafeText(item),quantity=math.floor(quantity),action=(action=="withdrawal" and "Withdrawal" or "Deposit"),owner=UnitName("player"),created=Core.Util:Now()}
  while #DB.bank > 100 do table.remove(DB.bank,1) end
  return true
end
local function AddGoal(text)
  if not text or text == "" then return false end
  DB.goals[#DB.goals+1] = {text=Core.Util:SafeText(text),created=Core.Util:Now(),done=false}
  return true
end
local function MarkGoalDone(index)
  local goal = DB.goals[tonumber(index) or 0]
  if not goal then return false end
  goal.done = true
  goal.completed = Core.Util:Now()
  return true
end

local function HandleGuildCommand(msg)
  local command, rest = tostring(msg or ""):match("^(%S+)%s*(.-)$")
  command = (command or ""):lower()
  if command == "note" then
    local action, text = (rest or ""):match("^(%S+)%s*(.-)$")
    if action == "add" and AddGuildNotice(text) then Core.Notifications:Print("Notice added to your local Guild Hall board.")
    else Core.Notifications:Print("Usage: /tgh note add <message>") end
  elseif command == "bank" then
    local action, tail = (rest or ""):match("^(%S+)%s*(.-)$")
    if action == "add" then
      local item, quantity, direction = (tail or ""):match("^(.-)%s+(%d+)%s*(%S*)$")
      if AddBankEntry(item, quantity, direction) then Core.Notifications:Print("Guild bank ledger entry saved locally.")
      else Core.Notifications:Print("Usage: /tgh bank add <item> <quantity> [deposit/withdrawal]") end
    else Core.Notifications:Print("Usage: /tgh bank add <item> <quantity> [deposit/withdrawal]") end
  elseif command == "goal" then
    local action, text = (rest or ""):match("^(%S+)%s*(.-)$")
    if action == "add" and AddGoal(text) then Core.Notifications:Print("Adventure goal added.")
    elseif action == "done" and MarkGoalDone(text) then Core.Notifications:Print("Adventure goal completed.")
    else Core.Notifications:Print("Usage: /tgh goal add <goal> OR /tgh goal done <number>") end
  elseif command == "pvp" then
    local action, amount = (rest or ""):match("^(%S+)%s*(.-)$")
    if action == "win" then DB.pvp.battlegrounds=DB.pvp.battlegrounds+1; DB.pvp.wins=DB.pvp.wins+1
    elseif action == "loss" then DB.pvp.battlegrounds=DB.pvp.battlegrounds+1; DB.pvp.losses=DB.pvp.losses+1
    elseif action == "honour" and tonumber(amount) and tonumber(amount)>0 then DB.pvp.honour=DB.pvp.honour+math.floor(tonumber(amount))
    else Core.Notifications:Print("Usage: /tgh pvp win | loss | honour <amount>"); return end
    Core.Notifications:Print("PvP record updated.")
  else
    Core.Notifications:Print("Guild Hall: /tgh | note add | bank add | goal add/done | pvp win/loss/honour")
  end
  Hall:Refresh()
end
