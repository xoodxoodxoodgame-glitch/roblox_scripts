-- Mining Module - Handles auto mining, ore detection, and tool stats
local Mining = {}

function Mining.init(State, Config, Services)
    Mining.State = State
    Mining.Config = Config
    Mining.Services = Services or {}
    
    -- Constants
    Mining.CELL = 4
    Mining.ORIGIN = Vector3.new(0, 0, 0)
    Mining.PROXIMITY_BUCKET_SIZE = 10
    
    -- Initialize material and gem data
    Mining:loadMaterialData()
    
    -- Setup ore caching
    Mining:setupOreCaching()
    
    -- Setup cargo UI
    Mining:setupCargoUI()
    
    -- Setup timer UI
    Mining:setupTimerUI()
    
    -- Start main mining loop
    Mining:startMiningLoop()
    
    -- Start timer update loop
    Mining:startTimerLoop()
    
    return Mining
end

function Mining:loadMaterialData()
    -- Current color mappings to preserve
    local CURRENT_COLORS = {
        -- Materials
        ["Tin"] = Color3.fromRGB(169, 169, 169),
        ["Iron"] = Color3.fromRGB(160, 82, 45),
        ["Lead"] = Color3.fromRGB(96, 96, 96),
        ["Cobalt"] = Color3.fromRGB(0, 71, 171),
        ["Aluminium"] = Color3.fromRGB(220, 220, 240),
        ["Silver"] = Color3.fromRGB(192, 192, 220),
        ["Uranium"] = Color3.fromRGB(0, 255, 0),
        ["Vanadium"] = Color3.fromRGB(173, 255, 47),
        ["Gold"] = Color3.fromRGB(255, 215, 0),
        ["Titanium"] = Color3.fromRGB(128, 0, 128),
        ["Tungsten"] = Color3.fromRGB(64, 64, 72),
        ["Molybdenum"] = Color3.fromRGB(160, 160, 170),
        ["Plutonium"] = Color3.fromRGB(0, 255, 255),
        ["Palladium"] = Color3.fromRGB(255, 255, 0),
        ["Iridium"] = Color3.fromRGB(255, 255, 255),
        ["Mithril"] = Color3.fromRGB(144, 238, 144),
        ["Thorium"] = Color3.fromRGB(0, 160, 80),
        ["Adamantium"] = Color3.fromRGB(0, 120, 40),
        ["Rhodium"] = Color3.fromRGB(139, 69, 19),
        ["Unobtainium"] = Color3.fromRGB(255, 0, 128),
        -- Gems
        ["Topaz"] = Color3.fromRGB(255, 191, 0),
        ["Emerald"] = Color3.fromRGB(0, 128, 0),
        ["Sapphire"] = Color3.fromRGB(0, 0, 255),
        ["Ruby"] = Color3.fromRGB(220, 20, 60),
        ["Diamond"] = Color3.fromRGB(0, 255, 255),
        ["Poudretteite"] = Color3.fromRGB(255, 0, 128),
        ["Zultanite"] = Color3.fromRGB(128, 0, 128),
        ["Grandidierite"] = Color3.fromRGB(0, 128, 128),
        ["Musgravite"] = Color3.fromRGB(128, 0, 64),
        ["Painite"] = Color3.fromRGB(255, 0, 0),
    }

    local materials = {}
    local gems = {}

    for oreId, oreData in pairs(self.Services.BlockDefinitions) do
        if oreData.Types and oreData.Types.Ore then
            materials[oreId] = {
                name = oreData.Name or oreId,
                color = CURRENT_COLORS[oreId] or (oreData.Appearance and oreData.Appearance.Color) or Color3.fromRGB(255, 255, 255),
                hardness = oreData.Hardness or 0,
                value = oreData.Value or 0
            }
        elseif oreData.Types and oreData.Types.Gem then
            gems[oreId] = {
                name = oreData.Name or oreId,
                color = CURRENT_COLORS[oreId] or (oreData.Appearance and oreData.Appearance.Color) or Color3.fromRGB(255, 255, 255),
                hardness = oreData.Hardness or 0,
                value = oreData.Value or 0
            }
        end
    end

    Mining.MATERIAL_DATA = materials
    Mining.GEM_DATA = gems
