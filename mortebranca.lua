-- ==================== Serviços ====================
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== Configurações ====================
local AimbotFOV = 220
local MaxAimbotDistance = 650
local AimbotKey = Enum.UserInputType.MouseButton2

local AimbotEnabled = true
local AimNPCEnabled = true
local AimNPCStrong = true
local ESPEnabled = true
local AimSpeed = 58.0
local AimPart = "Head"

-- ==================== ScreenGui ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MorteBranca"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== Main Frame ====================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 270, 0, 300)
mainFrame.Position = UDim2.new(1, -305, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
mainFrame.BackgroundTransparency = 0.28
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Parent = screenGui
mainFrame.ZIndex = 5
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

-- ==================== Barra de Título (Drag apenas aqui) ====================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 52)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex = 7
titleBar.Parent = mainFrame

-- ==================== Drag (somente pela barra de título) ====================
local dragging = false
local dragStartMouse = nil
local dragStartFrame = nil

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartMouse = input.Position
        dragStartFrame = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartMouse
        mainFrame.Position = UDim2.new(
            dragStartFrame.X.Scale, dragStartFrame.X.Offset + delta.X,
            dragStartFrame.Y.Scale, dragStartFrame.Y.Offset + delta.Y
        )
    end
end)

-- ==================== Overlay e Título ====================
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
overlay.BackgroundTransparency = 0.38
overlay.BorderSizePixel = 0
overlay.ZIndex = 5
overlay.Parent = mainFrame
Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 16)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "☠️ Morte Branca"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 23
title.TextStrokeTransparency = 0.7
title.TextStrokeColor3 = Color3.fromRGB(90, 60, 140)
title.ZIndex = 6
title.Parent = mainFrame

-- ==================== Linha ====================
local line = Instance.new("Frame")
line.Size = UDim2.new(1, -32, 0, 1)
line.Position = UDim2.new(0, 16, 0, 50)
line.BackgroundColor3 = Color3.fromRGB(160, 100, 255)
line.BorderSizePixel = 0
line.ZIndex = 6
line.Parent = mainFrame

-- ==================== Funções UI ====================
local function createToggle(yPos, text, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -30, 0, 32)
    frame.Position = UDim2.new(0, 15, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 6
    frame.Parent = mainFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 235, 240)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14.5
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 6
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 62, 0, 26)
    button.Position = UDim2.new(1, -72, 0.5, -13)
    button.BackgroundColor3 = defaultValue and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(40, 40, 48)
    button.Text = defaultValue and "ON" or "OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.BorderSizePixel = 0
    button.ZIndex = 6
    button.Parent = frame
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    button.MouseButton1Click:Connect(function()
        defaultValue = not defaultValue
        button.BackgroundColor3 = defaultValue and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(40, 40, 48)
        button.Text = defaultValue and "ON" or "OFF"
        callback(defaultValue)
    end)
end

local function createInput(yPos, labelText, defaultValue, isFOV)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 0, 24)
    label.Position = UDim2.new(0, 15, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = labelText .. defaultValue
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 6
    label.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 68, 0, 26)
    box.Position = UDim2.new(1, -83, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultValue)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13.5
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.ZIndex = 6
    box.Parent = mainFrame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num then
            if isFOV then
                AimbotFOV = math.clamp(num, 20, 900)
                box.Text = tostring(AimbotFOV)
            else
                MaxAimbotDistance = math.clamp(num, 50, 2500)
                box.Text = tostring(MaxAimbotDistance)
            end
            label.Text = labelText .. (isFOV and AimbotFOV or MaxAimbotDistance)
        end
    end)
end

-- ==================== Interface ====================
createToggle(65,  "Aimbot Players",          AimbotEnabled,  function(v) AimbotEnabled = v end)
createToggle(100, "Aim NPC Hostil",          AimNPCEnabled,  function(v) AimNPCEnabled = v end)
createToggle(135, "NPC Mira Forte (Gruda)",  AimNPCStrong,   function(v) AimNPCStrong = v end)
createToggle(170, "ESP Players",             ESPEnabled,     function(v) ESPEnabled = v end)

createInput(210, "FOV: ",           AimbotFOV,          true)
createInput(240, "Distância Máx: ", MaxAimbotDistance,  false)

-- ==================== Indicador Mira ====================
local aimPartLabel = Instance.new("TextLabel")
aimPartLabel.Size = UDim2.new(1, -30, 0, 26)
aimPartLabel.Position = UDim2.new(0, 15, 0, 272)
aimPartLabel.BackgroundTransparency = 1
aimPartLabel.Text = "Mira em: Cabeça  |  [B] para trocar"
aimPartLabel.TextColor3 = Color3.fromRGB(180, 130, 255)
aimPartLabel.Font = Enum.Font.GothamBold
aimPartLabel.TextSize = 13
aimPartLabel.TextXAlignment = Enum.TextXAlignment.Left
aimPartLabel.ZIndex = 6
aimPartLabel.Parent = mainFrame

