-- ═══════════════════════════════════════════════════════════
-- MM2 HUB — Part 1/3
-- Visual + Info only. No auto-kill, no silent aim.
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════
-- СОСТОЯНИЕ
-- ═══════════════════════════════════════════════════════════
local state = {
    espEnabled = false,
    roleESP = false,
    tracerEnabled = false,
    fovCircle = false,
    fullbright = false,
    autoCamMurderer = false,
    autoCamSheriff = false,
    highlightGun = false,
    highlightKnife = false,
    showDistances = false,
    nameTags = false,
    boxESP = false,
    coinESP = false,
    gunESP = false,
    showFPS = false,
    showPing = false,
    showRoundTime = false,
    showPlayerList = false,
    cameraFOV = 70,
    espColorMurderer = Color3.fromRGB(255, 0, 0),
    espColorSheriff = Color3.fromRGB(0, 100, 255),
    espColorInnocent = Color3.fromRGB(0, 255, 0),
}

-- ═══════════════════════════════════════════════════════════
-- ХЕЛПЕРЫ
-- ═══════════════════════════════════════════════════════════
local function char()
    return LP.Character
end

local function root()
    local c = char()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function notify(t, txt, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = t, Text = txt, Duration = dur or 2
        })
    end)
end

local function getRole(player)
    -- Определяем роль по инструментам в Backpack и Character
    if not player or not player.Character then return "Unknown" end
    local bp = player:FindFirstChild("Backpack")
    local ch = player.Character
    
    local function hasTool(name)
        if bp and bp:FindFirstChild(name) then return true end
        if ch and ch:FindFirstChild(name) then return true end
        return false
    end
    
    if hasTool("Knife") then return "Murderer" end
    if hasTool("Gun") or hasTool("Revolver") then return "Sheriff" end
    return "Innocent"
end

local function getRoleColor(role)
    if role == "Murderer" then return state.espColorMurderer end
    if role == "Sheriff" then return state.espColorSheriff end
    return state.espColorInnocent
end-- ═══════════════════════════════════════════════════════════
-- MM2 HUB — Part 2/3
-- Функции ESP и подсветки
-- ═══════════════════════════════════════════════════════════

-- ═════ 1. ROLE ESP (роли над головами) ═════
local roleTags = {}

local function clearRoleTags()
    for _, tag in pairs(roleTags) do
        if tag and tag.Parent then tag:Destroy() end
    end
    roleTags = {}
end

local function updateRoleESP()
    if not state.roleESP then
        clearRoleTags()
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            local role = getRole(p)
            local color = getRoleColor(role)
            
            if not roleTags[p] or not roleTags[p].Parent then
                local bb = Instance.new("BillboardGui")
                bb.Name = "RoleTag"
                bb.Size = UDim2.new(0, 200, 0, 40)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.AlwaysOnTop = true
                bb.Parent = p.Character.Head
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = color
                label.TextStrokeTransparency = 0
                label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                label.TextScaled = true
                label.Font = Enum.Font.GothamBold
                label.Parent = bb
                
                roleTags[p] = bb
            end
            
            local label = roleTags[p]:FindFirstChildOfClass("TextLabel")
            if label then
                label.Text = role:upper() .. " | " .. p.Name
                label.TextColor3 = color
            end
        end
    end
end

-- ═════ 2. PLAYER HIGHLIGHT (подсветка) ═════
local highlights = {}

local function clearHighlights()
    for _, h in pairs(highlights) do
        if h and h.Parent then h:Destroy() end
    end
    highlights = {}
end

local function updateHighlight()
    if not state.espEnabled then
        clearHighlights()
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local role = getRole(p)
            local color = getRoleColor(role)
            
            if not highlights[p] or not highlights[p].Parent then
                local h = Instance.new("Highlight")
                h.Name = "MM2HL"
                h.FillColor = color
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = p.Character
                highlights[p] = h
            end
            
            if highlights[p] then
                highlights[p].FillColor = color
            end
        end
    end
end

