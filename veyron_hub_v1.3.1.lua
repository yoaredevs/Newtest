--[[
   __     __  ___     ___     ____    _____   ____    _____  __     __  ____
   \ \   / / / _ \   / _ \   |  _ \  | ____| |  _ \  | ____| \ \   / / / ___|
    \ \_/ / | | | | | |_| |  | |_) | |  _|   | | | | |  _|    \ \_/ /  \___ \
     \   /  | |_| | |  _  |  |  _ <  | |___  | |_| | | |___    \   /    ___) |
      \_/    \___/  |_| |_|  |_| \_\ |_____| |____/  |_____|    \_/    |____/

                     Y O A R E D E V S   H U B
              yoaredevs  -  github.com/yoaredevs  -  Roblox: 6r0lw
]]

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")
local CoreGui            = game:GetService("CoreGui")
local TweenService       = game:GetService("TweenService")
local Debris             = game:GetService("Debris")
local TeleportService    = game:GetService("TeleportService")
local HttpService        = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local Camera      = Workspace.CurrentCamera

local gethui = gethui or function() return CoreGui end
local setclip = setclipboard or toclipboard or function() end

--[[YOARE_VERSION:1.2.1]]
local SCRIPT_VERSION = "1.3.1"
local VERSION_TAG    = "YOARE_VERSION:" .. SCRIPT_VERSION

local SCRIPT_URL = _G.YOARE_URL
_G.YOARE_URL = SCRIPT_URL

local SELF_FILE = "YoareDevsHub/self_" .. SCRIPT_VERSION .. ".lua"
local function sourceIsThisVersion(src)
    return type(src) == "string" and src:find(VERSION_TAG, 1, true) ~= nil
end

local function getSelfSource()
    if sourceIsThisVersion(_G.YOARE_SELF_SRC) then return _G.YOARE_SELF_SRC end
    local ok, src = pcall(function()
        if isfile and readfile and isfile(SELF_FILE) then return readfile(SELF_FILE) end
        return nil
    end)
    if ok and sourceIsThisVersion(src) then
        _G.YOARE_SELF_SRC = src
        return src
    end
    if SCRIPT_URL then
        local ok2, src2 = pcall(function() return game:HttpGet(SCRIPT_URL) end)
        if ok2 and sourceIsThisVersion(src2) then
            _G.YOARE_SELF_SRC = src2
            pcall(function()
                if not writefile then return end
                if makefolder and isfolder and not isfolder("YoareDevsHub") then makefolder("YoareDevsHub") end
                writefile(SELF_FILE, src2)
            end)
            return src2
        end
    end
    return nil
end

task.spawn(function() pcall(getSelfSource) end)

-- UPDATE GUARD: detecta quem JA USOU o script antes e exige atualizacao
-- com popup OBRIGATORIO (botao unico). Sinais de uso anterior:
--   1) arquivo self_X.Y.Z.lua de versao diferente (ex.: self_1.2.1.lua)
--   2) qualquer outro arquivo/pasta de configuracao (settings.json,
--      lang.txt, presets/, lang_data.json...) -- so' existem se o script
--      ja rodou pelo menos uma vez
-- Depois de mostrar o popup grava um marcador pra nao repetir na mesma
-- versao. Quem nunca usou (pasta inexistente) nunca ve o popup.
local UPDATE_MARKER = "YoareDevsHub/updated_" .. SCRIPT_VERSION .. ".txt"

local function detectPreviousUse()
    local olds, hasOldFiles = {}, false
    pcall(function()
        if not isfolder or not isfolder("YoareDevsHub") or not listfiles then return end
        for _, f in ipairs(listfiles("YoareDevsHub")) do
            local ver = string.match(f, "self_(%d+%.%d+%.%d+)%.lua$")
            if ver and ver ~= SCRIPT_VERSION then
                table.insert(olds, {file = f, version = ver})
            elseif not ver and not string.find(f, "updated_", 1, true) then
                hasOldFiles = true
            end
        end
    end)
    pcall(function()
        if isfolder and isfolder("YoareDevsHub/presets") then hasOldFiles = true end
    end)
    table.sort(olds, function(a, b) return a.version < b.version end)
    return olds, hasOldFiles
end

local function markUpdateDone()
    pcall(function()
        if not writefile then return end
        if makefolder and isfolder and not isfolder("YoareDevsHub") then makefolder("YoareDevsHub") end
        writefile(UPDATE_MARKER, "ok")
    end)
end

local LANG_FILE = "YoareDevsHub/lang.txt"
local SETTINGS_FILE = "YoareDevsHub/settings.json"
local PRESETS_FOLDER = "YoareDevsHub/presets"

local THEME_IMAGE_URL = "https://storage.googleapis.com/runable-templates/cli-uploads%2FSWT8vywkWGZzOi6HWtOmyCGbE6bVm30a%2FWPmawVx71IlIw4c_hVgG2%2F1000695862_VVR5xZ.jpg"

local HUB_NAME           = "Veyron Hub"
local THEME_NAME_COLOR   = Color3.fromRGB(43, 214, 199)
local DEFAULT_NAME_COLOR = Color3.fromRGB(255, 255, 255)
local THEME_IMAGE_ALPHA = 0.8

-- Cores do gradiente Hatsune Miku
local MIKU_COLORS = {
    Color3.fromRGB(57, 197, 187),   -- teal Miku
    Color3.fromRGB(255, 105, 180),  -- rosa
    Color3.fromRGB(135, 206, 235),  -- azul claro
    Color3.fromRGB(57, 197, 187),   -- volta ao teal
}

local STRINGS_URL = "https://storage.googleapis.com/runable-templates/cli-uploads%2FaJOk0h5xM4OWltNqZrKoR74QTjikghgj%2Fy0b-pPbV0JVoZE6CroCP1%2Fveyron_hub_strings.json"
local STRINGS_FILE = "YoareDevsHub/lang_data.json"
local STRINGS_FALLBACK = { pt = {}, en = {}, es = {} }

local function loadStringsData()
    -- 1) cache local (rapido, nao gasta rede em toda execucao)
    local ok, cached = pcall(function()
        if isfile and readfile and isfile(STRINGS_FILE) then return readfile(STRINGS_FILE) end
        return nil
    end)
    if ok and type(cached) == "string" and #cached > 0 then
        local ok2, data = pcall(function() return HttpService:JSONDecode(cached) end)
        if ok2 and type(data) == "table" and data.pt and data.en and data.es then
            return data
        end
    end

    -- 2) busca o JSON na web
    local ok3, body = pcall(function() return game:HttpGet(STRINGS_URL) end)
    if ok3 and type(body) == "string" and #body > 0 then
        local ok4, data = pcall(function() return HttpService:JSONDecode(body) end)
        if ok4 and type(data) == "table" and data.pt and data.en and data.es then
            pcall(function()
                if not writefile then return end
                if makefolder and isfolder and not isfolder("YoareDevsHub") then makefolder("YoareDevsHub") end
                writefile(STRINGS_FILE, body)
            end)
            return data
        end
    end

    -- 3) sem rede e sem cache: cai pra tabela vazia, T() ainda funciona
    -- retornando a proria chave como texto (degradado, mas nao quebra)
    return STRINGS_FALLBACK
end

local STRINGS = loadStringsData()

local LANG_FILE_VERSION = 2
local savedLang, savedSource = nil, nil

local function saveLang(key, source)
    source = source or "manual"
    _G.YOARE_LANG = key; _G.YOARE_LANG_SOURCE = source; _G.YOARE_LANG_V = LANG_FILE_VERSION
    pcall(function()
        if not writefile then return end
        if makefolder and isfolder and not isfolder("YoareDevsHub") then makefolder("YoareDevsHub") end
        writefile(LANG_FILE, "v" .. LANG_FILE_VERSION .. "|" .. key .. "|" .. source)
    end)
end

local function loadLang(strict)
    if _G.YOARE_LANG and STRINGS[_G.YOARE_LANG] and _G.YOARE_LANG_SOURCE == "manual" and _G.YOARE_LANG_V == LANG_FILE_VERSION then
        return _G.YOARE_LANG, "manual"
    end
    local ok, v = pcall(function()
        if isfile and readfile and isfile(LANG_FILE) then return readfile(LANG_FILE) end
        return nil
    end)
    if ok and type(v) == "string" then
        local raw = (v:gsub("%s", ""))
        local ver, vkey, vsource = raw:match("^v(%d+)|(%a+)|(%a+)$")
        if ver and STRINGS[vkey] then
            if tonumber(ver) >= LANG_FILE_VERSION then return vkey, vsource end
            return vkey, (vsource == "manual") and "geo" or vsource
        end
        local key, source = raw:match("^(%a+)|(%a+)$")
        if key and source == "manual" and STRINGS[key] then return key, "geo" end
        if not key then key, source = raw, "legacy" end
        if STRINGS[key] then return key, source end
    end
    if strict then return nil, nil end
    return "pt", "fallback"
end

savedLang, savedSource = loadLang(true)

local COUNTRY_LANG = {
    BR="pt",PT="pt",AO="pt",MZ="pt",CV="pt",GW="pt",ST="pt",TL="pt",
    ES="es",MX="es",AR="es",CL="es",CO="es",PE="es",VE="es",EC="es",BO="es",PY="es",UY="es",CR="es",PA="es",GT="es",HN="es",SV="es",NI="es",DO="es",CU="es",PR="es",GQ="es",
    US="en",GB="en",CA="en",AU="en",NZ="en",IE="en",ZA="en",IN="en",
}
local COUNTRY_NAME = {
    BR="Brasil",PT="Portugal",ES="Espanha / Espana / Spain",US="Estados Unidos / USA",MX="Mexico",AR="Argentina",CL="Chile",CO="Colombia",PE="Peru",GB="United Kingdom",CA="Canada",
}
local GEO_ENDPOINTS = {
    {url="https://api.country.is/",pattern='"country"%s*:%s*"(%a%a)"'},
    {url="https://ipinfo.io/country",pattern="^%s*(%a%a)%s*$"},
    {url="https://ipapi.co/country/",pattern="^%s*(%a%a)%s*$"},
    {url="https://ifconfig.co/country-iso",pattern="^%s*(%a%a)%s*$"},
    {url="http://ip-api.com/json/?fields=countryCode",pattern='"countryCode"%s*:%s*"(%a%a)"'},
}
local function getHttpRequest()
    return (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or (krnl and krnl.request) or request
end
local function httpGetBody(url)
    local req = getHttpRequest()
    if req then
        local ok, res = pcall(req, {Url=url,Method="GET",Headers={["User-Agent"]="Mozilla/5.0",["Accept"]="*/*"}})
        if ok and type(res)=="table" then
            local code = res.StatusCode or res.Status or res.status_code or 200
            local body = res.Body or res.body
            if (code==200 or code==0) and type(body)=="string" and #body>0 then return body end
        end
    end
    local ok2, body2 = pcall(function() return game:HttpGet(url) end)
    if ok2 and type(body2)=="string" and #body2>0 then return body2 end
    return nil
end
local function countryFromRoblox()
    local ok, cc = pcall(function() return game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LocalPlayer) end)
    if ok and type(cc)=="string" and #cc>=2 then return cc:sub(1,2):upper() end
    return nil
end
local function countryFromGeoIP()
    if not (getHttpRequest() or game.HttpGet) then return nil end
    for _, ep in ipairs(GEO_ENDPOINTS) do
        local body = httpGetBody(ep.url)
        if body then local cc = body:match(ep.pattern); if cc then return cc:upper() end end
    end
    return nil
end
local function countryFromLocale()
    local ok, loc = pcall(function() return game:GetService("LocalizationService").RobloxLocaleId or game:GetService("LocalizationService").SystemLocaleId end)
    if not ok or type(loc)~="string" then return nil end
    loc = loc:lower()
    local region = loc:match("^%a+%-(%a%a)")
    if region then return region:upper() end
    if loc:find("^pt") then return "BR" end
    if loc:find("^es") then return "ES" end
    if loc:find("^en") then return "US" end
    return nil
