--[[
    GameController
    クライアント側のメイン処理
    UIとゲーム状態の連携
    配置場所: StarterPlayerScripts/Controllers/GameController
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- モジュール読み込み
local Modules = ReplicatedStorage:WaitForChild("Modules")
local EventManager = require(Modules:WaitForChild("EventManager"))
local GameManager = require(Modules:WaitForChild("GameManager"))
local UIManager = require(Modules:WaitForChild("UIManager"))

-- プレイヤーデータ（サーバーから受信）
local playerData = nil

print("[GameController] クライアント起動開始...")

-- UIManager初期化
UIManager.initialize()

-- ローディング画面表示
UIManager.showScreen(UIManager.Screens.LOADING)

-- プレイヤーデータ受信時の処理
EventManager.onClientEvent("PlayerDataLoaded", function(data)
    print("[GameController] プレイヤーデータ受信")
    playerData = data

    -- ローディング完了、ホーム画面へ
    task.wait(1) -- ローディング演出用の待機
    UIManager.showScreen(UIManager.Screens.HOME)
    GameManager.changeState(GameManager.States.HOME)
end)

-- ゲーム状態変更時の処理
GameManager.onStateChanged(function(oldState, newState)
    print("[GameController] 状態変更検知: " .. oldState .. " → " .. newState)

    -- 状態に応じた画面切り替え
    if newState == GameManager.States.HOME then
        UIManager.showScreen(UIManager.Screens.HOME)
    elseif newState == GameManager.States.STAGE_SELECT then
        UIManager.showScreen(UIManager.Screens.STAGE_SELECT)
    elseif newState == GameManager.States.BATTLE then
        UIManager.showScreen(UIManager.Screens.BATTLE)
    elseif newState == GameManager.States.RESULT then
        UIManager.showScreen(UIManager.Screens.RESULT)
    elseif newState == GameManager.States.GACHA then
        UIManager.showScreen(UIManager.Screens.GACHA)
    elseif newState == GameManager.States.CHARACTER then
        UIManager.showScreen(UIManager.Screens.CHARACTER)
    elseif newState == GameManager.States.SHOP then
        UIManager.showScreen(UIManager.Screens.SHOP)
    end
end)

--[[
    getPlayerData
    現在のプレイヤーデータを取得
    @return table プレイヤーデータ
]]
local function getPlayerData()
    return playerData
end

print("[GameController] クライアント起動完了")

-- 公開API
return {
    getPlayerData = getPlayerData,
}