-- ═════ 3. TRACER (линии к игрокам) ═════
local tracers = {}

local function updateTracers()
    for _, t in pairs(tracers) do
        if t and t.Parent then t:Destroy() end
    end
    tracers = {}
    
    if not state.tracerEnabled then return end
    local myRoot = root()
    if not myRoot then return end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local role = getRole(p)
            local color = getRoleColor(role)
            
            local line = Instance.new("LineHandleAdornment")
            line.Name = "Tracer"
            line.Adornee = myRoot
            line.Thickness = 2
            line.Color3 = color
            line.AlwaysOnTop = true
            line.ZIndex = 999
            line.Length = (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
            line.CFrame = CFrame.lookAt(myRoot.Position, p.Character.HumanoidRootPart.Position)
            line.Parent = myRoot
            
            tracers[p] = line
        end
    end
end

-- ═════ 4. NAME + DISTANCE ═════
local nameTags = {}

local function clearNameTags()
    for _, n in pairs(nameTags) do
        if n and n.Parent then n:Destroy() end
    end
    nameTags = {}
end

local function updateNameTags()
    if not state.nameTags and not state.showDistances then
        clearNameTags()
        return
    end
    
    local myRoot = root()
    if not myRoot then return end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            local role = getRole(p)
            local color = getRoleColor(role)
            local dist = (p.Character.Head.Position - myRoot.Position).Magnitude
            
            if not nameTags[p] or not nameTags[p].Parent then
                local bb = Instance.new("BillboardGui")
                bb.Name = "NameTag"
                bb.Size = UDim2.new(0, 180, 0, 25)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true
                bb.Parent = p.Character.Head
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = color
                label.TextStrokeTransparency = 0
                label.TextScaled = true
                label.Font = Enum.Font.Gotham
                label.Parent = bb
                
                nameTags[p] = bb
            end
            
            local label = nameTags[p]:FindFirstChildOfClass("TextLabel")
            if label then
                local txt = p.Name
                if state.showDistances then
                    txt = txt .. " [" .. math.floor(dist) .. "m]"
                end
                label.Text = txt
            end
        end
    end
end

-- ═════ 5. FOV CIRCLE ═════
local fovCircleGui = nil
local function updateFovCircle()
    if fovCircleGui then fovCircleGui:Destroy() fovCircleGui = nil end
    if not state.fovCircle then return end
    
    local g = Instance.new("ScreenGui")
    g.Name = "FovCircle"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.Parent = PG
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 400, 0, 400)
    circle.Position = UDim2.new(0.5, -200, 0.5, -200)
    circle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.Parent = g
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 0, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = circle
    
    fovCircleGui = g
end

-- ═════ 6. COIN ESP ═════
local coinHighlights = {}
local function updateCoinESP()
    for _, h in pairs(coinHighlights) do
        if h and h.Parent then h:Destroy() end
    end
    coinHighlights = {}
    
    if not state.coinESP then return end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("coin") and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local h = Instance.new("Highlight")
                h.FillColor = Color3.fromRGB(255, 215, 0)
                h.OutlineColor = Color3.fromRGB(255, 255, 0)
                h.FillTransparency = 0.4
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = obj
                coinHighlights[obj] = h
            end
        end
    end
end

-- ═════ 7. GUN ESP ═════
local gunHighlights = {}
local function updateGunESP()
    for _, h in pairs(gunHighlights) do
        if h and h.Parent then h:Destroy() end
    end
    gunHighlights = {}
    
    if not state.gunESP then return end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (n == "gun" or n == "revolver") and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local h = Instance.new("Highlight")
            h.FillColor = Color3.fromRGB(0, 150, 255)
            h.OutlineColor = Color3.fromRGB(255, 255, 255)
            h.FillTransparency = 0.3
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = obj
            gunHighlights[obj] = h
        end
    end
end-- ═══════════════════════════════════════════════════════════
-- MM2 HUB — Part 3/3
-- Авто-камера, HUD, GUI
-- ═══════════════════════════════════════════════════════════

