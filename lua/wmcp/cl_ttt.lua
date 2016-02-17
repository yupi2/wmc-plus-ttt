-- if true then no music is played at the end of the round.
local wmcp_playroundend = CreateConVar("wmcp_playroundend", "1", FCVAR_ARCHIVE)
-- if true then no music is played at the end of the round if music is currently playing.
local wmcp_playroundendifmusic = CreateConVar("wmcp_playroundendifmusic", "1", FCVAR_ARCHIVE)
-- if true then the music from the end of the round continues to play into the next round.
local wmcp_contafterroundend = CreateConVar("wmcp_contafterroundend", "0", FCVAR_ARCHIVE)

hook.Add("TTTSettingsTabs", "WMCPTTT Settings", function(dtabs)
	local padding = dtabs:GetPadding() * 2

	local dsettings = vgui.Create("DPanelList", dtabs)
	dsettings:StretchToParent(0, 0, padding, 0)
	dsettings:EnableVerticalScrollbar(true)
	dsettings:SetPadding(10)
	dsettings:SetSpacing(10)

	local dgui = vgui.Create("DForm", dsettings)
	dgui:SetName("General settings")

	dgui:CheckBox("Play end-round music", "wmcp_playroundend")
	dgui:CheckBox("Play end-round music if a song is already playing", "wmcp_playroundendifmusic")
	dgui:CheckBox("Continue end-round music into the next round", "wmcp_contafterroundend")
	dsettings:AddItem(dgui)

	--dtabs:AddSheet("Settings", dsettings, "icon16/wrench_orange.png", false, false, "WMC related settings")
end)

hook.Add("WMCPPlayNetMsg", "TTTStuff", function(url, title, opts)
	if not opts.ttt_sent then return end

	if not wmcp_playroundend:GetBool() then
		return false -- block
	end

	if not wmcp_playroundendifmusic:GetBool() then
		local clip = wmcp.GetClip()
		if IsValid(clip) and clip:isPlaying() then
			return false -- block
		end
	end

	-- If media has been playing since last end-round, let's not play something new
	if wmcp_contafterroundend:GetBool() then
		local clip_opts = wmcp.GetClipMeta().opts
		if clip_opts and clip_opts.ttt_sent then
			return false
		end
	end
end)

-- Sent at round start to end any music started by TTT.
hook.Add("WMCPStopNetMsg", "TTTStuff", function(opts)
	if opts.ttt_sent and not wmcp_contafterroundend:GetBool() then
		local clip_opts = wmcp.GetClipMeta().opts
		if clip_opts and clip_opts.ttt_sent then
			return true -- stop that sound
		end
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
