local UILibrary = {}

-- サービス
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- テーマ
local Theme = {
	Accent = Color3.fromRGB(176, 79, 255),
	WindowBackground = Color3.fromRGB(36, 36, 36),
	WindowBorder = Color3.fromRGB(83, 83, 83),
	TabBackground = Color3.fromRGB(42, 42, 42),
	TabBorder = Color3.fromRGB(70, 70, 70),
	TabBorderDark = Color3.fromRGB(54, 54, 54),
	SectionBackground = Color3.fromRGB(48, 48, 48),
	SectionBorder = Color3.fromRGB(63, 63, 63),
	SectionOuterBorder = Color3.fromRGB(30, 30, 30),
	Text = Color3.fromRGB(240, 240, 240),
	TextDark = Color3.fromRGB(140, 140, 140),
	ElementBackground = Color3.fromRGB(48, 48, 48),
	ElementBorder = Color3.fromRGB(88, 88, 88),
	ElementOuterBorder = Color3.fromRGB(38, 38, 38),
	ButtonBackground = Color3.fromRGB(68, 68, 68),
	ButtonText = Color3.fromRGB(185, 185, 185),
}

-- 変数
local screenGui = Instance.new("ScreenGui")

-- クラス
local Section = {}
Section.__index = Section

local Tab = {}
Tab.__index = Tab

local Window = {}
Window.__index = Window

-- 動的変数
local _connections = {}
local _windows = {}

-- 初期化
do
	local g = getfenv()
	
	if g.syn and g.syn.protect_gui then
		g.syn.protect_gui(screenGui)
	end
	
	if g.gethui then
		screenGui.Parent = g.gethui()
	else
		local success = pcall(function()
			screenGui.Parent = CoreGui
		end)
		if not success then
			screenGui.Parent = Players.LocalPlayer.PlayerGui
		end
	end
	
	screenGui.Name = "UnchiUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
end

local function AddConnection(signal: RBXScriptSignal, callback: any): ()
	local connection = signal:Connect(callback)
	table.insert(_connections, connection)
end

local function ClearConnections(): ()
	for i, connection in _connections do
		connection:Disconnect()
		_connections[i] = nil
	end
end

