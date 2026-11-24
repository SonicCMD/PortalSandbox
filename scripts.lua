if game and game.IsLoaded and not game:IsLoaded() then
	game.Loaded:Wait()
end

local clockNow = (os and type(os.clock) == "function") and os.clock or tick
local task = task or {
	wait = wait,
	spawn = function(fn, ...)
		return spawn(fn, ...)
	end,
	delay = delay,
	defer = function(fn, ...)
		return spawn(fn, ...)
	end,
}

local hasCloneRef = (type(cloneref) == "function")
local function getServiceSafe(serviceName)
	local svc = game:GetService(serviceName)
	if hasCloneRef then
		local ok, ref = pcall(cloneref, svc)
		if ok and ref then
			return ref
		end
	end
	return svc
end

local Players = getServiceSafe("Players")
local TweenService = getServiceSafe("TweenService")
local UserInputService = getServiceSafe("UserInputService")
local GuiService = getServiceSafe("GuiService")
local RunService = getServiceSafe("RunService")
local ReplicatedStorage = getServiceSafe("ReplicatedStorage")
local CollectionService = getServiceSafe("CollectionService")
local Workspace = getServiceSafe("Workspace")

local IS_STUDIO_ENV = RunService:IsStudio()
local EXECUTOR_NAME = IS_STUDIO_ENV and "Roblox Studio" or "Roblox Client"
if not IS_STUDIO_ENV then
	local idFn = (type(identifyexecutor) == "function" and identifyexecutor)
		or (type(getexecutorname) == "function" and getexecutorname)
		or nil
	if idFn then
		local ok, res = pcall(idFn)
		if ok and type(res) == "string" and res ~= "" then
			EXECUTOR_NAME = res
		end
	end
end

local envTable = _G
if type(getgenv) == "function" then
	local ok, g = pcall(getgenv)
	if ok and type(g) == "table" then
		envTable = g
	end
end

if type(envTable._ShadowMenuCleanup) == "function" then
	pcall(envTable._ShadowMenuCleanup)
	envTable._ShadowMenuCleanup = nil
end

local localPlayer = Players.LocalPlayer
if not localPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	localPlayer = Players.LocalPlayer
end

local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 15)
if not playerGui then
	warn("[ShadowMenu] Không tìm thấy PlayerGui.")
	return
end

local hasGethui = (type(gethui) == "function")
local function resolveGuiParent()
	if hasGethui then
		local ok, hui = pcall(gethui)
		if ok and typeof(hui) == "Instance" then
			return hui
		end
	end
	return playerGui
end

local GUI_NAME = "ShadowMenuGui"
local guiTargetParent = resolveGuiParent()
local oldInTarget = guiTargetParent:FindFirstChild(GUI_NAME)
if oldInTarget then
	oldInTarget:Destroy()
end
local oldInPlayerGui = playerGui:FindFirstChild(GUI_NAME)
if oldInPlayerGui then
	oldInPlayerGui:Destroy()
end

local THEME = {
	BgMain = Color3.fromRGB(13, 14, 18),
	BgHeader = Color3.fromRGB(18, 20, 25),
	BgSidebar = Color3.fromRGB(17, 19, 24),
	BgCard = Color3.fromRGB(24, 27, 34),
	BgCardHover = Color3.fromRGB(32, 36, 46),
	BgInput = Color3.fromRGB(16, 18, 23),
	Border = Color3.fromRGB(52, 57, 68),
	BorderBright = Color3.fromRGB(218, 224, 236),
	Accent = Color3.fromRGB(242, 245, 250),
	AccentDim = Color3.fromRGB(165, 173, 188),
	AccentDarkText = Color3.fromRGB(14, 16, 20),
	TextPrimary = Color3.fromRGB(242, 244, 248),
	TextSecondary = Color3.fromRGB(154, 162, 178),
	TextMuted = Color3.fromRGB(108, 115, 130),
	ToggleOff = Color3.fromRGB(48, 53, 64),
	ToggleOn = Color3.fromRGB(238, 242, 248),
	Success = Color3.fromRGB(82, 196, 128),
}

local CONFIG = {
	Title = "SHADOW MENU",
	Subtitle = string.upper(EXECUTOR_NAME) .. " • " .. (UserInputService.TouchEnabled and "MOBILE" or "PC"),
	LogoAssetId = "",
	ToggleKey = Enum.KeyCode.RightControl,
	WideWidth = 540,
	WideHeight = 360,
	CompactWidth = 340,
	CompactHeight = 430,
	HeaderHeight = 44,
	SidebarWidth = 148,
	TopTabBarHeight = 42,
}

local connections = {}
local function track(conn)
	table.insert(connections, conn)
	return conn
end

local function disconnectSafe(conn)
	if conn and conn.Connected then
		conn:Disconnect()
	end
end

local function tween(obj, duration, props)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function addPadding(parent, top, right, bottom, left)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, top)
	p.PaddingRight = UDim.new(0, right)
	p.PaddingBottom = UDim.new(0, bottom)
	p.PaddingLeft = UDim.new(0, left)
	p.Parent = parent
	return p
end

local function isDragInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMoveInput(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function getSafeViewport()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.zero
	local topLeftInset, bottomRightInset = GuiService:GetGuiInset()
	return vp, math.max(topLeftInset.Y, 0), math.max(bottomRightInset.Y, 0)
end

local function createNinjaEmblem(parent, sizePx, logoAssetId, layoutOrder)
	local holder = Instance.new("Frame")
	holder.Name = "NinjaEmblem"
	if layoutOrder then
		holder.LayoutOrder = layoutOrder
	end
	holder.Size = UDim2.fromOffset(sizePx, sizePx)
	holder.BackgroundColor3 = Color3.fromRGB(240, 242, 246)
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = true
	holder.Parent = parent
	addCorner(holder, math.floor(sizePx * 0.28))

	if logoAssetId ~= "" then
		local img = Instance.new("ImageLabel")
		img.Name = "CustomLogo"
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.Image = logoAssetId
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = holder
		return holder
	end

	local bladeW = math.max(3, math.floor(sizePx * 0.14))
	local bladeH = math.floor(sizePx * 0.88)
	for _, rot in ipairs({ 44, -44 }) do
		local blade = Instance.new("Frame")
		blade.Size = UDim2.fromOffset(bladeW, bladeH)
		blade.Position = UDim2.fromScale(0.5, 0.5)
		blade.AnchorPoint = Vector2.new(0.5, 0.5)
		blade.Rotation = rot
		blade.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
		blade.BorderSizePixel = 0
		blade.Parent = holder
		addCorner(blade, 2)
	end

	local hood = Instance.new("Frame")
	hood.Size = UDim2.fromScale(0.66, 0.66)
	hood.Position = UDim2.fromScale(0.5, 0.53)
	hood.AnchorPoint = Vector2.new(0.5, 0.5)
	hood.BackgroundColor3 = Color3.fromRGB(14, 16, 20)
	hood.BorderSizePixel = 0
	hood.ZIndex = 2
	hood.Parent = holder
	addCorner(hood, math.floor(sizePx * 0.33))
	addStroke(hood, Color3.fromRGB(245, 247, 250), 1.5, 0)

	local visor = Instance.new("Frame")
	visor.Size = UDim2.fromScale(0.72, 0.28)
	visor.Position = UDim2.fromScale(0.5, 0.44)
	visor.AnchorPoint = Vector2.new(0.5, 0.5)
	visor.BackgroundColor3 = Color3.fromRGB(38, 42, 52)
	visor.BorderSizePixel = 0
	visor.ZIndex = 3
	visor.Parent = hood
	addCorner(visor, 4)

	for _, eyeCfg in ipairs({ { x = 0.27, rot = 14 }, { x = 0.73, rot = -14 } }) do
		local eye = Instance.new("Frame")
		eye.Size = UDim2.fromScale(0.28, 0.48)
		eye.Position = UDim2.fromScale(eyeCfg.x, 0.52)
		eye.AnchorPoint = Vector2.new(0.5, 0.5)
		eye.Rotation = eyeCfg.rot
		eye.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		eye.BorderSizePixel = 0
		eye.ZIndex = 4
		eye.Parent = visor
		addCorner(eye, 3)
	end

	return holder
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 9999
screenGui.IgnoreGuiInset = true
pcall(function()
	screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end)
local okParent = pcall(function()
	screenGui.Parent = guiTargetParent
end)
if not okParent or not screenGui.Parent then
	screenGui.Parent = playerGui
end

local destroyed = false
local onDestroyCallbacks = {}
local function onMenuDestroy(fn)
	table.insert(onDestroyCallbacks, fn)
end

local function cleanupMenuInstance()
	if not destroyed then
		destroyed = true
		for _, fn in ipairs(onDestroyCallbacks) do
			pcall(fn)
		end
		for _, conn in ipairs(connections) do
			disconnectSafe(conn)
		end
		connections = {}
		onDestroyCallbacks = {}
	end
	if envTable._ShadowMenuCleanup == cleanupMenuInstance then
		envTable._ShadowMenuCleanup = nil
	end
	if screenGui and screenGui.Parent then
		screenGui:Destroy()
	end
end

envTable._ShadowMenuCleanup = cleanupMenuInstance
screenGui.Destroying:Connect(cleanupMenuInstance)

local floatSize = UserInputService.TouchEnabled and 48 or 44
local floatButton = Instance.new("TextButton")
floatButton.Name = "FloatingToggle"
floatButton.Size = UDim2.fromOffset(floatSize, floatSize)
floatButton.Position = UDim2.fromOffset(16, 100)
floatButton.BackgroundColor3 = THEME.BgMain
floatButton.Text = ""
floatButton.AutoButtonColor = false
floatButton.ZIndex = 50
floatButton.Parent = screenGui
addCorner(floatButton, 14)
local floatStroke = addStroke(floatButton, THEME.BorderBright, 1.5, 0.12)

local emblemInFloat = createNinjaEmblem(floatButton, floatSize - 10, CONFIG.LogoAssetId)
emblemInFloat.Position = UDim2.fromScale(0.5, 0.5)
emblemInFloat.AnchorPoint = Vector2.new(0.5, 0.5)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(CONFIG.WideWidth, CONFIG.WideHeight)
mainFrame.Position = UDim2.fromOffset(100, 100)
mainFrame.BackgroundColor3 = THEME.BgMain
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Visible = true
mainFrame.ZIndex = 10
mainFrame.Parent = screenGui
addCorner(mainFrame, 12)
addStroke(mainFrame, THEME.Border, 1.25, 0)

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1
uiScale.Parent = mainFrame

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, CONFIG.HeaderHeight)
header.BackgroundColor3 = THEME.BgHeader
header.BorderSizePixel = 0
header.ZIndex = 12
header.Parent = mainFrame

local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, 0, 0, 1)
headerLine.Position = UDim2.new(0, 0, 1, -1)
headerLine.BackgroundColor3 = THEME.Border
headerLine.BorderSizePixel = 0
headerLine.Parent = header

local headerLeft = Instance.new("Frame")
headerLeft.Size = UDim2.new(1, -104, 1, 0)
headerLeft.Position = UDim2.fromOffset(12, 0)
headerLeft.BackgroundTransparency = 1
headerLeft.Parent = header

local headerLayout = Instance.new("UIListLayout")
headerLayout.FillDirection = Enum.FillDirection.Horizontal
headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
headerLayout.Padding = UDim.new(0, 10)
headerLayout.Parent = headerLeft

createNinjaEmblem(headerLeft, 28, CONFIG.LogoAssetId, 1)

local titleBox = Instance.new("Frame")
titleBox.Name = "TitleBox"
titleBox.LayoutOrder = 2
titleBox.Size = UDim2.new(1, -40, 1, 0)
titleBox.BackgroundTransparency = 1
titleBox.Parent = headerLeft

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 18)
titleLabel.Position = UDim2.fromOffset(0, 6)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = CONFIG.Title
titleLabel.TextColor3 = THEME.TextPrimary
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
titleLabel.Parent = titleBox

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(1, 0, 0, 14)
subLabel.Position = UDim2.fromOffset(0, 24)
subLabel.BackgroundTransparency = 1
subLabel.Font = Enum.Font.GothamMedium
subLabel.Text = CONFIG.Subtitle
subLabel.TextColor3 = THEME.TextMuted
subLabel.TextSize = 10
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.TextTruncate = Enum.TextTruncate.AtEnd
subLabel.Parent = titleBox

local headerControls = Instance.new("Frame")
headerControls.Size = UDim2.fromOffset(88, CONFIG.HeaderHeight)
headerControls.Position = UDim2.new(1, -96, 0, 0)
headerControls.BackgroundTransparency = 1
headerControls.Parent = header

local ctrlLayout = Instance.new("UIListLayout")
ctrlLayout.FillDirection = Enum.FillDirection.Horizontal
ctrlLayout.SortOrder = Enum.SortOrder.LayoutOrder
ctrlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ctrlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ctrlLayout.Padding = UDim.new(0, 6)
ctrlLayout.Parent = headerControls

local function makeHeaderBtn(name, text, orderIdx)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.LayoutOrder = orderIdx
	btn.Size = UDim2.fromOffset(36, 30)
	btn.BackgroundColor3 = THEME.BgCard
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.TextColor3 = THEME.TextPrimary
	btn.TextSize = 15
	btn.AutoButtonColor = false
	btn.Parent = headerControls
	addCorner(btn, 8)
	addStroke(btn, THEME.Border, 1, 0.2)
	return btn
end

local minimizeBtn = makeHeaderBtn("MinimizeBtn", "–", 1)
local closeBtn = makeHeaderBtn("CloseBtn", "×", 2)

local bodyContainer = Instance.new("Frame")
bodyContainer.Name = "BodyContainer"
bodyContainer.Size = UDim2.new(1, 0, 1, -CONFIG.HeaderHeight)
bodyContainer.Position = UDim2.fromOffset(0, CONFIG.HeaderHeight)
bodyContainer.BackgroundTransparency = 1
bodyContainer.Parent = mainFrame

local tabBar = Instance.new("ScrollingFrame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(0, CONFIG.SidebarWidth, 1, 0)
tabBar.BackgroundColor3 = THEME.BgSidebar
tabBar.BorderSizePixel = 0
tabBar.ScrollBarThickness = 2
tabBar.ScrollBarImageColor3 = THEME.BorderBright
tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabBar.ScrollingDirection = Enum.ScrollingDirection.Y
tabBar.Parent = bodyContainer

local tabPadding = addPadding(tabBar, 10, 8, 10, 8)

local tabListLayout = Instance.new("UIListLayout")
tabListLayout.FillDirection = Enum.FillDirection.Vertical
tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabListLayout.Padding = UDim.new(0, 6)
tabListLayout.Parent = tabBar

local tabDivider = Instance.new("Frame")
tabDivider.Name = "TabDivider"
tabDivider.Size = UDim2.new(0, 1, 1, 0)
tabDivider.Position = UDim2.fromOffset(CONFIG.SidebarWidth - 1, 0)
tabDivider.BackgroundColor3 = THEME.Border
tabDivider.BorderSizePixel = 0
tabDivider.ZIndex = 12
tabDivider.Parent = bodyContainer

local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -CONFIG.SidebarWidth, 1, 0)
contentArea.Position = UDim2.fromOffset(CONFIG.SidebarWidth, 0)
contentArea.BackgroundTransparency = 1
contentArea.ClipsDescendants = true
contentArea.Parent = bodyContainer

