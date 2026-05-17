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
mainFrame.Size = UDim2.new(0, 270, 0, 260)
mainFrame.Position = UDim2.new(1, -305, 0.5, -130)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
mainFrame.BackgroundTransparency = 0.28
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Parent = screenGui
mainFrame.ZIndex = 5

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

-- ==================== Drag Corrigido ====================
local dragging = false
local dragInput
local dragStart
local startPos

local function updateDrag(input)
	local delta = input.Position - dragStart

	mainFrame.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		updateDrag(input)
	end
end)

-- ==================== Overlay ====================
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
overlay.BackgroundTransparency = 0.38
overlay.BorderSizePixel = 0
overlay.ZIndex = 5
overlay.Parent = mainFrame

Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 16)

-- ==================== Título ====================
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "☠️ Morte Branca"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 23
title.TextStrokeTransparency = 0.7
title.TextStrokeColor3 = Color3.fromRGB(90,60,140)
title.ZIndex = 6
title.Parent = mainFrame

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(230,200,255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170,100,255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120,60,240))
}
titleGradient.Rotation = 40
titleGradient.Parent = title

-- ==================== Linha ====================
local line = Instance.new("Frame")
line.Size = UDim2.new(1, -32, 0, 1)
line.Position = UDim2.new(0, 16, 0, 50)
line.BackgroundColor3 = Color3.fromRGB(160,100,255)
line.BorderSizePixel = 0
line.ZIndex = 6
line.Parent = mainFrame

-- ==================== Função Toggle ====================
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
	label.TextColor3 = Color3.fromRGB(235,235,240)
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 14.5
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 6
	label.Parent = frame

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 62, 0, 26)
	button.Position = UDim2.new(1, -72, 0.5, -13)
	button.BackgroundColor3 = defaultValue and Color3.fromRGB(180,130,255) or Color3.fromRGB(0,0,0)
	button.Text = defaultValue and "ON" or "OFF"
	button.TextColor3 = Color3.fromRGB(255,255,255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.BorderSizePixel = 0
	button.ZIndex = 6
	button.Parent = frame

	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

	button.MouseButton1Click:Connect(function()
		defaultValue = not defaultValue

		button.BackgroundColor3 =
			defaultValue and Color3.fromRGB(180,130,255)
			or Color3.fromRGB(0,0,0)

		button.Text = defaultValue and "ON" or "OFF"

		callback(defaultValue)
	end)
end

-- ==================== Função Input ====================
local function createInput(yPos, labelText, defaultValue, isFOV)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -30, 0, 24)
	label.Position = UDim2.new(0, 15, 0, yPos)
	label.BackgroundTransparency = 1
	label.Text = labelText .. defaultValue
	label.TextColor3 = Color3.fromRGB(200,200,210)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 6
	label.Parent = mainFrame

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 68, 0, 26)
	box.Position = UDim2.new(1, -83, 0, yPos)
	box.BackgroundColor3 = Color3.fromRGB(25,25,32)
	box.TextColor3 = Color3.fromRGB(255,255,255)
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
createToggle(65, "Aimbot", AimbotEnabled, function(v)
	AimbotEnabled = v
end)

createToggle(105, "ESP", ESPEnabled, function(v)
	ESPEnabled = v
end)

createInput(150, "FOV: ", AimbotFOV, true)
createInput(180, "Distância Máx: ", MaxAimbotDistance, false)

-- ==================== Indicador Mira ====================
local aimPartLabel = Instance.new("TextLabel")
aimPartLabel.Size = UDim2.new(1, -30, 0, 26)
aimPartLabel.Position = UDim2.new(0, 15, 0, 215)
aimPartLabel.BackgroundTransparency = 1
aimPartLabel.Text = "Mira em: Cabeça"
aimPartLabel.TextColor3 = Color3.fromRGB(180,130,255)
aimPartLabel.Font = Enum.Font.GothamBold
aimPartLabel.TextSize = 14
aimPartLabel.TextXAlignment = Enum.TextXAlignment.Left
aimPartLabel.ZIndex = 6
aimPartLabel.Parent = mainFrame

