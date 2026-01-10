--[[
    EventManager
    RemoteEvent/RemoteFunctionの一元管理モジュール
    クライアント・サーバー間通信を統一的に扱う
]]

local EventManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

-- Eventsフォルダの参照
local Events = ReplicatedStorage:WaitForChild("Events")

-- イベント定義（必要に応じて追加）
local EVENT_DEFINITIONS = {
    -- ゲーム状態
    "GameStateChanged",

    -- プレイヤーデータ
    "PlayerDataLoaded",
    "PlayerDataUpdated",

    -- バトル関連
    "BattleStart",
    "BattleEnd",
    "EnemyDamaged",
    "PlayerDamaged",

    -- UI関連
    "UIScreenChanged",

    -- ガチャ・ショップ
    "GachaRoll",
    "PurchaseItem",
}

-- RemoteEvent/RemoteFunctionのキャッシュ
local _remoteEvents = {}
local _remoteFunctions = {}

--[[
    _getOrCreateRemoteEvent
    RemoteEventを取得または作成（サーバー側のみ作成可能）
    @param eventName string イベント名
    @return RemoteEvent
]]
local function _getOrCreateRemoteEvent(eventName)
    if _remoteEvents[eventName] then
        return _remoteEvents[eventName]
    end

    local remoteEvent = Events:FindFirstChild(eventName)

    if not remoteEvent and IS_SERVER then
        remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = Events
        print("[EventManager] RemoteEvent作成: " .. eventName)
    elseif not remoteEvent and IS_CLIENT then
        remoteEvent = Events:WaitForChild(eventName, 10)
    end

    _remoteEvents[eventName] = remoteEvent
    return remoteEvent
end

--[[
    initializeEvents
    全イベントを初期化（サーバー起動時に呼ぶ）
]]
function EventManager.initializeEvents()
    if not IS_SERVER then
        warn("[EventManager] initializeEventsはサーバー側でのみ実行可能")
        return
    end

    for _, eventName in ipairs(EVENT_DEFINITIONS) do
        _getOrCreateRemoteEvent(eventName)
    end

    print("[EventManager] 全イベント初期化完了")
end

--[[
    fireServer
    クライアント→サーバーへイベント送信
    @param eventName string イベント名
    @param ... any 送信データ
]]
function EventManager.fireServer(eventName, ...)
    if not IS_CLIENT then
        warn("[EventManager] fireServerはクライアント側でのみ実行可能")
        return
    end

    local remoteEvent = _getOrCreateRemoteEvent(eventName)
    if remoteEvent then
        remoteEvent:FireServer(...)
    end
end

--[[
    fireClient
    サーバー→特定クライアントへイベント送信
    @param eventName string イベント名
    @param player Player 送信先プレイヤー
    @param ... any 送信データ
]]
function EventManager.fireClient(eventName, player, ...)
    if not IS_SERVER then
        warn("[EventManager] fireClientはサーバー側でのみ実行可能")
        return
    end

    local remoteEvent = _getOrCreateRemoteEvent(eventName)
    if remoteEvent then
        remoteEvent:FireClient(player, ...)
    end
end

--[[
    fireAllClients
    サーバー→全クライアントへイベント送信
    @param eventName string イベント名
    @param ... any 送信データ
]]
function EventManager.fireAllClients(eventName, ...)
    if not IS_SERVER then
        warn("[EventManager] fireAllClientsはサーバー側でのみ実行可能")
        return
    end

    local remoteEvent = _getOrCreateRemoteEvent(eventName)
    if remoteEvent then
        remoteEvent:FireAllClients(...)
    end
end

--[[
    onServerEvent
    サーバー側でイベント受信時のコールバック登録
    @param eventName string イベント名
    @param callback function(player, ...) コールバック
    @return RBXScriptConnection
]]
function EventManager.onServerEvent(eventName, callback)
    if not IS_SERVER then
        warn("[EventManager] onServerEventはサーバー側でのみ実行可能")
        return nil
    end

    local remoteEvent = _getOrCreateRemoteEvent(eventName)
    if remoteEvent then
        return remoteEvent.OnServerEvent:Connect(callback)
    end
    return nil
end

--[[
    onClientEvent
    クライアント側でイベント受信時のコールバック登録
    @param eventName string イベント名
    @param callback function(...) コールバック
    @return RBXScriptConnection
]]
function EventManager.onClientEvent(eventName, callback)
    if not IS_CLIENT then
        warn("[EventManager] onClientEventはクライアント側でのみ実行可能")
        return nil
    end

    local remoteEvent = _getOrCreateRemoteEvent(eventName)
    if remoteEvent then
        return remoteEvent.OnClientEvent:Connect(callback)
    end
    return nil
end

return EventManager
