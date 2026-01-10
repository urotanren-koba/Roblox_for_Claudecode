--[[
    GameService
    サーバー側のメイン処理
    ゲーム全体の初期化とプレイヤー管理
    配置場所: ServerScriptService/Services/GameService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- モジュール読み込み
local Modules = ReplicatedStorage:WaitForChild("Modules")
local EventManager = require(Modules:WaitForChild("EventManager"))
local DataManager = require(Modules:WaitForChild("DataManager"))
local GameManager = require(Modules:WaitForChild("GameManager"))

-- 初期化
print("[GameService] サーバー起動開始...")

-- イベント初期化
EventManager.initializeEvents()

-- データマネージャー初期化
DataManager.initialize()

-- プレイヤー参加時の処理
local function onPlayerAdded(player)
    print("[GameService] プレイヤー参加: " .. player.Name)

    -- データ読み込み
    local playerData = DataManager.loadPlayerData(player)

    -- クライアントにデータ送信
    EventManager.fireClient("PlayerDataLoaded", player, playerData)

    -- キャラクター追加時の処理
    player.CharacterAdded:Connect(function(character)
        print("[GameService] キャラクター生成: " .. player.Name)
    end)
end

-- プレイヤー退出時の処理
local function onPlayerRemoving(player)
    print("[GameService] プレイヤー退出: " .. player.Name)

    -- データ保存
    DataManager.savePlayerData(player)

    -- キャッシュから削除
    DataManager.removeFromCache(player)
end

-- イベント接続
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- 既に参加しているプレイヤーの処理（Studio用）
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end

-- ゲーム状態をHomeに変更
GameManager.changeState(GameManager.States.HOME)

print("[GameService] サーバー起動完了")
