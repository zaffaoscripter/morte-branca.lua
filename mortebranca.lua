-- ==================== Services ====================
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ==================== Config ====================
local AimbotFOV         = 180
local MaxAimbotDistance = 500
local NpcScanRadius     = 250
local AimbotKey         = Enum.UserInputType.MouseButton2
local AimSpeed          = 55.0
local AimPart           = "Head"

local AimbotEnabled = true
local AimNPCEnabled = true
local AimNPCStrong  = true   -- sempre ativo
local ESPEnabled    = true
local ESPNPCEnabled = true   -- novo: ESP de NPCs separado

-- ==================== Player lookup ====================
local playerChars = {}

local function rebuildPlayerChars()
    playerChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = p end
    end
end
rebuildPlayerChars()

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        playerChars[c] = p
    end)
    p.CharacterRemoving:Connect(function(c)
        playerChars[c] = nil
    end)
end)
Players.PlayerRemoving:Connect(function(p)
    if p.Character then playerChars[p.Character] = nil end
end)

local function isPlayerChar(model)
    return playerChars[model] ~= nil
end

local function isNPCModel(model)
    if model == LocalPlayer.Character then return false end
    if isPlayerChar(model) then return false end
    local hum  = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    return hum ~= nil and root ~= nil
end

-- ==================== ESP via Drawing ====================
local PLAYER_COLOR = Color3.fromRGB(170, 80, 255)
local NPC_COLOR    = Color3.fromRGB(255, 50, 50)
local espObjects   = {}   -- [character] = { label }

local hasDrawing = (typeof(Drawing) == "table") or (Drawing ~= nil)

local function newLabel(color)
    if not hasDrawing then return nil end
    local t = Drawing.new("Text")
    t.Size         = 13
    t.Center       = true
    t.Outline      = true
    t.Font         = 1
    t.Color        = color
    t.OutlineColor = Color3.fromRGB(0, 0, 0)
    t.Visible      = false
    return t
end

local function createESP(character, color)
    if espObjects[character] then return end
    local label = newLabel(color)
    espObjects[character] = { lines = {}, label = label, color = color }
end

local function removeESP(character)
    local obj = espObjects[character]
    if not obj then return end
    if obj.label then obj.label:Remove() end
    espObjects[character] = nil
end

local function hideBox(lines, label)
    if label then label.Visible = false end
end

-- Atualiza ESP todo frame
RunService.RenderStepped:Connect(function()
    for character, obj in pairs(espObjects) do
        local isNPC = trackedNPCs and trackedNPCs[character] ~= nil

        if not ESPEnabled or (isNPC and not ESPNPCEnabled) then
            hideBox(obj.lines, obj.label)
        else
            local hum  = character:FindFirstChildOfClass("Humanoid")
            local root = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")

            if hum and root and head and hum.Health > 0 then
                local topPos, topVis   = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
                local _, botVis        = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.8, 0))

                if topVis and botVis and topPos.Z > 0 then
                    if obj.label then
                        local dist   = (Camera.CFrame.Position - root.Position).Magnitude
                        local player = playerChars[character]
                        local name   = player and player.Name or character.Name
                        obj.label.Position = Vector2.new(topPos.X, topPos.Y - 16)
                        obj.label.Text     = name .. "  [" .. math.floor(dist) .. "m]"
                        obj.label.Visible  = true
                    end
                else
                    hideBox(obj.lines, obj.label)
                end
            else
                hideBox(obj.lines, obj.label)
            end
        end
    end
end)

-- ==================== Hook players ====================
local function hookPlayer(player)
    if player == LocalPlayer then return end
    local function onChar(char)
        playerChars[char] = player
        createESP(char, PLAYER_COLOR)
    end
    local function onCharRemove(char)
        playerChars[char] = nil
        removeESP(char)
    end
    player.CharacterAdded:Connect(onChar)
    player.CharacterRemoving:Connect(onCharRemove)
    if player.Character then onChar(player.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(function(p)
    if p.Character then
        playerChars[p.Character] = nil
        removeESP(p.Character)
    end
end)

-- ==================== Track NPCs ====================
local trackedNPCs = {}

local function tryAddNPC(model)
    if trackedNPCs[model] then return end
    if not isNPCModel(model) then return end
    trackedNPCs[model] = true
    createESP(model, NPC_COLOR)

    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function()
            task.delay(2, function()
                trackedNPCs[model] = nil
                removeESP(model)
            end)
        end)
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
        task.defer(function() tryAddNPC(obj.Parent) end)
    end
end)
workspace.DescendantRemoving:Connect(function(obj)
    if obj:IsA("Model") and trackedNPCs[obj] then
        trackedNPCs[obj] = nil
        removeESP(obj)
    end
end)