-- ═════ 8. AUTO CAMERA (наведение камеры) ═════
local function autoCameraLoop()
    while state.autoCamMurderer or state.autoCamSheriff do
        local target = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local role = getRole(p)
                if state.autoCamMurderer and role == "Murderer" then
                    target = p.Character.HumanoidRootPart
                    break
                end
                if state.autoCamSheriff and role == "Sheriff" then
                    target = p.Character.HumanoidRootPart
                    break
                end
            end
        end
        
        if target and Camera then
            -- Плавное наведение камеры
            local lookAt = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(lookAt, 0.1)
        end
        
        task.wait(0.03)
    end
end

-- ═════ 9. HUD ═════
local hudGui = nil
local hudLabels = {}

local function makeHUD()
    if hudGui then hudGui:Destroy() end
    local g = Instance.new("ScreenGui")
    g.Name = "MM2HUD"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.Parent = PG
    hudGui = g
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 120)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = g
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(255, 0, 0)
    stroke.Thickness = 2
    
    local function makeLine(text, y)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -10, 0, 20)
        l.Position = UDim2.new(0, 5, 0, y)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.fromRGB(255, 255, 255)
        l.TextSize = 12
        l.Font = Enum.Font.Code
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = frame
        return l
    end
    
    hudLabels.fps = makeLine("FPS: --", 5)
    hudLabels.ping = makeLine("Ping: --", 25)
    hudLabels.round = makeLine("Round: --", 45)
    hudLabels.role = makeLine("My Role: --", 65)
    hudLabels.players = makeLine("Players: --", 85)
end

local function updateHUD()
    if not hudGui then return end
    if state.showFPS and hudLabels.fps then
        hudLabels.fps.Text = "FPS: " .. math.floor(workspace:GetRealPhysicsFPS())
    else
        if hudLabels.fps then hudLabels.fps.Text = "" end
    end
    if state.showPing and hudLabels.ping then
        local ping = 0
        pcall(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        hudLabels.ping.Text = "Ping: " .. ping
    end
    if state.showRoundTime and hudLabels.round then
        local timer = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("timer") and obj:IsA("TextLabel") then
                timer = obj.Text
                break
            end
        end
        hudLabels.round.Text = "Round: " .. tostring(timer)
    end
    if hudLabels.role then
        hudLabels.role.Text = "My Role: " .. getRole(LP)
    end
    if hudLabels.players then
        hudLabels.players.Text = "Players: " .. #Players:GetPlayers()
    end
end

-- ═════ 10. FULLBRIGHT ═════
local function toggleFullbright()
    state.fullbright = not state.fullbright
    if state.fullbright then
        pcall(function()
            Lighting.Brightness = 3
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        end)
    else
        pcall(function()
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        end)
    end
end

-- ═════ LOOP ОБНОВЛЕНИЙ ═════
RunService.RenderStepped:Connect(function()
    pcall(updateRoleESP)
    pcall(updateHighlight)
    pcall(updateNameTags)
    pcall(updateTracers)
    pcall(updateHUD)
end)

task.spawn(function()
    while true do
        pcall(updateCoinESP)
        pcall(updateGunESP)
        task.wait(1)
    end
end)

task.spawn(autoCameraLoop)

-- ═════ GUI ═════
local old = PG:FindFirstChild("MM2Hub")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "MM2Hub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PG

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 320, 0, 520)
panel.Position = UDim2.new(0.5, -160, 0.5, -260)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
titleBar.BorderSizePixel = 0
titleBar.Parent = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 20)
titleFix.Position = UDim2.new(0, 0, 1, -20)
titleFix.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🔪 MM2 HUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeX = Instance.new("TextButton")
closeX.Size = UDim2.new(0, 30, 0, 30)
closeX.Position = UDim2.new(1, -38, 0, 10)
closeX.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeX.Text = "✖"
closeX.TextColor3 = Color3.fromRGB(255, 255, 255)
closeX.TextSize = 14
closeX.Font = Enum.Font.GothamBold
closeX.BorderSizePixel = 0
closeX.Parent = titleBar
Instance.new("UICorner", closeX).CornerRadius = UDim.new(0, 8)
closeX.MouseButton1Click:Connect(function() panel.Visible = false end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -60)
scroll.Position = UDim2.new(0, 5, 0, 55)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
scroll.CanvasSize = UDim2.new(0, 0, 0, 1600)
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local function makeBtn(text, col, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 36)
    b.BackgroundColor3 = col
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = scroll
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(function() callback(b) end)
    return b