end
local RUN_GEO_COUNTRY, RUN_GEO_METHOD, RUN_GEO_FAIL = nil, nil, nil
_G.YOARE_GEO_COUNTRY, _G.YOARE_GEO_METHOD, _G.YOARE_GEO_FAIL = nil, nil, nil
local function detectCountry()
    if RUN_GEO_COUNTRY then return RUN_GEO_COUNTRY, nil, RUN_GEO_METHOD end
    if RUN_GEO_FAIL then return nil, RUN_GEO_FAIL, nil end
    local methods = {{name="roblox",fn=countryFromRoblox},{name="geoip",fn=countryFromGeoIP},{name="locale",fn=countryFromLocale}}
    for _, m in ipairs(methods) do
        local ok, cc = pcall(m.fn)
        if ok and cc then _G.YOARE_GEO_COUNTRY=cc; _G.YOARE_GEO_METHOD=m.name; return cc, nil, m.name end
    end
    local why = (getHttpRequest() or game.HttpGet) and "offline" or "nohttp"
    _G.YOARE_GEO_FAIL = why
    return nil, why, nil
end

local LANG, LANG_SOURCE
if savedLang and savedSource=="manual" then LANG, LANG_SOURCE = savedLang, "manual"
elseif savedLang and savedSource=="geo" then LANG, LANG_SOURCE = savedLang, "geo"
elseif savedLang then LANG, LANG_SOURCE = savedLang, "legacy"
else
    local okLoc, ccLoc = pcall(countryFromLocale)
    if okLoc and ccLoc and COUNTRY_LANG[ccLoc] then LANG, LANG_SOURCE = COUNTRY_LANG[ccLoc], "locale"
    else LANG, LANG_SOURCE = "pt", "default" end
end
_G.YOARE_LANG = LANG; _G.YOARE_LANG_SOURCE = LANG_SOURCE
local L = STRINGS[LANG]
local function T(key, ...)
    local s = L[key] or (STRINGS.en[key] or key)
    if select("#", ...)>0 then local ok, out = pcall(string.format, s, ...); return ok and out or s end
    return s
end
local function langName(key) local t=STRINGS[key]; return t and (t.flag.." "..t.label) or key end
local LANG_ORDER = {"pt","en","es"}
local LANG_LABELS, LABEL_TO_KEY = {}, {}
for _, key in ipairs(LANG_ORDER) do local label=langName(key); table.insert(LANG_LABELS,label); LABEL_TO_KEY[label]=key end

if _G.YOARE_Unload then pcall(_G.YOARE_Unload) end
local old = gethui():FindFirstChild("YOARE_Render")
if old then old:Destroy() end

local Screen = Instance.new("ScreenGui")
Screen.Name = "YOARE_Render"; Screen.ResetOnSpawn = false; Screen.IgnoreGuiInset = true
Screen.DisplayOrder = 999999; Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; Screen.Parent = gethui()

local Connections = {}
local function bind(c) table.insert(Connections, c); return c end

-- LOADER
local Loader = {}
do
    local holder = Instance.new("Frame")
    holder.Name = "YOARE_Loader"; holder.AnchorPoint = Vector2.new(0.5, 1)
    holder.Position = UDim2.new(0.5, 0, 1, -46); holder.AutomaticSize = Enum.AutomaticSize.XY
    holder.Size = UDim2.fromOffset(0, 0); holder.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    holder.BackgroundTransparency = 0.2; holder.BorderSizePixel = 0; holder.ZIndex = 100000
    holder.Parent = Screen
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = holder
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(255,255,255); stroke.Transparency = 0.82; stroke.Thickness = 1; stroke.Parent = holder
    local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0,9); pad.PaddingBottom = UDim.new(0,9); pad.PaddingLeft = UDim.new(0,14); pad.PaddingRight = UDim.new(0,16); pad.Parent = holder
    local list = Instance.new("UIListLayout"); list.FillDirection = Enum.FillDirection.Horizontal; list.VerticalAlignment = Enum.VerticalAlignment.Center; list.SortOrder = Enum.SortOrder.LayoutOrder; list.Padding = UDim.new(0,10); list.Parent = holder
    local spin = Instance.new("Frame"); spin.Name = "Spin"; spin.Size = UDim2.fromOffset(18,18); spin.BackgroundTransparency = 1; spin.BorderSizePixel = 0; spin.LayoutOrder = 1; spin.Parent = holder
    local ring = Instance.new("Frame"); ring.Size = UDim2.fromScale(1,1); ring.BackgroundTransparency = 1; ring.BorderSizePixel = 0; ring.Parent = spin
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1,0)
    local ringStroke = Instance.new("UIStroke"); ringStroke.Thickness = 2; ringStroke.Color = Color3.fromRGB(255,255,255); ringStroke.Transparency = 0.86; ringStroke.Parent = ring
    local orbit = Instance.new("Frame"); orbit.Name = "Orbit"; orbit.Size = UDim2.fromScale(1,1); orbit.BackgroundTransparency = 1; orbit.BorderSizePixel = 0; orbit.Parent = spin
    local RADIUS = 6.5
    for i = 0, 2 do
        local ang = math.rad(-24 * i); local sz = (i==0) and 5 or 4
        local dot = Instance.new("Frame"); dot.Size = UDim2.fromOffset(sz,sz); dot.AnchorPoint = Vector2.new(0.5,0.5)
        dot.Position = UDim2.new(0.5, math.sin(ang)*RADIUS, 0.5, -math.cos(ang)*RADIUS)
        dot.BackgroundColor3 = Color3.fromRGB(255,255,255); dot.BackgroundTransparency = i*0.34; dot.BorderSizePixel = 0; dot.Parent = orbit
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    end
    local label = Instance.new("TextLabel")
    label.Name = "Text"; label.AutomaticSize = Enum.AutomaticSize.XY; label.Size = UDim2.fromOffset(0,0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamMedium; label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255,255,255); label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "..."; label.LayoutOrder = 2; label.Parent = holder
    local spinConn = bind(RunService.RenderStepped:Connect(function(dt) orbit.Rotation = (orbit.Rotation + dt*300) % 360 end))
    function Loader.setText(txt) pcall(function() label.Text = txt end) end
    function Loader.done()
        pcall(function() spinConn:Disconnect() end)
        pcall(function()
            local info = TweenInfo.new(0.25)
            TweenService:Create(holder, info, {BackgroundTransparency=1}):Play()
            TweenService:Create(stroke, info, {Transparency=1}):Play()
            TweenService:Create(ringStroke, info, {Transparency=1}):Play()
            TweenService:Create(label, info, {TextTransparency=1}):Play()
            for _, d in ipairs(orbit:GetChildren()) do if d:IsA("Frame") then TweenService:Create(d, info, {BackgroundTransparency=1}):Play() end end
        end)
        task.delay(0.3, function() pcall(function() holder:Destroy() end) end)
    end
end

-- SETTINGS
local Settings = {
    AimbotEnabled = false, FOV = 80, ShowFOV = false, Smoothness = 0,
    TeamCheck = false, EspTeamCheck = false, WallCheck = false, TargetPart = "Head", Sticky = false,
    Prediction = false, BulletSpeed = 1200, GravityMode = "Workspace", CustomGravity = 196.2, VelocityStrength = 1,
    ProjectileChoice = {}, NoRecoilStrength = 1,
    EspEnabled = false, EspBox = true, EspTracer = true, EspName = false, EspDistance = false, EspHealth = false,
    EspThickness = 1, TracerOrigin = "Bottom", MaxDistance = 2000, ClickSound = true,
    AimPriority = "Center", AimMaxDistance = 5000, Whitelist = "", Blacklist = "", AimEasing = "Linear",
    ItemESP = false, ItemNames = "", ItemESPColor = Color3.fromRGB(255, 215, 0),
    StreamSafe = false, KillSound = false, NoRecoil = false, NoSpread = false,
    AimHold = false, EspFpsCap = 60,
    HitboxHead = false, HitboxSize = 5,
    Colors = {},
}
local WHITE = Color3.new(1,1,1)
Settings.Colors = {Box=WHITE, Tracer=WHITE, Text=WHITE, FOV=WHITE, Team=Color3.fromRGB(0,255,120)}

local function parseNameList(str)
    local t = {}
    for name in string.gmatch(str or "", "([^,]+)") do
        name = name:match("^%s*(.-)%s*$")
        if #name > 0 then t[name:lower()] = true end
    end
    return t
end
-- cache do parse (antes montava uma tabela nova por jogador por frame)
local nameListCache = {}
local function getNameList(listStr)
    local cached = nameListCache[listStr or ""]
    if not cached then
        cached = parseNameList(listStr)
        nameListCache[listStr or ""] = cached
    end
    return cached
end
local function isNameListed(player, listStr)
    local list = getNameList(listStr)
    if not next(list) then return false end
    local display = player.DisplayName:lower(); local name = player.Name:lower()
    return list[display] or list[name]
end

local function saveSettings()
    pcall(function()
        if not writefile then return end
        if makefolder and isfolder and not isfolder("YoareDevsHub") then makefolder("YoareDevsHub") end
        local copy = {}
        for k, v in pairs(Settings) do if k ~= "Colors" then copy[k] = v end end
        copy.BoxColor = {Settings.Colors.Box.R, Settings.Colors.Box.G, Settings.Colors.Box.B}
        copy.TracerColor = {Settings.Colors.Tracer.R, Settings.Colors.Tracer.G, Settings.Colors.Tracer.B}
        copy.TextColor = {Settings.Colors.Text.R, Settings.Colors.Text.G, Settings.Colors.Text.B}
        copy.FOVColor = {Settings.Colors.FOV.R, Settings.Colors.FOV.G, Settings.Colors.FOV.B}
        copy.TeamColor = {Settings.Colors.Team.R, Settings.Colors.Team.G, Settings.Colors.Team.B}
        copy.ItemESPColor = {Settings.ItemESPColor.R, Settings.ItemESPColor.G, Settings.ItemESPColor.B}
        writefile(SETTINGS_FILE, HttpService:JSONEncode(copy))
    end)
end

local function loadSettings()
    pcall(function()
        if not readfile or not isfile or not isfile(SETTINGS_FILE) then return end
        local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
        if type(data) ~= "table" then return end
        for k, v in pairs(data) do
            if k == "BoxColor" and type(v) == "table" then Settings.Colors.Box = Color3.new(v[1], v[2], v[3])
            elseif k == "TracerColor" and type(v) == "table" then Settings.Colors.Tracer = Color3.new(v[1], v[2], v[3])
            elseif k == "TextColor" and type(v) == "table" then Settings.Colors.Text = Color3.new(v[1], v[2], v[3])
            elseif k == "FOVColor" and type(v) == "table" then Settings.Colors.FOV = Color3.new(v[1], v[2], v[3])
            elseif k == "TeamColor" and type(v) == "table" then Settings.Colors.Team = Color3.new(v[1], v[2], v[3])
            elseif k == "ItemESPColor" and type(v) == "table" then Settings.ItemESPColor = Color3.new(v[1], v[2], v[3])
            elseif Settings[k] ~= nil then Settings[k] = v end
        end
    end)
end
loadSettings()

local function playClickSound()
    if not Settings.ClickSound then return end
    pcall(function()
        local s = Instance.new("Sound"); s.SoundId = "rbxassetid://6042053626"; s.Volume = 1; s.Parent = CoreGui; s:Play(); Debris:AddItem(s, 1)
    end)
end

local function playKillSound()
    if not Settings.KillSound then return end
    pcall(function()
        local s = Instance.new("Sound"); s.SoundId = "rbxassetid://9114488953"; s.Volume = 0.8; s.Parent = CoreGui; s:Play(); Debris:AddItem(s, 2)
    end)
end

-- PRESETS SYSTEM
local function listPresets()
    local list = {}
    pcall(function()
        if not isfolder or not isfolder(PRESETS_FOLDER) then return end
        for _, file in ipairs(listfiles(PRESETS_FOLDER)) do
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end
        end
    end)
    return list
