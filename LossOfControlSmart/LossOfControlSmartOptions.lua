--######################################################################
--######         Bakcport LossOfControlSmart from retail              #######
------------------------------------------------------------------------
--######################################################################

local LossOfControlSmart = LibStub("AceAddon-3.0"):GetAddon("LossOfControlSmart", "AceEvent-3.0");

local AceDB = LibStub("AceDB-3.0");
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local lossOfControlSmart = "Loss Of Control Alerts";
local profileDB;
local BASE_WIDTH, BASE_HEIGHT = 256, 58;

local LOC_OPTION_VALUE = function()
    return {
        [0] = LOC_OPTION_OFF,
        [1] = LOC_OPTION_ALERT,
        [2] = LOC_OPTION_FULL,
    };
end

local function SetOptionValue(self, value)
    profileDB[self.option.name] = value;
    LossOfControlSmart:SetDisplay();
end

local function GetOptionValue(self)
    return profileDB[self.option.name];
end

local function SetOptionEnable(self, value)

    for _, state in pairs(self.options.args) do
        if ( state.disabled ~= nil ) then
            state.disabled = not value;
        end
    end

    profileDB[self.option.name] = value;
    LoC_CVar.SetCVar("lossOfControlSmart", value);
    LossOfControlSmart:SendMessage("CVAR_UPDATE", LossOfControlFrame, "LOSS_OF_CONTROL", value and "1" or "0");
end

local function IsOptionEnable()
    return profileDB[lossOfControlSmart];
end

-- Layout/Sound setters that also apply changes immediately
local function SetFrameOption(self, value)
    profileDB[self.option.name] = value;
    if LossOfControlSmart.ApplyFrameSettings then
        LossOfControlSmart:ApplyFrameSettings();
    end
end

local function SetSoundOption(self, value)
    profileDB[self.option.name] = value;
end

LossOfControlSmart.default = {
    locale = "enUS",
    [lossOfControlSmart] = true,
    [LOC_TYPE_FULL] = 2,
    [LOC_TYPE_SILENCE] = 2,
    [LOC_TYPE_INTERRUPT] = 2,
    [LOC_TYPE_DISARM] = 2,
    [LOC_TYPE_ROOT] = 2;
    -- Frame & Sound defaults
    ["Width"] = BASE_WIDTH,
    ["Height"] = BASE_HEIGHT,
    ["X"] = 0,
    ["Y"] = 75,
    ["Sound"] = false,
    ["Lock Frame"] = true,
    ["Auto Detect CC"] = true,
};

