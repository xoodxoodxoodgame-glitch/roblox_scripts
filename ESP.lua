-- ESP Module - Handles ore ESP and player ESP
local ESP = {}

function ESP.init(State, Config, Services)
    ESP.State = State
    ESP.Config = Config
    ESP.Services = Services or {}
    
    -- Load material and gem data (copied from Mining module)
    ESP:loadMaterialData()
    
    -- ESP Object Pools for performance optimization
    ESP.ESPPools = {
        highlights = {},
        billboards = {}
    }
    
    -- Setup ESP connections
    ESP:setupESP()
    
    return ESP
end

function ESP:loadMaterialData()
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

    for oreId, oreData in pairs(ESP.Services.BlockDefinitions) do
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

    ESP.MATERIAL_DATA = materials
    ESP.GEM_DATA = gems
end

function ESP:setupESP()
    -- Setup Player ESP connections
    ESP:setupPlayerESP()
    
    -- Start ESP update loop
    ESP:startESPUpdateLoop()
end

-- Ore ESP Functions
function ESP:positionToBucket(pos)
    return Vector3.new(
        math.floor(pos.X / 10),
        math.floor(pos.Y / 10),
        math.floor(pos.Z / 10)
    )
end

function ESP:getNearbyBuckets(centerBucket, radiusBuckets)
    local buckets = {}
    for x = centerBucket.X - radiusBuckets, centerBucket.X + radiusBuckets do
        for y = centerBucket.Y - radiusBuckets, centerBucket.Y + radiusBuckets do
            for z = centerBucket.Z - radiusBuckets, centerBucket.Z + radiusBuckets do
                table.insert(buckets, Vector3.new(x, y, z))
            end
        end
    end
    return buckets
end

function ESP:createSpatialBuckets(validOres)
    local buckets = {}

    for ore, _ in pairs(validOres) do
        if ore and ore.Parent then
            local oreId = ESP:getCachedOreId(ore)
            if oreId then
                local bucket = ESP:positionToBucket(ore.Position)
                local bucketKey = string.format("%d,%d,%d", bucket.X, bucket.Y, bucket.Z)

                if not buckets[bucketKey] then
                    buckets[bucketKey] = {}
                end
                if not buckets[bucketKey][oreId] then
                    buckets[bucketKey][oreId] = {}
                end
                table.insert(buckets[bucketKey][oreId], ore)
            end
        end
    end

    return buckets
end

function ESP:groupOresByProximity(validOres)
    local groups = {}
    local processed = {}
    local buckets = ESP:createSpatialBuckets(validOres)

    for ore, _ in pairs(validOres) do
        if not processed[ore] and ore.Parent then
            local oreId = ESP:getCachedOreId(ore)
            if oreId then
                local group = {ores = {ore}, center = ore.Position, oreId = oreId}
                processed[ore] = true

                local centerBucket = ESP:positionToBucket(ore.Position)
                local nearbyBuckets = ESP:getNearbyBuckets(centerBucket, 2)

                for _, bucketCoord in ipairs(nearbyBuckets) do
                    local bucketKey = string.format("%d,%d,%d", bucketCoord.X, bucketCoord.Y, bucketCoord.Z)
                    local bucket = buckets[bucketKey]
                    if bucket and bucket[oreId] then
                        for _, otherOre in ipairs(bucket[oreId]) do
                            if not processed[otherOre] and otherOre.Parent and otherOre ~= ore then
                                local distance = (ore.Position - otherOre.Position).Magnitude
                                if distance <= 20 then
                                    table.insert(group.ores, otherOre)
                                    processed[otherOre] = true
                                end
                            end
                        end
                    end
                end

                if #group.ores > 1 then
                    local totalPos = Vector3.new(0, 0, 0)
                    for _, gOre in ipairs(group.ores) do
                        totalPos = totalPos + gOre.Position
                    end
                    group.center = totalPos / #group.ores
                end

                if not groups[oreId] then
                    groups[oreId] = {}
                end
                table.insert(groups[oreId], group)
            end
        end
    end

    return groups
end

function ESP:getCachedOreId(ore)
    return ESP.State.cachedOreIds[ore]
end

function ESP:isOreMineable(oreId)
    -- This should use Mining module's function when available
    return true -- Placeholder
end

function ESP:getHighlight(ore)
    local highlight = table.remove(ESP.ESPPools.highlights)
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

function ESP:releaseHighlight(highlight)
    if highlight and highlight.Parent then
        highlight.Adornee = nil
        highlight.Parent = nil
        table.insert(ESP.ESPPools.highlights, highlight)
    end
end

