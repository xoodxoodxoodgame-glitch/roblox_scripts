-- Decompiled with Konstant V2.1, a fast Luau decompiler made in Luau by plusgiant5 (https://discord.gg/brNTY8nX8t)
-- Decompiled on 2026-02-08 12:44:35
-- Luau version 6, Types version 3
-- Time taken: 0.016133 seconds

local tbl_3_upvr = {Vector3int16.new(1, 0, 0), Vector3int16.new(1, 1, 0), Vector3int16.new(1, -1, 0), Vector3int16.new(1, 0, 1), Vector3int16.new(1, 0, -1), Vector3int16.new(-1, 0, 0), Vector3int16.new(-1, 1, 0), Vector3int16.new(-1, -1, 0), Vector3int16.new(-1, 0, -1), Vector3int16.new(-1, 0, 1), Vector3int16.new(0, 1, 0), Vector3int16.new(0, 1, 1), Vector3int16.new(0, 1, -1), Vector3int16.new(0, -1, 0), Vector3int16.new(0, -1, 1), Vector3int16.new(0, -1, -1), Vector3int16.new(0, 0, 1), Vector3int16.new(0, 0, -1)}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService_upvr = game:GetService("RunService")
local module_3_upvr = {
	_StaticInstance = nil;
	_BlockDefinitionsOrder = {};
	_BlockDefinitionsOrderLookup = {};
}
module_3_upvr.__index = module_3_upvr
local Workspace_upvr = game:GetService("Workspace")
local Settings_upvr = require(ReplicatedStorage.Settings)
local MineGeneration_upvr = require(ReplicatedStorage.Packages.Mining.MineGeneration)
local Table3D_upvr = require(ReplicatedStorage.Packages.Table3D)
function module_3_upvr.new() -- Line 45
	--[[ Upvalues[5]:
		[1]: Workspace_upvr (readonly)
		[2]: Settings_upvr (readonly)
		[3]: MineGeneration_upvr (readonly)
		[4]: Table3D_upvr (readonly)
		[5]: module_3_upvr (readonly)
	]]
	local any_WorldToCell_result1 = Workspace_upvr.Terrain:WorldToCell(Settings_upvr.MineDigOrigin)
	return setmetatable({
		_MineOrigin = Vector3int16.new(any_WorldToCell_result1.X, any_WorldToCell_result1.Y, any_WorldToCell_result1.Z);
		_MineGeneration = MineGeneration_upvr.new(Settings_upvr.MineDigAxis, Settings_upvr.MineDigDirection);
		_Cells = Table3D_upvr.new();
		_ChangedCells = {};
	}, module_3_upvr)
end
function module_3_upvr.GetInstance() -- Line 58
	--[[ Upvalues[2]:
		[1]: module_3_upvr (readonly)
		[2]: RunService_upvr (readonly)
	]]
	if not module_3_upvr._StaticInstance then
		local any_new_result1_2 = module_3_upvr.new()
		module_3_upvr._StaticInstance = any_new_result1_2
		if RunService_upvr:IsRunning() then
			any_new_result1_2:SetUpReplication()
		end
	end
	return module_3_upvr._StaticInstance
end
function module_3_upvr.Get(arg1, arg2) -- Line 72
	return arg1._Cells:Get(arg2)
end
function module_3_upvr.Set(arg1, arg2, arg3) -- Line 79
	arg1._Cells:Set(arg2, arg3)
	arg1._ChangedCells[tostring(arg2)] = arg2
end
function module_3_upvr.GenerateAround(arg1, arg2) -- Line 88
	--[[ Upvalues[1]:
		[1]: tbl_3_upvr (readonly)
	]]
	for _, v in tbl_3_upvr do
		local var28 = arg2 + v
		if not arg1:Get(var28) then
			local any_ComputeMaterial_result1 = arg1._MineGeneration:ComputeMaterial(var28 - arg1._MineOrigin)
			if any_ComputeMaterial_result1.BoundaryIssue ~= "Front" then
				arg1:Set(var28, {
					Block = any_ComputeMaterial_result1.Block;
					Ore = any_ComputeMaterial_result1.Ore;
				})
			end
		end
	end
end
function module_3_upvr.GetChangedCells(arg1) -- Line 104
	local module = {}
	for _, v_2 in arg1._ChangedCells do
		table.insert(module, v_2)
	end
	table.clear(arg1._ChangedCells)
	return module
end
function module_3_upvr.Reset(arg1) -- Line 116
	table.clear(arg1._ChangedCells)
	for i_3, _ in arg1._Cells:List() do
		arg1._ChangedCells[tostring(i_3)] = i_3
	end
	arg1._Cells:Clear()
end
local MadComm_upvr = require(ReplicatedStorage.MadComm)
function module_3_upvr.SetUpReplication(arg1) -- Line 130
	--[[ Upvalues[2]:
		[1]: RunService_upvr (readonly)
		[2]: MadComm_upvr (readonly)
	]]
	if RunService_upvr:IsServer() then
		MadComm_upvr:CreateRemoteFunction(script, "GetCurrentCells").OnInvoke(function() -- Line 133
			--[[ Upvalues[1]:
				[1]: arg1 (readonly)
			]]
			return arg1:SerializeAll()
		end)
		local any_CreateRemoteEvent_result1_upvr = MadComm_upvr:CreateRemoteEvent(script, "CellsChanged")
		RunService_upvr.Heartbeat:Connect(function() -- Line 139
			--[[ Upvalues[2]:
				[1]: arg1 (readonly)
				[2]: any_CreateRemoteEvent_result1_upvr (readonly)
			]]
			if not next(arg1._ChangedCells) then
			else
				any_CreateRemoteEvent_result1_upvr:FireAllClients(arg1:SerializeChanged())
			end
		end)
	else
		any_CreateRemoteEvent_result1_upvr = MadComm_upvr:GetModule("MineTerrain")
		local var45 = any_CreateRemoteEvent_result1_upvr
		var45:GetEvent("CellsChanged").OnClientEvent:Connect(function(arg1_2) -- Line 146
			--[[ Upvalues[1]:
				[1]: arg1 (readonly)
			]]
			arg1:Deserialize(arg1_2)
		end)
		var45:GetRemoteFunction("GetCurrentCells"):InvokeServer():andThen(function(arg1_3) -- Line 151
			--[[ Upvalues[1]:
				[1]: arg1 (readonly)
			]]
			arg1:Deserialize(arg1_3)
		end)
	end
end
function module_3_upvr.Deserialize(arg1, arg2) -- Line 160
	-- KONSTANTWARNING: Variable analysis failed. Output will have some incorrect variable assignments
	local buffer_readu32_result1 = buffer.readu32(arg2, 0)
	for i_4 = 1, buffer_readu32_result1 do
		local var57 = 4 + 14 * (i_4 - 1)
		arg1:Set(Vector3int16.new(buffer.readi32(arg2, var57), buffer.readi32(arg2, var57 + 4), buffer.readi32(arg2, var57 + 8)), {
			Block = arg1._BlockDefinitionsOrder[buffer.readu8(arg2, var57 + 12)];
			Ore = arg1._BlockDefinitionsOrder[buffer.readu8(arg2, var57 + 13)];
		})
	end
	local var59 = buffer_readu32_result1 * 14 + 4
	for i_5 = 1, buffer.readu32(arg2, var59) do
		local var60 = var59 + 4 + 12 * (i_5 - 1)
		arg1:Set(Vector3int16.new(buffer.readi32(arg2, var60), buffer.readi32(arg2, var60 + 4), buffer.readi32(arg2, var60 + 8)), nil)
		local _
	end
end
function module_3_upvr.Serialize(arg1, arg2) -- Line 183
	-- KONSTANTWARNING: Variable analysis failed. Output will have some incorrect variable assignments
	local tbl = {}
	local tbl_4 = {}
	for _, v_4 in arg2 do
		local any_Get_result1 = arg1:Get(v_4)
		if any_Get_result1 then
			table.insert(tbl, {
				Position = v_4;
				Cell = any_Get_result1;
			})
		else
			table.insert(tbl_4, v_4)
		end
	end
	local buffer_create_result1 = buffer.create(#tbl * 14 + 4 + 4 + #tbl_4 * 12)
	buffer.writeu32(buffer_create_result1, 0, #tbl)
	for i_7, v_5 in tbl do
		local var91 = 4 + (i_7 - 1) * 14
		local Position = v_5.Position
		local Cell = v_5.Cell
		buffer.writei32(buffer_create_result1, var91, Position.X)
		buffer.writei32(buffer_create_result1, var91 + 4, Position.Y)
		buffer.writei32(buffer_create_result1, var91 + 8, Position.Z)
		buffer.writeu32(buffer_create_result1, var91 + 12, arg1._BlockDefinitionsOrderLookup[Cell.Block] or 0)
		if Cell.Ore then
			buffer.writeu32(buffer_create_result1, var91 + 13, arg1._BlockDefinitionsOrderLookup[Cell.Ore] or 0)
		end
	end
	local var94 = #tbl * 14 + 4
	buffer.writeu32(buffer_create_result1, var94, #tbl_4)
	for i_8, v_6 in tbl_4 do
		local var95 = var94 + 4 + (i_8 - 1) * 12
		buffer.writei32(buffer_create_result1, var95, v_6.X)
		buffer.writei32(buffer_create_result1, var95 + 4, v_6.Y)
		buffer.writei32(buffer_create_result1, var95 + 8, v_6.Z)
		local _
	end
	return buffer_create_result1
end
function module_3_upvr.SerializeAll(arg1) -- Line 230
	local module_2 = {}
	for i_9, _ in arg1._Cells:List() do
		table.insert(module_2, i_9)
	end
	return arg1:Serialize(module_2)
end
function module_3_upvr.SerializeChanged(arg1) -- Line 241
	return arg1:Serialize(arg1:GetChangedCells())
end
if RunService_upvr:IsRunning() then
	for i_10, _ in require(ReplicatedStorage.Definitions.BlockDefinitions), nil do
		table.insert(module_3_upvr._BlockDefinitionsOrder, i_10)
	end
	table.sort(module_3_upvr)
	for i_11, v_9 in module_3_upvr._BlockDefinitionsOrder do
		module_3_upvr._BlockDefinitionsOrderLookup[v_9] = i_11
	end
end
return module_3_upvr