end

function Mining:setupOreCaching()
    -- Handle existing ores and gems that are already placed when script starts
    for _, ore in ipairs(self.Services.PlacedOre:GetChildren()) do
        if ore:GetAttribute("MineId") then
            self.State.cachedOres[ore] = true
            self:cacheOreId(ore)
            ore.CanCollide = false
            ore.CanTouch = false
            ore.CanQuery = false
        end
    end

    -- Setup connections for new ores
    self.State.connections.placedOreAdded = self.Services.PlacedOre.ChildAdded:Connect(function(ore)
        if ore:GetAttribute("MineId") then
            self.State.cachedOres[ore] = true
            self:cacheOreId(ore)
            ore.CanCollide = false
            ore.CanTouch = false
            ore.CanQuery = false
        end
    end)

    self.State.connections.placedOreRemoved = self.Services.PlacedOre.ChildRemoved:Connect(function(ore)
        if self.State.cachedOres[ore] then
            if self.Config.ActiveHighlights[ore] then
                self:releaseHighlight(self.Config.ActiveHighlights[ore])
                self.Config.ActiveHighlights[ore] = nil
            end
            self:removeOreIdCache(ore)
            self.State.cachedOres[ore] = nil
        end
    end)
end

function Mining:setupCargoUI()
    -- Create cargo UI using UI module's function
    if self.UI then
        print("Mining: UI module found, creating cargo GUI")
        -- Call the static function correctly
        if self.UI.createOrePackCargoGUI then
            print("Mining: createOrePackCargoGUI function found")
            local screenGui, cargoFrame, cargoLabel = self.UI.createOrePackCargoGUI(self.Services.playerGui)
            self.State.cargoScreenGui = screenGui
            self.State.cargoFrame = cargoFrame
            self.State.cargoLabel = cargoLabel
            print("Mining: Cargo GUI created successfully via UI module")
            print("Mining: cargoLabel =", self.State.cargoLabel)
            print("Mining: cargoLabel type =", type(self.State.cargoLabel))
            if self.State.cargoLabel then
                print("Mining: cargoLabel.Name =", self.State.cargoLabel.Name)
            else
                warn("Mining: cargoLabel is still nil after UI module call - using fallback")
                self:createFallbackCargoUI()
            end
        else
            warn("Mining: createOrePackCargoGUI function not found in UI module. Attempting fallback.")
            -- Fallback: create cargo UI directly
            self:createFallbackCargoUI()
        end
    else
        warn("Mining: UI module not available. Attempting fallback.")
        -- Fallback: create cargo UI directly
        self:createFallbackCargoUI()
    end

    if not self.State.cargoLabel then
        warn("Mining: cargoLabel is nil after setupCargoUI completion - forcing fallback")
        self:createFallbackCargoUI()
    end
end

function Mining:createFallbackCargoUI()
    print("Mining: Creating fallback cargo UI")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "OrePackCargoGUI_Fallback"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = self.Services.playerGui

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

    self.State.cargoScreenGui = screenGui
    self.State.cargoFrame = cargoFrame
    self.State.cargoLabel = cargoLabel
    print("Mining: Fallback cargo UI created successfully")
    print("Mining: Fallback cargoLabel =", self.State.cargoLabel)
    print("Mining: Fallback cargoLabel.Name =", self.State.cargoLabel.Name)
end

function Mining:setupTimerUI()
    -- Create timer display (simple text label at top)
    local timerScreenGui = Instance.new("ScreenGui")
    timerScreenGui.Name = "MiningTimerGUI"
    timerScreenGui.ResetOnSpawn = false
    timerScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    timerScreenGui.Parent = self.Services.playerGui

    local timerFrame = Instance.new("Frame")
    timerFrame.Name = "TimerFrame"
    timerFrame.Size = UDim2.new(0, 200, 0, 30)
    timerFrame.Position = UDim2.new(0.5, -100, 0, 10) -- Top-center
    timerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    timerFrame.BackgroundTransparency = 0.3
    timerFrame.BorderSizePixel = 0
    timerFrame.Parent = timerScreenGui

    -- Add rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = timerFrame

    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, 0, 1, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timerLabel.TextSize = 18
    timerLabel.Font = Enum.Font.SourceSansBold
    timerLabel.Text = "00:00"
    timerLabel.Parent = timerFrame

    self.State.cachedTimerLabel = timerLabel
