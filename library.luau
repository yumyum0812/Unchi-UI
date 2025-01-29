local UILibrary = {}

-- サービス
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- テーマ
local Theme = {
	Accent = Color3.fromRGB(168, 62, 244),
	Text = Color3.fromRGB(214, 214, 214),
	WindowBackground = Color3.fromRGB(38, 38, 38),
	WindowBorderInner = Color3.fromRGB(75, 75, 75),
	WindowBorderOuter = Color3.fromRGB(20, 20, 20),
	TabText = Color3.fromRGB(128, 128, 128),
	TabBackground = Color3.fromRGB(34, 34, 34),
	TabBorderInner = Color3.fromRGB(22, 22, 22),
	TabBorderOuter = Color3.fromRGB(70, 70, 70),
	SectionBackground = Color3.fromRGB(44, 44, 44),
	SectionBorderInner = Color3.fromRGB(63, 63, 63),
	SectionBorderOuter = Color3.fromRGB(26, 26, 26),
	ElementBackground = Color3.fromRGB(50, 50, 50),
	ElementBorderInner = Color3.fromRGB(88, 88, 88),
	ElementBorderOuter = Color3.fromRGB(32, 32, 32),
	ButtonText = Color3.fromRGB(185, 185, 185),
	ButtonBackground = Color3.fromRGB(68, 68, 68),
}

-- 変数
local gui = nil
local windows = {}
local connections = {}

-- クラス
local Section = {}
Section.__index = Section

local Tab = {}
Tab.__index = Tab

local Window = {}
Window.__index = Window

--

local function GetCoreGui(): ()
	return game:GetService("CoreGui")
end

local function GetHiddenGui(): ()
	local env = getfenv()
	local wrapped = env.gethui or GetCoreGui
	return wrapped()
end

local function TryProtectGui(gui: ScreenGui): ()
	local env = getfenv()
	local syn = env.syn
	if syn and syn.protect_gui then
		syn.protect_gui(gui)
	end
end

-- 初期化
do
	gui = Instance.new("ScreenGui")
	gui.Name = "Unchi"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.AutoLocalize = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local success = pcall(function()
		gui.Parent = GetHiddenGui()
	end)
	if not success then
		gui.Parent = Players.LocalPlayer.PlayerGui
	end
	TryProtectGui(gui)
end

local function AddConnection(signal: RBXScriptSignal, callback: (any...) -> any...): ()
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
end

local function ClearConnections(): ()
	for i, connection in connections do
		connection:Disconnect()
		connections[i] = nil
	end
end

