-- Movement Module - Handles boost, toggle movement, and gravity
local Movement = {}

function Movement.init(State, Config, Services)
    Movement.State = State or {}
    Movement.Config = Config or {}
    Movement.Services = Services or {}
    
    -- Initialize mouse lock state
    Movement.State.mouseLocked = false
    
    local player = Movement.Services.player
    local UserInputService = Movement.Services.UserInputService
    
    -- Setup movement controls
    Movement:setupMovement()
    
    -- Setup humanoid state
    Movement:setupHumanoidState()
    
    return Movement
end

function Movement:setupHumanoidState()
    if Movement.State.humanoid then
        Movement.State.humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        Movement.State.humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        Movement.State.humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
    end
end

function Movement:setupMovement()
    local keys = {
        W = Enum.KeyCode.W,
        A = Enum.KeyCode.A,
        S = Enum.KeyCode.S,
        D = Enum.KeyCode.D
    }

    -- Mouse button detection
    Movement.State.connections.mouseButton1Down = Movement.Services.UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Movement.State.isLeftClickHeld = true
        end
    end)

    Movement.State.connections.mouseButton1Up = Movement.Services.UserInputService.InputEnded:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Movement.State.isLeftClickHeld = false
        end
    end)

    -- Input handling for boost and toggle movement
    Movement.State.connections.inputBegan = Movement.Services.UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end

        if input.KeyCode == Enum.KeyCode.C then
            if Movement.Config and Movement.Config.boostEnabled ~= nil then
            Movement.Config.boostEnabled = not Movement.Config.boostEnabled
            Movement:updateGravity()
        end
        elseif input.KeyCode == Enum.KeyCode.LeftAlt then
            -- Toggle between current setting and 500 (max)
            if Movement.Config.BoostSpeed ~= 500 then
                Movement.State.savedBoostSpeed = Movement.Config.BoostSpeed
                Movement:setBoostSpeed(500)
            else
                Movement:setBoostSpeed(Movement.State.savedBoostSpeed)
            end
        elseif input.KeyCode == Enum.KeyCode.H then
            -- Toggle movement and mouse lock
            if Movement.State.isAutoTunnel then
                Movement.State.isAutoTunnel = false
                Movement.State.autoTunnelLookDirection = nil
                Movement:stopToggleMovement()
                
                -- Unlock mouse when auto-tunnel disabled
                Movement.State.mouseLocked = false
                Movement.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                Movement.Services.UserInputService.MouseIconEnabled = true
                        
                -- Call ActivateEnded when auto-tunnel stops
                local tool = Movement.Mining:GetTool()
                if tool then
                    local pickaxeClient = Movement.Mining:getPickaxeClientFromToolModel(tool)
                    if pickaxeClient then
                        pickaxeClient:ActivateEnded()
                    else
                                            end
                else
                                    end
            else
                Movement.State.isAutoTunnel = true
                
                -- Lock mouse when auto-tunnel enabled
                Movement.State.mouseLocked = true
                Movement.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
                Movement.Services.UserInputService.MouseIconEnabled = false
                
                -- Trigger mining activation once when auto-tunnel starts
                local tool = Movement.Mining:GetTool()
                if tool then
                    local pickaxeClient = Movement.Mining:getPickaxeClientFromToolModel(tool)
                    if pickaxeClient then
                        pickaxeClient:ActivateStarted()
                    else
                                            end
                else
                                    end
            end
        end

        for _, key in pairs(keys) do
            if input.KeyCode == key then
                Movement.Config.moving = true
            end
        end
    end)

    Movement.State.connections.inputEnded = Movement.Services.UserInputService.InputEnded:Connect(function(input, gp)
        if gp then return end

        for _, key in pairs(keys) do
            if input.KeyCode == key then
                Movement.Config.moving =
                    Movement.Services.UserInputService:IsKeyDown(keys.W) or
                    Movement.Services.UserInputService:IsKeyDown(keys.A) or
                    Movement.Services.UserInputService:IsKeyDown(keys.S) or
                    Movement.Services.UserInputService:IsKeyDown(keys.D)

                if not Movement.Config.moving then
                    local currentVelocity = Movement.State.root.AssemblyLinearVelocity
                    Movement.State.root.AssemblyLinearVelocity = Vector3.new(0, currentVelocity.Y, 0)
                end
            end
        end
    end)

    -- Render stepped for boost and toggle movement
    Movement.State.connections.renderStepped = Movement.Services.RunService.RenderStepped:Connect(function()
        if Movement.Config and Movement.Config.boostEnabled and Movement.Config.moving then
            local dir = Movement.State.humanoid.MoveDirection
            if dir.Magnitude > 0 then
                local currentVelocity = Movement.State.root.AssemblyLinearVelocity
                local horizontalVelocity = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)

                local base = dir * Movement.State.humanoid.WalkSpeed
                local extra = dir * (Movement.Config.BoostSpeed - Movement.State.humanoid.WalkSpeed)

                local newHorizontalVelocity = base + extra

                Movement.State.root.AssemblyLinearVelocity = Vector3.new(
                    newHorizontalVelocity.X,
                    currentVelocity.Y,
                    newHorizontalVelocity.Z
                )
            end
        end
        
        -- Toggle movement loop
        Movement:toggleMovementLoop()

        -- Maintain look direction during active auto-tunneling movement
        if Movement.State.isAutoTunnel and Movement.State.autoTunnelLookDirection and Movement.State.root and Movement.Config.moving then
            local lookCFrame = CFrame.new(Movement.State.root.Position, Movement.State.root.Position + Movement.State.autoTunnelLookDirection)
            Movement.State.root.CFrame = lookCFrame
        end
    end)

    -- Character respawn handler
    Movement.State.connections.characterAdded = Movement.Services.player.CharacterAdded:Connect(function(newChar)
        Movement.State.character = newChar
        Movement.State.humanoid = newChar:WaitForChild("Humanoid")
        Movement.State.root = newChar:WaitForChild("HumanoidRootPart")

        -- Reapply humanoid state settings after respawn
        Movement.State.humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        Movement.State.humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        Movement.State.humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)

        -- Reset toggle movement state on respawn
        if Movement.State.isAutoTunnel then
            Movement.State.isAutoTunnel = false
            Movement.State.autoTunnelLookDirection = nil
            Movement:stopToggleMovement()
        end

        -- Find and disable collision for Hitbox
        local hitbox = newChar:FindFirstChild("Hitbox")
        if hitbox then
            hitbox.CanCollide = false
        end
    end)