LossOfControlSmart.options = {
    name = "",
    handler = LossOfControlSmart,
    type = "group",
    args = {
        lossOfControlSmart = {
            order = 0,
            type = "toggle",
            name = lossOfControlSmart,
            desc = OPTION_TOOLTIP_LOSS_OF_CONTROL,
            get = GetOptionValue,
            set = SetOptionEnable,
            width = "full"
        },
        full = {
            order = 1,
            type = "select",
            style = "dropdown",
            name = LOC_TYPE_FULL,
            desc = OPTION_LOSS_OF_CONTROL_FULL,
            get = GetOptionValue,
            set = SetOptionValue,
            values = LOC_OPTION_VALUE,
            disabled = not IsOptionEnable,
        },
        Silence = {
            order = 2,
            type = "select",
            style = "dropdown",
            name = LOC_TYPE_SILENCE,
            desc = OPTION_LOSS_OF_CONTROL_SILENCE,
            get = function()
                return profileDB[LOC_TYPE_SILENCE]
            end,
            set = SetOptionValue,
            values = LOC_OPTION_VALUE,
            disabled = not IsOptionEnable,
        },
        Interrupt = {
            order = 3,
            type = "select",
            style = "dropdown",
            name = LOC_TYPE_INTERRUPT,
            desc = OPTION_LOSS_OF_CONTROL_INTERRUPT,
            get = GetOptionValue,
            set = SetOptionValue,
            values = LOC_OPTION_VALUE,
            disabled = not IsOptionEnable,
        },
        Disarm = {
            order = 4,
            type = "select",
            style = "dropdown",
            name = LOC_TYPE_DISARM,
            desc = OPTION_LOSS_OF_CONTROL_DISARM,
            get = GetOptionValue,
            set = SetOptionValue,
            values = LOC_OPTION_VALUE,
            disabled = not IsOptionEnable,
        },
        Root = {
            order = 5,
            type = "select",
            style = "dropdown",
            name = LOC_TYPE_ROOT,
            desc = OPTION_LOSS_OF_CONTROL_ROOT,
            get = GetOptionValue,
            set = SetOptionValue,
            values = LOC_OPTION_VALUE,
            disabled = not IsOptionEnable,
        },
        FrameGroup = {
            order = 10,
            type = "group",
            name = "Frame & Sound",
            inline = true,
            disabled = false,
            args = {
                Width = {
                    order = 1,
                    type = "range",
                    name = "Width",
                    desc = "Overall frame width (keeps aspect ratio).",
                    min = 128,
                    max = 1024,
                    step = 1,
                    get = GetOptionValue,
                    set = SetFrameOption,
                },
                Height = {
                    order = 2,
                    type = "range",
                    name = "Height",
                    desc = "Overall frame height (keeps aspect ratio).",
                    min = 32,
                    max = 512,
                    step = 1,
                    get = GetOptionValue,
                    set = SetFrameOption,
                },
                X = {
                    order = 3,
                    type = "range",
                    name = "X",
                    desc = "Horizontal offset from screen center.",
                    min = -2000,
                    max = 2000,
                    step = 1,
                    get = GetOptionValue,
                    set = SetFrameOption,
                },
                Y = {
                    order = 4,
                    type = "range",
                    name = "Y",
                    desc = "Vertical offset from screen center.",
                    min = -1200,
                    max = 1200,
                    step = 1,
                    get = GetOptionValue,
                    set = SetFrameOption,
                },
                Sound = {
                    order = 5,
                    type = "toggle",
                    name = "Sound",
                    desc = "Play a sound when an alert starts.",
                    get = GetOptionValue,
                    set = SetSoundOption,
                },
                LockFrame = {
                    order = 6,
                    type = "toggle",
                    name = "Lock Frame",
                    desc = "Lock to prevent dragging with the mouse.",
                    get = GetOptionValue,
                    set = SetFrameOption,
                },
                Test = {
                    order = 7,
                    type = "execute",
                    name = "Test Alert",
                    func = function()
                        if LossOfControlSmart.TestAlert then
                            LossOfControlSmart:TestAlert();
                        end
                    end,
                },
                Reset = {
                    order = 8,
                    type = "execute",
                    name = "Reset Position/Size",
                    func = function()
                        profileDB["Width"] = BASE_WIDTH;
                        profileDB["Height"] = BASE_HEIGHT;
                        profileDB["X"] = 0;
                        profileDB["Y"] = 75;
                        if LossOfControlSmart.ApplyFrameSettings then
                            LossOfControlSmart:ApplyFrameSettings();
                        end
                    end,
                },
            },
        },
        Advanced = {
            order = 20,
            type = "group",
            name = "Advanced",
            inline = true,
            args = {
                AutoDetect = {
                    order = 1,
                    type = "toggle",
                    name = "Auto Detect CC",
                    desc = "Automatically infer and learn crowd-control spells that are not in the built-in list.",
                    get = function() return profileDB["Auto Detect CC"] end,
                    set = function(_, v) profileDB["Auto Detect CC"] = v end,
                },
                ClearLearned = {
                    order = 2,
                    type = "execute",
                    name = "Clear Learned CC",
                    desc = "Forget all automatically learned CC mappings.",
                    func = function()
                        if LossOfControlSmart.ClearLearnedCC then
                            LossOfControlSmart:ClearLearnedCC();
                        end
                    end,
                },
            },
        },
    },
};

function LossOfControlSmart:SetupOptions()
    AceConfig:RegisterOptionsTable("LossOfControlSmart", self.options, {SLASH_LossOfControlSmart1});

    self.optionsFrames = {};
    self.optionsFrames.general = AceConfigDialog:AddToBlizOptions("LossOfControlSmart", "LossOfControlSmart");
end

function LossOfControlSmart:OnInitialize()
    self.db = AceDB:New("LossOfControlDB");

    if self.db.char.myVal and self.db.char.myVal.locale and self.db.char.myVal.locale == GetLocale() then
        self.db.char.myVal = self.db.char.myVal
    else
        self.db.char.myVal = self.default
        self.db.char.myVal.locale = GetLocale()
    end
    
    profileDB = self.db.char.myVal;

    -- Backfill any missing default fields for users upgrading from older versions
    if type(self.default) == "table" then
        for k, v in pairs(self.default) do
            if profileDB[k] == nil then
                profileDB[k] = v;
            end
        end
    end

    self:SetupOptions();
    self:SetDisplay();
    LoC_CVar.SetCVar("lossOfControlSmart", self.db.char.myVal["Loss Of Control Alerts"]);
    self:SendMessage("VARIABLES_LOADED", LossOfControlFrame);
    -- Apply user saved frame settings once DB is ready
    if self.ApplyFrameSettings then
        self:ApplyFrameSettings();
    end

    SLASH_LossOfControlSmart1  = "/loc";
    SlashCmdList["LossOfControlSmart"] = function()
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.general);
    end

    if ( not ROMANSPECTOR_DISCORD ) then
        ROMANSPECTOR_DISCORD = true;
        DEFAULT_CHAT_FRAME:AddMessage("|cffbaf5aeLossOfControl|r: See more |cff44d3e3https://discord.gg/4GTrkkaV9U|r");
    end
