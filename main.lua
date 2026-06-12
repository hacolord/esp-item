local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- 1. ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SmartRadarSystem"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 2. WIDGET RADAR (50x50)
local widgetFrame = Instance.new("Frame")
widgetFrame.Name = "RadarWidget"
widgetFrame.Size = UDim2.new(0, 50, 0, 50) 
widgetFrame.Position = UDim2.new(0.5, 120, 0.5, 35)
widgetFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
widgetFrame.BorderSizePixel = 0
widgetFrame.Active = true
widgetFrame.Parent = screenGui

local widgetCorner = Instance.new("UICorner")
widgetCorner.CornerRadius = UDim.new(0, 10)
widgetCorner.Parent = widgetFrame

local scanBtn = Instance.new("TextButton")
scanBtn.Name = "ScanBtn"
scanBtn.Size = UDim2.new(1, 0, 1, 0) 
scanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
scanBtn.Text = "SCAN\nITEM"
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Font = Enum.Font.SourceSansBold
scanBtn.TextSize = 10 
scanBtn.Parent = widgetFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = scanBtn

--- =================================================== ---
---              LOGIC RADAR THÔNG MINH                 ---
--- =================================================== ---

local isScanning = false

-- Hàm dọn dẹp ESP cũ
local function clearOldEsp()
	for _, v in pairs(workspace:GetDescendants()) do
		if v.Name == "Radar_Highlight" or v.Name == "Radar_Billboard" then
			v:Destroy()
		end
	end
end

-- Hàm lấy tên đúng của Item
local function getCorrectName(object)
	if object:IsA("BasePart") and object.Parent:IsA("Model") and object.Parent.Name ~= "Workspace" then
		return object.Parent.Name
	end
	return object.Name
end

-- Bộ lọc thông minh hơn
local function isInteractable(object)
	if object:IsA("BasePart") and object.Transparency > 0.9 then return false end
	if object:IsDescendantOf(localPlayer.Character) then return false end -- Chặn tự quét chính mình
	
	-- Kiểm tra ProximityPrompt
	local prompt = object:FindFirstChildOfClass("ProximityPrompt") or object:FindFirstChild("ProximityPrompt", true)
	if prompt then
		return true
	end
	
	-- Lọc theo từ khóa tên
	local n = string.lower(object.Name)
	local keywords = {"chest", "box", "item", "fruit", "drop", "tool", "coin", "hợp chất", "material"}
	for _, key in pairs(keywords) do
		if string.find(n, key) then return true end
	end
	
	return false
end

-- Hàm tạo hiệu ứng
local function applyRadarEsp(object)
	if object:FindFirstChild("Radar_Highlight") then return end
	
	local target = (object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildOfClass("BasePart"))) or object
	if not target or not target:IsA("BasePart") then return end

	local displayName = getCorrectName(object)
	if displayName == "Part" or displayName == "Handle" or displayName == "MeshPart" then return end 

	-- Phát sáng viền
	local hl = Instance.new("Highlight")
	hl.Name = "Radar_Highlight"
	hl.FillColor = Color3.fromRGB(255, 255, 0)
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.5
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = object
	hl.Parent = object

	-- Hiện tên
	local bb = Instance.new("BillboardGui")
	bb.Name = "Radar_Billboard"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0, 120, 0, 30)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.Adornee = target
	bb.Parent = object
	
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = displayName
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255) 
	lbl.TextStrokeTransparency = 0
	lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lbl.Font = Enum.Font.SourceSansBold
	lbl.TextSize = 14
	lbl.Parent = bb
end

-- [CẬP NHẬT] Bắt đầu trình quét siêu tốc chuẩn 1 giây
local function startRadar()
	if isScanning then return end
	isScanning = true
	
	clearOldEsp() -- Xóa cũ để quét mới
	
	scanBtn.Text = "SCANNING"
	scanBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)

	task.spawn(function()
		-- Rút ngắn vòng lặp: Quét dứt điểm toàn bộ map ngay lập tức trong 1 giây duy nhất
		for _, v in pairs(workspace:GetDescendants()) do
			if isInteractable(v) then
				applyRadarEsp(v)
			end
		end
		
		task.wait(1) -- Chờ đủ 1 giây để hiển thị trạng thái đang hoạt động
		
		isScanning = false
		scanBtn.Text = "SCAN\nREADY"
		scanBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	end)
end

--- =================================================== ---
---                 HỆ THỐNG KÉO THẢ                    ---
--- =================================================== ---
local isDragging = false
local function setupDrag(f, b)
	local d, di, ds, sp
	b.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			d = true isDragging = false ds = i.Position sp = f.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false end end)
		end
	end)
	b.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			di = i if d then isDragging = true end
		end
	end)
	UIS.InputChanged:Connect(function(i) if i == di and d then 
		local delta = i.Position - ds
		f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
	end end)
end

setupDrag(widgetFrame, scanBtn)

scanBtn.MouseButton1Up:Connect(function()
	if not isDragging then
		startRadar()
	end
end)