function ESP:getBillboardAttachment()
    local attachment = table.remove(ESP.ESPPools.billboards)
    if not attachment then
        attachment = Instance.new("Attachment")
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "OreESP_Name"
        billboard.Parent = attachment
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true

        local textLabel = Instance.new("TextLabel")
        textLabel.Parent = billboard
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextSize = 16
        textLabel.TextTransparency = 0
        textLabel.TextStrokeTransparency = 0
    end
    attachment.Parent = workspace
    return attachment
end

function ESP:releaseBillboardAttachment(attachment)
    if attachment and attachment.Parent then
        attachment.Position = Vector3.new(0, 0, 0)
        attachment.Parent = nil
        table.insert(ESP.ESPPools.billboards, attachment)
    end
end

function ESP:createESPHighlight(ore)
    local highlight = ESP.Config.ActiveHighlights[ore]
    if not highlight then
        highlight = ESP:getHighlight(ore)
        ESP.Config.ActiveHighlights[ore] = highlight
    end

    local oreId = ESP:getCachedOreId(ore)
    -- This should use Mining module's data when available
    local oreData = {} -- Placeholder
    local oreColor = oreData and oreData.color or Color3.fromRGB(255, 255, 255)

    local isMineable = ESP:isOreMineable(oreId)
    local targetColor = isMineable and oreColor or Color3.fromRGB(255, 0, 0)

    if highlight.FillColor ~= targetColor then
        highlight.FillColor = targetColor
        highlight.OutlineColor = targetColor
    end

    return highlight
end