end

function Movement:updateGravity()
    if Movement.Config and Movement.Config.boostEnabled then
        Movement.Services.Workspace.Gravity = math.max(64, Movement.Config.BoostSpeed * 2)
    else
        Movement.Services.Workspace.Gravity = 64
    end
end

function Movement:setBoostSpeed(speed)
    Movement.Config.BoostSpeed = speed
    Movement:updateGravity()
end

function Movement:getCurrentCharacter()
    return Movement.Services.player.Character
end

function Movement:getCurrentHumanoid()
    local character = Movement:getCurrentCharacter()
    return character and character:FindFirstChild("Humanoid")
end

function Movement:getCurrentRootPart()
    local character = Movement:getCurrentCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

function Movement:stopToggleMovement()
    local rootPart = Movement:getCurrentRootPart()
    if rootPart then
        local currentVelocity = rootPart.AssemblyLinearVelocity
        rootPart.AssemblyLinearVelocity = Vector3.new(0, currentVelocity.Y, 0)
    end
end

function Movement:checkWallDistance()
    local rootPart = Movement:getCurrentRootPart()
    local character = Movement:getCurrentCharacter()

    if not rootPart or not character then
        return math.huge
    end

    local forwardDirection = rootPart.CFrame.LookVector
    local horizontalDir = Vector3.new(forwardDirection.X, 0, forwardDirection.Z)

    if horizontalDir.Magnitude < 1e-6 then
        return math.huge
    end

    local flatForward = horizontalDir.Unit
    local rayOrigin = rootPart.Position
    local rayDirection = flatForward * 5

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = Movement.Services.Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if raycastResult then
        return (raycastResult.Position - rootPart.Position).Magnitude
    else
        return math.huge
    end
end

function Movement:toggleMovementLoop()
    
    if not Movement.State.isAutoTunnel then
        return
    end

    local distance = Movement:checkWallDistance()

    if distance <= 5 then
            Movement:stopToggleMovement()
        return
    end

    local humanoid = Movement:getCurrentHumanoid()
    local rootPart = Movement:getCurrentRootPart()

    if not (humanoid and rootPart) then
            return
    end

    local camera = Movement.Services.Workspace.CurrentCamera
    if not camera then
            return
    end

    local forwardDirection = camera.CFrame.LookVector
    local horizontalDir = Vector3.new(forwardDirection.X, 0, forwardDirection.Z)

    if horizontalDir.Magnitude < 1e-6 then
            return
    end

    local flatForward = horizontalDir.Unit
    local currentVelocity = rootPart.AssemblyLinearVelocity
    local moveSpeed = Movement.Config.BoostSpeed
    local moveVelocity = flatForward * moveSpeed

    rootPart.AssemblyLinearVelocity = Vector3.new(moveVelocity.X, currentVelocity.Y, moveVelocity.Z)

end

function Movement:cleanup()
    print("Movement: Cleaning up...")
    
    -- Stop auto-tunnel
    Movement.State.isAutoTunnel = false
    Movement.State.autoTunnelLookDirection = nil
    Movement:stopToggleMovement()
    
    -- Disable boost
    if Movement.Config then
        Movement.Config.boostEnabled = false
        Movement.Config.moving = false
    end
    
    -- Reset gravity
    if Movement.Services.Workspace then
        Movement.Services.Workspace.Gravity = 64
    end
    
    -- Unlock mouse
    Movement.State.mouseLocked = false
    if Movement.Services.UserInputService then
        Movement.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Movement.Services.UserInputService.MouseIconEnabled = true
    end
    
    -- Reset left click state
    Movement.State.isLeftClickHeld = false
    
    print("Movement: Cleanup complete")
end

return Movement
