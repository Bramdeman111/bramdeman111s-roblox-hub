-- Bramdeman111s Hub
-- Script Hub for Aimbot ESP, Troll Script, and Infinite Yield

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- UI State
local UIEnabled = true
local UIMinimized = false
local ScreenGui
local MainFrame
local ContentFrame

-- Script states
local AimbotESPLoaded = false
local TrollScriptLoaded = false
local InfiniteYieldLoaded = false

-- Embedded Scripts (for standalone functionality)
local AimbotESPCode = [[-- Enhanced Roblox Client-Side Aimbot & ESP Script
-- Features: FOV Circle, UI Controls, Tracers, Nametags, Distance, Shoot Through Walls

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Whitelist (these players will NOT be aimed at)
local Whitelist = {
    "bramdeman111",
    "dennis456709"
}

-- Configuration
local Config = {
    AimbotEnabled = true,
    ESPEnabled = true,
    AimKey = Enum.UserInputType.MouseButton1,
    FOV = 150,
    Smoothness = 0.15,
    ESPColor = Color3.fromRGB(255, 0, 0),
    ESPThickness = 2,
    ESPFillTransparency = 0.5,
    TracerEnabled = true,
    NametagEnabled = true,
    DistanceEnabled = true,
    ShootThroughWalls = false,
    FOVCircleEnabled = true
}

-- ESP Storage
local ESPBoxes = {}
local ESPTracers = {}
local ESPNametags = {}
local ESPDistances = {}
local FOVCircle

-- UI State
local UIEnabled = true
local UIMinimized = false
local ScreenGui
local MainFrame
local ContentFrame

-- Notification System
local NotificationFrame = nil
local function CreateNotificationSystem()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    
    NotificationFrame = Instance.new("Frame")
    NotificationFrame.Name = "NotificationFrame"
    NotificationFrame.Size = UDim2.new(0, 300, 0, 0)
    NotificationFrame.Position = UDim2.new(1, -320, 1, -20)
    NotificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    NotificationFrame.BorderSizePixel = 0
    NotificationFrame.Parent = screenGui
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = NotificationFrame
    
    return screenGui
end

local function ShowNotification(text, color)
    if not NotificationFrame then return end
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(1, 0, 0, 40)
    notification.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
    notification.BorderSizePixel = 0
    notification.Parent = NotificationFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = notification
    
    NotificationFrame.Size = UDim2.new(0, 300, 0, NotificationFrame.Size.Y.Offset + 45)
    
    spawn(function()
        wait(3)
        for i = 1, 10 do
            notification.BackgroundTransparency = i / 10
            label.TextTransparency = i / 10
            wait(0.05)
        end
        notification:Destroy()
        NotificationFrame.Size = UDim2.new(0, 300, 0, NotificationFrame.Size.Y.Offset - 45)
    end)
end

-- Check if player is whitelisted
local function IsWhitelisted(player)
    for _, name in ipairs(Whitelist) do
        if string.lower(player.Name) == string.lower(name) then
            return true
        end
    end
    return false
end

-- Create FOV Circle
local function CreateFOVCircle()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Thickness = 1
    FOVCircle.NumSides = 60
    FOVCircle.Filled = false
    FOVCircle.Visible = Config.FOVCircleEnabled
    FOVCircle.Radius = Config.FOV / 2
end

-- Update FOV Circle
local function UpdateFOVCircle()
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Config.FOV / 2
        FOVCircle.Visible = Config.FOVCircleEnabled
    end
end

-- Get closest player to crosshair (excluding whitelisted)
local function GetClosestPlayerToCrosshair()
    local closestPlayer = nil
    local shortestDistance = Config.FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if IsWhitelisted(player) then
                continue
            end
            
            local hrp = player.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

-- Raycast check for shoot through walls
local function IsVisible(target)
    if Config.ShootThroughWalls then
        return true
    end
    
    local origin = Camera.CFrame.Position
    local targetHRP = target.Character.HumanoidRootPart
    local direction = (targetHRP.Position - origin).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = Workspace:Raycast(origin, direction * (origin - targetHRP.Position).Magnitude, raycastParams)
    
    return result == nil
end

-- Create ESP elements for a player
local function CreateESP(player)
    if ESPBoxes[player] then return end
    
    local box = Drawing.new("Square")
    box.Color = Config.ESPColor
    box.Thickness = Config.ESPThickness
    box.Filled = true
    box.Transparency = Config.ESPFillTransparency
    box.Visible = false
    
    local tracer = Drawing.new("Line")
    tracer.Color = Config.ESPColor
    tracer.Thickness = 1
    tracer.Visible = false
    
    local nametag = Drawing.new("Text")
    nametag.Color = Config.ESPColor
    nametag.Size = 16
    nametag.Center = true
    nametag.Outline = true
    nametag.Visible = false
    
    local distance = Drawing.new("Text")
    distance.Color = Config.ESPColor
    distance.Size = 14
    distance.Center = true
    distance.Outline = true
    distance.Visible = false
    
    ESPBoxes[player] = box
    ESPTracers[player] = tracer
    ESPNametags[player] = nametag
    ESPDistances[player] = distance
end

-- Remove ESP for a player
local function RemoveESP(player)
    if ESPBoxes[player] then
        ESPBoxes[player]:Remove()
        ESPBoxes[player] = nil
    end
    if ESPTracers[player] then
        ESPTracers[player]:Remove()
        ESPTracers[player] = nil
    end
    if ESPNametags[player] then
        ESPNametags[player]:Remove()
        ESPNametags[player] = nil
    end
    if ESPDistances[player] then
        ESPDistances[player]:Remove()
        ESPDistances[player] = nil
    end
end

-- Update ESP
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local hrp = player.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if IsWhitelisted(player) then
                if ESPBoxes[player] then
                    ESPBoxes[player].Visible = false
                    ESPTracers[player].Visible = false
                    ESPNametags[player].Visible = false
                    ESPDistances[player].Visible = false
                end
                continue
            end
            
            if not ESPBoxes[player] then
                CreateESP(player)
            end
            
            local box = ESPBoxes[player]
            local tracer = ESPTracers[player]
            local nametag = ESPNametags[player]
            local distanceText = ESPDistances[player]
            
            if onScreen and Config.ESPEnabled then
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                local scaleFactor = 1 / (dist * math.tan(math.rad(Camera.FieldOfView / 2)) * 2) * 1000
                local boxSize = Vector2.new(4 * scaleFactor, 6 * scaleFactor)
                
                box.Size = boxSize
                box.Position = Vector2.new(screenPos.X - boxSize.X / 2, screenPos.Y - boxSize.Y / 2)
                box.Visible = true
                
                if Config.TracerEnabled then
                    tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    tracer.To = Vector2.new(screenPos.X, screenPos.Y + boxSize.Y / 2)
                    tracer.Visible = true
                else
                    tracer.Visible = false
                end
                
                if Config.NametagEnabled then
                    nametag.Text = player.Name
                    nametag.Position = Vector2.new(screenPos.X, screenPos.Y - boxSize.Y / 2 - 20)
                    nametag.Visible = true
                else
                    nametag.Visible = false
                end
                
                if Config.DistanceEnabled then
                    distanceText.Text = string.format("%.1f studs", dist)
                    distanceText.Position = Vector2.new(screenPos.X, screenPos.Y + boxSize.Y / 2 + 15)
                    distanceText.Visible = true
                else
                    distanceText.Visible = false
                end
                
                box.Color = Config.ESPColor
                tracer.Color = Config.ESPColor
                nametag.Color = Config.ESPColor
                distanceText.Color = Config.ESPColor
            else
                box.Visible = false
                tracer.Visible = false
                nametag.Visible = false
                distanceText.Visible = false
            end
        else
            if ESPBoxes[player] then
                ESPBoxes[player].Visible = false
                ESPTracers[player].Visible = false
                ESPNametags[player].Visible = false
                ESPDistances[player].Visible = false
            end
        end
    end
end

-- Aimbot function
local function AimAtTarget(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    if not IsVisible(target) then
        return
    end
    
    local targetHRP = target.Character.HumanoidRootPart
    local currentCF = Camera.CFrame
    local targetCF = CFrame.new(currentCF.Position, targetHRP.Position)
    
    Camera.CFrame = currentCF:Lerp(targetCF, Config.Smoothness)
end

-- Input handling for aimbot
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Config.AimKey and Config.AimbotEnabled then
        local target = GetClosestPlayerToCrosshair()
        if target then
            AimAtTarget(target)
        end
    end
end)

-- Handle player joining/leaving
Players.PlayerAdded:Connect(function(player)
    if Config.ESPEnabled then
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Create UI
local function CreateUI()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AimbotESPUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 250, 0, 400)
    MainFrame.Position = UDim2.new(0, 10, 0, 10)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 5, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "Aimbot & ESP Settings"
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
    minimizeBtn.Position = UDim2.new(1, -55, 0, 2.5)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    minimizeBtn.Text = "-"
    minimizeBtn.TextSize = 18
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = titleBar
    
    minimizeBtn.MouseButton1Click:Connect(function()
        UIMinimized = not UIMinimized
        ContentFrame.Visible = not UIMinimized
        minimizeBtn.Text = UIMinimized and "+" or "-"
        minimizeBtn.BackgroundColor3 = UIMinimized and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(255, 200, 0)
        MainFrame.Size = UDim2.new(0, 250, 0, UIMinimized and 30 or 400)
    end)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -27.5, 0, 2.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "×"
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    closeBtn.MouseButton1Click:Connect(function()
        UIEnabled = false
        MainFrame.Visible = false
    end)
    
    ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, -30)
    ContentFrame.Position = UDim2.new(0, 0, 0, 30)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    local aimbotToggle = Instance.new("TextButton")
    aimbotToggle.Name = "AimbotToggle"
    aimbotToggle.Size = UDim2.new(1, -20, 0, 35)
    aimbotToggle.Position = UDim2.new(0, 10, 0, 10)
    aimbotToggle.BackgroundColor3 = Config.AimbotEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    aimbotToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    aimbotToggle.Text = "Aimbot: " .. (Config.AimbotEnabled and "ON" or "OFF")
    aimbotToggle.TextSize = 14
    aimbotToggle.Font = Enum.Font.Gotham
    aimbotToggle.Parent = ContentFrame
    
    aimbotToggle.MouseButton1Click:Connect(function()
        Config.AimbotEnabled = not Config.AimbotEnabled
        aimbotToggle.BackgroundColor3 = Config.AimbotEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        aimbotToggle.Text = "Aimbot: " .. (Config.AimbotEnabled and "ON" or "OFF")
        ShowNotification("🎯 Aimbot " .. (Config.AimbotEnabled and "Enabled" or "Disabled"), Config.AimbotEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0))
    end)
    
    local espToggle = Instance.new("TextButton")
    espToggle.Name = "ESPToggle"
    espToggle.Size = UDim2.new(1, -20, 0, 35)
    espToggle.Position = UDim2.new(0, 10, 0, 50)
    espToggle.BackgroundColor3 = Config.ESPEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    espToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    espToggle.Text = "ESP: " .. (Config.ESPEnabled and "ON" or "OFF")
    espToggle.TextSize = 14
    espToggle.Font = Enum.Font.Gotham
    espToggle.Parent = ContentFrame
    
    espToggle.MouseButton1Click:Connect(function()
        Config.ESPEnabled = not Config.ESPEnabled
        espToggle.BackgroundColor3 = Config.ESPEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        espToggle.Text = "ESP: " .. (Config.ESPEnabled and "ON" or "OFF")
        ShowNotification("👁️ ESP " .. (Config.ESPEnabled and "Enabled" or "Disabled"), Config.ESPEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0))
    end)
    
    local tracerToggle = Instance.new("TextButton")
    tracerToggle.Name = "TracerToggle"
    tracerToggle.Size = UDim2.new(1, -20, 0, 35)
    tracerToggle.Position = UDim2.new(0, 10, 0, 90)
    tracerToggle.BackgroundColor3 = Config.TracerEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    tracerToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    tracerToggle.Text = "Tracers: " .. (Config.TracerEnabled and "ON" or "OFF")
    tracerToggle.TextSize = 14
    tracerToggle.Font = Enum.Font.Gotham
    tracerToggle.Parent = ContentFrame
    
    tracerToggle.MouseButton1Click:Connect(function()
        Config.TracerEnabled = not Config.TracerEnabled
        tracerToggle.BackgroundColor3 = Config.TracerEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        tracerToggle.Text = "Tracers: " .. (Config.TracerEnabled and "ON" or "OFF")
        ShowNotification("📏 Tracers " .. (Config.TracerEnabled and "Enabled" or "Disabled"), Config.TracerEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0))
    end)
    
    local nametagToggle = Instance.new("TextButton")
    nametagToggle.Name = "NametagToggle"
    nametagToggle.Size = UDim2.new(1, -20, 0, 35)
    nametagToggle.Position = UDim2.new(0, 10, 0, 130)
    nametagToggle.BackgroundColor3 = Config.NametagEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    nametagToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    nametagToggle.Text = "Nametags: " .. (Config.NametagEnabled and "ON" or "OFF")
    nametagToggle.TextSize = 14
    nametagToggle.Font = Enum.Font.Gotham
    nametagToggle.Parent = ContentFrame
    
    nametagToggle.MouseButton1Click:Connect(function()
        Config.NametagEnabled = not Config.NametagEnabled
        nametagToggle.BackgroundColor3 = Config.NametagEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        nametagToggle.Text = "Nametags: " .. (Config.NametagEnabled and "ON" or "OFF")
        ShowNotification("🏷️ Nametags " .. (Config.NametagEnabled and "Enabled" or "Disabled"), Config.NametagEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0))
    end)
    
    local distanceToggle = Instance.new("TextButton")
    distanceToggle.Name = "DistanceToggle"
    distanceToggle.Size = UDim2.new(1, -20, 0, 35)
    distanceToggle.Position = UDim2.new(0, 10, 0, 170)
    distanceToggle.BackgroundColor3 = Config.DistanceEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    distanceToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceToggle.Text = "Distance: " .. (Config.DistanceEnabled and "ON" or "OFF")
    distanceToggle.TextSize = 14
    distanceToggle.Font = Enum.Font.Gotham
    distanceToggle.Parent = ContentFrame
    
    distanceToggle.MouseButton1Click:Connect(function()
        Config.DistanceEnabled = not Config.DistanceEnabled
        distanceToggle.BackgroundColor3 = Config.DistanceEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        distanceToggle.Text = "Distance: " .. (Config.DistanceEnabled and "ON" or "OFF")
        ShowNotification("📏 Distance " .. (Config.DistanceEnabled and "Enabled" or "Disabled"), Config.DistanceEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0))
    end)
    
    local fovCircleToggle = Instance.new("TextButton")
    fovCircleToggle.Name = "FOVCircleToggle"
    fovCircleToggle.Size = UDim2.new(1, -20, 0, 35)
    fovCircleToggle.Position = UDim2.new(0, 10, 0, 210)
    fovCircleToggle.BackgroundColor3 = Config.FOVCircleEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    fovCircleToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    fovCircleToggle.Text = "FOV Circle: " .. (Config.FOVCircleEnabled and "ON" or "OFF")
    fovCircleToggle.TextSize = 14
    fovCircleToggle.Font = Enum.Font.Gotham
    fovCircleToggle.Parent = ContentFrame
    
    fovCircleToggle.MouseButton1Click:Connect(function()
        Config.FOVCircleEnabled = not Config.FOVCircleEnabled
        fovCircleToggle.BackgroundColor3 = Config.FOVCircleEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        fovCircleToggle.Text = "FOV Circle: " .. (Config.FOVCircleEnabled and "ON" or "OFF")
        ShowNotification("⭕ FOV Circle " .. (Config.FOVCircleEnabled and "Enabled" or "Disabled"), Config.FOVCircleEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0))
    end)
    
    local wallToggle = Instance.new("TextButton")
    wallToggle.Name = "WallToggle"
    wallToggle.Size = UDim2.new(1, -20, 0, 35)
    wallToggle.Position = UDim2.new(0, 10, 0, 250)
    wallToggle.BackgroundColor3 = Config.ShootThroughWalls and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    wallToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    wallToggle.Text = "Shoot Through Walls: " .. (Config.ShootThroughWalls and "ON" or "OFF")
    wallToggle.TextSize = 14
    wallToggle.Font = Enum.Font.Gotham
    wallToggle.Parent = ContentFrame
    
    wallToggle.MouseButton1Click:Connect(function()
        Config.ShootThroughWalls = not Config.ShootThroughWalls
        wallToggle.BackgroundColor3 = Config.ShootThroughWalls and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        wallToggle.Text = "Shoot Through Walls: " .. (Config.ShootThroughWalls and "ON" or "OFF")
        ShowNotification("🎯 Shoot Through Walls " .. (Config.ShootThroughWalls and "Enabled" or "Disabled"), Config.ShootThroughWalls and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0))
    end)
    
    local fovLabel = Instance.new("TextLabel")
    fovLabel.Name = "FOVLabel"
    fovLabel.Size = UDim2.new(0, 50, 0, 20)
    fovLabel.Position = UDim2.new(0, 10, 0, 290)
    fovLabel.BackgroundTransparency = 1
    fovLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fovLabel.Text = "FOV:"
    fovLabel.TextSize = 14
    fovLabel.Font = Enum.Font.Gotham
    fovLabel.TextXAlignment = Enum.TextXAlignment.Left
    fovLabel.Parent = ContentFrame
    
    local fovInput = Instance.new("TextBox")
    fovInput.Name = "FOVInput"
    fovInput.Size = UDim2.new(1, -70, 0, 20)
    fovInput.Position = UDim2.new(0, 60, 0, 290)
    fovInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    fovInput.BorderSizePixel = 0
    fovInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    fovInput.PlaceholderText = tostring(Config.FOV)
    fovInput.Text = tostring(Config.FOV)
    fovInput.TextSize = 14
    fovInput.Font = Enum.Font.Gotham
    fovInput.ClearTextOnFocus = false
    fovInput.Parent = ContentFrame
    
    fovInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newFOV = tonumber(fovInput.Text)
            if newFOV and newFOV >= 50 and newFOV <= 300 then
                Config.FOV = newFOV
                fovFill.Size = UDim2.new((Config.FOV - 50) / 250, 0, 1, 0)
                ShowNotification("⭕ FOV set to " .. Config.FOV, Color3.fromRGB(0, 150, 255))
            else
                fovInput.Text = tostring(Config.FOV)
            end
        else
            fovInput.Text = tostring(Config.FOV)
        end
    end)
    
    local fovSlider = Instance.new("TextButton")
    fovSlider.Name = "FOVSlider"
    fovSlider.Size = UDim2.new(1, -20, 0, 10)
    fovSlider.Position = UDim2.new(0, 10, 0, 315)
    fovSlider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    fovSlider.Text = ""
    fovSlider.Parent = ContentFrame
    
    local fovFill = Instance.new("Frame")
    fovFill.Name = "FOVFill"
    fovFill.Size = UDim2.new((Config.FOV - 50) / 250, 0, 1, 0)
    fovFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    fovFill.Parent = fovSlider
    
    fovSlider.MouseButton1Down:Connect(function()
        local input = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = UserInputService:GetMouseLocation()
                local relativePos = (mousePos.X - fovSlider.AbsolutePosition.X) / fovSlider.AbsoluteSize.X
                relativePos = math.clamp(relativePos, 0, 1)
                Config.FOV = math.floor(50 + relativePos * 250)
                fovFill.Size = UDim2.new(relativePos, 0, 1, 0)
                fovInput.Text = tostring(Config.FOV)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                input:Disconnect()
            end
        end)
    end)
    
    return ScreenGui, MainFrame, ContentFrame