function ESP:createESPBillboard(groupKey, groupData)
    local attachment = ESP.Config.ESPGroups[groupKey]
    if not attachment then
        attachment = ESP:getBillboardAttachment()
        attachment.Name = "OreESP_Group_" .. groupKey
        ESP.Config.ESPGroups[groupKey] = attachment
    end

    if attachment.Position ~= groupData.center then
        attachment.Position = groupData.center
    end

    local billboard = attachment:FindFirstChild("OreESP_Name")
    if billboard then
        local textLabel = billboard:FindFirstChildOfClass("TextLabel")
        if textLabel then
            local distance = ESP.State.root and (groupData.center - ESP.State.root.Position).Magnitude or 0
            -- This should use Mining module's data when available
            local oreName = "Unknown" -- Placeholder

            local isMineable = ESP:isOreMineable(groupData.oreId)
            local targetColor = isMineable and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 0, 0)

            if textLabel.TextColor3 ~= targetColor then
                textLabel.TextColor3 = targetColor
            end

            local newText = string.format("%s x%d (%.1f)", oreName, #groupData.ores, distance)

            if textLabel.Text ~= newText then
                textLabel.Text = newText
            end
        end
    end

    return attachment
end

function ESP:updateESP()
    if not ESP.Config.ESPEnabled then
        ESP:cleanupESP()
        return
    end
    if not ESP.State.root then return end

    -- Collect valid ores
    local validOres = {}
    for ore, _ in pairs(ESP.State.cachedOres) do
        if ore and ore.Parent then
            local distance = (ore.Position - ESP.State.root.Position).Magnitude
            local oreId = ESP:getCachedOreId(ore)

            if (distance <= ESP.Config.ESPRange or oreId == "Unobtainium") and (ESP.Config.SelectedOres[oreId] or ESP.Config.SelectedGems[oreId]) then
                validOres[ore] = true
            end
        end
    end

    -- Remove highlights for ores that are no longer valid
    for ore, highlight in pairs(ESP.Config.ActiveHighlights) do
        if not validOres[ore] then
            ESP:releaseHighlight(highlight)
            ESP.Config.ActiveHighlights[ore] = nil
        end
    end

    -- Create or update highlights for valid ores
    for ore, _ in pairs(validOres) do
        ESP:createESPHighlight(ore)
    end

    -- Group ores and create/update billboards
    local groups = ESP:groupOresByProximity(validOres)
    local currentGroups = {}

    for oreId, oreGroups in pairs(groups) do
        for groupIndex, groupData in ipairs(oreGroups) do
            local groupKey = oreId .. "_" .. groupIndex
            currentGroups[groupKey] = true
            ESP:createESPBillboard(groupKey, groupData)
        end
    end

    -- Remove billboards for groups that no longer exist
    for groupKey, attachment in pairs(ESP.Config.ESPGroups) do
        if not currentGroups[groupKey] then
            ESP:releaseBillboardAttachment(attachment)
            ESP.Config.ESPGroups[groupKey] = nil
        end
    end
end

function ESP:cleanupESP()
    for ore, highlight in pairs(ESP.Config.ActiveHighlights) do
        ESP:releaseHighlight(highlight)
    end
    ESP.Config.ActiveHighlights = {}

    for groupKey, attachment in pairs(ESP.Config.ESPGroups) do
        ESP:releaseBillboardAttachment(attachment)
    end
    ESP.Config.ESPGroups = {}
end

-- Player ESP Functions
function ESP:setupPlayerESP()
    ESP.State.connections.playerESP_PlayerAdded = ESP.Services.Players.PlayerAdded:Connect(function(Player)
        if ESP.State.PlayerESPEnabled then
            ESP:ensureRespawnHook(Player)
            ESP:addPlayer(Player)
        end
    end)

    ESP.State.connections.playerESP_PlayerRemoving = ESP.Services.Players.PlayerRemoving:Connect(function(Player)
        ESP:removePlayer(Player)
        ESP:disconnectRespawnHook(Player)
    end)

    ESP.State.connections.playerESP_RenderStepped = ESP.Services.RunService.RenderStepped:Connect(function()
        if not ESP.State.PlayerESPEnabled then return end
        ESP.State.PlayerESPFrameCounter = ESP.State.PlayerESPFrameCounter + 1
        if ESP.State.PlayerESPFrameCounter % 2 == 0 then
            ESP:updateRealtime()
        end
    end)
end

function ESP:isWithinRange(Distance)
    if ESP.State.PlayerESPMaxDistance <= 0 then return true end
    if Distance == nil then return true end
    return Distance <= ESP.State.PlayerESPMaxDistance
end

function ESP:getDistanceToCharacter(LocalPosition, Character)
    if not LocalPosition then return nil end
    if not Character then return nil end
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return nil end
    return (LocalPosition - RootPart.Position).Magnitude
end

function ESP:getDisplayName(Player)
    local Name = (Player and Player.DisplayName) or ""
    return string.sub(Name, 1, 6)
end

function ESP:canUseDrawing()
    return Drawing and Drawing.new ~= nil
end

function ESP:getTracerTargetPosition(Character)
    if not Character then return nil end
    local Head = Character:FindFirstChild("Head")
    if Head and Head.Position then
        return Head.Position
    end
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    return RootPart and RootPart.Position or nil
end

function ESP:removeTracer(Player)
    local Tracer = ESP.State.PlayerESPTracers[Player]
    if Tracer then
        pcall(function()
            Tracer.Visible = false
            Tracer:Remove()
        end)
        ESP.State.PlayerESPTracers[Player] = nil
    end
end

function ESP:clearTracers()
    for Player, _ in pairs(ESP.State.PlayerESPTracers) do
        ESP:removeTracer(Player)
    end
    ESP.State.PlayerESPTracers = {}
end

function ESP:ensureTracer(Player)
    if ESP.State.PlayerESPTracers[Player] then
        local isFriend = ESP.State.friendshipCache[Player.UserId]
        if isFriend == nil then
            isFriend = ESP.Services.player:IsFriendsWith(Player.UserId)
            ESP.State.friendshipCache[Player.UserId] = isFriend
        end
        ESP.State.PlayerESPTracers[Player].Color = isFriend and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
        return ESP.State.PlayerESPTracers[Player]
    end
    if not ESP:canUseDrawing() then return nil end
    local Line = Drawing.new("Line")
    Line.Visible = false
    local isFriend = ESP.State.friendshipCache[Player.UserId]
    if isFriend == nil then
        isFriend = ESP.Services.player:IsFriendsWith(Player.UserId)
        ESP.State.friendshipCache[Player.UserId] = isFriend
    end
    Line.Color = isFriend and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
    Line.Thickness = 1
    Line.Transparency = 1
    ESP.State.PlayerESPTracers[Player] = Line
    return Line
end

function ESP:updateTracer(Player, Character)
    if not ESP.State.PlayerESPTracersEnabled then
        ESP:removeTracer(Player)
        return
    end
    if not ESP:canUseDrawing() then return end

    local Camera = ESP.Services.Workspace.CurrentCamera
    if not Camera then return end

    local TargetPos = ESP:getTracerTargetPosition(Character)
    if not TargetPos then
        ESP:removeTracer(Player)
        return
    end

    local ScreenPoint, OnScreen = Camera:WorldToViewportPoint(TargetPos)
    local Line = ESP:ensureTracer(Player)
    if not Line then return end

    local Viewport = Camera.ViewportSize
    local From = Vector2.new(Viewport.X / 2, 0)

    if OnScreen and ScreenPoint.Z > 0 then
        Line.From = From
        Line.To = Vector2.new(ScreenPoint.X, ScreenPoint.Y)
        Line.Visible = true
        return
    end

    if not ESP.State.PlayerESPTracersShowOffscreen then
        Line.Visible = false
        return
    end

    local ToX, ToY = ScreenPoint.X, ScreenPoint.Y
    local CenterX, CenterY = Viewport.X / 2, Viewport.Y / 2
    if ScreenPoint.Z <= 0 then
        ToX = CenterX + (CenterX - ToX)
        ToY = CenterY + (CenterY - ToY)
    end

    local Margin = 8
    ToX = math.clamp(ToX, Margin, Viewport.X - Margin)
    ToY = math.clamp(ToY, Margin, Viewport.Y - Margin)

    Line.From = From
    Line.To = Vector2.new(ToX, ToY)
    Line.Visible = true
end

function ESP:setBillboardText(Player, Distance)
    local Billboard = ESP.State.PlayerESPBillboards[Player]
    if not Billboard then return end
    local TextLabel = Billboard:FindFirstChildOfClass("TextLabel")
    if not TextLabel then return end

    if Distance then
        local nearDistance = 700
        local farDistance = 1000
        local minScale = 0.15
        local maxScale = 1.0

        local scale
        if Distance <= nearDistance then
            scale = maxScale
        elseif Distance >= farDistance then
            scale = minScale
        else
            local t = (Distance - nearDistance) / (farDistance - nearDistance)
            scale = maxScale - (t * (maxScale - minScale))
        end

        local opacity = math.max(0.3, math.min(1.0, 1000 / (Distance + 100)))

        Billboard.Size = UDim2.new(0, 200 * scale, 0, 50 * scale)
        TextLabel.TextTransparency = 1 - opacity
        TextLabel.TextStrokeTransparency = 1 - opacity
    else
        Billboard.Size = UDim2.new(0, 200, 0, 50)
        TextLabel.TextTransparency = 0
        TextLabel.TextStrokeTransparency = 0
    end

    local isFriend = ESP.State.friendshipCache[Player.UserId]
    if isFriend == nil then
        isFriend = ESP.Services.player:IsFriendsWith(Player.UserId)
        ESP.State.friendshipCache[Player.UserId] = isFriend
    end
    TextLabel.TextColor3 = isFriend and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)

    local NamePart = ESP.State.PlayerESPShowName and ESP:getDisplayName(Player) or nil
    local DistancePart = nil
    if ESP.State.PlayerESPShowDistance then
        DistancePart = Distance and string.format("%.1f", Distance) or "?"
    end

    if NamePart and DistancePart then
        TextLabel.Text = NamePart .. " | " .. DistancePart
    elseif NamePart then
        TextLabel.Text = NamePart
    elseif DistancePart then
        TextLabel.Text = DistancePart
    else
        TextLabel.Text = ""
    end
