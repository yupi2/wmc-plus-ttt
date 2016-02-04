-- wmcp_noroundend:
--   if true then no music is played at the end of the round.
local wmcp_noroundend = CreateClientConVar("wmcp_noroundend", "0")
-- wmcp_noroundendifmusic:
--   if true then no music is played at the end of the round is music is currently playing.
local wmcp_noroundendifmusic = CreateClientConVar("wmcp_noroundendifmusic", "0")
-- wmcp_contmusicafterroundend:
--   if true then the music from the end of the round continues to play into the next round.
local wmcp_contmusicafterroundend = CreateClientConVar("wmcp_contmusicafterroundend", "0")

hook.Add("TTTSettingsTabs", "WMCPTTT Settings", function(dtabs)
	local padding = dtabs:GetPadding() * 2

	local dsettings = vgui.Create("DPanelList", dtabs)
	dsettings:StretchToParent(0, 0, padding, 0)
	dsettings:EnableVerticalScrollbar(true)
	dsettings:SetPadding(10)
	dsettings:SetSpacing(10)

	local dgui = vgui.Create("DForm", dsettings)
	dgui:SetName("General settings")

	dgui:CheckBox("Disable end-round music", "wmcp_noroundend")
	dgui:CheckBox("Disable end-round music if a song is already playing", "wmcp_noroundendifmusic")
	dgui:CheckBox("Continue end-round music into the next round", "wmcp_contmusicafterroundend")
	dsettings:AddItem(dgui)

	--dtabs:AddSheet("Settings", dsettings, "icon16/wrench_orange.png", false, false, "WMC related settings")
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
	--[[
		-- first add FCVAR_REPLICATED to the CVAR's flags server side.
		local group = GetConVar("wmcp_allowedgroup"):GetString()
		if not LocalPlayer() in group then return end something like this
	]]

	menu:AddSpacer()

	local tttsmpnl, tttsmopt = menu:AddSubMenu("TTT")

	tttsmopt:SetIcon("VGUI/ttt/sprite_traitor")
	tttsmopt.m_Image:SetSize(16, 16)

	local is_innocent_music = false
	local is_timelimit_music = false
	local is_traitor_music = false

	if media.ttt_opts then
		is_innocent_music = media.ttt_opts[WIN_INNOCENT] == true
		is_timelimit_music = media.ttt_opts[WIN_TIMELIMIT] == true
		is_traitor_music = media.ttt_opts[WIN_TRAITOR] == true
	end

	tttsmpnl:AddOption("Toggle as Innocent end round music", function()
		print("Before "..tostring(is_innocent_music))
		PrintTable(media, 1)
		RunConsoleCommand("wmcpttt_setendround", mediaId, WIN_INNOCENT, is_innocent_music and "1" or "0")
		print("After")
		PrintTable(media, 1)
	end):SetIcon("icon16/" .. (is_innocent_music and "cancel" or "add") .. ".png")

	tttsmpnl:AddOption("Toggle as Time limit reached end round music", function()
		RunConsoleCommand("wmcpttt_setendround", mediaId, WIN_TIMELIMIT, is_timelimit_music and "1" or "0")
	end):SetIcon("icon16/" .. (is_timelimit_music and "cancel" or "add") .. ".png")

	tttsmpnl:AddOption("Toggle as Traitor end round music", function()
		RunConsoleCommand("wmcpttt_setendround", mediaId, WIN_TRAITOR, is_traitor_music and "1" or "0")
	end):SetIcon("icon16/" .. (is_traitor_music and "cancel" or "add") .. ".png")

	tttsmpnl:AddSpacer()

	do
		local plrsmpnl, plrsmopt = tttsmpnl:AddSubMenu("Players", function() end)
		plrsmopt:SetIcon("icon16/user_comment.png")

		plrsmpnl:AddSpacer()

		for _,plr in pairs(player.GetAll()) do
			local steamid = plr:SteamID()
			local checked = media.ttt_opts and media.ttt_opts[steamid]

			plrsmpnl:AddOption("[".. plr:UserID() .. "] " .. plr:Nick(), function()
				RunConsoleCommand("wmcpttt_setplayer", mediaId, steamid, checked and "1" or "0")
			end):SetIcon("icon16/" .. (checked and "cancel" or "add") .. ".png")
		end
	end

	do
		local sidsmpnl, sidsmopt = tttsmpnl:AddSubMenu("Steam IDs", function() end)
		sidsmopt:SetIcon("icon16/user_comment.png")

		sidsmpnl:AddOption("Add by SteamID", function()
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

		if media.ttt_opts then
			sidsmpnl:AddSpacer()

			for k,v in pairs(media.ttt_opts) do
				if not isstring(k) or v ~= true then
					continue
				end

				sidsmpnl:AddOption(k, function()
					Derma_Query("Are you sure you want to remove " .. k,
						"yay or nay",
						"yay", function()
							RunConsoleCommand("wmcpttt_setplayer", mediaId, k, "1")
						end,
						"nay")
				end):SetIcon("icon16/" .. (v and "cancel" or "add") .. ".png")
			end
		end
	end
end)