end

local function savePreset(name)
    if not name or #name == 0 then return false end
    pcall(function()
        if not writefile then return end
        if makefolder and isfolder and not isfolder("YoareDevsHub") then makefolder("YoareDevsHub") end
        if makefolder and isfolder and not isfolder(PRESETS_FOLDER) then makefolder(PRESETS_FOLDER) end
        local copy = {}
        for k, v in pairs(Settings) do if k ~= "Colors" then copy[k] = v end end
        copy.BoxColor = {Settings.Colors.Box.R, Settings.Colors.Box.G, Settings.Colors.Box.B}
        copy.TracerColor = {Settings.Colors.Tracer.R, Settings.Colors.Tracer.G, Settings.Colors.Tracer.B}
        copy.TextColor = {Settings.Colors.Text.R, Settings.Colors.Text.G, Settings.Colors.Text.B}
        copy.FOVColor = {Settings.Colors.FOV.R, Settings.Colors.FOV.G, Settings.Colors.FOV.B}
        copy.TeamColor = {Settings.Colors.Team.R, Settings.Colors.Team.G, Settings.Colors.Team.B}
        copy.ItemESPColor = {Settings.ItemESPColor.R, Settings.ItemESPColor.G, Settings.ItemESPColor.B}
        writefile(PRESETS_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(copy))
    end)
    return true
end

local function loadPreset(name)
    if not name then return false end
    pcall(function()
        if not readfile or not isfile or not isfile(PRESETS_FOLDER .. "/" .. name .. ".json") then return end
        local data = HttpService:JSONDecode(readfile(PRESETS_FOLDER .. "/" .. name .. ".json"))
        if type(data) ~= "table" then return end
        for k, v in pairs(data) do
            if k == "BoxColor" and type(v) == "table" then Settings.Colors.Box = Color3.new(v[1], v[2], v[3])
            elseif k == "TracerColor" and type(v) == "table" then Settings.Colors.Tracer = Color3.new(v[1], v[2], v[3])
            elseif k == "TextColor" and type(v) == "table" then Settings.Colors.Text = Color3.new(v[1], v[2], v[3])
            elseif k == "FOVColor" and type(v) == "table" then Settings.Colors.FOV = Color3.new(v[1], v[2], v[3])
            elseif k == "TeamColor" and type(v) == "table" then Settings.Colors.Team = Color3.new(v[1], v[2], v[3])
            elseif k == "ItemESPColor" and type(v) == "table" then Settings.ItemESPColor = Color3.new(v[1], v[2], v[3])
            elseif Settings[k] ~= nil then Settings[k] = v end
        end
    end)
    return true
end

local function deletePreset(name)
    if not name then return false end
    pcall(function()
        if delfile and isfile and isfile(PRESETS_FOLDER .. "/" .. name .. ".json") then
            delfile(PRESETS_FOLDER .. "/" .. name .. ".json")
        end
    end)
    return true
end

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function newFrame(parent, z)
    return mk("Frame", {BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Visible=false, ZIndex=z or 2}, parent)
end
local function newLabel(parent, size, z)
    return mk("TextLabel", {BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=size, TextColor3=Color3.new(1,1,1), TextStrokeTransparency=0, TextStrokeColor3=Color3.new(0,0,0), AnchorPoint=Vector2.new(0.5,0.5), Size=UDim2.fromOffset(260,16), Visible=false, ZIndex=z or 5}, parent)
end
local function lineBetween(f, from, to, thickness)
    local d = to - from
    f.Size = UDim2.fromOffset(math.max(d.Magnitude, 1), thickness)
    f.Position = UDim2.fromOffset((from.X+to.X)*0.5, (from.Y+to.Y)*0.5)
    f.Rotation = math.deg(math.atan2(d.Y, d.X))
end
local function setRect(f, x, y, w, h)
    f.Position = UDim2.fromOffset(x+w*0.5, y+h*0.5)
    f.Size = UDim2.fromOffset(w, h)
    f.Rotation = 0
end
local function col(which) return Settings.Colors[which] end

-- HITBOX HEAD (adiciona uma part extra, invisivel, soldada por fora da cabeca
-- do inimigo, so no seu client - facilita headshot em hit-detection local/hitscan
-- por raycast. NUNCA altera a Head original -> nao quebra fisica, ragdoll,
-- animacao nem HUD de vida do jogo, e nao afeta em nada outros jogadores/servidor.
-- Nome = "Head" propositalmente: muitos jogos checam hit.Name == "Head" pra
-- contar critico/headshot, entao a part extra precisa se chamar igual pra valer.
-- Identificacao interna usa Attribute, nao o Name (que fica igual ao original).
local function findHitboxPart(head)
    for _, child in ipairs(head:GetChildren()) do
        if child:GetAttribute("YOARE_Hitbox") then return child end
    end
    return nil
end
local function applyHeadHitbox(head, player)
    if not head or not head:IsA("BasePart") or player == LocalPlayer then return end
    local existing = findHitboxPart(head)
    if Settings.HitboxHead then
        local s = Settings.HitboxSize
        if existing then
            existing.Size = Vector3.new(s, s, s)
        else
            local part = Instance.new("Part")
            part.Name = "Head"
            part:SetAttribute("YOARE_Hitbox", true)
            part.Shape = Enum.PartType.Ball
            part.Size = Vector3.new(s, s, s)
            part.Transparency = 1
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = true
            part.Massless = true
            part.CastShadow = false
            part.CFrame = head.CFrame
            part.Parent = head
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = head
            weld.Part1 = part
            weld.Parent = part
        end
    elseif existing then
        existing:Destroy()
    end
end
local function restoreAllHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local existing = head and findHitboxPart(head)
        if existing then existing:Destroy() end
    end
end
local function refreshAllHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            applyHeadHitbox(player.Character:FindFirstChild("Head"), player)
        end
    end
end

-- PLAYER CACHE
local PlayerCache = {}
local function cacheCharacter(player, char)
    local cache = {Character = char}
    cache.Humanoid = char:FindFirstChildOfClass("Humanoid")
    cache.RootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    cache.Head = char:FindFirstChild("Head")
    PlayerCache[player] = cache
    -- CharacterAdded de OUTROS jogadores dispara antes dos filhos
    -- (Humanoid/HumanoidRootPart) replicarem pro seu cliente. Sem essa
    -- re-tentativa em background o cache ficava com Humanoid=nil pra
    -- sempre e o jogador sumia do ESP/Aimbot ate respawnar de novo.
    task.spawn(function()
        if not (cache.Humanoid and cache.Humanoid.Parent) then
            cache.Humanoid = char:WaitForChild("Humanoid", 5)
        end
        if not (cache.RootPart and cache.RootPart.Parent) then
            cache.RootPart = char:WaitForChild("HumanoidRootPart", 5) or char:FindFirstChild("Torso")
        end
        if not (cache.Head and cache.Head.Parent) then
            cache.Head = char:WaitForChild("Head", 5)
        end
        if Settings.HitboxHead then applyHeadHitbox(cache.Head, player) end
    end)
    if Settings.HitboxHead then applyHeadHitbox(cache.Head, player) end
end
local function clearCache(player) PlayerCache[player] = nil end
-- getCache agora re-resolve lazy qualquer parte nil/destruida em vez de
-- devolver o cache congelado (pegava Humanoid=nil eterno + partes com
-- StreamingEnabled, onde a parte some e volta)
local function getCache(player)
    local c = PlayerCache[player]
    if not c then return nil end
    local char = c.Character
    if not (char and char.Parent) then return nil end
    if not (c.Humanoid and c.Humanoid.Parent) then
        c.Humanoid = char:FindFirstChildOfClass("Humanoid")
    end
    if not (c.RootPart and c.RootPart.Parent) then
        c.RootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    end
    if not (c.Head and c.Head.Parent) then
        c.Head = char:FindFirstChild("Head")
    end
    return c
end

for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then cacheCharacter(p, p.Character) end
    bind(p.CharacterAdded:Connect(function(char) cacheCharacter(p, char) end))
    bind(p.CharacterRemoving:Connect(function() clearCache(p) end))
end
bind(Players.PlayerAdded:Connect(function(p)
    if p.Character then cacheCharacter(p, p.Character) end
    bind(p.CharacterAdded:Connect(function(char) cacheCharacter(p, char) end))
    bind(p.CharacterRemoving:Connect(function() clearCache(p) end))
end))
bind(Players.PlayerRemoving:Connect(function(p) clearCache(p) end))

local function isAlive(player)
    local c = getCache(player)
    if not c then return false end
    local hum = c.Humanoid
    return hum ~= nil and hum.Health > 0
end
-- times aliados: alguns jogos criam mais de um objeto Team pro mesmo
-- lado (ex.: "Vermelho A" e "Vermelho B" lutando juntos). O jeito
-- classico de marcar isso no Roblox e' dar a mesma TeamColor pros dois,
-- entao alem de comparar o Team em si, comparamos a TeamColor tambem
-- pra pegar esses casos sem precisar saber o nome exato dos times.
local WHITE_BRICK = BrickColor.White()
local function isTeammate(player)
    local myTeam, theirTeam = LocalPlayer.Team, player.Team
    if myTeam and theirTeam then
        if myTeam == theirTeam then return true end
        if myTeam.TeamColor and theirTeam.TeamColor and myTeam.TeamColor == theirTeam.TeamColor then
            return true
        end
        return false
    end
    -- sem Team nativo: alguns jogos so' setam TeamColor direto no Player
    local myColor, theirColor = LocalPlayer.TeamColor, player.TeamColor
    if myColor and theirColor and myColor ~= WHITE_BRICK and theirColor ~= WHITE_BRICK then
        return myColor == theirColor
    end
    return false
end
local function blockedByTeam(player)
    if not Settings.TeamCheck then return false end
    return isTeammate(player)
end
local function blockedByEspTeam(player)
    if not Settings.EspTeamCheck then return false end
    return isTeammate(player)
end
-- RaycastParams reaproveitado (antes criava um objeto novo por jogador por frame)
local RAY_PARAMS = RaycastParams.new()
RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
local rayFilterChar = nil
local function refreshRayFilter()
    local char = LocalPlayer.Character
    if rayFilterChar ~= char then
        rayFilterChar = char
        RAY_PARAMS.FilterDescendantsInstances = {char, Camera}
    end
end
local function isVisible(targetPart)
    if not Settings.WallCheck then return true end
    refreshRayFilter()
    local origin = Camera.CFrame.Position
    local result = Workspace:Raycast(origin, targetPart.Position - origin, RAY_PARAMS)
    if result then return result.Instance:IsDescendantOf(targetPart.Parent) end
    return true
end
local function partOf(char)
    local player = Players:GetPlayerFromCharacter(char)
    local cache = player and getCache(player)
    if cache and cache.RootPart then
        if Settings.TargetPart == "Head" then return char:FindFirstChild("Head") or cache.RootPart end
        return char:FindFirstChild(Settings.TargetPart) or cache.RootPart
    end
    return char:FindFirstChild(Settings.TargetPart) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end
local function distanceTo(pos)
    local myCache = getCache(LocalPlayer)
    if myCache and myCache.RootPart then return (myCache.RootPart.Position - pos).Magnitude end
    return (Camera.CFrame.Position - pos).Magnitude
end

-- PREDICAO
local function getBulletGravity()
    local m = Settings.GravityMode
    if m == "Workspace" then return math.abs(Workspace.Gravity) end
    if m == "Roblox" then return 196.2 end
    if m == "Zero" then return 0 end
    return math.abs(Settings.CustomGravity)
end
-- velocidade suavizada por personagem: a fisica do Roblox da "trepidaçao"
-- na AssemblyLinearVelocity e isso deixava a prediction nervosa. Com media
-- movel a mira fica cravada e ainda acompanha o alvo em movimento.
local velSmoothCache = setmetatable({}, { __mode = "k" })
local function getPartVelocity(char)
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    local v = (root and root.AssemblyLinearVelocity) or Vector3.zero
    local s = velSmoothCache[char]
    if not s then
        velSmoothCache[char] = v
        return v
    end
    local sm = s:Lerp(v, 0.35)
    velSmoothCache[char] = sm
    return sm
end
local function predictAimPosition(part)
    local pos = part.Position
    if not Settings.Prediction then return pos end
    if Settings.BulletSpeed <= 0 then return pos end
    local char = part.Parent
    local vel = getPartVelocity(char) * Settings.VelocityStrength
    local origin = Camera.CFrame.Position
    local t1 = (origin - pos).Magnitude / Settings.BulletSpeed
    local predicted = pos + vel * t1
    local t2 = (origin - predicted).Magnitude / Settings.BulletSpeed
    predicted = pos + vel * t2
    local drop = 0.5 * getBulletGravity() * t2 * t2
    if drop > 0 then predicted = predicted + Vector3.new(0, drop, 0) end
    return predicted
end

-- DETECCAO DE SISTEMA DE PROJETIL (bala com tempo de voo / queda real)
-- Escaneia o jogo por indicios REAIS de um sistema de projetil (nao chuta):
-- tags do CollectionService usadas por modulos conhecidos, nomes de
-- ModuleScript/Instancias famosas (FastCast, etc.) e pastas comuns de bala
-- direto no Workspace. Se achar, guarda o caminho exato do objeto encontrado
-- pra mostrar pro usuario no popup (prova real, nao suposicao).
local PROJECTILE_TAGS = {"Bullet", "Projectile", "Bolt", "Casing", "FastCastProjectile"}
local PROJECTILE_NAME_KEYS = {
    "fastcast", "fastcastredux", "projectile", "ballistic", "bulletmodule",
    "raycastprojectile", "trajectory", "bulletphysics", "projectilemotion",
    "bulletdrop", "traveltime",
}
local PROJECTILE_FOLDER_KEYS = {"bullets", "projectiles", "casings", "bolts", "rounds"}
local PROJECTILE_SCAN_CAP = 20000 -- limite de instancias verificadas por raiz, pra nao travar em jogos gigantes

local function detectProjectileSystem()
    local found = nil

    -- 1) tags do CollectionService (mais barato e mais confiavel)
    pcall(function()
        local CollectionService = game:GetService("CollectionService")
        for _, tag in ipairs(PROJECTILE_TAGS) do
            local items = CollectionService:GetTagged(tag)
            if items and #items > 0 then
                found = string.format("CollectionService tag \"%s\" (%s)", tag, items[1]:GetFullName())
                return
            end
        end
    end)
    if found then return found end

    -- 2) nomes conhecidos de modulos/instancias de projetil real
    local roots = {ReplicatedStorage, game:GetService("ReplicatedFirst"), Workspace}
    for _, root in ipairs(roots) do
        if found then break end
        pcall(function()
            local checked = 0
            for _, inst in ipairs(root:GetDescendants()) do
                checked += 1
                if checked > PROJECTILE_SCAN_CAP then return end
                local lname = inst.Name:lower()
                for _, key in ipairs(PROJECTILE_NAME_KEYS) do
                    if lname:find(key, 1, true) then
                        found = string.format("%s (%s)", inst:GetFullName(), inst.ClassName)
                        return
                    end
                end
            end
        end)
    end
    if found then return found end

    -- 3) pastas de bala direto no Workspace (folder ativa contando como sinal forte)
    pcall(function()
        for _, child in ipairs(Workspace:GetChildren()) do
            local lname = child.Name:lower()
            for _, key in ipairs(PROJECTILE_FOLDER_KEYS) do
                if lname:find(key, 1, true) then
                    found = string.format("%s (%s)", child:GetFullName(), child.ClassName)
                    return
                end
            end
        end
    end)
    return found
