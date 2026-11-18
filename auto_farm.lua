getgenv().__AutoSrc = [==[local __g = (getgenv and getgenv()) or _G
local __URL = "https://raw.githubusercontent.com/thanasankiminoto-art/auto-farm/main/auto_farm.lua"
local function __note(t, d)
	pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Auto Farm", Text = t, Duration = d or 6 }) end)
end
if not game:IsLoaded() then game.Loaded:Wait() end
__note("loading...", 4)
local __lp = game:GetService("Players").LocalPlayer
while not __lp do task.wait(0.2) __lp = game:GetService("Players").LocalPlayer end
-- start screen: the game's events (PlayerEvents.DialogEvents) only exist after Play is pressed.
-- Some games show your avatar on the start screen, so "no character" is not enough to tell.
local __RS = game:GetService("ReplicatedStorage")
local function __inGame()
	local pe = __RS:FindFirstChild("PlayerEvents")
	return pe and pe:FindFirstChild("DialogEvents") ~= nil
end
do local t = os.clock() while not __inGame() and os.clock() - t < 4 do task.wait(0.5) end end
if not __inGame() then
	pcall(function() if writefile and __g.__AutoSrc then writefile("auto_farm_src.lua", __g.__AutoSrc) end end)
	pcall(function()
		if queue_on_teleport then
			queue_on_teleport([[
local g = (getgenv and getgenv()) or _G
if g.__AutoQueuedRan then return end
g.__AutoQueuedRan = true
if isfile and isfile("auto_farm_src.lua") then
	g.__AutoSrc = readfile("auto_farm_src.lua")
	loadstring(g.__AutoSrc)()
else
	loadstring(game:HttpGet("]] .. __URL .. [["))()
end
]])
		end
	end)
	local function isPlay(b)
		if not (b:IsA("GuiButton") and b.Visible and b.AbsoluteSize.X > 0) then return false end
		local p = b
		while p and p:IsA("GuiObject") do if not p.Visible then return false end p = p.Parent end
		if p and p:IsA("ScreenGui") and not p.Enabled then return false end
		local texts = { b.Name, b.Parent and b.Parent.Name or "" }
		if b:IsA("TextButton") then texts[#texts + 1] = b.Text end
		for _, d in ipairs(b:GetDescendants()) do if d:IsA("TextLabel") then texts[#texts + 1] = d.Text end end
		for _, t in ipairs(texts) do
			local s = tostring(t):lower():gsub("<[^>]+>", ""):gsub("%s+", "")
			if not s:find("again") and not s:find("player") and not s:find("playing") and not s:find("display")
				and (s == "play" or s:sub(1, 4) == "play" or s == "start" or s == "startgame" or s:find("เล่น") or s:find("เริ่ม")) then
				return true
			end
		end
		return false
	end
	local function press(b)
		local fired = false
		pcall(function()
			for _, sig in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down", "MouseButton1Up" }) do
				for _, c in ipairs(getconnections(b[sig])) do c:Fire() fired = true end
			end
		end)
		if not fired then
			pcall(function() if firesignal then firesignal(b.MouseButton1Click) firesignal(b.Activated) fired = true end end)
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
	__note("start screen: pressing Play, the script starts in the game", 8)
	local t0, seen = os.clock(), false
	while not __inGame() and os.clock() - t0 < 120 do
		local pg = __lp:FindFirstChild("PlayerGui")
		for _, b in ipairs(pg and pg:GetDescendants() or {}) do
			if isPlay(b) then seen = true press(b) break end
		end
		task.wait(3)
	end
	if not __inGame() then
		if not seen then
			local names = {}
			for _, b in ipairs(__lp.PlayerGui:GetDescendants()) do
				if b:IsA("GuiButton") and b.Visible and #names < 15 then names[#names + 1] = b:GetFullName():gsub("^.-PlayerGui%.", "") end
			end
			warn("[Auto Farm] no Play button found. Buttons: " .. table.concat(names, " | "))
			__note("couldn't find the Play button - press it yourself, the script starts in the game", 15)
		end
		repeat task.wait(1) until __inGame()
	end
	if not __lp.Character then __lp.CharacterAdded:Wait() end
end
task.wait(3)
local __ok, __err = xpcall(function()
--@@BUILD 1794981199
--// AUTO ALL v2 -- one button: unlock every TP, turn in / accept / do every quest
--// Verified in-game:
--//   turn in   : DialogEvents.CompleteQuest:FireServer(nil, questId)   (works from far away)
--//   accept    : DialogEvents.StartQuest:FireServer(npcQuestId)        (works from far away)
--//   mob place : PlayerEvents.RequestQuestHint:InvokeServer({Type="Kill", MobToKill=name}) -> Vector3
--//   find item : PlayerData:FireServer("ProgressQuest", {QuestIndex=i}) near the object
--//   talk to   : DialogEvents.ProgressTalkQuest:FireServer(npcModel)
--//   unlock TP : PlayerData:FireServer("UnlockRespawnPoint", {RespawnPoint=part}) within a few studs (3D)
--//   warp      : PlayerData:FireServer("TravelToRespawnPoint", {RespawnPoint=part})
--//   movement  : BodyVelocity in 3D (Humanoid:MoveTo is blocked by the game)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local genv = (getgenv and getgenv()) or _G

local savedOpt = type(genv.__AutoAll) == "table" and genv.__AutoAll.opt or nil
-- clean up every older script from this session
for _, k in ipairs({ "__AutoAll", "__MegaAuto", "__AutoQuest", "__AutoFarm" }) do
	local o = genv[k]
	if type(o) == "table" and o.Destroy then pcall(o.Destroy) end
	genv[k] = nil
end
for _, k in ipairs({ "__noclipConn", "__antiFallConn" }) do
	local c = genv[k]
	if c then pcall(function() c:Disconnect() end) end
	genv[k] = nil
end
genv.__SimpleFarm = false

local PE = RS:WaitForChild("PlayerEvents")
local DE = PE:WaitForChild("DialogEvents") -- not there yet on the start screen (before Play)
local MultiHit = PE:WaitForChild("MultiEntityHit")
local CharController = require(RS:WaitForChild("Modules"):WaitForChild("CharacterController"))
local RC = require(RS:WaitForChild("Packages"):WaitForChild("ReplicaController"))
local FindObjects = RS:FindFirstChild("FloorAssets") and RS.FloorAssets:FindFirstChild("QuestFindObjects")

local M = {
	running = false, alive = true,
	speed = 100, hover = 12,
	kills = 0, turnedIn = 0, accepted = 0, unlocked = 0,
	phase = "Ready", logs = {},
	-- every feature can be switched on/off from the UI
	opt = {
		unlockTP = true,  -- fly to and unlock every respawn point
		turnIn = true,    -- hand in finished quests
		accept = true,    -- pick up new quests from every NPC
		kill = true,      -- do "kill X" quests
		find = true,      -- do "find item" quests
		talk = true,      -- do "talk to NPC" quests
		retreat = true,   -- fly up to heal when HP is low
		under = true,     -- attack from under the ground (false = from above)
		dist = 15,        -- starting distance from the mob (auto-adjusts)
		skills = true,    -- cast hotbar skills while fighting
		dodge = true,     -- step out of every enemy attack box before it lands
		autoFortune = true, -- pick the best dungeon fortune for me
		nextFloor = false, -- beat the floor boss and move up when strong enough
		bossLevel = 24,   -- min level before trying the floor boss
		autoPlay = true,  -- press Play on the start screen
		homeFloor = 0,    -- map to travel to when entering the game (0 = stay where you spawn)
		upgrade = false,  -- upgrade the weapon / armor you wear
		keepCoins = 2000, -- never spend coins below this
		chests = true,    -- open chests in cleared dungeons
		craft = false,    -- craft gear that beats yours
		dropForeign = true, -- drop quests that belong to another floor
		orbs = true,      -- pick up item orbs on the map
		bounty = true, -- hunt the bounty monster (pink marker) when one spawns on the map
		skipCutscene = true, -- skip / vote-skip cutscenes (boss intros etc.)
		autoSell = false, -- sell gear worse than yours in Sunshine Town when the bag is full
		healAt = 70,      -- cast heal skills below this HP %
		maxFightMin = 3,  -- skip quest mobs that would take longer than this to kill
		longSkip = true,  -- a quest that fails twice is skipped for 30 min (e.g. bosses that are too strong)
	},
}
M.statW = { Strength = 3, Vitality = 2, Dexterity = 0, Agility = 0, Intelligence = 0, Focus = 0 }
if type(genv.__AutoStatW) == "table" then for k, v in pairs(genv.__AutoStatW) do M.statW[k] = v end end
genv.__AutoStatW = M.statW
if savedOpt then
	for k, v in pairs(savedOpt) do
		if M.opt[k] ~= nil then M.opt[k] = v end
	end
end
local conns = {}
local skipUntil = {} -- questId -> os.clock() when it may be retried
local failCount = {} -- questId -> number of failed attempts

local function log(s)
	local L = M.logs
	L[#L + 1] = ("%.1f %s"):format(os.clock(), s)
	if #L > 150 then table.remove(L, 1) end
	-- also keep a log file that survives teleports (place id + time)
	if appendfile and s ~= M._lastLogLine then
		M._lastLogLine = s
		pcall(appendfile, "auto_farm_log_" .. lp.UserId .. ".txt", ("%s [%d] %s\n"):format(os.date("%H:%M:%S"), game.PlaceId, s))
	end
end

local function char()
	local ch = lp.Character
	if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	if hum and hrp and hum.Health > 0 then return hum, hrp end
end

local function data()
	for _, r in pairs(RC._replicas) do
		if r.Class == "PlayerData" and r.Children and r.Children[1] then return r.Children[1] end
	end
end

local function quests()
	local d = data()
	return d and d.Data.Quests.QuestsInProgress or {}
end

local statusLabel
local function status(s)
	M.phase = s
	if statusLabel then statusLabel.Text = s end
end

----------------------------------------------------------------------
-- noclip + flying (BodyVelocity, full 3D so we can reach caves / hills)
----------------------------------------------------------------------
-- seats next to respawn points grab the character and freeze it; never sit while running
local function unseat(hum)
	if hum.Sit or hum:GetState() == Enum.HumanoidStateType.Seated then
		hum.Sit = false
		local seat = hum.SeatPart
		if seat then
			for _, w in ipairs(seat:GetChildren()) do
				if w:IsA("Weld") and w.Name == "SeatWeld" then pcall(function() w:Destroy() end) end
			end
		end
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local noclipConn
local function setNoclip(on)
	if on and not noclipConn then
		noclipConn = RunService.Stepped:Connect(function()
			local ch = lp.Character
			if not ch then return end
			for _, p in ipairs(ch:GetChildren()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
			local hum = ch:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
				unseat(hum)
			end
		end)
	elseif not on and noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil
		local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
	end
end

-- smooth movement controller: every frame steer toward moveTarget with a speed that
-- shrinks near the target (no overshoot), keep the body upright, and stop the Humanoid
-- from "standing up" on nearby floors (that was the up/down bouncing)
local bv, gyro, moveConn
local moveTarget, faceTarget, moveSpeed = nil, nil, 100

local function ensureMovers(hrp)
	if not bv or bv.Parent ~= hrp then
		if bv then pcall(function() bv:Destroy() end) end
		bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bv.P = 1e4
		bv.Velocity = Vector3.zero
		bv.Parent = hrp
	end
	if not gyro or gyro.Parent ~= hrp then
		if gyro then pcall(function() gyro:Destroy() end) end
		gyro = Instance.new("BodyGyro")
		gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
		gyro.P = 2e4
		gyro.D = 500
		gyro.CFrame = hrp.CFrame
		gyro.Parent = hrp
	end
end

local function setTarget(pos, speed, face)
	moveTarget = pos
	moveSpeed = speed or M.speed
	faceTarget = face
	if moveConn then return end
	moveConn = RunService.Heartbeat:Connect(function()
		if not moveTarget then return end
		local hum, hrp = char()
		if not hrp then return end
		ensureMovers(hrp)
		hum.PlatformStand = true
		-- dodge every frame: the moment we are inside a red area, jump out and stay out
		-- ("Seek" attacks spawn right on top of us with ~0.8 s warning, the fight loop alone is too slow)
		if M.opt.dodge and M._safe then
			local out, inside = M._safe(hrp.Position)
			if inside then
				hrp.CFrame = CFrame.new(out) * (hrp.CFrame - hrp.CFrame.Position)
				hrp.AssemblyLinearVelocity = Vector3.zero
				local _, tgtBad = M._safe(moveTarget)
				if tgtBad then moveTarget = out end -- don't glide straight back in
			end
		end
		local d = moveTarget - hrp.Position
		local v = d * 6
		if v.Magnitude > moveSpeed then v = v.Unit * moveSpeed end
		if d.Magnitude < 0.5 then v = Vector3.zero end
		bv.Velocity = v
		local look = faceTarget or (d.Magnitude > 2 and moveTarget) or nil
		if look then
			local flatLook = Vector3.new(look.X, hrp.Position.Y, look.Z)
			if (flatLook - hrp.Position).Magnitude > 0.5 then
				gyro.CFrame = CFrame.lookAt(hrp.Position, flatLook)
			end
		end
	end)
end

local function release()
	moveTarget, faceTarget = nil, nil
	if moveConn then moveConn:Disconnect() moveConn = nil end
	if bv then pcall(function() bv:Destroy() end) end
	if gyro then pcall(function() gyro:Destroy() end) end
	bv, gyro = nil, nil
	local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

----------------------------------------------------------------------
-- respawn points (TP)
----------------------------------------------------------------------
local function rpParts()
	local t = {}
	local folder = workspace:FindFirstChild("RespawnPoints")
	if folder then
		for _, m in ipairs(folder:GetChildren()) do
			local pp = m.PrimaryPart
			if pp and pp:GetAttribute("Id") then t[#t + 1] = { part = pp, name = m.Name, id = tostring(pp:GetAttribute("Id")) } end
		end
	end
	return t
end

local function isUnlocked(id)
	local d = data()
	if not d then return false end
	local all = d.Data.FloorRespawnPoints or {}
	-- ids restart from 1 on every floor: only this floor's list counts
	local fl = M.currentFloor and M.currentFloor()
	if fl then
		local ids = all[tostring(fl)] or all[fl]
		return ids ~= nil and ids[tostring(id)] ~= nil
	end
	for _, ids in pairs(all) do
		if ids[tostring(id)] then return true end
	end
	return false
end

local function tpCount()
	local all, open = 0, 0
	for _, rp in ipairs(rpParts()) do
		all += 1
		if isUnlocked(rp.id) then open += 1 end
	end
	return open, all
end

-- warp to the unlocked point nearest the target, but only if that saves real distance
local function warpToward(target)
	local _, hrp = char()
	if not hrp then return end
	-- one warp, then fly: a moving target (or two spots far apart) made it bounce between two TP points
	if os.clock() - (M._lastWarpAt or -99) < 20 then return end
	local myDist = (hrp.Position - target).Magnitude
	local best, bd
	for _, rp in ipairs(rpParts()) do
		if isUnlocked(rp.id) then
			local d = (rp.part.Position - target).Magnitude
			if not bd or d < bd then best, bd = rp, d end
		end
	end
	if not best or bd + 150 >= myDist then return end
	local d = data()
	if not d then return end
	release()
	d:FireServer("TravelToRespawnPoint", { RespawnPoint = best.part })
	M._lastWarpAt = os.clock()
	log("warp -> " .. best.name)
	local from = hrp.Position
	local t0 = os.clock()
	repeat
		task.wait(0.25)
		local _, h = char()
		if h and (h.Position - from).Magnitude > 50 then break end
	until os.clock() - t0 > 5
	task.wait(0.5)
end

local function fly(target, stop, timeout)
	stop = stop or 6
	timeout = timeout or 45
	if not char() then return false end
	warpToward(target)
	local bestDist, bestAt
	local deadline = os.clock() + timeout
	while M.running and os.clock() < deadline do
		local hum, hrp = char()
		if not hrp then return false end
		if hum.SeatPart or hum.Sit then
			hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
			local w = hum.SeatPart and hum.SeatPart:FindFirstChild("SeatWeld")
			if w then pcall(function() w:Destroy() end) end
			hum.Sit = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		setTarget(target, M.speed)
		local dist = (target - hrp.Position).Magnitude
		if dist <= stop then return true end
		-- stuck (something keeps pushing us back): stop pushing instead of bouncing
		if not bestDist or dist < bestDist - 2 then
			bestDist, bestAt = dist, os.clock()
		elseif os.clock() - bestAt > 3 then
			log(("stuck %.0f studs from target, giving up"):format(dist))
			setTarget(hrp.Position, M.speed)
			return false
		end
		task.wait(0.1)
	end
	-- timed out: hold where we are instead of drifting
	local _, hrp = char()
	if hrp then setTarget(hrp.Position, M.speed) end
	return false
end

----------------------------------------------------------------------
-- combat
----------------------------------------------------------------------
local function equip()
	if not CharController:GetState("Equipped") then
		pcall(function()
			CharController:SetState("Equipped", true)
			PE.ManageWeapon:InvokeServer(true)
		end)
		task.wait(0.4)
	end
end

local function mobPos(m)
	local ok, cf = pcall(m.GetPivot, m)
	return ok and cf and cf.Position or nil
end

local function nearestMob(name)
	local _, hrp = char()
	if not hrp then return end
	local best, bd
	for _, e in ipairs(workspace.SpawnedEntities:GetChildren()) do
		if e.Name == name then
			local h = e:FindFirstChildOfClass("Humanoid")
			local p = h and h.Health > 0 and mobPos(e)
			if p then
				local d = (p - hrp.Position).Magnitude
				if not bd or d < bd then best, bd = e, d end
			end
		end
	end
	return best
end

local function recover()
	status("Low HP - recovering up high")
	local t0 = os.clock()
	local _, hrp = char()
	if not hrp then return end
	-- flying straight up gets pushed back down in caves (the bouncing), so instead
	-- warp to the nearest unlocked respawn camp and stand there normally to heal
	release()
	local best, bd
	for _, rp in ipairs(rpParts()) do
		if isUnlocked(rp.id) then
			local d = (rp.part.Position - hrp.Position).Magnitude
			if not bd or d < bd then best, bd = rp, d end
		end
	end
	local d = data()
	if best and d then
		status("Low HP - warping to " .. best.name .. " to heal")
		local from = hrp.Position
		d:FireServer("TravelToRespawnPoint", { RespawnPoint = best.part })
		repeat
			task.wait(0.25)
			local _, h = char()
			if not h or (h.Position - from).Magnitude > 30 then break end
		until os.clock() - t0 > 5
	end
	while M.running and os.clock() - t0 < 45 do
		local hum = char()
		if not hum then return end
		if hum.Health / hum.MaxHealth >= 0.8 then return end
		status(("Healing %d/%d"):format(hum.Health, hum.MaxHealth))
		task.wait(0.5)
	end
end

-- attack position: above the mob or under the ground, at an adaptive distance.
-- every 2 s: took damage -> move 5 studs farther; dealt no damage -> move 5 studs closer.
local MIN_DIST, MAX_DIST = 6, 33 -- hits register up to ~35 studs (tested)
local castSkills -- defined further down
----------------------------------------------------------------------
-- dodge: the server tells our client about every enemy attack before it lands
-- (Replicate -> VisualAOE / ProjectileThrow / DamageField with Size, Offset, Time).
-- We keep those boxes and never stand inside one.
----------------------------------------------------------------------
local zones = {}
local DODGE_MARGIN = 6
M.dodges = 0

local function zoneHas(z, pos, m)
	local l = z.cf:PointToObjectSpace(pos)
	return math.abs(l.X) <= z.size.X / 2 + m and math.abs(l.Y) <= z.size.Y / 2 + m and math.abs(l.Z) <= z.size.Z / 2 + m
end

local function liveZones()
	local now = os.clock()
	for i = #zones, 1, -1 do
		if zones[i].t < now then table.remove(zones, i) end
	end
	return zones
end

-- nearest point outside every danger box (pushes out through the closest face)
local function safePos(pos)
	if not M.opt.dodge then return pos, false end
	local moved = false
	for _ = 1, 6 do
		local hit
		for _, z in ipairs(liveZones()) do
			if zoneHas(z, pos, DODGE_MARGIN) then hit = z break end
		end
		if not hit then return pos, moved end
		local l = hit.cf:PointToObjectSpace(pos)
		local best, bestD
		for _, ax in ipairs({ "X", "Y", "Z" }) do
			local half = hit.size[ax] / 2 + DODGE_MARGIN + 2
			for _, sg in ipairs({ 1, -1 }) do
				local nl = Vector3.new(ax == "X" and sg * half or l.X, ax == "Y" and sg * half or l.Y, ax == "Z" and sg * half or l.Z)
				local d = (nl - l).Magnitude
				if not bestD or d < bestD then best, bestD = nl, d end
			end
		end
		pos = hit.cf:PointToWorldSpace(best)
		moved = true
	end
	return pos, moved
end

M._safe = safePos
local function addZone(cf, size, life)
	if typeof(cf) ~= "CFrame" or typeof(size) ~= "Vector3" then return end
	local z = { cf = cf, size = size, t = os.clock() + life }
	zones[#zones + 1] = z
	-- already standing in it? jump out right now instead of waiting for the fight loop
	local _, hrp = char()
	if M.opt.dodge and M.running and hrp and zoneHas(z, hrp.Position, DODGE_MARGIN) then
		local safe = safePos(hrp.Position)
		pcall(function() hrp.CFrame = CFrame.new(safe) * (hrp.CFrame - hrp.CFrame.Position) end)
		M.dodges += 1
	end
end

table.insert(conns, PE.Replicate.OnClientEvent:Connect(function(name, a)
	if type(a) ~= "table" or type(a.AttackAttributes) ~= "table" then return end
	local aa = a.AttackAttributes
	local em = a.EnemyModel
	local root = em and em:FindFirstChild("HumanoidRootPart")
	if not root or typeof(aa.Size) ~= "Vector3" then return end
	M._lastAtk = { t = os.clock(), who = em.Name, kind = name, size = aa.Size, time = aa.Time }
	local T = tonumber(aa.Time) or 1
	if name == "VisualAOE" then
		local cf = a.OverrideCFrame or root.CFrame
		if typeof(aa.Offset) == "CFrame" then cf *= aa.Offset end
		addZone(cf, aa.Size, T + 0.6)
	elseif name == "VisualProjectileThrow" or name == "SummonVisualProjectileThrow" then
		addZone(root.CFrame * CFrame.new(0, 0, root.Size.Z / -2 - aa.Size.Z / 2), aa.Size, T + (tonumber(aa.ProjectileDuration) or 0.5) + 0.6)
	elseif name == "VisualReverseProjectileThrow" then
		addZone(root.CFrame * CFrame.new(0, 0, root.Size.Z / 2 + aa.Size.Z / 2), aa.Size, T + (tonumber(aa.ProjectileDuration) or 0.5) + 0.6)
	elseif name == "VisualDamageField" then
		local cf = a.OverrideCFrame or root.CFrame
		if typeof(aa.Offset) == "CFrame" then cf *= aa.Offset end
		addZone(cf, aa.Size, T + (tonumber(aa.Count) or 1) * (tonumber(aa.TimeBetween) or 1) + 0.6)
	end
end))

-- many enemies at once (tower boss floors: ~5 bosses together): pick the spot that can still hit the
-- target (<= 33 studs) but is outside every red area and as far as possible from all the other enemies
local crowdOffset
M.crowdSpot = function(mob, p, sign, R)
	if not M.opt.dodge then return nil end
	local others = {}
	for _, e in ipairs(workspace.SpawnedEntities:GetChildren()) do
		if e ~= mob then
			local eh = e:FindFirstChildOfClass("Humanoid")
			local ep = eh and eh.Health > 0 and mobPos(e)
			if ep and (ep - p).Magnitude < 90 then others[#others + 1] = ep end
		end
	end
	if #others < 2 then crowdOffset = nil return nil end
	local zs = liveZones()
	local function score(pos)
		for _, z in ipairs(zs) do
			if zoneHas(z, pos, DODGE_MARGIN) then return nil end
		end
		local m = 999
		for _, ep in ipairs(others) do m = math.min(m, (ep - pos).Magnitude) end
		return m
	end
	local best, bestS
	-- hits only register when we are (almost) straight above/below the target, so stay in a narrow
	-- column; depth comes from the fight's own distance (goes deeper when hit, closer when hits miss)
	for _, r in ipairs({ 0, 6 }) do
		local y = sign * math.sqrt(R * R - r * r)
		for a = 0, (r == 0) and 0 or 7 do
			local ang = a * math.pi / 4
			local off = Vector3.new(math.cos(ang) * r, y, math.sin(ang) * r)
			local sc = score(p + off)
			if sc and (not bestS or sc > bestS) then best, bestS = off, sc end
		end
	end
	-- keep the current spot while it is still safe and nearly as good (no jittering around)
	-- the fight changed its distance (enemy heals when we hang too far): drop the old spot
	if crowdOffset and math.abs(crowdOffset.Magnitude - R) > 2 then crowdOffset = nil end
	if crowdOffset then
		local cur = score(p + crowdOffset)
		if cur and (not bestS or cur >= bestS - 8) then return p + crowdOffset end
	end
	crowdOffset = best
	return best and (p + best) or nil
end

local function kill(mob, single)
	local h = mob:FindFirstChildOfClass("Humanoid")
	local p = mobPos(mob)
	if not h or not p or h.Health <= 0 then return false end
	equip()
	local sign = M.opt.under and -1 or 1
	local dist = math.clamp(M.opt.dist or 15, MIN_DIST, MAX_DIST)
	do -- several enemies together (boss floors): start deeper, 25 studs is under most area attacks
		local near = 0
		for _, e in ipairs(workspace.SpawnedEntities:GetChildren()) do
			local eh = e ~= mob and e:FindFirstChildOfClass("Humanoid")
			local ep = eh and eh.Health > 0 and mobPos(e)
			if ep and (ep - p).Magnitude < 90 then near += 1 end
		end
		if near >= 2 then dist = math.max(dist, 25) end
	end
	fly(p + Vector3.new(0, sign * dist, 0), 8, 40)
	local hum0 = char()
	local myLast = hum0 and hum0.Health or 0
	local mobLast = h.Health
	local nextCheck = os.clock() + 2
	local t0 = os.clock()
	local lastProgress, lastHP = os.clock(), h.Health
	local retreats = 0
	-- keep fighting while the mob keeps losing HP; give up only after 20 s without any damage (hard cap 5 min)
	while M.running and (M.on.kill or M._dungeonRunning) and h.Health > 0 and mob.Parent and os.clock() - lastProgress < 20 and os.clock() - t0 < (single and 900 or 300)
		and not (h.Health >= h.MaxHealth and os.clock() - t0 > 12 and not single) do
		if h.Health < lastHP then
			M._dmg = (M._dmg or 0) + (lastHP - h.Health) -- live damage meter for "too strong" checks
			lastProgress, lastHP = os.clock(), h.Health
		end
		M._dmgTime = (M._dmgTime or 0) + 0.45
		local hum, hrp = char()
		if not hrp or (hum and hum.Health <= 0) then
			M.deathCount = M.deathCount or {}
			M.deathCount[mob.Name] = (M.deathCount[mob.Name] or 0) + 1
			if single then
				log(("died fighting %s (%d/3)"):format(mob.Name, M.deathCount[mob.Name]))
				return M.deathCount[mob.Name] < 3 -- not a failed quest yet: respawn and go again
			else
				M.deathBy = M.deathBy or {}
				M.deathBy[mob.Name] = os.time()
				log("died fighting " .. mob.Name .. " - it is skipped for 30 min")
			end
			return false
		end
		if (M._dungeonRunning or single) and hum.Health / hum.MaxHealth < 0.35 then
			-- dungeon / tower / mini-boss quest: never leave the enemy (it heals 10% per second when we go far).
			-- back off to the edge of our reach and keep hitting + dodging; Heal skill does the rest
			if dist < MAX_DIST then
				dist = MAX_DIST
				log(("low HP vs %s - holding at max range instead of leaving"):format(mob.Name))
			end
		elseif M.opt.retreat and hum.Health / hum.MaxHealth < 0.35 then
			retreats = (retreats or 0) + 1
			if retreats >= 2 and not M._dungeonRunning and not single then
				-- it brought us near death twice: too strong for now, don't wait to die
				M.deathBy = M.deathBy or {}
				M.deathBy[mob.Name] = os.time()
				log(("%s nearly killed us twice - too strong, skipping it 30 min"):format(mob.Name))
				recover()
				return false
			end
			recover()
			myLast, mobLast, nextCheck = hum.Health, h.Health, os.clock() + 2
		end
		if os.clock() >= nextCheck then
			local took = hum.Health < myLast - 1
			local dealt = h.Health < mobLast
			if took and dist < MAX_DIST then
				dist = math.min(MAX_DIST, dist + 5)
				log(("getting hit by %s, moving to %d studs %s"):format(mob.Name, dist, sign < 0 and "below" or "above"))
			elseif not dealt and dist > MIN_DIST then
				dist = math.max(MIN_DIST, dist - 5)
				log(("no damage on %s, moving closer: %d studs"):format(mob.Name, dist))
			end
			myLast, mobLast, nextCheck = hum.Health, h.Health, os.clock() + 2
		end
		p = mobPos(mob) or p
		-- glide to the spot above/below the mob (follows it if it walks)
		local want = M.crowdSpot(mob, p, sign, dist) or (p + Vector3.new(0, sign * dist, 0))
		local safe, dodging = safePos(want)
		-- standing in a red area right now: snap out instantly, gliding is too slow for 0.5s attacks
		if M.opt.dodge then
			local cur = hrp.Position
			local out, inside = safePos(cur)
			if inside then
				pcall(function() hrp.CFrame = CFrame.new(out) * (hrp.CFrame - hrp.CFrame.Position) end)
			end
		end
		if dodging and not M._lastDodgeLog or (dodging and os.clock() - M._lastDodgeLog > 3) then
			M._lastDodgeLog = os.clock()
			M.dodges += 1
			status("Dodging " .. mob.Name .. "'s attack")
		end
		setTarget(safe, dodging and 160 or 60, p)
		if not dodging and (hrp.Position - safe).Magnitude > 45 and os.clock() - (M._lastCatchUp or 0) > 1.5 then
			M._lastCatchUp = os.clock()
			pcall(function() hrp.CFrame = CFrame.new(safe) * (hrp.CFrame - hrp.CFrame.Position) end)
		end
		-- one swing hits every enemy in reach (the game's own swing sends a list too)
		local targets = { mob }
		for _, e in ipairs(workspace.SpawnedEntities:GetChildren()) do
			if #targets >= 12 then break end
			if e ~= mob then
				local eh = e:FindFirstChildOfClass("Humanoid")
				local ep = eh and eh.Health > 0 and mobPos(e)
				if ep and (ep - hrp.Position).Magnitude <= 32 then targets[#targets + 1] = e end
			end
		end
		pcall(function() MultiHit:FireServer(targets) end)
		castSkills(hum.Health / hum.MaxHealth)
		task.wait(0.45)
	end
	if h.Health <= 0 then
		M.kills += 1
		return true
	end
	if single and M.deathCount and (M.deathCount[mob.Name] or 0) > 0 and (M.deathCount[mob.Name] or 0) < 3 then return true end
	-- the mob was still taking damage (or someone else took it): not a failed quest
	if h.Health < h.MaxHealth and os.clock() - lastProgress < 20 then return true end
	if not mob.Parent then return true end
	return false
end

----------------------------------------------------------------------
-- quests
----------------------------------------------------------------------
local function turnInAll()
	for _, q in ipairs(quests()) do
		if not M.running then return end
		if q.Objective == "Return" then
			status("Turning in: " .. tostring(q.Title or q.ID))
			DE.CompleteQuest:FireServer(nil, q.ID)
			task.wait(1.2)
			local still = false
			for _, q2 in ipairs(quests()) do
				if q2.ID == q.ID and q2.Objective == "Return" then still = true end
			end
			if still then
				log("turn in failed: " .. q.ID)
			else
				M.turnedIn += 1
				log("turned in " .. q.ID)
				if q.Repeatable or tostring(q.ID):find("Daily") or tostring(q.ID):find("DAILY") or q.Type == "RandomKill" then
					M.side.dailyDone = M.side.dailyDone or {}
					M.side.dailyDone[q.ID] = os.time() -- the game keeps no client-side timer: remember when it comes back
				end
			end
		end
	end
end

local lastAccept = -math.huge
local function acceptAll()
	if os.clock() - lastAccept < 90 then return end
	lastAccept = os.clock()
	local d = data()
	if not d then return end
	local have = {}
	for _, q in ipairs(quests()) do have[q.ID] = true end
	local done = d.Data.Quests.CompletedQuests or {}
	local before = #quests()
	-- the game holds MAX_QUESTS (4) quests; taking one more silently DROPS the oldest one,
	-- so only take as many as there are free slots
	local maxQ = 4
	for _, r in pairs(RC._replicas) do
		if r.Class == "Info" and r.Data._GameData then maxQ = tonumber(r.Data._GameData.MAX_QUESTS) or 4 end
	end
	local free = maxQ - before
	M._lastAcceptGained = 0
	if free <= 0 then return end
	status("Picking up quests...")
	for _, n in ipairs(workspace.NPCs:GetChildren()) do
		if not M.running or free <= 0 then break end
		local info2 = n:FindFirstChild("NPCInfo")
		local id = info2 and info2:GetAttribute("ID")
		local tree = info2 and info2:FindFirstChild("DialogTree")
		if id and tree and not have[id] and not done[id] and tree:FindFirstChild("StartQuestCMD", true) then
			local n0 = #quests()
			DE.StartQuest:FireServer(id)
			task.wait(0.4)
			if #quests() > n0 then free -= 1 end
		end
	end
	task.wait(1)
	local gained = #quests() - before
	M._lastAcceptGained = gained
	if gained > 0 then
		M.accepted += gained
		log(("accepted %d new quests"):format(gained))
	end
end

local function doKill(q)
	-- a floor boss (e.g. Skeleton King) lives in its own boss room: go in through the boss gate
	do
		local info
		for _, r in pairs(RC._replicas) do if r.Class == "Info" then info = r.Data end end
		local want = tostring(q.MobToKill or ""):lower():gsub("%s", "")
		for name, bo in pairs(info and info.Bosses or {}) do
			local n = name:lower():gsub("%s", "")
			if want ~= "" and (n == want or n:find(want, 1, true) or want:find(n, 1, true)) and M.EnterBoss then
				status("Quest boss: " .. name .. " - going to the boss room")
				log("quest needs boss " .. name .. ", entering boss room")
				if os.clock() < (M._bossQuestRetry or 0) then return false end
				if not M.EnterBoss() then
					M._bossQuestRetry = os.clock() + 300 -- don't hammer it (this froze the game before)
					task.wait(2)
					return false
				end
				return true
			end
		end
	end
	local target = nearestMob(q.MobToKill)
	if not target then
		local ok, hint = pcall(function()
			return PE.RequestQuestHint:InvokeServer({ Type = "Kill", MobToKill = q.MobToKill })
		end)
		if not ok or typeof(hint) ~= "Vector3" then
			-- the monster lives on another map (e.g. the Mission Board's daily kill): go there
			local mf = M.loadDrops and ((M.loadDrops()).__mobFloor or {})[tostring(q.MobToKill)]
			local cur = M.currentFloor()
			local sd = M.side
			sd.questTried = sd.questTried or {}
			local okFloor = false
			for _, f in ipairs(M.floorList()) do if f.n == mf and f.ok then okFloor = true end end
			if mf and cur and mf ~= cur and okFloor and not M.inDungeon() and not M.onTrip() and not sd.questTrip and os.time() - (sd.questTried[q.MobToKill] or 0) > 600 then
				sd.questTried[q.MobToKill] = os.time()
				sd.questTrip, sd.questMob, sd.questFloor, sd.questSum, sd.questMoved = os.time(), q.MobToKill, mf, nil, os.time()
				M.saveState()
				log(("%s lives on map %d - going there for the quest"):format(tostring(q.MobToKill), mf))
				if M.travelTo(mf, "quest " .. tostring(q.MobToKill)) then task.wait(20) end
				return false
			end
			log("no location for " .. tostring(q.MobToKill))
			return false
		end
		status(("Going to %s"):format(q.MobToKill))
		fly(hint + Vector3.new(0, 15, 0), 10, 75)
		local t0 = os.clock()
		repeat
			task.wait(0.5)
			target = nearestMob(q.MobToKill)
		until target or M.bountyWaiting() or not M.running or not M.on.kill or os.clock() - t0 > 30
	end
	if not target then
		-- everything there is dead: wait for respawns instead of hopping to another quest
		M._noMob = M._noMob or {}
		M._noMob[q.ID] = (M._noMob[q.ID] or 0) + 1
		if M._noMob[q.ID] <= 4 then
			status(("Waiting for %s to respawn (%d/4)"):format(q.MobToKill, M._noMob[q.ID]))
			return true
		end
		M._noMob[q.ID] = nil
		log("no " .. q.MobToKill .. " spawned at its area")
		return false
	end
	if M._noMob then M._noMob[q.ID] = nil end
	-- too strong? (died to it recently, or it would take too long with our real damage per second)
	do
		local th = target:FindFirstChildOfClass("Humanoid")
		local dps = (M._dmgTime or 0) > 20 and (M._dmg or 0) / M._dmgTime or nil
		local single = (tonumber(q.Amount) or 1) <= 1
		local died, secs, limit
		if single then
			-- one-mob quests (mini bosses): keep trying, give up for 30 min only after 3 deaths
			died = M.deathCount and (M.deathCount[q.MobToKill] or 0) >= 3
			if died then M.deathCount[q.MobToKill] = 0 end
			secs, limit = 0, 1
		else
			died = M.deathBy and M.deathBy[q.MobToKill] and os.time() - M.deathBy[q.MobToKill] < 1800
			secs = (dps and dps > 0 and th) and th.Health / dps or 0
			limit = (M.opt.maxFightMin or 3) * 60
		end
		if died or secs > limit then
			log(("too strong: %s (%s) - skipping its quest 30 min"):format(q.MobToKill, died and (single and "died 3 times" or "died to it") or ("%d HP, about %d min to kill"):format(th.Health, math.ceil(secs / 60))))
			failCount[q.ID] = math.max(failCount[q.ID] or 0, 1) -- the failure below makes it 2 = long skip
			M.gaveUp = M.gaveUp or {}
			M.gaveUp[q.ID] = os.time() -- only these count as "can't do" when clearing all quests
			return false
		end
	end
	status(("Quest: %s - kill %s [%d/%d]"):format(tostring(q.Title or q.ID), q.MobToKill, q.Progress, q.Amount))
	return kill(target, (tonumber(q.Amount) or 1) <= 1)
end

local function doFind(q, index)
	local obj = FindObjects and FindObjects:FindFirstChild(q.ObjectToFind or "")
	local part = obj and obj:FindFirstChild("MainPart")
	if not part then
		log("can't locate item " .. tostring(q.ObjectToFind))
		return false
	end
	status("Finding " .. q.ObjectToFind)
	if not fly(part.Position + Vector3.new(0, 3, 0), 6, 75) then return false end
	local d = data()
	if d then d:FireServer("ProgressQuest", { QuestIndex = index }) end
	task.wait(1.5)
	return true
end

local function doTalk(q)
	local npc = workspace.NPCs:FindFirstChild(q.NPCToTalkTo or "")
	local pos = npc and npc:GetPivot().Position
	if not pos then
		local ok, hint = pcall(function()
			return PE.RequestQuestHint:InvokeServer({ Type = "TalkTo", NPCToTalkTo = q.NPCToTalkTo })
		end)
		if ok and typeof(hint) == "Vector3" then pos = hint end
	end
	if not pos then
		log("can't locate NPC " .. tostring(q.NPCToTalkTo))
		return false
	end
	status("Talking to " .. q.NPCToTalkTo)
	if not fly(pos + Vector3.new(0, 3, 0), 8, 75) then return false end
	npc = workspace.NPCs:FindFirstChild(q.NPCToTalkTo)
	if npc then DE.ProgressTalkQuest:FireServer(npc) end
	task.wait(1.5)
	return true
end

-- pick the next quest of the given kind we can do right now
local function nextStep(kind)
	local now = os.clock()
	for i, q in ipairs(quests()) do
		if q.Objective == kind and (skipUntil[q.ID] or 0) < now then return q, i end
	end
end

local function hasKind(kind)
	for _, q in ipairs(quests()) do
		if q.Objective == kind then return true end
	end
	return false
end

----------------------------------------------------------------------
-- unlock every TP (nearest first)
----------------------------------------------------------------------
local function unlockAll()
	while M.running do
		local _, hrp = char()
		if not hrp then return end
		local best, bd
		for _, rp in ipairs(rpParts()) do
			if not isUnlocked(rp.id) and (skipUntil["tp" .. rp.id] or 0) < os.clock() then
				local d = (rp.part.Position - hrp.Position).Magnitude
				if not bd or d < bd then best, bd = rp, d end
			end
		end
		if not best then return end
		status("Unlocking TP: " .. best.name)
		if fly(best.part.Position + Vector3.new(0, 3, 0), 5, 90) then
			local d = data()
			if d then d:FireServer("UnlockRespawnPoint", { RespawnPoint = best.part }) end
			task.wait(1.5)
		end
		if isUnlocked(best.id) then
			M.unlocked += 1
			log("unlocked " .. best.name)
		else
			log("unlock failed " .. best.name)
			skipUntil["tp" .. best.id] = os.clock() + 600
		end
	end
end

----------------------------------------------------------------------
-- functions: any number of switches can be ON together. One scheduler loop runs while
-- at least one is ON and does each enabled job in turn (they share one character, so
-- they can't literally move at the same time).
----------------------------------------------------------------------
----------------------------------------------------------------------
-- stats, best gear, skills
----------------------------------------------------------------------
local RF = require(RS.Modules.ReplicaFunctions)
local SkillFns = require(RS.Modules.SkillFunctions)
local SkillsMod = require(RS:WaitForChild("Skills"))
local STAT_NAMES = { "Strength", "Vitality", "Dexterity", "Agility", "Intelligence", "Focus" }

local function gameInfo()
	for _, r in pairs(RC._replicas) do
		if r.Class == "Info" then return r.Data end
	end
end

-- spend free points round-robin: +1 to each stat from top to bottom, again and again,
-- skipping stats that already reached their target
M.statT = M.statT or {}
M.statTarget = function(n, alloc)
	local t = M.statT[n]
	if t == nil then return alloc and alloc[n] or 0 end -- not set yet: keep what you have
	return t
end
M.planStats = function(alloc, points)
	local add = {}
	local progress = true
	while points > 0 and progress do
		progress = false
		for _, n in ipairs(STAT_NAMES) do
			if points <= 0 then break end
			if (alloc[n] or 0) + (add[n] or 0) < M.statTarget(n, alloc) then
				add[n] = (add[n] or 0) + 1
				points -= 1
				progress = true
			end
		end
	end
	return add, points
end
M.PlanStats = M.planStats
local function allocateStats()
	local d = data()
	if not d then return 0 end
	local points = d.Data.Stats.Points or 0
	if points <= 0 then return 0 end
	local alloc = d.Data.Stats.Allocations
	local add = {}
	local spent = 0
	-- +1 to each stat from top to bottom, round after round, skipping stats already at their target
	while points > 0 do
		local gave = false
		for _, n in ipairs(STAT_NAMES) do
			if points <= 0 then break end
			if (alloc[n] or 0) + (add[n] or 0) < M.statTarget(n, alloc) then
				add[n] = (add[n] or 0) + 1
				points -= 1
				spent += 1
				gave = true
			end
		end
		if not gave then break end -- every stat reached its target
	end
	for _, n in ipairs(STAT_NAMES) do
		if add[n] then
			d:FireServer("AllocateStatPoints", { Stat = n, Amount = add[n] })
			log(("stats: +%d %s"):format(add[n], n))
			task.wait(0.4)
		end
	end
	return spent
end

M.itemStats = function(item, invClass)
	local info = gameInfo()
	if not info or type(item) ~= "table" then return nil end
	local def = (info[invClass] and info[invClass][item.Name])
	if not def then
		local ok, cls = pcall(function() return RF:GetItemInfoClass(item.Class) end)
		def = ok and cls and info[cls] and info[cls][item.Name]
	end
	if not def then return nil end
	local ok, st = pcall(function() return RF:CalculateItemStatByLevel(item.Leveling and item.Leveling.Level or 1, def) end)
	if not ok or type(st) ~= "table" then return nil end
	local out = {}
	for k, v in pairs(st) do out[k] = v end
	for k, v in pairs(item.Substats or {}) do out[k] = (out[k] or 0) + (type(v) == "table" and v.Value or v or 0) end
	return out
end

M.magicBuild = function()
	return (M.statT.Intelligence or 0) > (M.statT.Strength or 0)
end

M.weaponScore = function(st)
	if not st then return -1 end
	local main = M.magicBuild() and (st.MagicalPower or 0) or (st.PhysicalPower or 0)
	return main * (1 + (st.CriticalRate or 0) / 100 * (st.CriticalDamage or 50) / 100)
end

M.armorScore = function(st)
	if not st then return -1 end
	return (st.ArmorRating or 0) + (st.Health or 0) * 2 + ((st.PhysicalResistance or 0) + (st.MagicalResistance or 0)) * 5
end

local function equipBestGear()
	local d = data()
	if not d then return end
	local inv, eq = d.Data.Inventory, d.Data.Equipped
	local changed = false
	local G = (M.side and M.side.gear) or {}
	local myLevel = d.Data.Leveling.Level or 1
	local function canWear(item) return ((item.Leveling and item.Leveling.Level) or 1) <= myLevel end
	-- a Gear Goals pick only takes the slot over once you own a copy you can wear; until then the best gear is used
	local function goalActive(id, cls)
		local g = G[id]
		if not (g and g.name) then return false end
		for _, c in ipairs(M.gearCopies(cls, g.name)) do
			if canWear(c.item) then return true end
		end
		return false
	end
	local w1Goal, w2Goal, armorGoal = goalActive("w1", "Weapons"), goalActive("w2", "Weapons"), goalActive("armor", "Armor")
	M._noDual = M._noDual or {}
	local function wscore(it) return M.weaponScore(M.itemStats(it, "Weapons")) end
	local function spaced() task.wait(math.max(0, (M._lastEquipAt or 0) + 2.5 - os.clock())) end
	if not w1Goal and not w2Goal then
		-- both hands together: two of the same type (dual wield) can beat one stronger weapon on its own
		local byCls = {}
		local function add(p)
			local c = p.item.Class
			if not c then return end
			byCls[c] = byCls[c] or {}
			table.insert(byCls[c], p)
		end
		for h = 1, 2 do
			local it = eq.Hands and eq.Hands[h]
			if type(it) == "table" then add({ item = it, hand = h, sc = wscore(it) }) end
		end
		for key, item in pairs(inv.Weapons or {}) do
			if canWear(item) then add({ key = key, item = item, sc = wscore(item) }) end
		end
		local bestCls, bestTotal, bestList
		for cls, list in pairs(byCls) do
			table.sort(list, function(x, y) return x.sc > y.sc end)
			local total = list[1].sc + ((not M._noDual[cls] and list[2]) and list[2].sc or 0)
			if not bestTotal or total > bestTotal then bestCls, bestTotal, bestList = cls, total, list end
		end
		local h1, h2 = eq.Hands and eq.Hands[1], eq.Hands and eq.Hands[2]
		local curTotal = (type(h1) == "table" and wscore(h1) or 0) + ((type(h1) == "table" and type(h2) == "table" and h2.Class == h1.Class) and wscore(h2) or 0)
		if bestList and bestTotal > curTotal * 1.05 + 1 then
			local want = { bestList[1], (not M._noDual[bestCls]) and bestList[2] or nil }
			local sameCls = type(h1) == "table" and h1.Class == bestCls
			log(("gear: %s x%d (%.0f > %.0f)"):format(bestCls, #want, bestTotal, curTotal))
			if not sameCls then
				-- new weapon type: main hand first (the second hand must match it)
				local first = want[1].key and want[1] or want[2]
				if first and first.key then
					spaced()
					d:FireServer("Equip", { SelectedItem = { "Weapons", first.key, first.item }, Hand = 1 })
					M._lastEquipAt = os.clock()
					changed = true
					task.wait(1.5)
					local other = first == want[1] and want[2] or want[1]
					if other and other.key then
						spaced()
						d:FireServer("Equip", { SelectedItem = { "Weapons", other.key, other.item }, Hand = 2 })
						M._lastEquipAt = os.clock()
						task.wait(1.5)
						local now = d.Data.Equipped.Hands[2]
						if not (type(now) == "table" and now.Name == other.item.Name) then M._noDual[bestCls] = true end
					end
				end
			else
				-- same type: put each wanted bag weapon in a hand that holds something not wanted
				local keep = {}
				for _, w in ipairs(want) do if w.hand then keep[w.hand] = true end end
				for _, w in ipairs(want) do
					if w.key then
						local hand = not keep[1] and 1 or not keep[2] and 2 or nil
						if hand then
							keep[hand] = true
							spaced()
							d:FireServer("Equip", { SelectedItem = { "Weapons", w.key, w.item }, Hand = hand })
							M._lastEquipAt = os.clock()
							changed = true
							task.wait(1.5)
							if hand == 2 then
								local now = d.Data.Equipped.Hands[2]
								if not (type(now) == "table" and now.Name == w.item.Name) then M._noDual[bestCls] = true end
							end
						end
					end
				end
			end
		end
	elseif not w2Goal then
		-- main hand is a Gear Goals pick: fill the second hand with the best weapon of the same type
		local main = eq.Hands and eq.Hands[1]
		local cls = type(main) == "table" and main.Class
		if cls and not M._noDual[cls] then
			local off = eq.Hands[2]
			local offScore = (type(off) == "table" and off.Class == cls) and wscore(off) or -1
			local k2, i2, s2
			for key, item in pairs(inv.Weapons or {}) do
				if item.Class == cls and canWear(item) then
					local sc = wscore(item)
					if sc > offScore and (not s2 or sc > s2) then k2, i2, s2 = key, item, sc end
				end
			end
			if i2 then
				local name, lvl = i2.Name, i2.Leveling.Level
				spaced()
				d:FireServer("Equip", { SelectedItem = { "Weapons", k2, i2 }, Hand = 2 })
				M._lastEquipAt = os.clock()
				task.wait(1.2)
				local now = eq.Hands[2]
				if type(now) == "table" and now.Name == name then
					log(("gear: second hand %s Lv%d (dual %s)"):format(name, lvl, cls))
					changed = true
				else
					M._noDual[cls] = true -- this weapon type can't be dual wielded
				end
			end
		end
	end
	-- armor
	local curA = M.armorScore(M.itemStats(eq.Armor, "Armor"))
	local bk, bi, bs
	for key, item in pairs(inv.Armor or {}) do
		local sc = canWear(item) and M.armorScore(M.itemStats(item, "Armor")) or -1
		if sc > curA and (not bs or sc > bs) then bk, bi, bs = key, item, sc end
	end
	if bi and not armorGoal then
		d:FireServer("Equip", { SelectedItem = { "Armor", bk, bi } })
		log(("gear: armor %s (%.0f > %.0f)"):format(bi.Name, bs, curA))
		changed = true
		task.wait(1)
	end
	return changed
end

-- best skills for farming, in priority order; ones the weapon can't use are skipped
-- farming order: damage + sustain first, buffs, then heals; skills you can't use yet are never slotted
local SKILL_PRIORITY = { "Vampiric Blade", "Power Strike", "Power Surge", "Deep Void", "Fire Ball", "Lightning Orb", "Still Water", "Aimed Shot", "Heal", "Soothing Presence" }
M.skillUsable = function(name, class, d)
	local mod = SkillsMod[name]
	local inf = mod and mod.Info
	if not inf then return false end
	if inf.WeaponClasses and not table.find(inf.WeaponClasses, class) then return false end
	local alloc = d.Data.Stats.Allocations
	for stat, need in pairs((inf.Requirements and inf.Requirements.Stats) or {}) do
		if (alloc[stat] or 0) < need then return false end
	end
	return true
end
M.SkillUsable = M.skillUsable

local function equipBestSkills()
	local d = data()
	if not d then return end
	local hands = d.Data.Equipped.Hands
	local class = hands and hands[1] and hands[1].Class
	if not class then return end
	local owned = d.Data.Skills or {}
	local function hotbar() return d.Data.Equipped.Hotbar.Skills[class] or {} end
	-- the 6 best skills you can use right now
	local want = {}
	for _, name in ipairs(SKILL_PRIORITY) do
		if owned[name] and M.skillUsable(name, class, d) then want[#want + 1] = name end
		if #want >= 6 then break end
	end
	local wanted = {}
	for _, n in ipairs(want) do wanted[n] = true end
	local function slotOf(name)
		for i = 1, 6 do local v = hotbar()[i]; if type(v) == "table" and v.Name == name then return i end end
	end
	for _, name in ipairs(want) do
		if not slotOf(name) then
			-- an empty slot, or one holding a skill you can't use / don't want
			local slot
			for i = 1, 6 do local v = hotbar()[i]; if v == nil or v == "None" then slot = i break end end
			if not slot then
				-- only push out a skill you cannot use; never touch a working skill you chose yourself
				for i = 1, 6 do local v = hotbar()[i]; if type(v) == "table" and not wanted[v.Name] and not M.skillUsable(v.Name, class, d) then slot = i break end end
			end
			if slot then
				local old = hotbar()[slot]
				if type(old) == "table" then
					d:FireServer("UnequipSkill", { SkillName = old.Name, WeaponClass = class, SkillSlot = slot })
					task.wait(0.4)
				end
				d:FireServer("EquipSkill", { SkillName = name, WeaponClass = class, SkillSlot = slot })
				task.wait(0.5)
				if slotOf(name) then log(("skills: %s -> slot %d%s"):format(name, slot, type(old) == "table" and (" (was " .. old.Name .. ")") or "")) end
			end
		end
	end
end

-- cast hotbar skills during a fight: Heal when hurt, damage skills when ready
local skillReadyAt = {}
castSkills = function(hpRatio)
	if not M.opt.skills then return end
	local d = data()
	local class = d and d.Data.Equipped.Hands[1] and d.Data.Equipped.Hands[1].Class
	if not class then return end
	for _, v in ipairs(d.Data.Equipped.Hotbar.Skills[class] or {}) do
		local name = type(v) == "table" and v.Name
		local mod = name and SkillsMod[name]
		if mod and os.clock() >= (skillReadyAt[name] or 0) then
			local isHeal = mod.Info and mod.Info.SkillType == "Heal"
			if not isHeal or hpRatio < (M.opt.healAt or 70) / 100 then
				local ok, can = pcall(SkillFns.CanCastSkill, SkillFns, lp.Character, d, name)
				if ok and can then
					local ok2, cast = pcall(function() return PE.SkillEvents.Cast:InvokeServer(name) end)
					if ok2 and cast then
						task.spawn(function() pcall(function() mod:Callback() end) end)
						local cd = mod.Info and mod.Info.Stats and mod.Info.Stats.Cooldown or 5
						skillReadyAt[name] = os.clock() + cd + 0.2
						M.casts = (M.casts or 0) + 1
						if M.casts <= 5 or M.casts % 20 == 0 then log("cast " .. name) end
						return -- one skill per swing
					end
				end
			end
		end
	end
end

----------------------------------------------------------------------
-- saved state (survives teleports into/out of dungeons)
----------------------------------------------------------------------
local Http = game:GetService("HttpService")
-- one settings file per account: two accounts on this PC must not share switches or stat targets
local STATE_FILE = "auto_farm_state_" .. lp.UserId .. ".json"
do
	-- the old shared file belonged to the first account that used the script
	local LEGACY = "auto_farm_state.json"
	if isfile and readfile and writefile and lp.Name == "kingkong_55595" then
		local ok1, has = pcall(isfile, STATE_FILE)
		local ok2, old = pcall(isfile, LEGACY)
		if ok1 and not has and ok2 and old then pcall(function() writefile(STATE_FILE, readfile(LEGACY)) end) end
	end
end
M.cycle = { enabled = false, questMin = 20, dungeonMin = 10, dungeons = {}, mode = "quest", phaseStart = 0, idx = 0, floor = nil }

local function saveState()
	local ok, txt = pcall(function()
		return Http:JSONEncode({ opt = M.opt, statW = M.statW, statT = M.statT, on = M.on, cycle = M.cycle, sellTrip = M.sellTrip, side = M.side, prio = M.prio })
	end)
	if ok and writefile then pcall(writefile, STATE_FILE, txt) end
end
M.Save = saveState

local function loadState()
	if not (isfile and readfile) then return nil end
	local ok, exists = pcall(isfile, STATE_FILE)
	if not ok or not exists then return nil end
	local ok2, st = pcall(function() return Http:JSONDecode(readfile(STATE_FILE)) end)
	return ok2 and type(st) == "table" and st or nil
end

-- re-run this script automatically after every teleport
local SRC_FILE = "auto_farm_src.lua"
local STARTER_SRC = [=[-- Auto Farm autostart (Madium AutoExecute)
-- 1) On the start screen: presses Play (if "Auto press Play" is ON in the script settings)
-- 2) In the game: loads the newest Auto Farm script saved in the executor workspace
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local lp = Players.LocalPlayer
while not lp do task.wait(0.2) lp = Players.LocalPlayer end

local opt = {}
pcall(function()
	if isfile("auto_farm_state.json") then
		local st = Http:JSONDecode(readfile("auto_farm_state.json"))
		opt = st.opt or {}
	end
end)

local function isPlayButton(b)
	if not (b:IsA("GuiButton") and b.Visible) then return false end
	local texts = { b.Name }
	if b:IsA("TextButton") then texts[#texts + 1] = b.Text end
	for _, d in ipairs(b:GetDescendants()) do
		if d:IsA("TextLabel") then texts[#texts + 1] = d.Text end
	end
	if b.Parent then texts[#texts + 1] = b.Parent.Name end
	for _, t in ipairs(texts) do
		local s = tostring(t):lower():gsub("%s+", "")
		if not s:find("again") and not s:find("player") and not s:find("playing")
			and (s == "play" or s == "playbtn" or s == "playbutton" or s == "playbtnframe" or s == "เล่น" or s == "เริ่มเกม" or s == "เริ่ม" or s == "start" or s == "startgame") then
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
			for _, c in ipairs(getconnections(b[sig])) do
				c:Fire()
				fired = true
			end
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

-- start screen
if opt.autoPlay ~= false then
	task.spawn(function()
		local t0 = os.clock()
		local presses = 0
		while os.clock() - t0 < 120 and presses < 5 do
			local pg = lp:FindFirstChild("PlayerGui")
			if pg then
				for _, b in ipairs(pg:GetDescendants()) do
					if isPlayButton(b) and visibleOnScreen(b) then
						press(b)
						presses += 1
						task.wait(2)
						break
					end
				end
			end
			task.wait(1)
		end
	end)
end

-- game places: load the farm script (the teleport queue uses the same guard, so it only runs once)
local RS = game:GetService("ReplicatedStorage")
local t0 = os.clock()
repeat task.wait(0.5) until (RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("ReplicaController")) or os.clock() - t0 > 30
if not (RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("ReplicaController")) then return end
if getgenv().__AutoQueuedRan then return end
getgenv().__AutoQueuedRan = true
if isfile and isfile("auto_farm_src.lua") then
	getgenv().__AutoSrc = readfile("auto_farm_src.lua")
	loadstring(getgenv().__AutoSrc)()
end
]=]
local function queueSelf()
	local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
	local src = genv.__AutoSrc
	if not q then return end
	-- keep the newest copy on disk; whatever version is queued always loads the newest one
	if src and writefile then
		local function build(t) return tonumber(t and t:match("%-%-@@BUILD (%d+)")) or 0 end
		local cur = isfile and isfile(SRC_FILE) and readfile(SRC_FILE) or nil
		if not cur or build(src) >= build(cur) then pcall(writefile, SRC_FILE, src) end
	end
	local clear = clear_teleport_queue or clearteleportqueue
	if clear then pcall(clear) end -- drop older copies queued by earlier versions
	-- the starter presses Play on a start screen and loads the newest script in game places
	if writefile then pcall(writefile, "auto_farm_start.lua", STARTER_SRC) end
	pcall(q, "if isfile and isfile('auto_farm_start.lua') then loadstring(readfile('auto_farm_start.lua'))() end")
end

----------------------------------------------------------------------
-- dungeons
----------------------------------------------------------------------
local CS = game:GetService("CollectionService")
local function inBoss()
	local info = gameInfo()
	if not info then return false end
	local g = info._GameData
	return (g.IsBoss and g.IsBoss ~= false) or (g.IsDailyBoss and g.IsDailyBoss ~= false) or false
end

local function inTower()
	local info = gameInfo()
	return info and info._GameData.IsTower and info._GameData.IsTower ~= false or false
end

local function inDungeon()
	local info = gameInfo()
	if not info then return false end
	local g = info._GameData
	if (g.IsBattleArena and g.IsBattleArena ~= false) or (g.IsEther and g.IsEther ~= false) then return true end
	local cat = info._GameData.IsCatacomb
	return type(info._GameData.IsDungeon) == "table" or inBoss() or inTower() or (cat and cat ~= false) or false
end

local function currentFloor()
	local info = gameInfo()
	if not info then return nil end
	local d = info._GameData.IsDungeon
	if type(d) == "table" and tonumber(d.Floor) then return tonumber(d.Floor) end
	local f = info._GameData.IsFloor
	if type(f) == "number" then return f end
	if type(f) == "table" then
		for _, k in ipairs({ "Floor", "Number", "Index", "Id" }) do
			if tonumber(f[k]) then return tonumber(f[k]) end
		end
	end
	return nil
end
M.currentFloor = currentFloor
M.inDungeon = inDungeon
M.saveState = saveState

local function instData()
	for _, r in pairs(RC._replicas) do
		if r.Class == "InstanceData" then return r end
	end
end

local function dungeonsForFloor(floor)
	local info = gameInfo()
	local list = {}
	local xp = {}
	for name, dg in pairs(info and info.Dungeons or {}) do
		if not floor or dg.Floor == floor then list[#list + 1] = name xp[name] = tonumber(dg.Experience) or 0 end
	end
	table.sort(list, function(a, b) if xp[a] ~= xp[b] then return xp[a] < xp[b] end return a < b end)
	-- bosses go last: better loot
	for name, bo in pairs(info and info.Bosses or {}) do
		if (not floor or bo.Floor == floor) and bo.Floor then
			local key = "BOSS:" .. name
			list[#list + 1] = key
			xp[key] = tonumber(bo.Experience) or 0
		end
	end
	for name, ar in pairs(info and info.BattleArenas or {}) do
		if (not floor or ar.Floor == floor) and ar.Floor then
			list[#list + 1] = "ARENA:" .. name
			xp["ARENA:" .. name] = 0
		end
	end
	for name, et in pairs(info and info.Ethers or {}) do
		if (not floor or et.Floor == floor) and et.Floor then
			list[#list + 1] = "ETHER:" .. name
			xp["ETHER:" .. name] = 0
		end
	end
	for name, ct in pairs(info and info.Catacombs or {}) do
		if (not floor or ct.Floor == floor) and ct.Floor then
			local key = "CATA:" .. name
			list[#list + 1] = key
			xp[key] = 0
		end
	end
	for name, tw in pairs(info and info.Towers or {}) do
		if (not floor or tw.Floor == floor) and tw.Floor then
			local key = "TOWER:" .. name
			list[#list + 1] = key
			xp[key] = 0
		end
	end
	for name, bo in pairs(info and info.DailyBosses or {}) do
		if (not floor or bo.Floor == floor) and bo.Floor then
			local key = "DAILY:" .. name
			list[#list + 1] = key
			xp[key] = tonumber(bo.Experience) or 0
		end
	end
	M._dgXP = xp
	return list
end

-- good for us first: buff to player > debuff to enemy > buff to enemy > debuff to player
M.fortuneScore = function(f)
	local base = (f.Operation == "Positive" and f.Type == "Player") and 300
		or (f.Operation == "Negative" and f.Type == "Enemy") and 200
		or (f.Operation == "Positive" and f.Type == "Enemy") and 100 or 0
	local good = base >= 200
	return base + (good and 1 or -1) * (tonumber(f.Tier) or 0) * 10 + (good and 1 or -1) * (tonumber(f.Percent) or 0) / 10
end

M.pickFortune = function(inst)
	if not M.opt.autoFortune then
		status("Fortune screen left for you to pick")
		local t0 = os.clock()
		while os.clock() - t0 < 60 and pcall(function() return CharController:GetState("SelectingFortunes") end) and CharController:GetState("SelectingFortunes") do task.wait(0.5) end
		return
	end
	local mine = inst.Data.PlayerFortunes and inst.Data.PlayerFortunes[lp.Name]
	if type(mine) ~= "table" then return end
	local bestI, bestS
	for i, f in pairs(mine) do
		local sc = M.fortuneScore(f)
		if not bestS or sc > bestS then bestI, bestS = i, sc end
	end
	if bestI then
		local f = mine[bestI]
		inst:FireServer("FortuneChosen", { Index = tonumber(bestI) or bestI })
		log(("fortune: %s %s %s %s%%"):format(tostring(f.Operation), tostring(f.Type), tostring(f.Name or ""), tostring(f.Percent)))
		task.wait(1)
		pcall(function() CharController:SetState("SelectingFortunes", false) end)
		pcall(function() lp.PlayerGui.MainGui.FortunesFrame.Visible = false end)
	end
end

local function nearestAnyMob()
	local _, hrp = char()
	if not hrp then return end
	local best, bd
	for _, e in ipairs(workspace.SpawnedEntities:GetChildren()) do
		local h = e:FindFirstChildOfClass("Humanoid")
		local p = h and h.Health > 0 and mobPos(e)
		if p then
			local d = (p - hrp.Position).Magnitude
			if not bd or d < bd then best, bd = e, d end
		end
	end
	return best
end

local function nextDungeonName()
	local list = {}
	for _, name in ipairs(dungeonsForFloor(M.cycle.floor or currentFloor() or 2)) do
		if M.cycle.dungeons[name] then list[#list + 1] = name end
	end
	if #list == 0 then
		local all = dungeonsForFloor(M.cycle.floor or currentFloor() or 2)
		if #all == 0 then return nil end
		local hardest
		for _, n in ipairs(all) do if not n:find(":") then hardest = n break end end -- nothing picked on this floor yet: start with the easiest
		if not hardest then return nil end
		list = { hardest } -- new floor, nothing picked yet: hardest normal dungeon here
	end
	M.cycle.idx = (M.cycle.idx % #list) + 1
	return list[M.cycle.idx], #list
end

local enterBoss -- defined with the next-floor code
M.enterDailyBoss = function(name)
	local d = data()
	local pad
	for _, p in ipairs(CS:GetTagged("DailyBossPad")) do
		pad = p:IsA("BasePart") and p or p:FindFirstChildWhichIsA("BasePart", true)
		if pad then break end
	end
	if pad then fly(pad.Position + Vector3.new(0, 3, 0), 6, 90) end
	saveState()
	queueSelf()
	release()
	d:FireServer("EnterDailyBoss", { DailyBoss = name })
	task.wait(3)
	for _, r in pairs(RC._replicas) do
		if r.Class == "DailyBoss" and r.Data.Players and r.Data.Players[1] == lp then pcall(function() r:FireServer("Enter") end) end
	end
	task.wait(15)
end

local function enterDungeon(name)
	local d = data()
	if not d or not name then return end
	-- a monster on a map (gear farming): go to its map, then hunt it for 3 minutes
	if name:sub(1, 4) == "MOB:" then
		local mob, fl = name:match("^MOB:(.+)@(%d+)$")
		fl = tonumber(fl)
		local cur = currentFloor()
		M.side.gearFarmFloor = fl
		M.side.gearFarmAt = os.time()
		if fl and cur and fl ~= cur then
			saveState()
			M._gearTravel = true
			M.side.gearPending = nil
			saveState()
			if M.travelTo(fl, "hunt " .. tostring(mob)) then task.wait(20) end
			return
		end
		M.farmMob(mob, 180)
		return
	end
	-- a dungeon / boss on another map (gear farming): go to its map first, enter on arrival
	if not name:find(":") or name:sub(1, 5) == "BOSS:" then
		local fl = M.instFloor(name)
		local cur = currentFloor()
		if fl and cur and fl ~= cur then
			M.side.cataTrip = os.time()
			M.side.cataName = name
			M.side.gearFarmFloor = fl
			M.side.gearFarmAt = os.time()
			saveState()
			M._gearTravel = true
			M.side.gearPending = nil
			saveState()
			if not M.travelTo(fl, (name:gsub("^BOSS:", "boss "))) then M.side.cataTrip = nil return end
			task.wait(20)
			return
		end
	end
	if name:sub(1, 5) == "BOSS:" then
		status("Going to boss: " .. name:sub(6))
		log("entering boss " .. name:sub(6))
		enterBoss()
		return
	elseif name:sub(1, 6) == "ARENA:" or name:sub(1, 6) == "ETHER:" then
		local arena = name:sub(1, 6) == "ARENA:"
		local af = M.instFloor(name)
		if af and currentFloor() ~= af then
			-- on another map (Arena: Desert of Death, Ether: Lotus Lands): go there, enter on arrival, home afterwards
			M.side.cataTrip = os.time()
			M.side.cataName = name
			saveState()
			if not M.travelTo(af, arena and "Battle Arena" or "The Ether") then M.side.cataTrip = nil return end
			task.wait(20)
			return
		end
		M.side.cataTrip = nil
		status("Going to " .. name:sub(7))
		log("entering " .. name:sub(7))
		local pos
		for _, p in ipairs(CS:GetTagged(arena and "BattleArenaPad" or "EtherPad")) do
			local bp = p:IsA("BasePart") and p or p:FindFirstChildWhichIsA("BasePart", true)
			pos = bp and bp.Position or select(2, pcall(function() return p:GetPivot().Position end))
			if typeof(pos) == "Vector3" then break else pos = nil end
		end
		if pos then fly(pos + Vector3.new(0, 4, 0), 6, 90) end
		saveState()
		queueSelf()
		release()
		if arena then d:FireServer("EnterBattleArena", { BattleArena = name:sub(7) }) else d:FireServer("EnterEther") end
		task.wait(3)
		for _, r in pairs(RC._replicas) do
			if r.Data and type(r.Data.Players) == "table" and r.Data.Players[1] == lp then pcall(function() r:FireServer("Enter") end) end
		end
		task.wait(15)
		return
	elseif name:sub(1, 5) == "CATA:" then
		local ct = ((gameInfo() or {}).Catacombs or {})[name:sub(6)]
		local cf = ct and tonumber(ct.Floor)
		if cf and currentFloor() ~= cf then
			M.side.cataTrip = os.time()
			M.side.cataName = name
			saveState()
			if not M.travelTo(cf, "Catacombs") then M.side.cataTrip = nil return end
			task.wait(20)
			return
		end
		M.side.cataTrip = nil
		status("Going to the Catacombs")
		log("entering catacombs")
		local pos
		for _, p in ipairs(CS:GetTagged("CatacombsPad")) do
			local bp = p:IsA("BasePart") and p or p:FindFirstChildWhichIsA("BasePart", true)
			pos = bp and bp.Position or select(2, pcall(function() return p:GetPivot().Position end))
			if typeof(pos) == "Vector3" then break else pos = nil end
		end
		if pos then fly(pos + Vector3.new(0, 4, 0), 6, 90) end
		saveState()
		queueSelf()
		release()
		d:FireServer("EnterCatacombs")
		task.wait(3)
		for _, r in pairs(RC._replicas) do
			if r.Class == "Catacomb" or r.Class == "Catacombs" then
				if r.Data.Players and r.Data.Players[1] == lp then pcall(function() r:FireServer("Enter") end) end
			end
		end
		task.wait(15)
		return
	elseif name:sub(1, 6) == "TOWER:" then
		local tf = M.towerFloor()
		if tf and currentFloor() ~= tf then
			-- the Tower is on another map (Flywood Forest): travel there, enter on arrival, home again afterwards
			M.side.towerTrip = os.time()
			saveState()
			if not M.travelTo(tf, "Tower") then M.side.towerTrip = nil return end
			task.wait(20)
			return
		end
		M.side.towerTrip = nil
		status("Going to the Tower")
		log("entering tower")
		local pad
		for _, p in ipairs(CS:GetTagged("TowerPad")) do
			pad = p:IsA("BasePart") and p or p:FindFirstChildWhichIsA("BasePart", true)
			if pad then break end
		end
		if pad then fly(pad.Position + Vector3.new(0, 4, 0), 6, 90) end
		saveState()
		queueSelf()
		release()
		d:FireServer("EnterTower")
		task.wait(3)
		for _, r in pairs(RC._replicas) do
			if r.Class == "Tower" and r.Data.Players and r.Data.Players[1] == lp then pcall(function() r:FireServer("Enter") end) end
		end
		task.wait(15)
		return
	elseif name:sub(1, 6) == "DAILY:" then
		status("Going to daily boss: " .. name:sub(7))
		log("entering daily boss " .. name:sub(7))
		M.enterDailyBoss(name:sub(7))
		return
	end
	status("Entering dungeon: " .. name)
	log("entering dungeon " .. name)
	saveState()
	queueSelf()
	release()
	d:FireServer("EnterDungeon", { Dungeon = name })
	task.wait(15) -- teleport takes us away; if it didn't, carry on
end

local function dungeonTimeLeft()
	-- "clear all quests first" mode has no clock: one lap = every selected dungeon once, then back to quests
	if (M.cycle.trigger or "time") == "alldone" then
		return (M.cycle.lapLeft or 0) > 0 and 60 or 0
	end
	return M.cycle.dungeonMin * 60 - (os.time() - (M.cycle.phaseStart or 0))
end

-- clear the dungeon we're in, then play again / go back depending on the cycle
-- tower floors that are not fights (glass panels, lava parkour, golf...): fly through walls to the finish toucher
M.towerFinishPart = function(ftype)
	local root = workspace:FindFirstChild("TowerFloors")
	local folder = root and root:FindFirstChild(tostring(ftype))
	if not folder then return end
	local _, hrp = char()
	local best, bd
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("BasePart") and d:FindFirstChildOfClass("TouchTransmitter") then
			local n = d.Name:lower()
			if n:find("complete") or n:find("finish") or n:find("goal") or n:find("end") or n:find("hole") or n:find("win") then
				local dist = hrp and (d.Position - hrp.Position).Magnitude or 0
				if not bd or dist < bd then best, bd = d, dist end
			end
		end
	end
	return best
end

-- Golf floor: stand by the ball (that hands us its physics), then put it into the hole part
M.solveTowerGolf = function(inst)
	local folder = workspace:FindFirstChild("TowerFloors") and workspace.TowerFloors:FindFirstChild("Golf")
	local ball, clear
	for _, v in ipairs(folder and folder:GetChildren() or {}) do
		local o = v:FindFirstChild("Objects")
		local c = o and o:FindFirstChild("Clear Part")
		if c and c:FindFirstChildOfClass("TouchTransmitter") and o:FindFirstChild("Golf Ball") then ball, clear = o["Golf Ball"], c end
	end
	if not ball then return false end
	local fl = inst.Data.Floor or {}
	local before = tostring(fl.Type) .. tostring(fl.Current)
	status(("Tower floor %s: Golf - putting the ball in"):format(tostring(fl.Current)))
	release()
	local t0 = os.clock()
	repeat
		local _, hrp = char()
		if not hrp then break end
		pcall(function() hrp.CFrame = CFrame.new(ball.Position + Vector3.new(0, 14, 0)) end)
		task.wait(1.2)
		for _ = 1, 20 do
			pcall(function()
				ball.AssemblyLinearVelocity = Vector3.zero
				ball.CFrame = CFrame.new(clear.Position)
				firetouchinterest(ball, clear, 0)
			end)
			task.wait(0.1)
			local f2 = inst.Data.Floor or {}
			if tostring(f2.Type) .. tostring(f2.Current) ~= before then break end
		end
		pcall(function() firetouchinterest(ball, clear, 1) end)
		task.wait(1)
		local f2 = inst.Data.Floor or {}
		if tostring(f2.Type) .. tostring(f2.Current) ~= before or inst.Data.Failed then
			log("tower: finished Golf")
			return true
		end
	until os.clock() - t0 > 40
	return false
end

M.solveTowerObby = function(inst)
	local fl = inst.Data.Floor or {}
	if tostring(fl.Type) == "Golf" then return M.solveTowerGolf(inst) end
	local part = M.towerFinishPart(fl.Type)
	if not part then return false end
	status(("Tower floor %s: %s - going to the finish"):format(tostring(fl.Current), tostring(fl.Type)))
	local before = tostring(fl.Type) .. tostring(fl.Current)
	fly(part.Position + Vector3.new(0, 3, 0), 4, 60)
	local _, hrp = char()
	if hrp then
		pcall(function() hrp.CFrame = CFrame.new(part.Position) end)
		pcall(function()
			firetouchinterest(hrp, part, 0)
			task.wait(0.1)
			firetouchinterest(hrp, part, 1)
		end)
	end
	release()
	local t0 = os.clock()
	repeat task.wait(0.5)
		local f2 = inst.Data.Floor or {}
		if tostring(f2.Type) .. tostring(f2.Current) ~= before or inst.Data.Failed then break end
	until os.clock() - t0 > 8
	log(("tower: finished %s"):format(tostring(fl.Type)))
	return true
end

local function runDungeon()
	local inst
	local t0 = os.clock()
	repeat inst = instData(); task.wait(0.5) until inst or os.clock() - t0 > 20
	if not inst then status("Dungeon data not found") return end
	M._dungeonRunning = true
	M._visitStart, M._goalHit = nil, nil
	M.pickFortune(inst)
	local idle = 0
	local tower = inTower()
	local function going()
		if inst.Data.Failed then return false end
		if tower and M.side.towerDone then return false end -- reached the floor you asked for
		if M._goalHit then M._goalHit = nil return false end -- Catacombs / Arena floor goal reached
		if tower then return true end -- waves keep coming; stops on fail or long idle (below)
		return not inst.Data.Completed
	end
	while M.running and going() do
		if not char() then
			status("Waiting for respawn...")
			release()
			task.wait(2)
		else
			local fl = inst.Data.Floor
			local ftype = fl and tostring(fl.Type) or ""
			if tower and fl then
				local key = ftype .. tostring(fl.Current)
				if key ~= M._towerKey then M._towerKey = key log(("tower floor %s: %s"):format(tostring(fl.Current), ftype)) end
				local cur = tonumber(fl.Current) or 0
				if cur > (M.side.towerBest or 0) then M.side.towerBest = cur end
				-- the Tower restarts at floor 1 on every entry, so it has one number only: the goal floor.
				-- leave once that floor is cleared (= the next floor has started)
				if (M.side.towerGoal or 0) % 10 == 1 then M.side.towerGoal = M.side.towerGoal - 1 end -- old "601" style value
				if cur > (M.side.towerGoal or 600) and M.side.towerRepeat and not M._goalHit then
					-- repeat on: leave now, the list brings it back in its turn (starts again from floor 1)
					M._goalHit = true
					M.side.towerRuns = (M.side.towerRuns or 0) + 1
					log(("tower: floor %d cleared - leaving, will run it again later"):format(cur - 1))
				elseif cur > (M.side.towerGoal or 600) and not M.side.towerDone and not M.side.towerRepeat then
					M.side.towerDone = true
					log(("tower goal reached: floor %d cleared"):format(cur - 1))
					saveState()
				end
			end
			if fl and not tower then
				local g = gameInfo()._GameData
				local kind = (g.IsCatacomb and g.IsCatacomb ~= false) and "cata" or (g.IsBattleArena and g.IsBattleArena ~= false) and "arena" or nil
				if kind then
					local cur = tonumber(fl.Current) or 0
					M.side.best = M.side.best or {}
					M.side.goal = M.side.goal or {}
					M.side.done = M.side.done or {}
					if cur > (M.side.best[kind] or 0) then
						M.side.best[kind] = cur
						log(("%s floor %d"):format(kind == "cata" and "catacombs" or "arena", cur))
					end
					M._visitStart = M._visitStart or cur
					local per = tonumber((M.side.per or {})[kind]) or 0
					if per > 0 and cur - M._visitStart >= per and not M._goalHit then
						M._goalHit = true
						log(("%s: %d floors done this visit (reached floor %d) - switching"):format(kind, per, cur))
					end
					local goal = 0 -- no stop-for-good here: same rewards on every floor, the list just loops
					M.side.done[kind] = false
					if goal > 0 and cur >= goal and not M.side.done[kind] then
						M.side.done[kind] = true
						M._goalHit = true
						log(("%s goal reached: floor %d"):format(kind, cur))
						saveState()
					end
				end
			end
			-- stay on one enemy until it dies (spreading damage lets the others heal back):
			-- keep the current target, else the most wounded one, else the nearest
			local mob
			do
				M._skipMob = M._skipMob or setmetatable({}, { __mode = "k" })
				local function ok(en) return (M._skipMob[en] or 0) < os.clock() end
				local cur = M._target
				local ch = cur and cur.Parent and cur:FindFirstChildOfClass("Humanoid")
				if ch and ch.Health > 0 and ok(cur) then
					mob = cur
				else
					local bestR
					for _, en in ipairs(workspace.SpawnedEntities:GetChildren()) do
						local eh = en:FindFirstChildOfClass("Humanoid")
						if eh and eh.Health > 0 and eh.MaxHealth > 0 and eh.Health < eh.MaxHealth and ok(en) then
							local r = eh.Health / eh.MaxHealth
							if not bestR or r < bestR then mob, bestR = en, r end
						end
					end
					if not mob then
						local _, hrp0 = char()
						local bd
						for _, en in ipairs(workspace.SpawnedEntities:GetChildren()) do
							local eh = en:FindFirstChildOfClass("Humanoid")
							local ep = eh and eh.Health > 0 and ok(en) and mobPos(en)
							if ep and hrp0 then
								local dd = (ep - hrp0.Position).Magnitude
								if not bd or dd < bd then mob, bd = en, dd end
							end
						end
					end
					mob = mob or nearestAnyMob()
				end
				M._target = mob
			end
			local e = inst.Data.Enemies or {}
			if tower and ftype ~= "" and ftype ~= "Wave" and ftype ~= "Boss" and not mob then
				idle = 0
				if not M.solveTowerObby(inst) then
					status("Tower: " .. ftype .. " - finish not found")
					task.wait(2)
				end
			elseif mob then
				idle = 0
				local fl = inst.Data.Floor
				status(tower and ("Tower floor %s - %s/%s - %s"):format(tostring(fl and fl.Current), tostring(e.NumberOfEnemiesDefeated), tostring(e.NumberOfEnemies), mob.Name)
					or ("Dungeon %s/%s - %s"):format(tostring(e.NumberOfEnemiesDefeated), tostring(e.NumberOfEnemies), mob.Name))
				local mh = mob:FindFirstChildOfClass("Humanoid")
				local before = mh and mh.Health
				kill(mob)
				if mh and mh.Health > 0 and mob.Parent and before and mh.Health >= math.min(before, mh.MaxHealth) then
					-- not a scratch on it (it walked off, or we could not reach it): try another enemy first
					M._skipMob = M._skipMob or setmetatable({}, { __mode = "k" })
					M._skipMob[mob] = os.clock() + 30
					M._target = nil
					log(("could not hurt %s - trying another enemy first"):format(mob.Name))
				end
			else
				idle += 1
				status(tower and "Tower: waiting for the next wave..." or "Dungeon: waiting for enemies...")
				task.wait(2)
				if idle > (tower and 20 or 30) then break end
			end
		end
	end
	M._dungeonRunning = false
	release()
	if inst.Data.Failed then log("dungeon failed") end
	if tower then
		local fl = inst.Data.Floor
		log(("tower run over at floor %s%s"):format(tostring(fl and fl.Current), inst.Data.Failed and " (failed)" or ""))
	elseif inst.Data.Completed then log("dungeon cleared") end
	if inst.Data.Completed and M.openChests then pcall(M.openChests) end
	if not M.running then return end
	if M.cycle.enabled and M.cycle.mode == "dungeon" then
		M.cycle.lapLeft = math.max(0, (M.cycle.lapLeft or 0) - 1) -- this one is done (cleared or failed)
	end
	task.wait(3)
	if inBoss() then
		if inst.Data.Completed then log("boss defeated!") M._bossWins = (M._bossWins or 0) + 1 end
		if inst.Data.Failed then log("boss fight lost") M._bossLosses = (M._bossLosses or 0) + 1 end
		saveState()
		queueSelf()
		local farming = M.cycle.enabled and M.cycle.mode == "dungeon" and dungeonTimeLeft() > 0 and inst.Data.Completed
		if farming then
			status(("Boss again (%d min left)"):format(math.ceil(dungeonTimeLeft() / 60)))
			inst:FireServer("PlayAgain")
		else
			if M.cycle.enabled and M.cycle.mode == "dungeon" and dungeonTimeLeft() <= 0 then
				M.cycle.mode = "quest"
				M.cycle.phaseStart = os.time()
				saveState()
				queueSelf()
			end
			status("Boss fight over - going back")
			inst:FireServer("Return")
		end
		task.wait(20)
		return
	end
	if M.cycle.enabled and M.cycle.mode == "dungeon" then
		local left = dungeonTimeLeft()
		saveState()
		queueSelf()
		if left > 0 then
			local name, count = nextDungeonName()
			local here = type(gameInfo()._GameData.IsDungeon) == "table" and gameInfo()._GameData.IsDungeon.Name
			if name and (count or 0) > 1 and name ~= here then
				status("Next dungeon: " .. name .. " (going back first)")
				M.cycle.pending = name
				saveState()
				queueSelf()
				inst:FireServer("Return")
			else
				status(("Playing again (%d min left)"):format(math.ceil(left / 60)))
				inst:FireServer("PlayAgain")
			end
		else
			M.cycle.mode = "quest"
			M.cycle.phaseStart = os.time()
			M.cycle.pending = nil
			saveState()
			queueSelf()
			status("Dungeon time over - back to quests")
			inst:FireServer("Return")
		end
		task.wait(20)
	else
		-- a one-off run (Tower / Boss function, or started by hand): just go back to the floor
		status(tower and "Tower run over - going back" or "Run over - going back")
		saveState()
		queueSelf()
		inst:FireServer("Return")
		task.wait(20)
	end
end

----------------------------------------------------------------------
-- auto sell: when the bag is (almost) full, go to Sunshine Town and sell
-- every weapon / armor / shield that is worse than what you wear
----------------------------------------------------------------------
local SELL_FLOOR = 1
local SELL_AT = 195 -- start a trip at this many items (limit is 200)
M.sellTrip = nil

local function bagSize()
	local d = data()
	if not d then return 0, 200 end
	local info = gameInfo()
	local ok, n = pcall(function() return RF:GetInventorySize(d) end)
	return ok and n or 0, info and info._GameData.INVENTORY_LIMIT or 200
end

M.sameItem = function(a, b)
	return type(a) == "table" and type(b) == "table" and a.Name == b.Name and a.ID ~= nil and a.ID == b.ID
end

-- list of { invClass, key, item } that are worse than what is equipped
-- what is never sold: favourites (the game's lock), anything picked on Gear Goals, names on the keep list,
-- and everything at or above the "keep rarity"
M.RARITY_RANK = { Common = 1, Uncommon = 2, Rare = 3, ["Super Rare"] = 4, Legendary = 5 }
M.keepItem = function(item, cls)
	if type(item) ~= "table" then return true end
	if item.Favorite then return true end
	local G = (M.side and M.side.gear) or {}
	for _, sl in pairs(G) do if type(sl) == "table" and sl.name == item.Name then return true end end
	if (M.opt.keepNames or {})[item.Name] then return true end
	local keepAt = M.RARITY_RANK[M.opt.keepRarity or "Legendary"] or 99
	local info = gameInfo() or {}
	local it = (info[cls] or {})[item.Name]
	local r = it and M.RARITY_RANK[it.Rarity] or 0
	return r >= keepAt
end
M.junkList = function()
	local d = data()
	if not d then return {} end
	local inv, eq = d.Data.Inventory, d.Data.Equipped
	local out = {}
	local wScore = M.weaponScore(M.itemStats(eq.Hands and eq.Hands[1], "Weapons"))
	for key, item in pairs(inv.Weapons or {}) do
		if not M.keepItem(item, "Weapons") and not M.sameItem(item, eq.Hands and eq.Hands[1]) and not M.sameItem(item, eq.Hands and eq.Hands[2]) then
			local sc = M.weaponScore(M.itemStats(item, "Weapons"))
			if sc >= 0 and sc < wScore then out[#out + 1] = { "Weapons", key, item } end
		end
	end
	local aScore = M.armorScore(M.itemStats(eq.Armor, "Armor"))
	for key, item in pairs(inv.Armor or {}) do
		if not M.keepItem(item, "Armor") and not M.sameItem(item, eq.Armor) then
			local sc = M.armorScore(M.itemStats(item, "Armor"))
			if sc >= 0 and sc < aScore then out[#out + 1] = { "Armor", key, item } end
		end
	end
	-- shields only when you actually use one
	local sh = eq.Hands and type(eq.Hands[2]) == "table" and eq.Hands[2].Class == "Shield" and eq.Hands[2]
	if sh then
		local sScore = M.armorScore(M.itemStats(sh, "Shields"))
		for key, item in pairs(inv.Shields or {}) do
			if not M.keepItem(item, "Shields") and not M.sameItem(item, sh) then
				local sc = M.armorScore(M.itemStats(item, "Shields"))
				if sc >= 0 and sc < sScore then out[#out + 1] = { "Shields", key, item } end
			end
		end
	end
	return out
end
M.JunkList = M.junkList

M.findMerchant = function()
	local npcs = workspace:FindFirstChild("NPCs")
	if not npcs then return end
	local fallback
	for _, n in ipairs(npcs:GetChildren()) do
		for _, d in ipairs(n:GetDescendants()) do
			local v = (d:IsA("StringValue") and d.Value:lower()) or ""
			-- Sunshine Town: Legosan "I'm a merchant. I'll buy anything useful from you"
			if v:find("merchant") or v:find("here to sell") or v:find("sellitemframe") or d.Name == "SellItemFrame" then return n end
		end
		local nm = n.Name:lower()
		if nm:find("merchant") or nm:find("sell") or nm:find("shop") or nm:find("trader") then fallback = fallback or n end
	end
	return fallback
end

M.goSell = function(back)
	if M.findMerchant() then -- e.g. Saurtha in the Desert of Death: no trip needed
		M.sellTrip = { back = currentFloor(), t = os.time(), here = true }
		log("bag full, selling to the merchant on this floor")
		return
	end
	M.sellTrip = { back = back or currentFloor() or 2, t = os.time() }
	saveState()
	queueSelf()
	release()
	status("Bag full - going to Sunshine Town to sell")
	log("bag full, travelling to Sunshine Town to sell")
	data():FireServer("Teleport", { FloorNumber = SELL_FLOOR })
	task.wait(20)
end
M.SellNow = function() task.spawn(M.goSell, currentFloor()) end

-- on the town floor with a pending trip: sell, then go back
M.doSellHere = function()
	local merchant = M.findMerchant()
	local sold, before = 0, select(1, bagSize())
	if not merchant then
		log("merchant not found in town")
	else
		status("Selling to " .. merchant.Name)
		fly(merchant:GetPivot().Position + merchant:GetPivot().LookVector * 5, 4, 120)
		release()
		task.wait(1)
		local d = data()
		-- bag keys shift after every sale, so re-read the list each time and wait for the item to be gone
		for _ = 1, 250 do
			if not M.running then break end
			local j = M.junkList()[1]
			if not j then break end
			local n0 = select(1, bagSize())
			local okSale = false
			for try = 1, 3 do
				d:FireServer("SellItem", { SelectedItem = j })
				local t0 = os.clock()
				repeat task.wait(0.1) until select(1, bagSize()) < n0 or os.clock() - t0 > 2.5
				if select(1, bagSize()) < n0 then okSale = true break end
				-- maybe too far or too fast: step next to the merchant again and wait a bit
				local _, hrp = char()
				if hrp and (hrp.Position - merchant:GetPivot().Position).Magnitude > 12 then
					fly(merchant:GetPivot().Position + merchant:GetPivot().LookVector * 5, 4, 20)
					release()
				end
				task.wait(1)
			end
			if not okSale then log("merchant stopped buying (" .. tostring(j[3].Name) .. ")") break end
			sold += 1
			task.wait(0.4)
		end
	end
	local after = select(1, bagSize())
	log(("sold %d items (bag %d -> %d)"):format(before - after, before, after))
	if before - after <= 0 and sold > 0 then log("selling did not work here") end
	local back = M.sellTrip and M.sellTrip.back or 2
	M.sellTrip = nil
	M._sellCooldown = os.time() + 1800 * ((before - after <= 0) and 1 or 0)
	saveState()
	queueSelf()
	if back == currentFloor() then return end -- sold on our own floor
	status("Going back to floor " .. back)
	data():FireServer("Teleport", { FloorNumber = back })
	task.wait(20)
end

-- returns true when it took over this scheduler pass
local function sellTick()
	if M.sellTrip then
		if M.sellTrip.here or currentFloor() == SELL_FLOOR then
			M.doSellHere()
		elseif os.time() - (M.sellTrip.t or 0) > 120 then
			M.sellTrip = nil -- teleport never happened
			saveState()
			return false
		else
			task.wait(2)
		end
		return true
	end
	if not M.opt.autoSell or os.time() < (M._sellCooldown or 0) then return false end
	local n, limit = bagSize()
	if n >= math.min(SELL_AT, limit - 5) then
		local junk = #M.junkList()
		if junk == 0 then
			M._sellCooldown = os.time() + 1800
			log("bag full but nothing worse than your gear to sell")
			return false
		end
		M.goSell(currentFloor())
		return true
	end
	return false
end

----------------------------------------------------------------------
-- items: upgrade what you wear, open dungeon chests, craft better gear
----------------------------------------------------------------------
local UCF = require(RS.Modules.UpgradeCrystalFunctions)

-- cost of one upgrade step for an item: crystal name, crystal amount, coins
M.upgradeCost = function(item)
	local lvl = item.Leveling and item.Leveling.Level or 1
	local okc, cname, camt = pcall(function() return UCF:GetUpgradeCrystalRequirement(lvl) end)
	local okp, coins = pcall(function() return UCF:CalculateUpgradeCost(item.Name, lvl, gameInfo()) end)
	return okc and cname or nil, okc and camt or 0, okp and coins or math.huge
end

M.canUpgrade = function(item, d)
	local myLevel = d.Data.Leveling.Level or 1
	local lvl = item.Leveling and item.Leveling.Level or 1
	if lvl >= myLevel then return false, "item is already at your level" end
	local cname, camt, coins = M.upgradeCost(item)
	if not cname then return false, "max level" end
	local have = (d.Data.Inventory.Materials or {})[cname] or 0
	if have < camt then return false, ("needs %d %s (have %d)"):format(camt, cname, have) end
	if (d.Data.Currencies.Coins or 0) - coins < (M.opt.keepCoins or 2000) then return false, "not enough coins" end
	return true
end

-- the game only upgrades items in the bag, and a weapon can't be taken off, only swapped:
-- put on a spare, upgrade the real one, put it back on
M.upgradeSlot = function(invClass)
	local d = data()
	if not d then return 0 end
	local eq, inv = d.Data.Equipped, d.Data.Inventory[invClass]
	local worn = invClass == "Weapons" and eq.Hands and eq.Hands[1] or eq.Armor
	if type(worn) ~= "table" or type(inv) ~= "table" then return 0 end
	if not M.canUpgrade(worn, d) then return 0 end
	local myLevel = d.Data.Leveling.Level or 1
	local spareK, spare
	for k, it in pairs(inv) do
		if ((it.Leveling and it.Leveling.Level) or 1) <= myLevel and (invClass ~= "Weapons" or it.Class == worn.Class) then spareK, spare = k, it break end
	end
	if not spare then
		for k, it in pairs(inv) do
			if ((it.Leveling and it.Leveling.Level) or 1) <= myLevel then spareK, spare = k, it break end
		end
	end
	if not spare then return 0 end
	local name, lvl0 = worn.Name, worn.Leveling.Level
	local before = {}
	for k in pairs(inv) do before[k] = true end
	local function equip(k, it)
		if invClass == "Weapons" then d:FireServer("Equip", { SelectedItem = { "Weapons", k, it }, Hand = 1 })
		else d:FireServer("Equip", { SelectedItem = { "Armor", k, it } }) end
		task.wait(1.2)
	end
	equip(spareK, spare)
	-- the item we took off is now somewhere in the bag
	local function findReal()
		for k, it in pairs(d.Data.Inventory[invClass]) do
			if it.Name == name and it.Leveling and it.Leveling.Level >= lvl0 and (not before[k] or it ~= spare) and it ~= spare then
				if not before[k] or it.Leveling.Level > lvl0 then return k, it end
			end
		end
		for k, it in pairs(d.Data.Inventory[invClass]) do
			if it.Name == name and it.Leveling and it.Leveling.Level == lvl0 and it ~= spare then return k, it end
		end
	end
	local k, it = findReal()
	local steps = 0
	if k then
		for _ = 1, (M.opt.upgradeSteps or 5) do
			if not M.canUpgrade(it, d) then break end
			local l = it.Leveling.Level
			d:FireServer("UpgradeItem", { SelectedItem = { invClass, k, it } })
			local t0 = os.clock()
			repeat
				task.wait(0.2)
				k, it = nil, nil
				for kk, x in pairs(d.Data.Inventory[invClass]) do
					if x.Name == name and x.Leveling and x.Leveling.Level == l + 1 then k, it = kk, x break end
				end
			until it or os.clock() - t0 > 3
			if not it then
				for kk, x in pairs(d.Data.Inventory[invClass]) do
					if x.Name == name and x.Leveling and x.Leveling.Level == l then k, it = kk, x break end
				end
				break
			end
			steps += 1
		end
	end
	-- put the real item back on, and make sure it really is on
	local want = lvl0 + steps
	for _ = 1, 4 do
		task.wait(1)
		local now = invClass == "Weapons" and d.Data.Equipped.Hands[1] or d.Data.Equipped.Armor
		if type(now) == "table" and now.Name == name and now.Leveling.Level == want then break end
		local fk, fit
		for kk, x in pairs(d.Data.Inventory[invClass]) do
			if x.Name == name and x.Leveling and x.Leveling.Level == want then fk, fit = kk, x break end
		end
		if fit then equip(fk, fit) end
	end
	if steps > 0 then log(("upgraded %s: level %d -> %d"):format(name, lvl0, lvl0 + steps)) end
	return steps
end

M.upgradeGear = function()
	if not M.opt.upgrade or os.clock() < (M._nextUpgrade or 0) then return end
	M._nextUpgrade = os.clock() + 120
	local d = data()
	if not d then return end
	local G = (M.side and M.side.gear) or {}
	for _, cls in ipairs({ "Weapons", "Armor" }) do
		local worn = cls == "Weapons" and d.Data.Equipped.Hands[1] or d.Data.Equipped.Armor
		local goal = cls == "Weapons" and G.w1 or G.armor
		if type(worn) == "table" and not (goal and goal.name) and M.canUpgrade(worn, d) then
			status("Upgrading " .. worn.Name)
			M.upgradeSlot(cls)
		end
	end
end

-- chests that appear in a cleared dungeon
M.openChests = function()
	if not M.opt.chests then return end
	local opened = 0
	for _, r in pairs(RC._replicas) do
		if r.Class == "Chest" and r.Data and r.Data.Spawned and r.Data.Available ~= false then
			local pv = r.Tags and r.Tags.ModelPivot
			local pos = typeof(pv) == "CFrame" and pv.Position or (typeof(pv) == "Vector3" and pv) or nil
			if pos then
				status("Opening a chest")
				fly(pos + Vector3.new(0, 3, 0), 5, 40)
			end
			pcall(function() r:FireServer("Open") end)
			task.wait(1.2)
			opened += 1
		end
	end
	release()
	if opened > 0 then log(("opened %d chest(s)"):format(opened)) end
end

-- craft a weapon / armor that beats what you wear, when you already own every material
M.craftBetter = function()
	if not M.opt.craft or os.clock() < (M._nextCraft or 0) then return end
	M._nextCraft = os.clock() + 300
	local d, info = data(), gameInfo()
	if not d or not info then return end
	local myLevel = d.Data.Leveling.Level or 1
	local mats, coins = d.Data.Inventory.Materials or {}, d.Data.Currencies.Coins or 0
	local eq = d.Data.Equipped
	local wScore = M.weaponScore(M.itemStats(eq.Hands and eq.Hands[1], "Weapons"))
	local aScore = M.armorScore(M.itemStats(eq.Armor, "Armor"))
	local wClass = type(eq.Hands[1]) == "table" and eq.Hands[1].Class
	local best, bestGain, bestKind
	for name, rc in pairs(info.Recipes or {}) do
		local lvl = tonumber(rc.Level) or 1
		local req = rc.Requirements or {}
		if lvl <= myLevel and coins - (tonumber(req.Coins) or 0) >= (M.opt.keepCoins or 2000) then
			local ok = true
			for m, n in pairs(req.Materials or {}) do if (mats[m] or 0) < n then ok = false break end end
			if ok then
				local wdef, adef = info.Weapons and info.Weapons[name], info.Armor and info.Armor[name]
				local fake = { Name = name, Leveling = { Level = lvl }, Substats = {}, Class = wdef and wdef.Class or "Armor" }
				if wdef and wdef.Class == wClass then
					local gain = M.weaponScore(M.itemStats(fake, "Weapons")) - wScore
					if gain > 0 and (not bestGain or gain > bestGain) then best, bestGain, bestKind = name, gain, "weapon" end
				elseif adef then
					local gain = (M.armorScore(M.itemStats(fake, "Armor")) - aScore) / 10
					if gain > 0 and (not bestGain or gain > bestGain) then best, bestGain, bestKind = name, gain, "armor" end
				end
			end
		end
	end
	if best then
		local n0 = select(1, bagSize())
		d:FireServer("Craft", { CraftableItem = best })
		task.wait(1.5)
		if select(1, bagSize()) > n0 then
			log(("crafted %s (%s, better than yours)"):format(best, bestKind))
			M._nextGear = 0 -- put it on right away
			M._nextCraft = os.clock() + 30
		else
			log("craft of " .. best .. " did not go through")
		end
	end
end

----------------------------------------------------------------------
-- home map: when entering the game on another map, travel to the chosen one
----------------------------------------------------------------------
M.floorList = function()
	local info, d = gameInfo(), data()
	local out = {}
	local unlocked = d and tonumber(d.Data.Attributes and d.Data.Attributes.Floor) or 1
	local level = d and d.Data.Leveling.Level or 1
	for i, f in ipairs(info and info.Floors or {}) do
		out[#out + 1] = { n = i, name = f.Name, need = tonumber(f.Level) or 0, ok = i <= unlocked and level >= (tonumber(f.Level) or 0) }
	end
	return out
end

M.travelTo = function(n, why)
	local d = data()
	if not d or not n or n <= 0 then return false end
	local f
	for _, x in ipairs(M.floorList()) do if x.n == n then f = x end end
	if not f then return false end
	if not f.ok then log(("can't travel to %s yet (needs level %d and its boss beaten)"):format(f.name, f.need)) return false end
	if currentFloor() == n then return false end
	log(("travelling to %s%s"):format(f.name, why and (" (" .. why .. ")") or ""))
	status("Travelling to " .. f.name)
	saveState()
	queueSelf()
	release()
	d:FireServer("Teleport", { FloorNumber = n })
	return true
end

-- TP points are per map: visit every map you can reach that still has locked TP points
-- (or that was never visited), unlock them there, then go back to the home map
M.tpTourTick = function()
	if not M.on.unlock or M.sellTrip or inDungeon() then return false end
	local cur = currentFloor()
	if not cur then return false end
	local sd = M.side
	sd.tpTotal = sd.tpTotal or {}
	sd.tpVisits = sd.tpVisits or {}
	local open, all = tpCount()
	if all == 0 then
		if os.clock() - (M._loadedAt or 0) < 30 then
			if sd.tpTrip then status("TP tour: waiting for this map's points to load") task.wait(2) return true end
			return false
		end
		sd.tpTotal[tostring(cur)] = 0
	else
		-- far points may not be loaded yet (streaming): the count only goes up, never down
		local dd = data()
		local saved = 0
		for _ in pairs(dd and dd.Data.FloorRespawnPoints and dd.Data.FloorRespawnPoints[tostring(cur)] or {}) do saved += 1 end
		sd.tpTotal[tostring(cur)] = math.max(all, saved, sd.tpTotal[tostring(cur)] or 0)
	end
	-- still points to do here (ones that failed wait 10 min; after 2 visits a map counts as done)
	local waiting = 0
	for _, rp in ipairs(rpParts()) do
		if not isUnlocked(rp.id) and (skipUntil["tp" .. rp.id] or 0) > os.clock() then waiting += 1 end
	end
	if open + waiting < all then return false end -- unlockAll keeps going here first
	local d = data()
	local frp = d and d.Data.FloorRespawnPoints or {}
	for _, f in ipairs(M.floorList()) do
		local key = tostring(f.n)
		if f.ok and f.n ~= cur and (sd.tpVisits[key] or 0) < 2 then
			local have = 0
			for _ in pairs(frp[key] or {}) do have += 1 end
			local total = sd.tpTotal[key]
			if not total or have < total then
				sd.tpVisits[key] = (sd.tpVisits[key] or 0) + 1
				sd.tpTrip = os.time()
				saveState()
				if M.travelTo(f.n, ("unlock TP points: %d/%s there"):format(have, total and tostring(total) or "?")) then
					task.wait(20)
					return true
				end
			end
		end
	end
	if sd.tpTrip then
		sd.tpTrip = nil
		log("TP points: every map you can reach is done")
		saveState()
		pcall(M.goHome)
	end
	return false
end

-- which map has the Tower (only one does)
M.towerFloor = function()
	local info = gameInfo()
	for _, tw in pairs(info and info.Towers or {}) do
		if tonumber(tw.Floor) then return tonumber(tw.Floor) end
	end
end
-- arrived on the Tower map because of a Tower trip: go straight in
M.instFloor = function(name)
	local info = gameInfo() or {}
	if name:sub(1, 5) == "BOSS:" then local b = (info.Bosses or {})[name:sub(6)] return b and tonumber(b.Floor) end
	if not name:find(":") then local dg = (info.Dungeons or {})[name] return dg and tonumber(dg.Floor) end
	local t = name:sub(1, 5) == "CATA:" and info.Catacombs or name:sub(1, 6) == "ARENA:" and info.BattleArenas or name:sub(1, 6) == "ETHER:" and info.Ethers or nil
	local key = name:match("^%u+:(.+)$")
	local x = t and key and t[key]
	return x and tonumber(x.Floor)
end
M.towerTripTick = function()
	-- arrived on the Catacombs map because of a Catacombs trip: go straight in
	local c = M.side.cataTrip
	if c then
		if os.time() - c > 300 then M.side.cataTrip = nil
		else
			local name = M.side.cataName
			local fl = name and M.instFloor(name)
			if fl and currentFloor() == fl then enterDungeon(name) return true end
		end
	end
	local t = M.side.towerTrip
	if not t then return false end
	if os.time() - t > 300 then M.side.towerTrip = nil return false end
	if currentFloor() == M.towerFloor() and not M.side.towerDone then
		enterDungeon("TOWER:Tower")
		return true
	end
	return false
end

-- daily bosses: one fight per boss per day, on every map you can enter. The "day" starts at the hour you set.
M.dailyDay = function()
	return os.date("%Y-%m-%d", os.time() - (tonumber(M.side.dailyHour) or 0) * 3600)
end
M.dailyNext = function()
	local info = gameInfo()
	local day = M.dailyDay()
	M.prio.daily = M.prio.daily or {}
	local ok = {}
	for _, f in ipairs(M.floorList()) do ok[f.n] = f.ok end
	local best, bestFloor
	for name, b in pairs(info and info.DailyBosses or {}) do
		local fl = tonumber(b.Floor)
		if fl and ok[fl] and M.prio.daily["DAILY:" .. name] ~= day then
			if not bestFloor or fl < bestFloor then best, bestFloor = name, fl end
		end
	end
	return best, bestFloor
end
-- go to the next daily boss that is still open today; true = it took over this pass
M.dailyGo = function()
	if M.sellTrip then return false end
	local name, fl = M.dailyNext()
	if not name then return false end
	if currentFloor() ~= fl then
		M.side.dailyTrip = os.time()
		saveState()
		if not M.travelTo(fl, "daily boss " .. name) then
			M.prio.daily["DAILY:" .. name] = M.dailyDay() -- can't get there today
			M.side.dailyTrip = nil
			return false
		end
		task.wait(20)
		return true
	end
	M.side.dailyTrip = nil
	M.prio.daily["DAILY:" .. name] = M.dailyDay()
	log(("daily boss: %s"):format(name))
	saveState()
	enterDungeon("DAILY:" .. name)
	return true
end

-- the home map: a fixed map, or -1 = the highest map you can enter right now
M.homeTarget = function()
	local n = tonumber(M.opt.homeFloor) or 0
	if n == -1 then
		local best = 0
		for _, f in ipairs(M.floorList()) do if f.ok and f.n > best then best = f.n end end
		return best
	end
	return n
end
M.goHome = function()
	local n = M.homeTarget()
	if n <= 0 or M.sellTrip or inDungeon() then return end
	if M.side.towerTrip and os.time() - M.side.towerTrip < 300 then return end
	if M.side.cataTrip and os.time() - M.side.cataTrip < 300 then return end -- on the way to the Catacombs
	if M.side.tpTrip and os.time() - M.side.tpTrip < 600 then return end -- TP point tour
	if M.side.scanTrip and os.time() - M.side.scanTrip < 300 then return end -- reading monster drops on every map
	if M.questTripHold() then return end -- on a quest trip: stay
	-- farming gear drops / crystals on this map: stay until that is done
	if M.prio.enabled and (M.prio.on.gear or M.gearMode() == "upgrade") and M.side.gearFarmFloor == currentFloor() and os.time() - (M.side.gearFarmAt or 0) < 1800 then return end
	-- in the middle of the daily boss tour: go straight to the next boss map, home comes after the last one
	if (M.side.daily or (M.prio.enabled and M.prio.on.daily)) and M.dailyNext() then return end
	local cur = currentFloor()
	if cur and cur ~= n then M.travelTo(n, "home map") end
end

----------------------------------------------------------------------
-- next floor: beat this floor's boss when strong enough, then travel up
----------------------------------------------------------------------
M._lastBossTry = -math.huge -- os.clock() starts near 0 after a restart

local function floorInfo()
	local info, d = gameInfo(), data()
	if not info or not d then return end
	local cur = currentFloor()
	if not cur then return end
	local nextN = cur + 1
	local nf = info.Floors and info.Floors[nextN]
	local unlocked = tonumber(d.Data.Attributes and d.Data.Attributes.Floor) or cur
	local level = tonumber(d.Data.Leveling and d.Data.Leveling.Level) or 0
	local bossName
	for name, b in pairs(info.Bosses or {}) do
		local u = b.UnlocksFloor
		local max = typeof(u) == "NumberRange" and u.Max or type(u) == "table" and (u.Max or u[2] or u[1]) or u
		if tonumber(max) == nextN then bossName = name end
	end
	return { cur = cur, nextN = nextN, nextName = nf and nf.Name, needLevel = nf and tonumber(nf.Level) or 0,
		unlocked = unlocked, level = level, boss = bossName, exists = nf ~= nil }
end
M.FloorInfo = floorInfo
M.EnterBoss = function() return enterBoss() end

enterBoss = function()
	local d = data()
	if not d then return false end
	local pos
	for _, p in ipairs(CS:GetTagged("BossPad")) do
		local bp = p:IsA("BasePart") and p or p:FindFirstChildWhichIsA("BasePart", true)
		if bp then pos = bp.Position break end
		-- far away the gate's parts are not loaded yet, but the model still knows where it is
		local ok, pv = pcall(function() return p:GetPivot().Position end)
		if ok and pv.Magnitude > 1 then pos = pv break end
	end
	if pos then
		status("Flying to the boss gate")
		fly(pos + Vector3.new(0, 3, 0), 6, 90)
	else
		log("boss gate position unknown - trying to enter from here")
	end
	local place0 = game.PlaceId
	saveState()
	queueSelf()
	release()
	d:FireServer("EnterBoss")
	task.wait(3)
	for _, r in pairs(RC._replicas) do
		if r.Class == "Boss" and r.Data.Players and r.Data.Players[1] == lp then pcall(function() r:FireServer("Enter") end) end
	end
	task.wait(15)
	log("boss entry did not teleport") -- still here after 18 s
	return false
end

local function progressTick()
	if not M.opt.nextFloor or M.sellTrip then return end
	-- on a trip (daily boss tour / Tower): don't climb maps from wherever the trip passes through
	if M.side.towerTrip and os.time() - M.side.towerTrip < 300 then return end
	if M.side.cataTrip and os.time() - M.side.cataTrip < 300 then return end -- on the way to the Catacombs
	if M.side.tpTrip and os.time() - M.side.tpTrip < 600 then return end -- TP point tour
	if M.side.scanTrip and os.time() - M.side.scanTrip < 300 then return end -- reading monster drops on every map
	if M.questTripHold() then return end -- on a quest trip: stay
	if (M.side.daily or (M.prio.enabled and M.prio.on.daily)) and M.dailyNext() then return end
	local f = floorInfo()
	if f and f.cur == 1 and (f.unlocked or 1) > 1 then return end -- town: the sell trip handles going back
	if not f or not f.exists then return end
	if M.prio.enabled and (M.prio.on.gear or M.gearMode() == "upgrade") and M.side.gearFarmFloor == f.cur and os.time() - (M.side.gearFarmAt or 0) < 1800 then return end -- farming gear here
	if f.unlocked >= f.nextN then
		if f.level >= f.needLevel then
			-- already unlocked further up: go straight to the highest map you can enter
			for _, x in ipairs(M.floorList()) do
				if x.ok and x.n > f.nextN then f.nextN, f.nextName = x.n, x.name end
			end
			status(("Going to floor %d: %s"):format(f.nextN, tostring(f.nextName)))
			log(("travelling to floor %d (%s)"):format(f.nextN, tostring(f.nextName)))
			if (tonumber(M.opt.homeFloor) or 0) > 0 then M.opt.homeFloor = f.nextN end -- a fixed home follows you up (-1 = best floor already does)
			turnInAll() -- hand in this floor's finished quests first (the boss quest can't be handed in from the next floor)
			task.wait(1)
			M.cycle.dungeons = {} -- pick dungeons again on the new floor
			M.cycle.idx = 0
			saveState()
			queueSelf()
			release()
			local dd = data()
			if not dd then return false end -- already on the way somewhere (data is gone mid-teleport)
			dd:FireServer("Teleport", { FloorNumber = f.nextN })
			task.wait(20)
			return true
		end
	elseif f.boss and f.level >= f.needLevel and os.clock() - M._lastBossTry > 600 then
		M._lastBossTry = os.clock()
		log(("trying boss %s to unlock floor %d"):format(f.boss, f.nextN))
		enterBoss()
		return true
	end
end

----------------------------------------------------------------------
-- per-floor housekeeping: quests from another floor, item orbs
----------------------------------------------------------------------
-- quests belong to one floor: one whose NPC isn't on this map can never progress here and only
-- blocks one of the 4 quest slots -> drop it (it can be taken again on its own floor)
M.dropForeignQuests = function()
	if not M.opt.dropForeign then return end
	-- only passing through this map (TP tour, daily boss, Tower, selling): keep the quests of the home map
	local sd = M.side
	local now = os.time()
	if (sd.tpTrip and now - sd.tpTrip < 600) or (sd.dailyTrip and now - sd.dailyTrip < 600)
		or (sd.towerTrip and now - sd.towerTrip < 300) or (sd.cataTrip and now - sd.cataTrip < 300) or M.sellTrip then return end
	local home = M.homeTarget()
	if home > 0 and currentFloor() ~= home then return end
	if os.clock() < (M._nextForeign or 0) then return end
	M._nextForeign = os.clock() + 60
	local d = data()
	local npcs = workspace:FindFirstChild("NPCs")
	if not d or not npcs or #npcs:GetChildren() < 3 then return end
	local ids, names = {}, {}
	for _, n in ipairs(npcs:GetChildren()) do
		names[n.Name] = true
		local ni = n:FindFirstChild("NPCInfo")
		local id = ni and ni:GetAttribute("ID")
		if id then ids[id] = true end
	end
	local list = quests()
	for i = #list, 1, -1 do
		local q = list[i]
		if not ids[q.ID] and not (q.NPCName and names[q.NPCName]) then
			log(("dropping quest from another floor: %s"):format(tostring(q.Title or q.ID)))
			d:FireServer("AbandonQuest", { QuestIndex = i })
			task.wait(0.6)
		end
	end
end

-- item orbs lying around the map (abilities etc.): fly there and pick them up
M.collectOrbs = function()
	if not M.opt.orbs then return end
	local d = data()
	if not d then return end
	local got = d.Data.Attributes and d.Data.Attributes.CollectedItemOrbs or {}
	for _, orb in ipairs(CS:GetTagged("ItemOrb")) do
		if not M.running then return end
		local id = orb:GetAttribute("Id")
		if id and not got[id] and (skipUntil["orb" .. id] or 0) < os.clock() then
			local okp, pos = pcall(function() return orb:GetPivot().Position end)
			if okp then
				status("Collecting item orb: " .. tostring(orb:GetAttribute("Name") or id))
				fly(pos + Vector3.new(0, 2, 0), 4, 120)
				local _, hrp = char()
				if hrp then
					pcall(function() hrp.CFrame = CFrame.new(pos) end)
					for _, x in ipairs(orb:GetDescendants()) do
						if x:IsA("ProximityPrompt") then pcall(fireproximityprompt, x) end
						if x:IsA("TouchTransmitter") and x.Parent then
							pcall(function() firetouchinterest(hrp, x.Parent, 0) task.wait(0.05) firetouchinterest(hrp, x.Parent, 1) end)
						end
					end
				end
				task.wait(2)
				release()
				if (d.Data.Attributes.CollectedItemOrbs or {})[id] then
					log("collected item orb: " .. tostring(orb:GetAttribute("Name") or id))
				else
					skipUntil["orb" .. id] = os.clock() + 1800
					log("could not collect orb " .. tostring(orb:GetAttribute("Name") or id))
				end
			end
		end
	end
end

----------------------------------------------------------------------
-- Tower function / Boss function: own switches, each runs every N minutes
----------------------------------------------------------------------
M.side = M.side or { per = { tower = 10, cata = 10, arena = 5 }, towerGoal = 700, towerBest = 0, tower = false, towerEvery = 30, nextTower = 0, boss = false, bossEvery = 30, nextBoss = 0, bossPick = {}, bossIdx = 0 }

M.bossKeys = function(floor)
	local out = {}
	for _, k in ipairs(dungeonsForFloor(floor or currentFloor() or M.cycle.floor or 2)) do
		if k:sub(1, 5) == "BOSS:" or k:sub(1, 6) == "DAILY:" then out[#out + 1] = k end
	end
	return out
end

-- bounty: a marked monster that shows up on the map now and then; first come first served
M.findBounty = function()
	local se = workspace:FindFirstChild("SpawnedEntities")
	for _, e in ipairs(se and se:GetChildren() or {}) do
		if e:GetAttribute("Bounty") then
			local h = e:FindFirstChildOfClass("Humanoid")
			if h and h.Health > 0 and mobPos(e) then return e end
		end
	end
end
-- a bounty is up on this map (and not given up on): long jobs stop early so it gets done first
M.bountyWaiting = function()
	if not M.opt.bounty or M.sellTrip or inDungeon() then return false end
	local mob = M.findBounty()
	return mob ~= nil and ((M._bountySkip and M._bountySkip[mob]) or 0) <= os.clock()
end
M.bountyTick = function()
	if not M.opt.bounty or M.sellTrip or inDungeon() then return false end
	local mob = M.findBounty()
	if not mob then return false end
	M._bountySkip = M._bountySkip or setmetatable({}, { __mode = "k" })
	if (M._bountySkip[mob] or 0) > os.clock() then return false end
	local h = mob:FindFirstChildOfClass("Humanoid")
	log(("bounty: %s (%d HP)"):format(mob.Name, h and h.MaxHealth or 0))
	status("Bounty: " .. mob.Name)
	local p = mobPos(mob)
	if p then warpToward(p) end
	pcall(kill, mob, true)
	release()
	h = mob.Parent and mob:FindFirstChildOfClass("Humanoid")
	if h and h.Health > 0 then
		M._bountySkip[mob] = os.clock() + 600
		log("bounty: could not kill " .. mob.Name .. ", trying again in 10 min")
	else
		M._bountyKills = (M._bountyKills or 0) + 1
		log("bounty: " .. mob.Name .. " is dead")
	end
	return true
end

M.sideTick = function()
	if M.sellTrip then return false end
	local sd = M.side
	if sd.towerRepeat then sd.towerDone = false end
	if sd.tower and not sd.towerDone and os.time() >= (sd.nextTower or 0) then
		sd.nextTower = os.time() + math.max(1, sd.towerEvery or 30) * 60
		enterDungeon("TOWER:Tower")
		return true
	end
	if sd.daily and M.dailyGo() then return true end
	if sd.boss and os.time() >= (sd.nextBoss or 0) then
		local picks = {}
		for _, k in ipairs(M.bossKeys()) do if k:sub(1, 5) == "BOSS:" then picks[#picks + 1] = k end end -- one boss per map
		if #picks > 0 then
			sd.bossIdx = ((sd.bossIdx or 0) % #picks) + 1
			sd.nextBoss = os.time() + math.max(1, sd.bossEvery or 30) * 60
			enterDungeon(picks[sd.bossIdx])
			return true
		end
	end
	return false
end

-- called every scheduler pass while on a floor
local function cycleTick()
	if not M.cycle.enabled then return end
	M.cycle.floor = currentFloor() or M.cycle.floor
	if M.cycle.pending then
		local name = M.cycle.pending
		M.cycle.pending = nil
		enterDungeon(name)
		return
	end
	local elapsed = os.time() - (M.cycle.phaseStart or 0)
	if M.cycle.mode == "quest" then
		local trig = M.cycle.trigger or "time"
		local ready
		if trig == "finish" then
			ready = elapsed >= M.cycle.questMin * 60 and not M.focus -- time is up and the current quest is done
			if elapsed >= M.cycle.questMin * 60 and M.focus then status("Time is up - finishing this quest first") end
		elseif trig == "alldone" then
			-- clear EVERY quest on the map first (they give a lot of EXP):
			-- hand in, try every NPC for new quests, and only go when none is left to do
			ready = false
			if M._noQuestWork then
				turnInAll()
				lastAccept = -math.huge
				acceptAll()
				turnInAll()
				local doable = 0
				local now = os.clock()
				for _, q in ipairs(quests()) do
					-- a quest only paused for 2 min still counts; only ones that failed twice (paused 30 min) are given up
					-- every quest still counts unless its mob was judged too strong (died 3x on a one-mob quest, etc.)
					local gave = M.gaveUp and M.gaveUp[q.ID] and os.time() - M.gaveUp[q.ID] < 1800
					if (q.Objective == "Kill" or q.Objective == "Find" or q.Objective == "TalkTo") and not gave then doable += 1 end
				end
				if doable == 0 and (M._lastAcceptGained or 0) == 0 then
					ready = true
					log("all quests on this map cleared - going to the dungeon")
				else
					M._noQuestWork = false
				end
			end
		else
			ready = elapsed >= M.cycle.questMin * 60
		end
		if ready then
			local name, count = nextDungeonName()
			if name then
				M.cycle.lapLeft = count or 1
				M.cycle.mode = "dungeon"
				M.cycle.phaseStart = os.time()
				enterDungeon(name)
			else
				status("Dungeon cycle: no dungeon selected")
			end
		end
	elseif M.cycle.mode == "dungeon" then
		if dungeonTimeLeft() > 0 then
			enterDungeon(nextDungeonName())
		else
			M.cycle.mode = "quest"
			M.cycle.phaseStart = os.time()
			saveState()
		end
	end
end

local LABELS = {
	stats = "Auto stats", gear = "Best gear + skills",
	unlock = "Unlock all TP", turnin = "Turn in quests", accept = "Accept quests",
	kill = "Kill quests", find = "Find quests", talk = "Talk quests",
}
local KIND = { kill = "Kill", find = "Find", talk = "TalkTo" }
M.on = { stats = false, gear = false, unlock = false, turnin = false, accept = false, kill = false, find = false, talk = false }
M.isOn = function(kind) -- used by the fight loop to abort when Kill is switched off
	for k, v in pairs(KIND) do if v == kind then return M.on[k] end end
	return true
end

local function anyOn()
	if M.cycle.enabled or M.opt.nextFloor or M.opt.autoSell or M.sellTrip or (M.side and (M.side.tower or M.side.boss or M.side.daily)) or (M.prio and M.prio.enabled) then return true end
	for _, v in pairs(M.on) do if v then return true end end
	return false
end

local taskButtons = {} -- name -> paint function
local function repaintTasks()
	for _, paint in pairs(taskButtons) do paint() end
end

local function questById(id)
	for i, q in ipairs(quests()) do
		if q.ID == id then return q, i end
	end
end

local function switchFor(objective)
	for name, k in pairs(KIND) do
		if k == objective then return M.on[name] and name or nil end
	end
end

local function questTitle(q)
	return tostring(q.Title or q.ID)
end

-- finish ONE quest at a time: stay on it until it's done, hand it in, take new ones, then pick the next
local function doOneQuest()
	local now = os.clock()
	local q, index
	if M.focus then
		q, index = questById(M.focus)
		if not q or q.Objective == "Return" or (skipUntil[q.ID] or 0) >= now or not switchFor(q.Objective) then
			q = nil
		end
	end
	if not q then
		M.focus = nil
		-- start with the quest that is closest to done
		local bestR
		for i, cand in ipairs(quests()) do
			if cand.Objective ~= "Return" and switchFor(cand.Objective) and (skipUntil[cand.ID] or 0) < now then
				local r = (tonumber(cand.Progress) or 0) / math.max(1, tonumber(cand.Amount) or 1)
				if not bestR or r > bestR then q, index, bestR = cand, i, r end
			end
		end
		if not q then return false end
		M.focus = q.ID
		log("working on quest: " .. questTitle(q))
	end
	local name = switchFor(q.Objective)
	local doer = name == "kill" and doKill or name == "find" and doFind or doTalk
	local success = doer(q, index)
	if success then
		failCount[q.ID] = nil
		local after = questById(q.ID)
		if not after or after.Objective == "Return" then
			log("quest done: " .. questTitle(q))
			M.focus = nil
			if M.on.turnin then turnInAll() end
			if M.on.accept then
				lastAccept = -math.huge -- take the next quests right away
				acceptAll()
			end
		end
	elseif M.on[name] then -- don't punish a quest that was cut short by switching off
		M.focus = nil
		failCount[q.ID] = (failCount[q.ID] or 0) + 1
		local long = M.opt.longSkip and failCount[q.ID] >= 2 and (M.gaveUp and M.gaveUp[q.ID])
		skipUntil[q.ID] = now + (long and 1800 or 120)
		log(("skipping %s for %s"):format(q.ID, long and "30 min" or "2 min"))
	end
	return true
end

----------------------------------------------------------------------
-- priority mode: one ordered list; every pass does the top task that has something to do
----------------------------------------------------------------------
M.PRIO_LABEL = {
	gear = "Gear goals (get + upgrade the gear you picked)",
	floor = "Next floor (boss + travel when level is reached)",
	daily = "Daily boss (once a day)",
	quests = "Quests of this floor",
	dungeons = "Dungeons (the ones picked on the Dungeons page)",
	tower = "Tower", boss = "Floor boss farm", arena = "Battle Arena", ether = "The Ether", cata = "Catacombs",
}
M.prio = M.prio or {
	enabled = false,
	order = { "floor", "daily", "quests", "dungeons", "cata", "arena", "ether", "boss", "tower" },
	on = { floor = true, daily = true, quests = true, dungeons = true, cata = false, arena = false, ether = false, boss = false, tower = false },
	cd = { dungeons = 10, cata = 0, arena = 0, ether = 30, boss = 30, tower = 0 }, -- minutes before the same activity repeats
	nextAt = {}, idx = {}, daily = {},
}
M.PRIO_PREFIX = { daily = "DAILY:", tower = "TOWER:", boss = "BOSS:", arena = "ARENA:", ether = "ETHER:", cata = "CATA:" }

-- instance keys of one activity on this floor
-- older saved lists don't have the newer rows yet
M.prioMigrate = function()
	local pr = M.prio
	if not table.find(pr.order, "gear") then
		local at = (table.find(pr.order, "quests") or 0) + 1
		table.insert(pr.order, at, "gear")
		pr.on.gear = false
	end
	pr.cd.gear = 0
end
M.prioKeys = function(id)
	local floor = currentFloor() or M.cycle.floor or 2
	local all = dungeonsForFloor(floor)
	local out = {}
	if id == "dungeons" then
		for _, k in ipairs(all) do if not k:find(":") and M.cycle.dungeons[k] then out[#out + 1] = k end end
		if #out == 0 then
			for _, k in ipairs(all) do if not k:find(":") then out[1] = k break end end -- nothing picked: the easiest
		end
	elseif id == "tower" then
		if M.side.towerRepeat then M.side.towerDone = false end
		if not M.side.towerDone and M.towerFloor() then out[1] = "TOWER:Tower" end
	elseif id == "gear" then
		M.gearTick()
		for _, k in ipairs(M.gearFarmKeys()) do out[#out + 1] = k end
	elseif id == "arena" or id == "ether" then
		do
			local ok = {}
			for _, f in ipairs(M.floorList()) do ok[f.n] = f.ok end
			local info = gameInfo() or {}
			for name, x in pairs(id == "arena" and info.BattleArenas or info.Ethers or {}) do
				if ok[tonumber(x.Floor)] then out[#out + 1] = (id == "arena" and "ARENA:" or "ETHER:") .. name end
			end
		end
	elseif id == "cata" then
		-- Catacombs from any map: travel to its map first (enterDungeon does it)
		do
			local ok = {}
			for _, f in ipairs(M.floorList()) do ok[f.n] = f.ok end
			for name, ct in pairs((gameInfo() or {}).Catacombs or {}) do
				if ok[tonumber(ct.Floor)] then out[#out + 1] = "CATA:" .. name end
			end
		end
	else
		local pre = M.PRIO_PREFIX[id]
		for _, k in ipairs(all) do if pre and k:sub(1, #pre) == pre then out[#out + 1] = k end end
	end
	return out
end

-- start the next run of an activity; ignoreCd = nothing else to do, so don't wait for its timer
M.prioRun = function(id, ignoreCd)
	local pr = M.prio
	if id == "floor" then
		if pr.on.daily and M.dailyNext() then return false end -- finish the daily boss tour first
		M.opt.nextFloor = true
		return progressTick() == true
	elseif id == "quests" then
		if M.on.turnin then turnInAll() end
		if M.on.accept then acceptAll() end
		if M.on.turnin then turnInAll() end
		local worked = doOneQuest()
		if not worked and os.clock() >= (M._prioAccept or 0) then
			-- looks finished: really ask every NPC once more before saying so
			M._prioAccept = os.clock() + 30
			turnInAll()
			lastAccept = -math.huge
			acceptAll()
			worked = doOneQuest()
		end
		M._noQuestWork = not worked
		return worked
	elseif id == "daily" then
		return M.dailyGo()
	end
	if (id == "cata" or id == "arena") and M.side.done and M.side.done[id] then return false end -- floor goal already reached
	local keys = M.prioKeys(id)
	if #keys == 0 then return false end
	if id == "tower" or id == "cata" or id == "arena" then pr.cd[id] = 0 end -- these go by floor goal, not by minutes
	if not ignoreCd and os.time() < (pr.nextAt[id] or 0) then return false end
	local i = ((pr.idx[id] or 0) % #keys) + 1
	pr.idx[id] = i
	if i == #keys then pr.nextAt[id] = os.time() + (pr.cd[id] or 30) * 60 end -- lap finished
	log(("priority: %s -> %s"):format(id, keys[i]))
	saveState()
	enterDungeon(keys[i])
	return true
end

-- quests, dungeons and the floor boss belong to the home map: after a trip elsewhere
-- (gear farming on a lower map, say) go back home before doing them
M.backHome = function()
	local n = M.homeTarget()
	if n <= 0 or M.sellTrip or inDungeon() then return false end
	local cur = currentFloor()
	if not cur or cur == n then return false end
	local sd, now = M.side, os.time()
	if (sd.towerTrip and now - sd.towerTrip < 300) or (sd.cataTrip and now - sd.cataTrip < 300)
		or (sd.tpTrip and now - sd.tpTrip < 600) or (sd.scanTrip and now - sd.scanTrip < 300)
		or (sd.dailyTrip and now - sd.dailyTrip < 600) then return false end
	if M.questTripHold() then return false end -- on a quest trip: stay until its quests are done
	sd.gearFarmFloor = nil
	saveState()
	if M.travelTo(n, "home map") then task.wait(20) return true end
	return false
end
-- gear farming needs many runs in a row (20 dungeon runs for a few upgrades is normal):
-- once it starts it keeps going for "Gear runs in a row" runs before the list moves on.
-- A trip to another map does not count as a run.
M.gearStreakRun = function()
	local sd = M.side
	if not (M.prio.on.gear and (sd.gearStreak or 0) > 0) then return false end
	if #M.prioKeys("gear") == 0 then sd.gearStreak = 0 return false end
	M.gearMeasure()
	M._gearTravel = false
	M.prio.last.gear = os.time()
	local keys = M.prioKeys("gear")
	local item = M.gearFarmFor
	-- saved before going in: entering a dungeon teleports, and this code does not run on after that
	if keys[1] and item then
		sd.gearPending = { key = keys[1], item = item, have = M.gearHave(item), t = os.time() }
		saveState()
	end
	local ok = M.prioRun("gear", true)
	if M._gearTravel then sd.gearPending = nil end
	if not M._gearTravel then sd.gearStreak = (sd.gearStreak or 1) - 1 end
	saveState()
	return ok
end
-- Upgrade mode: while any picked item is below your level (or not owned yet) and can be farmed,
-- do nothing else; once everything is as high as your level allows, the normal list runs
-- (quests / dungeons for EXP) until a level-up opens room again
-- one setting for how gear farming fits in with everything else:
--   balanced: gear gets its turn in the Priority list ("Gear runs in a row" per turn)
--   upgrade : upgrade materials come first until the gear matches your level; item hunts keep their turn
--   gearonly: once gear's turn starts it keeps going until every pick is owned and maxed
M.gearMode = function()
	local m = M.opt.gearMode
	if m == "balanced" or m == "upgrade" or m == "gearonly" then return m end
	return M.opt.gearFirst and "upgrade" or "balanced"
end
M.gearModeRun = function()
	if not (M.gearMode() == "upgrade" and M.gearAny()) then M._gearModeOn = false return false end
	M.gearTick()
	M._gearMatsOnly = true
	local keys = M.gearFarmKeys()
	if #keys == 0 then
		M._gearMatsOnly = false
		M.gearFarmKeys() -- back to the full list (item hunts) for the normal Priority turn
		if M._gearModeOn then log("upgrade mode: gear is as high as your level allows - back to normal farming") end
		M._gearModeOn = false
		return false
	end
	if not M._gearModeOn then log("upgrade mode: farming " .. tostring(M.gearFarmFor) .. " until the gear catches up with your level") end
	M._gearModeOn = true
	M._gearTravel = false
	M.prio.last.gear = os.time()
	local ok = M.prioRun("gear", true)
	M._gearMatsOnly = false
	return ok
end
-- Level up mode: only what gives EXP, until the next map opens:
-- next floor (boss + travel), daily bosses, quests, then dungeons and the floor boss in turns.
-- Gear still gets upgraded / worn whenever you are on the map; nothing is farmed for it.
M.levelModeRun = function()
	local pr = M.prio
	if M.prioRun("floor", false) then return true end
	if M.prioRun("daily", false) then return true end
	if not M._noQuestWork and M.backHome() then return true end
	if M.prioRun("quests", false) then return true end
	if M.oldQuestTick() then return true end
	-- on a quest trip and the quest list found nothing (more) to do here: the trip is over, go home before dungeons / bosses
	if M.side.questTrip and not M.inDungeon() and M.currentFloor() == M.side.questFloor and not M.questTripOpen() then
		M.questTripEnd("nothing (more) to do here")
		if M.backHome() then return true end
	end
	if M.backHome() then return true end
	local best, bestT
	for _, id in ipairs({ "dungeons", "boss" }) do
		if #M.prioKeys(id) > 0 then
			local t = pr.last[id] or 0
			if not bestT or t < bestT then best, bestT = id, t end
		end
	end
	if best then
		pr.last[best] = os.time()
		return M.prioRun(best, true)
	end
	return false
end
M.prioTick = function()
	M.prioMigrate()
	local pr = M.prio
	pr.last = pr.last or {}
	if M.opt.focus == "level" then return M.levelModeRun() end
	if M.gearModeRun() then return true end
	for _, id in ipairs(pr.order) do
		if pr.on[id] and (id == "floor" or id == "daily") and M.prioRun(id, false) then return true end
	end
	if M.gearStreakRun() then return true end
	for _, id in ipairs(pr.order) do
		if pr.on[id] and id == "quests" and not M._noQuestWork and M.backHome() then return true end -- quests left at home
		if pr.on[id] and id == "quests" and M.prioRun(id, false) then return true end
		if pr.on[id] and id == "quests" and M.oldQuestTick() then return true end
		-- on a quest trip and the quest list found nothing (more) to do here: the trip is over, go home before dungeons / bosses
		if M.side.questTrip and not M.inDungeon() and M.currentFloor() == M.side.questFloor and not M.questTripOpen() then
			M.questTripEnd("nothing (more) to do here")
			if M.backHome() then return true end
		end
	end
	-- the repeatable ones take turns: whoever went longest ago goes next (list order breaks ties);
	-- one still inside its waiting time is skipped unless nothing else is ready
	local now = os.time()
	local function pick(respectWait)
		local best, bestT
		for _, id in ipairs(pr.order) do
			if pr.on[id] and id ~= "floor" and id ~= "quests" and id ~= "daily"
				and not ((id == "cata" or id == "arena") and M.side.done and M.side.done[id])
				and #M.prioKeys(id) > 0 and (not respectWait or now >= (pr.nextAt[id] or 0)) then
				local t = pr.last[id] or 0
				if not bestT or t < bestT then best, bestT = id, t end
			end
		end
		return best
	end
	local id = pick(true) or pick(false)
	if id then
		if (id == "dungeons" or id == "boss") and M.backHome() then return true end
		pr.last[id] = now
		if id == "gear" then
			local n = tonumber(M.opt.gearRuns) or 10
			if M.gearMode() == "gearonly" then n = 0 end
			M.side.gearStreak = n <= 0 and 1e9 or n
			return M.gearStreakRun()
		end
		return M.prioRun(id, true)
	end
	return false
end

M.setPrio = function(v)
	M.prio.enabled = v
	if v then
		-- the list replaces the timer cycle and the separate Tower / Boss timers
		M.cycle.enabled = false
		M.cycle.pending = nil
		M.side.tower, M.side.boss = false, false
		for _, n in ipairs({ "turnin", "accept", "kill", "find", "talk" }) do M.on[n] = true end
		M.running = true
	end
	saveState()
end

----------------------------------------------------------------------
-- gear goals: pick up to 2 weapons (hand 1 / hand 2) and 1 armor. The script gets each one
-- (runs the dungeon / boss that drops it), upgrades it to the level you set (0 = your level),
-- farms the upgrade crystals it is short of, and wears it.
----------------------------------------------------------------------
M.GEAR_SLOTS = {
	{ id = "w1", cls = "Weapons", hand = 1, title = "Weapon 1 (main hand)" },
	{ id = "w2", cls = "Weapons", hand = 2, title = "Weapon 2 (second hand)" },
	{ id = "armor", cls = "Armor", title = "Armor" },
	{ id = "pet", cls = "Companions", title = "Pet", flat = true, eqKey = "Companion" },
	{ id = "mount", cls = "Mounts", title = "Mount", flat = true, eqKey = "Mount" },
}
M.VARIANT_RANK = { Sparkling = 3, Radiant = 2, Base = 1 }
M.TOWER_PRIZES = { ["Weeping Wyatt"] = 50, ["Guiding Fairy"] = 100, ["Giant Slime"] = 125, ["Infernal Wolf"] = 400, ["Metal Slime"] = 600 }
M.gearCfg = function()
	M.side.gear = M.side.gear or {}
	return M.side.gear
end
M.gearAny = function()
	local G = M.gearCfg()
	for _, sl in ipairs(M.GEAR_SLOTS) do if G[sl.id] and G[sl.id].name then return true end end
	return false
end

-- where an item (or a material) comes from
M.gearSources = function(itemName)
	local info = gameInfo() or {}
	local ok = {}
	for _, f in ipairs(M.floorList()) do ok[f.n] = f.ok end
	local out = {}
	local function add(kind, key, label, fl, farm)
		out[#out + 1] = { kind = kind, key = key, label = label, floor = fl, ok = fl == nil or ok[fl] == true, farm = farm }
	end
	local function has(x)
		local rw = x.Rewards or {}
		return (rw.Items and rw.Items[itemName] ~= nil) or (rw.Materials and rw.Materials[itemName] ~= nil)
	end
	for name, x in pairs(info.Dungeons or {}) do if has(x) then add("dungeon", name, "Dungeon " .. name, tonumber(x.Floor), true) end end
	for name, x in pairs(info.Bosses or {}) do if has(x) then add("boss", "BOSS:" .. name, "Boss " .. name, tonumber(x.Floor), true) end end
	for name, x in pairs(info.DailyBosses or {}) do if has(x) then add("daily", "DAILY:" .. name, "Daily boss " .. name .. " (once a day)", tonumber(x.Floor), false) end end
	for key in pairs((M.loadDrops())[itemName] or {}) do
		local mob, fl = tostring(key):match("^(.+)@(%d+)$")
		if mob then
			local miss = M.side.mobMissing and M.side.mobMissing[mob]
			if miss and os.time() - miss < 1200 then
				add("mob", "MOB:" .. key, ("Monster %s (rare spawn - not on the map lately; killed whenever it shows up, map trip again in %d min)"):format(mob, math.ceil((1200 - (os.time() - miss)) / 60)), tonumber(fl), false)
			else
				local hp = ((M.loadDrops()).__hp or {})[mob]
				add("mob", "MOB:" .. key, hp and hp >= 15000 and ("Monster %s (strong, %dk HP - may be a rare spawn)"):format(mob, math.floor(hp / 1000)) or "Monster " .. mob, tonumber(fl), true)
			end
		end
	end
	if info.Recipes and info.Recipes[itemName] then
		add("craft", nil, ("Crafting (needs Lv %s + materials)"):format(tostring(info.Recipes[itemName].Level or "?")), nil, false)
	end
	local function find(t, depth)
		if type(t) ~= "table" or depth < 0 then return false end
		if t.Name == itemName then return true end
		for _, v in pairs(t) do if type(v) == "table" and find(v, depth - 1) then return true end end
		return false
	end
	for _, r in pairs(RC._replicas) do
		if r.Class == "SkeletonChest" and find(r.Data, 3) then add("chest", nil, "Skeleton Chest (opened with Skeleton Keys)", nil, false) end
		if r.Class == "EtherShop" and find(r.Data, 4) then add("shop", nil, "Ether shop (Ether Crystals)", nil, false) end
		if r.Class == "BountyShop" and find(r.Data, 4) then add("shop", nil, "Bounty shop (Bounty Boons)", nil, false) end
	end
	if M.TOWER_PRIZES[itemName] then
		local tf = M.towerFloor and M.towerFloor()
		add("tower", nil, ("Tower floor %d (once)"):format(M.TOWER_PRIZES[itemName]), tf, false)
	end
	for cat, boxes in pairs(info.Shop or {}) do
		for boxName, box in pairs(boxes) do
			if type(box) == "table" and find(box.Items or {}, 2) or (type(box) == "table" and type(box.Items) == "table" and (box.Items[itemName] ~= nil or table.find(box.Items, itemName))) then
				add("box", nil, ("Shop box: %s (%s each, Bleeter Bits)"):format(boxName, tostring(box.Buy1Price or "?")), nil, false)
			end
		end
	end
	local rank = { dungeon = 1, mob = 2, boss = 3, daily = 4, tower = 5, craft = 6, chest = 7, shop = 8, box = 9 }
	table.sort(out, function(a, b)
		if a.ok ~= b.ok then return a.ok end
		if rank[a.kind] ~= rank[b.kind] then return rank[a.kind] < rank[b.kind] end
		return (a.floor or 0) < (b.floor or 0)
	end)
	return out
end

-- every copy you own of an item: worn ones first if equal level
M.gearCopies = function(cls, name)
	local d = data()
	if not d then return {} end
	local out = {}
	local eq = d.Data.Equipped
	if cls == "Companions" or cls == "Mounts" then
		local worn = eq[cls == "Companions" and "Companion" or "Mount"]
		if type(worn) == "table" and worn.Name == name then out[#out + 1] = { where = "worn", item = worn } end
		for k, it in pairs(d.Data.Inventory[cls] or {}) do
			if type(it) == "table" and it.Name == name then out[#out + 1] = { where = "bag", key = k, item = it } end
		end
		table.sort(out, function(a, b)
			local ra, rb = M.VARIANT_RANK[a.item.Variant or "Base"] or 0, M.VARIANT_RANK[b.item.Variant or "Base"] or 0
			if ra ~= rb then return ra > rb end
			return a.where ~= "bag" and b.where == "bag"
		end)
		return out
	end
	if cls == "Weapons" then
		for h = 1, 2 do
			local it = eq.Hands and eq.Hands[h]
			if type(it) == "table" and it.Name == name then out[#out + 1] = { where = "hand" .. h, item = it } end
		end
	else
		local it = eq.Armor
		if type(it) == "table" and it.Name == name then out[#out + 1] = { where = "armor", item = it } end
	end
	for k, it in pairs(d.Data.Inventory[cls] or {}) do
		if type(it) == "table" and it.Name == name then out[#out + 1] = { where = "bag", key = k, item = it } end
	end
	table.sort(out, function(a, b)
		local la, lb = (a.item.Leveling and a.item.Leveling.Level) or 1, (b.item.Leveling and b.item.Leveling.Level) or 1
		if la ~= lb then return la > lb end
		return a.where ~= "bag" and b.where == "bag"
	end)
	return out
end

-- worn item -> bag (weapons can't be taken off, only swapped: put a spare in its place)
M.gearFree = function(sl, copy)
	if copy.where == "bag" then return copy.key, copy.item end
	local d = data()
	if not d then return end
	local inv = d.Data.Inventory[sl.cls] or {}
	local myLevel = d.Data.Leveling.Level or 1
	local name, lvl = copy.item.Name, (copy.item.Leveling and copy.item.Leveling.Level) or 1
	local hand = copy.where == "hand1" and 1 or copy.where == "hand2" and 2 or nil
	local G = M.gearCfg()
	local spareK, spare
	for pass = 1, 2 do
		for k, it in pairs(inv) do
			local usable = ((it.Leveling and it.Leveling.Level) or 1) <= myLevel
			local picked = false
			for _, s in pairs(G) do if type(s) == "table" and s.name == it.Name then picked = true end end
			if usable and not picked and (pass == 2 or sl.cls ~= "Weapons" or it.Class == copy.item.Class) then spareK, spare = k, it break end
		end
		if spare then break end
	end
	if not spare then return end
	local before = {}
	for k in pairs(inv) do before[k] = true end
	task.wait(math.max(0, (M._lastEquipAt or 0) + 2.5 - os.clock()))
	if sl.cls == "Weapons" then
		d:FireServer("Equip", { SelectedItem = { "Weapons", spareK, spare }, Hand = hand })
	else
		d:FireServer("Equip", { SelectedItem = { "Armor", spareK, spare } })
	end
	M._lastEquipAt = os.clock()
	local t0 = os.clock()
	repeat
		task.wait(0.3)
		for k, it in pairs(d.Data.Inventory[sl.cls] or {}) do
			if it ~= spare and it.Name == name and ((it.Leveling and it.Leveling.Level) or 1) == lvl and (not before[k] or it == copy.item) then
				return k, it
			end
		end
	until os.clock() - t0 > 4
end

M.gearWear = function(sl, k, it)
	local d = data()
	if not d then return false end
	-- after an upgrade the bag entry can be a new table / key: look it up again
	local inv = d.Data.Inventory[sl.cls] or {}
	if inv[k] ~= it then
		for k2, it2 in pairs(inv) do
			if it2.Name == it.Name and (it2.Leveling and it2.Leveling.Level) == (it.Leveling and it.Leveling.Level) then k, it = k2, it2 break end
		end
	end
	local eq = d.Data.Equipped
	if sl.cls == "Weapons" then
		-- the second hand must hold the same weapon type as the first: put the main hand right first
		local main = eq.Hands and eq.Hands[1]
		if sl.hand == 2 and type(main) == "table" and main.Class ~= it.Class then
			M.gearState[sl.id] = ("hand 1 holds a %s, hand 2 needs the same type"):format(tostring(main.Class))
			return false
		end
	end
	-- the game ignores an equip that comes right after another one: space them out and try a few times
	local now
	for attempt = 1, 3 do
		task.wait(math.max(0, (M._lastEquipAt or 0) + 2.5 - os.clock()))
		if sl.cls == "Weapons" then
			d:FireServer("Equip", { SelectedItem = { "Weapons", k, it }, Hand = sl.hand })
		else
			d:FireServer("Equip", { SelectedItem = { "Armor", k, it } })
		end
		M._lastEquipAt = os.clock()
		local t0 = os.clock()
		repeat
			task.wait(0.3)
			eq = d.Data.Equipped
			now = sl.cls == "Weapons" and eq.Hands and eq.Hands[sl.hand] or eq.Armor
		until (type(now) == "table" and now.Name == it.Name) or os.clock() - t0 > 4
		if type(now) == "table" and now.Name == it.Name then break end
		-- the bag entry may have moved meanwhile
		for k2, it2 in pairs(d.Data.Inventory[sl.cls] or {}) do
			if it2.Name == it.Name and (it2.Leveling and it2.Leveling.Level) == (it.Leveling and it.Leveling.Level) then k, it = k2, it2 break end
		end
	end
	if type(now) == "table" and now.Name == it.Name then
		log(("gear goal: wearing %s Lv %d (%s)"):format(it.Name, it.Leveling.Level, sl.title))
		return true
	end
	M._gearNoWear = M._gearNoWear or {}
	M._gearNoWear[sl.id] = os.clock() + 120
	log(("gear goal: the game would not put %s in %s"):format(it.Name, sl.title))
	return false
end

M.gearUpgrade = function(sl, copy, target)
	local d = data()
	if not d then return end
	local k, it = M.gearFree(sl, copy)
	if not k then
		M.gearState[sl.id] = "can't upgrade it while worn: no spare item to swap in"
		return
	end
	status("Upgrading " .. it.Name)
	local myLevel = d.Data.Leveling.Level or 1
	local steps, from = 0, it.Leveling.Level
	while (it.Leveling.Level or 1) < target and steps < 40 do
		local cname, camt, coins = M.upgradeCost(it)
		local have = (d.Data.Inventory.Materials or {})[cname or ""] or 0
		if not cname or have < camt or (d.Data.Currencies.Coins or 0) - coins < (M.opt.keepCoins or 2000) then break end
		local l = it.Leveling.Level
		d:FireServer("UpgradeItem", { SelectedItem = { sl.cls, k, it } })
		local t0 = os.clock()
		repeat task.wait(0.3) until (it.Leveling.Level or 1) > l or os.clock() - t0 > 4
		if (it.Leveling.Level or 1) <= l then
			local again = (d.Data.Inventory[sl.cls] or {})[k]
			if again and again.Name == it.Name and (again.Leveling.Level or 1) > l then it = again else break end
		end
		steps += 1
	end
	if it.Leveling.Level > from then log(("gear goal: %s Lv %d -> %d"):format(it.Name, from, it.Leveling.Level)) end
	if (it.Leveling.Level or 1) <= myLevel then M.gearWear(sl, k, it) end
end

-- look at every slot; upgrade / wear what can be done now, list what has to be farmed
M.gearTick = function(force)
	if not M.gearAny() then M.gearNeeds = {} return end
	-- inside a dungeon / Tower / Ether the game does not apply gear changes: swapping there only leaves spares in your hands
	if inDungeon() then return end
	if not force and os.clock() < (M._nextGearGoal or 0) then return end
	M._nextGearGoal = os.clock() + 30
	local d = data()
	if not d then return end
	local G = M.gearCfg()
	local myLevel = d.Data.Leveling.Level or 1
	local needs, used = {}, {}
	M.gearState = M.gearState or {}
	for _, sl in ipairs(M.GEAR_SLOTS) do
		local cfg = G[sl.id]
		if not (cfg and cfg.name) then
			M.gearState[sl.id] = nil
		elseif sl.flat then
			local copies = M.gearCopies(sl.cls, cfg.name)
			local best = copies[1]
			if not best then
				needs[#needs + 1] = { item = cfg.name, slot = sl.id }
				M.gearState[sl.id] = "not owned yet"
			elseif best.where == "worn" then
				M.gearState[sl.id] = "in use"
			elseif not M._gearNoWear or (M._gearNoWear[sl.id] or 0) < os.clock() then
				d:FireServer("Equip", { SelectedItem = { sl.cls, best.key, best.item } })
				task.wait(1.2)
				local now = d.Data.Equipped[sl.eqKey]
				if type(now) == "table" and now.Name == cfg.name then
					log(("gear goal: %s now %s"):format(sl.title:lower(), cfg.name))
					M.gearState[sl.id] = "in use"
				else
					M._gearNoWear = M._gearNoWear or {}
					M._gearNoWear[sl.id] = os.clock() + 600
					M.gearState[sl.id] = "the game did not equip it (inside a dungeon?) - trying again in 10 min"
				end
			end
		else
			local copy
			for _, c in ipairs(M.gearCopies(sl.cls, cfg.name)) do
				-- a copy that sits in the other hand belongs to the other slot if that slot wants the same item
				local other = sl.id == "w1" and G.w2 or sl.id == "w2" and G.w1 or nil
				local otherHand = sl.id == "w1" and "hand2" or "hand1"
				local claimed = other and other.name == cfg.name and c.where == otherHand
				if not used[c.item] and not claimed then copy = c break end
			end
			if not copy then
				needs[#needs + 1] = { item = cfg.name, slot = sl.id }
				M.gearState[sl.id] = "not owned yet"
			else
				used[copy.item] = true
				M.gearUse = M.gearUse or {}
				M.gearUse[sl.id] = copy.item
				local target = (tonumber(cfg.target) or 0) > 0 and math.min(tonumber(cfg.target), myLevel) or myLevel
				local lvl = (copy.item.Leveling and copy.item.Leveling.Level) or 1
				local wearable = lvl <= myLevel
				if lvl < target then
					local cname, camt, coins = M.upgradeCost(copy.item)
					local have = (d.Data.Inventory.Materials or {})[cname or ""] or 0
					if not cname then
						M.gearState[sl.id] = ("Lv %d: max level"):format(lvl)
					elseif have < camt then
						needs[#needs + 1] = { item = cname, slot = sl.id, mat = true }
						M.gearState[sl.id] = ("Lv %d -> %d: short of %s (%d/%d)"):format(lvl, target, cname, have, camt)
					elseif (d.Data.Currencies.Coins or 0) - coins < (M.opt.keepCoins or 2000) then
						M.gearState[sl.id] = ("Lv %d -> %d: waiting for coins (%d a level)"):format(lvl, target, coins)
					else
						M.gearState[sl.id] = ("Lv %d -> %d: upgrading"):format(lvl, target)
						M.gearUpgrade(sl, copy, target)
						M._nextGearGoal = 0 -- look again next pass
						M.gearNeeds = needs
						return true
					end
				else
					M.gearState[sl.id] = ("Lv %d (goal %d) done"):format(lvl, target)
				end
				local mine = sl.cls == "Weapons" and ("hand" .. sl.hand) or "armor"
				if not wearable then
					M.gearState[sl.id] = M.gearState[sl.id] .. " - too high to wear yet"
				elseif copy.where ~= mine and (not M._gearNoWear or (M._gearNoWear[sl.id] or 0) < os.clock()) then
					local k, it = M.gearFree(sl, copy)
					if k then M.gearWear(sl, k, it) end
				end
			end
		end
	end
	M.gearNeeds = needs
	if #needs == 0 then M.side.gearFarmFloor = nil end
end

-- monster drops: the game shows the drop list only for monsters of the map you stand on,
-- so every map visit is remembered in auto_farm_drops.json (item -> "Monster@floor")
M.loadDrops = function()
	if M.dropCache then return M.dropCache end
	local ok, t = pcall(function() return Http:JSONDecode(readfile("auto_farm_drops.json")) end)
	M.dropCache = ok and type(t) == "table" and t or {}
	return M.dropCache
end
M.learnDrops = function()
	if inDungeon() then return end
	if os.clock() < (M._nextLearn or 0) then return end
	M._nextLearn = os.clock() + 120
	local fl = currentFloor()
	if not fl then return end
	local info = gameInfo() or {}
	M.dropCache = nil -- other accounts on this PC write the same file: start from what's on disk
	local cache = M.loadDrops()
	local changed = false
	cache.__hp = cache.__hp or {}
	for ename, e in pairs(info.Enemies or {}) do
		cache.__mobFloor = cache.__mobFloor or {}
		if cache.__mobFloor[ename] ~= fl then cache.__mobFloor[ename] = fl changed = true end
		local hp = type(e) == "table" and e.Values and tonumber(e.Values.Health)
		if hp and cache.__hp[ename] ~= hp then cache.__hp[ename] = hp changed = true end
		for item in pairs(type(e) == "table" and e.Drops or {}) do
			item = tostring(item)
			cache[item] = cache[item] or {}
			local key = ename .. "@" .. fl
			if not cache[item][key] then cache[item][key] = true changed = true end
		end
	end
	cache.__floors = cache.__floors or {}
	if not cache.__floors[tostring(fl)] then cache.__floors[tostring(fl)] = os.time() changed = true end
	cache.__mobFloors = cache.__mobFloors or {}
	if not cache.__mobFloors[tostring(fl)] then cache.__mobFloors[tostring(fl)] = os.time() changed = true end
	if changed then pcall(function() writefile("auto_farm_drops.json", Http:JSONEncode(cache)) end) end
end
-- every quest giver seen on each map, kept in auto_farm_quests.json (shared by all accounts on this PC):
-- the game only shows the quest givers of the map you stand on, so the full list grows as maps are visited
M.loadQuestBook = function()
	local ok, t = pcall(function() return Http:JSONDecode(readfile("auto_farm_quests.json")) end)
	return ok and type(t) == "table" and t or {}
end
M.learnQuests = function()
	if inDungeon() or os.clock() < (M._nextQuestLearn or 0) then return end
	M._nextQuestLearn = os.clock() + 120
	local fl = currentFloor()
	local npcs = workspace:FindFirstChild("NPCs")
	if not fl or not npcs or #npcs:GetChildren() < 3 then return end
	local book = M.loadQuestBook()
	local key = tostring(fl)
	book[key] = book[key] or {}
	local changed = false
	for _, n in ipairs(npcs:GetChildren()) do
		local ni = n:FindFirstChild("NPCInfo")
		local id = ni and ni:GetAttribute("ID")
		local tree = ni and ni:FindFirstChild("DialogTree")
		if id and tree and tree:FindFirstChild("StartQuestCMD", true) then
			local e = book[key][id]
			local title = tostring(ni:GetAttribute("Title") or id)
			if not e or e.t ~= title then
				book[key][id] = {
					t = title, npc = n.Name, ty = tostring(ni:GetAttribute("Type") or ""),
					mob = ni:GetAttribute("MobToKill"), obj = ni:GetAttribute("ObjectToFind"), amt = ni:GetAttribute("Amount"),
				}
				changed = true
			end
		end
	end
	if changed then pcall(function() writefile("auto_farm_quests.json", Http:JSONEncode(book)) end) end
end
-- text for the Quests page: per map, done / all known, and what is left
M.questBookText = function()
	local d = data()
	if not d then return "..." end
	local W = function(v) return ('<font color="#E9EEEA">%s</font>'):format(tostring(v)) end
	local done = d.Data.Quests.CompletedQuests or {}
	local prog = {}
	for _, q in ipairs(quests()) do prog[q.ID] = q end
	local book = M.loadQuestBook()
	local out = {}
	local totalLeft = 0
	for _, f in ipairs(M.floorList()) do
		local list = book[tostring(f.n)]
		if not list then
			out[#out + 1] = ("%s: %s"):format(W(f.n .. " " .. tostring(f.name)), f.ok and "not seen yet (fills in after a visit)" or '<font color="#9aa29c">locked</font>')
		else
			local ids = {}
			for id in pairs(list) do ids[#ids + 1] = id end
			table.sort(ids)
			local nDone, left, daily, nStory = 0, {}, 0, 0
			for _, id in ipairs(ids) do
				local e = list[id]
				local q = prog[id]
				local isDaily = tostring(id):find("Daily") or tostring(e.t):find("Daily") or e.ty == "RandomKill"
				if isDaily then
					if not q then daily += 1 end
				elseif done[id] and not q then
					nStory += 1
					nDone += 1
				else
					nStory += 1
					local what = e.mob and ("kill " .. tostring(e.amt or "") .. " " .. tostring(e.mob)) or e.obj and ("find " .. tostring(e.obj)) or tostring(e.ty)
					local st = q and ('<font color="#E8C15A">doing %s/%s</font>'):format(tostring(q.Progress or 0), tostring(q.Amount or 1)) or '<font color="#d65656">not taken</font>'
					left[#left + 1] = ("   - %s (%s: %s) %s"):format(tostring(e.t), tostring(e.npc), what, st)
				end
			end
			totalLeft += #left
			out[#out + 1] = ("%s: %s%d / %d story quests done%s%s"):format(W(f.n .. " " .. tostring(f.name)), #left == 0 and '<font color="#6ED876">all </font>' or "", nDone, nStory,
				daily > 0 and (" + %d daily"):format(daily) or "", f.ok and "" or ' <font color="#9aa29c">(map locked)</font>')
			for _, l in ipairs(left) do out[#out + 1] = l end
		end
	end
	table.insert(out, 1, ("Story quests left on the maps seen so far: %s  (daily quests come back every day and are not counted)"):format(W(totalLeft)))
	return table.concat(out, "\n")
end

-- one map trip at a time: is another trip (Tower, Catacombs, TP tour, drop scan, daily bosses, selling) under way?
M.onTrip = function()
	local sd, now = M.side, os.time()
	return M.sellTrip or (sd.towerTrip and now - sd.towerTrip < 300) or (sd.cataTrip and now - sd.cataTrip < 300)
		or (sd.tpTrip and now - sd.tpTrip < 600) or (sd.scanTrip and now - sd.scanTrip < 300) or (sd.dailyTrip and now - sd.dailyTrip < 600)
		or (sd.gearFarmFloor and now - (sd.gearFarmAt or 0) < 1800 and sd.gearFarmFloor ~= M.homeTarget())
end
M.questBookCached = function()
	if not M._qbCache or os.clock() > (M._qbCacheT or 0) then
		M._qbCache = M.loadQuestBook()
		M._qbCacheT = os.clock() + 60
	end
	return M._qbCache
end
-- a quest trip (old quests on a lower map, or a quest monster that lives on another map) ends:
-- what is still open there waits 3 hours before the next try
M.questTripEnd = function(why)
	local sd = M.side
	if not sd.questTrip then return end
	local d = data()
	local done = d and d.Data.Quests.CompletedQuests or {}
	sd.oldSkip = sd.oldSkip or {}
	local list = sd.questFloor and (M.questBookCached())[tostring(sd.questFloor)] or {}
	local open = 0
	for id, e in pairs(list) do
		local isDaily = tostring(id):find("Daily") or tostring(e.t):find("Daily") or e.ty == "RandomKill"
		if not done[id] and not isDaily then sd.oldSkip[id] = os.time() + 3 * 3600 open += 1 end
	end
	log(("quest trip to map %s over (%s)%s"):format(tostring(sd.questFloor), why, open > 0 and (" - %d left there, next try in 3 h"):format(open) or ""))
	sd.questTrip, sd.questMob, sd.questFloor, sd.questSum, sd.questMoved = nil, nil, nil, nil, nil
	M.saveState()
end
-- a quest of this trip's map is still open (taken, not ready to hand in)
M.questTripOpen = function()
	local sd = M.side
	local list = (M.questBookCached())[tostring(sd.questFloor or "")] or {}
	for _, q in ipairs(quests()) do
		if (list[q.ID] or (sd.questMob and q.MobToKill == sd.questMob)) and q.Objective ~= "Return" then return true end
	end
	return false
end
-- true while the trip's quests are still moving: nothing may pull the character home or up a map
M.questTripHold = function()
	local sd, now = M.side, os.time()
	if not sd.questTrip then return false end
	local cur = M.currentFloor()
	if M.inDungeon() or not cur then return true end
	if sd.questFloor and cur ~= sd.questFloor then
		if now - sd.questTrip < 120 then return false end -- still on the way
		M.questTripEnd("left the map")
		return false
	end
	if now - sd.questTrip > 2700 then M.questTripEnd("45 min are up") return false end
	local list = (M.questBookCached())[tostring(sd.questFloor or cur)] or {}
	local sum, open = 0, 0
	for _, q in ipairs(quests()) do
		if list[q.ID] or (sd.questMob and q.MobToKill == sd.questMob) then
			sum += (q.Progress or 0)
			if q.Objective ~= "Return" then open += 1 end
		end
	end
	if sd.questSum ~= sum then sd.questSum, sd.questMoved = sum, now end
	sd.questMoved = sd.questMoved or now
	if open == 0 and now - sd.questTrip > 90 then M.questTripEnd("done") return false end
	if now - sd.questMoved > 600 then M.questTripEnd("no progress for 10 min") return false end
	return true
end
-- story quests left on a lower map (not taken, or dropped when you went home): go there, take them, do them
M.oldQuestTick = function()
	if (M.opt.oldQuests == false and M.opt.dailyTour == false) or not M.on.accept then return false end
	local sd, now = M.side, os.time()
	if sd.questTrip or M.inDungeon() or M.onTrip() or now < (sd.oldQuestNext or 0) then return false end
	if M.dailyNext and M.dailyNext() then return false end
	local maxQ = 4
	for _, r in pairs(RC._replicas) do
		if r.Class == "Info" and r.Data._GameData then maxQ = tonumber(r.Data._GameData.MAX_QUESTS) or 4 end
	end
	if #quests() >= maxQ then return false end
	local d = data()
	if not d then return false end
	local done = d.Data.Quests.CompletedQuests or {}
	local prog = {}
	for _, q in ipairs(quests()) do prog[q.ID] = true end
	local cur = M.currentFloor()
	local book = M.questBookCached()
	sd.oldSkip = sd.oldSkip or {}
	for _, f in ipairs(M.floorList()) do
		local list = book[tostring(f.n)]
		if f.ok and list and f.n ~= cur then
			local n, nd = 0, 0
			sd.dailyDone, sd.dailyTry = sd.dailyDone or {}, sd.dailyTry or {}
			local due = {}
			for id, e in pairs(list) do
				local isDaily = tostring(id):find("Daily") or tostring(id):find("DAILY") or tostring(e.t):find("Daily") or e.ty == "RandomKill"
				if not isDaily and M.opt.oldQuests ~= false and not done[id] and not prog[id] and now >= (sd.oldSkip[id] or 0) then n += 1 end
				-- a daily comes back 24 h after it was handed in; one that could not be taken waits 6 h before the next try
				if isDaily and M.opt.dailyTour ~= false and not prog[id] and now - (sd.dailyDone[id] or 0) > 86400 and now - (sd.dailyTry[id] or 0) > 6 * 3600 then
					nd += 1
					due[#due + 1] = id
				end
			end
			if n + nd > 0 then
				for _, id in ipairs(due) do sd.dailyTry[id] = now end
				sd.oldQuestNext = now + 300
				sd.questTrip, sd.questFloor, sd.questMob, sd.questSum, sd.questMoved = now, f.n, nil, nil, now
				M.saveState()
				log(("map %d (%s): %d old quest(s), %d daily quest(s) to do - going there"):format(f.n, tostring(f.name), n, nd))
				if M.travelTo(f.n, nd > 0 and n == 0 and "daily quests" or "old quests") then task.wait(20) return true end
				M.questTripEnd("could not travel")
				return false
			end
		end
	end
	sd.oldQuestNext = now + 600
	return false
end
-- visit every map you can enter once, just to read its monsters' drops, then go home
M.scanStart = function(onlyMissing)
	local left = {}
	local known = (M.loadDrops()).__mobFloors or {}
	local qb = M.loadQuestBook()
	for _, f in ipairs(M.floorList()) do
		if f.ok and not (onlyMissing and known[tostring(f.n)] and qb[tostring(f.n)]) then left[#left + 1] = f.n end
	end
	if #left == 0 then return end
	M.side.scanLeft = left
	M.side.scanTrip = os.time()
	saveState()
	log(("reading monster drops on %d maps"):format(#left))
end
M.scanTick = function()
	local sd = M.side
	-- a map you can enter whose monster drops were never read (new PC, new map): go read it once, by itself
	if not sd.scanLeft and not inDungeon() and os.time() - (sd.autoScanAt or 0) > 6 * 3600 then
		local known = (M.loadDrops()).__mobFloors or {}
		local qb = M.loadQuestBook()
		for _, f in ipairs(M.floorList()) do
			if f.ok and not (known[tostring(f.n)] and qb[tostring(f.n)]) then
				sd.autoScanAt = os.time()
				log("monster drops: map " .. f.n .. " never read - reading the missing maps")
				M.scanStart(true)
				break
			end
		end
	end
	if not sd.scanLeft then return false end
	if inDungeon() then return false end
	local cur = currentFloor()
	if not cur then return false end
	M._nextLearn = 0
	M.learnDrops()
	M._nextQuestLearn = 0
	pcall(M.learnQuests)
	for i = #sd.scanLeft, 1, -1 do if sd.scanLeft[i] == cur then table.remove(sd.scanLeft, i) end end
	local nxt = sd.scanLeft[1]
	if not nxt then
		sd.scanLeft, sd.scanTrip = nil, nil
		saveState()
		log("monster drops: read on every map")
		M._scanDoneAt = os.clock()
		pcall(M.goHome)
		return false
	end
	sd.scanTrip = os.time()
	saveState()
	if M.travelTo(nxt, "read monster drops") then task.wait(20) else table.remove(sd.scanLeft, 1) end
	return true
end
-- hunt one kind of monster on this map for a while
M.farmMob = function(name, secs)
	local t0, killed = os.clock(), 0
	while os.clock() - t0 < secs and M.running and not inDungeon() do
		if M.bountyWaiting() then log("gear: bounty showed up - doing it first") break end
		local _, hrp = char()
		if not hrp then task.wait(1) continue end
		local best, bd
		local se = workspace:FindFirstChild("SpawnedEntities")
		for _, e in ipairs(se and se:GetChildren() or {}) do
			if e.Name == name then
				local h = e:FindFirstChildOfClass("Humanoid")
				local p = mobPos(e)
				if h and h.Health > 0 and p then
					local dd = (p - hrp.Position).Magnitude
					if not bd or dd < bd then best, bd = e, dd end
				end
			end
		end
		if not best then
			status("Gear: waiting for " .. name .. " to spawn")
			-- some monsters are rare / timed spawns (not always on the map): don't sit there for the whole turn
			if killed == 0 and os.clock() - t0 > 60 then
				M.side.mobMissing = M.side.mobMissing or {}
				M.side.mobMissing[name] = os.time()
				saveState()
				log(("gear: %s is not on the map (rare spawn) - other places first, it gets killed whenever it shows up"):format(name))
				break
			end
			task.wait(2)
		else
			if M.side.mobMissing then M.side.mobMissing[name] = nil end
			status(("Gear: hunting %s for %s (%d killed)"):format(name, tostring(M.gearFarmFor), killed))
			if bd > 250 then warpToward(mobPos(best)) end
			pcall(kill, best)
			killed += 1
		end
	end
	release()
	if killed > 0 then log(("gear: killed %d x %s"):format(killed, name)) end
	return killed
end

-- a wanted rare monster shows up on the map you're on: hunt it right away
M.gearRareTick = function()
	if inDungeon() or not M.side.mobMissing or not next(M.side.mobMissing) then return false end
	if os.clock() < (M._nextRare or 0) then return false end
	M._nextRare = os.clock() + 10
	local cur = currentFloor()
	local se = workspace:FindFirstChild("SpawnedEntities")
	if not cur or not se then return false end
	for _, n in ipairs(M.gearNeeds or {}) do
		for key in pairs((M.loadDrops())[n.item] or {}) do
			local mob, fl = tostring(key):match("^(.+)@(%d+)$")
			if mob and tonumber(fl) == cur and M.side.mobMissing[mob] then
				for _, e in ipairs(se:GetChildren()) do
					local h = e.Name == mob and e:FindFirstChildOfClass("Humanoid")
					if h and h.Health > 0 then
						log(("gear: %s showed up - hunting it for %s"):format(mob, n.item))
						M.gearFarmFor = n.item
						M.farmMob(mob, 120)
						return true
					end
				end
			end
		end
	end
	return false
end

-- the places to run for the first thing that is still missing (Priority row "Gear goals")
-- how much of the wanted thing you hold right now (materials: the stack, gear: number of copies)
M.gearHave = function(item)
	local d = data()
	if not d then return 0 end
	local inv = d.Data.Inventory
	if inv.Materials and inv.Materials[item] then return tonumber(inv.Materials[item]) or 0 end
	local n = 0
	for _, cls in ipairs({ "Weapons", "Armor" }) do
		for _, it in pairs(inv[cls] or {}) do if type(it) == "table" and it.Name == item then n += 1 end end
	end
	return n
end
-- each place is measured: what it gave per minute. Every place is tried twice, then the best one is used.
M.gearMeasure = function()
	local sd = M.side
	local pend = sd.gearPending
	if not pend or inDungeon() then return end
	sd.gearPending = nil
	local gain = math.max(0, M.gearHave(pend.item) - (pend.have or 0))
	local secs = math.max(30, os.time() - (pend.t or os.time()))
	sd.gearStat = sd.gearStat or {}
	local st = sd.gearStat[pend.item .. "|" .. pend.key] or { runs = 0, gain = 0, secs = 0 }
	st.runs, st.gain, st.secs = st.runs + 1, st.gain + gain, st.secs + secs
	sd.gearStat[pend.item .. "|" .. pend.key] = st
	log(("gear: %s gave %d %s (%.1f per hour so far)"):format(pend.key, gain, pend.item, st.gain / st.secs * 3600))
end
M.gearFarmKeys = function()
	local sd = M.side
	sd.gearStat = sd.gearStat or {}
	for _, n in ipairs(M.gearNeeds or {}) do
		if M._gearMatsOnly and not n.mat then continue end -- Upgrade mode: only upgrade materials, item hunts wait for their turn
		-- drops are random everywhere, so a couple of runs prove little: every place gets 3 tries,
		-- the score is smoothed ((got + 1) / time, so one dry run doesn't rule a place out),
		-- and every 6th run goes to the least-tried place to keep the numbers honest
		local best, bestRate, untried, least, leastRuns
		for _, s in ipairs(M.gearSources(n.item)) do
			if s.farm and s.ok then
				local st = sd.gearStat[n.item .. "|" .. s.key]
				local runs = st and st.runs or 0
				if runs < 3 then
					untried = untried or s.key
				else
					local rate = (st.gain + 1) / math.max(60, st.secs)
					if not bestRate or rate > bestRate then best, bestRate = s.key, rate end
				end
				if not leastRuns or runs < leastRuns then least, leastRuns = s.key, runs end
			end
		end
		sd.gearPicks = (sd.gearPicks or 0) + 1
		local pick = untried or ((sd.gearPicks % 6 == 0) and least) or best
		if pick then
			M.gearFarmFor = n.item
			return { pick }
		end
	end
	M.gearFarmFor = nil
	return {}
end

local function scheduler()
	M.schedRunning = true
	setNoclip(true)
	local unlockDone = false
	while M.alive and anyOn() do
		task.wait(0.1) -- never spin without yielding (a tight loop here froze the game once)
		local ok, err = pcall(function()
			if not char() then
				status("Waiting for respawn...")
				release()
				task.wait(2)
				return
			end
			if inDungeon() then
				runDungeon()
				if not M.cycle.enabled then
					task.wait(3)
				end
				return
			end
			if sellTick() then return end
			if M.bountyTick() then return end -- a bounty on this map comes before everything else
			if M.on.unlock then
				unlockAll()
				local open, all = tpCount()
				if open >= all and not unlockDone then
					unlockDone = true
					log(("TP unlocked %d/%d"):format(open, all))
				end
			end
			if M.scanTick() then return end
			if M.gearRareTick() then return end
			if M.tpTourTick() then return end
			pcall(M.gearMeasure) -- count what the last run gave before upgrades spend it
			M.upgradeGear()
			pcall(M.gearTick)
			pcall(M.learnDrops)
			pcall(M.learnQuests)
			M.craftBetter()
			M.dropForeignQuests()
			M.collectOrbs()
			if M.on.stats then allocateStats() end
			if M.on.gear and os.clock() >= (M._nextGear or 0) then
				M._nextGear = os.clock() + 60
				equipBestGear()
				equipBestSkills()
			end
			if M.towerTripTick() then return end
			if M.prio.enabled then
				if not M.prioTick() then
					status("Priority list: nothing to do right now")
					task.wait(3)
				end
				return
			end
			if M.sideTick() then return end
			progressTick()
			cycleTick()
			if M.on.turnin then turnInAll() end
			if M.on.accept then acceptAll() end
			if M.on.turnin then turnInAll() end
			local worked = doOneQuest()
			M._noQuestWork = not worked
			if not worked then
				local list = {}
				for k, v in pairs(M.on) do if v then list[#list + 1] = LABELS[k] end end
				status("Waiting - nothing to do for: " .. table.concat(list, ", "))
				task.wait(3)
			end
		end)
		if not ok then
			log("ERR " .. tostring(err))
			task.wait(2)
		end
	end
	M.schedRunning = false
	if anyOn() and M.alive then task.spawn(scheduler) return end -- switched back on while exiting
	M.running = false
	release()
	setNoclip(false)
	status("Stopped")
end

local function toggle(name)
	M.on[name] = not M.on[name]
	task.defer(saveState)
	if name == "accept" and M.on[name] then lastAccept = -math.huge end -- accept right away
	repaintTasks()
	if anyOn() then
		M.running = true
		if not M.schedRunning then task.spawn(scheduler) end -- never two loops at once
	else
		M.running = false -- scheduler and any flight/fight in progress stop
	end
end

local function stopTask(keepSaved)
	for k in pairs(M.on) do M.on[k] = false end
	if not keepSaved then M.opt.nextFloor = false M.side.tower = false M.side.boss = false M.prio.enabled = false end
	M.cycle.enabled = false
	M.cycle.pending = nil
	if not keepSaved then saveState() end
	M.running = false
	repaintTasks()
	status("Stopped")
end
M.Toggle = toggle
M.Stop = stopTask
M.RunTask = toggle -- old name, kept for compatibility

local function toggleCycle()
	M.cycle.enabled = not M.cycle.enabled
	if M.cycle.enabled then
		M.cycle.mode = "quest"
		M.cycle.phaseStart = os.time()
		M.cycle.floor = currentFloor() or M.cycle.floor
		M.running = true
		if not M.schedRunning then task.spawn(scheduler) end
	elseif not anyOn() then
		M.running = false
	end
	saveState()
end
M.ToggleCycle = toggleCycle
M.KillMob = function(mob) return kill(mob) end
M.SafePos = safePos
M.Zones = zones

----------------------------------------------------------------------
-- UI: sidebar hub (left menu, cards with switches / sliders / dropdowns)
----------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local TI = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function corner(o, r) mk("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, c, t, tr) return mk("UIStroke", { Color = c, Thickness = t or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o) end
local function pad(o, l, r, t, b) mk("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r), PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b) }, o) end
local function list(o, gap, horiz) return mk("UIListLayout", { Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = horiz and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical }, o) end

local C = {
	bg = Color3.fromRGB(16, 18, 17), side = Color3.fromRGB(20, 22, 21), card = Color3.fromRGB(25, 28, 26),
	field = Color3.fromRGB(33, 37, 34), line = Color3.fromRGB(43, 48, 45), hover = Color3.fromRGB(38, 43, 40),
	text = Color3.fromRGB(234, 238, 235), dim = Color3.fromRGB(146, 154, 149),
	accent = Color3.fromRGB(110, 216, 118), off = Color3.fromRGB(56, 61, 58), red = Color3.fromRGB(214, 86, 86),
}
local F, FB = Enum.Font.GothamMedium, Enum.Font.GothamBold

local gui = mk("ScreenGui", { Name = "AutoAllUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1003 })
do
	local ok = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not ok or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
end

-- phones / tablets: touch screen without a keyboard. The window is scaled to fit the screen,
-- pages use one column, and a floating button shows / hides it (there is no Right Ctrl)
M.mobile = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or ((getgenv and getgenv()) or _G).__ForceMobile == true
local W, H, SIDE = 720, 470, M.mobile and 150 or 186
local main = mk("Frame", { Size = UDim2.new(0, W, 0, H), Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2), BackgroundColor3 = C.bg, BorderSizePixel = 0 }, gui)
corner(main, 12)
stroke(main, C.line)
do
	-- size: fits the screen, and you can make it bigger / smaller (corner grip, or Settings)
	local sc = mk("UIScale", { Scale = 1 }, main)
	M.fitUI = function()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local maxS = math.min((vp.X - 16) / W, (vp.Y - 16) / H)
		local want = tonumber(M.opt.uiScale) or 1
		sc.Scale = math.clamp(math.min(want, maxS), 0.4, 1.6)
	end
	M.fitUI()
	pcall(function() table.insert(conns, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(M.fitUI)) end)
	local grip = mk("TextButton", { Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -22, 1, -22), BackgroundTransparency = 1, Text = "◢", TextColor3 = C.dim, Font = FB, TextSize = 16, ZIndex = 20 }, main)
	local gStart, gScale
	table.insert(conns, grip.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then gStart, gScale = i.Position, sc.Scale end
	end))
	table.insert(conns, UIS.InputChanged:Connect(function(i)
		if gStart and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - gStart
			M.opt.uiScale = math.clamp(gScale * (W * gScale + (d.X + d.Y) / 2) / (W * gScale), 0.4, 1.6)
			M.fitUI()
		end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(i)
		if gStart and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			gStart = nil
			pcall(function() if M.Save then M.Save() end end)
		end
	end))
	-- folded: the window turns into the MOI HUB logo; tap / click it to open again, drag to move it
	local logo = mk("ImageButton", { Size = UDim2.new(0, 58, 0, 58), Position = UDim2.new(0, 12, 0.35, 0), BackgroundColor3 = Color3.fromRGB(10, 12, 18), Image = "", ScaleType = Enum.ScaleType.Fit, AutoButtonColor = true, ZIndex = 50, Visible = false }, gui)
	corner(logo, 12)
	stroke(logo, C.accent, 2)
	local logoTxt = mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, RichText = true, Text = '<font color="#FFFFFF">MOI</font>\n<font color="#FF2D55">HUB</font>', Font = Enum.Font.GothamBlack, TextSize = 15, ZIndex = 51 }, logo)
	task.spawn(function()
		pcall(function()
			local file = "moihub_logo.png"
			if not (isfile and isfile(file)) then
				local png = game:HttpGet("https://raw.githubusercontent.com/thanasankiminoto-art/auto-farm/main/moihub.png")
				if type(png) == "string" and #png > 500 then writefile(file, png) end
			end
			local get = getcustomasset or getsynasset
			if get and isfile(file) then
				M.logoAsset = get(file)
				logo.Image = M.logoAsset
				logoTxt.Visible = false
				logo.BackgroundTransparency = 1
			end
		end)
	end)
	M.setOpen = function(v)
		main.Visible = v
		logo.Visible = not v
	end
	table.insert(conns, main:GetPropertyChangedSignal("Visible"):Connect(function() logo.Visible = not main.Visible end))
	local downPos, startPos, moved
	table.insert(conns, logo.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			downPos, startPos, moved = i.Position, logo.Position, false
		end
	end))
	table.insert(conns, UIS.InputChanged:Connect(function(i)
		if downPos and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - downPos
			if d.Magnitude > 8 then moved = true end
			if moved then logo.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end
		end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(i)
		if downPos and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			if not moved then M.setOpen(true) end
			downPos = nil
		end
	end))
end

local paints = {}   -- every control's repaint
local refreshers = {} -- text that changes every second
local function repaintAll() for _, f in ipairs(paints) do pcall(f) end end
-- switches that exist both on a page and in the Priority list are one and the same:
-- with the list on they show / change the list row, with it off the page's own switch
M.FN_LEGACY = {
	floor = { function() return M.opt.nextFloor end, function(v) M.opt.nextFloor = v end },
	daily = { function() return M.side.daily end, function(v) M.side.daily = v end },
	boss = { function() return M.side.boss end, function(v) M.side.boss = v if v then M.side.nextBoss = 0 end end },
	tower = { function() return M.side.tower end, function(v) M.side.tower = v if v then M.side.nextTower = 0 end end },
	dungeons = { function() return M.cycle.enabled end, function(v) if (M.cycle.enabled and true or false) ~= v then toggleCycle() end end },
}
M.fnGet = function(id)
	if M.prio.enabled then return M.prio.on[id] and true or false end
	local l = M.FN_LEGACY[id]
	return l and l[1]() and true or false
end
M.fnSet = function(id, v)
	if M.prio.enabled then
		M.prio.on[id] = v
		if v then M.prio.nextAt[id] = 0 end
		-- a page switch flipped by hand while on Level up also makes the list your own (Custom)
		if M.getMode and M.getMode() == "level" then M.opt.focus = "normal" M.opt.gearMode = "balanced" M.opt.gearFirst = false end
	else
		local l = M.FN_LEGACY[id]
		if l then l[2](v) end
	end
	if v then M.running = true if not M.schedRunning then task.spawn(scheduler) end end
	task.defer(saveState)
	repaintAll()
end
local function save() task.defer(saveState) end

----------------------------------------------------------------------
-- sidebar
----------------------------------------------------------------------
local side = mk("Frame", { Size = UDim2.new(0, SIDE, 1, 0), BackgroundColor3 = C.side, BorderSizePixel = 0 }, main)
corner(side, 12)
mk("Frame", { Size = UDim2.new(0, 14, 1, 0), Position = UDim2.new(1, -14, 0, 0), BackgroundColor3 = C.side, BorderSizePixel = 0 }, side)
mk("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0), BackgroundColor3 = C.line, BorderSizePixel = 0 }, side)

local head = mk("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1 }, side)
M.VERSION = "v21z"
do
	local hl0 = mk("ImageLabel", { Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 13, 0, 12), BackgroundColor3 = Color3.fromRGB(10, 12, 18), BorderSizePixel = 0, Image = "", ScaleType = Enum.ScaleType.Fit }, head)
	corner(hl0, 9)
	stroke(hl0, C.accent, 1.5)
	local ht = mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, RichText = true, Text = '<font color="#FFFFFF">MOI</font>\n<font color="#FF2D55">HUB</font>', Font = Enum.Font.GothamBlack, TextSize = 10 }, hl0)
	task.spawn(function()
		local t0 = os.clock()
		while not M.logoAsset and os.clock() - t0 < 30 do task.wait(0.5) end
		if M.logoAsset then hl0.Image = M.logoAsset ht.Visible = false end
	end)
end
mk("TextLabel", { Size = UDim2.new(1, -66, 0, 18), Position = UDim2.new(0, 58, 0, 14), BackgroundTransparency = 1, RichText = true, Text = 'MOI <font color="#6ED876">HUB</font>', TextColor3 = C.text, Font = FB, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left }, head)
mk("TextLabel", { Size = UDim2.new(1, -66, 0, 14), Position = UDim2.new(0, 58, 0, 33), BackgroundTransparency = 1, Text = "Auto Farm  -  " .. M.VERSION, TextColor3 = C.dim, Font = F, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, head)

local nav = mk("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -62 - 58), Position = UDim2.new(0, 0, 0, 62), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, side)
pad(nav, 8, 8, 4, 8)
list(nav, 2)

-- profile at the bottom
local prof = mk("Frame", { Size = UDim2.new(1, 0, 0, 58), Position = UDim2.new(0, 0, 1, -58), BackgroundTransparency = 1 }, side)
mk("Frame", { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.new(0, 8, 0, 0), BackgroundColor3 = C.line, BorderSizePixel = 0 }, prof)
local av = mk("ImageLabel", { Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 12, 0, 12), BackgroundColor3 = C.field, BorderSizePixel = 0, Image = "" }, prof)
corner(av, 17)
task.spawn(function()
	local ok, img = pcall(function() return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
	if ok then av.Image = img end
end)
local nm = lp.Name
mk("TextLabel", { Size = UDim2.new(1, -60, 0, 16), Position = UDim2.new(0, 54, 0, 13), BackgroundTransparency = 1, Text = nm:sub(1, 2) .. string.rep("*", math.max(3, #nm - 2)), TextColor3 = C.text, Font = FB, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, prof)
local runLbl = mk("TextLabel", { Size = UDim2.new(1, -60, 0, 14), Position = UDim2.new(0, 54, 0, 30), BackgroundTransparency = 1, Text = "", TextColor3 = C.dim, Font = F, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, RichText = true }, prof)
refreshers[#refreshers + 1] = function()
	runLbl.Text = M.running and '<font color="#6ED876">Running</font>' or "Idle"
end

----------------------------------------------------------------------
-- content area
----------------------------------------------------------------------
local content = mk("Frame", { Size = UDim2.new(1, -SIDE, 1, 0), Position = UDim2.new(0, SIDE, 0, 0), BackgroundTransparency = 1 }, main)
local topbar = mk("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, content)
local crumb = mk("TextLabel", { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 16, 0, 0), BackgroundTransparency = 1, Text = "", TextColor3 = C.text, Font = FB, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, RichText = true }, topbar)
local function topBtn(x, txt, col)
	local b = mk("TextButton", { Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, x, 0, 9), BackgroundColor3 = C.field, Text = txt, TextColor3 = col or C.dim, Font = FB, TextSize = 14, AutoButtonColor = false }, topbar)
	corner(b, 7)
	return b
end
local minBtn = topBtn(-72, "-")
local closeBtn = topBtn(-38, "x", C.red)

local pagesHolder = mk("Frame", { Size = UDim2.new(1, -24, 1, -54), Position = UDim2.new(0, 12, 0, 46), BackgroundTransparency = 1, ClipsDescendants = true }, content)

local pages, navItems = {}, {}
local currentPage

local function newPage(id)
	local sf = mk("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.off, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false }, pagesHolder)
	local row = mk("Frame", { Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, sf)
	local left, right
	if M.mobile then
		list(row, 10)
		left = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1 }, row)
		right = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2 }, row)
	else
		left = mk("Frame", { Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, row)
		right = mk("Frame", { Size = UDim2.new(0.5, -5, 0, 0), Position = UDim2.new(0.5, 5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, row)
	end
	list(left, 10) list(right, 10)
	pad(row, 0, 0, 0, 12)
	pages[id] = sf
	return left, right
end

local function showPage(id)
	currentPage = id
	for pid, sf in pairs(pages) do sf.Visible = pid == id end
	for pid, it in pairs(navItems) do
		local on = pid == id
		TweenService:Create(it.btn, TI, { BackgroundTransparency = on and 0 or 1 }):Play()
		it.lbl.TextColor3 = on and C.text or C.dim
		it.dot.BackgroundColor3 = on and C.accent or C.off
		it.bar.Visible = on
	end
	local it = navItems[id]
	crumb.Text = ('%s  <font color="#7d857f">&gt;</font>  <font color="#9aa29c">%s</font>'):format(it.group, it.title)
end

local navOrder = 0
local function navGroup(text)
	navOrder += 1
	local l = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "  " .. text, TextColor3 = C.dim, Font = F, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = navOrder }, nav)
	return l
end
local function navItem(id, group, label, title)
	navOrder += 1
	local b = mk("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.field, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = navOrder }, nav)
	corner(b, 8)
	local bar = mk("Frame", { Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = C.accent, BorderSizePixel = 0, Visible = false }, b)
	corner(bar, 2)
	local dot = mk("Frame", { Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 14, 0.5, -5), BackgroundColor3 = C.off, BorderSizePixel = 0 }, b)
	corner(dot, 3)
	local lbl = mk("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 34, 0, 0), BackgroundTransparency = 1, Text = label, TextColor3 = C.dim, Font = F, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, b)
	navItems[id] = { btn = b, lbl = lbl, dot = dot, bar = bar, group = group, title = title or label }
	table.insert(conns, b.MouseEnter:Connect(function() if currentPage ~= id then b.BackgroundTransparency = 0.6 end end))
	table.insert(conns, b.MouseLeave:Connect(function() if currentPage ~= id then b.BackgroundTransparency = 1 end end))
	table.insert(conns, b.MouseButton1Click:Connect(function() showPage(id) end))
end

----------------------------------------------------------------------
-- cards + controls
----------------------------------------------------------------------
local function card(col, title, icon)
	local c = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.card, BorderSizePixel = 0 }, col)
	corner(c, 12)
	stroke(c, C.line)
	list(c, 0)
	local hd = mk("TextButton", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, c)
	local ib = mk("Frame", { Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 12, 0.5, -14), BackgroundColor3 = C.field, BorderSizePixel = 0 }, hd)
	corner(ib, 7)
	mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = icon or "*", TextColor3 = C.accent, Font = FB, TextSize = 13 }, ib)
	mk("TextLabel", { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 50, 0, 0), BackgroundTransparency = 1, Text = title, TextColor3 = C.text, Font = FB, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, hd)
	local chev = mk("TextLabel", { Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -32, 0, 0), BackgroundTransparency = 1, Text = "v", TextColor3 = C.dim, Font = FB, TextSize = 12 }, hd)
	local body = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2 }, c)
	pad(body, 14, 14, 0, 12)
	list(body, 6)
	local open = true
	table.insert(conns, hd.MouseButton1Click:Connect(function()
		open = not open
		body.Visible = open
		chev.Text = open and "v" or ">"
	end))
	return body
end

local order = 0
local function nextOrder() order += 1 return order end

local function toggleRow(body, label, get, set)
	local row = mk("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = nextOrder() }, body)
	mk("TextLabel", { Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = C.text, Font = F, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
	local pill = mk("Frame", { Size = UDim2.new(0, 42, 0, 24), Position = UDim2.new(1, -42, 0.5, -12), BackgroundColor3 = C.off, BorderSizePixel = 0 }, row)
	corner(pill, 12)
	local glow = stroke(pill, C.accent, 2, 1)
	local knob = mk("Frame", { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Color3.fromRGB(28, 32, 29), BorderSizePixel = 0 }, pill)
	corner(knob, 9)
	local last
	local function paint()
		local on = get() and true or false
		if on == last then return end
		last = on
		TweenService:Create(pill, TI, { BackgroundColor3 = on and C.accent or C.off }):Play()
		TweenService:Create(knob, TI, { Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = on and Color3.fromRGB(22, 40, 24) or Color3.fromRGB(150, 156, 152) }):Play()
		TweenService:Create(glow, TI, { Transparency = on and 0.55 or 1 }):Play()
	end
	paint()
	paints[#paints + 1] = paint
	table.insert(conns, row.MouseButton1Click:Connect(function()
		set(not get())
		paint()
	end))
	return paint
end

local function optToggle(body, label, key)
	return toggleRow(body, label, function() return M.opt[key] end, function(v) M.opt[key] = v save() end)
end
local function funcToggle(body, name, label)
	local p = toggleRow(body, label or LABELS[name], function() return M.on[name] end, function() toggle(name) end)
	taskButtons[name] = p
	return p
end

local function sliderRow(body, label, lo, hi, step, get, set, fmt)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = nextOrder() }, body)
	mk("TextLabel", { Size = UDim2.new(1, -110, 0, 26), BackgroundTransparency = 1, Text = label, TextColor3 = C.text, Font = F, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
	local minus = mk("TextButton", { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -104, 0, 1), BackgroundColor3 = C.field, Text = "-", TextColor3 = C.text, Font = FB, TextSize = 14 }, row)
	corner(minus, 6)
	local vb = mk("TextBox", { Size = UDim2.new(0, 50, 0, 24), Position = UDim2.new(1, -77, 0, 1), BackgroundColor3 = C.field, Text = "", TextColor3 = C.accent, Font = FB, TextSize = 12, ClearTextOnFocus = false }, row)
	corner(vb, 6)
	local plus = mk("TextButton", { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -24, 0, 1), BackgroundColor3 = C.field, Text = "+", TextColor3 = C.text, Font = FB, TextSize = 14 }, row)
	corner(plus, 6)
	local hit = mk("TextButton", { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 28), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, row)
	local track = mk("Frame", { Size = UDim2.new(1, -8, 0, 6), Position = UDim2.new(0, 4, 0.5, -3), BackgroundColor3 = C.off, BorderSizePixel = 0 }, hit)
	corner(track, 3)
	local fill = mk("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.accent, BorderSizePixel = 0 }, track)
	corner(fill, 3)
	local knob = mk("Frame", { Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2 }, track)
	corner(knob, 8)
	local function paint()
		local v = get()
		local a = math.clamp((v - lo) / (hi - lo), 0, 1)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		if not vb:IsFocused() then vb.Text = (fmt or "%d"):format(v) end
	end
	paint()
	paints[#paints + 1] = paint
	local function put(v)
		v = math.clamp(lo + math.floor(((tonumber(v) or get()) - lo) / step + 0.5) * step, lo, hi)
		if v ~= get() then set(v) end
		paint()
	end
	local dragging = false
	local function setFromX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		put(lo + a * (hi - lo))
	end
	table.insert(conns, hit.MouseButton1Down:Connect(function(x) dragging = true setFromX(x) end))
	table.insert(conns, hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true setFromX(i.Position.X) end
	end))
	table.insert(conns, UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setFromX(i.Position.X) end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			save()
		end
	end))
	table.insert(conns, minus.MouseButton1Click:Connect(function() put(get() - step) save() end))
	table.insert(conns, plus.MouseButton1Click:Connect(function() put(get() + step) save() end))
	table.insert(conns, vb.FocusLost:Connect(function() put(vb.Text) save() end))
	return paint
end

-- options(): list of { value, label }. multi: get() returns a set table
local function dropdownRow(body, label, options, get, set, multi)
	local wrap = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder() }, body)
	list(wrap, 4)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = label, TextColor3 = C.text, Font = F, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, wrap)
	local box = mk("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.field, Text = "", AutoButtonColor = false, LayoutOrder = 2 }, wrap)
	corner(box, 8)
	local cur = mk("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = "", TextColor3 = C.text, Font = F, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, box)
	local chev = mk("TextLabel", { Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -28, 0, 0), BackgroundTransparency = 1, Text = "v", TextColor3 = C.dim, Font = FB, TextSize = 12 }, box)
	local drop = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.field, BorderSizePixel = 0, Visible = false, LayoutOrder = 3 }, wrap)
	corner(drop, 8)
	stroke(drop, C.line)
	pad(drop, 4, 4, 4, 4)
	list(drop, 2)
	local function paint()
		local opts = options()
		local names = {}
		for _, o in ipairs(opts) do
			local on = multi and get()[o[1]] or (not multi and get() == o[1])
			if on then names[#names + 1] = multi and o[1] or o[2] end
		end
		cur.Text = #names > 0 and table.concat(names, ", ") or "--"
		if drop.Visible then
			for _, c in ipairs(drop:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
			for i, o in ipairs(opts) do
				local on = multi and get()[o[1]] or (not multi and get() == o[1])
				local b = mk("TextButton", { Size = UDim2.new(1, 0, 0, 28), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = on and C.hover or C.field, Text = "", AutoButtonColor = false, LayoutOrder = i }, drop)
				corner(b, 6)
				-- long option text wraps onto a second line instead of running under the ON mark
				local ol = mk("TextLabel", { Size = UDim2.new(1, -54, 0, 28), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = o[2], TextColor3 = on and C.text or C.dim, Font = F, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left }, b)
				mk("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, ol)
				if on then mk("TextLabel", { Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -34, 0, 0), BackgroundTransparency = 1, Text = "ON", TextColor3 = C.accent, Font = FB, TextSize = 10 }, b) end
				b.MouseButton1Click:Connect(function()
					set(o[1])
					save()
					if not multi then drop.Visible = false chev.Text = "v" end
					paint()
				end)
			end
		end
	end
	paint()
	paints[#paints + 1] = paint
	table.insert(conns, box.MouseButton1Click:Connect(function()
		drop.Visible = not drop.Visible
		chev.Text = drop.Visible and "^" or "v"
		paint()
	end))
	return paint
end

local function textRow(body, fn, h)
	local l = mk("TextLabel", { Size = UDim2.new(1, 0, 0, h or 18), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = "", TextColor3 = C.dim, Font = F, TextSize = 12, TextWrapped = true, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = nextOrder() }, body)
	if type(fn) == "function" then
		refreshers[#refreshers + 1] = function() l.Text = fn() end
	else
		l.Text = fn
	end
	return l
end

local function buttonRow(body, text, col, cb)
	local b = mk("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = col or C.field, Text = text, TextColor3 = col and Color3.fromRGB(18, 22, 19) or C.text, Font = FB, TextSize = 13, AutoButtonColor = true, LayoutOrder = nextOrder() }, body)
	corner(b, 8)
	table.insert(conns, b.MouseButton1Click:Connect(cb))
	return b
end

local function hl(v) return ('<font color="#E9EEEA">%s</font>'):format(tostring(v)) end

----------------------------------------------------------------------
-- pages
----------------------------------------------------------------------
navGroup("Main")
navItem("home", "Main", "Home", "Overview")
navItem("quests", "Main", "Quests", "Auto Quest")
navItem("combat", "Main", "Combat", "Fighting")
navGroup("Farming")
navItem("prio", "Farming", "Priority", "Priority List")
navItem("dungeon", "Farming", "Dungeons", "Dungeon Cycle")
navItem("tower", "Farming", "Tower", "Tower")
navItem("boss", "Farming", "Bosses", "Boss Farm")
navItem("progress", "Farming", "Progression", "Next Floor")
navItem("character", "Farming", "Character", "Stats & Gear")
navItem("gear", "Farming", "Gear Goals", "Pick + Upgrade")
navGroup("Other")
navItem("teleport", "Other", "Teleport", "Maps")
navItem("settings", "Other", "Settings", "Window")

-- ONE MODE SWITCH: three big buttons, only one is on. Below them: what runs and what waits.
M.MODES = {
	{ id = "farm", name = "Custom", hint = "your own ON / OFF list below" },
	{ id = "level", name = "Level up", hint = "EXP only, to reach the next map" },
	{ id = "gear", name = "Upgrade gear", hint = "upgrade materials first, then farm" },
}
M.getMode = function()
	if M.opt.focus == "level" then return "level" end
	if M.gearMode and M.gearMode() == "upgrade" then return "gear" end
	return "farm"
end
-- the Priority rows show what each mode does: Level up switches them to its own set,
-- Custom / Upgrade gear bring your own set back (kept in prio.custom)
M.LEVEL_ROWS = { floor = true, daily = true, quests = true, dungeons = true, boss = true }
M.setMode = function(id)
	local pr = M.prio
	local was = M.getMode()
	if was ~= "level" then
		pr.custom = {}
		for k, v in pairs(pr.on) do pr.custom[k] = v end
		if was == "gear" then pr.custom.gear = pr.customGear end
	end
	if id == "level" then
		for _, k in ipairs(pr.order) do pr.on[k] = M.LEVEL_ROWS[k] or false end
	else
		for k, v in pairs(pr.custom or {}) do pr.on[k] = v end
		if id == "gear" then pr.customGear = pr.on.gear pr.on.gear = true end
	end
	M.opt.focus = id == "level" and "level" or "normal"
	M.opt.gearMode = id == "gear" and "upgrade" or "balanced"
	M.opt.gearFirst = id == "gear"
	if not M.prio.enabled then M.setPrio(true) end
	M.running = true
	if not M.schedRunning then task.spawn(scheduler) end
	M._nextGearGoal = 0
	save()
	repaintAll()
end
M.modeSummary = function()
	local m = M.getMode()
	local pr = M.prio
	local L0 = M.PRIO_LABEL or {}
	local function name(id) return (tostring(L0[id] or id):gsub("%s*%(.*$", "")) end
	local doing, waiting = {}, {}
	if m == "level" then
		doing = { "Next floor", "Daily boss", "Quests", "Dungeons", "Floor boss" }
		waiting = { "Tower", "Catacombs", "Battle Arena", "The Ether", "Gear farming" }
	else
		for _, id in ipairs(pr.order) do
			if pr.on[id] then doing[#doing + 1] = name(id) else waiting[#waiting + 1] = name(id) end
		end
		if m == "gear" then table.insert(doing, 1, "Upgrade materials (while gear is below your level)") end
	end
	local always = {}
	if M.opt.bounty then always[#always + 1] = "bounty hunt" end
	if M.opt.autoSell then always[#always + 1] = "auto sell" end
	if M.on and M.on.gear then always[#always + 1] = "best gear" end
	if M.on and M.on.stats then always[#always + 1] = "stat points" end
	if M.gearAny and M.gearAny() then always[#always + 1] = "gear goal upgrades" end
	local txt = ('<font color="#6ED876">Does:</font> %s\n<font color="#d65656">Waits:</font> %s'):format(table.concat(doing, ", "), #waiting > 0 and table.concat(waiting, ", ") or "nothing")
	if #always > 0 then txt = txt .. ('\n<font color="#9aa29c">Always on the side:</font> %s'):format(table.concat(always, ", ")) end
	if not pr.enabled then txt = '<font color="#d65656">Priority list is off: the pages\' own switches decide. Pick a mode to turn it on.</font>' end
	return txt
end
M.modeCard = function(col)
	local c = card(col, "Mode", "M")
	local holder = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder() }, c)
	list(holder, 6)
	local btns = {}
	for i, md in ipairs(M.MODES) do
		local b = mk("TextButton", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.field, Text = "", AutoButtonColor = false, LayoutOrder = i }, holder)
		corner(b, 9)
		local st = stroke(b, C.line, 1)
		local dot = mk("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 12, 0.5, -6), BackgroundColor3 = C.off, BorderSizePixel = 0 }, b)
		corner(dot, 6)
		mk("TextLabel", { Size = UDim2.new(1, -40, 0, 18), Position = UDim2.new(0, 32, 0, 4), BackgroundTransparency = 1, Text = md.name, TextColor3 = C.text, Font = FB, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, b)
		mk("TextLabel", { Size = UDim2.new(1, -40, 0, 14), Position = UDim2.new(0, 32, 0, 21), BackgroundTransparency = 1, Text = md.hint, TextColor3 = C.dim, Font = F, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, b)
		btns[md.id] = { b = b, st = st, dot = dot }
		table.insert(conns, b.MouseButton1Click:Connect(function() M.setMode(md.id) end))
	end
	local function paint()
		local cur = M.getMode()
		for id, x in pairs(btns) do
			local on = id == cur
			x.b.BackgroundColor3 = on and C.hover or C.field
			x.st.Color = on and C.accent or C.line
			x.dot.BackgroundColor3 = on and C.accent or C.off
		end
	end
	paint()
	paints[#paints + 1] = paint
	refreshers[#refreshers + 1] = paint
	textRow(c, function() return M.modeSummary() end, 70)
	return c
end

-- HOME
do
	local L, R = newPage("home")
	M.modeCard(L)
	local b = card(L, "Status", "S")
	statusLabel = textRow(b, "", 34)
	statusLabel.TextColor3 = C.text
	statusLabel.Text = "Ready"
	textRow(b, function()
		local q = M.focus and questById(M.focus)
		return "Current quest: " .. hl(q and ("%s [%s/%s]"):format(tostring(q.Title or q.ID), tostring(q.Progress), tostring(q.Amount)) or "-")
	end)
	textRow(b, function()
		if not M.cycle.enabled then return "Dungeon cycle: " .. hl("off") end
		if (M.cycle.trigger or "time") == "alldone" then
			if M.cycle.mode == "dungeon" then
				return ("Dungeon cycle: %s, %s left this lap (no timer)"):format(hl("dungeons"), hl(M.cycle.lapLeft or 0))
			end
			return "Dungeon cycle: " .. hl("clearing all quests first") .. " (no timer)"
		end
		local lim = (M.cycle.mode == "dungeon" and M.cycle.dungeonMin or M.cycle.questMin) * 60
		return ("Dungeon cycle: %s, %s min left"):format(hl(M.cycle.mode), hl(math.max(0, math.ceil((lim - (os.time() - (M.cycle.phaseStart or 0))) / 60))))
	end)
	local st = card(R, "Character", "C")
	textRow(st, function()
		local d = data()
		local f = floorInfo and floorInfo()
		local hum = char()
		return ("Level %s   |   Floor %s   |   HP %s"):format(hl(d and d.Data.Leveling.Level or "?"), hl(f and f.cur or "?"), hl(hum and math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) or "-"))
	end)
	textRow(st, function()
		local open, all = tpCount()
		local d = data()
		return ("Kills %s   Turned in %s   Dodged %s\nTP %s   Free stat points %s"):format(hl(M.kills), hl(M.turnedIn), hl(M.dodges), hl(open .. "/" .. all), hl(d and d.Data.Stats.Points or 0))
	end, 34)
	textRow(st, function()
		local d = data()
		if not d then return "" end
		local eq = d.Data.Equipped
		local function one(x) return type(x) == "table" and (x.Name .. " " .. hl("Lv " .. tostring(x.Leveling and x.Leveling.Level or "?"))) or '<font color="#7d857f">empty</font>' end
		return ("Hand 1: %s\nHand 2: %s\nArmor: %s"):format(one(eq.Hands and eq.Hands[1]), one(eq.Hands and eq.Hands[2]), one(eq.Armor))
	end, 50)
	local lg = card(R, "Log", "L")
	textRow(lg, function()
		local t = {}
		for i = math.max(1, #M.logs - 6), #M.logs do t[#t + 1] = (tostring(M.logs[i]):gsub("^%S+ ", ""):gsub("&", "&amp;"):gsub("<", "&lt;")) end
		return table.concat(t, "\n")
	end, 110)
end

-- QUESTS
do
	local L, R = newPage("quests")
	local b = card(L, "Auto Quest", "Q")
	funcToggle(b, "accept", "Accept quests")
	funcToggle(b, "kill", "Do kill quests")
	funcToggle(b, "find", "Do find-item quests")
	funcToggle(b, "talk", "Do talk-to-NPC quests")
	funcToggle(b, "turnin", "Turn in finished quests")
	if M.opt.oldQuests == nil then M.opt.oldQuests = true end
	optToggle(b, "Go back for quests left on lower maps", "oldQuests")
	if M.opt.dailyTour == nil then M.opt.dailyTour = true end
	optToggle(b, "Daily quests on every map (once a day each)", "dailyTour")
	optToggle(b, "Skip failed quests 30 min", "longSkip")
	textRow(b, "One quest at a time: finish it, hand it in, take new ones, then the next.")
	local t = card(L, "Teleports", "T")
	funcToggle(t, "unlock", "Unlock all TP points")
	textRow(t, function()
		local d = data()
		local frp = d and d.Data.FloorRespawnPoints or {}
		local cur = currentFloor()
		local lines = {}
		for _, f in ipairs(M.floorList()) do
			local key = tostring(f.n)
			local have = 0
			for _ in pairs(frp[key] or {}) do have += 1 end
			local total = (M.side.tpTotal or {})[key]
			if f.n == cur then local o, a = tpCount() total = math.max(a, total or 0) end
			if total then total = math.max(total, have) end
			local txt = not f.ok and '<font color="#9aa29c">locked map</font>' or total == 0 and '<font color="#9aa29c">no TP points</font>'
				or hl(have .. "/" .. (total and tostring(total) or "?"))
			lines[#lines + 1] = ("%s: %s"):format(f.name, txt)
		end
		return table.concat(lines, "\n")
	end, 92)
	textRow(t, "TP points belong to each map. With this on, the script finishes this map, then visits every other map you can reach, unlocks its points there and goes back home. ? = not visited yet.")
	local ql = card(R, "Quests In Progress", "L")
	textRow(ql, function()
		local t = {}
		for _, x in ipairs(quests()) do
			local mark = x.ID == M.focus and '<font color="#6ED876">> </font>' or "   "
			local what = x.Objective == "Kill" and ("kill " .. tostring(x.MobToKill)) or x.Objective == "Return" and "ready to turn in" or tostring(x.Objective)
			t[#t + 1] = ("%s%s - %s [%s/%s]"):format(mark, tostring(x.Title or x.ID), what, tostring(x.Progress or 0), tostring(x.Amount or 1))
		end
		return #t > 0 and table.concat(t, "\n") or "No quests"
	end, 90)
	local qb = card(R, "All Quests By Map", "A")
	textRow(qb, function() return M.questBookText() end, 120)
	textRow(qb, "The game only shows a map's quest givers while you are on it, so each map's list fills in on the first visit (the drop / TP tours visit them all). Quests that open later in a chain show up once they appear.")
end

-- COMBAT
do
	local L, R = newPage("combat")
	local b = card(L, "Fighting", "F")
	optToggle(b, "Use skills", "skills")
	optToggle(b, "Dodge attacks (red areas)", "dodge")
	optToggle(b, "Fly up to heal at low HP", "retreat")
	dropdownRow(b, "Attack Position", function() return { { true, "Underground (below the mob)" }, { false, "Above the mob" } } end,
		function() return M.opt.under end, function(v) M.opt.under = v end)
	sliderRow(b, "Start Distance (studs)", MIN_DIST, MAX_DIST, 1, function() return M.opt.dist end, function(v) M.opt.dist = v end)
	sliderRow(b, "Skip mobs taking over (min)", 1, 15, 1, function() return M.opt.maxFightMin or 3 end, function(v) M.opt.maxFightMin = v end)
	textRow(b, function()
		local dps = (M._dmgTime or 0) > 20 and (M._dmg or 0) / M._dmgTime or nil
		return "Your damage: " .. hl(dps and ("%.0f per second"):format(dps) or "measuring...") .. "  (a mob you died to is skipped 30 min)"
	end)
	sliderRow(b, "Heal skill below HP (%)", 20, 95, 5, function() return M.opt.healAt or 70 end, function(v) M.opt.healAt = v end)
	local sk = card(R, "Skills", "K")
	textRow(sk, function()
		local d = data()
		if not d then return "" end
		local class = d.Data.Equipped.Hands[1] and d.Data.Equipped.Hands[1].Class
		local bar = {}
		for _, v in ipairs((class and d.Data.Equipped.Hotbar.Skills[class]) or {}) do if type(v) == "table" then bar[v.Name] = true end end
		local alloc = d.Data.Stats.Allocations
		local t = {}
		for _, name in ipairs(SKILL_PRIORITY) do
			if (d.Data.Skills or {})[name] then
				local inf = SkillsMod[name] and SkillsMod[name].Info
				local need = {}
				for st, n in pairs((inf and inf.Requirements and inf.Requirements.Stats) or {}) do
					if (alloc[st] or 0) < n then need[#need + 1] = ("%s %d/%d"):format(st:sub(1, 3), alloc[st] or 0, n) end
				end
				if #need == 0 then
					t[#t + 1] = ('<font color="#6ED876">%s</font>  %s'):format(name, bar[name] and "in use" or "ready")
				else
					t[#t + 1] = ('<font color="#9aa29c">%s</font>  needs %s'):format(name, table.concat(need, ", "))
				end
			end
		end
		return table.concat(t, "\n")
	end, 120)
	textRow(sk, "Skills that are ready get slotted automatically (with 'Best gear + skills' ON) and are used in every fight.")
	local r = card(R, "How It Works", "?")
	textRow(r, "Before every enemy attack the game sends the red area to your client. The script leaves that area right away, keeps hitting from up to ~35 studs, then goes back to its spot.")
	textRow(r, function() return "Attacks dodged this session: " .. hl(M.dodges) end)
end

-- DUNGEONS
do
	local L, R = newPage("dungeon")
	local b = card(L, "Dungeon Cycle", "D")
	toggleRow(b, "Run dungeons", function() return M.fnGet("dungeons") end, function(v) M.fnSet("dungeons", v) end)
	textRow(b, function()
		if M.prio.enabled then
			return "Same switch as Dungeons on the Priority list. Runs the dungeons picked below in its turn; the minutes / trigger settings here are not used (Priority page: Waiting Time)."
		end
		return "Priority list is off: switches between quests and dungeons with the minutes / trigger below."
	end, 46)
	sliderRow(b, "Quests For (minutes)", 0, 120, 1, function() return M.cycle.questMin end, function(v) M.cycle.questMin = v end)
	sliderRow(b, "Dungeon For (minutes)", 1, 120, 1, function() return M.cycle.dungeonMin end, function(v) M.cycle.dungeonMin = v end)
	dropdownRow(b, "Go To Dungeon When", function()
		return { { "time", "Quest time is up" }, { "finish", "Time is up + current quest finished" }, { "alldone", "Clear ALL quests on the map first" } }
	end, function() return M.cycle.trigger or "time" end, function(v) M.cycle.trigger = v end)
	-- only real dungeons here: bosses, daily bosses, Tower, Catacombs, Arena and Ether have their own switches
	local function plainDungeons()
		local t = {}
		for _, n in ipairs(dungeonsForFloor(currentFloor() or M.cycle.floor or 2)) do if not n:find(":") then t[#t + 1] = n end end
		return t
	end
	for k in pairs(M.cycle.dungeons) do if tostring(k):find(":") then M.cycle.dungeons[k] = nil end end
	local function dgOpts()
		local out = { { "__all", "All dungeons" } }
		for i, n in ipairs(plainDungeons()) do
			local label = n:sub(1, 5) == "BOSS:" and ("Boss: " .. n:sub(6)) or n:sub(1, 6) == "DAILY:" and ("Daily boss: " .. n:sub(7)) or n:sub(1, 6) == "TOWER:" and n:sub(7) or n:sub(1, 5) == "CATA:" and n:sub(6) or (n:sub(1, 6) == "ARENA:" or n:sub(1, 6) == "ETHER:") and n:sub(7) or n
			out[#out + 1] = { n, ("%d. %s  (XP %d)"):format(i, label, (M._dgXP or {})[n] or 0) }
		end
		return out
	end
	dropdownRow(b, "Dungeons", dgOpts, function()
		local t = {}
		local all, any = true, false
		for _, n in ipairs(plainDungeons()) do
			if M.cycle.dungeons[n] then t[n] = true any = true else all = false end
		end
		if all and any then t.__all = true end
		return t
	end, function(v)
		local names = plainDungeons()
		if v == "__all" then
			local allOn = true
			for _, n in ipairs(names) do if not M.cycle.dungeons[n] then allOn = false end end
			for _, n in ipairs(names) do M.cycle.dungeons[n] = not allOn end
		else
			M.cycle.dungeons[v] = not M.cycle.dungeons[v]
		end
	end, true)
	optToggle(b, "Auto pick dungeon fortune", "autoFortune")
	local r = card(R, "Cycle Status", "i")
	textRow(r, function()
		if not M.cycle.enabled then return "Cycle is off." end
		local lim = (M.cycle.mode == "dungeon" and M.cycle.dungeonMin or M.cycle.questMin) * 60
		local left = math.max(0, lim - (os.time() - (M.cycle.phaseStart or 0)))
		local trig = ({ time = "when quest time is up", finish = "after time is up and the current quest is done", alldone = "after every quest on the map is cleared" })[M.cycle.trigger or "time"]
		if (M.cycle.trigger or "time") == "alldone" then
			return ("Phase: %s\nNo timer: all quests first, then every selected dungeon once (%s left this lap), repeat."):format(hl(M.cycle.mode), hl(M.cycle.mode == "dungeon" and (M.cycle.lapLeft or 0) or "-"))
		end
		return ("Phase: %s\nTime left: %s min\nGo to dungeon: %s"):format(hl(M.cycle.mode), hl(math.ceil(left / 60)), hl(trig))
	end, 50)
	textRow(r, "Dungeons are sorted easy to hard. With none picked on a new floor, the hardest one there is used.")
end

M.gearModeRows = function(body)
	dropdownRow(body, "Gear mode", function()
		return {
			{ "balanced", "Balanced - gear takes turns with everything" },
			{ "upgrade", "Upgrade first - then EXP until next level" },
			{ "gearonly", "Gear only - until every pick is done" },
		}
	end, function() return M.gearMode() end, function(v)
		M.opt.gearMode = v
		M.opt.gearFirst = v == "upgrade"
		M._nextGearGoal = 0
		M.running = true
		if not M.schedRunning then task.spawn(scheduler) end
	end)
	textRow(body, function()
		local m = M.gearMode()
		if m == "balanced" then
			return "Balanced: when gear's turn comes it farms \"Gear runs in a row\" runs, then quests, dungeons and the rest get their turns. Slowest for gear, nothing else waits."
		elseif m == "gearonly" then
			return "Gear only: once gear's turn comes nothing else runs until every pick is owned and as high as your level allows - including hunting drops you don't have yet (Next floor and Daily boss still go first)."
		end
		if M._gearModeOn then return ("Upgrade first - now farming %s; nothing else until the gear matches your level. Hunting drops you don't own still takes normal turns."):format(hl(M.gearFarmFor or "...")) end
		return "Upgrade first: whenever your gear is below your level it farms upgrade materials before anything else; once it matches, normal farming (quests / dungeons for EXP) until the next level-up. Hunting drops you don't own takes normal turns."
	end, 60)
end
-- PRIORITY
do
	local L, R = newPage("prio")
	M.prioMigrate()
	textRow(card(L, "Mode", "M"), function()
		local cur = M.getMode()
		local nm = cur
		for _, md in ipairs(M.MODES) do if md.id == cur then nm = md.name end end
		return ("Mode: %s  (change it on the Home page)"):format(hl(nm))
	end, 18)
	textRow(card(L, "Level", "L"), function()
		local d = data()
		local lv = d and d.Data.Leveling or {}
		local f = floorInfo and floorInfo()
		local nextTxt = ""
		if f and f.nextN and f.needLevel then
			nextTxt = (f.level or lv.Level or 0) >= f.needLevel and ("\nNext map %s is open"):format(hl(tostring(f.nextName))) or ("\nNext map %s needs Lv %s"):format(hl(tostring(f.nextName)), hl(f.needLevel))
		end
		return ("Level %s  (%s / %s EXP)%s"):format(hl(lv.Level or "?"), hl(lv.Experience or 0), hl(lv.ExperienceCap or "?"), nextTxt)
	end, 34)
	local b = card(L, "Priority List", "P")
	toggleRow(b, "Use the priority list", function() return M.prio.enabled end, function(v)
		M.setPrio(v)
		if v and not M.schedRunning then task.spawn(scheduler) end
		repaintAll()
	end)
	textRow(b, "Top to bottom: every pass does the first task that has something to do. Move tasks with the arrows, switch them on / off.")
	local rows = {}
	for i = 1, #M.prio.order do
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.field, BorderSizePixel = 0, LayoutOrder = nextOrder() }, b)
		corner(row, 7)
		local num = mk("TextLabel", { Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = tostring(i), TextColor3 = C.dim, Font = FB, TextSize = 12 }, row)
		local lbl = mk("TextLabel", { Size = UDim2.new(1, -128, 1, 0), Position = UDim2.new(0, 28, 0, 0), BackgroundTransparency = 1, Text = "", TextColor3 = C.text, Font = F, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
		local upB = mk("TextButton", { Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -96, 0.5, -11), BackgroundColor3 = C.card, Text = "^", TextColor3 = C.text, Font = FB, TextSize = 12 }, row)
		local dnB = mk("TextButton", { Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -72, 0.5, -11), BackgroundColor3 = C.card, Text = "v", TextColor3 = C.text, Font = FB, TextSize = 12 }, row)
		local onB = mk("TextButton", { Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -46, 0.5, -11), BackgroundColor3 = C.off, Text = "OFF", TextColor3 = C.text, Font = FB, TextSize = 11 }, row)
		corner(upB, 5) corner(dnB, 5) corner(onB, 11)
		rows[i] = function()
			local id = M.prio.order[i]
			lbl.Text = M.PRIO_LABEL[id] or tostring(id)
			local on = M.prio.on[id]
			onB.Text = on and "ON" or "OFF"
			onB.BackgroundColor3 = on and C.accent or C.off
			onB.TextColor3 = on and Color3.fromRGB(18, 30, 20) or C.dim
			lbl.TextColor3 = on and C.text or C.dim
		end
		local function swap(j)
			if j < 1 or j > #M.prio.order then return end
			M.prio.order[i], M.prio.order[j] = M.prio.order[j], M.prio.order[i]
			save()
			for _, f in ipairs(rows) do f() end
		end
		table.insert(conns, upB.MouseButton1Click:Connect(function() swap(i - 1) end))
		table.insert(conns, dnB.MouseButton1Click:Connect(function() swap(i + 1) end))
		table.insert(conns, onB.MouseButton1Click:Connect(function()
			local id = M.prio.order[i]
			M.prio.on[id] = not M.prio.on[id]
			if M.prio.on[id] then M.prio.nextAt[id] = 0 end
			-- changing a row by hand while on Level up turns this into your own (Custom) list
			if M.getMode() == "level" then M.opt.focus = "normal" M.opt.gearMode = "balanced" M.opt.gearFirst = false end
			save()
			repaintAll()
		end))
		rows[i]()
		paints[#paints + 1] = rows[i]
	end
	local r = card(R, "How It Decides", "?")
	textRow(r, "Quests run until none is left on the map. Daily bosses are tried once a day. Then Dungeons, Catacombs, Arena, Ether, Boss farm and Tower take turns in list order. Tower / Catacombs / Arena leave after the number of floors you set; Dungeons / Ether / Boss farm wait their minutes before repeating.")
	local fg = card(R, "Tower Goal (stop for good)", "G")
	sliderRow(fg, "Tower: leave after clearing floor", 10, 5000, 10, function()
		if (M.side.towerGoal or 0) % 10 == 1 then M.side.towerGoal = M.side.towerGoal - 1 end
		return M.side.towerGoal or 600
	end, function(v)
		M.side.towerGoal = v
		if (M.side.towerBest or 0) <= v then M.side.towerDone = false end
	end)
	textRow(fg, function()
		local bs = M.side.best or {}
		return ("Best so far: %s%s"):format(hl(M.side.towerBest or 0), M.side.towerDone and ' <font color="#6ED876">(done)</font>' or "")
	end)
	toggleRow(fg, "Run the Tower again after the goal", function() return M.side.towerRepeat end, function(v)
		M.side.towerRepeat = v
		if v then M.side.towerDone = false end
		save()
		repaintAll()
	end)
	textRow(fg, function()
		if M.side.towerRepeat then
			return ("On: clears up to the goal floor, leaves, and comes back in its turn (from floor 1 again). Runs to the goal so far: %s"):format(hl(M.side.towerRuns or 0))
		end
		return "Off: once the goal floor is cleared the Tower is never entered again."
	end, 34)
	local fv = card(R, "Floors Per Visit (then switch)", "F")
	for _, kd in ipairs({ { "cata", "Catacombs" }, { "arena", "Battle Arena" } }) do
		sliderRow(fv, kd[2], 0, 2000, 5, function() return (M.side.per or {})[kd[1]] or 0 end, function(v)
			M.side.per = M.side.per or {}
			M.side.per[kd[1]] = v
		end)
	end
	textRow(fv, "These never end on their own, so they go by floors: clear this many floors, leave, and the next task in the list takes its turn. 0 = stay until the run ends. Catacombs and Arena give the same rewards on every floor, so they never stop for good: the list keeps looping back to them. The Tower is not here: it only uses its goal above.")
	local w = card(R, "Waiting Time (minutes)", "T")
	for _, id in ipairs({ "dungeons", "ether", "boss" }) do
		sliderRow(w, (M.PRIO_LABEL[id]:gsub(" %(.*", "")), 0, 240, 5, function() return M.prio.cd[id] or 30 end, function(v) M.prio.cd[id] = v end)
	end
	local st = card(R, "Now", "i")
	textRow(st, function()
		if not M.prio.enabled then return "Priority list is off (the Dungeons / Tower / Bosses pages decide)." end
		local t = {}
		for _, id in ipairs(M.prio.order) do
			if M.prio.on[id] and M.PRIO_PREFIX[id] or (M.prio.on[id] and id == "dungeons") then
				local left = (M.prio.nextAt[id] or 0) - os.time()
				local n = #M.prioKeys(id)
				if n > 0 and id ~= "daily" then t[#t + 1] = ("%s: %s"):format((M.PRIO_LABEL[id]:gsub(" %(.*", "")), left > 0 and (math.ceil(left / 60) .. " min") or "ready") end
			end
		end
		return #t > 0 and table.concat(t, "\\n") or "No repeating activity is switched on."
	end, 60)
end

-- TOWER
do
	local L, R = newPage("tower")
	local b = card(L, "Tower", "T")
	toggleRow(b, "Run the Tower", function() return M.fnGet("tower") end, function(v) M.fnSet("tower", v) end)
	textRow(b, function()
		return ("Best floor so far: %s  /  leave after floor %s%s"):format(hl(M.side.towerBest or 0), hl(M.side.towerGoal or 600), M.side.towerDone and '  <font color="#6ED876">done</font>' or "")
	end)
	textRow(b, "The floor to stop at is set on the Priority page (Tower Goal).")
	local r = card(R, "Status", "i")
	textRow(r, function()
		if not M.fnGet("tower") then return "Tower function is off." end
		if M.prio.enabled then return "Runs in its turn on the Priority list." end
		local left = (M.side.nextTower or 0) - os.time()
		return "Next Tower run: " .. hl(left <= 0 and "now (after the current fight)" or (math.ceil(left / 60) .. " min"))
	end)
end

-- BOSSES
do
	local L, R = newPage("boss")
	local db = card(R, "Daily Bosses (every map)", "D")
	toggleRow(db, "Daily boss tour", function() return M.fnGet("daily") end, function(v) M.fnSet("daily", v) end)
	sliderRow(db, "New day starts at (hour)", 0, 23, 1, function() return M.side.dailyHour or 0 end, function(v) M.side.dailyHour = v end)
	textRow(db, function()
		local info = gameInfo()
		local day = M.dailyDay()
		local ok = {}
		for _, f in ipairs(M.floorList()) do ok[f.n] = f end
		local t = {}
		for name, bo in pairs(info and info.DailyBosses or {}) do
			local f = ok[tonumber(bo.Floor)]
			local st = (not f or not f.ok) and '<font color="#9aa29c">map locked</font>' or (M.prio.daily or {})["DAILY:" .. name] == day and '<font color="#6ED876">done today</font>' or '<font color="#E9EEEA">waiting</font>'
			t[#t + 1] = ("%s (%s, %s coins): %s"):format(name, f and f.name or "?", tostring(bo.Coins), st)
		end
		table.sort(t)
		return table.concat(t, "\n")
	end, 50)
	textRow(db, "Once a day: travels to each map that has a daily boss, fights it once, then goes back to your home map.")
	local b = card(L, "Boss Farm", "B")
	toggleRow(b, "Fight bosses", function() return M.fnGet("boss") end, function(v) M.fnSet("boss", v) end)
	textRow(b, function()
		local t = {}
		for _, k in ipairs(M.bossKeys()) do if k:sub(1, 5) == "BOSS:" then t[#t + 1] = k:sub(6) end end
		return "Boss of this map: " .. hl(#t > 0 and table.concat(t, ", ") or "none")
	end, 20)
	sliderRow(b, "Every (minutes)", 1, 180, 1, function() return M.side.bossEvery or 30 end, function(v) M.side.bossEvery = v end)
	textRow(b, "Fights the boss of the map you are on. Daily bosses have their own switch above. A lost fight just returns to the map and tries again next time.")
	local r = card(R, "Status", "i")
	textRow(r, function()
		if not M.fnGet("boss") then return "Boss function is off." end
		if M.prio.enabled then return "Runs in its turn on the Priority list." end
		local left = (M.side.nextBoss or 0) - os.time()
		return ("Next boss fight: %s\nWins this session: %s"):format(hl(left <= 0 and "now (after the current fight)" or (math.ceil(left / 60) .. " min")), hl(M._bossWins or 0))
	end, 34)
	local bt = card(L, "Bounty Hunt", "!")
	optToggle(bt, "Hunt bounty monsters", "bounty")
	textRow(bt, function()
		local mob = M.findBounty and M.findBounty()
		local h = mob and mob:FindFirstChildOfClass("Humanoid")
		local d = data()
		local boon = d and d.Data.Inventory.Materials["Bounty Boon"] or 0
		return ("On this map now: %s\nKilled this session: %s\nBounty Boon: %s"):format(
			hl(mob and ("%s (%d%%)"):format(mob.Name, h and math.floor(h.Health / h.MaxHealth * 100) or 0) or "none"),
			hl(M._bountyKills or 0), hl(boon))
	end, 50)
	textRow(bt, "A bounty monster (pink marker) shows up on a map now and then. When one is on the map you are on, the script drops what it is doing and goes to kill it. Not inside dungeons or the Tower.")
end

-- PROGRESSION
do
	local L, R = newPage("progress")
	local b = card(L, "Next Floor", "N")
	toggleRow(b, "Auto boss + next floor", function() return M.fnGet("floor") end, function(v) M.fnSet("floor", v) end)
	textRow(b, "As soon as your level reaches the next floor's requirement: beats this floor's boss (if not beaten yet), then travels to the next floor. A lost boss fight is retried every 10 min.")
	local r = card(R, "Requirements", "R")
	textRow(r, function()
		local f = floorInfo()
		if not f then return "Loading..." end
		if not f.exists then return "You are on the last floor." end
		local okL = f.level >= f.needLevel
		local okB = f.unlocked >= f.nextN
		local function mark(ok) return ok and '<font color="#6ED876">done</font>' or '<font color="#D65656">not yet</font>' end
		return ("Now: floor %s\nNext: floor %s - %s\n\nBeat %s: %s\nLevel %s (you %s): %s"):format(hl(f.cur), hl(f.nextN), hl(f.nextName), hl(f.boss or "boss"), mark(okB), hl(f.needLevel), hl(f.level), mark(okL))
	end, 100)
end

-- CHARACTER
do
	local L, R = newPage("character")
	local b = card(L, "Auto Stats", "S")
	funcToggle(b, "stats", "Auto spend stat points")
	textRow(b, "Set the value each stat should reach. Points go +1 at a time from top to bottom (1, 2, 3 ... 6, then 1 again), skipping stats that reached their target.")
	for idx, n in ipairs(STAT_NAMES) do
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = nextOrder() }, b)
		mk("TextLabel", { Size = UDim2.new(0, 18, 1, 0), BackgroundTransparency = 1, Text = tostring(idx), TextColor3 = C.dim, Font = FB, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, row)
		mk("TextLabel", { Size = UDim2.new(0, 84, 1, 0), Position = UDim2.new(0, 18, 0, 0), BackgroundTransparency = 1, Text = n, TextColor3 = C.text, Font = F, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)
		local minus = mk("TextButton", { Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -118, 0.5, -13), BackgroundColor3 = C.field, Text = "-", TextColor3 = C.text, Font = FB, TextSize = 14, AutoButtonColor = true }, row)
		corner(minus, 6)
		local box = mk("TextBox", { Size = UDim2.new(0, 56, 0, 26), Position = UDim2.new(1, -88, 0.5, -13), BackgroundColor3 = C.field, Text = "", PlaceholderText = "-", TextColor3 = C.accent, Font = FB, TextSize = 13, ClearTextOnFocus = false }, row)
		corner(box, 6)
		local plus = mk("TextButton", { Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -28, 0.5, -13), BackgroundColor3 = C.field, Text = "+", TextColor3 = C.text, Font = FB, TextSize = 14, AutoButtonColor = true }, row)
		corner(plus, 6)
		local function cur()
			local d = data()
			return d and d.Data.Stats.Allocations[n] or 0
		end
		local function paint()
			if not box:IsFocused() then box.Text = tostring(M.statTarget(n, data() and data().Data.Stats.Allocations)) end
		end
		local function setT(v)
			M.statT[n] = math.clamp(math.floor(tonumber(v) or cur()), cur(), 999) -- can't go below what's already spent
			save()
			paint()
		end
		paint()
		paints[#paints + 1] = paint
		table.insert(conns, minus.MouseButton1Click:Connect(function() setT(M.statTarget(n, data() and data().Data.Stats.Allocations) - 1) end))
		table.insert(conns, plus.MouseButton1Click:Connect(function() setT(M.statTarget(n, data() and data().Data.Stats.Allocations) + 1) end))
		table.insert(conns, box.FocusLost:Connect(function() setT(box.Text) end))
	end
	textRow(b, function()
		local d = data()
		if not d then return "" end
		local spent, want = 0, 0
		for _, n in ipairs(STAT_NAMES) do
			spent += d.Data.Stats.Allocations[n] or 0
			want += M.statTarget(n, d.Data.Stats.Allocations)
		end
		local free = d.Data.Stats.Points or 0
		local maxPts = spent + free + (120 - (d.Data.Leveling.Level or 1)) * 3
		local warn = want > maxPts and ' <font color="#D65656">(more than you can ever get)</font>' or ""
		return ("Points now: %s spent + %s free\nTargets total: %s / max %s at level 120%s"):format(hl(spent), hl(free), hl(want), hl(maxPts), warn)
	end, 34)
	local g = card(R, "Gear & Skills", "G")
	funcToggle(g, "gear", "Equip best gear + farm skills")
	textRow(g, "Checks every minute: best weapon and armor in your bag, and fills free skill slots.")
	local up = card(R, "Upgrade & Craft", "U")
	optToggle(up, "Upgrade the gear you wear", "upgrade")
	optToggle(up, "Craft gear better than yours", "craft")
	optToggle(up, "Open chests in cleared dungeons", "chests")
	sliderRow(up, "Keep at least (coins)", 0, 50000, 500, function() return M.opt.keepCoins or 2000 end, function(v) M.opt.keepCoins = v end)
	textRow(up, function()
		local d = data()
		if not d then return "" end
		local t = {}
		for _, cls in ipairs({ "Weapons", "Armor" }) do
			local worn = cls == "Weapons" and d.Data.Equipped.Hands[1] or d.Data.Equipped.Armor
			if type(worn) == "table" then
				local ok, why = M.canUpgrade(worn, d)
				t[#t + 1] = ("%s Lv%s: %s"):format(worn.Name, tostring(worn.Leveling.Level), ok and '<font color="#6ED876">can upgrade</font>' or tostring(why))
			end
		end
		return table.concat(t, "\n")
	end, 34)
	local sc = card(R, "Auto Sell", "$")
	toggleRow(sc, "Sell worse gear when bag is full", function() return M.opt.autoSell end, function(v)
		M.opt.autoSell = v
		save()
		if v then
			M.running = true
			if not M.schedRunning then task.spawn(scheduler) end
		end
	end)
	textRow(sc, function()
		local n, lim = bagSize()
		return ("Bag %s / %s   |   worse than yours: %s\nTrip starts at %s items: Sunshine Town, sell, come back."):format(hl(n), hl(lim), hl(#M.junkList()), hl(SELL_AT))
	end, 34)
	dropdownRow(sc, "Never sell this rarity and up", function()
		return { { "Legendary", "Legendary" }, { "Super Rare", "Super Rare and up" }, { "Rare", "Rare and up" }, { "Uncommon", "Uncommon and up" }, { "none", "Sell any rarity" } }
	end, function() return M.opt.keepRarity or "Legendary" end, function(v) M.opt.keepRarity = v end)
	dropdownRow(sc, "Never sell these (your weapons / armor)", function()
		local d = data()
		local seen, o = {}, {}
		for _, cls in ipairs({ "Weapons", "Armor" }) do
			for _, it in pairs(d and d.Data.Inventory[cls] or {}) do
				if type(it) == "table" and it.Name and not seen[it.Name] then seen[it.Name] = true o[#o + 1] = { it.Name, it.Name } end
			end
		end
		table.sort(o, function(a, b) return a[1] < b[1] end)
		return o
	end, function() M.opt.keepNames = M.opt.keepNames or {} return M.opt.keepNames end, function(v)
		M.opt.keepNames = M.opt.keepNames or {}
		M.opt.keepNames[v] = not M.opt.keepNames[v] or nil
	end, true)
	textRow(sc, "Also never sold: items you lock as favourite in the game, the item you wear, and everything picked on the Gear Goals page. Only gear weaker than what you wear is sold.")
	buttonRow(sc, "Sell now", nil, function() if M.SellNow then M.SellNow() end end)
	local a = card(R, "Allocated", "A")
	textRow(a, function()
		local d = data()
		if not d then return "" end
		local t = {}
		for _, n in ipairs(STAT_NAMES) do t[#t + 1] = ("%s %s"):format(n, hl(d.Data.Stats.Allocations[n] or 0)) end
		return table.concat(t, "\n") .. "\nFree points: " .. hl(d.Data.Stats.Points or 0)
	end, 110)
end

-- GEAR GOALS
do
	local L, R = newPage("gear")
	textRow(card(L, "Mode", "M"), "How hard gear is farmed is set by the Mode on the Home page: Upgrade gear = upgrade materials come first; Farm everything = gear takes its turn in the Priority list; Level up = no gear farming (upgrades still happen with what drops).")
	local RARITY_COL = {
		Common = Color3.fromRGB(170, 170, 170), Uncommon = Color3.fromRGB(100, 255, 0), Rare = Color3.fromRGB(0, 136, 255),
		["Super Rare"] = Color3.fromRGB(212, 0, 255), Legendary = Color3.fromRGB(255, 191, 0),
	}
	local RARITIES = { "Legendary", "Super Rare", "Rare", "Uncommon", "Common" }
	local CLASSES = { "All", "Scythe", "Greatsword", "Sword", "Axe", "Spear", "Dagger", "Rapier", "Staff" }
	for _, sl in ipairs(M.GEAR_SLOTS) do
		local col = (sl.id == "armor" or sl.flat) and R or L
		local b = card(col, sl.title, sl.id == "armor" and "A" or sl.id == "pet" and "P" or sl.id == "mount" and "M" or (sl.hand == 1 and "1" or "2"))
		local function cfg() return M.gearCfg()[sl.id] end
		local function infoOf(name)
			local info = gameInfo() or {}
			return name and (info[sl.cls] or {})[name]
		end
		-- chosen item: picture + name + state
		local top = mk("Frame", { Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = C.field, BorderSizePixel = 0, LayoutOrder = nextOrder() }, b)
		corner(top, 10)
		local img = mk("ImageLabel", { Size = UDim2.new(0, 64, 0, 64), Position = UDim2.new(0, 6, 0, 6), BackgroundColor3 = C.card, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Fit }, top)
		corner(img, 8)
		local imgStroke = stroke(img, C.line, 2)
		local nm = mk("TextLabel", { Size = UDim2.new(1, -84, 0, 22), Position = UDim2.new(0, 78, 0, 6), BackgroundTransparency = 1, Text = "", TextColor3 = C.text, Font = FB, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, top)
		local sub = mk("TextLabel", { Size = UDim2.new(1, -84, 0, 44), Position = UDim2.new(0, 78, 0, 28), BackgroundTransparency = 1, Text = "", TextColor3 = C.dim, Font = F, TextSize = 11, TextWrapped = true, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, top)
		local function paintTop()
			local c = cfg()
			local it = infoOf(c and c.name)
			if not it then
				img.Image = ""
				nm.Text = "Nothing picked"
				nm.TextColor3 = C.dim
				sub.Text = "Pick one below. Without a pick this slot keeps using the automatic best-gear choice."
				imgStroke.Color = C.line
				return
			end
			img.Image = tostring(it.Image or "")
			nm.Text = c.name
			nm.TextColor3 = RARITY_COL[it.Rarity] or C.text
			imgStroke.Color = RARITY_COL[it.Rarity] or C.line
			local copies = M.gearCopies(sl.cls, c.name)
			local own
			if #copies == 0 then own = "not owned"
			elseif sl.flat then own = ("own %d%s"):format(#copies, copies[1].item.Variant and (", best " .. copies[1].item.Variant) or "")
			else
				local use = (M.gearUse or {})[sl.id]
				if not use then
					-- same rule as the check: hand 1 takes the best copy, hand 2 the next one
					local G0 = M.gearCfg()
					local other = sl.id == "w2" and G0.w1 and G0.w1.name == c.name
					use = copies[other and 2 or 1] and copies[other and 2 or 1].item
				end
				local d0 = data()
				local eq = d0 and d0.Data.Equipped
				local worn = use and eq and (eq.Hands and (eq.Hands[1] == use and "in hand 1" or eq.Hands[2] == use and "in hand 2") or eq.Armor == use and "worn")
				own = use and ("using Lv %d (%s), own %d"):format(use.Leveling.Level, worn or "in bag", #copies) or ("own %d, best Lv %d"):format(#copies, copies[1].item.Leveling.Level)
			end
			local kind = sl.cls == "Weapons" and (it.Class or "") or sl.cls == "Armor" and "Armor" or sl.title
			local stt = (M.gearState or {})[sl.id]
			if not stt then stt = inDungeon() and "waits until you are back on the map" or "waiting for the next check" end
			sub.Text = ("%s %s - %s\n%s"):format(it.Rarity or "", kind, own, hl(stt))
		end
		refreshers[#refreshers + 1] = paintTop
		paints[#paints + 1] = paintTop
		-- where it comes from
		textRow(b, function()
			local c = cfg()
			if not (c and c.name) then return "" end
			local copies0 = M.gearCopies(sl.cls, c.name)
			if #copies0 > 0 and not sl.flat then
				local use = (M.gearUse or {})[sl.id] or copies0[1].item
				local cname = M.upgradeCost(use)
				if cname then
					local t = {}
					for i, s in ipairs(M.gearSources(cname)) do if i <= 4 and s.farm then t[#t + 1] = s.label:gsub("^Dungeon ", ""):gsub("^Boss ", "boss "):gsub("^Monster ", "") end end
					return ("Next upgrade needs %s - from: %s"):format(hl(cname), table.concat(t, ", "))
				end
				return "Max level reached."
			end
			local src = M.gearSources(c.name)
			if #src == 0 then return '<font color="#d65656">No known way to get it (event / removed item?).</font>' end
			local t = {}
			for i, s in ipairs(src) do
				if i > 4 then break end
				local fl = s.floor and (" - " .. (({ "Sunshine Town", "Flywood Forest", "Silent Snowfields", "Desert of Death", "Lotus Lands", "Fish Funland" })[s.floor] or ("floor " .. s.floor))) or ""
				t[#t + 1] = (s.ok and "" or '<font color="#7d857f">[locked] </font>') .. s.label .. fl
			end
			return "Drops from: " .. table.concat(t, "; ")
		end, 30)
		-- target level
		if not sl.flat then sliderRow(b, "Upgrade to level (0 = your level)", 0, 120, 1, function() local c = cfg() return c and c.target or 0 end, function(v)
			local G = M.gearCfg()
			G[sl.id] = G[sl.id] or {}
			G[sl.id].target = v
			M._nextGearGoal = 0
		end) end
		-- filters
		local flt = { rarity = "Legendary", class = "All" }
		do
			local c = cfg()
			local it = infoOf(c and c.name)
			if it then flt.rarity = it.Rarity or flt.rarity end
		end
		local grid
		local rebuild
		if sl.cls == "Weapons" then
			dropdownRow(b, "Weapon type", function()
				local o = {}
				for _, cl in ipairs(CLASSES) do o[#o + 1] = { cl, cl } end
				return o
			end, function() return flt.class end, function(v) flt.class = v if rebuild then rebuild() end end)
		end
		dropdownRow(b, "Rarity", function()
			local o = {}
			for _, r in ipairs(RARITIES) do o[#o + 1] = { r, r } end
			return o
		end, function() return flt.rarity end, function(v) flt.rarity = v if rebuild then rebuild() end end)
		-- picture grid
		local holder = mk("Frame", { Size = UDim2.new(1, 0, 0, 290), BackgroundColor3 = C.field, BorderSizePixel = 0, LayoutOrder = nextOrder() }, b)
		corner(holder, 10)
		grid = mk("ScrollingFrame", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.off, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, holder)
		mk("UIGridLayout", { CellSize = UDim2.new(0, 72, 0, 100), CellPadding = UDim2.new(0, 6, 0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
		rebuild = function()
			for _, ch in ipairs(grid:GetChildren()) do if ch:IsA("GuiButton") or ch:IsA("Frame") then ch:Destroy() end end
			local info = gameInfo() or {}
			local names = {}
			for name, it in pairs(info[sl.cls] or {}) do
				if it.Rarity == flt.rarity and (sl.cls ~= "Weapons" or flt.class == "All" or it.Class == flt.class) then names[#names + 1] = name end
			end
			table.sort(names, function(a, b)
				local ca, cb = tostring(info[sl.cls][a].Class), tostring(info[sl.cls][b].Class)
				if ca ~= cb then return ca < cb end
				return a < b
			end)
			local chosen = cfg() and cfg().name
			for i, name in ipairs(names) do
				local it = info[sl.cls][name]
				local cell = mk("TextButton", { BackgroundColor3 = name == chosen and C.hover or C.card, Text = "", AutoButtonColor = true, LayoutOrder = i }, grid)
				corner(cell, 8)
				stroke(cell, name == chosen and C.accent or (RARITY_COL[it.Rarity] or C.line), name == chosen and 2 or 1, name == chosen and 0 or 0.5)
				mk("ImageLabel", { Size = UDim2.new(0, 54, 0, 54), Position = UDim2.new(0.5, -27, 0, 4), BackgroundTransparency = 1, Image = tostring(it.Image or ""), ScaleType = Enum.ScaleType.Fit }, cell)
				mk("TextLabel", { Size = UDim2.new(1, -4, 0, 26), Position = UDim2.new(0, 2, 0, 56), BackgroundTransparency = 1, Text = name, TextColor3 = C.text, Font = F, TextSize = 10, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top }, cell)
				local src = M.gearSources(name)
				local how, hc = "no source", Color3.fromRGB(214, 86, 86)
				for _, s0 in ipairs(src) do
					if s0.farm and s0.ok then how, hc = "farmable", C.accent break end
					if s0.farm then how, hc = "map locked", Color3.fromRGB(150, 156, 152) break end
					how, hc = s0.kind == "daily" and "daily boss" or s0.kind == "craft" and "craft" or s0.kind == "chest" and "chest" or s0.kind == "tower" and "tower prize" or s0.kind == "box" and "shop box" or "shop", Color3.fromRGB(255, 191, 0)
					break
				end
				mk("TextLabel", { Size = UDim2.new(1, -4, 0, 12), Position = UDim2.new(0, 2, 1, -13), BackgroundTransparency = 1, Text = (sl.cls == "Weapons" and (tostring(it.Class) .. " · ") or "") .. how, TextColor3 = hc, Font = FB, TextSize = 8, TextTruncate = Enum.TextTruncate.AtEnd }, cell)
				local copies = M.gearCopies(sl.cls, name)
				if #copies > 0 then
					local tag = sl.flat and "owned" or ("Lv" .. copies[1].item.Leveling.Level)
					mk("TextLabel", { Size = UDim2.new(0, 40, 0, 14), Position = UDim2.new(1, -42, 0, 2), BackgroundColor3 = C.accent, Text = tag, TextColor3 = Color3.fromRGB(18, 30, 20), Font = FB, TextSize = 9 }, cell)
				end
				table.insert(conns, cell.MouseButton1Click:Connect(function()
					local G = M.gearCfg()
					G[sl.id] = G[sl.id] or {}
					G[sl.id].name = name
					M._nextGearGoal = 0
					if M._gearNoWear then M._gearNoWear[sl.id] = nil end
					save()
					rebuild()
					paintTop()
				end))
			end
			if #names == 0 then
				mk("TextLabel", { BackgroundTransparency = 1, Text = "nothing", TextColor3 = C.dim, Font = F, TextSize = 11 }, grid)
			end
		end
		rebuild()
		buttonRow(b, "Clear this slot", nil, function()
			M.gearCfg()[sl.id] = nil
			M.gearState = M.gearState or {}
			M.gearState[sl.id] = nil
			save()
			rebuild()
			paintTop()
		end)
	end
	local h = card(R, "How It Works", "?")

	textRow(h, function()
		local fl = (M.loadDrops()).__mobFloors or {}
		local parts = {}
		for _, f in ipairs(M.floorList()) do
			local mark
			if fl[tostring(f.n)] then mark = '<font color="#6ED876">done</font>'
			elseif not f.ok then mark = '<font color="#9aa29c">locked</font>'
			else mark = '<font color="#d65656">not read</font>' end
			parts[#parts + 1] = ("%d %s: %s"):format(f.n, tostring(f.name), mark)
		end
		local head = "Monster drops read per map (a map you can enter that isn't read yet gets read by itself):"
		local sl = M.side.scanLeft
		if sl then
			head = ('<font color="#E8C15A">Reading now</font> - %d map(s) to go%s'):format(#sl, sl[1] and (", next: map " .. sl[1]) or "")
		elseif M._scanDoneAt then
			head = ('<font color="#6ED876">Finished</font> %s ago. Monster drops read per map:'):format(math.floor((os.clock() - M._scanDoneAt) / 60) .. " min")
		end
		return head .. "\n" .. table.concat(parts, "\n")
	end, 110)
	sliderRow(h, "Gear runs in a row (0 = until done)", 0, 100, 1, function() return tonumber(M.opt.gearRuns) or 10 end, function(v) M.opt.gearRuns = v end)
	textRow(h, function()
		local st = M.side.gearStreak or 0
		if st <= 0 then return "Not farming gear right now." end
		return ("Farming gear: %s runs left in this turn%s"):format(hl(st > 1e8 and "until done" or st), M.gearFarmFor and (" - for " .. hl(M.gearFarmFor)) or "")
	end)
	textRow(h, function()
		local rows = {}
		for k, st in pairs(M.side.gearStat or {}) do
			local item, key = k:match("^(.-)|(.+)$")
			rows[#rows + 1] = { ("%s: %s - %d runs, %d got, %.1f / hour"):format(tostring(key):gsub("^BOSS:", "boss "):gsub("^MOB:", ""), tostring(item):gsub(" Upgrade Crystal", " crystal"), st.runs, st.gain, st.gain / math.max(1, st.secs) * 3600), st.gain / math.max(1, st.secs) }
		end
		table.sort(rows, function(a, b) return a[2] > b[2] end)
		local t = {}
		for i, r in ipairs(rows) do if i <= 6 then t[#t + 1] = r[1] end end
		return #t > 0 and ("Best places so far (each is tried 3 times, then mostly the best one; drops are random, so the numbers settle over time):\n" .. table.concat(t, "\n")) or "Each place is tried 3 times and timed, then the one that gives the most per hour is used most of the time."
	end, 80)
	textRow(h, "Monster drops: the game only shows what the monsters of the map you are on drop. The script remembers it for every map you visit (the TP point tour visits them all), so an item that shows \"no source\" can turn \"farmable\" later.")
	textRow(h, "Pet and Mount: picked ones are put on as soon as you own them. They can't be farmed: the card shows where they come from (Tower floors, shop boxes bought with Bleeter Bits, chests...). The script never buys boxes.")
	textRow(h, "For every slot you fill: if you don't own it yet, the Priority row \"Gear goals\" runs the dungeon / boss that drops it until it drops. Then it is upgraded up to the level you set (0 = your own level; it can never go above you), and when it is short of upgrade crystals it runs the dungeons that give those. It is worn in its hand / as armor as soon as you can wear it. Daily bosses, crafting, chests and shops are shown but not farmed here. Coins under \"keep coins\" are never spent.")
	textRow(h, function()
		local pr = M.prio
		local rowOn = pr.enabled and pr.on.gear
		local farm = M.gearFarmFor
		return ("Priority row \"Gear goals\": %s%s"):format(rowOn and hl("on") or '<font color="#d65656">off - turn it on to farm drops / crystals</font>', farm and ("\nFarming for: " .. hl(farm)) or "")
	end, 34)
end

-- TELEPORT
do
	local L, R = newPage("teleport")
	local b = card(L, "Home Map", "H")
	dropdownRow(b, "When entering the game, go to", function()
		local out = { { 0, "Off (stay where I spawn)" }, { -1, "My best floor (highest I can enter)" } }
		for _, f in ipairs(M.floorList()) do
			out[#out + 1] = { f.n, f.name .. (f.ok and "" or ("  (locked: Lv " .. f.need .. ")")) }
		end
		return out
	end, function() return tonumber(M.opt.homeFloor) or 0 end, function(v) M.opt.homeFloor = v end)
	textRow(b, function()
		local n = M.homeTarget()
		local name = "-"
		for _, f in ipairs(M.floorList()) do if f.n == n then name = f.name end end
		return "Home map now: " .. hl(n > 0 and name or "off")
	end)
	textRow(b, "Checked every time the script loads on a map. Trips to the Tower, the Catacombs, the Battle Arena, the Ether, daily bosses, TP points or selling don't count: it goes home after them.")
	buttonRow(b, "Go to the home map now", C.accent, function() task.spawn(M.goHome) end)
	local r = card(R, "Travel Now", "T")
	for _, f in ipairs(M.floorList()) do
		buttonRow(r, f.name .. (f.ok and "" or ("  (Lv " .. f.need .. ")")), nil, function() task.spawn(M.travelTo, f.n, "button") end)
	end
	textRow(r, function()
		local cur = currentFloor()
		for _, f in ipairs(M.floorList()) do if f.n == cur then return "You are in: " .. hl(f.name) end end
		return "You are in: " .. hl("a dungeon / special area")
	end)
end

-- SETTINGS
do
	local L, R = newPage("settings")
	local b = card(L, "Window", "W")
	textRow(b, "Right Ctrl shows / hides this window. Drag it by the top bar.")
	optToggle(b, "Auto press Play on the start screen", "autoPlay")
	optToggle(b, "Skip cutscenes (boss intros)", "skipCutscene")
	optToggle(b, "Drop quests from other floors", "dropForeign")
	optToggle(b, "Collect item orbs on the map", "orbs")
	sliderRow(b, "Window size (%)", 40, 160, 5, function() return math.floor((tonumber(M.opt.uiScale) or 1) * 100 + 0.5) end, function(v)
		M.opt.uiScale = v / 100
		M.fitUI()
	end)
	buttonRow(b, "STOP ALL", C.red, function() stopTask() release() setNoclip(false) repaintAll() end)
	buttonRow(b, "Unload script", nil, function() if M.Destroy then M.Destroy(true) end end)
	local r = card(R, "Saved Settings", "F")
	textRow(r, "Switches and settings are saved and come back after every teleport (dungeons, bosses, floors).")
end

showPage("home")

-- drag by the top bar, hide with Right Ctrl, minimize
do
	local dragging, ds, sp
	table.insert(conns, topbar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, ds, sp = true, i.Position, main.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end))
	table.insert(conns, UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - ds
			main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end))
	table.insert(conns, UIS.InputBegan:Connect(function(i, gp)
		if i.KeyCode == Enum.KeyCode.RightControl then main.Visible = not main.Visible end
	end))
	table.insert(conns, minBtn.MouseButton1Click:Connect(function() M.setOpen(false) end))
end

local function destroy(byUser)
	stopTask(byUser ~= true) -- replaced by a newer copy: keep the saved switches
	M.alive = false
	release()
	setNoclip(false)
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	pcall(function() gui:Destroy() end)
	if genv.__AutoAll == M then genv.__AutoAll = nil end
end
M.Destroy = destroy
table.insert(conns, closeBtn.MouseButton1Click:Connect(function() destroy(true) end))

task.spawn(function()
	while M.alive do
		if main.Visible then
			for _, f in ipairs(refreshers) do pcall(f) end
			for _, f in ipairs(paints) do pcall(f) end
		end
		task.wait(1)
	end
end)

genv.__AutoAll = M
do
	local st = loadState()
	if st then
		-- every saved option comes back, including ones added after the defaults (modes, keep lists, window size)
		for k, v in pairs(st.opt or {}) do M.opt[k] = v end
		pcall(function() if M.fitUI then M.fitUI() end end)
		for k, v in pairs(st.statW or {}) do M.statW[k] = v end
		for k, v in pairs(st.statT or {}) do M.statT[k] = tonumber(v) end
		for k, v in pairs(st.on or {}) do if M.on[k] ~= nil then M.on[k] = v end end
		for k, v in pairs(st.cycle or {}) do M.cycle[k] = v end
		M.sellTrip = st.sellTrip
		for k, v in pairs(st.side or {}) do M.side[k] = v end
		if type(st.prio) == "table" then
			for k, v in pairs(st.prio) do
				if k == "order" then
					-- keep the saved order, add any activity that is new in this version
					local seen, ord = {}, {}
					for _, id in ipairs(v) do if M.PRIO_LABEL[id] and not seen[id] then seen[id] = true ord[#ord + 1] = id end end
					for _, id in ipairs(M.prio.order) do if not seen[id] then ord[#ord + 1] = id end end
					M.prio.order = ord
				elseif type(v) == "table" and type(M.prio[k]) == "table" then
					for kk, vv in pairs(v) do M.prio[k][kk] = vv end
				else
					M.prio[k] = v
				end
			end
		end
		repaintAll()
	end
	if anyOn() then
		M.running = true
		log("resuming saved switches")
		if not M.schedRunning then task.spawn(scheduler) end
	end
end
queueSelf()
do
	-- in dungeons / towers: write down every hit we take and what was announced just before it
	local function hook(ch)
		local hum = ch:WaitForChild("Humanoid", 10)
		if not hum then return end
		local last = hum.Health
		table.insert(conns, hum.HealthChanged:Connect(function(v)
			if v < last - 5 and M._dungeonRunning and (M._hitLogs or 0) < 60 then
				M._hitLogs = (M._hitLogs or 0) + 1
				local la = M._lastAtk
				local _, hrp = char()
				local inside = hrp and select(2, safePos(hrp.Position))
				log(("HIT -%d inZone=%s last announced: %s"):format(last - v, tostring(inside),
					la and ("%s %s size %s time %s, %.1fs ago"):format(la.who, la.kind, tostring(la.size), tostring(la.time), os.clock() - la.t) or "none"))
			end
			last = v
		end))
	end
	if lp.Character then task.spawn(hook, lp.Character) end
	table.insert(conns, lp.CharacterAdded:Connect(hook))
end
M._loadedAt = os.clock()
-- unattended: no idle kick, and come back by itself after a disconnect
do
	local g = (getgenv and getgenv()) or _G
	if not g.__AutoKeepAlive then
		g.__AutoKeepAlive = true
		pcall(function()
			local vu = game:GetService("VirtualUser")
			lp.Idled:Connect(function()
				pcall(function() vu:CaptureController() vu:ClickButton2(Vector2.new(0, 0)) end)
			end)
		end)
		pcall(function()
			game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)
				if not msg or msg == "" or g.__AutoRejoining then return end
				-- leaving for a teleport (map change, dungeon, Tower) also sets a message: not a disconnect
				if tostring(msg):find("ClientInitiated") then return end
				task.wait(15)
				local still = ""
				pcall(function() still = game:GetService("GuiService"):GetErrorMessage() end)
				if still == "" or tostring(still):find("ClientInitiated") or g.__AutoRejoining then return end
				g.__AutoRejoining = true
				pcall(function() appendfile("auto_farm_log_" .. lp.UserId .. ".txt", os.date("%H:%M:%S") .. " disconnected (" .. tostring(msg):sub(1, 80) .. "), rejoining\n") end)
				task.spawn(function()
					while true do
						task.wait(15)
						pcall(function()
							if queue_on_teleport then
								queue_on_teleport('local g = getgenv() if g.__AutoQueuedRan then return end g.__AutoQueuedRan = true if isfile("auto_farm_src.lua") then g.__AutoSrc = readfile("auto_farm_src.lua") loadstring(g.__AutoSrc)() end')
							end
							game:GetService("TeleportService"):Teleport(16992122108, lp)
						end)
						task.wait(45)
					end
				end)
			end)
		end)
	end
end
-- skip cutscenes: the game skips on Enter (boss rooms: a vote sent to the server)
task.spawn(function()
	local vim = game:GetService("VirtualInputManager")
	while M.alive do
		if M.opt.skipCutscene then
			local okc, inCut = pcall(function() return CharController:GetState("InCutscene") end)
			local frame = lp.PlayerGui:FindFirstChild("FullGui") and lp.PlayerGui.FullGui:FindFirstChild("CutsceneTransitionFrame")
			local hint = frame and ((frame:FindFirstChild("TlSkip") and frame.TlSkip.Visible) or (frame:FindFirstChild("TlSkipBoss") and frame.TlSkipBoss.Visible))
			local early = false -- boss / daily boss room: the intro starts before the hint shows, vote right away
			if not (okc and inCut) and not hint and os.clock() - M._loadedAt < 40 then
				pcall(function()
					local gi = gameInfo()
					local gd = gi and gi._GameData
					early = gd and (gd.IsBoss or gd.IsDailyBoss) and true or false
				end)
			end
			if early then
				pcall(function()
					for _, r in pairs(RC._replicas) do
						if r.Class == "InstanceData" then r:FireServer("VoteSkipCutscene") end
					end
				end)
			end
			if (okc and inCut) or hint then
				pcall(function()
					for _, r in pairs(RC._replicas) do
						if r.Class == "InstanceData" then r:FireServer("VoteSkipCutscene") end
					end
					local d = data()
					if d then d:FireServer("VoteSkipCutscene") end
				end)
				pcall(function()
					vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
					task.wait(0.05)
					vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
				end)
				if not M._cutLogged or os.clock() - M._cutLogged > 10 then M._cutLogged = os.clock() log("skipping cutscene") end
			end
		end
		task.wait(0.5)
	end
end)
task.delay(6, function() if M.alive then pcall(M.goHome) end end)
log("AUTO v21z loaded")

end, debug.traceback)
if not __ok then
	__g.__AutoAllErr = __err
	warn("[Auto Farm] failed to start: " .. tostring(__err))
	__note("failed to start: " .. tostring(__err):sub(1, 150), 20)
else
	__g.__AutoAllErr = nil
	__note("loaded - the - button folds it into the logo, tap the logo to open it", 8)
end
]==]
loadstring(getgenv().__AutoSrc)()
