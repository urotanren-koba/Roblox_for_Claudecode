-- ============================================
-- ボタンハンドラー - LocalScript
-- StarterGui > GameUI に配置してください
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gameUI = playerGui:WaitForChild("GameUI")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local startGameRemote = remotes:WaitForChild("StartGameRemote")
local resetGameRemote = remotes:WaitForChild("ResetGameRemote")

local startButton = gameUI:WaitForChild("StartButton")
local winnerPanel = gameUI:WaitForChild("WinnerPanel")
local restartButton = winnerPanel:WaitForChild("RestartButton")

startButton.MouseButton1Click:Connect(function()
    startGameRemote:FireServer()
end)

restartButton.MouseButton1Click:Connect(function()
    resetGameRemote:FireServer()
end)

print("GameUI buttons connected!")