end

-- AIMBOT
local function getClosestPlayer()
    local vp = Camera.ViewportSize
    local cx, cy = vp.X * 0.5, vp.Y * 0.5
    local fov = Settings.FOV
    local fovSq = fov * fov
    local byDistance = (Settings.AimPriority == "Distance")
    local wl, bl = Settings.Whitelist, Settings.Blacklist
    local maxDist = Settings.AimMaxDistance

    -- ordena candidatos sem raycast; o wall check roda uma vez no final
    local candidates, n = nil, 0
    local best, bestScore, bestPart = nil, math.huge, nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) and not blockedByTeam(player) then
            if wl ~= "" and not isNameListed(player, wl) then continue end
            if bl ~= "" and isNameListed(player, bl) then continue end
            local char = player.Character
            local part = char and partOf(char)
            if part then
                local dist3D = distanceTo(part.Position)
                if dist3D <= maxDist then
                    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dx, dy = sp.X - cx, sp.Y - cy
                        local pixSq = dx*dx + dy*dy
                        -- o FOV sempre filtra em pixels; a prioridade so muda a ordem
                        if pixSq <= fovSq then
                            local score = byDistance and dist3D or pixSq
                            if score < bestScore then
                                if Settings.WallCheck then
                                    candidates = candidates or {}
                                    n += 1
                                    candidates[n] = {p = player, part = part, s = score}
                                end
                                best, bestScore, bestPart = player, score, part
                            end
                        end
                    end
                end
            end
        end
    end

    if not Settings.WallCheck then return best end
    if not candidates then return nil end
    -- do melhor pro pior, para no primeiro visivel (antes raycastava todos)
    table.sort(candidates, function(a, b) return a.s < b.s end)
    for i = 1, n do
        local c = candidates[i]
        if c.p.Parent and isVisible(c.part) then return c.p end
    end
    return nil
end

-- EASING
local function applyEasing(alpha, mode)
    if mode == "Sine" then return math.sin(alpha * math.pi / 2)
    elseif mode == "Quad" then return alpha * alpha end
    return alpha
end

-- FOV CIRCLE
local FOVCircle = mk("Frame", {Name="FOVCircle", AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, BorderSizePixel=0, Visible=false, ZIndex=1}, Screen)
mk("UICorner", {CornerRadius=UDim.new(1,0)}, FOVCircle)
local FOVStroke = mk("UIStroke", {Thickness=2, Color=Color3.fromRGB(255,80,0)}, FOVCircle)

-- PLAYER ESP
local ESP_Cache = {}
local function CreateEsp(player)
    if player == LocalPlayer or ESP_Cache[player] then return end
    local holder = mk("Folder", {Name="ESP_"..player.Name}, Screen)
    local o = {Holder = holder, Box = {}, Tracer = newFrame(holder, 2)}
    for i = 1, 4 do o.Box[i] = newFrame(holder, 3) end
    o.Name = newLabel(holder, 14, 5); o.Distance = newLabel(holder, 13, 5)
    o.HpBack = newFrame(holder, 2); o.HpBack.BackgroundColor3 = Color3.new(0,0,0)
    o.HpFill = newFrame(holder, 3)
    ESP_Cache[player] = o
end
local function hideEsp(o)
    for i = 1, 4 do o.Box[i].Visible = false end
    o.Tracer.Visible, o.Name.Visible, o.Distance.Visible = false, false, false
    o.HpBack.Visible, o.HpFill.Visible = false, false
end
local function RemoveEsp(player)
    local o = ESP_Cache[player]
    if o then if o.Holder then o.Holder:Destroy() end; ESP_Cache[player] = nil end
end
local function hideAllEsp()
    for _, o in pairs(ESP_Cache) do hideEsp(o) end
end
for _, p in ipairs(Players:GetPlayers()) do CreateEsp(p) end
bind(Players.PlayerAdded:Connect(CreateEsp))
bind(Players.PlayerRemoving:Connect(RemoveEsp))

local function updateEsp(player, o)
    if not Settings.EspEnabled or not player.Parent then return hideEsp(o) end
    local cache = getCache(player)
    if not cache or not cache.RootPart or not isAlive(player) then return hideEsp(o) end
    if blockedByEspTeam(player) then return hideEsp(o) end
    local hrp = cache.RootPart
    local dist = distanceTo(hrp.Position)
    if dist > Settings.MaxDistance then return hideEsp(o) end
    local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then return hideEsp(o) end
    local sizeX = 2000 / sp.Z; local sizeY = 2500 / sp.Z
    local bx, by = sp.X - sizeX/2, sp.Y - sizeY/2
    local color = isTeammate(player) and col("Team") or col("Box")
    local thick = Settings.EspThickness
    if Settings.EspBox then
        local e = {
            {Vector2.new(bx, by), Vector2.new(bx+sizeX, by)},
            {Vector2.new(bx, by+sizeY), Vector2.new(bx+sizeX, by+sizeY)},
            {Vector2.new(bx, by), Vector2.new(bx, by+sizeY)},
            {Vector2.new(bx+sizeX, by), Vector2.new(bx+sizeX, by+sizeY)},
        }
        for i = 1, 4 do lineBetween(o.Box[i], e[i][1], e[i][2], thick); o.Box[i].BackgroundColor3 = color; o.Box[i].Visible = true end
    else for i = 1, 4 do o.Box[i].Visible = false end end
    if Settings.EspTracer then
        local vp = Camera.ViewportSize; local from
        if Settings.TracerOrigin == "Center" then from = Vector2.new(vp.X/2, vp.Y/2)
        elseif Settings.TracerOrigin == "Top" then from = Vector2.new(vp.X/2, 0)
        elseif Settings.TracerOrigin == "Mouse" then from = Vector2.new(Mouse.X, Mouse.Y + 36)
        else from = Vector2.new(vp.X/2, vp.Y) end
        lineBetween(o.Tracer, from, Vector2.new(sp.X, sp.Y), thick)
        o.Tracer.BackgroundColor3 = isTeammate(player) and col("Team") or col("Tracer")
        o.Tracer.Visible = true
    else o.Tracer.Visible = false end
    if Settings.EspName then o.Name.Text = player.DisplayName; o.Name.TextColor3 = col("Text"); o.Name.Position = UDim2.fromOffset(bx + sizeX/2, by - 12); o.Name.Visible = true else o.Name.Visible = false end
    if Settings.EspDistance then o.Distance.Text = string.format("[%dm]", math.floor(dist)); o.Distance.TextColor3 = col("Text"); o.Distance.Position = UDim2.fromOffset(bx + sizeX/2, by + sizeY + 10); o.Distance.Visible = true else o.Distance.Visible = false end
    if Settings.EspHealth then
        local hum = cache.Humanoid
        local pct = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1) or 0
        local W = 3
        setRect(o.HpBack, bx - 6, by - 1, W + 2, sizeY + 2)
        local fh = math.max(sizeY * pct, 1)
        setRect(o.HpFill, bx - 5, by + sizeY - fh, W, fh)
        o.HpFill.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-pct)), math.floor(255*pct), 60)
        o.HpBack.Visible, o.HpFill.Visible = true, true
    else o.HpBack.Visible, o.HpFill.Visible = false, false end
end

-- ITEM ESP
local ItemESP_Cache = {}
local function updateItemESP()
    if not Settings.ItemESP then
        for _, o in pairs(ItemESP_Cache) do pcall(function() o:Destroy() end) end
        ItemESP_Cache = {}
        return
    end
    local names = parseNameList(Settings.ItemNames)
    if not next(names) then
        for _, o in pairs(ItemESP_Cache) do pcall(function() o:Destroy() end) end
        ItemESP_Cache = {}
        return
    end
    for inst, label in pairs(ItemESP_Cache) do
        if not inst or not inst.Parent then pcall(function() label:Destroy() end); ItemESP_Cache[inst] = nil end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and names[obj.Name:lower()] and not ItemESP_Cache[obj] then
            local lbl = newLabel(Screen, 13, 6); lbl.Text = obj.Name; lbl.TextColor3 = Settings.ItemESPColor; ItemESP_Cache[obj] = lbl
        end
    end
    for inst, lbl in pairs(ItemESP_Cache) do
        if inst and inst.Parent then
            local sp, onScreen = Camera:WorldToViewportPoint(inst.Position)
            if onScreen then lbl.Position = UDim2.fromOffset(sp.X, sp.Y); lbl.Visible = true else lbl.Visible = false end
        else lbl.Visible = false end
    end
