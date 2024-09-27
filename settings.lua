require("defines")

--- Adds settings for commands
if mods["BetterCommands"] then
	local is_ok, better_commands = pcall(require, "__BetterCommands__/BetterCommands/control")
	if is_ok then
		better_commands.COMMAND_PREFIX = MOD_SHORT_NAME
		better_commands.create_settings(MOD_PATH, MOD_SHORT_NAME) -- Adds switchable commands
	end
end


data:extend({
	{
		type = "int-setting",
		name = "recl_enemy_check_distance",
		setting_type = "runtime-global",
		default_value = 40,
		minimum_value = 1,
		maximum_value = 1024,
		hidden = false
	}, {
		type = "int-setting",
		name = "recl_reclaiming_distance",
		setting_type = "runtime-global",
		default_value = 18,
		minimum_value = 1,
		maximum_value = 1024,
		hidden = false
	}
})