local function AddGradientFrame(object: GuiBase, colors: Color3 | {Color3}, transparencies: (number | {number})?, rotation: number?, sizeOffset: number?): UIGradient
	transparencies = transparencies or 0
	rotation = rotation or 0
	sizeOffset = sizeOffset or 0

	local frame = Instance.new("Frame")
	frame.Parent = object
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.new(1, sizeOffset * 2, 1, sizeOffset * 2)

	local uiGradient = Instance.new("UIGradient")
	uiGradient.Parent = frame
	uiGradient.Rotation = rotation

	if typeof(colors) == "Color3" then
		uiGradient.Color = ColorSequence.new(colors)
	else
		local keypoints = {}
		for i, color in colors do
			local point = ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color)
			table.insert(keypoints, point)
		end
		uiGradient.Color = ColorSequence.new(keypoints)
	end

	if typeof(transparencies) == "number" then
		uiGradient.Transparency = NumberSequence.new(transparencies)
	else
		local keypoints = {}
		for i, transparency in transparencies do
			local point = NumberSequenceKeypoint.new((i - 1) / (#transparencies - 1), transparency)
			table.insert(keypoints, point)
		end
		uiGradient.Transparency = NumberSequence.new(keypoints)
	end

	return uiGradient
end

local function AddBorderFrame(object: GuiBase, color: Color3, thickness: number, sizeOffset: number?): ()
	sizeOffset = sizeOffset or 0

	local frame = Instance.new("Frame")
	frame.Parent = object
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(1, sizeOffset * 2, 1, sizeOffset * 2)
	frame.Position = UDim2.fromScale(0.5, 0.5)

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Parent = frame
	uiStroke.Enabled = true
	uiStroke.Color = color
	uiStroke.Transparency = 0
	uiStroke.Thickness = thickness
	uiStroke.LineJoinMode = Enum.LineJoinMode.Miter
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	return uiStroke
end

function UILibrary:Destroy(): ()
	ClearConnections()

	windows = {}

	gui:Destroy()
	gui = nil
end

function UILibrary:CreateWindow(properties: {[string]: any}?): typeof(Window)	
	local name = properties.Name
	local width = properties.Width or 450
	local height = properties.Height or 540
	local position = properties.Position or UDim2.fromScale(0.5, 0.5)

	local window = setmetatable({}, Window)
	window.tabs = {}
	window.objects = {}
	table.insert(windows, window)

	local root = Instance.new("Frame")
	root.Parent = gui
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.BackgroundTransparency = 1
	root.Position = position
	root.Size = UDim2.fromOffset(width, height)

	local background = Instance.new("Frame")
	background.Parent = root
	background.BackgroundColor3 = Theme.WindowBackground
	background.BorderSizePixel = 0
	background.BorderColor3 = Theme.WindowBorderOuter
	background.BorderMode = Enum.BorderMode.Inset
	background.BorderSizePixel = 1
	background.Size = UDim2.fromScale(1, 1)

	AddBorderFrame(root, Theme.WindowBorderInner, 1, -2)

	local handle = Instance.new("ImageButton")
	handle.Parent = root
	handle.BackgroundTransparency = 1
	handle.Size = UDim2.new(1, 0, 0, 64)
	handle.Image = ""
	handle.Selectable = false

	local title = Instance.new("TextLabel")
	title.Parent = root
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0.5, 0, 0, 12)
	title.Size = UDim2.new(1, -24, 0, 14)
	title.Font = Enum.Font.Code
	title.Text = name
	title.TextColor3 = Theme.Accent
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.SplitWord
	title.RichText = true

	local tabs = Instance.new("ScrollingFrame")
	tabs.Parent = root
	tabs.AnchorPoint = Vector2.new(0.5, 0)
	tabs.BackgroundTransparency = 1
	tabs.Position = UDim2.new(0.5, 0, 0, 31)
	tabs.Size = UDim2.new(1, -12, 0, 30)
	tabs.ScrollBarThickness = 0
	tabs.ScrollingDirection = Enum.ScrollingDirection.X
	tabs.CanvasSize = UDim2.new()
	tabs.AutomaticCanvasSize = Enum.AutomaticSize.X

	local tabsHolder = Instance.new("Frame")
	tabsHolder.Parent = tabs
	tabsHolder.AutomaticSize = Enum.AutomaticSize.X
	tabsHolder.BackgroundTransparency = 1
	tabsHolder.Size = UDim2.new(0, 0, 1, -1)

	local tabLine = Instance.new("Frame")
	tabLine.Parent = tabs
	tabLine.AnchorPoint = Vector2.new(0.5, 1)
	tabLine.BackgroundColor3 = Theme.Accent
	tabLine.BorderSizePixel = 0
	tabLine.Position = UDim2.new()
	tabLine.Size = UDim2.new()

	local uiList = Instance.new("UIListLayout")
	uiList.Parent = tabsHolder
	uiList.Padding = UDim.new(0, 0)
	uiList.FillDirection = Enum.FillDirection.Horizontal
	uiList.SortOrder = Enum.SortOrder.LayoutOrder

	local tabSections = Instance.new("Frame")
	tabSections.Parent = root
	tabSections.AnchorPoint = Vector2.new(0.5, 1)
	tabSections.BackgroundTransparency = 1
	tabSections.Position = UDim2.new(0.5, 0, 1, -6)
	tabSections.Size = UDim2.new(1, -12, 1, -66)

	local tabSectionsBg = Instance.new("Frame")
	tabSectionsBg.Parent = tabSections
	tabSectionsBg.BackgroundColor3 = Theme.TabBackground
	tabSectionsBg.Size = UDim2.fromScale(1, 1)
	tabSectionsBg.BorderColor3 = Theme.TabBorderOuter
	tabSectionsBg.BorderMode = Enum.BorderMode.Inset
	tabSectionsBg.BorderSizePixel = 1

	do
		local outline = Instance.new("Frame")
		outline.Parent = tabSections
		outline.BackgroundTransparency = 1
		outline.AnchorPoint = Vector2.new(0.5, 0.5)
		outline.Position = UDim2.fromScale(0.5, 0.5)
		outline.Size = UDim2.new(1, -4, 1, -4)

		local stroke = Instance.new("UIStroke")
		stroke.Parent = outline
		stroke.Enabled = true
		stroke.Color = Theme.TabBorderInner
		stroke.Thickness = 1
		stroke.LineJoinMode = Enum.LineJoinMode.Miter
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end

	window.objects.root = root
	window.objects.tabs = tabsHolder
	window.objects.tabSections = tabSections
	window.objects.tabLine = tabLine

	do -- ドラッグ対応
		local _input = nil
		local _startPos = nil
		local _startInput = nil
		
		local function onInputBegan(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_input = input
				_startPos = root.Position
				_startInput = input.Position

				local index = table.find(windows, window)
				if index then
					table.remove(windows, index)
					table.insert(windows, window)

					for i, w in windows do
						w.objects.root.ZIndex = i
					end
				end
			end
		end
		
		local function onInputEnded(input: InputObject)
			if (input == _input) and (input.UserInputState == Enum.UserInputState.End) then
				_input = nil
				_startPos = nil
				_startInput = nil
			end
		end
		
		local function onInputChanged(input: InputObject, gameProcessedEvent: boolean)
			if _input and (input.UserInputType == Enum.UserInputType.MouseMovement) then
				local add = input.Position - _startInput
				root.Position = _startPos + UDim2.fromOffset(add.X, add.Y)
			end
		end

		AddConnection(handle.InputBegan, onInputBegan)
		AddConnection(handle.InputEnded, onInputEnded)
		AddConnection(UserInputService.InputChanged, onInputChanged)
	end

	do -- カラーピッカー
		local pickerRoot = Instance.new("Frame")
		pickerRoot.Parent = root
		pickerRoot.AnchorPoint = Vector2.new(0.5, 0)
		pickerRoot.BackgroundTransparency = 1
		pickerRoot.Position = UDim2.fromOffset(-4, 0)
		pickerRoot.Size = UDim2.fromOffset(206, 206)
		pickerRoot.Visible = false

		local pickerBg = Instance.new("Frame")
		pickerBg.Parent = pickerRoot
		pickerBg.BackgroundColor3 = Theme.SectionBackground
		pickerBg.BorderColor3 = Theme.SectionBorderOuter
		pickerBg.BorderMode = Enum.BorderMode.Inset
		pickerBg.BorderSizePixel = 1
		pickerBg.Size = UDim2.fromScale(1, 1)

		AddBorderFrame(pickerRoot, Theme.SectionBorderInner, 1, -2)

		local svPanelRoot = Instance.new("ImageButton")
		svPanelRoot.Parent = pickerRoot
		svPanelRoot.AutoButtonColor = false
		svPanelRoot.BackgroundTransparency = 1
		svPanelRoot.Position = UDim2.fromOffset(4, 4)
		svPanelRoot.Size = UDim2.fromOffset(170, 170)
		svPanelRoot.Image = ""

		local svPanelBg = Instance.new("Frame")
		svPanelBg.Parent = svPanelRoot
		svPanelBg.BackgroundColor3 = Theme.ElementBackground
		svPanelBg.BorderColor3 = Theme.ElementBorderOuter
		svPanelBg.BorderMode = Enum.BorderMode.Inset
		svPanelBg.BorderSizePixel = 1
		svPanelBg.Size = UDim2.fromScale(1, 1)

		AddBorderFrame(svPanelRoot, Theme.ElementBorderInner, 1, -2)

		local svPanel = Instance.new("Frame")
		svPanel.Parent = svPanelRoot
		svPanel.AnchorPoint = Vector2.new(0.5, 0.5)
		svPanel.BorderSizePixel = 0
		svPanel.Position = UDim2.fromScale(0.5, 0.5)
		svPanel.Size = UDim2.new(1, -6, 1, -6)

		AddGradientFrame(svPanel, Color3.fromRGB(255, 255, 255), {0, 1}, 0)
		AddGradientFrame(svPanel, Color3.fromRGB(0, 0, 0), {0, 1}, -90)

		local huePanelRoot = Instance.new("ImageButton")
		huePanelRoot.Parent = pickerRoot
		huePanelRoot.AutoButtonColor = false
		huePanelRoot.BackgroundTransparency = 1
		huePanelRoot.Position = UDim2.fromOffset(178, 4)
		huePanelRoot.Size = UDim2.fromOffset(24, 170)
		huePanelRoot.Image = ""

		local huePanelBg = Instance.new("Frame")
		huePanelBg.Parent = huePanelRoot
		huePanelBg.BackgroundColor3 = Theme.ElementBackground
		huePanelBg.BorderColor3 = Theme.ElementBorderOuter
		huePanelBg.BorderMode = Enum.BorderMode.Inset
		huePanelBg.BorderSizePixel = 1
		huePanelBg.Size = UDim2.fromScale(1, 1)

		AddBorderFrame(huePanelRoot, Theme.ElementBorderInner, 1, -2)

		local huePanel = Instance.new("Frame")
		huePanel.Parent = huePanelRoot
		huePanel.AnchorPoint = Vector2.new(0.5, 0.5)
		huePanel.BorderSizePixel = 0
		huePanel.Position = UDim2.fromScale(0.5, 0.5)
		huePanel.Size = UDim2.new(1, -6, 1, -6)

		AddGradientFrame(huePanel, {
			Color3.fromHSV(0 / 7, 1, 1),
			Color3.fromHSV(1 / 7, 1, 1),
			Color3.fromHSV(2 / 7, 1, 1),
			Color3.fromHSV(3 / 7, 1, 1),
			Color3.fromHSV(4 / 7, 1, 1),
			Color3.fromHSV(5 / 7, 1, 1),
			Color3.fromHSV(6 / 7, 1, 1),
			Color3.fromHSV(7 / 7, 1, 1)
		}, nil, 90)

		local svHandle = Instance.new("Frame")
		svHandle.Parent = svPanel
		svHandle.AnchorPoint = Vector2.new(0.5, 0.5)
		svHandle.BackgroundColor3 = Theme.ElementBackground
		svHandle.BorderColor3 = Theme.ElementBorderOuter
		svHandle.BorderMode = Enum.BorderMode.Inset
		svHandle.BorderSizePixel = 1
		svHandle.Position = UDim2.fromScale(0, 0)
		svHandle.Size = UDim2.fromOffset(8, 8)

		AddBorderFrame(svHandle, Theme.ElementBorderInner, 1, -1)

		local hueHandle = Instance.new("Frame")
		hueHandle.Parent = huePanel
		hueHandle.AnchorPoint = Vector2.new(0.5, 0.5)
		hueHandle.BackgroundColor3 = Theme.ElementBackground
		hueHandle.BorderColor3 = Theme.ElementBorderOuter
		hueHandle.BorderMode = Enum.BorderMode.Inset
		hueHandle.BorderSizePixel = 1
		hueHandle.Position = UDim2.fromScale(0.5, 0)
		hueHandle.Size = UDim2.new(1, 8, 0, 8)

		AddBorderFrame(hueHandle, Theme.ElementBorderInner, 1, -1)

		local hexFieldRoot = Instance.new("Frame")
		hexFieldRoot.Parent = pickerRoot
		hexFieldRoot.AnchorPoint = Vector2.new(0.5, 1)
		hexFieldRoot.BackgroundTransparency = 1
		hexFieldRoot.Position = UDim2.new(0.5, 0, 1, -4)
		hexFieldRoot.Size = UDim2.new(1, -8, 0, 24)

		local hexFieldBg = Instance.new("Frame")
		hexFieldBg.Parent = hexFieldRoot
		hexFieldBg.BackgroundColor3 = Theme.ButtonBackground
		hexFieldBg.BorderColor3 = Theme.ElementBorderOuter
		hexFieldBg.BorderMode = Enum.BorderMode.Inset
		hexFieldBg.BorderSizePixel = 1
		hexFieldBg.Size = UDim2.fromScale(1, 1)

		AddBorderFrame(hexFieldRoot, Theme.ElementBorderInner, 1, -2)

		local hexField = Instance.new("TextBox")
		hexField.Parent = hexFieldRoot
		hexField.AnchorPoint = Vector2.new(0.5, 0.5)
		hexField.BackgroundTransparency = 1
		hexField.Position = UDim2.fromScale(0.5, 0.5)
		hexField.Size = UDim2.new(1, -4, 1, -4)
		hexField.Font = Enum.Font.Code
		hexField.Text = ""
		hexField.TextColor3 = Theme.Text
		hexField.TextSize = 14
		hexField.TextTruncate = Enum.TextTruncate.SplitWord
		hexField.TextXAlignment = Enum.TextXAlignment.Center
		hexField.ClearTextOnFocus = false

		AddGradientFrame(hexField, Color3.fromRGB(0, 0, 0), {0.6, 1}, -90)

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

		local function onValueChanged()
			if window.colorPicker.functions.onValueChanged then
				local color = Color3.fromHSV(_h, _s, _v)
				window.colorPicker.functions.onValueChanged(color)
			end
		end

		local function handleHueInput(input: InputObject)
			local relative = input.Position.Y - huePanel.AbsolutePosition.Y
			local ratio = math.clamp(relative / huePanel.AbsoluteSize.Y, 0, 1)

			_h = ratio

			updateVisual()
			updateHexField()
			onValueChanged()
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
			onValueChanged()
		end

		local function setColor(color: Color3)
			_h, _s, _v = color:ToHSV()
			updateVisual()
			updateHexField()
			onValueChanged()
		end
		
		local function onHueInputBegan(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_hueInput = input
				handleHueInput(input)
			end
		end
		
		local function onHueInputEnded(input: InputObject)
			if _hueInput == input and input.UserInputState == Enum.UserInputState.End then
				_hueInput = nil
			end
		end
		
		local function onHueInputChanged(input: InputObject)
			if _hueInput and input.UserInputType == Enum.UserInputType.MouseMovement then
				handleHueInput(input)
			end
		end
		
		local function onSvInputBegan(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_svInput = input
				handleSvInput(input)
			end
		end
		
		local function onSvInputEnded(input: InputObject)
			if _svInput == input and input.UserInputState == Enum.UserInputState.End then
				_svInput = nil
			end
		end
		
		local function onSvInputChanged(input: InputObject)
			if _svInput and input.UserInputType == Enum.UserInputType.MouseMovement then
				handleSvInput(input)
			end
		end
		
		local function onHexFieldFocusLost()
			local success, color = pcall(function()
				return Color3.fromHex(hexField.Text)
			end)
			if success then
				setColor(color)
			end
		end

		AddConnection(huePanelRoot.InputBegan, onHueInputBegan)
		AddConnection(huePanelRoot.InputEnded, onHueInputEnded)
		AddConnection(UserInputService.InputChanged, onHueInputChanged)

		AddConnection(svPanelRoot.InputBegan, onSvInputBegan)
		AddConnection(svPanelRoot.InputEnded, onSvInputEnded)
		AddConnection(UserInputService.InputChanged, onSvInputChanged)

		AddConnection(hexField.FocusLost, onHexFieldFocusLost)

		window.colorPicker = {
			objects = {
				root = pickerRoot,
			},
			functions = {
				onValueChanged = nil,
			},
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

function Window:CreateTab(properties: {[string]: any}): typeof(Tab)
	local name = properties.Name

	local tab = setmetatable({}, Tab)
	tab.window = self
	tab.functions = {}
	tab.objects = {}
	tab.sections = {}
	table.insert(self.tabs, tab)

	local button = Instance.new("TextButton")
	button.Parent = self.objects.tabs
	button.AutomaticSize = Enum.AutomaticSize.X
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Size = UDim2.fromScale(0, 1)
	button.Font = Enum.Font.Code
	button.Text = name
	button.TextColor3 = Theme.Accent
	button.TextSize = 14
	button.RichText = true

	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = button
	uiPadding.PaddingLeft = UDim.new(0, 16)
	uiPadding.PaddingRight = UDim.new(0, 16)

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
		uiList.Padding = UDim.new(0, 14)
		uiList.FillDirection = Enum.FillDirection.Vertical

		local uiPadding = Instance.new("UIPadding")
		uiPadding.Parent = sectionsL
		uiPadding.PaddingTop = UDim.new(0, 16)
		uiPadding.PaddingBottom = UDim.new(0, 10)
		uiPadding.PaddingLeft = UDim.new(0, 8)
		uiPadding.PaddingRight = UDim.new(0, 4)
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
		uiList.Padding = UDim.new(0, 14)
		uiList.FillDirection = Enum.FillDirection.Vertical

		local uiPadding = Instance.new("UIPadding")
		uiPadding.Parent = sectionsR
		uiPadding.PaddingTop = UDim.new(0, 16)
		uiPadding.PaddingBottom = UDim.new(0, 10)
		uiPadding.PaddingLeft = UDim.new(0, 4)
		uiPadding.PaddingRight = UDim.new(0, 8)
	end

	tab.objects.sectionsL = sectionsL
	tab.objects.sectionsR = sectionsR
	tab.selected = (#self.tabs == 1)

	local _tween = nil

	tab.functions.updateVisual = function(instant: boolean?)
		button.TextColor3 = tab.selected and Theme.Accent or Theme.TabText
		sections.Visible = tab.selected

		if tab.selected then
			if instant then
				self.objects.tabLine.Position = UDim2.new(0, button.AbsolutePosition.X - self.objects.tabs.AbsolutePosition.X + button.AbsoluteSize.X / 2, 1, -1)
				self.objects.tabLine.Size = UDim2.fromOffset(button.AbsoluteSize.X, 1)
			else
				if _tween then
					_tween:Cancel()
					_tween = nil
				end

				local info = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
				_tween = TweenService:Create(self.objects.tabLine, info, {
					Position = UDim2.new(0, button.AbsolutePosition.X - self.objects.tabs.AbsolutePosition.X + button.AbsoluteSize.X / 2, 1, -1),
					Size = UDim2.fromOffset(button.AbsoluteSize.X, 1)
				})
				_tween:Play()
			end
		end
	end

	do
		local function onAbsoluteSizeChanged()
			if tab.selected then
				tab.functions.updateVisual(true)
			end
		end
		
		AddConnection(button:GetPropertyChangedSignal("AbsoluteSize"), onAbsoluteSizeChanged)
	end

	do
		local function onActivated()
			if not tab.selected then
				tab.window.colorPicker.functions.onValueChanged = nil
				tab.window.colorPicker.objects.root.Visible = false

				for _, t in self.tabs do
					t.selected = (t == tab)
					t.functions.updateVisual()
				end
			end
		end
		
		AddConnection(button.Activated, onActivated)
	end

	tab.functions.updateVisual(true)

	do -- ホールド時のアニメーション
		local _tween = nil
		local _hover = false
		local _hold = false

		local function updateAnim(hold: boolean)
			if _tween then
				_tween:Cancel()
			end

			if not tab.selected then
				local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
				_tween = TweenService:Create(button, info, {
					TextColor3 = hold and Theme.Accent or Theme.TabText
				})
				_tween:Play()
			end
		end
		
		local function onInputBegan(input: InputObject)
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
		end
		
		local function onInputEnded(input: InputObject)
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
		end

		AddConnection(button.InputBegan, onInputBegan)
		AddConnection(button.InputEnded, onInputEnded)
	end

	return tab
end

function Tab:CreateSection(properties: {[string]: any}): typeof(Section)
	local name = properties.Name
	local rightSide = properties.RightSide

	local section = setmetatable({}, Section)
	section.tab = self
	section.objects = {}
	table.insert(self.sections, section)

	local root = Instance.new("Frame")
	root.Parent = rightSide and self.objects.sectionsR or self.objects.sectionsL
	root.BackgroundTransparency = 1
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.Size = UDim2.fromScale(1, 0)

	local background = Instance.new("Frame")
	background.Parent = root
	background.BackgroundColor3 = Theme.SectionBackground
	background.BorderColor3 = Theme.SectionBorderOuter
	background.BorderMode = Enum.BorderMode.Inset
	background.BorderSizePixel = 1
	background.Size = UDim2.fromScale(1, 1)

	AddBorderFrame(root, Theme.SectionBorderInner, 1, -2)

	local line = Instance.new("Frame")
	line.Parent = root
	line.AnchorPoint = Vector2.new(0.5, 0)
	line.BackgroundColor3 = Theme.Accent
	line.BorderSizePixel = 0
	line.Position = UDim2.fromScale(0.5, 0)
	line.Size = UDim2.new(1, -2, 0, 1)

	local textSpace = Instance.new("Frame")
	textSpace.Parent = root
	textSpace.AutomaticSize = Enum.AutomaticSize.X
	textSpace.BackgroundTransparency = 1
	textSpace.BorderSizePixel = 0
	textSpace.Position = UDim2.fromOffset(12, 0)
	textSpace.Size = UDim2.fromOffset(0, 1)

	local fill = Instance.new("Frame")
	fill.Parent = textSpace
	fill.BackgroundColor3 = Theme.SectionBackground
	fill.BorderSizePixel = 0
	fill.Position = UDim2.fromOffset(0, 0)
	fill.Size = UDim2.new(1, 0, 0, 2)

	local text = Instance.new("TextLabel")
	text.Parent = textSpace
	text.AutomaticSize = Enum.AutomaticSize.X
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromOffset(0, -8)
	text.Size = UDim2.fromOffset(0, 14)
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.Accent
	text.TextSize = 14
	text.RichText = true

	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = text
	uiPadding.PaddingLeft = UDim.new(0, 8)
	uiPadding.PaddingRight = UDim.new(0, 8)

	local elements = Instance.new("Frame")
	elements.Parent = root
	elements.BackgroundTransparency = 1
	elements.BorderSizePixel = 0
	elements.Position = UDim2.new()
	elements.Size = UDim2.fromScale(1, 1)

	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = elements
	uiPadding.PaddingTop = UDim.new(0, 8)
	uiPadding.PaddingBottom = UDim.new(0, 6)

	local uiList = Instance.new("UIListLayout")
	uiList.Parent = elements
	uiList.Padding = UDim.new()
	uiList.FillDirection = Enum.FillDirection.Vertical
	uiList.SortOrder = Enum.SortOrder.LayoutOrder

	section.objects.elements = elements

	return section
end

function Section:AddToggle(properties: {[string]: any}?): ()
	local name = properties.Name
	local callback = properties.Callback

	local button = Instance.new("ImageButton")
	button.Parent = self.objects.elements
	button.AutomaticSize = Enum.AutomaticSize.Y
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Size = UDim2.new(1, 0, 0, 0)
	button.Image = ""
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = button
	uiPadding.PaddingLeft = UDim.new(0, 10)
	uiPadding.PaddingRight = UDim.new(0, 10)
	uiPadding.PaddingTop = UDim.new(0, 4)
	uiPadding.PaddingBottom = UDim.new(0, 4)

	local text = Instance.new("TextLabel")
	text.Parent = button
	text.AnchorPoint = Vector2.new(1, 0)
	text.AutomaticSize = Enum.AutomaticSize.Y
	text.BackgroundTransparency = 1
	text.Position = UDim2.new(1, 0, 0, 0)
	text.Size = UDim2.new(1, -24, 0, 0)
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.Text
	text.TextSize = 14
	text.TextTruncate = Enum.TextTruncate.SplitWord
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.RichText = true

	local switch = Instance.new("Frame")
	switch.Parent = button
	switch.AnchorPoint = Vector2.new(0, 0.5)
	switch.BackgroundTransparency = 1
	switch.Position = UDim2.new(0, 0, 0.5, 0)
	switch.Size = UDim2.fromOffset(14, 14)

	local switchBg = Instance.new("Frame")
	switchBg.Parent = switch
	switchBg.BackgroundColor3 = Theme.ElementBackground
	switchBg.BorderColor3 = Theme.ElementBorderOuter
	switchBg.BorderMode = Enum.BorderMode.Inset
	switchBg.BorderSizePixel = 1
	switchBg.Size = UDim2.fromScale(1, 1)

	local innerBorder = AddBorderFrame(switch, Theme.ElementBorderInner, 1, -2)

	local coreHolder = Instance.new("Frame")
	coreHolder.Parent = switchBg
	coreHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	coreHolder.BackgroundTransparency = 1
	coreHolder.Position = UDim2.fromScale(0.5, 0.5)
	coreHolder.Size = UDim2.new(1, -4, 1, -4)

	local core = Instance.new("Frame")
	core.Parent = coreHolder
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.BackgroundColor3 = Theme.Accent
	core.BorderSizePixel = 0
	core.Position = UDim2.fromScale(0.5, 0.5)
	core.Size = UDim2.fromScale(1, 1)

	AddGradientFrame(core, Color3.fromRGB(0, 0, 0), {0.6, 1}, -90)

	do
		local _value = properties.Value or false
		local _tween = nil

		local function updateVisual(instant: boolean?)
			if _tween then
				_tween:Cancel()
				_tween = nil
			end

			if instant then
				core.Size = _value and UDim2.fromScale(1, 1) or UDim2.new()
			else
				local info = TweenInfo.new(0.1, Enum.EasingStyle.Sine)
				local scale = _value and UDim2.fromScale(1, 1) or UDim2.new()
				_tween = TweenService:Create(core, info, {Size = scale})
				_tween:Play()
			end
		end
		
		local function onActivated()
			_value = not _value
			updateVisual()
			if callback then
				task.spawn(callback, _value)
			end
		end

		AddConnection(button.Activated, onActivated)

		updateVisual(true)
	end

	do -- ホールド時のアニメーション
		local _tween = nil
		local _hover = false
		local _hold = false

		local function updateAnim(hold: boolean)
			if _tween then
				_tween:Cancel()
				_tween = nil
			end

			local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
			_tween = TweenService:Create(innerBorder, info, {
				Color = hold and Theme.Accent or Theme.ElementBorderInner
			})
			_tween:Play()
		end
		
		local function onInputBegan(input: InputObject)
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
		end
		
		local function onInputEnded(input: InputObject)
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
		end

		AddConnection(button.InputBegan, onInputBegan)
		AddConnection(button.InputEnded, onInputEnded)
	end
end

function Section:AddSlider(properties: {[string]: any}?): ()
	local name = properties.Name
	local min = properties.Min or 0
	local max = properties.Max or 10
	local decimal = properties.Decimal or 0
	local defaultValue = properties.Value or min
	local callback = properties.Callback

	assert(min < max, "最大値は最小値より大きい必要があります。")

	local frame = Instance.new("Frame")
	frame.Parent = self.objects.elements
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 0)
	
	local uiList = Instance.new("UIListLayout")
	uiList.Parent = frame
	uiList.FillDirection = Enum.FillDirection.Vertical
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	uiList.Padding = UDim.new(0, 4)
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = frame
	uiPadding.PaddingLeft = UDim.new(0, 10)
	uiPadding.PaddingRight = UDim.new(0, 10)
	uiPadding.PaddingTop = UDim.new(0, 4)
	uiPadding.PaddingBottom = UDim.new(0, 4)

	local text = Instance.new("TextLabel")
	text.Parent = frame
	text.AutomaticSize = Enum.AutomaticSize.Y
	text.BackgroundTransparency = 1
	text.Position = UDim2.new()
	text.Size = UDim2.fromScale(1, 0)
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.Text
	text.TextSize = 14
	text.TextTruncate = Enum.TextTruncate.SplitWord
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.RichText = true

	local slider = Instance.new("ImageButton")
	slider.Parent = frame
	slider.AutoButtonColor = false
	slider.AnchorPoint = Vector2.new(0.5, 1)
	slider.BackgroundColor3 = Theme.ElementBorderOuter
	slider.BorderSizePixel = 0
	slider.Position = UDim2.fromScale(0.5, 0)
	slider.Size = UDim2.new(1, 0, 0, 20)
	slider.Image = ""

	local sliderBg = Instance.new("Frame")
	sliderBg.Parent = slider
	sliderBg.BackgroundColor3 = Theme.ElementBackground
	sliderBg.BorderColor3 = Theme.ElementBorderOuter
	sliderBg.BorderMode = Enum.BorderMode.Inset
	sliderBg.BorderSizePixel = 1
	sliderBg.AnchorPoint = Vector2.new(0.5, 0.5)
	sliderBg.Position = UDim2.fromScale(0.5, 0.5)
	sliderBg.Size = UDim2.fromScale(1, 1)

	local innerBorder = AddBorderFrame(slider, Theme.ElementBorderInner, 1, -2)

	local progressHolder = Instance.new("Frame")
	progressHolder.Parent = slider
	progressHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	progressHolder.BackgroundTransparency = 1
	progressHolder.Position = UDim2.fromScale(0.5, 0.5)
	progressHolder.Size = UDim2.new(1, -6, 1, -6)

	local progress = Instance.new("Frame")
	progress.Parent = progressHolder
	progress.BackgroundColor3 = Theme.Accent
	progress.BorderSizePixel = 0
	progress.Position = UDim2.new()
	progress.Size = UDim2.new(1, 0, 1, 0)

	AddGradientFrame(progress, Color3.fromRGB(0, 0, 0), {0.6, 1}, -90)

	do
		local range = max - min
		local decimalScale = 10 ^ decimal

		local _input = nil
		local _tween = nil
		local _value = defaultValue

		local function updateVisual(instant: boolean?)
			local ratio = math.clamp((_value - min) / range, 0, 1)

			text.Text = name:format(_value)

			if instant then
				progress.Size = UDim2.new(ratio, 0, 1, 0)
			else
				if _tween then
					_tween:Cancel()
					_tween = nil
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
			if callback then
				task.spawn(callback, _value)
			end
		end
		
		local function onInputBegan(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				_input = input
				handleInput(input)
			end
		end
		
		local function onInputEnded(input: InputObject)
			if (input == _input) and (input.UserInputState == Enum.UserInputState.End) then
				_input = nil
			end
		end
		
		local function onInputChanged(input: InputObject, gameProcessedEvent: boolean)
			if _input and (input.UserInputType == Enum.UserInputType.MouseMovement) then
				handleInput(input)
			end
		end

		AddConnection(slider.InputBegan, onInputBegan)
		AddConnection(slider.InputEnded, onInputEnded)
		AddConnection(UserInputService.InputChanged, onInputChanged)

		updateVisual(true)
	end

	do -- ホールド時のアニメーション
		local _tween = nil
		local _hover = false
		local _hold = false

		local function updateAnim(hold: boolean)
			if _tween then
				_tween:Cancel()
				_tween = nil
			end

			local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
			_tween = TweenService:Create(innerBorder, info, {
				Color = hold and Theme.Accent or Theme.ElementBorderInner
			})
			_tween:Play()
		end

		local function onInputBegan(input: InputObject)
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
		end
		
		local function onInputEnded(input: InputObject)
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
		end
		
		AddConnection(slider.InputBegan, onInputBegan)
		AddConnection(slider.InputEnded, onInputEnded)
	end
end

function Section:AddColor(properties: {[string]: any}?): ()
	local name = properties.Name
	local defaultValue = properties.Value or Color3.fromRGB(255, 255, 255)
	local callback = properties.Callback

	local button = Instance.new("ImageButton")
	button.Parent = self.objects.elements
	button.AutomaticSize = Enum.AutomaticSize.Y
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Size = UDim2.new(1, 0, 0, 0)
	button.Image = ""
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = button
	uiPadding.PaddingLeft = UDim.new(0, 10)
	uiPadding.PaddingRight = UDim.new(0, 10)
	uiPadding.PaddingTop = UDim.new(0, 4)
	uiPadding.PaddingBottom = UDim.new(0, 4)

	local panelRoot = Instance.new("Frame")
	panelRoot.Parent = button
	panelRoot.AnchorPoint = Vector2.new(1, 0.5)
	panelRoot.BackgroundTransparency = 1
	panelRoot.Position = UDim2.fromScale(1, 0.5)
	panelRoot.Size = UDim2.fromOffset(24, 16)

	local panelBg = Instance.new("Frame")
	panelBg.Parent = panelRoot
	panelBg.BackgroundColor3 = Theme.ElementBackground
	panelBg.BorderColor3 = Theme.ElementBorderOuter
	panelBg.BorderMode = Enum.BorderMode.Inset
	panelBg.BorderSizePixel = 1
	panelBg.Size = UDim2.fromScale(1, 1)

	local innerBorder = AddBorderFrame(panelRoot, Theme.ElementBorderInner, 1, -2)

	local panel = Instance.new("Frame")
	panel.Parent = panelRoot
	panel.BackgroundColor3 = defaultValue
	panel.BorderSizePixel = 0
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -6, 1, -6)

	AddGradientFrame(panel, Color3.fromRGB(0, 0, 0), {0.6, 1}, -90)

	local text = Instance.new("TextLabel")
	text.Parent = button
	text.AutomaticSize = Enum.AutomaticSize.Y
	text.AnchorPoint = Vector2.new(0, 0)
	text.BackgroundTransparency = 1
	text.Position = UDim2.new()
	text.Size = UDim2.new(1, -46, 0, 0)
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.Text
	text.TextSize = 14
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextTruncate = Enum.TextTruncate.SplitWord
	text.RichText = true

	do
		local _value = defaultValue

		local function updateVisual()
			panel.BackgroundColor3 = _value
		end

		local onValueChanged = function(color)
			_value = color

			updateVisual()

			if callback then
				task.spawn(callback, _value)
			end
		end
		
		local function onActivated()
			local windowInfo = self.tab.window
			local colorPickerInfo = windowInfo.colorPicker

			local windowRoot = windowInfo.objects.root
			local pickerRoot = colorPickerInfo.objects.root

			if colorPickerInfo.functions.onValueChanged == onValueChanged then
				colorPickerInfo.functions.onValueChanged = nil
				pickerRoot.Visible = false
			else
				colorPickerInfo.functions.onValueChanged = onValueChanged
				colorPickerInfo.setColor(_value)
				local rel = button.AbsolutePosition - windowRoot.AbsolutePosition + Vector2.new(button.AbsoluteSize.X / 2, button.AbsoluteSize.Y)

				pickerRoot.Parent = windowRoot
				pickerRoot.Visible = true
				pickerRoot.Position = UDim2.fromOffset(rel.X, rel.Y)
			end
		end
		
		AddConnection(button.Activated, onActivated)
	end

	do -- ホールド時のアニメーション
		local _tween = nil
		local _hover = false
		local _hold = false

		local function updateAnim(hold: boolean)
			if _tween then
				_tween:Cancel()
				_tween = nil
			end

			local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
			_tween = TweenService:Create(innerBorder, info, {
				Color = hold and Theme.Accent or Theme.ElementBorderInner
			})
			_tween:Play()
		end
		
		local function onInputBegan(input: InputObject)
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
		end
		
		local function onInputEnded(input: InputObject)
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
		end

		AddConnection(button.InputBegan, onInputBegan)
		AddConnection(button.InputEnded, onInputEnded)
	end
end

function Section:AddButton(properties: {[string]: any}): ()
	local name = properties.Name
	local callback = properties.Callback

	local frame = Instance.new("Frame")
	frame.Parent = self.objects.elements
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 0)
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = frame
	uiPadding.PaddingLeft = UDim.new(0, 10)
	uiPadding.PaddingRight = UDim.new(0, 10)
	uiPadding.PaddingTop = UDim.new(0, 4)
	uiPadding.PaddingBottom = UDim.new(0, 4)

	local button = Instance.new("ImageButton")
	button.Parent = frame
	button.AutomaticSize = Enum.AutomaticSize.Y
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Position = UDim2.new()
	button.Size = UDim2.new(1, 0, 0, 0)
	button.Image = ""

	local buttonBg = Instance.new("Frame")
	buttonBg.Parent = button
	buttonBg.BackgroundColor3 = Theme.ButtonBackground
	buttonBg.BorderColor3 = Theme.ElementBorderOuter
	buttonBg.BorderMode = Enum.BorderMode.Inset
	buttonBg.BorderSizePixel = 1
	buttonBg.Size = UDim2.fromScale(1, 1)

	local innerBorder = AddBorderFrame(button, Theme.ElementBorderInner, 1, -2)

	AddGradientFrame(button, Color3.fromRGB(0, 0, 0), {0.6, 1}, -90, -2)

	local text = Instance.new("TextLabel")
	text.Parent = button
	text.AutomaticSize = Enum.AutomaticSize.Y
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 0)
	text.Font = Enum.Font.Code
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.ButtonText
	text.TextSize = 14
	text.TextXAlignment = Enum.TextXAlignment.Center
	text.TextTruncate = Enum.TextTruncate.SplitWord
	text.RichText = true
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = text
	uiPadding.PaddingLeft = UDim.new(0, 4)
	uiPadding.PaddingRight = UDim.new(0, 4)
	uiPadding.PaddingTop = UDim.new(0, 6)
	uiPadding.PaddingBottom = UDim.new(0, 6)

	do
		local function onActivated()
			if callback then
				task.spawn(callback)
			end
		end
		
		AddConnection(button.Activated, onActivated)
	end

	do -- ホールド時のアニメーション
		local _tween = nil
		local _hover = false
		local _hold = false
		
		local function updateAnim(hold: boolean)
			if _tween then
				_tween:Cancel()
				_tween = nil
			end

			local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
			_tween = TweenService:Create(innerBorder, info, {
				Color = hold and Theme.Accent or Theme.ElementBorderInner
			})
			_tween:Play()
		end
		
		local function onInputBegan(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				_hover = true
				if not _hold then
					updateAnim(true)
				end
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputState == Enum.UserInputState.Begin then
				_hold = true
				updateAnim(false)
			end
		end
		
		local function onInputEnded(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				_hover = false
				updateAnim(false)
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputState == Enum.UserInputState.End then
				_hold = false
				if _hover then
					updateAnim(true)
				end
			end
		end
		
		AddConnection(button.InputBegan, onInputBegan)
		AddConnection(button.InputEnded, onInputEnded)
	end
end

function Section:AddKeybind(properties: {[string]: any}): ()
	local name = properties.Name
	local callback = properties.Callback
	local defaultValue = properties.Value

	local frame = Instance.new("Frame")
	frame.Parent = self.objects.elements
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 0)
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = frame
	uiPadding.PaddingLeft = UDim.new(0, 10)
	uiPadding.PaddingRight = UDim.new(0, 10)
	uiPadding.PaddingTop = UDim.new(0, 4)
	uiPadding.PaddingBottom = UDim.new(0, 4)
	
	local uiList = Instance.new("UIListLayout")
	uiList.Parent = frame
	uiList.FillDirection = Enum.FillDirection.Vertical
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	uiList.Padding = UDim.new(0, 4)

	local text = Instance.new("TextLabel")
	text.Parent = frame
	text.AutomaticSize = Enum.AutomaticSize.Y
	text.AnchorPoint = Vector2.new(1, 0)
	text.BackgroundTransparency = 1
	text.Position = UDim2.new()
	text.Size = UDim2.fromScale(1, 0)
	text.Font = Enum.Font.Code
	text.Text = name
	text.TextColor3 = Theme.Text
	text.TextSize = 14
	text.TextTruncate = Enum.TextTruncate.SplitWord
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.RichText = true

	local button = Instance.new("ImageButton")
	button.Parent = frame
	button.AutomaticSize = Enum.AutomaticSize.Y
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Position = UDim2.new()
	button.Size = UDim2.new(1, 0, 0, 0)
	button.Image = ""

	local buttonBg = Instance.new("Frame")
	buttonBg.Parent = button
	buttonBg.BackgroundColor3 = Theme.ButtonBackground
	buttonBg.BorderColor3 = Theme.ElementBorderOuter
	buttonBg.BorderMode = Enum.BorderMode.Inset
	buttonBg.BorderSizePixel = 1
	buttonBg.Size = UDim2.fromScale(1, 1)

	local innerBorder = AddBorderFrame(button, Theme.ElementBorderInner, 1, -2)

	AddGradientFrame(button, Color3.fromRGB(0, 0, 0), {0.6, 1}, -90, -2)

	local buttonText = Instance.new("TextLabel")
	buttonText.Parent = button
	buttonText.AutomaticSize = Enum.AutomaticSize.Y
	buttonText.BackgroundTransparency = 1
	buttonText.Size = UDim2.fromScale(1, 0)
	buttonText.Font = Enum.Font.Code
	buttonText.Font = Enum.Font.Code
	buttonText.Text = ""
	buttonText.TextColor3 = Theme.ButtonText
	buttonText.TextSize = 14
	buttonText.TextXAlignment = Enum.TextXAlignment.Center
	buttonText.TextTruncate = Enum.TextTruncate.SplitWord
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = buttonText
	uiPadding.PaddingLeft = UDim.new(0, 4)
	uiPadding.PaddingRight = UDim.new(0, 4)
	uiPadding.PaddingTop = UDim.new(0, 6)
	uiPadding.PaddingBottom = UDim.new(0, 6)

	do -- 実装
		local _value = defaultValue
		local _waitForInput = false

		local function updateVisual()
			buttonText.Text = _value and _value.Name or "---"
		end
		
		local function onActivated()
			_waitForInput = true
			buttonText.Text = "..."

			if callback then
				task.spawn(callback, nil)
			end
		end
		
		local function onInputBegan(input: InputObject)
			if _waitForInput then
				_waitForInput = false

				if input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.Backspace then
						_value = nil
					else
						_value = input.KeyCode
					end
				end

				updateVisual()

				if callback then
					task.spawn(callback, _value)
				end
			end
		end

		AddConnection(button.Activated, onActivated)
		AddConnection(UserInputService.InputBegan, onInputBegan)

		updateVisual()
	end

	do -- マウスオーバー時のアニメーション
		local _tween = nil
		local _hover = false
		local _hold = false

		local function updateAnim(hold: boolean)
			if _tween then
				_tween:Cancel()
				_tween = nil
			end

			local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
			_tween = TweenService:Create(innerBorder, info, {
				Color = hold and Theme.Accent or Theme.ElementBorderInner
			})
			_tween:Play()
		end
		
		local function onInputBegan(input: InputObject)
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
		end
		
		local function onInputEnded(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				_hover = false
				updateAnim(false)
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputState == Enum.UserInputState.End then
				_hold = false
				if _hover then
					updateAnim(true)
				end
			end
		end

		AddConnection(button.InputBegan, onInputBegan)
		AddConnection(button.InputEnded, onInputEnded)
	end
end

function Section:AddTextLabel(properties: {[string]: any}): ()
	local text = properties.Text
	local alignment = properties.Alignment or Enum.TextXAlignment.Left
	local wrapped = properties.Wrapped or false
	
	local frame = Instance.new("Frame")
	frame.Parent = self.objects.elements
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.new()
	frame.Size = UDim2.fromScale(1, 0)
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = frame
	uiPadding.PaddingLeft = UDim.new(0, 10)
	uiPadding.PaddingRight = UDim.new(0, 10)
	uiPadding.PaddingTop = UDim.new(0, 4)
	uiPadding.PaddingBottom = UDim.new(0, 4)
	
	local label = Instance.new("TextLabel")
	label.Parent = frame
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.Position = UDim2.new()
	label.Size = UDim2.fromScale(1, 0)
	label.Font = Enum.Font.Code
	label.Text = text
	label.TextColor3 = Theme.Text
	label.TextSize = 14
	label.TextTruncate = Enum.TextTruncate.SplitWord
	label.TextXAlignment = alignment
	label.TextWrapped = wrapped
	label.RichText = true
end

return UILibrary
