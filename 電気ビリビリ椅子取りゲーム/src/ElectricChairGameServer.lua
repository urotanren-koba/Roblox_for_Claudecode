-- ============================================
-- 電気ビリビリ椅子取りゲーム - サーバースクリプト
-- ServerScriptServiceに配置してください
-- ============================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 参照待機
local GameStage = Workspace:WaitForChild("GameStage")
local ChairsFolder = GameStage:WaitForChild("Chairs")
local NPCsFolder = GameStage:WaitForChild("NPCs")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- 音楽取得
local bgm = nil
for _, child in ipairs(Workspace:GetChildren()) do
    if child:IsA("Sound") then
        bgm = child
        bgm.Volume = 0.5
        break
    end
end

-- RemoteEvents
local startGameRemote = Remotes:WaitForChild("StartGameRemote")
local resetGameRemote = Remotes:WaitForChild("ResetGameRemote")

-- 設定
local CONFIG = {
    MUSIC_MIN = 10,
    MUSIC_MAX = 20,
    SEAT_TIME = 5,
    COUNTDOWN = 5,
}

-- NPCテンプレート保存
local NPCTemplates = {}
local NPCPositions = {}

for _, npc in ipairs(NPCsFolder:GetChildren()) do
    if npc:IsA("Model") then
        local idx = npc:FindFirstChild("NPCIndex")
        if idx then
            NPCTemplates[idx.Value] = npc:Clone()
            local root = npc:FindFirstChild("HumanoidRootPart")
            if root then NPCPositions[idx.Value] = root.CFrame end
        end
    end
end

-- ゲーム状態
local State = {
    Running = false,
    Round = 0,
    Alive = {},
    Electric = {},
    Seats = {},
    Total = 0,
}

-- ユーティリティ
local function shuffle(t)
    local s = {}
    for i,v in ipairs(t) do s[i]=v end
    for i=#s,2,-1 do
        local j = math.random(i)
        s[i],s[j] = s[j],s[i]
    end
    return s
end

local function aliveCount()
    local c = 0
    for _ in pairs(State.Alive) do c=c+1 end
    return c
end

-- UI更新
local function updateUI(callback)
    for _, p in ipairs(Players:GetPlayers()) do
        local gui = p:FindFirstChild("PlayerGui")
        local ui = gui and gui:FindFirstChild("GameUI")
        if ui then callback(ui) end
    end
end

local function setStatus(t)
    print("[Status] "..t)
    updateUI(function(ui)
        local l = ui:FindFirstChild("StatusLabel")
        if l then l.Text = t end
    end)
end

local function setRound(r, a)
    updateUI(function(ui)
        local rl = ui:FindFirstChild("RoundLabel")
        local al = ui:FindFirstChild("AliveLabel")
        if rl then rl.Text = "ラウンド: "..r; rl.Visible = true end
        if al then al.Text = "生存者: "..a.."人"; al.Visible = true end
    end)
end

local function showCount(n)
    updateUI(function(ui)
        local l = ui:FindFirstChild("CountdownLabel")
        if l then l.Text = tostring(n); l.Visible = true end
    end)
end

local function hideCount()
    updateUI(function(ui)
        local l = ui:FindFirstChild("CountdownLabel")
        if l then l.Visible = false end
    end)
end

local function showStart(v)
    updateUI(function(ui)
        local b = ui:FindFirstChild("StartButton")
        if b then b.Visible = v end
    end)
end

local function showWinner(name)
    updateUI(function(ui)
        local p = ui:FindFirstChild("WinnerPanel")
        if p then
            local n = p:FindFirstChild("WinnerName")
            if n then n.Text = name end
            p.Visible = true
        end
    end)
end

local function hideWinner()
    updateUI(function(ui)
        local p = ui:FindFirstChild("WinnerPanel")
        if p then p.Visible = false end
    end)
end

-- 椅子管理
local function setChairs(count)
    for _, c in ipairs(ChairsFolder:GetChildren()) do
        if c:IsA("Model") then
            local idx = c:FindFirstChild("ChairIndex")
            local active = idx and idx.Value <= count
            local seat = c:FindFirstChild("Seat")
            local back = c:FindFirstChild("Backrest")
            if seat then seat.Transparency = active and 0 or 1 end
            if back then back.Transparency = active and 0 or 1 end
            for _, p in ipairs(c:GetChildren()) do
                if p.Name:match("^Leg_") then p.Transparency = active and 0 or 1 end
            end
            local bb = seat and seat:FindFirstChild("ChairNumber")
            if bb then bb.Enabled = active end
        end
    end
end

local function getChairs()
    local chairs = {}
    for _, c in ipairs(ChairsFolder:GetChildren()) do
        if c:IsA("Model") then
            local seat = c:FindFirstChild("Seat")
            if seat and seat.Transparency < 1 then
                local idx = c:FindFirstChild("ChairIndex")
                if idx then table.insert(chairs, idx.Value) end
            end
        end
    end
    return chairs
end

local function electricEffect(seatIdx)
    for _, c in ipairs(ChairsFolder:GetChildren()) do
        local idx = c:FindFirstChild("ChairIndex")
        if idx and idx.Value == seatIdx then
            local seat = c:FindFirstChild("Seat")
            if seat then
                seat.BrickColor = BrickColor.new("Bright yellow")
                seat.Material = Enum.Material.Neon
                local p = Instance.new("ParticleEmitter")
                p.Color = ColorSequence.new(Color3.new(1,1,0))
                p.Size = NumberSequence.new(0.5)
                p.Rate = 100
                p.Lifetime = NumberRange.new(0.2,0.5)
                p.Speed = NumberRange.new(5,15)
                p.Parent = seat
                task.delay(2, function()
                    if p then p:Destroy() end
                    seat.BrickColor = BrickColor.new("Brown")
                    seat.Material = Enum.Material.Wood
                end)
            end
            break
        end
    end
