-- suriwire
-- A wireshark plugin to integrate suricata alerts in wireshark
-- pcap output.
--
-- (c) 2011 Eric Leblond <eric@regit.org>
--
-- Wireshark - Network traffic analyzer
-- By Gerald Combs <gerald@wireshark.org>
-- Copyright 1998 Gerald Combs
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 3
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.


if (gui_enabled()) then 
	suri_alerts = {}
	suri_file = "sample.log"
	local suri_proto = Proto("suricata","Suricata Analysis")
	-- create a function to "postdissect" each frame
	local suri_sid = ProtoField.string("suricata.sid", "SID", FT_STRING)
	local suri_msg = ProtoField.string("suricata.msg", "Message", FT_STRING)

	function suri_proto.dissector(buffer,pinfo,tree)
	     for i, alert in ipairs(suri_alerts) do
		  a = pinfo.number - alert[1]
		  if (pinfo.number - alert[1] == 0) then
		     subtree = tree:add(suri_proto, buffer[0])
		     -- add protocol fields to subtree
		     subtree:add(suri_msg, "SID: " .. alert[2] .. ": "):append_text(alert[3])
		     subtree:add_expert_info(PI_MALFORMED, PI_WARN, alert[3])
		     break
		  end
	     end
	end

	function suri_proto.init()
	    local pat = "(%d+):(%d+):(.*)"
	    -- read the lines in table 'lines'
	    for line in io.lines() do
	      local alert = {}
	      for id, sid, text in string.gmatch(line, pat) do
		  table.insert(alert, id)
		  table.insert(alert, sid)
		  table.insert(alert, text)
	      end
	      table.insert(suri_alerts, alert)
	    end
	end

	-- register our protocol as a postdissector
	function suriwire_activate()
		function suriwire_register(file)
			suri_file = file
			print (file)
	    		io.input(suri_file)
			register_postdissector(suri_proto)
		end
		-- run suricata
		-- set input file
		new_dialog("Choose alert file", suriwire_register, "Choose file")
	end

	function suriwire_page()
		browser_open_url("http://home.regit.org/software/suriwire")
	end

	register_menu("Suricata/Activate", suriwire_activate, MENU_TOOLS_UNSORTED)
	register_menu("Suricata/Web", suriwire_page, MENU_TOOLS_UNSORTED)
end