local notifyHolder = Instance.new("Frame")
notifyHolder.Name = "Notifications"
notifyHolder.Size = UDim2.fromOffset(270, 240)
notifyHolder.Position = UDim2.new(1, -16, 1, -16)
notifyHolder.AnchorPoint = Vector2.new(1, 1)
notifyHolder.BackgroundTransparency = 1
notifyHolder.ZIndex = 80
notifyHolder.Parent = screenGui

local notifyLayout = Instance.new("UIListLayout")
notifyLayout.FillDirection = Enum.FillDirection.Vertical
notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifyLayout.Padding = UDim.new(0, 8)
notifyLayout.Parent = notifyHolder

local isCompactMode = false
local isMenuOpen = true
local isMinimized = false
local hasInitializedPosition = false
local currentBaseW = CONFIG.WideWidth
local currentBaseH = CONFIG.WideHeight
local activeTabData = nil

local function getActualFrameSize()
	local s = uiScale.Scale
	local h = isMinimized and CONFIG.HeaderHeight or currentBaseH
	return currentBaseW * s, h * s
end

local function clampPosition(rawX, rawY, widthPx, heightPx)
	local vp, topInset, bottomInset = getSafeViewport()
	local pad = 8
	local maxX = math.max(pad, vp.X - widthPx - pad)
	local minY = topInset + pad
	local maxY = math.max(minY, vp.Y - bottomInset - heightPx - pad)
	return math.clamp(rawX, pad, maxX), math.clamp(rawY, minY, maxY)
end

local function applyResponsiveLayout()
	local vp, topInset, bottomInset = getSafeViewport()
	if vp.X < 100 or vp.Y < 100 then
		return
	end

	local compact = (vp.X < 560) or (vp.Y > vp.X * 1.05)
	isCompactMode = compact

	local usableW = math.max(260, vp.X - 24)
	local usableH = math.max(220, vp.Y - topInset - bottomInset - 20)

	if compact then
		currentBaseW = CONFIG.CompactWidth
		currentBaseH = math.clamp(math.floor(usableH * 0.72), 340, CONFIG.CompactHeight)
		local fitScale = math.min(usableW / currentBaseW, usableH / currentBaseH, 1.05)
		uiScale.Scale = math.clamp(fitScale, 0.74, 1.25)

		tabBar.Size = UDim2.new(1, 0, 0, CONFIG.TopTabBarHeight)
		tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
		tabBar.ScrollingDirection = Enum.ScrollingDirection.X
		tabPadding.PaddingTop = UDim.new(0, 5)
		tabPadding.PaddingBottom = UDim.new(0, 5)
		tabListLayout.FillDirection = Enum.FillDirection.Horizontal
		tabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

		tabDivider.Size = UDim2.new(1, 0, 0, 1)
		tabDivider.Position = UDim2.fromOffset(0, CONFIG.TopTabBarHeight - 1)
		contentArea.Size = UDim2.new(1, 0, 1, -CONFIG.TopTabBarHeight)
		contentArea.Position = UDim2.fromOffset(0, CONFIG.TopTabBarHeight)

		notifyHolder.Position = UDim2.new(0.5, 0, 0, topInset + 10)
		notifyHolder.AnchorPoint = Vector2.new(0.5, 0)
		notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	else
		currentBaseW = CONFIG.WideWidth
		currentBaseH = CONFIG.WideHeight
		local fitScale = math.min(usableW / currentBaseW, usableH / currentBaseH, 1.0)
		uiScale.Scale = math.clamp(fitScale, 0.72, 1.25)

		tabBar.Size = UDim2.new(0, CONFIG.SidebarWidth, 1, 0)
		tabBar.AutomaticCanvasSize = Enum.AutomaticSize.Y
		tabBar.ScrollingDirection = Enum.ScrollingDirection.Y
		tabPadding.PaddingTop = UDim.new(0, 10)
		tabPadding.PaddingBottom = UDim.new(0, 10)
		tabListLayout.FillDirection = Enum.FillDirection.Vertical
		tabListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

		tabDivider.Size = UDim2.new(0, 1, 1, 0)
		tabDivider.Position = UDim2.fromOffset(CONFIG.SidebarWidth - 1, 0)
		contentArea.Size = UDim2.new(1, -CONFIG.SidebarWidth, 1, 0)
		contentArea.Position = UDim2.fromOffset(CONFIG.SidebarWidth, 0)

		notifyHolder.Position = UDim2.new(1, -16, 1, -16)
		notifyHolder.AnchorPoint = Vector2.new(1, 1)
		notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	end

	for _, child in ipairs(tabBar:GetChildren()) do
		if child:IsA("TextButton") then
			if compact then
				child.AutomaticSize = Enum.AutomaticSize.X
				child.Size = UDim2.fromOffset(0, 30)
				child.TextSize = 12
				child.TextXAlignment = Enum.TextXAlignment.Center
			else
				child.AutomaticSize = Enum.AutomaticSize.None
				child.Size = UDim2.new(1, 0, 0, 38)
				child.TextSize = 13
				child.TextXAlignment = Enum.TextXAlignment.Left
			end
		end
	end

	if activeTabData then
		activeTabData.Indicator.Visible = not compact
	end

	local targetH = isMinimized and CONFIG.HeaderHeight or currentBaseH
	mainFrame.Size = UDim2.fromOffset(currentBaseW, targetH)
	bodyContainer.Visible = not isMinimized

	local actualW, actualH = getActualFrameSize()
	if not hasInitializedPosition then
		hasInitializedPosition = true
		local startX = math.floor((vp.X - actualW) * 0.5)
		local startY = math.floor(math.max(topInset + 10, (vp.Y - actualH) * 0.5))
		local cx, cy = clampPosition(startX, startY, actualW, actualH)
		mainFrame.Position = UDim2.fromOffset(cx, cy)

		local fx, fy = clampPosition(16, topInset + 14, floatSize, floatSize)
		floatButton.Position = UDim2.fromOffset(fx, fy)
	else
		local cx, cy = clampPosition(mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset, actualW, actualH)
		mainFrame.Position = UDim2.fromOffset(cx, cy)

		local fx, fy = clampPosition(floatButton.Position.X.Offset, floatButton.Position.Y.Offset, floatSize, floatSize)
		floatButton.Position = UDim2.fromOffset(fx, fy)
	end
end

local cameraConn = nil
local function hookCameraViewport()
	disconnectSafe(cameraConn)
	local cam = Workspace.CurrentCamera
	if cam then
		cameraConn = track(cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout))
	end
	applyResponsiveLayout()
end

track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCameraViewport))
hookCameraViewport()
task.defer(applyResponsiveLayout)

local function setupDraggable(dragHandle, targetObj, getSizeFn, onTap)
	local activeInput = nil
	local dragStartMouse = Vector2.zero
	local dragStartPos = Vector2.zero
	local movedDistance = 0

	track(dragHandle.InputBegan:Connect(function(input)
		if activeInput or not isDragInput(input) then
			return
		end
		activeInput = input
		dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
		dragStartPos = Vector2.new(targetObj.Position.X.Offset, targetObj.Position.Y.Offset)
		movedDistance = 0
	end))

	track(UserInputService.InputChanged:Connect(function(input)
		if not activeInput or not isMoveInput(input) then
			return
		end
		if activeInput.UserInputType == Enum.UserInputType.Touch and input ~= activeInput then
			return
		end
		local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartMouse
		movedDistance = math.max(movedDistance, delta.Magnitude)
		local w, h = getSizeFn()
		local cx, cy = clampPosition(dragStartPos.X + delta.X, dragStartPos.Y + delta.Y, w, h)
		targetObj.Position = UDim2.fromOffset(cx, cy)
	end))

	track(UserInputService.InputEnded:Connect(function(input)
		if not activeInput then
			return
		end
		if input == activeInput or (activeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
			local wasTap = movedDistance <= 8
			activeInput = nil
			if wasTap and onTap then
				onTap()
			end
		end
	end))
end

local menuToggleSerial = 0
local function setMenuOpen(open)
	isMenuOpen = open
	menuToggleSerial = menuToggleSerial + 1
	local serial = menuToggleSerial

	if open then
		mainFrame.Visible = true
		applyResponsiveLayout()
		local targetH = isMinimized and CONFIG.HeaderHeight or currentBaseH
		mainFrame.Size = UDim2.fromOffset(currentBaseW, math.max(20, targetH - 18))
		tween(mainFrame, 0.18, { Size = UDim2.fromOffset(currentBaseW, targetH) })
		tween(floatStroke, 0.18, { Transparency = 0.05 })
	else
		local t = tween(mainFrame, 0.14, { Size = UDim2.fromOffset(currentBaseW, 12) })
		tween(floatStroke, 0.18, { Transparency = 0.45 })
		t.Completed:Connect(function()
			if not isMenuOpen and serial == menuToggleSerial then
				mainFrame.Visible = false
			end
		end)
	end
end

local function setMinimized(minimized)
	isMinimized = minimized
	minimizeBtn.Text = minimized and "+" or "–"
	if minimized then
		bodyContainer.Visible = false
		tween(mainFrame, 0.16, { Size = UDim2.fromOffset(currentBaseW, CONFIG.HeaderHeight) })
	else
		bodyContainer.Visible = true
		tween(mainFrame, 0.18, { Size = UDim2.fromOffset(currentBaseW, currentBaseH) })
	end
	task.defer(applyResponsiveLayout)
end

setupDraggable(header, mainFrame, getActualFrameSize, nil)
setupDraggable(floatButton, floatButton, function()
	return floatSize, floatSize
end, function()
	setMenuOpen(not isMenuOpen)
end)

track(closeBtn.Activated:Connect(function()
	setMenuOpen(false)
end))
track(minimizeBtn.Activated:Connect(function()
	setMinimized(not isMinimized)
end))

track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == CONFIG.ToggleKey then
		setMenuOpen(not isMenuOpen)
	end
end))

local Menu = {}
local tabCount = 0

function Menu:Notify(title, message, duration)
	if destroyed then
		return
	end
	local life = duration or 3
	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 54)
	toast.BackgroundColor3 = THEME.BgHeader
	toast.BackgroundTransparency = 0.05
	toast.BorderSizePixel = 0
	toast.Parent = notifyHolder
	addCorner(toast, 10)
	addStroke(toast, THEME.BorderBright, 1, 0.4)
	addPadding(toast, 8, 12, 8, 12)

	local tTitle = Instance.new("TextLabel")
	tTitle.Size = UDim2.new(1, 0, 0, 18)
	tTitle.BackgroundTransparency = 1
	tTitle.Font = Enum.Font.GothamBold
	tTitle.Text = title
	tTitle.TextColor3 = THEME.TextPrimary
	tTitle.TextSize = 13
	tTitle.TextXAlignment = Enum.TextXAlignment.Left
	tTitle.TextTruncate = Enum.TextTruncate.AtEnd
	tTitle.Parent = toast

	local tMsg = Instance.new("TextLabel")
	tMsg.Size = UDim2.new(1, 0, 0, 18)
	tMsg.Position = UDim2.fromOffset(0, 19)
	tMsg.BackgroundTransparency = 1
	tMsg.Font = Enum.Font.Gotham
	tMsg.Text = message
	tMsg.TextColor3 = THEME.TextSecondary
	tMsg.TextSize = 12
	tMsg.TextXAlignment = Enum.TextXAlignment.Left
	tMsg.TextTruncate = Enum.TextTruncate.AtEnd
	tMsg.Parent = toast

	task.delay(life, function()
		if toast.Parent then
			local fade = tween(toast, 0.2, { BackgroundTransparency = 1 })
			tween(tTitle, 0.2, { TextTransparency = 1 })
			tween(tMsg, 0.2, { TextTransparency = 1 })
			fade.Completed:Wait()
			if toast.Parent then
				toast:Destroy()
			end
		end
	end)
end

local function createCardText(parent, titleText, descText, rightReserve)
	local hasDesc = descText ~= nil and descText ~= ""
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -rightReserve, 0, 20)
	title.Position = UDim2.fromOffset(0, hasDesc and 8 or 12)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamSemibold
	title.Text = titleText
	title.TextColor3 = THEME.TextPrimary
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = parent

	if hasDesc then
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -rightReserve, 0, 16)
		desc.Position = UDim2.fromOffset(0, 29)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.Gotham
		desc.Text = descText
		desc.TextColor3 = THEME.TextSecondary
		desc.TextSize = 11
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextTruncate = Enum.TextTruncate.AtEnd
		desc.Parent = parent
	end
	return hasDesc
end

