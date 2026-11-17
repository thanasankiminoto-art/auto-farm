-- Auto Farm autostart: put this file in your executor's auto-execute folder.
-- 1) start screen: presses Play
-- 2) in the game: downloads the newest Auto Farm from GitHub and runs it
--    (no internet / GitHub down: runs the copy saved last time)
local URL = "https://raw.githubusercontent.com/thanasankiminoto-art/auto-farm/main/auto_farm.lua"
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
while not lp do task.wait(0.2) lp = Players.LocalPlayer end

local function isPlayButton(b)
	if not (b:IsA("GuiButton") and b.Visible) then return false end
	local texts = { b.Name }
	if b:IsA("TextButton") then texts[#texts + 1] = b.Text end
	for _, d in ipairs(b:GetDescendants()) do if d:IsA("TextLabel") then texts[#texts + 1] = d.Text end end
	if b.Parent then texts[#texts + 1] = b.Parent.Name end
	for _, t in ipairs(texts) do
		local s = tostring(t):lower():gsub("%s+", "")
		if not s:find("again") and not s:find("player") and not s:find("playing")
			and (s == "play" or s == "playbtn" or s == "playbutton" or s == "playbtnframe" or s == "start" or s == "startgame") then
			return true
		end
	end
	return false
end
local function visibleOnScreen(g)
	local p = g
	while p and p:IsA("GuiObject") do
		if not p.Visible then return false end
		p = p.Parent
	end
	if p and p:IsA("ScreenGui") and not p.Enabled then return false end
	return g.AbsoluteSize.X > 0
end
local function press(b)
	local fired = false
	for _, sig in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down", "MouseButton1Up" }) do
		pcall(function()
			for _, c in ipairs(getconnections(b[sig])) do c:Fire() fired = true end
		end)
	end
	if not fired then
		pcall(function()
			local vim = game:GetService("VirtualInputManager")
			local pos = b.AbsolutePosition + b.AbsoluteSize / 2
			local inset = game:GetService("GuiService"):GetGuiInset()
			vim:SendMouseButtonEvent(pos.X, pos.Y + inset.Y, 0, true, game, 1)
			task.wait(0.05)
			vim:SendMouseButtonEvent(pos.X, pos.Y + inset.Y, 0, false, game, 1)
		end)
	end
end
task.spawn(function()
	local t0, presses = os.clock(), 0
	while os.clock() - t0 < 120 and presses < 5 do
		local pg = lp:FindFirstChild("PlayerGui")
		if pg then
			for _, b in ipairs(pg:GetDescendants()) do
				if isPlayButton(b) and visibleOnScreen(b) then press(b) presses += 1 task.wait(2) break end
			end
		end
		task.wait(1)
	end
end)

-- game places only (the start screen has no game data)
local RS = game:GetService("ReplicatedStorage")
local t0 = os.clock()
repeat task.wait(0.5) until (RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("ReplicaController")) or os.clock() - t0 > 30
if not (RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("ReplicaController")) then return end
if getgenv().__AutoQueuedRan then return end
getgenv().__AutoQueuedRan = true
local ok, code = pcall(function() return game:HttpGet(URL .. "?t=" .. tostring(os.time())) end)
if ok and type(code) == "string" and #code > 1000 then
	loadstring(code)()
elseif isfile and isfile("auto_farm_src.lua") then
	getgenv().__AutoSrc = readfile("auto_farm_src.lua")
	loadstring(getgenv().__AutoSrc)()
end
