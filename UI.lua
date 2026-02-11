-- UI Module - Handles Fluent UI creation and management
local UI = {}

function UI.init(State, Config, Fluent, SaveManager, InterfaceManager)
    UI.State = State
    UI.Config = Config
    UI.Fluent = Fluent
    UI.SaveManager = SaveManager
    UI.InterfaceManager = InterfaceManager
    
    -- Create main window
    UI.Window = Fluent:CreateWindow({
        Title = "Fluent " .. Fluent.Version,
        SubTitle = "by dawid",
        TabWidth = 120,
        Size = UDim2.fromOffset(600, 600),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })
    
    -- Create tabs
    UI.Tabs = {
        Main = UI.Window:AddTab({ Title = "Main", Icon = "" }),
        PlayerESP = UI.Window:AddTab({ Title = "Player ESP", Icon = "eye" }),
        Statistics = UI.Window:AddTab({ Title = "Statistics", Icon = "bar-chart" }),
        Settings = UI.Window:AddTab({ Title = "Settings", Icon = "settings" })
    }
    
    UI:createMainTab()
    UI:createPlayerESPTab()
    UI:createStatisticsTab()
    
    -- Setup ping display
    UI:setupPingDisplay()
    
    -- Setup collapse timer update to use existing cachedTimerLabel
    UI:setupCollapseTimerUpdate()
    
    return UI
end

function UI:createMainTab()
    local Tabs = UI.Tabs
    
    -- Auto Mining Toggle
    local Toggle = Tabs.Main:AddToggle("AutoMining", {Title = "Auto Mining", Default = false })
    
    Tabs.Settings:AddKeybind("AutoMiningKeybind", {
        Title = "Auto Mining Keybind",
        Mode = "Toggle",
        Default = "Q",
        Callback = function(Value)
            UI.Config.AutoMining = Value
            Toggle:SetValue(Value)
        end
    })
    
    -- KILL SWITCH BUTTON - Emergency stop all functionality
    local KillSwitchButton = Tabs.Settings:AddButton({
        Title = "🚨 KILL SWITCH",
        Description = "EMERGENCY STOP - Disables all features immediately",
        Callback = function()
            -- Show confirmation notification instead of dialog
            UI.Fluent:Notify({
                Title = "🚨 KILL SWITCH",
                Content = "Press Alt+K to activate emergency stop\n(This will disable ALL features immediately)",
                Duration = 5
            })
        end
    })
    
    -- Add keybind hint for kill switch
    Tabs.Settings:AddParagraph({
        Title = "Kill Switch Shortcut",
        Content = "Press Alt + K for instant emergency stop (no confirmation)"
    })
    
    Toggle:OnChanged(function(Value)
        UI.Config.AutoMining = Value
        
        UI.Fluent:Notify({
            Title = Value and "✅ Auto Mining Enabled" or "❌ Auto Mining Disabled",
            Content = Value and "Mining script is now active!" or "Mining script has been stopped.",
            Duration = 2
        })
    end)
    
    -- Boost Speed Slider
    local BoostSlider = Tabs.Main:AddSlider("BoostSpeed", {
        Title = "Boost Speed",
        Description = "Extra movement speed when boost is active (press U to toggle)",
        Default = 100,
        Min = 20,
        Max = 500,
        Rounding = 0,
        Callback = function(Value)
            UI.Config.BoostSpeed = tonumber(Value)
        end
    })
    
    BoostSlider:OnChanged(function(Value)
        UI.Config.BoostSpeed = tonumber(Value)
        if UI.Movement and UI.Movement.updateGravity then
            UI.Movement.updateGravity()
        end
    end)
    
    -- ESP Range Slider
    local ESPRangeSlider = Tabs.Main:AddSlider("ESPRange", {
        Title = "ESP Range",
        Description = "Maximum distance to show ESP markers (in studs)",
        Default = 300,
        Min = 100,
        Max = 500,
        Rounding = 0,
        Callback = function(Value)
            UI.Config.ESPRange = tonumber(Value)
        end
    })
    
    ESPRangeSlider:OnChanged(function(Value)
        UI.Config.ESPRange = tonumber(Value)
    end)
    
    -- Ore Selection Dropdown
    local OreDropdown = Tabs.Main:AddDropdown("SelectedOres", {
        Title = "Select Ores to Mine",
        Description = "Choose which ores to automatically mine",
        Values = UI:getOreTypes().materials,
        Multi = true,
        Default = {},
    })
    
    OreDropdown:OnChanged(function(Value)
        UI.Config.SelectedOres = {}
        for OreName, State in next, Value do
            if State then
                UI.Config.SelectedOres[OreName] = true
            end
        end
    end)
    
    -- Gem Selection Dropdown
    local GemDropdown = Tabs.Main:AddDropdown("SelectedGems", {
        Title = "Select Gems to Mine",
        Description = "Choose which gems to automatically mine",
        Values = UI:getOreTypes().gems,
        Multi = true,
        Default = {},
    })
    
    GemDropdown:OnChanged(function(Value)
        UI.Config.SelectedGems = {}
        for GemName, State in next, Value do
            if State then
                UI.Config.SelectedGems[GemName] = true
            end
        end
    end)
