-- wmcp_noroundend:
--   if true then no music is played at the end of the round.
local wmcp_noroundend = CreateClientConVar("wmcp_noroundend", "0")
-- wmcp_noroundendifmusic:
--   if true then no music is played at the end of the round is music is currently playing.
local wmcp_noroundendifmusic = CreateClientConVar("wmcp_noroundendifmusic", "0")
-- wmcp_noroundendifunfocused:
--   if true then no music is played at the end of the round if the GMOD window isn't focused.
local wmcp_noroundendifunfocused = CreateClientConVar("wmcp_noroundendifunfocused", "1")
-- wmcp_contmusicafterroundend:
--   if true then the music from the end of the round continues to play into the next round.
local wmcp_contmusicafterroundend = CreateClientConVar("wmcp_contmusicafterroundend", "0")

hook.Add("TTTSettingsTabs", "WMCPTTT_Settings", function(dtabs)
	local dsettings = dtabs.Items[2].Panel

	-- todo ugh
end)

-- Just added "wyozimc_stop" in also because who wants to change their bind?
-- UPDATE: I don't really care too much anymore. I'm going to use
-- the following and everyone should too:                                                                       :^)
--     bind semicolon "stopsound; wyozimc_stop; wmcp_stop"
-- concommand.Add("wyozimc_stop", function()
	-- wmcp.StopClip()
-- end)

net.Receive("wmcpttt_play", function()
	local clip = wmcp.GetClip()
	local url, title = net.ReadString(), net.ReadString()
	if title == "" then title = nil end

	if wmcp_noroundend:GetBool() then return end

	if wmcp_noroundendifmusic:GetBool() then
		if IsValid(clip) and clip:isPlaying() then return end
	end

	if wmcp_noroundendifunfocused:GetBool() and not system.HasFocus() then
		return
	end

	-- If a song has been playing since the previous song, let's not stop it.
	if wmcp_contmusicafterroundend:GetBool() then
		local meta = wmcp.GetClipMeta()
		if meta and meta.ttt_started == true then return end
	end

	wmcp.Play(url, {title = title, ttt_started = true})
end)

net.Receive("wmcpttt_stop", function()
	if wmcp_contmusicafterroundend:GetBool() then
		local meta = wmcp.GetClipMeta()
		if meta and meta.ttt_started == true then return end
	end

	local clip = wmcp.GetClip()
	if IsValid(clip) then
		clip:stop()
	end
end)

hook.Add("WMCPMedialistRowRightClick", "WMCPAddDebugItem", function(menu, mediaId, line, media)
	-- Insert permission check here:
	-- todo eventually

	menu:AddSpacer()

	local submenu, smpnl = menu:AddSubMenu("TTT")

	smpnl:SetIcon("VGUI/ttt/sprite_traitor")
	smpnl.m_Image:SetSize(16, 16)

	local is_innocent_music = false
	local is_timelimit_music = false
	local is_traitor_music = false

	if media and media.ttt_opts then
		is_innocent_music = media.ttt_opts[WIN_INNOCENT] == true
		is_timelimit_music = media.ttt_opts[WIN_TIMELIMIT] == true
		is_traitor_music = media.ttt_opts[WIN_TRAITOR] == true
	end

	local blah = submenu:AddOption("Toggle as Innocent end round music", function()
		print("Before "..tostring(is_innocent_music))
		PrintTable(media, 1)
		RunConsoleCommand("wmcpttt_setendround", mediaId, WIN_INNOCENT, is_innocent_music and "1" or "0")
		print("After")
		PrintTable(media, 1)
	end):SetChecked(is_innocent_music)

	submenu:AddOption("Toggle as Time limit reached end round music", function()
		RunConsoleCommand("wmcpttt_setendround", mediaId, WIN_TIMELIMIT, is_timelimit_music and "1" or "0")
	end):SetChecked(is_timelimit_music)--:SetIcon("icon16/time.png")

	submenu:AddOption("Toggle as Traitor end round music", function()
		RunConsoleCommand("wmcpttt_setendround", mediaId, WIN_TRAITOR, is_traitor_music and "1" or "0")
	end):SetChecked(is_traitor_music)--:SetIcon("icon16/user_red.png")

	submenu:AddSpacer()

	local csubmenu, csmpnl = submenu:AddSubMenu("Player specific", function() end)
	csmpnl:SetIcon("icon16/user_comment.png")

	csubmenu:AddOption("Add by SteamID", function()
		Derma_StringRequest( 
			"Steam ID", 
			"Please input the steam id whose specific round end song to set",
			"",
			function(text) 
				RunConsoleCommand("wmcpttt_setplayer", mediaId, text, "0")
			end,
			function(text) end
		)
	end):SetIcon("icon16/add.png")

	csubmenu:AddOption("Remove by SteamID", function()
		Derma_StringRequest( 
			"Steam ID", 
			"Please input the steam id whose specific round end song to remove",
			"",
			function(text) 
				RunConsoleCommand("wmcpttt_setplayer", mediaId, text, "1")
			end,
			function(text) end
		)
	end):SetIcon("icon16/cancel.png")

	csubmenu:AddSpacer()

	for _,ply in pairs(player.GetAll()) do
		local steamid = ply:SteamID()
		local checked = media and media.ttt_opts and media.ttt_opts[steamid]

		csubmenu:AddOption(ply:Nick(), function()
			RunConsoleCommand("wmcpttt_setplayer", mediaId, steamid, checked and "1" or "0")
		end):SetChecked(checked)
	end

	--[[ menu:AddOption("Print data", function()
		print("Printing debug data from WMCP")
		print("menu: ", menu)
		print("id: ", id)
		print("line:", line)
		print("media:")
		PrintTable(media or {}, 1)
		print("")
	end):SetImage("icon16/lightning.png") ]]
end)