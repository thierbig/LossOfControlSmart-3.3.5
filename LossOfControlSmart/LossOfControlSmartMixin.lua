--######################################################################
--######         Bakcport LossOfControlSmart from retail              #######
------------------------------------------------------------------------
--######################################################################

local LossOfControlSmart = LibStub("AceAddon-3.0"):NewAddon("LossOfControlSmart", "AceEvent-3.0");
_G.LossOfControlSmart = LossOfControlSmart;
LossOfControlSmart.timer = LibStub("AceTimer-3.0");
local LossOfControl_AddControlOrUpdate, LossOfControl_AddInterruptControl, LossOfControl_Hide;

SOUNDKIT = SOUNDKIT or {};
SOUNDKIT.UI_LOSS_OF_CONTROL_START = "Interface\\AddOns\\LossOfControlSmart\\Media\\Sound\\34468.ogg";
-- Temporary store for learned CC mappings before DB is initialized
_G.LoC_LearnedCC = _G.LoC_LearnedCC or {};

local blacklist = {
    [72120] = true,
    [70106] = true,
    [72121] = true,
    [24134] = true,
    [71151] = true,
    [23262] = true,
    [38064] = true,
    [49010] = true,
    [72426] = true,
    -- [spellID] = true,
};

local SpellSchoolString = {
    [0x1]  = STRING_SCHOOL_PHYSICAL,
    [0x2]  = STRING_SCHOOL_HOLY,
    [0x4]  = STRING_SCHOOL_FIRE,
    [0x8]  = STRING_SCHOOL_NATURE,
    [0x10] = STRING_SCHOOL_FROST,
    [0x20] = STRING_SCHOOL_SHADOW,
    [0x40] = STRING_SCHOOL_ARCANE,
    -- double
    [0x3]  = STRING_SCHOOL_HOLYSTRIKE,
    [0x5]  = STRING_SCHOOL_FLAMESTRIKE,
    [0x6]  = STRING_SCHOOL_HOLYFIRE,
    [0x9]  = STRING_SCHOOL_STORMSTRIKE,
    [0xA]  = STRING_SCHOOL_HOLYSTORM,
    [0xC]  = STRING_SCHOOL_FIRESTORM,
    [0x11] = STRING_SCHOOL_FROSTSTRIKE,
    [0x12] = STRING_SCHOOL_HOLYFROST,
    [0x14] = STRING_SCHOOL_FROSTFIRE,
    [0x18] = STRING_SCHOOL_FROSTSTORM,
    [0x21] = STRING_SCHOOL_SHADOWSTRIKE,
    [0x22] = STRING_SCHOOL_SHADOWLIGHT,
    [0x24] = STRING_SCHOOL_SHADOWFLAME,
    [0x28] = STRING_SCHOOL_SHADOWSTORM,
    [0x30] = STRING_SCHOOL_SHADOWFROST,
    [0x41] = STRING_SCHOOL_SPELLSTRIKE,
    [0x42] = STRING_SCHOOL_DIVINE,
    [0x44] = STRING_SCHOOL_SPELLFIRE,
    [0x48] = STRING_SCHOOL_SPELLSTORM,
    [0x50] = STRING_SCHOOL_SPELLFROST,
    [0x60] = STRING_SCHOOL_SPELLSHADOW,
    [0x1C] = STRING_SCHOOL_ELEMENTAL,
    -- triple and more
    [0x7C] = STRING_SCHOOL_CHROMATIC,
    [0x7E] = STRING_SCHOOL_MAGIC,
    [0x7F] = STRING_SCHOOL_CHAOS,
};

function GetSchoolString(lockoutSchool)
    if ( SpellSchoolString[lockoutSchool] ) then
        return SpellSchoolString[lockoutSchool];
    end
end

local lockoutChannel = {
    --
    [GetSpellInfo(12051)] = GetSpellInfo(42897),
    --
    [GetSpellInfo(53007)] = GetSpellInfo(32375),
    --
    [GetSpellInfo(64901)] = GetSpellInfo(48071),
    [GetSpellInfo(64843)] = GetSpellInfo(48071),
    --
    [GetSpellInfo(48447)] = GetSpellInfo(50763),
};