end

-- LOCK INDICATOR (icone de cadeado lucide + nome do alvo, branco, com pulso)
local LockIndicator = mk("Frame", {
    Name = "LockIndicator", BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(220, 20), Position = UDim2.new(0.5, 0, 0.85, 0),
    Visible = false, ZIndex = 100001,
}, Screen)
mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
    HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6),
}, LockIndicator)
local LockIcon = mk("Frame", { -- placeholder ate' o WindUI carregar e trocarmos por um ImageLabel de icone
    Name = "LockIcon", BackgroundTransparency = 1, Size = UDim2.fromOffset(16, 16),
    LayoutOrder = 1, ZIndex = 100002,
}, LockIndicator)
local LockText = mk("TextLabel", {
    Name = "LockText", BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
    TextSize = 16, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.5,
    TextStrokeColor3 = Color3.new(0, 0, 0), AutomaticSize = Enum.AutomaticSize.X,
    Size = UDim2.fromOffset(0, 20), LayoutOrder = 2, ZIndex = 100002, Text = "",
    TextXAlignment = Enum.TextXAlignment.Left,
}, LockIndicator)
-- animacao de pulso (opacidade oscilando), roda continuo, so' fica visivel quando o LockIndicator.Visible = true
local lockPulseTween = nil
local function startLockPulse(imageLabel)
    pcall(function() if lockPulseTween then lockPulseTween:Cancel() end end)
    if not imageLabel then return end
    imageLabel.ImageTransparency = 0
    local info = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    lockPulseTween = TweenService:Create(imageLabel, info, {ImageTransparency = 0.55})
    lockPulseTween:Play()
end

-- KILL TRACKER (contador separado, nao usa fpsFrameCount)
local lastHealthMap = {}
local killTrackerCounter = 0

-- NORECOIL
local noRecoilLastCF = nil
local aimbotMovedCamera = false -- true quando o aimbot moveu a camera NESTE frame
local noRecoilReleaseAt = 0 -- tick() de quando o mouse/dedo soltou, pra segurar a correcao
-- um pouco depois do "solta o botao" (arma semi-auto/tap-fire ainda esta
-- recuperando a camera do coice quando o disparo ja acabou de sair)
local NO_RECOIL_GRACE = 0.35

local currentTarget = nil
local fpsFrameCount = 0
local fpsLastTime = tick()
local currentFPS = 60

-- HOLD DETECT (mouse ou dedo na tela) - usado pelo AimHold e pelo No Recoil
local holdCount = 0
bind(UserInputService.InputBegan:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        holdCount += 1
    end
end))
bind(UserInputService.InputEnded:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        holdCount = math.max(holdCount - 1, 0)
        if holdCount == 0 then noRecoilReleaseAt = tick() end
    end
end))
local function isHolding() return holdCount > 0 end
-- verdadeiro enquanto atirando OU dentro da janela de graca pos-solta (tap-fire)
local function isRecoilActive() return isHolding() or (tick() - noRecoilReleaseAt) < NO_RECOIL_GRACE end

-- SPREAD / RECOIL NOS VALORES DA ARMA
-- Muitos jogos guardam spread/recoil em NumberValues dentro da tool ou num
-- ModuleScript de config (ex.: "GunStates"). O NoSpread antigo so' tinha a
-- toggle e NUNCA aplicava nada -- aqui o hub zera esses valores direto na
-- arma equipada e re-aplica de tempo em tempo (o jogo pode resetar).
local SPREAD_ZERO_KEYS = { "spread", "spreadx", "spready", "spreadmin", "spreadmax", "minspread", "maxspread", "hipspread", "aimspread", "spreadmultiplier", "spreadred", "basespread" }
local RECOIL_ZERO_KEYS = { "recoil", "recoilamount", "recoilx", "recoily", "recoilz", "recoilmultiplier", "recoilmin", "recoilmax", "kick", "kickup", "camkick", "camshake" }
local function keyIn(list, n) for _, k in ipairs(list) do if n == k then return true end end return false end

local function applyWeaponMods()
    if not (Settings.NoSpread or Settings.NoRecoil) then return end
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end
    for _, obj in ipairs(tool:GetDescendants()) do
        pcall(function()
            if obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("FloatValue") or obj:IsA("DoubleValue") then
                local n = obj.Name:lower()
                if Settings.NoSpread then
                    if keyIn(SPREAD_ZERO_KEYS, n) then obj.Value = 0
                    elseif n == "accuracy" then obj.Value = (obj.MaxValue and obj.MaxValue > 0) and obj.MaxValue or 100 end
                end
                if Settings.NoRecoil and keyIn(RECOIL_ZERO_KEYS, n) then obj.Value = 0 end
            elseif obj:IsA("ModuleScript") then
                local nm = obj.Name:lower()
                if nm:find("state") or nm:find("config") or nm:find("setting") or nm:find("gun") or nm:find("weapon") or nm:find("data") then
                    local ok, mod = pcall(require, obj)
                    if ok and type(mod) == "table" then
                        for k, v in pairs(mod) do
                            if type(v) == "number" then
                                local lk = string.lower(tostring(k))
                                if Settings.NoSpread and string.find(lk, "spread") then mod[k] = 0
                                elseif Settings.NoSpread and lk == "accuracy" then mod[k] = 100
                                elseif Settings.NoRecoil and string.find(lk, "recoil") then mod[k] = 0 end
                            end
                        end
                    end
                end
            end
        end)
    end
end

task.spawn(function()
    while true do
        task.wait(0.2)
        applyWeaponMods()
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.2)
            applyWeaponMods()
        end
    end)
end)

-- throttle do ESP (em telas de 120Hz nao precisa recalcular 120x por segundo)
local espAccum = 0
local espVisible = false

-- CurrentCamera via evento em vez de leitura por frame
bind(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera or Camera
    rayFilterChar = nil
end))

-- RENDER LOOP (otimizado: apenas o essencial aqui)
bind(RunService.RenderStepped:Connect(function(dt)
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return end
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    fpsFrameCount = fpsFrameCount + 1
    local now = tick()
    if now - fpsLastTime >= 1 then currentFPS = fpsFrameCount; fpsFrameCount = 0; fpsLastTime = now end

    -- FOV
    if Settings.ShowFOV then
        FOVCircle.Position = UDim2.fromOffset(center.X, center.Y)
        FOVCircle.Size = UDim2.fromOffset(Settings.FOV*2, Settings.FOV*2)
        FOVStroke.Color = col("FOV")
        FOVCircle.Visible = true
    else FOVCircle.Visible = false end

    aimbotMovedCamera = false

    -- Aimbot (isolado em pcall: um erro aqui (ex.: char no meio do respawn)
    -- nao pode travar o resto do frame e derrubar o ESP junto)
    local aimOk, aimErr = pcall(function()
        if Settings.AimbotEnabled and (not Settings.AimHold or isHolding()) then
            local keep = Settings.Sticky and currentTarget
            if keep then
                local valid = currentTarget.Parent ~= nil and isAlive(currentTarget) and not blockedByTeam(currentTarget)
                if valid and Settings.WallCheck then local char = currentTarget.Character; local p = char and partOf(char); valid = p ~= nil and isVisible(p) end
                if not valid then keep = false; currentTarget = nil end
            end
            if not keep then currentTarget = getClosestPlayer() end
            if currentTarget and currentTarget.Character then
                local part = partOf(currentTarget.Character)
                if part then
                    local aimPos = predictAimPosition(part)
                    local goal = CFrame.new(Camera.CFrame.Position, aimPos)
                    if Settings.Smoothness <= 0 then
                        Camera.CFrame = goal
                    else
                        local base = 1 - math.clamp(Settings.Smoothness, 0, 0.95)
                        local rawAlpha = 1 - math.pow(base, math.clamp(dt * 60, 0.1, 10))
                        local alpha = applyEasing(rawAlpha, Settings.AimEasing)
                        Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
                    end
                    aimbotMovedCamera = true
                    LockText.Text = currentTarget.DisplayName
                    LockIndicator.Visible = true
                end
            else LockIndicator.Visible = false end
        else currentTarget = nil; LockIndicator.Visible = false end
    end)
    if not aimOk then
        currentTarget = nil
        LockIndicator.Visible = false
        warn("[yoaredevs] Aimbot error:", aimErr)
    end

    -- No Recoil v3: cancela a ROTACAO do coice em vez de remontar o
    -- LookVector na mao (a v2 mudava a direcao real da mira). Pega pitch,
    -- yaw E roll do delta de camera entre frames e anula uma fração
    -- ajustavel. Quem estiver atirando o aimbot recentra sozinho, entao a
    -- correcao PULA os frames onde o proprio aimbot moveu a camera -- os
    -- dois nao brigam mais e a mira para de tremer.
    local recoilOk, recoilErr = pcall(function()
        if Settings.NoRecoil then
            local current = Camera.CFrame
            if noRecoilLastCF and isRecoilActive() and not aimbotMovedCamera then
                local strength = math.clamp(Settings.NoRecoilStrength or 1, 0.3, 2)
                -- deadzone ALTA de proposito: so' pega salto BRUSCO (coice).
                -- movimento normal de mira fica 100% livre -- acabou a
                -- sensacao de "animacao"/atraso na camera da versao anterior
                local deadzone = 0.012 / strength
                local cancel = math.clamp(0.5 * strength, 0.25, 0.8)
                local delta = noRecoilLastCF:ToObjectSpace(current)
                local rx, ry, rz = delta:ToEulerAnglesYXZ()
                if math.abs(rx) > deadzone or math.abs(ry) > deadzone or math.abs(rz) > deadzone then
                    Camera.CFrame = current * CFrame.Angles(rx * cancel, ry * cancel, rz * cancel):Inverse()
                end
            end
            noRecoilLastCF = Camera.CFrame
        elseif noRecoilLastCF then
            noRecoilLastCF = nil
        end
    end)
    if not recoilOk then
        noRecoilLastCF = nil
        warn("[yoaredevs] NoRecoil error:", recoilErr)
    end

    -- Player ESP (com limite de taxa; cada jogador tem seu proprio pcall
    -- pra um erro num player nao travar a atualizacao dos outros --
    -- antes um unico pcall envolvia o loop inteiro e um player com dado
    -- invalido (character no meio do respawn, por exemplo) parava o ESP
    -- de todo mundo que vinha depois dele naquele frame, toda vez)
    if Settings.EspEnabled then
        local cap = Settings.EspFpsCap
        local run = true
        if cap and cap > 0 and cap < 240 then
            espAccum += dt
            local step = 1 / cap
            if espAccum < step then run = false else espAccum = 0 end
        end
        if run then
            for player, o in pairs(ESP_Cache) do
                local ok, err = pcall(updateEsp, player, o)
                if not ok then
                    pcall(hideEsp, o)
                    warn("[yoaredevs] ESP error (" .. tostring(player) .. "):", err)
                end
            end
        end
    elseif espVisible then
        hideAllEsp()
    end
    espVisible = Settings.EspEnabled
end))

-- HEARTBEAT LOOP (coisas pesadas: item esp, kill tracker, gradiente)
bind(RunService.Heartbeat:Connect(function()
    -- Kill tracker (contador proprio)
    killTrackerCounter = killTrackerCounter + 1
    if killTrackerCounter % 10 == 0 then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local cache = getCache(player)
                if cache and cache.Humanoid then
                    local currentHealth = cache.Humanoid.Health
                    local last = lastHealthMap[player]
                    if Settings.KillSound and last and last > 0 and currentHealth <= 0 then
                        playKillSound()
                    end
                    lastHealthMap[player] = currentHealth
                end
            end
        end
    end

    -- Item ESP (a cada 2 segundos aprox, nao a cada frame)
    if Settings.ItemESP and killTrackerCounter % 120 == 0 then
        pcall(updateItemESP)
    end
end))