function Menu:AddTab(name, iconText)
	tabCount = tabCount + 1
	local labelStr = (iconText and iconText ~= "") and (iconText .. "  " .. name) or name

	local tabBtn = Instance.new("TextButton")
	tabBtn.Name = "Tab_" .. name
	tabBtn.LayoutOrder = tabCount
	tabBtn.BackgroundColor3 = THEME.BgMain
	tabBtn.BackgroundTransparency = 1
	tabBtn.Font = Enum.Font.GothamSemibold
	tabBtn.Text = labelStr
	tabBtn.TextColor3 = THEME.TextSecondary
	tabBtn.TextSize = 13
	tabBtn.TextXAlignment = Enum.TextXAlignment.Left
	tabBtn.AutoButtonColor = false
	tabBtn.Parent = tabBar
	addCorner(tabBtn, 8)
	addPadding(tabBtn, 0, 10, 0, 12)

	local indicator = Instance.new("Frame")
	indicator.Name = "ActiveIndicator"
	indicator.Size = UDim2.fromOffset(3, 18)
	indicator.Position = UDim2.new(0, -10, 0.5, 0)
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.BackgroundColor3 = THEME.Accent
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.Parent = tabBtn
	addCorner(indicator, 2)

	local page = Instance.new("ScrollingFrame")
	page.Name = "Page_" .. name
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = THEME.BorderBright
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.Visible = false
	page.Parent = contentArea
	addPadding(page, 10, 12, 14, 12)

	local pageLayout = Instance.new("UIListLayout")
	pageLayout.FillDirection = Enum.FillDirection.Vertical
	pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pageLayout.Padding = UDim.new(0, 8)
	pageLayout.Parent = page

	local thisTab = { Button = tabBtn, Page = page, Indicator = indicator }
	local function activate()
		if activeTabData == thisTab then
			return
		end
		if activeTabData then
			activeTabData.Page.Visible = false
			activeTabData.Indicator.Visible = false
			tween(activeTabData.Button, 0.14, { BackgroundTransparency = 1, TextColor3 = THEME.TextSecondary })
		end
		activeTabData = thisTab
		page.Visible = true
		indicator.Visible = not isCompactMode
		tween(tabBtn, 0.14, { BackgroundTransparency = 0, BackgroundColor3 = THEME.BgCard, TextColor3 = THEME.TextPrimary })
	end

	track(tabBtn.Activated:Connect(activate))
	if tabCount == 1 then
		activate()
	end
	applyResponsiveLayout()

	local Tab = {}
	local order = 0
	local function nextOrder()
		order = order + 1
		return order
	end

	local function createCardBase(className, namePrefix, height)
		local obj = Instance.new(className)
		obj.Name = namePrefix
		obj.LayoutOrder = nextOrder()
		obj.Size = UDim2.new(1, 0, 0, height)
		obj.BackgroundColor3 = THEME.BgCard
		if className == "TextButton" then
			obj.Text = ""
			obj.AutoButtonColor = false
		else
			obj.BorderSizePixel = 0
		end
		obj.Parent = page
		addCorner(obj, 9)
		addStroke(obj, THEME.Border, 1, 0.25)
		return obj
	end

	function Tab:AddSection(title)
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Section_" .. title
		lbl.LayoutOrder = nextOrder()
		lbl.Size = UDim2.new(1, 0, 0, 22)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.Text = title
		lbl.TextColor3 = THEME.TextMuted
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = page
		addPadding(lbl, 4, 2, 0, 2)
		return lbl
	end

	function Tab:AddLabel(initialText)
		local card = createCardBase("Frame", "LabelCard", 36)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = THEME.BgInput
		addPadding(card, 9, 12, 9, 12)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 0)
		lbl.AutomaticSize = Enum.AutomaticSize.Y
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamMedium
		lbl.Text = initialText
		lbl.TextColor3 = THEME.TextSecondary
		lbl.TextSize = 12
		lbl.TextWrapped = true
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = card

		local ctrl = {}
		function ctrl:Set(text)
			lbl.Text = text
		end
		return ctrl
	end

	function Tab:AddButton(opts)
		local hasDesc = opts.Description ~= nil and opts.Description ~= ""
		local btn = createCardBase("TextButton", "Button_" .. opts.Name, hasDesc and 54 or 44)
		addPadding(btn, 0, 12, 0, 12)
		createCardText(btn, opts.Name, opts.Description, 28)

		local arrow = Instance.new("TextLabel")
		arrow.Size = UDim2.fromOffset(20, 20)
		arrow.Position = UDim2.new(1, 0, 0.5, 0)
		arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.BackgroundTransparency = 1
		arrow.Font = Enum.Font.GothamBold
		arrow.Text = "›"
		arrow.TextColor3 = THEME.AccentDim
		arrow.TextSize = 18
		arrow.Parent = btn

		track(btn.Activated:Connect(function()
			tween(btn, 0.08, { BackgroundColor3 = THEME.BgCardHover })
			task.delay(0.1, function()
				if btn.Parent then
					tween(btn, 0.14, { BackgroundColor3 = THEME.BgCard })
				end
			end)
			if opts.Callback then
				local ok, err = pcall(opts.Callback)
				if not ok then
					warn("[ShadowMenu Button Error]", err)
				end
			end
		end))
		return btn
	end

	function Tab:AddToggle(opts)
		local state = opts.Default == true
		local hasDesc = opts.Description ~= nil and opts.Description ~= ""
		local btn = createCardBase("TextButton", "Toggle_" .. opts.Name, hasDesc and 54 or 44)
		addPadding(btn, 0, 12, 0, 12)
		createCardText(btn, opts.Name, opts.Description, 56)

		local switchTrack = Instance.new("Frame")
		switchTrack.Size = UDim2.fromOffset(42, 22)
		switchTrack.Position = UDim2.new(1, 0, 0.5, 0)
		switchTrack.AnchorPoint = Vector2.new(1, 0.5)
		switchTrack.BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff
		switchTrack.BorderSizePixel = 0
		switchTrack.Parent = btn
		addCorner(switchTrack, 11)

		local knob = Instance.new("Frame")
		knob.Size = UDim2.fromOffset(16, 16)
		knob.Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
		knob.BackgroundColor3 = state and THEME.AccentDarkText or THEME.TextPrimary
		knob.BorderSizePixel = 0
		knob.Parent = switchTrack
		addCorner(knob, 8)

		local function applyState(newState, fireCallback)
			state = newState
			tween(switchTrack, 0.16, { BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff })
			tween(knob, 0.16, {
				Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
				BackgroundColor3 = state and THEME.AccentDarkText or THEME.TextPrimary,
			})
			if fireCallback and opts.Callback then
				local ok, err = pcall(opts.Callback, state)
				if not ok then
					warn("[ShadowMenu Toggle Error]", err)
				end
			end
		end

		track(btn.Activated:Connect(function()
			applyState(not state, true)
		end))

		local ctrl = {}
		function ctrl:Set(v, fireCallback)
			applyState(v == true, fireCallback ~= false)
		end
		function ctrl:Get()
			return state
		end
		return ctrl
	end

	function Tab:AddSlider(opts)
		local minVal = opts.Min
		local maxVal = opts.Max
		local step = opts.Step or 1
		local suffix = opts.Suffix or ""
		local value = math.clamp(opts.Default or minVal, minVal, maxVal)

		local card = createCardBase("Frame", "Slider_" .. opts.Name, 58)
		addPadding(card, 8, 12, 8, 12)

		local topRow = Instance.new("Frame")
		topRow.Size = UDim2.new(1, 0, 0, 20)
		topRow.BackgroundTransparency = 1
		topRow.Parent = card

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -68, 1, 0)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamSemibold
		title.Text = opts.Name
		title.TextColor3 = THEME.TextPrimary
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.Parent = topRow

		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.fromOffset(64, 20)
		valLbl.Position = UDim2.new(1, 0, 0, 0)
		valLbl.AnchorPoint = Vector2.new(1, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.Font = Enum.Font.GothamBold
		valLbl.TextColor3 = THEME.Accent
		valLbl.TextSize = 12
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.Parent = topRow

		local hitArea = Instance.new("Frame")
		hitArea.Size = UDim2.new(1, 0, 0, 24)
		hitArea.Position = UDim2.fromOffset(0, 22)
		hitArea.BackgroundTransparency = 1
		hitArea.Parent = card

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1, 0, 0, 6)
		bar.Position = UDim2.fromScale(0, 0.5)
		bar.AnchorPoint = Vector2.new(0, 0.5)
		bar.BackgroundColor3 = THEME.ToggleOff
		bar.BorderSizePixel = 0
		bar.Parent = hitArea
		addCorner(bar, 3)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(0, 1)
		fill.BackgroundColor3 = THEME.Accent
		fill.BorderSizePixel = 0
		fill.Parent = bar
		addCorner(fill, 3)

		local knob = Instance.new("Frame")
		knob.Size = UDim2.fromOffset(14, 14)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Position = UDim2.fromScale(0, 0.5)
		knob.BackgroundColor3 = THEME.Accent
		knob.BorderSizePixel = 0
		knob.Parent = bar
		addCorner(knob, 7)
		addStroke(knob, THEME.BgMain, 2, 0)

		local function setValue(raw, fireCallback)
			local snapped = math.clamp(minVal + math.round((raw - minVal) / step) * step, minVal, maxVal)
			value = snapped
			local alpha = (maxVal > minVal) and ((snapped - minVal) / (maxVal - minVal)) or 0
			fill.Size = UDim2.fromScale(alpha, 1)
			knob.Position = UDim2.fromScale(alpha, 0.5)
			valLbl.Text = (step < 1) and string.format("%.2f%s", snapped, suffix) or string.format("%d%s", math.round(snapped), suffix)
			if fireCallback and opts.Callback then
				local ok, err = pcall(opts.Callback, snapped)
				if not ok then
					warn("[ShadowMenu Slider Error]", err)
				end
			end
		end
		setValue(value, false)

		local draggingSlider = nil
		local function updateFromScreenX(x)
			local w = math.max(bar.AbsoluteSize.X, 1)
			local alpha = math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1)
			setValue(minVal + alpha * (maxVal - minVal), true)
		end

		track(hitArea.InputBegan:Connect(function(input)
			if draggingSlider or not isDragInput(input) then
				return
			end
			draggingSlider = input
			page.ScrollingEnabled = false
			updateFromScreenX(input.Position.X)
		end))
		track(UserInputService.InputChanged:Connect(function(input)
			if not draggingSlider or not isMoveInput(input) then
				return
			end
			if draggingSlider.UserInputType == Enum.UserInputType.Touch and input ~= draggingSlider then
				return
			end
			updateFromScreenX(input.Position.X)
		end))
		track(UserInputService.InputEnded:Connect(function(input)
			if not draggingSlider then
				return
			end
			if input == draggingSlider or (draggingSlider.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
				draggingSlider = nil
				page.ScrollingEnabled = true
			end
		end))

		local ctrl = {}
		function ctrl:Set(v)
			setValue(v, true)
		end
		function ctrl:Get()
			return value
		end
		return ctrl
	end

	function Tab:AddDropdown(opts)
		local options = opts.Options
		local selected = opts.Default or options[1] or ""
		local isOpen = false

		local wrapper = createCardBase("Frame", "Dropdown_" .. opts.Name, 44)
		wrapper.AutomaticSize = Enum.AutomaticSize.Y
		wrapper.ClipsDescendants = true

		local wrapLayout = Instance.new("UIListLayout")
		wrapLayout.FillDirection = Enum.FillDirection.Vertical
		wrapLayout.SortOrder = Enum.SortOrder.LayoutOrder
		wrapLayout.Parent = wrapper

		local topBtn = Instance.new("TextButton")
		topBtn.LayoutOrder = 1
		topBtn.Size = UDim2.new(1, 0, 0, 44)
		topBtn.BackgroundTransparency = 1
		topBtn.Text = ""
		topBtn.AutoButtonColor = false
		topBtn.Parent = wrapper
		addPadding(topBtn, 0, 12, 0, 12)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.45, 0, 1, 0)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamSemibold
		title.Text = opts.Name
		title.TextColor3 = THEME.TextPrimary
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.Parent = topBtn

		local currentLbl = Instance.new("TextLabel")
		currentLbl.Size = UDim2.new(0.55, -18, 1, 0)
		currentLbl.Position = UDim2.new(1, -18, 0, 0)
		currentLbl.AnchorPoint = Vector2.new(1, 0)
		currentLbl.BackgroundTransparency = 1
		currentLbl.Font = Enum.Font.GothamMedium
		currentLbl.Text = selected
		currentLbl.TextColor3 = THEME.AccentDim
		currentLbl.TextSize = 11
		currentLbl.TextXAlignment = Enum.TextXAlignment.Right
		currentLbl.TextTruncate = Enum.TextTruncate.AtEnd
		currentLbl.Parent = topBtn

		local chevron = Instance.new("TextLabel")
		chevron.Size = UDim2.fromOffset(16, 44)
		chevron.Position = UDim2.new(1, 0, 0, 0)
		chevron.AnchorPoint = Vector2.new(1, 0)
		chevron.BackgroundTransparency = 1
		chevron.Font = Enum.Font.GothamBold
		chevron.Text = "▾"
		chevron.TextColor3 = THEME.AccentDim
		chevron.TextSize = 14
		chevron.Parent = topBtn

		local useScrollBox = (#options > 5)
		local listBox = Instance.new(useScrollBox and "ScrollingFrame" or "Frame")
		listBox.LayoutOrder = 2
		if useScrollBox then
			listBox.Size = UDim2.new(1, 0, 0, 196)
			listBox.CanvasSize = UDim2.new(0, 0, 0, 0)
			listBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
			listBox.ScrollingDirection = Enum.ScrollingDirection.Y
			listBox.ScrollBarThickness = 3
			listBox.ScrollBarImageColor3 = THEME.BorderBright
		else
			listBox.Size = UDim2.new(1, 0, 0, 0)
			listBox.AutomaticSize = Enum.AutomaticSize.Y
		end
		listBox.BackgroundColor3 = THEME.BgInput
		listBox.BorderSizePixel = 0
		listBox.Visible = false
		listBox.Parent = wrapper
		addPadding(listBox, 6, 8, 8, 8)

		local listLayout = Instance.new("UIListLayout")
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 4)
		listLayout.Parent = listBox

		local optionButtons = {}
		local function selectOption(opt, fireCallback)
			selected = opt
			currentLbl.Text = opt
			for optName, ob in pairs(optionButtons) do
				local active = (optName == opt)
				ob.BackgroundColor3 = active and THEME.BgCardHover or THEME.BgCard
				ob.TextColor3 = active and THEME.Accent or THEME.TextSecondary
			end
			if fireCallback and opts.Callback then
				local ok, err = pcall(opts.Callback, opt)
				if not ok then
					warn("[ShadowMenu Dropdown Error]", err)
				end
			end
		end

		for i, opt in ipairs(options) do
			local ob = Instance.new("TextButton")
			ob.LayoutOrder = i
			ob.Size = UDim2.new(1, 0, 0, 36)
			ob.BackgroundColor3 = THEME.BgCard
			ob.Font = Enum.Font.GothamMedium
			ob.Text = opt
			ob.TextColor3 = THEME.TextSecondary
			ob.TextSize = 12
			ob.TextXAlignment = Enum.TextXAlignment.Left
			ob.AutoButtonColor = false
			ob.Parent = listBox
			addCorner(ob, 7)
			addPadding(ob, 0, 10, 0, 10)
			optionButtons[opt] = ob

			track(ob.Activated:Connect(function()
				selectOption(opt, true)
				isOpen = false
				listBox.Visible = false
				chevron.Text = "▾"
			end))
		end

		selectOption(selected, false)
		track(topBtn.Activated:Connect(function()
			isOpen = not isOpen
			listBox.Visible = isOpen
			chevron.Text = isOpen and "▴" or "▾"
		end))

		local ctrl = {}
		function ctrl:Set(v)
			selectOption(v, true)
		end
		function ctrl:Get()
			return selected
		end
		return ctrl
	end

	function Tab:AddInput(opts)
		local card = createCardBase("Frame", "Input_" .. opts.Name, 48)
		addPadding(card, 0, 12, 0, 12)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.48, 0, 1, 0)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamSemibold
		title.Text = opts.Name
		title.TextColor3 = THEME.TextPrimary
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.Parent = card

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0.5, 0, 0, 30)
		box.Position = UDim2.new(1, 0, 0.5, 0)
		box.AnchorPoint = Vector2.new(1, 0.5)
		box.BackgroundColor3 = THEME.BgInput
		box.Font = Enum.Font.Gotham
		box.PlaceholderText = opts.Placeholder or "Nhập giá trị..."
		box.PlaceholderColor3 = THEME.TextMuted
		box.Text = opts.Default or ""
		box.TextColor3 = THEME.TextPrimary
		box.TextSize = 12
		box.ClearTextOnFocus = opts.ClearOnFocus == true
		box.Parent = card
		addCorner(box, 7)
		local boxStroke = addStroke(box, THEME.Border, 1, 0.2)
		addPadding(box, 0, 8, 0, 8)

		track(box.Focused:Connect(function()
			boxStroke.Color = THEME.BorderBright
		end))
		track(box.FocusLost:Connect(function()
			boxStroke.Color = THEME.Border
			if opts.Callback then
				local ok, err = pcall(opts.Callback, box.Text)
				if not ok then
					warn("[ShadowMenu Input Error]", err)
				end
			end
		end))

		local ctrl = {}
		function ctrl:Set(text)
			box.Text = text
		end
		function ctrl:Get()
			return box.Text
		end
		return ctrl
	end

	function Tab:AddMiniMeter(opts)
		local card = createCardBase("Frame", "MiniMeter_" .. (opts and opts.Name or "Craft"), 68)
		addPadding(card, 8, 12, 8, 12)

		local topRow = Instance.new("Frame")
		topRow.Size = UDim2.new(1, 0, 0, 16)
		topRow.BackgroundTransparency = 1
		topRow.Parent = card

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(0.56, 0, 1, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.Text = (opts and opts.Title) or "QUICK CRAFT"
		titleLbl.TextColor3 = THEME.TextPrimary
		titleLbl.TextSize = 11
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
		titleLbl.Parent = topRow

		local stateLbl = Instance.new("TextLabel")
		stateLbl.Size = UDim2.new(0.44, 0, 1, 0)
		stateLbl.Position = UDim2.fromScale(1, 0)
		stateLbl.AnchorPoint = Vector2.new(1, 0)
		stateLbl.BackgroundTransparency = 1
		stateLbl.Font = Enum.Font.GothamBold
		stateLbl.Text = "SẴN SÀNG"
		stateLbl.TextColor3 = THEME.AccentDim
		stateLbl.TextSize = 11
		stateLbl.TextXAlignment = Enum.TextXAlignment.Right
		stateLbl.TextTruncate = Enum.TextTruncate.AtEnd
		stateLbl.Parent = topRow

		local trackBar = Instance.new("Frame")
		trackBar.Size = UDim2.new(1, 0, 0, 12)
		trackBar.Position = UDim2.fromOffset(0, 21)
		trackBar.BackgroundColor3 = THEME.BgInput
		trackBar.BorderSizePixel = 0
		trackBar.ClipsDescendants = true
		trackBar.Parent = card
		addCorner(trackBar, 5)
		addStroke(trackBar, THEME.Border, 1, 0.25)

		local zoneFrame = Instance.new("Frame")
		zoneFrame.Size = UDim2.fromScale(1, 1)
		zoneFrame.Position = UDim2.fromScale(0, 0)
		zoneFrame.BackgroundColor3 = THEME.Success
		zoneFrame.BackgroundTransparency = 0.45
		zoneFrame.BorderSizePixel = 0
		zoneFrame.Parent = trackBar
		addCorner(zoneFrame, 4)

		local fillBar = Instance.new("Frame")
		fillBar.Size = UDim2.fromScale(0, 1)
		fillBar.BackgroundColor3 = THEME.Success
		fillBar.BorderSizePixel = 0
		fillBar.Parent = trackBar
		addCorner(fillBar, 4)

		local detailLbl = Instance.new("TextLabel")
		detailLbl.Size = UDim2.new(1, 0, 0, 15)
		detailLbl.Position = UDim2.fromOffset(0, 37)
		detailLbl.BackgroundTransparency = 1
		detailLbl.Font = Enum.Font.Gotham
		detailLbl.Text = "Sẵn sàng Quick Craft | Đã craft: 0"
		detailLbl.TextColor3 = THEME.TextSecondary
		detailLbl.TextSize = 11
		detailLbl.TextXAlignment = Enum.TextXAlignment.Left
		detailLbl.TextTruncate = Enum.TextTruncate.AtEnd
		detailLbl.Parent = card

		local ctrl = {}
		function ctrl:SetState(stateText, color, fillAlpha, detailText)
			if stateText then
				stateLbl.Text = stateText
			end
			if color then
				stateLbl.TextColor3 = color
				fillBar.BackgroundColor3 = color
			end
			if fillAlpha ~= nil then
				fillBar.Size = UDim2.fromScale(math.clamp(fillAlpha, 0, 1), 1)
			end
			if detailText then
				detailLbl.Text = detailText
			end
		end
		return ctrl
	end

	return Tab
end

local gameRMShared = nil
local rmSharedObj = ReplicatedStorage:FindFirstChild("RMShared")
if rmSharedObj and rmSharedObj:IsA("ModuleScript") then
	local okReq, mod = pcall(require, rmSharedObj)
	if okReq and type(mod) == "table" then
		gameRMShared = mod
	end
end

local MATERIAL_DEFS = {
	{ Id = "Quantum", Option = "Quantum • Ore", DisplayName = "Quantum Crystal", Dim = "CrystalCaverns", Kind = "Ore" },
	{ Id = "Graviton", Option = "Graviton • Ore", DisplayName = "Graviton Shard", Dim = "GravityIslands", Kind = "Ore" },
	{ Id = "Magma", Option = "Magma • Ore", DisplayName = "Molten Core", Dim = "VolcanoWorld", Kind = "Ore" },
	{ Id = "Void", Option = "Void • Ore", DisplayName = "Void Essence", Dim = "TheVoid", Kind = "Ore" },
	{ Id = "Brine", Option = "Brine", DisplayName = "Pickle Brine", Dim = "PickleSewers", Kind = "Node" },
	{ Id = "Cell", Option = "Cell", DisplayName = "Blood Cell", Dim = "AnatomyPark", Kind = "Node" },
	{ Id = "Cog", Option = "Cog", DisplayName = "Golden Cog", Dim = "GearWorld", Kind = "Node" },
	{ Id = "DarkMatter", Option = "DarkMatter", DisplayName = "Dark Matter", Dim = "Citadel", Kind = "Node" },
	{ Id = "Ember", Option = "Ember", DisplayName = "Purge Ember", Dim = "PurgePlanet", Kind = "Node" },
	{ Id = "Feather", Option = "Feather", DisplayName = "Bird Feather", Dim = "BirdWorld", Kind = "Node" },
	{ Id = "Fleeb", Option = "Fleeb", DisplayName = "Fleeb Juice", Dim = "Froopyland", Kind = "Node" },
	{ Id = "Flesh", Option = "Flesh", DisplayName = "Cronenberg Flesh", Dim = "Cronenberg", Kind = "Node" },
	{ Id = "Ice", Option = "Ice", DisplayName = "Frost Crystal", Dim = "IceWorld", Kind = "Node" },
	{ Id = "Isotope", Option = "Isotope", DisplayName = "Isotope 322", Dim = "Wasteland", Kind = "Node" },
	{ Id = "Microchip", Option = "Microchip", DisplayName = "Microchip", Dim = "Microverse", Kind = "Node" },
	{ Id = "Pearl", Option = "Pearl", DisplayName = "Atlantis Pearl", Dim = "Atlantis", Kind = "Node" },
	{ Id = "Scrap", Option = "Scrap", DisplayName = "Scrap Metal", Dim = "OWN", Kind = "Node" },
	{ Id = "Seed", Option = "Seed", DisplayName = "Mega Seed", Dim = "Dimension35C", Kind = "Node" },
	{ Id = "Solar", Option = "Solar", DisplayName = "Solar Shard", Dim = "Gazorpazorp", Kind = "Node" },
	{ Id = "Squanch", Option = "Squanch", DisplayName = "Squanch Fruit", Dim = "PlanetSquanch", Kind = "Node" },
	{ Id = "Toxin", Option = "Toxin", DisplayName = "Toxic Sludge", Dim = "ToxicSwamp", Kind = "Node" },
	{ Id = "Venom", Option = "Venom", DisplayName = "Snake Venom", Dim = "SnakePlanet", Kind = "Node" },
	{ Id = "GunBody", Option = "GunBody", DisplayName = "Portal Gun Body", Dim = "Workbench", Kind = "Special" },
	{ Id = "PortalFluid", Option = "PortalFluid", DisplayName = "Portal Fluid", Dim = "Workbench", Kind = "Special" },
	{ Id = "Token", Option = "Token", DisplayName = "Arcade Token", Dim = "BlipsAndChitz", Kind = "Special" },
}

local MATERIAL_BY_ID = {}
local MATERIAL_OPTIONS = { "Tất cả Material", "Quặng (OreNode)", "Node Thường" }
local OPTION_TO_FILTER = {
	["Tất cả Material"] = { kind = "All" },
	["Quặng (OreNode)"] = { kind = "Ore" },
	["Node Thường"] = { kind = "Node" },
}
for _, m in ipairs(MATERIAL_DEFS) do
	MATERIAL_BY_ID[m.Id] = m
	table.insert(MATERIAL_OPTIONS, m.Option)
	OPTION_TO_FILTER[m.Option] = { kind = "Id", matId = m.Id }
end

local SharedState = {
	LootSessionCount = 0,
	RefreshCraftUi = nil,
	RefreshLootUi = nil,
}

local function splitCsv(str)
	local out = {}
	for part in string.gmatch(str or "", "[^,]+") do
		local trimmed = string.gsub(part, "^%s*(.-)%s*$", "%1")
		if trimmed ~= "" then
			table.insert(out, trimmed)
		end
	end
	return out
end

local function isCharacterPart(obj)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and obj:IsDescendantOf(plr.Character) then
			return true
		end
	end
	return false
end

local function getRealMatCount(matId)
	return tonumber(localPlayer:GetAttribute("Mat_" .. matId)) or 0
end

local function getRealItemCount(recipeId)
	return tonumber(localPlayer:GetAttribute("Item_" .. recipeId)) or 0
end

local function getRealIQLevel()
	return tonumber(localPlayer:GetAttribute("IQLevel")) or 1
end

local function getStreamedPartPosition(obj)
	if not obj or not obj.Parent then
		return nil, nil
	end
	if obj:IsA("BasePart") then
		return obj.Position, obj
	elseif obj:IsA("Tool") then
		local handle = obj:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			return handle.Position, handle
		end
		local part = obj:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.Position, part
		end
		return nil, nil
	elseif obj:IsA("Model") then
		local part = obj:FindFirstChild("Core") or obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart", true)
		if part and part:IsA("BasePart") then
			return part.Position, part
		end
		return nil, nil
	end
	return nil, nil
end

local function teleportCharacterTo(worldPos, offsetVec, faceTargetPos, maxStreamSec)
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not char or not hum or not root or hum.Health <= 0 then
		return false
	end
	local destPos = worldPos + (offsetVec or Vector3.new(0, 2.2, 0))
	local jumpDist = (destPos - root.Position).Magnitude
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	if faceTargetPos then
		local lookTarget = Vector3.new(faceTargetPos.X, destPos.Y, faceTargetPos.Z)
		if (lookTarget - destPos).Magnitude > 0.2 then
			char:PivotTo(CFrame.lookAt(destPos, lookTarget))
		else
			char:PivotTo(CFrame.new(destPos))
		end
	else
		char:PivotTo(CFrame.new(destPos) * (char:GetPivot().Rotation))
	end

	if jumpDist > 80 then
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { char }
		pcall(function()
			rayParams.RespectCanCollide = true
		end)
		local origin = root.Position + Vector3.new(0, 2, 0)
		if not Workspace:Raycast(origin, Vector3.new(0, -14, 0), rayParams) then
			local prevAnchored = root.Anchored
			root.Anchored = true
			task.spawn(function()
				pcall(function()
					localPlayer:RequestStreamAroundAsync(destPos, 3)
				end)
			end)
			local t0 = clockNow()
			local maxWait = maxStreamSec or 2.0
			while not destroyed and root.Parent and (clockNow() - t0) < maxWait do
				if Workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), rayParams) then
					break
				end
				task.wait(0.06)
			end
			local hit = Workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), rayParams)
			if hit and root.Parent then
				local hipHeight = (hum.RigType == Enum.HumanoidRigType.R15 and hum.HipHeight or 2) + root.Size.Y * 0.5
				local landedPos = Vector3.new(hit.Position.X, hit.Position.Y + hipHeight + 0.15, hit.Position.Z)
				if faceTargetPos then
					local lookPt = Vector3.new(faceTargetPos.X, landedPos.Y, faceTargetPos.Z)
					if (lookPt - landedPos).Magnitude > 0.2 then
						char:PivotTo(CFrame.lookAt(landedPos, lookPt))
					else
						char:PivotTo(CFrame.new(landedPos))
					end
				else
					char:PivotTo(CFrame.new(landedPos) * (char:GetPivot().Rotation))
				end
			end
			if root.Parent then
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				root.Anchored = prevAnchored == true
			end
		end
	end
	return true