task.spawn(function()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
            tryAddNPC(obj.Parent)
        end
        count = count + 1
        if count % 300 == 0 then task.wait() end
    end
end)

-- ==================== ScreenGui ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "MorteBranca"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== Main Frame ====================
local mainFrame = Instance.new("Frame")
mainFrame.Size                   = UDim2.new(0, 278, 0, 320)
mainFrame.Position               = UDim2.new(1, -314, 0.5, -160)
mainFrame.BackgroundColor3       = Color3.fromRGB(9, 9, 13)
mainFrame.BackgroundTransparency = 0.10
mainFrame.BorderSizePixel        = 0
mainFrame.Visible                = false
mainFrame.Active                 = true
mainFrame.Parent                 = screenGui
mainFrame.ZIndex                 = 5
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local frameStroke = Instance.new("UIStroke")
frameStroke.Color        = Color3.fromRGB(130, 55, 220)
frameStroke.Thickness    = 1.4
frameStroke.Transparency = 0.3
frameStroke.Parent       = mainFrame

-- ==================== Drag ====================
local titleBar = Instance.new("Frame")
titleBar.Size               = UDim2.new(1, 0, 0, 54)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex             = 9
titleBar.Parent             = mainFrame

do
    local dragging, dragMouse, dragOrigin = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging   = true
            dragMouse  = input.Position
            dragOrigin = mainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragMouse
            mainFrame.Position = UDim2.new(
                dragOrigin.X.Scale, dragOrigin.X.Offset + d.X,
                dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ==================== Título ====================
local titleLabel = Instance.new("TextLabel")
titleLabel.Size                  = UDim2.new(1, 0, 0, 52)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                  = "☠  Morte Branca"
titleLabel.TextColor3            = Color3.fromRGB(255, 255, 255)
titleLabel.Font                  = Enum.Font.GothamBlack
titleLabel.TextSize              = 21
titleLabel.TextStrokeTransparency = 0.5
titleLabel.TextStrokeColor3      = Color3.fromRGB(110, 40, 190)
titleLabel.ZIndex                = 7
titleLabel.Parent                = mainFrame

local sep = Instance.new("Frame")
sep.Size             = UDim2.new(1, -28, 0, 1)
sep.Position         = UDim2.new(0, 14, 0, 53)
sep.BackgroundColor3 = Color3.fromRGB(130, 55, 230)
sep.BorderSizePixel  = 0
sep.ZIndex           = 7
sep.Parent           = mainFrame

-- ==================== UI Helpers ====================
local function makeToggle(yPos, label, value, onChange)
    local row = Instance.new("Frame")
    row.Size               = UDim2.new(1, -28, 0, 32)
    row.Position           = UDim2.new(0, 14, 0, yPos)
    row.BackgroundTransparency = 1
    row.ZIndex             = 6
    row.Parent             = mainFrame

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0.7, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.TextColor3         = Color3.fromRGB(225, 225, 235)
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 14
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 7
    lbl.Parent             = row

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 60, 0, 26)
    btn.Position         = UDim2.new(1, -62, 0.5, -13)
    btn.BackgroundColor3 = value and Color3.fromRGB(148, 68, 255) or Color3.fromRGB(36, 36, 46)
    btn.Text             = value and "ON" or "OFF"
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 8
    btn.Parent           = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        value                = not value
        btn.BackgroundColor3 = value and Color3.fromRGB(148, 68, 255) or Color3.fromRGB(36, 36, 46)
        btn.Text             = value and "ON" or "OFF"
        onChange(value)
    end)
end