local function unload()
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    for p in pairs(ESP_Cache) do RemoveEsp(p) end
    for _, o in pairs(ItemESP_Cache) do pcall(function() o:Destroy() end) end
    pcall(restoreAllHitboxes)
    if Screen then Screen:Destroy() end
    _G.YOARE_Unload = nil
end
_G.YOARE_Unload = unload

local DEV_ROBLOX_NAME = "6r0lw"
local DEV_GITHUB = "https://github.com/yoaredevs"
local devThumb = nil
local function fetchDevThumb()
    if devThumb then return devThumb end
    local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(DEV_ROBLOX_NAME) end)
    if not ok or not id then return nil end
    local ok2, url = pcall(function() return Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end)
    if ok2 and url then devThumb = url end
    return devThumb
end

pcall(Loader.setText, T("load_ui"))
task.spawn(function() pcall(fetchDevThumb) end)

local okUI, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not okUI or type(WindUI) ~= "table" then
    pcall(Loader.done)
    warn(T("ui_fail"))
    return
end

pcall(Loader.setText, T("load_hub"))

-- troca o placeholder do LockIndicator por um icone lucide de cadeado
-- de verdade, branco, animado com pulso continuo
pcall(function()
    local icon = WindUI.Creator.Icons.Image({
        Icon = "lock", Colors = {Color3.new(1, 1, 1)}, Size = UDim2.fromOffset(16, 16),
    }).IconFrame
    if icon then
        icon.Name = "LockIcon"; icon.LayoutOrder = 1; icon.ZIndex = 100002
        icon.Parent = LockIndicator
        LockIcon:Destroy(); LockIcon = icon
        startLockPulse(icon)
    end
end)

local Window = WindUI:CreateWindow({
    Title = HUB_NAME, Icon = "crosshair", Author = "by yoaredevs",
    Folder = "YoareDevsHub", Size = UDim2.fromOffset(620, 540),
    Transparent = true, Theme = "Dark", SideBarWidth = 180,
    Background = THEME_IMAGE_URL, BackgroundImageTransparency = THEME_IMAGE_ALPHA,
})

-- STREAM SAFE
local function applyStreamSafe()
    pcall(function() if Settings.StreamSafe then Window:Minimize() else Window:Maximize() end end)
end

-- HUB NAME COLOR + GRADIENT (otimizado: tween em vez de RenderStepped)
local hubNameLabel = nil
local hubNameGradient = nil
local function findHubNameLabel()
    if hubNameLabel then return hubNameLabel end
    local roots = {}
    pcall(function() table.insert(roots, gethui()) end)
    pcall(function() table.insert(roots, CoreGui) end)
    for _, root in ipairs(roots) do
        local ok, list = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, d in ipairs(list) do
                if d:IsA("TextLabel") and d.Text == HUB_NAME then
                    hubNameLabel = d
                    return d
                end
            end
        end
    end
    return nil
end

local function setupGradient()
    local lbl = findHubNameLabel()
    if not lbl then return end
    if not hubNameGradient then
        hubNameGradient = Instance.new("UIGradient")
        hubNameGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, MIKU_COLORS[1]),
            ColorSequenceKeypoint.new(0.33, MIKU_COLORS[2]),
            ColorSequenceKeypoint.new(0.66, MIKU_COLORS[3]),
            ColorSequenceKeypoint.new(1, MIKU_COLORS[4]),
        })
        hubNameGradient.Parent = lbl
    end
end

local function removeGradient()
    if hubNameGradient then
        pcall(function() hubNameGradient:Destroy() end)
        hubNameGradient = nil
    end
end