end

local function stopCharacterMovement()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if hum and root then
		hum:MoveTo(root.Position)
	end
end

local function findExactTool(char, exactName)
	local lowTarget = string.lower(exactName)
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") and string.find(string.lower(item.Name), lowTarget, 1, true) then
			return item, true
		end
	end
	local backpack = localPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and string.find(string.lower(item.Name), lowTarget, 1, true) then
				return item, false
			end
		end
	end
	return nil, false
end

local function findOwnPlayerDimModel()
	local dims = Workspace:FindFirstChild("Dimensions")
	if not dims then
		return nil
	end
	local myCode = localPlayer:GetAttribute("MyDimCode")
	if myCode and myCode ~= "" then
		local byAttr = dims:FindFirstChild("Dim_" .. tostring(myCode))
		if byAttr then
			return byAttr
		end
	end
	local playerDims = ReplicatedStorage:FindFirstChild("PlayerDims")
	if playerDims then
		local cfg = playerDims:FindFirstChild("pd_" .. tostring(localPlayer.UserId))
		if cfg then
			local code = cfg:GetAttribute("Code")
			if code then
				local byCode = dims:FindFirstChild("Dim_" .. tostring(code))
				if byCode then
					return byCode
				end
			end
		end
	end
	for _, dim in ipairs(dims:GetChildren()) do
		if dim:GetAttribute("OwnerId") == localPlayer.UserId then
			return dim
		end
	end
	return nil
end

local function findOwnCraftStationPos()
	local garageFallback = nil
	for _, cs in ipairs(CollectionService:GetTagged("CraftStation")) do
		if cs:IsDescendantOf(Workspace) and cs:GetAttribute("OwnerId") == localPlayer.UserId then
			local fullLower = string.lower(cs:GetFullName())
			local okPos, pos = pcall(function()
				return cs:IsA("Model") and cs:GetPivot().Position or cs.Position
			end)
			if okPos and typeof(pos) == "Vector3" then
				if not string.find(fullLower, "bunker", 1, true) then
					return pos
				end
				garageFallback = garageFallback or pos
			end
		end
	end
	if garageFallback then
		return garageFallback
	end
	local ownDim = findOwnPlayerDimModel()
	if ownDim then
		local wb = ownDim:FindFirstChild("Workbench")
		local cs = wb and wb:FindFirstChild("CraftStation")
		if cs then
			if cs:IsA("BasePart") then
				return cs.Position
			elseif cs:IsA("Model") then
				return cs:GetPivot().Position
			end
		end
		if wb then
			local prompt = wb:FindFirstChild("CraftPrompt", true)
			if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then
				return prompt.Parent.Position
			end
		end
		local sp = ownDim:GetAttribute("Spawn")
		if typeof(sp) == "CFrame" then
			return sp.Position
		elseif typeof(sp) == "Vector3" then
			return sp
		end
		local mid = ownDim:GetAttribute("Mid")
		if typeof(mid) == "Vector3" then
			return mid
		end
	end
	local playerDims = ReplicatedStorage:FindFirstChild("PlayerDims")
	local cfg = playerDims and playerDims:FindFirstChild("pd_" .. tostring(localPlayer.UserId))
	local cfgSpawn = cfg and cfg:GetAttribute("Spawn")
	if typeof(cfgSpawn) == "CFrame" then
		return cfgSpawn.Position
	elseif typeof(cfgSpawn) == "Vector3" then
		return cfgSpawn
	end
	return nil
