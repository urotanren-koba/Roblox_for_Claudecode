--[[
    DataManager
    プレイヤーデータの保存・読込を管理するモジュール
    DataStoreServiceを使用してデータを永続化
]]

local DataManager = {}

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()

-- DataStore名
local DATA_STORE_NAME = "MusouGameData_v1"
local playerDataStore = nil

-- プレイヤーデータのキャッシュ
local _playerDataCache = {}

-- デフォルトのプレイヤーデータ構造
local DEFAULT_PLAYER_DATA = {
    -- 通貨
    coins = 0,
    gems = 0,

    -- プレイヤー情報
    level = 1,
    exp = 0,

    -- 所持キャラクター {characterId = {level, awakening, ...}}
    characters = {},

    -- 所持武器 {weaponId = {level, ...}}
    weapons = {},

    -- ステージ進行状況 {stageId = {cleared, bestScore, ...}}
    stageProgress = {},

    -- 設定
    settings = {
        bgmVolume = 1.0,
        seVolume = 1.0,
    },

    -- 統計
    stats = {
        totalPlayTime = 0,
        totalEnemiesDefeated = 0,
        totalStagesCleared = 0,
    },

    -- 最終ログイン
    lastLogin = 0,
}

--[[
    _deepCopy
    テーブルのディープコピー
    @param original table コピー元
    @return table コピー
]]
local function _deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = _deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

--[[
    _mergeDefaults
    デフォルト値をマージ（保存データに不足があれば補完）
    @param data table 保存データ
    @param defaults table デフォルト値
    @return table マージ後データ
]]
local function _mergeDefaults(data, defaults)
    local result = _deepCopy(data)
    for key, defaultValue in pairs(defaults) do
        if result[key] == nil then
            if type(defaultValue) == "table" then
                result[key] = _deepCopy(defaultValue)
            else
                result[key] = defaultValue
            end
        elseif type(defaultValue) == "table" and type(result[key]) == "table" then
            result[key] = _mergeDefaults(result[key], defaultValue)
        end
    end
    return result
end

--[[
    initialize
    DataManager初期化（サーバー起動時に呼ぶ）
]]
function DataManager.initialize()
    if not IS_SERVER then
        warn("[DataManager] initializeはサーバー側でのみ実行可能")
        return
    end

    local success, err = pcall(function()
        playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
    end)

    if success then
        print("[DataManager] 初期化完了")
    else
        warn("[DataManager] DataStore取得失敗: " .. tostring(err))
    end
end

--[[
    loadPlayerData
    プレイヤーデータを読み込む
    @param player Player 対象プレイヤー
    @return table プレイヤーデータ
]]
function DataManager.loadPlayerData(player)
    if not IS_SERVER then
        warn("[DataManager] loadPlayerDataはサーバー側でのみ実行可能")
        return nil
    end

    local userId = player.UserId
    local key = "Player_" .. userId

    -- キャッシュ確認
    if _playerDataCache[userId] then
        return _playerDataCache[userId]
    end

    local data = nil
    local success, err = pcall(function()
        data = playerDataStore:GetAsync(key)
    end)

    if success then
        if data then
            -- 既存データにデフォルト値をマージ
            data = _mergeDefaults(data, DEFAULT_PLAYER_DATA)
            print("[DataManager] データ読込成功: " .. player.Name)
        else
            -- 新規プレイヤー
            data = _deepCopy(DEFAULT_PLAYER_DATA)
            print("[DataManager] 新規プレイヤーデータ作成: " .. player.Name)
        end
    else
        warn("[DataManager] データ読込失敗: " .. player.Name .. " / " .. tostring(err))
        data = _deepCopy(DEFAULT_PLAYER_DATA)
    end

    -- 最終ログイン更新
    data.lastLogin = os.time()

    -- キャッシュに保存
    _playerDataCache[userId] = data

    return data
end

--[[
    savePlayerData
    プレイヤーデータを保存
    @param player Player 対象プレイヤー
    @return boolean 成功したか
]]
function DataManager.savePlayerData(player)
    if not IS_SERVER then
        warn("[DataManager] savePlayerDataはサーバー側でのみ実行可能")
        return false
    end

    local userId = player.UserId
    local key = "Player_" .. userId
    local data = _playerDataCache[userId]

    if not data then
        warn("[DataManager] 保存するデータがありません: " .. player.Name)
        return false
    end

    local success, err = pcall(function()
        playerDataStore:SetAsync(key, data)
    end)

    if success then
        print("[DataManager] データ保存成功: " .. player.Name)
        return true
    else
        warn("[DataManager] データ保存失敗: " .. player.Name .. " / " .. tostring(err))
        return false
    end
end

--[[
    getPlayerData
    キャッシュからプレイヤーデータを取得
    @param player Player 対象プレイヤー
    @return table プレイヤーデータ
]]
function DataManager.getPlayerData(player)
    return _playerDataCache[player.UserId]
end

--[[
    updatePlayerData
    プレイヤーデータを更新
    @param player Player 対象プレイヤー
    @param key string 更新するキー
    @param value any 新しい値
]]
function DataManager.updatePlayerData(player, key, value)
    local data = _playerDataCache[player.UserId]
    if data then
        data[key] = value
    end
end

--[[
    addCoins
    コインを追加
    @param player Player 対象プレイヤー
    @param amount number 追加量
]]
function DataManager.addCoins(player, amount)
    local data = _playerDataCache[player.UserId]
    if data then
        data.coins = (data.coins or 0) + amount
        print("[DataManager] コイン追加: " .. player.Name .. " +" .. amount .. " (合計: " .. data.coins .. ")")
    end
end

--[[
    addGems
    ジェムを追加
    @param player Player 対象プレイヤー
    @param amount number 追加量
]]
function DataManager.addGems(player, amount)
    local data = _playerDataCache[player.UserId]
    if data then
        data.gems = (data.gems or 0) + amount
        print("[DataManager] ジェム追加: " .. player.Name .. " +" .. amount .. " (合計: " .. data.gems .. ")")
    end
end

--[[
    removeFromCache
    キャッシュからプレイヤーデータを削除（退出時）
    @param player Player 対象プレイヤー
]]
function DataManager.removeFromCache(player)
    _playerDataCache[player.UserId] = nil
end

return DataManager