end

-- Initialize
CreateFOVCircle()
CreateNotificationSystem()
ScreenGui, MainFrame, ContentFrame = CreateUI()

-- M key toggle for UI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.M then
        UIEnabled = not UIEnabled
        MainFrame.Visible = UIEnabled
    end
end)

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and Config.ESPEnabled then
        CreateESP(player)
    end
end

-- Main update loop
RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateFOVCircle()
end)

-- Aimbot & ESP loaded
]]

local TrollScriptCode = [[-- Roblox Troll Script for Friend Trolling Game
-- Features: Fling, Kill, Freeze, Teleport, and more troll effects

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- UI State
local UIEnabled = true
local UIMinimized = false
local ScreenGui
local MainFrame
local ContentFrame
local PlayerDropdown

-- Player State
local FlyEnabled = false
local NoclipEnabled = false
local AirJumpEnabled = false
local ClickTPEnabled = false
local ESPEnabled = true
local SelectionTool = nil

-- ESP Storage
local ESPBoxes = {}
local ESPTracers = {}

-- Notification System
local NotificationFrame = nil
local function CreateNotificationSystem()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    
    NotificationFrame = Instance.new("Frame")
    NotificationFrame.Name = "NotificationFrame"
    NotificationFrame.Size = UDim2.new(0, 300, 0, 0)
    NotificationFrame.Position = UDim2.new(1, -320, 1, -20)
    NotificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    NotificationFrame.BorderSizePixel = 0
    NotificationFrame.Parent = screenGui
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = NotificationFrame
    
    return screenGui
end

local function ShowNotification(text, color)
    if not NotificationFrame then return end
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(1, 0, 0, 40)
    notification.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
    notification.BorderSizePixel = 0
    notification.Parent = NotificationFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = notification
    
    NotificationFrame.Size = UDim2.new(0, 300, 0, NotificationFrame.Size.Y.Offset + 45)
    
    spawn(function()
        wait(3)
        for i = 1, 10 do
            notification.BackgroundTransparency = i / 10
            label.TextTransparency = i / 10
            wait(0.05)
        end
        notification:Destroy()
        NotificationFrame.Size = UDim2.new(0, 300, 0, NotificationFrame.Size.Y.Offset - 45)
    end)
end

-- Troll Functions
local function FlingPlayer(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        ShowNotification("🚀 Flung " .. player.Name, Color3.fromRGB(255, 100, 0))
        local hrp = player.Character.HumanoidRootPart
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 10000, 0)
        bodyVelocity.Parent = hrp
        
        game.Debris:AddItem(bodyVelocity, 0.1)
        
        local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
        bodyAngularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyAngularVelocity.AngularVelocity = Vector3.new(1000, 1000, 1000)
        bodyAngularVelocity.Parent = hrp
        game.Debris:AddItem(bodyAngularVelocity, 0.5)
    end
end

local function KillPlayer(player)
    if player and player.Character and player.Character:FindFirstChild("Humanoid") then
        ShowNotification("💀 Killed " .. player.Name, Color3.fromRGB(200, 0, 0))
        player.Character.Humanoid.Health = 0
    end
end

local function FreezePlayer(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        ShowNotification("❄️ Froze " .. player.Name, Color3.fromRGB(0, 150, 255))
        local hrp = player.Character.HumanoidRootPart
        hrp.Anchored = true
    end
end

local function UnfreezePlayer(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        ShowNotification("🔓 Unfroze " .. player.Name, Color3.fromRGB(0, 200, 100))
        local hrp = player.Character.HumanoidRootPart
        hrp.Anchored = false
    end
end

local function TeleportPlayer(player, position)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = position
    end
end

local function TeleportPlayerRandomly(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local randomPos = CFrame.new(
            math.random(-100, 100),
            50,
            math.random(-100, 100)
        )
        player.Character.HumanoidRootPart.CFrame = randomPos
    end
end

local function MakePlayerInvisible(player)
    if player and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            end
        end
    end
end

local function MakePlayerVisible(player)
    if player and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            end
        end
    end
end

local function MakePlayerGiant(player)
    if player and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Size = part.Size * 5
            end
        end
    end
end

local function MakePlayerTiny(player)
    if player and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Size = part.Size * 0.2
            end
        end
    end
end

local function ResetPlayerSize(player)
    if player and player.Character then
        player.Character:BreakJoints()
        wait(0.1)
        player:LoadCharacter()
    end
end

local function SpinPlayer(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        ShowNotification("🌀 Spun " .. player.Name, Color3.fromRGB(150, 0, 200))
        local hrp = player.Character.HumanoidRootPart
        local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
        bodyAngularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyAngularVelocity.AngularVelocity = Vector3.new(0, 100, 0)
        bodyAngularVelocity.Parent = hrp
        game.Debris:AddItem(bodyAngularVelocity, 2)
    end
end

local function RemovePlayerTools(player)
    if player and player.Character then
        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") then
                tool:Destroy()
            end
        end
    end
end

local function GivePlayerRandomVelocity(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(
            math.random(-500, 500),
            math.random(100, 500),
            math.random(-500, 500)
        )
        bodyVelocity.Parent = hrp
        game.Debris:AddItem(bodyVelocity, 0.5)
    end
end

local function ExplodePlayer(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local explosion = Instance.new("Explosion")
        explosion.Position = hrp.Position
        explosion.BlastRadius = 20
        explosion.BlastPressure = 1000000
        explosion.Parent = Workspace
    end
end

local function NoclipPlayer(player)
    if player and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

local function UnnoclipPlayer(player)
    if player and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Self functions
local function ToggleFly()
    FlyEnabled = not FlyEnabled
    if FlyEnabled then
        ShowNotification("✈️ Fly Enabled", Color3.fromRGB(0, 150, 255))
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "FlyVelocity"
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.Parent = hrp
        end
    else
        ShowNotification("✈️ Fly Disabled", Color3.fromRGB(100, 100, 100))
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local flyVel = hrp:FindFirstChild("FlyVelocity")
            if flyVel then
                flyVel:Destroy()
            end
        end
    end
end

local flyConnection
local function UpdateFly()
    if FlyEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local flyVel = hrp:FindFirstChild("FlyVelocity")
        if flyVel then
            local cam = Workspace.CurrentCamera
            local moveDir = Vector3.new()
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end
            
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit * 50
                flyVel.Velocity = moveDir
            else
                flyVel.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end
end

local function ToggleNoclip()
    NoclipEnabled = not NoclipEnabled
    ShowNotification("👻 Noclip " .. (NoclipEnabled and "Enabled" or "Disabled"), Color3.fromRGB(150, 150, 150))
end

local function UpdateNoclip()
    if NoclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

local function TeleportToPlayer(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            ShowNotification("📍 Teleported to " .. player.Name, Color3.fromRGB(0, 200, 200))
            LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
        end
    end
end

local function TeleportToCoords(x, y, z)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        ShowNotification("📍 Teleported to " .. x .. "," .. y .. "," .. z, Color3.fromRGB(0, 150, 200))
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
    end
end

local function ToggleAirJump()
    AirJumpEnabled = not AirJumpEnabled
    ShowNotification("🦘 Air Jump " .. (AirJumpEnabled and "Enabled" or "Disabled"), Color3.fromRGB(0, 200, 100))
end

local jumpConnection
local function UpdateAirJump()
    if AirJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = 100
    end
end

local function ToggleClickTP()
    ClickTPEnabled = not ClickTPEnabled
    ShowNotification("🖱️ Click TP " .. (ClickTPEnabled and "Enabled" or "Disabled"), Color3.fromRGB(255, 100, 150))
    UpdateClickTP()
end

local clickTPConnection
local function UpdateClickTP()
    if ClickTPEnabled then
        clickTPConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mouse = LocalPlayer:GetMouse()
                if mouse.Hit and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = mouse.Hit
                end
            end
        end)
    else
        if clickTPConnection then
            clickTPConnection:Disconnect()
            clickTPConnection = nil
        end
    end
end

-- ESP Functions
local function GetTeamColor(player)
    if player.Team and player.TeamColor then
        return player.TeamColor.Color
    end
    return Color3.fromRGB(255, 255, 255)
end

local function CreateESP(player)
    if ESPBoxes[player] then return end
    
    local box = Drawing.new("Square")
    box.Color = GetTeamColor(player)
    box.Thickness = 2
    box.Filled = false
    box.Visible = false
    
    local tracer = Drawing.new("Line")
    tracer.Color = GetTeamColor(player)
    tracer.Thickness = 1
    tracer.Visible = false
    
    ESPBoxes[player] = box
    ESPTracers[player] = tracer
end

local function RemoveESP(player)
    if ESPBoxes[player] then
        ESPBoxes[player]:Remove()
        ESPBoxes[player] = nil
    end
    if ESPTracers[player] then
        ESPTracers[player]:Remove()
        ESPTracers[player] = nil
    end
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            
            if not ESPBoxes[player] then
                CreateESP(player)
            end
            
            local box = ESPBoxes[player]
            local tracer = ESPTracers[player]
            
            if onScreen and ESPEnabled then
                local dist = (Workspace.CurrentCamera.CFrame.Position - hrp.Position).Magnitude
                local scaleFactor = 1 / (dist * math.tan(math.rad(Workspace.CurrentCamera.FieldOfView / 2)) * 2) * 1000
                local boxSize = Vector2.new(4 * scaleFactor, 6 * scaleFactor)
                
                box.Size = boxSize
                box.Position = Vector2.new(screenPos.X - boxSize.X / 2, screenPos.Y - boxSize.Y / 2)
                box.Visible = true
                box.Color = GetTeamColor(player)
                
                tracer.From = Vector2.new(Workspace.CurrentCamera.ViewportSize.X / 2, Workspace.CurrentCamera.ViewportSize.Y)
                tracer.To = Vector2.new(screenPos.X, screenPos.Y + boxSize.Y / 2)
                tracer.Visible = true
                tracer.Color = GetTeamColor(player)
            else
                box.Visible = false
                tracer.Visible = false
            end
        else
            if ESPBoxes[player] then
                ESPBoxes[player].Visible = false
                ESPTracers[player].Visible = false
            end
        end
    end
end

-- Selection Tool
local function CreateSelectionTool(toolName)
    if SelectionTool then
        SelectionTool:Destroy()
    end
    
    SelectionTool = Instance.new("Tool")
    SelectionTool.Name = toolName
    SelectionTool.RequiresHandle = false
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.Transparency = 1
    handle.CanCollide = false
    handle.Parent = SelectionTool
    
    SelectionTool.Activated:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        if mouse.Target and mouse.Target.Parent:FindFirstChild("Humanoid") then
            local character = mouse.Target.Parent
            local player = Players:GetPlayerFromCharacter(character)
            if player and PlayerDropdown then
                PlayerDropdown.Text = player.Name
            end
        end
    end)
    
    SelectionTool.Parent = LocalPlayer.Backpack
end

-- Get selected player from dropdown
local function GetSelectedPlayer()
    if PlayerDropdown and PlayerDropdown.Text ~= "Select Player" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name == PlayerDropdown.Text then
                return player
            end
        end
    end
    return nil
end

-- Create UI
local function CreateUI()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TrollUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 280, 0, 800)
    MainFrame.Position = UDim2.new(0, 10, 0, 10)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.new(0, 5, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "🎭 Troll Menu"
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -65, 0, 2.5)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    minimizeBtn.Text = "-"
    minimizeBtn.TextSize = 20
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = titleBar
    
    minimizeBtn.MouseButton1Click:Connect(function()
        UIMinimized = not UIMinimized
        ContentFrame.Visible = not UIMinimized
        minimizeBtn.Text = UIMinimized and "+" or "-"
        minimizeBtn.BackgroundColor3 = UIMinimized and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(255, 200, 0)
        MainFrame.Size = UDim2.new(0, 280, 0, UIMinimized and 35 or 800)
    end)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -32.5, 0, 2.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "×"
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    closeBtn.MouseButton1Click:Connect(function()
        UIEnabled = false
        MainFrame.Visible = false
    end)
    
    ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, -35)
    ContentFrame.Position = UDim2.new(0, 0, 0, 35)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    local playerLabel = Instance.new("TextLabel")
    playerLabel.Size = UDim2.new(1, -20, 0, 25)
    playerLabel.Position = UDim2.new(0, 10, 0, 10)
    playerLabel.BackgroundTransparency = 1
    playerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerLabel.Text = "Select Target:"
    playerLabel.TextSize = 14
    playerLabel.Font = Enum.Font.Gotham
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerLabel.Parent = ContentFrame
    
    PlayerDropdown = Instance.new("TextBox")
    PlayerDropdown.Name = "PlayerDropdown"
    PlayerDropdown.Size = UDim2.new(1, -20, 0, 30)
    PlayerDropdown.Position = UDim2.new(0, 10, 0, 35)
    PlayerDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    PlayerDropdown.BorderSizePixel = 0
    PlayerDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerDropdown.PlaceholderText = "Select Player"
    PlayerDropdown.Text = "Select Player"
    PlayerDropdown.TextSize = 14
    PlayerDropdown.Font = Enum.Font.Gotham
    PlayerDropdown.Parent = ContentFrame
    
    local yOffset = 75
    local function CreateTrollButton(name, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 35)
        btn.Position = UDim2.new(0, 10, 0, yOffset)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = name
        btn.TextSize = 13
        btn.Font = Enum.Font.Gotham
        btn.Parent = ContentFrame
        
        btn.MouseButton1Click:Connect(callback)
        yOffset = yOffset + 40
        return btn
    end
    
    CreateTrollButton("🚀 Fling Player", Color3.fromRGB(255, 100, 0), function()
        local target = GetSelectedPlayer()
        if target then
            FlingPlayer(target)
        end
    end)
    
    CreateTrollButton("💀 Kill Player", Color3.fromRGB(200, 0, 0), function()
        local target = GetSelectedPlayer()
        if target then
            KillPlayer(target)
        end
    end)
    
    CreateTrollButton("❄️ Freeze Player", Color3.fromRGB(0, 150, 255), function()
        local target = GetSelectedPlayer()
        if target then
            FreezePlayer(target)
        end
    end)
    
    CreateTrollButton("🔓 Unfreeze Player", Color3.fromRGB(0, 200, 100), function()
        local target = GetSelectedPlayer()
        if target then
            UnfreezePlayer(target)
        end
    end)
    
    CreateTrollButton("🌀 Spin Player", Color3.fromRGB(150, 0, 200), function()
        local target = GetSelectedPlayer()
        if target then
            SpinPlayer(target)
        end
    end)
    
    CreateTrollButton("👻 Make Invisible", Color3.fromRGB(100, 100, 100), function()
        local target = GetSelectedPlayer()
        if target then
            MakePlayerInvisible(target)
        end
    end)
    
    CreateTrollButton("👤 Make Visible", Color3.fromRGB(200, 200, 200), function()
        local target = GetSelectedPlayer()
        if target then
            MakePlayerVisible(target)
        end
    end)
    
    CreateTrollButton("🏃 Teleport Randomly", Color3.fromRGB(255, 150, 0), function()
        local target = GetSelectedPlayer()
        if target then
            TeleportPlayerRandomly(target)
        end
    end)
    
    CreateTrollButton("🦖 Make Giant", Color3.fromRGB(0, 150, 0), function()
        local target = GetSelectedPlayer()
        if target then
            MakePlayerGiant(target)
        end
    end)
    
    CreateTrollButton("🐭 Make Tiny", Color3.fromRGB(0, 100, 200), function()
        local target = GetSelectedPlayer()
        if target then
            MakePlayerTiny(target)
        end
    end)
    
    CreateTrollButton("🔄 Reset Size", Color3.fromRGB(150, 150, 150), function()
        local target = GetSelectedPlayer()
        if target then
            ResetPlayerSize(target)
        end
    end)
    
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -20, 0, 2)
    divider.Position = UDim2.new(0, 10, 0, yOffset)
    divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    divider.BorderSizePixel = 0
    divider.Parent = ContentFrame
    yOffset = yOffset + 10
    
    CreateTrollButton("💥 Kill ALL Players", Color3.fromRGB(255, 0, 0), function()
        ShowNotification("💥 Killed ALL Players", Color3.fromRGB(255, 0, 0))
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                KillPlayer(player)
            end
        end
    end)
    
    CreateTrollButton("🚀 Fling ALL Players", Color3.fromRGB(255, 100, 0), function()
        ShowNotification("🚀 Flung ALL Players", Color3.fromRGB(255, 100, 0))
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                FlingPlayer(player)
            end
        end
    end)
    
    CreateTrollButton("💣 Explode ALL Players", Color3.fromRGB(255, 50, 50), function()
        ShowNotification("💣 Exploded ALL Players", Color3.fromRGB(255, 50, 50))
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                ExplodePlayer(player)
            end
        end
    end)
    
    CreateTrollButton("🌀 Spin ALL Players", Color3.fromRGB(150, 0, 200), function()
        ShowNotification("🌀 Spun ALL Players", Color3.fromRGB(150, 0, 200))
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                SpinPlayer(player)
            end
        end
    end)
    
    CreateTrollButton("👻 Invisible ALL", Color3.fromRGB(100, 100, 100), function()
        ShowNotification("👻 Made ALL Invisible", Color3.fromRGB(100, 100, 100))
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                MakePlayerInvisible(player)
            end
        end
    end)
    
    CreateTrollButton("🔧 Remove ALL Tools", Color3.fromRGB(200, 150, 0), function()
        ShowNotification("🔧 Removed ALL Tools", Color3.fromRGB(200, 150, 0))
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                RemovePlayerTools(player)
            end
        end
    end)
    
    local divider2 = Instance.new("Frame")
    divider2.Size = UDim2.new(1, -20, 0, 2)
    divider2.Position = UDim2.new(0, 10, 0, yOffset)
    divider2.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    divider2.BorderSizePixel = 0
    divider2.Parent = ContentFrame
    yOffset = yOffset + 10
    
    CreateTrollButton("✈️ Toggle Fly (WASD+Space)", Color3.fromRGB(0, 150, 255), function()
        ToggleFly()
    end)
    
    CreateTrollButton("👻 Toggle Noclip", Color3.fromRGB(150, 150, 150), function()
        ToggleNoclip()
    end)
    
    CreateTrollButton("🦘 Toggle Air Jump", Color3.fromRGB(0, 200, 100), function()
        ToggleAirJump()
    end)
    
    CreateTrollButton("🖱️ Toggle Click TP", Color3.fromRGB(255, 100, 150), function()
        ToggleClickTP()
    end)
    
    CreateTrollButton("👁️ Toggle ESP", Color3.fromRGB(255, 255, 0), function()
        ESPEnabled = not ESPEnabled
        ShowNotification("👁️ ESP " .. (ESPEnabled and "Enabled" or "Disabled"), Color3.fromRGB(255, 255, 0))
    end)
    
    local divider3 = Instance.new("Frame")
    divider3.Size = UDim2.new(1, -20, 0, 2)
    divider3.Position = UDim2.new(0, 10, 0, yOffset)
    divider3.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    divider3.BorderSizePixel = 0
    divider3.Parent = ContentFrame
    yOffset = yOffset + 10
    
    CreateTrollButton("📍 Teleport TO Player", Color3.fromRGB(0, 200, 200), function()
        local target = GetSelectedPlayer()
        if target then
            TeleportToPlayer(target)
        end
    end)
    
    local coordLabel = Instance.new("TextLabel")
    coordLabel.Size = UDim2.new(1, -20, 0, 20)
    coordLabel.Position = UDim2.new(0, 10, 0, yOffset)
    coordLabel.BackgroundTransparency = 1
    coordLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    coordLabel.Text = "Teleport to Coords (X,Y,Z):"
    coordLabel.TextSize = 13
    coordLabel.Font = Enum.Font.Gotham
    coordLabel.TextXAlignment = Enum.TextXAlignment.Left
    coordLabel.Parent = ContentFrame
    yOffset = yOffset + 25
    
    local coordInput = Instance.new("TextBox")
    coordInput.Size = UDim2.new(1, -20, 0, 30)
    coordInput.Position = UDim2.new(0, 10, 0, yOffset)
    coordInput.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    coordInput.BorderSizePixel = 0
    coordInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    coordInput.PlaceholderText = "0,50,0"
    coordInput.Text = "0,50,0"
    coordInput.TextSize = 14
    coordInput.Font = Enum.Font.Gotham
    coordInput.Parent = ContentFrame
    yOffset = yOffset + 35
    
    local teleportBtn = Instance.new("TextButton")
    teleportBtn.Size = UDim2.new(1, -20, 0, 35)
    teleportBtn.Position = UDim2.new(0, 10, 0, yOffset)
    teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    teleportBtn.BorderSizePixel = 0
    teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportBtn.Text = "📍 Teleport to Coords"
    teleportBtn.TextSize = 13
    teleportBtn.Font = Enum.Font.Gotham
    teleportBtn.Parent = ContentFrame
    yOffset = yOffset + 40
    
    teleportBtn.MouseButton1Click:Connect(function()
        local coords = coordInput.Text
        local x, y, z = coords:match("([^,]+),([^,]+),([^,]+)")
        if x and y and z then
            TeleportToCoords(tonumber(x), tonumber(y), tonumber(z))
        end
    end)
    
    local divider4 = Instance.new("Frame")
    divider4.Size = UDim2.new(1, -20, 0, 2)
    divider4.Position = UDim2.new(0, 10, 0, yOffset)
    divider4.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    divider4.BorderSizePixel = 0
    divider4.Parent = ContentFrame
    yOffset = yOffset + 10
    
    local toolLabel = Instance.new("TextLabel")
    toolLabel.Size = UDim2.new(1, -20, 0, 20)
    toolLabel.Position = UDim2.new(0, 10, 0, yOffset)
    toolLabel.BackgroundTransparency = 1
    toolLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    toolLabel.Text = "Selection Tool Name:"
    toolLabel.TextSize = 13
    toolLabel.Font = Enum.Font.Gotham
    toolLabel.TextXAlignment = Enum.TextXAlignment.Left
    toolLabel.Parent = ContentFrame
    yOffset = yOffset + 25
    
    local toolInput = Instance.new("TextBox")
    toolInput.Size = UDim2.new(1, -20, 0, 30)
    toolInput.Position = UDim2.new(0, 10, 0, yOffset)
    toolInput.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    toolInput.BorderSizePixel = 0
    toolInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    toolInput.PlaceholderText = "Selector"
    toolInput.Text = "Selector"
    toolInput.TextSize = 14
    toolInput.Font = Enum.Font.Gotham
    toolInput.Parent = ContentFrame
    yOffset = yOffset + 35
    
    local giveToolBtn = Instance.new("TextButton")
    giveToolBtn.Size = UDim2.new(1, -20, 0, 35)
    giveToolBtn.Position = UDim2.new(0, 10, 0, yOffset)
    giveToolBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    giveToolBtn.BorderSizePixel = 0
    giveToolBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    giveToolBtn.Text = "🎯 Give Selection Tool"
    giveToolBtn.TextSize = 13
    giveToolBtn.Font = Enum.Font.Gotham
    giveToolBtn.Parent = ContentFrame
    
    giveToolBtn.MouseButton1Click:Connect(function()
        CreateSelectionTool(toolInput.Text)
        ShowNotification("🎯 Gave selection tool: " .. toolInput.Text, Color3.fromRGB(255, 150, 50))
    end)
    
    return ScreenGui, MainFrame, ContentFrame
end

-- M key toggle for UI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.M then
        UIEnabled = not UIEnabled
        MainFrame.Visible = UIEnabled
    end
end)

-- Handle player joining/leaving for ESP
Players.PlayerAdded:Connect(function(player)
    if ESPEnabled then
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and ESPEnabled then
        CreateESP(player)
    end
end

-- Initialize notification system
CreateNotificationSystem()

-- Main update loop
RunService.RenderStepped:Connect(function()
    UpdateFly()
    UpdateNoclip()
    UpdateAirJump()
    UpdateESP()
end)

-- Initialize
ScreenGui, MainFrame, ContentFrame = CreateUI()

-- Troll script loaded
]]

-- Notification System
local NotificationFrame = nil
local function CreateNotificationSystem()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    
    NotificationFrame = Instance.new("Frame")
    NotificationFrame.Name = "NotificationFrame"
    NotificationFrame.Size = UDim2.new(0, 300, 0, 0)
    NotificationFrame.Position = UDim2.new(1, -320, 1, -20)
    NotificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    NotificationFrame.BorderSizePixel = 0
    NotificationFrame.Parent = screenGui
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = NotificationFrame
    
    return screenGui
end

local function ShowNotification(text, color)
    if not NotificationFrame then return end
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(1, 0, 0, 40)
    notification.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
    notification.BorderSizePixel = 0
    notification.Parent = NotificationFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = notification
    
    NotificationFrame.Size = UDim2.new(0, 300, 0, NotificationFrame.Size.Y.Offset + 45)
    
    -- Fade out and remove
    spawn(function()
        wait(3)
        for i = 1, 10 do
            notification.BackgroundTransparency = i / 10
            label.TextTransparency = i / 10
            wait(0.05)
        end
        notification:Destroy()
        NotificationFrame.Size = UDim2.new(0, 300, 0, NotificationFrame.Size.Y.Offset - 45)
    end)
end

-- Script loaders
local function LoadAimbotESP()
    if AimbotESPLoaded then
        ShowNotification("🎯 Aimbot ESP Already Loaded", Color3.fromRGB(255, 200, 0))
        return
    end
    
    ShowNotification("🎯 Loading Aimbot ESP...", Color3.fromRGB(0, 150, 255))
    
    -- Load the aimbot_esp_enhanced script from embedded code
    local success, err = pcall(function()
        loadstring(AimbotESPCode)()
    end)
    
    if success then
        AimbotESPLoaded = true
        ShowNotification("✅ Aimbot ESP Loaded!", Color3.fromRGB(0, 200, 0))
    else
        ShowNotification("❌ Failed to load Aimbot ESP", Color3.fromRGB(255, 0, 0))
        warn(err)
    end
end

local function LoadTrollScript()
    if TrollScriptLoaded then
        ShowNotification("🎭 Troll Script Already Loaded", Color3.fromRGB(255, 200, 0))
        return
    end
    
    ShowNotification("🎭 Loading Troll Script...", Color3.fromRGB(0, 150, 255))
    
    -- Load the troll_script from embedded code
    local success, err = pcall(function()
        loadstring(TrollScriptCode)()
    end)
    
    if success then
        TrollScriptLoaded = true
        ShowNotification("✅ Troll Script Loaded!", Color3.fromRGB(0, 200, 0))
    else
        ShowNotification("❌ Failed to load Troll Script", Color3.fromRGB(255, 0, 0))
        warn(err)
    end
end

local function LoadInfiniteYield()
    if InfiniteYieldLoaded then
        ShowNotification("♾️ Infinite Yield Already Loaded", Color3.fromRGB(255, 200, 0))
        return
    end
    
    ShowNotification("♾️ Loading Infinite Yield...", Color3.fromRGB(0, 150, 255))
    
    -- Load infinite yield
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
    
    if success then
        InfiniteYieldLoaded = true
        ShowNotification("✅ Infinite Yield Loaded!", Color3.fromRGB(0, 200, 0))
    else
        ShowNotification("❌ Failed to load Infinite Yield", Color3.fromRGB(255, 0, 0))
        warn(err)
    end
end

-- Create UI
local function CreateUI()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Bramdeman111Hub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    
    -- Main Frame
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 300, 0, 350)
    MainFrame.Position = UDim2.new(0, 10, 0, 10)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.new(0, 5, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "🎮 Bramdeman111's Hub"
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -65, 0, 5)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    minimizeBtn.Text = "-"
    minimizeBtn.TextSize = 20
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = titleBar
    
    minimizeBtn.MouseButton1Click:Connect(function()
        UIMinimized = not UIMinimized
        ContentFrame.Visible = not UIMinimized
        minimizeBtn.Text = UIMinimized and "+" or "-"
        minimizeBtn.BackgroundColor3 = UIMinimized and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(255, 200, 0)
        MainFrame.Size = UDim2.new(0, 300, 0, UIMinimized and 40 or 350)
    end)
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -32.5, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "×"
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    closeBtn.MouseButton1Click:Connect(function()
        UIEnabled = false
        MainFrame.Visible = false
    end)
    
    -- Content Frame
    ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, -40)
    ContentFrame.Position = UDim2.new(0, 0, 0, 40)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    -- Helper function to create script buttons
    local yOffset = 10
    local function CreateScriptButton(name, description, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 60)
        btn.Position = UDim2.new(0, 10, 0, yOffset)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = name .. "\n" .. description
        btn.TextSize = 14
        btn.Font = Enum.Font.Gotham
        btn.TextWrapped = true
        btn.Parent = ContentFrame
        
        btn.MouseButton1Click:Connect(callback)
        yOffset = yOffset + 70
        return btn
    end
    
    -- Script Buttons
    CreateScriptButton("🎯 Aimbot ESP", "Aimbot with ESP, FOV Circle, Tracers", Color3.fromRGB(0, 150, 255), function()
        LoadAimbotESP()
    end)
    
    CreateScriptButton("🎭 Troll Script", "Fling, Kill, Freeze, Fly, Noclip, More", Color3.fromRGB(255, 100, 0), function()
        LoadTrollScript()
    end)
    
    CreateScriptButton("♾️ Infinite Yield", "Admin Commands Panel", Color3.fromRGB(150, 0, 200), function()
        LoadInfiniteYield()
    end)
    
    -- Section divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -20, 0, 2)
    divider.Position = UDim2.new(0, 10, 0, yOffset)
    divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    divider.BorderSizePixel = 0
    divider.Parent = ContentFrame
    yOffset = yOffset + 15
    
    -- Load All Button
    local loadAllBtn = Instance.new("TextButton")
    loadAllBtn.Size = UDim2.new(1, -20, 0, 40)
    loadAllBtn.Position = UDim2.new(0, 10, 0, yOffset)
    loadAllBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    loadAllBtn.BorderSizePixel = 0
    loadAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadAllBtn.Text = "🚀 Load All Scripts"
    loadAllBtn.TextSize = 16
    loadAllBtn.Font = Enum.Font.GothamBold
    loadAllBtn.Parent = ContentFrame
    
    loadAllBtn.MouseButton1Click:Connect(function()
        LoadAimbotESP()
        wait(0.5)
        LoadTrollScript()
        wait(0.5)
        LoadInfiniteYield()
    end)
    
    return ScreenGui, MainFrame, ContentFrame
end

-- M key toggle for UI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.M then
        UIEnabled = not UIEnabled
        MainFrame.Visible = UIEnabled
    end
end)

-- Initialize notification system
CreateNotificationSystem()

-- Initialize UI
ScreenGui, MainFrame, ContentFrame = CreateUI()

-- Hub loaded successfully
