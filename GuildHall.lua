local ADDON, ns = ...
local Core = _G.TavernersCore
if not Core then return end

local DB = Core.Database:Register("TavernersGuildHallDB", {version=1, minimised=false}, 1)
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
SlashCmdList.TAVERNERSGUILDHALL=function(msg) if tostring(msg or ""):lower()=="refresh" then Hall:Refresh() else Hall:Toggle() end end
local ev=CreateFrame("Frame"); ev:RegisterEvent("PLAYER_LOGIN"); ev:SetScript("OnEvent",function() Build(); Hall:Refresh() end)
