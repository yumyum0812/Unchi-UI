-- Universal Cheat Collections for Roblox

-- ※ このスクリプトを実際のゲームプレイで使用しないでください。これは学習目的や、アンチチートのテストのみに使用されます。
-- ※ Synapse XのAPIが必要です。
-- ※ コンピュータ以外での動作は保証されていません。

-----------------------------------------------'

-- 設定
local Settings = {
    ToggleWindowKey = Enum.KeyCode.RightControl,
    Esp = {
        Enabled = true,
        AliveCheck = true,
        TeamCheck = true,

        Tracer = {
            Enabled = true,
            Color = Color3.fromRGB(255, 255, 255),
            UseTeamColor = true,
            Opacity = 0.5,
            Thickness = 1,
        },
        Skeleton = {
            Enabled = true,
            Color = Color3.fromRGB(255, 255, 255),
            UseTeamColor = true,
            Opacity = 0.5,
            Thickness = 1,
        },
    },
    Aimbot = {
        Enabled = true,
        TriggerKey = Enum.KeyCode.F,
        Toggle = true,
        AliveCheck = true,
        TeamCheck = true,

        LimitDistance = {
            Enabled = true,
            Amount = 500,
        },
        Fov = {
            Enabled = true,
            Visible = true,
            Amount = 200,
            Color = Color3.fromRGB(255, 255, 255),
            LockedColor = Color3.fromRGB(255, 0, 0),
            Opacity = 0.5,
            Thickness = 1,
        },
        WallCheck = {
            Enabled = true,
            CheckCanQuery = true,
            CheckCanCollide = false,
        }
    }
}

-- 定数

local BoneSets = {
    R6 = {
        {"Head", "Torso"},
        {"Torso", "Left Arm"},
        {"Torso", "Right Arm"},
        {"Torso", "Left Leg"},
        {"Torso", "Right Leg"},
    },
    R15 = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"UpperTorso", "RightUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LowerTorso", "RightUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"RightLowerLeg", "RightFoot"},
    },
}

-- 事前チェック
if not Drawing then
    warn("[UCC]", "Drawing APIが見つかりません。")
    return
end
if getgenv().UCCLoaded then
    warn("[UCC]", "既に読み込まれています。")
    return
else
    getgenv().UCCLoaded = true
end

-- サービス
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local UnchiUI = loadstring(game:HttpGet("https://github.com/yumyum0812/Unchi-UI/raw/refs/heads/main/unchi.luau"))()

-- 動的変数
local _connections = {} :: {RBXScriptConnection}
local _drawingInfos = {} :: {[string]: {Object: any, Using: boolean}}
local _aimbotActive = false
local _lockedPlayer = nil
local _window = nil

-- 関数
local function AddConnection(signal: RBXScriptSignal, callback: (any...) -> ()): ()
	local connection = signal:Connect(callback)
	table.insert(_connections, connection)
end

local function ClearConnections(): ()
	for _, connection in _connections do
		connection:Disconnect()
	end
	_connections = {}
end

local function GetDrawing(drawingType: string, identifier: string): ()
    local cache = _drawingInfos[identifier]
    if cache then
        cache.Using = true
        return cache.Object
    end

    local info = {}
    info.Object = Drawing.new(drawingType)
    info.Using = true

    _drawingInfos[identifier] = info

    return info.Object
end

local function PurgeDrawings(): ()
    for identifier, info in _drawingInfos do
        if not info.Using then
            info.Object:Remove()
            _drawingInfos[identifier] = nil
        else
            info.Using = false
        end
    end
end

local function ClearDrawings(): ()
    for identifier, info in _drawingInfos do
        info.Object:Remove()
        _drawingInfos[identifier] = nil
    end
end

local function GetFootPosition(hrp: BasePart, humanoid: Humanoid): Vector3
    if humanoid.RigType == Enum.HumanoidRigType.R6 then
        return hrp.CFrame * -Vector3.new(0, (hrp.Size.Y / 2) + 2, 0)
    end
    
    return hrp.CFrame * -Vector3.new(0, (hrp.Size.Y / 2) + humanoid.HipHeight, 0)
end