local function AddGradientFrame(object: GuiBase, colors: {Color3}?, transparencies: {number}?, rotation: number?): ()
	colors = colors or {Color3.fromRGB(255, 255, 255)}
	transparencies = transparencies or {0}
	rotation = rotation or 0
	
	local frame = Instance.new("Frame")
	frame.Parent = object
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Parent = frame
	uiGradient.Rotation = rotation
	
	if #colors > 1 then
		local keypoints = {}
		for i, color in colors do
			local point = ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color)
			table.insert(keypoints, point)
		end
		uiGradient.Color = ColorSequence.new(keypoints)
	else
		uiGradient.Color = ColorSequence.new(colors[1])
	end
	
	if #transparencies > 1 then
		local keypoints = {}
		for i, transparency in transparencies do
			local point = NumberSequenceKeypoint.new((i - 1) / (#transparencies - 1), transparency)
			table.insert(keypoints, point)
		end
		uiGradient.Transparency = NumberSequence.new(keypoints)
	else
		uiGradient.Transparency = NumberSequence.new(transparencies[1])
	end
end

function UILibrary:Unload(): ()
	ClearConnections()
	
	screenGui:Destroy()
	screenGui = nil
	
	_windows = {}
end

function UILibrary:CreateWindow(name: string, properties: {[string]: any}?): typeof(Window)
	properties = properties or {}
	local width = properties.Width or 440
	local height = properties.Height or 510
	
	local window = setmetatable({}, Window)
	window.tabs = {}
	window.objects = {}
	table.insert(_windows, window)
	
	local root = Instance.new("Frame")
	root.Parent = screenGui
	root.BackgroundColor3 = Theme.WindowBackground
	root.BorderSizePixel = 0
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(width, height)
	
	local handle = Instance.new("Frame")
	handle.Parent = root
	handle.Active = true
	handle.BackgroundTransparency = 1
	handle.Size = UDim2.new(1, 0, 0, 56)

	local outline = Instance.new("Frame")
	outline.Parent = root
	outline.BackgroundTransparency = 1
	outline.AnchorPoint = Vector2.new(0.5, 0.5)
	outline.Position = UDim2.fromScale(0.5, 0.5)
	outline.Size = UDim2.new(1, -4, 1, -4)

	local stroke = Instance.new("UIStroke")
	stroke.Parent = outline
	stroke.Enabled = true
	stroke.Color = Theme.WindowBorder
	stroke.Thickness = 1
	stroke.LineJoinMode = Enum.LineJoinMode.Miter
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local title = Instance.new("TextLabel")
	title.Parent = root
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0.5, 0, 0, 10)
	title.Size = UDim2.new(1, -20, 0, 14)
	title.Font = Enum.Font.Code
	title.Text = name
	title.TextColor3 = Theme.Accent
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd

	local tabSections = Instance.new("Frame")
	tabSections.Parent = root
	tabSections.AnchorPoint = Vector2.new(0.5, 1)
	tabSections.BackgroundColor3 = Theme.TabBackground
	tabSections.Position = UDim2.new(0.5, 0, 1, -8)
	tabSections.Size = UDim2.new(1, -16, 1, -64)
	tabSections.BorderColor3 = Theme.TabBorder
	tabSections.BorderMode = Enum.BorderMode.Inset
	tabSections.BorderSizePixel = 1

	local tabs = Instance.new("ScrollingFrame")
	tabs.Parent = root
	tabs.AnchorPoint = Vector2.new(0.5, 0)
	tabs.BackgroundTransparency = 1
	tabs.Position = UDim2.new(0.5, 0, 0, 32)
	tabs.Size = UDim2.new(1, -16, 0, 25)
	tabs.ScrollBarThickness = 0
	tabs.ScrollingDirection = Enum.ScrollingDirection.X
	tabs.CanvasSize = UDim2.new()
	tabs.AutomaticCanvasSize = Enum.AutomaticSize.X

	local uiList = Instance.new("UIListLayout")
	uiList.Parent = tabs
	uiList.Padding = UDim.new(0, 0)
	uiList.FillDirection = Enum.FillDirection.Horizontal
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	
	window.objects.root = root
	window.objects.tabs = tabs
	window.objects.tabSections = tabSections
	
	do -- ドラッグ対応
		local _input = nil
		local _startPos = nil
		local _startInput = nil

		AddConnection(handle.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_input = input
				_startPos = root.Position
				_startInput = input.Position
			end
		end)

		AddConnection(UserInputService.InputChanged, function(input: InputObject, gameProcessedEvent: boolean)
			if _input and (input.UserInputType == Enum.UserInputType.MouseMovement) then
				local add = input.Position - _startInput
				root.Position = _startPos + UDim2.fromOffset(add.X, add.Y)
			end
		end)

		AddConnection(handle.InputEnded, function(input: InputObject)
			if (input == _input) and (input.UserInputState == Enum.UserInputState.End) then
				_input = nil
				_startPos = nil
				_startInput = nil
			end
		end)
	end
	
	do -- カラーピッカー
		local picker = Instance.new("Frame")
		picker.Parent = root
		picker.AnchorPoint = Vector2.new(0.5, 0)
		picker.BackgroundColor3 = Theme.WindowBackground
		picker.BorderSizePixel = 0
		picker.Position = UDim2.fromOffset(-4, 0)
		picker.Size = UDim2.fromOffset(220, 220)
		picker.Visible = false
		
		local outline = Instance.new("Frame")
		outline.Parent = picker
		outline.AnchorPoint = Vector2.new(0.5, 0.5)
		outline.BackgroundTransparency = 1
		outline.Position = UDim2.fromScale(0.5, 0.5)
		outline.Size = UDim2.new(1, -4, 1, -4)
		
		local uiStroke = Instance.new("UIStroke")
		uiStroke.Parent = outline
		uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		uiStroke.Color = Theme.WindowBorder
		uiStroke.LineJoinMode = Enum.LineJoinMode.Miter
		uiStroke.Thickness = 1
		
		local svPanel = Instance.new("ImageButton")
		svPanel.Parent = picker
		svPanel.AutoButtonColor = false
		svPanel.BorderColor3 = Theme.TabBorder
		svPanel.BorderSizePixel = 1
		svPanel.BorderMode = Enum.BorderMode.Inset
		svPanel.Position = UDim2.fromOffset(6, 6)
		svPanel.Size = UDim2.fromOffset(180, 180)
		svPanel.Image = ""
		
		AddGradientFrame(svPanel, {Color3.fromRGB(255, 255, 255)}, {0, 1}, 0)
		AddGradientFrame(svPanel, {Color3.fromRGB(0, 0, 0)}, {0, 1}, -90)
		
		local huePanel = Instance.new("ImageButton")
		huePanel.Parent = picker
		huePanel.AutoButtonColor = false
		huePanel.BorderColor3 = Theme.TabBorder
		huePanel.BorderSizePixel = 1
		huePanel.BorderMode = Enum.BorderMode.Inset
		huePanel.Position = UDim2.fromOffset(192, 6)
		huePanel.Size = UDim2.fromOffset(22, 180)
		huePanel.Image = ""
		
		AddGradientFrame(huePanel, {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(255, 255, 0),
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(0, 255, 255),
			Color3.fromRGB(0, 0, 255),
			Color3.fromRGB(255, 0, 255),
			Color3.fromRGB(255, 0, 0),
		}, nil, 90)
		
		local svHandle = Instance.new("Frame")
		svHandle.Parent = svPanel
		svHandle.AnchorPoint = Vector2.new(0.5, 0.5)
		svHandle.BackgroundColor3 = Theme.WindowBackground
		svHandle.BorderColor3 = Theme.WindowBorder
		svHandle.BorderMode = Enum.BorderMode.Inset
		svHandle.BorderSizePixel = 1
		svHandle.Position = UDim2.fromScale(0, 0)
		svHandle.Size = UDim2.fromOffset(6, 6)
		
		local hueHandle = Instance.new("Frame")
		hueHandle.Parent = huePanel
		hueHandle.AnchorPoint = Vector2.new(0.5, 0.5)
		hueHandle.BackgroundColor3 = Theme.WindowBackground
		hueHandle.BorderColor3 = Theme.WindowBorder
		hueHandle.BorderMode = Enum.BorderMode.Inset
		hueHandle.BorderSizePixel = 1
		hueHandle.Position = UDim2.fromScale(0.5, 0)
		hueHandle.Size = UDim2.new(1, 4, 0, 6)
		
		local hexField = Instance.new("TextBox")
		hexField.Parent = picker
		hexField.AnchorPoint = Vector2.new(0.5, 1)
		hexField.BackgroundColor3 = Theme.TabBackground
		hexField.BorderColor3 = Theme.TabBorder
		hexField.BorderMode = Enum.BorderMode.Inset
		hexField.BorderSizePixel = 1
		hexField.Position = UDim2.new(0.5, 0, 1, -6)
		hexField.Size = UDim2.new(1, -12, 0, 22)
		hexField.Font = Enum.Font.Code
		hexField.Text = ""
		hexField.TextColor3 = Theme.Text
		hexField.TextSize = 14
		hexField.TextTruncate = Enum.TextTruncate.AtEnd
		hexField.TextXAlignment = Enum.TextXAlignment.Center
		hexField.ClearTextOnFocus = false
		
		local _h, _s, _v = 0, 0, 0
		local _hueInput = nil
		local _svInput = nil
		
		local function updateVisual()
			hueHandle.Position = UDim2.fromScale(0.5, _h)
			svHandle.Position = UDim2.fromScale(_s, 1 - _v)
			svPanel.BackgroundColor3 = Color3.fromHSV(_h, 1, 1)
		end
		
		local function updateHexField()
			local color = Color3.fromHSV(_h, _s, _v)
			hexField.Text = color:ToHex()
		end
		
		local function onValueChange()
			if window.colorPicker.colorElement then
				local color = Color3.fromHSV(_h, _s, _v)
				window.colorPicker.colorElement.callback(color)
			end
		end
		
		local function handleHueInput(input: InputObject)
			local relative = input.Position.Y - huePanel.AbsolutePosition.Y
			local ratio = math.clamp(relative / huePanel.AbsoluteSize.Y, 0, 1)

			_h = ratio
			
			updateVisual()
			updateHexField()
			onValueChange()
		end
		
		local function handleSvInput(input: InputObject)
			local relative = Vector2.new(input.Position.X, input.Position.Y) - svPanel.AbsolutePosition
			local ratio = Vector2.new(
				math.clamp(relative.X / svPanel.AbsoluteSize.X, 0, 1),
				math.clamp(relative.Y / svPanel.AbsoluteSize.Y, 0, 1)
			)
			
			_s = ratio.X
			_v = 1 - ratio.Y
			
			updateVisual()
			updateHexField()
			onValueChange()
		end
		
		local function setColor(color: Color3)
			_h, _s, _v = color:ToHSV()
			updateVisual()
			updateHexField()
			onValueChange()
		end
		
		AddConnection(huePanel.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_hueInput = input
				handleHueInput(input)
			end
		end)
		
		AddConnection(UserInputService.InputChanged, function(input: InputObject)
			if _hueInput and input.UserInputType == Enum.UserInputType.MouseMovement then
				handleHueInput(input)
			end
		end)
		
		AddConnection(huePanel.InputEnded, function(input: InputObject)
			if _hueInput == input and input.UserInputState == Enum.UserInputState.End then
				_hueInput = nil
			end
		end)
		
		AddConnection(svPanel.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_svInput = input
				handleSvInput(input)
			end
		end)

		AddConnection(UserInputService.InputChanged, function(input: InputObject)
			if _svInput and input.UserInputType == Enum.UserInputType.MouseMovement then
				handleSvInput(input)
			end
		end)

		AddConnection(svPanel.InputEnded, function(input: InputObject)
			if _svInput == input and input.UserInputState == Enum.UserInputState.End then
				_svInput = nil
			end
		end)
		
		AddConnection(hexField.FocusLost, function()
			local success, color = pcall(function()
				return Color3.fromHex(hexField.Text)
			end)
			if success then
				setColor(color)
			end
		end)
		
		window.colorPicker = {
			objects = {
				root = picker,
			},
			colorElement = nil,
			setColor = function(color: Color3)
				_h, _s, _v = color:ToHSV()
				updateVisual()
				updateHexField()
			end,
		}
	end

	return window
end

function Window:IsVisible(): boolean
	return self.objects.root.Visible
end

function Window:SetVisible(visible: boolean): ()
	self.objects.root.Visible = visible
end

function Window:CreateTab(name: string, properties: {[string]: any}?): typeof(Tab)
	properties = properties or {}
	
	local tab = setmetatable({}, Tab)
	tab.window = self
	tab.objects = {}
	tab.sections = {}
	table.insert(self.tabs, tab)

	local button = Instance.new("ImageButton")
	button.Parent = self.objects.tabs
	button.AutomaticSize = Enum.AutomaticSize.X
	button.AutoButtonColor = false
	button.BackgroundColor3 = Theme.TabBackground
	button.BorderColor3 = Theme.TabBorder
	button.BorderMode = Enum.BorderMode.Inset
	button.BorderSizePixel = 1
	button.Size = UDim2.fromOffset(0, 24)
	button.Image = ""

	local text = Instance.new("TextLabel")
	text.Parent = button
	text.AutomaticSize = Enum.AutomaticSize.X
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.Text
	text.TextSize = 14

	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = text
	uiPadding.PaddingLeft = UDim.new(0, 20)
	uiPadding.PaddingRight = UDim.new(0, 20)

	local fill = Instance.new("Frame")
	fill.Parent = button
	fill.AnchorPoint = Vector2.new(0.5, 1)
	fill.BackgroundColor3 = Theme.TabBackground
	fill.BorderSizePixel = 0
	fill.Position = UDim2.new(0.5, 0, 1, 2)
	fill.Size = UDim2.new(1, 0, 0, 2)

	local sections = Instance.new("Frame")
	sections.Parent = self.objects.tabSections
	sections.BorderSizePixel = 0
	sections.BackgroundTransparency = 1
	sections.Position = UDim2.new()
	sections.Size = UDim2.fromScale(1, 1)

	local sectionsL = Instance.new("ScrollingFrame")
	sectionsL.Parent = sections
	sectionsL.BackgroundTransparency = 1
	sectionsL.Position = UDim2.fromScale(0, 0)
	sectionsL.Size = UDim2.fromScale(0.5, 1)
	sectionsL.ScrollBarThickness = 0
	sectionsL.ScrollingDirection = Enum.ScrollingDirection.Y
	sectionsL.CanvasSize = UDim2.new()
	sectionsL.AutomaticCanvasSize = Enum.AutomaticSize.Y

	do
		local uiList = Instance.new("UIListLayout")
		uiList.Parent = sectionsL
		uiList.Padding = UDim.new(0, 18)
		uiList.FillDirection = Enum.FillDirection.Vertical

		local uiPadding = Instance.new("UIPadding")
		uiPadding.Parent = sectionsL
		uiPadding.PaddingTop = UDim.new(0, 20)
		uiPadding.PaddingBottom = UDim.new(0, 10)
		uiPadding.PaddingLeft = UDim.new(0, 10)
		uiPadding.PaddingRight = UDim.new(0, 5)
	end

	local sectionsR = Instance.new("ScrollingFrame")
	sectionsR.Parent = sections
	sectionsR.BackgroundTransparency = 1
	sectionsR.Position = UDim2.fromScale(0.5, 0)
	sectionsR.Size = UDim2.fromScale(0.5, 1)
	sectionsR.ScrollBarThickness = 0
	sectionsR.ScrollingDirection = Enum.ScrollingDirection.Y
	sectionsR.CanvasSize = UDim2.new()
	sectionsR.AutomaticCanvasSize = Enum.AutomaticSize.Y

	do
		local uiList = Instance.new("UIListLayout")
		uiList.Parent = sectionsR
		uiList.Padding = UDim.new(0, 18)
		uiList.FillDirection = Enum.FillDirection.Vertical

		local uiPadding = Instance.new("UIPadding")
		uiPadding.Parent = sectionsR
		uiPadding.PaddingTop = UDim.new(0, 20)
		uiPadding.PaddingBottom = UDim.new(0, 10)
		uiPadding.PaddingLeft = UDim.new(0, 5)
		uiPadding.PaddingRight = UDim.new(0, 10)
	end
	
	tab.objects.sectionsL = sectionsL
	tab.objects.sectionsR = sectionsR
	tab.selected = (#self.tabs == 1)

	function tab.updateVisual(selected: boolean)
		for _, t in self.tabs do
			if selected then
				button.BackgroundColor3 = Theme.TabBackground
				button.BorderColor3 = Theme.TabBorder
				text.TextColor3 = Theme.Text
				fill.Position = UDim2.new(0.5, 0, 1, 2)
			else
				button.BackgroundColor3 = Theme.WindowBackground
				button.BorderColor3 = Theme.TabBorderDark
				text.TextColor3 = Theme.TextDark
				fill.Position = UDim2.new(0.5, 0, 1, 1)
			end
			fill.BackgroundColor3 = button.BackgroundColor3
			sections.Visible = selected
		end
	end

	AddConnection(button.Activated, function()
		for _, t in self.tabs do
			if (t == tab) and (not t.selected) then
				tab.window.colorPicker.colorElement = nil
				tab.window.colorPicker.objects.root.Visible = false
			end
			t.updateVisual(t == tab)
			t.selected = (t == tab)
		end
	end)

	tab.updateVisual(#self.tabs == 1)

	return tab
end

function Tab:CreateSection(name: string, right: boolean?): typeof(Section)
	right = right or false
	
	local section = setmetatable({}, Section)
	section.tab = self
	section.objects = {}
	table.insert(self.sections, section)

	local frame = Instance.new("Frame")
	frame.Parent = right and self.objects.sectionsR or self.objects.sectionsL
	frame.BackgroundColor3 = Theme.SectionOuterBorder
	frame.BorderSizePixel = 0
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Size = UDim2.fromScale(1, 0)
	
	local background = Instance.new("Frame")
	background.Parent = frame
	background.BackgroundColor3 = Theme.SectionBackground
	background.BorderColor3 = Theme.SectionBorder
	background.BorderMode = Enum.BorderMode.Inset
	background.BorderSizePixel = 1
	background.AnchorPoint = Vector2.new(0.5, 0.5)
	background.Position = UDim2.fromScale(0.5, 0.5)
	background.Size = UDim2.new(1, -2, 1, -2)

	local line = Instance.new("Frame")
	line.Parent = frame
	line.AnchorPoint = Vector2.new(0.5, 0)
	line.BackgroundColor3 = Theme.Accent
	line.BorderSizePixel = 0
	line.Position = UDim2.fromScale(0.5, 0)
	line.Size = UDim2.new(1, -2, 0, 1)

	local textSpace = Instance.new("Frame")
	textSpace.Parent = frame
	textSpace.AutomaticSize = Enum.AutomaticSize.X
	textSpace.BackgroundTransparency = 1
	textSpace.BorderSizePixel = 0
	textSpace.Position = UDim2.fromOffset(10, -1)
	textSpace.Size = UDim2.fromOffset(0, 1)

	local fill = Instance.new("Frame")
	fill.Parent = textSpace
	fill.BackgroundColor3 = Theme.SectionBackground
	fill.BorderSizePixel = 0
	fill.Position = UDim2.fromOffset(0, 1)
	fill.Size = UDim2.new(1, 0, 0, 2)

	local text = Instance.new("TextLabel")
	text.Parent = textSpace
	text.AutomaticSize = Enum.AutomaticSize.X
	text.BackgroundTransparency = 1
	text.BorderSizePixel = 0
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.Accent
	text.TextSize = 14
	text.Position = UDim2.fromOffset(0, -8)
	text.Size = UDim2.fromOffset(0, 14)

	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = text
	uiPadding.PaddingLeft = UDim.new(0, 8)
	uiPadding.PaddingRight = UDim.new(0, 8)

	local elements = Instance.new("Frame")
	elements.Parent = frame
	elements.BackgroundTransparency = 1
	elements.BorderSizePixel = 0
	elements.Position = UDim2.new()
	elements.Size = UDim2.fromScale(1, 1)

	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = elements
	uiPadding.PaddingTop = UDim.new(0, 8)
	uiPadding.PaddingBottom = UDim.new(0, 4)

	local uiList = Instance.new("UIListLayout")
	uiList.Parent = elements
	uiList.Padding = UDim.new()
	uiList.FillDirection = Enum.FillDirection.Vertical
	uiList.SortOrder = Enum.SortOrder.LayoutOrder

	section.objects.elements = elements

	return section
end

function Section:AddToggle(name: string, properties: {[string]: any}?): ()
	properties = properties or {}
	local callback = properties.Callback or function() end
	
	local button = Instance.new("ImageButton")
	button.Parent = self.objects.elements
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Size = UDim2.new(1, 0, 0, 22)
	button.Image = ""

	local text = Instance.new("TextLabel")
	text.Parent = button
	text.AnchorPoint = Vector2.new(1, 0.5)
	text.BackgroundTransparency = 1
	text.Position = UDim2.new(1, 0, 0.5, 0)
	text.Size = UDim2.new(1, -32, 0, 14)
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.Text
	text.TextSize = 14
	text.TextTruncate = Enum.TextTruncate.AtEnd
	text.TextXAlignment = Enum.TextXAlignment.Left

	local switch = Instance.new("Frame")
	switch.Parent = button
	switch.AnchorPoint = Vector2.new(0, 0.5)
	switch.BackgroundColor3 = Theme.ElementOuterBorder
	switch.BorderSizePixel = 0
	switch.Position = UDim2.new(0, 8, 0.5, 0)
	switch.Size = UDim2.fromOffset(14, 14)
	
	local background = Instance.new("Frame")
	background.Parent = switch
	background.BackgroundColor3 = Theme.ElementBackground
	background.BorderColor3 = Theme.ElementBorder
	background.BorderMode = Enum.BorderMode.Inset
	background.BorderSizePixel = 1
	background.AnchorPoint = Vector2.new(0.5, 0.5)
	background.Position = UDim2.fromScale(0.5, 0.5)
	background.Size = UDim2.new(1, -2, 1, -2)

	local coreHolder = Instance.new("Frame")
	coreHolder.Parent = background
	coreHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	coreHolder.BackgroundTransparency = 1
	coreHolder.Position = UDim2.fromScale(0.5, 0.5)
	coreHolder.Size = UDim2.new(1, -2, 1, -2)

	local core = Instance.new("Frame")
	core.Parent = coreHolder
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.BackgroundColor3 = Theme.Accent
	core.BorderSizePixel = 0
	core.Position = UDim2.fromScale(0.5, 0.5)
	core.Size = UDim2.fromScale(1, 1)
	
	AddGradientFrame(core, {Color3.fromRGB(0, 0, 0)}, {0.6, 1}, -90)

	do
		local _value = properties.Value or false
		local _tween = nil

		local function updateVisual(silent: boolean?)
			if _tween and (_tween.PlaybackState ~= Enum.PlaybackState.Completed) then
				_tween:Cancel()
			end

			if silent then
				core.Size = _value and UDim2.fromScale(1, 1) or UDim2.new()
			else
				local info = TweenInfo.new(0.1, Enum.EasingStyle.Sine)
				local scale = _value and UDim2.fromScale(1, 1) or UDim2.new()
				_tween = TweenService:Create(core, info, {Size = scale})
				_tween:Play()
			end
		end

		AddConnection(button.Activated, function()
			_value = not _value
			updateVisual()
			callback(_value)
		end)

		updateVisual(true)
	end
	
	do -- ホールド時のアニメーション
		local _tween = nil
		local _hover = false
		local _hold = false

		local function updateAnim(hold: boolean)
			if _tween then
				_tween:Cancel()
			end

			local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
			_tween = TweenService:Create(switch, info, {
				BackgroundColor3 = hold and Theme.Accent or Theme.WindowBackground
			})
			_tween:Play()
		end

		AddConnection(button.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				_hover = true
				if not _hold then
					updateAnim(true)
				end
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_hold = true
				updateAnim(false)
			end
		end)

		AddConnection(button.InputEnded, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				_hover = false
				updateAnim(false)
			end
			if (input.UserInputType == Enum.UserInputType.MouseButton1) and (input.UserInputState == Enum.UserInputState.End) then
				_hold = false
				if _hover then
					updateAnim(true)
				end
			end
		end)
	end
end

function Section:AddSlider(name: string, properties: {[string]: any}?): ()
	properties = properties or {}
	
	local min = properties.Min or 0
	local max = properties.Max or 10
	local decimal = properties.Decimal or 0
	local defValue = properties.Value or min
	local callback = properties.Callback or function() end

	assert(min < max, "最大値は最小値より大きい必要があります。")

	local frame = Instance.new("Frame")
	frame.Parent = self.objects.elements
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 48)

	local text = Instance.new("TextLabel")
	text.Parent = frame
	text.AnchorPoint = Vector2.new(1, 0)
	text.BackgroundTransparency = 1
	text.Position = UDim2.new(1, 0, 0, 4)
	text.Size = UDim2.new(1, -10, 0, 14)
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.Text
	text.TextSize = 14
	text.TextTruncate = Enum.TextTruncate.AtEnd
	text.TextXAlignment = Enum.TextXAlignment.Left

	local slider = Instance.new("ImageButton")
	slider.Parent = frame
	slider.Active = true
	slider.Selectable = true
	slider.AutoButtonColor = false
	slider.AnchorPoint = Vector2.new(0.5, 1)
	slider.Image = ""
	slider.BackgroundColor3 = Theme.ElementOuterBorder
	slider.BorderSizePixel = 0
	slider.Position = UDim2.new(0.5, 0, 1, -4)
	slider.Size = UDim2.new(1, -16, 0, 20)
	
	local background = Instance.new("Frame")
	background.Parent = slider
	background.BackgroundColor3 = Theme.ElementBackground
	background.BorderColor3 = Theme.ElementBorder
	background.BorderMode = Enum.BorderMode.Inset
	background.BorderSizePixel = 1
	background.AnchorPoint = Vector2.new(0.5, 0.5)
	background.Position = UDim2.fromScale(0.5, 0.5)
	background.Size = UDim2.new(1, -2, 1, -2)
	
	local progressHolder = Instance.new("Frame")
	progressHolder.Parent = background
	progressHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	progressHolder.BackgroundTransparency = 1
	progressHolder.Position = UDim2.fromScale(0.5, 0.5)
	progressHolder.Size = UDim2.new(1, -2, 1, -2)

	local progress = Instance.new("Frame")
	progress.Parent = progressHolder
	progress.BackgroundColor3 = Theme.Accent
	progress.BorderSizePixel = 0
	progress.Position = UDim2.new()
	progress.Size = UDim2.new(1, 0, 1, 0)

	AddGradientFrame(progress, {Color3.fromRGB(0, 0, 0)}, {0.6, 1}, -90)

	do
		local range = max - min
		local decimalScale = 10 ^ decimal

		local _input = nil
		local _tween = nil
		local _value = defValue

		local function updateVisual(silent: boolean?)
			local ratio = math.clamp((_value - min) / range, 0, 1)
			
			text.Text = name:format(_value)
			
			if silent then
				progress.Size = UDim2.new(ratio, 0, 1, 0)
			else
				if _tween and (_tween.PlaybackState ~= Enum.PlaybackState.Completed) then
					_tween:Cancel()
				end

				local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
				_tween = TweenService:Create(progress, info, {Size = UDim2.new(ratio, 0, 1, 0)})
				_tween:Play()
			end
		end

		local function handleInput(input: InputObject)
			local relativePos = input.Position.X - progressHolder.AbsolutePosition.X
			local ratio = math.clamp(relativePos / progressHolder.AbsoluteSize.X, 0, 1)
			local rangeValue = math.round(ratio * range * decimalScale) / decimalScale
			local value = math.clamp(rangeValue + min, min, max)

			local valueChanged = value ~= _value
			_value = value
			
			if valueChanged then
				updateVisual()
			end
			callback(value)
		end
		
		AddConnection(slider.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_input = input
				handleInput(input)
			end
		end)

		AddConnection(UserInputService.InputChanged, function(input: InputObject, gameProcessedEvent: boolean)
			if _input and (input.UserInputType == Enum.UserInputType.MouseMovement) then
				handleInput(input)
			end
		end)

		AddConnection(slider.InputEnded, function(input: InputObject)
			if (input == _input) and (input.UserInputState == Enum.UserInputState.End) then
				_input = nil
			end
		end)

		updateVisual(true)
	end
	
	do -- ホールド時のアニメーション
		local _tween = nil
		local _hover = false
		local _hold = false

		local function updateAnim(hold: boolean)
			if _tween then
				_tween:Cancel()
			end

			local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
			_tween = TweenService:Create(slider, info, {
				BackgroundColor3 = hold and Theme.Accent or Theme.WindowBackground
			})
			_tween:Play()
		end

		AddConnection(slider.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				_hover = true
				if not _hold then
					updateAnim(true)
				end
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_hold = true
				updateAnim(false)
			end
		end)

		AddConnection(slider.InputEnded, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				_hover = false
				updateAnim(false)
			end
			if (input.UserInputType == Enum.UserInputType.MouseButton1) and (input.UserInputState == Enum.UserInputState.End) then
				_hold = false
				if _hover then
					updateAnim(true)
				end
			end
		end)
	end
end

function Section:AddColor(name: string, properties: {[string]: any}?): ()
	properties = properties or {}
	local defValue = properties.Value or Color3.fromRGB(255, 255, 255)
	local callback = properties.Callback or function() end
	
	local button = Instance.new("ImageButton")
	button.Parent = self.objects.elements
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Size = UDim2.new(1, 0, 0, 22)
	button.Image = ""

	local background = Instance.new("Frame")
	background.Parent = button
	background.AnchorPoint = Vector2.new(1, 0.5)
	background.BackgroundColor3 = Theme.ElementOuterBorder
	background.BorderSizePixel = 0
	background.Position = UDim2.new(1, -8, 0.5, 0)
	background.Size = UDim2.fromOffset(24, 16)
	
	local panelHolder = Instance.new("Frame")
	panelHolder.Parent = background
	panelHolder.BackgroundColor3 = Theme.ElementBackground
	panelHolder.BorderColor3 = Theme.ElementBorder
	panelHolder.BorderMode = Enum.BorderMode.Inset
	panelHolder.BorderSizePixel = 1
	panelHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	panelHolder.Position = UDim2.fromScale(0.5, 0.5)
	panelHolder.Size = UDim2.new(1, -2, 1, -2)
	
	local panel = Instance.new("Frame")
	panel.Parent = panelHolder
	panel.BackgroundColor3 = defValue
	panel.BorderSizePixel = 0
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -2, 1, -2)

	local gradient = Instance.new("Frame")
	gradient.Parent = panel
	gradient.BorderSizePixel = 0
	gradient.Position = UDim2.new()
	gradient.Size = UDim2.fromScale(1, 1)

	local uiGradient = Instance.new("UIGradient")
	uiGradient.Parent = gradient
	uiGradient.Rotation = -90
	uiGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
	uiGradient.Transparency = NumberSequence.new(0.6, 1)

	local text = Instance.new("TextLabel")
	text.Parent = button
	text.AnchorPoint = Vector2.new(0, 0.5)
	text.BackgroundTransparency = 1
	text.Position = UDim2.new(0, 10, 0.5, 0)
	text.Size = UDim2.new(1, -46, 0, 14)
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.Text
	text.TextSize = 14
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextTruncate = Enum.TextTruncate.AtEnd
	
	do
		local _color = defValue

		local function updateVisual()
			panel.BackgroundColor3 = _color
		end

		local colorElement = {
			callback = function(color: Color3)
				_color = color
				updateVisual()
				callback(color)
			end,
		}

		AddConnection(button.Activated, function()
			local windowInfo = self.tab.window
			local colorPickerInfo = self.tab.window.colorPicker
			
			local windowRoot = windowInfo.objects.root
			local pickerRoot = colorPickerInfo.objects.root
			
			if colorPickerInfo.colorElement == colorElement then
				colorPickerInfo.colorElement = nil
				pickerRoot.Visible = false
			else
				colorPickerInfo.colorElement = colorElement
				colorPickerInfo.setColor(_color)
				local rel = button.AbsolutePosition - windowRoot.AbsolutePosition + Vector2.new(button.AbsoluteSize.X / 2, button.AbsoluteSize.Y)

				pickerRoot.Parent = windowRoot
				pickerRoot.Visible = true
				pickerRoot.Position = UDim2.fromOffset(rel.X, rel.Y)
			end
		end)
	end
	
	do -- ホールド時のアニメーション
		local _tween = nil
		local _hover = false
		local _hold = false

		local function updateAnim(hold: boolean)
			if _tween then
				_tween:Cancel()
			end

			local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
			_tween = TweenService:Create(background, info, {
				BackgroundColor3 = hold and Theme.Accent or Theme.WindowBackground
			})
			_tween:Play()
		end

		AddConnection(button.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				_hover = true
				if not _hold then
					updateAnim(true)
				end
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_hold = true
				updateAnim(false)
			end
		end)

		AddConnection(button.InputEnded, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				_hover = false
				updateAnim(false)
			end
			if (input.UserInputType == Enum.UserInputType.MouseButton1) and (input.UserInputState == Enum.UserInputState.End) then
				_hold = false
				if _hover then
					updateAnim(true)
				end
			end
		end)
	end
end

function Section:AddButton(name: string, properties: {[string]: any}): ()
	properties = properties or {}
	local callback = properties.Callback or function() end
	
	local frame = Instance.new("Frame")
	frame.Parent = self.objects.elements
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 32)
	
	local button = Instance.new("ImageButton")
	button.Parent = frame
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.AutoButtonColor = false
	button.BackgroundColor3 = Theme.ElementOuterBorder
	button.BorderSizePixel = 0
	button.Position = UDim2.fromScale(0.5, 0.5)
	button.Size = UDim2.new(1, -16, 0, 26)
	button.Image= ""
	
	local background = Instance.new("Frame")
	background.Parent = button
	background.AnchorPoint = Vector2.new(0.5, 0.5)
	background.BackgroundColor3 = Theme.ButtonBackground
	background.BorderColor3 = Theme.ElementBorder
	background.BorderMode = Enum.BorderMode.Inset
	background.BorderSizePixel = 1
	background.Position = UDim2.fromScale(0.5, 0.5)
	background.Size = UDim2.new(1, -2, 1, -2)
	
	AddGradientFrame(background, {Color3.fromRGB(0, 0, 0)}, {0.6, 1}, -90)
	
	local text = Instance.new("TextLabel")
	text.Parent = background
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.Code
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.ButtonText
	text.TextSize = 14
	text.TextXAlignment = Enum.TextXAlignment.Center
	text.TextTruncate = Enum.TextTruncate.AtEnd
	
	AddConnection(button.Activated, function()
		callback()
	end)
	
	do -- ホールド時のアニメーション
		local _tween = nil
		local _hover = false
		local _hold = false
		
		local function updateAnim(hold: boolean)
			if _tween then
				_tween:Cancel()
			end

			local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
			_tween = TweenService:Create(button, info, {
				BackgroundColor3 = hold and Theme.Accent or Theme.WindowBackground
			})
			_tween:Play()
		end

		AddConnection(button.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				_hover = true
				if not _hold then
					updateAnim(true)
				end
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_hold = true
				updateAnim(false)
			end
		end)

		AddConnection(button.InputEnded, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				_hover = false
				updateAnim(false)
			end
			if (input.UserInputType == Enum.UserInputType.MouseButton1) and (input.UserInputState == Enum.UserInputState.End) then
				_hold = false
				if _hover then
					updateAnim(true)
				end
			end
		end)
	end
end

return UILibrary