end

function Mining:cacheOreId(ore)
    if not ore or not ore.Parent then return end

    local oreId = ore:GetAttribute("MineId")
    if oreId then
        self.State.cachedOreIds[ore] = oreId

        if not self.State.oreIdConnections[ore] then
            self.State.oreIdConnections[ore] = ore:GetAttributeChangedSignal("MineId"):Connect(function()
                local newOreId = ore:GetAttribute("MineId")
                self.State.cachedOreIds[ore] = newOreId
            end)
        end
    end
end

function Mining:getCachedOreId(ore)
    return self.State.cachedOreIds[ore]
end

function Mining:removeOreIdCache(ore)
    self.State.cachedOreIds[ore] = nil
    if self.State.oreIdConnections[ore] then
        self.State.oreIdConnections[ore]:Disconnect()
        self.State.oreIdConnections[ore] = nil
    end
end

function Mining:getPickaxeStats(toolModel)
    local toolObj = self.Services.ToolBase.ToolsByModel[toolModel]
    if not toolObj then return nil end
    local def = toolObj.Definition
    if not def or not def.Stats then return nil end
    local stats = def.Stats
    if type(stats.Hardness) ~= "number" or type(stats.Speed) ~= "number" then return nil end

    -- Apply upgrade bonuses
    local strengthBonus = self.Services.PlayerStats.PickaxeStrength or 0
    local speedBonus = self.Services.PlayerStats.PickaxeSpeed or 0
    local strengthMultiplier = 0.1
    local speedMultiplier = 0.1

    local adjustedStrength = stats.Hardness * (1 + strengthBonus * strengthMultiplier)
    local adjustedSpeed = stats.Speed * (1 + speedBonus * speedMultiplier)

    return {
        strength = adjustedStrength,
        speed = adjustedSpeed,
        baseStrength = stats.Hardness,
        baseSpeed = stats.Speed,
    }
end

function Mining:GetTool()
    for _, v in ipairs(self.Services.player.Character:GetChildren()) do
        if v:FindFirstChild("EquipRemote") then
            return v
        end
    end

    for _, v in ipairs(self.Services.player.InnoBackpack:GetChildren()) do
        if v:FindFirstChild("EquipRemote") and v.Name:find("Pickaxe") then
            return v
        end
    end

    return nil
end

function Mining:getPickaxeClientFromToolModel(toolModel)
    if not toolModel then return nil end
    local toolObj = self.Services.ToolBase.ToolsByModel[toolModel]
    if not toolObj then return nil end
    return toolObj:FindComponentByName("PickaxeClient")
end

