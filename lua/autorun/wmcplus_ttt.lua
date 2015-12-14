hook.Add("PostGamemodeLoaded", "WMC Plus TTT", function()
	if wmcp and engine.ActiveGamemode() == "terrortown" then
		wmcp.include_sv("wmcp/sv_ttt.lua")
		wmcp.include_cl("wmcp/cl_ttt.lua")
	end
end)
