--[[
    GameManager
    ゲーム全体の状態を管理するモジュール
    状態遷移: Loading → Home → Battle → Result → Home
]]

local GameManager = {}

-- ゲーム状態の定義
GameManager.States = {
    LOADING = "Loading",
    HOME = "Home",
    STAGE_SELECT = "StageSelect",
    BATTLE = "Battle",
    RESULT = "Result",
    GACHA = "Gacha",
    CHARACTER = "Character",
    SHOP = "Shop",
}

-- 現在の状態
local _currentState = GameManager.States.LOADING

-- 状態変更時のコールバック
local _stateChangedCallbacks = {}

-- プライベート関数: コールバック実行
local function _notifyStateChanged(oldState, newState)
    for _, callback in ipairs(_stateChangedCallbacks) do
        task.spawn(function()
            callback(oldState, newState)
        end)
    end
end

--[[
    getCurrentState
    現在のゲーム状態を取得
    @return string 現在の状態
]]
function GameManager.getCurrentState()
    return _currentState
end

--[[
    changeState
    ゲーム状態を変更
    @param newState string 新しい状態
    @return boolean 変更成功したか
]]
function GameManager.changeState(newState)
    -- 有効な状態かチェック
    local isValid = false
    for _, state in pairs(GameManager.States) do
        if state == newState then
            isValid = true
            break
        end
    end

    if not isValid then
        warn("[GameManager] 無効な状態: " .. tostring(newState))
        return false
    end

    local oldState = _currentState
    _currentState = newState

    print("[GameManager] 状態変更: " .. oldState .. " → " .. newState)
    _notifyStateChanged(oldState, newState)

    return true
end

--[[
    onStateChanged
    状態変更時のコールバックを登録
    @param callback function(oldState, newState)
]]
function GameManager.onStateChanged(callback)
    table.insert(_stateChangedCallbacks, callback)
end

--[[
    isState
    指定した状態かどうかをチェック
    @param state string チェックする状態
    @return boolean
]]
function GameManager.isState(state)
    return _currentState == state
end

return GameManager
