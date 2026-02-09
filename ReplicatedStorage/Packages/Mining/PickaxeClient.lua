-- Decompiled with Medal in Seliware

local v_u_1 = game.ReplicatedStorage.Assets.HoverSelectionBox2
local v_u_2 = game:GetService("Players")
local v3 = game:GetService("ReplicatedStorage")
local v4 = game:GetService("StarterPlayer")
local v_u_5 = game:GetService("UserInputService")
local v_u_6 = game:GetService("Workspace")
local v_u_7 = require(script.Parent.MiningTimeFunction)
local v_u_8 = require(script.Parent.PickaxeGui)
local v_u_9 = require(v4.StarterPlayerScripts.ControlsLib)
local v_u_10 = require(v4.StarterPlayerScripts.ControlsLib.TouchTracker)
local v_u_11 = require(v3.Controllers.MouseIconController)
local v_u_12 = require(v3.Controllers.PlayerDataController)
local v_u_13 = require(v3.Definitions.BlockDefinitions)
local v14 = require(v3.Definitions.RebirthUpgradeDefinitions)
local v_u_15 = require(v3.MadComm)
local v_u_16 = require(v3.External.Janitor)
local v_u_17 = require(v3.MadLib.MouseHit)
local v_u_18 = require(v3.External.Promise)
require(v3.External.Promise)
require(v3.Packages.InnoTools.ToolBase)
local v_u_19 = require(v3.Packages.Mining.CargoVolume)
local v_u_20 = require(v3.Packages.Mining.MineTerrain)
local v_u_21 = require(v3.Settings)
local v_u_22 = require(v3.UI.Elements.FloatingText)
local v_u_23 = require(v3.UI.UIThemes)
local v_u_24 = v14.PickaxeStrength.Strength
local v_u_25 = v14.PickaxeSpeed.Strength
local v_u_26 = {}
v_u_26.__index = v_u_26
v_u_26.Name = "PickaxeClient"
function v_u_26.new(p27, p28)
    -- upvalues: (copy) v_u_26, (copy) v_u_16, (copy) v_u_1, (copy) v_u_15
    local v29 = v_u_26
    local v_u_30 = setmetatable({}, v29)
    v_u_30.Janitor = v_u_16.new()
    v_u_30.ClientControlJanitor = v_u_30.Janitor:Add(v_u_16.new())
    v_u_30.Definition = p28
    v_u_30.Tool = p27
    v_u_30.Model = p27.Model
    v_u_30.Activated = false
    v_u_30.ClientControlActive = false
    v_u_30.Gui = nil
    v_u_30.SwingAnimTrack = nil
    v_u_30.SelectionBox = v_u_30.Janitor:Add(v_u_1:Clone())
    v_u_30.MiningProgressPct = 0
    v_u_30.LastMinedPosition = nil
    v_u_30.LastLockTime = 0
    v_u_30.SwingSoundHit = Instance.new("Sound")
    v_u_30.SwingSoundHit.SoundId = p28.SwingHitId
    v_u_30.SwingSoundHit.Volume = 0.4
    v_u_30.SwingSoundHit.Parent = v_u_30.Model.PrimaryPart
    v_u_30.SwingSoundMiss = Instance.new("Sound")
    v_u_30.SwingSoundMiss.Volume = 0.1
    v_u_30.SwingSoundMiss.SoundId = p28.SwingMissId
    v_u_30.SwingSoundMiss.Parent = v_u_30.Model.PrimaryPart
    v_u_30.BreakSound = Instance.new("Sound")
    v_u_30.BreakSound.SoundId = "rbxassetid://8044058354"
    v_u_30.BreakSound.PlaybackSpeed = 1.8
    v_u_30.BreakSound.Volume = 0.44
    v_u_30.BreakSound.Parent = v_u_30.Model.PrimaryPart
    v_u_15:GetInstancePromise(v_u_30.Model):andThen(function(p31)
        return p31:GetRemoteFunctionPromise("Activate")
    end):andThen(function(p32)
        -- upvalues: (copy) v_u_30
        v_u_30.ActivateRemote = p32
        if v_u_30.Tool:IsControlledByLocalCharacter() then
            v_u_30:StartClientControl()
        end
        v_u_30.Janitor:Add(v_u_30.Tool.EquippedCharacterChanged:Connect(function(_)
            -- upvalues: (ref) v_u_30
            if v_u_30.Tool:IsControlledByLocalCharacter() then
                v_u_30:StartClientControl()
            else
                v_u_30:StopClientControl()
            end
        end))
        v_u_30.Tool.OnEquip:Connect(function()
            -- upvalues: (ref) v_u_30
            if v_u_30.Tool:IsControlledByLocalCharacter() then
                v_u_30:OnLocalCharacterEquip()
            end
        end)
        v_u_30.Tool.OnUnequip:Connect(function()
            -- upvalues: (ref) v_u_30
            if v_u_30.Tool:IsControlledByLocalCharacter() then
                v_u_30:OnLocalCharacterUnequip()
            end
        end)
        if v_u_30.Tool.Equipped and v_u_30.Tool:IsControlledByLocalCharacter() then
            v_u_30:OnLocalCharacterEquip()
        end
    end)
    return v_u_30