local function UpdateEsp(deltaTime: number): ()
    if not Settings.Esp.Enabled then
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    for _, player in Players:GetPlayers() do
        if player == Players.LocalPlayer then
            continue
        end

        if Settings.Esp.TeamCheck and player.Team and (player.Team == Players.LocalPlayer.Team) then
            continue
        end

        local character = player.Character
        if not character then
            continue
        end

        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then
            continue
        end

        if Settings.Esp.AliveCheck and (humanoid.Health <= 0) then
            continue
        end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if (not hrp) or (not hrp:IsA("BasePart")) then
            continue
        end

        local worldPos = GetFootPosition(hrp, humanoid)
        local viewportPos, onScreen = camera:WorldToViewportPoint(worldPos)
        if viewportPos.Z < 0 then
            continue
        end

        if Settings.Esp.Tracer.Enabled then
            local drawing = GetDrawing("Line", "Tracer" .. player.UserId)
            drawing.Visible = true
            drawing.Color = Settings.Esp.Tracer.UseTeamColor and player.TeamColor.Color or Settings.Esp.Tracer.Color
            drawing.Transparency = Settings.Esp.Tracer.Opacity
            drawing.Thickness = Settings.Esp.Tracer.Thickness
            drawing.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            drawing.To = Vector2.new(viewportPos.X, viewportPos.Y)
        end

        if Settings.Esp.Skeleton.Enabled then
            local boneSets = BoneSets[humanoid.RigType.Name]
            if not boneSets then
                continue
            end

            for i, bone in boneSets do
                local part1 = character:FindFirstChild(bone[1])
                if (not part1) or (not part1:IsA("BasePart")) then
                    continue
                end

                local part2 = character:FindFirstChild(bone[2])
                if (not part2) or (not part2:IsA("BasePart")) then
                    continue
                end

                local viewportPos1, onScreen1 = camera:WorldToViewportPoint(part1.Position)
                local viewportPos2, onScreen2 = camera:WorldToViewportPoint(part2.Position)
                if (not onScreen1) and (not onScreen2) then
                    continue
                end

                local drawing = GetDrawing("Line", "Bone" .. player.UserId .. "_" .. i)
                drawing.Visible = true
                drawing.Color = Settings.Esp.Skeleton.UseTeamColor and player.TeamColor.Color or Settings.Esp.Skeleton.Color
                drawing.Transparency = Settings.Esp.Skeleton.Opacity
                drawing.Thickness = Settings.Esp.Skeleton.Thickness
                drawing.From = Vector2.new(viewportPos1.X, viewportPos1.Y)
                drawing.To = Vector2.new(viewportPos2.X, viewportPos2.Y)
            end
        end
    end
end

local function GetCharacters(): {Instance}
	local characters = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			table.insert(characters, character)
		end
	end
	return characters
end

local function GetAimbotTargetPart(camera: Camera, player: Player): BasePart?
	if player == Players.LocalPlayer then
		return nil
	end

	if Settings.Aimbot.TeamCheck and player.Team and (player.Team == Players.LocalPlayer.Team) then
        return nil
    end

	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return nil
	end

	if Settings.Aimbot.AliveCheck and (humanoid.Health <= 0) then
		return nil
	end

	local head = character:FindFirstChild("Head") :: BasePart
	if not head or not head:IsA("BasePart") then
		return nil
	end

	if Settings.Aimbot.LimitDistance.Enabled then
		local distance = (camera.CFrame.Position - head.CFrame.Position).Magnitude
		if distance > Settings.Aimbot.LimitDistance.Amount then
			return nil
		end
	end

	if Settings.Aimbot.Fov.Enabled then
		local viewportPos = camera:WorldToViewportPoint(head.CFrame.Position) :: Vector3
		if viewportPos.Z < 0 then
			return nil
		end

		local viewportCenter = camera.ViewportSize / 2
		local viewportDistance = (Vector2.new(viewportPos.X, viewportPos.Y) - viewportCenter).Magnitude
		if viewportDistance > Settings.Aimbot.Fov.Amount then
			return nil
		end
	end

	if Settings.Aimbot.WallCheck.Enabled then
		local characters = GetCharacters()
		local parts = camera:GetPartsObscuringTarget({head.CFrame.Position}, characters)

		for _, part in parts do
			if Settings.Aimbot.WallCheck.CheckCanQuery and (not part.CanQuery) then
				continue
			end

			if Settings.Aimbot.WallCheck.CheckCanCollide and (not part.CanCollide) then
				continue
			end

			return nil
		end
	end

	return head
end

