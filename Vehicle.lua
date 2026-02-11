-- Vehicle Module - Handles vehicle teleport functionality
local Vehicle = {}

function Vehicle.init(State, Config, Services)
    Vehicle.State = State
    Vehicle.Config = Config
    Vehicle.Services = Services or {}
    
    -- Setup vehicle teleport keybind
    Vehicle:setupVehicleTeleport()
    
    return Vehicle
end

function Vehicle:setupVehicleTeleport()
    Vehicle.State.connections.inputBegan = Vehicle.Services.UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        
        if input.KeyCode == Enum.KeyCode.V then
            local currentTime = tick()
            if currentTime - Vehicle.State.lastVPress > 0.5 then
                Vehicle.State.lastVPress = currentTime
                -- This should use UI module's Fluent notification when available
                if Vehicle.UI and Vehicle.UI.Fluent then
                    Vehicle.UI.Fluent:Notify({
                        Title = "Vehicle Teleport",
                        Content = "Press V again to teleport vehicle",
                        Duration = 1
                    })
                end
                return
            end
            Vehicle.State.lastVPress = 0

            local vehicle = Vehicle:findLocalPlayerVehicle()
            if vehicle then
                Vehicle:teleportVehicleToPlayer(vehicle)
                if Vehicle.UI and Vehicle.UI.Fluent then
                    Vehicle.UI.Fluent:Notify({
                        Title = "Vehicle Teleported",
                        Content = "Your vehicle has been teleported to your position.",
                        Duration = 2
                    })
                end
            else
                if Vehicle.UI and Vehicle.UI.Fluent then
                    Vehicle.UI.Fluent:Notify({
                        Title = "No Vehicle Found",
                        Content = "You don't have a vehicle spawned.",
                        Duration = 2
                    })
                end
            end
        end
    end)
end

function Vehicle:getRootPart()
    local character = Vehicle.Services.player.Character or Vehicle.Services.player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    return root
end

function Vehicle:isOwnedByLocalPlayer(vehicle)
    local ownerId = vehicle:GetAttribute("OwnerId")
    if ownerId == nil then return false end
    if typeof(ownerId) == "string" then
        ownerId = tonumber(ownerId)
    end
    return ownerId == Vehicle.Services.player.UserId
end

function Vehicle:findLocalPlayerVehicle()
    for _, vehicle in ipairs(Vehicle.Services.VehiclesFolder:GetChildren()) do
        if Vehicle:isOwnedByLocalPlayer(vehicle) then
            return vehicle
        end
    end
    return nil
end

function Vehicle:teleportVehicleToPlayer(vehicle)
    if not vehicle:IsA("Model") then return end
    local root = Vehicle:getRootPart()
    local targetCFrame = root.CFrame
    vehicle:PivotTo(targetCFrame)
end

function Vehicle:cleanup()
    print("Vehicle: Cleaning up...")
    
    -- Disconnect vehicle teleport connections
    if Vehicle.State.connections and Vehicle.State.connections.inputBegan then
        Vehicle.State.connections.inputBegan:Disconnect()
        Vehicle.State.connections.inputBegan = nil
    end
    
    print("Vehicle: Cleanup complete")
end

return Vehicle