end

local function getDimensionTargetPosition(dimName)
	local dims = Workspace:FindFirstChild("Dimensions")
	if not dims then
		return nil
	end
	if dimName == "OWN" then
		local playerDims = ReplicatedStorage:FindFirstChild("PlayerDims")
		local cfg = playerDims and playerDims:FindFirstChild("pd_" .. tostring(localPlayer.UserId))
		local cfgSpawn = cfg and cfg:GetAttribute("Spawn")
		if typeof(cfgSpawn) == "CFrame" then
			return cfgSpawn.Position
		elseif typeof(cfgSpawn) == "Vector3" then
			return cfgSpawn
		end
	end
	local dimModel = (dimName == "OWN") and findOwnPlayerDimModel() or dims:FindFirstChild(dimName)
	if not dimModel then
		return nil
	end
	local spawnAttr = dimModel:GetAttribute("Spawn")
	if typeof(spawnAttr) == "CFrame" then
		return spawnAttr.Position
	elseif typeof(spawnAttr) == "Vector3" then
		return spawnAttr
	end
	local midAttr = dimModel:GetAttribute("Mid")
	if typeof(midAttr) == "Vector3" then
		return midAttr + Vector3.new(0, 12, 0)
	end
	return nil
end

do
local matTab = Menu:AddTab("Auto Loot", "★")
matTab:AddSection("AUTO LOOT MATERIAL")

local selectedMatOption = "Tất cả Material"
local customMatFilter = ""
local teleportToMatEnabled = true
local autoLootEnabled = false
local autoPromptEnabled = true
local instantExecutorPrompt = false
local autoSwingToolEnabled = true
local autoLootChestsEnabled = true
local includeDimensionsScan = true
local lootMaxRange = 200
local lootLoopInterval = 0.25
local lootFolderNames = "DroppedLoot, Nodes, QuestIngredients"
local lootTagNames = "OreNode, QuestIngredient"
local lootRunId = 0
local nodeCooldownUntil = {}
local cachedNodes = {}
local lastCacheRebuildAt = 0
local lastPickaxeSwingAt = 0
local activeHoldPrompt = nil
local lootChestWindowUntil = 0

local matStatusLabel = matTab:AddLabel("Sẵn sàng | 25 Material & Dimensions")
local lootStatsLabel = matTab:AddLabel("Kho thực: Scrap 0 | Lần nhặt phiên: 0")

local function refreshLootStatsLabel()
	local parts = {}
	for _, m in ipairs(MATERIAL_DEFS) do
		local c = getRealMatCount(m.Id)
		if c > 0 then
			table.insert(parts, m.Id .. ":" .. c)
			if #parts >= 4 then
				break
			end
		end
	end
	local summary = #parts > 0 and table.concat(parts, " ") or ("Scrap:" .. getRealMatCount("Scrap"))
	lootStatsLabel:Set(string.format("Kho: %s | Nhặt phiên: %d", summary, SharedState.LootSessionCount))
end
SharedState.RefreshLootUi = refreshLootStatsLabel

local function releaseActivePrompt()
	if activeHoldPrompt then
		local p = activeHoldPrompt
		activeHoldPrompt = nil
		pcall(function()
			p:InputHoldEnd()
		end)
	end
end

local function getNodeMaterialAttr(obj)
	return obj:GetAttribute("MatKey") or obj:GetAttribute("Material") or obj:GetAttribute("MaterialId")
end

local function isChestCandidate(obj)
	return obj and obj.Parent and obj.Parent.Name == "LootChests"
end

local function isNodeAvailable(obj)
	if not obj or not obj.Parent or isCharacterPart(obj) then
		return false
	end
	if obj:GetAttribute("Claimed") == true or obj:GetAttribute("Broken") == true or obj:GetAttribute("Disabled") == true then
		return false
	end
	local owner = obj:GetAttribute("OwnerId")
	if owner ~= nil and owner ~= localPlayer.UserId then
		return false
	end
	local pos, basePart = getStreamedPartPosition(obj)
	if not pos or not basePart then
		return false
	end
	if pos.Y < -4000 then
		return false
	end
	local core = obj:FindFirstChild("Core")
	local p = (core and core:FindFirstChildWhichIsA("ProximityPrompt"))
		or (obj:IsA("ProximityPrompt") and obj)
		or obj:FindFirstChildWhichIsA("ProximityPrompt", true)
	if isChestCandidate(obj) then
		return (p ~= nil and p.Enabled)
	end
	local rawMat = tostring(getNodeMaterialAttr(obj) or "")
	local isOreObj = CollectionService:HasTag(obj, "OreNode")
		or obj:GetAttribute("Hits") ~= nil
		or (MATERIAL_BY_ID[rawMat] and MATERIAL_BY_ID[rawMat].Kind == "Ore")
		or false
	local isDropObj = (obj.Parent and obj.Parent.Name == "DroppedLoot")
		or (obj:FindFirstChildWhichIsA("ClickDetector", true) ~= nil)
	if not ((p and p.Enabled) or isOreObj or isDropObj) then
		return false
	end
	return true
end

local function rebuildMaterialCache(force)
	local now = clockNow()
	if not force and (now - lastCacheRebuildAt) < 1.2 and #cachedNodes > 0 then
		return cachedNodes
	end
	lastCacheRebuildAt = now

	local list = {}
	local seen = {}
	local function addCandidate(obj)
		if obj and not seen[obj] and not obj:IsA("LuaSourceContainer") and isNodeAvailable(obj) then
			seen[obj] = true
			table.insert(list, obj)
		end
	end

	for _, fName in ipairs(splitCsv(lootFolderNames)) do
		local folder = Workspace:FindFirstChild(fName)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				addCandidate(child)
			end
		end
	end

	for _, tName in ipairs(splitCsv(lootTagNames)) do
		for _, tagged in ipairs(CollectionService:GetTagged(tName)) do
			addCandidate(tagged)
		end
	end

	if autoLootChestsEnabled then
		local chests = Workspace:FindFirstChild("LootChests")
		if chests then
			for _, chest in ipairs(chests:GetChildren()) do
				addCandidate(chest)
			end
		end
	end

	if includeDimensionsScan then
		local dims = Workspace:FindFirstChild("Dimensions")
		if dims then
			for _, dim in ipairs(dims:GetChildren()) do
				for _, subName in ipairs({ "Nodes", "Ores", "Cave", "CaveMouths", "Props" }) do
					local sub = dim:FindFirstChild(subName)
					if sub then
						for _, child in ipairs(sub:GetChildren()) do
							if getNodeMaterialAttr(child) ~= nil or CollectionService:HasTag(child, "OreNode") or CollectionService:HasTag(child, "QuestIngredient") then
								addCandidate(child)
							end
						end
					end
				end
				for _, child in ipairs(dim:GetChildren()) do
					if getNodeMaterialAttr(child) ~= nil then
						addCandidate(child)
					end
				end
			end
		end
	end

	cachedNodes = list
	return list
end

local function getNodeDimName(obj)
	local full = obj:GetFullName()
	return string.match(full, "^Workspace%.Dimensions%.([^%.]+)") or (obj.Parent and obj.Parent.Name) or "Workspace"
end

local function matchMaterialTarget(obj)
	if not isNodeAvailable(obj) then
		return false
	end
	local customLower = string.lower(string.gsub(customMatFilter, "^%s*(.-)%s*$", "%1"))
	if customLower ~= "" then
		local hay = string.lower(
			obj.Name
				.. " "
				.. tostring(obj:GetAttribute("MatKey") or "")
				.. " "
				.. tostring(obj:GetAttribute("Material") or "")
				.. " "
				.. tostring(obj:GetAttribute("MaterialId") or "")
				.. " "
				.. tostring(obj:GetAttribute("MaterialName") or "")
				.. " "
				.. tostring(obj:GetAttribute("Text") or "")
				.. " "
				.. getNodeDimName(obj)
		)
		return string.find(hay, customLower, 1, true) ~= nil
	end

	local filter = OPTION_TO_FILTER[selectedMatOption] or { kind = "All" }
	if filter.kind == "All" then
		return true
	end
	if isChestCandidate(obj) then
		return false
	end

	local rawAttr = tostring(getNodeMaterialAttr(obj) or "")
	local isOre = CollectionService:HasTag(obj, "OreNode") or (MATERIAL_BY_ID[rawAttr] and MATERIAL_BY_ID[rawAttr].Kind == "Ore") or false
	if filter.kind == "Ore" then
		return isOre
	elseif filter.kind == "Node" then
		return not isOre
	end

	local def = MATERIAL_BY_ID[filter.matId]
	if not def then
		return false
	end
	local attrName = tostring(obj:GetAttribute("MaterialName") or "")
	local lowerName = string.lower(obj.Name)
	local idLow = string.lower(def.Id)
	return (rawAttr == def.Id)
		or (attrName == def.DisplayName)
		or (attrName == def.Option)
		or (string.find(lowerName, idLow, 1, true) ~= nil)
end

local function findNearestMaterialNode(originPos, useCooldown)
	local nodes = rebuildMaterialCache(false)
	local maxDist = teleportToMatEnabled and math.huge or lootMaxRange
	local bestDist, bestFallbackDist = maxDist, maxDist
	local bestPos, bestObj = nil, nil
	local fallbackPos, fallbackObj = nil, nil
	local now = clockNow()

	for _, obj in ipairs(nodes) do
		if matchMaterialTarget(obj) then
			local pos = getStreamedPartPosition(obj)
			if pos then
				local d = (pos - originPos).Magnitude
				local onCooldown = useCooldown and nodeCooldownUntil[obj] and nodeCooldownUntil[obj] > now
				if not onCooldown and d <= bestDist then
					bestDist = d
					bestPos = pos
					bestObj = obj
				elseif onCooldown and d <= bestFallbackDist then
					bestFallbackDist = d
					fallbackPos = pos
					fallbackObj = obj
				end
			end
		end
	end

	if bestObj then
		return bestObj, bestPos, bestDist
	end
	return fallbackObj, fallbackPos, fallbackDist
end

local function tryStreamSelectedDimension(originPos, checkRunFn)
	if not teleportToMatEnabled then
		return nil
	end
	local filter = OPTION_TO_FILTER[selectedMatOption]
	local targetDimName = nil
	if filter and filter.kind == "Id" then
		local def = MATERIAL_BY_ID[filter.matId]
		if def and def.Dim ~= "Workbench" then
			targetDimName = def.Dim
		end
	elseif filter and filter.kind == "Ore" then
		targetDimName = "CrystalCaverns"
	end
	if not targetDimName then
		local dims = Workspace:FindFirstChild("Dimensions")
		if dims and customMatFilter ~= "" then
			local cLow = string.lower(customMatFilter)
			for _, d in ipairs(dims:GetChildren()) do
				if string.find(string.lower(d.Name), cLow, 1, true) then
					targetDimName = d.Name
					break
				end
			end
		end
	end
	if not targetDimName then
		return nil
	end
	local dimPos = getDimensionTargetPosition(targetDimName)
	if not dimPos then
		return nil
	end
	if (dimPos - originPos).Magnitude > 180 then
		matStatusLabel:Set("Đang tải Dimension " .. targetDimName .. "...")
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local prevCFrame = root and root.CFrame or nil

		teleportCharacterTo(dimPos, Vector3.new(0, 4, 0), nil, 2.5)

		local foundObj, foundPos, foundDist = nil, nil, nil
		for _ = 1, 8 do
			if destroyed or (checkRunFn and not checkRunFn()) then
				break
			end
			task.wait(0.25)
			rebuildMaterialCache(true)
			foundObj, foundPos, foundDist = findNearestMaterialNode(dimPos, false)
			if foundObj then
				break
			end
		end

		if not foundObj and prevCFrame and char and char.Parent and root and root.Parent then
			teleportCharacterTo(prevCFrame.Position, Vector3.zero, nil, 1.5)
		end
		return foundObj, foundPos, foundDist
	end
	return nil
end

local function findNodePrompt(node)
	local core = node:FindFirstChild("Core")
	if core then
		local p = core:FindFirstChildWhichIsA("ProximityPrompt")
		if p and p.Enabled then
			return p
		end
	end
	local prompt = node:IsA("ProximityPrompt") and node or node:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt and prompt.Enabled then
		return prompt
	end
	return nil
end

local function holdPromptComplete(prompt, node, checkRunFn)
	local pParent = prompt.Parent
	local promptPos = (pParent and pParent:IsA("BasePart")) and pParent.Position or (getStreamedPartPosition(node) or Vector3.zero)
	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	pcall(function()
		prompt.RequiresLineOfSight = false
	end)

	local safeRange = math.min(3.2, math.max(1.8, (prompt.MaxActivationDistance or 6) - 1.2))
	if (promptPos - root.Position).Magnitude > safeRange then
		if teleportToMatEnabled then
			teleportCharacterTo(promptPos, Vector3.new(0, 1.8, 1.8), promptPos, 2.0)
			task.wait(0.22)
		else
			return false
		end
	end

	local cam = Workspace.CurrentCamera
	if cam and cam.CameraType ~= Enum.CameraType.Scriptable then
		cam.CFrame = CFrame.lookAt(promptPos + Vector3.new(0, 5.5, 7.5), promptPos)
		task.wait(0.08)
	end

	local matKey = tostring(getNodeMaterialAttr(node) or "")
	local matBefore = matKey ~= "" and getRealMatCount(matKey) or 0
	if isChestCandidate(node) then
		lootChestWindowUntil = clockNow() + 4.0
	end

	activeHoldPrompt = prompt
	pcall(function()
		prompt:InputHoldBegin()
	end)

	local hasFirePrompt = (type(fireproximityprompt) == "function")
	if instantExecutorPrompt and hasFirePrompt then
		pcall(fireproximityprompt, prompt)
		task.wait(0.12)
	end

	local totalHold = math.max(0.1, (prompt.HoldDuration or 0) + 0.25)
	local deadline = clockNow() + totalHold
	while clockNow() < deadline do
		if destroyed or not node.Parent or not prompt.Parent or not prompt.Enabled then
			break
		end
		if node:GetAttribute("Claimed") == true or node:GetAttribute("Broken") == true then
			break
		end
		if matKey ~= "" and getRealMatCount(matKey) > matBefore then
			break
		end
		if checkRunFn and not checkRunFn() then
			break
		end
		task.wait(0.05)
	end

	if node.Parent and prompt.Parent and prompt.Enabled and node:GetAttribute("Claimed") ~= true and hasFirePrompt then
		pcall(fireproximityprompt, prompt)
		task.wait(0.1)
	end

	releaseActivePrompt()
	return (not node.Parent)
		or (node:GetAttribute("Claimed") == true)
		or (node:GetAttribute("Broken") == true)
		or (matKey ~= "" and getRealMatCount(matKey) > matBefore)
