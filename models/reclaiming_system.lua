
---@class EmptyModule : module
local M = {}


--#region Global data
--local _players_data
local on_pre_entity_force_changed
local on_entity_force_changed
--#endregion


--#region Constants
local call = remote.call
--#endregion


local is_on_pre_entity_force_changed_event_active = false
local is_on_entity_force_changed_event_active     = false
if script.active_mods.EasyAPI then
	-- Finds settings from other mod config files
	for mod_name in pairs(script.active_mods) do
		local is_ok, config = pcall(require, string.format("__%s__/external_mod_configs", mod_name))
		if is_ok then
			if config.is_on_pre_entity_force_changed_event_active then
				is_on_pre_entity_force_changed_event_active = true
				if is_on_entity_force_changed_event_active then
					break
				end
			end
			if config.is_on_entity_force_changed_event_active then
				is_on_entity_force_changed_event_active = true
				if is_on_pre_entity_force_changed_event_active then
					break
				end
			end
		end
	end
end


--#region Pre-game stage

local function link_data()
	--_players_data = global.players

	if script.active_mods.EasyAPI then
		on_pre_entity_force_changed = call("EasyAPI", "get_event_name", "on_pre_entity_force_changed")
		on_entity_force_changed     = call("EasyAPI", "get_event_name", "on_entity_force_changed")
	end
end


local function get_data()

end


local function update_global_data()
	--global.players = global.players or {}

	link_data()

	--for player_index, player in pairs(game.players) do
	--	-- delete UIs, etc
	--end
end

local function reclaim_command(cmd)
	local player = game.get_player(cmd.player_index)
	if not (player and player.valid) then return end

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
		position = player.position,
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
		position = player.position,
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
		position = player.position,
		radius = settings.global["recl_reclaiming_distance"].value,
		force = enemy_forces
	}
	local raise_event = script.raise_event
	-- TODO: ask if is allowed to change force from other mods
	if not is_on_pre_entity_force_changed_event_active and
		not is_on_entity_force_changed_event_active
	then
		for _, entity in pairs(entites_for_capturing) do
			entity.force = player_force
		end
	elseif is_on_pre_entity_force_changed_event_active and
		not is_on_entity_force_changed_event_active
	then
		local pre_event_data = {
			entity = nil,
			next_force = player_force
		}
		for _, entity in pairs(entites_for_capturing) do
			pre_event_data.entity = entity
			raise_event(on_pre_entity_force_changed, pre_event_data)
			if entity.valid then
				entity.force = player_force
			end
		end
	elseif not is_on_pre_entity_force_changed_event_active and
		is_on_entity_force_changed_event_active
	then
		local event_data = {
			entity = nil,
			next_force = player_force
		}
		for _, entity in pairs(entites_for_capturing) do
			event_data.entity = entity
			event_data.prev_force = entity.force
			entity.force = player_force
			raise_event(on_entity_force_changed, event_data)
		end
	elseif is_on_pre_entity_force_changed_event_active and
		is_on_entity_force_changed_event_active
	then
		local pre_event_data = {
			entity = nil,
			next_force = nil
		}
		local event_data = {
			entity = nil,
			prev_force = nil
		}
		for _, entity in pairs(entites_for_capturing) do
			pre_event_data.entity = entity
			raise_event(on_pre_entity_force_changed, pre_event_data)
			if entity.valid then
				event_data.entity = entity
				event_data.prev_force = entity.force
				entity.force = player_force
				raise_event(on_entity_force_changed, event_data)
			end
		end
	end
end


M.on_init = update_global_data
M.on_configuration_changed = update_global_data
M.on_load = link_data
M.update_global_data_on_disabling = update_global_data -- for safe disabling of this mod

--#endregion


M.events = {
	--[defines.events.on_gui_click] = on_gui_click,
	--[defines.events.on_player_created] = on_player_created,
	--[defines.events.on_player_joined_game] = on_player_joined_game,
	--[defines.events.on_player_left_game] = on_player_left_game,
	--[defines.events.on_player_removed] = delete_player_data,
	--[defines.events.on_player_changed_surface] = clear_player_data,
	--[defines.events.on_player_respawned] = clear_player_data,
}

M.commands = {
	reclaim = reclaim_command,
}


return M
