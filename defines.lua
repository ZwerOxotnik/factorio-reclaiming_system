-- Change data in this file in your mod!
local _data = {
	MOD_NAME = "reclaiming_system",
	MOD_PATH = "__reclaiming_system__",

	-- Don't use symbols like '-' etc (it'll break pattern of regular expressions)
	MOD_SHORT_NAME = "recl_",
	AUTHOR = "ZwerOxotnik"
}

if (not IS_DATA_STAGE and script and script.active_mods) then
	if not MAKE_DEFINE_GLOBAL then
		return _data
	end
end

--- Make content of _data global
for k, v in pairs(_data) do
	_ENV[k] = v
end
