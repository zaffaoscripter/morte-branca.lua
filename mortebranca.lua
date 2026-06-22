-- ==================== Serviços ====================
local UserInputService = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

-- ==================== Configurações ====================
local AimbotFOV         = 180
local MaxAimbotDistance = 650
local AimbotKey         = Enum.UserInputType.MouseButton2
local AimSpeed          = 58.0
local AimPart           = "Head"

local AimbotEnabled  = true
local AimNPCEnabled  = true
local AimNPCStrong   = true
local ESPEnabled     = true

-- ==================== Cache de NPCs Hostis ====================
-- Evita workspace:GetDescendants() todo frame (caro demais)
local hostileCache    = {}   -- { part = BasePart, isPriority = bool }
local CACHE_INTERVAL  = 2.5  -- segundos entre rescans
local lastCacheScan   = 0

local HOSTILE_NAMES   = { "bandit", "zombie", "thug", "outlaw" }
local PRIORITY_NAMES  = { "moe wolff", "elder vampire", "vampire boss", "wolff" }

local function matchesAny(str, list)
    local s = str:lower()
    for _, v in ipairs(list) do
        if s:find(v, 1, true) then return true end
    end
    return false
end

local function rebuildHostileCache()
    hostileCache = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local root     = obj:FindFirstChild("HumanoidRootPart")
            if humanoid and root then
                local isPriority = matchesAny(obj.Name, PRIORITY_NAMES)
                local isHostile  = isPriority or matchesAny(obj.Name, HOSTILE_NAMES)
                    or (obj.Parent and (
                        matchesAny(obj.Parent.Name, PRIORITY_NAMES) or
                        matchesAny(obj.Parent.Name, HOSTILE_NAMES)
                    ))
                if isHostile then
                    table.insert(hostileCache, {
                        model      = obj,
                        humanoid   = humanoid,
                        root       = root,
                        isPriority = isPriority,
                    })
                end
            end
        end
    end
end

-- Atualiza cache quando entidades aparecem/somem
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") then
        task.delay(0.1, rebuildHostileCache) -- pequeno delay p/ filhos carregarem
    end
end)
workspace.DescendantRemoving:Connect(function(obj)
    if obj:IsA("Model") then
        for i, entry in ipairs(hostileCache) do
            if entry.model == obj then
                table.remove(hostileCache, i)
                break
            end
        end
    end
end)

rebuildHostileCache()

-- ==================== ScreenGui ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "MorteBranca"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== Main Frame ====================
local mainFrame = Instance.new("Frame")
mainFrame.Size                = UDim2.new(0, 275, 0, 310)
mainFrame.Position            = UDim2.new(1, -310, 0.5, -155)
mainFrame.BackgroundColor3    = Color3.fromRGB(10, 10, 14)
mainFrame.BackgroundTransparency = 0.18
mainFrame.BorderSizePixel     = 0
mainFrame.Visible             = false
mainFrame.Active              = true
mainFrame.Parent              = screenGui
mainFrame.ZIndex              = 5
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

-- ==================== Stroke ====================
local stroke = Instance.new("UIStroke")
stroke.Color       = Color3.fromRGB(120, 60, 200)
stroke.Thickness   = 1.2
stroke.Transparency = 0.5
stroke.Parent      = mainFrame

-- ==================== Drag (apenas barra de título) ====================
local titleBar = Instance.new("Frame")
titleBar.Size               = UDim2.new(1, 0, 0, 52)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex             = 9
titleBar.Parent             = mainFrame