local function UpdateAimbot(deltaTime: number): ()
	if not _aimbotActive then
		_lockedPlayer = nil
	end

	if _lockedPlayer and (not _lockedPlayer.Parent) then
		_lockedPlayer = nil
	end

    if not Settings.Aimbot.Enabled then
        _aimbotActive = false
        _lockedPlayer = nil
        return
    end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local targetLocked = false

	if _aimbotActive then
        local closestPart = nil

		if _lockedPlayer then
			local part = GetAimbotTargetPart(camera, _lockedPlayer)
			if part then
				closestPart = part
			else
				_lockedPlayer = nil
			end
		end

		if not closestPart then
			local closestDistance = math.huge
			local closestViewportDistance = math.huge

			for _, player in Players:GetPlayers() do
				local part = GetAimbotTargetPart(camera, player)
				if not part then
					continue
				end

				if Settings.Aimbot.Fov.Enabled then
					local viewportPos = camera:WorldToViewportPoint(part.CFrame.Position) :: Vector3
					local viewportCenter = camera.ViewportSize / 2
					local viewportDistance = (Vector2.new(viewportPos.X, viewportPos.Y) - viewportCenter).Magnitude
					if viewportDistance < closestViewportDistance then
						closestPart = part
						closestViewportDistance = viewportDistance
						_lockedPlayer = player
					end
				else
					local distance = (camera.CFrame.Position - part.CFrame.Position).Magnitude
					if distance < closestDistance then
						closestPart = part
						closestDistance = distance
						_lockedPlayer = player
					end
				end
			end
		end

		if closestPart then
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, closestPart.CFrame.Position)
            targetLocked = true
		end
	end

    if Settings.Aimbot.Fov.Enabled and Settings.Aimbot.Fov.Visible then
        local circle = GetDrawing("Circle", "AimbotFovCircle")
        circle.Visible = true
        circle.Color = targetLocked and Settings.Aimbot.Fov.LockedColor or Settings.Aimbot.Fov.Color
        circle.Transparency = Settings.Aimbot.Fov.Opacity
        circle.Thickness = Settings.Aimbot.Fov.Thickness
        circle.Radius = Settings.Aimbot.Fov.Amount
        circle.Position = camera.ViewportSize / 2
    end
end

local function OnPreRender(deltaTime: number): ()
    PurgeDrawings()
    UpdateAimbot(deltaTime)
    UpdateEsp(deltaTime)
end

local function OnUserInput(input: InputObject, gameProcessedEvent: boolean): ()
    if gameProcessedEvent then
        return
    end

    if input.KeyCode == Settings.Aimbot.TriggerKey then
		if not Settings.Aimbot.Toggle then
			_aimbotActive = (input.UserInputState ~= Enum.UserInputState.End)
		else
			if input.UserInputState == Enum.UserInputState.Begin then
				_aimbotActive = not _aimbotActive
			end
		end
	end

    if input.UserInputState == Enum.UserInputState.Begin then
        if input.KeyCode == Settings.ToggleWindowKey then
            if _window then
                _window:SetVisible(not _window:IsVisible())
            end
        end
    end
end

