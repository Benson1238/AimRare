-- AimRare.lua
-- Lightweight client-side aiming/visuals hub with dark UI

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local settings = {
    aimbot = true,
    teamCheck = true,
    showFov = true,
    fovRadius = 120,
    smoothness = 0.12,
    visuals = true,
}

-- Utility
local function safeParent(gui)
    local ok, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and coreGui then
        gui.Parent = coreGui
    elseif gethui then
        gui.Parent = gethui()
    else
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function newInstance(className, props)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

-- UI creation
local ScreenGui = newInstance("ScreenGui", {
    Name = "AimRareUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
safeParent(ScreenGui)

local container = newInstance("Frame", {
    Parent = ScreenGui,
    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
    BorderSizePixel = 0,
    Size = UDim2.fromOffset(300, 360),
    Position = UDim2.new(0, 16, 0, 100),
})
newInstance("UICorner", { Parent = container, CornerRadius = UDim.new(0, 10) })

local padding = newInstance("UIPadding", {
    Parent = container,
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
    PaddingTop = UDim.new(0, 12),
})

local layout = newInstance("UIListLayout", {
    Parent = container,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
})

local header = newInstance("Frame", {
    Parent = container,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 32),
    LayoutOrder = 0,
})
local title = newInstance("TextLabel", {
    Parent = header,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "AimRare",
    TextSize = 24,
    TextXAlignment = Enum.TextXAlignment.Left,
})
local titleAim = newInstance("TextLabel", {
    Parent = title,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 60, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    Font = Enum.Font.GothamBold,
    Text = "Aim",
    TextColor3 = Color3.fromRGB(0, 0, 0),
    TextSize = 24,
    TextXAlignment = Enum.TextXAlignment.Left,
})
local titleRare = newInstance("TextLabel", {
    Parent = title,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 70, 1, 0),
    Position = UDim2.new(0, 48, 0, 0),
    Font = Enum.Font.GothamBold,
    Text = "Rare",
    TextColor3 = Color3.fromRGB(255, 0, 0),
    TextSize = 24,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local function createSection(name)
    local section = newInstance("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -4, 0, 18),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    section.LayoutOrder = #container:GetChildren()
    return section
end

local function createToggle(name, default, callback)
    local button = newInstance("TextButton", {
        Parent = container,
        BackgroundColor3 = Color3.fromRGB(28, 28, 28),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 32),
        AutoButtonColor = false,
        Text = "",
    })
    newInstance("UICorner", { Parent = button, CornerRadius = UDim.new(0, 8) })

    local label = newInstance("TextLabel", {
        Parent = button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local indicator = newInstance("Frame", {
        Parent = button,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(46, 18),
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        BorderSizePixel = 0,
    })
    newInstance("UICorner", { Parent = indicator, CornerRadius = UDim.new(1, 0) })

    local knob = newInstance("Frame", {
        Parent = indicator,
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Color3.fromRGB(120, 120, 120),
        BorderSizePixel = 0,
    })
    newInstance("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

    local state = default

    local function refresh()
        indicator.BackgroundColor3 = state and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(45, 45, 45)
        knob.Position = state and UDim2.new(1, -18, 0, 0) or UDim2.new(0, 0, 0, 0)
    end

    button.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        callback(state)
    end)

    refresh()
    button.LayoutOrder = #container:GetChildren()
    return {
        Set = function(value)
            state = value
            refresh()
        end,
    }
end

local function createSlider(name, min, max, default, callback)
    local frame = newInstance("Frame", {
        Parent = container,
        BackgroundColor3 = Color3.fromRGB(28, 28, 28),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 46),
    })
    newInstance("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 8) })

    local label = newInstance("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 4),
        Size = UDim2.new(1, -20, 0, 18),
        Font = Enum.Font.Gotham,
        Text = string.format("%s: %d", name, default),
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local bar = newInstance("Frame", {
        Parent = frame,
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 10),
        Position = UDim2.new(0, 10, 0, 26),
    })
    newInstance("UICorner", { Parent = bar, CornerRadius = UDim.new(1, 0) })

    local fill = newInstance("Frame", {
        Parent = bar,
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
    })
    newInstance("UICorner", { Parent = fill, CornerRadius = UDim.new(1, 0) })

    local dragging = false
    local current = default

    local function setValueFromX(x)
        local relative = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        current = math.floor(min + (max - min) * relative + 0.5)
        fill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
        label.Text = string.format("%s: %d", name, current)
        callback(current)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setValueFromX(input.Position.X)
        end
    end)

    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setValueFromX(input.Position.X)
        end
    end)

    frame.LayoutOrder = #container:GetChildren()
    return {
        Set = function(value)
            current = math.clamp(value, min, max)
            fill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
            label.Text = string.format("%s: %d", name, current)
            callback(current)
        end,
    }
end

createSection("Aimbot")
createToggle("Enabled", settings.aimbot, function(state)
    settings.aimbot = state
end)
createToggle("Team Check", settings.teamCheck, function(state)
    settings.teamCheck = state
end)
local fovSlider = createSlider("FOV", 30, 400, settings.fovRadius, function(value)
    settings.fovRadius = value
end)
local smoothSlider = createSlider("Smoothness", 1, 100, math.floor(settings.smoothness * 100), function(value)
    settings.smoothness = value / 100
end)

createSection("Visuals")
createToggle("Show FOV", settings.showFov, function(state)
    settings.showFov = state
end)
createToggle("Highlight Players", settings.visuals, function(state)
    settings.visuals = state
end)

-- FOV circle (Drawing API if available, otherwise Frame)
local fovCircle
if Drawing and Drawing.new then
    fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(255, 0, 0)
    fovCircle.Thickness = 1.5
    fovCircle.Filled = false
    fovCircle.Transparency = 0.9
else
    fovCircle = newInstance("Frame", {
        Parent = ScreenGui,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(settings.fovRadius * 2, settings.fovRadius * 2),
    })
    newInstance("UICorner", { Parent = fovCircle, CornerRadius = UDim.new(1, 0) })
    local stroke = newInstance("UIStroke", {
        Parent = fovCircle,
        Thickness = 1.5,
        Color = Color3.fromRGB(255, 0, 0),
        Transparency = 0.1,
    })
end

-- Visuals: use Highlight objects per character
local activeHighlights = {}

local function clearHighlights()
    for player, highlight in pairs(activeHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
        activeHighlights[player] = nil
    end
end

local function applyHighlight(player)
    if not settings.visuals then
        return
    end
    if player == LocalPlayer then
        return
    end
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    local highlight = activeHighlights[player]
    if not highlight or not highlight.Parent then
        highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.8
        highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
        highlight.OutlineTransparency = 0.4
        highlight.Adornee = character
        highlight.Parent = character
        activeHighlights[player] = highlight
    else
        highlight.Adornee = character
    end
end

Players.PlayerRemoving:Connect(function(player)
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
        activeHighlights[player] = nil
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        applyHighlight(player)
    end)
end)

-- Target selection
local function isAlive(player)
    local character = player.Character
    if not character then
        return false
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getMousePosition()
    local pos = UserInputService:GetMouseLocation()
    return Vector2.new(pos.X, pos.Y)
end

local function worldToViewport(point)
    local screenPoint, onScreen = Camera:WorldToViewportPoint(point)
    return Vector2.new(screenPoint.X, screenPoint.Y), onScreen
end

local function isSameTeam(player)
    if settings.teamCheck then
        return player.Team == LocalPlayer.Team
    end
    return false
end

local function getClosestTarget()
    local closestPlayer
    local shortestDistance = settings.fovRadius
    local mousePos = getMousePosition()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) and not isSameTeam(player) then
            local character = player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local screenPos, onScreen = worldToViewport(hrp.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distance <= shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer
end

local currentTarget

local function updateFovCircle()
    if not fovCircle then
        return
    end

    local mousePos = getMousePosition()
    if fovCircle.Radius then -- Drawing object
        fovCircle.Visible = settings.showFov
        fovCircle.Radius = settings.fovRadius
        fovCircle.Position = mousePos
    else
        fovCircle.Visible = settings.showFov
        fovCircle.Size = UDim2.fromOffset(settings.fovRadius * 2, settings.fovRadius * 2)
        fovCircle.Position = UDim2.fromOffset(mousePos.X - settings.fovRadius, mousePos.Y - settings.fovRadius)
    end
end

local function aimAt(target)
    if not target then
        return
    end
    local character = target.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end
    local direction = (hrp.Position - Camera.CFrame.Position).Unit
    local desired = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)
    local lerped = Camera.CFrame:Lerp(desired, settings.smoothness)
    Camera.CFrame = lerped
end

RunService.RenderStepped:Connect(function()
    updateFovCircle()
    if settings.visuals then
        for _, player in ipairs(Players:GetPlayers()) do
            applyHighlight(player)
        end
    else
        clearHighlights()
    end

    if not settings.aimbot then
        currentTarget = nil
        return
    end

    currentTarget = getClosestTarget()
    if currentTarget then
        aimAt(currentTarget)
    end
end)

-- UI drag
local dragging = false
local dragStart
local startPos

container.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = container.Position
    end
end)

container.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Simple performance heartbeat guard
RunService.Stepped:Connect(function()
    if not LocalPlayer or not LocalPlayer.Character then
        clearHighlights()
    end
end)

print("AimRare loaded :: Dark UI, smooth assist, optimized")
