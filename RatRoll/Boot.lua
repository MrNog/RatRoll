-- ============================================================
--  RatRoll -- boot. Loads last.
--
--  The pieces the full Okanvil gets from its main window, which RatRoll does
--  not ship: the icon, the slash command, and closing on a boss pull.
-- ============================================================

if RATROLL_OFF then return end
local R = RatRoll

R.BRAND_ICON = "Interface\\AddOns\\RatRoll\\Media\\icon"
-- The lucky rat behind the windows, drawn the RatStash way: full strength under
-- a dark wash, cropped to the window's shape (the picture is 3 wide : 2 tall,
-- the rat on its right half, which every window keeps).
R.ForgeArtStyle = {
	tex = "Interface\\AddOns\\RatRoll\\Media\\window-bg",
	aspect = 1.5, washL = 0.95, washR = 0.87,
}
R.panels = R.panels or {}

-- /ratroll and /rr both open the mini roll.
function R:Toggle()
	if R.RollMgr and R.RollMgr.Toggle then R.RollMgr.Toggle() end
end

-- Minimap button: left click the roll window, right click soft reserves, drag
-- to move it round the minimap. Core builds it at login.
function R:BuildMinimap()
	if self.minimap then return end
	local b = CreateFrame("Button", "RatRoll_MinimapButton", Minimap)
	b:SetSize(31, 31); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(8)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp"); b:RegisterForDrag("LeftButton")
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local overlay = b:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53, 53); overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); overlay:SetPoint("TOPLEFT")
	local icon = b:CreateTexture(nil, "BACKGROUND")
	icon:SetSize(20, 20); icon:SetTexture(R.BRAND_ICON)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92); icon:SetPoint("CENTER", 1, 1)

	local function pos()
		local a = math.rad(R.db.minimapAngle or 220)
		b:ClearAllPoints()
		b:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(a), 80 * math.sin(a))
	end
	pos()
	b:SetScript("OnDragStart", function(s)
		s:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local px, py = GetCursorPosition()
			local sc = Minimap:GetEffectiveScale()
			R.db.minimapAngle = math.deg(math.atan2(py / sc - my, px / sc - mx))
			pos()
		end)
	end)
	b:SetScript("OnDragStop", function(s) s:SetScript("OnUpdate", nil) end)
	b:SetScript("OnClick", function(_, button)
		if button == "RightButton" then
			if SlashCmdList["RRRES"] then SlashCmdList["RRRES"]("") end
		else
			R:Toggle()
		end
	end)
	b:SetScript("OnEnter", function(s)
		GameTooltip:SetOwner(s, "ANCHOR_LEFT")
		GameTooltip:AddLine("RatRoll", 1, 0.82, 0)
		GameTooltip:AddLine("Left click: roll window", 0.86, 0.86, 0.87)
		GameTooltip:AddLine("Right click: soft reserves", 0.86, 0.86, 0.87)
		GameTooltip:AddLine("Drag: move", 0.54, 0.55, 0.58)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	if R.db.minimapHidden then b:Hide() end
	self.minimap = b
end

-- DBM pull: get out of the way.
function R:CloseAll()
	local function try(fn) local ok, err = pcall(fn); if not ok and R.Err then R:Err("CloseAll", err) end end
	if R.CloseDropdown then try(function() R:CloseDropdown() end) end
	if R.RollMgr and R.RollMgr.Hide then try(function() R.RollMgr.Hide() end) end
	if R.SoftResPanel and R.SoftResPanel.Hide then try(function() R.SoftResPanel.Hide(false) end) end
end

local function cmdLine(cmd, what) R:Print("  |cffffd200" .. cmd .. "|r  " .. what) end

-- /rr help: what a raider or a master looter sets.
local function userHelp()
	R:Print("commands:")
	cmdLine("/rr", "open/close the roll window")
	cmdLine("/rr timer 15", "seconds a roll stays open |cff8a8d93(0 = no timer)|r")
	cmdLine("/rr minimap", "show/hide the minimap button")
	cmdLine("/rr stop", "end the open roll |cff8a8d93(master looter)|r")
	cmdLine("/rrsr", "soft reserves |cff8a8d93(master looter)|r")
end

-- /rr dev: the test and debug commands, kept out of the users' list.
local function devHelp()
	R:Print("dev commands:")
	cmdLine("/rrloottest world", "record loot outside instances")
	cmdLine("/rrloottest ml", "pretend you are master looter |cff8a8d93(solo)|r")
	cmdLine("/rrloottest <item>", "a fake drop |cff8a8d93(name or id)|r")
	cmdLine("/rrloottest roll", "open the fake drop for rolls")
	cmdLine("/rrloottest clear", "delete the test session")
	cmdLine("/rrgive", "Give loot window on a fake raid |cff8a8d93(on|off = use it or the dropdown)|r")
	cmdLine("/rrtrade", "what you owe and to whom |cff8a8d93(clear = forget)|r")
	cmdLine("/rrerr", "error log")
	cmdLine("/rrfocus", "release a stuck keyboard focus")
	cmdLine("side by side", "/run Okanvil_DB.ratrollSideBySide = true; ReloadUI()")
end

SlashCmdList["RatRoll"] = function(arg)
	arg = (arg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if arg == "help" or arg == "?" then userHelp(); return end
	if arg == "dev" then devHelp(); return end
	R:Toggle()
end

-- /rr timer <seconds>: the roll timer, which Okanvil sets on its Settings page.
local rollSlash = SlashCmdList["RRROLL"]
SlashCmdList["RRROLL"] = function(msg)
	local cmd, n = (msg or ""):lower():match("^%s*(%a*)%s*(%d*)")
	if cmd == "help" then userHelp(); return end
	if cmd == "dev" then devHelp(); return end
	if cmd == "minimap" then
		R.db.minimapHidden = not R.db.minimapHidden or nil
		if R.minimap then if R.db.minimapHidden then R.minimap:Hide() else R.minimap:Show() end end
		R:Print("minimap button " .. (R.db.minimapHidden and "hidden" or "shown") .. "  |cff8a8d93(/rr minimap)|r")
		return
	end
	if cmd ~= "timer" then return rollSlash(msg) end
	local L = R.Loot
	if not (L and L.SetRollTimer) then return end
	if n ~= "" then L.SetRollTimer(tonumber(n)) end
	local s = L.RollTimer()
	R:Print("roll timer: |cffffd200" .. (s > 0 and (s .. "s") or "off") .. "|r  |cff8a8d93(/rr timer <seconds>, 0 = off)|r")
end

-- Okanvil commands for pages RatRoll does not have.
SlashCmdList["RRVER"], SLASH_RRVER1 = nil, nil
SlashCmdList["RRCOMMS"], SLASH_RRCOMMS1 = nil, nil

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	R:Print("loaded -- |cff00ff00/rr|r opens the roll window, |cff00ff00/rr help|r for settings.")
end)
