local function ConvertOldTTTOpts(t)
	if type(t) == "table" then
		-- Example TTTOpts.
		-- "TTTOpts":{"0":true,"4":true,"STEAMID":true}

		-- Redefine TTT constants as they are nil sometime.
		local ROLE_INNOCENT = 0
		local ROLE_TRAITOR  = 1

		local WIN_NONE      = 1
		local WIN_TRAITOR   = 2
		local WIN_INNOCENT  = 3
		local WIN_TIMELIMIT = 4

		local new = {}
		new[WIN_TRAITOR] = t[ROLE_TRAITOR]
		new[WIN_INNOCENT] = t[ROLE_INNOCENT]
		new[WIN_TIMELIMIT] = t[WIN_TIMELIMIT]

		for k, v in pairs(t) do
			if isstring(k) then
				new[k] = true
			end
		end

		return table.Count(new) > 0 and new or nil
	end
end

local function SplitAddedBy(str)
	-- example str: "STEAM_0:0:50054678|Wombloo"
	local split = string.Split(str, "|")
	return split[1], split[2]
end

local function CompileNicksAndSteamIds()
	local nicks = {}
	local wmcpData = util.JSONToTable(file.Read("wmcp.txt", "DATA"))

	for k, v in pairs(wmcpData) do
		local sid, nick = v.a_sid, v.a_nick
		if sid and nick then
			if not nicks[sid] then nicks[sid] = {} end
			table.insert(nicks[sid], nick)
		end
	end

	return nicks
end

-- Check for a constant nick and return the passed nick otherwise.
local function GetConstantNick(sid, nick)
	if constantNicks then
		return constantNicks[sid]
	elseif file.Exists("constantNicks.txt", "DATA") then
		constantNicks = util.JSONToTable(file.Read("constantNicks.txt", "DATA"))
		return constantNicks[sid] or nick
	else
		return nick
	end
end

local function ConvertOldWMCtoWMCP(old)
	local ti = table.insert
	local new = {}
	
	for k, v in pairs(old) do
		local sid, nick = SplitAddedBy(v.AddedBy)
		nick = GetConstantNick(sid, nick)
		local newTTTOpts = ConvertOldTTTOpts(v.TTTOpts)
		ti(new, {title = v.Title, url = v.Link, a_nick = nick, a_sid = sid, ttt_opts = newTTTOpts, date_added = v.Date})
	end

	return new
end

concommand.Add("wmcp_convertdata", function(ply, cmd, args, raw)
	-- fn = file name; fd = file data; tbl = table
	local fn_wyozimedia = args[1] or "wyozimedia.txt"
	local fn_wmcp = args[2] or "wmcp.txt"

	if not file.Exists(fn_wyozimedia, "DATA") then
		ply:ChatPrint("The file \'"..fn_wyozimedia.."\' doesn't exist; Exiting!")
		return
	end

	if file.Exists(fn_wmcp, "DATA") then
		local fn_backup = fn_wmcp..".bak"
		local num = 0

		while file.Exists(fn_backup..num, "DATA") do
			num = num + 1
		end

		local data = file.Read(fn_wmcp, "DATA")
		file.Write(fn_backup..num, "DATA")
	end

	local tbl_wyozimedia = util.JSONToTable(file.Read(fn_wyozimedia, "DATA"))
	if tbl_wyozimedia == nil then
		ply:ChatPrint("Invalid data in the wyozimedia file; Exiting!")
		return
	end

	tbl_wyozimedia = ConvertOldWMCtoWMCP(tbl_wyozimedia)
	file.Write(fn_wmcp, util.TableToJSON(tbl_wyozimedia, true))
end)

-- if file.Exists("wyozimedia.txt", "DATA") then
	-- local oldwmcData = file.Read("wyozimedia.txt", "DATA")
	-- local convertedData = ConvertOldWMCtoWMCP(util.JSONToTable(oldwmcData))

	-- local wmcpData

	-- if file.Exists("wmcp.bak.txt", "DATA") then
		-- wmcpData = file.Read("wmcp.bak.txt", "DATA")
	-- elseif file.Exists("wmcp.txt", "DATA") then
		-- wmcpData = file.Read("wmcp.txt", "DATA")
		-- file.Write("wmcp.bak.txt", wmcpData)
	-- end

	-- if wmcpData then
		-- -- stupid local variables to put the wmcp data first.
		-- local qqqq = util.JSONToTable(wmcpData)
		-- table.Add(qqqq, convertedData)
		-- convertedData = qqqq
	-- end

	-- file.Write("wmcp.txt", util.TableToJSON(convertedData, true))
-- end

-- Used this to compile every person's nickname with their steamid.
-- Then I chose the nickname to use and then put it constantNicks.txt as valid JSON.
-- It was a pain in the ass. I should us a GUI for it next time, but it would have
-- taken longer to write that instead of just sorting by hand.
--file.Write("list_of_nicks.txt", util.TableToJSON(CompileNicksAndSteamIds(), true))