function Mining:mineTarget(gridPos)
    local tool = self:GetTool()
    if not tool then
        return false, "No tool equipped"
    end

    local toolName = tool.Name
    local toolStats = self:getPickaxeStats(tool)
    if not toolStats then
        return false, "No tool stats available"
    end

    local pickaxeClient = self:getPickaxeClientFromToolModel(tool)
    if not pickaxeClient then
        return false, "PickaxeClient not ready for tool: " .. toolName
    end

    -- Start animation before mining
    if pickaxeClient.SwingAnimTrack then
        pickaxeClient.SwingAnimTrack:Play(nil, nil, 2.4)
    end

    local mineTerrainInstance = self.Services.MineTerrain.GetInstance()
    local cellData = mineTerrainInstance:Get(gridPos)

    if not cellData or not cellData.Block then
        return false, "No valid terrain data found at position"
    end

    local blockDefinition = self.Services.BlockDefinitions[cellData.Ore or cellData.Block]
    local targetInfo = { isTerrain = cellData.Ore == nil, cellData = cellData, blockDefinition = blockDefinition }

    if targetInfo.blockDefinition and targetInfo.blockDefinition.Id == "Air" then
        return false, "Cannot mine air blocks"
    elseif targetInfo.blockDefinition and targetInfo.blockDefinition.Hardness then
        local miningTime = self.Services.MiningTimeFunction(toolStats.speed, toolStats.strength, targetInfo.blockDefinition.Hardness)

        local promise = pickaxeClient.ActivateRemote:InvokeServer(gridPos)
        local startTime = tick()
        local success, _ = promise:await()
        local elapsedTime = tick() - startTime
        local delay = math.max(0, miningTime - elapsedTime)

        local targetType = targetInfo.isTerrain and "Terrain " or ""
        local targetName = targetInfo.blockDefinition.Name or (targetInfo.isTerrain and targetInfo.cellData.Block) or targetInfo.oreData.name
   
        print(string.format("⛏️ %s%s (H%d) | %s (%.0f/%.0f) | M: %.2fs | P: %.2fs | D: %.2fs",
            targetType,
            targetName,
            targetInfo.blockDefinition.Hardness,
            toolName,
            toolStats.strength,
            toolStats.speed,
            miningTime,
            elapsedTime,
            delay))

        return true, delay
    else
        local blockName = targetInfo.isTerrain and targetInfo.cellData.Block or targetInfo.oreData.name
        warn(string.format("⚠️ Block '%s' has no hardness data - skipping", blockName))
        return false, "Block has no hardness data"
    end
end

function Mining:worldToGridIndex(pos)
    local function toGridCoord(coord)
        return coord >= 0 and math.floor(coord / self.CELL) or math.ceil(coord / self.CELL - 1)
    end

    return Vector3.new(
        toGridCoord(pos.X - self.ORIGIN.X),
        toGridCoord(pos.Y - self.ORIGIN.Y),
        toGridCoord(pos.Z - self.ORIGIN.Z)
    )
end

function Mining:getOrePackCargo()
    local character = self.Services.player.Character
    if not character then return nil end

    local orePackCargo = character:FindFirstChild("OrePackCargo")
    if orePackCargo then
        return orePackCargo
    end

    local backpack = self.Services.player:FindFirstChild("Backpack")
    if backpack then
        orePackCargo = backpack:FindFirstChild("OrePackCargo")
        if orePackCargo then
            return orePackCargo
        end
    end

    return nil
end

function Mining:calculateMaxCapacity(container)
    if not container then return 0 end

    local size = container.Size
    if not size then return 0 end

    local itemSize = Vector3.new(1.25, 1.25, 1.25)

    local xCapacity = math.floor(size.X / itemSize.X)
    local yCapacity = math.floor(size.Y / itemSize.Y)
    local zCapacity = math.floor(size.Z / itemSize.Z)

    local maxCapacity = xCapacity * yCapacity * zCapacity

    return maxCapacity
end

function Mining:countCurrentItems(container)
    if not container then return 0 end

    local itemCount = 0

    for _, child in ipairs(container:GetChildren()) do
        if child:GetAttribute("BlockId") then
            itemCount = itemCount + 1
        end
    end

    return itemCount
end

function Mining:isOreMineable(oreId)
    local oreData = self.MATERIAL_DATA[oreId] or self.GEM_DATA[oreId]
    if not oreData or not oreData.hardness then
        return true
    end

    local tool = self:GetTool()
    if not tool then
        return false
    end

    local toolStats = self:getPickaxeStats(tool)
    if not toolStats then
        return false
    end

    local adjustedStrength = toolStats.strength

    return oreData.hardness <= adjustedStrength
end