do
    local dragging      = false
    local dragMouse     = nil
    local dragFramePos  = nil

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging     = true
            dragMouse    = input.Position
            dragFramePos = mainFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragMouse
            mainFrame.Position = UDim2.new(
                dragFramePos.X.Scale, dragFramePos.X.Offset + d.X,
                dragFramePos.Y.Scale, dragFramePos.Y.Offset + d.Y
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
local title = Instance.new("TextLabel")
title.Size                  = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text                  = "☠️  Morte Branca"
title.TextColor3            = Color3.fromRGB(255, 255, 255)
title.Font                  = Enum.Font.GothamBlack
title.TextSize              = 22
title.TextStrokeTransparency = 0.6
title.TextStrokeColor3      = Color3.fromRGB(100, 50, 180)
title.ZIndex                = 7
title.Parent                = mainFrame

-- ==================== Linha ====================
local line = Instance.new("Frame")
line.Size             = UDim2.new(1, -28, 0, 1)
line.Position         = UDim2.new(0, 14, 0, 51)
line.BackgroundColor3 = Color3.fromRGB(150, 80, 255)
line.BorderSizePixel  = 0
line.ZIndex           = 7
line.Parent           = mainFrame

-- ==================== UI: Toggle ====================
local npcStrongButton -- referência global para dim/undim

local function createToggle(yPos, text, defaultValue, callback, getRef)
    local frame = Instance.new("Frame")
    frame.Size               = UDim2.new(1, -28, 0, 32)
    frame.Position           = UDim2.new(0, 14, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.ZIndex             = 6
    frame.Parent             = mainFrame

    local label = Instance.new("TextLabel")
    label.Size               = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text               = text
    label.TextColor3         = Color3.fromRGB(230, 230, 238)
    label.Font               = Enum.Font.GothamSemibold
    label.TextSize           = 14
    label.TextXAlignment     = Enum.TextXAlignment.Left
    label.ZIndex             = 6
    label.Parent             = frame

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 62, 0, 26)
    btn.Position         = UDim2.new(1, -66, 0.5, -13)
    btn.BackgroundColor3 = defaultValue and Color3.fromRGB(160, 100, 255) or Color3.fromRGB(38, 38, 48)
    btn.Text             = defaultValue and "ON" or "OFF"
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 7
    btn.Parent           = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    if getRef then getRef(btn) end

    btn.MouseButton1Click:Connect(function()
        defaultValue         = not defaultValue
        btn.BackgroundColor3 = defaultValue and Color3.fromRGB(160, 100, 255) or Color3.fromRGB(38, 38, 48)
        btn.Text             = defaultValue and "ON" or "OFF"
        callback(defaultValue)
    end)

    return btn
end

-- ==================== UI: Input ====================
local function createInput(yPos, labelText, defaultValue, isFOV)
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0.6, 0, 0, 26)
    lbl.Position           = UDim2.new(0, 14, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText .. tostring(defaultValue)
    lbl.TextColor3         = Color3.fromRGB(195, 195, 210)
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 13.5
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 6
    lbl.Parent             = mainFrame

    local box = Instance.new("TextBox")
    box.Size               = UDim2.new(0, 72, 0, 26)
    box.Position           = UDim2.new(1, -86, 0, yPos)
    box.BackgroundColor3   = Color3.fromRGB(20, 20, 28)
    box.TextColor3         = Color3.fromRGB(255, 255, 255)
    box.Text               = tostring(defaultValue)
    box.Font               = Enum.Font.Gotham
    box.TextSize           = 13
    box.BorderSizePixel    = 0
    box.ClearTextOnFocus   = false
    box.ZIndex             = 7
    box.Parent             = mainFrame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    local stroke2 = Instance.new("UIStroke")
    stroke2.Color       = Color3.fromRGB(90, 50, 140)
    stroke2.Thickness   = 1
    stroke2.Transparency = 0.4
    stroke2.Parent      = box

    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num then
            if isFOV then
                AimbotFOV = math.clamp(num, 20, 900)
                box.Text  = tostring(AimbotFOV)
                lbl.Text  = labelText .. AimbotFOV
            else
                MaxAimbotDistance = math.clamp(num, 50, 2500)
                box.Text  = tostring(MaxAimbotDistance)
                lbl.Text  = labelText .. MaxAimbotDistance
            end
        else
            box.Text = isFOV and tostring(AimbotFOV) or tostring(MaxAimbotDistance)
        end
    end)
end

-- ==================== Monta Interface ====================
createToggle(62,  "Aimbot Players",         AimbotEnabled, function(v) AimbotEnabled = v end)

createToggle(96,  "Aim NPC Hostil",         AimNPCEnabled, function(v)
    AimNPCEnabled = v
    -- Escurece/ilumina o botão de Mira Forte visualmente
    if npcStrongButton then
        npcStrongButton.TextTransparency = v and 0 or 0.5
        npcStrongButton.BackgroundTransparency = v and 0 or 0.4
    end
end)

createToggle(130, "NPC Mira Forte (Gruda)", AimNPCStrong,  function(v) AimNPCStrong = v end,
    function(ref) npcStrongButton = ref end)

createToggle(164, "ESP Players",            ESPEnabled,    function(v) ESPEnabled = v end)

createInput(202, "FOV: ",           AimbotFOV,          true)
createInput(234, "Distância Máx: ", MaxAimbotDistance,  false)

-- ==================== Indicador de Mira ====================
local aimPartLabel = Instance.new("TextLabel")
aimPartLabel.Size               = UDim2.new(1, -28, 0, 26)
aimPartLabel.Position           = UDim2.new(0, 14, 0, 276)
aimPartLabel.BackgroundTransparency = 1
aimPartLabel.Text               = "Mira: Cabeça  [B] trocar  |  [Shift Dir] menu"
aimPartLabel.TextColor3         = Color3.fromRGB(140, 80, 220)
aimPartLabel.Font               = Enum.Font.GothamBold
aimPartLabel.TextSize           = 12
aimPartLabel.TextXAlignment     = Enum.TextXAlignment.Left
aimPartLabel.ZIndex             = 6
aimPartLabel.Parent             = mainFrame