end
function v_u_26.StartClientControl(p_u_33)
    -- upvalues: (copy) v_u_8, (copy) v_u_2, (copy) v_u_5, (copy) v_u_9, (copy) v_u_10
    if not p_u_33.ClientControlActive then
        p_u_33.ClientControlActive = true
        local v34 = p_u_33.ClientControlJanitor:Add(v_u_8.new())
        v34.Gui.Parent = v_u_2.LocalPlayer.PlayerGui
        p_u_33.Gui = v34
        p_u_33.SwingAnimTrack = p_u_33:LoadAnimation(p_u_33.Definition.SwingAnimationId)
        if p_u_33.SwingAnimTrack then
            p_u_33.SwingAnimTrack.Looped = true
            p_u_33.Janitor:Add(p_u_33.SwingAnimTrack:GetMarkerReachedSignal("Strike"):Connect(function()
                -- upvalues: (copy) p_u_33
                if p_u_33.MiningProgressPct and p_u_33.MiningProgressPct > 0 then
                    local v35 = 0.8 + 0.25 * p_u_33.MiningProgressPct ^ 5 + (math.random() - 0.5) * 0.08
                    p_u_33.SwingSoundHit.PlaybackSpeed = v35
                    p_u_33.SwingSoundHit:Play()
                else
                    p_u_33.SwingSoundMiss.PlaybackSpeed = 1.5 + (math.random() - 0.5) * 0.1
                    p_u_33.SwingSoundMiss:Play()
                end
            end))
        end
        p_u_33.ClientControlJanitor:Add(v_u_5.InputBegan:Connect(function(p36, p37)
            -- upvalues: (copy) p_u_33
            if p36.UserInputType == Enum.UserInputType.MouseButton1 and (not p37 and p_u_33.Tool.Equipped) then
                p_u_33:ActivateStarted()
            end
        end))
        p_u_33.ClientControlJanitor:Add(v_u_9.GetBindingStartEvent("ConsoleClick"):Connect(function()
            -- upvalues: (copy) p_u_33
            if p_u_33.Tool.Equipped then
                p_u_33:ActivateStarted()
            end
        end))
        p_u_33.ClientControlJanitor:Add(v_u_5.InputEnded:Connect(function(p38, _)
            -- upvalues: (copy) p_u_33
            if p38.UserInputType == Enum.UserInputType.MouseButton1 then
                p_u_33:ActivateEnded()
            end
        end))
        p_u_33.ClientControlJanitor:Add(v_u_9.GetBindingEndEvent("ConsoleClick"):Connect(function()
            -- upvalues: (copy) p_u_33
            if p_u_33.Tool.Equipped then
                p_u_33:ActivateEnded()
            end
        end))
        v_u_5.TouchStarted:connect(function(p_u_39, p40)
            -- upvalues: (ref) v_u_10, (copy) p_u_33
            if not p40 and (not v_u_10:IsTouchWithinThumbstick(p_u_39) and p_u_33.Tool.Equipped) then
                p_u_39.Changed:Connect(function()
                    -- upvalues: (copy) p_u_39, (ref) p_u_33
                    if p_u_39.UserInputState ~= Enum.UserInputState.Begin and (p_u_39.UserInputState ~= Enum.UserInputState.Change and p_u_33.Tool.Equipped) then
                        p_u_33:ActivateEnded()
                    end
                end)
                p_u_33:ActivateStarted()
            end
        end)
    end