local function makeInput(yPos, label, default, isFOV)
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0.58, 0, 0, 26)
    lbl.Position           = UDim2.new(0, 14, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label .. tostring(default)
    lbl.TextColor3         = Color3.fromRGB(190, 190, 205)
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 13.5
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 6
    lbl.Parent             = mainFrame

    local box = Instance.new("TextBox")
    box.Size             = UDim2.new(0, 72, 0, 26)
    box.Position         = UDim2.new(1, -86, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    box.TextColor3       = Color3.fromRGB(255, 255, 255)
    box.Text             = tostring(default)
    box.Font             = Enum.Font.Gotham
    box.TextSize         = 13
    box.BorderSizePixel  = 0
    box.ClearTextOnFocus = false
    box.ZIndex           = 8
    box.Parent           = mainFrame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    local bStroke = Instance.new("UIStroke")
    bStroke.Color        = Color3.fromRGB(100, 40, 180)
    bStroke.Thickness    = 1
    bStroke.Transparency = 0.45
    bStroke.Parent       = box

    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            if isFOV then
                AimbotFOV = math.clamp(n, 20, 900)
                box.Text  = tostring(AimbotFOV)
                lbl.Text  = label .. AimbotFOV
            else
                MaxAimbotDistance = math.clamp(n, 50, 2500)
                box.Text  = tostring(MaxAimbotDistance)
                lbl.Text  = label .. MaxAimbotDistance
            end
        else
            box.Text = isFOV and tostring(AimbotFOV) or tostring(MaxAimbotDistance)
        end
    end)
end

-- ==================== Build UI ====================
makeToggle(62,  "Aimbot  ·  Players",  AimbotEnabled, function(v) AimbotEnabled = v end)
makeToggle(97,  "Aimbot  ·  NPC",      AimNPCEnabled, function(v) AimNPCEnabled = v end)
makeToggle(132, "ESP  ·  NPCs",        ESPNPCEnabled, function(v)
    ESPNPCEnabled = v
    if not v then
        for model in pairs(trackedNPCs) do
            local obj = espObjects[model]
            if obj then hideBox(obj.lines, obj.label) end
        end
    end
end)
makeToggle(167, "ESP  ·  Outlines",    ESPEnabled,    function(v)
    ESPEnabled = v
    if not v then
        for _, obj in pairs(espObjects) do
            hideBox(obj.lines, obj.label)
        end
    end
end)

makeInput(208, "FOV  ·  ",       AimbotFOV,         true)
makeInput(240, "Max Range  ·  ", MaxAimbotDistance,  false)

local aimHint = Instance.new("TextLabel")
aimHint.Size               = UDim2.new(1, -28, 0, 24)
aimHint.Position           = UDim2.new(0, 14, 0, 285)
aimHint.BackgroundTransparency = 1
aimHint.Text               = "Aim Part: Head   ·   [B] swap   ·   [RShift] menu"
aimHint.TextColor3         = Color3.fromRGB(110, 55, 190)
aimHint.Font               = Enum.Font.Gotham
aimHint.TextSize           = 11.5
aimHint.TextXAlignment     = Enum.TextXAlignment.Left
aimHint.ZIndex             = 6
aimHint.Parent             = mainFrame

-- ==================== Hotkeys ====================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        mainFrame.Visible = not mainFrame.Visible
    end
    if input.KeyCode == Enum.KeyCode.B then
        if AimPart == "Head" then
            AimPart      = "HumanoidRootPart"
            aimHint.Text = "Aim Part: Body   ·   [B] swap   ·   [RShift] menu"
        else
            AimPart      = "Head"
            aimHint.Text = "Aim Part: Head   ·   [B] swap   ·   [RShift] menu"
        end
    end
end)

-- ==================== Aimbot: Player ====================
local function getClosestPlayer()
    local bestDist = math.huge
    local bestPart = nil
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local part = player.Character:FindFirstChild(AimPart)
                          or player.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and sp.Z > 0 then
                        local sDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        local rDist = (Camera.CFrame.Position - part.Position).Magnitude
                        if sDist < AimbotFOV and sDist < bestDist and rDist <= MaxAimbotDistance then
                            bestDist = sDist
                            bestPart = part
                        end
                    end
                end
            end
        end
    end
    return bestPart
end

-- ==================== Aimbot: NPC ====================
local function getClosestNPC()
    local bestDist = math.huge
    local bestPart = nil
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myRoot   = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for model in pairs(trackedNPCs) do
        local hum  = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 then
            local rDist = (myRoot.Position - root.Position).Magnitude
            if rDist <= NpcScanRadius and rDist <= MaxAimbotDistance then
                local part = model:FindFirstChild(AimPart) or root
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and sp.Z > 0 then
                    local sDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if sDist < AimbotFOV and sDist < bestDist then
                        bestDist = sDist
                        bestPart = part
                    end
                end
            end
        end
    end
    return bestPart
end

-- ==================== Tool Check ====================
local function hasItemInHand()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Tool") ~= nil
end

-- ==================== Aimbot Loop ====================
RunService.RenderStepped:Connect(function()
    if not UserInputService:IsMouseButtonPressed(AimbotKey) then return end
    if not hasItemInHand() then return end

    local targetPart = nil
    local isNPC      = false

    if AimNPCEnabled then
        targetPart = getClosestNPC()
        if targetPart then isNPC = true end
    end

    if not targetPart and AimbotEnabled then
        targetPart = getClosestPlayer()
    end

    if not targetPart then return end

    if isNPC and AimNPCStrong then
        -- Lock On sempre ativo para NPCs
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
    else
        local root      = targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart")
        local vel       = (root and root.AssemblyLinearVelocity) or Vector3.zero
        local predicted = targetPart.Position + (vel * 0.035)
        local targetCF  = CFrame.new(Camera.CFrame.Position, predicted)
        local smooth    = math.clamp(AimSpeed * 0.016 * 1.8, 0.08, 0.92)
        Camera.CFrame   = Camera.CFrame:Lerp(targetCF, smooth)
    end
end)

print("✅ Morte Branca | [RShift] Menu  [B] Swap Aim Part")