end

local function swingPickaxeAtOre(node, pos, checkRunFn)
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then
		return false
	end

	local pickaxeTool, isEquipped = findExactTool(char, "Pickaxe")
	if not pickaxeTool then
		matStatusLabel:Set("Cần craft Pickaxe (8 Scrap) để đào quặng Ore!")
		Menu:Notify("Auto Loot", "Bạn chưa có Pickaxe để đào quặng OreNode.", 2.2)
		return false
	end
	if not isEquipped then
		hum:EquipTool(pickaxeTool)
		task.wait(0.1)
	end

	local mineEvent = ReplicatedStorage:FindFirstChild("MineEvent")
	local matId = tostring(getNodeMaterialAttr(node) or "Quantum")
	local matBefore = getRealMatCount(matId)
	for swingIdx = 1, 6 do
		if destroyed or not node.Parent or node:GetAttribute("Broken") == true or node:GetAttribute("Claimed") == true then
			break
		end
		if checkRunFn and not checkRunFn() then
			break
		end
		local livePos = getStreamedPartPosition(node) or pos
		if teleportToMatEnabled then
			teleportCharacterTo(livePos, Vector3.new(0, 1.8, 2.6), livePos, 1.8)
		end
		if pickaxeTool.Parent ~= char and pickaxeTool.Parent == localPlayer:FindFirstChildOfClass("Backpack") then
			hum:EquipTool(pickaxeTool)
		end
		local now = clockNow()
		if (now - lastPickaxeSwingAt) < 0.78 then
			task.wait(0.78 - (now - lastPickaxeSwingAt))
		end
		lastPickaxeSwingAt = clockNow()
		pcall(function()
			pickaxeTool:Activate()
		end)
		if mineEvent and mineEvent:IsA("RemoteEvent") then
			pcall(function()
				mineEvent:FireServer("swing")
			end)
		end
		task.wait(0.3)
		if not node.Parent or node:GetAttribute("Broken") == true or node:GetAttribute("Claimed") == true then
			break
		end
		if swingIdx < 6 then
			task.wait(0.5)
		end
	end
	return (not node.Parent) or (node:GetAttribute("Broken") == true) or (getRealMatCount(matId) > matBefore)
end

local function collectMaterialNode(node, pos, isSingleAction, myRunId)
	if not node or not node.Parent then
		return false
	end
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then
		return false
	end

	local function keepGoing()
		if not isSingleAction then
			return autoLootEnabled and not destroyed and myRunId == lootRunId
		end
		return not destroyed
	end

	if teleportToMatEnabled then
		local jumpDist = (pos - root.Position).Magnitude
		teleportCharacterTo(pos, Vector3.new(0, 1.8, 1.8), pos, 2.2)
		task.wait(jumpDist > 10 and 0.35 or 0.14)
		pcall(function()
			RunService.Heartbeat:Wait()
		end)
	else
		hum:MoveTo(pos)
		if isSingleAction then
			matStatusLabel:Set("Đang đi tới: " .. node.Name .. " [" .. getNodeDimName(node) .. "]")
			return true
		end
	end

	local prompt = autoPromptEnabled and findNodePrompt(node) or nil
	if prompt then
		local done = holdPromptComplete(prompt, node, keepGoing)
		if not done and node.Parent then
			nodeCooldownUntil[node] = clockNow() + 1.8
		end
		return true
	end

	local matAttr = tostring(getNodeMaterialAttr(node) or "")
	local isOre = CollectionService:HasTag(node, "OreNode")
		or node:GetAttribute("Hits") ~= nil
		or (MATERIAL_BY_ID[matAttr] and MATERIAL_BY_ID[matAttr].Kind == "Ore")
	if autoSwingToolEnabled and isOre then
		swingPickaxeAtOre(node, pos, keepGoing)
	end

	if node.Parent then
		nodeCooldownUntil[node] = clockNow() + 2.0
	end
	return true
end

local lootEventObj = ReplicatedStorage:FindFirstChild("LootEvent")
if lootEventObj and lootEventObj:IsA("RemoteEvent") then
	track(lootEventObj.OnClientEvent:Connect(function(action, chestId)
		if destroyed or not autoLootChestsEnabled then
			return
		end
		if action == "show" and chestId ~= nil and (autoLootEnabled or clockNow() <= lootChestWindowUntil) then
			task.spawn(function()
				task.wait(0.08)
				pcall(function()
					lootEventObj:FireServer("take", chestId, "all")
				end)
				task.wait(0.1)
				pcall(function()
					lootEventObj:FireServer("leave", chestId)
				end)
			end)
		end
	end))
end

matTab:AddDropdown({
	Name = "Chọn Material",
	Options = MATERIAL_OPTIONS,
	Default = "Tất cả Material",
	Callback = function(opt)
		selectedMatOption = opt
		rebuildMaterialCache(true)
		local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		local origin = root and root.Position or Vector3.zero
		local node, _, dist = findNearestMaterialNode(origin, false)
		if node then
			local matId = tostring(getNodeMaterialAttr(node) or node.Name)
			matStatusLabel:Set(string.format("Tìm thấy %s [%s] (%.0f st)", matId, getNodeDimName(node), dist))
		else
			matStatusLabel:Set("Đã chọn: " .. opt .. " (Sẵn sàng TP tới Dim)")
		end
	end,
})

matTab:AddInput({
	Name = "Lọc tên / ID / Dim",
	Placeholder = "VD: Quantum, Scrap, Froopyland...",
	Default = "",
	Callback = function(txt)
		customMatFilter = string.gsub(txt, "^%s*(.-)%s*$", "%1")
	end,
})

matTab:AddToggle({
	Name = "Teleport (Không giới hạn)",
	Description = "TP qua Dimension & sát node để nhặt/đào",
	Default = true,
	Callback = function(on)
		teleportToMatEnabled = on
	end,
})

matTab:AddToggle({
	Name = "Auto Giữ Prompt",
	Description = "Giữ đủ HoldDuration + dự phòng fireproximityprompt",
	Default = true,
	Callback = function(on)
		autoPromptEnabled = on
	end,
})

matTab:AddToggle({
	Name = "Instant Prompt (Executor)",
	Description = "Thử kích nổ nhanh fireproximityprompt khi giữ",
	Default = false,
	Callback = function(on)
		instantExecutorPrompt = on
	end,
})

matTab:AddToggle({
	Name = "Tự vung Pickaxe đào Quặng",
	Description = "Chỉ dùng Pickaxe & gõ quặng (OreNode)",
	Default = true,
	Callback = function(on)
		autoSwingToolEnabled = on
	end,
})

matTab:AddToggle({
	Name = "Auto Mở Rương (LootChests)",
	Description = "Tự lấy toàn bộ đồ trong rương khi Auto Loot",
	Default = true,
	Callback = function(on)
		autoLootChestsEnabled = on
	end,
})

matTab:AddToggle({
	Name = "Quét Workspace.Dimensions",
	Description = "Quét cả Nodes/Ores đã stream ở các Dimensions",
	Default = true,
	Callback = function(on)
		includeDimensionsScan = on
		rebuildMaterialCache(true)
	end,
})

matTab:AddButton({
	Name = "Teleport & Loot ngay",
	Description = "Tìm node (hoặc TP sang Dim), lại sát & thu thập",
	Callback = function()
		task.spawn(function()
			local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not root then
				Menu:Notify("Auto Loot", "Đang chờ nhân vật hồi sinh.", 2)
				return
			end
			rebuildMaterialCache(true)
			local node, pos, dist = findNearestMaterialNode(root.Position, false)
			if not node then
				node, pos, dist = tryStreamSelectedDimension(root.Position)
			end
			if not node or not pos then
				matStatusLabel:Set("Chưa thấy node nào khớp xung quanh!")
				Menu:Notify("Auto Loot", "Không tìm thấy node phù hợp đã tải.", 2.2)
				return
			end
			local matId = tostring(getNodeMaterialAttr(node) or node.Name)
			matStatusLabel:Set(string.format("Đang loot %s [%s] (%.0f st)", matId, getNodeDimName(node), dist))
			Menu:Notify("Auto Loot", string.format("Đang thu thập %s [%s]", matId, getNodeDimName(node)), 2)
			collectMaterialNode(node, pos, true, lootRunId)
		end)
	end,
})

local function startAutoLootLoop()
	lootRunId = lootRunId + 1
	local myRunId = lootRunId
	nodeCooldownUntil = {}
	rebuildMaterialCache(true)
	task.spawn(function()
		while autoLootEnabled and not destroyed and myRunId == lootRunId do
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local targetObj, targetPos, dist = findNearestMaterialNode(root.Position, true)
				if not targetObj then
					targetObj, targetPos, dist = tryStreamSelectedDimension(root.Position, function()
						return autoLootEnabled and not destroyed and myRunId == lootRunId
					end)
				end
				if targetObj and targetPos then
					local matId = tostring(getNodeMaterialAttr(targetObj) or targetObj.Name)
					matStatusLabel:Set(string.format("Mục tiêu: %s [%s] (%.0f st)", matId, getNodeDimName(targetObj), dist))
					collectMaterialNode(targetObj, targetPos, false, myRunId)
				else
					matStatusLabel:Set("Đang quét... (chờ stream/spawn node)")
					task.wait(0.4)
				end
			else
				matStatusLabel:Set("Đang chờ nhân vật...")
			end
			task.wait(lootLoopInterval)
		end
		releaseActivePrompt()
	end)
end

matTab:AddToggle({
	Name = "Bật Auto Material / Loot",
	Description = "Liên tục tìm, giữ prompt/đào & xoay vòng Material",
	Default = false,
	Callback = function(on)
		autoLootEnabled = on
		if on then
			startAutoLootLoop()
			Menu:Notify("Auto Loot", "Đang chạy: " .. selectedMatOption, 2.2)
		else
			lootRunId = lootRunId + 1
			releaseActivePrompt()
			stopCharacterMovement()
			matStatusLabel:Set("Trạng thái: Đang tắt")
			Menu:Notify("Auto Loot", "Đã tắt Auto Material / Loot.", 2)
		end
	end,
})

matTab:AddSlider({
	Name = "Chu kỳ Auto Loot",
	Min = 0.10,
	Max = 1.00,
	Default = 0.25,
	Step = 0.05,
	Suffix = "s",
	Callback = function(val)
		lootLoopInterval = val
	end,
})

matTab:AddSlider({
	Name = "Phạm vi đi bộ",
	Min = 15,
	Max = 500,
	Default = 200,
	Step = 5,
	Suffix = " st",
	Callback = function(val)
		lootMaxRange = val
	end,
})

matTab:AddSection("NGUỒN MAP")