end
function v_u_26.StopClientControl(p41)
    p41:ActivateEnded()
end
function v_u_26.OnLocalCharacterEquip(p42)
    -- upvalues: (copy) v_u_11
    v_u_11.AddIconWithPriority(p42, "rbxassetid://140164678761108", 1)
end
function v_u_26.OnLocalCharacterUnequip(p43)
    -- upvalues: (copy) v_u_11
    v_u_11.RemoveReference(p43)
    p43:ActivateEnded()
end
function v_u_26.ActivateStarted(p44)
    -- upvalues: (copy) v_u_6, (copy) v_u_12, (copy) v_u_24, (copy) v_u_25, (copy) v_u_7, (copy) v_u_21
    if p44.Activated then
        return
    end
    p44.Activated = true
    if p44.SwingAnimTrack then
        p44.SwingAnimTrack:Play(nil, nil, 2.4)
    end
    while p44.Activated do
        local v45 = task.wait()
        if not p44.Activated then
            break
        end
        local v46 = nil
        local v47
        if v46 then
            v47 = nil
        else
            v47, v46 = p44:GetCurrentTarget()
        end
        if v47 and (v46 and v46.Hardness) then
            local v48 = v_u_6.Terrain:CellCenterToWorld(v47.X, v47.Y, v47.Z)
            if v48 ~= p44.LastMinedPosition then
                p44.MiningProgressPct = 0
                p44.LastLockTime = time()
                p44.LastMinedPosition = v48
                if p44.Gui then
                    p44.Gui:MiningStarted()
                end
            end
            local v49 = p44.Tool.Definition.Stats.Hardness * (1 + (v_u_12.LocalPlayerData.Upgrades.PickaxeStrength or 0) * v_u_24)
            local v50 = v_u_7(p44.Tool.Definition.Stats.Speed * (1 + (v_u_12.LocalPlayerData.Upgrades.PickaxeSpeed or 0) * v_u_25), v49, v46.Hardness)
            local v51 = p44.MiningProgressPct + v45 / v50
            p44.MiningProgressPct = math.clamp(v51, 0, 1)
            if p44.Gui then
                p44.Gui:SetProgressPct(p44.MiningProgressPct)
                local v52 = v50 > 999
                p44.Gui:SetUnminable(v52)
                if v52 then
                    local v53 = p44.Gui
                    local v54 = v46.Hardness / v_u_21.MiningHardnessRatioLimit
                    local v55 = math.ceil(v54)
                    v53:SetText(tostring(v55) .. " hardness needed")
                else
                    local v56 = p44.MiningProgressPct * 100
                    local v57 = math.round(v56)
                    local v58 = tostring(v57)
                    if p44.MiningProgressPct < 0.095 then
                        v58 = " 0" .. v58
                    elseif p44.MiningProgressPct < 1 then
                        v58 = " " .. v58
                    end
                    p44.Gui:SetText(v46.Name .. ": " .. v58 .. "%")
                end
            end
            p44.SelectionBox.Parent = game.Workspace
            p44.SelectionBox.CFrame = CFrame.new(v48)
            if p44.MiningProgressPct >= 1 then
                p44.MiningProgressPct = 0
                p44:CreateOreAddedText(v46, v48)
                p44:MineBlock(v47)
                p44.BreakSound:Play()
            end
        else
            p44.LastMinedPosition = nil
            p44.SelectionBox.Parent = game.ReplicatedStorage
            if p44.Gui then
                p44.Gui:MiningEnded()
            end
            p44.MiningProgressPct = 0
        end
    end
end
function v_u_26.ActivateEnded(p59)
    p59.Activated = false
    p59.MiningProgressPct = 0
    p59.LastMinedPosition = nil
    p59.SelectionBox.Parent = game.ReplicatedStorage
    if p59.SwingAnimTrack then
        p59.SwingAnimTrack:Stop()
    end
    if p59.Gui then
        p59.Gui:MiningEnded()
    end
