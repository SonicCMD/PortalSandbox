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
		title.Size = UDim2.new(0.54, 0, 1, 0)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamSemibold
		title.Text = opts.Name
		title.TextColor3 = THEME.TextPrimary
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.Parent = topBtn

		local currentLbl = Instance.new("TextLabel")
		currentLbl.Size = UDim2.new(0.46, -18, 1, 0)
		currentLbl.Position = UDim2.new(1, -18, 0, 0)
		currentLbl.AnchorPoint = Vector2.new(1, 0)
		currentLbl.BackgroundTransparency = 1
		currentLbl.Font = Enum.Font.GothamMedium
		currentLbl.Text = selected
		currentLbl.TextColor3 = THEME.AccentDim
		currentLbl.TextSize = 12
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
		titleLbl.Text = (opts and opts.Title) or "MINI-GAME CRAFT"
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
		zoneFrame.Size = UDim2.fromScale(0.24, 1)
		zoneFrame.Position = UDim2.fromScale(0.38, 0)
		zoneFrame.BackgroundColor3 = THEME.Success
		zoneFrame.BackgroundTransparency = 0.45
		zoneFrame.BorderSizePixel = 0
		zoneFrame.Parent = trackBar
		addCorner(zoneFrame, 4)

		local needle = Instance.new("Frame")
		needle.Size = UDim2.new(0, 4, 1, 0)
		needle.AnchorPoint = Vector2.new(0.5, 0)
		needle.Position = UDim2.fromScale(0.5, 0)
		needle.BackgroundColor3 = THEME.Accent
		needle.BorderSizePixel = 0
		needle.Parent = trackBar
		addCorner(needle, 2)

		local detailLbl = Instance.new("TextLabel")
		detailLbl.Size = UDim2.new(1, 0, 0, 15)
		detailLbl.Position = UDim2.fromOffset(0, 37)
		detailLbl.BackgroundTransparency = 1
		detailLbl.Font = Enum.Font.Gotham
		detailLbl.Text = "Bước: 0/0 | Pass: 0"
		detailLbl.TextColor3 = THEME.TextSecondary
		detailLbl.TextSize = 11
		detailLbl.TextXAlignment = Enum.TextXAlignment.Left
		detailLbl.TextTruncate = Enum.TextTruncate.AtEnd
		detailLbl.Parent = card

		local ctrl = {}
		function ctrl:SetState(stateText, color, zoneMin, zoneMax, needleAlpha, detailText)
			if stateText then
				stateLbl.Text = stateText
			end
			if color then
				stateLbl.TextColor3 = color
			end
			if zoneMin ~= nil and zoneMax ~= nil then
				local zMin = math.clamp(zoneMin, 0, 0.9)
				local zMax = math.clamp(zoneMax, zMin + 0.08, 1)
				zoneFrame.Position = UDim2.fromScale(zMin, 0)
				zoneFrame.Size = UDim2.fromScale(zMax - zMin, 1)
			end
			if needleAlpha ~= nil then
				local a = math.clamp(needleAlpha, 0, 1)
				needle.Position = UDim2.fromScale(a, 0)
				local inZone = zoneMin ~= nil and zoneMax ~= nil and a >= zoneMin and a <= zoneMax
				needle.BackgroundColor3 = inZone and THEME.Success or THEME.Accent
			end
			if detailText then
				detailLbl.Text = detailText
			end
		end
		return ctrl
	end

	return Tab
end

