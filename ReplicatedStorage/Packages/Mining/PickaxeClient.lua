-- Decompiled with Konstant V2.1, a fast Luau decompiler made in Luau by plusgiant5 (https://discord.gg/brNTY8nX8t)
-- Decompiled on 2026-02-08 13:35:10
-- Luau version 6, Types version 3
-- Time taken: 0.024059 seconds

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace_upvr = game:GetService("Workspace")
local MouseIconController_upvr = require(ReplicatedStorage.Controllers.MouseIconController)
local RebirthUpgradeDefinitions = require(ReplicatedStorage.Definitions.RebirthUpgradeDefinitions)
local MineTerrain_upvr = require(ReplicatedStorage.Packages.Mining.MineTerrain)
local module_upvr = {}
module_upvr.__index = module_upvr
module_upvr.Name = "PickaxeClient"
local Janitor_upvr = require(ReplicatedStorage.External.Janitor)
local HoverSelectionBox2_upvr = game.ReplicatedStorage.Assets.HoverSelectionBox2
local MadComm_upvr = require(ReplicatedStorage.MadComm)
function module_upvr.new(arg1, arg2) -- Line 49
	--[[ Upvalues[4]:
		[1]: module_upvr (readonly)
		[2]: Janitor_upvr (readonly)
		[3]: HoverSelectionBox2_upvr (readonly)
		[4]: MadComm_upvr (readonly)
	]]
	local setmetatable_result1_upvr = setmetatable({}, module_upvr)
	setmetatable_result1_upvr.Janitor = Janitor_upvr.new()
	setmetatable_result1_upvr.ClientControlJanitor = setmetatable_result1_upvr.Janitor:Add(Janitor_upvr.new())
	setmetatable_result1_upvr.Definition = arg2
	setmetatable_result1_upvr.Tool = arg1
	setmetatable_result1_upvr.Model = arg1.Model
	setmetatable_result1_upvr.Activated = false
	setmetatable_result1_upvr.ClientControlActive = false
	setmetatable_result1_upvr.Gui = nil
	setmetatable_result1_upvr.SwingAnimTrack = nil
	setmetatable_result1_upvr.SelectionBox = setmetatable_result1_upvr.Janitor:Add(HoverSelectionBox2_upvr:Clone())
	setmetatable_result1_upvr.MiningProgressPct = 0
	setmetatable_result1_upvr.LastMinedPosition = nil
	setmetatable_result1_upvr.LastLockTime = 0
	setmetatable_result1_upvr.SwingSoundHit = Instance.new("Sound")
	setmetatable_result1_upvr.SwingSoundHit.SoundId = arg2.SwingHitId
	setmetatable_result1_upvr.SwingSoundHit.Volume = 0.4
	setmetatable_result1_upvr.SwingSoundHit.Parent = setmetatable_result1_upvr.Model.PrimaryPart
	setmetatable_result1_upvr.SwingSoundMiss = Instance.new("Sound")
	setmetatable_result1_upvr.SwingSoundMiss.Volume = 0.1
	setmetatable_result1_upvr.SwingSoundMiss.SoundId = arg2.SwingMissId
	setmetatable_result1_upvr.SwingSoundMiss.Parent = setmetatable_result1_upvr.Model.PrimaryPart
	setmetatable_result1_upvr.BreakSound = Instance.new("Sound")
	setmetatable_result1_upvr.BreakSound.SoundId = "rbxassetid://8044058354"
	setmetatable_result1_upvr.BreakSound.PlaybackSpeed = 1.8
	setmetatable_result1_upvr.BreakSound.Volume = 0.44
	setmetatable_result1_upvr.BreakSound.Parent = setmetatable_result1_upvr.Model.PrimaryPart
	MadComm_upvr:GetInstancePromise(setmetatable_result1_upvr.Model):andThen(function(arg1_2) -- Line 86
		return arg1_2:GetRemoteFunctionPromise("Activate")
	end):andThen(function(arg1_3) -- Line 89
		--[[ Upvalues[1]:
			[1]: setmetatable_result1_upvr (readonly)
		]]
		setmetatable_result1_upvr.ActivateRemote = arg1_3
		if setmetatable_result1_upvr.Tool:IsControlledByLocalCharacter() then
			setmetatable_result1_upvr:StartClientControl()
		end
		setmetatable_result1_upvr.Janitor:Add(setmetatable_result1_upvr.Tool.EquippedCharacterChanged:Connect(function(arg1_4) -- Line 97
			--[[ Upvalues[1]:
				[1]: setmetatable_result1_upvr (copied, readonly)
			]]
			if setmetatable_result1_upvr.Tool:IsControlledByLocalCharacter() then
				setmetatable_result1_upvr:StartClientControl()
			else
				setmetatable_result1_upvr:StopClientControl()
			end
		end))
		setmetatable_result1_upvr.Tool.OnEquip:Connect(function() -- Line 107
			--[[ Upvalues[1]:
				[1]: setmetatable_result1_upvr (copied, readonly)
			]]
			if setmetatable_result1_upvr.Tool:IsControlledByLocalCharacter() then
				setmetatable_result1_upvr:OnLocalCharacterEquip()
			end
		end)
		setmetatable_result1_upvr.Tool.OnUnequip:Connect(function() -- Line 112
			--[[ Upvalues[1]:
				[1]: setmetatable_result1_upvr (copied, readonly)
			]]
			if setmetatable_result1_upvr.Tool:IsControlledByLocalCharacter() then
				setmetatable_result1_upvr:OnLocalCharacterUnequip()
			end
		end)
		if setmetatable_result1_upvr.Tool.Equipped and setmetatable_result1_upvr.Tool:IsControlledByLocalCharacter() then
			setmetatable_result1_upvr:OnLocalCharacterEquip()
		end
	end)
	return setmetatable_result1_upvr
end
local PickaxeGui_upvr = require(script.Parent.PickaxeGui)
local Players_upvr = game:GetService("Players")
local UserInputService_upvr = game:GetService("UserInputService")
local ControlsLib_upvr = require(StarterPlayer.StarterPlayerScripts.ControlsLib)
local TouchTracker_upvr = require(StarterPlayer.StarterPlayerScripts.ControlsLib.TouchTracker)
function module_upvr.StartClientControl(arg1) -- Line 126
	--[[ Upvalues[5]:
		[1]: PickaxeGui_upvr (readonly)
		[2]: Players_upvr (readonly)
		[3]: UserInputService_upvr (readonly)
		[4]: ControlsLib_upvr (readonly)
		[5]: TouchTracker_upvr (readonly)
	]]
	if arg1.ClientControlActive then
	else
		arg1.ClientControlActive = true
		local any_Add_result1 = arg1.ClientControlJanitor:Add(PickaxeGui_upvr.new())
		any_Add_result1.Gui.Parent = Players_upvr.LocalPlayer.PlayerGui
		arg1.Gui = any_Add_result1
		arg1.SwingAnimTrack = arg1:LoadAnimation(arg1.Definition.SwingAnimationId)
		if arg1.SwingAnimTrack then
			arg1.SwingAnimTrack.Looped = true
			arg1.Janitor:Add(arg1.SwingAnimTrack:GetMarkerReachedSignal("Strike"):Connect(function() -- Line 144
				--[[ Upvalues[1]:
					[1]: arg1 (readonly)
				]]
				if arg1.MiningProgressPct and 0 < arg1.MiningProgressPct then
					arg1.SwingSoundHit.PlaybackSpeed = 0.8 + 0.25 * arg1.MiningProgressPct ^ 5 + (math.random() - 0.5) * 0.08
					arg1.SwingSoundHit:Play()
				else
					arg1.SwingSoundMiss.PlaybackSpeed = 1.5 + (math.random() - 0.5) * 0.1
					arg1.SwingSoundMiss:Play()
				end
			end))
		end
		arg1.ClientControlJanitor:Add(UserInputService_upvr.InputBegan:Connect(function(arg1_5, arg2) -- Line 161
			--[[ Upvalues[1]:
				[1]: arg1 (readonly)
			]]
			if arg1_5.UserInputType == Enum.UserInputType.MouseButton1 and not arg2 and arg1.Tool.Equipped then
				arg1:ActivateStarted()
			end
		end))
		arg1.ClientControlJanitor:Add(ControlsLib_upvr.GetBindingStartEvent("ConsoleClick"):Connect(function() -- Line 171
			--[[ Upvalues[1]:
				[1]: arg1 (readonly)
			]]
			if arg1.Tool.Equipped then
				arg1:ActivateStarted()
			end
		end))
		arg1.ClientControlJanitor:Add(UserInputService_upvr.InputEnded:Connect(function(arg1_6, arg2) -- Line 180
			--[[ Upvalues[1]:
				[1]: arg1 (readonly)
			]]
			if arg1_6.UserInputType == Enum.UserInputType.MouseButton1 then
				arg1:ActivateEnded()
			end
		end))
		arg1.ClientControlJanitor:Add(ControlsLib_upvr.GetBindingEndEvent("ConsoleClick"):Connect(function() -- Line 188
			--[[ Upvalues[1]:
				[1]: arg1 (readonly)
			]]
			if arg1.Tool.Equipped then
				arg1:ActivateEnded()
			end
		end))
		UserInputService_upvr.TouchStarted:connect(function(arg1_7, arg2) -- Line 196
			--[[ Upvalues[2]:
				[1]: TouchTracker_upvr (copied, readonly)
				[2]: arg1 (readonly)
			]]
			if not arg2 and not TouchTracker_upvr:IsTouchWithinThumbstick(arg1_7) and arg1.Tool.Equipped then
				arg1_7.Changed:Connect(function() -- Line 199
					--[[ Upvalues[2]:
						[1]: arg1_7 (readonly)
						[2]: arg1 (copied, readonly)
					]]
					if arg1_7.UserInputState ~= Enum.UserInputState.Begin and arg1_7.UserInputState ~= Enum.UserInputState.Change and arg1.Tool.Equipped then
						arg1:ActivateEnded()
					end
				end)
				arg1:ActivateStarted()
			end
		end)
	end
end
function module_upvr.StopClientControl(arg1) -- Line 214
	arg1:ActivateEnded()
end
function module_upvr.OnLocalCharacterEquip(arg1) -- Line 219
	--[[ Upvalues[1]:
		[1]: MouseIconController_upvr (readonly)
	]]
	MouseIconController_upvr.AddIconWithPriority(arg1, "rbxassetid://140164678761108", 1)
end
function module_upvr.OnLocalCharacterUnequip(arg1) -- Line 224
	--[[ Upvalues[1]:
		[1]: MouseIconController_upvr (readonly)
	]]
	MouseIconController_upvr.RemoveReference(arg1)
	arg1:ActivateEnded()
end
local PlayerDataController_upvr = require(ReplicatedStorage.Controllers.PlayerDataController)
local Strength_upvr = RebirthUpgradeDefinitions.PickaxeStrength.Strength
local Strength_upvr_2 = RebirthUpgradeDefinitions.PickaxeSpeed.Strength
local MiningTimeFunction_upvr = require(script.Parent.MiningTimeFunction)
local Settings_upvr = require(ReplicatedStorage.Settings)
function module_upvr.ActivateStarted(arg1) -- Line 230
	--[[ Upvalues[6]:
		[1]: Workspace_upvr (readonly)
		[2]: PlayerDataController_upvr (readonly)
		[3]: Strength_upvr (readonly)
		[4]: Strength_upvr_2 (readonly)
		[5]: MiningTimeFunction_upvr (readonly)
		[6]: Settings_upvr (readonly)
	]]
	-- KONSTANTERROR: [0] 1. Error Block 1 start (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [0] 1. Error Block 1 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [3] 3. Error Block 2 start (CF ANALYSIS FAILED)
	do
		return
	end
	-- KONSTANTERROR: [3] 3. Error Block 2 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [4] 4. Error Block 3 start (CF ANALYSIS FAILED)
	arg1.Activated = true
	-- KONSTANTERROR: [4] 4. Error Block 3 end (CF ANALYSIS FAILED)
end
function module_upvr.ActivateEnded(arg1) -- Line 319
	arg1.Activated = false
	arg1.MiningProgressPct = 0
	arg1.LastMinedPosition = nil
	arg1.SelectionBox.Parent = game.ReplicatedStorage
	if arg1.SwingAnimTrack then
		arg1.SwingAnimTrack:Stop()
	end
	if arg1.Gui then
		arg1.Gui:MiningEnded()
	end
end
local MouseHit_upvr = require(ReplicatedStorage.MadLib.MouseHit)
local BlockDefinitions_upvr = require(ReplicatedStorage.Definitions.BlockDefinitions)
function module_upvr.GetCurrentTarget(arg1) -- Line 335
	--[[ Upvalues[3]:
		[1]: MouseHit_upvr (readonly)
		[2]: MineTerrain_upvr (readonly)
		[3]: BlockDefinitions_upvr (readonly)
	]]
	local any_GetTerrainCellHit_result1, any_GetTerrainCellHit_result2, any_GetTerrainCellHit_result3 = MouseHit_upvr:GetTerrainCellHit(200)
	assert(arg1.Tool.EquippedCharacter)
	local var41
	if not arg1.Tool.EquippedCharacter:FindFirstChild("HumanoidRootPart") then
		warn("No HRP for pickaxe")
		return nil
	end
	if not any_GetTerrainCellHit_result1 or not any_GetTerrainCellHit_result2 then
		return nil
	end
	var41 = arg1.Tool.EquippedCharacter:FindFirstChild("HumanoidRootPart").Position
	var41 = arg1.Tool.Definition.Stats
	if var41.Range < (var41 - any_GetTerrainCellHit_result1).Magnitude then
		return nil
	end
	var41 = Vector3int16.new(any_GetTerrainCellHit_result2.X, any_GetTerrainCellHit_result2.Y, any_GetTerrainCellHit_result2.Z)
	local any_Get_result1 = MineTerrain_upvr.GetInstance():Get(var41)
	if not any_Get_result1 then
		return nil
	end
	local function INLINED() -- Internal function, doesn't exist in bytecode
		var41 = BlockDefinitions_upvr[any_Get_result1.Ore]
		return var41
	end
	if not any_Get_result1.Ore or not INLINED() then
		var41 = BlockDefinitions_upvr[any_Get_result1.Block]
	end
	return any_GetTerrainCellHit_result2, var41
end
function module_upvr.LoadAnimation(arg1, arg2) -- Line 359
	if not arg2 then
		print("Pickaxe has no SwingAnimationId")
		return
	end
	local Animation = Instance.new("Animation")
	Animation.AnimationId = arg2
	if arg1.Tool.EquippedCharacter then
		local class_Humanoid = arg1.Tool.EquippedCharacter:FindFirstChildOfClass("Humanoid")
		if class_Humanoid then
			local class_Animator = class_Humanoid:FindFirstChildOfClass("Animator")
			assert(class_Animator, "Humanoid has no animator")
			return class_Animator:LoadAnimation(Animation)
		end
	end
	return nil
end
local Promise_upvr = require(ReplicatedStorage.External.Promise)
function module_upvr.MineBlock(arg1, arg2) -- Line 381
	--[[ Upvalues[2]:
		[1]: MineTerrain_upvr (readonly)
		[2]: Promise_upvr (readonly)
	]]
	local any_GetInstance_result1_upvr = MineTerrain_upvr.GetInstance()
	local Vector3int16_new_result1_upvr = Vector3int16.new(arg2.X, arg2.Y, arg2.Z)
	any_GetInstance_result1_upvr:Set(Vector3int16_new_result1_upvr, {
		Block = "Air";
	})
	any_GetInstance_result1_upvr:GenerateAround(Vector3int16_new_result1_upvr)
	return arg1.ActivateRemote:InvokeServer(Vector3int16_new_result1_upvr):andThen(function(arg1_8, arg2_2) -- Line 391
		--[[ Upvalues[1]:
			[1]: Promise_upvr (copied, readonly)
		]]
		if not arg1_8 then
			return Promise_upvr.reject(arg2_2)
		end
	end):catch(function(arg1_9) -- Line 396
		--[[ Upvalues[2]:
			[1]: any_GetInstance_result1_upvr (readonly)
			[2]: Vector3int16_new_result1_upvr (readonly)
		]]
		any_GetInstance_result1_upvr:Set(Vector3int16_new_result1_upvr, arg1_9)
	end)
end
local CargoVolume_upvr = require(ReplicatedStorage.Packages.Mining.CargoVolume)
local FloatingText_upvr = require(ReplicatedStorage.UI.Elements.FloatingText)
local UIThemes_upvr = require(ReplicatedStorage.UI.UIThemes)
function module_upvr.CreateOreAddedText(arg1, arg2, arg3) -- Line 402
	--[[ Upvalues[4]:
		[1]: CargoVolume_upvr (readonly)
		[2]: FloatingText_upvr (readonly)
		[3]: UIThemes_upvr (readonly)
		[4]: Workspace_upvr (readonly)
	]]
	if not arg2.IngredientId or arg2.IngredientId == "Stone" then
	else
		local EquippedPlayer = arg1.Tool.EquippedPlayer
		if EquippedPlayer then
			local any_ForPlayer_result1 = CargoVolume_upvr.ForPlayer(EquippedPlayer, "Backpack")
			local any_new_result1 = FloatingText_upvr.new()
			any_new_result1:SetTheme(UIThemes_upvr.Default)
			any_new_result1:SetTextSize(26)
			any_new_result1:SetExpireDuration()
			any_new_result1.TextLabel.TextStrokeTransparency = 0
			any_new_result1.Gui.StudsOffsetWorldSpace = Vector3.new(0, 0.5, 0)
			any_new_result1.Gui.AlwaysOnTop = true
			local Attachment = Instance.new("Attachment")
			Attachment.Parent = Workspace_upvr.Terrain
			Attachment.WorldCFrame = CFrame.new(arg3 - Vector3.new(0, 1, 0))
			any_new_result1.Janitor:Add(Attachment)
			any_new_result1:SetAdornee(Attachment)
			local Capacity = any_ForPlayer_result1.Capacity
			local len = #any_ForPlayer_result1:GetOres()
			if Capacity <= len then
				any_new_result1:SetText("<font color=\"#FF1111\">BACKPACK FULL</font>")
				return
			end
			local var64 = "+1 "..arg2.Name.." ("..tostring(len + 1)..'/'..tostring(Capacity)..')'
			if len == Capacity - 2 then
				var64 = "<font color=\"#FF7800\">"..var64.."</font>"
			elseif len == Capacity - 1 then
				var64 = "<font color=\"#FF1111\">"..var64.."</font>"
			end
			any_new_result1:SetText(var64)
		end
	end
end
function module_upvr.Destroy(arg1) -- Line 442
	--[[ Upvalues[1]:
		[1]: MouseIconController_upvr (readonly)
	]]
	arg1.Janitor:Cleanup()
	MouseIconController_upvr.RemoveReference(arg1)
end
return module_upvr