function RaidNotice_UpdateSlots( slotFrame, timings, elapsedTime, hasFading  )
    if ( slotFrame.scrollTime ) then
        slotFrame.scrollTime = slotFrame.scrollTime + elapsedTime;
        if ( slotFrame.scrollTime <= timings["RAID_NOTICE_SCALE_UP_TIME"] ) then
            slotFrame:SetTextHeight(floor(timings["RAID_NOTICE_MIN_HEIGHT"]+
            ((timings["RAID_NOTICE_MAX_HEIGHT"]-timings["RAID_NOTICE_MIN_HEIGHT"])*slotFrame.scrollTime/timings["RAID_NOTICE_SCALE_UP_TIME"])));
                elseif ( slotFrame.scrollTime <= timings["RAID_NOTICE_SCALE_DOWN_TIME"] ) then
            slotFrame:SetTextHeight(floor(timings["RAID_NOTICE_MAX_HEIGHT"] -
            ((timings["RAID_NOTICE_MAX_HEIGHT"]-timings["RAID_NOTICE_MIN_HEIGHT"])*(slotFrame.scrollTime -
             timings["RAID_NOTICE_SCALE_UP_TIME"])/(timings["RAID_NOTICE_SCALE_DOWN_TIME"] -
             timings["RAID_NOTICE_SCALE_UP_TIME"]))));
        else
            slotFrame:SetTextHeight(timings["RAID_NOTICE_MIN_HEIGHT"]);
            slotFrame.scrollTime = nil;
        end
    end
    if ( hasFading ) then
        FadingFrame_OnUpdate(slotFrame);
    end
end

function CooldownFrame_Clear(self)
    self:Hide();
end

-------------------------------------------------------------

-------------------------------------------------------------
LossOfControlAnimGroupMixin = {};
LossOfControlAnimGroupMixin.AnimationGroup = {};

function LossOfControlAnimGroupMixin:Mixin(...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...);
        self.AnimationGroup[i] = mixin;
    end
end

function LossOfControlAnimGroupMixin:Play()
    for _, childKey in pairs(self.AnimationGroup) do
        childKey:Play();
    end
end

function LossOfControlAnimGroupMixin:Stop()
    for _, childKey in pairs(self.AnimationGroup) do
        childKey:Stop();
    end
end

function LossOfControlAnimGroupMixin:IsPlaying()
    for _, childKey in pairs(self.AnimationGroup) do
        return childKey:IsPlaying();
    end
end

LossOfContolrMixin = LossOfControlSmart;
LossOfContolrMixin.ActiveControl = {};

function LossOfContolrMixin:OnLoad()
    self:RegisterEvent("UNIT_AURA", LossOfControl_AddControlOrUpdate);
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", LossOfControl_AddInterruptControl);
    self:RegisterEvent("PLAYER_ENTERING_WORLD", LossOfControl_Hide);

    self.Anim = LossOfControlAnimGroupMixin;
end

function LossOfContolrMixin:SetShown(value)
    if value then
        self:Show();
    else
         self:Hide();
    end
end

function LossOfContolrMixin:Added()
    local update = false;

    for i = 1, 255 do
        local name, _, iconTexture, _, locType, duration, expirationTime, _, _, _, spellID = UnitAura("player", i, "HARMFUL");
        if ( not name or blacklist[spellID] ) then
            break;
        end

        local spellInfo = LOSS_OF_CONTROL_STORAGE[spellID];

        if not spellInfo then
            -- Attempt to infer CC type for unknown debuffs
            spellInfo = LossOfControlSmart:InferMissingCC(spellID, i) -- returns {displayConst, priority, displayType}
            if spellInfo then
                LOSS_OF_CONTROL_STORAGE[spellID] = { spellInfo[1], spellInfo[2], spellInfo[3] } -- ensure future uses have displayType
            end
        end

        if spellInfo then

            local Fields = {
                locType = locType,
                spellID = spellID,
                displayText = spellInfo[1],
                iconTexture = iconTexture,
                startTime = GetTime(),
                expirationTime = expirationTime,
                timeRemaining = expirationTime - GetTime(),
                duration = duration,
                lockoutSchool = nil,
                priority = spellInfo[2],
                displayType = spellInfo[3],
            };

            if not self.ActiveControl[spellID] or self.ActiveControl[spellID] < expirationTime then
                self.ActiveControl[spellID] = expirationTime;
                self:ScanEvents(Fields);
                update = true;
            end
        end
    end

    return update;
end