local MATERIAL_DEFS = {
	{ Id = "Quantum", Option = "Quantum • Ore", DisplayName = "Quantum Crystal", Kind = "Ore", Reward = 1 },
	{ Id = "Graviton", Option = "Graviton • Ore", DisplayName = "Graviton Shard", Kind = "Ore", Reward = 1 },
	{ Id = "Magma", Option = "Magma • Ore", DisplayName = "Molten Core", Kind = "Ore", Reward = 1 },
	{ Id = "Void", Option = "Void • Ore", DisplayName = "Void Essence", Kind = "Ore", Reward = 1 },
	{ Id = "Brine", Option = "Brine", DisplayName = "Brine", Kind = "Node", Reward = 1 },
	{ Id = "Cell", Option = "Cell", DisplayName = "Cell", Kind = "Node", Reward = 1 },
	{ Id = "Cog", Option = "Cog", DisplayName = "Cog", Kind = "Node", Reward = 1 },
	{ Id = "DarkMatter", Option = "DarkMatter", DisplayName = "DarkMatter", Kind = "Node", Reward = 1 },
	{ Id = "Ember", Option = "Ember", DisplayName = "Ember", Kind = "Node", Reward = 1 },
	{ Id = "Feather", Option = "Feather", DisplayName = "Feather", Kind = "Node", Reward = 1 },
	{ Id = "Fleeb", Option = "Fleeb", DisplayName = "Fleeb", Kind = "Node", Reward = 1 },
	{ Id = "Flesh", Option = "Flesh", DisplayName = "Flesh", Kind = "Node", Reward = 1 },
	{ Id = "Ice", Option = "Ice", DisplayName = "Ice", Kind = "Node", Reward = 1 },
	{ Id = "Isotope", Option = "Isotope", DisplayName = "Isotope", Kind = "Node", Reward = 1 },
	{ Id = "Microchip", Option = "Microchip", DisplayName = "Microchip", Kind = "Node", Reward = 1 },
	{ Id = "Pearl", Option = "Pearl", DisplayName = "Pearl", Kind = "Node", Reward = 1 },
	{ Id = "Scrap", Option = "Scrap", DisplayName = "Scrap", Kind = "Node", Reward = 2 },
	{ Id = "Seed", Option = "Seed", DisplayName = "Seed", Kind = "Node", Reward = 1 },
	{ Id = "Solar", Option = "Solar", DisplayName = "Solar", Kind = "Node", Reward = 1 },
	{ Id = "Squanch", Option = "Squanch", DisplayName = "Squanch", Kind = "Node", Reward = 1 },
	{ Id = "Toxin", Option = "Toxin", DisplayName = "Toxin", Kind = "Node", Reward = 1 },
	{ Id = "Venom", Option = "Venom", DisplayName = "Venom", Kind = "Node", Reward = 1 },
	{ Id = "GunBody", Option = "GunBody", DisplayName = "GunBody", Kind = "Special", Reward = 1 },
	{ Id = "PortalFluid", Option = "PortalFluid", DisplayName = "PortalFluid", Kind = "Special", Reward = 1 },
	{ Id = "Token", Option = "Token", DisplayName = "Token", Kind = "Special", Reward = 1 },
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
	LootTotal = 0,
	LootCounts = {},
	AddCraftStock = nil,
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

local function getWorldPosition(obj)
	if not obj or not obj.Parent then
		return nil
	end
	if obj:IsA("BasePart") then
		return obj.Position
	elseif obj:IsA("Tool") then
		local handle = obj:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			return handle.Position
		end
		local part = obj:FindFirstChildWhichIsA("BasePart", true)
		return part and part.Position or nil
	elseif obj:IsA("Model") then
		local part = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.Position
		end
		return obj:GetPivot().Position
	end
	return nil
end

local function teleportCharacterTo(worldPos)
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not char or not hum or not root or hum.Health <= 0 then
		return false
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	char:PivotTo(CFrame.new(worldPos + Vector3.new(0, 4, 0)))
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

local function equipAndActivateTool(char, hum, preferredName)
	local equipped = char:FindFirstChildOfClass("Tool")
	if preferredName and (not equipped or not string.find(string.lower(equipped.Name), string.lower(preferredName), 1, true)) then
		local backpack = localPlayer:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") and string.find(string.lower(item.Name), string.lower(preferredName), 1, true) then
					hum:EquipTool(item)
					equipped = item
					break
				end
			end
		end
	end
	if not equipped then
		local backpack = localPlayer:FindFirstChildOfClass("Backpack")
		local firstTool = backpack and backpack:FindFirstChildOfClass("Tool")
		if firstTool then
			hum:EquipTool(firstTool)
			equipped = firstTool
		end
	end
	if equipped then
		pcall(function()
			equipped:Activate()
		end)
	end
end

do
local matTab = Menu:AddTab("Auto Loot", "★")
matTab:AddSection("AUTO LOOT MATERIAL")

local selectedMatOption = "Tất cả Material"
local customMatFilter = ""
local teleportToMatEnabled = true
local autoLootEnabled = false
local autoPromptEnabled = true
local autoSwingToolEnabled = true
local includeDimensionsScan = true
local lootMaxRange = 200
local lootLoopInterval = 0.22
local lootFolderNames = "DroppedLoot, Nodes"
local lootTagNames = "OreNode"
local lootRunId = 0
local lastPromptAt = {}
local nodeCooldownUntil = {}
local cachedNodes = {}
local lastCacheRebuildAt = 0
local watchedNodes = {}
local nodeWatchConns = {}

local matStatusLabel = matTab:AddLabel("Sẵn sàng | 25 Material & Dimensions")
local lootStatsLabel = matTab:AddLabel("Đã thu thập: 0 | Chưa có")

local function refreshLootStatsLabel()
	local topParts = {}
	for _, m in ipairs(MATERIAL_DEFS) do
		local c = SharedState.LootCounts[m.Id] or 0
		if c > 0 then
			table.insert(topParts, m.Id .. ":" .. c)
			if #topParts >= 4 then
				break
			end
		end
	end
	local matSummary = #topParts > 0 and table.concat(topParts, " ") or "Chưa có"
	lootStatsLabel:Set(string.format("Đã thu thập: %d | %s", SharedState.LootTotal, matSummary))
end
SharedState.RefreshLootUi = refreshLootStatsLabel

local function detectObjectMaterialDef(obj)
	local attrMat = obj:GetAttribute("Material") or obj:GetAttribute("MaterialId")
	if attrMat then
		local found = MATERIAL_BY_ID[tostring(attrMat)]
		if found then
			return found
		end
	end
	local attrText = string.lower(tostring(obj:GetAttribute("Text") or obj:GetAttribute("MaterialName") or ""))
	local lowerName = string.lower(obj.Name)
	for _, m in ipairs(MATERIAL_DEFS) do
		local idLow = string.lower(m.Id)
		if string.find(lowerName, idLow, 1, true) or string.find(attrText, idLow, 1, true) then
			return m
		end
	end
	return nil
end

local function isNodeAvailable(obj)
	if not obj or not obj.Parent or isCharacterPart(obj) then
		return false
	end
	if obj:GetAttribute("Claimed") == true or obj:GetAttribute("Broken") == true or obj:GetAttribute("Disabled") == true then
		return false
	end
	return true
end

local function rebuildMaterialCache(force)
	local now = clockNow()
	if not force and (now - lastCacheRebuildAt) < 1.8 and #cachedNodes > 0 then
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

	if includeDimensionsScan then
		local dims = Workspace:FindFirstChild("Dimensions")
		if dims then
			for _, dim in ipairs(dims:GetChildren()) do
				for _, subName in ipairs({ "Nodes", "Ores", "Cave", "CaveMouths", "Props" }) do
					local sub = dim:FindFirstChild(subName)
					if sub then
						for _, child in ipairs(sub:GetChildren()) do
							if child:GetAttribute("Material") ~= nil or child:GetAttribute("MaterialId") ~= nil or CollectionService:HasTag(child, "OreNode") then
								addCandidate(child)
							end
						end
					end
				end
				for _, child in ipairs(dim:GetChildren()) do
					if child:GetAttribute("Material") ~= nil or child:GetAttribute("MaterialId") ~= nil then
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

	local rawAttr = tostring(obj:GetAttribute("Material") or obj:GetAttribute("MaterialId") or "")
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
			local pos = getWorldPosition(obj)
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

local function clearNodeWatchers()
	for _, conn in ipairs(nodeWatchConns) do
		disconnectSafe(conn)
	end
	nodeWatchConns = {}
	watchedNodes = {}
end

local function watchNodeCollected(node)
	if watchedNodes[node] or not node or not node.Parent then
		return
	end
	watchedNodes[node] = true

	local matDef = detectObjectMaterialDef(node)
	local matId = matDef and matDef.Id or tostring(node:GetAttribute("Material") or node:GetAttribute("MaterialId") or "Scrap")
	local reward = matDef and matDef.Reward or 1
	local collected = false
	local localConns = {}

	local function finishWatch(awarded)
		if collected then
			return
		end
		collected = true
		watchedNodes[node] = nil
		for _, c in ipairs(localConns) do
			disconnectSafe(c)
		end
		if awarded and not destroyed then
			SharedState.LootTotal = SharedState.LootTotal + reward
			SharedState.LootCounts[matId] = (SharedState.LootCounts[matId] or 0) + reward
			if SharedState.AddCraftStock then
				SharedState.AddCraftStock(matId, reward)
			end
			refreshLootStatsLabel()
			lastCacheRebuildAt = 0
		end
	end

	local function checkState()
		if destroyed or not node.Parent or node:GetAttribute("Claimed") == true or node:GetAttribute("Broken") == true then
			finishWatch(not destroyed)
		end
	end

	local c1 = node.AncestryChanged:Connect(checkState)
	local c2 = node:GetAttributeChangedSignal("Claimed"):Connect(checkState)
	local c3 = node:GetAttributeChangedSignal("Broken"):Connect(checkState)
	table.insert(localConns, c1)
	table.insert(localConns, c2)
	table.insert(localConns, c3)
	table.insert(nodeWatchConns, c1)
	table.insert(nodeWatchConns, c2)
	table.insert(nodeWatchConns, c3)

	task.delay(6, function()
		finishWatch(false)
	end)
end

local function triggerValidPrompt(targetObj, rootPos)
	if not autoPromptEnabled or not targetObj then
		return
	end
	local prompt = targetObj:IsA("ProximityPrompt") and targetObj or targetObj:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt or not prompt.Enabled then
		return
	end
	local now = clockNow()
	if lastPromptAt[prompt] and (now - lastPromptAt[prompt]) < 0.7 then
		return
	end
	local parentPart = prompt.Parent
	local promptPos = (parentPart and parentPart:IsA("BasePart")) and parentPart.Position or (getWorldPosition(targetObj) or rootPos)
	if (promptPos - rootPos).Magnitude <= (prompt.MaxActivationDistance + 2) then
		lastPromptAt[prompt] = now
		task.spawn(function()
			pcall(function()
				prompt:InputHoldBegin()
				if prompt.HoldDuration > 0 then
					task.wait(prompt.HoldDuration + 0.05)
				else
					task.wait(0.05)
				end
				prompt:InputHoldEnd()
			end)
		end)
	end
end

local function collectMaterialNode(node, pos, isSingleAction, fromAutoLoop)
	if not node or not node.Parent then
		return false
	end
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then
		return false
	end

	if teleportToMatEnabled then
		teleportCharacterTo(pos)
		task.wait(0.04)
	else
		hum:MoveTo(pos)
		if isSingleAction then
			matStatusLabel:Set("Đang đi tới: " .. node.Name .. " [" .. getNodeDimName(node) .. "]")
			return true
		end
	end

	root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	watchNodeCollected(node)

	if autoSwingToolEnabled and (CollectionService:HasTag(node, "OreNode") or node:GetAttribute("Hits") ~= nil) then
		equipAndActivateTool(char, hum, "Pickaxe")
	end

	triggerValidPrompt(node, root.Position)

	if fromAutoLoop and node.Parent then
		nodeCooldownUntil[node] = clockNow() + 2.2
	end
	return true
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
			local matId = tostring(node:GetAttribute("Material") or node:GetAttribute("MaterialId") or node.Name)
			matStatusLabel:Set(string.format("Tìm thấy %s [%s] (%.0f st)", matId, getNodeDimName(node), dist))
		else
			matStatusLabel:Set("Đã chọn: " .. opt .. " (Chưa thấy node)")
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
	Description = "Dịch chuyển tới Material kể cả khác Dimension",
	Default = true,
	Callback = function(on)
		teleportToMatEnabled = on
	end,
})

