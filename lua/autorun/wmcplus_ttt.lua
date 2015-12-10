local function include_cl(file)
	if SERVER then AddCSLuaFile(file) end
	if CLIENT then include(file) end
end
local function include_sv(file)
	if SERVER then include(file) end
end
local function include_sh(file)
	include_cl(file)
	include_sv(file)
end

-- Load libraries
--if not medialib then wmcp.include_sh("wmcp_libs/medialib.lua") end
--if not nettable then wmcp.include_sh("wmcp_libs/nettable.lua") end

-- Load TTT files

hook.Add("PostGamemodeLoaded", "WMC Plus TTT", function()
	if wmcp and engine.ActiveGamemode() == "terrortown" then
		include_sv("wmcp/sv_ttt.lua")
		include_cl("wmcp/cl_ttt.lua")
	end
end)