-- ==================== Hotkeys ====================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightShift then
        mainFrame.Visible = not mainFrame.Visible
    end

    if input.KeyCode == Enum.KeyCode.B then
        if AimPart == "Head" then
            AimPart = "HumanoidRootPart"
            aimPartLabel.Text = "Mira: Corpo  [B] trocar  |  [Shift Dir] menu"
        else
            AimPart = "Head"
            aimPartLabel.Text = "Mira: Cabeça  [B] trocar  |  [Shift Dir] menu"
        end
    end
end)

-- ==================== ESP ====================
local ESPObjects = {}

local function createESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    -- Verifica se Drawing API existe no executor
    if not Drawing then return end
    local text          = Drawing.new("Text")
    text.Size           = 15
    text.Center         = true
    text.Outline        = true
    text.Font           = 2
    text.Color          = Color3.fromRGB(185, 130, 255)
    text.OutlineColor   = Color3.fromRGB(0, 0, 0)
    text.Visible        = false
    ESPObjects[player]  = text
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
        local char = player.Character
        if ESPEnabled and char then
            local head     = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if head and humanoid and humanoid.Health > 0 then
                local pos, visible = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
                if visible and pos.Z > 0 then
                    local dist = (Camera.CFrame.Position - head.Position).Magnitude
                    if dist <= MaxAimbotDistance then
                        esp.Position = Vector2.new(pos.X, pos.Y - 30)
                        esp.Text     = player.Name .. "  [" .. math.floor(dist) .. "m]"
                        esp.Visible  = true
                    else
                        esp.Visible = false
                    end
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
    return char and char:FindFirstChildOfClass("Tool") ~= nil
end

-- ==================== Target: Player ====================
local function getClosestPlayer()
    local bestDist = math.huge
    local bestPart = nil
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local part = char:FindFirstChild(AimPart) or char:FindFirstChild("HumanoidRootPart")
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
    end
    return bestPart
end

-- ==================== Target: NPC Hostil (via cache) ====================
local function getClosestHostileNPC()
    local bestDist     = math.huge
    local bestPart     = nil
    local priorityPart = nil
    local center       = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myRoot       = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    -- Rescan periódico leve (fallback de segurança)
    local now = tick()
    if now - lastCacheScan >= CACHE_INTERVAL then
        lastCacheScan = now
        rebuildHostileCache()
    end

    for _, entry in ipairs(hostileCache) do
        local hum  = entry.humanoid
        local root = entry.root
        if hum and root and hum.Health > 0 then
            local part = entry.model:FindFirstChild(AimPart) or root
            local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen and sp.Z > 0 then
                local sDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                local rDist = (myRoot.Position - part.Position).Magnitude
                if sDist < AimbotFOV and rDist <= MaxAimbotDistance then
                    if entry.isPriority then
                        -- Boss: vence sempre (pega o mais perto de center entre os bosses)
                        if not priorityPart or sDist < bestDist then
                            bestDist     = sDist
                            priorityPart = part
                        end
                    elseif not priorityPart and sDist < bestDist then
                        bestDist = sDist
                        bestPart = part
                    end
                end
            end
        end
    end

    return priorityPart or bestPart
end

-- ==================== Aimbot Principal ====================
RunService.RenderStepped:Connect(function()
    if not UserInputService:IsMouseButtonPressed(AimbotKey) then return end
    if not hasItemInHand() then return end

    local targetPart = nil
    local isNPC      = false

    if AimNPCEnabled then
        targetPart = getClosestHostileNPC()
        if targetPart then isNPC = true end
    end

    if not targetPart and AimbotEnabled then
        targetPart = getClosestPlayer()
    end

    if not targetPart then return end

    if isNPC and AimNPCStrong then
        -- Mira rígida: câmera gruda instantaneamente
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
    else
        -- Mira suave com predição de movimento
        -- AssemblyLinearVelocity é o correto no Roblox atual (Velocity foi depreciado)
        local root = targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart")
        local vel  = (root and root.AssemblyLinearVelocity) or Vector3.zero
        local predicted = targetPart.Position + (vel * 0.035)
        local targetCF  = CFrame.new(Camera.CFrame.Position, predicted)
        local smooth    = math.clamp(AimSpeed * 0.016 * 1.8, 0.08, 0.92)
        Camera.CFrame   = Camera.CFrame:Lerp(targetCF, smooth)
    end
end)

print("✅ Morte Branca | Shift Direito = Menu | B = Trocar Mira")