end

function UI:createPlayerESPTab()
    local Tabs = UI.Tabs
    
    -- Player ESP Toggle
    local PlayerESPToggle = Tabs.PlayerESP:AddToggle("PlayerESPEnabled", {
        Title = "Enable Player ESP",
        Description = "Highlights + labels for players",
        Default = false,
    })
    
    PlayerESPToggle:OnChanged(function(Value)
        UI.State.PlayerESPEnabled = Value and true or false
        if UI.ESP then
            if UI.State.PlayerESPEnabled then
                UI.ESP.enablePlayerESP()
            else
                UI.ESP.disablePlayerESP()
            end
        end
    end)
    
    -- Show Name Toggle
    local PlayerESPShowNameToggle = Tabs.PlayerESP:AddToggle("PlayerESPShowName", {
        Title = "Show Name",
        Description = "Show first 6 chars of name",
        Default = true,
    })
    
    PlayerESPShowNameToggle:OnChanged(function(Value)
        UI.State.PlayerESPShowName = Value and true or false
    end)
    
    -- Show Distance Toggle
    local PlayerESPShowDistanceToggle = Tabs.PlayerESP:AddToggle("PlayerESPShowDistance", {
        Title = "Show Distance",
        Description = "Show distance on label",
        Default = false,
    })
    
    PlayerESPShowDistanceToggle:OnChanged(function(Value)
        UI.State.PlayerESPShowDistance = Value and true or false
    end)
    
    -- ESP Range Slider
    local PlayerESPRangeSlider = Tabs.PlayerESP:AddSlider("PlayerESPRange", {
        Title = "ESP Range",
        Description = "Only show players within this distance (0 = unlimited)",
        Default = 0,
        Min = 0,
        Max = 20000,
        Rounding = 0,
    })
    
    PlayerESPRangeSlider:OnChanged(function(Value)
        UI.State.PlayerESPMaxDistance = Value or 0
    end)
    
    -- Tracer Lines Toggle
    local PlayerESPTracersToggle = Tabs.PlayerESP:AddToggle("PlayerESPTracers", {
        Title = "Tracer Lines",
        Description = "Line from top-center of screen to player (requires Drawing API)",
        Default = false,
    })
    
    PlayerESPTracersToggle:OnChanged(function(Value)
        UI.State.PlayerESPTracersEnabled = Value and true or false
        if not UI.State.PlayerESPTracersEnabled and UI.ESP then
            UI.ESP.clearTracers()
        end
    end)
    
    -- Tracers Offscreen Toggle
    local PlayerESPTracersOffscreenToggle = Tabs.PlayerESP:AddToggle("PlayerESPTracersOffscreen", {
        Title = "Tracers Offscreen",
        Description = "Keep tracers visible offscreen (clamped to screen edge)",
        Default = true,
    })
    
    PlayerESPTracersOffscreenToggle:OnChanged(function(Value)
        UI.State.PlayerESPTracersShowOffscreen = Value and true or false
    end)