local function CreateWindow()
    local window = UnchiUI:CreateWindow({
        Name = "Universal Cheat Collections",
    })

    do
        local tab = window:CreateTab({
            Name = "Aimbot"
        })
        do
            local section = tab:CreateSection({
                Name = "全体設定"
            })
            section:AddToggle({
                Name = "有効化",
                Value = Settings.Aimbot.Enabled,
                Callback = function(value: boolean): ()
                    Settings.Aimbot.Enabled = value
                end
            })
        end
        do
            local section = tab:CreateSection({
                Name = "操作"
            })
            section:AddKeybind({
                Name = "切り替えキー",
                Value = Settings.Aimbot.TriggerKey,
                Callback = function(value: Enum.KeyCode): ()
                    task.wait()
                    Settings.Aimbot.TriggerKey = value
                end
            })
            section:AddToggle({
                Name = "トグル切り替え",
                Value = Settings.Aimbot.Toggle,
                Callback = function(value: boolean): ()
                    Settings.Aimbot.Toggle = value
                end
            })
        end
        do
            local section = tab:CreateSection({
                Name = "ターゲット候補"
            })
            section:AddToggle({
                Name = "死者を除外",
                Value = Settings.Aimbot.AliveCheck,
                Callback = function(value: boolean): ()
                    Settings.Aimbot.AliveCheck = value
                end
            })
            section:AddToggle({
                Name = "同チームを除外",
                Value = Settings.Aimbot.TeamCheck,
                Callback = function(value: boolean): ()
                    Settings.Aimbot.TeamCheck = value
                end
            })
        end
        do
            local section = tab:CreateSection({
                Name = "壁チェック"
            })
            section:AddToggle({
                Name = "有効化",
                Value = Settings.Aimbot.WallCheck.Enabled,
                Callback = function(value: boolean): ()
                    Settings.Aimbot.WallCheck.Enabled = value
                end
            })
            section:AddToggle({
                Name = "クエリ可能のみ",
                Value = Settings.Aimbot.WallCheck.CheckCanQuery,
                Callback = function(value: boolean): ()
                    Settings.Aimbot.WallCheck.CheckCanQuery = value
                end
            })
            section:AddToggle({
                Name = "衝突可能のみ",
                Value = Settings.Aimbot.WallCheck.CheckCanCollide,
                Callback = function(value: boolean): ()
                    Settings.Aimbot.WallCheck.CheckCanCollide = value
                end
            })
        end
        do
            local section = tab:CreateSection({
                Name = "距離を制限"
            })
            section:AddToggle({
                Name = "有効化",
                Value = Settings.Aimbot.LimitDistance.Enabled,
                Callback = function(value: boolean): ()
                    Settings.Aimbot.LimitDistance.Enabled = value
                end
            })
            section:AddSlider({
                Name = "距離: %d",
                Min = 1,
                Max = 1000,
                Value = Settings.Aimbot.LimitDistance.Amount,
                Callback = function(value: number): ()
                    Settings.Aimbot.LimitDistance.Amount = value
                end,
            })
        end
        do
            local section = tab:CreateSection({
                Name = "範囲の指定",
                RightSide = true
            })
            section:AddToggle({
                Name = "有効化",
                Value = Settings.Aimbot.Fov.Enabled,
                Callback = function(value: boolean): ()
                    Settings.Aimbot.Fov.Enabled = value
                end
            })
            section:AddSlider({
                Name = "範囲: %d",
                Textbox = true,
                Min = 1,
                Max = 500,
                Value = Settings.Aimbot.Fov.Amount,
                Callback = function(value: number): ()
                    Settings.Aimbot.Fov.Amount = value
                end
            })
        end
        do
            local section = tab:CreateSection({
                Name = "範囲円の外観",
                RightSide = true
            })
            section:AddToggle({
                Name = "表示",
                Value = Settings.Aimbot.Fov.Visible,
                Callback = function(value: boolean): ()
                    Settings.Aimbot.Fov.Visible = value
                end
            })
            section:AddColor({
                Name = "色",
                Value = Settings.Aimbot.Fov.Color,
                Callback = function(value: Color3): ()
                    Settings.Aimbot.Fov.Color = value
                end
            })
            section:AddColor({
                Name = "ロック中の色",
                Value = Settings.Aimbot.Fov.LockedColor,
                Callback = function(value: Color3): ()
                    Settings.Aimbot.Fov.LockedColor = value
                end
            })
            section:AddSlider({
                Name = "不透明度: %.1f",
                Min = 0,
                Max = 1,
                Decimal = 1,
                Value = Settings.Aimbot.Fov.Opacity,
                Callback = function(value: number): ()
                    Settings.Aimbot.Fov.Opacity = value
                end
            })
            section:AddSlider({
                Name = "太さ: %d",
                Min = 1,
                Max = 4,
                Value = Settings.Aimbot.Fov.Thickness,
                Callback = function(value: number): ()
                    Settings.Aimbot.Fov.Thickness = value
                end
            })
        end
    end

    do
        local tab = window:CreateTab({
            Name = "ESP"
        })
        do
            local section = tab:CreateSection({
                Name = "全体設定"
            })
            section:AddToggle({
                Name = "有効化",
                Value = Settings.Esp.Enabled,
                Callback = function(value: boolean): ()
                    Settings.Esp.Enabled = value
                end
            })
        end
        do
            local section = tab:CreateSection({
                Name = "ターゲット候補",
            })
            section:AddToggle({
                Name = "死者を除外",
                Value = Settings.Esp.AliveCheck,
                Callback = function(value: boolean): ()
                    Settings.Esp.AliveCheck = value
                end
            })
            section:AddToggle({
                Name = "同チームを除外",
                Value = Settings.Esp.TeamCheck,
                Callback = function(value: boolean): ()
                    Settings.Esp.TeamCheck = value
                end
            })
        end
        do
            local section = tab:CreateSection({
                Name = "トレーサー",
                RightSide = true
            })
            section:AddToggle({
                Name = "有効化",
                Value = Settings.Esp.Tracer.Enabled,
                Callback = function(value: boolean): ()
                    Settings.Esp.Tracer.Enabled = value
                end
            })
            section:AddColor({
                Name = "色",
                Value = Settings.Esp.Tracer.Color,
                Callback = function(value: Color3): ()
                    Settings.Esp.Tracer.Color = value
                end
            })
            section:AddToggle({
                Name = "チームカラーを使用",
                Value = Settings.Esp.Tracer.UseTeamColor,
                Callback = function(value: boolean): ()
                    Settings.Esp.Tracer.UseTeamColor = value
                end
            })
            section:AddSlider({
                Name = "不透明度: %.1f",
                Min = 0,
                Max = 1,
                Decimal = 1,
                Value = Settings.Esp.Tracer.Opacity,
                Callback = function(value: number): ()
                    Settings.Esp.Tracer.Opacity = value
                end
            })
            section:AddSlider({
                Name = "太さ: %d",
                Min = 1,
                Max = 4,
                Value = Settings.Esp.Tracer.Thickness,
                Callback = function(value: number): ()
                    Settings.Esp.Tracer.Thickness = value
                end
            })
        end
        do
            local section = tab:CreateSection({
                Name = "スケルトン",
                RightSide = true
            })
            section:AddToggle({
                Name = "有効化",
                Value = Settings.Esp.Skeleton.Enabled,
                Callback = function(value: boolean): ()
                    Settings.Esp.Skeleton.Enabled = value
                end
            })
            section:AddColor({
                Name = "色",
                Value = Settings.Esp.Skeleton.Color,
                Callback = function(value: Color3): ()
                    Settings.Esp.Skeleton.Color = value
                end
            })
            section:AddToggle({
                Name = "チームカラーを使用",
                Value = Settings.Esp.Skeleton.UseTeamColor,
                Callback = function(value: boolean): ()
                    Settings.Esp.Skeleton.UseTeamColor = value
                end
            })
            section:AddSlider({
                Name = "不透明度: %.1f",
                Min = 0,
                Max = 1,
                Decimal = 1,
                Value = Settings.Esp.Skeleton.Opacity,
                Callback = function(value: number): ()
                    Settings.Esp.Skeleton.Opacity = value
                end
            })
            section:AddSlider({
                Name = "太さ: %d",
                Min = 1,
                Max = 4,
                Value = Settings.Esp.Skeleton.Thickness,
                Callback = function(value: number): ()
                    Settings.Esp.Skeleton.Thickness = value
                end
            })
        end
    end

    do
        local tab = window:CreateTab({
            Name = "その他"
        })
        do
            local section = tab:CreateSection({
                Name = "スクリプトをロード",
            })

            section:AddButton({
                Name = "Infinite Yield",
                Callback = function(): ()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
                end
            })
        end
    end

    do
        local tab = window:CreateTab({
            Name = "設定"
        })
        do
            local section = tab:CreateSection({
                Name = "操作",
            })

            section:AddKeybind({
                Name = "メニューの切り替え",
                Value = Settings.ToggleWindowKey,
                Callback = function(value: Enum.KeyCode): ()
                    task.wait()
                    Settings.ToggleWindowKey = value
                end
            })
        end
        do
            local section = tab:CreateSection({
                Name = "管理",
                RightSide = true
            })
            
            section:AddButton({
                Name = "終了",
                Callback = function(): ()
                    Destroy()
                end
            })
        end
    end

    _window = window
end

---------------------------------------------------

function Start(): ()
    AddConnection(RunService.PreRender, OnPreRender)
    AddConnection(UserInputService.InputBegan, OnUserInput)
    AddConnection(UserInputService.InputEnded, OnUserInput)
    CreateWindow()

    print("[UCC]", "読み込まれました")
end

function Destroy(): ()
    getgenv().UCCLoaded = false

    ClearConnections()
    ClearDrawings()
    UnchiUI:Destroy()

    print("[UCC]", "終了しました")
end

-- 初期化
Start()
