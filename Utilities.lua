-- Utilities Module - Common functions and data structures
local Utilities = {}

function Utilities.init(State, Config, Services)
    Utilities.State = State
    Utilities.Config = Config
    Utilities.Services = Services or {}
    
    -- Setup proximity prompt removal
    Utilities:setupProximityPrompts()
    
    -- Setup cleanup function
    Utilities:setupCleanup()
    
    -- Setup ping display
    Utilities:setupPingDisplay()
    
    return Utilities
end

function Utilities:setupProximityPrompts()
    local CHUNK_SIZE = 50 
    local function apply(obj)
        if obj:IsA("ProximityPrompt") then
            obj.HoldDuration = 0
        end
    end
    
    task.spawn(function()
        local all = Utilities.Services.Workspace:GetDescendants()
        local i = 1

        while i <= #all do
            local upper = math.min(i + CHUNK_SIZE - 1, #all)

            for j = i, upper do
                local obj = all[j]
                if obj then
                    apply(obj)
                end
            end

            i = upper + 1
            task.wait(0.05)
        end
    end)
    
    Utilities.State.connections.proximityPromptAdded = Utilities.Services.Workspace.DescendantAdded:Connect(apply)
end

function Utilities:setupPingDisplay()
    -- Create ping display GUI
    local UI = require(script.Parent.UI) or {}
    if UI.createPingDisplay then
        Utilities.State.pingScreenGui, Utilities.State.pingFrame, Utilities.State.pingLabel = 
            UI.createPingDisplay(Utilities.Services.playerGui)
    end
    
    -- Start ping display update loop
    Utilities:startPingUpdateLoop()
end

function Utilities:startPingUpdateLoop()
    task.spawn(function()
        while Utilities.State.pingScreenGui and Utilities.State.pingScreenGui.Parent do
            local ping = math.floor(Utilities.Services.Players.LocalPlayer:GetNetworkPing() * 1000)
            local pingColor = Color3.fromRGB(255, 255, 255)

            if ping < 50 then
                pingColor = Color3.fromRGB(0, 255, 0)
            elseif ping < 100 then
                pingColor = Color3.fromRGB(255, 255, 0)
            elseif ping < 200 then
                pingColor = Color3.fromRGB(255, 165, 0)
            else
                pingColor = Color3.fromRGB(255, 0, 0)
            end

            Utilities.State.pingLabel.TextColor3 = pingColor
            Utilities.State.pingLabel.Text = string.format("🏓 %dms", ping)

            task.wait(1)
        end
    end)
end

function Utilities:setupCleanup()
    -- Cleanup function for proper resource management
    Utilities.cleanup = function()
        Utilities.State.mainLoopRunning = false

        -- Disconnect all tracked connections
        for name, connection in pairs(Utilities.State.connections) do
            if connection then
                pcall(function() connection:Disconnect() end)
            end
        end
        Utilities.State.connections = {}

        -- Clear cached data
        Utilities.State.cachedOres = {}
        Utilities.State.cachedOreIds = {}
        
        -- Disconnect all ore ID change listeners
        for ore, connection in pairs(Utilities.State.oreIdConnections) do
            if connection then
                connection:Disconnect()
            end
        end
        Utilities.State.oreIdConnections = {}

        -- Clear friendship cache
        Utilities.State.friendshipCache = {}

        -- Destroy GUI elements
        if Utilities.State.cargoScreenGui and Utilities.State.cargoScreenGui.Parent then
            pcall(function() Utilities.State.cargoScreenGui:Destroy() end)
        end
        if Utilities.State.pingScreenGui and Utilities.State.pingScreenGui.Parent then
            pcall(function() Utilities.State.pingScreenGui:Destroy() end)
        end
    end

    -- Cleanup when player leaves the game
    Utilities.State.connections.playerRemoving = Utilities.Services.Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == Utilities.Services.player then
            Utilities.cleanup()
        end
    end)
end

function Utilities:dprint(...)
    if Utilities.Config.DebugAutoMining then
        print(...)
    end
end

return Utilities
