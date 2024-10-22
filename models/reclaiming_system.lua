
---@class ReclaimingSystem : module
local M = {}


--#region Global data
local _mod_data
local _prohibited_entities
--#endregion


--#region Constants
local call = remote.call
--#endregion


local on_pre_entity_changed_force
local on_entity_changed_force


local is_on_pre_entity_changed_force_event_active = false
local is_on_entity_changed_force_event_active     = false
if script.active_mods.EasyAPI then
	local configs_util = require("__EasyAPI__/external_mod_configs_util")
	local configs = configs_util.get_external_mod_configs()
	is_on_pre_entity_changed_force_event_active = configs_util.find_1st_truthy_value_in_configs(configs, "is_on_pre_entity_changed_force_event_active")
	is_on_entity_changed_force_event_active     = configs_util.find_1st_truthy_value_in_configs(configs, "is_on_entity_changed_force_event_active")
end


---@param player LuaPlayer
---@param target_position MapPosition
function M.reclaim(player, target_position)
	local player_force = player.force
	local enemy_forces = {}
	for _, force in pairs(game.forces) do
		if force.is_enemy(player_force) and force.name ~= "enemy" then
			enemy_forces[#enemy_forces+1] = force
		end
	end

	if #enemy_forces == 0 then
		player.print("There are no hostile teams", {1, 0, 0}) -- TODO: localization
		return
	end

	local enemy_entity = player.surface.find_entities_filtered{
		position = target_position,
		radius = settings.global["recl_enemy_check_distance"].value,
		force = enemy_forces,
		limit = 1,
		is_military_target = true
	}
	if #enemy_entity > 0 then
		player.print("There are military entities nearby", {1, 0, 0}) -- TODO: localization
		return
	end

	local enemy_entity = player.surface.find_entities_filtered{
		position = target_position,
		radius = settings.global["recl_enemy_check_distance"].value,
		type  = {"car", "cargo-wagon", "artillery-wagon", "fluid-wagon", "locomotive"}, -- TODO: improve
		force = enemy_forces,
		limit = 1
	}
	if #enemy_entity > 0 then
		player.print("There are military entities nearby", {1, 0, 0}) -- TODO: localization
		return
	end

	local entites_for_capturing = player.surface.find_entities_filtered{
		position = target_position,
		radius = settings.global["recl_reclaiming_distance"].value,
		force = enemy_forces
	}
	local raise_event = script.raise_event
	-- TODO: ask if is allowed to change force from other mods
	if not is_on_pre_entity_changed_force_event_active and
		not is_on_entity_changed_force_event_active
	then
		if next(_prohibited_entities) == nil then
			for _, entity in pairs(entites_for_capturing) do
				entity.force = player_force
			end
		else
			for _, entity in pairs(entites_for_capturing) do
				if not _prohibited_entities[entity.unit_number] then
					entity.force = player_force
				end
			end
		end
	elseif is_on_pre_entity_changed_force_event_active and
		not is_on_entity_changed_force_event_active
	then
		local pre_event_data = {
			entity = nil,
			next_force = player_force
		}
		if next(_prohibited_entities) == nil then
			for _, entity in pairs(entites_for_capturing) do
				pre_event_data.entity = entity
				raise_event(on_pre_entity_changed_force, pre_event_data)
				if entity.valid then
					entity.force = player_force
				end
			end
		else
			for _, entity in pairs(entites_for_capturing) do
				if not _prohibited_entities[entity.unit_number] then
					pre_event_data.entity = entity
					raise_event(on_pre_entity_changed_force, pre_event_data)
					if entity.valid then
						entity.force = player_force
					end
				end
			end
		end
	elseif not is_on_pre_entity_changed_force_event_active and
		is_on_entity_changed_force_event_active
	then
		local event_data = {
			entity = nil,
			next_force = player_force
		}
		if next(_prohibited_entities) == nil then
			for _, entity in pairs(entites_for_capturing) do
				event_data.entity = entity
				event_data.prev_force = entity.force
				entity.force = player_force
				raise_event(on_entity_changed_force, event_data)
			end
		else
			for _, entity in pairs(entites_for_capturing) do
				if not _prohibited_entities[entity.unit_number] then
					event_data.entity = entity
					event_data.prev_force = entity.force
					entity.force = player_force
					raise_event(on_entity_changed_force, event_data)
				end
			end
		end
	elseif is_on_pre_entity_changed_force_event_active and
		is_on_entity_changed_force_event_active
	then
		local pre_event_data = {
			entity = nil,
			next_force = nil
		}
		local event_data = {
			entity = nil,
			prev_force = nil
		}
		if next(_prohibited_entities) == nil then
			for _, entity in pairs(entites_for_capturing) do
				pre_event_data.entity = entity
				raise_event(on_pre_entity_changed_force, pre_event_data)
				if entity.valid then
					event_data.entity = entity
					event_data.prev_force = entity.force
					entity.force = player_force
					raise_event(on_entity_changed_force, event_data)
				end
			end
		else
			for _, entity in pairs(entites_for_capturing) do
				if not _prohibited_entities[entity.unit_number] then
					pre_event_data.entity = entity
					raise_event(on_pre_entity_changed_force, pre_event_data)
					if entity.valid then
						event_data.entity = entity
						event_data.prev_force = entity.force
						entity.force = player_force
						raise_event(on_entity_changed_force, event_data)
					end
				end
			end
		end
	end
end


---@param event EventData.on_script_trigger_effect
function M.on_script_trigger_effect(event)
	if event.effect_id ~= "reclaim" then return end
	local source = event.source_entity
	if not (source and source.valid) then return end
	if source.type ~= "character" then return end
	M.reclaim(source, event.target_position)
end


function M.auto_reclaim(event)
	if not settings.startup["recl_is_auto_reclaim_on"].value then return end

	-- TODO: optimize
	local reclaim = M.reclaim
	for _, player in pairs(game.connected_players) do
		reclaim(player, player.position)
	end
end


--#region Pre-game stage

function M.add_remote_interface()
	-- https://lua-api.factorio.com/latest/LuaRemote.html
	remote.remove_interface("reclaiming_system") -- For safety
	remote.add_interface("reclaiming_system", {
		get_mod_data = function() return _mod_data end,
		---@param name string
		get_internal_data = function(name) return _mod_data[name] end,
		---@param entity LuaEntity
		prohibit_entity = function(entity)
			_prohibited_entities[entity.unit_number] = entity
		end,
		---@param unit_number uint
		allow_entity = function(unit_number)
			_prohibited_entities[unit_number] = nil
		end,
		reclaim = M.reclaim,
	})
end

function M.link_data()
	_mod_data = storage._mod_data
	_prohibited_entities = _mod_data._prohibited_entities

	if script.active_mods.EasyAPI then
		on_pre_entity_changed_force = call("EasyAPI", "get_event_name", "on_pre_entity_changed_force")
		on_entity_changed_force     = call("EasyAPI", "get_event_name", "on_entity_changed_force")
	end
end


function M.update_global_data()
	storage._mod_data = storage._mod_data or {}
	_mod_data = storage._mod_data
	_mod_data._prohibited_entities = _mod_data._prohibited_entities or {}

	M.link_data()

	for unit_number, entity in pairs(_prohibited_entities) do
		if not entity.valid then
			_prohibited_entities[unit_number] = nil
		end
	end
end

function M.reclaim_command(cmd)
	local player = game.get_player(cmd.player_index)
	if not (player and player.valid) then return end
	M.reclaim(player, player.position)
end


M.on_init = M.update_global_data
M.on_configuration_changed = M.update_global_data
M.on_load = M.link_data
M.update_global_data_on_disabling = M.update_global_data -- for safe disabling of this mod

--#endregion


M.events = {
	-- [defines.events.on_script_trigger_effect] = M.on_script_trigger_effect,
}
if settings.startup["recl_is_add_capsule"].value then
	M.events[defines.events.on_script_trigger_effect] = M.on_script_trigger_effect
end

M.commands = {
	reclaim = M.reclaim_command,
}

M.on_nth_tick = {
	-- [60 * 5]  = M.auto_reclaim, -- Factorio messed up settings -- TODO: recheck later
}


return M