function LossOfContolrMixin:Update()
    local update = false;

    for index, controlData in pairs(C_LossOfControlSmart.ControlData) do
        if not self:GetControlID(controlData.spellID)
        and not controlData.lockoutSchool then
            self.ActiveControl[controlData.spellID] = nil;
            C_LossOfControlSmart.ControlData[index] = nil;
            C_LossOfControlSmart.ControlData = self:SetControlDataPriority(C_LossOfControlSmart.ControlData);
            self:SendMessage("LOSS_OF_CONTROL_UPDATE", LossOfControlFrame);
            update = true;
        end
    end

    return update;
end

function LossOfContolrMixin:AddInterruptControl(event, ...)
    local _, subEvent, _, _, _, _, destName, _, spellID, _, _, _, spellName, lockoutSchool = ...;

    if ( subEvent == "SPELL_INTERRUPT" and destName == UnitName("player") ) then
        if lockoutSchool then
            local _, _, iconTexture = GetSpellInfo(spellID);
            local duration;

            if lockoutChannel[spellName] then
                _, duration = GetSpellCooldown(lockoutChannel[spellName]);
            else
                _, duration = GetSpellCooldown(spellName);
            end

            local Fields = {
                locType = "SCHOOL_INTERRUPT",
                spellID = spellID,
                displayText = LOSS_OF_CONTROL_DISPLAY_INTERRUPT_SCHOOL,
                iconTexture = iconTexture,
                startTime = GetTime(),
                expirationTime = duration + GetTime(),
                timeRemaining = duration,
                duration = duration,
                lockoutSchool = lockoutSchool,
                priority = 5,
                displayType = LossOfControlSmart:GetDisplayValue(LOC_TYPE_INTERRUPT),
            }

            self:ScanEvents(Fields);
            self.ActiveControl[spellID] = true;
            LossOfControlSmart.timer:ScheduleTimer( function() self:InterruptUpdate() end, duration );
        end
    end

end

function LossOfContolrMixin:InterruptUpdate()
    for k, v in pairs(C_LossOfControlSmart.ControlData) do
        if ( v.lockoutSchool and math.floor(v.expirationTime - GetTime()) <= 0 ) then
            C_LossOfControlSmart.ControlData[k] = nil;
            C_LossOfControlSmart.ControlData = self:SetControlDataPriority(C_LossOfControlSmart.ControlData);
        end
    end
    self:SendMessage("LOSS_OF_CONTROL_UPDATE", LossOfControlFrame);
end