-- ==================== Toggle Menu ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.RightShift then
		mainFrame.Visible = not mainFrame.Visible
	end

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

-- ==================== ESP ====================
local ESPObjects = {}

local function createESP(player)
	if player == LocalPlayer or ESPObjects[player] then
		return
	end

	local text = Drawing.new("Text")
	text.Size = 16
	text.Center = true
	text.Outline = true
	text.Font = 2
	text.Color = Color3.fromRGB(195,145,255)
	text.OutlineColor = Color3.fromRGB(0,0,0)
	text.Visible = false

	ESPObjects[player] = text
end

for _, plr in ipairs(Players:GetPlayers()) do
	createESP(plr)
end

Players.PlayerAdded:Connect(createESP)

Players.PlayerRemoving:Connect(function(player)
	if ESPObjects[player] then
		ESPObjects[player]:Remove()
		ESPObjects[player] = nil
	end
end)

RunService.RenderStepped:Connect(function()
	for player, esp in pairs(ESPObjects) do
		if ESPEnabled
			and player.Character
			and player.Character:FindFirstChild("Head")
			and player.Character:FindFirstChildOfClass("Humanoid")
		then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

			if humanoid.Health > 0 then
				local head = player.Character.Head

				local pos, visible =
					Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))

				if visible and pos.Z > 0 then
					local dist =
						(Camera.CFrame.Position - head.Position).Magnitude

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

-- ==================== Tool Check ====================
local function hasItemInHand()
	local char = LocalPlayer.Character

	if not char then
		return false
	end

	return char:FindFirstChildOfClass("Tool") ~= nil
end

-- ==================== Get Closest ====================
local function getClosestTarget()
	local closestDist = math.huge
	local closestPlayer = nil

	local mousePos = Vector2.new(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local humanoid =
				player.Character:FindFirstChildOfClass("Humanoid")

			if humanoid and humanoid.Health > 0 then
				local targetPart =
					player.Character:FindFirstChild(AimPart)
					or player.Character:FindFirstChild("HumanoidRootPart")

				if targetPart then
					local screenPos, onScreen =
						Camera:WorldToViewportPoint(targetPart.Position)

					if onScreen and screenPos.Z > 0 then
						local distanceFromCenter =
							(Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

						local realDistance =
							(Camera.CFrame.Position - targetPart.Position).Magnitude

						if distanceFromCenter < AimbotFOV
							and distanceFromCenter < closestDist
							and realDistance <= MaxAimbotDistance
						then
							closestDist = distanceFromCenter
							closestPlayer = player
						end
					end
				end
			end
		end
	end

	return closestPlayer
end

-- ==================== Aimbot ====================
RunService.RenderStepped:Connect(function()
	if not AimbotEnabled then
		return
	end

	if not hasItemInHand() then
		return
	end

	if not UserInputService:IsMouseButtonPressed(AimbotKey) then
		return
	end

	local target = getClosestTarget()

	if not target or not target.Character then
		return
	end

	local targetPart =
		target.Character:FindFirstChild(AimPart)
		or target.Character:FindFirstChild("HumanoidRootPart")

	if not targetPart then
		return
	end

	local root =
		target.Character:FindFirstChild("HumanoidRootPart")

	local velocity = root and root.Velocity or Vector3.zero

	local camPos = Camera.CFrame.Position
	local predictedPos = targetPart.Position + (velocity * 0.035)

	local targetCF =
		CFrame.new(camPos, predictedPos)

	local smoothness =
		math.clamp(AimSpeed * 0.016 * 1.8, 0.08, 0.92)

	Camera.CFrame =
		Camera.CFrame:Lerp(targetCF, smoothness)
end)

print("✅ Morte Branca carregado | Shift Direito = Menu | B = Cabeça/Corpo")
