--[[
    SHADOW MENU ALL-IN-ONE (1 Script Duy Nhất - LocalScript)
    - Tương thích PC (chuột + phím tắt) & Mobile (cảm ứng đa điểm, ngang/dọc)
    - Invisible Free + Ghost View (tối ưu cache & tự khôi phục)
    - Selection Material + Teleport không giới hạn khoảng cách + Instant / Auto Loot
    - Auto Farm Mobs + Hỗ trợ Spawn dữ liệu mẫu Local QA trong Roblox Studio
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
if not localPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	localPlayer = Players.LocalPlayer
end

local playerGui = localPlayer:WaitForChild("PlayerGui", 15)
if not playerGui then
	warn("[ShadowMenu] Không tìm thấy PlayerGui.")
	return
end

local GUI_NAME = "ShadowMenuGui"
local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui then
	oldGui:Destroy()
end

--==============================================================================
-- CẤU HÌNH THEME & KÍCH THƯỚC
--==============================================================================
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
	Subtitle = "PC • MOBILE",
	LogoAssetId = "", -- Điền "rbxassetid://ID_ANH" nếu muốn dùng ảnh logo riêng
	ToggleKey = Enum.KeyCode.RightControl,
	WideWidth = 540,
	WideHeight = 360,
	CompactWidth = 340,
	CompactHeight = 430,
	HeaderHeight = 44,
	SidebarWidth = 148,
	TopTabBarHeight = 42,
	GhostTransparency = 0.72,
}

--==============================================================================
-- TIỆN ÍCH CHUNG & QUẢN LÝ KẾT NỐI
--==============================================================================
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

--==============================================================================
-- KHỞI TẠO SCREENGUI & KHUNG CHÍNH
--==============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 9999
screenGui.IgnoreGuiInset = true
pcall(function()
	screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end)
screenGui.Parent = playerGui

local destroyed = false
local onDestroyCallbacks = {}
local function onMenuDestroy(fn)
	table.insert(onDestroyCallbacks, fn)
end

screenGui.Destroying:Connect(function()
	if destroyed then
		return
	end
	destroyed = true
	for _, fn in ipairs(onDestroyCallbacks) do
		pcall(fn)
	end
	for _, conn in ipairs(connections) do
		disconnectSafe(conn)
	end
	connections = {}
	onDestroyCallbacks = {}
end)

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

-- Header
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

--==============================================================================
-- RESPONSIVE LAYOUT & DRAG ENGINE (PC + MOBILE NGANG/DỌC)
--==============================================================================
local isCompactMode = false
local isMenuOpen = true
local isMinimized = false
local userScaleMultiplier = 1.0
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
		uiScale.Scale = math.clamp(fitScale * userScaleMultiplier, 0.74, 1.25)

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
		uiScale.Scale = math.clamp(fitScale * userScaleMultiplier, 0.72, 1.25)

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

local isRebindingKey = false
track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or isRebindingKey then
		return
	end
	if input.KeyCode == CONFIG.ToggleKey then
		setMenuOpen(not isMenuOpen)
	end
end))

--==============================================================================
-- MENU API (DRY BUILDER)
--==============================================================================
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

function Menu:SetUserScale(mult)
	userScaleMultiplier = math.clamp(mult, 0.75, 1.3)
	applyResponsiveLayout()
end

function Menu:ResetFloatingPosition()
	local _, topInset = getSafeViewport()
	local fx, fy = clampPosition(16, topInset + 14, floatSize, floatSize)
	floatButton.Position = UDim2.fromOffset(fx, fy)
end

function Menu:Destroy()
	screenGui:Destroy()
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
		function ctrl:Set(v)
			applyState(v == true, true)
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

		local listBox = Instance.new("Frame")
		listBox.LayoutOrder = 2
		listBox.Size = UDim2.new(1, 0, 0, 0)
		listBox.AutomaticSize = Enum.AutomaticSize.Y
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

	function Tab:AddKeybind(opts)
		local currentKey = opts.Default
		local listening = false
		local btn = createCardBase("TextButton", "Keybind_" .. opts.Name, 44)
		addPadding(btn, 0, 12, 0, 12)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -112, 1, 0)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamSemibold
		title.Text = opts.Name
		title.TextColor3 = THEME.TextPrimary
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.Parent = btn

		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.fromOffset(102, 26)
		badge.Position = UDim2.new(1, 0, 0.5, 0)
		badge.AnchorPoint = Vector2.new(1, 0.5)
		badge.BackgroundColor3 = THEME.BgInput
		badge.Font = Enum.Font.GothamBold
		badge.Text = currentKey.Name
		badge.TextColor3 = THEME.Accent
		badge.TextSize = 11
		badge.TextTruncate = Enum.TextTruncate.AtEnd
		badge.Parent = btn
		addCorner(badge, 6)
		addStroke(badge, THEME.Border, 1, 0.15)

		track(btn.Activated:Connect(function()
			if listening then
				return
			end
			listening = true
			isRebindingKey = true
			badge.Text = "Nhấn phím..."
			badge.TextColor3 = THEME.Success
		end))

		track(UserInputService.InputBegan:Connect(function(input)
			if not listening then
				return
			end
			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
				listening = false
				task.defer(function()
					isRebindingKey = false
				end)
				if input.KeyCode ~= Enum.KeyCode.Escape then
					currentKey = input.KeyCode
					if opts.Callback then
						pcall(opts.Callback, currentKey)
					end
				end
				badge.Text = currentKey.Name
				badge.TextColor3 = THEME.Accent
			end
		end))

		local ctrl = {}
		function ctrl:Get()
			return currentKey
		end
		return ctrl
	end

	return Tab
