--Copyright (c) 2013, Byrthnoth
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of <addon name> nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

_addon.name = 'Cancel'
_addon.version = '1.0'
_addon.author = 'Byrth'
_addon.commands = {'cancel'}

res = require 'resources'

-- OPTIMIZATION: Cache language setting at load time
language = windower.ffxi.get_info().language:lower()


windower.register_event('addon command',function (...)
	local command = table.concat({...},' ')
	if not command then return end
	local status_id_tab = command:split(',')
	status_id_tab.n = nil
	
	-- OPTIMIZATION: Cache player buffs outside loops (avoids repeated API calls)
	local player = windower.ffxi.get_player()
	if not player then return end
	
	-- OPTIMIZATION: Build target ID set first for O(1) lookups
	-- This converts the O(n*m) nested loop into O(n+m) complexity
	local target_ids = {}
	
	-- First pass: resolve all command arguments to buff IDs
	for _, pattern in ipairs(status_id_tab) do
		-- Check if pattern is a numeric ID
		local numeric_id = tonumber(pattern)
		if numeric_id then
			target_ids[numeric_id] = true
		else
			-- Pattern is a name - find matching buff IDs
			-- Check if pattern contains wildcards
			local has_wildcard = pattern:match('[*?]')
			
			for buff_id, buff_data in pairs(res.buffs) do
				if buff_data and buff_data[language] then
					local buff_name = buff_data[language]
					local matches = false
					
					if has_wildcard then
						-- Use wildcard matching
						matches = windower.wc_match(buff_name, pattern)
					else
						-- Simple case-insensitive equality check (faster)
						matches = buff_name:lower() == pattern:lower()
					end
					
					if matches then
						target_ids[buff_id] = true
					end
				end
			end
		end
	end
	
	-- Second pass: cancel matching buffs (single loop through player buffs)
	for _, buff_id in ipairs(player.buffs) do
		if target_ids[buff_id] then
			cancel(buff_id)
		end
	end
end)

function cancel(id)
	windower.packets.inject_outgoing(0xF1,string.char(0xF1,0x04,0,0,id%256,math.floor(id/256),0,0)) -- Inject the cancel packet
end