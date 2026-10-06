-- ============================================================
--  RatRoll -- guard. Loads first.
--
--  RatRoll is the mini roll, master loot and soft reserves of Okanvil, built
--  from the same code. With the full Okanvil installed RatRoll has nothing to
--  add, and the two would fight over the same windows -- so RatRoll stays off.
--  Every generated file starts with `if RATROLL_OFF then return end`.
-- ============================================================

if IsAddOnLoaded("Okanvil") or Okanvil then
	RATROLL_OFF = true
	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_LOGIN")
	f:SetScript("OnEvent", function()
		DEFAULT_CHAT_FRAME:AddMessage("|cffffd200[RatRoll]|r Okanvil is installed and already does"
			.. " everything RatRoll does, so RatRoll is off.")
	end)
	return
end

-- The shared code checks LITE to act as RatRoll: everyone gets Clear, the
-- master looter loads the soft reserves in the SR panel, and the version reply
-- says "RatRoll". Set before Core.lua, which keeps this table.
RatRoll = { LITE = "RatRoll" }