end

function UI:getOreTypes()
    -- Materials ordered by hardness (lowest to highest)
    local materials = {
        "Tin", "Iron", "Lead", "Cobalt", "Aluminium", "Silver", "Uranium", "Vanadium",
        "Tungsten","Gold", "Titanium", "Molybdenum", "Plutonium", "Palladium",
        "Mithril", "Thorium", "Iridium", "Adamantium", "Rhodium", "Unobtainium"
    }

    -- Gems in definition order
    local gems = {
        "Topaz", "Emerald", "Ruby", "Sapphire", "Diamond", "Poudretteite",
        "Zultanite", "Grandidierite", "Musgravite", "Painite"
    }

    return {
        materials = materials,
        gems = gems,
        all = function()
            local all = {}
            for _, ore in ipairs(materials) do
                table.insert(all, ore)
            end
            for _, gem in ipairs(gems) do
                table.insert(all, gem)
            end
            return all
        end
    }
end

function UI.createOrePackCargoGUI(playerGui)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "OrePackCargoGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local cargoFrame = Instance.new("Frame")
    cargoFrame.Name = "CargoFrame"
    cargoFrame.Size = UDim2.new(0, 160, 0, 40)
    cargoFrame.Position = UDim2.new(0, 10, 1, -40) -- Bottom-left
    cargoFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    cargoFrame.BackgroundTransparency = 0.3
    cargoFrame.BorderSizePixel = 0
    cargoFrame.Parent = screenGui

    -- Add rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = cargoFrame

    local cargoLabel = Instance.new("TextLabel")
    cargoLabel.Name = "CargoLabel"
    cargoLabel.Size = UDim2.new(1, 0, 1, 0)
    cargoLabel.BackgroundTransparency = 1
    cargoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    cargoLabel.TextSize = 24
    cargoLabel.Font = Enum.Font.SourceSansBold
    cargoLabel.Text = "Loading..."
    cargoLabel.Parent = cargoFrame

    return screenGui, cargoFrame, cargoLabel
end