end

--==============================================================================
-- HỆ THỐNG INVISIBLE FREE TỐI ƯU (1 CACHE DUY NHẤT, KHÔNG TẠO CONNECTION THỪA)
--==============================================================================
local invisEnabled = false
local ghostViewEnabled = true
local savedProps = {}        -- [Instance] = { propName = origValue }
local transparentCache = {}  -- Mảng phẳng các BasePart/Decal/Texture có orig < 1 để đổi GhostView O(n)
local charDescConn = nil
local attrSyncConn = nil

local function getServerRemote()
	local r = ReplicatedStorage:FindFirstChild("FreeInvisibleEvent")
	if r and r:IsA("RemoteEvent") then
		return r
	end
	return nil
end

local function cacheProp(inst, prop, val)
	local bag = savedProps[inst]
	if not bag then
		bag = {}
		savedProps[inst] = bag
	end
	if bag[prop] == nil then
		bag[prop] = val
	end
end

local function applyInvisToInstance(inst)
	if not invisEnabled then
		return
	end
	if inst:IsA("BasePart") or inst:IsA("Decal") or inst:IsA("Texture") then
		local orig = inst.Transparency
		cacheProp(inst, "Transparency", orig)
		local cachedOrig = savedProps[inst].Transparency
		if cachedOrig < 1 then
			table.insert(transparentCache, inst)
			inst.Transparency = ghostViewEnabled and CONFIG.GhostTransparency or 1
		end
	elseif inst:IsA("ParticleEmitter")
		or inst:IsA("Trail")
		or inst:IsA("Beam")
		or inst:IsA("Light")
		or inst:IsA("BillboardGui")
		or inst:IsA("Highlight")
	then
		cacheProp(inst, "Enabled", inst.Enabled)
		inst.Enabled = false
	elseif inst:IsA("Humanoid") then
		cacheProp(inst, "DisplayDistanceType", inst.DisplayDistanceType)
		inst.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

local function refreshGhostView()
	if not invisEnabled then
		return
	end
	local targetAlpha = ghostViewEnabled and CONFIG.GhostTransparency or 1
	for i = #transparentCache, 1, -1 do
		local inst = transparentCache[i]
		if inst.Parent then
			inst.Transparency = targetAlpha
		else
			table.remove(transparentCache, i)
		end
	end
end

local function clearInvisCache()
	disconnectSafe(charDescConn)
	charDescConn = nil
	disconnectSafe(attrSyncConn)
	attrSyncConn = nil
	savedProps = {}
	transparentCache = {}
end

local function setInvisible(active, fireRemote)
	invisEnabled = active
	local char = localPlayer.Character
	local remote = getServerRemote()

	if fireRemote and remote then
		remote:FireServer(active)
	end

	if active then
		disconnectSafe(charDescConn)
		disconnectSafe(attrSyncConn)
		savedProps = {}
		transparentCache = {}

		if char then
			for _, desc in ipairs(char:GetDescendants()) do
				applyInvisToInstance(desc)
			end
			charDescConn = char.DescendantAdded:Connect(function(desc)
				task.defer(function()
					if invisEnabled and desc.Parent then
						applyInvisToInstance(desc)
					end
				end)
			end)
		end

		-- Chỉ dùng 1 listener duy nhất để giữ Ghost View sau khi Server đồng bộ xong
		if remote then
			attrSyncConn = localPlayer:GetAttributeChangedSignal("FreeInvisible"):Connect(function()
				if invisEnabled and ghostViewEnabled and localPlayer:GetAttribute("FreeInvisible") == true then
					task.defer(refreshGhostView)
				end
			end)
		end
	else
		disconnectSafe(charDescConn)
		charDescConn = nil
		disconnectSafe(attrSyncConn)
		attrSyncConn = nil

		for inst, props in pairs(savedProps) do
			if inst.Parent then
				for prop, val in pairs(props) do
					pcall(function()
						inst[prop] = val
					end)
				end
			end
		end
		savedProps = {}
		transparentCache = {}
	end
end