end

function ESP:removePlayer(Player)
    if ESP.State.PlayerESPHighlights[Player] then
        ESP.State.PlayerESPHighlights[Player]:Destroy()
        ESP.State.PlayerESPHighlights[Player] = nil
    end
    if ESP.State.PlayerESPBillboards[Player] then
        ESP.State.PlayerESPBillboards[Player]:Destroy()
        ESP.State.PlayerESPBillboards[Player] = nil
    end
    ESP:removeTracer(Player)
    ESP.State.friendshipCache[Player.UserId] = nil
end

function ESP:addPlayer(Player)
    local LocalPlayer = ESP.Services.Players.LocalPlayer
    if Player == LocalPlayer then return end

    if ESP.State.PlayerESPHighlights[Player] then
        ESP.State.PlayerESPHighlights[Player]:Destroy()
        ESP.State.PlayerESPHighlights[Player] = nil
    end
    if ESP.State.PlayerESPBillboards[Player] then
        ESP.State.PlayerESPBillboards[Player]:Destroy()
        ESP.State.PlayerESPBillboards[Player] = nil
    end

    local Character = Player.Character
    if not Character then return end
    if not Character:FindFirstChild("HumanoidRootPart") then return end

    local Highlight = Instance.new("Highlight")
    Highlight.Name = "PlayerESP"

    local isFriend = ESP.State.friendshipCache[Player.UserId]
    if isFriend == nil then
        isFriend = ESP.Services.player:IsFriendsWith(Player.UserId)
        ESP.State.friendshipCache[Player.UserId] = isFriend
    end
    if isFriend then
        Highlight.FillColor = Color3.fromRGB(0, 255, 0)
        Highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    else
        Highlight.FillColor = Color3.fromRGB(255, 0, 0)
        Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
    Highlight.FillTransparency = 0.5
    Highlight.OutlineTransparency = 0
    Highlight.Parent = Character
    ESP.State.PlayerESPHighlights[Player] = Highlight

    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "PlayerESP_Billboard"
    Billboard.Size = UDim2.new(0, 200, 0, 50)
    Billboard.StudsOffset = Vector3.new(0, -20, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = Character:FindFirstChild("Head") or Character:FindFirstChild("HumanoidRootPart") or Character

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.TextStrokeTransparency = 0
    TextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.Font = Enum.Font.SourceSansBold
    TextLabel.TextSize = 16
    TextLabel.Parent = Billboard

    ESP.State.PlayerESPBillboards[Player] = Billboard

    local LocalPlayer = ESP.Services.Players.LocalPlayer
    local LocalRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local LocalPosition = LocalRootPart and LocalRootPart.Position
    local Distance = ESP:getDistanceToCharacter(LocalPosition, Character)
    ESP:setBillboardText(Player, Distance)
end

function ESP:ensureRespawnHook(Player)
    local LocalPlayer = ESP.Services.Players.LocalPlayer
    if Player == LocalPlayer then return end
    if ESP.State.PlayerESPRespawnConnections[Player] then return end

    ESP.State.PlayerESPRespawnConnections[Player] = Player.CharacterAdded:Connect(function()
        if not ESP.State.PlayerESPEnabled then return end
        task.wait(0.1)
        ESP:addPlayer(Player)
    end)
end

function ESP:disconnectRespawnHook(Player)
    if ESP.State.PlayerESPRespawnConnections[Player] then
        ESP.State.PlayerESPRespawnConnections[Player]:Disconnect()
        ESP.State.PlayerESPRespawnConnections[Player] = nil
    end
end

function ESP:disablePlayerESP()
    ESP.State.PlayerESPEnabled = false

    for Player, Highlight in pairs(ESP.State.PlayerESPHighlights) do
        if Highlight then
            Highlight:Destroy()
        end
        ESP.State.PlayerESPHighlights[Player] = nil
    end

    for Player, Billboard in pairs(ESP.State.PlayerESPBillboards) do
        if Billboard then
            Billboard:Destroy()
        end
        ESP.State.PlayerESPBillboards[Player] = nil
    end

    for Player, Conn in pairs(ESP.State.PlayerESPRespawnConnections) do
        if Conn then
            Conn:Disconnect()
        end
        ESP.State.PlayerESPRespawnConnections[Player] = nil
    end

    ESP:clearTracers()
end

function ESP:enablePlayerESP()
    ESP.State.PlayerESPEnabled = true
    for _, Player in ipairs(ESP.Services.Players:GetPlayers()) do
        ESP:ensureRespawnHook(Player)
    end
    ESP:updateRealtime()
end

function ESP:updateRealtime()
    if not ESP.State.PlayerESPEnabled then return end

    local LocalPlayer = ESP.Services.Players.LocalPlayer
    local LocalCharacter = LocalPlayer.Character
    local LocalRootPart = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")
    local LocalPosition = LocalRootPart and LocalRootPart.Position

    for _, Player in ipairs(ESP.Services.Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            ESP:ensureRespawnHook(Player)

            local Character = Player.Character
            local HasCharacter = Character and Character:FindFirstChild("HumanoidRootPart")
            local Distance = HasCharacter and ESP:getDistanceToCharacter(LocalPosition, Character) or nil

            if HasCharacter and not ESP:isWithinRange(Distance) then
                if ESP.State.PlayerESPHighlights[Player] or ESP.State.PlayerESPBillboards[Player] then
                    ESP:removePlayer(Player)
                end
                ESP:removeTracer(Player)
                continue
            end

            local HasHighlight = ESP.State.PlayerESPHighlights[Player] and ESP.State.PlayerESPHighlights[Player].Parent
            local HasBillboard = ESP.State.PlayerESPBillboards[Player] and ESP.State.PlayerESPBillboards[Player].Parent

            if HasCharacter and (not HasHighlight or not HasBillboard) then
                ESP:removePlayer(Player)
                ESP:addPlayer(Player)
            elseif not HasCharacter and (HasHighlight or HasBillboard) then
                ESP:removePlayer(Player)
            end

            if ESP.State.PlayerESPBillboards[Player] then
                ESP:setBillboardText(Player, Distance)
            end

            if HasCharacter then
                ESP:updateTracer(Player, Character)
            else
                ESP:removeTracer(Player)
            end
        end
    end
end

function ESP:startESPUpdateLoop()
    task.spawn(function()
        while ESP.State.mainLoopRunning and task.wait(0.1) do
            ESP:updateESP()
        end
    end)
end

return ESP