end
function v_u_26.GetCurrentTarget(p60)
    -- upvalues: (copy) v_u_17, (copy) v_u_20, (copy) v_u_13
    local v61, v62, _ = v_u_17:GetTerrainCellHit(200)
    local v63 = p60.Tool.EquippedCharacter
    assert(v63)
    local v64 = p60.Tool.EquippedCharacter:FindFirstChild("HumanoidRootPart")
    if v64 then
        if v61 and v62 then
            if (v64.Position - v61).Magnitude > p60.Tool.Definition.Stats.Range then
                return nil
            else
                local v65 = v_u_20.GetInstance():Get(Vector3int16.new(v62.X, v62.Y, v62.Z))
                if v65 then
                    return v62, v65.Ore and v_u_13[v65.Ore] or v_u_13[v65.Block]
                else
                    return nil
                end
            end
        else
            return nil
        end
    else
        warn("No HRP for pickaxe")
        return nil
    end
end
function v_u_26.LoadAnimation(p66, p67)
    if p67 then
        local v68 = Instance.new("Animation")
        v68.AnimationId = p67
        local v69 = p66.Tool.EquippedCharacter and p66.Tool.EquippedCharacter:FindFirstChildOfClass("Humanoid")
        if not v69 then
            return nil
        end
        local v70 = v69:FindFirstChildOfClass("Animator")
        assert(v70, "Humanoid has no animator")
        return v70:LoadAnimation(v68)
    end
    print("Pickaxe has no SwingAnimationId")
end
function v_u_26.MineBlock(p71, p72)
    -- upvalues: (copy) v_u_20, (copy) v_u_18
    local v_u_73 = v_u_20.GetInstance()
    local v_u_74 = Vector3int16.new(p72.X, p72.Y, p72.Z)
    v_u_73:Set(v_u_74, {
        ["Block"] = "Air"
    })
    v_u_73:GenerateAround(v_u_74)
    return p71.ActivateRemote:InvokeServer(v_u_74):andThen(function(p75, p76)
        -- upvalues: (ref) v_u_18
        if not p75 then
            return v_u_18.reject(p76)
        end
    end):catch(function(p77)
        -- upvalues: (copy) v_u_73, (copy) v_u_74
        v_u_73:Set(v_u_74, p77)
    end)
end
function v_u_26.CreateOreAddedText(p78, p79, p80)
    -- upvalues: (copy) v_u_19, (copy) v_u_22, (copy) v_u_23, (copy) v_u_6
    if p79.IngredientId and p79.IngredientId ~= "Stone" then
        local v81 = p78.Tool.EquippedPlayer
        if v81 then
            local v82 = v_u_19.ForPlayer(v81, "Backpack")
            local v83 = v_u_22.new()
            v83:SetTheme(v_u_23.Default)
            v83:SetTextSize(26)
            v83:SetExpireDuration()
            v83.TextLabel.TextStrokeTransparency = 0
            v83.Gui.StudsOffsetWorldSpace = Vector3.new(0, 0.5, 0)
            v83.Gui.AlwaysOnTop = true
            local v84 = Instance.new("Attachment")
            v84.Parent = v_u_6.Terrain
            v84.WorldCFrame = CFrame.new(p80 - Vector3.new(0, 1, 0))
            v83.Janitor:Add(v84)
            v83:SetAdornee(v84)
            local v85 = v82.Capacity
            local v86 = #v82:GetOres()
            if v85 <= v86 then
                v83:SetText("<font color=\"#FF1111\">BACKPACK FULL</font>")
                return
            end
            local v87 = p79.Name
            local v88 = v86 + 1
            local v89 = "+1 " .. v87 .. " (" .. tostring(v88) .. "/" .. tostring(v85) .. ")"
            if v86 == v85 - 2 then
                v89 = "<font color=\"#FF7800\">" .. v89 .. "</font>"
            elseif v86 == v85 - 1 then
                v89 = "<font color=\"#FF1111\">" .. v89 .. "</font>"
            end
            v83:SetText(v89)
        end
    end
end
function v_u_26.Destroy(p90)
    -- upvalues: (copy) v_u_11
    p90.Janitor:Cleanup()
    v_u_11.RemoveReference(p90)
end
return v_u_26\0