track(localPlayer.CharacterRemoving:Connect(clearInvisCache))
track(localPlayer.CharacterAdded:Connect(function()
	task.wait(0.2)
	if invisEnabled then
		setInvisible(true, false)
	end
end))
onMenuDestroy(function()
	if invisEnabled then
		setInvisible(false, true)
	else
		clearInvisCache()
	end
end)

--==============================================================================
-- XÂY DỰNG CÁC TAB CHỨC NĂNG
--==============================================================================
local speedEnabled = false
local targetWalkSpeed = 32
local jumpEnabled = false
local targetJumpPower = 80

local function applyMoveStats(char)
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if speedEnabled then
		hum.WalkSpeed = targetWalkSpeed
	end
	if jumpEnabled then
		hum.UseJumpPower = true
		hum.JumpPower = targetJumpPower
	end
end

track(localPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.2)
	applyMoveStats(char)
end))

local origLighting = {
	Brightness = Lighting.Brightness,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ClockTime = Lighting.ClockTime,
}

-- Tab 1: Chức năng
local mainTab = Menu:AddTab("Chức năng", "⚔")
mainTab:AddSection("TÀNG HÌNH (INVISIBLE FREE)")

local invisToggle = mainTab:AddToggle({
	Name = "Bật Invisible Free",
	Description = "Ẩn nhân vật, phụ kiện, hiệu ứng & bảng tên",
	Default = false,
	Callback = function(on)
		setInvisible(on, true)
		local modeText = getServerRemote() and "Đồng bộ Server" or "Client Local"
		Menu:Notify("Invisible Free", (on and "Đã bật (" or "Đã tắt (") .. modeText .. ")", 2.5)
	end,
})

mainTab:AddToggle({
	Name = "Ghost View (Tự nhìn thấy mờ)",
	Description = "Hiển thị mờ 72% cho riêng bạn để dễ điều khiển",
	Default = true,
	Callback = function(on)
		ghostViewEnabled = on
		refreshGhostView()
	end,
})

mainTab:AddSection("DI CHUYỂN (LOCAL TEST)")

local speedToggle = mainTab:AddToggle({
	Name = "Bật tăng tốc chạy",
	Description = "Áp dụng WalkSpeed tùy chỉnh cho nhân vật",
	Default = false,
	Callback = function(on)
		speedEnabled = on
		local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = on and targetWalkSpeed or 16
		end
	end,
})

mainTab:AddSlider({
	Name = "Tốc độ chạy",
	Min = 16,
	Max = 120,
	Default = 32,
	Step = 1,
	Callback = function(val)
		targetWalkSpeed = val
		if speedEnabled and localPlayer.Character then
			local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = val
			end
		end
	end,
})

local jumpToggle = mainTab:AddToggle({
	Name = "Bật nhảy cao",
	Description = "Áp dụng JumpPower tùy chỉnh",
	Default = false,
	Callback = function(on)
		jumpEnabled = on
		local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = on and targetJumpPower or 50
		end
	end,
})

mainTab:AddSlider({
	Name = "Lực nhảy",
	Min = 50,
	Max = 160,
	Default = 80,
	Step = 5,
	Callback = function(val)
		targetJumpPower = val
		if jumpEnabled and localPlayer.Character then
			local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.UseJumpPower = true
				hum.JumpPower = val
			end
		end
	end,
})

mainTab:AddButton({
	Name = "Khôi phục tất cả thông số",
	Description = "Tắt tàng hình & đặt lại WalkSpeed, JumpPower",
	Callback = function()
		invisToggle:Set(false)
		speedToggle:Set(false)
		jumpToggle:Set(false)
		Menu:Notify("Đã khôi phục", "Nhân vật đã trở về trạng thái mặc định.", 2.5)
	end,
})

--==============================================================================
-- DỮ LIỆU CHUNG & HỖ TRỢ QA (SELECTION MATERIAL, TELEPORT, LOOT, MOBS)
--==============================================================================
local MATERIAL_DEFS = {
	{ Id = "Crystal", Option = "Crystal Ore", NodeName = "CrystalNode", Reward = 1, Color = Color3.fromRGB(95, 205, 255) },
	{ Id = "Scrap", Option = "Scrap Metal", NodeName = "ScrapNode", Reward = 2, Color = Color3.fromRGB(220, 175, 95) },
	{ Id = "Plasma", Option = "Plasma Core", NodeName = "PlasmaNode", Reward = 1, Color = Color3.fromRGB(165, 110, 255) },
}

local MATERIAL_OPTIONS = { "Tất cả Material" }
local OPTION_TO_MAT_ID = { ["Tất cả Material"] = "All" }
for _, m in ipairs(MATERIAL_DEFS) do
	table.insert(MATERIAL_OPTIONS, m.Option)
	OPTION_TO_MAT_ID[m.Option] = m.Id
end

