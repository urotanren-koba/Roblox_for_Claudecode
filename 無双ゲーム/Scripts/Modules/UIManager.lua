--[[
    UIManager
    画面遷移とUI表示を管理するモジュール
    各画面の表示/非表示を一元管理
]]

local UIManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 画面定義
UIManager.Screens = {
    LOADING = "LoadingScreen",
    HOME = "HomeScreen",
    STAGE_SELECT = "StageSelectScreen",
    BATTLE = "BattleScreen",
    RESULT = "ResultScreen",
    CHARACTER = "CharacterScreen",
    WEAPON = "WeaponScreen",
    GACHA = "GachaScreen",
    SHOP = "ShopScreen",
    SETTINGS = "SettingsScreen",
}

-- 現在表示中の画面
local _currentScreen = nil

-- 画面変更時のコールバック
local _screenChangedCallbacks = {}

-- プレイヤーのScreenGui参照
local _playerGui = nil

--[[
    _getPlayerGui
    PlayerGuiを取得
    @return PlayerGui
]]
local function _getPlayerGui()
    if _playerGui then
        return _playerGui
    end

    local player = Players.LocalPlayer
    if player then
        _playerGui = player:WaitForChild("PlayerGui")
    end

    return _playerGui
end

--[[
    _notifyScreenChanged
    画面変更をコールバックに通知
    @param oldScreen string 前の画面
    @param newScreen string 新しい画面
]]
local function _notifyScreenChanged(oldScreen, newScreen)
    for _, callback in ipairs(_screenChangedCallbacks) do
        task.spawn(function()
            callback(oldScreen, newScreen)
        end)
    end
end

--[[
    initialize
    UIManager初期化（クライアント起動時に呼ぶ）
]]
function UIManager.initialize()
    local playerGui = _getPlayerGui()
    if not playerGui then
        warn("[UIManager] PlayerGuiが見つかりません")
        return
    end

    print("[UIManager] 初期化完了")
end

--[[
    showScreen
    指定した画面を表示（他の画面は非表示）
    @param screenName string 画面名
    @param hideOthers boolean 他画面を非表示にするか（デフォルトtrue）
]]
function UIManager.showScreen(screenName, hideOthers)
    if hideOthers == nil then
        hideOthers = true
    end

    local playerGui = _getPlayerGui()
    if not playerGui then
        return
    end

    local oldScreen = _currentScreen

    -- 他画面を非表示
    if hideOthers then
        for _, screen in pairs(UIManager.Screens) do
            local screenGui = playerGui:FindFirstChild(screen)
            if screenGui then
                screenGui.Enabled = (screen == screenName)
            end
        end
    else
        -- 指定画面のみ表示
        local screenGui = playerGui:FindFirstChild(screenName)
        if screenGui then
            screenGui.Enabled = true
        end
    end

    _currentScreen = screenName
    print("[UIManager] 画面表示: " .. screenName)

    _notifyScreenChanged(oldScreen, screenName)
end

--[[
    hideScreen
    指定した画面を非表示
    @param screenName string 画面名
]]
function UIManager.hideScreen(screenName)
    local playerGui = _getPlayerGui()
    if not playerGui then
        return
    end

    local screenGui = playerGui:FindFirstChild(screenName)
    if screenGui then
        screenGui.Enabled = false
        print("[UIManager] 画面非表示: " .. screenName)
    end

    if _currentScreen == screenName then
        _currentScreen = nil
    end
end

--[[
    hideAllScreens
    全画面を非表示
]]
function UIManager.hideAllScreens()
    local playerGui = _getPlayerGui()
    if not playerGui then
        return
    end

    for _, screen in pairs(UIManager.Screens) do
        local screenGui = playerGui:FindFirstChild(screen)
        if screenGui then
            screenGui.Enabled = false
        end
    end

    _currentScreen = nil
    print("[UIManager] 全画面非表示")
end

--[[
    getCurrentScreen
    現在表示中の画面を取得
    @return string 画面名
]]
function UIManager.getCurrentScreen()
    return _currentScreen
end

--[[
    onScreenChanged
    画面変更時のコールバック登録
    @param callback function(oldScreen, newScreen)
]]
function UIManager.onScreenChanged(callback)
    table.insert(_screenChangedCallbacks, callback)
end

--[[
    getScreen
    画面のScreenGuiを取得
    @param screenName string 画面名
    @return ScreenGui
]]
function UIManager.getScreen(screenName)
    local playerGui = _getPlayerGui()
    if not playerGui then
        return nil
    end

    return playerGui:FindFirstChild(screenName)
end

--[[
    isScreenVisible
    指定画面が表示中か確認
    @param screenName string 画面名
    @return boolean
]]
function UIManager.isScreenVisible(screenName)
    local playerGui = _getPlayerGui()
    if not playerGui then
        return false
    end

    local screenGui = playerGui:FindFirstChild(screenName)
    if screenGui then
        return screenGui.Enabled
    end

    return false
end

return UIManager