function LossOfContolrMixin:SetControlDataPriority(ControlData)
    local t = {}
    for _, data in pairs(ControlData) do
        if data and data.priority then
            t[#t + 1] = data;
        end
    end

    table.sort(t, function (a,b)
        if a.priority == b.priority then
            return a.expirationTime > b.expirationTime;
        else
            return (a.priority > b.priority);
        end
    end)

    return t
end

function LossOfContolrMixin:GetControlID(spellID)
    for i = 1, 255 do
        local debuffID = select(11, UnitAura("player", i, "HARMFUL"));
        if ( not debuffID ) then
            return;
        end

        if ( spellID == debuffID ) then
            return true;
        end
    end
end

function LossOfContolrMixin:ScanEvents(Fields)
    tinsert(C_LossOfControlSmart.ControlData, Fields);
    C_LossOfControlSmart.ControlData = self:SetControlDataPriority(C_LossOfControlSmart.ControlData); -- сразу сортируем, т.к. от индекса толку никакого
    local index = C_LossOfControlSmart.GetActiveLossOfControlDataCount();
    self:SendMessage("LOSS_OF_CONTROL_ADDED", LossOfControlFrame, index);
end

function LossOfContolrMixin:RegisterEvents(event)
    self:RegisterMessage(event, LossOfControlFrame_OnEvent);
end

function LossOfContolrMixin:UnRegisterEvents(event)
    self:UnregisterMessage(event, LossOfControlFrame_OnEvent);
end

function LossOfControl_AddInterruptControl(event, ...)
    if ( event and ... ) then
        LossOfContolrMixin:AddInterruptControl(event, ...);
    end
end

function LossOfControl_AddControlOrUpdate(event, unit)
    if not ( unit == "player" ) then
        return;
    end

    return LossOfContolrMixin:Update() or LossOfContolrMixin:Added();
end

function LossOfControl_Hide()
    if LossOfControlFrame and LossOfControlFrame:IsShown() then
        LossOfControlFrame:Hide();
        LossOfContolrMixin.ActiveControl = {};
        C_LossOfControlSmart.ControlData = {};
    end
end

TimeLeftMixin = {};

function TimeLeftMixin:SetShown(value)
    if ( value ) then
        self:Show();
    else
        self:Hide();
    end
end

function Mixin(object, ...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...);
        for k, v in pairs(mixin) do
            object[k] = v;
        end
    end
    return object;
end
function CreateAndInitFromMixin(mixin, ...)
    local object = CreateFromMixins(mixin);
    object:Init(...);
    return object;
end

-- =============================================
-- Auto-detect missing CC (tooltip + optional DRData)
-- =============================================

local Category = {
    STUN = "STUN",
    FEAR = "FEAR",
    HORROR = "HORROR",
    INCAPACITATE = "INCAPACITATE",
    DISORIENT = "DISORIENT",
    SLEEP = "SLEEP",
    SAP = "SAP",
    ROOT = "ROOT",
    SILENCE = "SILENCE",
    DISARM = "DISARM",
    POLYMORPH = "POLYMORPH",
    CYCLONE = "CYCLONE",
    BANISH = "BANISH",
    SHACKLE = "SHACKLE",
    POSSESS = "POSSESS",
    CHARM = "CHARM",
    FREEZE = "FREEZE",
};

-- Priorities roughly aligned with C_LossOfControlSmart.lua locals
local CategoryPriority = {
    STUN = 5,
    FEAR = 3,
    HORROR = 3,
    INCAPACITATE = 5,
    DISORIENT = 6,
    SLEEP = 6,
    SAP = 6,
    ROOT = 4,
    SILENCE = 1,
    DISARM = 2,
    POLYMORPH = 6,
    CYCLONE = 7,
    BANISH = 5,
    SHACKLE = 6,
    POSSESS = 6,
    CHARM = 6,
    FREEZE = 6,
};

local CategoryDisplayConst = {
    STUN = LOSS_OF_CONTROL_DISPLAY_STUN,
    FEAR = LOSS_OF_CONTROL_DISPLAY_FEAR,
    HORROR = LOSS_OF_CONTROL_DISPLAY_HORROR,
    INCAPACITATE = LOSS_OF_CONTROL_DISPLAY_INCAPACITATE,
    DISORIENT = LOSS_OF_CONTROL_DISPLAY_DISORIENT,
    SLEEP = LOSS_OF_CONTROL_DISPLAY_SLEEP,
    SAP = LOSS_OF_CONTROL_DISPLAY_SAP,
    ROOT = LOSS_OF_CONTROL_DISPLAY_ROOT,
    SILENCE = LOSS_OF_CONTROL_DISPLAY_SILENCE,
    DISARM = LOSS_OF_CONTROL_DISPLAY_DISARM,
    POLYMORPH = LOSS_OF_CONTROL_DISPLAY_POLYMORPH,
    CYCLONE = LOSS_OF_CONTROL_DISPLAY_CYCLONE,
    BANISH = LOSS_OF_CONTROL_DISPLAY_BANISH,
    SHACKLE = LOSS_OF_CONTROL_DISPLAY_SHACKLE_UNDEAD,
    POSSESS = LOSS_OF_CONTROL_DISPLAY_POSSESS,
    CHARM = LOSS_OF_CONTROL_DISPLAY_CHARM,
    FREEZE = LOSS_OF_CONTROL_DISPLAY_FREEZE,
};

-- Map category to which options bucket determines displayType (full/root/silence/disarm)
local CategoryToOptionType = {
    ROOT = LOC_TYPE_ROOT,
    SILENCE = LOC_TYPE_SILENCE,
    DISARM = LOC_TYPE_DISARM,
    -- others default to FULL
};

local function GetLocaleKeywords()
    local L = GetLocale();
    local t = {};
    if L == "ruRU" then
        t[Category.STUN] = {"оглуш", "стан"};
        t[Category.FEAR] = {"страх"};
        t[Category.HORROR] = {"ужас"};
        t[Category.INCAPACITATE] = {"паралич"};
        t[Category.DISORIENT] = {"дезориента"};
        t[Category.SLEEP] = {"сон", "спяч"};
        t[Category.SAP] = {"ошелом"};
        t[Category.ROOT] = {"обездвиж", "корн"};
        t[Category.SILENCE] = {"немота", "немой"};
        t[Category.DISARM] = {"обезоруж"};
        t[Category.POLYMORPH] = {"превращ", "сглаз"};
        t[Category.CYCLONE] = {"смерч"};
        t[Category.BANISH] = {"изгнан", "изгнание"};
        t[Category.SHACKLE] = {"оков", "сковыв"};
        t[Category.POSSESS] = {"одержим", "контроль"};
        t[Category.CHARM] = {"подчин", "соблазн"};
        t[Category.FREEZE] = {"замороз"};
    else
        -- default/enUS and most latin locales (simple stems)
        t[Category.STUN] = {"stun"};
        t[Category.FEAR] = {"fear"};
        t[Category.HORROR] = {"horror"};
        t[Category.INCAPACITATE] = {"incapac", "repent"};
        t[Category.DISORIENT] = {"disorient", "blind"};
        t[Category.SLEEP] = {"sleep", "wyvern"};
        t[Category.SAP] = {"sap"};
        t[Category.ROOT] = {"root", "freeze", "frost nova", "entang"};
        t[Category.SILENCE] = {"silence", "pacif"};
        t[Category.DISARM] = {"disarm"};
        t[Category.POLYMORPH] = {"polymorph", "hex"};
        t[Category.CYCLONE] = {"cyclone"};
        t[Category.BANISH] = {"banish"};
        t[Category.SHACKLE] = {"shackle"};
        t[Category.POSSESS] = {"possess", "mind control"};
        t[Category.CHARM] = {"charm", "seduc"};
        t[Category.FREEZE] = {"freez", "ice"};
    end
    return t;
end

local function ScanTooltipForCategory(auraIndex)
    local tip = _G.LoC_ScanTooltip or CreateFrame("GameTooltip", "LoC_ScanTooltip", UIParent, "GameTooltipTemplate");
    _G.LoC_ScanTooltip = tip;
    tip:SetOwner(UIParent, "ANCHOR_NONE");
    tip:ClearLines();
    tip:SetUnitDebuff("player", auraIndex, "HARMFUL");
    local lines = tip:NumLines();
    local text = "";
    for i = 1, lines do
        local left = _G["LoC_ScanTooltipTextLeft"..i];
        if left then
            local t = left:GetText();
            if t and t ~= "" then
                text = text .. "\n" .. string.lower(t);
            end
        end
    end
    if text == "" then return nil end
    local kw = GetLocaleKeywords();
    for cat, list in pairs(kw) do
        for _, needle in ipairs(list) do
            if string.find(text, needle) then
                return cat;
            end
        end
    end
end

local function CategoryFromName(name)
    if not name then return nil end
    local s = string.lower(name);
    local kw = GetLocaleKeywords();
    for cat, list in pairs(kw) do
        for _, needle in ipairs(list) do
            if string.find(s, needle) then
                return cat;
            end
        end
    end
end

local function ResolveCategoryForSpell(spellID, auraIndex)
    -- Optional DR library
    local DRData = LibStub and LibStub("DRData-1.0", true);
    if DRData and DRData.GetCategory then
        local cat = DRData:GetCategory(spellID);
        if type(cat) == "string" then
            cat = string.upper(cat);
            if CategoryPriority[cat] then
                return cat;
            end
        end
    end
    -- Fallback to tooltip and spell name scanning
    local name = GetSpellInfo(spellID);
    return ScanTooltipForCategory(auraIndex) or CategoryFromName(name);
end

function LossOfControlSmart:InferMissingCC(spellID, auraIndex)
    -- Respect user toggle if present (defaults to on)
    if self.db and self.db.char and self.db.char.myVal and self.db.char.myVal["Auto Detect CC"] == false then
        return nil;
    end

    -- Cache any learned mapping
    self.db = self.db or {};
    local learned = (self.db.char and self.db.char.myVal and self.db.char.myVal.learnedCC) or _G.LoC_LearnedCC or {};
    local category = learned[spellID];
    if not category then
        category = ResolveCategoryForSpell(spellID, auraIndex);
        if not category then
            return nil;
        end
        -- Persist learned mapping
        if self.db.char and self.db.char.myVal then
            self.db.char.myVal.learnedCC = self.db.char.myVal.learnedCC or {};
            self.db.char.myVal.learnedCC[spellID] = category;
        else
            _G.LoC_LearnedCC = _G.LoC_LearnedCC or {};
            _G.LoC_LearnedCC[spellID] = category;
        end
    end

    local displayConst = CategoryDisplayConst[category];
    local priority = CategoryPriority[category] or 5;
    local optionType = CategoryToOptionType[category] or LOC_TYPE_FULL;
    local displayType = self.GetDisplayValue and self:GetDisplayValue(optionType) or 2;

    return { displayConst or LOSS_OF_CONTROL_DISPLAY_STUN, priority, displayType };
end