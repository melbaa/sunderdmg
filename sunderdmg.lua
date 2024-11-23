local ADDON_NAME = "sunderdmg"
SDMG = {}

function SDMG.spellrank(spellname)
    local i = 1
    local rank = nil
    local name = nil
    while true do
        local name_iter, rank_iter = GetSpellName(i, BOOKTYPE_SPELL);
        if not name_iter then break end
        if name_iter == spellname then
            rank = rank_iter
            name = name_iter
        end
        i = i + 1
    end
    return name, rank
end

function SDMG.sunderrank()
    local name, rank = SDMG.spellrank("Sunder Armor")
    if not rank then return 0 end
    local a, b, rank = string.find(rank, "Rank (%d)")
    if not rank then return 0 end
    rank = tonumber(rank)
    return rank
end


function SDMG.mitigated(armor)
    if armor < 0 then armor = 0 end
    local attacker_level = UnitLevel("player")
    local tmpvalue = 0.1 * armor / (8.5 * attacker_level + 40)
    tmpvalue = tmpvalue / (1 + tmpvalue)
    if tmpvalue < 0 then tmpvalue = 0 end
    if tmpvalue > 0.75 then tmpvalue = 0.75 end
    return tmpvalue
end


function SDMG.mitigated2(armor, attacker_level)
    if armor < 0 then armor = 0 end
    local m = 400 + 85 * attacker_level
    local tmpvalue = armor / (armor + m)
    if tmpvalue < 0 then tmpvalue = 0 end
    if tmpvalue > 0.75 then tmpvalue = 0.75 end
    return tmpvalue
end


-- Interface
SDMG.f1 = CreateFrame("Frame",nil,UIParent)
SDMG.f1:SetMovable(true)
SDMG.f1:EnableMouse(true)
SDMG.f1:SetWidth(100) 
SDMG.f1:SetHeight(100) 
SDMG.f1:SetAlpha(.90);
SDMG.f1:SetPoint("CENTER",350,-100)
SDMG.f1.text = SDMG.f1:CreateFontString(nil,"ARTWORK") 
SDMG.f1.text:SetFont("Fonts\\ARIALN.ttf", 24, "OUTLINE")
SDMG.f1.text:SetPoint("CENTER",0,0)
SDMG.f1:RegisterForDrag("LeftButton")
SDMG.f1:SetScript("OnDragStart", function() SDMG.f1:StartMoving() end)
SDMG.f1:SetScript("OnDragStop", function()
    SDMG.f1:StopMovingOrSizing()
    point, _, rel_point, x_offset, y_offset = SDMG.f1:GetPoint()

    if x_offset < 20 and x_offset > -20 then
        x_offset = 0
    end

    sdmg_opts.point = point
    sdmg_opts.rel_point = rel_point
    sdmg_opts.x_offset = floor(x_offset / 1) * 1
    sdmg_opts.y_offset = floor(y_offset / 1) * 1
end);
SDMG.f1:Hide()

function SDMG:Init()
    if not sdmg_opts then
        sdmg_opts = {
            point = "CENTER",
            rel_point = "CENTER",
            x_offset = 350,
            y_offset = -100,
        }
    end

    SDMG.f1:SetPoint(sdmg_opts.point, UIParent, sdmg_opts.rel_point, sdmg_opts.x_offset, sdmg_opts.y_offset)
end
 
local function displayupdate(show, message)
    if show == 1 then
        SDMG.f1.text:SetText(message)
        SDMG.f1:Show()
    elseif show == 2 then
        SDMG.f1:Hide()
    else
        SDMG.f1:Hide()
    end
end

local function getAP()
    local base, buff, debuff = UnitAttackPower("player")
    return base + buff + debuff
end

local function displayString()
    local hp = UnitHealth("target")
    local ap = getAP()

    local attacker_level = UnitLevel("player")
    local sunder_power = 450
    if attacker_level < 60 then
        sunder_power = SDMG.sunderrank() * 90
    end

    local armor = UnitResistance("target", 0)
    local newarmor = armor - sunder_power
    local newarmor3 = armor - sunder_power * 3
    local newarmor5 = armor - sunder_power * 5

    local mit = SDMG.mitigated2(armor, attacker_level)
    local newmit = SDMG.mitigated2(newarmor, attacker_level)
    local newmit3 = SDMG.mitigated2(newarmor3, attacker_level)
    local newmit5 = SDMG.mitigated2(newarmor5, attacker_level)
    local ehp = hp * (1+mit)
    local newehp = hp * (1+newmit)
    local newehp3 = hp * (1+newmit3)
    -- local newehp5 = hp * (1+newmit5)
    local result = floor(ehp-newehp)
    local result3 = floor(ehp-newehp3)
    -- local result5 = floor(ehp - newehp5)
    local btbasedmg = (0.3 * ap + 150)
    local btdmg = btbasedmg * (1 - mit)
    return 'mit ' .. floor(mit*1000)/10 .. ' x1: ' .. floor(newmit*1000)/10 .. ' x5: ' .. floor(newmit5*1000)/10
        -- .. '\navgdiff5 ' .. floor(result5/5) .. ' x5 ' .. result5 .. ' dp30rx5 ' ..  floor(result5/5)*3
        .. '\nsunder x1: ' .. result ..  ' x3: ' .. floor(result3)
        .. '\nbtbase ' .. floor(btbasedmg) .. ' btmit ' .. floor(btdmg) 
end

SDMG.f1:RegisterEvent("ADDON_LOADED")
SDMG.f1:RegisterEvent("UNIT_AURA")
SDMG.f1:RegisterEvent("PLAYER_TARGET_CHANGED")

SDMG.f1:SetScript("OnEvent", function()
    displayupdate(1, displayString())
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A sunderdmg:|r Loaded",1,1,1)
            SDMG:Init()
        end
    end
end);
