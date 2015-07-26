-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

local tonumber = _G.tonumber

-------------------------------------------------------------------------------
-- AddOn namespace.
-------------------------------------------------------------------------------
local FOLDER_NAME, private = ...

local LibStub = _G.LibStub
local LibToast = LibStub("LibToast-1.0")
local LootToasts = LibStub("AceAddon-3.0"):NewAddon(FOLDER_NAME, "AceEvent-3.0")

LibToast:Register(FOLDER_NAME, function(toast, title, text, iconTexture, qualityID, amountGained, amountOwned)
	local _, _, _, hex = _G.GetItemQualityColor(qualityID)
	toast:SetFormattedTitle("%s %s", title, amountGained > 1 and _G.PARENS_TEMPLATE:format(amountGained) or "")
	toast:SetFormattedText("|c%s%s|r %s", hex, text, amountOwned > 0 and _G.PARENS_TEMPLATE:format(amountOwned) or "")

	if iconTexture then
		toast:SetIconTexture(iconTexture)
	end
end)

function LootToasts:OnEnable()
	self:RegisterEvent("CHAT_MSG_CURRENCY")
	self:RegisterEvent("CHAT_MSG_LOOT")
	self:RegisterEvent("CHAT_MSG_MONEY")
end

do
	local CURRENCY_PATTERN = (_G.CURRENCY_GAINED):gsub("%%s", "(.+)")
	local CURRENCY_MULTIPLE_PATTERN = (_G.CURRENCY_GAINED_MULTIPLE):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")

	function LootToasts:CHAT_MSG_CURRENCY(eventName, message)
		local currencyLink, amountGained = message:match(CURRENCY_MULTIPLE_PATTERN)
		if not currencyLink then
			amountGained, currencyLink = 1, message:match(CURRENCY_PATTERN)

			if not currencyLink then
				return
			end
		end

		local name, amountOwned, texturePath = _G.GetCurrencyInfo(tonumber(currencyLink:match("currency:(%d+)")))
		LibToast:Spawn(FOLDER_NAME, _G.CURRENCY, name, texturePath, 1, tonumber(amountGained), tonumber(amountOwned))
	end
end -- do-block

do
	local LOOT_PATTERN = (_G.LOOT_ITEM_SELF):gsub("%%s", "(.+)")
	local LOOT_MULTIPLE_PATTERN = (_G.LOOT_ITEM_SELF_MULTIPLE):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")

	function LootToasts:CHAT_MSG_LOOT(eventName, message)
		local itemLink, amountGained = message:match(LOOT_MULTIPLE_PATTERN)
		if not itemLink then
			amountGained, itemLink = 1, message:match(LOOT_PATTERN)

			if not itemLink then
				return
			end
		end
		amountGained = tonumber(amountGained) or 0

		local name, _, quality, _, _, _, _, _, _, texturePath = _G.GetItemInfo(itemLink)
		LibToast:Spawn(FOLDER_NAME, _G.HELPFRAME_ITEM_TITLE, name, texturePath, quality, amountGained, amountGained + tonumber(_G.GetItemCount(itemLink)))
	end
end -- do-block

do
	local GOLD_PATTERN = _G.GOLD_AMOUNT:gsub("%%d", "(%%d+)")
	local SILVER_PATTERN = _G.SILVER_AMOUNT:gsub("%%d", "(%%d+)")
	local COPPER_PATTERN = _G.COPPER_AMOUNT:gsub("%%d", "(%%d+)")

	local function MoneyMatch(moneyString, pattern)
		return moneyString:match(pattern) or 0
	end

	local function MoneyStringToCopper(moneyString)
		if not moneyString then
			return 0
		end

		return MoneyMatch(moneyString, GOLD_PATTERN) * 10000 + MoneyMatch(moneyString, SILVER_PATTERN) * 100 + MoneyMatch(moneyString, COPPER_PATTERN)
	end

	local function GetMoneyIconAndString(copperAmount)
		if copperAmount >= 10000 then
			local goldAmount = copperAmount / 10000
			local icon = goldAmount < 10 and [[Interface\ICONS\INV_Misc_Coin_01]] or [[Interface\ICONS\INV_Misc_Coin_02]]
			return icon, ("%s %s %s"):format(_G.GOLD_AMOUNT_TEXTURE:format(goldAmount, 0, 0), _G.SILVER_AMOUNT_TEXTURE:format((copperAmount / 100) % 100, 0, 0), _G.COPPER_AMOUNT_TEXTURE:format(copperAmount % 100, 0, 0))
		elseif copperAmount >= 100 then
			local silverAmount = (copperAmount / 100) % 100
			local icon = silverAmount < 10 and [[Interface\ICONS\INV_Misc_Coin_03]] or [[Interface\ICONS\INV_Misc_Coin_04]]
			return icon, ("%s %s"):format(_G.SILVER_AMOUNT_TEXTURE:format(silverAmount, 0, 0), _G.COPPER_AMOUNT_TEXTURE:format(copperAmount % 100, 0, 0))
		else
			local copperAmount = copperAmount % 100
			local icon = copperAmount < 10 and [[Interface\ICONS\INV_Misc_Coin_05]] or [[Interface\ICONS\INV_Misc_Coin_06]]
			return icon, _G.COPPER_AMOUNT_TEXTURE:format(copperAmount, 0, 0)
		end
	end

	function LootToasts:CHAT_MSG_MONEY(eventName, message)
		local copperAmount = MoneyStringToCopper(message)
		if not copperAmount or copperAmount <= 0 then
			return
		end

		local texturePath, moneyString = GetMoneyIconAndString(copperAmount)
		LibToast:Spawn(FOLDER_NAME, _G.MONEY, moneyString, texturePath, 1, 0, 0)
	end
end -- do-block