matTab:AddButton({
	Name = "Quét lại Node trên Map",
	Description = "Làm mới cache các node đã stream & đếm kết quả",
	Callback = function()
		local allNodes = rebuildMaterialCache(true)
		local matched = 0
		for _, obj in ipairs(allNodes) do
			if matchMaterialTarget(obj) then
				matched = matched + 1
			end
		end
		matStatusLabel:Set(string.format("Đã tải: %d khớp (%d node đang stream)", matched, #allNodes))
	end,
})

matTab:AddInput({
	Name = "Folder Tài nguyên",
	Placeholder = "DroppedLoot, Nodes, QuestIngredients",
	Default = "DroppedLoot, Nodes, QuestIngredients",
	Callback = function(txt)
		lootFolderNames = txt
		lastCacheRebuildAt = 0
	end,
})

matTab:AddInput({
	Name = "Tag Tài nguyên",
	Placeholder = "OreNode, QuestIngredient",
	Default = "OreNode, QuestIngredient",
	Callback = function(txt)
		lootTagNames = txt
		lastCacheRebuildAt = 0
	end,
})

onMenuDestroy(function()
	if autoLootEnabled then
		autoLootEnabled = false
		lootRunId = lootRunId + 1
	end
	releaseActivePrompt()
	stopCharacterMovement()
	nodeCooldownUntil = {}
	cachedNodes = {}
end)
end

do
local craftTab = Menu:AddTab("Quick Craft", "⚒")
craftTab:AddSection("QUICK CRAFT (NO MINIGAME)")

local DEFAULT_RECIPES = {
	{ Id = "Flashlight", DisplayName = "Flashlight", IQ = 1, Cost = { Scrap = 3 } },
	{ Id = "MatFinder", DisplayName = "Material Finder", IQ = 1, Cost = { Scrap = 10 } },
	{ Id = "Pickaxe", DisplayName = "Pickaxe", IQ = 1, Cost = { Scrap = 8 } },
	{ Id = "LaserPistol", DisplayName = "Laser Pistol", IQ = 1, Cost = { Scrap = 5, Fleeb = 2 } },
	{ Id = "Plumbus", DisplayName = "Plumbus", IQ = 1, Cost = { Fleeb = 5, Flesh = 4 } },
	{ Id = "DarkMatterGrenade", DisplayName = "DarkMatter Grenade", IQ = 3, Cost = { DarkMatter = 6, Scrap = 4 } },
	{ Id = "MeeseeksBox", DisplayName = "Meeseeks Box", IQ = 5, Cost = { Scrap = 7, Fleeb = 4, Seed = 4 } },
	{ Id = "SlimeBlaster", DisplayName = "Slime Blaster", IQ = 8, Cost = { Brine = 7, Fleeb = 3, Scrap = 4 } },
	{ Id = "FreezeRay", DisplayName = "Freeze Ray", IQ = 11, Cost = { Ice = 8, Scrap = 5, Fleeb = 3 } },
	{ Id = "ShrinkRay", DisplayName = "Shrink Ray", IQ = 14, Cost = { Microchip = 6, Quantum = 3, Scrap = 4 } },
	{ Id = "TeleportRemote", DisplayName = "Teleport Remote", IQ = 17, Cost = { Void = 6, Microchip = 4 } },
	{ Id = "FloatBomb", DisplayName = "Float Bomb", IQ = 20, Cost = { Graviton = 5, Ember = 4 } },
	{ Id = "PlasmaShotgun", DisplayName = "Plasma Shotgun", IQ = 28, Cost = { Isotope = 4, Scrap = 5, Pearl = 2 } },
	{ Id = "GravityGun", DisplayName = "Gravity Gun", IQ = 32, Cost = { Graviton = 7, Scrap = 5, Microchip = 2 } },
	{ Id = "TeslaGun", DisplayName = "Tesla Gun", IQ = 36, Cost = { Token = 5, Magma = 4, Scrap = 4 } },
	{ Id = "SawBoomerang", DisplayName = "Buzzsaw Boomerang", IQ = 40, Cost = { Venom = 5, Scrap = 6, Toxin = 3, Cog = 3 } },
	{ Id = "MindBlower", DisplayName = "Mind Blower", IQ = 45, Cost = { Squanch = 5, Token = 5, Seed = 3 } },
	{ Id = "Forcefield", DisplayName = "Forcefield", IQ = 50, Cost = { Quantum = 6, Graviton = 4, Scrap = 6 } },
	{ Id = "HomingLauncher", DisplayName = "Homing Launcher", IQ = 56, Cost = { Isotope = 5, Cell = 4, Microchip = 3 } },
	{ Id = "DarkMatterMine", DisplayName = "DarkMatter Mine", IQ = 62, Cost = { Void = 4, DarkMatter = 4, Ember = 4 } },
	{ Id = "PortalHacker", DisplayName = "Portal Hacker", IQ = 69, Cost = { Microchip = 6, Quantum = 4, Token = 4, Void = 3 } },
	{ Id = "AkiraPalmLaser", DisplayName = "Akira Palm Laser", IQ = 77, Cost = { Solar = 8, Scrap = 6, DarkMatter = 3 } },
	{ Id = "MeteorCaller", DisplayName = "Meteor Caller", IQ = 88, Cost = { Pearl = 5, Toxin = 5, Magma = 4 } },
	{ Id = "TimeStopper", DisplayName = "Time Stopper", IQ = 105, Cost = { Quantum = 5, Void = 5, Token = 3, Cog = 4 } },
	{ Id = "DeathRay", DisplayName = "Death Ray", IQ = 125, Cost = { Cell = 6, Isotope = 5, Quantum = 4, Void = 3 } },
	{ Id = "RickPrimeBomb", DisplayName = "Rick Prime Bomb", IQ = 150, Cost = { DarkMatter = 9, Scrap = 7, Flesh = 6, Seed = 4 } },
	{ Id = "JetPack", DisplayName = "Rocket Boots", IQ = 175, Cost = { Magma = 6, Feather = 4, Scrap = 6 } },
	{ Id = "ZapperDrone", DisplayName = "Prime Bots", IQ = 190, Cost = { Microchip = 12, Cog = 10, Scrap = 20, Solar = 5 } },
	{ Id = "FFDeactivator", DisplayName = "FF Deactivator", IQ = 200, Cost = { Microchip = 12, Graviton = 8, DarkMatter = 6, Scrap = 15 } },
	{ Id = "PlasmaRifle", DisplayName = "Plasma Rifle", IQ = 265, Cost = { Isotope = 12, Quantum = 8, Void = 6, Scrap = 20 } },
	{ Id = "EvilEyepatch", DisplayName = "Evil Eyepatch", IQ = 385, Cost = { Cog = 40, Microchip = 25, Quantum = 15, DarkMatter = 10 } },
	{ Id = "PortalGunBody", DisplayName = "Portal Gun Body", IQ = 1, Cost = {}, Quest = true },
	{ Id = "PortalFluid", DisplayName = "Portal Fluid", IQ = 1, Cost = {}, Quest = true },
	{ Id = "PortalGun", DisplayName = "Portal Gun", IQ = 1, Cost = {}, Quest = true },
}

local DISPLAY_OVERRIDES = {
	DarkMatterGrenade = "DarkMatter Grenade",
	DarkMatterMine = "DarkMatter Mine",
	PortalHacker = "Portal Hacker",
	FFDeactivator = "FF Deactivator",
	HomingLauncher = "Homing Launcher",
	EvilEyepatch = "Evil Eyepatch",
	MatFinder = "Material Finder",
}

local CRAFT_RECIPES = {}
local CRAFT_RECIPES_BY_ID = {}
local CRAFT_OPTIONS = {}
local OPTION_TO_RECIPE_ID = {}

local function registerRecipe(id, displayName, iq, cost, isQuest)
	if CRAFT_RECIPES_BY_ID[id] then
		return
	end
	local shortName = DISPLAY_OVERRIDES[id] or displayName or id
	local entry = {
		Id = id,
		DisplayName = shortName,
		IQ = iq or 1,
		Cost = cost or {},
		Quest = isQuest == true,
	}
	table.insert(CRAFT_RECIPES, entry)
	CRAFT_RECIPES_BY_ID[id] = entry
	table.insert(CRAFT_OPTIONS, shortName)
	OPTION_TO_RECIPE_ID[shortName] = id
end

if gameRMShared and type(gameRMShared.Recipes) == "table" then
	local ordered = {}
	if type(gameRMShared.RecipeOrder) == "table" then
		for _, k in ipairs(gameRMShared.RecipeOrder) do
			table.insert(ordered, k)
		end
	end
	for k in pairs(gameRMShared.Recipes) do
		if k ~= "MaterialFinder" and not table.find(ordered, k) then
			table.insert(ordered, k)
		end
	end
	for _, key in ipairs(ordered) do
		local r = gameRMShared.Recipes[key]
		if type(r) == "table" and r.pass == nil then
			local iq = (type(gameRMShared.iqReq) == "function") and gameRMShared.iqReq(key) or 1
			local fallbackDef = nil
			for _, dr in ipairs(DEFAULT_RECIPES) do
				if dr.Id == key then
					fallbackDef = dr
					break
				end
			end
			local cleanTitle = (fallbackDef and fallbackDef.DisplayName) or (type(r.tool) == "string" and r.tool) or tostring(r.name or key)
			registerRecipe(key, cleanTitle, iq, r.cost or {}, r.quest ~= nil)
		end
	end
end

for _, dr in ipairs(DEFAULT_RECIPES) do
	registerRecipe(dr.Id, dr.DisplayName, dr.IQ, dr.Cost, dr.Quest)
end

local selectedRecipeOption = CRAFT_OPTIONS[1] or "Flashlight"
local quickCraftMode = "Tự động (Pass 0s / Chuẩn 6.2s)"
local hookGameCraftEnabled = true
local autoTpWorkbench = true
local craftBatchCount = 1
local autoCraftAllMode = false
local autoCraftLoop = false
local craftBusy = false
local craftRunId = 0
local totalCraftedCount = 0

local placeCraftCount = #CRAFT_RECIPES
local craftStatusLabel = craftTab:AddLabel(string.format("Sẵn sàng Quick Craft | %d món (trừ Gamepass)", placeCraftCount))
local craftInvLabel = craftTab:AddLabel("Kho: Đang đồng bộ...")
local quickMeter = craftTab:AddMiniMeter({ Name = "Craft", Title = "QUICK CRAFT STATUS" })

local function invokeCraftRemoteTimeout(actionName, recipeId, timeoutSec)
	local craftFn = ReplicatedStorage:FindFirstChild("CraftFunction")
	if not craftFn or not craftFn:IsA("RemoteFunction") then
		return false, "KHÔNG TÌM THẤY CraftFunction"
	end
	local done = false
	local okCall, res1, res2 = false, nil, nil
	local startT = clockNow()

	task.spawn(function()
		local ok, a, b = pcall(function()
			return craftFn:InvokeServer(actionName, recipeId)
		end)
		if not done then
			done = true
			okCall, res1, res2 = ok, a, b
		end
	end)

	local limit = timeoutSec or 5.0
	while not done and (clockNow() - startT) < limit do
		if destroyed then
			done = true
			return false, "CANCELLED"
		end
		task.wait(0.03)
	end
	if not done then
		done = true
		return false, "SERVER_TIMEOUT"
	end
	if not okCall then
		return false, tostring(res1 or "REMOTE_ERROR")
	end
	return res1 == true, tostring(res2 or (res1 and "OK" or "SERVER_REJECTED"))
end

local function isQuestRecipeDone(recipeId)
	if recipeId == "PortalGunBody" then
		return getRealMatCount("GunBody") >= 1 or localPlayer:GetAttribute("PortalGunLocked") ~= true
	elseif recipeId == "PortalFluid" then
		return getRealMatCount("PortalFluid") >= 1 or localPlayer:GetAttribute("PortalGunLocked") ~= true
	elseif recipeId == "PortalGun" then
		return localPlayer:GetAttribute("PortalGunLocked") ~= true
	end
	return false
end

local function canCraftRecipeReal(recipe)
	if not recipe then
		return false, "CÔNG THỨC KHÔNG TỒN TẠI"
	end
	if recipe.Quest and isQuestRecipeDone(recipe.Id) then
		return false, "ĐÃ XONG QUEST NÀY"
	end
	local myIQ = getRealIQLevel()
	if myIQ < (recipe.IQ or 1) then
		return false, string.format("THIẾU IQ (%d/%d)", myIQ, recipe.IQ or 1)
	end
	for matId, need in pairs(recipe.Cost) do
		local have = getRealMatCount(matId)
		if have < need then
			return false, string.format("THIẾU %s (%d/%d)", matId, have, need)
		end
	end
	return true, "ĐỦ ĐIỀU KIỆN"
end

local function refreshCraftInventoryLabel()
	local recipeId = OPTION_TO_RECIPE_ID[selectedRecipeOption] or "Flashlight"
	local recipe = CRAFT_RECIPES_BY_ID[recipeId]
	local reqParts = {}
	if recipe then
		local keys = {}
		for matId in pairs(recipe.Cost) do
			table.insert(keys, matId)
		end
		table.sort(keys)
		for _, matId in ipairs(keys) do
			local need = recipe.Cost[matId]
			table.insert(reqParts, string.format("%s:%d/%d", matId, getRealMatCount(matId), need))
		end
	end
	local reqStr = #reqParts > 0 and table.concat(reqParts, " ") or "Miễn phí"
	local owned = getRealItemCount(recipeId)
	local okCond, _ = canCraftRecipeReal(recipe)
	local tag = okCond and "ĐỦ" or "THIẾU"
	craftInvLabel:Set(
		string.format(
			"%s [%s | IQ %d/%d] (%s) • Có:%d | Crafted:%d",
			selectedRecipeOption,
			tag,
			getRealIQLevel(),
			recipe and recipe.IQ or 1,
			reqStr,
			owned,
			totalCraftedCount
		)
	)
end
SharedState.RefreshCraftUi = refreshCraftInventoryLabel

local function moveNearOwnWorkbench(forceSyncWait)
	if not autoTpWorkbench then
		return true
	end
	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local targetBenchPos = findOwnCraftStationPos()
	if not targetBenchPos then
		return true
	end
	if (targetBenchPos - root.Position).Magnitude > 5.5 or forceSyncWait then
		teleportCharacterTo(targetBenchPos, Vector3.new(0, 2.2, 2.8), targetBenchPos, 2.2)
		task.wait(0.4)
		pcall(function()
			RunService.Heartbeat:Wait()
		end)
	end
	return true
end

local function hasGameQuickCraftPass()
	if gameRMShared and type(gameRMShared.passOn) == "function" then
		local ok, has = pcall(gameRMShared.passOn, localPlayer, "QuickCraft")
		if ok and has == true then
			return true
		end
	end
	return (localPlayer:GetAttribute("Pass_QuickCraft") == true or localPlayer:GetAttribute("Own_QuickCraft") == true)
		and localPlayer:GetAttribute("PassOff_QuickCraft") ~= true
end

local function getCraftServerWaitSeconds()
	local baseMin = (gameRMShared and tonumber(gameRMShared.CRAFT_MIN_TIME)) or 6
	if hasGameQuickCraftPass() then
		return 0
	end
	if quickCraftMode == "Ép 0s (Thử Pass)" then
		return 0
	end
	return baseMin + 0.25
end

local function waitCraftProgress(durationSec, badgeText, targetName, expectedRunId)
	if durationSec <= 0 then
		return true
	end
	local startWait = clockNow()
	while (clockNow() - startWait) < durationSec do
		if destroyed or (expectedRunId and expectedRunId ~= craftRunId) then
			return false
		end
		local alpha = math.clamp((clockNow() - startWait) / durationSec, 0.25, 0.96)
		local remain = math.max(0, durationSec - (clockNow() - startWait))
		quickMeter:SetState(badgeText, THEME.Accent, alpha, string.format("Bỏ 3D • Chờ Server %.1fs -> %s", remain, targetName))
		task.wait(0.08)
	end
	return true
end

local function executeCraftStepRemote(stepId, stepName, expectedRunId)
	quickMeter:SetState("BEGIN...", THEME.Accent, 0.25, "Gửi beginCraft -> " .. stepName)
	local okBegin, msgBegin = invokeCraftRemoteTimeout("beginCraft", stepId, 5.0)
	if not okBegin then
		local lowBegin = string.lower(msgBegin or "")
		local distIssue = string.find(lowBegin, "far", 1, true)
			or string.find(lowBegin, "near", 1, true)
			or string.find(lowBegin, "close", 1, true)
			or string.find(lowBegin, "bench", 1, true)
			or string.find(lowBegin, "station", 1, true)
			or string.find(lowBegin, "dist", 1, true)
			or string.find(lowBegin, "range", 1, true)
			or string.find(lowBegin, "move", 1, true)
		if distIssue and autoTpWorkbench then
			quickMeter:SetState("ĐỒNG BỘ TP", THEME.Accent, 0.2, "Chờ đồng bộ Workbench -> thử lại")
			moveNearOwnWorkbench(true)
			okBegin, msgBegin = invokeCraftRemoteTimeout("beginCraft", stepId, 5.0)
		end
	end
	if not okBegin then
		quickMeter:SetState("TỪ CHỐI", THEME.TextSecondary, 0, "beginCraft: " .. msgBegin)
		return false, msgBegin
	end

	local waitSec = getCraftServerWaitSeconds()
	if waitSec > 0 then
		if not waitCraftProgress(waitSec, "QUICK WAIT", stepName, expectedRunId) then
			return false, "CANCELLED"
		end
	end

	quickMeter:SetState("CRAFTING...", THEME.Accent, 0.9, "Gửi craft -> " .. stepName)
	local okCraft, msgCraft = invokeCraftRemoteTimeout("craft", stepId, 5.0)

	if not okCraft and waitSec == 0 and msgCraft ~= "SERVER_TIMEOUT" and msgCraft ~= "CANCELLED" then
		local lowMsg = string.lower(msgCraft or "")
		local hardBlock = string.find(lowMsg, "iq", 1, true)
			or string.find(lowMsg, "material", 1, true)
			or string.find(lowMsg, "already", 1, true)
			or string.find(lowMsg, "pass", 1, true)
		if not hardBlock then
			local baseMin = (gameRMShared and tonumber(gameRMShared.CRAFT_MIN_TIME)) or 6
			quickMeter:SetState("THỬ 6.2S", THEME.Accent, 0.2, "Server từ chối 0s -> thử lại chuẩn " .. (baseMin + 0.25) .. "s")
			local okRetryBegin = invokeCraftRemoteTimeout("beginCraft", stepId, 5.0)
			if okRetryBegin then
				if not waitCraftProgress(baseMin + 0.25, "AUTO 6.2S", stepName, expectedRunId) then
					return false, "CANCELLED"
				end
				okCraft, msgCraft = invokeCraftRemoteTimeout("craft", stepId, 5.0)
			end
		end
	end

	return okCraft, msgCraft
end

local function performSingleQuickCraft(recipe, expectedRunId)
	local okCond, condMsg = canCraftRecipeReal(recipe)
	if not okCond then
		return false, condMsg
	end

	moveNearOwnWorkbench()

	if recipe.Id == "PortalGun" and localPlayer:GetAttribute("PortalGunLocked") == true then
		local steps = (gameRMShared and type(gameRMShared.PortalGunSteps) == "table" and gameRMShared.PortalGunSteps)
			or { "PortalGunBody", "PortalFluid", "PortalGun" }
		local lastMsg = "OK"
		for _, stepId in ipairs(steps) do
			if destroyed or (expectedRunId and expectedRunId ~= craftRunId) then
				return false, "CANCELLED"
			end
			if stepId == "PortalGun" or not isQuestRecipeDone(stepId) then
				local stepName = (CRAFT_RECIPES_BY_ID[stepId] and CRAFT_RECIPES_BY_ID[stepId].DisplayName) or stepId
				local okStep, msgStep = executeCraftStepRemote(stepId, stepName, expectedRunId)
				if not okStep then
					quickMeter:SetState("LỖI QUEST", THEME.TextSecondary, 0, msgStep)
					refreshCraftInventoryLabel()
					return false, msgStep
				end
				lastMsg = msgStep
			end
		end
		totalCraftedCount = totalCraftedCount + 1
		quickMeter:SetState("QUICK OK!", THEME.Success, 1, string.format("Xong Portal Gun | Tổng craft: %d", totalCraftedCount))
		refreshCraftInventoryLabel()
		return true, lastMsg
	end

	local okStep, msgStep = executeCraftStepRemote(recipe.Id, recipe.DisplayName, expectedRunId)
	if okStep then
		totalCraftedCount = totalCraftedCount + 1
		quickMeter:SetState("QUICK OK!", THEME.Success, 1, string.format("Xong %s | Tổng craft: %d", recipe.DisplayName, totalCraftedCount))
		refreshCraftInventoryLabel()
		return true, msgStep
	end

	quickMeter:SetState("LỖI CRAFT", THEME.TextSecondary, 0, msgStep)
	refreshCraftInventoryLabel()
	return false, msgStep
end

local function executeQuickCraftBatch(desiredCount, expectedRunId, overrideRecipeId)
	if craftBusy then
		return false, "ĐANG CRAFT..."
	end
	craftBusy = true

	local recipeId = overrideRecipeId or OPTION_TO_RECIPE_ID[selectedRecipeOption] or "Flashlight"
	local recipe = CRAFT_RECIPES_BY_ID[recipeId]
	local t0 = clockNow()
	local doneCount = 0
	local lastErr = nil

	for _ = 1, math.clamp(math.floor(desiredCount or 1), 1, 100) do
		if destroyed or (expectedRunId and expectedRunId ~= craftRunId) then
			craftBusy = false
			return false, "ĐÃ HỦY"
		end
		local okOne, msgOne = performSingleQuickCraft(recipe, expectedRunId)
		if not okOne then
			lastErr = msgOne
			break
		end
		doneCount = doneCount + 1
		task.wait(0.05)
	end

	craftBusy = false
	refreshCraftInventoryLabel()
	if doneCount == 0 then
		return false, tostring(lastErr or "KHÔNG THỂ CRAFT")
	end
	local ms = math.max(1, math.round((clockNow() - t0) * 1000))
	return true, string.format("Quick Craft xong %dx %s (%d ms)", doneCount, recipe.DisplayName, ms)
end

local function executeQuickCraftAll(expectedRunId)
	local typesDone = 0
	local lastErr = nil
	local t0 = clockNow()
	for _, recipe in ipairs(CRAFT_RECIPES) do
		if destroyed or (expectedRunId and expectedRunId ~= craftRunId) then
			break
		end
		local okCond = canCraftRecipeReal(recipe)
		if okCond then
			local okBatch, errBatch = executeQuickCraftBatch(craftBatchCount, expectedRunId, recipe.Id)
			if okBatch then
				typesDone = typesDone + 1
			else
				lastErr = errBatch
				if errBatch == "SERVER_TIMEOUT" or errBatch == "KHÔNG TÌM THẤY CraftFunction" then
					return false, errBatch
				end
			end
		end
	end
	if typesDone == 0 then
		return false, lastErr or "CHƯA CÓ MÓN NÀO ĐỦ IQ & MATERIAL"
	end
	local ms = math.max(1, math.round((clockNow() - t0) * 1000))
	return true, string.format("Quick Craft %d loại (%d ms)", typesDone, ms)
end

local origAssemblyInvoke = nil
local assemblyHookActive = false
local hasGetCallbackValue = (type(getcallbackvalue) == "function")

local function shadowAssemblyHandler(recipeKey)
	if destroyed or not hookGameCraftEnabled then
		if origAssemblyInvoke then
			return origAssemblyInvoke(recipeKey)
		end
		return false
	end
	assemblyHookActive = true
	local labelName = (CRAFT_RECIPES_BY_ID[recipeKey] and CRAFT_RECIPES_BY_ID[recipeKey].DisplayName) or tostring(recipeKey or "Item")
	local waitSec = getCraftServerWaitSeconds()
	Menu:Notify("Quick Craft Hook", "Đã bỏ minigame 3D -> " .. labelName .. (waitSec > 0 and string.format(" (%.1fs)", waitSec) or " (0s)"), 2.2)
	if waitSec > 0 then
		if not waitCraftProgress(waitSec, "HOOK 3D SKIP", labelName, nil) then
			assemblyHookActive = false
			return false
		end
	else
		quickMeter:SetState("HOOK 3D SKIP", THEME.Success, 1, "Đã bỏ Minigame 3D -> " .. labelName)
	end
	assemblyHookActive = false
	return true
end

local function applyCraftAssemblyHook(enableHook)
	local targetObj = ReplicatedStorage:FindFirstChild("CraftAssembly")
	if not targetObj or not targetObj:IsA("BindableFunction") then
		return
	end
	if enableHook then
		if hasGetCallbackValue then
			local okCb, cb = pcall(getcallbackvalue, targetObj, "OnInvoke")
			if okCb and type(cb) == "function" and cb ~= shadowAssemblyHandler then
				origAssemblyInvoke = cb
			end
			if okCb and cb == shadowAssemblyHandler then
				return
			end
		end
		if not assemblyHookActive then
			targetObj.OnInvoke = shadowAssemblyHandler
		end
	elseif origAssemblyInvoke then
		targetObj.OnInvoke = origAssemblyInvoke
	end
end

if hookGameCraftEnabled then
	applyCraftAssemblyHook(true)
end

track(ReplicatedStorage.ChildAdded:Connect(function(child)
	if not destroyed and hookGameCraftEnabled and child.Name == "CraftAssembly" and child:IsA("BindableFunction") then
		task.delay(0.1, function()
			if not destroyed and hookGameCraftEnabled then
				applyCraftAssemblyHook(true)
			end
		end)
	end
end))

task.spawn(function()
	for _, d in ipairs({ 0.4, 1.2, 2.5, 5.0 }) do
		task.wait(d)
		if destroyed then
			return
		end
		if hookGameCraftEnabled then
			applyCraftAssemblyHook(true)
		end
	end
	while not destroyed do
		if hookGameCraftEnabled and not assemblyHookActive then
			applyCraftAssemblyHook(true)
		end
		task.wait(1.5)
	end
end)

craftTab:AddDropdown({
	Name = "Chọn Công thức",
	Options = CRAFT_OPTIONS,
	Default = selectedRecipeOption,
	Callback = function(opt)
		selectedRecipeOption = opt
		local r = CRAFT_RECIPES_BY_ID[OPTION_TO_RECIPE_ID[opt] or "Flashlight"]
		local okCond, condMsg = canCraftRecipeReal(r)
		quickMeter:SetState(okCond and "ĐỦ ĐỒ" or "CHỜ ĐỒ", okCond and THEME.Success or THEME.AccentDim, okCond and 1 or 0, condMsg .. " | Crafted: " .. totalCraftedCount)
		refreshCraftInventoryLabel()
	end,
})

craftTab:AddDropdown({
	Name = "Chế độ Quick Craft",
	Options = { "Tự động (Pass 0s / Chuẩn 6.2s)", "Chuẩn Server (6.2s)", "Ép 0s (Thử Pass)" },
	Default = "Tự động (Pass 0s / Chuẩn 6.2s)",
	Callback = function(opt)
		quickCraftMode = opt
		craftStatusLabel:Set("Chế độ Quick Craft: " .. opt)
	end,
})

craftTab:AddToggle({
	Name = "Hook nút CRAFT Game (Bỏ 3D)",
	Description = "Bấm CRAFT trên bàn Workbench tự bỏ minigame 3D",
	Default = true,
	Callback = function(on)
		hookGameCraftEnabled = on
		applyCraftAssemblyHook(on)
		craftStatusLabel:Set(on and "Đã bật Hook nút CRAFT Workbench (Bỏ 3D)" or "Đã tắt Hook nút CRAFT Game")
	end,
})

craftTab:AddToggle({
	Name = "TP tới Workbench trước khi Craft",
	Description = "Tự dịch chuyển sát CraftStation (< 5.5 st)",
	Default = true,
	Callback = function(on)
		autoTpWorkbench = on
	end,
})

craftTab:AddSlider({
	Name = "Số lượng / lần bấm",
	Min = 1,
	Max = 50,
	Default = 1,
	Step = 1,
	Suffix = "x",
	Callback = function(val)
		craftBatchCount = val
	end,
})

craftTab:AddButton({
	Name = "Quick Craft Ngay",
	Description = "Gửi Server craft món đang chọn & bỏ mini-game 3D",
	Callback = function()
		task.spawn(function()
			craftStatusLabel:Set("Đang Quick Craft: " .. selectedRecipeOption .. "...")
			Menu:Notify("Quick Craft", "Đang bắt đầu: " .. selectedRecipeOption, 1.8)
			local ok, msg = executeQuickCraftBatch(craftBatchCount, nil, nil)
			craftStatusLabel:Set((ok and "OK: " or "Thông báo: ") .. msg)
			Menu:Notify(ok and "Quick Craft Xong" or "Quick Craft Lỗi", msg, 2.5)
		end)
	end,
})

craftTab:AddButton({
	Name = "Quick Craft Tất Cả Đủ Đồ",
	Description = "Quét 34 công thức thường (trừ Gamepass) & craft ngay",
	Callback = function()
		task.spawn(function()
			craftStatusLabel:Set("Đang quét 34 công thức không Gamepass...")
			Menu:Notify("Quick Craft", "Đang quét tất cả món đủ đồ...", 2)
			local ok, msg = executeQuickCraftAll(nil)
			craftStatusLabel:Set((ok and "OK: " or "Thông báo: ") .. msg)
			Menu:Notify(ok and "Quick Craft Xong" or "Quick Craft", msg, 2.5)
		end)
	end,
})

craftTab:AddToggle({
	Name = "Auto Quick Craft mọi món đủ đồ",
	Description = "Khi bật Loop sẽ quét tất cả công thức hợp lệ",
	Default = false,
	Callback = function(on)
		autoCraftAllMode = on
	end,
})

local autoCraftToggle
autoCraftToggle = craftTab:AddToggle({
	Name = "Bật Auto Quick Craft Loop",
	Description = "Tự động Quick Craft liên tục khi đủ Material & IQ",
	Default = false,
	Callback = function(on)
		autoCraftLoop = on
		craftRunId = craftRunId + 1
		local myId = craftRunId
		if not on then
			craftStatusLabel:Set("Auto Quick Craft: Đã dừng")
			return
		end
		Menu:Notify("Quick Craft Loop", autoCraftAllMode and "Đang chạy Auto All..." or ("Đang auto: " .. selectedRecipeOption), 2.2)
		task.spawn(function()
			while autoCraftLoop and not destroyed and myId == craftRunId do
				local ok, msg
				if autoCraftAllMode then
					ok, msg = executeQuickCraftAll(myId)
				else
					ok, msg = executeQuickCraftBatch(craftBatchCount, myId, nil)
				end
				craftStatusLabel:Set((ok and "Auto OK: " or "Dừng: ") .. msg)
				if not ok and (msg == "SERVER_TIMEOUT" or msg == "KHÔNG TÌM THẤY CraftFunction") then
					autoCraftLoop = false
					if autoCraftToggle then
						autoCraftToggle:Set(false, false)
					end
					Menu:Notify("Quick Craft Dừng", msg, 2.5)
					break
				end
				task.wait(ok and 0.15 or 0.9)
			end
		end)
	end,
})

craftTab:AddButton({
	Name = "Kiểm tra món đủ đồ ngay",
	Description = "Liệt kê những công thức thường đang đủ IQ & Material",
	Callback = function()
		local readyNames = {}
		for _, recipe in ipairs(CRAFT_RECIPES) do
			if canCraftRecipeReal(recipe) then
				table.insert(readyNames, recipe.DisplayName)
			end
		end
		if #readyNames > 0 then
			local summary = string.format("Đủ đồ (%d): %s", #readyNames, table.concat(readyNames, ", "))
			craftStatusLabel:Set(summary)
			Menu:Notify("Kiểm tra Craft", string.format("Có %d công thức thường đủ đồ!", #readyNames), 2.5)
		else
			craftStatusLabel:Set("Chưa có công thức thường nào đủ IQ & Material.")
			Menu:Notify("Kiểm tra Craft", "Chưa có món nào đủ IQ & Material.", 2.2)
		end
	end,
})

onMenuDestroy(function()
	autoCraftLoop = false
	craftBusy = false
	craftRunId = craftRunId + 1
	hookGameCraftEnabled = false
	applyCraftAssemblyHook(false)
end)
end

local lastMatCounts = {}
for attrName, attrVal in pairs(localPlayer:GetAttributes()) do
	if string.sub(attrName, 1, 4) == "Mat_" then
		lastMatCounts[attrName] = tonumber(attrVal) or 0
	end
end

track(localPlayer.AttributeChanged:Connect(function(attrName)
	if destroyed then
		return
	end
	if string.sub(attrName, 1, 4) == "Mat_" then
		local prevVal = lastMatCounts[attrName] or 0
		local newVal = tonumber(localPlayer:GetAttribute(attrName)) or 0
		lastMatCounts[attrName] = newVal
		if newVal > prevVal then
			SharedState.LootSessionCount = SharedState.LootSessionCount + 1
		end
		if SharedState.RefreshLootUi then
			SharedState.RefreshLootUi()
		end
		if SharedState.RefreshCraftUi then
			SharedState.RefreshCraftUi()
		end
	elseif attrName == "IQLevel" or string.sub(attrName, 1, 5) == "Item_" or attrName == "PortalGunLocked" then
		if SharedState.RefreshCraftUi then
			SharedState.RefreshCraftUi()
		end
	end
end))

task.defer(function()
	if SharedState.RefreshCraftUi then
		SharedState.RefreshCraftUi()
	end
	if SharedState.RefreshLootUi then
		SharedState.RefreshLootUi()
	end
end)

Menu:Notify("Shadow Menu", "Auto Loot & Quick Craft (" .. (UserInputService.TouchEnabled and "Mobile" or "PC") .. ") sẵn sàng!", 3)