function UI.createPingDisplay(playerGui)
    local pingScreenGui = Instance.new("ScreenGui")
    pingScreenGui.Name = "PingDisplayGUI"
    pingScreenGui.ResetOnSpawn = false
    pingScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pingScreenGui.Parent = playerGui

    local pingFrame = Instance.new("Frame")
    pingFrame.Name = "PingFrame"
    pingFrame.Size = UDim2.new(0, 120, 0, 35)
    pingFrame.Position = UDim2.new(0, 10, 0.5, -17.5) -- Center-left
    pingFrame.AnchorPoint = Vector2.new(0, 0.5) -- Anchor to center-left
    pingFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    pingFrame.BackgroundTransparency = 0.4
    pingFrame.BorderSizePixel = 0
    pingFrame.Parent = pingScreenGui

    -- Add rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = pingFrame

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "PingLabel"
    pingLabel.Size = UDim2.new(1, 0, 1, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    pingLabel.TextSize = 16
    pingLabel.Font = Enum.Font.SourceSansBold
    pingLabel.Text = "Ping: --ms"
    pingLabel.Parent = pingFrame

    return pingScreenGui, pingFrame, pingLabel
end

function UI:setupPingDisplay()
    -- Create ping display GUI using the existing function
    UI.State.pingScreenGui, UI.State.pingFrame, UI.State.pingLabel = 
        UI.createPingDisplay(UI.State.playerGui)
    
    -- Start ping update loop
    UI:startPingUpdateLoop()
end

function UI:startPingUpdateLoop()
    task.spawn(function()
        while UI.State.pingScreenGui and UI.State.pingScreenGui.Parent do
            -- Fix: Check if pingLabel exists before trying to use it
            if UI.State.pingLabel then
                local ping = math.floor(game.Players.LocalPlayer:GetNetworkPing() * 1000)
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

                UI.State.pingLabel.TextColor3 = pingColor
                UI.State.pingLabel.Text = string.format("🏓 %dms", ping)
            end

            task.wait(1)
        end
    end)
end

function UI:setupCollapseTimerUpdate()
    -- Set up connection to monitor Percent text changes
    local function setupConnection()
        local collapseStuff = workspace:FindFirstChild("CollapseStuff")
        if not collapseStuff then return end
        
        local collapseSignGui = collapseStuff:FindFirstChild("CollapseSignGui")
        if not collapseSignGui then return end
        
        local billboardGui = collapseSignGui:FindFirstChild("BillboardGui")
        if not billboardGui then return end
        
        local percent = billboardGui:FindFirstChild("Percent")
        if not percent then return end
        
        -- Connect to the Text property change signal
        local connection = percent:GetPropertyChangedSignal("Text"):Connect(function()
            UI:updateCollapseTimerDisplay(percent)
        end)
        
        -- Store connection for cleanup
        table.insert(UI.State.connections, connection)
        
        -- Initial update
        UI:updateCollapseTimerDisplay(percent)
    end
    
    -- Try to setup connection immediately
    setupConnection()
    
    -- Also setup a watcher for when the objects get created
    local function waitForObjects()
        local collapseStuff = workspace:WaitForChild("CollapseStuff", 5)
        if collapseStuff then
            local collapseSignGui = collapseStuff:WaitForChild("CollapseSignGui", 5)
            if collapseSignGui then
                local billboardGui = collapseSignGui:WaitForChild("BillboardGui", 5)
                if billboardGui then
                    local percent = billboardGui:WaitForChild("Percent", 5)
                    if percent then
                        setupConnection()
                    end
                end
            end
        end
    end
    
    -- Start watching for objects in case they're not created yet
    task.spawn(waitForObjects)
end

function UI:updateCollapseTimerDisplay(percentLabel)
    if not UI.State.cachedTimerLabel or not percentLabel then return end
    
    local percentValue = percentLabel.Text
    
    -- Extract numeric value from text (assuming format like "75%" or "75")
    local numericValue = percentValue:gsub("%%", "")
    local number = tonumber(numericValue)
    
    if number then
        -- Format as percentage display
        local timeDisplay = string.format("%s%%", numericValue)
        
        -- Color code based on percentage
        local timerColor = Color3.fromRGB(255, 255, 255)
        if number <= 25 then
            timerColor = Color3.fromRGB(255, 0, 0) -- Red for low time
        elseif number <= 50 then
            timerColor = Color3.fromRGB(255, 165, 0) -- Orange for medium time
        elseif number <= 75 then
            timerColor = Color3.fromRGB(255, 255, 0) -- Yellow for getting low
        else
            timerColor = Color3.fromRGB(0, 255, 0) -- Green for plenty of time
        end
        
        UI.State.cachedTimerLabel.TextColor3 = timerColor
        UI.State.cachedTimerLabel.Text = timeDisplay
    else
        UI.State.cachedTimerLabel.Text = percentValue
        UI.State.cachedTimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

function UI:createStatisticsTab()
    local Tabs = UI.Tabs
    
    -- Statistics Title
    Tabs.Statistics:AddParagraph({
        Title = "📊 Mining Statistics",
        Content = "Track your mining progress and earnings"
    })
    
    -- Statistics Section
    Tabs.Statistics:AddSection("Ore Breakdown")
    
    -- Function to create ore display labels
    local function createOreDisplay(oreName, oreId)
        local oreLabel = Tabs.Statistics:AddParagraph({
            Title = oreName .. " Statistics",
            Description = "Total " .. oreName .. " mined: 0\nValue: $0.00"
        })
        
        local oreValueLabel = Tabs.Statistics:AddParagraph({
            Title = oreName .. " Value", 
            Description = "Total value of " .. oreName .. " mined: $0.00"
        })
        
        return oreLabel, oreValueLabel
    end
    
    -- Create displays for common materials
    local materialDisplays = {}
    local materials = {"Tin", "Iron", "Lead", "Cobalt", "Aluminium", "Silver", "Uranium", "Vanadium", "Gold", "Titanium", "Tungsten", "Molybdenum", "Plutonium", "Palladium", "Mithril", "Thorium", "Iridium", "Adamantium", "Rhodium", "Unobtainium"}
    
    for _, materialName in ipairs(materials) do
        local label, valueLabel = createOreDisplay(materialName, materialName)
        materialDisplays[materialName] = {label = label, valueLabel = valueLabel}
    end
    
    -- Create displays for gems
    local gemDisplays = {}
    local gems = {"Topaz", "Emerald", "Ruby", "Sapphire", "Diamond", "Poudretteite", "Zultanite", "Grandidierite", "Musgravite", "Painite"}
    
    for _, gemName in ipairs(gems) do
        local label, valueLabel = createOreDisplay(gemName, gemName)
        gemDisplays[gemName] = {label = label, valueLabel = valueLabel}
    end
    
    -- Function to update statistics display
    local function updateStatistics()
        if UI.State and UI.Mining then
            -- Update material counts and values
            for materialName, displays in pairs(materialDisplays) do
                if UI.State.oreCounts and UI.State.oreCounts[materialName] then
                    displays.label:SetDesc(materialName .. "\nTotal: " .. materialName .. " x" .. UI.State.oreCounts[materialName] .. "\nValue: $" .. string.format("%.2f", (UI.Mining.MATERIAL_DATA and UI.Mining.MATERIAL_DATA[materialName] and UI.Mining.MATERIAL_DATA[materialName].value or 0) * UI.State.oreCounts[materialName]))
                else
                    displays.label:SetDesc(materialName .. "\nTotal: " .. materialName .. " x0\nValue: $0.00")
                end
            end
            
            -- Update gem counts and values
            for gemName, displays in pairs(gemDisplays) do
                if UI.State.gemCounts and UI.State.gemCounts[gemName] then
                    displays.label:SetDesc(gemName .. "\nTotal: " .. gemName .. " x" .. UI.State.gemCounts[gemName] .. "\nValue: $" .. string.format("%.2f", (UI.Mining.GEM_DATA and UI.Mining.GEM_DATA[gemName] and UI.Mining.GEM_DATA[gemName].value or 0) * UI.State.gemCounts[gemName]))
                else
                    displays.label:SetDesc(gemName .. "\nTotal: " .. gemName .. " x0\nValue: $0.00")
                end
            end
        end
    end
    
    -- Update statistics every 2 seconds
    task.spawn(function()
        while UI.Fluent and not UI.Fluent.Unloaded do
            updateStatistics()
            task.wait(2)
        end
    end)
    
    -- Initial update
    updateStatistics()
end

function UI:cleanup()
    print("UI: Cleaning up...")
    
    -- Destroy the entire Fluent UI window
    if UI.Fluent then
        UI.Fluent:Destroy()
        UI.Fluent = nil
    end
    
    -- Stop ping update loop
    if UI.State.pingScreenGui then
        UI.State.pingScreenGui:Destroy()
        UI.State.pingScreenGui = nil
    end
    
    -- Clear UI references
    UI.State.pingFrame = nil
    UI.State.pingLabel = nil
    UI.State.cargoScreenGui = nil
    UI.State.cargoFrame = nil
    UI.State.cargoLabel = nil
    UI.State.cachedTimerLabel = nil
    
    -- Clear module references
    UI.ESP = nil
    UI.Mining = nil
    UI.Movement = nil
    
    print("UI: Cleanup complete")
end

return UI
