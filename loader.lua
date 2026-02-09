-- Modular Mining Script Loader
-- Loads all modules using loadstring for better organization

-- External Dependencies
loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Shared state and services
local Rep = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Global state table shared across modules
local State = {
    -- Core state
    connections = {},
    mainLoopRunning = false,
    
    -- Ore caching and ESP
    cachedOres = {},
    cachedOreIds = {},
    oreIdConnections = {},
    
    -- Player ESP
    PlayerESPEnabled = false,
    PlayerESPHighlights = {},
    PlayerESPBillboards = {},
    PlayerESPMaxDistance = 0,
    PlayerESPFrameCounter = 0,
    PlayerESPRespawnConnections = {},
    PlayerESPShowName = true,
    PlayerESPShowDistance = false,
    PlayerESPTracersEnabled = false,
    PlayerESPTracersShowOffscreen = true,
    PlayerESPTracers = {},
    friendshipCache = {},
    
    -- Movement and input
    isLeftClickHeld = false,
    isAutoTunnel = false,
    autoTunnelLookDirection = nil,
    
    -- UI
    cargoScreenGui = nil,
    cargoFrame = nil,
    cargoLabel = nil,
    pingScreenGui = nil,
    pingFrame = nil,
    pingLabel = nil,
    cachedTimerLabel = nil,
    
    -- Character state
    character = nil,
    humanoid = nil,
    root = nil,
    
    -- Runtime caches
    targetsOrderCache = {},
    consecutiveFails = 0,
    lastCleanup = 0,
    lastVPress = 0,
    savedBoostSpeed = 100
}

-- Config table shared across modules
local Config = {
    AutoMining = false,
    MineRange = 40,
    DebugAutoMining = false,
    BoostSpeed = 100,
    boostEnabled = false,
    moving = false,
    SelectedOres = {},
    SelectedGems = {},
    ESPEnabled = true,
    ESPRange = 300,
    ActiveHighlights = {},
    ESPGroups = {}
}

-- Game Modules
local Packages = Rep:WaitForChild("Packages")
local InnoTools = Packages:WaitForChild("InnoTools")
require(InnoTools:WaitForChild("ToolController"))
local ToolBase = require(InnoTools:WaitForChild("ToolBase"))
local Controllers = Rep:WaitForChild("Controllers")
local PlayerDataController = require(Controllers:WaitForChild("PlayerDataController"))
local PlayerStats = PlayerDataController.LocalPlayerData.Upgrades
local MiningTimeFunction = require(Rep.Packages.Mining.MiningTimeFunction)
local MineTerrain = require(Rep.Packages.Mining.MineTerrain)
local BlockDefinitions = require(Rep.Definitions.BlockDefinitions)

local PlacedOre = workspace:WaitForChild("PlacedOre")
local VehiclesFolder = workspace:WaitForChild("Vehicles")

-- Initialize character state
State.character = player.Character or player.CharacterAdded:Wait()
State.humanoid = State.character:WaitForChild("Humanoid")
State.root = State.character:WaitForChild("HumanoidRootPart")

-- Find and disable collision for Hitbox
local hitbox = State.character:FindFirstChild("Hitbox")
if hitbox then
    hitbox.CanCollide = false
end

-- Module loader function using loadstring
local function loadModule(moduleName)
    local success, module = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/xoodxoodxoodgame-glitch/roblox_scripts/main/" .. moduleName .. ".lua?v=" .. tick()))()
    end)
    
    if success then
        return module
    else
        warn("Failed to load module:", moduleName, "-", module)
        return nil
    end
end

-- Load all modules
local Utilities = loadModule("Utilities")
local UI = loadModule("UI")
local Mining = loadModule("Mining")
local ESP = loadModule("ESP")
local Movement = loadModule("Movement")
local Vehicle = loadModule("Vehicle")

-- Shared services object passed to all modules
local Services = {
    Rep = Rep,
    Players = Players,
    UserInputService = UserInputService,
    RunService = RunService,
    Workspace = Workspace,
    player = player,
    playerGui = playerGui,
    PlacedOre = PlacedOre,
    VehiclesFolder = VehiclesFolder,
    ToolBase = ToolBase,
    PlayerStats = PlayerStats,
    MiningTimeFunction = MiningTimeFunction,
    MineTerrain = MineTerrain,
    BlockDefinitions = BlockDefinitions
}

-- Initialize modules with shared state and services
if Utilities then
    Utilities.init(State, Config, Services)
end

if UI then
    UI.init(State, Config, Fluent, SaveManager, InterfaceManager, Services)
end

if Mining then
    Mining.init(State, Config, Services)
end

if ESP then
    ESP.init(State, Config, Services)
end

if Movement then
    Movement.init(State, Config, Services)
end

if Vehicle then
    Vehicle.init(State, Config, Services)
end

-- Set cross-module references
if ESP then
    ESP.UI = UI
    ESP.Mining = Mining
end

if UI then
    UI.ESP = ESP
    UI.Mining = Mining
    UI.Movement = Movement
end

if Mining then
    Mining.UI = UI
end

if Movement then
    Movement.UI = UI
    Movement.Mining = Mining
end

-- Setup SaveManager and InterfaceManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/Mining")

-- Build interface sections
if UI and UI.Tabs then
    InterfaceManager:BuildInterfaceSection(UI.Tabs.Settings)
    SaveManager:BuildConfigSection(UI.Tabs.Settings)
    if UI.Window then
        UI.Window:SelectTab(1)
    end
end

SaveManager:LoadAutoloadConfig()

print("✅ Modular Mining Script Loaded Successfully!")