local qaStats = {
	Coins = 0,
	Crystal = 0,
	Scrap = 0,
	Plasma = 0,
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

local function getDevTestActionRemote()
	local folder = ReplicatedStorage:FindFirstChild("DevTestRemotes")
	local r = folder and folder:FindFirstChild("DevTestAction")
	if r and r:IsA("RemoteEvent") then
		return r
	end
	return nil
end

local function clearLocalQaSamples()
	for _, folderName in ipairs({ "TestResources", "TestMobs" }) do
		local folder = Workspace:FindFirstChild(folderName)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				if child:GetAttribute("IsLocalQaSample") == true then
					child:Destroy()
				end
			end
		end
	end
end

-- Tab 2: Selection Material + Teleport + Instant / Auto Loot
local matTab = Menu:AddTab("Material", "★")
matTab:AddSection("SELECTION MATERIAL & LOOT")

local selectedMatOption = "Tất cả Material"
local customMatFilter = ""
local teleportToMatEnabled = true
local autoLootEnabled = false
local autoPromptEnabled = true
local lootMaxRange = 200
local lootFolderNames = "TestResources, DroppedLoot"
local lootTagNames = "TestResource"
local lootRunId = 0
local lastPromptAt = {}

local matStatusLabel = matTab:AddLabel("Trạng thái: Sẵn sàng | Chọn Material bên dưới")
local qaStatsLabel = matTab:AddLabel("QA Stats: Coins 0 | Cry 0 | Scr 0 | Pls 0")

local function refreshQaStatsLabel()
	qaStatsLabel:Set(string.format(
		"QA Stats: Coins %d | Cry %d | Scr %d | Pls %d",
		qaStats.Coins,
		qaStats.Crystal,
		qaStats.Scrap,
		qaStats.Plasma
	))
end

local function getMatDefById(matId)
	for _, m in ipairs(MATERIAL_DEFS) do
		if m.Id == matId then
			return m
		end
	end
	return nil
end

local function detectObjectMaterialDef(obj)
	local attrId = obj:GetAttribute("MaterialId")
	if attrId then
		local found = getMatDefById(tostring(attrId))
		if found then
			return found
		end
	end
	local lowerName = string.lower(obj.Name)
	for _, m in ipairs(MATERIAL_DEFS) do
		if obj.Name == m.NodeName or string.find(lowerName, string.lower(m.Id), 1, true) then
			return m
		end
	end
	return nil
end

local function matchMaterialTarget(obj)
	if not obj or not obj.Parent or isCharacterPart(obj) or obj:GetAttribute("Claimed") == true then
		return false
	end
	local customLower = string.lower(string.gsub(customMatFilter, "^%s*(.-)%s*$", "%1"))
	if customLower ~= "" then
		local nLower = string.lower(obj.Name)
		local attrId = string.lower(tostring(obj:GetAttribute("MaterialId") or ""))
		local attrName = string.lower(tostring(obj:GetAttribute("MaterialName") or ""))
		return (string.find(nLower, customLower, 1, true) ~= nil) or (attrId == customLower) or (attrName == customLower)
	end

	local matId = OPTION_TO_MAT_ID[selectedMatOption] or "All"
	if matId == "All" then
		return true
	end
	local def = getMatDefById(matId)
	if not def then
		return false
	end
	local attrId = tostring(obj:GetAttribute("MaterialId") or "")
	local attrName = tostring(obj:GetAttribute("MaterialName") or "")
	local lowerName = string.lower(obj.Name)
	return (attrId == def.Id)
		or (attrName == def.Option)
		or (obj.Name == def.NodeName)
		or (string.find(lowerName, string.lower(def.Id), 1, true) ~= nil)
end

local function findNearestMaterialNode(originPos)
	local maxDist = teleportToMatEnabled and math.huge or lootMaxRange
	local bestDist = maxDist
	local bestPos = nil
	local bestObj = nil
	local seen = {}

	local function checkCandidate(obj)
		if seen[obj] or not matchMaterialTarget(obj) then
			return
		end
		seen[obj] = true
		local pos = getWorldPosition(obj)
		if pos then
			local d = (pos - originPos).Magnitude
			if d <= bestDist then
				bestDist = d
				bestPos = pos
				bestObj = obj
			end
		end
	end

	for _, fName in ipairs(splitCsv(lootFolderNames)) do
		local folder = Workspace:FindFirstChild(fName)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				checkCandidate(child)
			end
		end
	end

	for _, tName in ipairs(splitCsv(lootTagNames)) do
		for _, tagged in ipairs(CollectionService:GetTagged(tName)) do
			checkCandidate(tagged)
		end
	end

	return bestObj, bestPos, bestDist
end

local function triggerValidPrompt(targetObj, rootPos)
	if not autoPromptEnabled or not targetObj then
		return
	end
	local prompt = targetObj:IsA("ProximityPrompt") and targetObj or targetObj:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt or not prompt.Enabled then
		return
	end
	local now = os.clock()
	if lastPromptAt[prompt] and (now - lastPromptAt[prompt]) < 0.8 then
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

local function collectMaterialNode(node, pos, isSingleAction)
	if not node or not node.Parent then
		return false
	end
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then
		return false
	end

	local serverRemote = getDevTestActionRemote()
	if teleportToMatEnabled then
		if serverRemote then
			serverRemote:FireServer("TeleportToResource", node)
			task.wait(0.08)
		else
			teleportCharacterTo(pos)
			task.wait(0.04)
		end
	else
		hum:MoveTo(pos)
		if isSingleAction then
			matStatusLabel:Set("Đang đi tới: " .. node.Name)
			return true
		end
	end

	root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	if serverRemote then
		serverRemote:FireServer("InstantLoot", node)
	end

	triggerValidPrompt(node, root.Position)

	if node:GetAttribute("IsLocalQaSample") == true and node:GetAttribute("Claimed") ~= true then
		node:SetAttribute("Claimed", true)
		local matDef = detectObjectMaterialDef(node)
		if matDef then
			qaStats[matDef.Id] = (qaStats[matDef.Id] or 0) + matDef.Reward
			refreshQaStatsLabel()
			Menu:Notify("Instant Loot (QA)", string.format("+%d %s", matDef.Reward, matDef.Option), 2)
		end
		node:Destroy()
	end
	return true
end

matTab:AddDropdown({
	Name = "Chọn Material",
	Options = MATERIAL_OPTIONS,
	Default = "Tất cả Material",
	Callback = function(opt)
		selectedMatOption = opt
		local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		local origin = root and root.Position or Vector3.zero
		local node, _, dist = findNearestMaterialNode(origin)
		if node then
			matStatusLabel:Set(string.format("Tìm thấy %s (%.0f st)", node.Name, dist))
		else
			matStatusLabel:Set("Đã chọn: " .. opt .. " (Chưa thấy node)")
		end
	end,
})

matTab:AddInput({
	Name = "Lọc tên / ID riêng",
	Placeholder = "Bỏ trống = dùng Dropdown",
	Default = "",
	Callback = function(txt)
		customMatFilter = string.gsub(txt, "^%s*(.-)%s*$", "%1")
	end,
})

matTab:AddToggle({
	Name = "Teleport (Không giới hạn)",
	Description = "Dịch chuyển xuyên map tới Material đã chọn",
	Default = true,
	Callback = function(on)
		teleportToMatEnabled = on
	end,
})

matTab:AddToggle({
	Name = "Auto Instant / Prompt",
	Description = "Kích hoạt ProximityPrompt & thu thập ngay",
	Default = true,
	Callback = function(on)
		autoPromptEnabled = on
	end,
})

matTab:AddButton({
	Name = "Teleport & Loot ngay",
	Description = "Tìm Material đã chọn, TP đến và nhặt ngay",
	Callback = function()
		local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not root then
			Menu:Notify("Material", "Đang chờ nhân vật hồi sinh.", 2)
			return
		end
		local node, pos, dist = findNearestMaterialNode(root.Position)
		if not node or not pos then
			matStatusLabel:Set("Không tìm thấy Material phù hợp!")
			Menu:Notify("Material", "Không có node nào khớp lựa chọn.", 2.2)
			return
		end
		matStatusLabel:Set(string.format("Đang tới %s (%.0f st)", node.Name, dist))
		collectMaterialNode(node, pos, true)
	end,
})

local function startAutoLootLoop()
	lootRunId = lootRunId + 1
	local myRunId = lootRunId
	task.spawn(function()
		while autoLootEnabled and not destroyed and myRunId == lootRunId do
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local targetObj, targetPos, dist = findNearestMaterialNode(root.Position)
				if targetObj and targetPos then
					matStatusLabel:Set(string.format("Mục tiêu: %s (%.0f st)", targetObj.Name, dist))
					collectMaterialNode(targetObj, targetPos, false)
				else
					matStatusLabel:Set("Đang quét... (không thấy node phù hợp)")
				end
			else
				matStatusLabel:Set("Đang chờ nhân vật...")
			end
			task.wait(0.28)
		end
	end)
end

local autoLootToggle = matTab:AddToggle({
	Name = "Bật Auto Material / Loot",
	Description = "Liên tục tìm & thu thập Material đã chọn",
	Default = false,
	Callback = function(on)
		autoLootEnabled = on
		if on then
			startAutoLootLoop()
			Menu:Notify("Auto Material", "Đang chạy: " .. selectedMatOption, 2.2)
		else
			lootRunId = lootRunId + 1
			stopCharacterMovement()
			matStatusLabel:Set("Trạng thái: Đang tắt")
			Menu:Notify("Auto Material", "Đã tắt Auto Material / Loot.", 2)
		end
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

matTab:AddSection("NGUỒN MAP & DỮ LIỆU TEST")

matTab:AddInput({
	Name = "Folder Tài nguyên",
	Placeholder = "TestResources, DroppedLoot",
	Default = "TestResources, DroppedLoot",
	Callback = function(txt)
		lootFolderNames = txt
	end,
})

matTab:AddInput({
	Name = "Tag Tài nguyên",
	Placeholder = "TestResource",
	Default = "TestResource",
	Callback = function(txt)
		lootTagNames = txt
	end,
})

local function spawnLocalQaArena()
	local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	local origin = root and root.Position or Vector3.new(0, 5, 0)
	clearLocalQaSamples()

	local resFolder = Workspace:FindFirstChild("TestResources")
	if not resFolder then
		resFolder = Instance.new("Folder")
		resFolder.Name = "TestResources"
		resFolder.Parent = Workspace
	end
	local mobFolder = Workspace:FindFirstChild("TestMobs")
	if not mobFolder then
		mobFolder = Instance.new("Folder")
		mobFolder.Name = "TestMobs"
		mobFolder.Parent = Workspace
	end

	local offsets = {
		Vector3.new(18, 0, 0),
		Vector3.new(-24, 0, 14),
		Vector3.new(220, 0, -40), -- Node xa >220 studs để test Teleport không giới hạn
	}
	for i, m in ipairs(MATERIAL_DEFS) do
		local p = Instance.new("Part")
		p.Name = m.NodeName
		p.Size = Vector3.new(3, 3, 3)
		p.Color = m.Color
		p.Material = Enum.Material.Neon
		p.Anchored = true
		p.Position = origin + offsets[i]
		p:SetAttribute("MaterialId", m.Id)
		p:SetAttribute("MaterialName", m.Option)
		p:SetAttribute("IsLocalQaSample", true)

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Loot " .. m.Option
		prompt.ObjectText = m.NodeName
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.Parent = p

		CollectionService:AddTag(p, "TestResource")
		p.Parent = resFolder
	end

	for i = 1, 2 do
		local mob = Instance.new("Model")
		mob.Name = "TestGoblin_" .. i
		mob:SetAttribute("IsLocalQaSample", true)

		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Size = Vector3.new(3, 4.5, 2)
		hrp.Color = Color3.fromRGB(210, 80, 80)
		hrp.Material = Enum.Material.SmoothPlastic
		hrp.Anchored = true
		hrp.Position = origin + Vector3.new(i * 14, 1, 22)
		hrp.Parent = mob

		local hum = Instance.new("Humanoid")
		hum.MaxHealth = 70
		hum.Health = 70
		hum.Parent = mob

		mob.PrimaryPart = hrp
		CollectionService:AddTag(mob, "TestMob")
		mob.Parent = mobFolder
	end
end

matTab:AddButton({
	Name = "Tạo mẫu Material & Mob",
	Description = "Sinh 3 Material (có node xa 220 st) & 2 Mob QA",
	Callback = function()
		local serverRemote = getDevTestActionRemote()
		if serverRemote then
			serverRemote:FireServer("SpawnSampleTestArena")
		else
			spawnLocalQaArena()
			Menu:Notify("Local QA Arena", "Đã tạo 3 Material (xa 220 st) & 2 Mob mẫu!", 3)
		end
	end,
})

matTab:AddButton({
	Name = "Dọn đồ mẫu QA",
	Description = "Xóa các node và Mob mẫu Local QA",
	Callback = function()
		clearLocalQaSamples()
		Menu:Notify("Local QA", "Đã dọn đồ mẫu trong Workspace.", 2)
	end,
})

-- Tab 3: Auto Farm Mobs
local mobTab = Menu:AddTab("Mobs", "⚡")
mobTab:AddSection("AUTO FARM MOBS")

local autoMobEnabled = false
local tpToMobEnabled = true
local autoAttackEnabled = true
local mobAttackRange = 12
local mobAttackCooldown = 0.4
local mobFolderNames = "TestMobs"
local mobTagNames = "TestMob"
local mobRunId = 0

local mobStatusLabel = mobTab:AddLabel("Mob Farm: Đang tắt")

local function findNearestLivingMob(originPos)
	local bestMob, bestPos, bestDist = nil, nil, math.huge
	local seen = {}

	local function checkMob(obj)
		if seen[obj] or not obj.Parent or not obj:IsA("Model") or isCharacterPart(obj) then
			return
		end
		seen[obj] = true
		local hum = obj:FindFirstChildOfClass("Humanoid")
		local pos = getWorldPosition(obj)
		if hum and hum.Health > 0 and pos then
			local d = (pos - originPos).Magnitude
			if d < bestDist then
				bestDist = d
				bestPos = pos
				bestMob = obj
			end
		end
	end

	for _, fName in ipairs(splitCsv(mobFolderNames)) do
		local folder = Workspace:FindFirstChild(fName)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				checkMob(child)
			end
		end
	end

	for _, tName in ipairs(splitCsv(mobTagNames)) do
		for _, tagged in ipairs(CollectionService:GetTagged(tName)) do
			checkMob(tagged)
		end
	end

	return bestMob, bestPos, bestDist
end

local function equipAndActivateTool(char, hum)
	local equipped = char:FindFirstChildOfClass("Tool")
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

local function startAutoMobLoop()
	mobRunId = mobRunId + 1
	local myRunId = mobRunId
	task.spawn(function()
		while autoMobEnabled and not destroyed and myRunId == mobRunId do
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local mob, mobPos, dist = findNearestLivingMob(root.Position)
				if mob and mobPos then
					local mobHum = mob:FindFirstChildOfClass("Humanoid")
					mobStatusLabel:Set(string.format("Mục tiêu: %s (HP %.0f) • %.0f st", mob.Name, mobHum and mobHum.Health or 0, dist))
					if dist > mobAttackRange then
						if tpToMobEnabled then
							local serverRemote = getDevTestActionRemote()
							if serverRemote then
								serverRemote:FireServer("TeleportToMob", mob)
							else
								teleportCharacterTo(mobPos + Vector3.new(0, 0, -4))
							end
							task.wait(0.08)
						else
							hum:MoveTo(mobPos)
						end
					end

					if autoAttackEnabled and mob.Parent and mobHum and mobHum.Health > 0 then
						local currRoot = char:FindFirstChild("HumanoidRootPart")
						if currRoot and (mobPos - currRoot.Position).Magnitude <= (mobAttackRange + 4) then
							equipAndActivateTool(char, hum)
							local serverRemote = getDevTestActionRemote()
							if serverRemote then
								serverRemote:FireServer("AttackMob", mob)
							elseif mob:GetAttribute("IsLocalQaSample") == true then
								mobHum:TakeDamage(35)
								if mobHum.Health <= 0 and mob:GetAttribute("Rewarded") ~= true then
									mob:SetAttribute("Rewarded", true)
									qaStats.Coins = qaStats.Coins + 15
									refreshQaStatsLabel()
									Menu:Notify("Tiêu diệt Mob (QA)", "+15 Coins (" .. mob.Name .. ")", 2)
									local deadMob = mob
									task.delay(0.6, function()
										if deadMob.Parent then
											deadMob:Destroy()
										end
									end)
								end
							end
						end
					end
					task.wait(mobAttackCooldown)
				else
					mobStatusLabel:Set("Mob Farm: Không có Mob sống")
					task.wait(0.35)
				end
			else
				mobStatusLabel:Set("Đang chờ nhân vật...")
				task.wait(0.35)
			end
		end
	end)
end

local autoMobToggle = mobTab:AddToggle({
	Name = "Bật Auto Farm Mobs",
	Description = "Tự chọn Mob gần nhất, áp sát và tấn công",
	Default = false,
	Callback = function(on)
		autoMobEnabled = on
		if on then
			startAutoMobLoop()
			Menu:Notify("Auto Farm Mobs", "Đã bật tự động săn Mob.", 2.2)
		else
			mobRunId = mobRunId + 1
			stopCharacterMovement()
			mobStatusLabel:Set("Mob Farm: Đang tắt")
			Menu:Notify("Auto Farm Mobs", "Đã tắt Auto Farm Mobs.", 2)
		end
	end,
})

mobTab:AddToggle({
	Name = "Teleport tới Mob",
	Description = "Bật = dịch chuyển áp sát; Tắt = đi bộ lại",
	Default = true,
	Callback = function(on)
		tpToMobEnabled = on
	end,
})

mobTab:AddToggle({
	Name = "Tự trang bị & đánh",
	Description = "Tự cầm Tool & kích hoạt đòn đánh trong tầm",
	Default = true,
	Callback = function(on)
		autoAttackEnabled = on
	end,
})

mobTab:AddSlider({
	Name = "Tầm đánh Mob",
	Min = 6,
	Max = 24,
	Default = 12,
	Step = 1,
	Suffix = " st",
	Callback = function(val)
		mobAttackRange = val
	end,
})

mobTab:AddSlider({
	Name = "Nhịp đánh",
	Min = 0.2,
	Max = 1.5,
	Default = 0.4,
	Step = 0.05,
	Suffix = "s",
	Callback = function(val)
		mobAttackCooldown = val
	end,
})

mobTab:AddSection("NGUỒN MOB (FOLDER / TAG)")

mobTab:AddInput({
	Name = "Folder Mob",
	Placeholder = "TestMobs",
	Default = "TestMobs",
	Callback = function(txt)
		mobFolderNames = txt
	end,
})

mobTab:AddInput({
	Name = "Tag Mob",
	Placeholder = "TestMob",
	Default = "TestMob",
	Callback = function(txt)
		mobTagNames = txt
	end,
})

onMenuDestroy(function()
	if autoLootEnabled then
		autoLootEnabled = false
		lootRunId = lootRunId + 1
	end
	if autoMobEnabled then
		autoMobEnabled = false
		mobRunId = mobRunId + 1
	end
	stopCharacterMovement()
	lastPromptAt = {}
end)

-- Tab 4: Hiển thị
local visualTab = Menu:AddTab("Hiển thị", "◈")
visualTab:AddSection("TRẠNG THÁI HỆ THỐNG")

local statusLabel = visualTab:AddLabel("FPS: -- | Thiết bị: " .. (UserInputService.TouchEnabled and "Mobile/Touch" or "PC"))
local showLiveStats = true
visualTab:AddToggle({
	Name = "Cập nhật FPS & Tọa độ",
	Default = true,
	Callback = function(on)
		showLiveStats = on
	end,
})

local accumTime = 0
local frameCount = 0
track(RunService.RenderStepped:Connect(function(dt)
	if not showLiveStats or not mainFrame.Visible then
		return
	end
	accumTime = accumTime + dt
	frameCount = frameCount + 1
	if accumTime >= 0.35 then
		local fps = math.round(frameCount / accumTime)
		accumTime = 0
		frameCount = 0
		local posStr = "Chưa có nhân vật"
		local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root then
			posStr = string.format("%.0f, %.0f, %.0f", root.Position.X, root.Position.Y, root.Position.Z)
		end
		statusLabel:Set(string.format("FPS: %d | Tọa độ: %s", fps, posStr))
	end
end))

visualTab:AddSection("CAMERA & ÁNH SÁNG")
visualTab:AddSlider({
	Name = "Góc nhìn (FOV)",
	Min = 50,
	Max = 120,
	Default = 70,
	Step = 1,
	Suffix = "°",
	Callback = function(val)
		if Workspace.CurrentCamera then
			Workspace.CurrentCamera.FieldOfView = val
		end
	end,
})

visualTab:AddToggle({
	Name = "Làm sáng môi trường (Client)",
	Description = "Tăng độ sáng cục bộ để dễ quan sát",
	Default = false,
	Callback = function(on)
		if on then
			Lighting.Brightness = 2.5
			Lighting.Ambient = Color3.fromRGB(180, 180, 180)
			Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
		else
			Lighting.Brightness = origLighting.Brightness
			Lighting.Ambient = origLighting.Ambient
			Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
		end
	end,
})

visualTab:AddDropdown({
	Name = "Thời gian (Client)",
	Options = { "Mặc định", "Ban ngày (12:00)", "Hoàng hôn (17:45)", "Ban đêm (00:00)" },
	Default = "Mặc định",
	Callback = function(choice)
		if choice == "Mặc định" then
			Lighting.ClockTime = origLighting.ClockTime
		elseif choice == "Ban ngày (12:00)" then
			Lighting.ClockTime = 12
		elseif choice == "Hoàng hôn (17:45)" then
			Lighting.ClockTime = 17.75
		elseif choice == "Ban đêm (00:00)" then
			Lighting.ClockTime = 0
		end
	end,
})

-- Tab 3: Cài đặt
local settingsTab = Menu:AddTab("Cài đặt", "⚙")
settingsTab:AddSection("GIAO DIỆN & ĐIỀU KHIỂN")

settingsTab:AddSlider({
	Name = "Tỉ lệ kích thước Menu",
	Min = 0.8,
	Max = 1.25,
	Default = 1.0,
	Step = 0.05,
	Suffix = "x",
	Callback = function(val)
		Menu:SetUserScale(val)
	end,
})

settingsTab:AddKeybind({
	Name = "Phím ẩn / hiện Menu (PC)",
	Default = CONFIG.ToggleKey,
	Callback = function(newKey)
		CONFIG.ToggleKey = newKey
		Menu:Notify("Phím tắt", "Đã đổi sang phím: " .. newKey.Name, 2)
	end,
})

settingsTab:AddInput({
	Name = "Đổi tiêu đề Menu",
	Placeholder = "Nhập tên menu...",
	Default = CONFIG.Title,
	Callback = function(txt)
		if txt ~= "" then
			titleLabel.Text = txt
		end
	end,
})

settingsTab:AddSection("QUẢN LÝ")
settingsTab:AddButton({
	Name = "Đưa nút nổi về vị trí gốc",
	Callback = function()
		Menu:ResetFloatingPosition()
		Menu:Notify("Vị trí nút", "Đã đặt lại nút nổi về góc mặc định.", 2)
	end,
})

settingsTab:AddButton({
	Name = "Đóng & Hủy Menu",
	Description = "Tắt chức năng và xóa hoàn toàn GUI khỏi màn hình",
	Callback = function()
		Menu:Destroy()
	end,
})

Menu:Notify("Shadow Menu", "Sẵn sàng trên " .. (UserInputService.TouchEnabled and "Mobile" or "PC") .. "!", 3)
