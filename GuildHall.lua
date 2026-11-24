local ADDON, ns = ...
local Core = _G.TavernersCore
if not Core then return end

local DB = Core.Database:Register("TavernersGuildHallDB", {version=1, minimised=false}, 1)
local Hall = {db=DB}
Core:RegisterModule("GuildHall", Hall)

local frame, body, rows = nil, nil, {}
local function AddLine(text, template)
  local fs = body:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
  fs:SetPoint("TOPLEFT", 10, -#rows * 25 - 6)
  fs:SetWidth(660); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true)
  fs:SetText(text); rows[#rows+1] = fs
end
local function Clear()
  for _, row in ipairs(rows) do row:Hide(); row:SetParent(nil) end
  rows = {}
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
  status("Quest Companion", q, q and (tostring(CountQuests(q) or 0) .. " active quests") or nil)
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
  AddLine(" ")
  AddLine("|cffd9c49aYour Guild Hall is a local dashboard. Addon modules appear here when installed and loaded. Guild-wide sharing is handled by each module's approved sync features.|r", "GameFontHighlightSmall")
  body:SetHeight(math.max(300, #rows * 25 + 30))
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
  local refresh=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
  refresh:SetSize(100,24); refresh:SetPoint("TOPRIGHT",-42,-48); refresh:SetText("Refresh")
  refresh:SetScript("OnClick",function() Hall:Refresh() end)
  local actions={{"Quests","QuestCompanion"},{"Gear","GearGuide"},{"Dungeons","DungeonTool"},{"Crafting","CraftingDirectory"},{"Ammo","AmmoGuard"}}
  local x=18
  for _,action in ipairs(actions) do
    local b=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
    b:SetSize(118,24); b:SetPoint("TOPLEFT",x,-48); b:SetText(action[1])
    b:SetScript("OnClick",function() OpenModule(action[2]) end)
    x=x+124
  end
  local scroll=CreateFrame("ScrollFrame","TavernersGuildHallScroll",frame,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",18,-52); scroll:SetPoint("BOTTOMRIGHT",-36,18)
  body=CreateFrame("Frame",nil,scroll); body:SetSize(660,400); scroll:SetScrollChild(body)
end
function Hall:Toggle()
  Build()
  if frame:IsShown() then frame:Hide() else frame:Show(); self:Refresh() end
end
SLASH_TAVERNERSGUILDHALL1="/taverners"; SLASH_TAVERNERSGUILDHALL2="/tgh"; SLASH_TAVERNERSGUILDHALL3="/guildhall"
SlashCmdList=SlashCmdList or {}
SlashCmdList.TAVERNERSGUILDHALL=function() Hall:Toggle() end
local ev=CreateFrame("Frame"); ev:RegisterEvent("PLAYER_LOGIN"); ev:SetScript("OnEvent",function() Build(); Hall:Refresh() end)
