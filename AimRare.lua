-- AimRare.lua
-- Lightweight client-side aiming/visuals hub with dark UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Configuration
local settings = {
    aimbot = true,
    teamCheck = true,
    showFov = true,
    fovRadius = 120,
    smoothness = 0.12,
    visuals = true,
}

local ConfigManager = {}
ConfigManager.values = settings
ConfigManager._bindings = {}
ConfigManager._changed = Instance.new("BindableEvent")

function ConfigManager:Update(key, value)
    if self.values[key] == value then
        return
    end
    self.values[key] = value
    if self._bindings[key] then
        for _, callback in ipairs(self._bindings[key]) do
            callback(value)
        end
    end
    self._changed:Fire(key, value)
end

function ConfigManager:Bind(key, callback)
    self._bindings[key] = self._bindings[key] or {}
    table.insert(self._bindings[key], callback)
end

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

local UIComponentFactory = {}

local function bindLayoutOrder(object)
    object.LayoutOrder = #container:GetChildren()
end

function UIComponentFactory.create(def)
    if def.type == "toggle" then
        local button = newInstance("TextButton", {
            Parent = container,
            BackgroundColor3 = Color3.fromRGB(28, 28, 28),
            BorderSizePixel = 0,
            Size = UDim2.new(1, -4, 0, 32),
            AutoButtonColor = false,
            Text = "",
        })
        newInstance("UICorner", { Parent = button, CornerRadius = UDim.new(0, 8) })

        newInstance("TextLabel", {
            Parent = button,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -80, 1, 0),
            Font = Enum.Font.Gotham,
            Text = def.name,
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

        local state = def.default

        local function refresh()
            indicator.BackgroundColor3 = state and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(45, 45, 45)
            knob.Position = state and UDim2.new(1, -18, 0, 0) or UDim2.new(0, 0, 0, 0)
        end

        button.MouseButton1Click:Connect(function()
            state = not state
            refresh()
            if def.bindKey then
                ConfigManager:Update(def.bindKey, state)
            end
            if def.callback then
                def.callback(state)
            end
        end)

        refresh()
        bindLayoutOrder(button)
        return button
    elseif def.type == "slider" then
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
            Text = string.format("%s: %d", def.name, def.default),
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
            Size = UDim2.new((def.default - def.min) / (def.max - def.min), 0, 1, 0),
        })
        newInstance("UICorner", { Parent = fill, CornerRadius = UDim.new(1, 0) })

        local dragging = false
        local current = def.default

        local function setValueFromX(x)
            local relative = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            current = math.floor(def.min + (def.max - def.min) * relative + 0.5)
            fill.Size = UDim2.new((current - def.min) / (def.max - def.min), 0, 1, 0)
            label.Text = string.format("%s: %d", def.name, current)
            if def.bindKey then
                ConfigManager:Update(def.bindKey, def.transform and def.transform(current) or current)
            end
            if def.callback then
                def.callback(current)
            end
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

        bindLayoutOrder(frame)
        return frame
    end
end

local function createComponent(def)
    return UIComponentFactory.create(def)
end

createSection("Aimbot")
createComponent({ type = "toggle", name = "Enabled", default = settings.aimbot, bindKey = "aimbot" })
createComponent({ type = "toggle", name = "Team Check", default = settings.teamCheck, bindKey = "teamCheck" })
createComponent({ type = "slider", name = "FOV", min = 30, max = 400, default = settings.fovRadius, bindKey = "fovRadius" })
createComponent({
    type = "slider",
    name = "Smoothness",
    min = 1,
    max = 100,
    default = math.floor(settings.smoothness * 100),
    bindKey = "smoothness",
    transform = function(value)
        return value / 100
    end,
})

createSection("Visuals")
createComponent({ type = "toggle", name = "Show FOV", default = settings.showFov, bindKey = "showFov" })
createComponent({ type = "toggle", name = "Highlight Players", default = settings.visuals, bindKey = "visuals" })

ConfigManager:Bind("visuals", function(enabled)
    if not enabled then
        clearHighlights()
    end
end)

