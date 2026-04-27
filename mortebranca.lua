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
local ESPEnabled = true
local AimSpeed = 58.0          -- Quanto maior, mais "rápido"

local AimPart = "Head"         -- "Head" ou "HumanoidRootPart" (Corpo)
local ShowAimPart = true       -- Mostra qual parte está mirando no GUI

-- ==================== ScreenGui ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MorteBranca"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- = Toggle Button Lateral =
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 18, 0, 36)
toggleButton.Position = UDim2.new(1, -20, 0.5, -18)
toggleButton.BackgroundTransparency = 1
toggleButton.Text = "◀"
toggleButton.TextColor3 = Color3.fromRGB(170, 170, 185)
toggleButton.TextSize = 16
toggleButton.Font = Enum.Font.GothamBold
toggleButton.BorderSizePixel = 0
toggleButton.ZIndex = 20
toggleButton.Parent = screenGui

toggleButton.MouseEnter:Connect(function() toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255) end)
toggleButton.MouseLeave:Connect(function() toggleButton.TextColor3 = Color3.fromRGB(170, 170, 185) end)

-- == Main Frame =
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 270, 0, 260)
mainFrame.Position = UDim2.new(1, -305, 0.5, -130)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
mainFrame.BackgroundTransparency = 0.28
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local blur = Instance.new("BlurEffect")
blur.Size = 24
blur.Parent = mainFrame

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
overlay.BackgroundTransparency = 0.38
overlay.BorderSizePixel = 0
overlay.Parent = mainFrame
Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 16)

-- Título
local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "☠️ Morte Branca"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 23
title.TextStrokeTransparency = 0.7
title.TextStrokeColor3 = Color3.fromRGB(90, 60, 140)

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 200, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 100, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 60, 240))
}
titleGradient.Rotation = 40
titleGradient.Parent = title

-- Linha decorativa
local line = Instance.new("Frame", mainFrame)
line.Size = UDim2.new(1, -32, 0, 1)
line.Position = UDim2.new(0, 16, 0, 50)
line.BackgroundColor3 = Color3.fromRGB(160, 100, 255)
line.BorderSizePixel = 0

-- == Toggles =
local function createToggle(yPos, text, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -30, 0, 32)
    frame.Position = UDim2.new(0, 15, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = mainFrame

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 235, 240)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14.5
    label.TextXAlignment = Enum.TextXAlignment.Left

    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(0, 62, 0, 26)
    button.Position = UDim2.new(1, -72, 0.5, -13)
   button.BackgroundColor3 = defaultValue and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(0, 0, 0)
    button.Text = defaultValue and "ON" or "OFF"
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.BorderSizePixel = 0
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    button.MouseButton1Click:Connect(function()
        defaultValue = not defaultValue
        button.BackgroundColor3 = defaultValue and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(0, 0, 0)
        button.Text = defaultValue and "ON" or "OFF"
        callback(defaultValue)
    end)
end

createToggle(65, "Aimbot", AimbotEnabled, function(v) AimbotEnabled = v end)
createToggle(105, "ESP", ESPEnabled, function(v) ESPEnabled = v end)

-- = Input Fields =
local function createInput(yPos, labelText, defaultValue, isFOV)
    local label = Instance.new("TextLabel", mainFrame)
    label.Size = UDim2.new(1, -30, 0, 24)
    label.Position = UDim2.new(0, 15, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = labelText .. defaultValue
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", mainFrame)
    box.Size = UDim2.new(0, 68, 0, 26)
    box.Position = UDim2.new(1, -83, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultValue)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13.5
    box.BorderSizePixel = 0
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

createInput(150, "FOV: ", AimbotFOV, true)
createInput(180, "Distância Máx: ", MaxAimbotDistance, false)

-- Indicador de parte do corpo
local aimPartLabel = Instance.new("TextLabel", mainFrame)
aimPartLabel.Size = UDim2.new(1, -30, 0, 26)
aimPartLabel.Position = UDim2.new(0, 15, 0, 215)
aimPartLabel.BackgroundTransparency = 1
aimPartLabel.Text = "Mira em: " .. (AimPart == "Head" and "Cabeça" or "Corpo")
aimPartLabel.TextColor3 = Color3.fromRGB(180, 130, 255)
aimPartLabel.Font = Enum.Font.GothamBold
aimPartLabel.TextSize = 14
aimPartLabel.TextXAlignment = Enum.TextXAlignment.Left

-- = Função de Toggle da Interface =
local function toggleInterface()
    mainFrame.Visible = not mainFrame.Visible
    toggleButton.Text = mainFrame.Visible and "▶" or "◀"
end
toggleButton.MouseButton1Click:Connect(toggleInterface)

-- = Tecla F - Mudar entre Cabeça e Corpo =
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.B then
        if AimPart == "Head" then
            AimPart = "HumanoidRootPart"
            aimPartLabel.Text = "Mira em: Corpo"
        else
            AimPart = "Head"
            aimPartLabel.Text = "Mira em: Cabeça"
        end
    end
end)

-- = ESP FUDIDAO =
local ESPObjects = {}

local function createESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    local nameTag = Drawing.new("Text")
    nameTag.Size = 15.8
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameTag.Color = Color3.fromRGB(195, 145, 255)
    nameTag.Transparency = 0.45
    nameTag.TextStrokeTransparency = 0.35
    nameTag.Visible = false
    ESPObjects[player] = nameTag
end

for _, plr in ipairs(Players:GetPlayers()) do createESP(plr) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    if ESPObjects[p] then
        ESPObjects[p]:Remove()
        ESPObjects[p] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    for player, esp in pairs(ESPObjects) do
        if ESPEnabled and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                if onScreen and pos.Z > 0 then
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

-- = Aimbot Potente =
local function hasItemInHand()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Tool") ~= nil
end

local function getClosestTarget()
    local closestDist = math.huge
    local closestPlayer = nil
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local targetPart = char:FindFirstChild(AimPart) or char:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            local realDist = (Camera.CFrame.Position - targetPart.Position).Magnitude

                            if screenDist < AimbotFOV and screenDist < closestDist and realDist <= MaxAimbotDistance then
                                closestDist = screenDist
                                closestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Aimbot Loop 
RunService.RenderStepped:Connect(function(dt)
    if not AimbotEnabled or not hasItemInHand() or not UserInputService:IsMouseButtonPressed(AimbotKey) then 
        return 
    end

    local target = getClosestTarget()
    if not target or not target.Character then return end

    local targetPart = target.Character:FindFirstChild(AimPart) or target.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    local camPos = Camera.CFrame.Position
    local targetPos = targetPart.Position

    -- Leve prediction (melhora muito em movimento)
    local velocity = target.Character:FindFirstChild("HumanoidRootPart").Velocity
    targetPos = targetPos + velocity * 0.035   -- ajuste fino aqui se quiser mais/menos predição

    local direction = (targetPos - camPos).Unit
    local targetCF = CFrame.new(camPos, camPos + direction)

    -- Smoothing mais potente
    local lerpAlpha = math.clamp(AimSpeed * 0.016 * 1.8, 0.08, 0.92)  -- otimizado para 60fps
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, lerpAlpha)
end)

print("Morte Branca carregado - Aimbot aprimorado | Pressione B para alternar Cabeça/Corpo")
