-- ============================================================
--  RatRoll -- boot. Loads last.
--
--  The pieces the full Okanvil gets from its main window, which RatRoll does
--  not ship: the icon, the slash command, and closing on a boss pull.
-- ============================================================

if RATROLL_OFF then return end
local R = RatRoll

R.BRAND_ICON = "{{ICON}}"
-- The lucky rat behind the windows, drawn the RatStash way: full strength under
-- a dark wash, cropped to the window's shape (the picture is 3 wide : 2 tall,
-- the rat on its right half, which every window keeps).
R.ForgeArtStyle = {
	tex = "Interface\\AddOns\\RatRoll\\Media\\window-bg",
	aspect = 1.5, washL = 0.825, washR = 0.525,
}
R.panels = R.panels or {}

-- /ratroll and /rr both open the mini roll.
function R:Toggle()
	if R.RollMgr and R.RollMgr.Toggle then R.RollMgr.Toggle() end
end

-- DBM pull: get out of the way.
function R:CloseAll()
	local function try(fn) local ok, err = pcall(fn); if not ok and R.Err then R:Err("CloseAll", err) end end
	if R.CloseDropdown then try(function() R:CloseDropdown() end) end
	if R.RollMgr and R.RollMgr.Hide then try(function() R.RollMgr.Hide() end) end
	if R.SoftResPanel and R.SoftResPanel.Hide then try(function() R.SoftResPanel.Hide(false) end) end
end

SlashCmdList["RatRoll"] = function(arg)
	arg = (arg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if arg == "help" or arg == "?" then
		R:Print("commands:")
		R:Print("  |cffffd200/rr|r              open/close the roll window")
		R:Print("  |cffffd200/rr stop|r         end the open roll |cff8a8d93(master looter)|r")
		R:Print("  |cffffd200/rrsr|r            soft reserves |cff8a8d93(master looter)|r")
		R:Print("  |cffffd200/rrerr|r           error log")
		R:Print("  |cffffd200/rrfocus|r         release a stuck keyboard focus")
		R:Print("  |cffffd200/rrloottest|r      fake drops for testing |cff8a8d93(world, <item>, roll, ml, clear)|r")
		return
	end
	R:Toggle()
end

-- Okanvil commands for pages RatRoll does not have.
SlashCmdList["OKVER"], SLASH_OKVER1 = nil, nil
SlashCmdList["OKCOMMS"], SLASH_OKCOMMS1 = nil, nil

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	R:Print("loaded -- |cff00ff00/rr|r opens the roll window.")
end)