-- Gradiente animado via Tween (muito mais leve que RenderStepped)
local gradientTweenConn = nil
local bgOn = true -- declarado ANTES das funcoes (estava so' no fim do arquivo, e o gradiente nunca animava)
local function startGradientAnimation()
    if gradientTweenConn then return end
    local function rotate()
        if not hubNameGradient or not bgOn then return end
        -- balanco suave de vai-e-vem em vez de giro completo: bem mais leve
        hubNameGradient.Rotation = 0
        local tween = TweenService:Create(hubNameGradient, TweenInfo.new(3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 35})
        tween:Play()
        gradientTweenConn = tween
    end
    rotate()
end

local function stopGradientAnimation()
    if gradientTweenConn then
        pcall(function() gradientTweenConn:Cancel() end)
        gradientTweenConn = nil
    end
    if hubNameGradient then hubNameGradient.Rotation = 0 end
end

local function setHubNameColor(color)
    local lbl = findHubNameLabel()
    if lbl then
        pcall(function() TweenService:Create(lbl, TweenInfo.new(0.25), {TextColor3 = color}):Play() end)
        return true
    end
    return false
end

pcall(function()
    Window:EditOpenButton({Title = "yoaredevs", Icon = "crosshair", CornerRadius = UDim.new(1, 0), Draggable = true})
end)

local TabHome = Window:Tab({Title = T("tab_home"), Icon = "house"})
local TabAim = Window:Tab({Title = T("tab_aim"), Icon = "crosshair"})
local TabESP = Window:Tab({Title = T("tab_esp"), Icon = "eye"})
local TabMisc = Window:Tab({Title = T("tab_misc"), Icon = "settings"})
Window:SelectTab(1)

-- VERIFICACAO DE VERSAO (obrigatoria): detectou uso anterior -> popup de
-- atualizacao com botao unico. Só aparece UMA vez por versão (marcador).
task.spawn(function()
    task.wait(0.5)
    local olds, hasOldFiles = detectPreviousUse()
    local markerExists = false
    pcall(function()
        if isfile and isfile(UPDATE_MARKER) then markerExists = true end
    end)
    local hasOldCache = #olds > 0
    warn(string.format("[yoaredevs] update-guard: caches_antigos=%d uso_anterior=%s marcador=%s",
        #olds, tostring(hasOldFiles), tostring(markerExists)))
    if markerExists or (not hasOldCache and not hasOldFiles) then return end
    local listStr = ""
    for i, o in ipairs(olds) do
        listStr = listStr .. (i > 1 and ", " or "") .. o.version
    end
    local reason
    if hasOldCache then
        reason = "Versão antiga detectada no cache: " .. listStr .. "."
    else
        reason = "Uso anterior do script detectado (configurações salvas)."
    end
    local shown = pcall(function()
        Window:Dialog({
            Title = "Atualização necessária",
            Content = reason .. "\nEsta versão (" .. SCRIPT_VERSION .. ") corrige bugs e substitui funções antigas. A atualização é obrigatória.",
            Icon = "refresh-cw",
            Buttons = {
                {Title = "Atualizar para " .. SCRIPT_VERSION, Variant = "Primary", Callback = function()
                    for _, o in ipairs(olds) do
                        pcall(function() if delfile then delfile(o.file) end end)
                    end
                    markUpdateDone()
                    local newSrc = getSelfSource()
                    if newSrc and sourceIsThisVersion(newSrc) then
                        local chunk, cerr = loadstring(newSrc)
                        if chunk then
                            pcall(function() Window:Destroy() end)
                            pcall(unload)
                            local ok, err = pcall(chunk)
                            if not ok then warn("[yoaredevs] update reload:", err) end
                            return
                        end
                    end
                    pcall(function() WindUI:Notify({Title = "Atualização", Content = "Atualizado para " .. SCRIPT_VERSION .. ".", Duration = 6, Icon = "check"}) end)
                end},
            },
        })
    end)
    if not shown then
        for _, o in ipairs(olds) do
            pcall(function() if delfile then delfile(o.file) end end)
        end
        markUpdateDone()
        pcall(function() WindUI:Notify({Title = "Atualização", Content = "Atualizado para " .. SCRIPT_VERSION .. " (rastros antigos limpos).", Duration = 6, Icon = "check"}) end)
    end
end)

-- TAB HOME
TabHome:Section({Title = T("sec_hub")})
local DEV_THUMB_URL = devThumb
local function addDevThumb(tab, height)
    if not DEV_THUMB_URL then return false end
    return pcall(function() tab:Image({Title = "yoaredevs ("..DEV_ROBLOX_NAME..")", Image = DEV_THUMB_URL, Height = height, Radius = 12}) end)
end
local homeThumbOk = addDevThumb(TabHome, 260)
TabHome:Paragraph({Title = T("dev_owner"), Desc = T("dev_desc", DEV_GITHUB, DEV_ROBLOX_NAME), Image = homeThumbOk and nil or DEV_THUMB_URL})
TabHome:Paragraph({Title = T("about_title"), Desc = T("about_desc", SCRIPT_VERSION)})
TabHome:Paragraph({Title = T("binds_title"), Desc = T("binds_desc")})
TabHome:Section({Title = T("sec_status")})
local statusPara = TabHome:Paragraph({Title = T("session"), Desc = T("loading")})
task.spawn(function()
    while Screen.Parent do
        local n = 0
        for _ in pairs(ESP_Cache) do n += 1 end
        pcall(function()
            statusPara:SetDesc(string.format(T("status_fmt"), n, currentFPS,
                LocalPlayer.Team and LocalPlayer.Team.Name or T("no_team"),
                Settings.AimbotEnabled and "ON" or "OFF",
                Settings.EspEnabled and "ON" or "OFF",
                Settings.FOV,
                currentTarget and currentTarget.DisplayName or T("none")))
        end)
        task.wait(1)
    end
end)

-- TAB AIMBOT
TabAim:Section({Title = T("sec_aimbot")})
TabAim:Toggle({Title = T("aim_toggle"), Desc = T("aim_toggle_desc"), Value = Settings.AimbotEnabled,
    Callback = function(v) playClickSound(); Settings.AimbotEnabled = v; saveSettings() end})
TabAim:Dropdown({Title = T("target_part"), Values = {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LeftLeg", "RightLeg"},
    Value = Settings.TargetPart, Callback = function(v) playClickSound(); Settings.TargetPart = v; saveSettings() end})
TabAim:Slider({Title = T("fov"), Desc = T("fov_desc"), Step = 5,
    Value = {Min = 10, Max = 900, Default = Settings.FOV},
    Callback = function(v) Settings.FOV = v; saveSettings() end})
TabAim:Slider({Title = T("smooth"), Desc = T("smooth_desc"), Step = 0.01,
    Value = {Min = 0, Max = 0.95, Default = Settings.Smoothness},
    Callback = function(v) Settings.Smoothness = v; saveSettings() end})
TabAim:Toggle({Title = T("sticky"), Value = Settings.Sticky,
    Callback = function(v) Settings.Sticky = v; saveSettings() end})

-- RECOIL (movido para Aimbot)
TabAim:Section({Title = T("sec_recoil")})
TabAim:Toggle({Title = T("no_recoil"), Desc = T("no_recoil_desc"), Value = Settings.NoRecoil,
    Callback = function(v) playClickSound(); Settings.NoRecoil = v; saveSettings() end})
TabAim:Slider({Title = "Força do No Recoil", Desc = "Quanto maior, mais do coice é cancelado", Step = 0.1,
    Value = {Min = 0.3, Max = 2, Default = Settings.NoRecoilStrength},
    Callback = function(v) Settings.NoRecoilStrength = v; saveSettings() end})
TabAim:Toggle({Title = T("no_spread"), Desc = T("no_spread_desc"), Value = Settings.NoSpread,
    Callback = function(v) playClickSound(); Settings.NoSpread = v; saveSettings() end})
TabAim:Toggle({Title = T("aim_hold"), Desc = T("aim_hold_desc"), Value = Settings.AimHold,
    Callback = function(v) playClickSound(); Settings.AimHold = v; saveSettings() end})

-- HITBOX
TabAim:Section({Title = T("sec_hitbox")})
TabAim:Toggle({Title = T("hitbox_head"), Desc = T("hitbox_head_desc"), Value = Settings.HitboxHead,
    Callback = function(v)
        playClickSound(); Settings.HitboxHead = v; saveSettings()
        if v then refreshAllHitboxes() else restoreAllHitboxes() end
    end})
TabAim:Slider({Title = T("hitbox_size"), Desc = T("hitbox_size_desc"), Step = 0.5,
    Value = {Min = 1, Max = 12, Default = Settings.HitboxSize},
    Callback = function(v)
        Settings.HitboxSize = v; saveSettings()
        if Settings.HitboxHead then refreshAllHitboxes() end
    end})

-- AUDIO (movido para Aimbot)
TabAim:Section({Title = T("sec_audio")})
TabAim:Toggle({Title = T("kill_sound"), Desc = T("kill_sound_desc"), Value = Settings.KillSound,
    Callback = function(v) playClickSound(); Settings.KillSound = v; saveSettings() end})

TabAim:Section({Title = T("sec_aim_adv")})
TabAim:Dropdown({Title = T("aim_priority"), Desc = T("aim_priority_desc"),
    Values = {T("priority_center"), T("priority_distance")},
    Value = Settings.AimPriority == "Center" and T("priority_center") or T("priority_distance"),
    Callback = function(v)
        playClickSound()
        Settings.AimPriority = (v == T("priority_center")) and "Center" or "Distance"
        saveSettings()
    end})
TabAim:Slider({Title = T("aim_max_dist"), Desc = T("aim_max_dist_desc"), Step = 100,
    Value = {Min = 100, Max = 10000, Default = Settings.AimMaxDistance},
    Callback = function(v) Settings.AimMaxDistance = v; saveSettings() end})

TabAim:Section({Title = T("sec_players")})
TabAim:Input({Title = T("whitelist"), Desc = T("whitelist_desc"), Value = Settings.Whitelist,
    Callback = function(v) Settings.Whitelist = v; saveSettings() end})
TabAim:Input({Title = T("blacklist"), Desc = T("blacklist_desc"), Value = Settings.Blacklist,
    Callback = function(v) Settings.Blacklist = v; saveSettings() end})

TabAim:Section({Title = T("sec_easing")})
TabAim:Dropdown({Title = T("aim_easing"),
    Values = {T("easing_linear"), T("easing_sine"), T("easing_quad")},
    Value = Settings.AimEasing == "Linear" and T("easing_linear") or (Settings.AimEasing == "Sine" and T("easing_sine") or T("easing_quad")),
    Callback = function(v)
        playClickSound()
        if v == T("easing_linear") then Settings.AimEasing = "Linear"
        elseif v == T("easing_sine") then Settings.AimEasing = "Sine"
        else Settings.AimEasing = "Quad" end
        saveSettings()
    end})

-- PREDICAO (fluxo novo): ativar a toggle NAO liga a funcao na hora. O hub
-- detecta se o jogo tem sistema de projetil real (bala com tempo de voo e
-- queda) e abre um popup com o resultado + pergunta "usar prediction?".
-- So' liga se voce confirmar "Sim". A resposta fica salva por jogo
-- (PlaceId): se voce ja confirmou que o jogo tem projetil, a proxima vez a
-- toggle liga direto, sem popup.
TabAim:Section({Title = T("sec_pred")})

local initialPredStatus = "Nenhuma verificação feita neste jogo ainda."
do
    local choice = Settings.ProjectileChoice[tostring(game.PlaceId)]
    if choice == true then initialPredStatus = "Projétil confirmado neste jogo (resposta salva)."
    elseif choice == false then initialPredStatus = "Hitscan confirmado neste jogo (resposta salva)." end
end
local predStatusPara = TabAim:Paragraph({Title = "Detector de projétil", Desc = initialPredStatus})
local predToggle
local predSyncing = false -- evita loop quando o popup liga/desliga a toggle via Set()

local function setPredStatus(txt)
    pcall(function() predStatusPara:SetDesc(txt) end)
end

local function detectAndAskProjectile()
    local placeId = tostring(game.PlaceId)
    setPredStatus("Verificando o jogo...")
    task.spawn(function()
        local okScan, foundPath = pcall(detectProjectileSystem)
        if not okScan then foundPath = nil end
        setPredStatus(foundPath and ("Detectado: " .. foundPath) or "Nenhum sistema de projétil detectado (jogo parece hitscan).")
        local content
        if foundPath then
            content = "Sistema de projétil detectado:\n" .. foundPath .. "\n\nA bala desse jogo tem tempo de voo e queda. A prediction vai ajudar.\n\nAtivar prediction?"
        else
            content = "Nenhum sistema de projétil detectado.\nEsse jogo parece ser hitscan (bala instantanea). A prediction pode DESMIRAR o aimbot.\n\nAtivar mesmo assim?"
        end
        local shown = pcall(function()
            Window:Dialog({
                Title = "Prediction",
                Content = content,
                Icon = "crosshair",
                Buttons = {
                    {Title = "Não", Variant = "Secondary", Callback = function()
                        Settings.Prediction = false
                        Settings.ProjectileChoice[placeId] = false
                        saveSettings()
                        predSyncing = true
                        pcall(function() predToggle:Set(false) end)
                        predSyncing = false
                    end},
                    {Title = "Sim", Variant = "Primary", Callback = function()
                        Settings.Prediction = true
                        Settings.ProjectileChoice[placeId] = true
                        saveSettings()
                        predSyncing = true
                        pcall(function() predToggle:Set(true) end)
                        predSyncing = false
                        pcall(function() WindUI:Notify({Title = "Prediction", Content = "Prediction ativada.", Duration = 3, Icon = "check"}) end)
                    end},
                },
            })
        end)
        if not shown then
            Settings.Prediction = false
            saveSettings()
            predSyncing = true
            pcall(function() predToggle:Set(false) end)
            predSyncing = false
            pcall(function() WindUI:Notify({Title = "Prediction", Content = "Popup indisponivel no seu executor. Tente de novo.", Duration = 5, Icon = "x"}) end)
        end
    end)
end

predToggle = TabAim:Toggle({Title = T("pred_toggle"), Desc = T("pred_toggle_desc"), Value = Settings.Prediction,
    Callback = function(v)
        if predSyncing then return end
        playClickSound()
        if not v then
            Settings.Prediction = false
            saveSettings()
            return
        end
        -- ligando: ja confirmou antes nesse jogo? liga direto. senao, pergunta.
        local placeId = tostring(game.PlaceId)
        if Settings.ProjectileChoice[placeId] == true then
            Settings.Prediction = true
            saveSettings()
            return
        end
        detectAndAskProjectile()
    end})

TabAim:Button({Title = "Verificar novamente", Desc = "Re-detecta o sistema de projétil deste jogo", Callback = function()
    playClickSound()
    detectAndAskProjectile()
end})
TabAim:Slider({Title = T("bullet_speed"), Desc = T("bullet_speed_desc"), Step = 50,
    Value = {Min = 0, Max = 3000, Default = Settings.BulletSpeed},
    Callback = function(v) Settings.BulletSpeed = v; saveSettings() end})
TabAim:Dropdown({Title = T("bullet_gravity"), Desc = T("bullet_gravity_desc"),
    Values = {T("grav_workspace"), T("grav_roblox"), T("grav_zero"), T("grav_custom")},
    Value = Settings.GravityMode == "Workspace" and T("grav_workspace") or (Settings.GravityMode == "Roblox" and T("grav_roblox") or (Settings.GravityMode == "Zero" and T("grav_zero") or T("grav_custom"))),
    Callback = function(v)
        playClickSound()
        if v == T("grav_workspace") then Settings.GravityMode = "Workspace"
        elseif v == T("grav_roblox") then Settings.GravityMode = "Roblox"
        elseif v == T("grav_zero") then Settings.GravityMode = "Zero"
        else Settings.GravityMode = "Custom" end
        saveSettings()
    end})
TabAim:Slider({Title = T("custom_gravity"), Desc = T("custom_gravity_desc"), Step = 1,
    Value = {Min = 0, Max = 500, Default = Settings.CustomGravity},
    Callback = function(v) Settings.CustomGravity = v; saveSettings() end})
TabAim:Slider({Title = T("vel_strength"), Desc = T("vel_strength_desc"), Step = 0.05,
    Value = {Min = 0, Max = 2, Default = Settings.VelocityStrength},
    Callback = function(v) Settings.VelocityStrength = v; saveSettings() end})

TabAim:Section({Title = T("sec_checks")})
TabAim:Toggle({Title = T("team_check"), Desc = T("team_check_desc"), Value = Settings.TeamCheck,
    Callback = function(v) playClickSound(); Settings.TeamCheck = v; saveSettings() end})
TabAim:Toggle({Title = T("wall_check"), Desc = T("wall_check_desc"), Value = Settings.WallCheck,
    Callback = function(v) playClickSound(); Settings.WallCheck = v; saveSettings() end})

TabAim:Section({Title = T("sec_fov_circle")})
TabAim:Toggle({Title = T("circle_fov"), Value = Settings.ShowFOV,
    Callback = function(v) playClickSound(); Settings.ShowFOV = v; saveSettings() end})
TabAim:Colorpicker({Title = T("circle_color"), Default = Settings.Colors.FOV,
    Callback = function(c) Settings.Colors.FOV = c; saveSettings() end})

-- TAB ESP
TabESP:Section({Title = T("sec_esp")})
TabESP:Toggle({Title = T("esp_toggle"), Value = Settings.EspEnabled,
    Callback = function(v)
        playClickSound(); Settings.EspEnabled = v
        if not v then hideAllEsp() end
        saveSettings()
    end})
TabESP:Toggle({Title = T("esp_box"), Value = Settings.EspBox,
    Callback = function(v) Settings.EspBox = v; saveSettings() end})
TabESP:Toggle({Title = T("esp_tracer"), Value = Settings.EspTracer,
    Callback = function(v) Settings.EspTracer = v; saveSettings() end})
TabESP:Dropdown({Title = T("tracer_origin"), Values = {"Bottom", "Center", "Top", "Mouse"},
    Value = Settings.TracerOrigin,
    Callback = function(v) Settings.TracerOrigin = v; saveSettings() end})
TabESP:Toggle({Title = T("esp_name"), Value = Settings.EspName,
    Callback = function(v) Settings.EspName = v; saveSettings() end})
TabESP:Toggle({Title = T("esp_distance"), Value = Settings.EspDistance,
    Callback = function(v) Settings.EspDistance = v; saveSettings() end})
TabESP:Toggle({Title = T("esp_health"), Value = Settings.EspHealth,
    Callback = function(v) Settings.EspHealth = v; saveSettings() end})
TabESP:Toggle({Title = T("esp_team_check"), Desc = T("esp_team_check_desc"), Value = Settings.EspTeamCheck,
    Callback = function(v) playClickSound(); Settings.EspTeamCheck = v; saveSettings() end})
TabESP:Slider({Title = T("thickness"), Step = 1,
    Value = {Min = 1, Max = 5, Default = Settings.EspThickness},
    Callback = function(v) Settings.EspThickness = v; saveSettings() end})
TabESP:Slider({Title = T("max_distance"), Step = 50,
    Value = {Min = 100, Max = 5000, Default = Settings.MaxDistance},
    Callback = function(v) Settings.MaxDistance = v; saveSettings() end})
TabESP:Slider({Title = T("esp_fps"), Desc = T("esp_fps_desc"), Step = 10,
    Value = {Min = 20, Max = 240, Default = Settings.EspFpsCap},
    Callback = function(v) Settings.EspFpsCap = v; saveSettings() end})

TabESP:Section({Title = T("sec_colors")})
TabESP:Colorpicker({Title = T("box_color"), Default = Settings.Colors.Box,
    Callback = function(c) Settings.Colors.Box = c; saveSettings() end})
TabESP:Colorpicker({Title = T("tracer_color"), Default = Settings.Colors.Tracer,
    Callback = function(c) Settings.Colors.Tracer = c; saveSettings() end})
TabESP:Colorpicker({Title = T("team_color"), Default = Settings.Colors.Team,
    Callback = function(c) Settings.Colors.Team = c; saveSettings() end})
TabESP:Colorpicker({Title = T("text_color"), Default = Settings.Colors.Text,
    Callback = function(c) Settings.Colors.Text = c; saveSettings() end})
TabESP:Button({Title = T("rebuild_esp"), Callback = function()
    for p in pairs(ESP_Cache) do RemoveEsp(p) end
    for _, p in ipairs(Players:GetPlayers()) do CreateEsp(p) end
    WindUI:Notify({Title = T("sec_esp"), Content = T("rebuild_esp_done"), Duration = 3, Icon = "refresh-cw"})
end})

TabESP:Section({Title = T("sec_item_esp")})
TabESP:Toggle({Title = T("item_esp_toggle"), Value = Settings.ItemESP,
    Callback = function(v)
        playClickSound(); Settings.ItemESP = v
        if not v then for _, o in pairs(ItemESP_Cache) do pcall(function() o:Destroy() end) end; ItemESP_Cache = {} end
        saveSettings()
    end})
TabESP:Input({Title = T("item_esp_names"), Desc = T("item_esp_names_desc"), Value = Settings.ItemNames,
    Callback = function(v) Settings.ItemNames = v; saveSettings() end})
TabESP:Colorpicker({Title = T("item_esp_color"), Default = Settings.ItemESPColor,
    Callback = function(c) Settings.ItemESPColor = c; saveSettings() end})

-- TAB MISC
TabMisc:Section({Title = T("sec_dev")})
local miscThumbOk = addDevThumb(TabMisc, 260)
TabMisc:Paragraph({Title = "yoaredevs", Desc = T("dev_para_desc", DEV_GITHUB, DEV_ROBLOX_NAME), Image = miscThumbOk and nil or DEV_THUMB_URL})
TabMisc:Button({Title = T("copy_github"), Callback = function()
    setclip(DEV_GITHUB)
    WindUI:Notify({Title = T("copied"), Content = DEV_GITHUB, Duration = 4, Icon = "clipboard"})
end})

TabMisc:Section({Title = T("sec_server")})
TabMisc:Button({Title = T("rejoin"), Callback = function()
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end})
TabMisc:Button({Title = T("server_hop"), Callback = function()
    task.spawn(function()
        local ok, res = pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if not ok or not res or not res.data then
            WindUI:Notify({Title = T("server_hop"), Content = T("hop_fail"), Duration = 4, Icon = "x"})
            return
        end
        for _, s in ipairs(res.data) do
            if type(s.id) == "string" and s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                return
            end
        end
        WindUI:Notify({Title = T("server_hop"), Content = T("hop_none"), Duration = 4, Icon = "x"})
    end)
end})
TabMisc:Button({Title = T("copy_jobid"), Callback = function()
    setclip(game.JobId)
    WindUI:Notify({Title = T("tab_misc"), Content = T("jobid_copied"), Duration = 3, Icon = "clipboard"})
end})

-- PRESETS
TabMisc:Section({Title = T("sec_presets")})
local presetList = listPresets()
local presetDropdown = nil
local function refreshPresets()
    presetList = listPresets()
    if #presetList == 0 then table.insert(presetList, T("preset_none")) end
    return presetList
end
refreshPresets()

local presetInput = ""
TabMisc:Input({Title = T("preset_name"), Value = "",
    Callback = function(v) presetInput = v end})
TabMisc:Button({Title = T("preset_save"), Callback = function()
    if presetInput and #presetInput > 0 then
        savePreset(presetInput)
        playClickSound()
        WindUI:Notify({Title = T("sec_presets"), Content = T("preset_saved"), Duration = 3, Icon = "save"})
        refreshPresets()
    end
end})

presetDropdown = TabMisc:Dropdown({Title = T("preset_load"), Values = presetList, Value = presetList[1] or T("preset_none"),
    Callback = function(v)
        if v == T("preset_none") then return end
        playClickSound()
        loadPreset(v)
        WindUI:Notify({Title = T("sec_presets"), Content = T("preset_loaded"), Duration = 3, Icon = "download"})
    end})

TabMisc:Button({Title = T("preset_delete"), Callback = function()
    local selected = presetDropdown and presetDropdown.Value
    if selected and selected ~= T("preset_none") then
        deletePreset(selected)
        playClickSound()
        WindUI:Notify({Title = T("sec_presets"), Content = T("preset_deleted"), Duration = 3, Icon = "trash"})
        refreshPresets()
    end
end})

TabMisc:Section({Title = T("sec_lang")})
local langPara = TabMisc:Paragraph({Title = T("lang_dd"), Desc = T("lang_current", langName(LANG))})

local function reloadInLang(key, source)
    saveLang(key, source or "manual")
    pcall(function() WindUI:Notify({Title = T("sec_lang"), Content = T("lang_reloading"), Duration = 3, Icon = "refresh-cw"}) end)
    task.spawn(function()
        task.wait(0.4)
        local src = getSelfSource()
        if not src then
            pcall(function() WindUI:Notify({Title = T("sec_lang"), Content = T("lang_reload_manual"), Duration = 8, Icon = "info"}) end)
            pcall(function() langPara:SetDesc(T("lang_current", langName(key))) end)
            return
        end
        local chunk, cerr = loadstring(src)
        if not chunk then
            warn("[yoaredevs] reload compile:", cerr)
            pcall(function() WindUI:Notify({Title = T("sec_lang"), Content = T("lang_reload_manual"), Duration = 8, Icon = "info"}) end)
            return
        end
        pcall(function() Window:Destroy() end)
        pcall(unload)
        local ok, err = pcall(chunk)
        if not ok then
            warn("[yoaredevs] reload:", err)
            pcall(function() WindUI:Notify({Title = T("sec_lang"), Content = T("lang_reload_fail"), Duration = 6, Icon = "x"}) end)
        end
    end)
end

local function askLangChange(key)
    if key == LANG then return end
    local label = langName(key)
    local shown = pcall(function()
        Window:Dialog({
            Title = T("lang_dialog_title"),
            Content = T("lang_dialog_content", label),
            Icon = "languages",
            Buttons = {
                {Title = T("cancel"), Variant = "Secondary", Callback = function() pcall(function() langPara:SetDesc(T("lang_current", langName(LANG))) end) end},
                {Title = T("confirm"), Variant = "Primary", Callback = function() reloadInLang(key) end},
            },
        })
    end)
    if not shown then reloadInLang(key) end
end

TabMisc:Dropdown({Title = T("lang_dd"), Desc = T("lang_dd_desc"), Values = LANG_LABELS, Value = langName(LANG),
    Callback = function(v)
        playClickSound()
        local key = LABEL_TO_KEY[v]
        if key then askLangChange(key) end
    end})

TabMisc:Section({Title = T("sec_bg")})
local function applyBg()
    pcall(function() Window:SetBackgroundImageTransparency(bgOn and THEME_IMAGE_ALPHA or 1) end)
    pcall(setHubNameColor, bgOn and THEME_NAME_COLOR or DEFAULT_NAME_COLOR)
    if bgOn then setupGradient(); startGradientAnimation() else removeGradient(); stopGradientAnimation() end
end

task.spawn(function()
    for _ = 1, 20 do
        if setHubNameColor(bgOn and THEME_NAME_COLOR or DEFAULT_NAME_COLOR) then break end
        task.wait(0.1)
    end
end)

local THEME_LABELS = {T("theme_default"), T("theme_image")}
TabMisc:Dropdown({Title = T("theme_dd"), Desc = T("theme_dd_desc"), Values = THEME_LABELS, Value = T("theme_image"),
    Callback = function(v)
        playClickSound()
        bgOn = (v == T("theme_image"))
        applyBg()
    end})

TabMisc:Section({Title = T("sec_stream")})
TabMisc:Toggle({Title = T("stream_safe"), Desc = T("stream_safe_desc"), Value = Settings.StreamSafe,
    Callback = function(v) playClickSound(); Settings.StreamSafe = v; saveSettings(); applyStreamSafe() end})

TabMisc:Section({Title = T("sec_script")})
TabMisc:Toggle({Title = T("click_sound"), Value = Settings.ClickSound,
    Callback = function(v) Settings.ClickSound = v; saveSettings() end})
TabMisc:Button({Title = T("unload_script"), Callback = function()
    unload()
    pcall(function() Window:Destroy() end)
end})

-- KEYBINDS
bind(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Settings.EspEnabled = not Settings.EspEnabled
        if not Settings.EspEnabled then hideAllEsp() end
        WindUI:Notify({Title = "ESP", Content = Settings.EspEnabled and "ON" or "OFF", Duration = 2, Icon = "eye"})
        saveSettings()
    elseif input.KeyCode == Enum.KeyCode.RightAlt then
        Settings.AimbotEnabled = not Settings.AimbotEnabled
        WindUI:Notify({Title = "Aimbot", Content = Settings.AimbotEnabled and "ON" or "OFF", Duration = 2, Icon = "crosshair"})
        saveSettings()
    end
end))

-- LOADED NOTIFICATION
WindUI:Notify({Title = T("loaded_title"), Content = T("loaded_desc"), Duration = 6, Icon = "check"})
applyStreamSafe()

-- GEO DIALOG
local function showGeoDialog(geoLang)
    local content
    if GEO_COUNTRY then
        local countryLabel = COUNTRY_NAME[GEO_COUNTRY]
        if not countryLabel then countryLabel = string.format("%s (%s)", GEO_COUNTRY, T("geo_country_unknown")) end
        content = T("geo_ok", countryLabel, GEO_COUNTRY, langName(geoLang))
    else
        local reason = (GEO_FAIL == "nohttp") and T("geo_reason_nohttp") or T("geo_reason_offline")
        content = T("geo_fail", reason, langName(LANG))
    end
    local buttons = {}
    if geoLang and geoLang ~= LANG then
        table.insert(buttons, {Title = STRINGS[geoLang].flag .. " " .. STRINGS[geoLang].label, Variant = "Primary", Callback = function() reloadInLang(geoLang, "geo") end})
        table.insert(buttons, {Title = T("geo_keep"), Variant = "Secondary", Callback = function() saveLang(LANG, "geo"); pcall(function() langPara:SetDesc(T("lang_current", langName(LANG))) end) end})
    else
        table.insert(buttons, {Title = T("geo_keep"), Variant = "Primary", Callback = function() saveLang(LANG, "geo"); pcall(function() langPara:SetDesc(T("lang_current", langName(LANG))) end) end})
        for _, key in ipairs(LANG_ORDER) do
            if key ~= LANG then
                table.insert(buttons, {Title = STRINGS[key].flag .. " " .. STRINGS[key].label, Variant = "Secondary", Callback = function() reloadInLang(key) end})
            end
        end
    end
    local shown = pcall(function()
        Window:Dialog({Title = T("geo_title"), Content = content, Icon = "languages", Buttons = buttons})
    end)
    if not shown then
        saveLang(LANG, "geo")
        pcall(function() WindUI:Notify({Title = T("geo_title"), Content = content, Duration = 8, Icon = "languages"}) end)
    end
end

pcall(Loader.done)

-- Deteccao background
pcall(function()
    if LANG_SOURCE == "manual" then return end
    local cc, why, method = detectCountry()
    GEO_COUNTRY, GEO_FAIL, GEO_METHOD = cc, why, method
    warn(string.format("[yoaredevs] deteccao: pais=%s | metodo=%s | idioma_boot=%s | origem_boot=%s | idioma_detectado=%s | falha=%s",
        tostring(cc), tostring(method), tostring(LANG), tostring(LANG_SOURCE), tostring(cc and (COUNTRY_LANG[cc] or "en")), tostring(why)))
    local geoLang = cc and (COUNTRY_LANG[cc] or "en") or nil
    local firstTime = (savedSource ~= "geo" and savedSource ~= "manual")
    if geoLang and geoLang == LANG and not firstTime then
        saveLang(LANG, "geo")
        pcall(function() WindUI:Notify({Title = T("geo_title"), Content = string.format("%s (%s)", langName(LANG), tostring(cc)), Duration = 4, Icon = "languages"}) end)
    else
        pcall(showGeoDialog, geoLang)
    end
end)