function Mining:getAllTargets()
    local targets = {}
    for oreId, enabled in pairs(self.Config.SelectedOres) do
        if enabled then
            targets[#targets + 1] = oreId
        end
    end
    for gemId, enabled in pairs(self.Config.SelectedGems) do
        if enabled then
            targets[#targets + 1] = gemId
        end
    end

    if #targets == 0 then
        return targets
    end

    -- Sort targets by hardness DESC, then distance ASC
    local selectionKey = self:buildSelectionKey(self.Config.SelectedOres, self.Config.SelectedGems)
    local rootPos = self.State.root and self.State.root.Position or nil
    local now = tick()

    local canReuseCache = (self.State.targetsOrderCache.lastSelectionKey == selectionKey)
        and (now - self.State.targetsOrderCache.lastUpdate) < 0.35

    if canReuseCache and rootPos and self.State.targetsOrderCache.lastRootPos then
        if (rootPos - self.State.targetsOrderCache.lastRootPos).Magnitude < 2 then
            return self.State.targetsOrderCache.list
        end
    elseif canReuseCache and not rootPos then
        return self.State.targetsOrderCache.list
    end

    local minDistanceById = {}
    for _, id in ipairs(targets) do
        minDistanceById[id] = math.huge
    end

    if rootPos then
        for ore, _ in pairs(self.State.cachedOres) do
            if ore and ore.Parent then
                local oreId = self:getCachedOreId(ore)
                if oreId and minDistanceById[oreId] ~= nil then
                    local dist = (ore.Position - rootPos).Magnitude
                    if dist < minDistanceById[oreId] then
                        minDistanceById[oreId] = dist
                    end
                end
            end
        end
    end

    table.sort(targets, function(a, b)
        local ha = self:getTargetHardness(a)
        local hb = self:getTargetHardness(b)
        if ha ~= hb then
            return ha > hb
        end

        local da = minDistanceById[a] or math.huge
        local db = minDistanceById[b] or math.huge
        if da ~= db then
            return da < db
        end

        return tostring(a) < tostring(b)
    end)

    self.State.targetsOrderCache.list = targets
    self.State.targetsOrderCache.lastUpdate = now
    self.State.targetsOrderCache.lastRootPos = rootPos
    self.State.targetsOrderCache.lastSelectionKey = selectionKey

    return targets
end

function Mining:buildSelectionKey(selectedOres, selectedGems)
    local parts = {}
    for id, enabled in pairs(selectedOres) do
        if enabled then
            parts[#parts + 1] = id
        end
    end
    for id, enabled in pairs(selectedGems) do
        if enabled then
            parts[#parts + 1] = id
        end
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

function Mining:getTargetHardness(targetId)
    local data = self.MATERIAL_DATA[targetId] or self.GEM_DATA[targetId]
    return (data and data.hardness) or 0
end

function Mining:startMiningLoop()
    task.spawn(function()
        self.State.mainLoopRunning = true
        self.State.lastCleanup = tick()
        self.State.consecutiveFails = 0

        while self.State.mainLoopRunning and task.wait() do
            -- Periodic cleanup every 10 seconds
            if tick() - self.State.lastCleanup > 10 then
                for ore, _ in pairs(self.State.cachedOres) do
                    if not (ore and ore.Parent) then
                        self.State.cachedOres[ore] = nil
                        if self.Config.ActiveHighlights[ore] then
                            self:releaseHighlight(self.Config.ActiveHighlights[ore])
                            self.Config.ActiveHighlights[ore] = nil
                        end
                        self:removeOreIdCache(ore)
                    end
                end
                self.State.lastCleanup = tick()
            end

            -- Check if backpack is full
            local orePackCargo = self:getOrePackCargo()
            if orePackCargo then
                local currentItems = self:countCurrentItems(orePackCargo)
                local maxCapacity = self:calculateMaxCapacity(orePackCargo)
                if currentItems >= maxCapacity then
                    continue
                end
            end

            -- Skip mining if left click is being held
            if self.State.isLeftClickHeld then
                continue
            end

            if self.Config.AutoMining then
                local tool = self:GetTool()
                if tool and self.State.character and self.State.root then
                    local toolStats = self:getPickaxeStats(tool)

                    if toolStats then
                        local selectedTargets = self:getAllTargets()
                        if #selectedTargets > 0 then
                            local selectedSet = {}
                            for _, targetId in ipairs(selectedTargets) do
                                selectedSet[targetId] = true
                            end

                            local adjustedStrength = toolStats.strength
                            local adjustedSpeed = toolStats.speed

                            -- Find the best ore
                            local bestOre = nil
                            local bestPriority = -1
                            local bestValue = -1
                            local bestDistance = self.Config.MineRange + 1

                            for ore, _ in pairs(self.State.cachedOres) do
                                if ore and ore.Parent then
                                    local oreId = self:getCachedOreId(ore)
                                    if oreId and selectedSet[oreId] then
                                        local distance = (ore.Position - self.State.root.Position).Magnitude
                                        if distance <= self.Config.MineRange then
                                            local oreData = self.MATERIAL_DATA[oreId] or self.GEM_DATA[oreId]
                                            if oreData then
                                                local miningTime = self.Services.MiningTimeFunction(adjustedSpeed, adjustedStrength, oreData.hardness)
                                                if miningTime >= 9999999 then
                                                    continue
                                                end

                                                local value = oreData.value
                                                local isGem = self.GEM_DATA[oreId] ~= nil
                                                local priority = isGem and 1 or 0

                                                local isBetter = false
                                                if priority > bestPriority then
                                                    isBetter = true
                                                elseif priority == bestPriority then
                                                    if value > bestValue then
                                                        isBetter = true
                                                    elseif value == bestValue and distance < bestDistance then
                                                        isBetter = true
                                                    end
                                                end

                                                if isBetter then
                                                    bestOre = ore
                                                    bestPriority = priority
                                                    bestValue = value
                                                    bestDistance = distance
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            -- Mine the best ore if found
                            if bestOre then
                                local grid = self:worldToGridIndex(bestOre:GetPivot())
                                local gridPos = Vector3int16.new(grid.X, grid.Y, grid.Z)

                                local success, result = self:mineTarget(gridPos)

                                if success then
                                    self.State.consecutiveFails = 0
                                    task.wait(result)

                                    local tool = self:GetTool()
                                    if tool then
                                        local pickaxeClient = self:getPickaxeClientFromToolModel(tool)
                                        if pickaxeClient and pickaxeClient.SwingAnimTrack then
                                            pickaxeClient.SwingAnimTrack:Stop()
                                        end
                                    end
                                else
                                    self.State.consecutiveFails = self.State.consecutiveFails + 1
                                    warn(result .. string.format(" (consecutive fails: %d)", self.State.consecutiveFails))
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

function Mining:startTimerLoop()
    task.spawn(function()
        while self.State.mainLoopRunning and task.wait(0.1) do
            local orePackCargo = self:getOrePackCargo()
            if orePackCargo then
                local currentItems = self:countCurrentItems(orePackCargo)
                local maxCapacity = self:calculateMaxCapacity(orePackCargo)
                local timerText = self.State.cachedTimerLabel and self.State.cachedTimerLabel.Text or "--:--"
                local boostText = self.Config.boostEnabled and string.format("B:%d", self.Config.BoostSpeed) or "B:OFF"
                -- Fix: Check if cargoLabel exists before trying to use it
                if self.State.cargoLabel then
                    self.State.cargoLabel.Text = string.format("%d/%d : %s : %s", currentItems, maxCapacity, timerText, boostText)
                    if currentItems >= maxCapacity then
                        self.State.cargoLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                    elseif currentItems >= maxCapacity * 0.8 then
                        self.State.cargoLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                    else
                        self.State.cargoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    end
                else
                    print("Mining: cargoLabel is nil - cargo UI was not created properly")
                end
            end
        end
    end)
end

-- ESP functions (will be moved to ESP module but needed here for now)
function Mining:getHighlight(ore)
    local highlight = table.remove(self.Config.ActiveHighlights or {})
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "OreESP"
    end
    highlight.Adornee = ore
    highlight.Parent = ore
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    return highlight
end

function Mining:releaseHighlight(highlight)
    if highlight and highlight.Parent then
        highlight.Adornee = nil
        highlight.Parent = nil
        table.insert(self.Config.ActiveHighlights or {}, highlight)
    end
end

return Mining