end

-- 1. Role ESP
makeBtn("🎭 1. ROLE ESP: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    state.roleESP = not state.roleESP
    b.Text = state.roleESP and "🎭 1. ROLE ESP: ВКЛ" or "🎭 1. ROLE ESP: ВЫКЛ"
    b.BackgroundColor3 = state.roleESP and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(60, 60, 90)
end)

-- 2. Player ESP
makeBtn("👁️ 2. PLAYER ESP: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    state.espEnabled = not state.espEnabled
    b.Text = state.espEnabled and "👁️ 2. PLAYER ESP: ВКЛ" or "👁️ 2. PLAYER ESP: ВЫКЛ"
    b.BackgroundColor3 = state.espEnabled and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(60, 60, 90)
end)

-- 3. Tracers
makeBtn("📏 3. TRACERS: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    state.tracerEnabled = not state.tracerEnabled
    b.Text = state.tracerEnabled and "📏 3. TRACERS: ВКЛ" or "📏 3. TRACERS: ВЫКЛ"
    b.BackgroundColor3 = state.tracerEnabled and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(60, 60, 90)
end)

-- 4. Name tags
makeBtn("📛 4. NAME TAGS: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    state.nameTags = not state.nameTags
    b.Text = state.nameTags and "📛 4. NAME TAGS: ВКЛ" or "📛 4. NAME TAGS: ВЫКЛ"
    b.BackgroundColor3 = state.nameTags and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(60, 60, 90)
end)

-- 5. Distances
makeBtn("📐 5. DISTANCES: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    state.showDistances = not state.showDistances
    b.Text = state.showDistances and "📐 5. DISTANCES: ВКЛ" or "📐 5. DISTANCES: ВЫКЛ"
    b.BackgroundColor3 = state.showDistances and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(60, 60, 90)
end)

-- 6. FOV Circle
makeBtn("🎯 6. FOV CIRCLE: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    state.fovCircle = not state.fovCircle
    updateFovCircle()
    b.Text = state.fovCircle and "🎯 6. FOV CIRCLE: ВКЛ" or "🎯 6. FOV CIRCLE: ВЫКЛ"
    b.BackgroundColor3 = state.fovCircle and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(60, 60, 90)
end)

-- 7. Coin ESP
makeBtn("🪙 7. COIN ESP: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    state.coinESP = not state.coinESP
    b.Text = state.coinESP and "🪙 7. COIN ESP: ВКЛ" or "🪙 7. COIN ESP: ВЫКЛ"
    b.BackgroundColor3 = state.coinESP and Color3.fromRGB(150, 100, 0) or Color3.fromRGB(60, 60, 90)
end)

-- 8. Gun ESP
makeBtn("🔫 8. GUN ESP: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    state.gunESP = not state.gunESP
    b.Text = state.gunESP and "🔫 8. GUN ESP: ВКЛ" or "🔫 8. GUN ESP: ВЫКЛ"
    b.BackgroundColor3 = state.gunESP and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(60, 60, 90)
end)

-- 9. Auto Cam Murderer
makeBtn("🎥 9. AUTO CAM MURDERER: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    state.autoCamMurderer = not state.autoCamMurderer
    b.Text = state.autoCamMurderer and "🎥 9. AUTO CAM MURDERER: ВКЛ" or "🎥 9. AUTO CAM MURDERER: ВЫКЛ"
    b.BackgroundColor3 = state.autoCamMurderer and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(60, 60, 90)
end)