-- ==================== Toggle Menu ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        mainFrame.Visible = not mainFrame.Visible
    end
    if input.KeyCode == Enum.KeyCode.B then
        if AimPart == "Head" then
            AimPart = "HumanoidRootPart"
            aimPartLabel.Text = "Mira em: Corpo  |  [B] para trocar"
        else
            AimPart = "Head"
            aimPartLabel.Text = "Mira em: Cabeça  |  [B] para trocar"
        end
    end
end)

-- ==================== ESP ====================
local ESPObjects = {}

local function createESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    local text = Drawing.new("Text")
    text.Size = 16
    text.Center = true
    text.Outline = true
    text.Font = 2
    text.Color = Color3.fromRGB(195, 145, 255)
    text.OutlineColor = Color3.fromRGB(0, 0, 0)
    text.Visible = false
    ESPObjects[player] = text
end

for _, plr in ipairs(Players:GetPlayers()) do createESP(plr) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        ESPObjects[player]:Remove()
        ESPObjects[player] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    for player, esp in pairs(ESPObjects) do
        local active = ESPEnabled
            and player.Character
            and player.Character:FindFirstChild("Head")

        if active then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local head = player.Character.Head
                local pos, visible = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                if visible and pos.Z > 0 then
                    local dist = (Camera.CFrame.Position - head.Position).Magnitude
                    esp.Position = Vector2.new(pos.X, pos.Y - 28)
                    esp.Text = player.Name .. " [" .. math.floor(dist) .. "m]"
                    esp.Visible = true
                else
                    esp.Visible = false
                end
            else
                esp.Visible = false
            end
        else
            esp.Visible = false
        end
    end
end)

-- ==================== Utilitários ====================
local function hasItemInHand()
    local char = LocalPlayer.Character
    if not char then return false end
    return char:FindFirstChildOfClass("Tool") ~= nil
end

local function isHostileName(name)
    local n = name:lower()
    return n:find("moe wolff") or n:find("elder vampire") or
           n:find("vampire boss") or n:find("wolff") or
           n:find("bandit") or n:find("zombie") or
           n:find("thug") or n:find("outlaw")
end

-- ==================== Target: Player mais próximo ====================
local function getClosestPlayer()
    local closestDist = math.huge
    local closestPart = nil
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local part = player.Character:FindFirstChild(AimPart)
                    or player.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and screenPos.Z > 0 then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        local realDist   = (Camera.CFrame.Position - part.Position).Magnitude
                        if screenDist < AimbotFOV and screenDist < closestDist and realDist <= MaxAimbotDistance then
                            closestDist = screenDist
                            closestPart = part
                        end
                    end
                end
            end
        end
    end
    return closestPart
end

-- ==================== Target: NPC Hostil mais próximo ====================
local function getClosestHostileNPC()
    local closestDist = math.huge
    local closestPart = nil
    local priorityPart = nil
    local center  = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myRoot  = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if not myRoot then return nil end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local rootPart = obj:FindFirstChild("HumanoidRootPart")
            if humanoid and rootPart and humanoid.Health > 0 then
                if isHostileName(obj.Name) or (obj.Parent and isHostileName(obj.Parent.Name)) then
                    local part = obj:FindFirstChild(AimPart) or rootPart
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and screenPos.Z > 0 then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        local realDist   = (myRoot.Position - part.Position).Magnitude
                        if screenDist < AimbotFOV and realDist <= MaxAimbotDistance then
                            -- Boss vampiro tem prioridade máxima imediata
                            local n = obj.Name:lower()
                            if n:find("moe wolff") or n:find("elder vampire") or n:find("vampire boss") or n:find("wolff") then
                                priorityPart = part
                            elseif screenDist < closestDist and not priorityPart then
                                closestDist = screenDist
                                closestPart = part
                            end
                        end
                    end
                end
            end
        end
    end

    return priorityPart or closestPart
end

-- ==================== Aimbot Principal ====================
RunService.RenderStepped:Connect(function()
    if not UserInputService:IsMouseButtonPressed(AimbotKey) then return end
    if not hasItemInHand() then return end

    local targetPart = nil
    local isNPC = false

    if AimNPCEnabled then
        targetPart = getClosestHostileNPC()
        if targetPart then isNPC = true end
    end

    if not targetPart and AimbotEnabled then
        targetPart = getClosestPlayer()
    end

    if not targetPart then return end

    if isNPC and AimNPCStrong then
        -- Mira rígida: gruda direto no NPC
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
    else
        -- Mira suave com predição de movimento (players ou NPC sem Gruda)
        local root = targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart")
        local velocity = (root and root.Velocity) or Vector3.zero
        local predictedPos = targetPart.Position + (velocity * 0.035)
        local targetCF = CFrame.new(Camera.CFrame.Position, predictedPos)
        local smoothness = math.clamp(AimSpeed * 0.016 * 1.8, 0.08, 0.92)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, smoothness)
    end
end)

print("✅ Morte Branca carregado | Shift Direito = Menu | B = Trocar Mira")