ConfigManager:Bind("showFov", function()
    updateFovCircle()
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

-- Visuals: use Highlight objects per character with pooling
local activeHighlights = {}
local highlightPool = {}

local function acquireHighlight()
    local highlight = table.remove(highlightPool)
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.8
        highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
        highlight.OutlineTransparency = 0.4
    end
    highlight.Enabled = true
    return highlight
end

local function releaseHighlight(player)
    local highlight = activeHighlights[player]
    if highlight then
        highlight.Enabled = false
        highlight.Adornee = nil
        highlight.Parent = nil
        table.insert(highlightPool, highlight)
        activeHighlights[player] = nil
    end
end

local function clearHighlights()
    for player in pairs(activeHighlights) do
        releaseHighlight(player)
    end
end

local function applyHighlight(player)
    if not settings.visuals or player == LocalPlayer then
        return
    end
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    local highlight = activeHighlights[player]
    if not highlight then
        highlight = acquireHighlight()
        activeHighlights[player] = highlight
    end
    highlight.Adornee = character
    highlight.Parent = character
end

Players.PlayerRemoving:Connect(function(player)
    releaseHighlight(player)
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

local function getSafeScreenCenter()
    local insetTopLeft, insetBottomRight = GuiService:GetGuiInset()
    local viewport = Camera.ViewportSize
    local safeSize = viewport - insetTopLeft - insetBottomRight
    return insetTopLeft + safeSize / 2
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

local function isVisible(hrp, character)
    local origin = Camera.CFrame.Position
    local direction = hrp.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    local result = Workspace:Raycast(origin, direction, params)
    if not result then
        return true
    end
    return result.Instance:IsDescendantOf(character)
end

local function getClosestTarget()
    local closestPlayer
    local bestScore = math.huge
    local screenCenter = getSafeScreenCenter()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Parent == Players and isAlive(player) and not isSameTeam(player) then
            local character = player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid then
                local screenPos, onScreen = worldToViewport(hrp.Position)
                if onScreen then
                    local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if screenDistance <= settings.fovRadius and isVisible(hrp, character) then
                        local worldDistance = (hrp.Position - Camera.CFrame.Position).Magnitude
                        local healthFactor = math.max(humanoid.Health, 1) / math.max(humanoid.MaxHealth, 1)
                        local proximityScore = worldDistance * 0.1
                        local blendedScore = (screenDistance * (1 + healthFactor)) + proximityScore
                        if blendedScore < bestScore then
                            bestScore = blendedScore
                            closestPlayer = player
                        end
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

    local screenCenter = getSafeScreenCenter()
    if fovCircle.Radius then -- Drawing object
        fovCircle.Visible = settings.showFov
        fovCircle.Radius = settings.fovRadius
        fovCircle.Position = screenCenter
    else
        fovCircle.Visible = settings.showFov
        fovCircle.Size = UDim2.fromOffset(settings.fovRadius * 2, settings.fovRadius * 2)
        fovCircle.Position = UDim2.fromOffset(screenCenter.X - settings.fovRadius, screenCenter.Y - settings.fovRadius)
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
    local cameraCFrame = Camera.CFrame
    local direction = (hrp.Position - cameraCFrame.Position).Unit
    local currentLook = cameraCFrame.LookVector

    local function toAngles(vec)
        local yaw = math.atan2(vec.X, vec.Z)
        local pitch = math.asin(math.clamp(vec.Y, -1, 1))
        return yaw, pitch
    end

    local function deltaAngle(targetAngle, currentAngle)
        local diff = targetAngle - currentAngle
        while diff > math.pi do
            diff = diff - (2 * math.pi)
        end
        while diff < -math.pi do
            diff = diff + (2 * math.pi)
        end
        return diff
    end

    local targetYaw, targetPitch = toAngles(direction)
    local currentYaw, currentPitch = toAngles(currentLook)

    local deltaYaw = deltaAngle(targetYaw, currentYaw)
    local deltaPitch = deltaAngle(targetPitch, currentPitch)
    local angleMagnitude = math.sqrt(deltaYaw ^ 2 + deltaPitch ^ 2)
    local distance = (hrp.Position - cameraCFrame.Position).Magnitude

    local angleFactor = math.clamp(angleMagnitude / math.pi, 0, 1)
    local distanceFactor = math.clamp(distance / 500, 0, 1)
    local adaptiveSmoothness = math.clamp(settings.smoothness + ((angleFactor + distanceFactor) / 2) * (1 - settings.smoothness), 0, 1)

    local newYaw = currentYaw + deltaYaw * adaptiveSmoothness
    local newPitch = currentPitch + deltaPitch * adaptiveSmoothness
    local newCFrame = CFrame.new(cameraCFrame.Position) * CFrame.fromOrientation(newPitch, newYaw, 0)
    Camera.CFrame = newCFrame
end

local lastVisualUpdate = 0

local function updateVisuals(dt)
    updateFovCircle()
    if time() - lastVisualUpdate < 0.1 then
        return
    end
    lastVisualUpdate = time()

    if settings.visuals then
        for _, player in ipairs(Players:GetPlayers()) do
            applyHighlight(player)
        end
    else
        clearHighlights()
    end
end

local function executeAimbot()
    if not settings.aimbot then
        currentTarget = nil
        return
    end

    currentTarget = getClosestTarget()
    if currentTarget then
        aimAt(currentTarget)
    end
end

RunService.Heartbeat:Connect(updateVisuals)
RunService.RenderStepped:Connect(executeAimbot)

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
