util.AddNetworkString("wmcpttt_play")
util.AddNetworkString("wmcpttt_stop")

local table = table
local pairs = pairs
local ipairs = ipairs

local mediaListTbl = nettable.get("WMCPMedia.Main")

local function GetPlayerSong()
	local alive = util.GetAlivePlayers()
	if #alive == 1 then
		local sid = alive[1]:SteamID()
		local available_links = {}

		for _, media in pairs(mediaListTbl) do
			if media.ttt_opts and media.ttt_opts[sid] then
				table.insert(available_links, {title = media.title, url = media.url})
			end
		end

		if #available_links > 0 then
			return table.Random(available_links)
		end
	end
end

local function GetRoundEndSong(round_result)
	local possibilities = {}

	if round_result == WIN_TIMELIMIT then
		-- Add in innocent-win songs.
		for _, media in pairs(mediaListTbl) do
			if media.ttt_opts and (media.ttt_opts[WIN_TIMELIMIT] or media.ttt_opts[WIN_INNOCENT]) then
				table.insert(possibilities, {title = media.title, url = media.url})
			end
		end
	else
		for _, media in pairs(mediaListTbl) do
			if media.ttt_opts and media.ttt_opts[round_result] then
				table.insert(possibilities, {title = media.title, url = media.url})
			end
		end
	end

	return #possibilities > 0 and table.Random(possibilities) or nil
end

hook.Add("TTTEndRound", "WMCPTTT_PlayRoundEnds", function(result)
	local playsong = GetPlayerSong() or GetRoundEndSong(result)
	if playsong then
		net.Start("wmcpttt_play")
			net.WriteString(playsong.url)
			net.WriteString(playsong.title or "")
		net.Broadcast()
	end
end)

hook.Add("TTTPrepareRound", "WMCPTTT_StopRoundEnds", function()
	net.Start("wmcpttt_stop")
	net.Broadcast()
end)

concommand.Add("wmcpttt_setendround", function(ply, cmd, args, raw)
	if not wmcp.IsAllowed(ply, "edit") then ply:ChatPrint("access denied") return end

	local id = tonumber(args[1])
	local round_result = tonumber(args[2])
	local to_remove = args[3] == "1"

	if not id then return end

	if round_result ~= WIN_TRAITOR and round_result ~= WIN_INNOCENT and
			round_result ~= WIN_TIMELIMIT then
		return
	end

	local val = mediaListTbl[id]
	if not val then return end

	if to_remove then
		if not val.ttt_opts then return end
		val.ttt_opts[round_result] = nil
		if table.Count(val.ttt_opts) == 0 then
			val.ttt_opts = nil
		end
	else
		if not val.ttt_opts then val.ttt_opts = {} end
		-- Exit early so we don't resend the table to users or rewrite the file.
		if val.ttt_opts[round_result] then return end
		val.ttt_opts[round_result] = true
	end

	nettable.commit(mediaListTbl)
	wmcp.Persist()
end)

concommand.Add("wmcpttt_setplayer", function(ply, cmd, args, raw)
	if not wmcp.IsAllowed(ply, "edit") then ply:ChatPrint("access denied") return end

	local id = tonumber(args[1])
	local sid = tostring(args[2] or "")
	local to_remove = args[3] == "1"

	if not id or not sid then return end

	-- The only check if it's a valid Steam ID.
	-- I don't want to deal with copying the function definition
	-- in because then I would have to deal with license shit.
	-- Plus, who doesn't use ULib?
	if ULib and ULib.isValidSteamID then
		if not ULib.isValidSteamID(sid) then return end
	end

	local val = mediaListTbl[id]
	if not val then return end

	if to_remove then
		if not val.ttt_opts then return end
		val.ttt_opts[sid] = nil
		if table.Count(val.ttt_opts) == 0 then
			val.ttt_opts = nil
		end
	else
		if not val.ttt_opts then val.ttt_opts = {} end
		-- Exit early so we don't resend the table to users or rewrite the file.
		if val.ttt_opts[sid] then return end
		val.ttt_opts[sid] = true
	end

	nettable.commit(mediaListTbl)
	wmcp.Persist()
end)