matTab:AddToggle({
	Name = "Auto Instant / Prompt",
	Description = "Tự kích hoạt ProximityPrompt trên node",
	Default = true,
	Callback = function(on)
		autoPromptEnabled = on
	end,
})

matTab:AddToggle({
	Name = "Tự vung Tool / Pickaxe",
	Description = "Tự cầm Pickaxe & gõ khi gặp quặng (OreNode)",
	Default = true,
	Callback = function(on)
		autoSwingToolEnabled = on
	end,
})

matTab:AddToggle({
	Name = "Quét Workspace.Dimensions",
	Description = "Quét cả Nodes/Ores ở các Dimensions trên map",
	Default = true,
	Callback = function(on)
		includeDimensionsScan = on
		rebuildMaterialCache(true)
	end,
})

matTab:AddButton({
	Name = "Teleport & Loot ngay",
	Description = "Tìm node gần nhất khớp Material, TP & thu thập",
	Callback = function()
		local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not root then
			Menu:Notify("Auto Loot", "Đang chờ nhân vật hồi sinh.", 2)
			return
		end
		rebuildMaterialCache(true)
		local node, pos, dist = findNearestMaterialNode(root.Position, false)
		if not node or not pos then
			matStatusLabel:Set("Không tìm thấy node phù hợp!")
			Menu:Notify("Auto Loot", "Không có node nào khớp lựa chọn.", 2.2)
			return
		end
		local matId = tostring(node:GetAttribute("Material") or node:GetAttribute("MaterialId") or node.Name)
		matStatusLabel:Set(string.format("Đang tới %s [%s] (%.0f st)", matId, getNodeDimName(node), dist))
		collectMaterialNode(node, pos, true, false)
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
				if targetObj and targetPos then
					local matId = tostring(targetObj:GetAttribute("Material") or targetObj:GetAttribute("MaterialId") or targetObj.Name)
					matStatusLabel:Set(string.format("Mục tiêu: %s [%s] (%.0f st)", matId, getNodeDimName(targetObj), dist))
					collectMaterialNode(targetObj, targetPos, false, true)
				else
					matStatusLabel:Set("Đang quét... (không thấy node phù hợp)")
				end
			else
				matStatusLabel:Set("Đang chờ nhân vật...")
			end
			task.wait(lootLoopInterval)
		end
	end)
end

matTab:AddToggle({
	Name = "Bật Auto Material / Loot",
	Description = "Liên tục tìm, xoay vòng & thu thập Material",
	Default = false,
	Callback = function(on)
		autoLootEnabled = on
		if on then
			startAutoLootLoop()
			Menu:Notify("Auto Loot", "Đang chạy: " .. selectedMatOption, 2.2)
		else
			lootRunId = lootRunId + 1
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
	Default = 0.22,
	Step = 0.02,
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
	Description = "Làm mới cache & đếm số node khớp bộ lọc",
	Callback = function()
		local allNodes = rebuildMaterialCache(true)
		local matched = 0
		for _, obj in ipairs(allNodes) do
			if matchMaterialTarget(obj) then
				matched = matched + 1
			end
		end
		matStatusLabel:Set(string.format("Đã quét: %d khớp (%d tổng node)", matched, #allNodes))
	end,
})

matTab:AddInput({
	Name = "Folder Tài nguyên",
	Placeholder = "DroppedLoot, Nodes",
	Default = "DroppedLoot, Nodes",
	Callback = function(txt)
		lootFolderNames = txt
		lastCacheRebuildAt = 0
	end,
})

matTab:AddInput({
	Name = "Tag Tài nguyên",
	Placeholder = "OreNode",
	Default = "OreNode",
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
	stopCharacterMovement()
	clearNodeWatchers()
	lastPromptAt = {}
	nodeCooldownUntil = {}
	cachedNodes = {}
end)
end

do
local craftTab = Menu:AddTab("Auto Craft", "⚒")
craftTab:AddSection("AUTO CRAFT & MINI-GAME")

local CRAFT_MINI_PRESETS = {
	TimingBar = { Label = "Timing Bar (QTE)", Steps = 4, BaseDuration = 0.84, ZoneMin = 0.40, ZoneMax = 0.60 },
	SequenceTap = { Label = "Chuỗi Nút (Sequence)", Steps = 3, BaseDuration = 0.60, ZoneMin = 0.35, ZoneMax = 0.65 },
	HeatGauge = { Label = "Cân Nhiệt (Gauge)", Steps = 3, BaseDuration = 0.72, ZoneMin = 0.30, ZoneMax = 0.70 },
}

local CRAFT_RECIPES = {
	{ Id = "Pickaxe", DisplayName = "Pickaxe", CraftTime = 0.8, Yield = 1, Ingredients = { Scrap = 4, Cog = 2 }, MiniKey = "SequenceTap" },
	{ Id = "Flashlight", DisplayName = "Flashlight", CraftTime = 0.8, Yield = 1, Ingredients = { Scrap = 2, Solar = 1, Microchip = 1 }, MiniKey = "SequenceTap" },
	{ Id = "MaterialFinder", DisplayName = "Material Finder", CraftTime = 1.2, Yield = 1, Ingredients = { Microchip = 3, Quantum = 2, Scrap = 2 }, MiniKey = "SequenceTap" },
	{ Id = "TeleportRemote", DisplayName = "Teleport Remote", CraftTime = 1.4, Yield = 1, Ingredients = { Microchip = 3, PortalFluid = 2, Void = 2 }, MiniKey = "TimingBar" },
	{ Id = "PortalHacker", DisplayName = "Portal Hacker", CraftTime = 1.5, Yield = 1, Ingredients = { Microchip = 4, GunBody = 2, DarkMatter = 2 }, MiniKey = "TimingBar" },
	{ Id = "PlasmaRifle", DisplayName = "Plasma Rifle", CraftTime = 1.8, Yield = 1, Ingredients = { GunBody = 2, Quantum = 3, Ember = 2, Cog = 2 }, MiniKey = "HeatGauge" },
	{ Id = "GravityGun", DisplayName = "Gravity Gun", CraftTime = 1.8, Yield = 1, Ingredients = { GunBody = 2, Graviton = 4, Microchip = 3 }, MiniKey = "TimingBar" },
	{ Id = "DarkMatterGrenade", DisplayName = "DarkMatter Bomb", CraftTime = 1.3, Yield = 1, Ingredients = { DarkMatter = 3, Magma = 2, Scrap = 2 }, MiniKey = "HeatGauge" },
	{ Id = "FreezeRay", DisplayName = "Freeze Ray", CraftTime = 1.5, Yield = 1, Ingredients = { GunBody = 2, Ice = 4, Pearl = 2 }, MiniKey = "HeatGauge" },
	{ Id = "TimeStopper", DisplayName = "Time Stopper", CraftTime = 2.0, Yield = 1, Ingredients = { Void = 3, Quantum = 3, Token = 2, Cog = 2 }, MiniKey = "TimingBar" },
}

local CRAFT_RECIPES_BY_ID = {}
local CRAFT_OPTIONS = {}
local OPTION_TO_RECIPE_ID = {}
local craftStock = {}

for _, m in ipairs(MATERIAL_DEFS) do
	craftStock[m.Id] = 12
end
for _, recipe in ipairs(CRAFT_RECIPES) do
	CRAFT_RECIPES_BY_ID[recipe.Id] = recipe
	table.insert(CRAFT_OPTIONS, recipe.DisplayName)
	OPTION_TO_RECIPE_ID[recipe.DisplayName] = recipe.Id
	craftStock[recipe.Id] = 0
end

local CRAFT_MINI_TYPE_MAP = {
	["Timing Bar"] = "TimingBar",
	["Chuỗi Nút"] = "SequenceTap",
	["Cân Nhiệt"] = "HeatGauge",
}

local selectedRecipeOption = "Pickaxe"
local selectedMiniType = "Theo Công thức"
local craftMiniMode = "Tức thời (0ms)"
local craftBatchCount = 10
local autoCraftAllMode = false
local autoCraftLoop = false
local craftBusy = false
local craftStepBusy = false
local craftRunId = 0
local craftMiniCleared = 0
local totalCraftedCount = 0

local placeCraftFolder = ReplicatedStorage:FindFirstChild("CraftItems")
local placeCraftCount = placeCraftFolder and #placeCraftFolder:GetChildren() or 0
local initCraftHint = "Sẵn sàng | " .. EXECUTOR_NAME
if placeCraftCount > 0 then
	initCraftHint = initCraftHint .. string.format(" • %d CraftItems", placeCraftCount)
end

local craftStatusLabel = craftTab:AddLabel(initCraftHint)
local craftInvLabel = craftTab:AddLabel("Kho: Đang tải...")
local craftMiniMeter = craftTab:AddMiniMeter({ Name = "Craft", Title = "MINI-GAME CRAFT" })

local function cloneDict(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = v
	end
	return copy
end

local function resolveMiniPreset(recipe)
	local key = CRAFT_MINI_TYPE_MAP[selectedMiniType] or (recipe and recipe.MiniKey) or "TimingBar"
	return CRAFT_MINI_PRESETS[key] or CRAFT_MINI_PRESETS.TimingBar, key
end

local function buildCraftPlan(stockCopy, targetRecipeId, planOut, depth)
	planOut = planOut or {}
	depth = depth or 0
	if depth > 6 then
		return false, "DEPENDENCY_CYCLE"
	end
	local recipe = CRAFT_RECIPES_BY_ID[targetRecipeId]
	if not recipe then
		return false, "UNKNOWN_RECIPE"
	end
	for itemId, reqAmt in pairs(recipe.Ingredients) do
		local have = stockCopy[itemId] or 0
		if have < reqAmt then
			local sub = CRAFT_RECIPES_BY_ID[itemId]
			if not sub then
				return false, "MISSING_" .. itemId
			end
			local times = math.ceil((reqAmt - have) / sub.Yield)
			for _ = 1, times do
				local ok, err = buildCraftPlan(stockCopy, itemId, planOut, depth + 1)
				if not ok then
					return false, err
				end
			end
		end
		stockCopy[itemId] = (stockCopy[itemId] or 0) - reqAmt
	end
	stockCopy[recipe.Id] = (stockCopy[recipe.Id] or 0) + recipe.Yield
	table.insert(planOut, recipe.Id)
	return true, planOut
end

local function buildCraftBatchPlan(stockStart, targetRecipeId, maxItems)
	local stockCopy = cloneDict(stockStart)
	local fullPlan = {}
	local craftedItems = 0
	local limit = math.clamp(math.floor(maxItems or 1), 1, 500)
	local lastErr = nil

	for _ = 1, limit do
		local trial = cloneDict(stockCopy)
		local itemPlan = {}
		local ok, err = buildCraftPlan(trial, targetRecipeId, itemPlan)
		if not ok then
			lastErr = err
			break
		end
		stockCopy = trial
		for _, rid in ipairs(itemPlan) do
			table.insert(fullPlan, rid)
		end
		craftedItems = craftedItems + 1
	end

	return craftedItems, fullPlan, lastErr
end

local function refreshCraftInventoryLabel()
	local recipeId = OPTION_TO_RECIPE_ID[selectedRecipeOption] or "Pickaxe"
	local recipe = CRAFT_RECIPES_BY_ID[recipeId]
	local reqParts = {}
	if recipe then
		local keys = {}
		for matId in pairs(recipe.Ingredients) do
			table.insert(keys, matId)
		end
		table.sort(keys)
		for _, matId in ipairs(keys) do
			local need = recipe.Ingredients[matId]
			table.insert(reqParts, string.format("%s:%d/%d", matId, craftStock[matId] or 0, need))
		end
	end
	local reqStr = #reqParts > 0 and table.concat(reqParts, " ") or "Không"
	craftInvLabel:Set(
		string.format(
			"%s (%s) • Đã craft:%d | Mini:%d",
			selectedRecipeOption,
			reqStr,
			totalCraftedCount,
			craftMiniCleared
		)
	)
end
SharedState.RefreshCraftUi = refreshCraftInventoryLabel
SharedState.AddCraftStock = function(matId, amount)
	if not matId or matId == "" then
		return
	end
	craftStock[matId] = (craftStock[matId] or 0) + (tonumber(amount) or 1)
	refreshCraftInventoryLabel()
end

craftTab:AddDropdown({
	Name = "Chọn Công thức",
	Options = CRAFT_OPTIONS,
	Default = "Pickaxe",
	Callback = function(opt)
		selectedRecipeOption = opt
		local r = CRAFT_RECIPES_BY_ID[OPTION_TO_RECIPE_ID[opt] or "Pickaxe"]
		local preset = resolveMiniPreset(r)
		craftMiniMeter:SetState("SẴN SÀNG", THEME.AccentDim, preset.ZoneMin, preset.ZoneMax, 0.5, preset.Label .. " | Pass: " .. craftMiniCleared)
		refreshCraftInventoryLabel()
	end,
})

craftTab:AddDropdown({
	Name = "Kiểu Mini Craft",
	Options = { "Theo Công thức", "Timing Bar", "Chuỗi Nút", "Cân Nhiệt" },
	Default = "Theo Công thức",
	Callback = function(opt)
		selectedMiniType = opt
		local r = CRAFT_RECIPES_BY_ID[OPTION_TO_RECIPE_ID[selectedRecipeOption] or "Pickaxe"]
		local preset = resolveMiniPreset(r)
		craftMiniMeter:SetState("SẴN SÀNG", THEME.AccentDim, preset.ZoneMin, preset.ZoneMax, 0.5, preset.Label .. " | Pass: " .. craftMiniCleared)
	end,
})

craftTab:AddDropdown({
	Name = "Chế độ Mini Craft",
	Options = { "Tức thời (0ms)", "Auto (<0.25s)", "Thường (Gốc)" },
	Default = "Tức thời (0ms)",
	Callback = function(opt)
		craftMiniMode = opt
		craftStatusLabel:Set("Chế độ Mini Craft: " .. opt)
	end,
})

craftTab:AddSlider({
	Name = "Số lượng / lần bấm",
	Min = 1,
	Max = 50,
	Default = 10,
	Step = 1,
	Suffix = "x",
	Callback = function(val)
		craftBatchCount = val
	end,
})

local function runCraftMiniGame(recipe, mode, showUi, expectedRunId)
	local preset = resolveMiniPreset(recipe)
	local steps = preset.Steps
	local zoneMid = (preset.ZoneMin + preset.ZoneMax) * 0.5

	if mode == "Tức thời (0ms)" then
		craftMiniCleared = craftMiniCleared + 1
		if showUi then
			craftMiniMeter:SetState(
				"TỨC THỜI OK",
				THEME.Success,
				preset.ZoneMin,
				preset.ZoneMax,
				zoneMid,
				string.format("%s (%d/%d) | Pass: %d", preset.Label, steps, steps, craftMiniCleared)
			)
		end
		return true
	end

	local isFastAuto = (mode == "Auto (<0.25s)")
	local perStepWait = isFastAuto and 0.025 or (preset.BaseDuration / steps)

	for stepIdx = 1, steps do
		if destroyed or (expectedRunId and expectedRunId ~= craftRunId) then
			return false, "CANCELLED"
		end
		if showUi then
			local startAlpha = ((stepIdx % 2) == 1) and 0.14 or 0.86
			craftMiniMeter:SetState(
				isFastAuto and "AUTO GIẢI..." or "ĐANG RÈN...",
				THEME.Accent,
				preset.ZoneMin,
				preset.ZoneMax,
				startAlpha,
				string.format("%s (%d/%d) | Canh vùng...", preset.Label, stepIdx, steps)
			)
			task.wait(perStepWait * 0.45)
			if destroyed or (expectedRunId and expectedRunId ~= craftRunId) then
				return false, "CANCELLED"
			end
			craftMiniMeter:SetState(
				isFastAuto and "AUTO HIT!" or "ĐÚNG VÙNG",
				THEME.Success,
				preset.ZoneMin,
				preset.ZoneMax,
				zoneMid,
				string.format("%s (%d/%d) | Khớp tâm!", preset.Label, stepIdx, steps)
			)
			task.wait(perStepWait * 0.55)
		else
			task.wait(perStepWait)
		end
	end

	craftMiniCleared = craftMiniCleared + 1
	if showUi then
		craftMiniMeter:SetState(
			isFastAuto and "AUTO PASS" or "XONG (GỐC)",
			THEME.Success,
			preset.ZoneMin,
			preset.ZoneMax,
			zoneMid,
			string.format("%s (%d/%d) | Pass: %d", preset.Label, steps, steps, craftMiniCleared)
		)
	end
	return true
end

local function executeCraftStep(recipeId, mode, showUi, expectedRunId)
	if craftStepBusy then
		return false, "CRAFT_BUSY"
	end
	local recipe = CRAFT_RECIPES_BY_ID[recipeId]
	if not recipe then
		return false, "INVALID_RECIPE"
	end
	craftStepBusy = true
	local ok, reason = pcall(function()
		for itemId, reqAmt in pairs(recipe.Ingredients) do
			if (craftStock[itemId] or 0) < reqAmt then
				error("INSUFFICIENT_" .. itemId, 0)
			end
		end
		local mgOk, mgErr = runCraftMiniGame(recipe, mode, showUi, expectedRunId)
		if not mgOk then
			error(tostring(mgErr or "MINIGAME_CANCELLED"), 0)
		end
		if mode == "Thường (Gốc)" and recipe.CraftTime > 0 then
			task.wait(recipe.CraftTime)
		end
		for itemId, reqAmt in pairs(recipe.Ingredients) do
			craftStock[itemId] = craftStock[itemId] - reqAmt
		end
		craftStock[recipe.Id] = (craftStock[recipe.Id] or 0) + recipe.Yield
	end)
	craftStepBusy = false
	if ok then
		return true, "OK"
	end
	return false, tostring(reason)
end

local function executeCraftBatch(desiredCount, expectedRunId, overrideRecipeId)
	if craftBusy then
		return false, "CRAFT_ALREADY_RUNNING"
	end
	craftBusy = true

	local recipeId = overrideRecipeId or OPTION_TO_RECIPE_ID[selectedRecipeOption] or "Pickaxe"
	local recipeObj = CRAFT_RECIPES_BY_ID[recipeId]
	local recipeLabel = recipeObj and recipeObj.DisplayName or selectedRecipeOption
	local targetItems, fullPlan, planErr = buildCraftBatchPlan(craftStock, recipeId, desiredCount)
	if targetItems == 0 or #fullPlan == 0 then
		craftBusy = false
		return false, tostring(planErr or "INSUFFICIENT_MATERIALS")
	end

	local activeMode = craftMiniMode
	local t0 = clockNow()
	local stepCount = 0
	local totalSteps = #fullPlan
	local isInstant = (activeMode == "Tức thời (0ms)")

	for i, stepRecipeId in ipairs(fullPlan) do
		if destroyed or (expectedRunId and expectedRunId ~= craftRunId) then
			craftBusy = false
			return false, "CANCELLED"
		end
		local showUi = (not isInstant) or (i == totalSteps)
		local okStep, errStep = executeCraftStep(stepRecipeId, activeMode, showUi, expectedRunId)
		if not okStep then
			craftBusy = false
			refreshCraftInventoryLabel()
			return false, errStep
		end
		if isInstant and (i % 64 == 0) then
			RunService.Heartbeat:Wait()
		end
		stepCount = stepCount + 1
	end

	totalCraftedCount = totalCraftedCount + targetItems
	craftBusy = false
	local elapsedMs = math.max(1, math.round((clockNow() - t0) * 1000))
	refreshCraftInventoryLabel()
	return true, string.format("Xong %dx %s (%d bước, %d ms)", targetItems, recipeLabel, stepCount, elapsedMs)
end

local function executeCraftAllAvailable(expectedRunId)
	local itemsDone = 0
	local t0 = clockNow()
	for _, recipe in ipairs(CRAFT_RECIPES) do
		if destroyed or (expectedRunId and expectedRunId ~= craftRunId) then
			break
		end
		local ok = executeCraftBatch(craftBatchCount, expectedRunId, recipe.Id)
		if ok then
			itemsDone = itemsDone + 1
		end
	end
	if itemsDone == 0 then
		return false, "KHÔNG ĐỦ NGUYÊN LIỆU"
	end
	local ms = math.max(1, math.round((clockNow() - t0) * 1000))
	return true, string.format("Đã craft %d loại công thức (%d ms)", itemsDone, ms)
end

craftTab:AddButton({
	Name = "Craft Ngay + Auto Mini",
	Description = "Craft SL đã chọn & tự giải mini-game",
	Callback = function()
		task.spawn(function()
			craftStatusLabel:Set(string.format("Đang craft %dx %s (%s)...", craftBatchCount, selectedRecipeOption, craftMiniMode))
			local ok, msg = executeCraftBatch(craftBatchCount, nil, nil)
			craftStatusLabel:Set((ok and "OK: " or "Lỗi: ") .. msg)
		end)
	end,
})

craftTab:AddButton({
	Name = "Craft Tối Đa (Max Kho)",
	Description = "Ghép hết kho item đang chọn tức thời",
	Callback = function()
		task.spawn(function()
			craftStatusLabel:Set("Đang craft tối đa & giải mini...")
			local ok, msg = executeCraftBatch(500, nil, nil)
			craftStatusLabel:Set((ok and "Max OK: " or "Lỗi: ") .. msg)
		end)
	end,
})

craftTab:AddButton({
	Name = "Craft Tất Cả Đủ Đồ",
	Description = "Quét 10 công thức & craft mọi món đủ kho",
	Callback = function()
		task.spawn(function()
			craftStatusLabel:Set("Đang craft hàng loạt mọi món đủ đồ...")
			local ok, msg = executeCraftAllAvailable(nil)
			craftStatusLabel:Set((ok and "All OK: " or "Dừng: ") .. msg)
		end)
	end,
})

craftTab:AddToggle({
	Name = "Auto Craft mọi món đủ đồ",
	Description = "Bật để Auto Loop quét cả 10 công thức",
	Default = false,
	Callback = function(on)
		autoCraftAllMode = on
	end,
})

local autoCraftToggle
autoCraftToggle = craftTab:AddToggle({
	Name = "Bật Auto Craft Loop",
	Description = "Lặp tự động craft + mini khi còn đồ",
	Default = false,
	Callback = function(on)
		autoCraftLoop = on
		craftRunId = craftRunId + 1
		local myId = craftRunId
		if not on then
			craftStatusLabel:Set("Auto Craft: Đã dừng")
			return
		end
		task.spawn(function()
			while autoCraftLoop and not destroyed and myId == craftRunId do
				local ok, msg
				if autoCraftAllMode then
					ok, msg = executeCraftAllAvailable(myId)
				else
					ok, msg = executeCraftBatch(craftBatchCount, myId, nil)
				end
				craftStatusLabel:Set((ok and "Auto OK: " or "Dừng: ") .. msg)
				if not ok then
					autoCraftLoop = false
					if autoCraftToggle then
						autoCraftToggle:Set(false, false)
					end
					break
				end
				RunService.Heartbeat:Wait()
			end
		end)
	end,
})

craftTab:AddButton({
	Name = "Test Nhanh 1 Mini Craft",
	Description = "Chạy thử 1 mini-game của công thức",
	Callback = function()
		if craftBusy then
			craftStatusLabel:Set("Đang chạy Craft/Mini-Game...")
			return
		end
		task.spawn(function()
			craftBusy = true
			local recipe = CRAFT_RECIPES_BY_ID[OPTION_TO_RECIPE_ID[selectedRecipeOption] or "Pickaxe"]
			local t0 = clockNow()
			local ok = runCraftMiniGame(recipe, craftMiniMode, true, nil)
			craftBusy = false
			refreshCraftInventoryLabel()
			local ms = math.max(1, math.round((clockNow() - t0) * 1000))
			craftStatusLabel:Set(ok and string.format("Mini OK (%s, %d ms)", craftMiniMode, ms) or "Đã hủy Mini-Game")
		end)
	end,
})

craftTab:AddButton({
	Name = "Nạp Material (+25)",
	Description = "+25 cho toàn bộ 25 Material",
	Callback = function()
		for _, m in ipairs(MATERIAL_DEFS) do
			craftStock[m.Id] = (craftStock[m.Id] or 0) + 25
		end
		refreshCraftInventoryLabel()
		craftStatusLabel:Set("Đã nạp +25 cho toàn bộ 25 Material!")
	end,
})

onMenuDestroy(function()
	autoCraftLoop = false
	craftBusy = false
	craftStepBusy = false
	craftRunId = craftRunId + 1
end)
end

task.defer(function()
	if SharedState.RefreshCraftUi then
		SharedState.RefreshCraftUi()
	end
	if SharedState.RefreshLootUi then
		SharedState.RefreshLootUi()
	end
end)

Menu:Notify("Shadow Menu", "Auto Loot & Auto Craft sẵn sàng trên " .. (UserInputService.TouchEnabled and "Mobile" or "PC") .. "!", 3)