end

-- NPC管理
local function initNPCs()
    State.Alive = {}
    for _, npc in ipairs(NPCsFolder:GetChildren()) do
        if npc:IsA("Model") then
            local idx = npc:FindFirstChild("NPCIndex")
            if idx then State.Alive[npc.Name] = npc end
        end
    end
    State.Total = aliveCount()
end

local function eliminate(name)
    local npc = State.Alive[name]
    if not npc then return end
    local root = npc:FindFirstChild("HumanoidRootPart")
    if root then
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(math.random(-40,40), 60, math.random(-40,40))
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Parent = root
        task.delay(0.5, function() if bv then bv:Destroy() end end)
        task.delay(3, function() if npc then npc:Destroy() end end)
    end
    State.Alive[name] = nil
end

-- 座席割当
local function assignSeats(chairs)
    local assign = {}
    local sc = shuffle(chairs)
    local npcList = {}
    for name in pairs(State.Alive) do table.insert(npcList, name) end
    npcList = shuffle(npcList)
    for i, name in ipairs(npcList) do
        if sc[i] then assign[name] = sc[i] end
    end
    return assign
end

-- リセット
local function resetGame()
    print("[Reset]")
    if bgm then bgm:Stop() end
    NPCsFolder:ClearAllChildren()
    for idx, template in pairs(NPCTemplates) do
        local npc = template:Clone()
        local alive = npc:FindFirstChild("IsAlive")
        if alive then alive.Value = true end
        if NPCPositions[idx] then npc:SetPrimaryPartCFrame(NPCPositions[idx]) end
        npc.Parent = NPCsFolder
    end
    for _, c in ipairs(ChairsFolder:GetChildren()) do
        if c:IsA("Model") then
            local seat = c:FindFirstChild("Seat")
            local back = c:FindFirstChild("Backrest")
            if seat then seat.Transparency=0; seat.BrickColor=BrickColor.new("Brown"); seat.Material=Enum.Material.Wood end
            if back then back.Transparency=0 end
            for _, p in ipairs(c:GetChildren()) do
                if p.Name:match("^Leg_") then p.Transparency=0 end
            end
            local bb = seat and seat:FindFirstChild("ChairNumber")
            if bb then bb.Enabled=true end
        end
    end
    State.Running = false
    State.Round = 0
    State.Alive = {}
    setStatus("STARTボタンを押してゲーム開始")
    showStart(true)
    hideWinner()
    hideCount()
    updateUI(function(ui)
        local rl = ui:FindFirstChild("RoundLabel")
        local al = ui:FindFirstChild("AliveLabel")
        if rl then rl.Visible = false end
        if al then al.Visible = false end
    end)
end

-- メインゲーム
local function startGame()
    if State.Running then return end
    State.Running = true
    print("=== GAME START ===")
    showStart(false)
    hideWinner()
    initNPCs()
    State.Round = 0
    local total = aliveCount()
    local elimPerRound = math.max(1, math.floor(total/10))
    setStatus("ゲーム開始！参加者: "..total.."人")
    task.wait(2)

    while aliveCount() > 1 and State.Running do
        State.Round = State.Round + 1
        local alive = aliveCount()
        setRound(State.Round, alive)
        setStatus("ラウンド "..State.Round)
        task.wait(1)

        setChairs(alive)
        local chairs = getChairs()
        local elimCount = math.min(elimPerRound, alive-1)
        elimCount = math.max(1, elimCount)

        local sc = shuffle(chairs)
        State.Electric = {}
        for i=1, elimCount do
            if sc[i] then State.Electric[sc[i]] = true end
        end

        setStatus("♪ 音楽スタート！")
        if bgm then bgm:Play() end
        local dur = math.random(CONFIG.MUSIC_MIN, CONFIG.MUSIC_MAX)
        task.wait(dur)

        if bgm then bgm:Stop() end
        setStatus("⚡ 音楽ストップ！座れ！")
        task.wait(CONFIG.SEAT_TIME)

        State.Seats = assignSeats(chairs)
        setStatus("全員着席！")
        task.wait(1)

        for i=CONFIG.COUNTDOWN, 1, -1 do
            showCount(i)
            task.wait(1)
        end
        hideCount()

        setStatus("⚡⚡⚡ ビリビリ！！ ⚡⚡⚡")
        local elim = {}
        for name, seat in pairs(State.Seats) do
            if State.Electric[seat] then
                table.insert(elim, {name=name, seat=seat})
            end
        end

        for _, d in ipairs(elim) do
            print("💀 "..d.name)
            electricEffect(d.seat)
            eliminate(d.name)
        end

        local names = {}
        for _, d in ipairs(elim) do table.insert(names, d.name) end
        if #names > 0 then setStatus("脱落: "..table.concat(names, ", ")) end
        task.wait(3)
    end

    local winner = "なし"
    for name in pairs(State.Alive) do winner = name; break end
    print("🏆 Winner: "..winner)
    setStatus("ゲーム終了！")
    showWinner(winner)
    State.Running = false
end

-- イベント接続
startGameRemote.OnServerEvent:Connect(function(player)
    print("[Remote] Start from "..player.Name)
    startGame()
end)

resetGameRemote.OnServerEvent:Connect(function(player)
    print("[Remote] Reset from "..player.Name)
    resetGame()
end)

print("=== ElectricChairGame Server Ready ===")