-- 10. Auto Cam Sheriff
makeBtn("🎥 10. AUTO CAM SHERIFF: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    state.autoCamSheriff = not state.autoCamSheriff
    b.Text = state.autoCamSheriff and "🎥 10. AUTO CAM SHERIFF: ВКЛ" or "🎥 10. AUTO CAM SHERIFF: ВЫКЛ"
    b.BackgroundColor3 = state.autoCamSheriff and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(60, 60, 90)
end)

-- 11. Fullbright
makeBtn("💡 11. FULLBRIGHT: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    toggleFullbright()
    b.Text = state.fullbright and "💡 11. FULLBRIGHT: ВКЛ" or "💡 11. FULLBRIGHT: ВЫКЛ"
    b.BackgroundColor3 = state.fullbright and Color3.fromRGB(200, 150, 0) or Color3.fromRGB(60, 60, 90)
end)

-- 12. HUD
makeBtn("📺 12. HUD: ВЫКЛ", Color3.fromRGB(60, 60, 90), function(b)
    state.showFPS = not state.showFPS
    state.showPing = state.showFPS
    state.showRoundTime = state.showFPS
    if state.showFPS then makeHUD() else if hudGui then hudGui:Destroy() hudGui = nil end end
    b.Text = state.showFPS and "📺 12. HUD: ВКЛ" or "📺 12. HUD: ВЫКЛ"
    b.BackgroundColor3 = state.showFPS and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(60, 60, 90)
end)

-- 13. Показать роли в чате
makeBtn("💬 13. ПОКАЗАТЬ РОЛИ В КОНСОЛИ", Color3.fromRGB(80, 80, 140), function()
    print("=== РОЛИ ИГРОКОВ ===")
    for _, p in ipairs(Players:GetPlayers()) do
        print(p.Name .. " -> " .. getRole(p))
    end
end)

-- 14. Показать мою роль
makeBtn("🎭 14. МОЯ РОЛЬ", Color3.fromRGB(80, 80, 140), function()
    print("Ты: " .. getRole(LP))
    notify("Твоя роль", getRole(LP))
end)

-- 15. Инфо о карте
makeBtn("🗺️ 15. ИНФО О СЕРВЕРЕ", Color3.fromRGB(80, 80, 140), function()
    print("Сервер: " .. game.JobId)
    print("Место: " .. game.PlaceId)
    print("Игроков: " .. #Players:GetPlayers())
end)

-- 16. Reset highlights
makeBtn("♻️ 16. СБРОСИТЬ ПОДСВЕТКУ", Color3.fromRGB(150, 50, 50), function()
    clearRoleTags()
    clearHighlights()
    clearNameTags()
    print("Подсветка сброшена")
end)

-- 17. Test роли
makeBtn("🔍 17. ПРОСКАНИРОВАТЬ РОЛИ", Color3.fromRGB(80, 80, 140), function()
    local m, s, i = 0, 0, 0
    for _, p in ipairs(Players:GetPlayers()) do
        local r = getRole(p)
        if r == "Murderer" then m = m + 1
        elseif r == "Sheriff" then s = s + 1
        else i = i + 1 end
    end
    notify("Роли", "🔪 " .. m .. "  🔫 " .. s .. "  😇 " .. i)
end)

-- 18. Cleanup
makeBtn("🧹 18. ОЧИСТИТЬ ВСЁ", Color3.fromRGB(150, 50, 50), function()
    clearRoleTags()
    clearHighlights()
    clearNameTags()
    for _, t in pairs(tracers) do if t and t.Parent then t:Destroy() end end
    for _, c in pairs(coinHighlights) do if c and c.Parent then c:Destroy() end end
    for _, g in pairs(gunHighlights) do if g and g.Parent then g:Destroy() end end
    if fovCircleGui then fovCircleGui:Destroy() end
    if hudGui then hudGui:Destroy() end
end)

notify("🔪 MM2 HUB", "Загружено. 18 функций.")
print("[MM2Hub] Загружено.")