end

function LossOfControlSmart:GetDisplayValue( controlType )
    return profileDB[controlType];
end

local displayType = {
    [LOSS_OF_CONTROL_DISPLAY_DISARM] = LOC_TYPE_DISARM,
    [LOSS_OF_CONTROL_DISPLAY_ROOT] = LOC_TYPE_ROOT,
    [LOSS_OF_CONTROL_DISPLAY_SILENCE] = LOC_TYPE_SILENCE,
};

function LossOfControlSmart:SetDisplay()
    for _, spellData in pairs(LOSS_OF_CONTROL_STORAGE) do
        local controlType = spellData[1];
        spellData[3] = self:GetDisplayValue(displayType[controlType] or LOC_TYPE_FULL);
    end
end

-- Apply current settings to the runtime frame (size, position, drag lock)
function LossOfControlSmart:ApplyFrameSettings()
    local f = _G.LossOfControlFrame;
    if not f or not profileDB then return end

    local width = tonumber(profileDB["Width"]) or BASE_WIDTH;
    local height = tonumber(profileDB["Height"]) or BASE_HEIGHT;
    local x = tonumber(profileDB["X"]) or 0;
    local y = tonumber(profileDB["Y"]) or 0;
    local locked = profileDB["Lock Frame"] ~= false; -- default locked

    -- Maintain aspect ratio by using a uniform scale derived from width/height
    local scaleW = width / BASE_WIDTH;
    local scaleH = height / BASE_HEIGHT;
    local scale = math.max(0.25, math.min(4.0, math.min(scaleW, scaleH)));
    f:SetScale(scale);

    f:ClearAllPoints();
    f:SetPoint("CENTER", UIParent, "CENTER", x, y);

    -- Drag handling
    f:SetClampedToScreen(true);
    f:SetMovable(true);
    if locked then
        f:EnableMouse(false);
        f:RegisterForDrag();
    else
        f:EnableMouse(true);
        f:RegisterForDrag("LeftButton");
    end

    f:SetScript("OnDragStart", function(frame)
        if not profileDB["Lock Frame"] then
            frame:StartMoving();
        end
    end)
    f:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing();
        local _, _, _, dx, dy = frame:GetPoint();
        profileDB["X"], profileDB["Y"] = math.floor(dx + 0.5), math.floor(dy + 0.5);
    end)
end

function LossOfControlSmart:IsSoundEnabled()
    if profileDB and profileDB["Sound"] ~= nil then
        return profileDB["Sound"];
    end
    return true;
end

function LossOfControlSmart:TestAlert()
    local f = _G.LossOfControlFrame;
    if not f then return end
    local data = {
        locType = "STUN",
        spellID = 12826,
        displayText = "Test Alert",
        iconTexture = "Interface\\Icons\\Ability_Rogue_KidneyShot",
        startTime = GetTime(),
        timeRemaining = 10,
        duration = 10,
        lockoutSchool = nil,
        priority = 10,
        displayType = 1, -- ALERT
    };
    LossOfControlFrame_SetUpDisplay(f, true, data);
    -- Keep alert visible for ~10 seconds for positioning
    f.fadeTime = 10;
end

function LossOfControlSmart:ClearLearnedCC()
    if not profileDB then return end
    profileDB.learnedCC = {};
    _G.LoC_LearnedCC = {};
    DEFAULT_CHAT_FRAME:AddMessage("|cffbaf5aeLossOfControl|r: Cleared learned CC mappings.");
end

LoC_CVar = LoC_CVar or {};
LoC_CVar.Config = {};

function LoC_CVar.GetCVarBool(name)
    return LoC_CVar.Config[name];
end

function LoC_CVar.SetCVar(eventName, value)
    if ( type(value) == "boolean" ) then
        LoC_CVar.Config[eventName] = value and "1" or "0";
    else
        LoC_CVar.Config[eventName] = value and tostring(value) or nil;
    end
end
